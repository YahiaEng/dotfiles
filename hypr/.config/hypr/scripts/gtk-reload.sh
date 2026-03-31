#!/usr/bin/env bash
# Reload GTK3/GTK4 theme for Thunar and other GTK apps
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null
gsettings set org.gnome.desktop.interface icon-theme "Adwaita" 2>/dev/null
gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic" 2>/dev/null
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null
gsettings set org.gnome.desktop.interface font-name "FiraCode Nerd Font 11" 2>/dev/null
gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null
