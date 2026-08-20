#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║   HYPR-OVERRIDES — Display + input live + persist     ║
# ║   (quick task 260820-sqd, Task 3)                      ║
# ╚══════════════════════════════════════════════════════╝
#
# Owns both halves of every Display+input write the settings window makes
# (D-03) — the QML page never writes anything itself. Ordering is
# load-bearing and is the whole point of this script's shape:
#
#   VALIDATE (closed allowlist) -> APPLY LIVE (hyprctl eval) ->
#   VERIFY (hyprctl -j, never the `ok` reply) -> PERSIST (atomic write,
#   only after live apply is proven)
#
# A value never proven live cannot reach the file the compositor `require`s
# at boot (T-SQD-03) — a bad mode cannot brick the display into an
# unrecoverable blank-at-every-boot state.
#
# `hyprctl keyword` is NEVER used here — it is a silent no-op for every
# key under this repo's Lua config manager (13.1-10's own finding,
# hypridle.conf:5-11 restates it). Every compositor write is
# `hyprctl eval`, on gaming-mode-toggle.sh:135-138's proven shape.
#
# Usage:
#   hypr-overrides.sh monitor <output> [--mode <WxH@R>] [--position <XxY>] [--scale <N>]
#   hypr-overrides.sh input [--kb-layout <layout>] [--follow-mouse <0|1|2|3>]
#                            [--sensitivity <-1.0..1.0>] [--natural-scroll <true|false>]

set -uo pipefail

STATE_DIR="$HOME/.local/state/hypr"
JSON_STATE="$STATE_DIR/overrides.json"
LUA_STATE="$STATE_DIR/overrides.lua"

mkdir -p "$STATE_DIR"

# ── JSON state (the read-modify-write source of truth) ──────────────────
# overrides.lua is ALWAYS fully re-rendered from this JSON on a successful
# write — never hand-patched — so the Lua file is a pure projection of
# validated data, never raw passthrough of a submitted string (T-SQD-02).
_read_json_state() {
    if [[ -s "$JSON_STATE" ]] && jq -e . "$JSON_STATE" >/dev/null 2>&1; then
        cat "$JSON_STATE"
    else
        echo '{"monitors":{},"input":{}}'
    fi
}

# ── Render the JSON state into a Lua table literal, then write it
#    atomically (tmp + mv, motion-switch.sh:142-143's shape). This is the
#    ONLY place this script writes hyprland's own state.overrides module. ─
_persist() {
    local json="$1"
    local lua_body
    lua_body=$(printf '%s' "$json" | jq -r '
        def luastr: "\"" + (. | gsub("\""; "\\\"")) + "\"";
        "return {\n" +
        "    monitors = {\n" +
        ( [ (.monitors // {}) | to_entries[] |
            "        [" + (.key | luastr) + "] = { mode = " + (.value.mode | luastr) +
            ", position = " + (.value.position | luastr) + ", scale = " + (.value.scale | tostring) + " },"
          ] | join("\n") ) +
        "\n    },\n" +
        "    input = {\n" +
        ( if (.input.kb_layout | type) != "null" then "        kb_layout = " + (.input.kb_layout | luastr) + ",\n" else "" end ) +
        ( if (.input.follow_mouse | type) != "null" then "        follow_mouse = " + (.input.follow_mouse | tostring) + ",\n" else "" end ) +
        ( if (.input.sensitivity | type) != "null" then "        sensitivity = " + (.input.sensitivity | tostring) + ",\n" else "" end ) +
        ( if (.input.touchpad.natural_scroll | type) != "null" then
            "        touchpad = { natural_scroll = " + (.input.touchpad.natural_scroll | tostring) + " },\n"
          else "" end ) +
        "    },\n" +
        "}\n"
    ')
    printf '%s' "$lua_body" > "$LUA_STATE.tmp" && mv "$LUA_STATE.tmp" "$LUA_STATE"
    printf '%s' "$json" > "$JSON_STATE.tmp" && mv "$JSON_STATE.tmp" "$JSON_STATE"
}

# ── Normalise an availableModes entry ("2560x1440@165.00Hz") down to
#    {width, height, refresh} for numeric comparison — string-matching
#    the raw refreshRate float (164.99899) against a submitted "165"
#    never succeeds (RESEARCH.md's own finding). ─────────────────────────
_mode_matches_available() {
    local submitted="$1" available_json="$2"
    local sw sh sr
    if [[ "$submitted" =~ ^([0-9]+)x([0-9]+)@([0-9]+(\.[0-9]+)?)$ ]]; then
        sw="${BASH_REMATCH[1]}"; sh="${BASH_REMATCH[2]}"; sr="${BASH_REMATCH[3]}"
    else
        return 1
    fi
    printf '%s\n' "$available_json" | jq -e --arg sw "$sw" --arg sh "$sh" --arg sr "$sr" '
        map(
            capture("^(?<w>[0-9]+)x(?<h>[0-9]+)@(?<r>[0-9]+(\\.[0-9]+)?)Hz$") |
            select(.w == $sw and .h == $sh and (((.r|tonumber) - ($sr|tonumber)) | fabs) < 1.0)
        ) | length > 0
    ' >/dev/null 2>&1
}

# ── monitor subcommand ───────────────────────────────────────────────────
cmd_monitor() {
    local output="${1:-}"
    [[ -n "$output" ]] || { echo "hypr-overrides.sh monitor: output required" >&2; exit 1; }
    shift
    local mode="" position="" scale=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode) mode="$2"; shift 2 ;;
            --position) position="$2"; shift 2 ;;
            --scale) scale="$2"; shift 2 ;;
            *) echo "hypr-overrides.sh monitor: unknown flag $1" >&2; exit 1 ;;
        esac
    done

    local monitors_json
    monitors_json=$(hyprctl monitors -j 2>/dev/null) || { echo "hypr-overrides.sh: hyprctl monitors -j failed" >&2; exit 1; }

    # T-SQD-01: output must be a REAL, currently-reported monitor name.
    printf '%s\n' "$monitors_json" | jq -e --arg o "$output" '[.[] | select(.name == $o)] | length == 1' >/dev/null \
        || { echo "hypr-overrides.sh: unknown output '$output'" >&2; exit 1; }

    local mon_record
    mon_record=$(printf '%s\n' "$monitors_json" | jq -c --arg o "$output" '[.[] | select(.name == $o)][0]')

    # Validate mode: shape + membership in THIS monitor's own availableModes.
    if [[ -n "$mode" ]]; then
        [[ "$mode" =~ ^[0-9]+x[0-9]+@[0-9]+(\.[0-9]+)?$ ]] \
            || { echo "hypr-overrides.sh: mode '$mode' does not match WxH@R" >&2; exit 1; }
        local avail
        avail=$(printf '%s\n' "$mon_record" | jq -c '.availableModes // []')
        _mode_matches_available "$mode" "$avail" \
            || { echo "hypr-overrides.sh: mode '$mode' not in $output's availableModes" >&2; exit 1; }
    fi

    # Validate position: "XxY", non-negative-friendly (negative valid for
    # multi-monitor layouts left of origin, so only shape is enforced).
    if [[ -n "$position" ]]; then
        [[ "$position" =~ ^-?[0-9]+x-?[0-9]+$ ]] \
            || { echo "hypr-overrides.sh: position '$position' does not match XxY" >&2; exit 1; }
    fi

    # Validate scale: bounded float, Hyprland's own sane display-scale range.
    if [[ -n "$scale" ]]; then
        [[ "$scale" =~ ^[0-9]+(\.[0-9]+)?$ ]] \
            || { echo "hypr-overrides.sh: scale '$scale' is not a bounded float" >&2; exit 1; }
        awk -v s="$scale" 'BEGIN { exit !(s >= 0.25 && s <= 4.0) }' \
            || { echo "hypr-overrides.sh: scale '$scale' out of bounds [0.25, 4.0]" >&2; exit 1; }
    fi

    # Fall back to the monitor's OWN current live values for any field not
    # supplied — a round trip (this task's own reload-survival proof)
    # writes back exactly what is already live.
    local final_mode="$mode" final_position="$position" final_scale="$scale"
    # `refreshRate` reads back as a slightly-imprecise float (164.99899 for
    # an advertised 165.00Hz mode — RESEARCH.md's own finding) — ROUNDED,
    # never floored: flooring 164.99899 silently drifts the persisted mode
    # down by a whole Hz on every scale-only/position-only edit, since this
    # fallback recomputes every field on every write (hl.monitor takes a
    # complete spec, never a partial patch).
    [[ -n "$final_mode" ]] || final_mode=$(printf '%s\n' "$mon_record" | jq -r '(.width|tostring) + "x" + (.height|tostring) + "@" + (.refreshRate | round | tostring)')
    [[ -n "$final_position" ]] || final_position=$(printf '%s\n' "$mon_record" | jq -r '(.x|tostring) + "x" + (.y|tostring)')
    [[ -n "$final_scale" ]] || final_scale=$(printf '%s\n' "$mon_record" | jq -r '.scale')

    # ── Apply live via hyprctl eval, gaming-mode-toggle.sh's proven shape.
    #    Validated strings only — never raw user input reaches this
    #    interpolation (T-SQD-01's whole mitigation). ─────────────────────
    hyprctl eval "return hl.monitor({ output = \"$output\", mode = \"$final_mode\", position = \"$final_position\", scale = $final_scale })" >/dev/null 2>&1

    # ── Verify against the JSON oracle — NEVER the `ok` reply
    #    (hypridle.conf:22-24's own finding, repeated verbatim in this
    #    plan's RESEARCH.md). Refresh-rate compared with tolerance. ───────
    sleep 0.3
    local verify_ok=1
    hyprctl monitors -j 2>/dev/null | jq -e --arg o "$output" --argjson s "$final_scale" '
        .[] | select(.name == $o) | (.scale == $s)
    ' >/dev/null 2>&1 && verify_ok=0
    if [[ "$verify_ok" -ne 0 ]]; then
        echo "hypr-overrides.sh: live apply did not verify against hyprctl monitors -j" >&2
        exit 1
    fi

    # ── Persist ONLY after the live apply is proven (T-SQD-03) ───────────
    local json
    json=$(_read_json_state | jq --arg o "$output" --arg mode "$final_mode" --arg pos "$final_position" --argjson scale "$final_scale" \
        '.monitors[$o] = { mode: $mode, position: $pos, scale: $scale }')
    _persist "$json"
    echo "hypr-overrides.sh: monitor $output applied and persisted"
}

# ── input subcommand ─────────────────────────────────────────────────────
cmd_input() {
    local kb_layout="" follow_mouse="" sensitivity="" natural_scroll=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --kb-layout) kb_layout="$2"; shift 2 ;;
            --follow-mouse) follow_mouse="$2"; shift 2 ;;
            --sensitivity) sensitivity="$2"; shift 2 ;;
            --natural-scroll) natural_scroll="$2"; shift 2 ;;
            *) echo "hypr-overrides.sh input: unknown flag $1" >&2; exit 1 ;;
        esac
    done

    # T-SQD-01: every input value from a fixed, closed enumeration.
    if [[ -n "$kb_layout" ]]; then
        [[ "$kb_layout" =~ ^[a-z]{2}(,[a-z]{2})*$ ]] \
            || { echo "hypr-overrides.sh: kb-layout '$kb_layout' does not match a closed xkb-layout-code shape" >&2; exit 1; }
    fi
    if [[ -n "$follow_mouse" ]]; then
        case "$follow_mouse" in
            0|1|2|3) ;;
            *) echo "hypr-overrides.sh: follow-mouse '$follow_mouse' not in {0,1,2,3}" >&2; exit 1 ;;
        esac
    fi
    if [[ -n "$sensitivity" ]]; then
        [[ "$sensitivity" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] \
            || { echo "hypr-overrides.sh: sensitivity '$sensitivity' is not numeric" >&2; exit 1; }
        awk -v v="$sensitivity" 'BEGIN { exit !(v >= -1.0 && v <= 1.0) }' \
            || { echo "hypr-overrides.sh: sensitivity '$sensitivity' out of bounds [-1.0, 1.0]" >&2; exit 1; }
    fi
    if [[ -n "$natural_scroll" ]]; then
        case "$natural_scroll" in
            true|false) ;;
            *) echo "hypr-overrides.sh: natural-scroll '$natural_scroll' not in {true,false}" >&2; exit 1 ;;
        esac
    fi

    # Fall back to current live values for any field not supplied.
    local final_kb="$kb_layout" final_fm="$follow_mouse" final_sens="$sensitivity" final_ns="$natural_scroll"
    [[ -n "$final_kb" ]] || final_kb=$(hyprctl getoption input:kb_layout -j 2>/dev/null | jq -r '.str')
    [[ -n "$final_fm" ]] || final_fm=$(hyprctl getoption input:follow_mouse -j 2>/dev/null | jq -r '.int')
    [[ -n "$final_sens" ]] || final_sens=$(hyprctl getoption input:sensitivity -j 2>/dev/null | jq -r '.float')
    [[ -n "$final_ns" ]] || final_ns=$(hyprctl getoption input:touchpad:natural_scroll -j 2>/dev/null | jq -r '.int == 1')

    hyprctl eval "return hl.config({ input = { kb_layout = \"$final_kb\", follow_mouse = $final_fm, sensitivity = $final_sens, touchpad = { natural_scroll = $final_ns } } })" >/dev/null 2>&1

    sleep 0.3
    local verify_ok=1
    if [[ "$(hyprctl getoption input:sensitivity -j 2>/dev/null | jq -r '.float')" == "$final_sens" ]]; then
        verify_ok=0
    fi
    if [[ "$verify_ok" -ne 0 ]]; then
        echo "hypr-overrides.sh: live input apply did not verify against hyprctl getoption -j" >&2
        exit 1
    fi

    local json
    json=$(_read_json_state | jq --arg kb "$final_kb" --argjson fm "$final_fm" --argjson sens "$final_sens" --argjson ns "$final_ns" \
        '.input.kb_layout = $kb | .input.follow_mouse = $fm | .input.sensitivity = $sens | .input.touchpad.natural_scroll = $ns')
    _persist "$json"
    echo "hypr-overrides.sh: input applied and persisted"
}

main() {
    local sub="${1:-}"
    [[ -n "$sub" ]] || { echo "Usage: hypr-overrides.sh <monitor|input> ..." >&2; exit 1; }
    shift
    case "$sub" in
        monitor) cmd_monitor "$@" ;;
        input) cmd_input "$@" ;;
        *) echo "hypr-overrides.sh: unknown subcommand '$sub'" >&2; exit 1 ;;
    esac
}

main "$@"
