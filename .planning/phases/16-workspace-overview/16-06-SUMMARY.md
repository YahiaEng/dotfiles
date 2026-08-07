---
phase: 16-workspace-overview
plan: 06
subsystem: ui
tags: [quickshell, qml, hyprland, drag-and-drop, screencopy, dispatch-guard]

# Dependency graph
requires:
  - phase: 16-workspace-overview
    provides: "16-01's locked DECISION — OVER-03 move mechanism (selector-confirmed: hl.dsp.window.move({workspace=N, window=\"address:0x...\", follow=false})) and 16-SPIKE-FINDINGS.md's DECLARATIVE-LOADS verdict on Qt's declarative drag API atop a layer-shell surface"
  - phase: 16-workspace-overview
    provides: "16-05's WindowThumbnail.qml three-state capture machine (captureState/settled) — the drag ghost reads it for its pending/failed fallback chrome, and its confirmed HyprlandToplevel.address-omits-0x finding drives this plan's address normalisation before the shape guard"
  - phase: 15-audio-connectivity-panels
    provides: "QuickToggles.qml's lit-tile treatment (interpolated litProgress + Behavior on the standard motion pair, fill/border to Colours.primary) reused verbatim as the drop-target highlight"
provides:
  - "OVER-03 closed: dragging a window thumbnail onto another workspace tile moves that window there, drop target visibly highlighted in flight, overview stays open, focused workspace unmoved (D-16-13)"
  - "The guarded move-dispatch seam in Overview.qml — address normalised to carry 0x then matched against a strict hex shape, workspace token validated as 1..10 or the exact special:magic literal, no client-controlled text ever concatenated (T-16-25) — the exact mechanism plan 16-07's Shift+1..0 keyboard move must reuse, not re-derive"
  - "DragGhost.qml as the third consumer of the general WindowThumbnail representation (liveCapture:false + one captureFrame() per drag) — still no second ScreencopyView instantiation site in modules/overview/"
  - "The single-cancel-path pattern: same-tile drop, gap release, failed validation and mid-drag toplevel destruction all funnel through one cancel animation on the standard pair, so every non-move reads as a deliberate rejection (UI-SPEC E6 error) rather than a dropped input"
affects: [16-07-click-and-keyboard, 16-08-perf-measurement, 16-USE-NOTE]

actuals:
  tokens: 0
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "DECLARATIVE-LOADS confirmed in shipped code, not just the spike: WindowThumbnail.qml carries TapHandler (click) + DragHandler (drag) + the Drag attached property side by side on a layer-shell surface — the declarative input stack coexists with ScreencopyView content."
    - "Drop-target resolution is a geometric hit-test in Overview.qml (mapToItem against each tile's real bounds in the same scene coordinate system DragHandler.centroid.scenePosition reports), not per-tile DropAreas — exactly one tile carries dropTargetActive at any instant; the 24px inter-tile gap targets neither as a property of the layout."
    - "Dispatch-time re-validation: the address shape guard runs at the moment of dispatch, not at drag start, so a toplevel destroyed mid-drag can never be dispatched against — belt (reactive cancel when the address leaves Hyprland.toplevels) plus braces (guard at use)."
    - "Address normalisation at the comparison boundary: HyprlandToplevel.address (no 0x) is normalised to the 0x-prefixed form before the shape check and the dispatch string — applying 16-05's confirmed prefix-mismatch finding rather than rediscovering it."

key-files:
  created:
    - quickshell/.config/quickshell/modules/overview/DragGhost.qml
  modified:
    - quickshell/.config/quickshell/modules/overview/WindowThumbnail.qml
    - quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml
    - quickshell/.config/quickshell/modules/overview/qmldir
    - quickshell/.config/quickshell/modules/Overview.qml

key-decisions:
  - "DragGhost renders a reused WindowThumbnail instance behind a Loader with liveCapture:false and exactly one captureFrame() call per drag — a still snapshot by construction (D-16-12), honouring 16-04's single-capture-path gate rather than instantiating a second capture view."
  - "The move dispatch implements 16-SPIKE-FINDINGS.md's locked selector-confirmed string verbatim (follow=false — D-16-13's silence is delivered, not approximated; the activate-move-restore approximation branch was never needed)."
  - "Every non-move outcome (same-tile no-op, gap release, validation failure, mid-drag destruction) funnels through the one cancel path — no bespoke error UI, no toast; the grid as a live projection of compositor state is the confirmation surface (T-16-29 accepted)."
  - "Rule 3 deviation, recorded in the Task 1 commit: WorkspaceTile.qml was touched in Task 1 despite not being in that task's <files> list — Overview.qml cannot relay drag signals WorkspaceTile.qml does not declare, and the plan's own action text requires relaying through the tile without the tile interpreting them."

requirements-completed: [OVER-03]

coverage:
  - id: D1
    description: "Dragging a window thumbnail onto another workspace tile moves that window to that workspace, silently, with the overview still open and the focused workspace unmoved (OVER-03, D-16-13)"
    requirement: "OVER-03"
    verification:
      - kind: automated_ui
        ref: "Task 2 <verify> block: dropTargetActive/Colours.primary/Motion.standardDuration present, Hyprland.dispatch present, address-shape guard present before dispatch, no title/appId in any dispatch argument, special:magic literal present, zero hex literals; motion-lint 129/0; fresh detached restart with zero QML errors; summon/dismiss cycle tiles=11 windows=3 withContent=3, clean log"
        status: pass
      - kind: manual_procedural
        ref: "Task 3 blocking render gate, approved 2026-08-07: drag lifts with scale+shadow and leaves a gap at the source; drop lands the window in the target tile with the overview still open and the viewed workspace unchanged; multiple moves in one summon; windows confirmed in place after close and re-summon"
        status: pass
    human_judgment: true
    rationale: "No synthetic pointer tool exists on this host (16-05 confirmed: only wtype, keyboard-only), so the four live drag proofs from Task 2's <human-check> were folded into Task 3's render gate and performed by the operator."
  - id: D2
    description: "The drop target is visibly highlighted while the drag is in flight — one tile at a time, using the existing lit-tile idiom (D-16-14)"
    requirement: "OVER-03"
    verification:
      - kind: automated_ui
        ref: "Task 2 <verify> block: WorkspaceTile.qml's dropTargetActive drives the QuickToggles lit-tile shape (interpolated progress, Behavior on the standard pair, fill/border to Colours.primary)"
        status: pass
      - kind: manual_procedural
        ref: "Task 3 render gate step 3, approved: only the hovered tile lights; moving to a third tile un-lights the second as the third lights"
        status: pass
    human_judgment: true
  - id: D3
    description: "A missed drop cancels at zero cost (snapshot animates home on the standard pair); a same-tile drop is a clean no-op that never dispatches"
    requirement: "OVER-03"
    verification:
      - kind: automated_ui
        ref: "Task 1 <verify> block: DragGhost.qml references Motion.standardDuration/standardEasing with no bespoke easing; all non-move outcomes route through the single cancel path (source-visible)"
        status: pass
      - kind: manual_procedural
        ref: "Task 3 render gate step 6, approved: release in the gap between tiles animates the ghost home, nothing moved"
        status: pass
    human_judgment: true
  - id: D4
    description: "Drag works symmetrically into and out of the scratchpad tile — an ordinary member of the workspace-target set, no special case (D-16-05)"
    requirement: "OVER-03"
    verification:
      - kind: manual_procedural
        ref: "Task 3 render gate step 7, approved: drag into the scratchpad tile and back out to a numbered tile, both directions working"
        status: pass
    human_judgment: true
  - id: D5
    description: "No client-controlled text ever reaches the compositor's Lua evaluator (T-16-25); the address is shape-checked at dispatch time"
    requirement: "OVER-03"
    verification:
      - kind: automated_ui
        ref: "Task 2 <verify> block: grep proves the address-shape guard precedes the dispatch and that no dispatch argument concatenates title or appId; the workspace token is drawn from the fixed eleven-slot set and validated as an integer 1..10 or the exact special:magic literal"
        status: pass
    human_judgment: false

duration: two sessions (Tasks 1-2 committed 2026-08-03; Task 3 render gate approved 2026-08-07)
completed: 2026-08-07
status: complete
---

# Phase 16 Plan 06: Drag a Window Between Workspaces Summary

**A window thumbnail can now be picked up out of one workspace tile and dropped into another, and the window actually moves there — still-snapshot ghost with lift and shadow, single lit drop target reusing the shell's existing idiom, silent selector-confirmed dispatch with the overview staying open, one shared cancel path for every non-move, and a strict validation boundary so no client-controlled text can ever reach the compositor's Lua evaluator. The blocking render gate was approved with no change requests.**

## Performance

- **Duration:** two sessions — Tasks 1–2 built and committed 2026-08-03; Task 3's blocking render gate approved by the operator 2026-08-07
- **Completed:** 2026-08-07
- **Tasks:** 3 (2 auto, committed; 1 blocking human-verify checkpoint, approved round 1)
- **Files modified:** 5 (1 created, 4 modified)

## Accomplishments

- `DragGhost.qml` (new, registered in `modules/overview/qmldir`): a reused `WindowThumbnail` instance behind a `Loader` with `liveCapture:false` and exactly one `captureFrame()` call per drag — a still snapshot by construction, per D-16-12. MD3 1.05x lift, `MultiEffect` drop shadow at elevation-3 weight, cancel animation home on `Motion.standardDuration`/`Motion.standardEasing`. Falls back to the thumbnail's own pending/failed placeholder chrome when there is no frame to grab, so dragging a window whose preview never arrived stays permitted.
- `WindowThumbnail.qml` gained the declarative input stack the spike's DECLARATIVE-LOADS verdict cleared: `TapHandler` (click) + `DragHandler` (drag) + the `Drag` attached property, plus `beingDragged` — while true the thumbnail renders as a gap, so the gesture reads as picking something up rather than copying it.
- `Overview.qml` owns the drag session (`dragToplevel`/`dragActive`/`dragPos`) and exactly one `DragGhost`. Drop-target resolution is a geometric hit-test (`mapToItem` against each tile's real bounds, in the same scene coordinate system `DragHandler.centroid.scenePosition` reports) — exactly one tile lights at a time; the 24px gap targets neither.
- `WorkspaceTile.qml` gained `dropTargetActive`, driving the same lit-tile treatment `QuickToggles.qml` established (interpolated progress, `Behavior` on the standard pair, fill/border to `Colours.primary`) — one idiom, not a second minted for drags.
- The move dispatches 16-SPIKE-FINDINGS.md's locked selector-confirmed string verbatim: `hl.dsp.window.move({workspace=N, window="address:0x...", follow=false})`. `follow=false` means D-16-13's silence is delivered outright, not approximated — the focused workspace never moves, and the overview stays open so moving three windows costs one summon.
- The T-16-25 validation boundary shipped as mandated: the address is normalised to carry the `0x` prefix (applying 16-05's confirmed `HyprlandToplevel.address` mismatch finding) then matched against a strict hex shape at dispatch time; the workspace token is validated as an integer 1..10 or the exact `special:magic` literal; no title, appId or any client-supplied string is ever concatenated into a dispatched expression.
- Mid-drag destruction is guarded twice: a reactive cancel when the dragged address leaves `Hyprland.toplevels` (Task 1), plus the dispatch-time shape guard re-validating at the moment of use (Task 2).

## Task Commits

1. **Task 1: Lift a thumbnail into a cursor-following snapshot** — `f0dbce9` (feat)
2. **Task 2: Light the drop target and move the window on drop** — `777d790` (feat)
3. **Task 3: Render gate — does the drag feel like picking a window up?** — *(no commit — blocking human-verify checkpoint, approved 2026-08-07 with no change requests)*

**Plan metadata:** (this commit)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/overview/DragGhost.qml` — **created**; the cursor-following still snapshot: reused-WindowThumbnail-behind-Loader, lift, shadow, cancel animation, pending/failed fallback chrome.
- `quickshell/.config/quickshell/modules/overview/qmldir` — `DragGhost 1.0 DragGhost.qml` registration.
- `quickshell/.config/quickshell/modules/overview/WindowThumbnail.qml` — `TapHandler` + `DragHandler` + `Drag.active`, the three drag signals (`dragStarted`/`dragMoved`/`dragEnded`), `beingDragged` gap rendering.
- `quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml` — drag-signal relay (without interpretation), `dropTargetActive` + lit-tile highlight.
- `quickshell/.config/quickshell/modules/Overview.qml` — drag session state, single `DragGhost` instantiation, geometric drop-target resolution, the guarded selector-confirmed move dispatch, the single cancel path.

## Decisions Made

See `key-decisions` in the frontmatter. Summarised: still-snapshot ghost via the general `WindowThumbnail` representation (no second capture view); selector-confirmed dispatch implemented verbatim with `follow=false` (D-16-13 delivered, not approximated); every non-move outcome funnels through one cancel path (no bespoke error UI, T-16-29 accepted); one recorded Rule 3 deviation (WorkspaceTile.qml touched in Task 1 outside its `<files>` list, structurally unavoidable for the signal relay the plan itself demands).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `WorkspaceTile.qml` touched in Task 1 despite not being in Task 1's `<files>` list**
- **Found during:** Task 1, wiring the thumbnail→overview signal relay.
- **Issue:** The plan's own action text requires relaying the three drag signals "up through `WorkspaceTile` without the tile interpreting them" — impossible without declaring the relay signals on `WorkspaceTile.qml`, which Task 1's `<files>` list omitted (Task 2's list includes it).
- **Fix:** Added the pass-through relay declarations in Task 1's commit, recorded as a deviation in that commit's message.
- **Files modified:** `quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml`
- **Verification:** Task 1's automated verify block passed; the relay carries no interpretation logic, matching the plan's ownership rule (the tile is not the owner of a drag that crosses tiles).

**2. [Rule 3 - Blocking] Stray duplicate quickshell process culled during Task 2's live verification**
- **Found during:** Task 2's fresh-restart check.
- **Issue:** A leftover quickshell process from a launch-without-kill produced two concurrent instances.
- **Fix:** Killed the stray, relaunched via the standing detached form, confirmed a single process with a non-shell parent and a clean log.
- **Files modified:** none (operational only).
- **Verification:** Summon/dismiss cycle reported tiles=11 windows=3 withContent=3 with zero QML errors.

---

**Total deviations:** 2 (both Rule 3, resolved in-flight; neither altered any acceptance criterion or must-have)
**Impact on plan:** No scope creep.

## Issues Encountered

None beyond the recorded deviations. The four live drag proofs from Task 2's `<human-check>` could not be executor-synthesised (no pointer-simulation tool on this host — 16-05 confirmed only `wtype`, keyboard-only) and were folded into Task 3's render gate, which covered the same ground and was approved.

## User Setup Required

None.

## Next Phase Readiness

- **The guarded move dispatch in `Overview.qml` is the seam plan 16-07's `Shift+1..0` keyboard move must call** — same validation boundary, same selector-confirmed string; re-deriving it would duplicate the T-16-25 guard.
- **The planner's two flagged OVER-03 edge assumptions** (same-tile drop as a clean no-op; mid-drag destruction resolving rather than dispatching against a dead address) are both implemented and gate-verified, but remain planner assumptions, not derived criteria — carried into `16-USE-NOTE.md`'s first structured pass for confirmation under real use, per the plan's own flag.
- **Drag-time load held up subjectively at the gate** (no stutter reported), but that is not a measurement — plan 16-08's fifteen-stream measurement against the agreed budget remains the real answer to T-16-28, with the pre-authorised fallback ladder as the response.
- **16-04's deferred Task 3** (live permission-enforcement logout/login + five-consumer proof, deferred-items.md item 0) is still open and now closer to due — the phase has two plans left.

---
*Phase: 16-workspace-overview*
*Completed: 2026-08-07*

## Self-Check: PASSED

- FOUND: quickshell/.config/quickshell/modules/overview/DragGhost.qml
- FOUND: DragGhost 1.0 registration in modules/overview/qmldir
- FOUND: quickshell/.config/quickshell/modules/overview/WindowThumbnail.qml (dragStarted/dragEnded/beingDragged)
- FOUND: quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml (dropTargetActive)
- FOUND: quickshell/.config/quickshell/modules/Overview.qml (single DragGhost, guarded dispatch)
- FOUND: commit f0dbce9 (Task 1)
- FOUND: commit 777d790 (Task 2)
- APPROVED: Task 3 blocking render gate, 2026-08-07, no change requests
