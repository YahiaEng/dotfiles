---
phase: 19-notification-server-centre
plan: 01
subsystem: notifications
tags: [quickshell, qml, dbus, notifications, hyprland]

# Dependency graph
requires:
  - phase: 18-qml-bar-retirement-machinery
    provides: Design.qml/BarRoles.qml token+role singletons, GradientBorder.qml rim component, Motion.qml duration/easing tokens, the ^quickshell-.* windowrules.lua family (blur/ignore_alpha), Bar.qml's always-top+right anchor posture, the shell.qml root-scope always-on mounting pattern
provides:
  - The full Phase 19 token/colour-role surface (ten Design.qml tokens, three BarRoles.qml rows) every later notification plan consumes without reopening either file
  - A pragma-Singleton NotifServer owning org.freedesktop.Notifications with exactly D-19-38's capability set (body, body-markup, body-hyperlinks, actions, icon-static, persistence)
  - NotifData, the per-notification wrapper bound live via property-changed Connections (the mechanism a replaces_id re-send updates in place without re-animating)
  - NotifPopupStack + NotifCard — a real, themed, top-right popup surface with a working D-19-04 dismiss timer (5s/3s/never) and stack/reflow via ListView transitions
  - Three exact-match windowrules.lua namespace rows (quickshell-notif-popups/-centre/-toast) so waves 2-3 never reopen that file
affects: [19-02, 19-03, 19-04, 19-05, 19-06, 19-07, 19-08]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
actuals:
  tokens: 8409
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: [Quickshell.Services.Notifications]
  patterns:
    - "pragma Singleton + qmldir's singleton keyword for NotifServer, the same both-required construction rule Colours.qml/Motion.qml/Design.qml already established (12-06)"
    - "A per-notification wrapper (NotifData) binds through a Connections block on the wrapped Notification's own property-changed signals, never by re-subscribing to the server's arrival signal — the binding shape that makes an in-place replaces_id update fall out for free instead of needing an explicit no-reanimate guard"
    - "A corner-anchored surface (top+right, matching Bar.qml's own always-anchored edges in both orientations) lets the compositor auto-clear whichever edge the bar currently reserves — no live read of Bar's exclusiveZone/vertical properties needed in the consuming surface"
    - "QtObject-rooted QML files must assign a Connections/Item child through an explicit named property (property Connections _x: Connections { ... }), never as an anonymous default-property child — QtObject has no default property"

key-files:
  created:
    - quickshell/.config/quickshell/modules/notifications/NotifServer.qml
    - quickshell/.config/quickshell/modules/notifications/NotifData.qml
    - quickshell/.config/quickshell/modules/notifications/NotifPopupStack.qml
    - quickshell/.config/quickshell/modules/notifications/NotifCard.qml
    - quickshell/.config/quickshell/modules/notifications/qmldir
  modified:
    - quickshell/.config/quickshell/modules/dashboard/Design.qml
    - quickshell/.config/quickshell/modules/bar/BarRoles.qml
    - quickshell/.config/quickshell/shell.qml
    - hypr/.config/hypr/config/windowrules.lua

key-decisions:
  - "QtObject root types need an explicit named Connections property, not an anonymous child — QtObject carries no default property, so a bare Connections { ... } child fails to compile with 'Cannot assign to non-existent default property'. Found live wiring NotifData.qml, fixed with property Connections _liveBindings: Connections { ... }."
  - "NotifPopupStack anchors the exact same two edges Bar.qml always anchors (top+right, in both bar orientations) rather than branching on Bar's own vertical/reservedZoneExtent properties — the compositor auto-pushes an anchored surface past another surface's exclusive-zone reservation on a shared edge regardless of this surface's own (zero) exclusiveZone, the same live-measured mechanism SectionPopout.qml's own F5 finding already established. Live-verified: popup landed at x=1430 (10px clear of the vertical bar at x=1870) with margins.top/right both a constant Design.barSideMargin (10)."
  - "swaync is D-Bus-activated (Type=dbus, BusName=org.freedesktop.Notifications in swaync.service), not merely a bare exec-once process as the plan's own precondition text implied — plain pkill -x swaync respawned it within ~1s via systemd's own D-Bus activation. systemctl --user mask/unmask was needed to hold the bus name uncontested for Task 2/3's live busctl verification; unmasked immediately afterward, restoring the pre-test state."

patterns-established:
  - "Notification tokens/roles live exclusively in Design.qml/BarRoles.qml, extended in one pass by Task 1 so no later Phase 19 plan reopens either file for a token addition"
  - "NotifServer's public surface (popups/history/dnd/unreadCount, dismiss/clearAll/openCentre/toggleDnd) is declared in full now; unimplemented verbs are honest, reachable empty stubs — never unreachable branches — for waves 2-3 to extend"

requirements-completed: [QNOTIF-01, QNOTIF-02]

coverage:
  - id: D1
    description: "Full Phase 19 Design.qml token surface (10 tokens) and BarRoles.qml colour-role surface (3 rows, all `color`-typed) declared in one pass"
    requirement: "QNOTIF-01"
    verification:
      - kind: other
        ref: "grep -q 'readonly property .* <token>' Design.qml (all 10) + grep -qE 'readonly property color +<role>:' BarRoles.qml (all 3) + quickshell-doctor --self-test"
        status: pass
    human_judgment: false
  - id: D2
    description: "Shell owns org.freedesktop.Notifications with exactly the D-19-38 capability set; NotifData binds live via Connections, never re-reading the server's arrival signal"
    requirement: "QNOTIF-01"
    verification:
      - kind: manual_procedural
        ref: "live busctl --user list (sole owner, count=1) + busctl call GetCapabilities (exactly 6 members: persistence, body, body-markup, body-hyperlinks, actions, icon-static) against the real session, swaync.service masked for the duration"
        status: pass
    human_judgment: false
  - id: D3
    description: "A real notify-send renders a themed top-right popup card; two in flight stack and reflow; low/normal/critical urgency respect swaync-identical dismiss timing"
    requirement: "QNOTIF-02"
    verification:
      - kind: other
        ref: "live hyprctl layers geometry: single card 430x86 at x=1430 (10px clear of the vertical bar); two cards grow the stack to height 180 (86 + Design.spacingSm 8 + 86); low-urgency collapses to empty ~3-4s; critical still rendered unchanged after 6s"
        status: pass
      - kind: manual_procedural
        ref: "operator checkpoint approval, 2026-08-13: cards render per design (rounded corners, gradient rim, translucent fill, readable text), second card visibly sits below the first with a gap, dismissing the upper card animates the lower one upward"
        status: pass
    human_judgment: false

duration: ~55min
completed: 2026-08-13
status: complete
---

# Phase 19 Plan 01: Notification Server Tracer Summary

**A Quickshell-owned `org.freedesktop.Notifications` server (exactly six declared capabilities) renders real `notify-send` calls as themed, top-right, auto-dismissing popup cards — the end-to-end proof every later Phase 19 plan builds out from.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-08-13 (session start)
- **Completed:** 2026-08-13T09:37:31Z (last task commit)
- **Tasks:** 3 completed
- **Files modified:** 9 (5 created, 4 modified)

## Accomplishments
- Declared the complete Phase 19 `Design.qml`/`BarRoles.qml` token and colour-role surface in one pass, so no later plan in this phase reopens either file
- The Quickshell process now owns `org.freedesktop.Notifications`, declaring exactly D-19-38's capability set (`body`, `body-markup`, `body-hyperlinks`, `actions`, `icon-static`, `persistence`) — live-verified via `busctl` against the real session
- A real `notify-send` renders a themed, top-right popup card within 1s; two cards stack with an 8px gap and reflow via `ListView` `add`/`move`/`displaced`/`remove` transitions; the D-19-04 dismiss timer (5s normal, 3s low, critical never) was live-verified end to end
- `NotifPopupStack` anchors the exact same two edges `Bar.qml` always anchors (top+right), so the compositor auto-clears whichever edge the bar currently reserves in either orientation — no live read of `Bar`'s own `exclusiveZone`/`vertical` properties needed

## Task Commits

Each task was committed atomically:

1. **Task 1: Declare the full token and colour-role surface** - `d25c24c` (feat)
2. **Task 2: The server — own the bus name, declare capabilities, wrap one notification** - `fe753f5` (feat)
3. **Task 3: One popup card on screen — the end-to-end proof** - `c54d864` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified
- `quickshell/.config/quickshell/modules/notifications/NotifServer.qml` - pragma-Singleton D-Bus notification server, popups/unreadCount/dismiss() implemented for real
- `quickshell/.config/quickshell/modules/notifications/NotifData.qml` - per-notification wrapper, live property-changed binding
- `quickshell/.config/quickshell/modules/notifications/NotifPopupStack.qml` - top-right PanelWindow, ListView with stack/reflow transitions
- `quickshell/.config/quickshell/modules/notifications/NotifCard.qml` - popup card body, icon fallback chain, dismiss timer, critical-urgency colour swap
- `quickshell/.config/quickshell/modules/notifications/qmldir` - registers all four new types
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` - ten new `notif*` tokens
- `quickshell/.config/quickshell/modules/bar/BarRoles.qml` - three new `notifSurface*` colour roles
- `quickshell/.config/quickshell/shell.qml` - imports the notifications module, mounts `NotifServer` reference and `NotifPopupStack` at root scope
- `hypr/.config/hypr/config/windowrules.lua` - three exact-match `quickshell-notif-{popups,centre,toast}` animation rows

## Decisions Made
- QtObject-rooted files must assign a `Connections` child through a named property, not an anonymous default-property child (found live, see key-decisions in frontmatter)
- Corner-anchoring `NotifPopupStack` to `Bar.qml`'s own always-anchored edges (top+right) lets the compositor's own exclusive-zone accounting clear whichever edge the bar reserves, avoiding a live property read entirely
- `swaync` is D-Bus-activated, not a bare process — `systemctl --user mask`/`unmask` was the correct tool for a clean single-owner test window, not `pkill` alone

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `Connections` block fails to compile as an anonymous child of a `QtObject` root**
- **Found during:** Task 2 (writing `NotifData.qml`)
- **Issue:** `quickshell -p` reported `Cannot assign to non-existent default property` at the `Connections { ... }` block — `QtObject` (unlike `Item`/`Singleton`) has no default property to receive an anonymous child
- **Fix:** Assigned the block through an explicit named property instead: `property Connections _liveBindings: Connections { ... }`
- **Files modified:** `quickshell/.config/quickshell/modules/notifications/NotifData.qml`
- **Verification:** `quickshell -p` reported `Configuration Loaded` with no errors; live-verified against the real session (Task 2/3 automated checks both passed)
- **Committed in:** `fe753f5` (Task 2 commit — found and fixed before the commit, not a separate follow-up)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary for Task 2 to compile at all. No scope creep — the fix is a QML-language-constraint correction, not a design change.

## Issues Encountered
- `swaync.service` (`Type=dbus`, `BusName=org.freedesktop.Notifications`) auto-respawned within ~1s of a plain `pkill -x swaync`, because killing the process released the bus name and something on the session (most likely the bar's own persistent `swaync-client -swb` subscriber attempting to reconnect) triggered D-Bus re-activation. Resolved by `systemctl --user mask swaync.service` for the duration of the live `busctl`/`notify-send` verification, then `systemctl --user unmask swaync.service` immediately afterward — this is normal flow (documented in the plan's own Task 2 precondition), not a defect.
- `quickshell.service` briefly hit systemd's `start-limit-hit` while iterating on the `NotifData.qml` fix above (several restart attempts in quick succession during debugging); resolved with `systemctl --user reset-failed quickshell.service` before continuing. No code change required.
- This session's display reports as a `FALLBACK`/no-physical-framebuffer output — `grim` screenshots returned solid black despite `hyprctl layers` proving correct surface geometry. Visual confirmation (card appearance, stacking gap, reflow animation) was therefore deferred to a `checkpoint:human-verify`, approved by the operator before this SUMMARY was written.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The full token/colour-role surface, the D-Bus server, and a real, themed, animated popup card are all proven live and committed — plans 19-02 through 19-07 (the centre, gestures, `replaces_id`, history/grouping, DND/suppression, the shared toggle grid, the security/consolidated review) build out from this proven slice without re-proving the architecture.
- No blockers. `swaync` remains installed and functional as a fallback until plan 19-08's deletion — this plan's own `NotifPopupStack`/`NotifServer` coexist with it in the sense that whichever process claims `org.freedesktop.Notifications` first wins (an acknowledged, documented transitional state per D-19-42/T-19-02, not a defect to fix here).

---
*Phase: 19-notification-server-centre*
*Completed: 2026-08-13*
