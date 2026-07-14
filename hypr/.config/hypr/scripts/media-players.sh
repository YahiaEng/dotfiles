#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║   MEDIA PLAYER ALLOWLIST + CONTROL DISPATCHER (D-21/25) ║
# ║  HARD CONSTRAINT: a player's D-Bus bus name is          ║
# ║  attacker-influenced. It is the ONLY metadata-derived   ║
# ║  string this repo ever allows near a command invocation ║
# ║  — validated once, here, by `_valid_id`, and nowhere    ║
# ║  else. This file is the ONLY place playerctl is ever    ║
# ║  invoked for a mutating action.                         ║
# ╚══════════════════════════════════════════════════════╝
#
# CLI:
#   media-players.sh list              -> JSON array [{id,label,active}], always exit 0
#   media-players.sh active            -> effective player id + exit 0, or empty + exit 1 (D-25 gate)
#   media-players.sh select <id>       -> persist selection, exit 0; exit 2 on invalid id
#   media-players.sh cmd <id> <verb> [numeric-arg]
#                                       -> argv-form playerctl invocation; exit 2 on any
#                                          validation failure (no playerctl call is ever made)
#
# State file: ~/.cache/eww-media-player ("<id>"), owned exclusively by `select`.

set -euo pipefail

SELECTED_FILE="$HOME/.cache/eww-media-player"

# _valid_id <candidate> — the sole gate for T-08-07-02. A bash [[ =~ ]]
# regex test: no subshell, no external command, never re-parses the
# candidate as code.
_valid_id() {
    [[ "$1" =~ ^[A-Za-z0-9._-]{1,128}$ ]]
}

# _valid_ids — playerctl -l output, one id per line, filtered through
# _valid_id. Any hostile/malformed id is silently dropped here and
# never appears again in this script.
_valid_ids() {
    local line
    # `|| [[ -n "$line" ]]` is deliberate: `read` returns non-zero on
    # the final line if the producer's output doesn't end in a
    # trailing newline (a real, if rare, edge case for any external
    # tool's stdout) — without this, that last line is silently
    # dropped rather than validated.
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -n "$line" ]] || continue
        if _valid_id "$line"; then
            printf '%s\n' "$line"
        fi
    done < <(playerctl -l 2>/dev/null || true)
}

# _effective_id — the id in $SELECTED_FILE if it is still a valid,
# currently-live id; otherwise the first valid live id; otherwise
# nothing. Shared by `list` (active-marker) and `active` (D-25 gate).
_effective_id() {
    local ids saved found=""
    ids="$(_valid_ids)"
    if [[ -z "$ids" ]]; then
        printf ''
        return
    fi

    saved="$(cat "$SELECTED_FILE" 2>/dev/null || true)"
    if [[ -n "$saved" ]] && _valid_id "$saved"; then
        while IFS= read -r line; do
            if [[ "$line" == "$saved" ]]; then
                found="$saved"
                break
            fi
        done <<<"$ids"
    fi

    if [[ -z "$found" ]]; then
        found="$(head -n1 <<<"$ids")"
    fi
    printf '%s' "$found"
}

# _label_for <id> — UI-SPEC Copywriting Contract: strip a trailing
# `.instance_<digits>` suffix, then capitalise the first character.
# Never shows the raw D-Bus instance string.
_label_for() {
    local id="$1" stripped first rest
    # Strip a literal trailing `.instance_<digits[_digits]>` suffix if
    # present (bash regex match, no extglob dependency). Real-world
    # form observed live on this machine is `.instance_1_201`
    # (underscore-joined digit groups), not a single digit run.
    if [[ "$id" =~ ^(.*)\.instance_[0-9_]+$ ]]; then
        stripped="${BASH_REMATCH[1]}"
    else
        stripped="$id"
    fi
    first="${stripped:0:1}"
    rest="${stripped:1}"
    printf '%s%s' "${first^^}" "$rest"
}

cmd_list() {
    local ids active_id id label is_active out="[]"
    ids="$(_valid_ids)"
    active_id="$(_effective_id)"

    if [[ -z "$ids" ]]; then
        printf '[]\n'
        return 0
    fi

    out="[]"
    while IFS= read -r id; do
        [[ -n "$id" ]] || continue
        label="$(_label_for "$id")"
        if [[ "$id" == "$active_id" ]]; then
            is_active=true
        else
            is_active=false
        fi
        out="$(jq -n -c --argjson acc "$out" --arg id "$id" --arg label "$label" --argjson active "$is_active" \
            '$acc + [{id: $id, label: $label, active: $active}]')"
    done <<<"$ids"

    printf '%s\n' "$out"
    return 0
}

cmd_active() {
    local id
    id="$(_effective_id)"
    if [[ -z "$id" ]]; then
        return 1
    fi
    printf '%s\n' "$id"
    return 0
}

cmd_select() {
    local id="${1-}"
    if [[ -z "$id" ]] || ! _valid_id "$id"; then
        return 2
    fi
    printf '%s\n' "$id" >"$SELECTED_FILE.tmp" && mv "$SELECTED_FILE.tmp" "$SELECTED_FILE"
    return 0
}

cmd_cmd() {
    local id="${1-}" action="${2-}" arg="${3-}"

    if [[ -z "$id" ]] || ! _valid_id "$id"; then
        return 2
    fi

    case "$action" in
        play-pause | next | previous)
            playerctl --player="$id" "$action" 2>/dev/null || true
            return 0
            ;;
        seek | volume)
            if [[ -z "$arg" ]] || [[ ! "$arg" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                return 2
            fi
            if [[ "$action" == "seek" ]]; then
                playerctl --player="$id" position "$arg" 2>/dev/null || true
            else
                playerctl --player="$id" volume "$arg" 2>/dev/null || true
            fi
            return 0
            ;;
        *)
            # Anything outside the literal allowlist — no playerctl call.
            return 2
            ;;
    esac
}

main() {
    local subcmd="${1-}"
    shift || true

    case "$subcmd" in
        list)
            cmd_list
            ;;
        active)
            cmd_active
            ;;
        select)
            cmd_select "${1-}"
            ;;
        cmd)
            cmd_cmd "${1-}" "${2-}" "${3-}"
            ;;
        *)
            echo "Usage: $(basename -- "$0") {list|active|select <id>|cmd <id> <verb> [arg]}" >&2
            exit 2
            ;;
    esac
}

main "$@"
