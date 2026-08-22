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

# ── Recording defaults (quick-260821-6z1 Task 10, R-6/PD-05) — bounded to
#    the three values that were previously literals in the single
#    gpu-screen-recorder invocation (fps, codec) plus the audio mode that
#    was previously re-asked interactively on EVERY recording (audio).
#    Container, capture-target selection, the CPU-fallback flag and the
#    notification/GIF pipeline are all untouched — this is bounded flag
#    plumbing, not a script redesign. Absent file degrades to exactly
#    today's literals (60/auto/ask — "ask" preserves the interactive
#    walker prompt this script always ran before this task). ────────────
RECORD_DEFAULTS_STATE="$HOME/.local/state/hypr/record-defaults.json"

_read_defaults() {
    if [[ -s "$RECORD_DEFAULTS_STATE" ]] && jq -e . "$RECORD_DEFAULTS_STATE" >/dev/null 2>&1; then
        cat "$RECORD_DEFAULTS_STATE"
    else
        echo '{"fps":60,"codec":"auto","audio":"ask"}'
    fi
}

cmd_get_defaults() {
    _read_defaults
}

# Closed enumeration per key — an unknown key or an unenumerated value
# exits non-zero and writes nothing, never trusting the argument as free
# text. `fps`/`codec` are gpu-screen-recorder's own documented value sets
# (the binary is not installed on this dev host — see this file's own
# header — so these are its documented CLI vocabulary, not a live probe);
# `audio` mirrors pick_audio()'s own three interactive choices plus
# "ask" for today's per-recording prompt.
cmd_set_default() {
    local key="${1:-}" value="${2:-}"
    [[ -n "$key" && -n "$value" ]] \
        || { echo "record-toggle.sh set-default: usage: set-default <key> <value>" >&2; exit 1; }

    case "$key" in
        fps)
            case "$value" in
                24|30|60|120) ;;
                *) echo "record-toggle.sh: fps '$value' not in {24,30,60,120}" >&2; exit 1 ;;
            esac
            ;;
        codec)
            case "$value" in
                auto|h264|hevc|av1|vp8|vp9) ;;
                *) echo "record-toggle.sh: codec '$value' not in {auto,h264,hevc,av1,vp8,vp9}" >&2; exit 1 ;;
            esac
            ;;
        audio)
            case "$value" in
                silent|desktop|desktop+mic|ask) ;;
                *) echo "record-toggle.sh: audio '$value' not in {silent,desktop,desktop+mic,ask}" >&2; exit 1 ;;
            esac
            ;;
        *)
            echo "record-toggle.sh: set-default: unknown key '$key' (expected fps|codec|audio)" >&2
            exit 1
            ;;
    esac

    mkdir -p "$(dirname "$RECORD_DEFAULTS_STATE")"
    local json
    if [[ "$key" == "fps" ]]; then
        json=$(_read_defaults | jq --arg k "$key" --argjson v "$value" '.[$k] = $v')
    else
        json=$(_read_defaults | jq --arg k "$key" --arg v "$value" '.[$k] = $v')
    fi
    printf '%s' "$json" > "$RECORD_DEFAULTS_STATE.tmp" && mv "$RECORD_DEFAULTS_STATE.tmp" "$RECORD_DEFAULTS_STATE"
    echo "record-toggle.sh: $key set to $value"
}

# The `pgrep` status probe this file's own header already anticipated as
# "a future bar module could read" — a readable status surface, not a
# new mechanism.
cmd_status() {
    if recording_active; then
        echo "recording"
    else
        echo "idle"
    fi
}

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
#
# `AUDIO_OVERRIDE` (quick task 260822-sht, Task 6, consumer 5) is set by
# main()'s `--audio <mode>` argument — the seam the launcher's
# ConfirmMode-adjacent picker (PickerMode.qml, `pickerId: "recordaudio"`)
# re-invokes this script through. D-1's inversion of control: this script
# no longer blocks on an interactive picker mid-flow at all.
AUDIO_DEVICES=""
AUDIO_OVERRIDE=""
pick_audio() {
    # An explicit --audio override always wins, regardless of the stored
    # default — this is the picker's own re-invocation path.
    if [[ -n "$AUDIO_OVERRIDE" ]]; then
        case "$AUDIO_OVERRIDE" in
            silent) AUDIO_DEVICES="" ;;
            desktop) AUDIO_DEVICES="default_output" ;;
            desktop+mic) AUDIO_DEVICES="default_output|default_input" ;;
        esac
        return
    fi

    # Task 10 (PD-05): a non-"ask" default skips the picker entirely —
    # "ask" (the absent-file default) preserves today's flow byte-for-byte,
    # this non-`ask` fast path unchanged.
    local audio_default
    audio_default=$(_read_defaults | jq -r '.audio // "ask"')
    if [[ "$audio_default" != "ask" ]]; then
        case "$audio_default" in
            silent) AUDIO_DEVICES="" ;;
            desktop) AUDIO_DEVICES="default_output" ;;
            desktop+mic) AUDIO_DEVICES="default_output|default_input" ;;
        esac
        return
    fi

    # "ask" and no --audio override: this script has no interactive path
    # left. Summon the launcher's audio picker and exit — the picker
    # re-invokes `record-toggle.sh --audio <mode>` once a choice is made.
    qs ipc call launcher open recordaudio >/dev/null 2>&1 || true
    exit 0
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

    # Task 10 (PD-05): fps/codec read from the same defaults `pick_audio`
    # already reads, each falling back to today's literal (60/auto).
    local defaults fps codec
    defaults=$(_read_defaults)
    fps=$(printf '%s' "$defaults" | jq -r '.fps // 60')
    codec=$(printf '%s' "$defaults" | jq -r '.codec // "auto"')

    gpu-screen-recorder "${capture_args[@]}" -k "$codec" -f "$fps" -fm cfr \
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

# ── Dispatcher (Task 10, R-6) — every existing caller and keybind is
#    unaffected: `record-toggle.sh` with no argument still does exactly
#    the bare `if recording_active; then stop_recording; else
#    start_recording; fi` this file always did. ─────────────────────────
main() {
    local sub="${1:-}"
    case "$sub" in
        status)
            cmd_status
            ;;
        set-default)
            shift
            cmd_set_default "$@"
            ;;
        get-defaults)
            cmd_get_defaults
            ;;
        --audio)
            # Quick task 260822-sht, Task 6, consumer 5 — validated BEFORE
            # any use (T-08-05's allowlist-before-use discipline), same
            # closed three-way enumeration `pick_audio()`'s own case
            # statements map to devices. The picker (PickerMode.qml,
            # `pickerId: "recordaudio"`) re-invokes exactly this shape.
            local mode="${2:-}"
            case "$mode" in
                silent | desktop | desktop+mic) ;;
                *)
                    echo "record-toggle.sh: --audio '$mode' not in {silent,desktop,desktop+mic}" >&2
                    exit 1
                    ;;
            esac
            AUDIO_OVERRIDE="$mode"
            if recording_active; then
                stop_recording
            else
                start_recording
            fi
            ;;
        "")
            if recording_active; then
                stop_recording
            else
                start_recording
            fi
            ;;
        *)
            echo "record-toggle.sh: unknown argument '$sub' (expected status|set-default|get-defaults|--audio <mode>, or no argument to toggle)" >&2
            exit 1
            ;;
    esac
}

main "$@"
