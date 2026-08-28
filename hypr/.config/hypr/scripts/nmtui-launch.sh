#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║        NETWORK MANAGER (nmtui) — launcher            ║
# ║  Opens a floating kitty running nmtui                ║
# ╚══════════════════════════════════════════════════════╝
# D-17: no new GUI package — NetworkManager already manages the network
# and nmtui ships with it. Follows fastfetch-logo-switch.sh's exact
# launcher-shim shape; --class/--title values are locked by 07-UI-SPEC.md.

uwsm app -- kitty \
    --class "network-manager" \
    --title "Network" \
    -o background_opacity=0.85 \
    -o font_size=11 \
    -- nmtui
