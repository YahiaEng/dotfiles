#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║          WALLPAPER VISIBILITY OWNER (D-14/AMB-01)     ║
# ║  The SOLE owner of the live-wallpaper player's process ║
# ║  lifecycle. Every actor (idle watcher, gaming mode,     ║
# ║  reduced-motion, the picker, theme-apply) declares an   ║
# ║  INTENT here; this script computes the resulting state  ║
# ║  and starts/stops mpvpaper accordingly. No actor may     ║
# ║  ever start or kill mpvpaper directly — that is the      ║
# ║  exact desync bug class bar-visibility.sh (Phase 8,      ║
# ║  D-03, renamed Phase 18 Plan 15) already proved out and   ║
# ║  this script mirrors.                                     ║
# ╚══════════════════════════════════════════════════════╝
#
# CLI contract:
#   wallpaper-visibility.sh <idle|gaming|motion> <hide|show>
#       A suppression source declares its own intent. <source> is
#       validated against a strict, fixed allowlist BEFORE it is ever
#       used to build a path (T-08-05 discipline, carried over from
#       bar-visibility.sh) — it becomes part of a filename under
#       ~/.cache/wallpaper-visibility.d/, so an unvalidated value could
#       write outside that directory. Call sites for these three names
#       land in 17-03 (D-30 idle, D-28 gaming, D-31 reduced motion) — this
#       plan declares the names and their arbitration only, wires no
#       caller. A fourth name, `fullscreen`, is added to this allowlist
#       ONLY if the D-27 fallback watcher is built (see
#       wallpaper-fullscreen-watch.sh header if present).
#   wallpaper-visibility.sh select <absolute-path>
#       Record the live wallpaper to play. Validated BEFORE anything is
#       written anywhere (T-17-01) — see _validate_selection below. This
#       is the one argument in the whole system that ends up on an
#       external player's argv, so it is re-validated on every _compute,
#       never trusted from a prior write.
#   wallpaper-visibility.sh clear
#       Drop the current selection (falls back to "stopped").
#   wallpaper-visibility.sh reassert
#       Recompute from the existing intent files and selection, and
#       force re-actuation even if the target already matches
#       .actuated. Idempotent. Mirrors bar-visibility.sh's `reassert`
#       — theme-apply's wallpaper step should call this after selecting
#       a new live wallpaper so a switch can never desync the owner's
#       process state from what is actually on disk.
#   wallpaper-visibility.sh status
#       Prints the computed state (`stopped` or `playing:<path>`) and
#       exits 0. Read-only with respect to the player itself — never
#       starts/stops it — but still runs the same _compute every other
#       verb uses, including selection re-validation.
#   wallpaper-visibility.sh snapshot
#       D-20/17-03 Task 3: records the CURRENT (re-validated) selection
#       state into a snapshot file for a later `restore`. Actuates
#       nothing. When no selection is currently valid, records a fixed
#       sentinel meaning "no live wallpaper was selected".
#   wallpaper-visibility.sh restore
#       D-20/17-03 Task 3: resolves the snapshot to exactly ONE action —
#       when the stored value still passes _validate_selection it behaves
#       as `select` on that path; in every other case (sentinel, missing
#       file, or a path that no longer validates) it behaves as `clear`.
#       Failing closed to `clear` is deliberate: a snapshot pointing at a
#       file the user deleted mid-picker must end with NO player, never a
#       stale one. This is D-20's "single restore intent" — callers never
#       branch on live-versus-still to decide which verb to send.
#
# ── State model ──────────────────────────────────────────────────────
# Per-source intent files: ~/.cache/wallpaper-visibility.d/<source>, one
# per source (idle/gaming/motion[/fullscreen]), each holding the literal
# string "hide" or "show". These can legitimately fire concurrently (an
# idle timeout and a gaming-mode toggle landing in the same instant is a
# real possibility, not theoretical), so this owner serializes the
# ENTIRE read-modify-write — read intents + selection, compute, actuate,
# record .actuated — under a single process-wide advisory lock (flock on
# .owner.lock, blocking; see _acquire_lock / main below), the exact idiom
# bar-visibility.sh already proved in production (T-17-03). Every
# individual file publish is ALSO atomic on its own — written to a
# UNIQUE mktemp'd temp in the same directory, then mv'd into place. A
# missing intent file means "show" — the safe default (a wallpaper you
# can see), same convention as the analog.
#
# BASE_UNION = "hide" if ANY of {idle, gaming, motion[, fullscreen]}
# currently says hide, else "show" — the same union-of-sources rule
# bar-visibility.sh uses, generalised to this owner's source set.
#
# The actuation target is "stopped" when BASE_UNION is hide, or when no
# selection is currently recorded/valid; otherwise it is
# "playing:<absolute-path>".
#
# ── D-29 deviation from the bar analog, stated explicitly (updated
#    Phase 18 Plan 15 for the analog's rename and actuation swap) ─────
# bar-visibility.sh actuates over Quickshell IPC (`qs ipc call bar
# <verb>`) against a QML process that is already running and rendering
# continuously. This owner actuates by STARTING and STOPPING a process
# instead — mpvpaper is not a persistent daemon the rest of the system
# already keeps alive, so there is no running target to send a verb to
# when the intent is "stopped".
# Pausing/resuming the actual video during a hard hide (fullscreen etc)
# is mpvpaper's OWN internal job via `-p -a full` (RESEARCH.md Deep-Dive
# #1) — this script must NEVER write mpv's playback-suspend ("pause")
# property and must NEVER open an mpv IPC socket (no --input-ipc-server
# anywhere in this file). Two independent writers to one `pause`
# property is the exact two-sources-of-truth bug class Phase 8 already
# deleted once (D-03's single-owner rule exists precisely to prevent
# it) — enable gaming mode, close the fullscreen window, and this
# script's OWN suppression logic would race mpvpaper's fullscreen
# handling to un-pause. Consequence, recorded here rather than
# discovered later: this owner's own suppression states (idle/gaming/
# motion[/fullscreen fallback]) restart the loop from the beginning
# every time, because stopping and relaunching the process is the only
# lever this owner has. ONLY the primary `-p -a full` fullscreen path
# (mpvpaper's own internal pause, never touched by this script) can
# preserve playback position.

set -euo pipefail

# ── Tunable constants ────────────────────────────────────────────────
# D-16 (no-audio, hwdec) + Pitfall 3 (loop-file=inf is mandatory — mpvpaper
# only auto-loops in slideshow mode) + T-17-04 (stop-screensaver=no is a
# planner addition beyond D-16's literal flag list: mpv's stop-screensaver
# defaults to yes, which would make the player send Wayland idle-inhibit
# and silently defeat hypridle's dim/lock chain and D-30's own idle
# suppression — confirmed present on the installed mpv binary via
# `mpv --list-options` before being trusted here; see the plan SUMMARY for
# the recorded confirmation).
MPV_OPTS="no-audio loop-file=inf hwdec=auto-safe stop-screensaver=no"

INTENT_DIR="$HOME/.cache/wallpaper-visibility.d"
LOCK_FILE="$INTENT_DIR/.owner.lock"
ACTUATED_FILE="$INTENT_DIR/.actuated"
SELECTION_FILE="$INTENT_DIR/.selection"
SNAPSHOT_FILE="$INTENT_DIR/.snapshot"
# Fixed sentinel meaning "no live wallpaper was selected" — distinct from
# any real path, so a snapshot taken from a still-only state round-trips
# correctly through `restore` (D-20).
SNAPSHOT_SENTINEL="__none__"

# D-02: the only directory a selection may ever resolve inside.
WALLPAPERS_ROOT="$HOME/Pictures/Wallpapers"

# ── Serialize the whole read-modify-write (T-17-03) ──────────────────
# A BLOCKING flock (never -n: an intent must be processed, never
# dropped) held for the duration of every verb, so concurrent sources
# firing close together run their compute→actuate strictly one after
# the other rather than interleaving a lost update or spawning two
# players. fd 8 stays open for the process lifetime; the lock releases
# automatically on exit.
_acquire_lock() {
    exec 8>"$LOCK_FILE" || return 0
    flock 8 2>/dev/null || true
}

# ── Atomic single-line writes (unique-temp + mv) ─────────────────────
# WR-04: each write is wrapped so a failed `printf` (disk full,
# permissions) never leaves the mktemp'd file behind — the `&&` chain's
# own failure is caught by the enclosing `{ ...; } ||` and cleaned up,
# rather than the failing redirect's temp file silently orphaning inside
# $INTENT_DIR forever.
_write_intent() {
    local source="$1" value="$2"
    local tmp
    tmp="$(mktemp "$INTENT_DIR/.$source.XXXXXX")"
    { printf '%s\n' "$value" >"$tmp" && mv -f "$tmp" "$INTENT_DIR/$source"; } || rm -f "$tmp"
}

_read_intent() {
    local source="$1"
    cat "$INTENT_DIR/$source" 2>/dev/null || echo "show"
}

_write_selection() {
    local value="$1"
    local tmp
    tmp="$(mktemp "$INTENT_DIR/.selection.XXXXXX")"
    { printf '%s\n' "$value" >"$tmp" && mv -f "$tmp" "$SELECTION_FILE"; } || rm -f "$tmp"
}

_read_selection() {
    cat "$SELECTION_FILE" 2>/dev/null || true
}

_write_actuated() {
    local target="$1"
    local tmp
    tmp="$(mktemp "$INTENT_DIR/.actuated.XXXXXX")"
    { printf '%s\n' "$target" >"$tmp" && mv -f "$tmp" "$ACTUATED_FILE"; } || rm -f "$tmp"
}

_write_snapshot() {
    local value="$1"
    local tmp
    tmp="$(mktemp "$INTENT_DIR/.snapshot.XXXXXX")"
    { printf '%s\n' "$value" >"$tmp" && mv -f "$tmp" "$SNAPSHOT_FILE"; } || rm -f "$tmp"
}

_read_snapshot() {
    cat "$SNAPSHOT_FILE" 2>/dev/null || true
}

# ── T-17-01: the selection validator ─────────────────────────────────
# This argument ends up on an external player's argv. Normalise with
# `realpath -m --no-symlinks` (lexical `..` resolution, links never
# followed — blocks traversal while still allowing a user's own
# symlinked video inside live/), then require ALL of:
#   1. the normalised path is under $WALLPAPERS_ROOT
#   2. the basename of its parent directory is exactly "live"
#   3. the target is a regular file
# On success, prints the normalised path on stdout and returns 0. On
# failure, prints nothing and returns 1 — the caller must never write an
# unvalidated value anywhere.
_validate_selection() {
    local raw="$1"
    local normalized
    normalized="$(realpath -m --no-symlinks -- "$raw" 2>/dev/null)" || return 1
    [[ -n "$normalized" ]] || return 1

    case "$normalized" in
    "$WALLPAPERS_ROOT"/*) ;;
    *) return 1 ;;
    esac

    local parent_dir parent_base
    parent_dir="$(dirname "$normalized")"
    parent_base="$(basename "$parent_dir")"
    [[ "$parent_base" == "live" ]] || return 1

    [[ -f "$normalized" ]] || return 1

    printf '%s' "$normalized"
}

# ── Compute the current state ────────────────────────────────────────
# Sets: BASE_UNION (show|hide), HIDE_SOURCES (array of sources currently
# saying hide), SELECTION (validated absolute path or empty), TARGET
# (stopped|playing:<path>). The selection is RE-validated here on every
# call, never trusted from a prior write — a file deleted or edited out
# from under a stale .selection must never reach mpvpaper's argv.
_compute() {
    HIDE_SOURCES=()
    local s
    for s in idle gaming motion; do
        if [[ "$(_read_intent "$s")" == "hide" ]]; then
            HIDE_SOURCES+=("$s")
        fi
    done

    if [[ ${#HIDE_SOURCES[@]} -gt 0 ]]; then
        BASE_UNION="hide"
    else
        BASE_UNION="show"
    fi

    SELECTION="$(_read_selection)"
    if [[ -n "$SELECTION" ]]; then
        local rechecked
        if rechecked="$(_validate_selection "$SELECTION")"; then
            SELECTION="$rechecked"
        else
            SELECTION=""
        fi
    fi

    if [[ "$BASE_UNION" == "hide" || -z "$SELECTION" ]]; then
        TARGET="stopped"
    else
        TARGET="playing:$SELECTION"
    fi
}

# A bare `pgrep -x mpvpaper` is NOT a safe liveness/single-instance
# check: a defunct (zombie) mpvpaper still matches by name — its comm
# stays "mpvpaper" until its parent reaps it — but it is not running,
# not decoding, and not rendering anything. Found live during this
# plan's own proof: killing a standalone probe instance left a `Zsl`
# zombie sitting alongside the owner's real `Ssl` process, which would
# have made every pgrep-based check below unreliable (the single-
# instance guard would think a launch is unnecessary, the stop-side
# wait would spin its full bound against a process that can never
# change state, and — worst — the post-launch registration wait would
# return immediately on the STALE zombie match instead of actually
# waiting for the NEW process to appear). Filters to processes whose
# `ps -o stat=` does not start with `Z`.
_mpvpaper_running() {
    local pid stat
    for pid in $(pgrep -x mpvpaper 2>/dev/null); do
        stat="$(ps -o stat= -p "$pid" 2>/dev/null)"
        case "$stat" in
        Z*) continue ;;
        *) return 0 ;;
        esac
    done
    return 1
}

# Bounded wait for mpvpaper to actually exit before a relaunch is
# allowed to proceed — so a relaunch can never race a still-dying
# process into two layer surfaces (T-17-03). Escalates to SIGKILL if
# the graceful SIGTERM window expires. Found live during this plan's
# own Task 3 proof: a heavily CPU-loaded webp_anim decode (measured
# 260-300% CPU — a real characteristic of animated-WebP playback, not
# an anomaly) did NOT respond to plain SIGTERM within the original 2s
# bound (confirmed independently: still alive 3s after a manual `kill
# -TERM`), so the bounded wait timed out, gave up, and the caller
# proceeded to launch a SECOND process — two real mpvpaper processes
# and two `mpvpaper`-namespaced layer surfaces existed simultaneously.
# A plain SIGTERM cannot be relied on to be prompt against a CPU-bound
# decode; SIGKILL can neither be caught nor deferred by the target, and
# was confirmed live to terminate the same stuck process within ~1s.
_stop_player() {
    pkill -x mpvpaper 2>/dev/null || true
    local waited=0
    while _mpvpaper_running && ((waited < 20)); do
        sleep 0.1
        waited=$((waited + 1))
    done

    if _mpvpaper_running; then
        pkill -9 -x mpvpaper 2>/dev/null || true
        waited=0
        while _mpvpaper_running && ((waited < 20)); do
            sleep 0.1
            waited=$((waited + 1))
        done
    fi
}

# ── Actuate the computed state ───────────────────────────────────────
# force=1 (reassert) always re-actuates; force=0 (every other verb)
# skips when the computed target already matches the last actuated
# target (absorb redundant calls, never amplify them — same rule as the
# waybar analog's T-08-18).
_actuate() {
    local force="$1"
    _compute

    if [[ "$force" -ne 1 ]]; then
        local last
        last="$(cat "$ACTUATED_FILE" 2>/dev/null || echo "")"
        if [[ "$last" == "$TARGET" ]]; then
            return 0
        fi
    fi

    case "$TARGET" in
    stopped)
        _stop_player
        ;;
    playing:*)
        local path="${TARGET#playing:}"
        # Stop first if anything is running — never let two mpvpaper
        # processes (and two layer surfaces) exist at once. Zombie-
        # excluding check (_mpvpaper_running) — see its own header.
        if _mpvpaper_running; then
            _stop_player
        fi
        # Argv ARRAY, expanded "${cmd[@]}" — never a single string, never
        # eval (T-17-01). Matches how every other session process this
        # repo launches goes through `uwsm app --` (D-15); `setsid ... &
        # disown` detaches it from this script's own process group, the
        # same idiom elephant-restart.sh already uses to launch a
        # long-running process and return control immediately. Plays on
        # every output via the literal '*' (D-22).
        #
        # `8>&-` is load-bearing, not decoration: without it, this
        # long-running child INHERITS fd 8 (the open flock reference
        # main() holds via _acquire_lock) across the fork/exec boundary.
        # A backgrounded child that outlives this script keeps that fd
        # open indefinitely, which keeps the blocking flock held forever
        # — every LATER invocation of this script (idle/gaming/motion/
        # select/reassert/status, all of which call _acquire_lock before
        # doing anything else) would then hang permanently waiting on a
        # lock a live wallpaper process doesn't even know it's holding.
        # Found live during this plan's own tracer proof: a `select` then
        # `reassert` deadlocked exactly this way until fd 8 was closed
        # for the spawned child.
        local cmd=(uwsm app -- mpvpaper -p -a full -o "$MPV_OPTS" '*' "$path")
        setsid "${cmd[@]}" >/dev/null 2>&1 </dev/null 8>&- &
        disown
        # Bounded wait for the launch to actually register — symmetric to
        # _stop_player's own bounded wait for exit, and load-bearing for
        # the same reason. The launch above is asynchronous (uwsm goes
        # through a systemd-run scope before the real mpvpaper binary
        # appears to `pgrep`); without this wait, a rapid CONSECUTIVE
        # invocation's own `_mpvpaper_running` check above can run
        # before this one has finished starting, see nothing running, and
        # launch a SECOND process instead of recognising the first —
        # found live during this plan's own tracer proof running
        # `reassert` twice back to back. Zombie-excluding check
        # (_mpvpaper_running) — a stale defunct entry from an EARLIER
        # instance would otherwise satisfy a bare pgrep immediately,
        # making this wait return before the NEW process is actually up.
        local waited=0
        while ! _mpvpaper_running && ((waited < 30)); do
            sleep 0.1
            waited=$((waited + 1))
        done
        ;;
    esac

    _write_actuated "$TARGET"
}

_cmd_select() {
    local raw="${1:-}"
    # IN-02: enforce the documented contract (not just an empty check) —
    # a relative path previously fell through to _validate_selection's
    # own realpath(1) normalisation, which resolves it against this
    # process's CWD, so the exact same relative argument could accept or
    # reject depending on the caller's CWD at invocation time. Reject it
    # outright here instead, matching the error message that already
    # claims this requirement.
    if [[ -z "$raw" || "$raw" != /* ]]; then
        echo "wallpaper-visibility.sh: 'select' requires an absolute path" >&2
        exit 1
    fi

    local validated
    if ! validated="$(_validate_selection "$raw")"; then
        echo "wallpaper-visibility.sh: rejected selection '$raw' — must be a regular file directly inside \$HOME/Pictures/Wallpapers/<theme>/live/" >&2
        exit 1
    fi

    _write_selection "$validated"
    _actuate 0
}

_cmd_clear() {
    rm -f "$SELECTION_FILE" 2>/dev/null || true
    _actuate 0
}

# D-20/17-03 Task 3: records the CURRENTLY VALID selection (via _compute,
# the same re-validation every other verb uses) — never the raw
# .selection file content, so a snapshot never captures a value that was
# about to be silently dropped anyway. Actuates nothing.
_cmd_snapshot() {
    _compute
    if [[ -n "$SELECTION" ]]; then
        _write_snapshot "$SELECTION"
    else
        _write_snapshot "$SNAPSHOT_SENTINEL"
    fi
}

# D-20/17-03 Task 3: resolves to exactly ONE action. Fails CLOSED to
# `clear` for the sentinel, a missing snapshot file, or a stored value
# that no longer passes _validate_selection — reuses that SAME validator,
# never a second path-shape test. A snapshot naming a file the user
# deleted mid-picker must end with no player, never a stale one.
_cmd_restore() {
    local stored validated
    stored="$(_read_snapshot)"
    if [[ -n "$stored" && "$stored" != "$SNAPSHOT_SENTINEL" ]] \
        && validated="$(_validate_selection "$stored")"; then
        _write_selection "$validated"
        _actuate 0
    else
        rm -f "$SELECTION_FILE" 2>/dev/null || true
        _actuate 0
    fi
}

main() {
    mkdir -p "$INTENT_DIR"
    # T-17-03: take the owner lock BEFORE reading any intent or
    # selection, so the entire compute→actuate critical section is
    # serialized against every other actor.
    _acquire_lock

    local verb="${1:-}"

    case "$verb" in
    status)
        _compute
        echo "$TARGET"
        ;;
    reassert)
        _actuate 1
        ;;
    select)
        _cmd_select "${2:-}"
        ;;
    clear)
        _cmd_clear
        ;;
    snapshot)
        _cmd_snapshot
        ;;
    restore)
        _cmd_restore
        ;;
    idle | gaming | motion)
        local state="${2:-}"
        if [[ "$state" != "hide" && "$state" != "show" ]]; then
            echo "wallpaper-visibility.sh: '$verb' requires 'hide' or 'show'" >&2
            exit 1
        fi
        _write_intent "$verb" "$state"
        _actuate 0
        ;;
    *)
        # T-08-05 discipline: reject BEFORE any path is ever built from
        # this value — <source> is only ever used inside the matched
        # branches above, never here.
        echo "wallpaper-visibility.sh: unknown source/verb '$verb' (expected idle|gaming|motion|select|clear|snapshot|restore|reassert|status)" >&2
        exit 1
        ;;
    esac
}

main "$@"
