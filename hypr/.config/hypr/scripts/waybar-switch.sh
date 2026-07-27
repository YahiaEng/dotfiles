#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║           WAYBAR LAYOUT SWITCHER (walker)            ║
# ║   Layouts are discovered from disk (D-32) — dropping  ║
# ║   a config-<name>.jsonc + a compiled waybar-style-    ║
# ║   <name>.css sheet here makes it selectable with zero ║
# ║   script edits.                                       ║
# ╚══════════════════════════════════════════════════════╝
#
# 13-05 fix: waybar-switch.sh (bound to $mainMod,B — Super+B, not in this
# plan's original files_modified) still pointed at the pre-conversion
# repo-stowed style-<slug>.css, which no longer exists (all six waybar
# stylesheets are now .scss, compiled into $STATE_DIR). Repointed at the
# compiled state-dir sheet, mirroring waybar-launch.sh's own disk-truth
# idiom (D-32/D-05) rather than inventing a second one — the actual
# launch invocation below now DELEGATES to waybar-launch.sh itself, so
# there is exactly one place in the repo that constructs the waybar
# flags and one place that owns the missing-sheet degrade behavior.

set -euo pipefail

WAYBAR_DIR="$HOME/.config/waybar"
STATE_DIR="$HOME/.local/state/theme"
STATE_FILE="$HOME/.cache/current-waybar-layout"
WAYBAR_LAUNCH="$HOME/.config/hypr/scripts/waybar-launch.sh"

mkdir -p "$(dirname "$STATE_FILE")"

# ── Menu-label derivation (UI-SPEC Copywriting Contract) ─────────────
# Same idiom as theme-switch.sh's palette prettify() (Phase 5, D-32's
# direct precedent): hyphen -> space, title-case each word. No per-layout
# hardcoded description string — a new layout inherits this for free.
prettify() {
    local raw="$1"
    local spaced="${raw//-/ }"
    local out=""
    local word
    for word in $spaced; do
        out+="${word^} "
    done
    echo "${out% }"
}

# ── Layout enumeration (D-32) ────────────────────────
# The filesystem is the single source of truth for "what layouts exist" —
# glob config-*.jsonc, strip the config- prefix/.jsonc suffix to recover
# the slug, sort for a stable menu order across runs.
shopt -s nullglob
CONFIG_FILES=("$WAYBAR_DIR"/config-*.jsonc)
shopt -u nullglob

if [[ ${#CONFIG_FILES[@]} -eq 0 ]]; then
    notify-send -a "Waybar Switcher" "Error" \
        "No waybar layouts found in $WAYBAR_DIR" -i dialog-error 2>/dev/null || true
    exit 1
fi

mapfile -t CONFIG_FILES < <(printf '%s\n' "${CONFIG_FILES[@]}" | sort)

SLUGS=()
DISPLAYS=()
for f in "${CONFIG_FILES[@]}"; do
    name="$(basename "$f" .jsonc)"
    name="${name#config-}"
    SLUGS+=("$name")
    DISPLAYS+=("$(prettify "$name")")
done

# ── Show walker menu ───────────────────────────────────
# WR-04: walker 2.16.2 signals Esc / click-outside / Return-on-empty
# cancel via exit status 130 with no stdout (128+SIGINT convention), never
# exit 0 + empty output. `|| rc=$?` captures the exit code without
# tripping `set -euo pipefail` on a bare command-substitution assignment.
rc=0
SELECTED=$(printf '%s\n' "${DISPLAYS[@]}" | walker --dmenu --placeholder "Waybar Layout") || rc=$?
if (( rc == 130 )); then
    exit 0   # user cancel
elif (( rc != 0 )); then
    notify-send -a "Waybar Switcher" "Error" "walker dmenu failed" -i dialog-error 2>/dev/null || true
    exit 1   # hard failure: not installed (127), elephant dead (1), crash
fi

[[ -z "$SELECTED" ]] && exit 0   # defensive; walker never returns 0+empty, but harmless

# ── Map selection back to its slug ───────────────────
# Parallel-array lookup (identical shape to theme-switch.sh) — never
# re-parse a decorated label with glob patterns.
LAYOUT=""
for i in "${!DISPLAYS[@]}"; do
    if [[ "${DISPLAYS[$i]}" == "$SELECTED" ]]; then
        LAYOUT="${SLUGS[$i]}"
        break
    fi
done

[[ -z "$LAYOUT" ]] && exit 1

# ── Guard: config without a matching COMPILED stylesheet (T-08-14/T-08-15,
#    repointed 13-05) ─────────────────────────────────────────────────
# A config-<slug>.jsonc with no compiled waybar-style-<slug>.css in the
# state dir would launch an unstyled bar — fail loudly instead of
# silently degrading, exactly the same both-files-must-exist check
# waybar-launch.sh performs before trusting a saved layout (D-32/D-05) —
# mirrored here, not reinvented, so the two scripts can never disagree
# about what makes a layout valid.
if [[ ! -f "$WAYBAR_DIR/config-${LAYOUT}.jsonc" || ! -f "$STATE_DIR/waybar-style-${LAYOUT}.css" ]]; then
    notify-send -a "Waybar Switcher" "Error" \
        "Layout '${LAYOUT}' is missing its config or compiled stylesheet — run theme-apply" -i dialog-error 2>/dev/null || true
    exit 1
fi

# ── Apply layout ─────────────────────────────────────
# Kill existing waybar
pkill waybar || true
sleep 0.3

# Save state BEFORE launching — waybar-launch.sh reads this same
# $HOME/.cache/current-waybar-layout file (verified: identical path,
# both scripts agree).
echo "$LAYOUT" > "$STATE_FILE"

# 13-05: delegate the actual invocation to waybar-launch.sh rather than
# reconstructing the -c/-s flags here a second time — that script already
# owns the compiled-sheet path construction AND the visible degrade-to-
# config-only fallback if a compiled sheet is unexpectedly missing by the
# time it runs (a defense-in-depth window between this guard and the
# exec, however small). uwsm app -- wraps it as its own managed scope
# unit, same as the guard above already confirmed is safe to launch and
# the same wrapping autostart.conf uses for this exact script.
uwsm app -- "$WAYBAR_LAUNCH" &

notify-send -a "Waybar Switcher" "Layout Changed" \
    "Switched to ${LAYOUT} layout" \
    -i preferences-desktop-display -t 2000
