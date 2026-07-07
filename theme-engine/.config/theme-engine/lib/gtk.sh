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

    # ── GTK4/libadwaita accent color (THEME-03/D-17, dark-only ceiling) ──
    # GTK4/libadwaita apps read color-scheme + accent-color live from
    # org.gnome.desktop.interface via the portal (GNOME47+ accent key,
    # confirmed present on this libadwaita 1.9.2). This is a best-effort
    # single-swatch approximation of the full Material You palette — the
    # fuller palette path is the named-color gtk-4.0/gtk.css @import
    # (wired in Plan 01-02). Full GTK4/libadwaita palette theming beyond
    # dark + one accent swatch is structurally unsupported upstream; this
    # is the realistic ceiling, not a gap (THEME-03).
    theme_engine_gtk4_accent

    # GTK3 apps cannot hot-reload CSS — restart the background Thunar
    # daemon so the CSS baseline is fresh for the next window (D-15).
    #
    # Empirically corrected this plan: Thunar is a D-Bus single-instance
    # app on this system — there is only ever ONE thunar process, whether
    # it was started as `--daemon` or as a plain window. `thunar --quit`
    # tears down that WHOLE process, closing any open window along with
    # it (verified live: opening a window against a running `--daemon`
    # process reuses the same PID, and `--quit` closed the window too —
    # see SUMMARY). There is no separate "daemon-only" PID to target once
    # a window is attached, so the only way to honor the "never kill a
    # visible window" invariant is to skip the restart while a window is
    # open, deferring the fresh-CSS restart until Thunar returns to its
    # windowless resting state.
    if pgrep -x thunar >/dev/null 2>&1; then
        local thunar_has_window=0
        if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
            if hyprctl clients -j 2>/dev/null \
                | jq -e '[.[] | select(.class | ascii_downcase == "thunar")] | length > 0' \
                >/dev/null 2>&1; then
                thunar_has_window=1
            fi
        fi

        if [[ "$thunar_has_window" == "1" ]]; then
            notify-send -a "Thunar" "Notice" "New theme applied. Open Thunar window(s) will refresh after being closed and reopened." -t 3000 2>/dev/null || true
        else
            # Bounded poll instead of a fixed sleep for the exit wait
            # (Don't-Hand-Roll table); falls through to a forced kill
            # after the cap (T-03-01) rather than hang the switch on a
            # daemon that never exits.
            thunar --quit 2>/dev/null || true

            local waited=0
            while pgrep -x thunar >/dev/null 2>&1 && (( waited < 20 )); do
                sleep 0.1
                (( waited++ ))
            done
            if pgrep -x thunar >/dev/null 2>&1; then
                killall -q -9 thunar 2>/dev/null || true
            fi

            # Fully detach so a long-running daemon never holds a
            # caller's pipe/fd open (same rationale as the walker
            # relaunch in reload.sh).
            setsid uwsm app -- thunar --daemon >/dev/null 2>&1 </dev/null &
            disown
        fi
    fi
}

# theme_engine_gtk4_accent — best-effort GTK4/libadwaita accent-color
# mapping (D-17). gsettings' accent-color key is a fixed enum (blue,
# teal, green, yellow, orange, red, pink, purple, slate) — not an
# arbitrary hex — so this maps the state dir's Material You accent hex
# to the nearest enum member by hue. Never blocks/fails theme_engine_gtk_reload
# on error (best-effort, dark-only ceiling per THEME-03).
theme_engine_gtk4_accent() {
    local colors_file="$HOME/.local/state/theme/gtk-4.0-colors.css"
    [[ -f "$colors_file" ]] || return 0
    command -v python3 >/dev/null 2>&1 || return 0

    local hex
    hex=$(grep -m1 '@define-color accent_color ' "$colors_file" 2>/dev/null | grep -oE '#[0-9a-fA-F]{6}')
    [[ -n "$hex" ]] || return 0

    local accent
    accent=$(python3 - "$hex" <<'PYEOF' 2>/dev/null
import colorsys, sys
hexv = sys.argv[1].lstrip('#')
r, g, b = (int(hexv[i:i+2], 16) / 255.0 for i in (0, 2, 4))
h, s, l = colorsys.rgb_to_hls(r, g, b)[0], colorsys.rgb_to_hls(r, g, b)[2], colorsys.rgb_to_hls(r, g, b)[1]
deg = h * 360
if s < 0.15:
    print("slate")
elif deg < 15 or deg >= 345:
    print("red")
elif deg < 45:
    print("orange")
elif deg < 70:
    print("yellow")
elif deg < 160:
    print("green")
elif deg < 195:
    print("teal")
elif deg < 255:
    print("blue")
elif deg < 290:
    print("purple")
else:
    print("pink")
PYEOF
)
    [[ -n "$accent" ]] || return 0
    gsettings set org.gnome.desktop.interface accent-color "$accent" 2>/dev/null || true
}
