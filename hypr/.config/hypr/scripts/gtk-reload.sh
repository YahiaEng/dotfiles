#!/usr/bin/env bash
# Rebuild gtk.css and force GTK apps to re-read theme

# Concatenate colors into gtk.css (inline colors, no @import)
cat "$HOME/.config/gtk-3.0/colors.css" "$HOME/.config/gtk-3.0/gtk-base.css" \
    > "$HOME/.config/gtk-3.0/gtk.css" 2>/dev/null
cat "$HOME/.config/gtk-4.0/colors.css" "$HOME/.config/gtk-4.0/gtk-base.css" \
    > "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null

# Update settings.ini to ensure next-launch apps get the right theme
for dir in "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; do
    if [[ -f "$dir/settings.ini" ]]; then
        sed -i 's/gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=1/' "$dir/settings.ini"
    fi
done

# Try gsettings toggle (works if xdg-desktop-portal-gtk is running)
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null
gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null
sleep 0.1
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null

# Force-reload any running Thunar instances (GTK3 cannot hot-reload CSS)
if pgrep -x thunar >/dev/null 2>&1; then
    thunar --quit 2>/dev/null
    sleep 0.3
    uwsm app -- thunar --daemon &
    disown
fi
