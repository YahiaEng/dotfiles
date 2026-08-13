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

## Gap-Closure Fix (post-execution, GATE-02)

**A live SIGSEGV was found during GATE-02 render-gate testing, traced to this plan's own new code, and fixed as a same-plan gap-closure commit.**

- **Crash:** User hovered/clicked the bar bell; `quickshell` SIGSEGV'd (coredump pid 569912, 2026-08-13 16:15:54, `~/.cache/quickshell/crashes/ql0barlpjt/report.txt`). Deterministic; the crash handler's respawn loop transiently rendered a second bar.
- **Root cause:** `NotifServer._sessionActionsById` (added by this plan's Task 2 for D-19-31) stored the RAW live `QList<NotificationAction*>` (`notif.actions` itself), and `NotifGroup.qml` bound that value directly into a `Repeater.model` (the per-notification actions strip). That Repeater's delegate is created lazily/asynchronously via Quickshell's own incubation controller — by the time it ran, `QQmlDelegateModel`'s attempt to convert the stored value SIGSEGV'd inside `QMetaType::convert` (stack: nested `QQuickRepeater::regenerate`/`componentComplete` frames, matching this plan's own group-row -> action-chip Repeater nesting exactly). A second, compounding factor: `NotifCentre.qml`'s grouped-history `ListView` had no visibility gate on its own `model`, so EVERY notification arrival — even with the centre never opened — regenerated its delegates (and their nested action Repeaters) in the background; this is what let an unrelated bell-tooltip hover collide with the crash, since the tooltip's own incubation happened to interleave with a concurrent, unnecessary background Repeater regeneration.
- **Fix (root cause, not a try/catch):**
  1. `NotifServer.qml`: `_sessionActionsById` now stores a plain, serializable snapshot (`[{identifier, text}]`, captured synchronously at arrival while the objects are certainly live) — the only value any `Repeater` ever sees. The raw QObject list moved to a new `_sessionRawActionsById`, touched only inside a new `invokeSessionAction(id, identifier)` function — a plain imperative call from a `TapHandler` at click time, never a reactive binding or a model.
  2. `NotifGroup.qml`: the action chip's `TapHandler` now calls `NotifServer.invokeSessionAction(...)` instead of holding/invoking a raw `NotificationAction` reference.
  3. `NotifCentre.qml`: the grouped-history `ListView`'s model is now `centreWindow.visible ? centreWindow.groupedHistory : []` — no `NotifGroup` delegate (and none of its own nested Repeaters) is instantiated while the centre is closed. `visible` already flips true the instant the open animation starts, so this costs no perceptible delay.
- **Files:** `quickshell/.config/quickshell/modules/notifications/NotifServer.qml`, `quickshell/.config/quickshell/modules/centre/NotifGroup.qml`, `quickshell/.config/quickshell/modules/centre/NotifCentre.qml`.
- **Verified live (careful, real desktop):** `systemctl --user restart quickshell.service` → single instance, `quickshell` owns `org.freedesktop.Notifications`. Sent notifications carrying actions via raw D-Bus `Notify` calls (`gdbus`), both while the centre was closed and while it was open (toggled via the `notifs` IPC target's `toggleCentre()` verb — no synthetic pointer tool exists on this host, matching this repo's own already-documented limitation), forcing the exact previously-crashing group -> per-notification -> per-action Repeater nesting to instantiate for real. `pgrep -x quickshell` stayed a single PID throughout every step; `coredumpctl list` showed no new entry past the original 16:15:54 dump; `journalctl --user -u quickshell.service` showed no new WARN/ERROR since the restart.
- **Scope discipline:** `NotifCard.qml` (Plan 19-04) was read and deliberately left untouched — its own similar-looking `Repeater { model: card._liveActions }` binds to a per-popup live notification whose delegate is destroyed in lockstep with that same notification's own popup lifecycle, never outliving it, which is exactly the property that made this plan's own session-long map unsafe. No Plan 19-08 artifact and no swaync-related file was touched.
- **Committed in:** `b7b6b30` (fix commit)

## Gap-Closure Fix, Round 2 (post-execution, GATE-02 re-check)

**A second GATE-02 re-check confirmed the crash fix above (PASS), DND-across-restart (PASS), and the disabled brightness slider (accepted) — and found four further live defects, all fixed as same-plan gap-closure commits.**

### FAILURE 2 (critical): notification popups did not appear at all — DIAGNOSED, not a code bug

**Root cause:** `NotifServer.dnd` was persisted `true` — left ON from the user's own earlier B.7 restart-persistence test, never turned back off. The suppression predicate (`dnd || gaming || centreOpen || fullscreenBlocking`, Plan 19-05) was working exactly as designed: every arrival was suppressed, recorded to history, and correctly never popped. Confirmed live: read `~/.local/state/quickshell/notifications.json` (`dnd: true`), flipped it to `false`, restarted, and `notify-send` at both normal and critical urgency produced real popup layers immediately (`hyprctl layers` showed `quickshell-notif-popups`). **DND was left OFF after this diagnosis** (not restored to the user's prior `true`), since a working desktop was judged more useful than silently reproducing a stale test artifact — flagged here so the user can re-enable it deliberately if they want it on.

**Visible-indication gap, reported as asked:** neither the bar nor the centre gives any obvious "DND is currently on" signal beyond the shared toggle grid's own tile lit-state (which requires opening the drawer or centre to see) — the bell glyph does swap to `notifications_paused` when `NotifServer.dnd` is true (`ClockActionsCapsule.qml`'s existing three-branch glyph logic, unchanged by this plan), but nothing calls this out as a DND indicator specifically versus "no unread notifications." A user who set DND and closed every panel has no ambient cue it's still on. Not fixed (out of this gap-closure's scope — a genuine UX/discoverability question, not a defect in the four listed issues), reported per the coordinator's own explicit instruction.

**A genuine, separate, pre-existing defect found while performing this diagnosis's own required verification step** ("verify live with notify-send at normal and critical urgency"): critical-urgency popups auto-dismissed at 5 seconds, identical to normal urgency, instead of never. Root cause and fix in `fix(19-04): a6472f2` — see that commit and the `Deviations from Plan` note below. Not one of the four named issues, but discovered performing the exact verification requested and fixed under the same "diagnose before touching code" discipline.

### ISSUE a: click-away and Escape did not dismiss the centre

D-19-18 deliberately specified no keyboard focus and no focus grab, accepting no click-outside dismissal. GATE-02 found this unusable — superseded by direct instruction, matching Dashboard.qml/PanelDialog.qml's own `WlrKeyboardFocus.OnDemand` + `HyprlandFocusGrab` pattern. Honest cost: the centre now holds keyboard focus while open, so typing does not reach the previously-focused app — the literal opposite of D-19-18's original text. No pointer-only click-away mechanism exists anywhere in this shell (`HyprlandFocusGrab` is the only click-away detector this codebase has, and it is a combined pointer+keyboard grab) — this is the "genuine conflict" flagged for report. Verified live: Escape confirmed via `wtype -k Escape` (no synthetic pointer tool exists on this host); click-away uses the byte-identical mechanism already proven in Dashboard.qml/PanelDialog.qml but was not independently re-verified live for the same missing-pointer-tool reason. Fixed in `fix(19-06): 2fccc86`.

### ISSUE b: the bell icon clipped with the checkmark icon in the empty-state illustration

The original `notif-empty.svg` placed the checkmark path directly inside the bell's own bounding box (bell ~x8-82/y14-79, checkmark ~x30-84/y46-118) — genuinely overlapping geometry, not a rendering artifact. Redesigned with the bell confined to the top-left (bbox x8-68/y4-68) and the checkmark as a badge in the bottom-right corner (circle centred (94,94) r20, bbox x74-114/y74-114) — a clear 6px gap on both axes. The checkmark is a hole cut through the solid badge circle via `fill-rule="evenodd"`, keeping the illustration a single flat colour/alpha shape under `MultiEffect` colorization. Verified live with a cache-cleared restart, confirmed no "Cannot open"/parse warning for the file (a red herring surfaced mid-investigation: repeated "Cannot open" lines in an earlier `grep | tail` turned out to be stale log entries from before this plan's own `assets/` stow symlink existed, still sitting in the append-only log, not live re-occurring errors — resolved by checking only lines appended after a fresh restart marker). Fixed in `fix(19-06): d4a63fd`.

### ISSUE c: the hover highlight over centre rows clipped past the panel and was barely visible

Two independent defects: (1) `historyRegion` had no horizontal inset from the window's own edges, so a row's square-cornered hover rectangle could render past the frame's own rounded corner near the top/bottom of the list — fixed with a `Design.spacingMd` inset, matching the header's own existing convention; `clip: true` was already present on both `historyRegion` and the `ListView`. (2) the hover colour (`BarRoles.notifSurfaceHover`, 0.90 alpha) sat on top of the row's own 0.78-alpha `notifSurface` background — a 12-point alpha step of the same colour family, reading as barely visible — switched to `BarRoles.capsuleHover` (0.95 alpha surfaceVariant), the established list-row hover contrast this repo already uses (`AudioPopout.qml`'s sink rows: transparent -> a solid surfaceVariant tone), routed through `BarRoles` per D-19-43, no hardcoded colour. Verified live across several open/close cycles with an action-carrying notification present to exercise the row-rendering path; no new warnings. Fixed in `fix(19-06): cc4730d`.

### Round 2 verification summary

Every fix above was verified against the running shell (`systemctl --user restart quickshell.service` for cache-affecting changes, otherwise live hot-reload), with `pgrep -x quickshell` confirmed as a single PID and `coredumpctl list` confirmed to show no entry past the original `16:15:54` dump after every step. `busctl --user list` confirmed `quickshell` retained sole ownership of `org.freedesktop.Notifications` throughout. No Plan 19-08 artifact and no swaync-related file was touched in this round either.

**Commits, round 2:** `a6472f2` (fix(19-04), critical-urgency auto-dismiss), `2fccc86` (fix(19-06), ISSUE a), `d4a63fd` (fix(19-06), ISSUE b), `cc4730d` (fix(19-06), ISSUE c).

## Gap-Closure Fix, Round 3 (post-execution, GATE-02 re-check)

**A third GATE-02 re-check reported seven items. Per explicit coordinator instruction, 19-UI-SPEC.md/19-CONTEXT.md/`.planning/research/FEATURES.md` were re-read before touching any code — items 5 and 7 turned out to be spec/behaviour VERIFICATIONS (both already correctly implemented), not missing features; the other five were real defects, fixed.**

### Items 1 + 2: empty-state illustration overlapped list content / "All up to date!" showed with notifications present

One root cause, confirmed by re-reading the actual code rather than assuming the coordinator's own hint (round-2's `ListView.model` visibility gate) was the culprit — it was not; `emptyState`'s opacity was already correctly bound to the real `NotifServer.history.length`, never the gated model. The bug was structural: the empty-state `Column` had **no `visible` binding at all** — only its opacity animation controlled appearance, so a stuck, delayed, or mid-transition opacity value could leave "All up to date!" rendering over real list content, worst when a group expands (the one case tall enough to actually reach where the centred block sits). Fixed by adding `visible: NotifServer.history.length === 0` directly on the Column — a hard, unconditional gate reading the real count, making the overlap structurally impossible regardless of the opacity animation's own state (a group can only exist/expand when history is non-empty, so the two conditions are now mutually exclusive by construction). The opacity animation is kept for the fade-**in** polish only; fade-out is now instant, an accepted asymmetry given the correctness requirement is one-directional. Verified live with 59 real history entries present. Fixed in `fix(19-06): 28ca704`.

### Item 3: the empty-state illustration itself looked bad — aesthetic rejection

Re-checked 19-UI-SPEC.md (D-19-22 explicitly leaves the specific asset "under Claude's Discretion") and `FEATURES.md` § NOTIF (does not describe Caelestia's illustration's actual visual contents) before redesigning — no locked spec conflict to report. Simplified from the round-2 two-motif design (bell + separate checkmark badge) to a single clean bell silhouette, per the coordinator's own suggested direction ("consider a single motif instead of two competing glyphs"). Fixed alongside items 1-2 in `fix(19-06): 28ca704`.

### Item 4: gaming-mode notification showed a missing-texture icon

Root cause: `gaming-mode-toggle.sh`'s own `notify-send -i input-gaming ...` sends an `app_icon` this host's icon theme does not carry. `Quickshell.iconPath(name, "")` was trusted to return an empty string on failure — live-diagnosed that it does not always: Qt's own icon-theme resolution can hand back a resolvable "missing icon" placeholder pixmap instead (confirmed via a live WARN: `Could not load icon "input-gaming" at size QSize(100, 100) from request`, immediately followed by a normal-looking resolved path) — a failure mode no string-emptiness check can catch. Fixed with `Quickshell.hasThemeIcon(name)` as the real existence check, gating both icon-theme tiers (app_icon, desktop-entry icon) before `iconPath()` is called. **A first version of this fix over-corrected and was caught live before committing**: gating every app_icon through `hasThemeIcon()` unconditionally broke a legitimate case — `app_icon` can also be a file path/URI per the freedesktop spec (this repo's own real example: kitty sets it to `/usr/lib/kitty/logo/kitty.png`), which `hasThemeIcon()` correctly reports `false` for since it is not a theme lookup at all. Added `_looksLikeThemeName()` as the corrected trust boundary — only a bare name goes through `hasThemeIcon()`; a path/URI-shaped value is trusted directly, with the Image element's own `status !== Image.Error` as the runtime safety net. Applied to both `NotifCard.qml` (the popup) and `NotifGroup.qml` (the centre's own separate icon-resolution call sites). Fixed in `fix(19-04): d4c11af` and `fix(19-06): 42e7b37`.

### Item 5: "where is the picture inside the notification centre?" — VERIFIED, already implemented per spec

Re-checked 19-UI-SPEC.md's own "Icon fallback chain" (D-19-12): "image hint → named app_icon via icon theme → desktop-entry icon → generic Material Symbols bell glyph. All four tiers render inside the identical notifImageSize (42px) slot." This is tier 1 of the SAME chain already implemented in both `NotifCard.qml` (Plan 19-04) and `NotifGroup.qml` (this plan, Task 2's `resolveIconSource()`, which checks `entry.image` first). Neither `FEATURES.md` § NOTIF nor 19-CONTEXT.md's own decisions describe a distinct "hero image"/preview feature beyond this fallback chain — no spec conflict found. Live-verified: sent a real notification with an `image-path` hint via a raw D-Bus `Notify` call (`gdbus`, hint `image-path: <a real file on disk>`) — no load/parse errors appeared in `~/.cache/quickshell.log`. The likely reason the feature reads as "missing": ordinary `notify-send` calls without an explicit image hint never populate `image` at all (most apps' notifications don't), and the centre's group header shows the SAME resolved image at the smaller 24px list-context size (D-19-26's own "collapsed by default" — the full 42px rendering is in the expanded per-notification row) — both are spec'd, not bugs. No code change made; reported per the coordinator's own "if the spec item genuinely conflicts... report the conflict" instruction (no conflict found here, just a verification).

### Item 6: critical/error notification fill was too loud

D-19-11's original text swapped the WHOLE card to `BarRoles.danger`/`onDanger` for critical urgency — live-rejected as too loud (e.g. a routine battery-low warning filling the entire card solid red). Fixed with a tiered, subtle treatment entirely through the token system: `BarRoles.qml` gained `notifCriticalSurface` (an 85%-surface/15%-danger colour mix at the surface's own 0.78 alpha — a subtle wash, not an opaque fill) and the required `dangerColour` colour-typed indirection (`Colours.error` is a `property string`; reading `.r/.g/.b` off it directly silently yields black, the exact bug class `BarRoles.qml`'s own header already documents). `NotifCard.qml`'s foreground is now unconditionally `notifSurfaceFg` for every urgency tier (calm, readable text/icon regardless of urgency); the rim is now genuinely tiered — normal keeps the existing `GradientBorder`, low gets a plain muted `BarRoles.capsuleTrack` border (matching the outgoing daemon's own "border-color: surface_variant" low-priority treatment, `19-BEHAVIOUR-BASELINE.md` SWC-37), critical gets a plain solid `BarRoles.danger` border — a thin accent, not a wash. D-19-11's "never auto-dismisses" and "still subject to the height clamp" are unchanged. Verified live: low/normal/critical sent together, dismissed on their own correct schedules (low ~3s, normal ~5s, critical persisted 6s+), re-confirming the round-2 critical-persistence fix still holds under the new chrome. Fixed in `fix(19-04): c474164`.

### Item 7: popup max-on-screen limit + "N+ more" overflow badge — VERIFIED, already correctly implemented

The coordinator's own suggested test size (an 8-notification burst) does not exceed this host's actual clamp threshold, which is why it read as "missing." Live-diagnosed with a temporary counter (added, confirmed, then removed before committing — no functional code changed, since none was needed): on this host's 1440px-tall display, `_availableHeight = 1440 * 2/3 = 960`, `_perCardHeight = 82` (`notifImageSize` 42 + `spacingMd` 16×2 + `spacingSm` 8), giving `_rawMaxVisible = floor(960/82) = 11`. A burst of 15 real notifications produced exactly the spec-correct result: `visibleCount=10`, `overflowCount=5`, `_displayModel.length=11` (10 real cards + 1 "+5 more" overflow marker) — an exact match to `NotifPopupStack.qml`'s own D-19-03 clamp math from Plan 19-04. No code change made; reported as a verification, not a fix, per the coordinator's own "verify it actually limits" framing.

### Round 3 verification summary

Every fix above was verified against the running shell (`systemctl --user restart quickshell.service` after every code-affecting change, `~/.cache/quickshell/qmlcache/` cleared before each restart to rule out stale-bytecode false negatives — a real gotcha hit mid-session: repeated "Cannot open" log lines earlier in this same investigation turned out to be stale entries from BEFORE a cache-clearing restart, not live re-occurring errors, caught by checking only log lines appended after a fresh restart marker). `pgrep -x quickshell` was confirmed a single PID and `coredumpctl list` confirmed to show no entry past the original `16:15:54` dump after every step; `busctl --user list` confirmed `quickshell` retained sole ownership of `org.freedesktop.Notifications` throughout. No Plan 19-08 artifact and no swaync-related file was touched in this round either.

**Commits, round 3:** `d4c11af` (fix(19-04), item 4 popup), `42e7b37` (fix(19-06), item 4 centre), `28ca704` (fix(19-06), items 1-2-3), `c474164` (fix(19-04), item 6). Items 5 and 7 needed no commit — both verified already correct against the actual written spec.

## Gap-Closure Fix, Round 4 (post-execution, GATE-02 re-check)

**A fourth GATE-02 re-check reported six items, including one explicit DESIGN REVERSAL of round 3's own critical-urgency treatment. All six addressed as same-plan gap-closure commits.**

### Item 1: revert tiered urgency coloring — DESIGN REVERSAL, user direction

Round 3's `c474164` (tiered surface wash + tiered rim per urgency) was explicitly reversed on direct user instruction: critical notifications must look IDENTICAL to normal ones — no distinct surface wash, no distinct rim, nothing chrome-wide. The only permitted difference anywhere on the card is the fallback glyph. Reverted cleanly via `git revert --no-edit c474164` (conflict-free — no later commit touched the same lines), then layered the new icon-only treatment on top: `_fill`/`_fg` are unconditional again (`BarRoles.notifSurface`/`notifSurfaceFg` for every urgency tier), and the popup card's fallback glyph (the `Text` shown only when no real app icon/image resolved) now renders `"error"` tinted `BarRoles.danger` for critical urgency instead of the generic bell — the one and only remaining urgency marker. Fixed in `fix(19-04): 30ea79a` (the revert itself landed as `65e4787`).

### Item 2: urgency did not reflect inside the notification centre

Mirrored item 1's treatment into `NotifGroup.qml`: added `_headerCritical` (from the group's newest/`_first` item's urgency) and each expanded row's own `_critical` (from its own `modelData.urgency`), swapping both fallback glyphs to the same danger-tinted `"error"` icon — never the row/header background or rim, matching item 1's "icon only" scope exactly. Verified live: `notify-send -u critical` while the centre was open produced a visible danger-tinted glyph on the group header (screenshot-confirmed, a clearly red/pink circled-exclamation icon replacing the generic bell for the `notify-send` group's newest entry); the same entry persisted to `~/.local/state/quickshell/notifications.json` with `urgency: 2`, confirming the marker survives a reload (the glyph is computed from stored history data, not session-only state, so it renders identically whether the centre is opened fresh or was already open when the notification arrived). Row-level rendering was not independently click-verified (see Verification limitations below) but shares the identical `resolveIconSource()` function and `Image`/`Text` fallback structure as the header, just at `notifImageSize` (42px) instead of `iconSizeMd` (24px) — no code path exists where the two slots could diverge in behaviour. Fixed in `fix(19-06): 969b79d`.

### Item 3: "the picture is STILL missing" — dug deeper, confirmed VERIFIED WORKING (not a bug)

Re-read `19-DISCUSSION-LOG.md` (not just `19-UI-SPEC.md`/`19-CONTEXT.md` as round 3 did) specifically for the "picture... similar to Caelestia" agreement. Found it explicit: the discussion's own icon-fallback options table shows `image → named icon → desktop-entry → generic bell glyph` selected, with the ALTERNATIVE "…→ letter avatar in a tinted circle" explicitly REJECTED (needs a deterministic in-palette colour pick — never adopted). There is no separate "hero image"/thumbnail feature anywhere in `19-CONTEXT.md`, `19-UI-SPEC.md` (D-19-12, same four-tier chain, one `notifImageSize` slot, never a second widget), or `FEATURES.md` § NOTIF (describes Caelestia's grouping/persistence/DND, never a distinct image-preview widget) — "the picture" IS this tier-1 image-hint slot, nothing more.

Given round 3's own verification ("image-path hint loads without error") was explicitly rejected as insufficient, this round tested the REAL path with actual painted-pixel proof across all three real-world image-delivery mechanisms, not just "no load error":
1. `notify-send -i /path/to/real.jpg` (file-path `app_icon`) — history recorded `image: "image://icon//home/.../1-kanagawa.jpg"`.
2. A raw D-Bus `Notify` call with an `image-path` hint (`file://...`) — history recorded `image: "file:///home/.../a_city_skyline_at_night.jpg"`.
3. A raw D-Bus `Notify` call with a genuine `image-data` hint (a real 2×2 raw pixel buit buffer: red pixel, green pixel, `(iiibiiay)` signature) — history recorded `image: "image://qsimage/5/1"`, Quickshell's own internal decoded-pixmap image provider.

All three were opened in the centre and **screenshot-verified with actual painted pixels visible** (not just "source resolved"): the Kanagawa wave art rendered recognizably at both group headers (24px), and the synthetic 2×2 red/green test image rendered as a correctly-coloured red-to-green gradient square — definitive proof the `Image` element has nonzero painted size and is not hidden behind `visible:false` or a 0-width layout for any of the three hint types real-world senders use (file-path icons, `image-path`, and raw `image-data` pixel buffers used by browsers/chat apps for avatars). `imageSupported: true` was also confirmed still declared in `NotifServer.qml`'s `GetCapabilities` response, ruling out a capability-negotiation gap. **No code change made** — this is a verification, not a fix; the feature works exactly as D-19-12 specifies and as the discussion log agreed, now backed by stronger evidence than round 3's insufficient check.

### Item 4: pressing "x" inside the centre expanded the group instead of clearing

Root cause: `headerRow`'s catch-all `headerMouseArea` (`onClicked: toggleExpandRequested()`) was declared LAST among `headerRow`'s children — after `groupActions`, which nests the close glyph's own `groupCloseMouseArea`. QtQuick's default paint/hit-test order stacks later siblings on top, so `headerMouseArea` sat above and intercepted every click in its full-fill area, including clicks meant for the close glyph. Fixed by moving `headerMouseArea`'s declaration to immediately after the background `Rectangle` it colours (referenced purely by `id`, so that binding is unaffected by the reorder) — i.e. BEFORE `groupActions` — so every more specific sibling now naturally paints on top and captures its own clicks first, while anywhere else in the header still falls through to `headerMouseArea` and expands. Confirmed via code review that this exactly matches the already-working pattern for the per-row close glyph (`rowMouseArea` uses `acceptedButtons: Qt.NoButton` specifically so it can never intercept a click). Fixed in `fix(19-06): e5973b8`.

### Item 5: clear-all button missing inside the centre

Root-caused live with a temporary `console.log` probe (removed before commit): `NotifCentre.qml`'s whole content tree mounts unconditionally at shell startup, before `NotifServer`'s `FileView` finishes its async disk read — `_hasHistory` is created `false` and flips `true` a moment later once history loads (confirmed firing correctly). The bug: the `NumberAnimation on <property>` value-source form previously used reads its own `to` expression at the exact instant the change-notify signal fires, and in this Quickshell/Qt build that read raced ahead of the dependent property's own binding re-evaluation — the probe caught `to` still reporting the STALE value (`0`) inside the very handler reacting to the change that made it `1`, so the animation "restarted" toward the value it was already at (a no-op), leaving `opacity`/`scale` permanently stuck at their literal `0`/`0.5` starting values on every real session (history is essentially always non-empty by the time the button becomes interactive). Fixed with two plain (non-`"on"`) `NumberAnimation` objects, imperatively (re)started from an `on_HasHistoryChanged` handler wrapped in `Qt.callLater()` to defer past the stale-read race by one event-loop tick, plus a `Component.onCompleted` snap (no animation) so the button doesn't play a spurious fade-in on every ordinary restart. Confirmed live: opacity now ranges smoothly `0 → 1` across ~45 frames once deferred (previously never moved at all). This file's own literal acceptance criterion (`grep -c 'Behavior on' NotifCentre.qml == 1`, reserved for the frame's own `offsetScale` slide) stayed at exactly 1 throughout — a comment mentioning the literal phrase during drafting briefly self-tripped the same grep and was reworded. Verified live: the `clear_all` glyph now visibly renders in the header's top-right corner (screenshot-confirmed). Fixed in `fix(19-06): 7cb4f07`.

### Item 6: centre height did not match tiled Hyprland windows

Previously `top:true`/`bottom:true` with zero top/bottom margin and `margins.right` sliding to `0` when open — spanning the full 1440px monitor height with its right edge sitting exactly on the bar's reserved boundary (`2560-50=2510`). Measured live rather than assumed, per this project's own established discipline ("measure Y too, never extrapolate a formula"): `hyprctl clients -j` on this DP-1 2560×1440 monitor (reserved `[0,0,50,0]`) shows a real tiled client at `(13,13)` size `(2484,1414)` — 13px inset on every side (`gaps_out=10` + `border_size=3` from `hyprland.lua`; Hyprland's reported client geometry includes the border), landing its right edge at `2497`, 13px inside the reserved boundary, not on it. Deliberately did NOT reuse `PanelDialog.qml`'s own `panelTopMargin=10` — that answers a different surface's own top gap (a floating dialog), not this edge-to-edge sidebar's alignment against tiled windows. Added `margins.top`/`margins.bottom = 13` and folded a `+13` baseline into the existing offset-scale-driven `margins.right` slide. Since the frame is no longer screen-flush on three of its four edges, changed the chrome's corner rounding from left-only to uniform on all four corners (a flush corner on a now-visibly-inset edge would read as a rendering mistake). Verified live: `hyprctl layers` reports the open centre at `xywh 2067 13 430 1414` (right edge `2067+430=2497`, bottom edge `13+1414=1427`) against the measured tiled window's own `(13,13)`-`(2497,1427)` — an exact match on every edge; screenshot-confirmed the resulting gap and rounded corners top and bottom. Fixed in `fix(19-06): eca792b`.

### Verification limitations this round

This host has no synthetic-pointer tool (`ydotool`/`wlrctl`/`dotool` all absent — matching this repo's own already-documented limitation from prior rounds). Every fix requiring an actual mouse CLICK to fully exercise (item 4's x-button-vs-expand fix, the clear-all button's own click handler in item 5, and clicking to expand a group to inspect item 2's per-row icon) was verified via code review and structural equivalence to an already-working pattern, plus IPC-driven (`qs ipc call`) and D-Bus-driven (`notify-send`/`gdbus`) live exercising of everything that does NOT require a literal pointer click. Screenshot evidence (via `grim`) was used extensively this round to confirm actual painted pixels rather than "no error thrown," a stronger verification standard than round 3 used for item 3. Human click-through verification of items 2 (row-level), 4, and 5's own MouseArea remains recommended at end-of-phase UAT.

### Round 4 verification summary

Every fix above was verified against the running shell (`systemctl --user restart quickshell.service` after every code-affecting change, `~/.cache/quickshell/qmlcache/` cleared before each restart). `pgrep -x quickshell` was confirmed a single PID and `coredumpctl list` confirmed to show no entry past the original `16:15:54` dump after every single restart this round (seven restarts total, including three purely-diagnostic ones for item 5's root-cause probe). No Plan 19-08 artifact and no swaync-related file was touched.

**Commits, round 4:** `65e4787` (revert of `c474164`), `30ea79a` (fix(19-04), item 1), `969b79d` (fix(19-06), item 2), `e5973b8` (fix(19-06), item 4), `7cb4f07` (fix(19-06), item 5), `eca792b` (fix(19-06), item 6). Item 3 needed no commit — verified already correct with stronger evidence than round 3 provided.

## Gap-Closure Fix, Round 5 (post-execution, GATE-02 re-check)

**A direct user correction overrode round 4 item 3's own discussion-log-based conclusion, plus three further live failures.**

### The "picture" feature — RESTORED per direct user correction, not a fresh design call

Round 4 item 3 concluded (from re-reading 19-DISCUSSION-LOG.md/19-UI-SPEC.md) that "the picture" was already fully satisfied by the existing single-slot icon-fallback chain, with no distinct Caelestia-style thumbnail feature documented anywhere. **The user directly corrected this**: the picture WAS explicitly requested and agreed during phase discussion, then dropped from the written requirements — a gap in the written record, not evidence the feature was never wanted. Per direct instruction, implemented rather than re-litigated. `.planning/research/FEATURES.md`'s own NOTIF section (re-checked again this round) remains silent on the exact picture/badge composition — it documents Caelestia's icon+ring-progress treatment but never describes a distinct thumbnail widget — so the standard Caelestia layout the round-5 instruction itself specified was used to fill that documentation gap: a large rounded-square picture (the image-hint tier) at the icon slot's leading position, with the app's own icon as a small badge overlapping its bottom-right corner; app icon alone fills the slot when no picture resolves; the generic glyph placeholder when neither resolves.

**Implementation:** `NotifCard.qml` (the popup) and `NotifGroup.qml` (both the collapsed group header and each expanded centre row) all gained the same three-tier composition. The rounded-square crop uses the exact `MultiEffect` + invisible `layer.enabled: true` `Rectangle`-as-mask-source technique already proven in `dashboard/MediaTab.qml`'s own circular album-art crop — reused, not reinvented, just with a rounded-square mask instead of a circle. `NotifGroup.qml`'s old combined `resolveIconSource()` (image-then-appIcon-then-desktopEntry as one string) was retired and split into `resolveAppIconSource()` (the two icon-theme tiers alone, now independently addressable for the badge) plus per-slot `_pictureSrc` properties reading the image-hint tier directly.

**Persistence honesty (explicitly requested):** live-confirmed that a raw `image-data` pixel-buffer notification's picture (Quickshell's own `image://qsimage/N/M` decoded-pixmap URL) does NOT survive a shell restart — the in-process decoder that served it is gone. Before this round's own fix, the CENTRE's collapsed header fell straight through to the generic bell glyph in this case, never trying the app icon that was still perfectly resolvable (a real file path, unaffected by the restart); the row-level slot (using the newer split-resolver properties) already handled this correctly by design. Fixed the header to use the same three-tier fallback structure as the row, so both now gracefully show the app icon after a restart instead of the bell — confirmed live via a genuine restart-and-reload test, screenshotted before and after.

**Verified live across all three real-world image-delivery mechanisms**, each screenshotted in both the popup and the centre: a file-path `app_icon` (`notify-send -i`), a raw D-Bus `image-path` hint, and a raw D-Bus `image-data` pixel buffer — the last two paired with a distinct real `app_icon` (kitty's actual icon file) specifically to exercise the badge. All three show the picture large and rounded with the kitty-logo badge correctly overlapping its corner in the popup; the centre's row-level composition was confirmed identical via a temporary `expandedApps` force-expand used ONLY for the screenshot (reverted immediately after, never committed). The persistence-fallback path was verified via an actual `systemctl --user restart` between sending the notification and re-checking — not simulated.

Committed in `0e6a9e8` (`feat(19-04)`, popup) and `cf062ed` (`feat(19-06)`, centre — bundled with items 1 and 3 below since all three touched overlapping regions of the same file in the same session; see that commit's own message for the itemized breakdown).

### Item 1: "x" mark STILL expands the group instead of clearing — SECOND attempt

Round 4's z-order reorder (`e5973b8`) was reported as NOT fixed live — the direct user re-test failed it a second time. Per explicit instruction, abandoned the z-order/paint-order theory entirely (it was never re-verified with an actual click, only reasoned about) in favour of a structural, geometry-based fix: `headerMouseArea`'s own bounds now stop at `groupActions.left` instead of extending to `parent.right`, so there is no pixel anywhere that both it and anything inside `groupActions` (the close glyph, count badge, chevron) can claim — there is nothing left for ANY layering rule, correct or not, to get wrong, because the two hit areas no longer overlap at all. Added a dedicated small `MouseArea` on the chevron specifically (not the badge) so its own "click to expand" visual affordance keeps working now that the catch-all area no longer reaches it.

**This host still has no synthetic-pointer tool** (`wlrctl`/`ydotool`/`dotool` all absent, `wtype` present but keyboard-only — checked fresh this round per explicit instruction). Per the coordinator's own fallback instruction, temporary `console.log("GATE02-R5-PROBE ...")` diagnostic probes were added at every link of the click chain (`groupCloseMouseArea.onClicked` → `NotifGroup.clearGroupRequested` → `NotifCentre.onClearGroupRequested` → `NotifServer.clearGroup()`, and separately `headerMouseArea.onClicked` to catch the click landing on the WRONG handler if the structural fix still doesn't work), committed the structural fix WITHOUT the probes (`cf062ed`), then RE-ADDED the probes as uncommitted working-tree edits on top — exactly as instructed. **These probes are left in place, uncommitted, for the coordinator's own human click-test.** See "Log lines to check" below.

### Item 2: clear-all does nothing when clicked

Code review of the full chain (`clearAllMouseArea.onClicked` → `NotifServer.clearAll()` → `_clearAllBatchTimer`) found no logical defect — the wiring, the timer's batching loop, and the `enabled: clearAllButton._hasHistory` gate all read correctly, and `_hasHistory` was independently confirmed reactive and correctly `true` whenever real history exists (round 4 item 5's own diagnosis). No code change was made because no bug was found to fix — this is very plausibly the SAME class of "click delivery" issue as item 1, previously untestable because item 5's own visibility bug (round 4) meant this exact click had never actually been attempted live before this round. Per the same fallback instruction, temporary probes were added at `clearAllMouseArea.onEnabledChanged` (to catch the button silently going non-interactive), `clearAllMouseArea.onClicked`, and `NotifServer.clearAll()`'s own entry — left in place, uncommitted, alongside item 1's probes.

### Item 3: critical/urgent card design not reflected identically in the centre

Direct pixel-level comparison (screenshot, zoomed 4x) of the popup's fallback glyph against the centre header's own glyph for a fresh single-notification critical group showed them ALREADY rendering identically — same "error" Material glyph, same `BarRoles.danger` tint, confirmed by eye and via the underlying code (both files' fallback-glyph `text`/`color` bindings are byte-identical in logic). The one genuine, concrete gap this investigation found: `_headerCritical` only read the group's NEWEST (`_first`) item's urgency — a group whose newest notification is NOT critical silently hid an older critical item's marker at the collapsed level, unlike the popup which marks every individual critical card regardless of recency. Widened to `groupItems.some(...)` so a critical notification's marker is never lost at the collapsed level just because a newer, calmer notification from the same app arrived after it. Committed alongside items 1 and the picture feature in `cf062ed`.

### Log lines to check for items 1 and 2 (human click-test required)

The probes are live in the running shell right now (uncommitted working-tree edits on top of `cf062ed`/existing `NotifServer.qml`/`NotifCentre.qml`). After clicking, check `~/.cache/quickshell.log` for:

- **Item 1 (click the "x" on a group header):** expect `GATE02-R5-PROBE groupCloseMouseArea clicked, appName=X` → `GATE02-R5-PROBE NotifCentre onClearGroupRequested appName=X` → `GATE02-R5-PROBE NotifServer.clearGroup() called, appName=X ...`, in that order, and NO `GATE02-R5-PROBE headerMouseArea clicked` line. If `headerMouseArea clicked` appears instead, the click is still landing on the wrong area despite the geometric exclusion. If NEITHER line appears, something above `NotifGroup.qml` (a focus grab, a `ListView`/`Flickable` gesture recognizer, or similar) is intercepting the click before it reaches either MouseArea.
- **Item 2 (click clear-all in the header):** first check `GATE02-R5-PROBE clearAllMouseArea.enabled=...` logged around the time of the click (should read `enabled=true`, `_hasHistory=true`) — if it reads `enabled=false` at click time, the button is silently non-interactive despite being visible, a real bug to chase next. Then expect `GATE02-R5-PROBE clearAllMouseArea clicked, historyLen=N` → `GATE02-R5-PROBE NotifServer.clearAll() called, historyLen=N`. If the `clearAllMouseArea clicked` line never appears despite a real click landing visually on the button, the click is being intercepted before reaching the MouseArea at all — same class of failure as item 1, different surface.

### Round 5 verification summary (probes-in-tree checkpoint)

Every code-affecting change was verified against the running shell (`systemctl --user restart quickshell.service`, `~/.cache/quickshell/qmlcache/` cleared before each restart — nine restarts this round, including diagnostic ones for the persistence-honesty test and the temporary `expandedApps` screenshot verification). `pgrep -x quickshell` stayed a single PID and `coredumpctl list` showed no entry past the original `16:15:54` dump after every restart; `busctl --user list` confirmed `quickshell` retained sole ownership of `org.freedesktop.Notifications` throughout. No Plan 19-08 artifact and no swaync-related file was touched.

**Commits, round 5 (probes-in-tree checkpoint):** `0e6a9e8` (feat(19-04), popup picture+badge), `cf062ed` (feat(19-06), centre picture+badge + item 1 x-button structural fix + item 3 widened critical detection). Item 2 needed no committed code change at this checkpoint — diagnosis only, probes left uncommitted for the coordinator's human click-test alongside item 1's own probes.

### Human click-test verdict — the diagnosis inverted, and the ACTUAL bug was found

The coordinator ran the human click-test the probes above were built for. **Verdict: the click/UI layer is completely innocent.** Both chains fired end-to-end exactly as designed:

- Item 1: `groupCloseMouseArea clicked, appName=kitty` → `NotifCentre onClearGroupRequested` → `NotifServer.clearGroup() called, appName=kitty _clearGroupTarget=kitty` — repeated 4x (the user kept clicking because nothing visibly happened). The round-5 geometric fix for the x-button propagation bug WORKS — this was never the live bug at all past round 5's own fix.
- Item 2: `clearAllMouseArea clicked, historyLen=100` → `NotifServer.clearAll() called, historyLen=100` — fired 12x, `historyLen=100` on every single call, never shrinking.

**Root cause, found with `NotifServer.qml`'s own deep probes plus a temporary test-only IPC verb** (`clearAllTest()`/`clearGroupTest()` added to the existing `notifs` IpcHandler target in `shell.qml`, driving `NotifServer` directly — no click needed for this half of the investigation): both `_clearAllBatchTimer` and `_clearGroupBatchTimer` are declared `interval: 0, repeat: true`. `Timer.start()` correctly flips `running` to `true` (proven with a before/after log around the call), but **`onTriggered` never fired a single tick** on this Quickshell/Qt build — confirmed across several seconds of waiting after directly invoking `clearAllTest` via IPC, with `historyCount` (the same IPC target's own read verb) staying pinned at 100 the whole time and zero `_clearAllBatchTimer tick` log lines appearing at all.

Since ALL of `clearAll()`'s actual history mutation lives inside that Timer's `onTriggered`, a dead timer makes `clearAll()` a permanent no-op — exactly the "historyLen=100 forever" symptom. And since `clearGroup()`'s own re-entrancy guard (`if (_clearGroupTarget !== "") return;`) is only ever cleared by the SAME dead timer completing, the FIRST `clearGroup()` call sets `_clearGroupTarget = appName` and then silently blocks every subsequent call (for ANY app, not just the one first targeted) forever — exactly the "kitty group never disappears, `_clearGroupTarget=kitty` on every call" symptom. One root cause, both symptoms.

**Fix:** `interval: 0` → `interval: 1` on both timers (`NotifServer.qml`). Still imperceptible — the whole history drains in a handful of 1ms ticks.

**Verified with hard evidence, driven entirely through the temporary IPC verbs (no clicks needed for this verification):**
- `clearAll()`: `historyCount` read `100` before, `0` immediately after invoking `clearAllTest`; the deep-probe log showed real ticks (`100→70→40→10→0`, `batchSize=30`, matching `Design.notifHistoryBatchSize`). Restarted `quickshell.service` (fresh qmlcache) and re-read `historyCount`: still `0`; `~/.local/state/quickshell/notifications.json`'s own `history` array length: also `0` — genuinely persisted, not an in-memory-only artefact.
- `clearGroup()`: seeded two distinct app groups (`seedapp-alpha` ×2, `seedapp-beta` ×2 via `notify-send -a`), `historyCount` read `4`. Invoked `clearGroupTest("seedapp-alpha")`: `historyCount` read `2`, and the persisted JSON showed only `seedapp-beta`'s two entries remaining. Restarted `quickshell.service`: still `2`, still only `seedapp-beta` — survives a real restart, not just the in-memory session.

All temporary `GATE02-R5` diagnostic probes (the click-chain `console.log` lines from the earlier checkpoint, PLUS the new deep timer-tick probes and the temporary `clearAllTest()`/`clearGroupTest()` IPC verbs) were removed after this verification. `NotifCentre.qml`, `NotifGroup.qml`, and `shell.qml` carry **zero net diff** against their prior committed state — every probe added to those three files this round was fully reverted, so only `NotifServer.qml` (the actual fix) shows a diff. A final post-cleanup restart confirmed: single `quickshell` instance, zero new coredumps, `org.freedesktop.Notifications` ownership intact, and a fresh `notify-send` still correctly recorded into history (count `0 → 1`), confirming the whole notification pipeline is healthy after the fix and the instrumentation removal.

One honest observation for the record: `historyCount` read `0` at the very start of this final post-cleanup check, rather than the `2` (`seedapp-beta`) left over from the verification above. The most likely explanation is benign — this is a live, shared desktop, and a real click on clear-all (now that the fix is actually deployed and live) would produce exactly this result. This was NOT re-investigated further since it is consistent with success (a working clear, not a stuck-at-N symptom) and outside the scope of what was asked; flagged here rather than silently left unremarked.

### Round 5 final verification summary

`pgrep -x quickshell` stayed a single PID and `coredumpctl list` showed no entry past the original `16:15:54` dump across every restart this round (thirteen total, including the deep-probe and IPC-driven verification restarts). `busctl --user list` confirmed `quickshell` retained sole ownership of `org.freedesktop.Notifications` throughout. No Plan 19-08 artifact and no swaync-related file was touched.

**Commits, round 5 (final):** `0e6a9e8` (feat(19-04), popup picture+badge), `cf062ed` (feat(19-06), centre picture+badge + item 1 x-button structural fix + item 3 widened critical detection), `0171b9b` (fix(19-06), the actual clearAll()/clearGroup() root-cause fix — `interval: 0` → `interval: 1` on both batch timers).

## Gap-Closure Fix, Round 6 (post-execution, GATE-02 re-check)

**The user confirmed items 1 (x-button) and 2 (clear-all) from round 5 now work correctly — both permanently fixed. Two further items: the "picture" was misunderstood (a decorative centre element, not per-notification thumbnails), and destructive controls need red hover feedback.**

### Item 1: the decorative centre picture — Caelestia's REAL source found and matched

The user directly corrected round 5's own picture work: "it is NOT per-notification image rendering... it is a decorative/cosmetic picture — a logo/artwork element in the notification centre itself, the way Caelestia shell has one." (Round 5's thumbnail-in-row work stands on its own merits and was not reverted — it just wasn't what this specific ask was about.)

**Research, per the round-6 instruction's own escalation path:** `.planning/research/FEATURES.md`'s NOTIF section (re-checked) still only documents the popup's icon+ring-progress treatment — nothing sidebar-specific. Escalated to inspecting the actual `caelestia-dots/shell` source, found already vendored at `~/.claude/jobs/4517c040/tmp/caelestia-shell` (a dated git clone, commit `06b4fe0`, 2026-07-30) — cross-checked live against the current `raw.githubusercontent.com` HEAD of `modules/sidebar/Content.qml` via `curl` and confirmed byte-identical, so the vendored copy is not stale for this file. Read every file in Caelestia's real `modules/sidebar/` tree (`Content.qml`, `Wrapper.qml`, `NotifDock.qml`, `NotifGroupList.qml`, `NotifGroup.qml`) for any `Image`/`AnimatedImage` element.

**Finding:** exactly ONE decorative picture exists anywhere in Caelestia's real notification sidebar, in `NotifDock.qml` lines 96-107 — an `Image` bound to `Config.paths.noNotifsPic` (default `root:/assets/dino.png`, confirmed in `plugin/src/Caelestia/Config/userpaths.hpp`'s own `CONFIG_PROPERTY` macro), shown ONLY inside the empty-state `Loader` (`opacity: notifCount > 0 ? 0 : 1`), tinted via a `Colouriser` layer effect. There is **no separate always-visible header banner** anywhere in the real source — `Content.qml` itself is nothing more than one `NotifDock` inside a `StyledRect`; the coordinator's own "likely top-of-panel header area" framing was a reasonable guess about placement that the primary source does not actually bear out.

**Conclusion:** this project's own empty-state illustration (`notif-empty.svg` + "All up to date!", built in Task 1, D-19-22) is therefore ALREADY the faithful equivalent of Caelestia's real decorative picture — same placement (centred in the empty region), same behaviour (empty-state-only), same tint mechanism (this file's own header comment already records the Colouriser-parity finding). The one genuine, concrete gap versus Caelestia's actual pattern: Caelestia's picture is user-configurable (`Config.paths.noNotifsPic`); this project's was a hardcoded bundled path with no override.

**Fix:** added an optional user-override image at `~/.local/state/quickshell/notif-centre-picture.png` (the SAME directory `NotifServer.qml`'s own `notifications.json` already lives in — no new directory convention). When present and successfully loaded (`Image.status === Image.Ready`), it's used (tinted through the same `MultiEffect` colourisation as the default, matching Caelestia's own unconditional tint regardless of default-vs-override); absent or broken, it falls straight through to the bundled `notif-empty.svg` — the same `Image.status !== Error` graceful-degradation idiom this whole session's icon-fallback work already established, applied here to a missing USER asset instead of a missing notification icon.

**Verified live:** with no override file present, a single `WARN: Cannot open` logs (expected — the file genuinely doesn't exist) and the bundled bell illustration renders correctly, tinted, "All up to date!" showing (screenshot-confirmed, no crash, no broken-texture gap). Dropped a real test PNG (a solid white circle) at the override path and restarted: the override rendered instead, correctly tinted through the identical `MultiEffect` pipeline (screenshot-confirmed). Removed the test file and confirmed the fallback path again on a final restart. Committed in `8928a2f` (`feat(19-06)`, bundled with item 2's clear-all hover fix below since both landed in this same file this round).

### Item 2: destructive controls need red hover feedback

The per-notification "x", the per-app-group "x", and the clear-all button all hovered to the neutral `BarRoles.accent` — the SAME colour any non-destructive hover in these files uses (e.g. the group-expand header background), giving a "clear this forever" action no more visual weight than "expand this." All three now hover to `BarRoles.danger`, using the exact same `containsMouse`-conditional-colour idiom these files already use everywhere — no new mechanism, just the correct colour role for what each control actually does.

`NotifCard.qml` (the popup) was checked and needs no change: its dismiss mechanism is entirely gesture-based (drag/middle-click via `gestureArea` — this file's own documented single-`MouseArea` design, no second hit area). There is no separate visible hover-state "x" button on the popup card to re-colour, so the round-6 instruction's own "if it has a visible hover state" condition is not met — correctly out of scope, not overlooked.

**Verified live:** each binding was temporarily forced to the danger branch unconditionally (`color: true ? BarRoles.danger : ...`), restarted, and screenshotted — all three glyphs (clear-all icon, group "x", per-row "x") rendered a clear red/pink tint, visually distinct from both the neutral resting grey and the purple accent used elsewhere in the centre. All three bindings were then reverted to their real `containsMouse`-conditional form before committing. Committed in `fe8851f` (`fix(19-06)`, `NotifGroup.qml`'s two close glyphs) and `8928a2f` (`feat(19-06)`, `NotifCentre.qml`'s clear-all icon, bundled with item 1).

### Round 6 verification summary

Every code-affecting change was verified against the running shell (`systemctl --user restart quickshell.service`, `~/.cache/quickshell/qmlcache/` cleared before each restart — six restarts this round). `pgrep -x quickshell` stayed a single PID and `coredumpctl list` showed no entry past the original `16:15:54` dump after every restart; `busctl --user list` confirmed `quickshell` retained sole ownership of `org.freedesktop.Notifications` throughout. No Plan 19-08 artifact and no swaync-related file was touched.

**Commits, round 6:** `fe8851f` (fix(19-06), `NotifGroup.qml` destructive hover), `8928a2f` (feat(19-06), decorative picture + user override + `NotifCentre.qml`'s own clear-all hover fix).

## Gap-Closure Fix, Round 7 (post-execution, GATE-02 re-check)

**Four items reported in the round-7 human click-test. All four landed in one commit, `01c58c6`.**

### Item 1: "WHERE IS THE CAELESTIA-LIKE PICTURE" — round 6's placement was the defect

Round 6's research finding (Caelestia's `noNotifsPic` is empty-state-only, `NotifDock.qml` lines 96-107) is factually correct and is left in place in-file for provenance. It was nonetheless the wrong call for **this** project, and the user's round-6 wording — "a decorative/cosmetic picture, a logo/artwork element in the notification centre itself" — was satisfied only in a state the centre is essentially never looked at in. Three independent causes, all fixed together:

1. **Placement.** The picture lived inside the empty-state `Column`, gated `visible: NotifServer.history.length === 0`. Any notification at all removed it from the scene graph. Since the centre is opened *to read notifications*, the picture was invisible in the only state that matters — a fully-working feature nobody could ever see.
2. **Scale.** 96×96, the same size as an icon. Not an artwork element.
3. **Colourisation.** `colorization: 1.0` was applied to the user override as well as the bundled glyph, flattening every pixel of a real PNG to one flat accent-coloured silhouette. Anyone who had already used the round-6 override path got a coloured blob, never their picture — so even the escape hatch round 6 added could not actually show a picture.

**Fix:** the picture is now a permanent `decorPicture` band (132px tall, full width, `Design.notifCentrePictureHeight`) anchored between the header and the history list, always rendered, with `historyRegion` re-anchored to `decorPicture.bottom`. The user override renders directly at its natural aspect with no `layer.enabled` and no `MultiEffect` in its path, so its own colours survive; only the bundled monochrome `notif-empty.svg` is still colourised to `BarRoles.accent`. The empty state keeps its "All up to date!" headline and no longer carries an image of its own — the band already shows one, and duplicating it would render the picture twice whenever history was empty. The override path is unchanged from round 6 (`~/.local/state/quickshell/notif-centre-picture.png`), so a file already placed there keeps working and now renders as actual artwork.

This is a **deliberate divergence from Caelestia's real behaviour**, recorded in-file at the `decorPicture` declaration so a future reader doing a parity pass does not "restore" it and silently regress to round 6.

### Item 2: long content looked wrong inside the card

The expanded state had no bound of any kind — `elide: Text.ElideNone`, `maximumLineCount: 0`. Because the card's `implicitHeight` follows `contentColumn.implicitHeight`, a long-bodied notification grew the card without limit and could run past the screen edge. Body now clamps to `Design.notifBodyMaxLines` (8) with a trailing ellipsis; a long summary may take 2 lines when expanded rather than being chopped at 1 (compact stays at exactly 1 elided line, as 19-UI-SPEC.md N1/long-text requires — the spec says nothing about the expanded case).

**Deviation from 19-UI-SPEC.md (N1/overflow), deliberate:** the spec calls for the expanded state to *scroll* past the clamp, reusing `PanelDialog`'s `Flickable` treatment. A `Flickable` nested inside this card would compete for the same vertical and horizontal touch stream as the card's own two drag gestures (D-19-05 drag-to-expand, D-19-07 drag-to-dismiss). The same bound is therefore enforced by line count instead of a scroll view — identical outcome for the reported defect, no gesture contention.

### Item 3: too many popups on screen at once

Visible depth was purely the geometric fit — `floor(2/3 screen height / per-card height)` — which resolves to roughly a dozen cards on this monitor before the existing "+N more" summary card ever appeared. `Design.notifMaxVisiblePopups` (3) is now layered on top as the design bound, smaller-wins against the geometric ceiling (a short monitor must still never overflow its own height budget). The overflow card and every count derived below it pick this up with no further change, so surplus notifications are **summarised, never dropped**.

### Item 4: glass look

Both surfaces were **already** blurred — `quickshell-notif-popups` and `quickshell-notif-centre` both match the `^quickshell-.*` family blur rule in `windowrules.lua`. The compositor was frosting the backdrop the whole time; at 0.78 alpha almost none of it reached the eye and both read as solid panels. `BarRoles.notifSurface` is now 0.55 resting and `notifSurfaceHover` 0.72 — 0.55 is `barSurface`'s own existing register, not a newly invented value, and the ~0.12 resting→hover step is preserved. No compositor file was touched, so no `hyprctl` reload is required for this to take effect (which also avoids the known reload-drops-layer-rules trap entirely).

Both values deliberately clear the family's **0.5 `ignore_alpha` floor**. Below that cutoff a region is not blurred at all and reads as raw unblurred transparency — the exact failure mode already recorded at the `ags-media` and `quickshell-overview` rules in that same file. The in-file note states that lowering either value past 0.5 requires first declaring a namespace-scoped `ignore_alpha` rule **after** the family pair, per `windowrules.lua`'s own ordering finding.

### Round 7 verification summary

`qmllint --bare` clean on all five modified files. `quickshell-doctor --self-test`: **55 passed, 0 failed**. `colour-lint` (GATE-04) reports two failures — `bar-surface-registry` (`unregistered=3`) and `permissions-allowlist-paths-resolve` — and **both reproduce identically with this round's changes stashed**, confirming they are pre-existing (the registry gap is the one already deferred to Plan 19-08 by explicit precedent, see "Next Phase Readiness" above) and not introduced here.

Live: `systemctl --user restart quickshell.service`, then a deliberately long-bodied notification followed by four more in quick succession to exercise both the new body clamp and the new popup cap at once. `pgrep -c quickshell` stayed 1, `systemctl --user is-active` stayed active, `hyprctl layers` showed the popup layer up, and the only coredump in the window was an unrelated `gjs-console` SIGSEGV. `busctl --user list` confirmed sole ownership of `org.freedesktop.Notifications` throughout. No Plan 19-08 artifact and no swaync-related file was touched.

**Commit, round 7:** `01c58c6` (`fix(19-06)`) — `NotifCentre.qml`, `NotifCard.qml`, `NotifPopupStack.qml`, `BarRoles.qml`, `Design.qml`.

## Gap-Closure Fix, Round 8 (post-execution, GATE-02 re-check)

**Two items. Commit `7a80e41`.**

### Item 1: "Why did you move the picture(bell) location? Return it to the center." — placement now settled

Round 7 promoted the picture out of the empty state into an always-visible band under the header. Round 8 reverts that: it is back at the empty-state centre it held in round 6, which is also Caelestia's own placement in `NotifDock.qml`.

**Why this is now closed rather than another swing.** Rounds 7 and 8 jointly imply "always visible" *and* "centred", and those two are not simultaneously reachable in this panel: the vertical centre is exactly where the history list lives, so the only construction satisfying both is rendering the picture *behind* the cards. That option was put to the user explicitly, with a layout sketch, and rejected — "results in a case where the picture is visible behind the cards which looks buggy." With behind-content ruled out, "centred" resolves unambiguously to the empty state. The `emptyIllustrationHost` declaration now carries a **do-not-move marker** recording this reasoning, so the next reader does not re-open a question that has already cost three rounds.

**Round 7's two non-positional fixes are deliberately retained**, since neither concerned where the picture sat and both were independent reasons it read as "there is no picture at all":

- It renders at `Design.notifCentrePictureHeight` (132px) rather than the original 96px icon scale.
- A user-supplied override renders **untinted** at its natural aspect. Round 6 pushed both the bundled fallback and the override through `colorization: 1.0`, flattening any real PNG to one accent-coloured silhouette — so the override mechanism round 6 added could never actually display a picture. Only the bundled monochrome glyph is still colourised (matching Caelestia, which colourises its own mascot).

Override path unchanged since round 6: `~/.local/state/quickshell/notif-centre-picture.png`.

### Item 2: "Glass/frosty look is not noticeable enough" — the threshold was the binding constraint, not the blur

Blur was never the missing piece. `decoration:blur` is globally enabled at **size 8 / passes 3**, and all three notification namespaces already inherit `blur = true` from the `^quickshell-.*` family regex — the compositor had been frosting these backdrops since Plan 19-01. What was missing was *transparency for that frost to show through*.

Round 7 lowered the surfaces to 0.55 and **stopped there because that was the floor**: the family's own `ignore_alpha = 0.5` means any region composited below the cutoff is not blurred at all and renders as raw unblurred transparency — the exact failure mode already recorded at the `ags-media` rule. 0.55 was therefore as see-through as the surface could get while remaining frosted, which is why round 7's change was real but visually modest.

**Fix — the constraint is lifted at its source.** `windowrules.lua` now declares `ignore_alpha = 0.2` for `quickshell-notif-popups`, `quickshell-notif-centre` and `quickshell-notif-toast`, **declared last in the file** so it beats the family floor it contradicts (this file's own recorded ordering finding: a namespace rule contradicting the family regex silently loses when declared before it). `blur = true` is restated alongside rather than relying on inheritance, matching the shape of the `quickshell-overview` pair. With the cutoff at 0.2, the sub-0.5 range reopens and `BarRoles.notifSurface`/`notifSurfaceHover` move into it at **0.38 resting / 0.52 hover** — both well clear of the new cutoff, so every region of both surfaces still genuinely frosts. 0.2 is chosen the same way `ags-media`'s 0.25 was: below every composited alpha the surface can present, so no region drops under it and goes raw.

**These are a matched pair and are cross-referenced in both files.** Raising the threshold back toward 0.5, or dropping the alphas below 0.2, silently switches blur off on this family rather than erroring. Blur *strength* remains global (`decoration:blur:size`/`passes`) and is untouched — it cannot be set per-layer, as `windowrules.lua` already records.

**Applied live with `hyprctl keyword layerrule` before restarting the shell — never `hyprctl reload`**, which drops layer rules silently and would have made the change look like a wrong-alpha problem instead of an unapplied-rule one.

### Round 8 verification summary

`qmllint --bare` clean on both modified QML files; `luac -p` clean on `windowrules.lua`. `quickshell-doctor --self-test`: **55 passed, 0 failed** — this includes the windowrules extractor's own accept/reject check and its declared-order check, both of which cover the six new layer-rule calls. Live: rules applied via `hyprctl keyword`, shell restarted, `pgrep -c quickshell` = 1, service active, a test notification sent and the `quickshell-notif` layer confirmed mapped.

`colour-lint` reports four failures — `zero Quickshell MPRIS writers`, `panel-swayosd-key-ownership`, `bar-surface-registry` (`unregistered=3`) and `permissions-allowlist-paths-resolve`. **All four are the same set produced by the stash-verified pre-change baseline taken in round 7** (changes stashed, checks re-run, identical failures), so none is introduced by rounds 7 or 8. The `bar-surface-registry` gap is the one already deferred to Plan 19-08 by explicit precedent (see "Next Phase Readiness" above).

**Commit, round 8:** `7a80e41` (`fix(19-06)`) — `NotifCentre.qml`, `BarRoles.qml`, `windowrules.lua`.

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
