#!/usr/bin/env bash
# capture-window.sh — freeze-capture a click-selected window, pipe straight
# into satty for annotate + save + copy (SHOT-01/02, D-01/D-02/D-05).
#
# Same hyprshot -m window / satty flag verification as capture-region.sh
# (see that file's header comment for full sourcing). `-m window` shows a
# slurp overlay over every visible window on the focused workspace so the
# user can click the one they want — the standard upstream hyprshot window
# UX (raw.githubusercontent.com/Gustash/Hyprshot/main/hyprshot).
set -euo pipefail

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="$SCREENSHOT_DIR/screenshot_${TIMESTAMP}.png"

hyprshot -m window -z -r | satty --filename - --output-filename "$FILENAME" --disable-notifications

# satty owns save+copy (D-02); only notify if a file actually landed —
# Escape/window-close exits satty without saving and must stay silent.
if [ -f "$FILENAME" ]; then
    notify-send -a "Screenshot" "Screenshot Captured" \
        "Saved to $FILENAME\nCopied to clipboard" \
        -i camera-photo -t 3000
fi
