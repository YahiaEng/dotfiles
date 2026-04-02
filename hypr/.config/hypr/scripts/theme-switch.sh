#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              THEME SWITCHER (walker)                 ║
# ║   Switches between Material You + 6 static themes    ║
# ╚══════════════════════════════════════════════════════╝

THEMES_DIR="$HOME/.config/themes"
HYPR_COLORS="$HOME/.config/hypr/colors.conf"
WAYBAR_COLORS="$HOME/.config/waybar/colors.css"
KITTY_COLORS="$HOME/.config/kitty/colors.conf"
WOFI_COLORS="$HOME/.config/wofi/colors.css"
SWAYNC_COLORS="$HOME/.config/swaync/colors.css"
WLOGOUT_COLORS="$HOME/.config/wlogout/colors.css"
GTK3_COLORS="$HOME/.config/gtk-3.0/colors.css"
GTK4_COLORS="$HOME/.config/gtk-4.0/colors.css"
YAZI_THEME="$HOME/.config/yazi/theme.toml"
STATE_FILE="$HOME/.cache/current-theme"

mkdir -p "$(dirname "$STATE_FILE")"

THEME_LIST="🎨 Material You (Dynamic)
🐱 Catppuccin Mocha
🧛 Dracula
🌹 Rosé Pine
🪵 Gruvbox Dark
🌃 Tokyo Night
❄️ Nord"

SELECTED=$(echo "$THEME_LIST" | walker --dmenu --placeholder "Select Theme")
[[ -z "$SELECTED" ]] && exit 0

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

reload_all() {
    hyprctl reload
    pkill -SIGUSR2 waybar || true
    pkill -SIGUSR1 kitty || true
    swaync-client -rs || true
    ~/.config/hypr/scripts/gtk-reload.sh
    ~/.config/hypr/scripts/walker-restart.sh
}

apply_static_theme() {
    local name="$1"

    cp "$THEMES_DIR/static/${name}.conf" "$HYPR_COLORS"
    cp "$THEMES_DIR/css/${name}.css" "$WAYBAR_COLORS"
    cp "$THEMES_DIR/css/${name}.css" "$WOFI_COLORS"
    cp "$THEMES_DIR/css/${name}.css" "$SWAYNC_COLORS"
    cp "$THEMES_DIR/css/${name}.css" "$WLOGOUT_COLORS"

    # GTK: write colors.css then rebuild gtk.css via concatenation
    cp "$THEMES_DIR/gtk/${name}.css" "$GTK3_COLORS"
    cp "$THEMES_DIR/gtk/${name}.css" "$GTK4_COLORS"
    cat "$GTK3_COLORS" "$HOME/.config/gtk-3.0/gtk-base.css" > "$HOME/.config/gtk-3.0/gtk.css"
    cat "$GTK4_COLORS" "$HOME/.config/gtk-4.0/gtk-base.css" > "$HOME/.config/gtk-4.0/gtk.css"

    # Walker: generate CSS with hardcoded hex (no @define-color)
    ~/.config/hypr/scripts/walker-theme-gen.sh --from-css "$THEMES_DIR/css/${name}.css"

    cp "$THEMES_DIR/kitty/${name}.conf" "$KITTY_COLORS"
    cp "$THEMES_DIR/yazi/${name}.toml" "$YAZI_THEME"
    ~/.config/hypr/scripts/vscodium-theme.sh "$name"

    reload_all
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
            "No wallpaper found. Use Super+Shift+B to pick one first." \
            -i dialog-error -t 5000
        exit 1
    fi

    # matugen generates ALL outputs directly:
    #   Walker style.css (hardcoded hex via walker-style.css template)
    #   GTK colors.css, waybar/wofi/swaync/wlogout colors.css, etc.
    if ! matugen image "$wallpaper" --source-color-index 0 2>/tmp/matugen-error.log; then
        notify-send -a "Theme Switcher" "Matugen Error" \
            "$(cat /tmp/matugen-error.log 2>/dev/null || echo 'Unknown error')" \
            -i dialog-error -t 5000
        exit 1
    fi

    # Rebuild GTK gtk.css (matugen wrote colors.css, concatenate with base)
    cat "$GTK3_COLORS" "$HOME/.config/gtk-3.0/gtk-base.css" \
        > "$HOME/.config/gtk-3.0/gtk.css" 2>/dev/null
    cat "$GTK4_COLORS" "$HOME/.config/gtk-4.0/gtk-base.css" \
        > "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null

    ~/.config/hypr/scripts/vscodium-theme.sh materialyou
    reload_all
    echo "materialyou" > "$STATE_FILE"
    notify-send -a "Theme Switcher" "Material You Applied" \
        "Colors generated from current wallpaper" \
        -i preferences-desktop-theme -t 3000
}

if [[ "$THEME" == "materialyou" ]]; then
    apply_material_you
else
    apply_static_theme "$THEME"
fi
