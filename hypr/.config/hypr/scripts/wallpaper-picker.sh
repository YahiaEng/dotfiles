#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║     WALLPAPER PICKER — fzf + chafa + live awww       ║
# ║                                                      ║
# ║  - Left pane:  wallpaper list with fzf fuzzy search  ║
# ║  - Right pane: chafa thumbnail preview               ║
# ║  - Desktop:    live awww animated preview as you     ║
# ║                navigate through selections           ║
# ║                                                      ║
# ║  Enter  = confirm selection                          ║
# ║  Esc/q  = cancel and restore previous wallpaper      ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CURRENT_LINK="$WALLPAPER_DIR/current.jpg"
STATE_FILE="$HOME/.local/state/theme/current-theme"
PREVIOUS_FILE="$HOME/.cache/wallpaper-picker-previous"

# ── Pipeline-themed fzf colors (THM-04/D-15) ─────────
# Best-effort source of the engine-rendered fragment; the current
# catppuccin-mocha hex values survive only as ${VAR:-fallback} defaults
# below (fresh-install graceful degradation before the first theme-apply).
# shellcheck source=/dev/null
source "$HOME/.local/state/theme/fzf-colors.conf" 2>/dev/null || true

# ── Ensure directory exists ──────────────────────────
mkdir -p "$WALLPAPER_DIR"

# ── Save current wallpaper so we can restore on cancel
PREVIOUS_WALLPAPER=$(readlink -f "$CURRENT_LINK" 2>/dev/null || echo "")
echo "$PREVIOUS_WALLPAPER" > "$PREVIOUS_FILE"

# ── Gather images ────────────────────────────────────
IMAGES=$(find "$WALLPAPER_DIR" -maxdepth 1 \
    -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) \
    ! -name "current.jpg" \
    -printf "%f\n" | sort)

if [[ -z "$IMAGES" ]]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    echo "Add images and try again."
    echo ""
    echo "Press any key to exit..."
    read -rn1
    exit 1
fi

# ── Preview script (written to tmp) ─────────────────
# THM-04/D-13/D-14: pixel-perfect preview via the kitty graphics protocol,
# reusing fzf's own upstream fzf-preview.sh technique verbatim (RESEARCH
# Pattern 4) rather than re-deriving the kitten icat invocation — the
# trailing `sed '$d'` + ANSI-reset pair is the exact fix fzf's maintainers
# ship for the "stale image on scroll" / "reset code confuses fzf's line
# count" artifacts. chafa -f kitty (same protocol) is the fallback when
# kitten is unavailable; the original block-symbols chafa call is the last
# resort for non-kitty-graphics terminals.
PREVIEW_SCRIPT=$(mktemp /tmp/wp-preview-XXXXXX.sh)
cat > "$PREVIEW_SCRIPT" << 'PREVIEW'
#!/usr/bin/env bash
FILE="$HOME/Pictures/Wallpapers/$1"
[[ ! -f "$FILE" ]] && exit 0

# Get preview pane dimensions from fzf — reserve 2 rows for the metadata
# line printed below the image.
COLS=${FZF_PREVIEW_COLUMNS:-40}
LINES=${FZF_PREVIEW_LINES:-20}
IMG_LINES=$((LINES - 2))
[[ $IMG_LINES -lt 1 ]] && IMG_LINES=1

if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten &>/dev/null; then
    # Primary: kitty graphics protocol via kitten icat (verbatim fzf
    # upstream pattern — RESEARCH.md Pattern 4).
    kitten icat --clear --transfer-mode=memory --unicode-placeholder \
        --stdin=no --place="${COLS}x${IMG_LINES}@0x0" "$FILE" 2>/dev/null \
        | sed '$d' | sed $'$s/$/\e[m/'
elif command -v chafa &>/dev/null && chafa --help 2>/dev/null | grep -q 'kitty'; then
    # Fallback 1: chafa's own kitty-graphics-protocol output format — same
    # pixel-perfect protocol, different tool.
    chafa --format=kitty --size="${COLS}x${IMG_LINES}" \
          --animate=off --center=on \
          "$FILE" 2>/dev/null
else
    # Fallback 2 (last resort): character-block-art rendering.
    chafa --size="${COLS}x${IMG_LINES}" \
          --animate=off \
          --center=on \
          --color-space=din99d \
          --symbols=block+border+space \
          "$FILE" 2>/dev/null
fi

# Print filename and dimensions below preview (single ANSI-bold emphasis
# convention, UI-SPEC Typography).
echo ""
DIMS=$(identify -format "%wx%h" "$FILE" 2>/dev/null || echo "unknown")
SIZE=$(du -h "$FILE" 2>/dev/null | cut -f1)
echo -e " \e[1m$1\e[0m  │  ${DIMS}  │  ${SIZE}"
PREVIEW
chmod +x "$PREVIEW_SCRIPT"

# ── Live preview script (awww on desktop) ────────────
LIVE_SCRIPT=$(mktemp /tmp/wp-live-XXXXXX.sh)
cat > "$LIVE_SCRIPT" << 'LIVE'
#!/usr/bin/env bash
FILE="$HOME/Pictures/Wallpapers/$1"
[[ ! -f "$FILE" ]] && exit 0
awww img "$FILE" \
    --transition-type wipe \
    --transition-angle 30 \
    --transition-duration 1 \
    --transition-fps 165 \
    --transition-step 90 2>/dev/null &
LIVE
chmod +x "$LIVE_SCRIPT"

# ── Run fzf ──────────────────────────────────────────
SELECTED=$(echo "$IMAGES" | fzf \
    --preview "$PREVIEW_SCRIPT {}" \
    --preview-window "right,60%,border-left" \
    --bind "focus:execute-silent($LIVE_SCRIPT {})" \
    --bind "ctrl-r:execute-silent(awww img '$WALLPAPER_DIR/{}' --transition-type random --transition-duration 1 --transition-fps 165)" \
    --header " 🖼  Wallpaper Picker  │  ↑↓ browse  │  Enter confirm  │  Esc cancel" \
    --header-first \
    --prompt "  " \
    --pointer "▶" \
    --marker "●" \
    --color="bg:${FZF_COLOR_BG:--1},bg+:${FZF_COLOR_BG_PLUS:-#313244},fg:${FZF_COLOR_FG:-#cdd6f4},fg+:${FZF_COLOR_FG_PLUS:-#cba6f7},hl:${FZF_COLOR_HL:-#f5c2e7},hl+:${FZF_COLOR_HL_PLUS:-#f5c2e7}" \
    --color="info:${FZF_COLOR_INFO:-#94e2d5},prompt:${FZF_COLOR_PROMPT:-#cba6f7},pointer:${FZF_COLOR_POINTER:-#f5c2e7},marker:${FZF_COLOR_MARKER:-#f5c2e7},spinner:${FZF_COLOR_SPINNER:-#94e2d5}" \
    --color="header:${FZF_COLOR_HEADER:-#a6adc8},border:${FZF_COLOR_BORDER:-#585b70},gutter:-1" \
    --border rounded \
    --margin 1,2 \
    --padding 1 \
    --no-scrollbar \
    --cycle \
    --reverse) || true

# ── Cleanup ──────────────────────────────────────────
rm -f "$PREVIEW_SCRIPT" "$LIVE_SCRIPT"

# ── Handle selection or cancellation ─────────────────
if [[ -z "$SELECTED" ]]; then
    # Cancelled — restore previous wallpaper
    if [[ -n "$PREVIOUS_WALLPAPER" && -f "$PREVIOUS_WALLPAPER" ]]; then
        awww img "$PREVIOUS_WALLPAPER" \
            --transition-type center \
            --transition-duration 1 \
            --transition-fps 165 2>/dev/null
    fi
    rm -f "$PREVIOUS_FILE"
    exit 0
fi

# ── Confirm selection ────────────────────────────────
FULL_PATH="$WALLPAPER_DIR/$SELECTED"
ln -sfr "$FULL_PATH" "$CURRENT_LINK"

# Final animated set (in case live preview didn't fire)
awww img "$FULL_PATH" \
    --transition-type center \
    --transition-duration 2 \
    --transition-fps 165

# ── Material You regeneration if active (D-20) ───────
# In dynamic mode, wallpaper and palette must always match — re-run the
# single shared engine entrypoint (theme-apply), never reimplement
# apply+reload here (this used to be the third duplication site, D-01).
# In static mode, picking a wallpaper changes only the wallpaper.
CURRENT_THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "")
if [[ "$CURRENT_THEME" == "materialyou" ]]; then
    sleep 0.5
    ~/.config/theme-engine/theme-apply materialyou
else
    notify-send -a "Wallpaper Picker" "Wallpaper Changed" \
        "Set to $SELECTED" \
        -i preferences-desktop-wallpaper -t 2000
fi

rm -f "$PREVIOUS_FILE"
