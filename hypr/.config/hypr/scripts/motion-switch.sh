#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║   MOTION STYLE + ACCESSIBILITY SWITCHER — CLI (D-06/  ║
# ║   D-07, rebased for the style/accessibility axis split ║
# ║   by quick-260821-swp)                                 ║
# ╚══════════════════════════════════════════════════════╝
#
# Usage: motion-switch.sh <style>
#        motion-switch.sh --accessibility <full|reduced|off>
#        motion-switch.sh --get
#        motion-switch.sh --get-accessibility
#        motion-switch.sh --list
#        motion-switch.sh --list-accessibility
#        motion-switch.sh --help
#
# Unlike fastfetch-logo-switch.sh (a thin kitty+fzf launcher), this
# script IS the axis's whole interface this phase (D-07) — it writes the
# state file directly and triggers exactly one theme-apply re-render,
# never a second entrypoint.
#
# quick-260821-swp: this script used to hand-duplicate lib/motion.sh's own
# closed-set reader "in miniature" (the file's own prior header warned that
# drift between the two copies would be a bug) — it now SOURCES lib/motion.sh
# instead, so there is exactly one reader/migration implementation in the
# whole repo. lib/motion.sh defines only constants and functions at its top
# level, so sourcing it here has no side effects of its own.
#
# 13-01/D-21 shipped a second, temporary two-argument flag here selecting
# the A/B curve-comparison toggle (md3 vs. legacy). It was removed in
# plan 13-07 — the soak gate that would have driven a D-22 retune was
# waived by explicit operator decision rather than passed (see
# 13-MOTION-SOAK-VERDICT.md), so the toggle's measuring-instrument job was
# done and it does not ship: it was never a user-facing setting or a
# reversion path.

set -euo pipefail

# The deployed (stowed) location first — this is what every real install
# and every verify run against a live theme-apply actually has, regardless
# of whether THIS script itself is being invoked via its stowed symlink or
# directly from a repo checkout (`cd`, unlike `readlink -f`, does not
# resolve a symlinked directory, so a SCRIPT_DIR-relative path here would
# be wrong exactly in the stowed-invocation case). Falls back to a
# repo-relative guess only for the rare case this runs before the repo has
# ever been stowed.
MOTION_LIB="$HOME/.config/theme-engine/lib/motion.sh"
if [[ ! -f "$MOTION_LIB" ]]; then
    SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
    MOTION_LIB="$(cd -- "$SCRIPT_DIR/../../.." &>/dev/null && pwd)/theme-engine/.config/theme-engine/lib/motion.sh"
fi
if [[ ! -f "$MOTION_LIB" ]]; then
    echo "motion-switch.sh: cannot find lib/motion.sh (looked under ~/.config/theme-engine and under the repo)" >&2
    exit 1
fi
# shellcheck source=theme-engine/.config/theme-engine/lib/motion.sh
source "$MOTION_LIB"

CURRENT_THEME_FILE="$HOME/.local/state/theme/current-theme"
THEME_APPLY="$HOME/.config/theme-engine/theme-apply"

usage() {
    echo "Usage: motion-switch.sh <style|--accessibility <value>|--get|--get-accessibility|--list|--list-accessibility>" >&2
    echo "Valid styles:" >&2
    if [[ -s "$MOTION_JSON" ]] && jq -e . "$MOTION_JSON" >/dev/null 2>&1; then
        jq -r '.styles | keys[]' "$MOTION_JSON" 2>/dev/null | while IFS= read -r p; do
            echo "  - $p" >&2
        done
    else
        echo "  (motion.json unreadable — cannot enumerate styles)" >&2
    fi
    echo "Valid accessibility values: full, reduced, off" >&2
}

# list_styles — one style per line, two tab-separated fields (key, label),
# under a header line. The two-space indent + tab-separated shape is a
# CONTRACT with WindowManagerPage.qml's SelectRow parser (R-2/R-3's
# "the CLI's list format and the QML parser change together" rule) — never
# change one without the other in the same commit.
list_styles() {
    if [[ ! -s "$MOTION_JSON" ]] || ! jq -e . "$MOTION_JSON" >/dev/null 2>&1; then
        echo "motion-switch.sh: $MOTION_JSON is missing, empty, or not valid JSON" >&2
        return 1
    fi
    echo "Motion styles:"
    jq -r '.styles | to_entries[] | "\(.key)\t\(.value.label // .key)"' "$MOTION_JSON" | \
        while IFS=$'\t' read -r key label; do
            printf '  %s\t%s\n' "$key" "$label"
        done
}

# list_accessibility — same two-space/tab-separated shape as list_styles,
# for the second (reduce-motion) SelectRow.
list_accessibility() {
    echo "Motion accessibility values:"
    printf '  %s\t%s\n' "full" "Full"
    printf '  %s\t%s\n' "reduced" "Reduced"
    printf '  %s\t%s\n' "off" "Off"
}

get_current_style() {
    theme_engine_read_motion_style
}

get_current_accessibility() {
    theme_engine_read_motion_accessibility
}

# _trigger_theme_apply — D-36's ONE entrypoint, literally: this is the
# single call site in the whole script that invokes $THEME_APPLY. Both the
# style-preset path and the --accessibility path below call this same
# function after writing their own state file — never a second render path,
# per TOKEN-05/D-36's "driven through theme-apply's existing single
# entrypoint" contract. This script never writes a rendered file itself.
_trigger_theme_apply() {
    local current_theme
    current_theme="$(cat "$CURRENT_THEME_FILE" 2>/dev/null || echo "catppuccin")"

    if [[ -x "$THEME_APPLY" ]]; then
        # Re-render only: the COLOUR theme is unchanged, so suppress
        # theme-apply's "Theme Applied — Switched to X" toast, which would
        # otherwise announce a colour-theme switch that never happened.
        # Errors inside theme-apply still notify.
        THEME_APPLY_QUIET=1 "$THEME_APPLY" "$current_theme"
        return $?
    else
        echo "motion-switch.sh: $THEME_APPLY not found or not executable — state written but not re-rendered" >&2
        return 1
    fi
}

if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

case "$1" in
    --help|-h)
        usage
        exit 0
        ;;
    --list)
        list_styles
        exit $?
        ;;
    --list-accessibility)
        list_accessibility
        exit $?
        ;;
    --get)
        get_current_style
        exit 0
        ;;
    --get-accessibility)
        get_current_accessibility
        exit 0
        ;;
    --accessibility)
        if [[ $# -ne 2 ]]; then
            echo "motion-switch.sh: --accessibility requires exactly one value" >&2
            usage
            exit 1
        fi
        ACCESS_VALUE="$2"
        case "$ACCESS_VALUE" in
            full|reduced|off) ;;
            *)
                echo "motion-switch.sh: unknown accessibility value '$ACCESS_VALUE'" >&2
                usage
                exit 1
                ;;
        esac
        mkdir -p "$(dirname "$MOTION_ACCESS_FILE")"
        # WR-02 idiom (commit.sh's current-theme write): temp-file + mv gives
        # per-file atomicity — a concurrent reader sees the old value or the
        # new one, never a truncated file.
        printf '%s\n' "$ACCESS_VALUE" > "$MOTION_ACCESS_FILE.tmp" \
            && mv "$MOTION_ACCESS_FILE.tmp" "$MOTION_ACCESS_FILE"
        _trigger_theme_apply
        exit $?
        ;;
esac

if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

STYLE="$1"

if [[ ! -s "$MOTION_JSON" ]] || ! jq -e . "$MOTION_JSON" >/dev/null 2>&1; then
    echo "motion-switch.sh: $MOTION_JSON is missing, empty, or not valid JSON" >&2
    exit 1
fi

# Security Domain V5 — validate against motion.json's ACTUAL .styles keys
# before this value is ever written to a file the compositor parses.
# Mirrors theme-apply's palette-name validation exactly (same posture,
# higher stakes: this value ends up inside a Hyprland-consumed fragment).
VALID_STYLES="$(jq -r '.styles | keys[]' "$MOTION_JSON" 2>/dev/null)"
if ! printf '%s\n' "$VALID_STYLES" | grep -qx -- "$STYLE"; then
    echo "motion-switch.sh: unknown style '$STYLE'" >&2
    usage
    exit 1
fi

mkdir -p "$(dirname "$MOTION_STYLE_FILE")"

# WR-02 idiom (commit.sh's current-theme write): temp-file + mv gives
# per-file atomicity — a concurrent reader sees the old value or the new
# one, never a truncated file.
printf '%s\n' "$STYLE" > "$MOTION_STYLE_FILE.tmp" \
    && mv "$MOTION_STYLE_FILE.tmp" "$MOTION_STYLE_FILE"

# One entrypoint, per TOKEN-05's "driven through theme-apply's existing
# single entrypoint" — this script never writes a rendered file itself.
_trigger_theme_apply
exit $?
