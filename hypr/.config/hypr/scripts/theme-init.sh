#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              THEME INIT (login)                      ║
# ║   Thin caller: reads the saved theme (D-10 fallback), ║
# ║   sets the wallpaper (D-19), and calls theme-apply.   ║
# ╚══════════════════════════════════════════════════════╝

STATE_FILE="$HOME/.local/state/theme/current-theme"
WALLPAPER="$HOME/Pictures/Wallpapers/current.jpg"

THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "catppuccin")

# Wallpaper-setting is owned by the picker/init, never by matugen (D-19).
if [[ -f "$WALLPAPER" ]]; then
    awww img "$WALLPAPER" \
        --transition-type center \
        --transition-duration 1 \
        --transition-fps 165
fi

exec ~/.config/theme-engine/theme-apply "$THEME"
