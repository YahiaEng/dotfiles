#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║        WALLPAPER PICKER — launcher                   ║
# ║  Opens a floating kitty running the fzf picker       ║
# ╚══════════════════════════════════════════════════════╝

uwsm app -- kitty \
    --class "wallpaper-picker" \
    --title "Wallpaper Picker" \
    -o background_opacity=0.85 \
    -o font_size=11 \
    -- ~/.config/hypr/scripts/wallpaper-picker.sh
