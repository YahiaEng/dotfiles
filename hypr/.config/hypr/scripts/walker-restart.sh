#!/usr/bin/env bash
# Restart Walker service to pick up new CSS

# Remove any shadow themes from data dir
rm -rf "$HOME/.local/share/walker/themes/rice" 2>/dev/null

# Ensure theme dir exists as real dir
WALKER_DIR="$HOME/.config/walker/themes/rice"
[[ -L "$WALKER_DIR" ]] && rm -f "$WALKER_DIR"
mkdir -p "$WALKER_DIR"

# Verify style.css exists before restart
if [[ ! -f "$WALKER_DIR/style.css" ]]; then
    notify-send -a "Walker" "Warning" "style.css missing — generating default" -t 2000
    ~/.config/hypr/scripts/walker-theme-gen.sh
fi

# Kill all walker processes by binary name
killall -q walker 2>/dev/null
sleep 0.5
killall -q -9 walker 2>/dev/null

# Remove stale socket
rm -f "/run/user/$(id -u)/walker/walker.sock" 2>/dev/null

sleep 0.3

# Relaunch via uwsm
uwsm app -- walker --gapplication-service &
disown
