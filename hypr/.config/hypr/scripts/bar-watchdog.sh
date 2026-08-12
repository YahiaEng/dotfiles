#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║         QML BAR SURFACE WATCHDOG (WINDOWS #67)         ║
# ║  Long-running Hyprland socket2 listener. On monitor    ║
# ║  events, checks whether the bar's layer surface        ║
# ║  actually exists and restarts quickshell.service ONLY  ║
# ║  if it genuinely does not.                              ║
# ╚══════════════════════════════════════════════════════╝
#
# THE DEFECT (WINDOWS.md row 67): a monitor removal/re-add (display sleep,
# DPMS cycle, hotplug) destroys the `quickshell-bar` layer surface.
# quickshell itself stays perfectly healthy — same pid, NRestarts=0,
# ActiveState=active, zero QML errors. Live log, both occurrences:
#   quickshell.hyprland.ipc: Got removal for monitor "FALLBACK" which was
#   not previously tracked
#   qt.qpa.wayland: There are no outputs - creating placeholder screen
# The PanelWindow binds to the placeholder screen and never migrates back.
# The bar is gone until the service is restarted by hand, and the shell
# keeps logging `bar: visibility=visible zone=reserved` while nothing is
# actually mounted — WINDOWS row 67's own recorded false-positive.
#
# THIS REVERSES D-18-28. 18-15 deleted this repo's standalone socket2
# listener (waybar-fullscreen-watch.sh) outright: "the standalone socket2
# listener is deleted outright, not repointed — the fullscreen intent is
# now reported by the QML shell itself". That removal was correct FOR
# THAT DEFECT, because the shell could report its own fullscreen intent.
# Here the situation is structurally different: the shell is precisely
# the thing that fails — it goes on reporting a healthy bar while no
# surface exists — so a self-healing mechanism cannot live inside the
# thing that needs healing. It has to watch from outside. Hence this
# script is a genuine reintroduction of a retired pattern, not a return
# to the same problem D-18-28 solved.
#
# WHY THIS READS `hyprctl layers -j` AND NEVER `bar-visibility.sh status`:
# WINDOWS row 67 records that verb printing `visible` with no surface
# present, and its documented `reassert` recovery verb completing without
# error and changing nothing. Anything that greps that verb is testing
# the shell's OPINION of its own state, not reality. `hyprctl layers -j`
# is the compositor's own live view of mounted layer surfaces — it cannot
# be fooled by a shell that is wrong about itself.
#
# WHY THE NAMESPACE MATCH IS EXACT EQUALITY ON "quickshell-bar":
# `hyprctl layers -j` on this host currently also reports
# `quickshell-bar-hotzone` and a `quickshell-bardrawer-*` family as live
# sibling namespaces. A prefix or substring match would report a healthy
# bar during precisely the outage this watchdog exists to catch — it
# would look like it works and never fire. Exact string equality only.
#
# WHY RECOVERY IS `systemctl --user restart quickshell.service` AND NOT
# `pkill quickshell`: pkill sends SIGTERM by default, which
# quickshell.service's own header documents as being in the clean-exit
# exemption list under systemd.service(5) — SIGTERM does NOT restart the
# unit. quickshell.service's header calls this "the single most likely
# misdiagnosis this unit can cause". The correct restart command is
# `systemctl --user restart quickshell.service`, and that is the only
# recovery action this script ever takes.
#
# WHY PYTHON3 STDLIB ONLY: socat, nc and ncat are all ABSENT on this host
# (verified live this session). Adding a package would touch install.sh's
# reproducibility contract for no reason python3 alone doesn't already
# solve. The inline `python3 - <<'PYEOF'` idiom is theme-doctor's
# established shape, inherited directly from the retired
# waybar-fullscreen-watch.sh (git show adce9e6^:...).

set -euo pipefail

MODE="watch"
case "${1:-}" in
    "") MODE="watch" ;;
    --check) MODE="check" ;;
    --dry-run) MODE="dry-run" ;;
    *)
        echo "usage: $0 [--check|--dry-run]" >&2
        exit 2
        ;;
esac

# Headless/no-session safety (mirrors quickshell-launch.sh's guard paths
# and the retired listener's own): if XDG_RUNTIME_DIR or
# HYPRLAND_INSTANCE_SIGNATURE is unset, exit 0 immediately — never block,
# never spin. --check needs no socket at all and must still work without
# one (it only shells out to hyprctl), so this guard only applies to
# watch/dry-run modes below, after the socket path is known not to exist.
#
# Exit 0 here, not exit 1: under the unit added alongside this script,
# Restart=on-failure means a clean exit degrades to a logged skip and can
# NEVER enter a restart cycle — the same reasoning quickshell.service's
# header gives for quickshell-launch.sh's two guard paths (missing
# binary, missing shell.qml). A headless/no-session environment is not a
# failure of this watchdog; it is simply nothing to watch yet.
if [[ "$MODE" != "check" ]]; then
    if [[ -z "${XDG_RUNTIME_DIR:-}" || -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        exit 0
    fi
fi

SOCKET_PATH=""
if [[ -n "${XDG_RUNTIME_DIR:-}" && -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    SOCKET_PATH="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
fi

if [[ "$MODE" != "check" ]]; then
    if [[ ! -S "$SOCKET_PATH" ]]; then
        exit 0
    fi
fi

exec python3 - "$SOCKET_PATH" "$MODE" <<'PYEOF'
import json
import os
import select
import socket
import subprocess
import sys
import time

SOCKET_PATH = sys.argv[1]
MODE = sys.argv[2]  # "watch" | "check" | "dry-run"

# Tunables, each read from an env override with the shipped value as the
# default, so the test harness can compress a 15-minute rate-limit window
# into seconds without editing this file. Parsed defensively — a
# malformed override falls back to the default rather than crashing the
# watchdog at session start.
def _env_float(name, default):
    try:
        return float(os.environ.get(name, default))
    except (TypeError, ValueError):
        return float(default)

def _env_int(name, default):
    try:
        return int(float(os.environ.get(name, default)))
    except (TypeError, ValueError):
        return int(default)

DEBOUNCE = _env_float("BAR_WATCHDOG_DEBOUNCE_SEC", 3.0)
MIN_INTERVAL = _env_float("BAR_WATCHDOG_MIN_INTERVAL_SEC", 30)
MAX_RESTARTS = _env_int("BAR_WATCHDOG_MAX_RESTARTS", 3)
WINDOW_SEC = _env_float("BAR_WATCHDOG_WINDOW_SEC", 900)

BAR_NAMESPACE = "quickshell-bar"

# Deliberately closed set — this tuple is the single place to widen it.
# Any other event name (activewindow, workspace, fullscreen, ...) is
# ignored before its payload is even examined.
MONITOR_EVENTS = ("monitoradded", "monitoraddedv2", "monitorremoved")

_restart_timestamps = []


def log(msg):
    # stdout only — under the unit this lands in the journal, so there is
    # no log file and no rotation logic to maintain. flush=True is
    # required, not decorative: stdout is a pipe under systemd and would
    # otherwise block-buffer.
    print(f"bar-watchdog: {msg}", flush=True)


def bar_surface_present():
    """Return True / False / None (INDETERMINATE)."""
    try:
        result = subprocess.run(
            ["hyprctl", "layers", "-j"],
            capture_output=True,
            text=True,
            check=False,
            timeout=5,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None

    if result.returncode != 0:
        return None

    try:
        data = json.loads(result.stdout)
    except (json.JSONDecodeError, TypeError):
        return None

    if not isinstance(data, dict):
        return None

    for monitor_entry in data.values():
        if not isinstance(monitor_entry, dict):
            continue
        levels = monitor_entry.get("levels")
        if not isinstance(levels, dict):
            continue
        for layer_list in levels.values():
            if not isinstance(layer_list, list):
                continue
            for layer in layer_list:
                if not isinstance(layer, dict):
                    continue
                # Exact string equality only — see the header's namespace
                # rationale. "quickshell-bar-hotzone" and
                # "quickshell-bardrawer-*" are live sibling namespaces on
                # this host and must NOT satisfy this check.
                if layer.get("namespace") == BAR_NAMESPACE:
                    return True
    return False


def recover(dry_run):
    now = time.monotonic()
    # Prune the restart-timestamp list to the rolling window.
    global _restart_timestamps
    _restart_timestamps = [t for t in _restart_timestamps if now - t < WINDOW_SEC]

    if _restart_timestamps and (now - _restart_timestamps[-1]) < MIN_INTERVAL:
        log(f"cooldown active (min interval {MIN_INTERVAL}s) — skip restart")
        return

    if len(_restart_timestamps) >= MAX_RESTARTS:
        log(
            f"rate limit reached ({MAX_RESTARTS} restarts in {WINDOW_SEC}s "
            "window) — skip restart, a genuinely broken shell must not be "
            "respawned in a loop"
        )
        return

    # Record the timestamp in dry-run too, so the rate limiter is the
    # same code path under test as in production.
    _restart_timestamps.append(now)

    if dry_run:
        log("WOULD RESTART quickshell.service")
        return

    try:
        result = subprocess.run(
            ["systemctl", "--user", "restart", "quickshell.service"],
            check=False,
            timeout=30,
        )
        log(f"restarted quickshell.service (rc={result.returncode})")
    except (OSError, subprocess.TimeoutExpired) as exc:
        log(f"restart attempt failed: {exc}")


def evaluate(dry_run):
    present = bar_surface_present()
    if present is None:
        log("indeterminate — hyprctl layers -j unreadable/non-JSON, no action")
        return
    if present:
        log("bar surface present — no action")
        return
    recover(dry_run)


if MODE == "check":
    present = bar_surface_present()
    if present is True:
        print("present")
        sys.exit(0)
    if present is False:
        print("absent")
        sys.exit(1)
    print("indeterminate")
    sys.exit(2)

# watch / dry-run modes below.
DRY_RUN = MODE == "dry-run"

s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
try:
    s.connect(SOCKET_PATH)
except OSError:
    sys.exit(0)

# Announce liveness once at connect time so the journal always carries
# evidence the watchdog is actually attached and watching, independent
# of whether a monitor event has fired yet — the unit can otherwise run
# for hours in complete silence (correct, but unverifiable at a glance).
log(f"watching {SOCKET_PATH} for monitor events (mode={MODE})")

buf = b""
pending_deadline = None  # time.monotonic() deadline, or None if idle

while True:
    if pending_deadline is None:
        timeout = None  # block at zero CPU until an event arrives
    else:
        timeout = max(0.0, pending_deadline - time.monotonic())

    # select, not a bare recv: one thread has to serve both a blocking
    # read and an expiring debounce timer. timeout=None blocks at zero
    # CPU when nothing is pending; a finite timeout lets the debounce
    # deadline actually expire and be evaluated even if no further event
    # arrives.
    try:
        readable, _, _ = select.select([s], [], [], timeout)
    except OSError:
        break

    if not readable:
        # Empty select result = the debounce expired -> clear the
        # pending deadline and evaluate.
        pending_deadline = None
        evaluate(DRY_RUN)
        continue

    try:
        chunk = s.recv(4096)
    except OSError:
        break

    if not chunk:
        # EOF: the compositor closed the connection (session exit). An
        # unconditional loop around a dead read would peg a core at 100%
        # for the rest of uptime — reproduced verbatim in spirit from the
        # retired listener's own guard. Break, exit 0, never spin.
        break

    buf += chunk
    while b"\n" in buf:
        line, buf = buf.split(b"\n", 1)
        text = line.decode("utf-8", errors="replace")
        event, _, payload = text.partition(">>")
        del payload  # never parsed for non-monitor events, deliberately

        if DRY_RUN:
            log(f"event seen: {event}")

        if event not in MONITOR_EVENTS:
            # Ignore every other event name. Window titles and classes
            # are never parsed here — the payload is not even inspected
            # once the event name fails this check.
            continue

        # A further event before the debounce expires PUSHES the
        # deadline out — a sleep/wake burst collapses into one judgement,
        # and the surface gets time to settle before it is judged
        # missing.
        pending_deadline = time.monotonic() + DEBOUNCE

sys.exit(0)
PYEOF
