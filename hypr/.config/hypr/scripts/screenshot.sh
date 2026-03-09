#!/usr/bin/env bash
# Screenshot utility using grim + slurp
# Usage: screenshot.sh [full|area|window]

set -euo pipefail

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="$SCREENSHOT_DIR/screenshot_${TIMESTAMP}.png"

case "${1:-full}" in
    full)
        grim "$FILENAME"
        ;;
    area)
        grim -g "$(slurp)" "$FILENAME"
        ;;
    window)
        grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$FILENAME"
        ;;
    *)
        echo "Usage: screenshot.sh [full|area|window]"
        exit 1
        ;;
esac

# Copy to clipboard
wl-copy < "$FILENAME"

notify-send -a "Screenshot" "Screenshot Captured" \
    "Saved to $FILENAME\nCopied to clipboard" \
    -i camera-photo -t 3000
