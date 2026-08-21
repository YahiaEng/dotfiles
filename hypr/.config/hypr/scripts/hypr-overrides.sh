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
#   hypr-overrides.sh look [--gaps-in <0-30>] [--gaps-out <0-60>]
#                           [--border-size <0-10>] [--gaps-workspaces <0-100>]
#                           [--rounding <0-30>] [--blur-enabled <true|false>]
#                           [--blur-size <1-20>] [--blur-passes <1-5>]
#                           [--inactive-opacity <0.5-1.0>] [--shadow-enabled <true|false>]
#                           [--workspace-back-and-forth <true|false>]
#                           [--allow-workspace-cycles <true|false>]
#
# `look` (quick-260821-6z1 Task 4, D-03/R-2) — the compositor "look and
# feel" knobs the Window manager settings page drives. Ships ONLY the
# GREEN rows of RESEARCH.md's Compositor Knob Ledger, both AMBER rows
# (gaps-workspaces, allow-workspace-cycles) probed live on this host on
# 2026-08-21 and shipped since their write half verified. Deliberately
# does NOT cover animation speed (N-01 — not a compositor option at all;
# the Motion preset already IS this control) or border colour (N-02 — the
# theme pipeline re-applies it on every `hyprctl reload`, which fires on
# every theme switch; an eval-applied override would silently revert).
# `general:no_border_on_floating`, `misc:vfr`, `dwindle:pseudotile`,
# `animations:first_launch_animation` and `misc:new_window_takes_over_fullscreen`
# all return `no such option` on this build (Hyprland 0.56.2) and must
# never appear below.

set -uo pipefail

STATE_DIR="$HOME/.local/state/hypr"
JSON_STATE="$STATE_DIR/overrides.json"
LUA_STATE="$STATE_DIR/overrides.lua"

mkdir -p "$STATE_DIR"

# ── Lua string escaping (review CR-03) — the ONE place both the eval sink
#    and the persist sink escape a value before it enters a Lua string
#    literal. `_persist()` already escaped via its own jq `luastr` filter;
#    this is the same escaping, usable from bash for the `hyprctl eval`
#    call sites, which is where CR-03 found the sink that was missed. ────
_luastr() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# ── JSON state (the read-modify-write source of truth) ──────────────────
# overrides.lua is ALWAYS fully re-rendered from this JSON on a successful
# write — never hand-patched — so the Lua file is a pure projection of
# validated data, never raw passthrough of a submitted string (T-SQD-02).
_read_json_state() {
    if [[ -s "$JSON_STATE" ]] && jq -e . "$JSON_STATE" >/dev/null 2>&1; then
        cat "$JSON_STATE"
    else
        echo '{"monitors":{},"input":{},"general":{},"decoration":{},"binds":{}}'
    fi
}

# ── Render the JSON state into a Lua table literal, then write it
#    atomically (tmp + mv, motion-switch.sh:142-143's shape). This is the
#    ONLY place this script writes hyprland's own state.overrides module. ─
_persist() {
    local json="$1"

    # Review WR-01: refuse to render/write a degenerate (empty or
    # malformed) JSON payload — the caller-side fallback-read validation
    # (cmd_input) is the FIRST line of defense; this is the second,
    # independent one, at the one shared choke point every write passes
    # through. Back up the existing good file before ever touching it,
    # idle-overrides.sh's own pattern for the equivalent risk on the
    # idle/lock side, mirrored here for the Display+input side.
    if [[ -z "$json" ]] || ! printf '%s' "$json" | jq -e . >/dev/null 2>&1; then
        echo "hypr-overrides.sh: _persist refused an empty/malformed JSON payload — overrides.lua NOT touched" >&2
        return 1
    fi
    [[ -f "$LUA_STATE" ]] && cp -a "$LUA_STATE" "$LUA_STATE.bak"
    [[ -f "$JSON_STATE" ]] && cp -a "$JSON_STATE" "$JSON_STATE.bak"

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
        "    general = {\n" +
        ( if ((.general.gaps_in) | type) != "null" then "        gaps_in = " + (.general.gaps_in | tostring) + ",\n" else "" end ) +
        ( if ((.general.gaps_out) | type) != "null" then "        gaps_out = " + (.general.gaps_out | tostring) + ",\n" else "" end ) +
        ( if ((.general.border_size) | type) != "null" then "        border_size = " + (.general.border_size | tostring) + ",\n" else "" end ) +
        ( if ((.general.gaps_workspaces) | type) != "null" then "        gaps_workspaces = " + (.general.gaps_workspaces | tostring) + ",\n" else "" end ) +
        "    },\n" +
        "    decoration = {\n" +
        ( if ((.decoration.rounding) | type) != "null" then "        rounding = " + (.decoration.rounding | tostring) + ",\n" else "" end ) +
        ( if ((.decoration.inactive_opacity) | type) != "null" then "        inactive_opacity = " + (.decoration.inactive_opacity | tostring) + ",\n" else "" end ) +
        "        blur = {\n" +
        ( if ((.decoration.blur.enabled) | type) != "null" then "            enabled = " + (.decoration.blur.enabled | tostring) + ",\n" else "" end ) +
        ( if ((.decoration.blur.size) | type) != "null" then "            size = " + (.decoration.blur.size | tostring) + ",\n" else "" end ) +
        ( if ((.decoration.blur.passes) | type) != "null" then "            passes = " + (.decoration.blur.passes | tostring) + ",\n" else "" end ) +
        "        },\n" +
        "        shadow = {\n" +
        ( if ((.decoration.shadow.enabled) | type) != "null" then "            enabled = " + (.decoration.shadow.enabled | tostring) + ",\n" else "" end ) +
        "        },\n" +
        "    },\n" +
        "    binds = {\n" +
        ( if ((.binds.workspace_back_and_forth) | type) != "null" then "        workspace_back_and_forth = " + (.binds.workspace_back_and_forth | tostring) + ",\n" else "" end ) +
        ( if ((.binds.allow_workspace_cycles) | type) != "null" then "        allow_workspace_cycles = " + (.binds.allow_workspace_cycles | tostring) + ",\n" else "" end ) +
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
    # WR-02: filter to matching entries via `test()` BEFORE `capture()` —
    # a bare `capture()` throws on any entry that doesn't match the
    # pattern, poisoning the whole `map()` and rejecting every mode for
    # this monitor over a single malformed/unexpected availableModes
    # entry (interlaced/stereo suffix, different case, etc.).
    printf '%s\n' "$available_json" | jq -e --arg sw "$sw" --arg sh "$sh" --arg sr "$sr" '
        map(
            select(test("^[0-9]+x[0-9]+@[0-9]+(\\.[0-9]+)?Hz$")) |
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

    # Review CR-03: a strict character allowlist BEFORE any use — matches
    # the threat model's own "closed allowlist" language. Every real
    # connector name (DP-1, HDMI-A-1, eDP-1, Unknown-1, ...) is
    # [A-Za-z0-9._-]; confirmed against this host's own `hyprctl monitors
    # -j .name` (DP-1). Membership-in-live-set (below) is the SECOND,
    # independent check — this one exists so a value that somehow passed
    # membership (a race, a compositor bug) still cannot carry a `"` or
    # backslash into the `hyprctl eval` Lua-string sink.
    [[ "$output" =~ ^[A-Za-z0-9._-]+$ ]] \
        || { echo "hypr-overrides.sh: output '$output' contains characters outside the closed allowlist" >&2; exit 1; }

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
    #    interpolation (T-SQD-01's whole mitigation). Review CR-03: escaped
    #    identically to how `_persist()`'s own `luastr` jq filter already
    #    escapes the SAME values before they reach the persisted Lua file —
    #    this eval call site was the one sink that had been missed. ───────
    hyprctl eval "return hl.monitor({ output = \"$(_luastr "$output")\", mode = \"$(_luastr "$final_mode")\", position = \"$(_luastr "$final_position")\", scale = $final_scale })" >/dev/null 2>&1

    # ── Verify against the JSON oracle — NEVER the `ok` reply
    #    (hypridle.conf:22-24's own finding, repeated verbatim in this
    #    plan's RESEARCH.md). Review CR-01: verify ONLY the field(s) this
    #    call actually asked to change (the ORIGINAL $mode/$position/$scale,
    #    not $final_*, which always holds a value via the current-live
    #    fallback and would make an unrequested field's check a tautology
    #    against itself). If none of the three flags were given at all
    #    (a bare re-apply of whatever is already live), verify all three —
    #    still a real check, since it confirms the eval call actually took
    #    effect rather than silently no-opping. ───────────────────────────
    sleep 0.3
    local live_json
    live_json=$(hyprctl monitors -j 2>/dev/null)
    local verify_ok=0
    local check_mode=0 check_position=0 check_scale=0
    if [[ -n "$mode" || ( -z "$mode" && -z "$position" && -z "$scale" ) ]]; then check_mode=1; fi
    if [[ -n "$position" || ( -z "$mode" && -z "$position" && -z "$scale" ) ]]; then check_position=1; fi
    if [[ -n "$scale" || ( -z "$mode" && -z "$position" && -z "$scale" ) ]]; then check_scale=1; fi

    if [[ "$check_mode" -eq 1 ]]; then
        local sw sh
        if [[ "$final_mode" =~ ^([0-9]+)x([0-9]+)@ ]]; then
            sw="${BASH_REMATCH[1]}"; sh="${BASH_REMATCH[2]}"
            printf '%s\n' "$live_json" | jq -e --arg o "$output" --arg w "$sw" --arg h "$sh" \
                '.[] | select(.name == $o) | ((.width|tostring) == $w and (.height|tostring) == $h)' >/dev/null 2>&1 \
                || verify_ok=1
        else
            verify_ok=1
        fi
    fi
    if [[ "$check_position" -eq 1 ]]; then
        printf '%s\n' "$live_json" | jq -e --arg o "$output" --arg pos "$final_position" \
            '.[] | select(.name == $o) | ((.x|tostring) + "x" + (.y|tostring)) == $pos' >/dev/null 2>&1 \
            || verify_ok=1
    fi
    if [[ "$check_scale" -eq 1 ]]; then
        printf '%s\n' "$live_json" | jq -e --arg o "$output" --argjson s "$final_scale" \
            '.[] | select(.name == $o) | .scale == $s' >/dev/null 2>&1 \
            || verify_ok=1
    fi
    if [[ "$verify_ok" -ne 0 ]]; then
        echo "hypr-overrides.sh: live apply did not verify against hyprctl monitors -j (mode=$check_mode position=$check_position scale=$check_scale)" >&2
        exit 1
    fi

    # ── Persist ONLY after the live apply is proven (T-SQD-03) ───────────
    local json
    json=$(_read_json_state | jq --arg o "$output" --arg mode "$final_mode" --arg pos "$final_position" --argjson scale "$final_scale" \
        '.monitors[$o] = { mode: $mode, position: $pos, scale: $scale }')
    _persist "$json" || exit 1
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

    # Fall back to current live values for any field not supplied. Review
    # WR-01: each fallback read is checked non-empty/well-formed before
    # use — an unchecked empty value here would make the `--argjson`
    # calls building `json` below fail, and `_persist("")` would silently
    # clobber the ENTIRE overrides file (including any prior monitor
    # settings) with an empty table. Fail closed instead: exit before
    # ever calling `hyprctl eval` or touching the persisted file.
    local final_kb="$kb_layout" final_fm="$follow_mouse" final_sens="$sensitivity" final_ns="$natural_scroll"
    [[ -n "$final_kb" ]] || final_kb=$(hyprctl getoption input:kb_layout -j 2>/dev/null | jq -r '.str')
    [[ -n "$final_fm" ]] || final_fm=$(hyprctl getoption input:follow_mouse -j 2>/dev/null | jq -r '.int')
    [[ -n "$final_sens" ]] || final_sens=$(hyprctl getoption input:sensitivity -j 2>/dev/null | jq -r '.float')
    # `hyprctl getoption` reports this SPECIFIC option under a `.bool` key,
    # not `.int` (measured live: `{"bool":true,"set":true}`, no `.int`
    # field at all) — a `.int == 1` read here always evaluated to the
    # literal string "false" regardless of the real value, found while
    # testing CR-02's fix (the old code never verified natural_scroll at
    # all, so this was silently masked until CR-02 added a real check).
    [[ -n "$final_ns" ]] || final_ns=$(hyprctl getoption input:touchpad:natural_scroll -j 2>/dev/null | jq -r '.bool')
    for _pair in "kb_layout:$final_kb" "follow_mouse:$final_fm" "sensitivity:$final_sens" "natural_scroll:$final_ns"; do
        local _fname="${_pair%%:*}" _fval="${_pair#*:}"
        [[ -n "$_fval" && "$_fval" != "null" ]] \
            || { echo "hypr-overrides.sh: could not read current live value for '$_fname' (hyprctl getoption failed?) — refusing to apply or persist" >&2; exit 1; }
    done

    # Escaped identically to `_persist()`'s own `luastr` filter (CR-03's
    # discipline extended here too, even though kb_layout's own regex
    # already forbids quote/backslash characters — defense in depth, no
    # cost). follow_mouse/sensitivity/natural_scroll are numeric/boolean
    # Lua literals, unquoted, never string-interpolated.
    hyprctl eval "return hl.config({ input = { kb_layout = \"$(_luastr "$final_kb")\", follow_mouse = $final_fm, sensitivity = $final_sens, touchpad = { natural_scroll = $final_ns } } })" >/dev/null 2>&1

    # Review CR-02: verify ONLY the field(s) this call actually asked to
    # change — the ORIGINAL $kb_layout/$follow_mouse/$sensitivity/
    # $natural_scroll, not $final_*, which always holds a value via the
    # current-live fallback and would make an unrequested field's check a
    # tautology. A bare `input` call with no flags at all verifies every
    # field, same reasoning as cmd_monitor above.
    sleep 0.3
    local verify_ok=0
    local bare_call=0
    [[ -z "$kb_layout" && -z "$follow_mouse" && -z "$sensitivity" && -z "$natural_scroll" ]] && bare_call=1

    if [[ -n "$kb_layout" || "$bare_call" -eq 1 ]]; then
        [[ "$(hyprctl getoption input:kb_layout -j 2>/dev/null | jq -r '.str')" == "$final_kb" ]] || verify_ok=1
    fi
    if [[ -n "$follow_mouse" || "$bare_call" -eq 1 ]]; then
        [[ "$(hyprctl getoption input:follow_mouse -j 2>/dev/null | jq -r '.int')" == "$final_fm" ]] || verify_ok=1
    fi
    if [[ -n "$sensitivity" || "$bare_call" -eq 1 ]]; then
        # Numeric comparison with tolerance, not exact string match: found
        # while testing this fix — `hyprctl getoption`'s `.float` formats
        # to 6 decimal places ("0.000000"), which never string-equals a
        # user-supplied "0.00" (or any value not already in that exact
        # shape) even when numerically identical. Same class of bug as
        # the `.bool`/`.int` field-name mismatch above, surfaced the same
        # way: the old code's sensitivity check was already exact-string,
        # just tautological before CR-02 made it a real check.
        local live_sens
        live_sens=$(hyprctl getoption input:sensitivity -j 2>/dev/null | jq -r '.float')
        awk -v a="$live_sens" -v b="$final_sens" 'BEGIN { exit !((a - b < 0 ? b - a : a - b) < 0.001) }' \
            || verify_ok=1
    fi
    if [[ -n "$natural_scroll" || "$bare_call" -eq 1 ]]; then
        [[ "$(hyprctl getoption input:touchpad:natural_scroll -j 2>/dev/null | jq -r '.bool')" == "$final_ns" ]] || verify_ok=1
    fi
    if [[ "$verify_ok" -ne 0 ]]; then
        echo "hypr-overrides.sh: live input apply did not verify against hyprctl getoption -j" >&2
        exit 1
    fi

    local json
    json=$(_read_json_state | jq --arg kb "$final_kb" --argjson fm "$final_fm" --argjson sens "$final_sens" --argjson ns "$final_ns" \
        '.input.kb_layout = $kb | .input.follow_mouse = $fm | .input.sensitivity = $sens | .input.touchpad.natural_scroll = $ns')
    _persist "$json" || exit 1
    echo "hypr-overrides.sh: input applied and persisted"
}

# Extracts the first whitespace-separated token of a `hyprctl getoption
# -j` reply's `.css` field ("5 5 5 5" -> "5") — `gaps_in`/`gaps_out`
# verify on this 4-tuple STRING field, never `.int` (RESEARCH.md's own
# finding, the same field-name bug class that already bit
# `input:touchpad:natural_scroll`'s `.bool`/`.int` mismatch).
_first_css_token() {
    printf '%s' "$1" | jq -r '.css' | awk '{print $1}'
}

# ── look subcommand (quick-260821-6z1 Task 4, D-03/R-2) ─────────────────
cmd_look() {
    local gaps_in="" gaps_out="" border_size="" gaps_workspaces=""
    local rounding="" blur_enabled="" blur_size="" blur_passes="" inactive_opacity="" shadow_enabled=""
    local wbf="" awc=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --gaps-in) gaps_in="$2"; shift 2 ;;
            --gaps-out) gaps_out="$2"; shift 2 ;;
            --border-size) border_size="$2"; shift 2 ;;
            --gaps-workspaces) gaps_workspaces="$2"; shift 2 ;;
            --rounding) rounding="$2"; shift 2 ;;
            --blur-enabled) blur_enabled="$2"; shift 2 ;;
            --blur-size) blur_size="$2"; shift 2 ;;
            --blur-passes) blur_passes="$2"; shift 2 ;;
            --inactive-opacity) inactive_opacity="$2"; shift 2 ;;
            --shadow-enabled) shadow_enabled="$2"; shift 2 ;;
            --workspace-back-and-forth) wbf="$2"; shift 2 ;;
            --allow-workspace-cycles) awc="$2"; shift 2 ;;
            *) echo "hypr-overrides.sh look: unknown flag $1" >&2; exit 1 ;;
        esac
    done

    # ── VALIDATE — a character-shape check independent of the numeric
    #    bound check, per every other subcommand's own discipline. ───────
    _bool_ok() { [[ "$1" == "true" || "$1" == "false" ]]; }
    _int_bounded() {
        local v="$1" lo="$2" hi="$3"
        [[ "$v" =~ ^[0-9]+$ ]] || return 1
        awk -v v="$v" -v lo="$lo" -v hi="$hi" 'BEGIN { exit !(v >= lo && v <= hi) }'
    }

    [[ -z "$gaps_in" ]]           || _int_bounded "$gaps_in" 0 30           || { echo "hypr-overrides.sh: gaps-in '$gaps_in' out of bounds [0,30]" >&2; exit 1; }
    [[ -z "$gaps_out" ]]          || _int_bounded "$gaps_out" 0 60          || { echo "hypr-overrides.sh: gaps-out '$gaps_out' out of bounds [0,60]" >&2; exit 1; }
    [[ -z "$border_size" ]]       || _int_bounded "$border_size" 0 10       || { echo "hypr-overrides.sh: border-size '$border_size' out of bounds [0,10]" >&2; exit 1; }
    [[ -z "$gaps_workspaces" ]]   || _int_bounded "$gaps_workspaces" 0 100  || { echo "hypr-overrides.sh: gaps-workspaces '$gaps_workspaces' out of bounds [0,100]" >&2; exit 1; }
    [[ -z "$rounding" ]]          || _int_bounded "$rounding" 0 30          || { echo "hypr-overrides.sh: rounding '$rounding' out of bounds [0,30]" >&2; exit 1; }
    [[ -z "$blur_size" ]]         || _int_bounded "$blur_size" 1 20         || { echo "hypr-overrides.sh: blur-size '$blur_size' out of bounds [1,20]" >&2; exit 1; }
    [[ -z "$blur_passes" ]]       || _int_bounded "$blur_passes" 1 5        || { echo "hypr-overrides.sh: blur-passes '$blur_passes' out of bounds [1,5]" >&2; exit 1; }
    [[ -z "$blur_enabled" ]]      || _bool_ok "$blur_enabled"               || { echo "hypr-overrides.sh: blur-enabled '$blur_enabled' not in {true,false}" >&2; exit 1; }
    [[ -z "$shadow_enabled" ]]    || _bool_ok "$shadow_enabled"             || { echo "hypr-overrides.sh: shadow-enabled '$shadow_enabled' not in {true,false}" >&2; exit 1; }
    [[ -z "$wbf" ]]               || _bool_ok "$wbf"                       || { echo "hypr-overrides.sh: workspace-back-and-forth '$wbf' not in {true,false}" >&2; exit 1; }
    [[ -z "$awc" ]]               || _bool_ok "$awc"                       || { echo "hypr-overrides.sh: allow-workspace-cycles '$awc' not in {true,false}" >&2; exit 1; }
    if [[ -n "$inactive_opacity" ]]; then
        [[ "$inactive_opacity" =~ ^[0-9]+(\.[0-9]+)?$ ]] \
            || { echo "hypr-overrides.sh: inactive-opacity '$inactive_opacity' is not numeric" >&2; exit 1; }
        awk -v v="$inactive_opacity" 'BEGIN { exit !(v >= 0.5 && v <= 1.0) }' \
            || { echo "hypr-overrides.sh: inactive-opacity '$inactive_opacity' out of bounds [0.5,1.0]" >&2; exit 1; }
    fi

    # ── Fall back to current live values for any field not supplied
    #    (cmd_input's own WR-01 discipline: every fallback read is
    #    checked non-empty/well-formed BEFORE use, since an unchecked
    #    empty value would make the eval/persist calls below silently
    #    clobber the entire overrides file). ───────────────────────────
    local final_gaps_in="$gaps_in" final_gaps_out="$gaps_out" final_border_size="$border_size" final_gaps_workspaces="$gaps_workspaces"
    local final_rounding="$rounding" final_blur_enabled="$blur_enabled" final_blur_size="$blur_size" final_blur_passes="$blur_passes"
    local final_inactive_opacity="$inactive_opacity" final_shadow_enabled="$shadow_enabled"
    local final_wbf="$wbf" final_awc="$awc"

    [[ -n "$final_gaps_in" ]]           || final_gaps_in=$(_first_css_token "$(hyprctl getoption general:gaps_in -j 2>/dev/null)")
    [[ -n "$final_gaps_out" ]]          || final_gaps_out=$(_first_css_token "$(hyprctl getoption general:gaps_out -j 2>/dev/null)")
    [[ -n "$final_border_size" ]]       || final_border_size=$(hyprctl getoption general:border_size -j 2>/dev/null | jq -r '.int')
    [[ -n "$final_gaps_workspaces" ]]   || final_gaps_workspaces=$(hyprctl getoption general:gaps_workspaces -j 2>/dev/null | jq -r '.int')
    [[ -n "$final_rounding" ]]          || final_rounding=$(hyprctl getoption decoration:rounding -j 2>/dev/null | jq -r '.int')
    [[ -n "$final_blur_enabled" ]]      || final_blur_enabled=$(hyprctl getoption decoration:blur:enabled -j 2>/dev/null | jq -r '.bool')
    [[ -n "$final_blur_size" ]]         || final_blur_size=$(hyprctl getoption decoration:blur:size -j 2>/dev/null | jq -r '.int')
    [[ -n "$final_blur_passes" ]]       || final_blur_passes=$(hyprctl getoption decoration:blur:passes -j 2>/dev/null | jq -r '.int')
    [[ -n "$final_inactive_opacity" ]]  || final_inactive_opacity=$(hyprctl getoption decoration:inactive_opacity -j 2>/dev/null | jq -r '.float')
    [[ -n "$final_shadow_enabled" ]]    || final_shadow_enabled=$(hyprctl getoption decoration:shadow:enabled -j 2>/dev/null | jq -r '.bool')
    [[ -n "$final_wbf" ]]               || final_wbf=$(hyprctl getoption binds:workspace_back_and_forth -j 2>/dev/null | jq -r '.bool')
    [[ -n "$final_awc" ]]               || final_awc=$(hyprctl getoption binds:allow_workspace_cycles -j 2>/dev/null | jq -r '.bool')

    for _pair in "gaps_in:$final_gaps_in" "gaps_out:$final_gaps_out" "border_size:$final_border_size" \
                 "gaps_workspaces:$final_gaps_workspaces" "rounding:$final_rounding" "blur_enabled:$final_blur_enabled" \
                 "blur_size:$final_blur_size" "blur_passes:$final_blur_passes" "inactive_opacity:$final_inactive_opacity" \
                 "shadow_enabled:$final_shadow_enabled" "workspace_back_and_forth:$final_wbf" "allow_workspace_cycles:$final_awc"; do
        local _fname="${_pair%%:*}" _fval="${_pair#*:}"
        [[ -n "$_fval" && "$_fval" != "null" ]] \
            || { echo "hypr-overrides.sh: could not read current live value for '$_fname' (hyprctl getoption failed?) — refusing to apply or persist" >&2; exit 1; }
    done

    # ── APPLY LIVE — one combined hl.config call, every field a numeric
    #    or boolean Lua literal (none need _luastr — no strings here). ───
    hyprctl eval "return hl.config({ general = { gaps_in = $final_gaps_in, gaps_out = $final_gaps_out, border_size = $final_border_size, gaps_workspaces = $final_gaps_workspaces }, decoration = { rounding = $final_rounding, inactive_opacity = $final_inactive_opacity, blur = { enabled = $final_blur_enabled, size = $final_blur_size, passes = $final_blur_passes }, shadow = { enabled = $final_shadow_enabled } }, binds = { workspace_back_and_forth = $final_wbf, allow_workspace_cycles = $final_awc } })" >/dev/null 2>&1

    # ── VERIFY — ONLY the fields THIS call actually asked to change; a
    #    bare call with no flags at all verifies every field (still a
    #    real check: confirms the eval call took effect at all). ────────
    sleep 0.3
    local verify_ok=0
    local bare_call=0
    [[ -z "$gaps_in$gaps_out$border_size$gaps_workspaces$rounding$blur_enabled$blur_size$blur_passes$inactive_opacity$shadow_enabled$wbf$awc" ]] && bare_call=1

    if [[ -n "$gaps_in" || "$bare_call" -eq 1 ]]; then
        [[ "$(_first_css_token "$(hyprctl getoption general:gaps_in -j 2>/dev/null)")" == "$final_gaps_in" ]] || verify_ok=1
    fi
    if [[ -n "$gaps_out" || "$bare_call" -eq 1 ]]; then
        [[ "$(_first_css_token "$(hyprctl getoption general:gaps_out -j 2>/dev/null)")" == "$final_gaps_out" ]] || verify_ok=1
    fi
    if [[ -n "$border_size" || "$bare_call" -eq 1 ]]; then
        [[ "$(hyprctl getoption general:border_size -j 2>/dev/null | jq -r '.int')" == "$final_border_size" ]] || verify_ok=1
    fi
    if [[ -n "$gaps_workspaces" || "$bare_call" -eq 1 ]]; then
        [[ "$(hyprctl getoption general:gaps_workspaces -j 2>/dev/null | jq -r '.int')" == "$final_gaps_workspaces" ]] || verify_ok=1
    fi
    if [[ -n "$rounding" || "$bare_call" -eq 1 ]]; then
        [[ "$(hyprctl getoption decoration:rounding -j 2>/dev/null | jq -r '.int')" == "$final_rounding" ]] || verify_ok=1
    fi
    if [[ -n "$blur_enabled" || "$bare_call" -eq 1 ]]; then
        [[ "$(hyprctl getoption decoration:blur:enabled -j 2>/dev/null | jq -r '.bool')" == "$final_blur_enabled" ]] || verify_ok=1
    fi
    if [[ -n "$blur_size" || "$bare_call" -eq 1 ]]; then
        [[ "$(hyprctl getoption decoration:blur:size -j 2>/dev/null | jq -r '.int')" == "$final_blur_size" ]] || verify_ok=1
    fi
    if [[ -n "$blur_passes" || "$bare_call" -eq 1 ]]; then
        [[ "$(hyprctl getoption decoration:blur:passes -j 2>/dev/null | jq -r '.int')" == "$final_blur_passes" ]] || verify_ok=1
    fi
    if [[ -n "$inactive_opacity" || "$bare_call" -eq 1 ]]; then
        local live_op
        live_op=$(hyprctl getoption decoration:inactive_opacity -j 2>/dev/null | jq -r '.float')
        awk -v a="$live_op" -v b="$final_inactive_opacity" 'BEGIN { exit !((a - b < 0 ? b - a : a - b) < 0.001) }' \
            || verify_ok=1
    fi
    if [[ -n "$shadow_enabled" || "$bare_call" -eq 1 ]]; then
        [[ "$(hyprctl getoption decoration:shadow:enabled -j 2>/dev/null | jq -r '.bool')" == "$final_shadow_enabled" ]] || verify_ok=1
    fi
    if [[ -n "$wbf" || "$bare_call" -eq 1 ]]; then
        [[ "$(hyprctl getoption binds:workspace_back_and_forth -j 2>/dev/null | jq -r '.bool')" == "$final_wbf" ]] || verify_ok=1
    fi
    if [[ -n "$awc" || "$bare_call" -eq 1 ]]; then
        [[ "$(hyprctl getoption binds:allow_workspace_cycles -j 2>/dev/null | jq -r '.bool')" == "$final_awc" ]] || verify_ok=1
    fi
    if [[ "$verify_ok" -ne 0 ]]; then
        echo "hypr-overrides.sh: live look apply did not verify against hyprctl getoption -j" >&2
        exit 1
    fi

    # ── PERSIST ONLY after the live apply is proven ──────────────────────
    local json
    json=$(_read_json_state | jq \
        --argjson gi "$final_gaps_in" --argjson go "$final_gaps_out" --argjson bs "$final_border_size" --argjson gw "$final_gaps_workspaces" \
        --argjson ro "$final_rounding" --argjson io "$final_inactive_opacity" \
        --argjson be "$final_blur_enabled" --argjson bsz "$final_blur_size" --argjson bp "$final_blur_passes" \
        --argjson se "$final_shadow_enabled" --argjson wbf "$final_wbf" --argjson awc "$final_awc" \
        '.general.gaps_in = $gi | .general.gaps_out = $go | .general.border_size = $bs | .general.gaps_workspaces = $gw
         | .decoration.rounding = $ro | .decoration.inactive_opacity = $io
         | .decoration.blur.enabled = $be | .decoration.blur.size = $bsz | .decoration.blur.passes = $bp
         | .decoration.shadow.enabled = $se
         | .binds.workspace_back_and_forth = $wbf | .binds.allow_workspace_cycles = $awc')
    _persist "$json" || exit 1
    echo "hypr-overrides.sh: look applied and persisted"
}

main() {
    local sub="${1:-}"
    [[ -n "$sub" ]] || { echo "Usage: hypr-overrides.sh <monitor|input|look> ..." >&2; exit 1; }
    shift
    case "$sub" in
        monitor) cmd_monitor "$@" ;;
        input) cmd_input "$@" ;;
        look) cmd_look "$@" ;;
        *) echo "hypr-overrides.sh: unknown subcommand '$sub'" >&2; exit 1 ;;
    esac
}

main "$@"
