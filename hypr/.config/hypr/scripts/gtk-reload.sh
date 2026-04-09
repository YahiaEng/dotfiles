#!/usr/bin/env bash
# Rebuild gtk.css and force GTK apps to re-read theme

# Concatenate colors into gtk.css
cat "$HOME/.config/gtk-3.0/colors.css" "$HOME/.config/gtk-3.0/gtk-base.css" \
    > "$HOME/.config/gtk-3.0/gtk.css" 2>/dev/null
cat "$HOME/.config/gtk-4.0/colors.css" "$HOME/.config/gtk-4.0/gtk-base.css" \
    > "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null

# Ensure GTK_THEME is in the current systemd user environment
# (uwsm env is only read at session start — this propagates mid-session)
export GTK_THEME=adw-gtk3-dark
systemctl --user import-environment GTK_THEME 2>/dev/null
dbus-update-activation-environment --systemd GTK_THEME 2>/dev/null

# Try gsettings (works if xdg-desktop-portal-gtk is running)
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null
gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null
sleep 0.1
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null

# GTK3 apps CANNOT hot-reload CSS — must be restarted
# Restart Thunar if it's running
if pgrep -x thunar >/dev/null 2>&1; then
    thunar --quit 2>/dev/null
    sleep 0.5
    GTK_THEME=adw-gtk3-dark uwsm app -- thunar --daemon &
    disown
fi
