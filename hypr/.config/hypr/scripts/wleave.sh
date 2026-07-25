#!/usr/bin/env bash
# Open-only power-menu launcher (D-18): no toggle branch, and no liveness
# scan of any other running instance — the retired GTK3 engine's toggle
# logic and outer-window geometry arithmetic (content/pad/border
# derivation, a focused-monitor size query, and a centring helper) are dead
# code on this engine, which anchors all four screen edges and centres its
# own content natively. Dismissal is Esc or a scrim click-away, both
# handled natively by the binary; there is no in-surface error UI (D-23) —
# the two notify-send calls below are the entire error state.
set -euo pipefail

if ! command -v wleave >/dev/null 2>&1; then
    notify-send "Power menu" "wleave is not installed" -u critical
    exit 1
fi

wleave &
WLEAVE_PID=$!

sleep 0.3

if ! kill -0 "$WLEAVE_PID" >/dev/null 2>&1; then
    notify-send "Power menu" "wleave failed to launch" -u critical
    exit 1
fi
