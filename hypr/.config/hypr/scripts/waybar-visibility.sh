#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║          WAYBAR VISIBILITY OWNER (D-01..05/08)        ║
# ║  The SOLE owner of waybar visibility. Four actors      ║
# ║  (idle watcher, fullscreen watcher, gaming-mode,        ║
# ║  keybind) declare an INTENT here; this script computes  ║
# ║  the resulting state and signals waybar. No actor may   ║
# ║  ever send a raw toggle directly — that is the exact    ║
# ║  desync bug class this repo has already deleted twice   ║
# ║  (see 08-CONTEXT.md D-03). waybar's own on-sigusr1 is    ║
# ║  configured to a FIXED `hide` action (bar-common.jsonc), ║
# ║  never `toggle` — this script is what decides whether    ║
# ║  to send that hide signal or the SIGUSR2 reload/show     ║
# ║  signal, never waybar's own toggle logic.                ║
# ╚══════════════════════════════════════════════════════╝
#
# Silent infrastructure — zero user-facing toast calls anywhere (UI-SPEC
# Copywriting Contract: the bar appearing/disappearing/dimming IS the
# feedback).
#
# CLI contract:
#   waybar-visibility.sh <idle|fullscreen|gaming> <hide|show>
#       A source declares its own intent. <source> is validated against a
#       strict, fixed allowlist BEFORE it is ever used to build a path
#       (T-08-05) — it becomes part of a filename under
#       ~/.cache/waybar-visibility.d/, so an unvalidated value could write
#       outside that directory.
#   waybar-visibility.sh keybind toggle
#       The explicit bar-toggle bind (D-02). Sets an override to the
#       opposite of whatever is currently computed, recording the base
#       union in effect at that moment — see the override model below.
#   waybar-visibility.sh reassert
#       Recompute from the existing intent files and re-signal waybar,
#       changing no source's declared intent. Idempotent. This is what
#       theme-engine/lib/reload.sh calls immediately after its own waybar
#       SIGUSR2, so a theme switch (which resets visibility via the
#       `reload` signal action) can never desync the owner's state.
#   waybar-visibility.sh status
#       Prints the computed state (visible / hidden-idle / hidden-hard)
#       and exits 0. Read-only with respect to waybar itself — never
#       signals — but may still self-heal a stale override file it
#       discovers along the way (same computation every other verb uses).
#
# ── State model ──────────────────────────────────────────────────────
# Per-source intent files: ~/.cache/waybar-visibility.d/<source>, one per
# source (idle/fullscreen/gaming), each holding the literal string "hide"
# or "show". The four actors can legitimately fire concurrently (a
# fullscreen event and an idle timeout landing in the same instant is a
# real possibility, not theoretical), so this owner serializes the ENTIRE
# read-modify-write — read intents, compute, write CSS + signal, record
# .actuated — under a single process-wide advisory lock (flock on
# .owner.lock, blocking; see _acquire_lock / main below), the same idiom
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
# Keybind override file (~/.cache/waybar-visibility.d/.override, two
# lines: the override's value, then the base_union that was in effect
# when it was set). While the override exists AND base_union has not
# changed since it was recorded, the override wins over base_union. The
# instant base_union changes, the override is stale and is discarded —
# an override must never outlive the condition it was overriding (D-02).
#
# ── Actuation (D-04) ─────────────────────────────────────────────────
# computed "show"                         -> truncate the owner's CSS
#                                            file, SIGUSR2 (reload/show).
# computed "hide", ONLY idle is hiding    -> write the dim rule into the
#                                            owner's CSS file, SIGUSR2.
#                                            The surface stays MAPPED —
#                                            exclusive zone KEPT (no
#                                            reflow during normal idle
#                                            cycles).
# computed "hide", fullscreen/gaming (or  -> truncate the CSS file (so a
# an unconditioned manual override) hides    later reveal isn't also
#                                            dimmed), SIGUSR1 (fixed
#                                            `hide` -> true unmap ->
#                                            exclusive zone DROPPED).
# Only signals when the computed actuation target differs from the last
# actuated target (tracked in .actuated) — redundant calls are absorbed,
# never amplified (T-08-18: the fullscreen event stream is documented to
# fire multiple times per transition). `reassert` is the one exception:
# it always re-signals, because its entire purpose is correcting a state
# waybar's own reload signal may have just externally reset without this
# script's knowledge.

set -euo pipefail

# ── Tunable constants ────────────────────────────────────────────────
IDLE_DIM_OPACITY="0.05"

INTENT_DIR="$HOME/.cache/waybar-visibility.d"
OVERRIDE_FILE="$INTENT_DIR/.override"
ACTUATED_FILE="$INTENT_DIR/.actuated"
LOCK_FILE="$INTENT_DIR/.owner.lock"
VISIBILITY_CSS="$HOME/.local/state/theme/waybar-visibility.css"

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

# _write_css <content> — atomic unique-temp+mv (T-08-16). content is
# always a fixed literal assembled in this script, never interpolated
# from any external input — an empty string truncates (reveal), a
# non-empty string is the idle-dim rule (hide).
_write_css() {
    local content="$1"
    local dir tmp
    dir="$(dirname "$VISIBILITY_CSS")"
    tmp="$(mktemp "$dir/.waybar-visibility.css.XXXXXX")"
    if [[ -n "$content" ]]; then
        printf '%s\n' "$content" > "$tmp"
    else
        : > "$tmp"
    fi
    mv -f "$tmp" "$VISIBILITY_CSS"
}

# ── Compute the current state ────────────────────────────────────────
# Sets: BASE_UNION (show|hide), HIDE_SOURCES (array of sources currently
# saying hide), COMPUTED (show|hide), OVERRIDE_ACTIVE (0|1), STATUS
# (visible|hidden-idle|hidden-hard). Self-heals a stale override file as
# a side effect (an override whose recorded base_at_set no longer
# matches the live base_union) — safe for read-only callers (`status`)
# since discarding a dead file is idempotent and never itself signals
# waybar.
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
        # action (never a dim) is the correct, conservative reading.
        if [[ "$OVERRIDE_ACTIVE" -eq 0 && ${#HIDE_SOURCES[@]} -eq 1 && "${HIDE_SOURCES[0]}" == "idle" ]]; then
            STATUS="hidden-idle"
        else
            STATUS="hidden-hard"
        fi
    fi
}

# ── Actuate the computed state (D-04) ────────────────────────────────
# force=1 (reassert) always re-signals; force=0 (every other verb) skips
# the signal when the computed target already matches the last actuated
# target (T-08-18: absorb redundant calls, never amplify them).
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

    case "$target" in
        visible)
            _write_css ""
            pkill -SIGUSR2 waybar 2>/dev/null || true
            ;;
        hidden-idle)
            _write_css "window#waybar { opacity: ${IDLE_DIM_OPACITY}; }"
            pkill -SIGUSR2 waybar 2>/dev/null || true
            ;;
        hidden-hard)
            _write_css ""
            pkill -SIGUSR1 waybar 2>/dev/null || true
            ;;
    esac

    _write_actuated "$target"
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
    mkdir -p "$(dirname "$VISIBILITY_CSS")"
    # WR-01: take the owner lock BEFORE reading any intent, so the entire
    # compute→actuate critical section is serialized against the other
    # three actors. Must follow `mkdir -p "$INTENT_DIR"` (the lock file
    # lives inside it).
    _acquire_lock
    # First-run guarantee (D-06/Task 1): the CSS file must always exist —
    # every style-*.css @imports it, and an unresolvable @import makes
    # GTK3 discard the WHOLE stylesheet. stow.sh seeds it too, but this
    # script must not depend on stow.sh having been (re-)run.
    [[ -f "$VISIBILITY_CSS" ]] || : > "$VISIBILITY_CSS"

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
                echo "waybar-visibility.sh: 'keybind' requires 'toggle'" >&2
                exit 1
            fi
            _cmd_keybind_toggle
            _actuate 0
            ;;
        idle|fullscreen|gaming)
            local state="${2:-}"
            if [[ "$state" != "hide" && "$state" != "show" ]]; then
                echo "waybar-visibility.sh: '$verb' requires 'hide' or 'show'" >&2
                exit 1
            fi
            _write_intent "$verb" "$state"
            _actuate 0
            ;;
        *)
            # T-08-05: reject BEFORE any path is ever built from this
            # value — <source> is only ever used inside the matched
            # branches above, never here.
            echo "waybar-visibility.sh: unknown source/verb '$verb' (expected idle|fullscreen|gaming|keybind|reassert|status)" >&2
            exit 1
            ;;
    esac
}

main "$@"
