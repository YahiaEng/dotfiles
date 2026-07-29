---
phase: 14-dashboard-drawer
plan: 03
subsystem: ui
tags: [quickshell, qml, swipeview, tabbar, motion-tokens, matugen-crossfade]

requires:
  - phase: 14-01
    provides: the drawer tracer surface (layer-shell window, blur, silhouette, exclusive focus grab, dismiss paths, the placeholder pane this plan replaces)
  - phase: 12
    provides: the Colours/Motion token pipeline (Colours.qml roles, Motion.qml's seven resolvable names) this pager and its manifest consume
  - phase: 14-02
    provides: Material Symbols Rounded FILL-axis render verdict, consumed by the header's active-tab glyph interpolation branch

provides:
  - The modules/dashboard/ QML module — one checked-in qmldir registering nine types (four tab shells, three non-visual Scope backends, two visual components), each carrying the D-41 populated/pending/empty widgetState register
  - The four-tab pager: TabBar header (icon+label, non-flickable Row, one-way synced) over a four-pane SwipeView, drag-threshold commit with spring-back, arrow keys clamped at both ends (no wraparound), swipe-tracking indicator
  - Shell-root selected-tab memory (dashboardTabIndex) and the shared MediaBackend/WeatherBackend instances, both bound to the loader's active state — the scope correction that leaves 14-04..14-07 exactly one file each
  - Per-tab dynamic drawer proportions (Caelestia scheme): drawerWidth/drawerHeight now read the active tab's advisory implicitWidth/implicitHeight and animate to it, superseding the original uniform 850x860 frame
  - A live-verified, non-interactive theme-crossfade proof: the drawer re-themes without restart, without closing, and with zero new quickshell.log lines while a hyprctl-driven theme-apply runs underneath it

affects: [14-04, 14-05, 14-06, 14-07, 14-08, 14-09]

tech-stack:
  added: []
  patterns:
    - "Custom SwipeView contentItem (ListView) reproducing every stock property except highlightMoveDuration, which binds to Motion.standardDuration — the one property motion-lint structurally cannot see (camelCase, not the lowercase `duration:` regex), so the guard is a source assertion, not a mechanical lint check"
    - "Header TabBar contentItem replaced with a non-flickable Row so two horizontal drag surfaces never compete for the same gesture inside a SwipeView"
    - "swipeProgress derived read-only property (contentX / width, clamped) is the single value both the indicator's x and the FILL-axis interpolation read — one-way sync, never a `checked` state"
    - "Per-tab advisory implicitWidth/implicitHeight on tab stubs (D-04 prohibition deliberately reversed) drives frame-level Behavior-animated resize, decoupled from each tab's own anchors.fill-driven actual geometry"

key-files:
  created:
    - quickshell/.config/quickshell/modules/dashboard/qmldir
    - quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml
    - quickshell/.config/quickshell/modules/dashboard/MediaTab.qml
    - quickshell/.config/quickshell/modules/dashboard/PerformanceTab.qml
    - quickshell/.config/quickshell/modules/dashboard/WeatherTab.qml
    - quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml
    - quickshell/.config/quickshell/modules/dashboard/WeatherBackend.qml
    - quickshell/.config/quickshell/modules/dashboard/SystemResources.qml
    - quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml
    - quickshell/.config/quickshell/modules/dashboard/Dial.qml
  modified:
    - quickshell/.config/quickshell/modules/Dashboard.qml
    - quickshell/.config/quickshell/shell.qml
    - .planning/phases/14-dashboard-drawer/deferred-items.md

key-decisions:
  - "Render-gate round 2 (2026-07-29) APPROVED: proportions, resize smoothness, and indicator-during-resize all confirmed working correctly by the human"
  - "Theme crossfade (check 4) could not be tested interactively by the human (theme switching steals focus from the drawer) — verified non-interactively by the executor instead: drawer held open, theme-apply run from the executor's own shell to nord then back to dracula, before/after screenshots captured, quickshell.log confirmed free of errors/warnings, drawer confirmed to stay open at the same surface address throughout, original theme (dracula) restored"
  - "Tab memory (drawer reopens on the last tab shown, not always Dashboard) is KEPT AS-IS — explicitly ratified by the human at the render gate as the intended shell-root tab-memory feature (D-14), not a bug"
  - "D-02/D-04's fixed uniform 850x860 frame was superseded at the render gate by user request: per-tab dynamic proportions following the Caelestia scheme (wider/shorter baseline, frame animates on Motion.standardDuration/standardEasing to each tab's advisory implicit size). D-04's literal 'no tab may declare an implicit size' prohibition is deliberately reversed for this plan only, replaced by the new invariant that the pane's actual geometry is still anchors.fill-driven — only the frame-sizing metadata is per-tab"
  - "Width is shared across panes at any single instant — this is a SwipeView/Container structural constraint, not a design choice. The shared value itself changes over time as the active tab changes; genuinely unequal SIMULTANEOUS pane widths were deliberately NOT built and were flagged to the user, who accepted this for now"
  - "Per-tab placeholder implicitWidth/implicitHeight values on the four tab stubs are engineering estimates only, not measured content sizes. The four wave-3 content plans (14-04..14-07) and the wave-4 plan (14-08) must derive real sizes from real built content, not inherit these placeholder numbers as if they were final"

patterns-established:
  - "Non-interactive crossfade verification pattern for surfaces where interactive testing would steal window focus: hold the surface open via IPC (hyprctl -j layers to confirm the same surface address/geometry before and after), drive the theme pipeline directly from a shell (not through the picker UI), diff before/after screenshots, and confirm the log shows zero new lines rather than assuming absence-of-new-lines is itself an error — this repo's Colours.qml FileView/JsonAdapter re-themes via live property binding with no quickshell restart and no log line, which is the expected, previously-established (Phase 12, D-13/QS-04) behavior, not a silent failure"

requirements-completed: [DASH-02]

coverage:
  - id: D1
    description: "modules/dashboard/ module surface: one checked-in qmldir registering nine types, each carrying the D-41 widgetState register"
    requirement: "DASH-02"
    verification:
      - kind: unit
        ref: "Task 1 <automated> verify block (bidirectional qmldir/file registration loop, D-41 register presence, no hex/implicit-size violations) — exit 0, echo OK"
        status: pass
    human_judgment: false
  - id: D2
    description: "Four-tab pager: TabBar header + SwipeView, one-way sync, swipe-tracking indicator, drag-threshold commit with spring-back, clamped arrow keys, Motion.standardDuration-driven transition timing"
    requirement: "DASH-02"
    verification:
      - kind: unit
        ref: "Task 2 <automated> verify block (source assertions for highlightMoveDuration token binding, hex-literal absence, PathView/Material absence, keyNavigationEnabled false, Left/Right handlers present, dashboardTabIndex/drawerOpen wiring present, motion-lint exit 0, hyprctl -j layers h==860 at commit time) — exit 0, echo OK"
        status: pass
      - kind: manual_procedural
        ref: "Task 2 human-check: drag-and-hold indicator tracking, release-past-threshold commit, release-below-threshold spring-back — performed live during Task 2 execution"
        status: pass
    human_judgment: false
  - id: D3
    description: "Render-gate round 2 sign-off: per-tab dynamic proportions read right, resize animation is smooth, indicator tracks correctly during resize"
    verification:
      - kind: manual_procedural
        ref: "Render-gate round 2 human response, 2026-07-29: '1- proportions are better now / 2- resize animation is smooth / 3- indicator is resizing correctly'"
        status: pass
    human_judgment: true
    rationale: "Visual feel and proportion judgment on a live desktop surface — not mechanically verifiable, requires the human who requested the revision to confirm it reads as intended."
  - id: D4
    description: "Theme crossfade with the drawer held open: drawer re-themes correctly, stays open, and the log shows no errors across a real theme-apply run"
    verification:
      - kind: automated_ui
        ref: "Executor close-out session, 2026-07-29: hyprctl -j layers confirmed the quickshell-dashboard surface (same address 0x561313d76640) unchanged across dracula -> nord -> dracula; grim screenshots /tmp/theme-crossfade-test/{before-dracula,after-nord,restored-dracula}.png visually confirm full re-theme (header, indicator, tab bar, waybar, notification toast); quickshell.log line count and tail both unchanged/error-free across both theme-apply invocations (exit 0 each); current-theme state file restored to dracula (original value) after the test"
        status: pass
    human_judgment: false
  - id: D5
    description: "Tab-memory behavior (reopens on last tab shown) is the intended shell-root tab-memory feature, not a defect"
    verification:
      - kind: manual_procedural
        ref: "Render-gate round 2 human response, 2026-07-29: explicit decision to KEEP tab memory as-is after being told it is the D-14 shell-root feature working as designed"
        status: pass
    human_judgment: true
    rationale: "A behavior/intent ratification, not a mechanically checkable property — the human's decision itself is the artifact."

duration: multi-session (render-gate round 1, revision, render-gate round 2, crossfade close-out)
completed: 2026-07-29
status: complete
---

# Phase 14 Plan 03: The Pager — TabBar Header, Four-Pane SwipeView, Dynamic Proportions Summary

**Four-tab drawer pager (TabBar + SwipeView, one-way synced, Motion-token-driven timing) plus per-tab dynamic Caelestia-style proportions revised in at the render gate, closed after a non-interactive theme-crossfade proof the human could not run interactively.**

## Performance

- **Duration:** multi-session (three tasks, two render-gate rounds, one revision pass, one executor-driven close-out verification)
- **Tasks:** 3 (Task 1 auto, Task 2 auto, Task 3 checkpoint:human-verify — plus an unplanned revision commit between render-gate rounds)
- **Files modified:** 13 across three commits (10 created, 3 modified)

## Accomplishments

- Laid down the whole `modules/dashboard/` module surface in one commit: nine registered types (four tab shells, three non-visual `Scope` backends, two visual component stubs), every one carrying the D-41 `widgetState` register and zero hex/raw-motion literals
- Built the real pager: `TabBar` header with icon+label per tab over a four-pane `SwipeView`, one-way synced (pager is sole source of truth), `highlightMoveDuration` bound to `Motion.standardDuration` instead of Qt's stock `250` literal, a continuously-tracking swipe-progress indicator, clamped (non-wrapping) arrow keys, and shell-root tab memory across dismiss/re-summon
- Mounted every shared instance wave-3 needs (`mediaBackendInstance`, `weatherBackendInstance`, `SystemResources`) so 14-04 through 14-07 each touch exactly one file
- Revised the frame from a fixed uniform 850x860 to per-tab dynamic proportions (Caelestia scheme) after render-gate round 1 feedback, animating drawer size to each tab's advisory implicit geometry over the same Motion tokens the pager already uses
- Closed render-gate round 2 with full approval (proportions, resize smoothness, indicator-during-resize) and an explicit human ratification that shell-root tab memory is intended behavior, not a bug
- Verified the one item the human could not test interactively — theme crossfade with the drawer open — non-interactively: held the drawer open via IPC, ran `theme-apply` to `nord` then back to `dracula` from the executor's own shell, captured before/after screenshots, confirmed a clean re-theme with the surface staying open the whole time and zero new `quickshell.log` lines, and restored the user's original theme

## Task Commits

Each task was committed atomically:

1. **Task 1: The `modules/dashboard/` module surface** — `a1a022a` (feat) — qmldir + nine stubs, `motion-lint` 75/0
2. **Task 2: The pager** — `c1ba640` (feat) — TabBar/SwipeView/indicator/arrows/tab-memory, one live-found binding-loop deviation fixed inline (Rule 1)
3. **Task 3 revision: per-tab dynamic proportions** — `1d2491a` (feat) — render-gate round 1 feedback applied; superseded D-02/D-04's uniform-frame acceptance criterion by explicit user request

**Plan metadata:** (this commit) — SUMMARY, STATE.md, ROADMAP.md

_Note: the plan's Task 3 was a `checkpoint:human-verify` gate, not a code task — its two rounds and the intervening revision commit are documented in the render-gate history below rather than as a numbered fourth commit._

## Files Created/Modified

- `quickshell/.config/quickshell/modules/dashboard/qmldir` - module `qs.modules.dashboard`, nine registrations, frozen for wave 3
- `quickshell/.config/quickshell/modules/dashboard/{DashboardTab,MediaTab,PerformanceTab,WeatherTab}.qml` - tab shells; D-41 register; property contracts for wave-3; now also carry per-tab advisory `implicitWidth`/`implicitHeight` estimates (D-04 reversed by the revision commit)
- `quickshell/.config/quickshell/modules/dashboard/{MediaBackend,WeatherBackend,SystemResources}.qml` - non-visual `Scope` backends, `drawerOpen` lifecycle gate, zero idle footprint in stub form
- `quickshell/.config/quickshell/modules/dashboard/{QuickToggles,Dial}.qml` - visual component stubs, unmounted this plan
- `quickshell/.config/quickshell/modules/Dashboard.qml` - TabBar header, SwipeView pager, swipe-progress indicator, clamped arrows, tab-index constants, dynamic drawer sizing with animated resize
- `quickshell/.config/quickshell/shell.qml` - `dashboardTabIndex` shell-root memory, `mediaBackendInstance`/`weatherBackendInstance` mounts bound to loader active state
- `.planning/phases/14-dashboard-drawer/deferred-items.md` - logged one unrelated pre-existing `quickshell-doctor` FAIL (QS-03 headless-hotplug territory), out of this plan's scope

## Decisions Made

See `key-decisions` in frontmatter. In prose:

- The render gate ran twice. Round 1 raised mixed feedback across four dimensions (proportions, resize smoothness, indicator-during-resize, and an inability to test theme crossfade interactively) plus a question about tab-memory behavior. The proportions/resize/indicator concerns drove the `1d2491a` revision (per-tab dynamic sizing, Caelestia scheme). Round 2 approved all three revised items explicitly ("proportions are better now", "resize animation is smooth", "indicator is resizing correctly").
- Tab memory was questioned, then explicitly ratified as intended (D-14 shell-root memory, not a defect) — recorded as a user-decided behavior for future plans to respect, not silently assumed.
- The one item round 2 still could not close interactively — theme crossfade, because switching themes steals window focus from the drawer — was handed to this close-out session for non-interactive verification (see below), rather than left unverified.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed a live-found QML binding-loop warning during Task 2**
- **Found during:** Task 2 (pager construction)
- **Issue:** Binding `TabButton` width directly to `tabBar.width` produced a genuine binding-loop warning — `TabBar`'s own `Control.implicitWidth` fed back through the `Row` `contentItem`'s implicit-size computation.
- **Fix:** Derived tab-button width from the wrapping header `Item`'s width instead of `tabBar.width`, and overrode `TabBar`'s own `contentItem` with a plain `Row`+`Repeater` rather than leaving the stock `ListView`-based contentItem (Fusion-style on this Qt build) in place.
- **Files modified:** `quickshell/.config/quickshell/modules/Dashboard.qml`
- **Verification:** Zero binding-loop/error lines in `quickshell.log` after the fix, across a full live summon/tab-cycle/dismiss round-trip.
- **Committed in:** `c1ba640` (Task 2 commit)

**2. [Rule 1 - Bug] Fixed a second binding-loop introduced by the proportions revision**
- **Found during:** Task 3 revision pass (per-tab dynamic proportions)
- **Issue:** Once `header.width` became a per-frame animated value (frame now resizes per tab), `TabBar`'s default `implicitWidth` computation started tripping Qt's binding-loop detector again, round-tripping through the `Row`/`TabButton` content machinery.
- **Fix:** Overrode with a direct, non-cyclical `implicitWidth: header.width` mirror — `TabBar`'s implicit size was never consumed for actual layout (real geometry always comes from `anchors.fill`), so this changes nothing visible.
- **Files modified:** `quickshell/.config/quickshell/modules/Dashboard.qml`
- **Verification:** Live-verified via `hyprctl -j layers`: all four tabs produce distinct, correct geometry; `quickshell.log` free of binding-loop/error lines across full forward/back tab navigation and a motion-scale sweep (off/reduced/normal/lively).
- **Committed in:** `1d2491a` (render-gate revision commit)

**3. [Rule 4-adjacent, user-directed] D-02/D-04's uniform fixed frame superseded by explicit user request**
- **Found during:** Render-gate round 1
- **Issue:** Not a bug — a deliberate architectural revision requested by the human after seeing the fixed 850x860 frame live: wider/shorter baseline, genuine per-tab dynamic proportions following the Caelestia dashboard's content-driven sizing convention.
- **Fix:** `drawerWidth`/`drawerHeight` now read the active tab's advisory `implicitWidth`/`implicitHeight` and animate to it via `Behavior` on `Motion.standardDuration`/`standardEasing`. `drawerMinWidth`/`drawerMinHeight` floor the frame so the header always has room for four tabs. This is recorded as a user-directed decision (not a Rule 1-4 auto-fix in the mechanical sense) because it changes an acceptance criterion the plan had originally locked (D-04's "identical frame height on all four tabs"), superseded openly at the render gate rather than silently reinterpreted.
- **Files modified:** `quickshell/.config/quickshell/modules/Dashboard.qml`, `quickshell/.config/quickshell/modules/dashboard/{DashboardTab,MediaTab,PerformanceTab,WeatherTab}.qml`
- **Verification:** Live-verified via `hyprctl -j layers`: Dashboard 1008x572, Media 948x532, Performance 1048x472, Weather 1068x512 — four distinct, correct geometries; arrow-key clamping still holds at both ends; dismiss/re-summon tab memory still holds; waybar's reserved zone unchanged across summon/dismiss; `motion-lint` clean on every touched file.
- **Committed in:** `1d2491a`

---

**Total deviations:** 3 (2 Rule-1 binding-loop bug fixes, 1 user-directed architectural revision recorded openly rather than silently reinterpreted)
**Impact on plan:** Both binding-loop fixes were necessary correctness fixes with no scope creep. The proportions revision changes one of the plan's own locked acceptance criteria (D-04's uniform-frame-height truth) — this is recorded explicitly here and in STATE.md decisions rather than treated as if the original plan's truth still holds.

## Issues Encountered

**Theme crossfade could not be verified interactively.** The human reported at render-gate round 2 that switching themes via the walker picker steals window focus from the drawer, making it impossible to judge the crossfade while holding the drawer open. Resolved by verifying it non-interactively as part of this close-out session:

1. Recorded the pre-test canonical theme state: `~/.local/state/theme/current-theme` = `dracula`.
2. Summoned the drawer via `hyprctl dispatch 'hl.dsp.global("quickshell:dashboard")'` (the corrected Lua-config dispatch form, per `14-01-SUMMARY.md`'s flagged fix — the plan's own `<automated>` blocks still carry the stale, non-working `hyprctl dispatch global quickshell:dashboard` syntax).
3. Captured `hyprctl -j layers` geometry and a `grim` screenshot (`/tmp/theme-crossfade-test/before-dracula.png`) with the drawer open on the Media tab, Dracula palette.
4. Ran `~/.config/theme-engine/theme-apply nord` directly from the executor's shell (exit 0). Re-checked `hyprctl -j layers`: same surface address (`0x561313d76640`), same geometry — the drawer never closed or restarted. Captured `after-nord.png`: full re-theme visible (header, tab bar, indicator, waybar, and a "Theme Applied — Switched to nord" toast), drawer still open on the same tab.
5. Checked `~/.cache/quickshell.log`: line count and tail unchanged, zero new error/warning lines. This is expected, not a red flag — Phase 12's D-13/QS-04 finding already established that `Colours.qml`'s `FileView`/`JsonAdapter` re-themes via live property binding with zero `reload.sh` involvement and no quickshell restart, so a pure color-token change produces no log line at all, only a visual change.
6. Ran `~/.config/theme-engine/theme-apply dracula` to restore (exit 0). Re-checked geometry (unchanged, same surface) and captured `restored-dracula.png` — visually confirms the original Dracula palette is back.
7. Dismissed the drawer (`hyprctl -j layers` confirms empty after dismiss) and confirmed `~/.local/state/theme/current-theme` reads `dracula` again, matching the pre-test value.

**Result: PASS.** The drawer crossfades correctly with no restart, no close, and no error while a real theme-apply runs underneath it.

Screenshots retained at `/tmp/theme-crossfade-test/{before-dracula,after-nord,restored-dracula}.png` (not committed — `/tmp` is outside the repo; this is throwaway verification evidence, not a shipped artifact).

One incidental observation, not a defect: `~/.cache/current-theme` (a separate, apparently unused/stale cache file distinct from the canonical `~/.local/state/theme/current-theme`) read `catppuccin` both before and after this test and was not touched by it — pre-existing, out of this plan's scope, not investigated further.

## Known Stubs

- All four tab panes (`DashboardTab`, `MediaTab`, `PerformanceTab`, `WeatherTab`) render only their D-41 empty-state placeholder line ("not built yet — plan 14-0X") — this is the plan's explicit, intended scope (frame and contracts only; content is wave 3/4's job) and is not a defect.
- Per-tab `implicitWidth`/`implicitHeight` values added in the revision commit are engineering estimates, not measured real-content sizes. Flagged explicitly for 14-04 through 14-08: derive real sizes from real built content rather than inheriting these placeholder numbers as final.
- `QuickToggles.qml` and `Dial.qml` are unmounted stubs — 14-04 and 14-06 mount and fill them respectively; not a gap in this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `modules/dashboard/` is a real, frozen module surface: wave-3 plans (14-04, 14-05, 14-06, 14-07) can each touch exactly one owned file plus the shared instances this plan already mounted, without colliding with each other or needing to touch `Dashboard.qml`, `shell.qml`, or `qmldir`.
- The pager's frame is no longer uniform across tabs — it is per-tab dynamic and animates on the same Motion tokens as everything else. Wave-3 and wave-4 plans must replace the placeholder `implicitWidth`/`implicitHeight` estimates on their own tab with real values once their content is built, not treat the current numbers as load-bearing.
- Theme crossfade is proven correct on the live pager+header combination — no follow-up needed there.
- One pre-existing, unrelated `quickshell-doctor` FAIL (QS-03 headless-hotplug territory) remains logged in `deferred-items.md`, not owned by this plan.

---
*Phase: 14-dashboard-drawer*
*Completed: 2026-07-29*
