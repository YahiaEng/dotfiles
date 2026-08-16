---
phase: 22-fresh-install-proof
plan: 01
subsystem: infra
tags: [podman, container-run, install.sh, aur, gradle, threat-model]

# Dependency graph
requires:
  - phase: 21-media-fold-in-contract-close
    provides: repo at post-migration shape (5 stow packages retired, contract.json at 17 entries)
provides:
  - "A recorded, evidence-based baseline verdict for the unmodified container gate against today's origin/main: overall=FAIL"
  - "Confirmation that the five-deletion reproducibility question (RETIRE-09) is UNTESTED, not failed — the run never got past install.sh --core-only"
  - "A falsification of the T-22-01-DOS threat-model mitigation claim, backed by live podman ps/top/inspect evidence"
  - "The operator's harness-repair-first decision at the plan's Task 3 blocking checkpoint, recorded for the next plan to consume"
affects: [22-02-fresh-install-proof, 22-03-fresh-install-proof, 22-04-fresh-install-proof, 22-05-fresh-install-proof, 22-06-fresh-install-proof]

actuals:
  tokens: 8457
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - .planning/phases/22-fresh-install-proof/22-BASELINE.md
    - .planning/phases/22-fresh-install-proof/baseline-evidence/summary.log
    - .planning/phases/22-fresh-install-proof/baseline-evidence/03-install.log
  modified:
    - .planning/STATE.md

key-decisions:
  - "Operator selected harness-repair-first at the Task 3 blocking checkpoint: three confirmed harness/environment blockers and zero migration evidence means the harness must be fixed before any reproduction conclusion is trustworthy."
  - "RETIRE-09 is NOT marked complete by this plan — the baseline is inconclusive on the actual question, not a pass."

patterns-established: []

requirements-completed: []  # RETIRE-09 intentionally NOT marked complete — see "Decisions Made" below.

coverage:
  - id: D1
    description: "verify/container-run.sh run once, unmodified, against today's origin/main; verdict, exit code, per-step ledger, and per-step failure logs captured as raw evidence"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: ".planning/phases/22-fresh-install-proof/22-BASELINE.md ## Run identity, ## Verdict, ## Step ledger"
        status: pass
    human_judgment: false
  - id: D2
    description: "22-BASELINE.md authored with all seven required sections; the two decisive logs copied verbatim/truncated-and-labeled into baseline-evidence/, surviving the verify/logs/ gitignore"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "diff -q baseline-evidence/summary.log verify/logs/run-20260816T191755Z/summary.log; grep section-presence check"
        status: pass
    human_judgment: false
  - id: D3
    description: "The theme-doctor failure inventory (D-22-09's sole admissible input) is unavailable this run and explicitly recorded as such, with no fabricated substitute — plan 22-04 is blocked"
    verification: []
    human_judgment: true
    rationale: "Absence of data is a phase-shape finding requiring operator awareness, not a mechanically verifiable pass/fail — the operator already confirmed this reading at the Task 3 checkpoint."
  - id: D4
    description: "T-22-01-DOS threat-model mitigation claim is falsified by direct measurement (podman ps/top/inspect showing the container still running minutes after the host wrapper's timeout-driven exit)"
    verification:
      - kind: manual_procedural
        ref: ".planning/phases/22-fresh-install-proof/22-BASELINE.md ## Harness health (THREAT-MODEL FINDING block)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Task 3 blocking checkpoint (world-selection decision) presented to and answered by the operator: harness-repair-first"
    verification: []
    human_judgment: true
    rationale: "A blocking human decision by design — the plan explicitly withholds a recommendation and requires operator judgment on which world the baseline fits."

duration: ~72min
completed: 2026-08-16
status: complete
---

# Phase 22 Plan 01: Baseline Measurement Summary

**Ran the unmodified `verify/container-run.sh` gate against today's `origin/main`: it FAILED for two harness/environment reasons unrelated to the migration, leaving RETIRE-09's actual reproducibility question untested — operator chose harness-repair-first.**

## Performance

- **Duration:** ~72 min (most of it the container run itself: image pull + ~63 min of `install.sh --core-only` before the 3600s timeout fired, then several more minutes of undetected orphaned-container runtime)
- **Started:** 2026-08-16T19:17:06Z
- **Completed:** 2026-08-16T20:28:51Z
- **Tasks:** 3 (Task 1 tracer-style run + capture, Task 2 write BASELINE.md + copy evidence, Task 3 blocking checkpoint)
- **Files modified:** 4 (`22-BASELINE.md`, `baseline-evidence/summary.log`, `baseline-evidence/03-install.log`, `.planning/STATE.md`)

## Accomplishments

- Ran `verify/container-run.sh` completely unmodified against `origin/main` (confirmed byte-identical via `git diff --quiet origin/main -- verify/container-run.sh`), producing a real, dated `verify/logs/run-20260816T191755Z/` evidence run.
- Discovered and documented **two independent, non-migration causes** for the `overall=FAIL` verdict: (1) the 3600s `CONTAINER_TIMEOUT` is undersized for the current ~32-package AUR batch, and (2) the timeout wrapper's `SIGKILL` only stops the host-side `podman run` client, not the actual conmon-owned container under rootless podman — independently verified live via `podman ps -a`/`podman top`/`podman inspect` showing the container still building AUR packages several minutes after the host script had already exited with its own verdict.
- Found, via the orphaned container continuing to run on its own, a **real but pre-existing** `install.sh` defect: `limine-dracut-support` (in `install.sh` since 2026-03-14, unrelated to any of the five deleted packages) fails to build against the `archlinux/archlinux:latest` image's Gradle version (`Cannot find module 'gradle-public-api-legacy'`).
- Falsified this plan's own threat-model line T-22-01-DOS ("the timeout wrapper bounds the whole run") with direct measurement, and recorded that finding explicitly rather than letting it stand unchallenged.
- Presented the Task 3 blocking checkpoint with the full evidence set; operator selected **harness-repair-first**, recorded in `22-BASELINE.md ## Checkpoint resolution`.

## Task Commits

Each task was committed atomically:

1. **Precondition housekeeping: sync pending STATE.md bookkeeping so the clean-tree precondition holds** - `9169785` (docs)
2. **Task 1 + Task 2: run the container gate and write 22-BASELINE.md + copy evidence** - `de74b5a` (docs)
3. **Task 3 resolution: record operator decision + T-22-01-DOS falsification** - `eacd114` (docs)

**Plan metadata:** *(pending — this SUMMARY + STATE.md + ROADMAP.md commit, made immediately after this document)*

## Files Created/Modified

- `.planning/phases/22-fresh-install-proof/22-BASELINE.md` - the full baseline record: run identity, verdict, harness-health finding, step ledger, empty theme-doctor inventory (data doesn't exist yet), defects surfaced, not-done-here note, and the checkpoint resolution
- `.planning/phases/22-fresh-install-proof/baseline-evidence/summary.log` - verbatim copy of the run's machine-readable summary (survives the `verify/logs/` gitignore)
- `.planning/phases/22-fresh-install-proof/baseline-evidence/03-install.log` - truncated copy (head + the full `limine-dracut-support` failure block + tail, omission explicitly labeled) of the 1.3MB install log, substituted for the plan's originally-expected `05-theme-doctor.log`, which this run never produced
- `.planning/STATE.md` - phase-transition bookkeeping sync (pre-existing drift, committed to satisfy the precondition check) plus, in this final commit, position/decision updates

## Decisions Made

- **Precondition compliance:** the working tree had a pre-existing uncommitted `.planning/STATE.md` bookkeeping edit (phase-name casing, timestamp, position — unrelated to anything the harness clones/tests) at plan start. Committed and pushed it before the precondition check, since the plan's own Task 1 acceptance criteria scope the "clean tree" verification to `git status --porcelain -- ':!.planning'` — confirming `.planning/` churn is expected and out of scope for the precondition's actual purpose (not letting a local-only commit to the *tested* tree diverge from what the harness clones).
- **Substituted `03-install.log` for the plan's expected `05-theme-doctor.log`.** The run never reached `theme-doctor` in either the host's timeout-truncated view or the in-container script's own eventual conclusion, so `05-theme-doctor.log` does not exist. Per explicit instruction, no placeholder was fabricated for it — `03-install.log` (the log that actually contains the failing step's evidence) was copied instead, truncated with the omission clearly labeled since the full file is 1.3MB of mostly curl-progress-bar noise.
- **`RETIRE-09` deliberately NOT marked complete** (`requirements-completed: []`) despite being in this plan's frontmatter `requirements` field. This plan's job was measurement, not closure — the baseline is inconclusive on RETIRE-09's actual question (whether the five deletions broke reproduction), and marking the requirement complete here would falsely claim the fresh-install proof passed when it is, in fact, blocked pending harness repair.
- **Operator decision, recorded verbatim in `22-BASELINE.md`:** `harness-repair-first`. Reasoning: D-22-12 exists so a harness bug is never attributed to the migration; there are three confirmed harness/environment blockers and zero migration evidence right now. The baseline fits none of the plan's three anticipated worlds cleanly — closest to world 3 ("harness did not complete"), but differing in that `overall=` lines were written twice, by two different writers, about two different non-migration failures.
- **Manually stopped the orphaned container** (`podman kill`/`podman rm -f`, though it had already self-terminated by the time the command ran) after all evidence was captured. This is host-resource cleanup of a runaway process this measurement itself created — not a change to any tracked file or to the harness's behavior — and happened only after every fact in `22-BASELINE.md` was already recorded.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Committed pending `.planning/STATE.md` drift to satisfy the clean-tree precondition**
- **Found during:** Task 1 precondition check
- **Issue:** `git status --porcelain` was non-empty (pre-existing orchestrator bookkeeping edit to `.planning/STATE.md`), which the plan's precondition literally requires to be empty before proceeding.
- **Fix:** Committed and pushed the pending `.planning/STATE.md` edit (phase-name casing, timestamp, position — pure bookkeeping, unrelated to what the harness clones/tests).
- **Files modified:** `.planning/STATE.md`
- **Committed in:** `9169785`

**2. [Rule 3 - Blocking] Copied `03-install.log` in place of the plan-expected `05-theme-doctor.log`**
- **Found during:** Task 2, after Task 1's run never reached the `theme-doctor` step
- **Issue:** The plan's Task 2 `<action>` and acceptance criteria assume `05-theme-doctor.log` exists to copy; it does not, because the run failed before `stow.sh`/`theme-doctor` ran.
- **Fix:** Copied `03-install.log` (truncated, labeled) instead, since it is the log that actually contains the failing step's evidence. No placeholder fabricated for the missing `05-theme-doctor.log`; its absence is recorded plainly in `22-BASELINE.md`'s failure-inventory section.
- **Files modified:** `.planning/phases/22-fresh-install-proof/baseline-evidence/03-install.log`
- **Committed in:** `de74b5a`

---

**Total deviations:** 2 auto-fixed (both Rule 3 - blocking, needed to complete the plan's own tasks under conditions the plan text didn't anticipate).
**Impact on plan:** Neither deviation changed what the plan measures or reports — both were necessary adaptations to reality (a pre-existing bookkeeping drift, and a missing log the run's own failure mode made unreachable). No scope creep; no fix applied to any tracked file outside `.planning/`.

## Issues Encountered

- **The container gate's own timeout mechanism doesn't stop the container it's supposed to bound**, discovered by direct, independent measurement after the host-side wrapper had already exited — see `22-BASELINE.md ## Harness health` for the full account and the T-22-01-DOS threat-model falsification. Not fixed here; flagged for the harness-repair plan.
- **A real, pre-existing AUR package build failure** (`limine-dracut-support` vs. the container image's Gradle version) blocks `install.sh --core-only` independent of anything this milestone changed. Not fixed here; flagged for the harness-repair plan (or a separate install.sh fix, depending on how that plan scopes it).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `.planning/phases/22-fresh-install-proof/22-BASELINE.md` is the complete, committed record the harness-repair plan needs as its starting evidence — no re-measurement required before that plan begins.
- **Blocker for plan 22-04:** the `theme-doctor` failure inventory (D-22-09's only admissible input) does not exist yet. 22-04 cannot proceed until a run reaches `step=theme-doctor`.
- **Blocker for the rest of the wave graph:** per the operator's `harness-repair-first` decision, a new plan (outside this plan's scope, being created separately) must land before 22-02/22-03 can be trusted to build on a working baseline — the container gate needs its timeout-kill mechanism and budget fixed, and the `limine-dracut-support` build failure needs a resolution, before RETIRE-09's actual reproducibility question can be tested at all.

---
*Phase: 22-fresh-install-proof*
*Completed: 2026-08-16*

## Self-Check: PASSED

All 4 claimed files verified present on disk; all 3 claimed commits verified present in `git log --oneline --all`.
