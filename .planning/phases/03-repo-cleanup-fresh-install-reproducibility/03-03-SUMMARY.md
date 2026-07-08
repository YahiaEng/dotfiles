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

requirements-completed: []  # NOT completing INST-01/CLEAN-02 yet — see status below; the code-level CLEAN-02 invariant is functionally complete and correctly verified working (fires FAIL on dirty tree, will fire PASS once committed), but INST-01's "all configured providers register" truth is still unmet on this machine pending the human action.

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
    verification: []
    human_judgment: true
    rationale: "Root-caused as a Go plugin/host binary build-invocation mismatch (not a package-install gap): elephant main binary was built 2026-05-13; elephant-files/providerlist/runner/websearch were rebuilt independently 2026-07-08 in a separate paru invocation. All elephant-* packages ARE installed (pacman -Qs elephant confirms all 9 provider packages + host binary present), but the host binary's own provider registry does not recognize the four newer plugins (confirmed via `elephant generate doc files` producing zero output vs a working provider like calc). The fix requires a single coordinated `paru` rebuild of the whole elephant split package (host + every provider .so built together in one invocation) followed by `pacman -U`, which needs interactive sudo — unavailable in this non-interactive execution session. Requires a human to run the fix command in their own terminal; verification command provided below."

# Metrics
duration: 55min
completed: 2026-07-08
status: blocked
---

# Phase 3 Plan 3: Strict Verification Tooling Summary

**theme-doctor and theme-stress-test are now strict (menus provider-parity fixed, git-clean invariant added, all carve-outs removed) — but theme-doctor still cannot exit 0 on this machine because the elephant provider gap is a Go plugin/host build-invocation mismatch, not the simple "never installed" gap the plan assumed, and its real fix needs interactive sudo unavailable in this session.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-07-08T20:30:00Z (approx)
- **Completed:** 2026-07-08T21:25:31Z (paused at blocker, not plan-complete)
- **Tasks:** 2 of 2 code-complete; 1 of 2 fully verified end-to-end (Task 2's code is fully verifiable statically; Task 1's live "theme-doctor exits 0" acceptance criterion is blocked)
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

1. **Task 1: Close the elephant provider gap and harden theme-doctor (provider parity + git-clean invariant)** - `90f73c2` (fix) — code complete; the "elephant provider gap closed on this machine" and "theme-doctor exits 0" acceptance criteria remain **unmet** pending the human action below
2. **Task 2: Make theme-stress-test strict and confirm the Phase-2 false-pass guards hold** - `1a4ce30` (fix) — fully complete and statically verified

**Plan metadata:** not yet committed — this plan is not complete; no final `docs({phase}-{plan}): complete` commit will be made until the blocker below is resolved and a continuation session confirms `theme-doctor` exits 0.

_Note: no TDD tasks in this plan._

## Files Created/Modified
- `theme-engine/.config/theme-engine/theme-doctor` - prefix/package-aware menus provider-parity branch, git-clean invariant added, "expected/known gap" carve-out removed
- `theme-engine/.config/theme-engine/theme-stress-test` - strict `check_theme_doctor` (exit-0 required, `set +e`/`-e` toggle for safe capture under `set -euo pipefail`), accepted-gap tolerance and comment removed, per-switch description updated

## Decisions Made
- menus provider parity: satisfied via `elephant-menus` package presence OR a `menus:*` active entry — no placeholder menu file seeded (this was Research's Open Question 1; resolved per the planner_note's recommendation, the cheaper/correct interpretation)
- check_theme_doctor: requires theme-doctor exit 0, full stop — no tolerated FAIL of any kind now that the carve-out is gone
- Did NOT attempt an alternative/similar-named package substitute for the missing elephant providers (Rule 3's package-manager-install exclusion) — instead root-caused precisely why the already-correctly-named, already-installed packages still don't register, which is a build-invocation issue, not a naming/legitimacy issue
- Did NOT mark INST-01/CLEAN-02 as complete in requirements-completed — CLEAN-02's git-clean invariant mechanism is code-complete and verified working, but INST-01's "all configured providers register" truth (a must_haves item in this plan's own frontmatter) is not yet true on this machine

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

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary correctness fix, no scope creep — without it, theme-stress-test would have crashed instead of aborting-with-diagnostics on its very first `theme-doctor` failure.

## Issues Encountered

**Blocked / Requires Human Action — theme-doctor cannot yet exit 0 on this machine**

The plan's Task 1 action assumed the elephant provider gap was a simple "genuinely-missing package" problem, fixable with `paru -S --needed --noconfirm elephant-files elephant-providerlist elephant-runner elephant-websearch`. Investigation this session found that assumption is **incorrect**:

- `pacman -Qs elephant` shows all 9 elephant-* provider packages AND the main `elephant` package already installed (version `2.21.0-1` across the board).
- `elephant listproviders` still only reports `calc`, `clipboard`, `desktopapplications`, `symbols` — the same 4 as before this session, missing `files`, `providerlist`, `runner`, `websearch`.
- `pacman -Qi` shows the main `elephant` package and the 4 "working" providers were all installed together on **2026-05-13** (one batch/build), while `elephant-files`/`elephant-providerlist`/`elephant-runner`/`elephant-websearch` were installed independently on **2026-07-08** — a separate, later `paru` invocation.
- `elephant generate doc files` (and `menus`) produce **zero output**, whereas `elephant generate doc calc` produces real documentation — this proves the main `elephant` host binary's own compiled-in provider registry, not just its plugin-`.so` loader, does not recognize these four provider names at all. This is consistent with Go's plugin ABI requiring the host binary and every `.so` plugin it loads to be compiled together in the same build invocation — `elephant` (the host) was never rebuilt in the same invocation as the four newer provider `.so` files, so it doesn't know about them even though the files exist on disk at `/usr/lib/elephant/*.so`.
- Restarting the `elephant` process (attempted twice this session) does not change this — the gap is baked into the compiled host binary, not a stale-daemon issue.
- Attempted the real fix — `paru -S --noconfirm elephant elephant-calc elephant-clipboard elephant-desktopapplications elephant-files elephant-menus elephant-providerlist elephant-runner elephant-symbols elephant-websearch` (forcing a coordinated rebuild+reinstall of the entire split package in one invocation) — paru determined the `elephant` pkgbase was "up to date" and skipped rebuilding, then required `sudo` to install the (stale-cached) packages; `sudo` demanded an interactive password prompt this non-interactive session cannot supply (`sudo: a terminal is required to read the password`).

**What the plan's Task 1 code-level acceptance criteria this affects:**
- ✅ `bash -n`/`shellcheck -S error` pass on theme-doctor
- ✅ Provider-parity loop has the menus branch; all other providers use exact-line match
- ✅ "expected/known gap" carve-out comment is gone
- ✅ git-clean invariant present, correctly FAILs/PASSes
- ❌ `elephant listproviders` covers files/providerlist/runner/websearch (still missing — blocked)
- ❌ Running `theme-doctor` exits 0 on this machine (currently exits 1: 21 passed, 2 failed — the provider-parity FAIL above, plus the git-clean FAIL which will resolve once this plan's commits land)

**Exact fix for a human to run** (in their own interactive terminal, where they can enter their sudo password):
```bash
paru -Bcc elephant   # optional: clear paru's stale per-package build cache first, forces a true rebuild
paru -S --noconfirm --rebuild elephant elephant-calc elephant-clipboard elephant-desktopapplications \
  elephant-files elephant-menus elephant-providerlist elephant-runner elephant-symbols elephant-websearch
pkill -x elephant
setsid uwsm app -- elephant >/dev/null 2>&1 </dev/null & disown
```

**Verification command** (run after the above):
```bash
elephant listproviders
# Expected: calc, clipboard, desktopapplications, files, providerlist, runner, symbols, websearch
# (menus will only appear as menus:<file> once a real menu file exists under
#  ~/.config/elephant/menus/ — theme-doctor's fix already accounts for this
#  via the elephant-menus package check, so menus absence here is fine)

~/.local/state/theme  # sanity: confirm state dir intact
theme-engine/.config/theme-engine/theme-doctor  # or the stowed path once re-stowed
# Expected: Summary: 23 passed, 0 failed / exit 0
```

Once `theme-doctor` exits 0, a continuation session should: (1) re-run the plan's Task 1 `<verify>` block in full to confirm the automated PASS, (2) update `requirements-completed` in this SUMMARY to `[INST-01, CLEAN-02]`, (3) run `state advance-plan` / `roadmap update-plan-progress` / `requirements mark-complete INST-01 CLEAN-02`, and (4) make the final `docs(03-03): complete strict verification tooling plan` metadata commit.

## User Setup Required

**A human must run the elephant rebuild command above in their own interactive terminal** (this session's sandboxed shell cannot supply a sudo password). See "Issues Encountered" above for the exact command and verification steps. No other external service configuration is required.

## Next Phase Readiness

- theme-doctor and theme-stress-test's CODE is fully strict and ready to serve as fresh-install evidence for Plan 03-04's reproduction gate, **once** the elephant rebuild lands and `theme-doctor` genuinely exits 0 on a re-run.
- Plan 03-04 (or a continuation of this plan) should NOT proceed to using these tools as "green means healthy" evidence until the human action above is confirmed — running them now would show a real, accurate FAIL, not a false pass, but the FAIL still needs to be resolved before this plan's must_haves are satisfied.
- The git-clean invariant will show PASS once this plan's own commits are made (the only current source of repo dirtiness besides the pre-existing `.planning/STATE.md` edit is this plan's own uncommitted work).

---
*Phase: 03-repo-cleanup-fresh-install-reproducibility*
*Paused (not complete): 2026-07-08*

## Self-Check: PASSED

- FOUND: theme-engine/.config/theme-engine/theme-doctor
- FOUND: theme-engine/.config/theme-engine/theme-stress-test
- FOUND: .planning/phases/03-repo-cleanup-fresh-install-reproducibility/03-03-SUMMARY.md
- FOUND commit: 90f73c2
- FOUND commit: 1a4ce30
