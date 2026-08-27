// modules/session/PowerActions.qml — the six power-menu actions, extracted
// from PowerMenu.qml's own inline array (quick-260821-6z1 Task 12, D-01
// bundle 3) into a singleton BOTH PowerMenu.qml and SessionPage.qml read.
// PowerMenu.qml is NOT itself a singleton (mounted behind a LazyLoader,
// modules/session/qmldir's own header explains why) — a settings page has
// no live instance to read `actions` from, so the six names would
// otherwise have to be duplicated in two places. This singleton is the
// single source of truth for the label set; SessionPage.qml's own
// "default focused action" SelectRow reads `PowerActions.actions` for its
// model, never a second hardcoded name list.
//
// Same registration discipline as every other singleton in this tree:
// `pragma Singleton` here AND the `singleton` keyword in
// modules/session/qmldir, or bare `PowerActions.actions`-style access
// resolves to `undefined` forever, with no load error.
//
// ── NO ACTION HERE WRAPS hyprshutdown ANY MORE ─────────────────────────
// (quick task 260827-74s, 2026-08-27, operator decision. Reboot and Shut
// Down first; Log Out followed in the same task on the operator's "fix log
// out as well and any other power menu action".)
//
// Audited, all six: Lock (`uwsm app -- hyprlock`), Suspend and Hibernate
// (`systemctl suspend|hibernate`) never wrapped it and do not tear the
// session down at all — they resume into this same session. Log Out,
// Reboot and Shut Down all did. None do now, and a tree-wide grep shows
// zero remaining consumers outside this comment.
//
// They used to run `hyprshutdown --post-cmd '<verb>'`, which asks every
// window to close and then WAITS. hyprshutdown 0.1.1-6 registers exactly
// these options — dry-run, no-exit, top-label, post-cmd, verbose, no-fork,
// vt, help — and NO timeout of any kind. Run with --dry-run --verbose it
// loops `Re-closing apps` forever; its own UI offers `Force quit` with the
// warning "You can force quit Hyprland, but that risks losing unsaved
// progress." So one app that will not close held the machine on
// "Shutting down... / Waiting for your apps to exit." indefinitely. That
// was the operator's reported hang.
//
// systemd was NOT the bottleneck, so lowering DefaultTimeoutStopSec would
// have fixed nothing: the journal holds two clean power-key poweroffs that
// bypass hyprshutdown, Aug 22 (1.5s) and Aug 24 (1.3s) power-key to
// `Reached target System Power Off`, with app-graphical.slice gone 75ms
// into the Aug 24 teardown.
//
// The wrap was never load-bearing either. It came from Phase 4 / FIX-01,
// whose own 04-01-SUMMARY.md Task 2 records the hang it targeted as never
// reproduced — "No hang reproduced", "intermittent / not currently
// reproducible on demand" — and applied the wrap on a structural
// bare-systemctl-is-uwsm-incorrect argument, not on evidence.
//
// TRADE-OFF, stated to the operator before they chose this and accepted:
// apps are now killed when the compositor exits rather than asked to close,
// so unsaved work is likelier lost. This also retires the mechanism behind
// requirement QPOWER-04 ("keep the graceful compositor exit that closed the
// FIX-01 hang class"). If a black-screen hang ever DOES appear on this
// path, hyprshutdown's `--vt N` option ("Switch to VT N after Hyprland
// exits (fixes NVIDIA+SDDM black screen)") is the targeted remedy — it was
// never wired up here. It is no longer in `install.sh` either, since
// nothing consumes it — `sudo pacman -S hyprshutdown` first if you ever
// want that flag.
//
// ── Log Out specifically: bare `uwsm stop` does NOT stall ──────────────
// This is the WR-04 / D-29 question — "does `uwsm stop` stall on unclosed
// clients on this host?" — whose stopwatch test the operator waived unrun
// on 2026-07-28, leaving Logout wrapped "by default, not by evidence"
// (13-03-SUMMARY.md). The journal answers it. On the Aug 24 teardown, with
// VSCodium, Zen and seven kitty windows live (10.2 GiB peak across the
// slice):
//
//   18:31:44.095  uwsm receives SIGTERM, starts stopping the session
//   18:31:44.162  app-graphical.slice released          ← +67ms
//   18:31:44.581  wayland-wm@hyprland.desktop stopped   ← +486ms
//   18:31:44.688  session envelope fully stopped        ← +593ms
//
// Clients did not hold it up; nothing came near `wayland-wm`'s own 10s
// TimeoutStopSec, let alone the 90s the app scopes carry. `uwsm stop`
// stops `wayland-wm@*.service` (uwsm main.py `stop_wm()`), and systemd
// cascades that to `graphical-session.target` and `app-graphical.slice` —
// the same units torn down above.
//
// HONEST CAVEAT: that trigger was SIGTERM delivered to uwsm during a
// system poweroff, not the `uwsm stop` CLI. Same units, same cascade, so
// the durations carry — but this is journal-derived, not the literal
// stopwatch D-29 asked for. Treat WR-04 as answered-by-evidence, not as a
// gate that was finally run.
//
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // 12 o'clock (0°), then clockwise — Log Out (60°), Suspend (120°),
    // Hibernate (180°), Reboot (240°), Shut Down (300°). PowerMenu.qml's
    // own rotation model reads this same order; do not reorder without
    // checking that file's `rotateFocus()`.
    readonly property var actions: [
        {
            glyph: "lock", label: "Lock", mnemonic: "l",
            command: ["sh", "-c", "uwsm app -- hyprlock"]
        },
        {
            glyph: "logout", label: "Log Out", mnemonic: "e",
            command: ["sh", "-c", "cliphist wipe; uwsm stop"]
        },
        {
            glyph: "bedtime", label: "Suspend", mnemonic: "u",
            command: ["sh", "-c", "systemctl suspend"]
        },
        {
            glyph: "ac_unit", label: "Hibernate", mnemonic: "h",
            command: ["sh", "-c", "systemctl hibernate"]
        },
        {
            glyph: "restart_alt", label: "Reboot", mnemonic: "r",
            command: ["sh", "-c", "cliphist wipe; systemctl reboot"]
        },
        {
            glyph: "power_settings_new", label: "Shut Down", mnemonic: "s",
            command: ["sh", "-c", "cliphist wipe; systemctl poweroff"]
        }
    ]
}
