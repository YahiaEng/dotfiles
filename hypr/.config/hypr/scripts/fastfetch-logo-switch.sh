#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║      FASTFETCH LOGO PICKER — launcher                ║
# ║  Opens a floating kitty running the fzf picker        ║
# ╚══════════════════════════════════════════════════════╝

uwsm app -- kitty \
    --class "fastfetch-logo-picker" \
    --title "Fastfetch Logo Picker" \
    -o background_opacity=0.85 \
    -o font_size=11 \
    -- ~/.config/hypr/scripts/fastfetch-logo-picker.sh
