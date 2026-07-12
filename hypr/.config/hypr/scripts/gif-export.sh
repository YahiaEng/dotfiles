#!/usr/bin/env bash
# gif-export.sh — two-pass ffmpeg palettegen/paletteuse conversion of a
# recorded .mp4 to a .gif beside it. Invoked as the "Export GIF"
# notification action from record-toggle.sh's Recording Saved
# notification (SHOT-03, D-04).
set -euo pipefail

INPUT="${1:?Usage: gif-export.sh <input.mp4>}"
if [[ ! -f "$INPUT" ]]; then
    notify-send -a "Screen Recorder" "Error" "GIF export: input file not found" -i dialog-error -t 6000 2>/dev/null || true
    exit 1
fi

OUTPUT="${INPUT%.*}.gif"
PALETTE=$(mktemp --suffix=.png)
LOG=$(mktemp)
trap 'rm -f "$PALETTE" "$LOG"' EXIT

# Security Domain T-06-09: truncate + strip control chars before any
# subprocess error text reaches notify-send.
sanitize() {
    head -c 200 | tr -d '\000-\011\013\014\016-\037'
}

# Pass 1: generate an optimal 256-color palette for the clip.
if ! ffmpeg -y -i "$INPUT" -vf "fps=15,scale=960:-1:flags=lanczos,palettegen" "$PALETTE" >"$LOG" 2>&1; then
    err=$(sanitize <"$LOG")
    notify-send -a "Screen Recorder" "Error" "GIF export failed (palette): $err" -i dialog-error -t 6000 2>/dev/null || true
    exit 1
fi

# Pass 2: encode the GIF using that palette.
if ! ffmpeg -y -i "$INPUT" -i "$PALETTE" \
    -filter_complex "fps=15,scale=960:-1:flags=lanczos[x];[x][1:v]paletteuse" \
    "$OUTPUT" >"$LOG" 2>&1; then
    err=$(sanitize <"$LOG")
    notify-send -a "Screen Recorder" "Error" "GIF export failed (encode): $err" -i dialog-error -t 6000 2>/dev/null || true
    exit 1
fi

notify-send -a "Screen Recorder" "GIF Exported" "Saved to $OUTPUT" -i image-gif -t 3000
