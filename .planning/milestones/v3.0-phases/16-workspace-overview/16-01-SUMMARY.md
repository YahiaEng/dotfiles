---
phase: 16-workspace-overview
plan: 01
subsystem: infra
tags: [hyprland, quickshell, qml, hyprctl-dispatch, screencopy, wlr-layer-shell]

# Dependency graph
requires:
  - phase: 11-quickshell-viability-gate
    provides: "D-43 layer posture (Overlay/OnDemand/HyprlandFocusGrab), QS-02's human-verified click-outside-dismiss combination, the screencopy feasibility mechanism"
  - phase: 13.1-hyprland-lua-config-migration
    provides: "The Lua-expression hyprctl dispatch entry point (hl.dsp.xxx(...)) this plan probes"
provides:
  - "The exact, live-verified dispatch string for a silent, address-targeted window move: hl.dsp.window.move({workspace=N, window=\"address:0x...\", follow=false})"
  - "Confirmation that WlrKeyboardFocus.OnDemand + forceActiveFocus()-on-Component.onCompleted delivers arrow-key input with zero prior click"
  - "Confirmation that DragHandler + Drag attached property + DropArea load without error on a WlrLayer.Overlay PanelWindow"
  - "Confirmation that ScreencopyView captures a toplevel parked on a non-visible workspace"
  - "A disclosed, recovered incident and a load-bearing rule: never issue a selector-less Hyprland dispatch, even when the compositor's active window appears null"
affects: [16-02-grid-and-capture, 16-06-drag-and-drop, 16-07-click-and-keyboard]

actuals:
  tokens: 3955
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Throwaway qs -p harness pattern for live-verifying Quickshell/Hyprland mechanisms before writing production QML — scratchpad-only, deleted, never touches quickshell/.config/quickshell/"
    - "Isolated-probe methodology for hyprctl dispatch spikes: a reset_state() step before every candidate so a prior probe's side effect can never masquerade as evidence for the next candidate"

key-files:
  created:
    - .planning/phases/16-workspace-overview/16-SPIKE-FINDINGS.md
  modified: []

key-decisions:
  - "DECISION — OVER-03 move mechanism: selector-confirmed. hl.dsp.window.move({workspace=N, window=\"address:0x...\", follow=false}) is the exact, one-dispatch, silent move D-16-13 requires — live-verified with an isolated probe matrix and a control probe, not inferred."
  - "Keyboard focus posture ships as WlrKeyboardFocus.OnDemand (no escalation to Exclusive needed) — arrow keys reach the surface via Dashboard.qml's existing forceActiveFocus()-on-Component.onCompleted pattern with zero prior click."
  - "Qt's declarative Drag API (DragHandler/Drag/DropArea) is cleared for use on the overview's layer-shell surface — loads with zero QML errors."
  - "Inactive-workspace capture works with no special handling — D-16-01's ten always-rendered slots need no fallback beyond D-16-10's existing pending/denied states for the off-screen case."

requirements-completed: []

coverage: []

duration: ~25min
completed: 2026-08-03
status: complete
---

# Phase 16 Plan 01: Wave 0 Dispatch/Focus/Drag/Capture Spike Summary

**Live-verified `hl.dsp.window.move({workspace=N, window="address:0x...", follow=false})` as the exact silent window-move dispatch OVER-03 needs, plus three supporting mechanism verdicts (OnDemand keyboard focus, Qt drag API, inactive-workspace screencopy) — no production QML written, one real incident (an accidental live browser close) disclosed and recovered in full.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-08-03
- **Tasks:** 3 (2 `auto` + 1 `checkpoint:decision`)
- **Files modified:** 1 (`16-SPIKE-FINDINGS.md`, created)

## Accomplishments

- Settled OVER-03's dispatch selector against the live compositor: `hl.dsp.window.move({workspace=N, window="address:0x...", follow=false})` moves a named, non-focused window and keeps the compositor's focused workspace unchanged (D-16-13's "silent" requirement, honoured exactly rather than approximated).
- Built one throwaway `qs -p` harness (scratchpad only) that settled three further mechanisms in a single session: keyboard focus posture (`ONDEMAND-SUFFICIENT`), Qt drag API viability (`DECLARATIVE-LOADS`), and inactive-workspace screencopy (`CAPTURES-OFFSCREEN`).
- Operator locked the move mechanism at the Task 3 checkpoint: `selector-confirmed`, matching the plan's own recommendation.
- Found and corrected an implicit API-surface assumption: `HyprlandToplevel` has no `class`/`appId` property — window class must be read from `lastIpcObject["class"]` (bracket notation, since `class` is a reserved word).
- Disclosed and fully recovered a real operational incident (`hl.dsp.window.kill()` closing the live Zen browser instead of the throwaway client) and recorded the underlying rule as a standing constraint for every later dispatch call in this phase.

## Task Commits

Each task was committed atomically:

1. **Task 1: Settle the OVER-03 dispatch selector against the live compositor** - `6ea1edc` (docs)
2. **Task 2: Settle focus posture, Qt drag viability, and inactive-workspace capture on one throwaway layer-shell harness** - `b0416db` (docs)
3. **Task 3: Lock OVER-03's window-move mechanism (checkpoint:decision, operator selected `selector-confirmed`)** - `71b9559` (docs)

**Plan metadata:** (this commit)

## Files Created/Modified
- `.planning/phases/16-workspace-overview/16-SPIKE-FINDINGS.md` - Four `VERDICT —` sections (dispatch selector, keyboard focus posture, Qt drag on layer-shell, inactive-workspace capture) plus `DECISION — OVER-03 move mechanism`, each with full command/output transcripts.

## Decisions Made

- **OVER-03 move mechanism locked as `selector-confirmed`** — the literal dispatch string `hl.dsp.window.move({workspace=N, window="address:0x...", follow=false})` is what plan 16-06's drop handler implements verbatim. Chosen because Task 1's live evidence (isolated probe matrix + a control probe proving the selector was necessary, not incidental) directly confirmed the one-dispatch silent form exists on this build — no reason to fall back to a multi-dispatch activate-then-restore approximation or to ship a documented divergence from D-16-13.
- **Keyboard focus stays `WlrKeyboardFocus.OnDemand`** — no escalation needed. Click-outside dismiss for this posture is recorded as inherited-verified (Phase 11's QS-02 gate + Dashboard.qml's/ScreencopyProbe.qml's daily production use of the identical combination) rather than freshly reproduced, since this host has no pointer synthesizer — flagged explicitly in the findings rather than silently assumed.
- **Qt's declarative Drag API is cleared for the overview's drop handler** — `DragHandler`/`Drag`/`DropArea` load with zero QML errors on the D-43 layer posture; the manual `MouseArea`/hit-test fallback the plan named is not needed. Live drag-gesture behaviour is deferred to a human exercising it directly (no pointer synthesizer on this host).
- **No inactive-workspace fallback needed for capture** — a window on a non-visible workspace produces real `hasContent`/`sourceSize`, so D-16-01's ten always-rendered slots need no special-casing beyond D-16-10's existing pending/denied states.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `HyprlandToplevel` has no `class`/`appId` property — corrected the capture-probe harness's window-matching logic**
- **Found during:** Task 2 (throwaway harness build)
- **Issue:** A first draft of the harness read `t.class`, which silently evaluated to `undefined` for every toplevel (both because `class` is a reserved word requiring bracket-notation property access, and because `HyprlandToplevel`'s real property list — confirmed by reading the installed qmltypes directly — has no `class`/`appId` field at all).
- **Fix:** Read the window class from `t.lastIpcObject["class"]` (the raw `hyprctl clients` JSON map exposed via `HyprlandToplevel.lastIpcObject`), using bracket notation.
- **Files modified:** scratchpad-only (`spike.qml`, never entered the repo)
- **Verification:** Harness log shows `class=kitty ws=2 wayland=yes -> MATCHED` after the fix, versus `class=undefined` before it.
- **Committed in:** `b0416db` (finding documented in `16-SPIKE-FINDINGS.md`'s inactive-workspace-capture VERDICT section; no repo code was affected since the harness is scratchpad-only)

**Total deviations:** 1 auto-fixed (Rule 1, scoped entirely to the throwaway harness — no production code touched)
**Impact on plan:** None on scope; the correction is recorded as a load-bearing API-surface note for plan 16-02+, which will need the same `lastIpcObject["class"]` read pattern for any window-class-based logic.

### Requirements NOT marked complete (deliberate)

The plan's frontmatter lists `requirements: [OVER-01, OVER-03]`, and the standard state-update step calls for marking listed requirements complete. **This was deliberately skipped.** Every plan in this phase from 16-01 through 16-07 lists `OVER-01` and/or `OVER-03` in its own `requirements` frontmatter (16-02 through 16-07 all reference one or both) — this spike plan produces only verification findings, not the shipped grid/drag/click surface either requirement actually describes ("A keybind opens a full-screen grid...", "Dragging a window thumbnail... moves that window, with a hover-highlight"). Marking either complete now would falsely close them in `REQUIREMENTS.md` while six more plans remain to build the features. `REQUIREMENTS.md`'s traceability table is left at `Pending` for both, matching reality; they will be marked complete by whichever later plan in this phase actually ships the corresponding surface.

## Issues Encountered

**One real incident during Task 1, fully disclosed and recovered:**

While restoring the live session to its original state, `hyprctl dispatch "hl.dsp.window.kill()"` was issued to close the throwaway `spike-throwaway` client. It did not target the throwaway — Hyprland's internal "last active window" pointer was still the real Zen browser window (`0x55a754ea02d0`, open before this task began), even though the compositor's focused workspace at that moment was an empty workspace and `hyprctl activewindow -j` had reported `null` moments earlier. `kill()` with no explicit selector closed that Zen process outright.

**Recovery:** Zen (`zen-browser`) was relaunched via `uwsm app -- zen-browser`; its session restore brought back the exact same tab (title byte-identical: "Minecraft Season 3 Start (Part 1) - YouTube — Zen Browser"). The restored window was moved back to workspace 1 using the now-confirmed silent-move dispatch and workspace 1 was refocused — functionally identical to the original layout (same tab, same workspace, same focus), though not byte-identical by PID/window address. The throwaway client was then closed by sending `kill` directly to its PID (read from `hyprctl clients -j`'s `.pid` field), avoiding a repeat of the same mistake.

**Standing rule this incident establishes for the rest of Phase 16 (recorded prominently in `16-SPIKE-FINDINGS.md` and repeated here so it is not lost in a single file's scroll depth):**

> **Never issue a selector-less, destructive Hyprland dispatch** (`kill()`, or any dispatcher relying on the implicit "active window") from Phase 16 QML or from any future live probing in this repo. Hyprland's internal last-focused-window pointer survives a focus-to-empty-workspace transition even when `hyprctl activewindow -j` reports `null` at the moment of the call. Every dispatch this phase's production code issues must carry an explicit `window="address:..."` selector — the same rule the confirmed move dispatch itself already follows.

This is directly relevant to plan 16-06 (drag-drop move dispatch, already scoped to use the selector form) and to any future plan that adds a close/kill affordance to the overview (none currently planned, but the rule applies if one is ever added).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 16-06's drop handler can implement `hl.dsp.window.move({workspace=N, window="address:" + draggedWindow.address, follow=false})` directly — no further verification needed, the string is locked and evidenced.
- The overview's `PanelWindow` can ship `WlrKeyboardFocus.OnDemand` with `forceActiveFocus()` on the content root's `Component.onCompleted` — proven sufficient for keyboard-only summon-and-navigate (D-16-16).
- `DragHandler`/`Drag`/`DropArea` are cleared for OVER-03's drag implementation; no fallback to manual `MouseArea` hit-testing is needed.
- D-16-01's ten-slot grid needs no additional capture fallback for workspaces that are occupied but not currently visible.
- **Open, not a blocker:** live drag-gesture behaviour (actual pointer-driven drag/drop) and `HyprlandFocusGrab` click-outside dismiss under `OnDemand` were not freshly exercised in this spike — this host has no pointer synthesizer. Both are recorded as inherited-verified from prior phases' human-clicked evidence (QS-02, and Dashboard.qml's daily production use) rather than freshly reproduced here; flagged so a later human render-and-look gate (standing constraint 1, already required for this UI-flagged phase) is the first fresh confirmation, not a silent gap.
- `lastIpcObject["class"]` (bracket notation) is the correct read for a toplevel's window class in any plan that needs it — `HyprlandToplevel` has no direct `class`/`appId` property.

---
*Phase: 16-workspace-overview*
*Completed: 2026-08-03*
