---
phase: quick
plan: 260709-a5i
subsystem: infra
tags: [install.sh, paru, AUR, packaging]

# Dependency graph
requires: []
provides:
  - "install.sh AUR_PKGS no longer contains the dead alpm_octopi_utils entry that conflicted with octopi"
affects: [03-04-container-gate, INST-03]

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified: [install.sh]

key-decisions:
  - "Removed alpm_octopi_utils entirely rather than swapping to alpm_octopi_utils-git — octopi 0.19.0 no longer depends on either package, so no replacement entry is needed"

patterns-established: []

requirements-completed: []  # INST-03 NOT marked complete — full container/VM run + human sign-off remains outstanding (see REQUIREMENTS.md line 37/107); this quick task only removes the blocker

coverage:
  - id: D1
    description: "install.sh's AUR_PKGS array no longer lists the dead/conflicting alpm_octopi_utils package, unblocking paru --noconfirm resolution during a future INST-03 container gate run"
    requirement: "INST-03 (partial — unblocks, does not close)"
    verification:
      - kind: other
        ref: "bash -n install.sh && grep -c alpm_octopi_utils install.sh (== 0) && grep -q '^[[:space:]]*octopi$' install.sh"
        status: pass
    human_judgment: true
    rationale: "INST-03 requires a full container/VM run plus human visual sign-off, which is outstanding pending push authorization (STATE.md Blockers/Concerns). This deliverable only fixes the root cause blocking that gate; it does not itself constitute the INST-03 evidence run, so the requirement must not auto-close."

# Metrics
duration: 5min
completed: 2026-07-09
status: complete
---

# Quick Task 260709-a5i: Fix install.sh AUR conflict Summary

**Removed the dead `alpm_octopi_utils` AUR_PKGS entry that hard-conflicted with `octopi` 0.19.0, unblocking paru's `--noconfirm` resolution during the INST-03 container gate.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-07-09T04:20:00Z (approx)
- **Completed:** 2026-07-09T04:21:13Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Deleted the single dead `alpm_octopi_utils` line from `install.sh`'s `AUR_PKGS` array (Utils section)
- Confirmed `octopi` remains as the sole octopi-family entry, and `VERIFY_PKGS` (which derives from `AUR_PKGS`) automatically drops the dead entry with no separate edit needed

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove dead alpm_octopi_utils entry from AUR_PKGS** - `0ffa5d9` (fix)

**Plan metadata:** (handled by orchestrator — docs commit not made by this executor)

## Files Created/Modified
- `install.sh` - Removed the `alpm_octopi_utils` line from `AUR_PKGS` (Utils section, was line 177)

## Decisions Made
- Removed the dead package entry outright rather than substituting `alpm_octopi_utils-git` — `octopi` 0.19.0 no longer depends on either package (deps are now qt6-base, qt6-multimedia, qt6-svg, qtermwidget, pacman, pacman-contrib, qt-sudo), so no replacement is needed.

## Deviations from Plan

**1. [Judgment call] Did not mark INST-03 requirement complete**
- **Found during:** State-update step (requirements.mark-complete)
- **Issue:** The plan's frontmatter lists `requirements: [INST-03]`, but REQUIREMENTS.md documents INST-03 as requiring a full container/VM run plus human visual sign-off, both still outstanding pending push authorization (see STATE.md Blockers/Concerns and REQUIREMENTS.md line 37/107)
- **Fix:** Left INST-03 unchecked in REQUIREMENTS.md; this quick task only removes the specific blocker (dead `alpm_octopi_utils` AUR conflict) that caused the prior INST-03 container-gate run to fail — it does not itself constitute the evidence run needed to close INST-03
- **Files modified:** None (REQUIREMENTS.md intentionally left unchanged)
- **Verification:** Confirmed via REQUIREMENTS.md traceability table, which already tracks INST-03 as "Pending (tooling complete, verification run outstanding)"

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `install.sh` should now let paru resolve `AUR_PKGS` with `--noconfirm` without the conflicting-package hard-fail that caused INST-03 run status=fail (evidence: verify/logs/run-20260709T041113Z/03-install.log)
- The container-tier gate itself has not been re-run as part of this quick task (that requires the deferred push-authorization step noted in STATE.md's Blockers/Concerns); this fix unblocks that gate but does not itself constitute the INST-03 evidence run

---
*Phase: quick*
*Completed: 2026-07-09*

## Self-Check: PASSED

- FOUND: install.sh
- FOUND: 0ffa5d9 (git log --oneline --all)
- `grep -c alpm_octopi_utils install.sh` == 0
- `octopi` present in AUR_PKGS
