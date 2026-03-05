#!/usr/bin/env bash
# ~/.dotfiles/scripts/.local/bin/theme-switcher.sh

# Ensure a wallpaper path is provided
if [ -z "$1" ]; then
    echo "Usage: theme <wallpaper-name.format>"
    exit 1
fi

WALLPAPER="$HOME/.config/wallpapers/$1"

# 1. Switch the wallpaper with swww (Optimized for your 165Hz monitor)
# We use a smooth wipe transition
swww img "$WALLPAPER" \
    --transition-fps 165 \
    --transition-type wipe \
    --transition-duration 2

# Cache the current wallpaper for hyprlock to use
mkdir -p ~/.cache
cp "$WALLPAPER" ~/.cache/current_wallpaper.jpg

# 2. Generate Material You colors with Matugen (Forcing dark mode as requested)
matugen image "$WALLPAPER" -m dark

# 3. Reload Waybar so it picks up the newly generated colors.css
# SIGUSR2 dynamically reloads Waybar without killing the process entirely
killall -SIGUSR2 waybar

# Note: Hyprland automatically detects changes to sourced config files, 
# so it will instantly update the borders without needing a reload command!

# Reload Kitty terminal colors globally
killall -SIGUSR1 kitty

# Reload SwayNC styles globally
swaync-client -rs