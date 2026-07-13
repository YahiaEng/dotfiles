#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║           CLIPBOARD MANUAL WIPE (walker)               ║
# ║  Destructive-safe confirm (default-No) then            ║
# ║  `cliphist wipe` (UTIL-03/D-15 manual wipe entry).      ║
# ║  Does NOT touch the Super+C cliphist list flow.         ║
# ╚══════════════════════════════════════════════════════╝
set -euo pipefail

COUNT=0
if command -v cliphist >/dev/null 2>&1; then
    # WR-02: `cliphist list` exits 1 ("please store something first") on an
    # empty/fresh db — which is also the state left after a successful
    # wipe. Under set -e that non-zero pipeline would kill the script
    # before the confirm dialog ever renders; `|| true` neutralises
    # pipefail's propagation while wc's output is still captured, and the
    # parameter expansion defaults an empty capture to 0.
    COUNT=$(cliphist list 2>/dev/null | wc -l | tr -d '[:space:]' || true)
    COUNT=${COUNT:-0}
fi

# UI-SPEC Copywriting Contract: destructive confirm, default focus = No —
# "No" listed first so it is the default-highlighted dmenu row (never
# pre-select the destructive option).
rc=0
SELECTED=$(printf 'No\nYes\n' | walker --dmenu \
    --placeholder "This clears all $COUNT saved clipboard entries. This cannot be undone.") || rc=$?
# theme-switch.sh's exit-130-cancel pattern, verbatim.
if ((rc == 130)); then
    exit 0 # user cancelled — walker's own 128+SIGINT convention
elif ((rc != 0)); then
    notify-send -a "Clipboard" "Error" "walker dmenu failed" -i dialog-error 2>/dev/null || true
    exit 1
fi

[[ "$SELECTED" != "Yes" ]] && exit 0 # No / anything else — abort, no wipe

cliphist wipe

notify-send -a "Clipboard" "History Wiped" "All entries cleared" -i edit-clear -t 2000 2>/dev/null || true
