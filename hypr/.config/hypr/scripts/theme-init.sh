#!/usr/bin/env bash
# Applies the last-used theme on login. Falls back to catppuccin.
# Also sets a default wallpaper with awww if one exists.

set -euo pipefail

STATE_FILE="$HOME/.cache/current-theme"
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
WALLPAPER="$HOME/Pictures/Wallpapers/current.jpg"

THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "catppuccin")

# Set wallpaper if it exists
if [[ -f "$WALLPAPER" ]]; then
    awww img "$WALLPAPER" \
        --transition-type center \
        --transition-duration 1 \
        --transition-fps 165
fi

# Apply theme
if [[ "$THEME" == "materialyou" ]]; then
    if [[ -f "$WALLPAPER" ]]; then
        matugen image "$WALLPAPER" -m dark

        # Concatenate GTK colors
        cat "$GTK3_COLORS" "$HOME/.config/gtk-3.0/gtk-base.css" \
            > "$HOME/.config/gtk-3.0/gtk.css" 2>/dev/null
        cat "$GTK4_COLORS" "$HOME/.config/gtk-4.0/gtk-base.css" \
            > "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null

        # Concatenate Walker colors
        cat "$WALKER_COLORS" "$HOME/.config/walker/themes/rice/style-base.css" \
            > "$HOME/.config/walker/themes/rice/style.css" 2>/dev/null

        # Apply VSCodium theme
        ~/.config/hypr/scripts/vscodium-theme.sh materialyou

        # Reload all applications
        hyprctl reload 2>/dev/null || true
        pkill -SIGUSR2 waybar 2>/dev/null || true
        pkill -SIGUSR1 kitty 2>/dev/null || true
        swaync-client -rs 2>/dev/null || true
        ~/.config/hypr/scripts/gtk-reload.sh
        ~/.config/hypr/scripts/walker-restart.sh
    fi
else
    # Validate theme name
    if [[ ! -f "$THEMES_DIR/static/${THEME}.conf" ]]; then
        THEME="catppuccin"
    fi

    cp "$THEMES_DIR/static/${THEME}.conf" "$HYPR_COLORS"
    cp "$THEMES_DIR/css/${THEME}.css" "$WAYBAR_COLORS"
    cp "$THEMES_DIR/css/${THEME}.css" "$WOFI_COLORS"
    cp "$THEMES_DIR/css/${THEME}.css" "$SWAYNC_COLORS"
    cp "$THEMES_DIR/css/${THEME}.css" "$WLOGOUT_COLORS"
    cp "$THEMES_DIR/gtk/${THEME}.css" "$GTK3_COLORS"
    cp "$THEMES_DIR/gtk/${THEME}.css" "$GTK4_COLORS"
    cat "$GTK3_COLORS" "$HOME/.config/gtk-3.0/gtk-base.css" > "$HOME/.config/gtk-3.0/gtk.css"
    cat "$GTK4_COLORS" "$HOME/.config/gtk-4.0/gtk-base.css" > "$HOME/.config/gtk-4.0/gtk.css"
    cp "$THEMES_DIR/css/${THEME}.css" "$WALKER_COLORS"
    cat "$WALKER_COLORS" "$HOME/.config/walker/themes/rice/style-base.css" > "$HOME/.config/walker/themes/rice/style.css"
    cp "$THEMES_DIR/kitty/${THEME}.conf" "$KITTY_COLORS"
    cp "$THEMES_DIR/yazi/${THEME}.toml" "$YAZI_THEME"
    ~/.config/hypr/scripts/vscodium-theme.sh "$THEME"

    hyprctl reload 2>/dev/null || true
    pkill -SIGUSR2 waybar 2>/dev/null || true
    pkill -SIGUSR1 kitty 2>/dev/null || true
    swaync-client -rs 2>/dev/null || true
    # Reload GTK apps (Thunar, etc.)
    ~/.config/hypr/scripts/gtk-reload.sh

    # Restart Walker service with new colors
    ~/.config/hypr/scripts/walker-restart.sh
fi

echo "$THEME" > "$STATE_FILE"
