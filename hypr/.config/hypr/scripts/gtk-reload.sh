#!/usr/bin/env bash
# Rebuild gtk.css from colors + base, then reload GTK theme for Thunar etc.

# Concatenate colors into gtk.css (no @import — inline colors)
cat "$HOME/.config/gtk-3.0/colors.css" "$HOME/.config/gtk-3.0/gtk-base.css" \
    > "$HOME/.config/gtk-3.0/gtk.css" 2>/dev/null
cat "$HOME/.config/gtk-4.0/colors.css" "$HOME/.config/gtk-4.0/gtk-base.css" \
    > "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null

# Toggle GTK theme to force re-read
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null
gsettings set org.gnome.desktop.interface icon-theme "Adwaita" 2>/dev/null
gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic" 2>/dev/null
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null
gsettings set org.gnome.desktop.interface font-name "FiraCode Nerd Font 11" 2>/dev/null
gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null
