#!/usr/bin/env bash
# record-toggle.sh — toggle screen/region recording via gpu-screen-recorder
# with an explicit audio picker and NVENC hardware encode + cpu fallback
# (SHOT-03, D-03/D-04/D-06/D-07/D-08).
#
# Structure adapted from the Omarchy reference implementation
# (raw.githubusercontent.com/basecamp/omarchy/master/bin/omarchy-capture-screenrecording,
# fetched live this session since gpu-screen-recorder is not yet installed
# on this dev machine): slurp monitor/region picker with a hyprpicker
# freeze, the exact `-k auto -f 60 -fm cfr -fallback-cpu-encoding yes`
# gpu-screen-recorder invocation, and the SIGINT-then-bounded-5s-poll-
# then-SIGKILL stop idiom (mirrors this repo's existing reload.sh/gtk.sh
# bounded-poll convention). Diverges from the Omarchy reference for:
#   - D-06: an explicit walker --dmenu audio picker (silent/desktop/
#     desktop+mic) runs BEFORE region/monitor select, reusing theme-
#     switch.sh's exit-code-130 cancel pattern verbatim — Omarchy takes
#     audio mode as CLI flags instead.
#   - D-04: GIF export is a notification action calling the separate
#     gif-export.sh, not a synchronous ffmpeg finalize step.
#   - No webcam overlay (out of scope this phase) and no bar-status
#     indicator toggle (Phase 8) — see recording_active() below for the
#     pgrep status probe a future bar module could read.
set -euo pipefail

VIDEOS_DIR="$HOME/Videos"
mkdir -p "$VIDEOS_DIR"

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
RECORDING_FILE="$RUNTIME_DIR/record-toggle-filename"
LOG_FILE="$RUNTIME_DIR/record-toggle.log"

# Status probe for a future bar recording indicator: while a
# recording is active, `pgrep -f "^gpu-screen-recorder "` (note the
# trailing space, bounding the match to argv[0]) is truthy — no other
# state file needed for a simple running/not-running check. WR-05: the
# unbounded prefix `^gpu-screen-recorder` also matched sibling binaries
# (gpu-screen-recorder-ui/-gtk/-notification); the trailing space is safe
# because this script always invokes the recorder with arguments.
recording_active() {
    pgrep -f "^gpu-screen-recorder " >/dev/null 2>&1
}

# Security Domain T-06-09: truncate + strip control chars before any
# subprocess error text reaches notify-send.
sanitize() {
    head -c 200 | tr -d '\000-\011\013\014\016-\037'
}

stop_recording() {
    pkill -SIGINT -f "^gpu-screen-recorder " 2>/dev/null || true

    # Bounded 5s poll then SIGKILL — mirrors this repo's existing
    # reload.sh/gtk.sh bounded-poll idiom.
    local count=0
    while pgrep -f "^gpu-screen-recorder " >/dev/null 2>&1 && ((count < 50)); do
        sleep 0.1
        count=$((count + 1))
    done
    if pgrep -f "^gpu-screen-recorder " >/dev/null 2>&1; then
        pkill -9 -f "^gpu-screen-recorder " 2>/dev/null || true
    fi

    local filename
    filename=$(cat "$RECORDING_FILE" 2>/dev/null || true)
    rm -f "$RECORDING_FILE"

    if [[ -n "$filename" && -f "$filename" ]]; then
        # Backgrounded: notify-send -A blocks on the user's action choice
        # until they click or the notification times out — must not hang
        # this script (mirrors Omarchy's own backgrounded subshell here).
        (
            action=$(notify-send -a "Screen Recorder" "Recording Saved" "Saved to $filename" \
                -i media-record -t 3000 \
                -A "open=Open" -A "gif=Export GIF" 2>/dev/null) || true
            case "$action" in
                open) xdg-open "$filename" 2>/dev/null || true ;;
                gif) ~/.config/hypr/scripts/gif-export.sh "$filename" & ;;
            esac
        ) &
        disown
    fi
}

# D-06: explicit audio picker BEFORE region/monitor select — never
# capture audio without an explicit user choice. Sets the global
# AUDIO_DEVICES var (empty = silent, omit -a entirely). Must be called
# as a plain function (not via command substitution) so its `exit` calls
# on cancel/failure actually terminate the script, not just a subshell.
AUDIO_DEVICES=""
pick_audio() {
    local rc=0
    local selected
    selected=$(printf '%s\n' \
        "🔇 Silent (no audio)" \
        "🔊 Desktop Audio" \
        "🎙️ Desktop + Mic" |
        walker --dmenu --placeholder "Select Recording Audio") || rc=$?
    # walker 2.16.2 cancel convention (Esc/click-outside) is exit 130 —
    # reused verbatim from theme-switch.sh (D-06).
    if ((rc == 130)); then
        exit 0
    elif ((rc != 0)); then
        notify-send -a "Screen Recorder" "Error" "walker dmenu failed" -i dialog-error 2>/dev/null || true
        exit 1
    fi
    [[ -z "$selected" ]] && exit 0

    case "$selected" in
        "🔇 Silent (no audio)") AUDIO_DEVICES="" ;;
        "🔊 Desktop Audio") AUDIO_DEVICES="default_output" ;;
        "🎙️ Desktop + Mic") AUDIO_DEVICES="default_output|default_input" ;;
        *) exit 1 ;;
    esac
}

# Monitor + window rectangles on the focused workspace, slurp's "X,Y WxH"
# format — copied verbatim from the Omarchy reference so the region/
# monitor-snap UX matches the tool this repo is adapting.
get_rectangles() {
    local active_workspace
    active_workspace=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .activeWorkspace.id')
    hyprctl monitors -j | jq -r --arg ws "$active_workspace" '
        .[] | select(.activeWorkspace.id == ($ws | tonumber)) |
        "\(.x),\(.y) \(.width / .scale | floor)x\(.height / .scale | floor)"'
    hyprctl clients -j | jq -r --arg ws "$active_workspace" '
        .[] | select(.workspace.id == ($ws | tonumber)) |
        "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

# Echoes "monitor:NAME" when the selection matches an entire monitor,
# otherwise "region:WxH+X+Y". Returns non-zero if the user cancelled.
select_capture_target() {
    local rects
    rects=$(get_rectangles)
    hyprpicker -r -z >/dev/null 2>&1 &
    local picker_pid=$!
    sleep 0.1
    local selection
    selection=$(echo "$rects" | slurp 2>/dev/null) || true
    kill "$picker_pid" 2>/dev/null || true

    [[ $selection =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]] || return 1
    local sx=${BASH_REMATCH[1]} sy=${BASH_REMATCH[2]}
    local sw=${BASH_REMATCH[3]} sh=${BASH_REMATCH[4]}

    # A bare click (area < 20px^2) snaps to whichever rectangle the click
    # landed inside, avoiding accidental 2px recordings.
    if ((sw * sh < 20)); then
        while IFS= read -r rect; do
            [[ $rect =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]] || continue
            local rx=${BASH_REMATCH[1]} ry=${BASH_REMATCH[2]}
            local rw=${BASH_REMATCH[3]} rh=${BASH_REMATCH[4]}
            if ((sx >= rx && sx < rx + rw && sy >= ry && sy < ry + rh)); then
                sx=$rx sy=$ry sw=$rw sh=$rh
                break
            fi
        done <<<"$rects"
    fi

    local monitor
    monitor=$(hyprctl monitors -j | jq -r --argjson x "$sx" --argjson y "$sy" --argjson w "$sw" --argjson h "$sh" '
        .[] | select(.x == $x and .y == $y and (.width / .scale | floor) == $w and (.height / .scale | floor) == $h) | .name' | head -1)

    if [[ -n "$monitor" ]]; then
        echo "monitor:$monitor"
        return
    fi

    echo "region:${sw}x${sh}+${sx}+${sy}"
}

start_recording() {
    pick_audio

    local target
    target=$(select_capture_target) || exit 0 # user cancelled slurp

    local capture_args=()
    case "$target" in
        monitor:*) capture_args=(-w "${target#monitor:}") ;;
        region:*) capture_args=(-w region -region "${target#region:}") ;;
    esac

    local audio_args=()
    # D-06: silent omits the -a flag entirely — never capture audio
    # without an explicit selection.
    [[ -n "$AUDIO_DEVICES" ]] && audio_args=(-a "$AUDIO_DEVICES" -ac aac)

    local filename
    filename="$VIDEOS_DIR/recording_$(date +%Y%m%d_%H%M%S).mp4"
    : >"$LOG_FILE"

    gpu-screen-recorder "${capture_args[@]}" -k auto -f 60 -fm cfr \
        -fallback-cpu-encoding yes -o "$filename" "${audio_args[@]}" \
        >/dev/null 2>>"$LOG_FILE" &
    local pid=$!

    # Wait until either the output file appears (recorder is up) or the
    # process dies (start failure) — unbounded, matching the Omarchy
    # reference; GPU encoder init is near-instant so this never hangs in
    # practice, and a genuine hang is a gpu-screen-recorder bug, not
    # something to paper over with an arbitrary timeout here.
    while kill -0 "$pid" 2>/dev/null && [[ ! -f "$filename" ]]; do
        sleep 0.2
    done

    if kill -0 "$pid" 2>/dev/null; then
        echo "$filename" >"$RECORDING_FILE"
        notify-send -a "Screen Recorder" "Recording Started" "Press Alt+Print to stop" \
            -i media-record -t 2500
    else
        local err
        err=$(sanitize <"$LOG_FILE")
        notify-send -a "Screen Recorder" "Error" "Recording failed to start: $err" \
            -i dialog-error -t 6000 2>/dev/null || true
        exit 1
    fi
}

if recording_active; then
    stop_recording
else
    start_recording
fi
