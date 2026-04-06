#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              THEME INIT (login)                      ║
# ║  Restores saved theme + wallpaper on session start   ║
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

THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "catppuccin")
WALLPAPER="$HOME/Pictures/Wallpapers/current.jpg"

# Break Walker stow symlink if present (so writes go to real file)
WALKER_STYLE="$HOME/.config/walker/themes/rice/style.css"
mkdir -p "$(dirname "$WALKER_STYLE")"
[[ -L "$WALKER_STYLE" ]] && rm -f "$WALKER_STYLE"
rm -rf "$HOME/.local/share/walker/themes/rice" 2>/dev/null

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
        matugen image "$WALLPAPER" --source-color-index 0

        # Rebuild GTK gtk.css
        cat "$GTK3_COLORS" "$HOME/.config/gtk-3.0/gtk-base.css" \
            > "$HOME/.config/gtk-3.0/gtk.css" 2>/dev/null
        cat "$GTK4_COLORS" "$HOME/.config/gtk-4.0/gtk-base.css" \
            > "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null

        ~/.config/hypr/scripts/vscodium-theme.sh materialyou
        hyprctl reload 2>/dev/null || true
        pkill -SIGUSR2 waybar 2>/dev/null || true
        pkill -SIGUSR1 kitty 2>/dev/null || true
        swaync-client -rs 2>/dev/null || true
        ~/.config/hypr/scripts/gtk-reload.sh
        ~/.config/hypr/scripts/walker-restart.sh
    fi
else
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

    ~/.config/hypr/scripts/walker-theme-gen.sh --from-css "$THEMES_DIR/css/${THEME}.css"

    cp "$THEMES_DIR/kitty/${THEME}.conf" "$KITTY_COLORS"
    cp "$THEMES_DIR/yazi/${THEME}.toml" "$YAZI_THEME"
    ~/.config/hypr/scripts/vscodium-theme.sh "$THEME"

    hyprctl reload 2>/dev/null || true
    pkill -SIGUSR2 waybar 2>/dev/null || true
    pkill -SIGUSR1 kitty 2>/dev/null || true
    swaync-client -rs 2>/dev/null || true
    ~/.config/hypr/scripts/gtk-reload.sh
    ~/.config/hypr/scripts/walker-restart.sh
fi

echo "$THEME" > "$STATE_FILE"
