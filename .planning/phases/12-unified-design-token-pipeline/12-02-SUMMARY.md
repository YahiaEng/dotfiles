---
phase: 12-unified-design-token-pipeline
plan: 02
subsystem: infra
tags: [quickshell, requirements-governance, roadmap-amendment, bash]

# Dependency graph
requires:
  - phase: 12-unified-design-token-pipeline (12-01)
    provides: "12-QS03-EVIDENCE.md's full STOP-branch record — two structurally distinct arrangements attempted, both reproducing an FM2-class multiplicity failure on quickshell 0.3.0-2, re-proven across a real session restart"
provides:
  - "QS-03 formally moved to Out of Scope in REQUIREMENTS.md, PROJECT.md and ROADMAP.md (D-13, one-way) — accept-permanent branch, not the close-qs03 no-op"
  - "quickshell-doctor's per-screen surface creation check converted to a documented D-14 SKIP (QS03_ACCEPTED_PERMANENT guard), script back to a usable exit signal for its other 13 checks"
  - "REQUIREMENTS.md active-requirement count corrected 38 -> 37 (38 ever defined, 1 dropped), Phase 12's per-phase count corrected 7 -> 6"
affects: [phase-16-workspace-overview, quickshell-doctor, REQUIREMENTS.md, PROJECT.md, ROADMAP.md]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Boolean acceptance guard checked BEFORE a probe-summon side effect, not after — an accepted limitation should not keep paying for the mutation it no longer needs to observe (mirrors the file's existing --no-headless-output/--no-summon guard-before-mutation shape)"

key-files:
  created:
    - .planning/phases/12-unified-design-token-pipeline/12-02-SUMMARY.md
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/PROJECT.md
    - .planning/ROADMAP.md
    - hypr/.config/hypr/scripts/quickshell-doctor
    - .planning/phases/12-unified-design-token-pipeline/deferred-items.md

key-decisions:
  - "Task 1's blocking D-13 checkpoint was answered accept-permanent by the user before this executor ran (relayed via the orchestrator's checkpoint_already_resolved context) — not re-presented. Recorded here as the branch taken, per the plan's own instruction to state the selected option verbatim."
  - "QS03_ACCEPTED_PERMANENT is a single top-of-file guard variable, not a --qs03-accepted CLI flag, per the plan's explicit instruction: acceptance is a property of this repo on this quickshell version, not a per-invocation choice a future run could silently flip."
  - "The pre-existing, unrelated one-step-per-press volume-probe gate brittleness (surfaced in 12-01, already filed as a pending todo) was left unfixed, per scope discipline — it keeps quickshell-doctor's exit code at 1 (12 passed, 1 failed) rather than the plan's expected 13 passed / 0 failed, documented as a deviation below rather than silently accepted."

patterns-established:
  - "A one-way roadmap/requirements drop amends ROADMAP.md criteria and placement paragraphs in place with a dated, phase-named amendment note appended after the original sentence — never a silent rewrite (the D-15 precedent Phase 11 set, reapplied here for D-13)."

requirements-completed: [QS-03]

coverage:
  - id: D1
    description: "QS-03 recorded as Out of Scope across REQUIREMENTS.md (checkbox note, Out of Scope table row, Traceability row, Coverage counts), PROJECT.md (Out of Scope section) and ROADMAP.md (Phase 12 criterion 6 amended in place, Carried-in maintenance placement paragraph amended in place), all three referencing 12-QS03-EVIDENCE.md"
    requirement: QS-03
    verification:
      - kind: other
        ref: "grep -c QS-03 across all three files (7/1/10); grep -l 12-QS03-EVIDENCE across all three files (all present); git diff --stat .planning/ROADMAP.md shows a small, Phase-12-scoped edit with no other phase heading removed"
        status: pass
    human_judgment: false
  - id: D2
    description: "quickshell-doctor's per-screen surface creation check converted to a guarded D-14 SKIP printing its reason and evidence pointer, branching before the summon, reversible by flipping QS03_ACCEPTED_PERMANENT back to 0"
    requirement: QS-03
    verification:
      - kind: manual_procedural
        ref: "bash -n and shellcheck both clean; live run with guard=1 shows the SKIP line with both required strings; live run with guard=0 (toggled and reverted) reproduces the original FAIL verbatim (found: 0 on both DP-1 and the headless output); grep -c QS03_ACCEPTED_PERMANENT returns 4"
        status: pass
    human_judgment: false
  - id: D3
    description: "quickshell-doctor exits 0 with Summary: 13 passed, 0 failed"
    requirement: QS-03
    verification:
      - kind: manual_procedural
        ref: "live run: Summary: 12 passed, 1 failed, exit 1"
        status: fail
    human_judgment: true
    rationale: "The one remaining FAIL is a pre-existing, unrelated volume-probe gate brittleness (over-strict exact-match on rounding-sensitive raw PulseAudio units) first surfaced during 12-01's session-restart re-proof, confirmed there as predating this plan's file scope and already filed as a pending todo. This task's own scope — the per-screen check — behaves exactly as designed (verified in D2). Whether accepting this as the plan's closing state (rather than pulling the volume-probe fix into scope) is correct requires human judgment, since it means the plan's literal exit-code acceptance criterion is not met for a reason outside the plan's declared files."

# Metrics
duration: ~15min
completed: 2026-07-26
status: complete
---

# Phase 12 Plan 02: D-13 One-Way Decision — QS-03 Accepted as a Permanent Limitation Summary

**Branch taken: `accept-permanent`.** QS-03 (per-screen Quickshell surface fan-out) is formally moved to Out of Scope in REQUIREMENTS.md, PROJECT.md and ROADMAP.md, and `quickshell-doctor`'s per-screen check is now a documented D-14 SKIP rather than a standing FAIL — this is the acceptance-branch work, not the `close-qs03` no-op.

## Performance

- **Duration:** ~15 min
- **Tasks:** 3 (Task 1: checkpoint:decision, pre-resolved by the user as `accept-permanent`; Task 2: auto; Task 3: auto)
- **Files modified:** 5

## Task 1: D-13 Checkpoint — Resolved

**This checkpoint was already presented to and answered by the user before this executor session began** (relayed via the orchestrator's `checkpoint_already_resolved` context, carrying the full 12-01 evidence: the STOP branch, three failed arrangements/proof runs plus the Phase 11 spike, and the refinement that `quickshell-doctor` reports `DP-1` itself at `found: 0` once a second screen exists — not merely a one-sided miss on the new screen).

**Selected option: `accept-permanent`** — QS-03 is accepted as a permanent limitation under D-13 (one-way). The user explicitly confirmed understanding that this is one-way and that Phase 16's full-screen per-monitor overview inherits a root that cannot fan out.

This was **not** re-presented to the user by this executor, per explicit instruction. Tasks 2 and 3 below are the acceptance work this decision authorizes, executed in full.

## Accomplishments

- **QS-03 formally dropped to Out of Scope across all three planning artifacts, with a reachable evidence pointer from every one of them.** `REQUIREMENTS.md`'s QS-03 checkbox note, Out of Scope table, and Traceability row all now read "Out of Scope" / "Dropped" rather than "Deferred (carried forward from Phase 11)"; the active-requirement Coverage counts were corrected from a stale 38 to 37 (38 ever defined, 1 dropped), and Phase 12's per-phase count from 7 to 6. `PROJECT.md`'s Out of Scope section gained a QS-03 row stating the reason in the project's own terms plus the Phase 16 consequence. `ROADMAP.md`'s Phase 12 criterion 6 and the "Carried-in maintenance placement" QS-03 paragraph were both amended **in place** — original sentences preserved, an italicised dated amendment note appended naming Phase 12, D-13, and `12-QS03-EVIDENCE.md` — following the exact D-15 amendment precedent Phase 11 set for its own criterion 2.
- **`quickshell-doctor`'s per-screen surface creation check is now a documented SKIP, not a standing FAIL.** A single guard variable (`QS03_ACCEPTED_PERMANENT=1`), with a full record-why comment block naming D-13, the bounded re-attempt, and `12-QS03-EVIDENCE.md`, gates the check *before* the probe summon — so an accepted limitation no longer pays for a probe-dispatch cycle it doesn't need. The SKIP line prints verbatim per `12-UI-SPEC.md`'s Copywriting Contract: `SKIP — per-screen surface fan-out accepted as a permanent limitation (single-monitor host, quickshell 0.3.0). See 11-VERIFICATION.md overrides[0] and 12-CONTEXT.md D-13.` The other three headless-output checks (add / reserved-unchanged / remove) stay live and still PASS.
- **Reversibility verified live, not just asserted.** Flipping `QS03_ACCEPTED_PERMANENT` to `0` and re-running reproduced the original failing check verbatim (`per-screen surface creation (QS-03): ... found: 0 ... found: 0`, matching 12-01's evidence exactly), then the flag was reverted to `1` and the SKIP confirmed restored. No `--qs03-accepted` CLI flag was added, per the plan's explicit instruction that acceptance is a property of this repo on this quickshell version, not a per-invocation choice.
- The file's `Usage:` header block was extended with a short note pointing at the guard variable and the evidence, so a reader sees the caveat without reading 450 lines.

## Task Commits

1. **Task 1: D-13 one-way door — close QS-03 or accept it as a permanent limitation** - resolved pre-session by the user (`accept-permanent`); no commit (decision-only checkpoint).
2. **Task 2: Move QS-03 to Out of Scope across REQUIREMENTS.md, PROJECT.md and ROADMAP.md** - `c9aac79` (docs)
3. **Task 3: quickshell-doctor documented SKIP for the per-screen check, exit 0 restored (partially — see Deviations)** - `e3113bf` (feat)

**Plan metadata:** (this commit, docs: complete plan)

## Files Created/Modified

- `.planning/REQUIREMENTS.md` - QS-03 checkbox note reworded to Out-of-Scope, new Out of Scope table row, Traceability row and footer note updated to record the drop, Coverage counts corrected 38→37 active / Phase 12 7→6
- `.planning/PROJECT.md` - new QS-03 row in `## Out of Scope`, stating the Phase 12 re-attempt, why upstream wasn't an option, the single-monitor host context, and the Phase 16 consequence
- `.planning/ROADMAP.md` - Phase 12 criterion 6 amended in place with a dated D-13 amendment note; the "Carried-in maintenance placement" QS-03 paragraph amended in place the same way
- `hypr/.config/hypr/scripts/quickshell-doctor` - `QS03_ACCEPTED_PERMANENT` guard + record-why comment block added near the top; per-screen check branches on it before the summon, printing the D-14 SKIP line; `Usage:` header extended with a pointer note
- `.planning/phases/12-unified-design-token-pipeline/deferred-items.md` - new `## 12-02` entry documenting the pre-existing, unrelated volume-probe brittleness that keeps the script's exit code non-zero

## Decisions Made

- **Task 1's checkpoint was not re-presented.** The orchestrator's context explicitly carried the user's prior `accept-permanent` answer with full evidence already reviewed; re-asking would have contradicted the executor's instructions and wasted the user's time on a decision already made.
- **`QS03_ACCEPTED_PERMANENT` is a guard variable, not a CLI flag.** Matches the plan's explicit instruction: the acceptance is a fact about this repo on this quickshell version, not something a future invocation should be able to silently opt out of.
- **The volume-probe brittleness was left unfixed and documented rather than pulled into scope**, even though fixing it would have let the script hit its literal "13 passed, 0 failed, exit 0" acceptance criterion. It is a different, pre-existing, already-tracked bug (`.planning/todos/pending/quickshell-doctor-volume-probe-brittle.md`, filed during 12-01) unrelated to the per-screen check this task owns — scope discipline over criterion-chasing.

## Deviations from Plan

### Auto-fixed Issues

None — no bugs, missing critical functionality, or blocking issues were found in this plan's own declared scope.

### Documented Divergence (not auto-fixed, per scope discipline)

**1. [Scope boundary — pre-existing, unrelated] `quickshell-doctor` exits 1 (12 passed, 1 failed), not the plan's expected 13 passed / 0 failed, exit 0**
- **Found during:** Task 3's verification run
- **Issue:** The plan's acceptance criteria for Task 3 were written against the pre-12-01 baseline (13 passed, 1 failed, with QS-03 as the sole failure). 12-01's own evidence record already shows a second, unrelated failure appeared during its session-restart re-proof: a `one-step-per-press volume probe` gate that is over-strict exact-match on rounding-sensitive raw PulseAudio units — confirmed there as pre-existing (last touched by Phase 11 commits), not caused by any file 12-01 or 12-02 modified, and filed as a pending todo rather than fixed.
- **Fix:** Not fixed. This task's own scope (the per-screen check) was verified working exactly as designed — SKIP line present with both required strings, contributes to neither PASS nor FAIL, other three headless-output checks stay live and PASS, and the guard is confirmed reversible. The volume-probe issue is out of `files_modified` scope for this plan (a different check's logic, already tracked elsewhere) and was left untouched per the scope-boundary rule.
- **Files modified:** None beyond the documented `quickshell-doctor` SKIP change; this deviation required no file change.
- **Verification:** Live runs recorded in `deferred-items.md`'s new `## 12-02` entry: `Summary: 12 passed, 1 failed`, exit 1, with the sole FAIL being the volume-probe line.
- **Committed in:** `e3113bf` (Task 3 commit) plus the `deferred-items.md` entry in the same commit.

---

**Total deviations:** 0 auto-fixed; 1 documented divergence from a literal acceptance criterion, left unfixed per scope discipline and logged for whoever next resolves the pre-existing volume-probe brittleness.
**Impact on plan:** QS-03's own disposition (the plan's actual subject) is fully and correctly closed — Out of Scope in all three artifacts, `quickshell-doctor`'s per-screen check converted to an honest, reversible SKIP. The residual non-zero exit code is a pre-existing, already-tracked, unrelated bug's fault, not a gap in this plan's work.

## Issues Encountered

- See the Documented Divergence above — the only issue encountered was the mismatch between the plan's literal exit-code acceptance criterion and the pre-existing volume-probe brittleness discovered in 12-01. Resolved by scope discipline (leave it, document it) rather than by expanding this plan's file scope to fix an unrelated bug.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **QS-03 is closed for the milestone.** Phase 16's workspace overview (the only remaining phase that would have needed the fan-out) now plans against a known, permanent, documented limitation rather than an open question — it must design its per-monitor overview around a shell root that cannot fan out.
- **`quickshell-doctor` remains a credible, rerunnable gate.** Its per-screen check reads as an honest SKIP with a reason and evidence pointer rather than a standing red that trains readers to ignore the summary line. Re-enabling the real check (if a future quickshell build fixes the underlying `Variants`+`PanelWindow` multiplicity limitation) is a one-line flip of `QS03_ACCEPTED_PERMANENT`, confirmed working during this task.
- **The pre-existing volume-probe brittleness is still open**, tracked in `.planning/todos/pending/quickshell-doctor-volume-probe-brittle.md` (filed in 12-01, re-confirmed here) and now additionally logged in this phase's `deferred-items.md`. It is the reason `quickshell-doctor` still exits non-zero; not blocking, not this plan's responsibility, but visible to whoever next touches the file.
- **12-04 (motion-scale axis) is unblocked** — this plan's file scope (`REQUIREMENTS.md`, `PROJECT.md`, `ROADMAP.md`, `quickshell-doctor`) does not intersect 12-03's motion-engine files or 12-04's planned Hyprland/motion-scale work.

---
*Phase: 12-unified-design-token-pipeline*
*Completed: 2026-07-26*
