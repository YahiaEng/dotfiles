---
phase: 02-static-dynamic-parity-switch-reliability
plan: 02
subsystem: infra
tags: [theme-engine, reliability, stress-test, rsync, bash, matugen, walker, elephant, thunar]

# Dependency graph
requires:
  - phase: 02-static-dynamic-parity-switch-reliability (plan 02-01)
    provides: "lib/contract.sh's contract_normalize_color, theme-parity render-only parity checker, contract.json manifest"
provides:
  - "theme-stress-test: parameterized 10-switch alternating static↔dynamic harness with per-switch abort-on-failure assertions"
  - "D-40 reliability fix: lib/commit.sh no longer wipes ~/.local/state/theme/logs/ on every theme-apply commit"
  - "D-41 clean full gate evidence: 140/0 stress pass + 217/0 parity pass in one uninterrupted sequence"
  - "02-VERIFICATION.md: human-signed-off PIPE-06 proof with D-15/D-37 caveat documented"
affects: [phase-3-fresh-vm-verification, theme-engine-regression-tooling]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Abort-on-first-failure harness (opposite of theme-parity's run-all-report-all) with a diagnostics dump to a timestamped log"
    - "rsync --delete commit step must exclude non-contract runtime subdirectories (logs/) to avoid self-destructive syncs"

key-files:
  created:
    - theme-engine/.config/theme-engine/theme-stress-test
    - .planning/phases/02-static-dynamic-parity-switch-reliability/02-VERIFICATION.md
  modified:
    - theme-engine/.config/theme-engine/lib/commit.sh

key-decisions:
  - "D-40 fix scope: excluded logs/ from commit.sh's rsync --delete rather than moving logs/ outside the state dir or reimplementing the sync — minimal, reuses the existing atomic-commit call"
  - "D-41 gate satisfied by back-to-back stress (22:27:06Z) then parity (22:28:32Z) runs in the same uninterrupted session, immediately following the D-40 fix commit"

patterns-established:
  - "New keeper regression scripts (theme-stress-test) join theme-doctor/theme-parity in theme-engine/.config/theme-engine/, stowed and reusable by Phase 3's fresh-VM verification"

requirements-completed: [PIPE-06]

coverage:
  - id: D1
    description: "theme-stress-test harness: parameterized (--switches/--gap), drives real theme-apply, alternates static↔dynamic across 6 presets + materialyou, per-switch checks (theme-doctor, format-normalized sentinel incl. hyprland.conf, walker+elephant liveness+bus-name), abort-on-first-failure with diagnostics dump, timestamped log output"
    requirement: PIPE-06
    verification:
      - kind: other
        ref: "cd /home/aorus/dotfiles && bash -n theme-engine/.config/theme-engine/theme-stress-test (structure gate: sources contract.sh, calls theme-apply, checks dev.benz.walker, uses $((waited+1)) form, no unscoped killall)"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-40 reliability bug found and fixed: lib/commit.sh's rsync -a --delete wiped ~/.local/state/theme/logs/ on every theme-apply commit; fixed with --exclude=logs/"
    requirement: PIPE-06
    verification:
      - kind: other
        ref: "~/.local/state/theme/logs/theme-parity-20260707T222832Z.log (217 passed, 0 failed, re-run after fix)"
        status: pass
      - kind: other
        ref: "~/.local/state/theme/logs/stress-20260707T222706Z.log (140 passed, 0 failed, own log survived all 10 switches after fix)"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-41 clean full gate: fresh, uninterrupted 10-switch stress run (zero failures) immediately followed by all-green theme-parity, in one session"
    requirement: PIPE-06
    verification:
      - kind: other
        ref: "~/.local/state/theme/logs/stress-20260707T222706Z.log SUMMARY line: 140 passed, 0 failed"
        status: pass
      - kind: other
        ref: "~/.local/state/theme/logs/theme-parity-20260707T222832Z.log SUMMARY line: 217 passed, 0 failed"
        status: pass
    human_judgment: false
  - id: D4
    description: "Human visual sign-off on switch #10 (materialyou): newly-opened Thunar window, summoned Walker, waybar, swaync, kitty all correctly themed with no drift/stuck-white/stale-mix (D-35 success-criterion bar); D-15/D-37 already-open-Thunar-window caveat documented as an accepted, non-failure behavior"
    requirement: PIPE-06
    verification: []
    human_judgment: true
    rationale: "Visual/functional correctness across live desktop apps cannot be asserted by a test — this is the project's explicit non-negotiable human evidence bar (D-35). Sign-off was captured this session via checkpoint approval and is recorded verbatim in 02-VERIFICATION.md."

# Metrics
duration: 11min
completed: 2026-07-08
status: complete
---

# Phase 2 Plan 02: Repeated-Switch Reliability Summary

**Built a rerunnable 10-switch alternating static↔dynamic stress harness, found and fixed a real reliability bug (commit.sh's rsync --delete silently wiping its own logs/ output), and closed on a human-signed-off D-41 clean full gate proving PIPE-06.**

## Performance

- **Duration:** 11 min (across this session; work began at commit `7c329ff` and closed at `9c447eb`)
- **Started:** 2026-07-07T22:25:37Z
- **Completed:** 2026-07-07T22:36:10Z
- **Tasks:** 3 (theme-stress-test build, clean-gate loop + D-40 fix, human sign-off + 02-VERIFICATION.md)
- **Files modified:** 3 (theme-stress-test created, lib/commit.sh fixed, 02-VERIFICATION.md created)

## Accomplishments

- `theme-stress-test` — a parameterized (`--switches`/`--gap`), abort-on-first-failure harness that drives the real `theme-apply` entrypoint through an alternating static↔dynamic sequence (6 static presets rotated + materialyou interleaved), with Thunar/Walker precondition and postcondition health checks, per-switch `theme-doctor` + format-normalized sentinel-color + walker/elephant liveness assertions, and a timestamped machine-readable log
- Found and fixed a real reliability bug (D-40): `lib/commit.sh`'s `rsync -a --delete` was wiping `~/.local/state/theme/logs/` on every theme-apply commit because `logs/` isn't part of the matugen render contract — fixed with `--exclude=logs/`
- Reached the D-41 clean full gate: a fresh, uninterrupted 10-switch stress run (140 passed, 0 failed) immediately followed by an all-green `theme-parity` run (217 passed, 0 failed) in one session
- Obtained the mandatory human visual sign-off (D-35): user confirmed Thunar (newly-opened window), Walker, waybar, swaync, and kitty all correctly rendered the switch-#10 materialyou palette with no drift/stuck-white
- Recorded `02-VERIFICATION.md` quoting both passing logs, the D-40 fix, the human sign-off, and the D-15/D-37 already-open-Thunar-window caveat as a documented, accepted pass (not a failure)

## Task Commits

Each task was committed atomically:

1. **Task 1: theme-stress-test — 10-switch alternating harness with per-switch assertions** - `7c329ff` (feat)
2. **Task 2: Run clean-gate loop, fix reliability bug (D-40), reach D-41 clean full gate** - `0d34782` (fix)
3. **Task 3: Human visual sign-off + record 02-VERIFICATION.md** - `9c447eb` (docs)

**Plan metadata:** (this commit)

## Files Created/Modified

- `theme-engine/.config/theme-engine/theme-stress-test` - New keeper regression script: parameterized 10-switch alternating harness with abort-on-first-failure semantics, joins theme-doctor/theme-parity as stowed tooling
- `theme-engine/.config/theme-engine/lib/commit.sh` - Fixed rsync `--delete` to exclude `logs/`, preventing the atomic commit step from destroying non-contract runtime log output on every switch
- `.planning/phases/02-static-dynamic-parity-switch-reliability/02-VERIFICATION.md` - Evidence record: passing stress + parity logs quoted, D-40 fix documented, human sign-off recorded, D-15/D-37 caveat documented

## Decisions Made

- Fixed D-40 minimally by excluding `logs/` from the existing `rsync --delete` call rather than relocating `logs/` outside the state dir or reworking the commit sync logic — smallest change that preserves the atomic-commit contract for all 10 tracked output files while protecting the harness's own runtime artifacts.
- The D-41 gate's "one uninterrupted sequence" requirement was satisfied by running the stress test and `theme-parity` back-to-back (22:27:06Z → 22:28:32Z) in the same session immediately after the D-40 fix landed — not stitching together separate historical runs.

## Deviations from Plan

None - plan executed exactly as written. Task 2's D-40 reliability bug was an expected possible outcome per the plan's own acceptance criteria ("if the first stress run passes with no failure, record 'no reliability bug found'... otherwise fix it") — a bug WAS found and fixed within the plan's explicitly authorized scope (`lib/commit.sh`), following the plan's own diagnostic and reuse-existing-patterns guidance. This is planned-path execution, not a deviation.

## Issues Encountered

None beyond the D-40 bug itself, which is documented above as an in-scope, plan-anticipated finding and fix (not an unplanned deviation).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- PIPE-04 (parity, from 02-01) and PIPE-06 (repeated-switch reliability, this plan) are both proven and human-verified — Phase 2's two requirements are complete.
- Three keeper regression tools now exist side-by-side in `theme-engine/.config/theme-engine/`: `theme-doctor` (fast invariant check), `theme-parity` (render-only structural/semantic parity), `theme-stress-test` (live 10-switch reliability gate) — all reusable by Phase 3's fresh-VM verification (D-42).
- No blockers for Phase 3. The D-15/D-37 already-open-GTK3-window staleness caveat remains an accepted, documented limitation (not a defect) carried forward from Phase 1.

---
*Phase: 02-static-dynamic-parity-switch-reliability*
*Completed: 2026-07-08*

## Self-Check: PASSED

All created/modified files verified present on disk (theme-stress-test, 02-VERIFICATION.md, 02-02-SUMMARY.md, lib/commit.sh) and all four task/metadata commit hashes (7c329ff, 0d34782, 9c447eb, 79fe274) verified present in git log.
