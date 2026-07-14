#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║           WAYBAR LAYOUT SWITCHER (walker)            ║
# ║   Layouts are discovered from disk (D-32) — dropping  ║
# ║   a config-<name>.jsonc + style-<name>.css pair here  ║
# ║   makes it selectable with zero script edits.         ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

WAYBAR_DIR="$HOME/.config/waybar"
STATE_FILE="$HOME/.cache/current-waybar-layout"

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

# ── Guard: config without a matching stylesheet (T-08-14/T-08-15) ────
# A config-<slug>.jsonc with no style-<slug>.css would launch an
# unstyled bar — fail loudly instead of silently degrading.
if [[ ! -f "$WAYBAR_DIR/config-${LAYOUT}.jsonc" || ! -f "$WAYBAR_DIR/style-${LAYOUT}.css" ]]; then
    notify-send -a "Waybar Switcher" "Error" \
        "Layout '${LAYOUT}' is missing its config or stylesheet" -i dialog-error 2>/dev/null || true
    exit 1
fi

# ── Apply layout ─────────────────────────────────────
# Kill existing waybar
pkill waybar || true
sleep 0.3

# Launch waybar as a uwsm-managed scope unit
uwsm app -- waybar -c "$WAYBAR_DIR/config-${LAYOUT}.jsonc" \
       -s "$WAYBAR_DIR/style-${LAYOUT}.css" &

# Save state
echo "$LAYOUT" > "$STATE_FILE"

notify-send -a "Waybar Switcher" "Layout Changed" \
    "Switched to ${LAYOUT} layout" \
    -i preferences-desktop-display -t 2000
