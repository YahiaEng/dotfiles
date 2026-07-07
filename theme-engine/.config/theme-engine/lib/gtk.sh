#!/usr/bin/env bash
# theme-engine/lib/gtk.sh — gsettings toggle + GTK theme env propagation
# (D-13/PIPE-05)
#
# GTK_THEME's single source of truth is uwsm/.config/uwsm/env (D-13). This
# script only PROPAGATES the already-exported value into the running
# systemd/dbus activation environment for apps started mid-session — it
# never hardcodes/re-exports a literal theme name itself.

# theme_engine_gtk_reload
theme_engine_gtk_reload() {
    # Propagate whatever GTK_THEME is already set to in this shell's
    # environment (inherited from uwsm/env at session start) — no
    # hardcoded value assigned here (PIPE-05).
    if [[ -n "${GTK_THEME:-}" ]]; then
        systemctl --user import-environment GTK_THEME 2>/dev/null || true
        dbus-update-activation-environment --systemd GTK_THEME 2>/dev/null || true
    fi

    # gsettings toggle — works when xdg-desktop-portal-gtk is running.
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null || true
    sleep 0.1
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null || true

    # GTK3 apps cannot hot-reload CSS — restart only the background
    # Thunar daemon, never a visible window (D-15). Bounded poll instead
    # of a fixed sleep for the exit wait (Don't-Hand-Roll table).
    if pgrep -x thunar >/dev/null 2>&1; then
        thunar --quit 2>/dev/null || true

        local waited=0
        while pgrep -x thunar >/dev/null 2>&1 && (( waited < 20 )); do
            sleep 0.1
            (( waited++ ))
        done

        # Fully detach so a long-running daemon never holds a caller's
        # pipe/fd open (same rationale as the walker relaunch in reload.sh).
        setsid uwsm app -- thunar --daemon >/dev/null 2>&1 </dev/null &
        disown
    fi
}
