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
# ║                                                        ║
# ║  Stow-parity guard (07-05 root-cause fix): adding a    ║
# ║  new menu TOML to the repo is a silent no-op until      ║
# ║  `stow` is re-run — ~/.config/elephant/menus/ holds     ║
# ║  file-level symlinks (folded because the dir pre-       ║
# ║  existed), so a repo-side TOML with no live symlink is  ║
# ║  invisible to elephant while every repo-side gate stays ║
# ║  green. Checked BEFORE cycling elephant, self-heals via ║
# ║  `stow --restow`, and refuses to proceed on a still-     ║
# ║  broken tree rather than restart into a known-bad state.║
# ╚══════════════════════════════════════════════════════╝

set -uo pipefail

log() { echo "elephant-restart: $*"; }

# ── Resolve repo root (script is reached via a stow symlink) ─────────
# readlink -f follows the symlink at ~/.config/hypr/scripts/elephant-restart.sh
# to its real path inside the repo: <repo>/hypr/.config/hypr/scripts/elephant-restart.sh.
# Four levels up from that file's directory is the repo root. Never hardcode
# the repo path — this must work under any clone location.
SCRIPT_REAL=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "$SCRIPT_REAL")
REPO_ROOT=$(cd "$SCRIPT_DIR/../../../.." && pwd)
REPO_MENUS_DIR="$REPO_ROOT/elephant/.config/elephant/menus"
LIVE_MENUS_DIR="$HOME/.config/elephant/menus"

# ── Stow-parity guard: every repo menu TOML must have a live counterpart ──
check_menu_parity() {
    local missing=()
    local f name
    if [[ ! -d "$REPO_MENUS_DIR" ]]; then
        log "WARNING — repo menus dir not found at $REPO_MENUS_DIR, skipping parity check"
        return 0
    fi
    for f in "$REPO_MENUS_DIR"/*.toml; do
        [[ -e "$f" ]] || continue
        name=$(basename "$f")
        if [[ ! -e "$LIVE_MENUS_DIR/$name" ]]; then
            missing+=("$name")
        fi
    done
    if (( ${#missing[@]} > 0 )); then
        log "PARITY FAILED — missing from $LIVE_MENUS_DIR: ${missing[*]}"
        return 1
    fi
    return 0
}

if ! check_menu_parity; then
    if ! command -v stow >/dev/null 2>&1; then
        notify-send -a "Elephant" "Error" "menu TOML(s) not stowed and 'stow' is not on PATH — run: stow --restow elephant --target=\$HOME" -i dialog-error -t 8000 2>/dev/null || true
        log "FAILED — stow not on PATH; manual fix: (cd \"$REPO_ROOT\" && stow --restow elephant --target=\"\$HOME\")"
        exit 1
    fi
    log "auto-healing — re-stowing elephant package to restore missing menu symlink(s)"
    ( cd "$REPO_ROOT" && stow --restow elephant --target="$HOME" ) 2>&1 | while IFS= read -r line; do log "stow: $line"; done
    if ! check_menu_parity; then
        notify-send -a "Elephant" "Error" "menu TOML(s) still missing from ~/.config/elephant/menus/ after restow — not restarting elephant into a known-broken state" -i dialog-error -t 8000 2>/dev/null || true
        log "FAILED — parity guard still failing after 'stow --restow elephant'; refusing to cycle elephant"
        exit 1
    fi
    log "parity restored — all repo menu TOMLs now have live symlinks"
fi

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
