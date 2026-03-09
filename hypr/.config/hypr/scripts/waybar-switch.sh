#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║           WAYBAR LAYOUT SWITCHER (wofi)               ║
# ║   Switches between minimal, full, floating configs    ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

WAYBAR_DIR="$HOME/.config/waybar"
STATE_FILE="$HOME/.cache/current-waybar-layout"

mkdir -p "$(dirname "$STATE_FILE")"

# ── Layout options ───────────────────────────────────
LAYOUT_LIST="📏 Minimal — Clock + Workspaces
📊 Full — System stats, media, tray
🏝️ Floating — Island-style modules"

# ── Show wofi menu ───────────────────────────────────
SELECTED=$(echo "$LAYOUT_LIST" | wofi --dmenu \
    --prompt "Waybar Layout" \
    --width 420 \
    --height 200 \
    --cache-file /dev/null)

[[ -z "$SELECTED" ]] && exit 0

# ── Map selection to layout name ─────────────────────
case "$SELECTED" in
    *"Minimal"*)   LAYOUT="minimal"  ;;
    *"Full"*)      LAYOUT="full"     ;;
    *"Floating"*)  LAYOUT="floating" ;;
    *)             exit 1            ;;
esac

# ── Apply layout ─────────────────────────────────────
# Kill existing waybar
pkill waybar || true
sleep 0.3

# Launch waybar with the selected config and style
waybar -c "$WAYBAR_DIR/config-${LAYOUT}.jsonc" \
       -s "$WAYBAR_DIR/style-${LAYOUT}.css" &
disown

# Save state
echo "$LAYOUT" > "$STATE_FILE"

notify-send -a "Waybar Switcher" "Layout Changed" \
    "Switched to ${LAYOUT} layout" \
    -i preferences-desktop-display -t 2000
