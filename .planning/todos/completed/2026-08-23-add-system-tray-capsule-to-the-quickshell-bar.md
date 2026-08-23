---
created: 2026-08-22T23:44:02.887Z
title: Add system tray capsule to the Quickshell bar
area: ui
severity: major
files:
  - quickshell/.config/quickshell/modules/bar/ (new capsule lives here)
  - quickshell/.config/quickshell/modules/Bar.qml
  - quickshell/.config/quickshell/modules/bar/BarEntryModel.qml (capsule registration)
  - quickshell/.config/quickshell/modules/Prefs.qml (bar.capsules.* toggle)
---

## Problem

**This desktop has no system tray at all**, so applications that minimise to tray
cannot be closed from their own window — they hide to a tray that does not exist and
their window comes straight back.

Verified 2026-08-23:

- A tree-wide grep of `quickshell/.config/quickshell/` finds **zero** references to
  `SystemTray` or `StatusNotifier`.
- `busctl --user list` shows **no** `StatusNotifierWatcher` registered on the session
  bus — nothing is hosting the SNI protocol.

waybar provided the tray. It was retired in Phase 18 Plan 20 (RETIRE-02) and the
Quickshell bar never took the role over, so the capability was lost rather than ported.

**How it surfaced.** The operator reported that Steam relaunched itself every time they
closed it. Debugging separated two independent faults:

1. A `steamwebhelper` crash loop — `bad IPC message, reason 213` renderer kills plus
   repeated webhelper respawns. **STILL UNFIXED and unrelated to this todo.** Two
   remedies were tried and BOTH FAILED: clearing
   `~/.local/share/Steam/config/htmlcache`, and launching with `-cef-disable-gpu`.
   Measured over the full log 2026-08-23 04:19: 37 browser starts and 22 renderer kills,
   with starts continuing at 02:43, 02:46 and two 10s apart at 04:18 — i.e. long after
   both remedies were applied. An earlier note in this file claimed it was fixed; that
   was wrong, drawn from a ~1-minute sample of a loop whose period is minutes to hours.
   Note the alarming-looking `data:text/html,%3Cbody%3E%3C%2Fbody%3E` URL IS a red
   herring — `webhelper.txt` shows Steam's own client window is internally named
   `SteamBrowser-'data:text/'`, so that part is normal.
2. **This one** — independently of the crash loop, closing the window does not quit Steam,
   because there is no tray to minimise into. `steam -shutdown` is the only reliable quit.
   The two faults are separate: a tray would fix the close behaviour even while the
   webhelper loop persists.

Affects every tray-minimising app, not just Steam: Discord, Telegram, Nextcloud, etc.

## Solution

Build an in-process tray capsule for the bar. Both required APIs are already installed —
verified at `/usr/lib/qt6/qml/Quickshell/`:

- `Quickshell.Services.SystemTray` — the SNI host/items
- `Quickshell.DBusMenu` — the right-click context menus tray items expose

Follow the established capsule pattern rather than inventing a new one (see
`.claude/CLAUDE.md`, "Stack Patterns by Variant"): build it under
`quickshell/.config/quickshell/modules/bar/`, read every colour from `Colours.qml` /
`BarRoles.qml` (`colour-lint` GATE-04 rejects literals), animate through `Motion.qml`'s
seven allowed token pairs, and register it in `BarEntryModel.qml` so it participates in
the existing per-capsule visibility system.

Scope to settle when this is picked up:

- Left-click activate, right-click DBusMenu, middle-click secondary-activate.
- Icon resolution must use the `Quickshell.hasThemeIcon()`-gated chain
  (`NotifGroup.qml:133-150`) — `Quickshell.iconPath(name, "")` alone returns a
  placeholder for a missing name that renders as a broken-texture glyph.
- A `bar.capsules.systemTray` pref in `Prefs.qml` (`_allowedKeys` **and** `_defaults`),
  matching the other capsule toggles.
- Decide overflow behaviour when many items are present.

**Deliberately deferred** out of quick task 260822-sht (the walker/elephant → QML
launcher migration): this belongs to the bar, not the launcher, and Stage 3 of that task
is an irreversible retirement that should not absorb a new bar surface mid-flight.
