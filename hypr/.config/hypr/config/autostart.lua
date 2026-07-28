-- hypr/.config/hypr/config/autostart.lua — Lua port of config/autostart.conf
-- (Phase 13.1, plan 13.1-03 Task 2). All 17 exec-once lines are ported as
-- one call each (see below) inside a single hl.on("hyprland.start",
-- function() ... end) handler, in the identical top-to-bottom order, each
-- command string byte-identical to the hyprlang original. hl.on's event
-- name ("hyprland.start") is HL.EventName (hl.meta.lua); the top-level
-- exec_cmd helper (HL.API.exec_cmd) is used here, NOT the dsp-namespaced
-- dispatcher form used inside hl.bind — this repo has no bracket-rule
-- autostart entries, so the optional second argument is not needed
-- anywhere below.
--
-- Ordering is load-bearing (preserved from autostart.conf's own comments,
-- CONTEXT.md prohibition — no entry added, removed or reordered):
-- environment import before the uwsm app launches, gaming-mode reset
-- early.

hl.on("hyprland.start", function()
    -- ── Export env to dbus AND systemd user session FIRST ─
    -- Both are needed: dbus for portals, systemd for uwsm app scopes
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE GTK_THEME XCURSOR_THEME XCURSOR_SIZE")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE GTK_THEME XCURSOR_THEME XCURSOR_SIZE")

    -- ── Gaming mode (D-28) — always reset to OFF on session start ──
    -- UNCONDITIONAL, not a seed-if-missing guard: a stale ON state means
    -- the screen never locks (hypridle stays inhibited) AND the desktop
    -- is silently unthemed (eye-candy stays off) — this is the backstop
    -- that forecloses that failure mode structurally. Because
    -- gaming-mode-toggle.sh only ever changes the compositor at RUNTIME
    -- (hyprctl keyword, D-26, never a config-file write), a fresh
    -- Hyprland session already starts with the full on-disk config — the
    -- compositor has no memory of a prior session's runtime overrides.
    -- Resetting this state FILE is therefore sufficient; there is
    -- nothing left to un-apply on the compositor side. Placed EARLY
    -- (right after env export) — this is a cheap, order-independent
    -- state write with no daemon dependency, unlike everything below it.
    hl.exec_cmd("echo off > ~/.cache/gaming-mode")

    -- ── Wallpaper daemon ─────────────────────────────────
    hl.exec_cmd("uwsm app -- awww-daemon")

    -- ── Status bar ───────────────────────────────────────
    hl.exec_cmd("uwsm app -- ~/.config/hypr/scripts/waybar-launch.sh")

    -- ── Waybar fullscreen watcher (BAR-01/D-01) ──────────
    -- Long-running Hyprland socket2 listener translating fullscreen
    -- enter/exit events into intents on waybar-visibility.sh, the sole
    -- owner of waybar visibility (D-03). No-ops cleanly with no session.
    hl.exec_cmd("uwsm app -- ~/.config/hypr/scripts/waybar-fullscreen-watch.sh")

    -- ── Quickshell shell root (D-01/D-02, QS-05) ──────────
    -- Headless by design — ships nothing visible in daily use. The probe
    -- instrumentation panel (Super+Shift+G) is the only surface it can
    -- ever render, and only while summoned. quickshell-doctor (plan 03)
    -- asserts this process stays alive and claims zero exclusive zone.
    hl.exec_cmd("uwsm app -- ~/.config/hypr/scripts/quickshell-launch.sh")

    -- ── Notification daemon ──────────────────────────────
    -- swaync-launch.sh points swaync at the sass-compiled state-dir
    -- stylesheet (D-01/D-34/13-02), degrading to unstyled rather than
    -- not running at all if the compiled sheet is ever absent.
    hl.exec_cmd("uwsm app -- ~/.config/hypr/scripts/swaync-launch.sh")

    -- ── AGS media applet daemon (MEDIA-01/MEDIA-04, 10-06) ──
    -- The sole media-widget daemon this repo autostarts. The waybar
    -- media segment toggles this instance ("media") via
    -- `ags request -i media toggle-media`.
    hl.exec_cmd("uwsm app -- ags run --directory ~/.config/ags")

    -- ── Application launcher (elephant backend + walker) ─
    hl.exec_cmd("uwsm app -- elephant")
    hl.exec_cmd("uwsm app -- walker --gapplication-service")

    -- ── Idle daemon ──────────────────────────────────────
    hl.exec_cmd("uwsm app -- hypridle")

    -- ── SwayOSD (OSD-01/D-23/D-24) ───────────────────────
    -- swayosd-client (bound to XF86Audio*/mic-mute keys in keybinds.conf)
    -- is a thin D-Bus client with nothing to talk to until this server
    -- runs; it performs the actual volume/mute change AND renders the
    -- themed OSD pill from style.css. Launched here, before theme-init,
    -- so the pill is themed on first paint. The keyless caps-lock OSD is
    -- handled separately by the packaged swayosd-libinput-backend.service
    -- (system bus, enabled in install.sh).
    hl.exec_cmd("uwsm app -- swayosd-server")

    -- ── Polkit agent ─────────────────────────────────────
    hl.exec_cmd("uwsm app -- /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- ── Clipboard ────────────────────────────────────────
    -- UTIL-03/D-15: -max-items caps history at ~100 entries (default is
    -- 750) so plaintext secrets don't accumulate unbounded; paired with a
    -- session-end wipe (wleave logout/shutdown/reboot actions) and a
    -- manual wipe entry (clipboard-wipe.sh, Super+Shift+C) — Security
    -- Domain Information Disclosure mitigation, ships in the same wave
    -- as the cap.
    hl.exec_cmd("uwsm app -- wl-paste --type text --watch cliphist -max-items 100 store")
    hl.exec_cmd("uwsm app -- wl-paste --type image --watch cliphist -max-items 100 store")

    -- ── Apply last theme on login (wait for daemons to be ready) ──
    -- theme-init.sh is a thin caller (D-01): it only reads the saved
    -- theme (~/.local/state/theme/current-theme, falling back to
    -- catppuccin, D-10) and sets the wallpaper, then delegates to
    -- ~/.config/theme-engine/theme-apply for all rendering + reload.
    hl.exec_cmd("sleep 2 && ~/.config/hypr/scripts/theme-init.sh")
end)
