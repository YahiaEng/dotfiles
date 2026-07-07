#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              THEME SWITCHER (walker)                 ║
# ║   Thin caller: only picks a name, theme-apply does    ║
# ║   the rendering + reload (D-01/PIPE-01).               ║
# ╚══════════════════════════════════════════════════════╝

THEME_LIST="🎨 Material You (Dynamic)
🐱 Catppuccin Mocha
🧛 Dracula
🌹 Rosé Pine
🪵 Gruvbox Dark
🌃 Tokyo Night
❄️ Nord"

SELECTED=$(echo "$THEME_LIST" | walker --dmenu --placeholder "Select Theme")
[[ -z "$SELECTED" ]] && exit 0

case "$SELECTED" in
    *"Material You"*)  THEME="materialyou" ;;
    *"Catppuccin"*)    THEME="catppuccin"  ;;
    *"Dracula"*)       THEME="dracula"     ;;
    *"Rosé Pine"*)     THEME="rosepine"    ;;
    *"Gruvbox"*)       THEME="gruvbox"     ;;
    *"Tokyo Night"*)   THEME="tokyonight"  ;;
    *"Nord"*)          THEME="nord"        ;;
    *)                 exit 1              ;;
esac

exec ~/.config/theme-engine/theme-apply "$THEME"
