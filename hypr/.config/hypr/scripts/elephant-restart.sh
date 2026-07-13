#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              ELEPHANT-RESTART                        ║
# ║  Cycles the elephant daemon + walker's gapplication   ║
# ║  service together (RESEARCH Pitfall 3: elephant scans ║
# ║  ~/.config/elephant/menus/ ONCE at startup, no hot-    ║
# ║  reload). Restarting elephant alone would leave walker ║
# ║  talking to a stale/closed socket, so both are cycled  ║
# ║  here, mirroring theme-engine/lib/reload.sh's kill/    ║
# ║  relaunch/bounded-poll idiom.                          ║
# ╚══════════════════════════════════════════════════════╝

set -uo pipefail

log() { echo "elephant-restart: $*"; }

# ── Restart elephant ──────────────────────────────────
if pgrep -x elephant >/dev/null 2>&1; then
    pkill -x elephant 2>/dev/null || true
fi

waited=0
while pgrep -x elephant >/dev/null 2>&1 && (( waited < 20 )); do
    sleep 0.1
    waited=$(( waited + 1 ))
done

setsid uwsm app -- elephant >/dev/null 2>&1 </dev/null &
disown

# Bounded readiness poll — the real signal is `elephant listproviders`
# actually responding, not a bare sleep (per Task 3's explicit mandate).
ewaited=0
elephant_up=0
while (( ewaited < 50 )); do
    if elephant listproviders >/dev/null 2>&1; then
        elephant_up=1
        break
    fi
    sleep 0.1
    ewaited=$(( ewaited + 1 ))
done

if [[ "$elephant_up" != "1" ]]; then
    notify-send -a "Elephant" "Error" "elephant did not come back up after restart" -i dialog-error -t 6000 2>/dev/null || true
    log "FAILED — elephant did not respond to 'elephant listproviders' within 5s"
    exit 1
fi

# ── Restart walker's gapplication service so it reconnects to the new
#    elephant socket instead of a stale one ───────────────────────────
if pgrep -x walker >/dev/null 2>&1; then
    pkill -x walker 2>/dev/null || true
fi

wwaited=0
while pgrep -x walker >/dev/null 2>&1 && (( wwaited < 20 )); do
    sleep 0.1
    wwaited=$(( wwaited + 1 ))
done

setsid uwsm app -- walker --gapplication-service >/dev/null 2>&1 </dev/null &
disown

# Bounded poll: process-alive is the best readiness signal available for
# walker's own service (no listproviders-equivalent on this side).
lwaited=0
walker_up=0
while (( lwaited < 20 )); do
    if pgrep -x walker >/dev/null 2>&1; then
        walker_up=1
        break
    fi
    sleep 0.1
    lwaited=$(( lwaited + 1 ))
done

if [[ "$walker_up" != "1" ]]; then
    notify-send -a "Walker" "Error" "walker service did not come back up after elephant restart" -i dialog-error -t 6000 2>/dev/null || true
    log "FAILED — walker did not relaunch within 2s"
    exit 1
fi

log "elephant + walker cycled successfully"
exit 0
