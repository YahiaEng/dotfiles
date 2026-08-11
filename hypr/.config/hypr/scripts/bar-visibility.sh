#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║             BAR VISIBILITY OWNER (D-18-23/27/28)      ║
# ║  The SOLE owner of the QML bar's visibility state.     ║
# ║  Four actors (idle listener, fullscreen reporter,       ║
# ║  gaming-mode, keybind) declare an INTENT here; this     ║
# ║  script computes the resulting state and actuates the   ║
# ║  bar over Quickshell IPC. No actor may ever call         ║
# ║  `qs ipc call bar <verb>` directly — that is the exact   ║
# ║  desync bug class this repo has already deleted twice    ║
# ║  (this script's own pre-rename form, then                ║
# ║  wallpaper-visibility.sh).                                ║
# ║  This is the same proven state machine, renamed —        ║
# ║  D-18-27's whole point is that it is carried across, not ║
# ║  rebuilt, because on-disk state survives the QBAR-10      ║
# ║  restarts in-process state would not, hypridle is an      ║
# ║  external daemon that invokes a command line no matter    ║
# ║  what, and there are live callers across four files that  ║
# ║  would all otherwise have to move.                        ║
# ╚══════════════════════════════════════════════════════╝
#
# Silent infrastructure — zero user-facing toast calls anywhere (UI-SPEC
# Copywriting Contract: the bar appearing/disappearing IS the feedback).
#
# CLI contract:
#   bar-visibility.sh <idle|fullscreen|gaming> <hide|show>
#       A source declares its own intent. <source> is validated against a
#       strict, fixed allowlist BEFORE it is ever used to build a path
#       (T-08-05, carried through verbatim from the pre-rename owner) — it
#       becomes part of a filename under ~/.cache/bar-visibility.d/, so an
#       unvalidated value could write outside that directory.
#   bar-visibility.sh keybind toggle
#       The explicit bar-toggle bind (D-18-29, still a Hyprland compositor
#       bind, never a QML GlobalShortcut). Sets an override to the
#       opposite of whatever is currently computed, recording the base
#       union in effect at that moment — see the override model below.
#   bar-visibility.sh reassert
#       Recompute from the existing intent files and re-actuate over IPC,
#       changing no source's declared intent. Idempotent. This is what
#       theme-engine/lib/reload.sh calls immediately after its own waybar
#       SIGUSR2, and what shell.qml's own startup sequence forces once
#       after declaring its fullscreen intent (D-18-28's ordering
#       contract), so this script's state can never desync from what the
#       bar is actually rendering.
#   bar-visibility.sh status
#       Prints the computed state (visible / hidden-idle / hidden-hard)
#       and exits 0. Read-only with respect to the bar itself — never
#       actuates — but may still self-heal a stale override file it
#       discovers along the way (same computation every other verb uses).
#       `qs ipc call bar status` must print the byte-identical string —
#       that equality IS the single-owner claim made checkable rather
#       than asserted (QBAR-07).
#
# ── State model ──────────────────────────────────────────────────────
# Per-source intent files: ~/.cache/bar-visibility.d/<source>, one per
# source (idle/fullscreen/gaming), each holding the literal string "hide"
# or "show". The four actors can legitimately fire concurrently (a
# fullscreen event and an idle timeout landing in the same instant is a
# real possibility, not theoretical), so this owner serializes the ENTIRE
# read-modify-write — read intents, compute, actuate, record .actuated —
# under a single process-wide advisory lock (flock on .owner.lock,
# blocking; see _acquire_lock / main below), the same idiom
# media-popup-open.sh uses. Only one invocation is ever inside the
# compute→actuate critical section at a time, so the lost-update / torn-
# publish class (WR-01) cannot occur. Every individual file publish is
# ALSO atomic on its own — written to a UNIQUE mktemp'd temp in the same
# directory, then mv'd into place (belt-and-suspenders: no two writers
# ever share a fixed .tmp path). A missing intent file means "show" — the
# safe default, a bar you can see (T-08-17: any file content other than
# the literal "hide" is also treated as "show", never executed or
# interpolated anywhere).
#
# base_union = "hide" if ANY of {idle, fullscreen, gaming} currently say
# hide, else "show" — D-01's "hides on either trigger, returns only when
# BOTH clear," generalised to three sources.
#
# Keybind override file (~/.cache/bar-visibility.d/.override, two lines:
# the override's value, then the base_union that was in effect when it
# was set). While the override exists AND base_union has not changed
# since it was recorded, the override wins over base_union. The instant
# base_union changes, the override is stale and is discarded — an
# override must never outlive the condition it was overriding (D-02).
#
# ── Actuation (Phase 18 Plan 15, QBAR-07) ────────────────────────────
# Three computed states map to three fixed literal IPC verbs against the
# `bar` IpcHandler in shell.qml:
#   computed "visible"     -> the "show" verb
#   computed "hidden-idle" -> the "hideIdle" verb  (zone KEPT — no reflow
#                              during ordinary idle cycles)
#   computed "hidden-hard" -> the "hideHard" verb  (zone RELEASED —
#                              fullscreen, gaming, or the keybind override)
# Both hidden states now draw NOTHING at all — a property of the QML
# surface, not of a stylesheet. The old 5% lit sliver (the opacity
# constant, the CSS-writing helper and the CSS path) is deleted outright
# in this commit, not renamed and not repointed; nothing replaces it.
# `~/.local/state/theme/waybar-visibility.css` now has NO writer at all —
# it is an inert empty stub, retained only so waybar's four stylesheets
# still resolve their @import until RETIRE-02 (18-20) deletes waybar,
# that file, its contract entry and the stow.sh seed together.
#
# Only a differing computed target is actuated (tracked in .actuated) —
# redundant calls are absorbed, never amplified (T-08-18: the fullscreen
# event stream is documented to fire multiple times per transition).
# `reassert` is the one exception: it always re-actuates, because its
# entire purpose is correcting a state the bar's own process may have
# just externally reset without this script's knowledge (e.g. a shell
# restart).
#
# `.actuated` is recorded ONLY when the IPC call succeeds (a change from
# the pre-rename owner, which recorded it unconditionally after a signal
# that could not itself fail this visibly): a failed actuation against a
# dead or restarting shell leaves the previous target standing, so the
# NEXT event retries instead of the failure being silently absorbed as
# already-done. The shell's own startup reassert (shell.qml,
# Component.onCompleted) is the second recovery path, covering a full
# restart rather than a transient failure — the two together cover both
# failure modes.

set -euo pipefail

INTENT_DIR="$HOME/.cache/bar-visibility.d"
OVERRIDE_FILE="$INTENT_DIR/.override"
ACTUATED_FILE="$INTENT_DIR/.actuated"
LOCK_FILE="$INTENT_DIR/.owner.lock"

# ── Serialize the whole read-modify-write (WR-01) ────────────────────
# A BLOCKING flock (never -n: an event must be processed, never dropped)
# held for the duration of every verb, so two actors firing close
# together run their compute→actuate strictly one after the other rather
# than interleaving a lost update or a torn publish. fd 8 stays open for
# the process lifetime; the lock releases automatically on exit. If flock
# is somehow unavailable the RMW still runs (unlocked) — the unique-temp
# writes keep each individual publish atomic, degrading to the old
# behaviour rather than failing closed and freezing the bar.
_acquire_lock() {
    exec 8>"$LOCK_FILE" || return 0
    flock 8 2>/dev/null || true
}

# ── Atomic single-line writes (unique-temp + mv, WR-01) ──────────────
# Every publish writes to a UNIQUE mktemp'd temp in the target's own
# directory (never a fixed `.tmp` shared across concurrent callers) and
# then mv's it into place — a same-filesystem atomic rename. Combined
# with the process-wide flock main() holds, a torn or lost publish is
# impossible even when four actors fire in the same instant.
_write_intent() {
    local source="$1" value="$2"
    local tmp
    tmp="$(mktemp "$INTENT_DIR/.$source.XXXXXX")"
    printf '%s\n' "$value" > "$tmp" && mv -f "$tmp" "$INTENT_DIR/$source"
}

_read_intent() {
    local source="$1"
    cat "$INTENT_DIR/$source" 2>/dev/null || echo "show"
}

_write_override() {
    local value="$1" base_at_set="$2"
    local tmp
    tmp="$(mktemp "$INTENT_DIR/.override.XXXXXX")"
    printf '%s\n%s\n' "$value" "$base_at_set" > "$tmp" && mv -f "$tmp" "$OVERRIDE_FILE"
}

_write_actuated() {
    local target="$1"
    local tmp
    tmp="$(mktemp "$INTENT_DIR/.actuated.XXXXXX")"
    printf '%s\n' "$target" > "$tmp" && mv -f "$tmp" "$ACTUATED_FILE"
}

# ── Compute the current state ────────────────────────────────────────
# Sets: BASE_UNION (show|hide), HIDE_SOURCES (array of sources currently
# saying hide), COMPUTED (show|hide), OVERRIDE_ACTIVE (0|1), STATUS
# (visible|hidden-idle|hidden-hard). Self-heals a stale override file as
# a side effect (an override whose recorded base_at_set no longer
# matches the live base_union) — safe for read-only callers (`status`)
# since discarding a dead file is idempotent and never itself actuates
# the bar.
_compute() {
    HIDE_SOURCES=()
    local s
    for s in idle fullscreen gaming; do
        if [[ "$(_read_intent "$s")" == "hide" ]]; then
            HIDE_SOURCES+=("$s")
        fi
    done

    if [[ ${#HIDE_SOURCES[@]} -gt 0 ]]; then
        BASE_UNION="hide"
    else
        BASE_UNION="show"
    fi

    local override_value="" override_base_at_set=""
    if [[ -f "$OVERRIDE_FILE" ]]; then
        { read -r override_value; read -r override_base_at_set; } < "$OVERRIDE_FILE" 2>/dev/null || true
    fi

    if [[ -n "$override_value" && "$override_base_at_set" == "$BASE_UNION" ]]; then
        COMPUTED="$override_value"
        OVERRIDE_ACTIVE=1
    else
        if [[ -n "$override_value" ]]; then
            # Stale: the condition this override was overriding has
            # changed since it was set. An override must never outlive
            # the condition it was overriding (D-02).
            rm -f "$OVERRIDE_FILE" 2>/dev/null || true
        fi
        COMPUTED="$BASE_UNION"
        OVERRIDE_ACTIVE=0
    fi

    if [[ "$COMPUTED" == "show" ]]; then
        STATUS="visible"
    else
        # D-04: a hard-hiding source (fullscreen/gaming) among the
        # CURRENTLY declared intents always dominates a mere idle dim.
        # An active override forcing "hide" is also hard — by
        # construction (see _cmd_keybind_toggle below) an active override
        # only exists when base_union hasn't changed since it flipped
        # the PREVIOUSLY computed value, so an active override's value
        # never equals a bare idle-only base_union; treating any
        # override-driven hide as an explicit, hard, want-the-pixels-back
        # action (never a mere idle hide) is the correct, conservative
        # reading.
        if [[ "$OVERRIDE_ACTIVE" -eq 0 && ${#HIDE_SOURCES[@]} -eq 1 && "${HIDE_SOURCES[0]}" == "idle" ]]; then
            STATUS="hidden-idle"
        else
            STATUS="hidden-hard"
        fi
    fi
}

# ── Actuate via Quickshell IPC (Phase 18 Plan 15, QBAR-07) ───────────
# Bounded call to the `bar` IpcHandler in shell.qml — the actuation tail
# that replaces the pre-rename owner's two `pkill -SIGUSR*` signal lines.
# The bound is load-bearing, not defensive: this call runs INSIDE the
# flock the whole read-modify-write is holding (see main()'s
# _acquire_lock below), so an unresponsive/hung shell without a bound
# would wedge every other actor (hypridle, gaming mode, the keybind,
# reload.sh) behind it indefinitely — a failure the signal-based
# actuation it replaces could never have had, because a signal returns
# immediately regardless of whether anything is listening. Returns the
# IPC call's own exit status; discards both output streams.
_ipc_call() {
    local verb="$1"
    timeout 2 qs ipc call bar "$verb" >/dev/null 2>&1
}

# ── Actuate the computed state ───────────────────────────────────────
# force=1 (reassert) always re-actuates; force=0 (every other verb) skips
# the actuation when the computed target already matches the last
# actuated target (T-08-18: absorb redundant calls, never amplify them).
_actuate() {
    local force="$1"
    _compute

    local target
    case "$STATUS" in
        visible) target="visible" ;;
        hidden-idle) target="hidden-idle" ;;
        hidden-hard) target="hidden-hard" ;;
    esac

    if [[ "$force" -ne 1 ]]; then
        local last
        last="$(cat "$ACTUATED_FILE" 2>/dev/null || echo "")"
        if [[ "$last" == "$target" ]]; then
            return 0
        fi
    fi

    # Each branch passes a fixed literal verb to _ipc_call — never a
    # variable built from anything — so no external value reaches the
    # IPC command at all. Captured through an `if` rather than a bare
    # invocation so a failed call does not trip this script's own
    # `errexit` and abort the critical section on a dead shell.
    local ok=0
    case "$target" in
        visible)     if _ipc_call show;     then ok=1; fi ;;
        hidden-idle) if _ipc_call hideIdle; then ok=1; fi ;;
        hidden-hard) if _ipc_call hideHard; then ok=1; fi ;;
    esac

    # Record .actuated ONLY on a successful actuation: a failed call
    # leaves the previous target standing, so the next event retries
    # rather than the failure being silently absorbed as already-done.
    # The shell's own startup reassert is the second recovery path,
    # covering a full restart rather than a transient failure.
    if [[ "$ok" -eq 1 ]]; then
        _write_actuated "$target"
    fi
}

_cmd_keybind_toggle() {
    _compute
    local new_override_value
    if [[ "$COMPUTED" == "show" ]]; then
        new_override_value="hide"
    else
        new_override_value="show"
    fi
    _write_override "$new_override_value" "$BASE_UNION"
}

main() {
    mkdir -p "$INTENT_DIR"
    # WR-01: take the owner lock BEFORE reading any intent, so the entire
    # compute→actuate critical section is serialized against the other
    # three actors. Must follow `mkdir -p "$INTENT_DIR"` (the lock file
    # lives inside it).
    _acquire_lock

    local verb="${1:-}"

    case "$verb" in
        status)
            _compute
            echo "$STATUS"
            ;;
        reassert)
            _actuate 1
            ;;
        keybind)
            local action="${2:-}"
            if [[ "$action" != "toggle" ]]; then
                echo "bar-visibility.sh: 'keybind' requires 'toggle'" >&2
                exit 1
            fi
            _cmd_keybind_toggle
            _actuate 0
            ;;
        idle|fullscreen|gaming)
            local state="${2:-}"
            if [[ "$state" != "hide" && "$state" != "show" ]]; then
                echo "bar-visibility.sh: '$verb' requires 'hide' or 'show'" >&2
                exit 1
            fi
            _write_intent "$verb" "$state"
            _actuate 0
            ;;
        *)
            # T-08-05: reject BEFORE any path is ever built from this
            # value — <source> is only ever used inside the matched
            # branches above, never here.
            echo "bar-visibility.sh: unknown source/verb '$verb' (expected idle|fullscreen|gaming|keybind|reassert|status)" >&2
            exit 1
            ;;
    esac
}

main "$@"
