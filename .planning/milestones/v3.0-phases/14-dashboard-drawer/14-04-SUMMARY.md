---
phase: 14-dashboard-drawer
plan: 04
subsystem: ui
tags: [quickshell, qml, swaync, hyprland, material-you, motion, dashboard]

requires:
  - phase: 14-03
    provides: "QuickToggles.qml stub, module manifest, footer contract in DashboardTab.qml"
  - phase: 14-02
    provides: "Material Symbols family string + A3 FILL-axis verdict (fill-axis-renders)"
  - phase: 12
    provides: "Colours/Motion singletons, motion.json scales, motion-lint CHECK A/B"
provides:
  - "Filled QuickToggles.qml: three swaync-mirrored chips (Gaming/DND/Dark) on D-22's truth-driven pending model"
  - "Full-width Off|Reduced|Normal|Lively motion-scale segmented row, direct-jump, one re-render per press"
  - "DashboardTab.qml footer mount, bottom-anchored, 14-03 placeholder still rendering above it"
  - "swaync theme-toggle direction + glyph flipped to light on dark (D-26)"
  - "14-RESEARCH.md Open Question 1 closed: subscribe-emits-dnd, verified live"
  - "Hyprland animation speed ceiling clamp in theme-engine/lib/motion.sh"
  - "Dark chip's process lifecycle fixed (startDetached) so it survives drawer dismissal"
  - "Drawer top-margin anchored to match swaync's control-centre and real window position"
affects: [14-08, 14-09, "Phase 15 (wifi-connecting/bt-pairing pending model inheritance)"]

tech-stack:
  added: []
  patterns:
    - "Truth-driven pending model: lit state is a pure read of the watched backend source, never assigned by a press; pendingChip disables the control until the source changes or a watchdog fires"
    - "startDetached() for any exec that launches a focus-stealing surface (walker) whose lifetime must outlive the drawer item that spawned it"
    - "Speed-ceiling clamp mirroring the existing floor-clamp's WARN-and-continue posture, for any Hyprland target with a hard max"

key-files:
  created: []
  modified:
    - "quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml"
    - "quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml"
    - "swaync/.config/swaync/config.json"
    - "theme-engine/.config/theme-engine/lib/motion.sh"
    - "quickshell/.config/quickshell/modules/Dashboard.qml"

key-decisions:
  - "D-27's Dark chip stays exactly as specified: exec theme-switch.sh (walker palette picker), no direct light/dark flip invented — approved by the user at the render gate as 'leave as D-27 specifies'"
  - "swaync's theme action flipped to report true on dark (glyph U+F0594, crescent-moon), matching the drawer's Dark chip direction; bounded to 2 changed lines"
  - "OQ1 verdict: subscribe-emits-dnd — swaync-client --subscribe emits a fresh {\"dnd\":...} line on every flip on this 0.12.6 build; polling fallback (2s timer, 4s grace window) is wired but never armed"
  - "Motion-scale row reads ~/.local/state/theme/motion-scale directly, not Motion.motionScale (motion-lint CHECK A dangling reference), following Probe.qml's precedent"
  - "Round-1 render-gate fix: Hyprland's hl.animation() hard-rejects speed > 100.00 — lively's 1.25x multiplier scaled border-rotate's 10000ms to speed 125.00; added a ceiling clamp to 100.00 with a WARN line, mirroring the existing floor clamp"
  - "Round-1 render-gate fix: Dark chip's process used running: true, tying theme-switch.sh's lifetime to the QuickToggles item destroyed on dismissal — switched to startDetached() so the walker picker and the palette selection survive drawer teardown"
  - "Round-1 render-gate fix: drawer margins.top: 10 added to Dashboard.qml (user-directed, out of this plan's declared files_modified) so the drawer's top edge lines up with swaync's control-centre (control-center-margin-top: 10) and real Hyprland window position (gaps_out: 10), instead of sitting flush against waybar's reserved zone"
  - "Round-2 render gate: all three fixes APPROVED by the user (2026-07-29) — theme selection now applies from the Dark chip, lively preset runs clean, drawer drop position correct"

requirements-completed: [DASH-07]

coverage:
  - id: D1
    description: "swaync's theme-toggle action flipped to report true on dark, with a dark-reading glyph (U+F0594), bounded to a 2-line diff"
    requirement: "DASH-07"
    verification:
      - kind: manual_procedural
        ref: "swaync-client -R reload + control-centre screenshot: LIT with mode=dark, UNLIT with a hand-injected mode=light (restored); jq assertion on parsed update-command direction"
        status: pass
    human_judgment: false
  - id: D2
    description: "Three swaync-mirrored chips (Gaming/DND/Dark) on D-22's truth-driven pending model: instant ripple, pending pulse, committed state only on confirmed backend change, quiet timeout revert"
    requirement: "DASH-07"
    verification:
      - kind: manual_procedural
        ref: "Rapid double-press idempotency proof (Gaming + DND, exactly one flip each), forced-hung-backend watchdog-revert proof, zero-idle-footprint proof (subscribe process count 1-open/0-dismissed across 3 cycles), motion-lint CHECK A/B pass"
        status: pass
    human_judgment: true
    rationale: "Pending feel, chip legibility across themes/motion scales, and the Dark chip's picker-behaviour honesty cost are recorded discretion calls this plan's render gate exists to judge, not mechanically provable — Round 2 gate APPROVED 2026-07-29"
  - id: D3
    description: "14-RESEARCH.md Open Question 1 closed: swaync-client --subscribe emits DND changes live on this 0.12.6 build (verdict subscribe-emits-dnd); polling fallback wired and provable, never armed"
    requirement: "DASH-07"
    verification:
      - kind: manual_procedural
        ref: "Live observation: toggling DND from outside the drawer while open produced a fresh {\"dnd\":...} subscribe line for every -dn/-df flip with no polling needed"
        status: pass
    human_judgment: false
  - id: D4
    description: "Full-width Off|Reduced|Normal|Lively segmented row, direct jump, one theme-apply re-render per press, committed selection read from the state file"
    requirement: "DASH-07"
    verification:
      - kind: manual_procedural
        ref: "All four presets exercised: state file held exactly the pressed value each time, motion.json mtime changed exactly once per press, jq confirms segment values equal motion.json's .scales key set, pending-window second-press no-op confirmed"
        status: pass
    human_judgment: true
    rationale: "Segment label fit, selected-segment obviousness, and the check-glyph call are recorded discretion the render gate judges — Round 2 gate APPROVED 2026-07-29 (no changes requested to the row itself)"
  - id: D5
    description: "Hyprland animation speed ceiling clamp added to theme-engine/lib/motion.sh (WARN-and-clamp to 100.00, mirroring the existing floor clamp)"
    verification:
      - kind: manual_procedural
        ref: "hyprctl configerrors clean across all four presets including repeated lively passes, post-fix"
        status: pass
    human_judgment: false
  - id: D6
    description: "Dark chip's process switched from running: true to startDetached() so theme-switch.sh's walker picker survives drawer dismissal"
    verification:
      - kind: manual_procedural
        ref: "Reproduced the reported symptom (SIGTERM'd direct-child PID ~0.6s post-launch), then confirmed a fully-detached (setsid) launch: walker opened, a selection was made, theme-apply completed"
        status: pass
    human_judgment: false
  - id: D7
    description: "Drawer anchored margins.top: 10 in Dashboard.qml, matching swaync's control-center-margin-top and Hyprland's gaps_out, instead of sitting flush against waybar's reserved zone"
    verification:
      - kind: manual_procedural
        ref: "hyprctl -j layers: drawer renders at y=56 (was y=46); waybar's own reserved-zone geometry byte-identical before/after"
        status: pass
    human_judgment: true
    rationale: "Visual drop-position correctness is a user-directed design judgment made live at the render gate, not a mechanically-derivable value — Round 2 gate APPROVED 2026-07-29"

duration: multi-session (2 render-gate rounds)
completed: 2026-07-29
status: complete
---

# Phase 14 Plan 04: Dashboard Quick-Toggles + swaync Mirror Summary

**Three swaync-mirrored quick-toggle chips (Gaming/DND/Dark) and a direct-jump motion-scale segmented row, filled onto D-22's truth-driven pending model and mounted as the Dashboard tab's footer, with swaync's own theme button flipped to agree — closing DASH-07 and 14-RESEARCH.md Open Question 1.**

## Performance

- **Duration:** Multi-session — task work ~1h27m (2026-07-29T16:44 → 18:11), plus two render-gate rounds
- **Started:** 2026-07-29T16:44:13+03:00
- **Completed:** 2026-07-29 (Round 2 render gate approved)
- **Tasks:** 4 (3 execution + 1 blocking render gate)
- **Files modified:** 5 (3 plan-declared + 2 render-gate fixes)

## Accomplishments

- Filled `QuickToggles.qml`'s 14-03 stub with the real state layer, D-22's truth-driven pending machine, and three MD3 tonal chips (Gaming, DND, Dark) that exec the exact commands and read the exact state sources swaync's own grid does — no second source of truth for DASH-07.
- Added the full-width `Off | Reduced | Normal | Lively` motion-scale segmented row beneath the chips, jumping the axis directly at one `theme-apply` re-render per press, reading its committed selection from `~/.local/state/theme/motion-scale` rather than the linter-invisible `Motion.motionScale`.
- Mounted the finished block as `DashboardTab.qml`'s bottom-anchored footer, leaving 14-03's placeholder rendering above it for 14-08.
- Flipped swaync's own theme-toggle action (D-26) to report `true` on dark with a dark-reading glyph, bounded to a 2-line diff, so both grids now light in the same direction off the shared `~/.local/state/theme/mode` file.
- Closed 14-RESEARCH.md Open Question 1 live: `swaync-client --subscribe` does emit DND state changes on this swaync 0.12.6 build (verdict `subscribe-emits-dnd`); the polling fallback is wired and provable, not merely described, and never had to arm.
- Found and fixed three render-gate-surfaced bugs across two gate rounds (below) — all approved.

## Task Commits

Each task was committed atomically:

1. **Task 1: D-26 — flip swaync's theme toggle direction and glyph together** - `7bdb8a9` (feat)
2. **Task 2: The three swaync-mirrored chips on D-22's truth-driven pending model, and the OQ1 subscribe verdict** - `e955c92` (feat)
3. **Task 3: The Off/Reduced/Normal/Lively motion-scale segmented row, and the footer mount** - `0ede181` (feat)
4. **Task 4: Render gate (2 rounds)** - human-verify checkpoint, resolved via 3 fix commits below, Round 2 APPROVED

**Render-gate fix commits** (Round 1 feedback, re-verified and APPROVED in Round 2):
- `a8bd942` — fix: clamp Hyprland animation speed to its 100.00 ceiling
- `4af5a15` — fix: startDetached() the Dark chip's process so it survives drawer dismissal
- `c909aa9` — fix: anchor drawer to top of window area (`margins.top: 10` in Dashboard.qml)

**Plan metadata:** (this commit) — `docs(14-04): complete quick-toggle grid + swaync mirror plan`

## Files Created/Modified

- `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` - Filled from 14-03's stub: state readers, pending machine, three mirrored chips, motion-scale segmented row; startDetached() fix for the Dark chip
- `quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml` - Footer mount for `QuickToggles`, bottom-anchored, 14-03 placeholder retained above it
- `swaync/.config/swaync/config.json` - Theme-toggle action direction + glyph flipped (D-26), 2-line diff, other actions byte-identical
- `theme-engine/.config/theme-engine/lib/motion.sh` - Animation speed ceiling clamp (100.00 max), WARN-and-clamp posture mirroring the existing floor clamp
- `quickshell/.config/quickshell/modules/Dashboard.qml` - `margins.top: 10` added, user-directed at the render gate, outside this plan's declared `files_modified`

## Decisions Made

- **D-27's Dark chip stays exactly as specified.** Pressing it execs `theme-switch.sh` (walker's palette picker) — no direct light/dark flip was invented, since no such backend exists and inventing one would be the second source of truth DASH-07 forbids. The user approved this as the Dark chip's real behaviour at Round 1 of the render gate ("Leave it as D-27 specifies").
- **swaync's theme button flipped to agree with the drawer.** `update-command` now reports `true` on the dark value with glyph `U+F0594` (crescent-moon); the edit is bounded to that one action object.
- **OQ1 closed as `subscribe-emits-dnd`.** `swaync-client --subscribe` reliably emits a line per DND flip on this 0.12.6 build; the poll fallback is wired (armed only if no line lands within a 4s grace window) but never had to fire.
- **Motion-scale row reads its state file directly**, not `Motion.motionScale`, following `Probe.qml`'s established precedent for the same linter-CHECK-A gap.
- **Round 1 fixes (all three approved in Round 2):**
  1. Hyprland's `hl.animation()` hard-rejects `speed > 100.00`; the `lively` preset's 1.25x multiplier pushed `border-rotate`'s 10000ms duration to speed 125.00, which Hyprland silently dropped. Fixed with a ceiling clamp in `theme-engine/lib/motion.sh` (WARN-and-clamp to 100.00), mirroring the existing floor clamp's posture. Root-caused and reproduced live via `hyprctl configerrors`.
  2. The Dark chip's process used `running: true`, tying `theme-switch.sh`'s lifetime to the `QuickToggles` item — destroyed on drawer dismissal, killing the script before the user could pick a palette while the orphaned walker window stayed open and unresponsive to selection. Reproduced the exact symptom (SIGTERM at ~0.6s) before fixing with `startDetached()`. This is a regression introduced by this plan, not a pre-existing walker/theme-apply defect — both were confirmed not at fault.
  3. The drawer dropped flush against waybar's reserved zone (y=46, 0px gap) rather than aligning with swaync's control-centre (`control-center-margin-top: 10`) or a real tiled Hyprland window (`gaps_out: 10`, both y=56) — reading as dropped in the bare gap strip between the bar and window content. Fixed with `margins.top: 10` in `Dashboard.qml`, user-directed at the render gate and outside this plan's declared `files_modified` (documented deviation, Rule 4-adjacent user decision rather than an autonomous architectural call).
- **Round 2 render gate: APPROVED.** User confirmed all three fixes: theme selection now applies correctly from the Dark chip, the lively preset runs clean with no Hyprland error, and the drawer's drop position now reads correctly relative to waybar and the window area.

## Deviations from Plan

### Auto-fixed / User-directed Issues

**1. [Rule 1 - Bug, render-gate feedback] Hyprland animation speed ceiling clamp**
- **Found during:** Task 4, Round 1 render gate (lively preset)
- **Issue:** `border-rotate`'s 10000ms duration × lively's 1.25x multiplier = speed 125.00, exceeding Hyprland's 100.00 hard maximum; `hl.animation()` rejected it via `configerrors`, and the floor clamp added in 13-01 had no ceiling counterpart.
- **Fix:** Added a WARN-and-clamp-to-100.00 ceiling in `theme-engine/lib/motion.sh`, mirroring the existing floor clamp's never-fail posture.
- **Files modified:** `theme-engine/.config/theme-engine/lib/motion.sh`
- **Verification:** `hyprctl configerrors` clean across all four presets, including repeated lively passes.
- **Committed in:** `a8bd942`

**2. [Rule 1 - Bug, render-gate feedback, this-plan regression] Dark chip process lifetime**
- **Found during:** Task 4, Round 1 render gate (theme selection didn't apply)
- **Issue:** `darkProcess` used `running: true`, so destroying the `QuickToggles` item on drawer dismissal (D-13's focus-loss rule) killed `theme-switch.sh`'s direct-child process before the user could select a palette from the orphaned, now-unresponsive walker window.
- **Fix:** Switched to `darkProcess.startDetached()` so the process is fully detached (setsid) and survives the drawer's destruction.
- **Files modified:** `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml`
- **Verification:** Reproduced the exact symptom via SIGTERM at ~0.6s, then confirmed the fix end-to-end: walker opened, a selection was made, `theme-apply` completed.
- **Committed in:** `4af5a15`

**3. [Rule 4 - User-directed design change, out of plan's declared files] Drawer top-margin anchoring**
- **Found during:** Task 4, Round 1 render gate (drop position)
- **Issue:** The drawer dropped flush against waybar's reserved zone (y=46) rather than aligning with swaync's control centre or a real tiled window's start position (both y=56), reading as dropped in an awkward gap between the bar and window content.
- **Fix:** Added `margins.top: 10` to `quickshell/.config/quickshell/modules/Dashboard.qml`, matching swaync's `control-center-margin-top: 10` literal.
- **Files modified:** `quickshell/.config/quickshell/modules/Dashboard.qml` — outside this plan's declared `files_modified` list; flagged here per protocol since it touches a file three sibling wave-3 plans share.
- **Verification:** `hyprctl -j layers` confirms the drawer now renders at y=56 (was y=46); waybar's own reserved-zone geometry is byte-identical before and after.
- **Committed in:** `c909aa9`

---

**Total deviations:** 3 (2 auto-fixed bugs, 1 user-directed design change outside declared scope)
**Impact on plan:** All three were surfaced at the render gate, fixed, re-presented, and explicitly APPROVED in Round 2 (2026-07-29). No scope creep beyond what the gate itself authorized.

## Issues Encountered

None beyond the three render-gate findings documented above, all resolved and approved.

## Render Gate History

**Round 1 (mixed):**
- Approved as-is: mirror direction (both ways), pending feel, chip legibility (light + dark), segmented row selection clarity, footer weight.
- Three issues raised: (1) theme selection from the Dark chip's picker didn't apply, (2) the lively preset produced a Hyprland error, (3) the drawer dropped in an awkward position between waybar and the window area (swaync-style top-of-window-area anchoring requested).

**Fixes:** `a8bd942`, `4af5a15`, `c909aa9` (see Decisions Made and Deviations above).

**Round 2: APPROVED.** User confirmed all three fixes: theme selection applies correctly, the lively preset runs clean, and the drop position is now correct.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- DASH-07 is satisfied on a real surface: the drawer's quick-toggles read and write the same backing state as swaync's grid, proven in both directions, with no second source of truth for gaming, DND, or dark mode.
- D-22's truth-driven pending model exists as a working, proven convention — the exact affordance Phase 15's wifi-connecting and bt-pairing states inherit.
- D-24's segmented motion-scale row jumps the axis directly at one re-render per press.
- 14-RESEARCH.md Open Question 1 has a recorded verdict (`subscribe-emits-dnd`) for this build.
- The Dashboard tab has its base line: 14-08 composes the clock hero, calendar, compact media widget, and resources strip above a footer that already works.
- The drawer's top-margin anchoring (now matching swaync's 10px control-centre margin) affects any future geometry work on `Dashboard.qml` in 14-09's polish pass — noted so it isn't silently re-derived differently.
- The motion pipeline now has a speed ceiling clamp alongside its existing floor clamp — any future long-duration animation paired with a high motion-scale multiplier is protected from a silent Hyprland config rejection.

## Self-Check: PASSED

All 5 modified files and the SUMMARY.md itself verified present on disk; all 6 commits (`7bdb8a9`, `e955c92`, `0ede181`, `a8bd942`, `4af5a15`, `c909aa9`) verified present in git history.

---
*Phase: 14-dashboard-drawer*
*Completed: 2026-07-29*
