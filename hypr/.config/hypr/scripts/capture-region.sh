#!/usr/bin/env bash
# capture-region.sh — freeze-capture a slurp-selected region, pipe straight
# into satty for annotate + save + copy (SHOT-01/02, D-01/D-02/D-05).
#
# hyprshot flags verified against the live upstream script
# (raw.githubusercontent.com/Gustash/Hyprshot/main/hyprshot — hyprshot
# 1.3.0, official extra repo, not yet installed on this dev machine;
# RESEARCH.md Assumption A2 / Pattern 4):
#   -m region  : interactive slurp region selection
#   -z         : freeze screen contents during selection (D-01)
#   -r         : write raw PPM image data to stdout — hyprshot's own
#                save_geometry() returns immediately in RAW mode, before
#                its own send_notification() call, so no duplicate
#                hyprshot notification ever fires
#
# satty flags verified against the live upstream CLI definition
# (raw.githubusercontent.com/gabm/Satty/main/cli/src/command_line.rs —
# satty 0.21.1, official extra repo, not yet installed on this dev
# machine; RESEARCH.md Assumption A1 / Open Question 3):
#   --filename -            : read the piped image from stdin
#   --output-filename PATH  : save-to-file target. actions-on-enter =
#                              save-to-clipboard,save-to-file is already
#                              set in the rendered ~/.config/satty/config.toml
#                              (06-02), so Enter/Ctrl+C performs
#                              copy+save+exit — satty owns save+copy (D-02)
#   --disable-notifications : suppress satty's own generic GNotification
#                              so this script's notify-send (matching the
#                              pre-existing screenshot.sh wording/icon,
#                              06-UI-SPEC Copywriting Contract) is the
#                              only notification the user sees
set -euo pipefail

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="$SCREENSHOT_DIR/screenshot_${TIMESTAMP}.png"

hyprshot -m region -z -r | satty --filename - --output-filename "$FILENAME" --disable-notifications

# satty owns save+copy (D-02); only notify if a file actually landed —
# Escape/window-close exits satty without saving and must stay silent.
if [ -f "$FILENAME" ]; then
    notify-send -a "Screenshot" "Screenshot Captured" \
        "Saved to $FILENAME\nCopied to clipboard" \
        -i camera-photo -t 3000
fi
