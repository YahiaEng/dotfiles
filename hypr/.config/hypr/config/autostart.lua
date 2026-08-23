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
    -- Both are needed: dbus for portals, systemd for uwsm app scopes.
    --
    -- 18-07 (QBAR-10, D-18-40): HYPRLAND_INSTANCE_SIGNATURE added to both
    -- lists below. A transient `uwsm app` scope is forked by the caller
    -- and inherits Hyprland's own environment; quickshell.service (18-07)
    -- is forked by the systemd user MANAGER instead and inherits the
    -- manager's own environment block — a different block. From the
    -- moment quickshell's launch path moves to the unit, any variable it
    -- needs that is missing from the manager's block is simply absent,
    -- and HYPRLAND_INSTANCE_SIGNATURE is the one Quickshell's Hyprland
    -- integration uses to find the compositor's socket. uwsm DOES export
    -- this variable into the manager block too, but asynchronously,
    -- through its own finalize mechanism (UWSM_FINALIZE_VARNAMES) — this
    -- line makes it deterministic instead: it already runs FIRST in this
    -- handler, it reads the variable from Hyprland's own environment
    -- where it is guaranteed present, and re-importing a variable uwsm
    -- also exports is idempotent and sets the identical value. This is a
    -- value change to an existing line's argument list, not a new entry
    -- (D-15/D-35's "no entry added, removed or reordered" governs entries,
    -- not an existing entry's arguments), so it does not touch that
    -- prohibition.
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE GTK_THEME XCURSOR_THEME XCURSOR_SIZE HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE GTK_THEME XCURSOR_THEME XCURSOR_SIZE HYPRLAND_INSTANCE_SIGNATURE")

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

    -- The retired bar's fullscreen watcher (formerly BAR-01/D-01) was
    -- RETIRED here (D-18-28, Phase 18 Plan 15/QBAR-07): the standalone
    -- socket2 listener was deleted outright, not repointed — the
    -- fullscreen intent is now reported by the QML shell itself, off the
    -- `fullscreenBlocking` value it already derives for DASH-08, via an
    -- onFullscreenBlockingChanged handler in shell.qml. One long-running
    -- process was removed from the session as a direct consequence, and
    -- RETIRE-02 (18-20) removed the launcher entry itself the same way —
    -- both are deliberate, plan-authorised entry removals, the narrower
    -- exception D-18-28 and this plan carve out of this file's own "no
    -- entry added, removed or reordered" prohibition above. The QML bar's
    -- own launch entry is the `quickshell.service` start below.

    -- ── Quickshell shell root (D-01/D-02, QS-05; 18-07 QBAR-10) ───
    -- No longer headless: 18-01 mounted a permanent PanelWindow bar with
    -- a real exclusive zone, so this shell root's process death is now a
    -- visible desktop outage, not the invisible loss of a headless probe
    -- daemon. The probe instrumentation panel (Super+Shift+G) is still a
    -- surface it can render, summoned on demand; it is no longer the
    -- only one. This process IS the session's notification server: it
    -- owns org.freedesktop.Notifications on the session bus (Phase 19,
    -- RETIRE-03/D-19-42), and quickshell-doctor's own owner registry
    -- names it as the declared owner of that bus name. The separate
    -- notification daemon that used to hold it had its launch entry
    -- removed from this file in Plan 19-08 Task 4 — see the removal
    -- carve-out recorded further down this file. quickshell-doctor still
    -- asserts this process stays alive and its liveness/namespace checks
    -- are unaffected by the launch-mechanism change below.
    --
    -- 18-07 (QBAR-10, D-18-40): launched through quickshell.service
    -- instead of a transient `uwsm app` scope — this is the ONLY entry
    -- in this file that does not launch through a uwsm scope, and that
    -- is deliberate, not an oversight. D-15/D-35's autostart prohibition
    -- forbids an entry being ADDED, REMOVED or REORDERED; this changes
    -- neither — the entry stays, in this exact position, in the same
    -- relative order, launching the same program from the same
    -- unmodified script. Only the MECHANISM on this one line changes.
    -- Widening this deviation to any other entry on this page is not in
    -- scope for this plan. `--no-block` is deliberately NOT used: the
    -- start job for a Type=simple service completes as soon as the
    -- process is forked, this call is not on the compositor's critical
    -- path, and blocking means a unit that fails to load surfaces its
    -- error here rather than nowhere at all.
    hl.exec_cmd("systemctl --user start quickshell.service")

    -- ── Bar watchdog (WINDOWS.md row 67) ─────────────────
    -- Monitor removal/re-add (display sleep, DPMS cycle, hotplug)
    -- destroys the `quickshell-bar` layer surface while quickshell
    -- itself stays perfectly healthy — same pid, NRestarts=0,
    -- ActiveState=active, zero QML errors — and keeps reporting
    -- `bar: visibility=visible zone=reserved` while no surface exists.
    -- The bar stays gone until quickshell.service is restarted by hand.
    --
    -- This REVERSES the removal noted directly above: D-18-28 deleted
    -- this repo's standalone socket2 listener because the QML shell
    -- could report its own fullscreen intent instead. Here the shell is
    -- precisely the thing that fails — it cannot report an outage it
    -- doesn't know it's in — so a self-healing mechanism structurally
    -- cannot live inside it. One long-running process was removed from
    -- the session there; a different one, for a different defect, is
    -- added back here. Full listener + fixture-proven test harness:
    -- hypr/.config/hypr/scripts/bar-watchdog.sh.
    --
    -- D-15/D-35 carve-out: this is an entry ADDED, which this file's own
    -- "no entry added, removed or reordered" prohibition (top of file)
    -- otherwise forbids. Named here as a deliberate, plan-authorised
    -- addition (quick 260812-n9b) in the same register D-18-28 used for
    -- its authorised removal — not an oversight, and not a widening of
    -- the prohibition's exception surface beyond this one line.
    --
    -- `systemctl --user start`, not `uwsm app --`: the unit is what
    -- carries the restart policy and the session-teardown binding,
    -- exactly as for quickshell.service directly above. `--no-block` is
    -- deliberately not used, for the same reason that entry gives: the
    -- start job for a Type=simple service completes as soon as the
    -- process is forked, this call is not on the compositor's critical
    -- path, and blocking means a unit that fails to load surfaces its
    -- error here rather than nowhere at all.
    hl.exec_cmd("systemctl --user start quickshell-bar-watchdog.service")

    -- The standalone notification daemon that used to be launched HERE
    -- was RETIRED in Plan 19-08 Task 4 (RETIRE-03, D-19-42). Its launch
    -- entry and its launch script are both gone: the QML shell root
    -- started above now owns org.freedesktop.Notifications directly, in
    -- the same process, so a second launcher on this page would be a
    -- second process racing for a bus name only one owner can hold —
    -- and the loser fails quietly, which is precisely the failure D-19-42
    -- exists to make impossible.
    --
    -- This is an entry REMOVED, which this file's own "no entry added,
    -- removed or reordered" prohibition (top of file) otherwise forbids.
    -- Named here as a deliberate, plan-authorised removal in the same
    -- register D-18-28 and RETIRE-02 (18-20) used for theirs — not an
    -- oversight, and not a widening of the prohibition's exception
    -- surface beyond this one entry.
    --
    -- The swap was made atomic on purpose: this removal and the declared
    -- owner in quickshell-doctor's registry are the same fact recorded in
    -- two places, so they move together. See that file's own note at the
    -- registry row for the one wrinkle in how that landed here.

    -- The separate application-launcher processes (the retired backend
    -- daemon and its GTK4 frontend) that used to be started HERE were
    -- RETIRED in quick task 260822-sht Task 10: the launcher is now a
    -- native QML surface
    -- (`modules/launcher/`) living inside the quickshell.service process
    -- started above, summoned in-process rather than autostarted as its
    -- own daemon pair.
    --
    -- This is an entry REMOVED, which this file's own "no entry added,
    -- removed or reordered" prohibition (top of file) otherwise forbids.
    -- Named here as a deliberate, plan-authorised removal in the same
    -- register D-18-28 and RETIRE-02/RETIRE-03 (18-20/19-08) used for
    -- theirs — not an oversight, and not a widening of the prohibition's
    -- exception surface beyond this one entry.

    -- ── Idle daemon ──────────────────────────────────────
    -- Session-start idle-intent reset: the bar-visibility intent files
    -- survive reboots (D-18-27), but hypridle's on-resume can only fire
    -- after a same-session on-timeout — so an idle=hide left behind by a
    -- session that crashed while idle-hidden would strand the bar hidden
    -- for an active user until the next full idle→resume cycle. A fresh
    -- session is non-idle by definition, so declare it through the owner
    -- BEFORE hypridle starts. The declare path writes the intent file
    -- even if the Quickshell IPC actuation fails (the shell may not be
    -- up yet); shell.qml's startup reassert then reads the fresh state.
    hl.exec_cmd("uwsm app -- ~/.config/hypr/scripts/bar-visibility.sh idle show")
    hl.exec_cmd("uwsm app -- hypridle")

    -- ── Polkit agent ─────────────────────────────────────
    hl.exec_cmd("uwsm app -- /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- ── Clipboard ────────────────────────────────────────
    -- UTIL-03/D-15: -max-items caps history at ~100 entries (default is
    -- 750) so plaintext secrets don't accumulate unbounded; paired with a
    -- session-end wipe (PowerMenu.qml's own logout/shutdown/reboot actions,
    -- migrated from wleave's layout.json — RETIRE-05, Phase 20 Plan 10) and
    -- a manual wipe entry (clipboard-wipe.sh, Super+Shift+C) — Security
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
