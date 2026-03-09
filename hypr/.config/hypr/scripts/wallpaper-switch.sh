#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║           WALLPAPER PICKER (wofi + swww)              ║
# ║   Picks a wallpaper and optionally runs matugen       ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CURRENT_LINK="$WALLPAPER_DIR/current.jpg"
STATE_FILE="$HOME/.cache/current-theme"

# ── Ensure wallpaper directory exists ────────────────
mkdir -p "$WALLPAPER_DIR"

# ── Find all image files ─────────────────────────────
IMAGES=$(find "$WALLPAPER_DIR" -maxdepth 1 \
    -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) \
    ! -name "current.jpg" \
    | sort)

if [[ -z "$IMAGES" ]]; then
    notify-send -a "Wallpaper Picker" "No Wallpapers Found" \
        "Add images to ~/Pictures/Wallpapers/" \
        -i dialog-warning -t 5000
    exit 1
fi

# ── Build display list (filenames only) ──────────────
DISPLAY_LIST=""
while IFS= read -r img; do
    DISPLAY_LIST+="🖼️ $(basename "$img")\n"
done <<< "$IMAGES"

# ── Show wofi menu ───────────────────────────────────
SELECTED=$(echo -e "$DISPLAY_LIST" | wofi --dmenu \
    --prompt "Pick Wallpaper" \
    --width 420 \
    --height 400 \
    --cache-file /dev/null)

[[ -z "$SELECTED" ]] && exit 0

# ── Extract filename ─────────────────────────────────
FILENAME=$(echo "$SELECTED" | sed 's/^🖼️ //')
FULL_PATH="$WALLPAPER_DIR/$FILENAME"

if [[ ! -f "$FULL_PATH" ]]; then
    notify-send -a "Wallpaper Picker" "Error" \
        "File not found: $FILENAME" \
        -i dialog-error -t 3000
    exit 1
fi

# ── Set wallpaper with swww ──────────────────────────
# Update the 'current' symlink
ln -sf "$FULL_PATH" "$CURRENT_LINK"

swww img "$FULL_PATH" \
    --transition-type center \
    --transition-duration 2 \
    --transition-fps 165

# ── If current theme is Material You, regenerate ─────
CURRENT_THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "")
if [[ "$CURRENT_THEME" == "materialyou" ]]; then
    sleep 0.5
    matugen image "$FULL_PATH" -m dark
    notify-send -a "Wallpaper Picker" "Wallpaper + Theme Updated" \
        "Material You colors regenerated from $FILENAME" \
        -i preferences-desktop-wallpaper -t 3000
else
    notify-send -a "Wallpaper Picker" "Wallpaper Changed" \
        "Set to $FILENAME" \
        -i preferences-desktop-wallpaper -t 2000
fi
