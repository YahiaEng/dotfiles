---
phase: 16-workspace-overview
plan: 02
subsystem: ui
tags: [quickshell, qml, hyprland, wlr-layer-shell, screencopy, wayland-toplevel-management]

# Dependency graph
requires:
  - phase: 16-workspace-overview
    provides: "16-01's live-verified OVER-03 dispatch selector, ONDEMAND-SUFFICIENT keyboard focus posture, and DECLARATIVE-LOADS Qt drag verdict (used to confirm this plan's layer posture choices, not re-derived)"
  - phase: 11-quickshell-viability-gate
    provides: "D-43 layer posture (Overlay/OnDemand/HyprlandFocusGrab), the proven ToplevelManager -> Repeater -> ScreencopyView capture pattern (ScreencopyProbe.qml)"
  - phase: 14-dashboard-drawer
    provides: "LazyLoader summon mechanism, GlobalShortcut/IpcHandler declared-manifest pattern, PanelDialog/Design/Colours singleton conventions"
provides:
  - "The full-screen quickshell-overview surface: one live-thumbnail tile proving OVER-01/OVER-02 end-to-end (Super+O -> layer surface -> workspace model -> per-window live capture -> click-to-focus-and-close -> destroy-on-dismiss)"
  - "MANDATORY pattern for every later plan in this phase that renders toplevels: Hyprland.refreshToplevels() on Component.onCompleted — lastIpcObject starts empty for windows created after initial sync and never repopulates on its own"
  - "MANDATORY pattern for every ScreencopyView instance: constraintSize must be set to the target item's size — it paints at native/source resolution when only anchors.fill is set"
  - "Evidence-backed confirmation that concurrent per-toplevel screencopy works (multiple simultaneous hasContent=true streams with distinct sourceSize) — the load-bearing assumption under 16-03's eleven tiles and 16-08's fifteen-stream measurement is no longer an assumption"
  - "quickshell-overview blur closed: exact-match blur=false layer rule, operator-mandated no further blur changes for the rest of this phase"
  - "The verification-methodology lesson: model-level IPC counts (windows=N) do not prove pixels are painted — plan 16-04's D-16-23 check 6 must assert something that can actually catch a paint/geometry defect, not just non-zero counts"
affects: [16-03-grid-and-scratchpad, 16-04-doctor-checks-and-permissions, 16-05-window-click-parity, 16-06-drag-and-drop, 16-07-click-and-keyboard, 16-08-perf-measurement]

actuals:
  tokens: 6406
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Hyprland.refreshToplevels() on Component.onCompleted for any surface rendering live toplevel geometry — lastIpcObject is NOT auto-populated for windows created after Quickshell's initial sync"
    - "ScreencopyView always needs constraintSize: Qt.size(target.width, target.height) — anchors.fill alone only sizes the item's hit-test bounds, not the painted texture scale"
    - "Per-namespace Hyprland layer_rule exact-match overrides the family regex rule for the same property (blur=false for quickshell-overview overrides the ^quickshell-.* family's blur=true) — same mechanism already established for ignore_alpha overrides (wleave)"
    - "workspace as a WorkspaceTile property (not an internal Hyprland.focusedWorkspace read) — lets later plans instantiate many tiles against different workspaces without touching the type"

key-files:
  created:
    - quickshell/.config/quickshell/modules/Overview.qml
    - quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml
    - quickshell/.config/quickshell/modules/overview/qmldir
  modified:
    - quickshell/.config/quickshell/modules/qmldir
    - quickshell/.config/quickshell/shell.qml
    - quickshell/.config/quickshell/shortcuts.json
    - hypr/.config/hypr/config/keybinds.lua
    - hypr/.config/hypr/config/windowrules.lua

key-decisions:
  - "Blur strength is architecturally global (LayerRule's only blur field is a boolean — hl.meta.lua line 551; decoration.blur.size/passes/etc. has no per-layer override). 'Turn it down' has exactly one honest answer for this architecture: off. Pulled D-16-06's own pre-authorized fallback lever #1 (exact-match blur=false for quickshell-overview only) rather than chasing an alpha value that either does nothing (above the family ignore_alpha=0.5 floor) or silently disables blur outright (below it, reproducing ags-media's own already-documented mistake)."
  - "Operator directive, binding for the rest of Phase 16: do not touch the global blur setting again. quickshell-overview's backdrop is a plain 0.45-alpha tint with no compositor blur, settled."
  - "Model-level counts are not proof of painted pixels. Two defect fixes (constraintSize alone, then a first blur-alpha attempt) shipped false passes verified only by screenshot/IPC-count; the real multi-window root cause (lastIpcObject staleness) was found only with a temporary per-delegate measurement verb reporting raw geometry inputs, computed geometry, and capture state together. That diagnostic verb was removed after use — it returned window titles over the IPC socket, conflicting with T-16-06's threat mitigation — but the lesson and the required pattern are recorded here for every later plan."

requirements-completed: [OVER-01, OVER-02]

coverage:
  - id: D1
    description: "Super+O opens a full-screen quickshell-overview layer surface on the focused monitor; a second press (or Esc, or click-outside) closes it, destroying the wl_surface on every dismissal path"
    requirement: "OVER-01"
    verification:
      - kind: manual_procedural
        ref: "Task 3 render gate — operator confirmed live on their desktop (round 2, approved)"
        status: pass
      - kind: automated_ui
        ref: "hyprctl layers -j / hyprctl monitors -j reserved-array summon-and-diff, run in Task 1's <verify> block"
        status: pass
    human_judgment: true
    rationale: "Whether thumbnails read as genuinely live (not frozen/grey) is a visual judgment call — standing constraint 1 requires the human render-and-look gate for every visual surface, and this exact defect (only one window visibly painted) survived two automated/screenshot-based checks before being caught by the operator's own eyes."
  - id: D2
    description: "Every window on the focused workspace renders as its own live, correctly-scaled ScreencopyView thumbnail at real hyprctl-clients geometry, non-overlapping and distinct"
    requirement: "OVER-01"
    verification:
      - kind: manual_procedural
        ref: "Task 3 render gate round 2 — operator confirmed live with 3+ real windows"
        status: pass
      - kind: other
        ref: "Temporary per-delegate IPC measurement (x/y/width/height/hasContent/sourceSize), reproduced with the exact freshly-spawned-window sequence that broke it, showing correct non-overlapping geometry and 32-key lastIpcObject for every delegate"
        status: pass
    human_judgment: true
    rationale: "This exact deliverable is what shipped two false passes before the real fix — human confirmation on the live desktop is the only check in this plan's history that has actually caught the defect class correctly."
  - id: D3
    description: "Clicking a tile's empty area focuses that workspace and dismisses the overview in the same gesture"
    requirement: "OVER-02"
    verification:
      - kind: manual_procedural
        ref: "Task 3 render gate — operator confirmed click-to-focus-and-close"
        status: pass
    human_judgment: false
  - id: D4
    description: "overview IPC status verb (toggle/status) reports live tile/window/withContent counts; keybind-doctor and quickshell-doctor coexistence gates pass with the new chord and namespace"
    verification:
      - kind: automated_ui
        ref: "keybind-doctor exit 0 (14/0); quickshell-doctor --no-headless-output 15/0 before and after adding the overview manifest entry (QSD_FIXTURE_SHORTCUTS_MANIFEST seam, no live-session disruption); busctl single-Notifications-owner and dashboard-teardown coexistence checks"
        status: pass
    human_judgment: false

duration: multi-session (API session-limit interruption mid-plan, resumed same day)
completed: 2026-08-03
status: complete
---

# Phase 16 Plan 02: The Tracer Summary

**Super+O opens a full-screen `quickshell-overview` layer surface showing every window on the focused workspace as its own live, correctly-scaled `ScreencopyView` thumbnail — proven end-to-end after two false-pass defect fixes were caught by the operator and traced to their real root causes with a per-delegate measurement instead of screenshots.**

## Performance

- **Duration:** multi-session (an API session-limit interruption occurred mid-plan; resumed same day with full context preserved via the coordinator's handoff)
- **Completed:** 2026-08-03
- **Tasks:** 3 (1 tracer + 1 auto + 1 checkpoint:human-verify)
- **Files modified:** 8 (3 created, 5 modified)

## Accomplishments

- OVER-01 and OVER-02 both demonstrated true end-to-end on a thin, production-quality slice: Super+O → Hyprland Lua bind → declared shortcut manifest → shell root `LazyLoader` → full-screen `quickshell-overview` layer surface → `Hyprland.focusedWorkspace` → that workspace's `toplevels` → one live `ScreencopyView` per window at real scaled geometry → click to focus the workspace and close → destroy-on-dismiss.
- Found and fixed two real render-gate defects the hard way — the first fix (`constraintSize`) was real but incomplete, and a follow-up alpha tweak for a second defect was actively wrong (silently disabled blur) — both caught by the operator's own eyes after automated/screenshot verification had already claimed success twice.
- Root-caused the persistent multi-window defect with a temporary per-delegate IPC measurement verb (not a third screenshot): `HyprlandToplevel.lastIpcObject` starts as an empty object for windows created after Quickshell's initial sync and never repopulates without an explicit `Hyprland.refreshToplevels()` call — the same lag `shell.qml`'s own `fullscreenBlocking` guard already documents elsewhere in this repo, now confirmed to apply here too.
- Directly refuted, with evidence rather than assumption, the hypothesis that concurrent per-toplevel screencopy might not work on this build — every delegate reported `hasContent=true` with distinct, correct `sourceSize` values simultaneously. This was the load-bearing open question under 16-03's eleven-tile grid and 16-08's fifteen-stream performance measurement.
- Closed the backdrop-blur question for the rest of the phase: blur strength is architecturally global (no per-surface intensity knob exists at all), so "too strong" has exactly one real fix — an exact-match `blur = false` override for this namespace, operator-confirmed and now off-limits to revisit.

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end tracer** (`type="tracer"`) - `2bfa947` (feat)
2. **Task 2: Prove the new chord and namespace coexist** - *(no commit — zero file diff; both `keybind-doctor` and `quickshell-doctor` passed unmodified against the new manifest entry, and the dashboard `LazyLoader`'s state stayed consistent through the focus-grab handoff with no `shell.qml` fix needed)*
3. **Task 3: Render gate** (`type="checkpoint:human-verify"`, `gate="blocking"`) - approved on the second round; no file changes of its own

**Fixes committed between the render-gate rounds** (Task 1's tracer feedback gate and Task 3 both surfaced real defects — see Deviations):

- `2a5f221` (fix) - scale `ScreencopyView` into its tile via `constraintSize`
- `527c09d` (fix) - disable family blur for `quickshell-overview`, retune scrim
- `7756d61` (fix) - refresh Hyprland toplevels on summon (the real multi-window root cause)

**Plan metadata:** (this commit)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/Overview.qml` - the full-screen surface: layer posture, scrim (no blur, 0.45 alpha), focus grab, dismissal, `Hyprland.refreshToplevels()` on open, thumbnail-count aggregation
- `quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml` - one workspace's live thumbnails: real-geometry `Repeater` over `workspace.toplevels`, `constraintSize`-scaled `ScreencopyView` per window, whole-tile click target
- `quickshell/.config/quickshell/modules/overview/qmldir` - module manifest for the new `overview/` subdirectory (live through the existing whole-directory stow symlink, no `stow.sh` change)
- `quickshell/.config/quickshell/modules/qmldir` - registers `Overview 1.0 Overview.qml`
- `quickshell/.config/quickshell/shell.qml` - `overviewLoader` (`LazyLoader`), `toggleOverview()` (deliberately consults no fullscreen guard, per D-16-19), `overviewShortcut` (`GlobalShortcut`), `overviewIpc` (`IpcHandler`: `toggle()`/`status()`)
- `quickshell/.config/quickshell/shortcuts.json` - fifth manifest entry, `SUPER O`
- `hypr/.config/hypr/config/keybinds.lua` - `Super+O` bind, joins the existing `quickshell:` block
- `hypr/.config/hypr/config/windowrules.lua` - `quickshell-overview` `fade` animation rule (D-16-24) + exact-match `blur = false` override

## Decisions Made

- **Blur strength cannot be adjusted per-surface — confirmed from `hl.meta.lua`, not assumed.** `LayerRule`'s only blur-related field is a boolean (`blur?: boolean`); every `decoration.blur.*` intensity knob is a single global compositor setting. Pulled D-16-06's own pre-authorized fallback lever #1 (exact-match `blur = false` for `quickshell-overview`) rather than lowering scrim alpha, which either does nothing (above the family `ignore_alpha = 0.5` floor) or silently disables blur entirely (below it — reproduces `ags-media`'s own already-documented failure mode in this same file). **Operator directive: blur is settled, do not touch it again for the rest of this phase.**
- **`Hyprland.refreshToplevels()` on `Component.onCompleted` is now a required pattern, not optional polish.** `lastIpcObject` genuinely starts empty (`{}`, not null) for any toplevel created after Quickshell's own initial sync and does not repopulate on its own — proven by waiting 4+ seconds inside one still-summoned session with zero change. Every later plan in this phase that renders toplevel geometry (16-03's grid, 16-05's click parity, 16-06's drag, 16-07's keyboard model) inherits this requirement identically.
- **`constraintSize` is required on every `ScreencopyView`, not optional.** `anchors.fill: parent` alone only sizes the item's hit-test bounds; without an explicit `constraintSize: Qt.size(target.width, target.height)`, the view paints its captured buffer at native/source resolution, relying on an ancestor's `clip: true` to crop the overflow rather than genuinely scaling down.
- **Concurrent per-toplevel screencopy is confirmed working, not assumed.** Multiple simultaneous `ScreencopyView` instances all reported `hasContent = true` with correct, distinct `sourceSize` values throughout — this was the single most consequential open question for the rest of the phase (16-03's eleven tiles, 16-08's fifteen-stream measurement), and it is now evidence-backed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `ScreencopyView` painted at native resolution instead of scaling into its tile**
- **Found during:** Task 3 render gate, round 1 (operator: "Only shows the current window")
- **Issue:** `WorkspaceTile.qml`'s delegate set only `anchors.fill: parent` on its `ScreencopyView`. The property that actually controls the painted scale — `constraintSize` (present in the qmltypes specifically "for scaling the capture into a tile", per 16-RESEARCH.md Q1) — was never set, so with 3+ windows open the largest/nearest window's unscaled capture visually swallowed the whole tile.
- **Fix:** `constraintSize: Qt.size(windowDelegate.width, windowDelegate.height)`.
- **Files modified:** `quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml`
- **Verification:** Screenshot pixel-crop comparison at the time appeared to confirm the fix (it was real, but incomplete — see deviation 3).
- **Committed in:** `2a5f221`

**2. [Rule 1 - Bug] Backdrop blur read as too strong on a full-screen surface**
- **Found during:** Task 3 render gate, round 1 (operator: "the blur is too strong")
- **Issue:** 16-UI-SPEC.md's recommended 0.55 scrim alpha (already lower than the panels' 0.78) still read as heavy at full-screen scale — a genuine ~5x larger blurred region than any panel this shell has drawn before (D-16-06's own named risk). A first attempt lowered the scrim alpha to 0.35, which was **wrong**: 0.35 sits below the family `^quickshell-.*` `ignore_alpha` floor (0.5), which does not soften blur — it silently disables it, producing raw unblurred transparency (`ags-media`'s own already-documented past mistake in `windowrules.lua`, reproduced firsthand rather than assumed).
- **Fix:** Confirmed via `hl.meta.lua` that `LayerRule`'s blur field is boolean-only (no per-surface intensity control exists at all). Pulled D-16-06's pre-authorized fallback lever #1: exact-match `blur = false` for `quickshell-overview` only (every other `quickshell-*` surface unaffected), then retuned scrim alpha to 0.45 (safe now that `ignore_alpha` is moot without blur).
- **Files modified:** `quickshell/.config/quickshell/modules/Overview.qml`, `hypr/.config/hypr/config/windowrules.lua`
- **Verification:** Screenshot-compared against both the original 0.55 and the broken 0.35 attempt before shipping; operator approved at the round-2 render gate.
- **Committed in:** `527c09d`

**3. [Rule 1 - Bug] Multi-window defect persisted after the `constraintSize` fix — real root cause was `lastIpcObject` staleness**
- **Found during:** Task 3 render gate, round 2 (operator, verbatim: "Super+o still only opens current window" — the second false pass on this exact defect)
- **Issue:** `constraintSize` (deviation 1) fixed a real but separate paint-scale bug; it did not fix the actual persistent defect. Root-caused with a temporary per-delegate IPC measurement (not a third screenshot): `HyprlandToplevel.lastIpcObject` starts as an empty `QVariantMap` (`{}`, not null — confirmed via `Object.keys(ipc).length === 0`) for any toplevel created after Quickshell's initial sync, and never spontaneously repopulates — proven by waiting 4+ seconds inside one still-summoned session with zero change. `WorkspaceTile.qml`'s existing `(ipc && ipc.at) ? ipc.at : [0,0]` guard was firing correctly on that empty object and staying collapsed forever; the missing piece was ever asking Hyprland to repopulate it. Also directly refuted, with the same measurement, the hypothesis that concurrent per-toplevel screencopy might not work — every delegate showed `hasContent=true` with distinct, correct `sourceSize` values simultaneously throughout.
- **Fix:** `Overview.qml` calls `Hyprland.refreshToplevels()` on `Component.onCompleted` (every summon). Re-verified with the exact sequence that reproduced the bug (freshly-spawned windows, summoned immediately, zero settle time): every delegate showed a fully-populated (32-key) `lastIpcObject` and correct, non-overlapping geometry.
- **Files modified:** `quickshell/.config/quickshell/modules/Overview.qml`, `quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml` (guard comment updated to record the confirmed cause)
- **Verification:** Per-delegate IPC measurement (removed after use — see below) plus screenshot corroboration; operator approved at the round-2 render gate.
- **Committed in:** `7756d61`

---

**Total deviations:** 3 auto-fixed (all Rule 1 — bugs found at the render gate, not scope additions)
**Impact on plan:** No scope creep; all three fixes were required for OVER-01's literal wording ("every open window appears as a live thumbnail") to actually hold. The temporary diagnostic IPC verb built to find deviation 3's root cause (per-delegate `x/y/width/height/hasContent/sourceSize`) was deliberately removed before the final commit — it returned window titles over the local IPC socket, which conflicts with T-16-06's threat mitigation (this phase's `overview` verb set is scoped to never return titles, content, or addresses).

## Issues Encountered

**The verification-methodology lesson, carried forward explicitly for plan 16-04:** two consecutive "screenshot-verified live before committing" claims on the exact same defect were wrong, and the model-level IPC count (`windows=N withContent=N`) never caught it either — a check that only proves the *model* has N delegates, never that N are actually *painted*, is blind to exactly this defect class. The real fix was found only once a per-delegate measurement combined raw geometry inputs (`at`/`size`/`lastIpcObject` key count), computed layout (`x`/`y`/`width`/`height`), and capture state (`hasContent`/`sourceSize`) in one reading. Plan 16-04 owns the formal `quickshell-doctor` IPC check (D-16-23 check 6, "an `overview` IPC verb reporting how many tiles have content") — it must assert something that would actually have caught this defect (e.g., cross-checking `windows` against the real toplevel count from `hyprctl clients -j`, or a geometry-sanity check), not merely a non-zero count.

**A live-desktop confound during diagnosis, not a defect:** early reproduction attempts used `kitty --class ... &` spawned as a direct shell child of the agent's own terminal window (itself one of the workspace's windows under test), which triggered Hyprland's `misc:enable_swallow` feature — hiding the parent terminal and reporting it at the child's identical geometry. This produced a misleading "only one window visible" result that was **not** deviation 3's real bug. Corrected by spawning test windows via `hl.dsp.exec_cmd(...)` (Hyprland-launched, not terminal-child) for all subsequent reproduction.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **Plan 16-03** (grid + scratchpad) can instantiate eleven `WorkspaceTile` instances directly — the type takes `workspace` as a property, not an internal read, by design. It must also call `Hyprland.refreshToplevels()` on its own surface's `Component.onCompleted` (or reuse Overview.qml's existing call if the surface structure allows) — this is not optional, every later plan rendering toplevels needs it.
- **Every `ScreencopyView` in every later plan must set `constraintSize`** — confirmed required, not a style preference.
- **16-08's fifteen-stream performance measurement can proceed without first re-verifying that concurrent capture works at all** — that question is now closed with evidence (multiple simultaneous `hasContent=true` streams with distinct `sourceSize`), not open.
- **16-04's D-16-23 check 6 (the formal `overview` IPC status check) must be written to actually catch a geometry/paint defect**, per this plan's own verification-methodology lesson — a bare non-zero `windows` count is insufficient, proven by this plan's own history.
- **Blur is closed for the rest of Phase 16** — `decoration.blur.*` (global) is off-limits by operator instruction; any further per-surface blur tuning must go through the `blur: boolean` layer-rule mechanism only, matching `quickshell-overview`'s own exact-match override.
- D-16-10 (pending/denied per-window capture states), D-16-14 (drag drop-target highlight), and the keyboard model (D-16-15/16/17) are all explicitly out of scope for this tracer and remain for their respective owning plans.

---
*Phase: 16-workspace-overview*
*Completed: 2026-08-03*
