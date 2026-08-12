#!/usr/bin/env bash
# quickshell-launch.sh — guarded, logged launcher (D-06)
#
# Mirrors the retired bar's own launcher's guard-then-exec shape, but
# stricter: a headless shell root (D-02) that dies leaves zero other
# visible evidence, so this script guards binary + config existence AND
# logs startup/exit, where that retired launcher only guarded the layout
# choice.
#
# No `-e`: this script ends in `exec`; an `-e` abort on a transient
# failure must never leave the session with nothing running — a missing
# binary or config degrades to "skip, logged", never a hard crash.
#
# 18-07 (QBAR-10, D-18-40): as of this plan, this script is
# quickshell.service's ExecStart= target rather than a uwsm scope's
# command — see quickshell/.config/systemd/user/quickshell.service for
# the unit itself. This script still runs as the process systemd
# supervises, and its final `exec quickshell -p "$CONFIG_DIR"` below is
# what makes quickshell the unit's main pid — the process the restart
# policy actually watches. This gives the two guard paths' `exit 0` a
# second meaning it did not carry before: a clean exit is explicitly
# exempted from `Restart=on-failure`, so a missing binary or a missing
# shell.qml stays a logged skip and can NEVER enter a restart cycle — it
# was already the right behaviour for a headless daemon, and it is now
# also the right behaviour under a supervisor. The correct way to
# restart quickshell is now `systemctl --user restart quickshell.service`
# — NOT a plain `pkill quickshell` (SIGTERM), which the restart policy
# exempts and will NOT bring the bar back on its own. This also
# supersedes the standing executor rule requiring a detached relaunch
# (`setsid uwsm app -- ...`): a relaunch through quickshell.service
# cannot die with the shell that requested it, because the process is a
# child of the systemd user manager, not of the caller — the failure
# mode that rule existed to guard against structurally cannot occur
# through the unit.
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

# ── Threaded scene-graph render loop ─────────────────────
# Qt was auto-selecting the BASIC render loop here, which runs animation and
# rendering together on the GUI thread. Measured with QSG_RENDER_TIMING=1 on
# this host (DP-1, 2560x1440@165Hz) across a dashboard tab transition:
#
#   basic (Qt's own default):  ~16ms between frames  -> ~60fps
#   threaded (this setting):   ~6ms  between frames  -> ~165fps
#
# The 6ms figure holds for BOTH the render thread's syncAndRender AND the GUI
# thread's polishAndSync, so animations actually advance at the panel's rate
# rather than merely being redrawn more often. Every drawer animation was
# leaving roughly two thirds of this display's refresh rate unused.
#
# Reversible: comment out this one line to return to Qt's auto-selection. Kept
# as an explicit export rather than a wrapper so `quickshell` still execs as
# PID 1 of this script and the uwsm/systemd scope is unchanged.
#
# Worth watching on this NVIDIA + Wayland host: the threaded loop is the more
# demanding of the two. One full session was exercised with no crash, abort or
# tearing observed, but that is one session, not a soak.
export QSG_RENDER_LOOP=threaded

echo "quickshell-launch.sh: starting $(date -Is)" >>"$LOG"
exec quickshell -p "$CONFIG_DIR" >>"$LOG" 2>&1
