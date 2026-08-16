---
phase: 22-fresh-install-proof
plan: 05
subsystem: infra
tags: [container-run, retirement-check, stow-link-check, theme-doctor, fresh-install-proof]

# Dependency graph
requires:
  - phase: 22-fresh-install-proof
    plan: 04
    provides: "run-20260816T230409Z: the green, five-gate container run (overall=PASS, all nine step tokens ok, theme-doctor allowed=3 blocking=0) this plan closes SC-1/SC-2/SC-3's mechanical halves on"
provides:
  - "22-DEFECTS.md: the fix-and-re-run loop's zero-iteration record, with the independent re-verification that earned closing on 22-04's existing run rather than re-running the ~17min container gate"
  - "green-evidence/{summary,04a-retirement-check,04b-stow-link-check,05-theme-doctor}.log: the green run's four decisive logs, committed past verify/logs/'s gitignore — the durable proof this gate ever passed"
  - "SC-1, SC-2 and SC-3's mechanical halves closed on cited evidence lines, with the graphical-tier gap named explicitly as still open"
affects: [22-06-fresh-install-proof]

actuals:
  tokens: 22800
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Closing a success criterion by citing a specific evidence line rather than a summary claim — the same discipline as retirement-check's own report tier, applied one level up at the plan-summary layer"

key-files:
  created:
    - .planning/phases/22-fresh-install-proof/22-DEFECTS.md
    - .planning/phases/22-fresh-install-proof/green-evidence/summary.log
    - .planning/phases/22-fresh-install-proof/green-evidence/04a-retirement-check.log
    - .planning/phases/22-fresh-install-proof/green-evidence/04b-stow-link-check.log
    - .planning/phases/22-fresh-install-proof/green-evidence/05-theme-doctor.log
  modified: []

key-decisions:
  - "Closed on plan 22-04's existing green run rather than launching a new ~17-minute container re-run. The plan authorizes both paths explicitly, conditioned on independently re-verifying the existing run's evidence rather than trusting its SUMMARY prose. That verification was performed line-by-line against all four raw logs (not sampled), cross-checked against a clean HEAD==origin/main and a git log confirming zero repository or harness changes have landed since the green run — see 22-DEFECTS.md's verification section for the full record."
  - "Task 1's bounded fix-and-re-run loop produced zero iterations and zero rows in 22-DEFECTS.md — not because the loop was skipped, but because its own precondition (a failing step) was never true. Recorded as a legitimate, substantive finding (the five package deletions did not break reproduction) rather than an absence of work, per this plan's own framing."
  - "Task 3's decision checkpoint was not triggered — it exists only for a loop that exhausts four iterations without reaching green or a defect requiring architectural authorization, and Task 1 never entered iteration 1."

patterns-established: []

requirements-completed: []  # RETIRE-09 intentionally NOT marked complete — SC-1/SC-2/SC-3's mechanical halves close here, but the graphical VM tier (plan 22-06) and its human verdict remain outstanding, matching every prior plan in this phase's declared precedent of declining to close it early.

coverage:
  - id: D1
    description: "SC-1's mechanical half closes: the D-34/D-36 container gate ran green against a genuine fresh remote clone through install.sh + stow.sh, with theme-parity passing inside that fresh install"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "green-evidence/summary.log: overall=PASS; step=clone status=ok (shallow clone of the public remote, not a copy of the developer tree); step=install status=ok; step=stow status=ok; step=theme-parity status=ok"
        status: pass
    human_judgment: false
  - id: D2
    description: "SC-2 closes on evidence gathered from inside the reproduced system (the container), not the developer host which still has the old packages installed"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "green-evidence/04a-retirement-check.log: failed_classes=0 for all 8 registered surfaces (waybar, swaync, swayosd, wleave, ags, wlogout, eww, retirement-fixture), including the host-package pacman -Q class run against the container itself; green-evidence/04b-stow-link-check.log: 3 passed, 0 failed across three present sweep roots (.config 43 symlinks, Pictures/Wallpapers 92 symlinks, . 1 symlink), none dangling"
        status: pass
    human_judgment: false
  - id: D3
    description: "SC-3's mechanical half closes: zero blocking failures across all eight registered surfaces, plus the one-time human read of surviving non-.planning hits (performed by plan 22-03, verified present here rather than re-done)"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "green-evidence/04a-retirement-check.log: failed_classes=0 x8; 22-03-SUMMARY.md: README.md's Notifications row and repo-tree diagram corrected, env.lua's client enumeration rewritten (not scrubbed) — the two known non-.planning hits named in this phase's own context"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every defect the container tier surfaced was fixed, not deferred — the fix-and-re-run loop found zero defects to fix, confirmed by independent re-verification rather than trust"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "22-DEFECTS.md: 0 iterations, 0 rows, full re-verification record (HEAD==origin/main, git log clean since the green run, all four raw logs read and cross-checked against 22-04-SUMMARY.md's claims)"
        status: pass
    human_judgment: false

duration: ~15min
completed: 2026-08-17
status: complete
---

# Phase 22 Plan 05: Fresh-Install Fix Loop and SC-1/SC-2/SC-3 Closure Summary

**The container tier's fix-and-re-run loop found zero defects — the five stow-package deletions did not break fresh-install reproduction — and SC-1, SC-2 and SC-3's mechanical halves close on plan 22-04's already-green, independently re-verified run: `overall=PASS`, all eight retirement-check surfaces at `failed_classes=0` from inside the reproduced container, zero dangling symlinks across three swept roots.**

## Performance

- **Duration:** ~15 min (Task 1 re-verification + 22-DEFECTS.md ~10min, Task 2 evidence copy + this summary ~5min)
- **Tasks:** 2 (Task 3's checkpoint not triggered — Task 1 never entered its first iteration)
- **Files modified:** 6 (`22-DEFECTS.md` created, 4 `green-evidence/*.log` files created, this SUMMARY)

## Accomplishments

- **Task 1 — the fix-and-re-run loop ran zero iterations, and that is the finding, not a shortcut.** Plan 22-04's own run (`run-20260816T230409Z`, `origin/main` at `56a9bd5`, warm cache) had already reached `overall=PASS` with all nine gating step tokens `status=ok` before this plan started, so the loop's own precondition — a failing step to extract a defect from — was never true. Per this plan's explicit instruction not to take the green run on trust, independently re-verified rather than accepted it: confirmed `HEAD == origin/main` (`1da4da968118ab76403e8e8165fc3b333b83483e`, clean tree), confirmed `git log` shows only doc-only commits on top of 22-04's run-recording commit (no repository or harness change since the green run), read all four copied evidence logs in full and cross-checked every claim in 22-04-SUMMARY.md against the raw log content line-by-line (not sampled) — every one held. Confirmed `verify/container-run.sh` on `origin/main` still carries all nine step tokens and zero informational statuses, and all three of 22-04's commits (`4662571`, `56a9bd5`, `5657fda`) are present on the remote. Recorded the full verification and the zero-defect finding in `22-DEFECTS.md`.
- **Task 2 — green run evidence committed, SC-1/SC-2/SC-3's mechanical halves closed on cited lines.** Copied the four decisive logs from the already-committed `baseline-evidence/22-04-*.log` copies into `green-evidence/` (byte-identical, `diff -q` confirmed) — the canonical location this plan's own artifact spec names, since `verify/logs/` itself is gitignored and would otherwise leave no durable proof the gate ever passed. Closure argument written into this summary's `coverage` block, each criterion tied to a cited log line: SC-1 to `overall=PASS` plus the `clone`/`install`/`stow`/`theme-parity` step tokens; SC-2 to `04a-retirement-check.log`'s `failed_classes=0` across all 8 surfaces (explicitly noting the `host-package` class ran `pacman -Q` against the container, answering the question the dev host cannot) and `04b-stow-link-check.log`'s zero-dangling result across its three named present roots; SC-3 to the same `failed_classes=0` count plus plan 22-03's already-performed human read of the surviving non-`.planning` hits (README.md, env.lua), verified present rather than re-done.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix, push, re-run — zero-iteration loop, independently re-verified** — `42ce7fc` (docs)
2. **Task 2: Commit the green run's evidence** — `aad237a` (docs)

**Plan metadata:** *(pending — this SUMMARY + STATE.md + ROADMAP.md commit, made immediately after this document)*

## Files Created/Modified

- `.planning/phases/22-fresh-install-proof/22-DEFECTS.md` — new, the zero-iteration record and its full independent-verification trail
- `.planning/phases/22-fresh-install-proof/green-evidence/summary.log` — copied from `baseline-evidence/22-04-summary.log`, byte-identical
- `.planning/phases/22-fresh-install-proof/green-evidence/04a-retirement-check.log` — copied, byte-identical
- `.planning/phases/22-fresh-install-proof/green-evidence/04b-stow-link-check.log` — copied, byte-identical
- `.planning/phases/22-fresh-install-proof/green-evidence/05-theme-doctor.log` — copied, byte-identical

## Decisions Made

- **Closed on plan 22-04's existing run rather than launching a new container re-run.** See `key-decisions` in frontmatter. The plan sanctions both paths; the re-verification requirement attached to the "close on the existing run" path was actually performed (four raw logs read in full, cross-checked against the SUMMARY's claims, HEAD/origin/main drift checked, harness step-token integrity checked), not skipped in favor of trusting prose.
- **Task 3's checkpoint was not triggered.** It exists only for a loop that exhausts four iterations without reaching green, or a defect whose fix would require architectural authorization. Neither condition arose — Task 1 never entered its first iteration because there was no failing step to work from.

## Allowlist strictness — carried forward unchanged from 22-04

Per this plan's own read-first instructions, the caveat 22-04's SUMMARY recorded is carried forward rather than smoothed over: the allowlist's rejection behavior (a *new*, non-admitted `theme-doctor` failure correctly failing the container harness end-to-end) was proven only by a local, out-of-container dry-run of the identical parsing/matching logic, not inside a real podman container. The live run this plan closes on only ever exercised the "everything admitted, `blocking=0`" branch. This is not upgraded to "proven strict" anywhere in this plan's SC-2 closure argument.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed as written for both `Task` blocks. Task 1's zero-iteration outcome is not a deviation; it is the plan's own explicitly anticipated outcome ("this task's fix-and-re-run loop should terminate on its first iteration with an empty fix list").

## Issues Encountered

- **The original run directory `verify/logs/run-20260816T230409Z` no longer exists on disk** — only the four files 22-04 already copied into `baseline-evidence/` survive, since `verify/logs/` is gitignored and the run directory itself is ephemeral (not preserved by design). This did not block verification: the copied logs were read in full and their content matches 22-04-SUMMARY.md's claims exactly, and no repository or harness change has landed since the run that could plausibly explain a discrepancy between the (now-gone) live run and its committed copy.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **SC-1, SC-2 and SC-3's mechanical halves are closed on cited, independently re-verified evidence.** `RETIRE-09` remains open by design — plan 22-06's graphical VM tier and its mandatory human render-and-look verdict are still required (the container renders nothing; every QML surface this milestone built is invisible to it).
- **The container tier's own job is done.** No further container re-runs are anticipated for this phase; plan 22-06 moves to the graphical tier entirely.
- **Push discipline held.** `HEAD == origin/main` was confirmed at plan start and both task commits landed on `origin/main` directly (no branching in this repo's git config).

---
*Phase: 22-fresh-install-proof*
*Completed: 2026-08-17*

## Self-Check: PASSED

All 5 claimed files verified present on disk; both task commits (`42ce7fc`, `aad237a`) verified present in `git log --oneline --all`.
