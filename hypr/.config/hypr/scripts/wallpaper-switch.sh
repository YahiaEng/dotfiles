#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║        WALLPAPER PICKER — launcher                   ║
# ║  Opens the shell's QML picker, with the fzf TUI as   ║
# ║  the fallback when the shell is not available        ║
# ╚══════════════════════════════════════════════════════╝
#
# Every surface that offers "change the wallpaper" goes through this one
# script — Super+W (keybinds.lua) and the launcher's Style ▸ Wallpaper entry
# (MenuTree.qml) — so retargeting the picker is a change HERE, not a change
# at each call site. Quick task 260826-pk2 repointed it from the fzf TUI to
# Settings ▸ Wallpaper, which now carries the category grid, live-animating
# tiles and the Browse button.
#
# THE FALLBACK IS NOT DECORATION. The QML picker only exists while
# quickshell is running, and this repo has a standing failure mode where the
# shell dies at boot on a bad QML import — in which case Super+W must still
# change the wallpaper rather than doing nothing at all. `qs ipc call`
# returns non-zero when no shell is listening, which is the signal to fall
# back to the terminal picker that needs no shell.
#
# Both paths ultimately drive the same wallpaper-picker.sh --set contract.

set -uo pipefail

if command -v qs >/dev/null 2>&1 && qs ipc call settings openPage wallpaper >/dev/null 2>&1; then
    exit 0
fi

echo "wallpaper-switch: shell IPC unavailable — falling back to the terminal picker" >&2

uwsm app -- kitty \
    --class "wallpaper-picker" \
    --title "Wallpaper Picker" \
    -o background_opacity=0.85 \
    -o font_size=11 \
    -- ~/.config/hypr/scripts/wallpaper-picker.sh
