#!/usr/bin/env bash
# quickshell-launch.sh — guarded, logged launcher (D-06)
#
# Mirrors waybar-launch.sh's guard-then-exec shape, but stricter: a
# headless shell root (D-02) that dies leaves zero other visible evidence,
# so this script guards binary + config existence AND logs startup/exit,
# where waybar-launch.sh only guards the layout choice.
#
# No `-e`: this script ends in `exec`; an `-e` abort on a transient
# failure must never leave the session with nothing running — a missing
# binary or config degrades to "skip, logged", never a hard crash.
set -uo pipefail

LOG="$HOME/.cache/quickshell.log"
CONFIG_DIR="$HOME/.config/quickshell"

# ── Log rotation ─────────────────────────────────────
# Truncate at the top of each run if the log has grown past ~1 MiB, so a
# long-lived session can't grow it unbounded (T-11-05).
if [[ -f "$LOG" ]]; then
    LOG_SIZE=$(stat -c %s "$LOG" 2>/dev/null || echo 0)
    if [[ "$LOG_SIZE" -gt 1048576 ]]; then
        : > "$LOG"
    fi
fi

if ! command -v quickshell >/dev/null 2>&1; then
    echo "quickshell-launch.sh: quickshell binary not found — skipping $(date -Is)" >>"$LOG"
    exit 0
fi
if [[ ! -f "$CONFIG_DIR/shell.qml" ]]; then
    echo "quickshell-launch.sh: $CONFIG_DIR/shell.qml not found — skipping $(date -Is)" >>"$LOG"
    exit 0
fi

echo "quickshell-launch.sh: starting $(date -Is)" >>"$LOG"
exec quickshell -p "$CONFIG_DIR" >>"$LOG" 2>&1
