#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              THEME SWITCHER (walker)                    ║
# ║   Switches between Material You + 6 static themes    ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

THEMES_DIR="$HOME/.config/themes"
HYPR_COLORS="$HOME/.config/hypr/colors.conf"
WAYBAR_COLORS="$HOME/.config/waybar/colors.css"
KITTY_COLORS="$HOME/.config/kitty/colors.conf"
WOFI_COLORS="$HOME/.config/wofi/colors.css"
SWAYNC_COLORS="$HOME/.config/swaync/colors.css"
WLOGOUT_COLORS="$HOME/.config/wlogout/colors.css"
GTK3_COLORS="$HOME/.config/gtk-3.0/colors.css"
GTK4_COLORS="$HOME/.config/gtk-4.0/colors.css"
WALKER_COLORS="$HOME/.config/walker/themes/rice/colors.css"
YAZI_THEME="$HOME/.config/yazi/theme.toml"
STATE_FILE="$HOME/.cache/current-theme"

# Ensure cache directory exists
mkdir -p "$(dirname "$STATE_FILE")"

# ── Theme options ────────────────────────────────────
THEME_LIST="🎨 Material You (Dynamic)
🐱 Catppuccin Mocha
🧛 Dracula
🌹 Rosé Pine
🪵 Gruvbox Dark
🌃 Tokyo Night
❄️ Nord"

# ── Show walker menu ───────────────────────────────────
SELECTED=$(echo "$THEME_LIST" | walker --dmenu --placeholder "Select Theme")

[[ -z "$SELECTED" ]] && exit 0

# ── Map selection to theme name ──────────────────────
case "$SELECTED" in
    *"Material You"*)  THEME="materialyou" ;;
    *"Catppuccin"*)    THEME="catppuccin"  ;;
    *"Dracula"*)       THEME="dracula"     ;;
    *"Rosé Pine"*)     THEME="rosepine"    ;;
    *"Gruvbox"*)       THEME="gruvbox"     ;;
    *"Tokyo Night"*)   THEME="tokyonight"  ;;
    *"Nord"*)          THEME="nord"        ;;
    *)                 exit 1              ;;
esac

# ── Apply theme ──────────────────────────────────────
apply_static_theme() {
    local name="$1"

    # Copy Hyprland colors
    cp "$THEMES_DIR/static/${name}.conf" "$HYPR_COLORS"

    # Copy CSS colors for waybar, wofi, swaync, wlogout
    cp "$THEMES_DIR/css/${name}.css" "$WAYBAR_COLORS"
    cp "$THEMES_DIR/css/${name}.css" "$WOFI_COLORS"
    cp "$THEMES_DIR/css/${name}.css" "$SWAYNC_COLORS"
    cp "$THEMES_DIR/css/${name}.css" "$WLOGOUT_COLORS"

    # Copy GTK colors
    cp "$THEMES_DIR/gtk/${name}.css" "$GTK3_COLORS"
    cp "$THEMES_DIR/gtk/${name}.css" "$GTK4_COLORS"

    # Copy Walker colors
    cp "$THEMES_DIR/css/${name}.css" "$WALKER_COLORS"

    # Copy kitty colors
    cp "$THEMES_DIR/kitty/${name}.conf" "$KITTY_COLORS"

    # Copy yazi theme
    cp "$THEMES_DIR/yazi/${name}.toml" "$YAZI_THEME"

    # Apply VSCodium theme
    ~/.config/hypr/scripts/vscodium-theme.sh "$name"

    # Reload applications
    hyprctl reload
    pkill -SIGUSR2 waybar || true
    pkill -SIGUSR1 kitty || true
    swaync-client -rs || true
    # Reload GTK apps (Thunar, etc.)
    ~/.config/hypr/scripts/gtk-reload.sh

    # Restart Walker (no reload signal — must restart the service)
    ~/.config/hypr/scripts/walker-restart.sh

    # Save state
    echo "$name" > "$STATE_FILE"

    notify-send -a "Theme Switcher" "Theme Applied" "Switched to ${name}" \
        -i preferences-desktop-theme -t 3000
}

apply_material_you() {
    local wallpaper
    wallpaper=$(readlink -f ~/Pictures/Wallpapers/current.jpg 2>/dev/null \
                || echo "$HOME/Pictures/Wallpapers/current.jpg")

    if [[ ! -f "$wallpaper" ]]; then
        notify-send -a "Theme Switcher" "Error" \
            "No wallpaper found at ~/Pictures/Wallpapers/current.jpg\nUse Super+Shift+B to pick a wallpaper first." \
            -i dialog-error -t 5000
        exit 1
    fi

    # Run matugen with dark mode
    matugen image "$wallpaper" -m dark

    # Save state
    echo "materialyou" > "$STATE_FILE"

    notify-send -a "Theme Switcher" "Material You Applied" \
        "Colors generated from current wallpaper" \
        -i preferences-desktop-theme -t 3000
}

# ── Execute ──────────────────────────────────────────
if [[ "$THEME" == "materialyou" ]]; then
    apply_material_you
else
    apply_static_theme "$THEME"
fi
