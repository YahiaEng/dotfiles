---
phase: 16-workspace-overview
plan: 08
subsystem: testing
tags: [performance, measurement, quickshell, hyprland, screencopy, benchmarking]

requires:
  - phase: 16-04
    provides: "the single capture path whose cost this plan measures"
  - phase: 16-07
    provides: "keyboard navigation and the final visual design measured here — including the scrim removal that invalidated the ladder's own costing"
provides:
  - "16-OVER04-MEASUREMENT.md — the recorded measurement and the OVER-04 verdict"
  - "16-USE-NOTE.md — the running use note discharging criterion 5 over three calendar days"
  - "A verdict of INSIDE-BUDGET on the CPU term, with the FPS terms recorded as UNMEASURED"
affects: [16-phase-close, any-future-capture-mode-change]

actuals:
  tokens: 9000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Assert the load floor at SAMPLE time, not at arm time"
    - "Discard and preserve a measurement whose load generator was unrepresentative"

key-files:
  created:
    - .planning/phases/16-workspace-overview/16-OVER04-MEASUREMENT.md
    - .planning/phases/16-workspace-overview/16-USE-NOTE.md
  modified: []

key-decisions:
  - "Verdict INSIDE-BUDGET on the CPU term; ladder rung reached: none; no code changed"
  - "FPS floor and target recorded as UNMEASURED rather than estimated — the only instrument froze the host"
  - "The debug overlay was not retried after it forced a physical restart"

patterns-established:
  - "A minimum-load assertion does not protect against an unrepresentatively harsh load"
  - "Exclude top's first batch iteration — it is an average since process start"

requirements-completed: [OVER-04]

coverage:
  - id: D1
    description: "Three-condition performance measurement plus a closed-overview baseline, under the budget's own load floor, with raw samples preserved"
    requirement: OVER-04
    verification:
      - kind: automated_ui
        ref: "Task 1 <automated> verify — load floor, per-condition rows, raw sample lines, versions, overlay restored"
        status: pass
    human_judgment: false
  - id: D2
    description: "A named OVER-04 verdict with the ladder rung reached, and no code changed on a passing measurement"
    requirement: OVER-04
    verification:
      - kind: automated_ui
        ref: "Task 2 <automated> verify — verdict heading, empty diff for ladder files, tiles=11, no new IPC verb"
        status: pass
    human_judgment: false
  - id: D3
    description: "Structured first pass over the finished surface, and the running use note opened for criterion 5"
    verification:
      - kind: manual_procedural
        ref: "16-USE-NOTE.md 2026-08-08 entry — approved, no defects reported"
        status: pass
    human_judgment: true
    rationale: "Standing constraint 1 requires human sign-off on a visual surface; criterion 5 additionally requires observations from ordinary use, which no automated check can produce."

duration: 1 session
completed: 2026-08-08
status: complete
---

# Phase 16 Plan 08: OVER-04 Measurement Summary

**Live capture ships for all eleven tiles: the shell peaks at 20.9% of one core during a sustained drag against a 50% ceiling, so no ladder rung was descended and no code changed — but the FPS half of the budget is recorded as unmeasured, because the only instrument for it froze the machine.**

## Performance

- **Duration:** 1 session
- **Tasks:** 3 of 3 (2 auto, 1 blocking human-verify)
- **Files created:** 2 (both planning artifacts)
- **Files modified:** 0 source files — a passing measurement changes nothing

## Accomplishments

- **Measured three conditions plus a baseline** under 12 windows across 5 workspaces, with the load floor re-asserted at sample time rather than trusted from arm time.
- **Verdict `INSIDE-BUDGET`, ladder rung: none.** Worst observed 20.9% during a sustained human-driven drag; 13.8% at rest; 13.7% over a fullscreen client; 0.0% with the overview dismissed, confirming the zero-idle doctrine.
- **Caught a false verdict before it triggered the ladder.** A first run measured 265% and would have forced rung 1 — deleting the frosted glass approved one plan earlier — purely because the load generator was pathological.
- **Opened the running use note** that holds phase 16 open until entries span three calendar days.

## Task Commits

1. **Task 1 + Task 2: measurement and verdict** — `9069775` (docs)
2. **Task 3: use note opened** — `25f69d3` (docs)
3. **Plan closure** — this commit (docs)

## Results

| Condition | n | mean | peak | vs 50% ceiling |
|---|---|---|---|---|
| Baseline — overview closed | 6 | 0.0% | 0.0% | zero-idle confirmed |
| A — at rest | 9 | 13.8% | 16.0% | 3.1× headroom |
| B — sustained drag (peak load) | 11 | 19.7% | 20.9% | 2.4× headroom |
| C — over fullscreen client | 9 | 13.7% | 16.0% | 3.1× headroom |

## Decisions Made

- **No ladder rung descended.** D-16-07 fires on a demonstrated miss and there is none. The plan is explicit that descending on less "would trade live thumbnails for a number rather than for a visible problem", and the same logic forbids descending for a number that could not be taken.
- **FPS terms recorded as UNMEASURED, not estimated.** The verdict names what was proven and does not claim the rest.
- **The debug overlay was not retried.** A second forced restart is too high a price for a number.

## Deviations from Plan

### The FPS instrument froze the host

The plan prescribes enabling the compositor's frame-time overlay via `hyprctl eval` + `hl.config`, which is the correct form for this Lua-configured compositor. Done exactly as written, on top of the overview with 11 live captures, **it froze the machine hard enough to require a physical restart** — Hyprland's IPC stopped answering every subsequent request, including the one that would have disabled the overlay. Two of the budget's three terms are consequently unmeasured. The surface is not implicated: the CPU term was measured cleanly before and after, and the overlay is a compositor-side debug facility.

### A discarded run that would have produced the wrong answer

The first measurement used three terminals running `while :; do date +%s.%N; done` and put the shell at **265% — a 5.3× miss that would have triggered the ladder.** The realistic load measures ~14%, a 19× difference on identical code and host. The plan's precondition asserts a *minimum* window count, which correctly prevents a too-easy measurement; nothing guarded the other end. The discarded run is preserved in the measurement file rather than deleted, because the failure mode is the interesting part.

Had it been trusted, rung 1 would have removed the frosted-glass treatment approved across thirteen render-gate rounds in plan 16-07 — for an artifact of the load generator.

### Two corrections for future readers

- **`hl.dsp.fullscreen()` does not exist** and errors; the working form is `hl.dsp.window.fullscreen(0)` (keybinds.lua line 70). Condition C was silently measured against a *non*-fullscreen client until this was caught and the condition re-run.
- **The ladder's costing is stale.** D-16-07 priced rung 1 as removing a full-screen blur "roughly five times the blur region of any panel". Plan 16-07 removed the full-bleed scrim, so only the eleven tiles blur now. Rung 2 should be weighed ahead of rung 1 by anyone re-running this after a regression.

### `16-USE-NOTE.md` did not exist

The plan states the file "has been created with today's entry stubbed out". It had not been, so creating it was folded into Task 3.

### The first pass carries no per-point findings

The gate was approved without written observations against the eight points. Recorded in the note as "approved, no defects reported" rather than written up as eight passes with invented detail — the note flags two areas (smoothness under load, and the three-highlight collision) where this entry is weaker evidence than it appears.

---

**Total deviations:** 1 instrument failure with host impact, 1 discarded measurement, 2 corrections recorded for reuse, 1 missing artifact created, 1 gate approved without per-point detail.

## ⚠ Phase 16 is NOT complete

This plan is complete; the phase is not. Two things remain open:

1. **Criterion 5** — `16-USE-NOTE.md` must span **three calendar days**. Earliest close: **2026-08-10**. This was decided up front because the overview is the milestone's highest-frequency surface and the Phase 9 pattern is "looked fine at review, wrong in daily use".
2. **`deferred-items.md`** — the inherited-opacity defect on the capture-failure catch (plan 16-04's surface) is still open.
