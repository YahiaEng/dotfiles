#!/usr/bin/env bash
# Launches waybar with the last-used layout, defaulting to 'full'

WAYBAR_DIR="$HOME/.config/waybar"
STATE_FILE="$HOME/.cache/current-waybar-layout"

LAYOUT=$(cat "$STATE_FILE" 2>/dev/null || echo "full")

# Validate layout
case "$LAYOUT" in
    minimal|full|floating) ;;
    *) LAYOUT="full" ;;
esac

waybar -c "$WAYBAR_DIR/config-${LAYOUT}.jsonc" \
       -s "$WAYBAR_DIR/style-${LAYOUT}.css" &
disown
