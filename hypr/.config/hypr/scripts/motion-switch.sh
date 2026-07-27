#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║        MOTION-SCALE SWITCHER — CLI (D-06/D-07)       ║
# ║  State file + CLI only this phase — no fzf picker,   ║
# ║  no Super-key menu entry (deferred to Phase 13).      ║
# ╚══════════════════════════════════════════════════════╝
#
# Usage: motion-switch.sh <off|reduced|normal|lively>
#        motion-switch.sh --get
#        motion-switch.sh --list
#        motion-switch.sh --help
#        motion-switch.sh --curves <md3|legacy>
#        motion-switch.sh --curves --get
#
# Unlike font-switch.sh/icon-theme-switch.sh (thin kitty+fzf launchers),
# this script IS the axis's whole interface this phase (D-07) — it writes
# the state file directly and triggers exactly one theme-apply re-render,
# never a second entrypoint.
#
# --curves (13-01/D-21) is a SECOND, temporary axis riding the exact same
# one-entrypoint contract: it flips D-21's A/B curve-set comparison toggle
# (motion.json's `curve_sets`) rather than the scale multiplier, through
# the SAME single theme-apply re-render below (D-36 — never a second
# render path). Removed in plan 13-07 alongside motion.json's `curve_sets`.

set -euo pipefail

MOTION_STATE_FILE="$HOME/.local/state/theme/motion-scale"
MOTION_DEFAULT="normal"
MOTION_CURVES_FILE="$HOME/.local/state/theme/motion-curves"
MOTION_CURVES_DEFAULT="md3"
MOTION_JSON="$HOME/.config/theme-engine/motion.json"
CURRENT_THEME_FILE="$HOME/.local/state/theme/current-theme"
THEME_APPLY="$HOME/.config/theme-engine/theme-apply"

# theme_engine_read_motion_scale — the SAME closed-set reader lib/motion.sh
# uses (duplicated here in miniature rather than sourced, since this script
# runs standalone from a keybind/terminal, not from inside theme-apply's
# process). Any drift between the two would be a bug; both read the exact
# same state file and default value.
_read_motion_scale() {
    local v
    v="$(cat "$MOTION_STATE_FILE" 2>/dev/null || echo "$MOTION_DEFAULT")"
    case "$v" in
        off|reduced|normal|lively) echo "$v" ;;
        *) echo "$MOTION_DEFAULT" ;;
    esac
}

# _read_motion_curves — the SAME closed-set reader as lib/motion.sh's
# theme_engine_read_motion_curves (duplicated here for the same
# standalone-invocation reason as _read_motion_scale above).
_read_motion_curves() {
    local v
    v="$(cat "$MOTION_CURVES_FILE" 2>/dev/null || echo "$MOTION_CURVES_DEFAULT")"
    case "$v" in
        md3|legacy) echo "$v" ;;
        *) echo "$MOTION_CURVES_DEFAULT" ;;
    esac
}

usage() {
    echo "Usage: motion-switch.sh <preset|--get|--list>" >&2
    echo "       motion-switch.sh --curves <curve-set|--get>" >&2
    echo "Valid presets:" >&2
    if [[ -s "$MOTION_JSON" ]] && jq -e . "$MOTION_JSON" >/dev/null 2>&1; then
        jq -r '.scales | keys[]' "$MOTION_JSON" 2>/dev/null | while IFS= read -r p; do
            echo "  - $p" >&2
        done
    else
        echo "  (motion.json unreadable — cannot enumerate presets)" >&2
    fi
    echo "Valid curve-sets (D-21 temporary A/B toggle):" >&2
    if [[ -s "$MOTION_JSON" ]] && jq -e . "$MOTION_JSON" >/dev/null 2>&1; then
        jq -r '.curve_sets | keys[]' "$MOTION_JSON" 2>/dev/null | while IFS= read -r c; do
            echo "  - $c" >&2
        done
    else
        echo "  (motion.json unreadable — cannot enumerate curve-sets)" >&2
    fi
}

list_presets() {
    if [[ ! -s "$MOTION_JSON" ]] || ! jq -e . "$MOTION_JSON" >/dev/null 2>&1; then
        echo "motion-switch.sh: $MOTION_JSON is missing, empty, or not valid JSON" >&2
        return 1
    fi
    echo "Motion-scale presets:"
    jq -r '.scales | to_entries[] | "\(.key)\t\(.value.multiplier)"' "$MOTION_JSON" | \
        while IFS=$'\t' read -r name mult; do
            # Title Case for display (UI-SPEC Copywriting Contract) — the
            # state file itself stays lowercase always.
            title="$(printf '%s' "$name" | sed 's/^./\U&/')"
            echo "  ${title} (x${mult})"
        done
    echo "off disables at the toolkit level rather than scaling durations."
    echo
    echo "Curve-sets (D-21 temporary A/B toggle — motion-switch.sh --curves <name>):"
    jq -r '.curve_sets | keys[]' "$MOTION_JSON" 2>/dev/null | \
        while IFS= read -r name; do
            title="$(printf '%s' "$name" | sed 's/^./\U&/')"
            echo "  ${title}"
        done
}

get_current() {
    _read_motion_scale
}

# _trigger_theme_apply — D-36's ONE entrypoint, literally: this is the
# single call site in the whole script that invokes $THEME_APPLY. Both the
# --curves path and the scale-preset path below call this same function
# after writing their own state file — never a second render path, per
# TOKEN-05/D-36's "driven through theme-apply's existing single entrypoint"
# contract. This script never writes a rendered file itself.
_trigger_theme_apply() {
    local current_theme
    current_theme="$(cat "$CURRENT_THEME_FILE" 2>/dev/null || echo "catppuccin")"

    if [[ -x "$THEME_APPLY" ]]; then
        "$THEME_APPLY" "$current_theme"
        return $?
    else
        echo "motion-switch.sh: $THEME_APPLY not found or not executable — state written but not re-rendered" >&2
        return 1
    fi
}

# --curves dispatch (13-01/D-21) — handled before the single-arg branch
# below since it is the only two-argument form this script accepts.
if [[ $# -eq 2 && "$1" == "--curves" ]]; then
    CURVES_ARG="$2"

    if [[ "$CURVES_ARG" == "--get" ]]; then
        _read_motion_curves
        exit 0
    fi

    if [[ ! -s "$MOTION_JSON" ]] || ! jq -e . "$MOTION_JSON" >/dev/null 2>&1; then
        echo "motion-switch.sh: $MOTION_JSON is missing, empty, or not valid JSON" >&2
        exit 1
    fi

    # Security Domain V5 — validate against motion.json's ACTUAL curve_sets
    # keys before this value is ever written to a file the compositor
    # parses. Never a hardcoded enum (T-13-02) — mirrors the PRESET
    # validation below exactly.
    VALID_CURVE_SETS="$(jq -r '.curve_sets | keys[]' "$MOTION_JSON" 2>/dev/null)"
    if ! printf '%s\n' "$VALID_CURVE_SETS" | grep -qx "$CURVES_ARG"; then
        echo "motion-switch.sh: unknown curve-set '$CURVES_ARG'" >&2
        usage
        exit 1
    fi

    mkdir -p "$(dirname "$MOTION_CURVES_FILE")"

    # WR-02 idiom (commit.sh's current-theme write): temp-file + mv gives
    # per-file atomicity — a concurrent reader sees the old value or the
    # new one, never a truncated file.
    printf '%s\n' "$CURVES_ARG" > "$MOTION_CURVES_FILE.tmp" \
        && mv "$MOTION_CURVES_FILE.tmp" "$MOTION_CURVES_FILE"

    _trigger_theme_apply
    exit $?
fi

if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

case "$1" in
    --help|-h)
        usage
        exit 0
        ;;
    --list)
        list_presets
        exit $?
        ;;
    --get)
        get_current
        exit 0
        ;;
esac

PRESET="$1"

if [[ ! -s "$MOTION_JSON" ]] || ! jq -e . "$MOTION_JSON" >/dev/null 2>&1; then
    echo "motion-switch.sh: $MOTION_JSON is missing, empty, or not valid JSON" >&2
    exit 1
fi

# Security Domain V5 — validate against motion.json's ACTUAL scales keys
# before this value is ever written to a file the compositor parses.
# Mirrors theme-apply's palette-name validation exactly (same posture,
# higher stakes: this value ends up inside a Hyprland-consumed fragment).
VALID_PRESETS="$(jq -r '.scales | keys[]' "$MOTION_JSON" 2>/dev/null)"
if ! printf '%s\n' "$VALID_PRESETS" | grep -qx "$PRESET"; then
    echo "motion-switch.sh: unknown preset '$PRESET'" >&2
    usage
    exit 1
fi

mkdir -p "$(dirname "$MOTION_STATE_FILE")"

# WR-02 idiom (commit.sh's current-theme write): temp-file + mv gives
# per-file atomicity — a concurrent reader sees the old value or the new
# one, never a truncated file.
printf '%s\n' "$PRESET" > "$MOTION_STATE_FILE.tmp" \
    && mv "$MOTION_STATE_FILE.tmp" "$MOTION_STATE_FILE"

# One entrypoint, per TOKEN-05's "driven through theme-apply's existing
# single entrypoint" — this script never writes a rendered file itself.
_trigger_theme_apply
exit $?
