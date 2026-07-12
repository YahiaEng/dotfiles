#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║        ICON THEME PICKER — launcher                  ║
# ║  Opens a floating kitty running the fzf picker       ║
# ╚══════════════════════════════════════════════════════╝

uwsm app -- kitty \
    --class "icon-theme-picker" \
    --title "Icon Theme Picker" \
    -o background_opacity=0.85 \
    -o font_size=11 \
    -- ~/.config/hypr/scripts/icon-theme-picker.sh
