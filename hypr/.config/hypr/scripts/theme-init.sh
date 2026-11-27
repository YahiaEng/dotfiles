#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              THEME INIT (login)                      ║
# ║   Thin caller: reads the saved theme (D-10 fallback), ║
# ║   sets the wallpaper (D-19), and calls theme-apply.   ║
# ╚══════════════════════════════════════════════════════╝

# IN-01: deliberately NO `set -euo pipefail` here, unlike theme-apply/
# wallpaper-visibility.sh's own sibling entrypoints. This script's
# contract is "thin caller, never blocks" — the final `exec theme-apply
# "$THEME"` line below MUST always run, even if the best-effort `awww`
# preview call above it fails transiently (e.g. the compositor's own
# animated-wallpaper daemon not yet ready at the very start of login).
# Adding `set -e` would let that single early-login failure abort this
# script before `exec` ever runs, silently skipping theme-apply and
# leaving the desktop unthemed at login — a worse outcome than the
# `awww` call itself failing quietly. Left un-set on purpose, not an
# oversight.
STATE_FILE="$HOME/.local/state/theme/current-theme"
# D-19-45: pointer moved from the stow-managed Wallpapers directory into
# engine-owned state — same symlink, new home.
WALLPAPER="$HOME/.local/state/theme/current.jpg"

THEME_APPLY="$HOME/.config/theme-engine/theme-apply"

THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "catppuccin")

# Wallpaper-setting is owned by the picker/init, never by matugen (D-19).
if [[ -f "$WALLPAPER" ]]; then
    awww img "$WALLPAPER" \
        --transition-type center \
        --transition-duration 1 \
        --transition-fps 165
fi

# Load the optional cursor plugin in the background during login.
~/.config/hypr/scripts/hyprpm-complete.sh >/dev/null 2>&1 &

THEME_APPLY_QUIET=1 exec "$THEME_APPLY" "$THEME"
