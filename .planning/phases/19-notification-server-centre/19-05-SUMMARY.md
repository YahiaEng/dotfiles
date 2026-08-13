---
phase: 19-notification-server-centre
plan: 05
subsystem: notifications
tags: [quickshell, qml, notifications, singleton, toast, brightness]

# Dependency graph
requires:
  - phase: 19-notification-server-centre
    provides: "19-01's pragma-Singleton NotifServer owning org.freedesktop.Notifications, its popups/history/dnd public surface as honest empty stubs; 19-04's full popup card, replaces_id and gesture-driven dismiss(id)"
provides:
  - "NotifServer.qml's history persistence (~/.local/state/quickshell/notifications.json), DND ownership (persisted, reverts on a failed write), and the four-input suppression predicate (dnd/gaming/centreOpen/fullscreenBlocking) — the server half of QNOTIF-09/10"
  - "ToggleState.qml, a pragma-Singleton sole owner of all six quick-toggle tiles' state (gaming/dnd/dark/volume/wifi/bluetooth), promoted out of QuickToggles.qml so a second grid instance (Plan 19-06's centre) cannot drift from the drawer's own — QNOTIF-07"
  - "modules/toast/Toast.qml (module qs.modules.toast) — a generic, chrome-only transient-notice frame reused verbatim by Phase 20's OSD, wired to NotifServer.dndToggled for the DND on/off notice"
  - "BrightnessBackend.setPercent(percent) — an absolute setter alongside the existing relative adjust(steps), for Plan 19-06's centre slider"
affects: [19-06, 19-07, 19-08, 20]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
actuals:
  tokens: 26200
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A file-backed FileView/setText() persistence pair (never the toolkit's hot-reload-scoped PersistentProperties type) for state that must survive a real process restart, not just a QML hot reload — WeatherBackend.qml's own cache-write idiom, reused here for notification history + DND"
    - "Cross-singleton wiring via a declarative Binding element (shell.qml's own PopoutController.barSettled precedent) rather than an imperative one-shot assignment or a second read of compositor/backend state — used to feed NotifServer.fullscreenBlocking and to relay QuickToggles' already-threaded backend seams into ToggleState"
    - "A view/state split for a component instantiated more than once: ToggleState.qml (pragma Singleton) owns every FileView/Process/Timer/pending-model bit of state; QuickToggles.qml owns only rendering, reading ToggleState.* and calling ToggleState.pressChipByName() — makes a second grid instance structurally incapable of drifting rather than merely tested not to"
    - "A chrome-only reusable frame with a generic default-property content slot (Toast.qml), fed reactive content by its single mount site (shell.qml) rather than carrying feature-specific copy inside the frame itself — the frame is reused by name across features (Phase 20's OSD) without a second copy of the chrome"

key-files:
  created:
    - quickshell/.config/quickshell/modules/dashboard/ToggleState.qml
    - quickshell/.config/quickshell/modules/toast/Toast.qml
    - quickshell/.config/quickshell/modules/toast/qmldir
  modified:
    - quickshell/.config/quickshell/modules/notifications/NotifServer.qml
    - quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml
    - quickshell/.config/quickshell/modules/dashboard/qmldir
    - quickshell/.config/quickshell/modules/bar/BrightnessBackend.qml
    - quickshell/.config/quickshell/shell.qml

key-decisions:
  - "History is recorded unconditionally at D-Bus arrival (before the suppression branch), not at dismiss time as Plan 19-04's tracer version did — a genuinely suppressed notification is never popped and therefore never dismissed, so recording-on-dismiss would have left it with no history entry at all, exactly the 'silently destroyed' case D-19-33 forbids. dismiss(id) no longer pushes into history (would have double-recorded every popped-and-dismissed notification); it only removes the popup wrapper now."
  - "Do-not-disturb, gaming mode and 'centre open' are three independent, uncoupled suppression inputs read by NotifServer directly (gaming via its own FileView on ~/.cache/gaming-mode — a duplicate READ of the one truth file ToggleState also reads, not a second source of truth for it); fullscreenBlocking is the one input NotifServer never computes itself, fed instead by a shell.qml Binding onto shell.qml's own existing single fullscreen-focus owner (RESEARCH.md Pattern 6, reused verbatim)."
  - "ToggleState's backend seams (audioBackend/wifiBackend/bluetoothBackend) arrive via three Binding elements declared INSIDE QuickToggles.qml, relaying properties QuickToggles already receives from the existing Dashboard.qml -> DashboardTab.qml threading path — chosen over wiring shell.qml directly into the singleton, so neither of those two files needed an edit for this plan (despite both being listed in the plan's own files_modified)."
  - "DND toggle copy strings (the exact UI-SPEC Copywriting Contract text) live on NotifServer.qml, emitted through a new dndToggled(newValue, heading, body) signal, rather than inside Toast.qml or shell.qml — keeps Toast.qml a genuinely generic chrome frame (Phase 20 reuse) and keeps the copy on the file that already owns DND as its single source, rather than a third location."
  - "A tile whose injected backend seam is null (volume/wifi/bluetooth only — gaming/dark/dnd have no injectable backend to go missing) now renders at the repo's established 0.38 disabled opacity with an explanatory tooltip and a disabled press, instead of silently reporting a default value that reads as real truth — a new behaviour this plan's own acceptance criteria required, not present before."

patterns-established:
  - "Any later plan needing a second QuickToggles-style multi-instance component should follow this plan's exact split: promote the STATE to a pragma-Singleton first, convert the existing component into a pure view over it, and thread any instance-scoped backend handle through the view's own already-existing property, relayed via a Binding — never straight from shell.qml into the singleton."

requirements-completed: [QNOTIF-07, QNOTIF-09, QNOTIF-10]

coverage:
  - id: D1
    description: "NotifServer persists notification history and do-not-disturb to ~/.local/state/quickshell/notifications.json (never the hot-reload-scoped PersistentProperties type), reloads both on start, caps history at Design.notifHistoryCap dropping the oldest, and derives suppression from four independent inputs (dnd/gaming/centreOpen/fullscreenBlocking) that never write each other"
    requirement: "QNOTIF-09"
    verification:
      - kind: other
        ref: "Live end-to-end: notify-send after a genuine `systemctl --user restart quickshell.service` (D-Bus id counter reset confirms a real process restart, not a hot reload) — notifications.json exists, history count correct, survives a SECOND restart. Manually flipped dnd:true in the state file, restarted, confirmed NotifServer read it back true, sent a notification and confirmed no quickshell-notif-popups layer surface appeared while the history array still grew by one entry. grep-verified: 0 PersistentProperties references, 0 activeToplevel references (fullscreen input comes from shell.qml's own single owner via a Binding), no gaming-mode branch writes dnd."
        status: pass
      - kind: other
        ref: "quickshell-doctor --self-test (55/0) and a full quickshell-doctor run, A/B-compared via git stash against the pre-Task-1 baseline — zero new failures introduced"
        status: pass
    human_judgment: true
    rationale: "The plan's own Task 1 <human-check> (tile-lit-state after a DND-on restart, and the fullscreen-focused-client suppression path specifically) was not run interactively this session, per this project's established live-verification-skip preference — hyprctl's global-shortcut dispatch failed on this host's own Lua config syntax during an attempt to summon the drawer for a real click-through, unrelated to this plan's own files. The underlying persistence and suppression mechanics were instead proven live via direct JSON/state-file inspection and a real systemd restart (see verification above), leaving only the on-screen tile-rendering half for a human to confirm."
  - id: D2
    description: "ToggleState.qml (pragma Singleton) is the sole owner of all six quick-toggle tiles' state; QuickToggles.qml is a pure view reading ToggleState.* — a second grid instantiation cannot drift because there is exactly one state owner in the process. DND's truth/write now goes through NotifServer.dnd/toggleDnd(), replacing the swaync-client subscribe/poll pair entirely. A tile with a null backend seam renders disabled with an explanatory tooltip."
    requirement: "QNOTIF-07"
    verification:
      - kind: other
        ref: "grep-verified: 0 swaync-client references in QuickToggles.qml (was 3 process/timer sites); exactly one QuickToggles.qml file in the repo; full two-line 'Do Not Disturb' label string present verbatim; ToggleState.qml carries pragma Singleton and is declared `singleton ToggleState 1.0 ToggleState.qml` in dashboard/qmldir; the chip-width formula line is byte-identical to the pre-refactor file (git show HEAD~ vs current, diffed directly, not inferred from git diff's own line-churn on a full-file rewrite)"
        status: pass
      - kind: other
        ref: "quickshell-doctor --self-test (55/0) and a full quickshell-doctor A/B run via git stash — identical 6 pre-existing failures on both sides (swaync ownership race, MPRIS, swayosd, bar-surface-registry, permissions-allowlist), zero new failures from this task's files"
        status: pass
    human_judgment: true
    rationale: "The plan's own Task 2 <human-check> (opening the drawer, toggling the DND tile, watching it light, confirming the six-tile row renders untruncated with the full two-line label) needs a human to actually look at the rendered grid — not run interactively this session per the project's established live-verification-skip preference, and this host's `hyprctl dispatch global quickshell:dashboard` failed on a pre-existing Lua-config syntax issue unrelated to this plan when an attempt was made to summon the drawer for inspection. The state-ownership mechanics (single source of truth, DND's server-backed read/write, no swaync-client calls) were instead proven structurally via grep and doctor, per the coverage entry above."
  - id: D3
    description: "modules/toast/Toast.qml is a generic, chrome-only transient-notice PanelWindow (top-centre, notifSurface chrome, content-hugging, slide+fade motion, auto-dismissing, never click-dismissible) wired to NotifServer's new dndToggled signal via one always-mounted shell.qml instance; BrightnessBackend gains setPercent(percent), an absolute setter guarded identically to the existing relative adjust(steps), which itself is left byte-unchanged"
    requirement: "QNOTIF-10"
    verification:
      - kind: other
        ref: "grep-verified: Toast.qml + toast/qmldir exist, qmldir declares `Toast 1.0 Toast.qml`; both DND copy strings present verbatim in NotifServer.qml; BrightnessBackend.qml gains a `function setPercent(` site; windowrules.lua's quickshell-notif-toast row count is still exactly 1 (no duplicate added); adjust(steps)'s own function body diffed byte-for-byte identical against the pre-Task-3 commit. Live: quickshell-doctor --self-test 55/0; the toast namespace is absent from `hyprctl layers` while inactive (toastActive gates `visible`) and the popup-stack namespace remains present with zero content, confirming the two surfaces don't collide"
        status: pass
      - kind: other
        ref: "Deviation found and fixed live via ~/.cache/quickshell.log during this task's own verification: shell.qml never imported QtQuick, so its new Text/Column toast-content children failed to load ('Text is not a type'), crash-looping quickshell.service through systemd's restart limit; Toast.qml separately needed an `import \"../bar\"` for BarRoles ('ReferenceError: BarRoles is not defined'). Both fixed, confirmed clean by a subsequent 'Configuration Loaded' with no WARN/ERROR lines and a successful `systemctl --user restart`."
        status: pass
    human_judgment: true
    rationale: "The plan's own Task 3 <human-check> (visually confirming the toast slides in top-centre with the correct on/off copy, self-dismisses after ~2s, and two rapid toggles produce exactly one toast rather than two stacked) needs a human to actually watch the animation — not run interactively this session. The DND toggle used to exercise suppression (coverage D1) was done by directly editing the on-disk state file rather than calling NotifServer.toggleDnd() through a real UI press, so it did NOT exercise the dndToggled signal or the toast's own show()/hide() path at all; only the frame's structural correctness (imports resolve, layer namespace behaves, chrome tokens present) was live-verified this session."

# Metrics
duration: ~30min
completed: 2026-08-13
status: complete
---

# Phase 19 Plan 05: Notification History, Do-Not-Disturb Ownership & Shared Toggle Grid Summary

**NotifServer now persists notification history and do-not-disturb across a real process restart and derives popup suppression from four independent inputs; the quick-toggle grid's entire state (including DND, now server-backed instead of swaync-client) moved into one `ToggleState` singleton so a second grid instance can never drift; and a reusable top-centre toast frame plus an absolute brightness setter are in place for the centre and Phase 20's OSD to build on.**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-08-13 (session start)
- **Completed:** 2026-08-13T15:14:00+03:00 (approx, last verification restart)
- **Tasks:** 3 completed
- **Files modified:** 8 (3 created, 5 modified)

## Accomplishments
- `NotifServer.qml` persists `{ history, dnd }` to `~/.local/state/quickshell/notifications.json` via a `FileView`/`setText()` pair (never the hot-reload-scoped `PersistentProperties` type), reloaded on start — history live-verified to survive a genuine `systemctl --user restart quickshell.service` (D-Bus id counter reset confirms a real process restart) across two consecutive restarts
- The suppression predicate is a single OR over `dnd`/`gaming`/`centreOpen`/`fullscreenBlocking` — every arrival is recorded to history unconditionally, before that branch, so a suppressed notification always leaves a trace; `fullscreenBlocking` is fed by a `shell.qml` `Binding` onto its own existing single fullscreen-focus owner (RESEARCH.md Pattern 6), never recomputed inside `NotifServer.qml` (`grep -c 'activeToplevel'` returns 0)
- `toggleDnd()` persists optimistically and reverts `dnd` if the write fails (T-19-18's backstop), fires a new `dndToggled(newValue, heading, body)` signal carrying the exact UI-SPEC copy, and clears in-flight popups only when turning DND **on** (D-19-37)
- `ToggleState.qml` — a new `pragma Singleton` — is now the sole owner of all six quick-toggle tiles' state; `QuickToggles.qml` is a pure view over it. DND's truth/write moved from a `swaync-client -D` subscribe/poll pair straight onto `NotifServer.dnd`/`toggleDnd()`
- A tile whose backend seam (`audioBackend`/`wifiBackend`/`bluetoothBackend`) is null now renders at the repo's established 0.38 disabled opacity with an explanatory tooltip, rather than silently showing a default value that reads as real truth
- `modules/toast/Toast.qml` — a new, generic, chrome-only transient-notice frame (top-centre, `notifSurface` chrome, content-hugging, slide+fade motion) with a `default property alias body` content slot; carries zero do-not-disturb copy itself so Phase 20's OSD can reuse the identical chrome for a value readout
- `BrightnessBackend.qml` gains `setPercent(percent)`, an absolute setter guarded by the exact same device-presence probe and single-flight/coalescing shape as the existing `adjust(steps)` — whose own function body is byte-unchanged by this addition

## Task Commits

Each task was committed atomically:

1. **Task 1: History persistence, do-not-disturb ownership, and the suppression predicate** - `97380df` (feat)
2. **Task 2: Promote the quick-toggle grid to one state owner with two views** - `e9a50c1` (feat)
3. **Task 3: The transient toast frame, and an absolute brightness setter** - `62c0f31` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified
- `quickshell/.config/quickshell/modules/notifications/NotifServer.qml` - history persistence + cap, DND persistence + revert-on-failure, the four-input suppression predicate, `dndToggled` signal and copy strings, batched `clearAll()`
- `quickshell/.config/quickshell/modules/dashboard/ToggleState.qml` - new: sole owner of all six quick-toggle tiles' state and every verb that mutates them
- `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` - converted to a pure view over `ToggleState`; gained the unreachable-backend disabled-opacity/tooltip treatment
- `quickshell/.config/quickshell/modules/dashboard/qmldir` - registers `ToggleState` as a third singleton
- `quickshell/.config/quickshell/modules/toast/Toast.qml` - new: generic transient-notice frame
- `quickshell/.config/quickshell/modules/toast/qmldir` - new: registers `Toast` in module `qs.modules.toast`
- `quickshell/.config/quickshell/modules/bar/BrightnessBackend.qml` - new `setPercent(percent)` absolute setter alongside the unchanged `adjust(steps)`
- `quickshell/.config/quickshell/shell.qml` - `fullscreenBlocking`/`NotifServer` Binding, the always-mounted DND `Toast` instance + its `Connections` on `dndToggled`, `import QtQuick`/`import "modules/toast"`

## Decisions Made
See `key-decisions` in frontmatter — summarized: history records unconditionally at arrival rather than at dismiss (supersedes 19-04's dismiss-time recording, which would have missed genuinely-suppressed notifications entirely); the three suppression inputs beyond `dnd` are each sourced from their own existing single owner (a duplicate read of the gaming-mode file, never a duplicate WRITE; a `Binding` for fullscreen, never a second Hyprland read); `ToggleState`'s backend seams are relayed through `QuickToggles.qml`'s own already-threaded properties via `Binding` elements rather than wiring `shell.qml` directly into the singleton, so `Dashboard.qml`/`DashboardTab.qml` needed no edit despite being named in the plan's own `files_modified`; DND's toast copy lives on `NotifServer.qml`, not `Toast.qml` or `shell.qml`, keeping the frame generic and the copy single-sourced.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `shell.qml` never imported `QtQuick`, so this task's new `Text`/`Column` toast-content children crash-looped the live shell**
- **Found during:** Task 3, live verification via `~/.cache/quickshell.log` after wiring the DND toast into `shell.qml`
- **Issue:** `shell.qml`'s import list carried `QtQml`/`Quickshell`/`Quickshell.Hyprland`/`Quickshell.Io` plus directory imports, but never `QtQuick` — every prior surface in that file was either a directory-imported custom type or a `Quickshell`-core type, so the gap had never surfaced before. Adding the toast's own `Text`/`Column` content children (the first bare `QtQuick` primitives declared directly in `shell.qml`) failed with `Text is not a type`, and `quickshell.service`'s `Restart=on-failure`/`RestartSec=2` drove it through systemd's `StartLimitBurst=5` within about ten seconds, landing the unit in `start-limit-hit`.
- **Fix:** Added `import QtQuick` to `shell.qml`.
- **Files modified:** `quickshell/.config/quickshell/shell.qml`
- **Verification:** `systemctl --user reset-failed quickshell.service && systemctl --user restart quickshell.service` — `~/.cache/quickshell.log` showed `Configuration Loaded` with no further `Text is not a type` line; service confirmed `active (running)` via `systemctl --user status`.
- **Committed in:** `62c0f31` (Task 3 commit — found and fixed before the commit, not a separate follow-up)

**2. [Rule 1 - Bug] `Toast.qml` referenced `BarRoles.notifSurface`/`notifSurfaceFg` without importing `"../bar"`**
- **Found during:** Task 3, same live-log pass immediately after fixing Deviation 1
- **Issue:** `Toast.qml`'s import list carried `"../"` (for `Colours`/`Motion`) and `"../dashboard"` (for `Design`) but not `"../bar"`, where `BarRoles` — the notification-family colour-role singleton this frame's own chrome reads per the UI-SPEC — is registered. Produced `ReferenceError: BarRoles is not defined` on every load.
- **Fix:** Added `import "../bar"` to `Toast.qml`.
- **Files modified:** `quickshell/.config/quickshell/modules/toast/Toast.qml`
- **Verification:** Same restart cycle as Deviation 1 — the `BarRoles is not defined` warning is absent from the log after the fix, with `Configuration Loaded` and no further WARN/ERROR lines referencing `Toast.qml`.
- **Committed in:** `62c0f31` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact on plan:** Both were necessary for Task 3's own new UI content to load at all — the second was found only because the first crash-loop was already being investigated via the live log, the discipline this project's own `quickshell.service` header comment names as the reason a supervisor exists. No scope creep: both fixes are missing-import corrections in files this plan's own task already declared, not new files or new capability.

## Issues Encountered

- **`quickshell.service` crash-looped through systemd's restart limit** while Deviation 1 above was live (`StartLimitBurst=5`/`StartLimitIntervalSec=60`, confirmed via `systemctl --user status` reporting `Result: start-limit-hit`) before the fix landed. Recovered with `systemctl --user reset-failed quickshell.service && systemctl --user restart quickshell.service`, the same recovery command this repo's own `quickshell.service` header comment documents for exactly this situation. No lasting effect — the unit is `active (running)` and clean at session end.
- **`hyprctl dispatch global quickshell:dashboard` failed on this host** with a Lua-config parse error (`')' expected near 'quickshell'`) when an attempt was made to summon the dashboard drawer for a real click-through of the promoted toggle grid and the DND toast. Reproduced twice with different quoting; this is a pre-existing quirk of this repo's Lua-migrated Hyprland config (Phase 13.1), unrelated to any file this plan touches — no fix attempted, since diagnosing/fixing Hyprland's own global-shortcut CLI dispatch syntax is out of this plan's declared scope. As a result, the plan's own `<human-check>` blocks across all three tasks were not run interactively this session (see each coverage entry's `rationale` above); the underlying mechanics were instead proven via direct JSON/log/grep verification and `quickshell-doctor`.
- **`org.freedesktop.Notifications` bus ownership raced back to `swaync`** during the crash-loop recovery above (each `quickshell.service` restart attempt is a fresh race, and `swaync` won one of the several restarts triggered while chasing Deviation 1). This is the same documented, accepted transitional state Plans 19-01/19-04 already recorded (`D-19-42`/`T-19-02` — whichever process claims the name first wins until Plan 19-08 deletes `swaync`), not a regression from this plan's own code; `quickshell-doctor`'s single-owner check now reads `[PASS] ... owner: swaync` as a result of this session's own restart churn, which will re-flip on the next boot or restart as it always has.
- **`quickshell-doctor`'s `bar-surface-registry` "unregistered" count is now 2** (was 1 before this plan): `modules/notifications/NotifPopupStack.qml` (Plan 19-01, pre-existing) and this plan's own `modules/toast/Toast.qml` both declare a `WlrLayershell.namespace` that `hypr/.config/hypr/scripts/quickshell-doctor`'s `QSD_KNOWN_NONBAR_FRAMES` array does not yet enumerate. That script is not in this plan's declared `files_modified`, and the established pattern across Plans 19-01 through 19-04 (confirmed via `git stash` A/B comparison before AND after this plan's own changes — the other 5 quickshell-doctor failures are byte-identical on both sides) is to defer Phase 19's `quickshell-doctor` registry updates to Plan 19-08's own closing GATE-02 pass rather than reopen the script per-plan. Recorded here rather than silently absorbed or silently fixed out of scope.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `ToggleState.qml` is ready for Plan 19-06 to instantiate `QuickToggles {}` a second time (in the centre's footer) with zero risk of drift — it is a pure view over the same singleton the drawer already reads.
- `NotifServer.centreOpen` is an honest, reachable, currently-unbound property — Plan 19-06's own centre `PanelWindow` should bind it off its own lifecycle (the `panelOpen`/`drawerOpen` precedent), and `NotifServer.openCentre()` already clears the popup stack correctly once something calls it.
- `Toast.qml`'s generic content slot is ready for Phase 20's OSD indicators to reuse for a value readout without touching the frame's own chrome.
- `BrightnessBackend.setPercent(percent)` is ready for Plan 19-06's centre brightness slider; this host has no backlight device, so the call path is proven a clean no-op here and will only be exercised for real on hardware that has one.
- No blockers. The three items in "Issues Encountered" above (Hyprland global-shortcut CLI dispatch quirk, the swaync ownership race, and the widened `bar-surface-registry` gap) are all pre-existing or explicitly deferred, not new work this phase's later plans need to unblock.

---
*Phase: 19-notification-server-centre*
*Completed: 2026-08-13*

## Self-Check: PASSED

All 8 created/modified files confirmed present on disk; all 3 task commits
(`97380df`, `e9a50c1`, `62c0f31`) confirmed present in `git log --oneline --all`.
