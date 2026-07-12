#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║        FONT SWITCHER — launcher                      ║
# ║  Opens a floating kitty running the fzf picker       ║
# ╚══════════════════════════════════════════════════════╝

uwsm app -- kitty \
    --class "font-switcher" \
    --title "Font Switcher" \
    -o background_opacity=0.85 \
    -o font_size=11 \
    -- ~/.config/hypr/scripts/font-switcher.sh
