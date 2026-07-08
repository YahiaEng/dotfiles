---
phase: 03-repo-cleanup-fresh-install-reproducibility
plan: 03
subsystem: infra
tags: [bash, elephant, walker, theme-doctor, theme-stress-test, systemd, go-plugins, pacman, aur]

# Dependency graph
requires:
  - phase: 02-static-dynamic-parity-switch-reliability
    provides: theme-doctor/theme-parity/theme-stress-test keeper tools, contract.json single-source file list
provides:
  - "theme-doctor: strict prefix/package-aware menus provider-parity branch + permanent git-clean invariant, carve-out comment removed"
  - "theme-stress-test: strict check_theme_doctor (requires theme-doctor exit 0), carve-out logic removed"
  - "D-67 verification: theme-parity's zero-result loud-failure guard and template-leftover coverage confirmed still present, no gap found"
  - "Root-cause finding: the elephant provider gap is a Go plugin/host build-invocation mismatch, not a 'never installed' gap"
affects: [03-04, INST-01 verification loop, VM/container reproduction gate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Prefix/package-aware provider-parity branch for data-driven elephant providers (menus:<file> vs bare package-installed check)"
    - "set +e/-e toggle around a bare VAR=$(cmd) capture inside a set -euo pipefail script, to safely capture a non-zero exit code without aborting (mirrors this file's own abort_with_diagnostics precedent)"

key-files:
  created: []
  modified:
    - theme-engine/.config/theme-engine/theme-doctor
    - theme-engine/.config/theme-engine/theme-stress-test

key-decisions:
  - "menus provider parity is satisfied via elephant-menus package presence OR a menus:* active entry — no placeholder menu file seeded (matches planner_note's resolved Open Question 1)"
  - "check_theme_doctor requires theme-doctor exit 0, full stop — no tolerated FAIL of any kind"
  - "The elephant files/providerlist/runner/websearch gap is NOT a missing-package issue (all elephant-* packages are installed per pacman -Qs elephant) — it is a Go plugin/host binary build-invocation mismatch requiring a coordinated full-package rebuild that needs interactive sudo unavailable in this execution session. This is the plan's one open item — see 'Blocked / Requires Human Action' below."

patterns-established:
  - "Verification tools that reuse elephant listproviders must treat data-driven providers (name:instance registration) with a prefix/package-aware branch, never a bare string equality"

requirements-completed: [INST-01, CLEAN-02]  # Both now met: the elephant rebuild (human action) closed the provider gap, and theme-doctor exits 0 clean (23 passed, 0 failed) including the git-clean invariant.

coverage:
  - id: D1
    description: "theme-doctor's menus provider-parity branch is prefix/package-aware (satisfied via elephant-menus package or menus:* entry) instead of an impossible bare-string match"
    requirement: INST-01
    verification:
      - kind: unit
        ref: "manual run: theme-doctor output shows no [FAIL] mentioning 'menus' after the fix (confirmed in this session's live run)"
        status: pass
    human_judgment: false
  - id: D2
    description: "theme-doctor has a permanent git status --porcelain invariant (D-50/CLEAN-02) with a guarded skip when git/.git is absent"
    requirement: CLEAN-02
    verification:
      - kind: unit
        ref: "manual run: theme-doctor correctly FAILs on the dirty tree pre-commit and will PASS once this plan's changes are committed"
        status: pass
    human_judgment: false
  - id: D3
    description: "theme-doctor's 'expected/known gap' carve-out comment is removed; theme-stress-test's accepted-gap tolerance logic and comment are removed; check_theme_doctor now requires a strict exit 0"
    requirement: INST-01
    verification:
      - kind: unit
        ref: "grep -qE 'expected/known gap|deferred to Phase 3' theme-doctor (absent); grep -qE 'accepted elephant-provider gap|already-accepted' theme-stress-test (absent); bash -n + shellcheck -S error pass on both files"
        status: pass
    human_judgment: false
  - id: D4
    description: "The four genuinely-missing elephant providers (files/providerlist/runner/websearch) register in elephant listproviders and theme-doctor exits 0 on this machine"
    requirement: INST-01
    verification:
      - kind: unit
        ref: "Continuation session: `elephant listproviders` now returns symbols, desktopapplications, clipboard, files, calc, providerlist, runner, websearch (all 8 configured providers active) after the human-run paru --rebuild of the elephant split package + elephant restart. `theme-doctor` re-run: Summary: 23 passed, 0 failed, exit 0."
        status: pass
    human_judgment: true
    rationale: "Root-caused as a Go plugin/host binary build-invocation mismatch (not a package-install gap): elephant main binary was built 2026-05-13; elephant-files/providerlist/runner/websearch were rebuilt independently 2026-07-08 in a separate paru invocation. All elephant-* packages ARE installed (pacman -Qs elephant confirms all 9 provider packages + host binary present), but the host binary's own provider registry did not recognize the four newer plugins (confirmed via `elephant generate doc files` producing zero output vs a working provider like calc). RESOLVED: user ran the coordinated `paru --rebuild elephant elephant-*` + elephant restart in their own interactive terminal (sudo required); a continuation session re-verified `elephant listproviders` and a strict `theme-doctor` exit 0 afterward."

# Metrics
duration: 55min (original session) + continuation verification
completed: 2026-07-09
status: complete
---

# Phase 3 Plan 3: Strict Verification Tooling Summary

**theme-doctor and theme-stress-test are now strict (menus provider-parity fixed, git-clean invariant added, all carve-outs removed), and the elephant provider gap — a Go plugin/host build-invocation mismatch, not the simple "never installed" gap the plan assumed — is closed on this machine: theme-doctor exits 0 (23 passed, 0 failed).**

## Performance

- **Duration:** ~55 min (original session) + continuation verification session
- **Started:** 2026-07-08T20:30:00Z (approx)
- **Completed:** 2026-07-09 (continuation session verified the human-action fix and finalized the plan)
- **Tasks:** 2 of 2 code-complete and fully verified end-to-end (theme-doctor exits 0 clean after the user's elephant rebuild)
- **Files modified:** 2

## Accomplishments
- theme-doctor's provider-parity loop now uses a prefix/package-aware branch for the data-driven `menus` provider (satisfied via `menus:*` in `elephant listproviders` OR the `elephant-menus` package being installed), while every other configured provider still uses an exact-line match — this correctly resolves D-66's "menus is not a bug, it's a comparison-logic gap" finding without seeding a placeholder menu file
- theme-doctor's "expected/known gap" carve-out comment block is gone — the provider-parity check is unconditionally strict now
- theme-doctor gained a permanent `git status --porcelain` invariant (D-50/CLEAN-02), guarded-skip when git/`.git` is absent, mirroring the existing stow-conflict guarded-skip shape
- theme-stress-test's `check_theme_doctor` now requires theme-doctor to exit 0 outright — the accepted-gap tolerance logic (comparing "unexpected" vs "accepted" FAIL counts) and its explanatory comment block are fully removed
- Fixed a `set -e` hazard introduced by the check_theme_doctor simplification: a bare `VAR=$(cmd)` assignment inside a `set -euo pipefail` script is not exempted from errexit just because the *caller* tests the function in an `if` — wrapped the capture in a local `set +e`/`set -e` toggle, mirroring this same file's own `abort_with_diagnostics` precedent
- The per-switch check description in theme-stress-test no longer references an "accepted elephant-provider gap"
- Confirmed (read-only, no changes needed) that the D-67 Phase-2 false-pass guards are still live in theme-parity: the zero-result render is a loud FAIL (Pitfall-4 guard), and every rendered file (including walker-style.css/css-literal) is scanned unconditionally for raw `{{` template leftovers
- **Root-caused** the deferred elephant provider gap far more precisely than the plan anticipated: it is not a "package never installed" issue (confirmed: `pacman -Qs elephant` shows all 9 provider packages + the main `elephant` binary present) — it is a Go plugin/host binary build-invocation mismatch. The main `elephant` binary was built 2026-05-13; `elephant-files`/`elephant-providerlist`/`elephant-runner`/`elephant-websearch` were rebuilt independently on 2026-07-08 in a separate `paru` invocation. Confirmed via `elephant generate doc files` producing zero output (vs. real output for a working provider like `calc`) that the host binary's own provider registry — not just the .so loader — does not know about these four plugins at all.

## Task Commits

Each task was committed atomically:

1. **Task 1: Close the elephant provider gap and harden theme-doctor (provider parity + git-clean invariant)** - `90f73c2` (fix) — code complete; the "elephant provider gap closed on this machine" and "theme-doctor exits 0" acceptance criteria are now **confirmed met** after the human-run elephant rebuild (verified in continuation session)
2. **Task 2: Make theme-stress-test strict and confirm the Phase-2 false-pass guards hold** - `1a4ce30` (fix) — fully complete and statically verified
3. **Pause/checkpoint commit** - `99097a7` (docs) — recorded the sudo-gated blocker and paused state
4. **Continuation/finalization commit** - see commit table in PLAN COMPLETE response — finalizes SUMMARY.md, STATE.md, ROADMAP.md, REQUIREMENTS.md after re-verifying the fix

_Note: no TDD tasks in this plan._

## Files Created/Modified
- `theme-engine/.config/theme-engine/theme-doctor` - prefix/package-aware menus provider-parity branch, git-clean invariant added, "expected/known gap" carve-out removed
- `theme-engine/.config/theme-engine/theme-stress-test` - strict `check_theme_doctor` (exit-0 required, `set +e`/`-e` toggle for safe capture under `set -euo pipefail`), accepted-gap tolerance and comment removed, per-switch description updated

## Decisions Made
- menus provider parity: satisfied via `elephant-menus` package presence OR a `menus:*` active entry — no placeholder menu file seeded (this was Research's Open Question 1; resolved per the planner_note's recommendation, the cheaper/correct interpretation)
- check_theme_doctor: requires theme-doctor exit 0, full stop — no tolerated FAIL of any kind now that the carve-out is gone
- Did NOT attempt an alternative/similar-named package substitute for the missing elephant providers (Rule 3's package-manager-install exclusion) — instead root-caused precisely why the already-correctly-named, already-installed packages still don't register, which is a build-invocation issue, not a naming/legitimacy issue
- Marked INST-01/CLEAN-02 as complete in requirements-completed — confirmed in this continuation session: CLEAN-02's git-clean invariant is code-complete and verified working, and INST-01's "all configured providers register" truth is now true on this machine after the human-run elephant rebuild

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed a set -e hazard introduced by simplifying check_theme_doctor**
- **Found during:** Task 2
- **Issue:** The straightforward simplification of `check_theme_doctor` (capture output + exit code, return it) used a bare `VAR=$(cmd)` assignment inside a script running `set -euo pipefail`. If `theme-doctor` exits non-zero, that assignment statement itself is not exempted from `errexit` (the exemption only covers the command directly tested by an `if`/`while`/`&&`/`||`, not commands nested inside a function body called from that position) — this would have silently killed the entire `theme-stress-test` script the first time `theme-doctor` failed, before `check_or_abort` ever got a chance to log/abort with diagnostics.
- **Fix:** Wrapped the capture in a local `set +e` / `set -e` toggle inside `check_theme_doctor`, mirroring the exact same idiom this file's own `abort_with_diagnostics` function already uses for the same reason.
- **Files modified:** `theme-engine/.config/theme-engine/theme-stress-test`
- **Verification:** `bash -n` and `shellcheck -S error` both pass; the function was manually traced against `set -euo pipefail` semantics.
- **Committed in:** `1a4ce30` (part of Task 2 commit)

---

**2. [Checkpoint - human-action] Elephant provider gap required a sudo-gated full package rebuild, not the plan-assumed "install missing packages"**
- **Found during:** Task 1
- **Issue:** The plan's Task 1 action assumed the elephant provider gap was a simple "genuinely-missing package" problem, fixable with `paru -S --needed --noconfirm elephant-files elephant-providerlist elephant-runner elephant-websearch`. Investigation found that assumption was **incorrect**: `pacman -Qs elephant` showed all 9 elephant-* provider packages AND the main `elephant` package already installed. `elephant listproviders` still only reported `calc`, `clipboard`, `desktopapplications`, `symbols` — missing `files`, `providerlist`, `runner`, `websearch`. `pacman -Qi` showed the main `elephant` package and the 4 working providers were all installed together on 2026-05-13, while the 4 missing providers were installed independently on 2026-07-08 in a separate `paru` invocation. `elephant generate doc files` produced zero output (vs. real output for `calc`) — proving the host binary's compiled-in provider registry, not just its plugin-`.so` loader, didn't recognize the four newer plugins. This is a Go plugin ABI mismatch: the host binary and every `.so` plugin it loads must be compiled together in the same build invocation. Restarting the `elephant` process alone did not fix it. The real fix (`paru --rebuild` of the whole elephant split package) requires interactive sudo, unavailable in the original non-interactive execution session.
- **Resolution:** Checkpoint returned as `human-action`. The user ran, in their own interactive terminal:
  ```bash
  paru -Bcc elephant
  paru -S --noconfirm --rebuild elephant elephant-calc elephant-clipboard elephant-desktopapplications \
    elephant-files elephant-menus elephant-providerlist elephant-runner elephant-symbols elephant-websearch
  pkill -x elephant
  setsid uwsm app -- elephant >/dev/null 2>&1 </dev/null & disown
  ```
  and confirmed with "done". This continuation session re-verified: `elephant listproviders` now returns all 8 active providers (symbols, desktopapplications, clipboard, files, calc, providerlist, runner, websearch), and `theme-doctor` exits 0 with "Summary: 23 passed, 0 failed".
- **Files modified:** none (runtime/package-state fix only, no repo files touched)
- **Verification:** `elephant listproviders` output and `theme-doctor` exit-0 re-run, both captured live in the continuation session.
- **Committed in:** N/A (no code change — the fix was a package rebuild + daemon restart on the dev machine, not a repo change)

---

**Total deviations:** 1 auto-fixed (1 bug) + 1 human-action checkpoint (resolved)
**Impact on plan:** Necessary correctness fix (Task 2) + a real environmental blocker correctly identified and resolved via human action (Task 1) — no scope creep, no shortcuts taken to work around the sudo requirement.

## Issues Encountered

**RESOLVED — theme-doctor now exits 0 on this machine**

The plan's Task 1 action assumed the elephant provider gap was a simple "genuinely-missing package" problem. Investigation found the real cause was a Go plugin/host build-invocation mismatch (see Deviation 2 above) requiring a coordinated `paru --rebuild` of the entire elephant split package, which needs interactive sudo. This was surfaced as a `human-action` checkpoint; the user resolved it in their own terminal.

**Confirmed in this continuation session:**
```
$ elephant listproviders
symbols
desktopapplications
clipboard
files
calc
providerlist
runner
websearch

$ theme-engine/.config/theme-engine/theme-doctor
...
Summary: 23 passed, 0 failed
EXIT_CODE=0
```

All plan `must_haves.truths` are now confirmed:
- `elephant listproviders` covers every provider walker/config.toml configures (files, providerlist, runner, websearch active) ✓
- theme-doctor's menus provider-parity branch is prefix/package-aware, satisfied via `elephant-menus` install ✓
- theme-doctor exits 0 (23 passed, 0 failed) — no accepted-gap carve-out remains ✓
- theme-doctor asserts `git status --porcelain` is empty (CLEAN-02/D-50) ✓ (verified clean before this session's commit)
- theme-stress-test's `check_theme_doctor` requires a clean theme-doctor pass (strict, no tolerated FAIL) ✓
- The Phase-2 false-pass guards (D-67) still hold: theme-parity fails loudly on zero results (`# A zero-file render is a FAIL, never a silent skip/false-pass`) and walker-style.css `{{...}}` template-leftover coverage is present (re-confirmed via grep in this session) ✓

## User Setup Required

None remaining. The elephant rebuild (the plan's one human-action item) was completed and verified in this continuation session.

## Next Phase Readiness

- theme-doctor and theme-stress-test are fully strict and confirmed exit-0-clean — ready to serve as fresh-install evidence for Plan 03-04's reproduction gate.
- Plan 03-04 can proceed using these tools as genuine "green means healthy" evidence — the elephant provider gap is closed and independently re-verified, not just code-complete.
- The git-clean invariant passed in this session's pre-commit check; it will continue to hold as long as future theme switches don't leave stray tracked changes.

---
*Phase: 03-repo-cleanup-fresh-install-reproducibility*
*Completed: 2026-07-09*

## Self-Check: PASSED

- FOUND: theme-engine/.config/theme-engine/theme-doctor
- FOUND: theme-engine/.config/theme-engine/theme-stress-test
- FOUND: .planning/phases/03-repo-cleanup-fresh-install-reproducibility/03-03-SUMMARY.md
- FOUND commit: 90f73c2
- FOUND commit: 1a4ce30
- FOUND commit: 99097a7
- CONFIRMED: elephant listproviders covers all 8 active providers (files, providerlist, runner, websearch now active)
- CONFIRMED: theme-doctor exits 0, "Summary: 23 passed, 0 failed"
