#!/usr/bin/env bash
# capture-full.sh — freeze-capture the active monitor instantly (no click
# step), pipe straight into satty for annotate + save + copy (SHOT-01/02,
# D-01/D-02/D-05).
#
# Same hyprshot / satty flag verification as capture-region.sh (see that
# file's header comment for full sourcing). `-m output -m active` takes
# the CURRENT=1 path in hyprshot's begin_grab() (grab_active_output) which
# skips slurp entirely and captures the monitor holding the active
# workspace — a true one-keypress "full screen" capture, matching the
# instant behavior of the old bare grim/slurp full-screen mode this
# script replaces.
set -euo pipefail

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="$SCREENSHOT_DIR/screenshot_${TIMESTAMP}.png"

hyprshot -m output -m active -z -r | satty --filename - --output-filename "$FILENAME" --disable-notifications

# satty owns save+copy (D-02); only notify if a file actually landed —
# Escape/window-close exits satty without saving and must stay silent.
if [ -f "$FILENAME" ]; then
    notify-send -a "Screenshot" "Screenshot Captured" \
        "Saved to $FILENAME\nCopied to clipboard" \
        -i camera-photo -t 3000
fi
