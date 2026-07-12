#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║           WAYBAR LAYOUT SWITCHER (walker)            ║
# ║   Switches between minimal, full, floating configs   ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

WAYBAR_DIR="$HOME/.config/waybar"
STATE_FILE="$HOME/.cache/current-waybar-layout"

mkdir -p "$(dirname "$STATE_FILE")"

# ── Layout options ───────────────────────────────────
LAYOUT_LIST="📏 Minimal — Clock + Workspaces
📊 Full — System stats, media, tray
🏝️ Floating — Island-style modules"

# ── Show walker menu ───────────────────────────────────
# WR-04: walker 2.16.2 signals Esc / click-outside / Return-on-empty
# cancel via exit status 130 with no stdout (128+SIGINT convention), never
# exit 0 + empty output. `|| rc=$?` captures the exit code without
# tripping `set -euo pipefail` on a bare command-substitution assignment.
rc=0
SELECTED=$(echo "$LAYOUT_LIST" | walker --dmenu --placeholder "Waybar Layout") || rc=$?
if (( rc == 130 )); then
    exit 0   # user cancel
elif (( rc != 0 )); then
    notify-send -a "Waybar Switcher" "Error" "walker dmenu failed" -i dialog-error 2>/dev/null || true
    exit 1   # hard failure: not installed (127), elephant dead (1), crash
fi

[[ -z "$SELECTED" ]] && exit 0   # defensive; walker never returns 0+empty, but harmless

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

# Launch waybar as a uwsm-managed scope unit
uwsm app -- waybar -c "$WAYBAR_DIR/config-${LAYOUT}.jsonc" \
       -s "$WAYBAR_DIR/style-${LAYOUT}.css" &

# Save state
echo "$LAYOUT" > "$STATE_FILE"

notify-send -a "Waybar Switcher" "Layout Changed" \
    "Switched to ${LAYOUT} layout" \
    -i preferences-desktop-display -t 2000
