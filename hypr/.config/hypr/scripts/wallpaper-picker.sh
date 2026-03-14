#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║     WALLPAPER PICKER — fzf + chafa + live swww       ║
# ║                                                      ║
# ║  - Left pane:  wallpaper list with fzf fuzzy search  ║
# ║  - Right pane: chafa thumbnail preview               ║
# ║  - Desktop:    live swww animated preview as you     ║
# ║                navigate through selections           ║
# ║                                                      ║
# ║  Enter  = confirm selection                          ║
# ║  Esc/q  = cancel and restore previous wallpaper      ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CURRENT_LINK="$WALLPAPER_DIR/current.jpg"
STATE_FILE="$HOME/.cache/current-theme"
PREVIOUS_FILE="$HOME/.cache/wallpaper-picker-previous"

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
    read -n1
    exit 1
fi

# ── Preview script (written to tmp) ─────────────────
PREVIEW_SCRIPT=$(mktemp /tmp/wp-preview-XXXXXX.sh)
cat > "$PREVIEW_SCRIPT" << 'PREVIEW'
#!/usr/bin/env bash
FILE="$HOME/Pictures/Wallpapers/$1"
[[ ! -f "$FILE" ]] && exit 0

# Get preview pane dimensions from fzf
COLS=${FZF_PREVIEW_COLUMNS:-40}
LINES=${FZF_PREVIEW_LINES:-20}

# Show image with chafa
chafa --size="${COLS}x${LINES}" \
      --animate=off \
      --center=on \
      --color-space=din99d \
      --symbols=block+border+space \
      "$FILE" 2>/dev/null

# Print filename and dimensions below preview
echo ""
DIMS=$(identify -format "%wx%h" "$FILE" 2>/dev/null || echo "unknown")
SIZE=$(du -h "$FILE" 2>/dev/null | cut -f1)
echo -e " \e[1m$1\e[0m  │  ${DIMS}  │  ${SIZE}"
PREVIEW
chmod +x "$PREVIEW_SCRIPT"

# ── Live preview script (swww on desktop) ────────────
LIVE_SCRIPT=$(mktemp /tmp/wp-live-XXXXXX.sh)
cat > "$LIVE_SCRIPT" << 'LIVE'
#!/usr/bin/env bash
FILE="$HOME/Pictures/Wallpapers/$1"
[[ ! -f "$FILE" ]] && exit 0
swww img "$FILE" \
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
    --bind "ctrl-r:execute-silent(swww img '$WALLPAPER_DIR/{}' --transition-type random --transition-duration 1 --transition-fps 165)" \
    --header " 🖼  Wallpaper Picker  │  ↑↓ browse  │  Enter confirm  │  Esc cancel" \
    --header-first \
    --prompt "  " \
    --pointer "▶" \
    --marker "●" \
    --color="bg:-1,bg+:#313244,fg:#cdd6f4,fg+:#cba6f7,hl:#f5c2e7,hl+:#f5c2e7" \
    --color="info:#94e2d5,prompt:#cba6f7,pointer:#f5c2e7,marker:#f5c2e7,spinner:#94e2d5" \
    --color="header:#a6adc8,border:#585b70,gutter:-1" \
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
        swww img "$PREVIOUS_WALLPAPER" \
            --transition-type center \
            --transition-duration 1 \
            --transition-fps 165 2>/dev/null
    fi
    rm -f "$PREVIOUS_FILE"
    exit 0
fi

# ── Confirm selection ────────────────────────────────
FULL_PATH="$WALLPAPER_DIR/$SELECTED"
ln -sf "$FULL_PATH" "$CURRENT_LINK"

# Final animated set (in case live preview didn't fire)
swww img "$FULL_PATH" \
    --transition-type center \
    --transition-duration 2 \
    --transition-fps 165

# ── Material You regeneration if active ──────────────
CURRENT_THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "")
if [[ "$CURRENT_THEME" == "materialyou" ]]; then
    sleep 0.5
    matugen image "$FULL_PATH" -m dark
    notify-send -a "Wallpaper Picker" "Wallpaper + Theme Updated" \
        "Material You colors regenerated from $SELECTED" \
        -i preferences-desktop-wallpaper -t 3000
else
    notify-send -a "Wallpaper Picker" "Wallpaper Changed" \
        "Set to $SELECTED" \
        -i preferences-desktop-wallpaper -t 2000
fi

rm -f "$PREVIOUS_FILE"
