---
phase: 13-motion-retrofit-existing-surface-sweep
plan: 07
subsystem: theme-engine
tags: [hyprland, motion, md3, motion-lint, theme-stress-test, windows-ledger, waiver]

# Dependency graph
requires:
  - phase: 13-motion-retrofit-existing-surface-sweep
    provides: "13-01's D-19 soak clock and A/B curve-set toggle, 13-06's wallpaper-untrack fix that unblocked the stress test"
provides:
  - "13-MOTION-SOAK-VERDICT.md — a WAIVER RECORD (not a passed verdict) for D-19/D-20"
  - "D-21 A/B curve-comparison toggle fully removed from the shipped tree"
  - "theme-stress-test's first-ever full 10/10 committed run this milestone"
  - "WINDOWS.md ledger entry 9 closed (open_count now 6, entry 10 remains legitimately open)"
affects: [phase-14, phase-15, phase-16, phase-17]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Waiver-record artifact shape: an evidence document that states plainly 'this gate did not pass' rather than reframing an unmet requirement as a soft pass — same design philosophy as 13-03's WR-04 waiver record"

key-files:
  created:
    - .planning/phases/13-motion-retrofit-existing-surface-sweep/13-MOTION-SOAK-VERDICT.md
  modified:
    - hypr/.config/hypr/config/animations.conf
    - hypr/.config/hypr/scripts/motion-switch.sh
    - theme-engine/.config/theme-engine/lib/motion.sh
    - theme-engine/.config/theme-engine/motion.json
    - .planning/WINDOWS.md

key-decisions:
  - "The D-19/D-20 soak gate was WAIVED by explicit operator decision (relayed via the orchestrator), not passed. Measured fact: Hyprland PID 966 is a single unbroken compositor process/boot spanning and predating the entire soak window — distinct-session count is 1, floor is 3. Zero A/B flips were performed. All thirteen per-motion verdicts are recorded NOT ASSESSED, never 'keep'."
  - "The A/B toggle removal (Task 4) was treated as unconditional, real work — not waived alongside the soak gate. The plan's standing prohibition against shipping the toggle applies regardless of whether the soak that would have justified retunes actually ran."
  - "WINDOWS.md ledger entry 9 closed on the strength of the committed, unmodified theme-stress-test's own full run (10/10, 162/0, exit 0) — not a root-cause-fix-alone prediction, per D-25's standing rule that such a prediction was already wrong once at the Phase 12 close."

requirements-completed: []

coverage:
  - id: D1
    description: "D-19/D-20 soak gate reached and explicitly waived, recorded as a waiver (not a pass) with the measured floor shortfall and a NOT-ASSESSED verdict on all 13 motions"
    requirement: "MOTION-03 (soak-depth aspect only — see Known Gaps below; REQUIREMENTS.md's literal render-gate wording was already satisfied by 13-01/13-02/13-05)"
    verification:
      - kind: other
        ref: "13-MOTION-SOAK-VERDICT.md; measured session count via Hyprland PID/journalctl --list-boots"
        status: fail
    human_judgment: true
    rationale: "The operator explicitly waived this gate to close the phase rather than continue the soak. This is recorded as a genuine gate failure/waiver, not a pass — see Known Gaps."
  - id: D2
    description: "D-21 A/B curve-comparison toggle removed completely from motion.json, lib/motion.sh, motion-switch.sh, and animations.conf; non-adopted x-* marked easings deleted"
    requirement: "MOTION-01"
    verification:
      - kind: other
        ref: "Four negative-grep checks all clean; Hyprland --verify-config clean; hyprctl animations -j readback confirms all six retuned slots hold literal MD3 curve names; motion-lint exit 0 (53/0); all four motion-scale presets verified working; motion-curves state file confirmed absent"
        status: pass
    human_judgment: false
  - id: D3
    description: "Closing gates all green: theme-stress-test 10/10 (162/0, exit 0, first full run this milestone), motion-lint --no-pending exit 0, all 8 gate scripts exit 0, git tree clean after the run, WINDOWS.md entry 9 closed"
    requirement: "MOTION-01, MOTION-02"
    verification:
      - kind: other
        ref: "theme-stress-test (162/0), motion-lint --no-pending (1/0), theme-doctor (206/0), theme-parity (2697/0), waybar-design-lint (32/0), waybar-equivalence-check (0/0), keybind-doctor (13/0), quickshell-doctor (13/0), motion-lint (53/0), motion-lint --self-test (11/0)"
        status: pass
    human_judgment: false

duration: ~90min (includes one orchestrator-relayed waiver mid-plan)
completed: 2026-07-28
status: complete
---

# Phase 13 Plan 07: D-19/D-20 Soak Waiver, A/B Toggle Removal, Closing Gates Summary

**The D-19/D-20 soak gate was reached and explicitly waived by the operator rather than passed — recorded honestly as a waiver, not a verdict — while the D-21 A/B curve-comparison toggle was still fully removed as required, the committed theme-stress-test completed its first-ever clean 10/10 run this milestone, and all eight regression gates plus WINDOWS.md ledger entry 9 closed green.**

## Performance

- **Duration:** ~90 min (includes a mid-plan pause where the executor correctly refused to fabricate Task 1's soak floor/verdict, followed by an orchestrator-relayed operator waiver)
- **Completed:** 2026-07-28
- **Tasks:** 4 (Task 1: waived checkpoint, recorded as a waiver; Task 2: no-op, no motion assessed to retune; Task 3: not-applicable no-op; Task 4: real removal + closing gates)
- **Files modified:** 6 (5 code/config + 1 new evidence artifact)

## Accomplishments

- **Task 1 — refused to fabricate, then recorded the waiver honestly.** Reached the blocking D-19/D-20 soak-verdict gate, confirmed its precondition (13-01's render gate approved, soak clock started 2026-07-27T03:40:53Z), re-measured the three mechanical baseline gates (all green, no regression), then stopped and asked the operator for the real floor numbers and per-motion verdicts rather than guessing. The orchestrator relayed an explicit operator decision to waive the gate. `13-MOTION-SOAK-VERDICT.md` was written as a **waiver record** — not a verdict — stating plainly that the floor was not met (measured session count 1 of floor 3, via Hyprland's PID/boot age; zero A/B flips performed) and that all thirteen per-motion rows are `NOT ASSESSED — soak gate waived`, never `keep`.
- **Task 2/3 — correctly recorded as not-applicable, not as passed.** No motion was assessed, so no retune was demanded (Task 2) and no targeted re-soak was possible (Task 3). Both are documented in the verdict artifact as no-ops distinct from "clean verdict stands."
- **Task 4 — the A/B toggle removal was real work, done in full regardless of the waiver.** `motion.json`'s `curve_sets` object and D-11's marked non-MD3 `x-*` easing extension (5 character curves, none ever adopted by any retune) are gone. `motion-switch.sh`'s `--curves <md3|legacy>` flag, its reader, its validation, its state write, and its `--list`/usage mentions are gone. `lib/motion.sh`'s curve-set reader, curve-alias emission block, and validation clauses are gone (speed-variable and indicator emission untouched). `animations.conf`'s six feel-changing slots (`windowsIn/Out/Move`, `fadeIn/Out`, `workspaces`) now hold literal MD3 curve names pinned to the toggle's former `md3` mapping.
- **Closing gates, all green:** the committed, unmodified `theme-stress-test` completed **10/10 consecutive switches, 162 passed, 0 failed, exit 0** — the first time this exact script has run to full completion this milestone (Phase 12 close and 13-06 both left it blocked). `motion-lint --no-pending` exits 0 with zero pending exemptions. All eight regression gate scripts exit 0 (see counts below). `git status --porcelain` is empty after the full stress-test run.
- **WINDOWS.md ledger entry 9 closed**, citing the 10/10 run as the proof — not a root-cause-fix-alone prediction, per D-25's standing rule (a scratch-patched "expected to pass identically" prediction was already wrong once at the Phase 12 close).

## Task Commits

1. **Task 1: D-19 floor / D-20 verdict — waived, recorded as such** — `9083140` (docs: write waiver record)
2. **Task 2/3: retune / re-soak — recorded as not-applicable no-ops** — no separate commit (recorded inside `9083140`'s artifact, since no code changed)
3. **Task 4A/B: remove the A/B toggle** — `e7587c6` (fix)
4. **Task 4C/D: closing gates + ledger entry 9 close** — `fe6e50e` (docs: WINDOWS.md update; the gate runs themselves produced no file changes beyond the ledger)

## Files Created/Modified

- `.planning/phases/13-motion-retrofit-existing-surface-sweep/13-MOTION-SOAK-VERDICT.md` — new: the waiver record (D-19 floor table with the measured session-count shortfall, thirteen `NOT ASSESSED` motion rows, forbidden-language check, and explicit consequence statement)
- `hypr/.config/hypr/config/animations.conf` — six `$motion_curve_<slot>` references replaced with literal MD3 curve names (`motion-emphasized-decelerate`, `motion-emphasized-accelerate`, `motion-standard`, `motion-standard-decelerate`, `motion-standard-accelerate`)
- `hypr/.config/hypr/scripts/motion-switch.sh` — `--curves` flag, its reader, validation, state write, and usage/`--list` mentions removed entirely
- `theme-engine/.config/theme-engine/lib/motion.sh` — curve-set reader, curve-alias emission block, and curve_sets validation clauses removed; speed/indicator emission untouched
- `theme-engine/.config/theme-engine/motion.json` — `curve_sets` object and the five `x-*` marked non-MD3 easings removed (none were ever adopted); shipped easing vocabulary is now pure MD3
- `.planning/WINDOWS.md` — entry 9 marked `fixed`, citing the 10/10 stress-test run

## Decisions Made

- **D-19/D-20 gate: WAIVED, not passed.** The executor refused to invent floor counts or per-motion verdicts (they are the operator's lived, multi-session experience, not something an agent can measure). The orchestrator then relayed the operator's explicit decision to waive the gate and close the phase. This is recorded as a genuine gate failure, using the words "waived" and "not assessed" throughout — never "deemed acceptable," "effectively keep," or similar softening language.
- **The A/B toggle removal was NOT waived alongside the soak gate.** The plan's prohibition against shipping the toggle is unconditional — it exists because leaving the toggle would convert a one-way MD3-purity decision into a user-flippable setting, independent of whether the soak that would have justified any retunes actually completed. This work was done in full and verified live.
- **Closing gates were NOT waived.** `motion-lint --no-pending`, the full ten-switch `theme-stress-test`, and all eight gate scripts were run for real and are genuinely green — none of these were skipped or asserted without evidence.
- **WINDOWS.md open_count is 6, not the plan's literal 5** — same documented-discrepancy class as 13-06's entry reconciliation. Entry 10 (D-06 boundary correction, added by sibling plan 13-01 after this plan's acceptance criterion was authored against a 9-entry ledger) remains legitimately open and out of this plan's scope; it was not force-marked fixed to make the number match.

## Known Gaps (read before treating MOTION-03 as fully closed)

**REQUIREMENTS.md's MOTION-03 checkbox remains `[x] Complete`, and this plan did not change it** — its literal wording ("Every retrofitted surface passes a blocking human render-and-look gate before its plan closes") was already satisfied by 13-01 (Hyprland), 13-02 (swaync) and 13-05 (waybar)'s own render gates, none of which this plan touches or invalidates.

**However, this plan's own must-have truths — the D-19/D-20 "recorded multi-session use note, one row per motion" — were NOT achieved.** They were waived. The specific failure mode D-19/D-20 exist to catch (a motion that looks fine at a one-off review but reads wrong once lived with, across restarts, at real reaction speed) is **not ruled out for any of the thirteen motions** in `13-MOTION-SOAK-VERDICT.md`. If any of the following slots is actually wrong in daily use, this plan produced no evidence either way: window open/close/move, workspace switch, special-workspace transition, fade in/out, layer entrance/exit, border colour transition, notification-centre transitions, waybar module transitions, battery blink indicators.

This is flagged here, not softened, so a future phase or audit does not mistake the render-gate completion (real, mechanical, already proven) for the soak-based perceptual completion (waived, never performed).

## Threat Flags

None — this plan removed surface (the A/B toggle and its flag/state-file) rather than adding any.

## Issues Encountered

- No implementation bugs. The one procedural event worth recording: the executor reached Task 1, correctly identified that it could not fabricate operator-only soak data, and returned a checkpoint asking for it — the orchestrator then relayed an explicit operator waiver rather than the requested data, and execution proceeded per the orchestrator's revised instructions (write a waiver record, do the real toggle-removal and gate work unconditionally).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan 13-07 is complete. **Phase 13 itself is NOT marked complete by this plan** — the orchestrator owns that decision. As of this plan's completion, all 7 phase plans have a SUMMARY.md on disk (13-01 through 13-07), including 13-03 which closed concurrently under its own WR-04 waiver.
- All three of the phase's regression gates (`motion-lint`, `theme-parity`, `theme-doctor`) are green with no regression from this plan's baseline (206/0, 2697/0, 53/0 respectively), plus `motion-lint --no-pending` (0 pending) and the full 10/10 `theme-stress-test` run — a genuinely clean baseline for Phase 14 to build on.
- **Carry the Known Gaps section above into any future phase or audit that touches these thirteen motion slots** — the soak-based perceptual validation was waived, not performed, and remains a legitimate open question about daily-use feel.
- WINDOWS.md now stands at fixed: 1, 2, 8, 9 (4 total); open: 3, 4, 5, 6, 7, 10 (6 total); total_count 10.

---
*Phase: 13-motion-retrofit-existing-surface-sweep*
*Completed: 2026-07-28*
