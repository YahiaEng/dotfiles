#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              CLIPBOARD MANUAL WIPE                     ║
# ║  `cliphist wipe` (UTIL-03/D-15 manual wipe entry).      ║
# ║  Does NOT touch the Super+C cliphist list flow.         ║
# ╚══════════════════════════════════════════════════════╝
#
# The confirm dialog itself moved to the launcher's ConfirmMode.qml (quick
# task 260822-sht, Task 6) — D-1's inversion of control: a QML surface
# owns the destructive-safe confirm (default-focus = No, UI-SPEC
# Copywriting Contract) and invokes this script with `--yes` on
# confirmation. This script no longer has an interactive path at all; the
# entry count read, the empty-database exit handling, the wipe itself and
# the notification are unchanged real logic, not picker scaffolding.
set -euo pipefail

usage() {
    echo "clipboard-wipe.sh: usage: clipboard-wipe.sh --yes" >&2
    exit 1
}

[[ $# -eq 1 && "$1" == "--yes" ]] || usage

COUNT=0
if command -v cliphist >/dev/null 2>&1; then
    # WR-02: `cliphist list` exits 1 ("please store something first") on an
    # empty/fresh db — which is also the state left after a successful
    # wipe. Under set -e that non-zero pipeline would kill the script
    # before the wipe below ever runs; `|| true` neutralises pipefail's
    # propagation while wc's output is still captured, and the parameter
    # expansion defaults an empty capture to 0.
    COUNT=$(cliphist list 2>/dev/null | wc -l | tr -d '[:space:]' || true)
    COUNT=${COUNT:-0}
fi

cliphist wipe

notify-send -a "Clipboard" "History Wiped" "All entries cleared" -i edit-clear -t 2000 2>/dev/null || true
