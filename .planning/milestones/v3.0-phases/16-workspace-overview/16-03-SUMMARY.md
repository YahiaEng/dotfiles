---
phase: 16-workspace-overview
plan: 03
subsystem: ui
tags: [quickshell, qml, hyprland, wlr-layer-shell, screencopy, wayland-toplevel-management]

# Dependency graph
requires:
  - phase: 16-workspace-overview
    provides: "16-02's proven tracer end-to-end (Super+O -> layer surface -> workspace model -> live capture -> click-to-focus-and-close -> destroy-on-dismiss), and its two MANDATORY patterns: Hyprland.refreshToplevels() on Component.onCompleted, and constraintSize on every ScreencopyView"
  - phase: 14-dashboard-drawer
    provides: "Cascade.qml's row-level stagger runner (D-21), reused verbatim by D-16-24; PanelDialog.qml's Component.onCompleted arming-point shape, mirrored here"
provides:
  - "The complete D-16-01 grid: ten fixed numbered tiles (5x2, mirrors the number row) plus D-16-05's always-present eleventh scratchpad tile, all rendering on every summon regardless of occupancy, at fixed unchanging screen positions"
  - "WindowThumbnail.qml — the single general representation of 'a window drawn small', the ONLY ScreencopyView instantiation site in modules/overview/, with liveCapture as the variant property D-16-07's fallback ladder and D-16-12's drag ghost both reach for later"
  - "Confirmed at eleven tiles, not just one: Hyprland.refreshToplevels() and per-view constraintSize both hold at full grid scale with zero new defects — the tracer's two mandatory patterns generalise cleanly"
  - "D-16-24's three-band row-level entrance cascade (row 1, row 2, scratchpad), reusing D-21's existing stagger/emphasized-in tokens verbatim — motion.json unchanged"
  - "The fixed-slot geometry contract, human-verified stable across repeated summons: tile 7 (and every other slot) renders at the identical pixel position every time — the load-bearing assumption under 16-06's drag-and-drop drop targets"
affects: [16-04-doctor-checks-and-permissions, 16-05-window-click-parity, 16-06-drag-and-drop, 16-07-click-and-keyboard, 16-08-perf-measurement]

actuals:
  tokens: 8005
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "WindowThumbnail.qml is the ONLY ScreencopyView instantiation site in modules/overview/ — enforced as a directory-wide grep count in this plan's own acceptance criteria, and promoted to a quickshell-doctor check by plan 16-04. Any later plan that needs a second capture path must extend this type (e.g. via liveCapture), never add a second ScreencopyView elsewhere."
    - "liveCapture (bool, default true) is WindowThumbnail's variant switch — D-16-07's fallback ladder and D-16-12's drag ghost are both a PROPERTY CHANGE on this type, not a second renderer. D-16-11 bakes exactly one mode (live:true) into the shipped build; liveCapture must never become a user-facing runtime toggle."
    - "isScratchpad on WorkspaceTile changes exactly three things (border colour -> Colours.tertiary, empty-state glyph -> inventory_2, identity overlay content) and nothing else — clipping/geometry/capture/click-to-focus/occupied-split are identical to a numbered tile. This sameness is what plan 16-06 needs for symmetric drag-in/drag-out."
    - "Grid slots are resolved by iterating Hyprland.workspaces.values and matching on id (numbered) or name === 'special:magic' (scratchpad) — Hyprland.workspaces itself is never padded. The slot LIST is the fixed thing (10 ints + one name token); the workspace behind each slot is what may be null."
    - "Cascade bands can be non-tab containers: Overview.qml's three bands (rowOne, rowTwo, scratchpadTile) are wired via the same Component.onCompleted-arm-and-run shape PanelDialog.qml uses (not Dashboard.qml's per-tab-switch runCascadeForActivePane() shape) — the right precedent for any single-content, destroy-on-dismiss surface, not a tabbed one."

key-files:
  created:
    - quickshell/.config/quickshell/modules/overview/WindowThumbnail.qml
  modified:
    - quickshell/.config/quickshell/modules/Overview.qml
    - quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml
    - quickshell/.config/quickshell/modules/overview/qmldir

key-decisions:
  - "WindowThumbnail.qml's geometry arithmetic (at/size, monitor-offset, captureScale) is a straight hoist of the tracer's own proven delegate arithmetic out of WorkspaceTile.qml — no new formula was introduced, only relocated, to avoid re-deriving something 16-02 already fought two false-pass rounds to get right."
  - "The 5x2 grid is a Column of two Rows, not a single Grid element — chosen specifically so each row is an independently addressable top-level Item for Cascade's band list (Task 2 needed this; a single Grid item has no sub-band seam to hang a per-row transform on)."
  - "Cascade arming reuses PanelDialog.qml's Component.onCompleted shape (assign bands, armed=true, run(), all in one block), not Dashboard.qml's per-tab runCascadeForActivePane() shape — Overview.qml has one piece of content per summon (destroyed on dismiss like PanelDialog's panels), not multiple tabs sharing one cascade runner across tab switches."
  - "Both Hyprland.refreshToplevels() and the cascade arming had to live in the SAME Component.onCompleted block on overviewWindow, because QML permits exactly one handler per signal per object — this constrained the implementation shape but not the behavior."
  - "The scratchpad's window-move verification (Super+Shift+S raising the reported count by one) was deliberately NOT reproduced by the executor via a selector-less hyprctl dispatch against the operator's real windows. Live-system safety constraint 1 (no selector-less Hyprland window dispatch) rules that out on a desktop with real windows open; the check was folded into the Task 3 human render gate instead, where the operator performs the real keybind themselves. tiles=11 was independently confirmed both with real windows present and with an empty scratchpad, which covers the position-permanence half of the criterion."

requirements-completed: [OVER-01]

coverage:
  - id: D1
    description: "Ten fixed numbered tiles (5 columns x 2 rows, mirroring the number row) render on every summon regardless of occupancy, at unchanging screen positions across repeated summons"
    requirement: "OVER-01"
    verification:
      - kind: manual_procedural
        ref: "Task 3 render gate — operator approved live on their desktop (repeated Super+O presses, tile 7 confirmed at the same position every time)"
        status: pass
      - kind: automated_ui
        ref: "qs ipc call overview status reporting tiles=10 (Task 1) then tiles=11 (Task 2); windows= cross-checked against hyprctl clients -j's own count on workspaces 1-10"
        status: pass
    human_judgment: true
    rationale: "Whether tile positions are genuinely pixel-stable across repeated summons — the load-bearing assumption under 16-06's drag-and-drop drop targets — is a claim only a human watching the live desktop across several real Super+O presses can actually confirm; a single IPC snapshot cannot prove stability across time."
  - id: D2
    description: "Every window renders at its real scaled position/size (real geometry recognisable by shape alone), read through the newly-extracted WindowThumbnail.qml type"
    requirement: "OVER-01"
    verification:
      - kind: manual_procedural
        ref: "Task 3 render gate — operator confirmed tiles read as true miniatures (left/right/size/position all matched the real desktop) with 3+ real windows spread across workspaces"
        status: pass
    human_judgment: true
    rationale: "This exact deliverable is what shipped two false passes in 16-02 before the real fix was found — human confirmation on the live desktop remains the only check in this surface's history that has actually caught the defect class correctly."
  - id: D3
    description: "An eleventh, always-present, visually distinct scratchpad tile renders on every summon whether or not it holds windows, in a permanently reserved position beneath the 5x2 block"
    requirement: "OVER-01"
    verification:
      - kind: automated_ui
        ref: "qs ipc call overview status reporting tiles=11 both with real windows present on numbered workspaces and with the scratchpad empty (position independent of occupancy)"
        status: pass
      - kind: manual_procedural
        ref: "Task 3 render gate — operator confirmed the scratchpad tile is visibly smaller, differently outlined, showed the window sent via Super+Shift+S, and remained present (now empty) after pulling it back out with Super+S"
        status: pass
    human_judgment: true
    rationale: "Whether the scratchpad reads as 'distinct, intentional' rather than 'broken/missing' and whether the live send/pull-back round trip actually works end-to-end are visual/interactive judgments; the executor deliberately did not reproduce the window-move step itself via a selector-less dispatch (live-system safety constraint 1), so the human gate is the only place this specific check ran end-to-end."
  - id: D4
    description: "The entrance cascades by row (row 1, row 2, scratchpad) in three bands, not per-tile, on D-21's existing stagger/emphasized-in tokens with no new motion.json growth"
    requirement: "OVER-01"
    verification:
      - kind: other
        ref: "~/.cache/quickshell.log line 'cascade: run tab=-1 bands=3' with no 'skip band-with-transform' line, and no TypeError/ReferenceError/Unable-to-assign, across a summon/dismiss cycle; git diff --stat -- theme-engine/motion.json empty; motion-lint exits 0 (113 checks) with Overview.qml/WorkspaceTile.qml/WindowThumbnail.qml all in scope"
        status: pass
      - kind: manual_procedural
        ref: "Task 3 render gate — operator confirmed the cascade reads as three quick, distinct steps (row, row, scratchpad), not a slow ripple or an all-at-once pop"
        status: pass
    human_judgment: true
    rationale: "The log line proves the mechanism ran with the right band count; whether the timing actually reads as three quick steps rather than sluggish or instantaneous is a felt-timing judgment only a human watching it can make."

duration: single session (compressed run, no intermediate checkpoints below the mandatory render gate)
completed: 2026-08-03
status: complete
---

# Phase 16 Plan 03: Grid and Scratchpad Summary

**D-16-01's fixed 5x2 numbered grid plus D-16-05's always-present scratchpad tile, both rendering at unchanging screen positions on every summon, with capture consolidated into a single new `WindowThumbnail` type and a three-band row-level entrance cascade — human-approved live on the operator's desktop.**

## Performance

- **Duration:** single session, compressed run (Tasks 1-2 auto-executed with live IPC/log verification after each; Task 3's visual render gate paused for and received human approval)
- **Completed:** 2026-08-03
- **Tasks:** 3 (2 auto + 1 checkpoint:human-verify)
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- Expanded the tracer's single tile into the full D-16-01 contract: ten numbered tiles in a fixed 5-column x 2-row arrangement mirroring the number row (`1 2 3 4 5` over `6 7 8 9 0`), every slot rendering on every summon whether occupied or not, at a screen position that does not move between summons — human-confirmed across repeated Super+O presses, which is the load-bearing assumption plan 16-06's drag-and-drop drop targets rest on.
- Extracted `WindowThumbnail.qml`, the single general representation of "a window drawn small" — the assumption-delta promotion recorded in the plan's own decision block. It is now the ONLY `ScreencopyView` instantiation site in `modules/overview/` (enforced by this plan's own acceptance criteria as a directory-wide grep count), with `liveCapture` as the variant property D-16-07's fallback ladder and D-16-12's drag ghost both reach for later without a second renderer.
- Added D-16-05's eleventh scratchpad tile: always rendered regardless of occupancy, in a permanently reserved position beneath the 5x2 block, differing from a numbered tile in exactly three cosmetic properties (tertiary border, `inventory_2` glyph, no numeral) while sharing every other code path — clipping, real geometry, capture, click-to-focus — verbatim, which is what keeps plan 16-06's drag-in/drag-out symmetric rather than a special case.
- Wired D-16-24's row-level entrance cascade — three bands (row 1, row 2, scratchpad), not eleven per-tile animations — reusing `Cascade.qml`'s existing stagger/emphasized-in tokens verbatim, so `motion.json` did not grow and Phase 12's D-25 semantic-layer growth policy stayed shut.
- Confirmed live, at full eleven-tile scale rather than just assumed to generalise from the tracer's one tile: `Hyprland.refreshToplevels()` and per-view `constraintSize` both held with zero new defects — `qs ipc call overview status` reported `tiles=11` and a `windows=` count matching `hyprctl clients -j`'s own, with clean logs across summon/dismiss cycles both before and after the human render gate.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extract WindowThumbnail, then render the fixed ten-slot numbered grid** - `cb56d8b` (feat)
2. **Task 2: Add the scratchpad tile and the row-level entrance cascade** - `8f93784` (feat)
3. **Task 3: Render gate** (`type="checkpoint:human-verify"`, `gate="blocking"`) - approved by the operator with no requested changes; no file changes of its own (mirrors 16-02 Task 3's own precedent)

**Plan metadata:** (this commit)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/overview/WindowThumbnail.qml` — **new.** The single general representation of "a window drawn small": `toplevel`/`captureScale`/`monitor`/`liveCapture` properties, one `ScreencopyView` (the only instance in the directory), `hasContent` exposed for the aggregate counts. Geometry arithmetic hoisted verbatim from the tracer's own proven delegate — not re-derived.
- `quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml` — rewritten around `WindowThumbnail`: `slotLabel` identity overlay on a legibility pill, occupied/unoccupied background split, empty-state quiet glyph, focused-workspace outline ring, monitor badge (structurally present, unexercised on this single-monitor host — the recorded backstop truth), and `isScratchpad` wired to its exactly-three cosmetic differences.
- `quickshell/.config/quickshell/modules/Overview.qml` — rewritten content: `Column` of two `Row`s (5 tiles each, resolved by workspace id) plus the eleventh scratchpad `WorkspaceTile` beneath, the load-bearing fit arithmetic recorded as header comments, `workspaceForSlot()`/`scratchpadWorkspace()`/`isFocusedSlot()`/`activateTile()` helper functions shared across all eleven tiles, one `Cascade` instance armed and run from the same `Component.onCompleted` that calls `Hyprland.refreshToplevels()`, and the `tileCount`/`thumbnailCount`/`thumbnailsWithContent` aggregation now summed across all eleven tiles for the `overview` IPC status verb.
- `quickshell/.config/quickshell/modules/overview/qmldir` — registers `WindowThumbnail 1.0 WindowThumbnail.qml` in the same commit that creates it, per this manifest's own standing rule.

## Decisions Made

See `key-decisions` in the frontmatter above for the full list with rationale. Summarised:
- `WindowThumbnail.qml`'s geometry math is a straight hoist, not a rewrite, of the tracer's own already-proven delegate arithmetic.
- The grid is a `Column` of two `Row`s (not a single `Grid` element) specifically so each row is an independently addressable Cascade band.
- Cascade arming mirrors `PanelDialog.qml`'s single-content `Component.onCompleted` shape, not `Dashboard.qml`'s per-tab-switch shape — the right precedent for a destroy-on-dismiss, one-content-per-summon surface.
- The scratchpad's live window-move check was deliberately deferred to the human render gate rather than reproduced by the executor via a selector-less `hyprctl dispatch` against the operator's real windows (live-system safety constraint 1) — `tiles=11` was independently confirmed with and without scratchpad occupancy, which covers the position-permanence half of the criterion without that risk.

## Deviations from Plan

None — plan executed exactly as written. No Rule 1/2/3 auto-fixes were needed; the tracer's two mandatory patterns (`refreshToplevels()`, `constraintSize`) generalised cleanly to eleven tiles with zero new defects, and the render gate was approved on the first pass with no requested changes.

## Issues Encountered

**A live-system-safety constraint shaped one verification step, not a defect.** The plan's own `<verify>` block for Task 2 suggests `hyprctl dispatch 'hl.dsp.window.move({ workspace = "special:magic" })'` to test the scratchpad window-move — this dispatcher operates on whichever window is currently focused with no per-window address selector, i.e. exactly the selector-less pattern this project's standing live-system-safety rule 1 prohibits on a desktop with real windows open (a prior Wave 0 agent destroyed the operator's real browser this way). The executor did not run it. Instead: (a) `tiles=11` was independently verified both with real windows present elsewhere and with the scratchpad genuinely empty, confirming the tile's position does not depend on occupancy; (b) the live send/pull-back round trip via the real `Super+Shift+S`/`Super+S` keybinds was folded into Task 3's human render gate, where the operator performed it themselves and confirmed it worked. No plan content needed to change for this — it is a note for whoever verifies plan 16-06 (which will need a real per-window drag/drop against live windows) to read the live-system-safety section of the executor prompt before attempting anything similar with hyprctl directly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness — what 16-05 through 16-08 must not re-derive or re-break

- **The fixed-slot geometry contract is human-verified stable, not just asserted.** Tile 7 (and every other slot) renders at the identical pixel position across repeated Super+O presses — confirmed live at the Task 3 render gate. **Plan 16-06's drag-and-drop drop targets depend on this holding**; nothing in this plan's own code computes slot position from anything other than fixed Column/Row layout plus a fixed `slotLabel`-to-id mapping, so there is no live state that could make a tile move between summons. If a later plan ever makes slot position depend on workspace state (e.g. reordering by recency), that would silently break this contract — don't.
- **`WindowThumbnail.qml`'s interface is now the seam every later plan should extend, not duplicate:** `toplevel`, `captureScale`, `monitor`, `liveCapture` (bool, default `true`) properties in, `hasContent` out, exactly one `ScreencopyView` inside. Plan 16-05's pending/blank/denied states are a natural addition here (an internal state derived from `toplevel`/`hasContent`, exposed as a new readonly property or reusing `hasContent`'s own falsy state) — **do not build a second capture-state component**; extend this type. Plan 16-06's drag ghost and plan 16-07's keyboard-driven selection both read/observe this same type; neither needs a new one.
- **The scratchpad tile shares the numbered tiles' `activated()`/click-to-focus code path verbatim** — its `MouseArea`, `Repeater`, and `WindowThumbnail` instantiation are byte-identical to a numbered tile's, differing only in `isScratchpad`'s three cosmetic effects. **Plan 16-06 can treat it as a valid drop target using the exact same mechanism as any numbered tile** — there is no structural reason it should be excluded, and D-16-05's whole point (symmetric drag-in/drag-out) depends on that uniformity holding. If 16-06 decides to exclude it anyway, that is a new decision to record, not something this plan's code forces.
- **The tracer's two mandatory patterns (`Hyprland.refreshToplevels()` on `Component.onCompleted`, `constraintSize` on every `ScreencopyView`) held cleanly at full eleven-tile/multi-window scale** with zero new defects — confirmed via live IPC counts matching `hyprctl clients -j` and clean logs across multiple summon/dismiss cycles. Plan 16-08's fifteen-stream performance measurement does not need to re-verify that concurrent capture or the refresh timing work at this scale; that question was closed by 16-02 and re-confirmed here, not reopened.
- **Live-system safety note carried forward:** any later plan needing to move or manipulate a real window via `hyprctl dispatch` (16-06's drag-and-drop especially) must pass an explicit window selector (e.g. `address:0x...`) rather than relying on this repo's Lua `hl.dsp.window.*` dispatchers, which operate on the implicitly-focused window with no selector argument in the shapes exercised so far. Verify the actual dispatcher signature (or focus the intended window explicitly first) before issuing a live move against the operator's real desktop.

---
*Phase: 16-workspace-overview*
*Completed: 2026-08-03*
