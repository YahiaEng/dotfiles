---
phase: 19-notification-server-centre
plan: 02
subsystem: docs
tags: [gate-01, ledger-04, swaync, debug-ledger, behaviour-baseline, phase-19]

# Dependency graph
requires:
  - phase: 18-qml-bar-retirement-machinery
    provides: the GATE-01 Recurrence Protocol shape (18-BEHAVIOUR-BASELINE.md) this plan's document mirrors section-for-section
provides:
  - "19-BEHAVIOUR-BASELINE.md: a 40-row, gesture-and-observation enumeration of the live swaync surface (config.json's 28 keys, style.scss, launch fallback, and all six CLI verbs across their real call sites), read before any of its sources are touched by plan 19-08"
  - "Six LEDGER-04 dispositions, all corrected to `resolved` against 15-UAT.md's own Gaps ledger rather than the `deferred` outcome 19-RESEARCH.md's own ground-truth pass had predicted"
  - "deferred-items.md's G-15-7 entry pointed at plan 19-08 as its live-verification location, not marked closed"
affects: [19-08]

actuals:
  tokens: 13200
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "GATE-01 Recurrence Protocol applied to a second surface (swaync) — direct read, no dedicated resolver, mechanical unaccounted-key closure proof"
    - "Cross-checking a phase's own research ground-truth against an EARLIER phase's UAT ledger before writing a disposition, rather than trusting the current phase's research pass as the last word"

key-files:
  created:
    - .planning/phases/19-notification-server-centre/19-BEHAVIOUR-BASELINE.md
  modified:
    - .planning/debug/bluetooth-enable-inert.md
    - .planning/debug/wifi-hidden-network-not-detected.md
    - .planning/debug/wifi-hidden-network-unsupported.md
    - .planning/debug/wifi-scan-progress-feedback.md
    - .planning/debug/wifi-wrong-password-external-dialog.md
    - .planning/milestones/v3.0-phases/15-audio-connectivity-panels/deferred-items.md

key-decisions:
  - "All five open .planning/debug/ session files are dispositioned `resolved`, not the `deferred` outcome the plan's own action text predicted — 15-UAT.md's Gaps ledger (a source 19-RESEARCH.md's LEDGER-04 Ground Truth section did not cross-check) shows each was already fixed by its own Phase 15 gap-closure plan (15-11 through 15-14) and confirmed pass on round-2 UAT retest, the same day it was diagnosed in four of the five cases."
  - "G-15-7 (bluetooth pairing containment) is resolved-by-construction in this phase's design contract but explicitly NOT marked closed — its live pairing verification is pointed at plan 19-08, matching its own stated closing condition split into a declared-capability half (satisfied here) and a live-verification half (owed to 19-08)."
  - "Corrected LEDGER-04 count recorded in writing: five debug-session files + one separately-tracked deferred item = six dispositions, not the roadmap's stale six-debug-sessions framing — matching 19-RESEARCH.md's own correction."

patterns-established:
  - "Before writing a 'deferred/out of scope' disposition on any debug-ledger item, check whether a LATER phase's own UAT ledger (or the item's own repo cross-references) already closed it via an unrelated already-merged plan — a debug session's frontmatter can lag its own shipped fix by weeks with nothing to force the loop closed."

requirements-completed: [LEDGER-04]

coverage:
  - id: D1
    description: "19-BEHAVIOUR-BASELINE.md enumerates the live swaync surface (28 config keys, style.scss, launch fallback, 6 CLI verbs) in gesture-and-observation form with mechanically-proven completeness"
    requirement: LEDGER-04
    verification:
      - kind: other
        ref: "python3 unaccounted-keys closure loop (embedded in the plan's own <verify> and re-run at self-check) — empty remainder"
        status: pass
      - kind: manual_procedural
        ref: "grep -qF for '## Unaccounted Keys', '## Dead Definitions', '## Not a Port Specification'"
        status: pass
    human_judgment: false
  - id: D2
    description: "Six LEDGER-04 items (five debug-session files + G-15-7) each carry a written, dated Phase 19 disposition; the five session files corrected to `resolved` against 15-UAT.md's Gaps ledger; G-15-7 pointed at plan 19-08, not closed"
    requirement: LEDGER-04
    verification:
      - kind: other
        ref: "plan 19-02-PLAN.md's own <verify> shell block: 5-file count assertion, per-file status+Phase-19-block grep, and G-15-7's '19-08' pointer grep"
        status: pass
    human_judgment: false
  - id: D3
    description: "No wifi or bluetooth panel QML source file was modified reaching either finding — the corrected disposition rests on 15-UAT.md and the debug files' own content, not a drive-by panel edit"
    requirement: LEDGER-04
    verification:
      - kind: other
        ref: "git diff --name-only over both task commits — zero .qml/.lua/.sh/.json files"
        status: pass
    human_judgment: false

duration: ~35min
completed: 2026-08-13
status: complete
---

# Phase 19 Plan 02: GATE-01 Baseline & LEDGER-04 Dispositions Summary

**Wrote the swaync GATE-01 behaviour baseline (40 capability rows across config.json, style.scss and six CLI verbs) and discovered, via a cross-check the phase's own research pass had skipped, that all five open `.planning/debug/` sessions were already fixed and UAT-passed in Phase 15 — corrected their dispositions from the plan's predicted "deferred" to "resolved" against that stronger evidence.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-08-13T09:19:00Z (approx, per STATE.md session start)
- **Completed:** 2026-08-13T09:29:31Z
- **Tasks:** 2
- **Files modified:** 7 (1 created, 6 modified)

## Accomplishments

- `19-BEHAVIOUR-BASELINE.md` created: 40 `SWC-*` capability rows covering every one of `swaync/config.json`'s 28 top-level keys, its six widgets and their nested `widget-config`, `style.scss`'s theming/motion contract, the launch-fallback discipline, and all six live CLI verbs (`-t -sw` toggle, `-rs` reload, `-dn`/`-df` explicit DND pair from **both** toggle grids, `-d -sw` single-verb DND from the bar bell, `--subscribe`/`-swb`/`-D` live-state reads) — each traced to its real repo call site (`keybinds.lua:227`, `reload.sh:82-89`, `QuickToggles.qml`, `ClockActionsCapsule.qml`, `config.json`'s own `buttons-grid`).
- `## Unaccounted Keys` closure proven mechanically — the plan's own python3 loop over all 28 keys returns an empty remainder, not an assertion of thoroughness.
- `## Not a Port Specification` names D-19-17's widget-order inversion (swaync's `title, dnd, volume, slider, buttons-grid, notifications` vs. the replacement's deliberately inverted header→history→footer) as the concrete trap for a future reader.
- All five open `.planning/debug/` session files (`bluetooth-enable-inert`, `wifi-hidden-network-not-detected`, `wifi-hidden-network-unsupported`, `wifi-scan-progress-feedback`, `wifi-wrong-password-external-dialog`) each received a dated Phase 19 disposition block and a frontmatter `status: resolved`, correcting the plan's own predicted "deferred" outcome against `15-UAT.md`'s Gaps ledger, which independently records every one of these five bugs as already fixed by its own Phase 15 gap-closure plan (15-11 through 15-14) and confirmed `pass` on round-2 UAT retest.
- `deferred-items.md`'s G-15-7 entry (bluetooth pairing containment) gained a "Phase 19 Disposition" section naming it resolved-by-construction in this phase's design contract, explicitly **not** marked closed, with its live pairing verification pointed at plan `19-08`.
- Corrected LEDGER-04 count recorded in writing in both the SUMMARY and the `deferred-items.md` entry itself: five debug-session files + one separately-tracked deferred item = six dispositions — the historical sixth (`panels-missing-animated-border.md`) was already closed under Phase 18's LEDGER-01, before this phase began.

## Task Commits

Each task was committed atomically:

1. **Task 1: GATE-01 — enumerate the live notification daemon's behaviour before anything is deleted** - `7f4c203` (docs)
2. **Task 2: LEDGER-04 — six dispositions across two ledgers, against corrected ground truth** - `6b9fa9f` (docs)

**Plan metadata:** (this commit, following)

## Files Created/Modified

- `.planning/phases/19-notification-server-centre/19-BEHAVIOUR-BASELINE.md` - GATE-01 enumeration of the outgoing swaync surface (created)
- `.planning/debug/bluetooth-enable-inert.md` - frontmatter `status: diagnosed` → `resolved`; Phase 19 disposition block citing 15-12's fix and 15-UAT.md's G-15-2 pass
- `.planning/debug/wifi-hidden-network-not-detected.md` - added missing YAML frontmatter (`status: resolved`); Phase 19 disposition block citing commit `12575ac` and 15-UAT.md's G-15-6 pass
- `.planning/debug/wifi-hidden-network-unsupported.md` - frontmatter `status: diagnosed` → `resolved`; Phase 19 disposition block citing 15-14's fix and 15-UAT.md's G-15-4b pass
- `.planning/debug/wifi-scan-progress-feedback.md` - frontmatter `status: diagnosed` → `resolved`; Phase 19 disposition block citing 15-11's fix and 15-UAT.md's G-15-1 pass
- `.planning/debug/wifi-wrong-password-external-dialog.md` - frontmatter `status: diagnosed` → `resolved`; Phase 19 disposition block citing 15-13's fix (`quickshell/.config/autostart/nm-applet.desktop`) and 15-UAT.md's G-15-4 pass
- `.planning/milestones/v3.0-phases/15-audio-connectivity-panels/deferred-items.md` - G-15-7 entry gained a Phase 19 Disposition section pointing at plan 19-08

## Decisions Made

- **All five debug-session dispositions corrected from the plan's predicted "deferred" to "resolved."** The plan's own action text (following `19-RESEARCH.md`'s LEDGER-04 Ground Truth section) expected an "explicitly-reasoned deferral" for all five, on the finding that "none of the five is fixed as a byproduct of notification-server work" — true, but incomplete: none of the five was fixed BY Phase 19, but all five were already fixed by their OWN Phase 15 gap-closure plans (15-11 through 15-14), landed the same day each was diagnosed in four of five cases, and confirmed `pass` on Phase 15's own round-2 UAT retest. `15-UAT.md`'s Gaps ledger records each with an explicit `gap_id`, `status: resolved`, `resolved_by: <plan>`, and a passing retest — evidence `19-RESEARCH.md`'s own research pass did not cross-check. Rather than write a factually-incorrect deferral, each file's disposition was corrected against the stronger, already-committed evidence, with the correction and its reasoning documented explicitly in each file (never silently) and flagged here as a deviation from the plan's own stated expectation.
- **G-15-7 stays open, deliberately.** Unlike the five session files, G-15-7's own closing condition genuinely has a piece this phase cannot satisfy from documentation alone — a real bluetooth pairing verified against the shipped server. Marking it resolved here would be exactly the fabricated-resolution failure the plan (and `19-RESEARCH.md`'s own LEDGER-04 framing) warns against, so it was pointed at plan `19-08` instead, per the plan's own explicit instruction.
- **No wifi or bluetooth panel source file was opened for editing.** The corrected dispositions rest entirely on `15-UAT.md`'s own Gaps ledger and each debug file's own prior content — the only read-only cross-reference into panel QML was a brief `grep` confirming `BluetoothBackend.qml`/`BluetoothPanel.qml` already contain the `adapterBlocked` fix 15-12 shipped, used purely as corroboration of `15-UAT.md`'s own claim, not as the basis for the disposition. Zero panel files were modified — confirmed by `git diff --name-only` across both task commits.
- **`wifi-hidden-network-not-detected.md` was missing YAML frontmatter entirely** (it used a bare `**Status:**` prose line, not the `status:` key the other four files and the plan's verify script require). Added a proper frontmatter block (Rule 3 — blocking issue: the plan's own automated verify greps for `^status:`) while preserving the original prose header verbatim and noting the frontmatter is the authoritative field.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug/stale documentation] Five debug-session dispositions corrected from "deferred" to "resolved" against a stronger source than the plan anticipated**
- **Found during:** Task 2, before writing any disposition
- **Issue:** The plan's action text, following `19-RESEARCH.md`'s LEDGER-04 Ground Truth section, expected all five open `.planning/debug/` session files to receive an "explicitly-reasoned deferral." Cross-checking `.planning/milestones/v3.0-phases/15-audio-connectivity-panels/15-UAT.md`'s own Gaps ledger (a source not consulted by the Phase 19 research pass) showed all five bugs were already fixed by their own Phase 15 gap-closure plans and confirmed `pass` on round-2 UAT retest — writing a deferral for an already-shipped, already-verified fix would itself have been a form of inaccurate record-keeping.
- **Fix:** Each of the five files' frontmatter `status:` set to `resolved` (one file, `wifi-hidden-network-not-detected.md`, needed a frontmatter block added since it had none), each gaining a dated "Phase 19 Disposition" section citing the specific Phase 15 plan/commit that fixed it, the specific `15-UAT.md` gap_id/result that verified it, and an explicit note correcting `19-RESEARCH.md`'s characterization with reasoning (not silently).
- **Files modified:** `.planning/debug/bluetooth-enable-inert.md`, `.planning/debug/wifi-hidden-network-not-detected.md`, `.planning/debug/wifi-hidden-network-unsupported.md`, `.planning/debug/wifi-scan-progress-feedback.md`, `.planning/debug/wifi-wrong-password-external-dialog.md`
- **Verification:** Plan's own automated verify block (5-file count, per-file status+Phase-19-block grep) passes; each disposition traces to a specific, quoted `15-UAT.md` gap_id/status/resolved_by field.
- **Committed in:** `6b9fa9f` (Task 2 commit)

**2. [Rule 3 - Blocking] Added missing YAML frontmatter to `wifi-hidden-network-not-detected.md`**
- **Found during:** Task 2
- **Issue:** This file used a bare `**Status:**` prose line instead of a `status:` YAML key — the plan's own verify script (`grep -qE '^status:[[:space:]]*(resolved|deferred)'`) would fail against it regardless of disposition content.
- **Fix:** Added a proper YAML frontmatter block (`status`, `trigger`, `created`, `updated`) matching the other four files' convention, and a short note in the body clarifying the frontmatter field is authoritative over the original prose "Status:" line, which was kept verbatim.
- **Files modified:** `.planning/debug/wifi-hidden-network-not-detected.md`
- **Verification:** `grep -qE '^status:[[:space:]]*(resolved|deferred)'` now passes for this file.
- **Committed in:** `6b9fa9f` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 bug/stale-documentation correction spanning 5 files, 1 blocking frontmatter fix). **Impact:** Both deviations improve the accuracy of the planning record without touching any code path; neither expands scope beyond documentation the plan's own task already declared in-scope (`.planning/debug/*.md`, `deferred-items.md`). No wifi or bluetooth panel source file was modified.

## Issues Encountered

None beyond the deviations documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `19-BEHAVIOUR-BASELINE.md` is committed and ready to be read by plan `19-08`'s GATE-02 render gate as its exclusion-aware capability list.
- LEDGER-04 is fully dispositioned: all six items carry a written, dated Phase 19 disposition, with G-15-7 correctly left open and pointed at plan `19-08` rather than fabricated-closed.
- No blockers for the next plan in this phase's wave sequence.

## Self-Check: PASSED

- All created/modified files verified present on disk with `[ -f ]` (19-BEHAVIOUR-BASELINE.md, 5 debug session files, deferred-items.md).
- Both task commits (`7f4c203`, `6b9fa9f`) verified present in `git log --oneline --all`.
- Plan-level `<verification>` re-run: unaccounted-keys closure loop returns empty; 5-file LEDGER-04 count + per-file status/Phase-19-block assertions pass; G-15-7 `19-08` pointer present; `git diff --name-only` across both commits contains zero `.qml`/`.lua`/`.sh`/`.json` files.
- All task-level `<acceptance_criteria>` re-checked and passing (see Deviations section for the two corrections applied along the way).

---
*Phase: 19-notification-server-centre*
*Completed: 2026-08-13*
