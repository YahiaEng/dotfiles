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
WALLPAPER="$HOME/Pictures/Wallpapers/current.jpg"

THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "catppuccin")

# Wallpaper-setting is owned by the picker/init, never by matugen (D-19).
if [[ -f "$WALLPAPER" ]]; then
    awww img "$WALLPAPER" \
        --transition-type center \
        --transition-duration 1 \
        --transition-fps 165
fi

# D-33: finish the optional dynamic-cursors plugin build once a session
# exists (install.sh's guarded block may have run with no compositor at
# all). Backgrounded so it can never delay theming, output-suppressed so
# it can never pollute the login path. Wired here — instead of an
# autostart.lua entry — because that file carries a documented
# no-new-entries prohibition (D-15/D-35: "no entry added, removed or
# reordered"). This does put one guarded background line inside a script
# D-21 otherwise frames as a "thin caller"; a systemd user unit was
# considered and rejected instead, because this repo ships no systemd
# user units at all and a new one would mean a unit file, a stow
# registration and an enable step — three new surfaces for the
# criterion-3 sweep in the phase designated first to cut (17-06). One
# guarded background line is the smallest surface that satisfies both
# constraints at once.
~/.config/hypr/scripts/hyprpm-complete.sh >/dev/null 2>&1 &

exec ~/.config/theme-engine/theme-apply "$THEME"
