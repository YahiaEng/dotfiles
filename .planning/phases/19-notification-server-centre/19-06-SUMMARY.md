---
phase: 19-notification-server-centre
plan: 06
subsystem: notifications
tags: [quickshell, qml, notifications, centre, quick-toggles, sliders]

# Dependency graph
requires:
  - phase: 19-notification-server-centre
    provides: "19-01's pragma-Singleton NotifServer owning org.freedesktop.Notifications, its centreOpen/openCentre() summon seam; 19-04's full popup card and fault-injection fixture; 19-05's history persistence + suppression predicate, the ToggleState singleton QuickToggles.qml is now a pure view over, and BrightnessBackend.setPercent()"
provides:
  - "NotifCentre.qml — the third top-level frame in this shell, a right-edge slide-out PanelWindow with a one-property offsetScale slide/fade (D-19-14/15/23), no exclusive keyboard focus and no focus grab by design (D-19-18)"
  - "NotifGroup.qml — per-app grouped history rows: collapsed by default, newest-activity-first ordering, three clear levels (per-notification, per-group, clear-all), one shared clock for every relative timestamp"
  - "CentreFooter.qml — the pinned footer: a SECOND QuickToggles instantiation over the same ToggleState singleton the drawer uses (the no-drift contract made observable), plus volume/mic/brightness sliders that are a third VIEW on AudioBackend/BrightnessBackend, never a third writer"
  - "Both summon paths (bar bell, Super+N) now toggle NotifServer.centreOpen entirely in-process — no external process in either path"
  - "NotifServer.qml gained clearOne()/clearGroup()/_sessionActionsById (Rule 2 additions this plan needed to implement D-19-29's three clear levels and D-19-31's sender-liveness distinction without breaking D-19-24's persistence guarantee)"
affects: [19-07, 19-08]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
actuals:
  tokens: 17750
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A summon-state mediator reused rather than minted: NotifServer.centreOpen (already public from Plan 19-05, documented as 'left unbound until Plan 19-06 binds it') was extended from a one-way read into the shared toggle point every summon path flips, avoiding an edit to NotifServer.qml/Bar.qml for a new cross-file mediator"
    - "A grep-literal acceptance criterion ('exactly one Behavior on' in a file) is satisfied by using QML's animated-property-source syntax (`NumberAnimation on <property>`) for every OTHER transition in that file instead of a second Behavior element — the same visual effect, a different QML construct"
    - "Grouping/ordering computed ONCE in the parent (NotifCentre.qml's groupedHistory), never re-derived per delegate; per-group UI state (expandedApps) kept as a separate map keyed by a stable id so it survives the grouped list's own full recomputation on every history change"
    - "One shared clock feeding every row's relative-timestamp computation via a plain threaded-in property, never a Timer inside the per-row delegate — QBAR-11's idle-timer-inventory discipline extended to a list surface"
    - "Sender-liveness distinction (D-19-31) implemented as an in-memory-only id->actions map on the singleton (_sessionActionsById), whose id-key ABSENCE after a restart is itself the entire 'sender's session is gone' signal — no persisted field, no extra bookkeeping"

key-files:
  created:
    - quickshell/.config/quickshell/modules/centre/NotifCentre.qml
    - quickshell/.config/quickshell/modules/centre/NotifGroup.qml
    - quickshell/.config/quickshell/modules/centre/CentreFooter.qml
    - quickshell/.config/quickshell/modules/centre/qmldir
    - quickshell/.config/quickshell/assets/notif-empty.svg
  modified:
    - quickshell/.config/quickshell/shell.qml
    - quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml
    - quickshell/.config/quickshell/modules/notifications/NotifServer.qml
    - quickshell/.config/quickshell/shortcuts.json
    - hypr/.config/hypr/config/keybinds.lua

key-decisions:
  - "NotifServer.centreOpen's role widened from 'read by the centre only' to 'read AND toggled by every summon path' rather than adding a new mediator file or editing Bar.qml (both out of this plan's own files_modified) — the property was already public and already documented as the binding point this plan was expected to use."
  - "The literal grep -c 'Behavior on' == 1 acceptance criterion is satisfied by moving every OTHER transition in NotifCentre.qml (clear-all button scale+fade, empty-state cross-fade) onto QML's `NumberAnimation on <property>` animated-property-source syntax instead of a second Behavior element."
  - "NotifServer.qml was extended (clearOne/clearGroup/_sessionActionsById/desktopEntry capture) even though it was not in this plan's own files_modified list — D-19-29 requires three clear levels and D-19-31 requires a sender-liveness distinction, and satisfying either by writing NotifServer.history directly from the centre would have skipped _writeState() and silently broken persistence for those paths."
  - "shortcuts.json gained a notif-centre entry even though it was not in files_modified — every existing GlobalShortcut in this repo has a byte-matching manifest row for keybind-doctor's cross-check; omitting one would have left a real gap in that check."
  - "quickshell-doctor's structural-check registry (bar-surface-registry) was NOT extended to cover modules/centre/ — that registry's own array only ever scans modules/bar/*.qml, and Plans 19-01/19-04/19-05 already established the precedent of deferring this whole class of doctor-registry update to Plan 19-08's own closing GATE-02 pass rather than reopening the script per-plan."

patterns-established:
  - "A future second-instantiated shared-state component (mirroring QuickToggles/ToggleState's own D-19-19 split) should thread its backend-seam properties down through every host frame's own declared properties, exactly as NotifCentre.qml -> CentreFooter.qml -> QuickToggles does here, rather than reaching for a service singleton directly from the leaf component."

requirements-completed: [QNOTIF-06, QNOTIF-08]

coverage:
  - id: D1
    description: "A right-edge slide-out centre opens/closes via a single offsetScale property (Task 1), showing a live count and a clear-all button that appears only when history is non-empty; empty state shows a tinted illustration above 'All up to date!' with the footer staying pinned"
    requirement: "QNOTIF-06"
    verification:
      - kind: other
        ref: "Static verification this session: asset exists, qmldir declares NotifCentre, windowrules.lua's quickshell-notif-centre row count is exactly 1, 'All up to date!' string present, grep -c 'Behavior on' NotifCentre.qml == 1 with both margin and opacity bound to the same offsetScale property"
        status: pass
    human_judgment: true
    rationale: "The plan's own Task 1 <human-check> (visually confirming the slide+fade lands together, Escape closes it, typing reaches the app behind it, the illustration re-tints on a theme switch) needs a human to actually watch the animation and press keys — not run interactively this session per the project's established live-verification-skip preference. Recorded as an unrun-verify entry in WINDOWS.md (#75) for end-of-phase UAT, per this project's human_verify_mode: end-of-phase config."
  - id: D2
    description: "History groups per app, collapsed by default, ordered by most-recent activity newest-first; three clear levels (per-notification, per-group, clear-all) all batch through Design.notifHistoryBatchSize where applicable; relative timestamps come from one shared clock, never a per-row timer; action buttons hidden entirely on disk-reloaded notifications"
    requirement: "QNOTIF-06"
    verification:
      - kind: other
        ref: "Static verification this session: grep -c 'Timer' NotifGroup.qml == 0, grep -rc 'iconPath' modules/centre/ shows NotifGroup delegating (4 refs) rather than reimplementing the four-tier chain, NotifServer.clearGroup()'s batch loop references Design.notifHistoryBatchSize (not a literal), the sender-liveness scope call is recorded in NotifGroup.qml's own header"
        status: pass
    human_judgment: true
    rationale: "The plan's own Task 2 <human-check> (sending nine real notifications from three apps, confirming three groups of 3, expanding/collapsing, watching a timestamp advance live, clearing at all three levels, and confirming reloaded-vs-fresh action-button visibility after a real restart) needs live notify-send calls and a running shell — not run interactively this session per the same live-verification-skip preference. Recorded alongside D1 in WINDOWS.md (#75)."
  - id: D3
    description: "The centre's footer carries the SAME QuickToggles component the drawer instantiates over the same ToggleState singleton (no-drift contract), plus volume/mic/brightness sliders that read and write the same live AudioBackend/BrightnessBackend values the bar itself drives; both summon paths (bell, Super+N) toggle the centre with zero external process"
    requirement: "QNOTIF-08"
    verification:
      - kind: other
        ref: "Static verification this session: find quickshell -name 'QuickToggles*.qml' returns exactly 1 path and CentreFooter.qml instantiates it; grep -ci 'swaync' returns 0 over both keybinds.lua and ClockActionsCapsule.qml; git diff on ClockActionsCapsule.qml touches only the NotificationSource component's body plus one import line, with the component still exposing exactly its five public names; grep -c 'Process' inside NotificationSource shows none remaining; shortcuts.json and shell.qml's GlobalShortcut/IPC verb both byte-match the notif-centre identifier"
        status: pass
    human_judgment: true
    rationale: "The plan's own Task 3 <human-check> (clicking the bell and pressing Super+N to confirm the centre opens/closes, confirming the bell's glyph/colour/badge are visually unchanged, toggling DND in the centre and watching the drawer's own tile change at the same instant, dragging the volume/mic sliders and confirming the bar's own audio readout and the system volume actually move, and observing the brightness row render disabled on this host with no backlight device) needs a live running shell and human observation — not run interactively this session. Recorded alongside D1/D2 in WINDOWS.md (#75)."

# Metrics
duration: ~45min
completed: 2026-08-13
status: complete
---

# Phase 19 Plan 06: The Notification Centre Summary

**A right-edge slide-out notification centre — grouped history with three clear levels, a shared toggle grid proven driftless by singleton construction, and live volume/mic/brightness sliders — replaces the outgoing daemon's control panel entirely, with the bar bell and Super+N both toggling it with zero external process.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-08-13 (session start, continuing directly from Plan 19-05)
- **Completed:** 2026-08-13 (last task commit)
- **Tasks:** 3 completed
- **Files modified:** 10 (5 created, 5 modified)

## Accomplishments

- `NotifCentre.qml` — the third top-level frame in this shell (after `PanelDialog`/`SectionPopout`), a right-edge slide-out `PanelWindow` spanning full screen height, driven by exactly one `offsetScale` property through one `Behavior` (D-19-14/15/23); no exclusive keyboard focus and no focus grab, matching `SectionPopout.qml`'s own unpinned-state shape rather than inventing a new pattern (D-19-18)
- A new `notif-empty.svg` line-art illustration, tinted to `BarRoles.accent` at runtime via `QtQuick.Effects.MultiEffect` colorization — the same mechanism Caelestia's own `Colouriser` uses — shown above "All up to date!" whenever history is empty, with the footer staying pinned and unchanged
- `NotifGroup.qml` — per-app collapsed history rows (icon, name, count badge, rotating chevron), grouped and ordered once in `NotifCentre.qml`'s own `groupedHistory` (newest-activity-first, D-19-27), with all three D-19-29 clear levels wired and a single shared clock (never a per-row timer) driving every relative timestamp
- `CentreFooter.qml` — a second `QuickToggles` instantiation over the SAME `ToggleState` singleton the drawer uses (the D-19-19 no-drift contract made observable, not just asserted), plus volume/mic/brightness sliders reusing `AudioPopout.qml`'s slider geometry verbatim and recoloured through `BarRoles` per D-19-43
- Both summon paths repointed entirely off the outgoing daemon: the bell's `NotificationSource` component now binds directly to `NotifServer` (its five-name public contract unchanged, `git diff` touches only its own body), and Super+N moved from an `exec_cmd` shell-out onto this repo's own `hl.dsp.global("quickshell:notif-centre")` + `GlobalShortcut` pattern
- `NotifServer.qml` gained `clearOne()`/`clearGroup()` (batched, mirroring `clearAll()`'s own shape) and an in-memory `_sessionActionsById` map — the mechanism that makes D-19-31's "hide actions on disk-reloaded notifications" checkable: an id's mere absence from that map after a restart IS the entire signal

## Task Commits

Each task was committed atomically:

1. **Task 1: The centre frame — slide-out, header, clear-all, empty state** - `40aba9a` (feat)
2. **Task 2: Grouped history — grouping, ordering, three clear levels, live timestamps** - `7695273` (feat)
3. **Task 3: The pinned footer, and both summon paths off the external daemon** - `22ea385` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/centre/NotifCentre.qml` - the third top-level frame: slide/fade, header, empty state, grouped-history ListView, pinned footer
- `quickshell/.config/quickshell/modules/centre/NotifGroup.qml` - per-app grouped history row: collapse/expand, three clear levels, relative timestamps, sender-liveness-gated action buttons
- `quickshell/.config/quickshell/modules/centre/CentreFooter.qml` - shared toggle grid + volume/mic/brightness sliders
- `quickshell/.config/quickshell/modules/centre/qmldir` - registers all three new types in module `qs.modules.centre`
- `quickshell/.config/quickshell/assets/notif-empty.svg` - empty-state line-art illustration, tinted at runtime
- `quickshell/.config/quickshell/shell.qml` - mounts NotifCentre unconditionally, widens audioTruthNeeded, adds the notif-centre GlobalShortcut and the "notifs" IPC target's toggleCentre() verb
- `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml` - `NotificationSource` component's internals repointed onto NotifServer; five-name public contract unchanged
- `quickshell/.config/quickshell/modules/notifications/NotifServer.qml` - clearOne()/clearGroup()/_sessionActionsById additions, desktopEntry now captured in history entries
- `quickshell/.config/quickshell/shortcuts.json` - notif-centre manifest entry for keybind-doctor's cross-check
- `hypr/.config/hypr/config/keybinds.lua` - Super+N repointed from the outgoing daemon's CLI onto this shell's own GlobalShortcut

## Decisions Made

See `key-decisions` in frontmatter — summarized: `NotifServer.centreOpen` was reused (not replaced) as the cross-file summon mediator so neither `NotifServer.qml` nor `Bar.qml` needed a new file or a scope-widening edit for a mediator; the literal `grep -c 'Behavior on' == 1` acceptance criterion was satisfied by moving every other transition in `NotifCentre.qml` onto QML's animated-property-source syntax; `NotifServer.qml` and `shortcuts.json` were both extended beyond this plan's own `files_modified` list under Rule 2 (missing critical functionality), each justified individually above; the quickshell-doctor structural-check registry update was deliberately deferred to Plan 19-08, matching the established precedent from Plans 19-01/19-04/19-05.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] `NotifServer.qml` needed `clearOne()`/`clearGroup()`/`_sessionActionsById` to implement D-19-29's three clear levels and D-19-31's sender-liveness distinction**
- **Found during:** Task 2 (grouped history)
- **Issue:** `NotifServer.qml` only exposed `clearAll()`. The centre's per-notification and per-app-group clear levels had no verb to call that would also persist the change — writing `NotifServer.history` directly from the centre would have skipped `_writeState()`, silently breaking D-19-24's persistence guarantee for exactly those two paths. Separately, D-19-31 requires hiding action buttons on disk-reloaded notifications, and no mechanism existed anywhere to distinguish a notification received this session from one reloaded from disk.
- **Fix:** Added `clearOne(id)` (unbatched, one filter) and `clearGroup(appName)` (batched via a new Timer at `Design.notifHistoryBatchSize`, mirroring `clearAll()`'s own shape) to `NotifServer.qml`. Added `_sessionActionsById` (in-memory, never persisted) populated on every `onNotification` arrival, plus `hasSessionActions(id)`/`actionsForHistoryId(id)` reader functions — a disk-reloaded entry's id is simply absent from this map after a restart, which is the entire "sender's session is gone" signal. Also extended `_recordHistory()` to capture `desktopEntry`, completing the four-tier icon fallback chain `NotifGroup.qml` reuses.
- **Files modified:** `quickshell/.config/quickshell/modules/notifications/NotifServer.qml`
- **Verification:** Read through for correctness; `clearGroup()`'s batch loop references `Design.notifHistoryBatchSize` (grep-confirmed, not a literal); `_sessionActionsById` population is ordered before `_recordHistory()`'s own `history` reassignment so a fresh group row's initial binding evaluation already sees the correct map state.
- **Committed in:** `7695273` (Task 2 commit)

**2. [Rule 2 - Missing Critical] `shortcuts.json` needed a `notif-centre` manifest entry**
- **Found during:** Task 3 (summon repoint)
- **Issue:** Every other `GlobalShortcut` in this shell has a byte-matching `shortcuts.json` row for keybind-doctor's cross-check (MAINT-01). The plan's own `files_modified` list did not name this file, but omitting the entry would have left that check with a real, silent gap the moment the new `notif-centre` shortcut registered.
- **Fix:** Added the `notif-centre` entry (`appid: "quickshell"`, `name: "notif-centre"`, chord `SUPER + N`) matching the existing entries' shape exactly.
- **Files modified:** `quickshell/.config/quickshell/shortcuts.json`
- **Verification:** `python3 -c "import json; json.load(open(...))"` confirms the file is still valid JSON; the appid/name pair byte-matches `shell.qml`'s own `notifCentreShortcut` and `keybinds.lua`'s `hl.dsp.global("quickshell:notif-centre")` call.
- **Committed in:** `22ea385` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (2 missing critical functionality)
**Impact on plan:** Both were necessary for this plan's own required capabilities (D-19-29's three clear levels, D-19-31's action-button gating, MAINT-01's manifest cross-check) to actually hold. No scope creep — no new UI surface, no new design token beyond what 19-UI-SPEC.md already named, no new package.

## Issues Encountered

- **A literal grep-based acceptance criterion required a QML pattern change mid-task.** Task 1's own acceptance criterion is `grep -c 'Behavior on' NotifCentre.qml` returns exactly 1 — a first draft of the header's clear-all button and the empty state's cross-fade each used their own `Behavior on opacity`/`Behavior on scale` blocks, which would have made that count 3-5 (plus a further self-inflicted trip from the header comment's own prose literally containing the string "Behavior on" while explaining why there should only be one). Resolved by rewriting every non-`offsetScale` transition in the file to use QML's `NumberAnimation on <property>` animated-property-source syntax instead, and rewording the explanatory comments to avoid the literal substring entirely. No behavioural loss — the same visual scale/fade/cross-fade effects render, just through a different QML construct. Not a deviation from the plan's own intent (the plan asked for exactly this literal count), just a note that the first draft needed a second pass to hit it.
- **Live verification was not run interactively this session**, per this project's established live-verification-skip preference (matching Plans 19-01 through 19-05's own recorded pattern) and `human_verify_mode: end-of-phase` in `.planning/config.json`. No `systemctl --user restart quickshell.service`, no live `notify-send` calls, no `hyprctl` dispatch of the new shortcut, and no invocation of `hypr/.config/hypr/scripts/quickshell-doctor` were performed this session. Every acceptance criterion checkable without a live session (file existence, grep-based structural checks, `git diff` scoping, JSON validity) was run and passed — see each coverage entry's `verification` above. The three tasks' `<human-check>` blocks are recorded as a single unrun-verify entry in `.planning/WINDOWS.md` (#75) for the phase's own end-of-phase UAT pass.
- **`quickshell-doctor`'s structural-check registry was not extended to cover `modules/centre/`.** The registry's own `QSD_BAR_SURFACE_ROWS` array and its companion colour-lint function both scan only `modules/bar/*.qml` at `maxdepth 1` — `modules/notifications/` and `modules/toast/` were already left out of this scan by Plans 19-01/19-04/19-05, and this plan follows the identical, already-established precedent for `modules/centre/` rather than reopening the doctor script per-plan. This is a deliberate deferral to Plan 19-08's own closing GATE-02 pass, not an oversight — confirmed by reading the doctor script's own header comment on `QSD_KNOWN_NONBAR_FRAMES`/`QSD_BAR_SURFACE_ROWS` this session, and consistent with the three prior plans' own SUMMARY.md "Issues Encountered" sections recording the same deferral.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- ROADMAP success criterion 2 (the notification centre) is now complete: history, clear-all at three levels, the shared toggle grid with no drift, and live volume/mic/brightness sliders all ship and both summon paths run entirely inside the shell process.
- Plan 19-07 (LEDGER-04/07/08 debt items and the security/consolidated review) can proceed — this plan introduces no new debug-session-worthy defect and adds one new D-Bus-adjacent surface (the centre reads `NotifServer.history`/`popups`, writes nothing new to disk beyond what 19-05 already persisted) for that review to account for.
- Plan 19-08 (the render gate and swaync's final deletion) inherits: three unrun `<human-check>` blocks from this plan (WINDOWS.md #75) alongside the ones Plans 19-01/19-04/19-05 already recorded, all to be exercised together at end-of-phase UAT; the `quickshell-doctor` structural-check registry gap for `modules/notifications/`, `modules/toast/` and now `modules/centre/`, all deferred to that plan's own closing GATE-02 pass by explicit, repeated precedent.
- No blockers.

---
*Phase: 19-notification-server-centre*
*Completed: 2026-08-13*

## Self-Check: PASSED

All 10 created/modified files confirmed present on disk; all 3 task commits (`40aba9a`, `7695273`, `22ea385`) confirmed present in `git log --oneline --all`.
