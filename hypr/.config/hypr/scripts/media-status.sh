#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║      MEDIA STATUS JSON EMITTER (D-21/25, T-08-07-01)    ║
# ║  HARD CONSTRAINT: every string field originates in a    ║
# ║  third-party player and is emitted through `jq --arg`   ║
# ║  — never through string concatenation, never into a     ║
# ║  shell command. This is the eww `deflisten` payload     ║
# ║  contract; one JSON object per line, always.            ║
# ╚══════════════════════════════════════════════════════╝
#
# CLI:
#   media-status.sh once     -> one JSON line (the payload contract), exit 0
#   media-status.sh watch    -> loop forever; print only on change (deflisten source)
#   media-status.sh position -> {"position":N,"length":M} only (reserved, lower-cost poll)
#
# Payload contract (one line, jq -c):
#   player, label, status, title, artist, album, art, position, length,
#   volume, can_seek
#
# `player`/`label` are sourced exclusively from media-players.sh
# (already validated there by _valid_id) — this script never invokes
# playerctl with a mutating verb; every playerctl call below is a
# read-only query.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
MEDIA_PLAYERS="$SCRIPT_DIR/media-players.sh"
MEDIA_ART_RESOLVE="$SCRIPT_DIR/media-art-resolve.sh"

# CONTEXT grants polling-strategy discretion to Claude. A 1 Hz
# change-detected poll is chosen over a `playerctl -F` follower
# because re-targeting on a player switch is then free — each tick
# simply re-reads the current selection via media-players.sh active.
POLL_INTERVAL=1

_empty_payload() {
    jq -c -n \
        --arg player "" --arg label "" --arg status "" --arg title "" \
        --arg artist "" --arg album "" --arg art "" \
        --argjson position 0 --argjson length 0 --argjson volume -1 --argjson can_seek false \
        '{player:$player, label:$label, status:$status, title:$title, artist:$artist,
          album:$album, art:$art, position:$position, length:$length,
          volume:$volume, can_seek:$can_seek}'
}

# _sanitize <raw> — strip C0 control chars + newlines (closes the
# deflisten line-desync vector, T-08-07-07), then truncate to 200
# chars. This is the ONLY transformation applied to untrusted text;
# it never re-parses the string as code.
_sanitize() {
    local raw="$1" clean
    clean="$(tr -d '\000-\037' <<<"$raw")"
    printf '%s' "${clean:0:200}"
}

cmd_once() {
    local player label status title artist album art_url art
    local length_us length position_f position volume can_seek

    player="$("$MEDIA_PLAYERS" active 2>/dev/null || true)"
    if [[ -z "$player" ]]; then
        _empty_payload
        return 0
    fi

    label="$("$MEDIA_PLAYERS" list 2>/dev/null | jq -r --arg id "$player" \
        '(.[] | select(.id == $id) | .label) // ""' 2>/dev/null || true)"

    status="$(playerctl --player="$player" status 2>/dev/null || true)"
    title="$(playerctl --player="$player" metadata xesam:title 2>/dev/null || true)"
    artist="$(playerctl --player="$player" metadata xesam:artist 2>/dev/null || true)"
    album="$(playerctl --player="$player" metadata xesam:album 2>/dev/null || true)"
    art_url="$(playerctl --player="$player" metadata mpris:artUrl 2>/dev/null || true)"
    length_us="$(playerctl --player="$player" metadata mpris:length 2>/dev/null || true)"
    position_f="$(playerctl --player="$player" position 2>/dev/null || true)"
    volume="$(playerctl --player="$player" volume 2>/dev/null || true)"

    title="$(_sanitize "$title")"
    artist="$(_sanitize "$artist")"
    album="$(_sanitize "$album")"
    label="$(_sanitize "$label")"
    status="$(_sanitize "$status")"

    art=""
    if [[ -n "$art_url" ]]; then
        art="$("$MEDIA_ART_RESOLVE" "$art_url" 2>/dev/null || true)"
    fi

    # length: mpris:length is microseconds; integer-divide down to
    # seconds. 0 when absent or non-numeric.
    if [[ "$length_us" =~ ^[0-9]+$ ]]; then
        length=$((length_us / 1000000))
    else
        length=0
    fi

    # position: playerctl's float seconds, rounded down to an integer.
    if [[ "$position_f" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        position="${position_f%%.*}"
    else
        position=0
    fi

    # volume: playerctl's float 0-1, or -1 when the player exposes no
    # volume property (empty output) — tells the widget to hide the
    # slider row entirely (a player capability limit, not a D-21
    # descope).
    if [[ "$volume" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        : # keep as-is, passed through --argjson below
    else
        volume="-1"
    fi

    # can_seek: playerctl/mpris expose no direct CLI surface for the
    # MPRIS `CanSeek` property (RESEARCH did not verify one). Used as
    # a documented heuristic: a nonzero length implies the track is
    # seekable in practice for every player observed on this machine.
    if [[ "$length" -gt 0 ]]; then
        can_seek=true
    else
        can_seek=false
    fi

    jq -c -n \
        --arg player "$player" --arg label "$label" --arg status "$status" \
        --arg title "$title" --arg artist "$artist" --arg album "$album" \
        --arg art "$art" \
        --argjson position "$position" --argjson length "$length" \
        --argjson volume "$volume" --argjson can_seek "$can_seek" \
        '{player:$player, label:$label, status:$status, title:$title, artist:$artist,
          album:$album, art:$art, position:$position, length:$length,
          volume:$volume, can_seek:$can_seek}'
    return 0
}

cmd_watch() {
    local last="" cur
    while true; do
        cur="$(cmd_once 2>/dev/null || true)"
        if [[ -n "$cur" && "$cur" != "$last" ]]; then
            printf '%s\n' "$cur"
            last="$cur"
        fi
        sleep "$POLL_INTERVAL"
    done
}

cmd_position() {
    local player position_f length_us length position
    player="$("$MEDIA_PLAYERS" active 2>/dev/null || true)"
    if [[ -z "$player" ]]; then
        jq -c -n --argjson position 0 --argjson length 0 '{position:$position, length:$length}'
        return 0
    fi

    position_f="$(playerctl --player="$player" position 2>/dev/null || true)"
    length_us="$(playerctl --player="$player" metadata mpris:length 2>/dev/null || true)"

    if [[ "$position_f" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        position="${position_f%%.*}"
    else
        position=0
    fi
    if [[ "$length_us" =~ ^[0-9]+$ ]]; then
        length=$((length_us / 1000000))
    else
        length=0
    fi

    jq -c -n --argjson position "$position" --argjson length "$length" '{position:$position, length:$length}'
    return 0
}

main() {
    local subcmd="${1-}"
    case "$subcmd" in
        once)
            cmd_once
            ;;
        watch)
            cmd_watch
            ;;
        position)
            cmd_position
            ;;
        *)
            echo "Usage: $(basename -- "$0") {once|watch|position}" >&2
            exit 2
            ;;
    esac
}

main "$@"
