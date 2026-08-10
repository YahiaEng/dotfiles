---
phase: 13-motion-retrofit-existing-surface-sweep
plan: 06
subsystem: theme-engine
tags: [git-clean-invariant, wallpaper, motion-lint, gsd-tools-windows, stow, bash, python]

# Dependency graph
requires:
  - phase: 13-motion-retrofit-existing-surface-sweep
    provides: "13-05's waybar sass conversion and D-32's exemption-removal groundwork (swaync 13-02, animations.conf 13-01, waybar 13-05)"
provides:
  - "current.jpg untracked, gitignored, and seeded at install (D-23) — clean-tree invariant now TRUE, not merely unchecked"
  - "motion-lint EXEMPTIONS/LINE_EXEMPTIONS D-32 end state: 3 whole-file + 1 line-level entry, permanent reasons, structured pending:False fields"
  - "motion-lint --no-pending: opt-in zero-pending assertion, proven able to fail and proven opt-in"
  - "WINDOWS.md ledger reconciled: entries 1, 2, 8 marked fixed"
affects: [13-07, theme-stress-test, motion-lint, stow.sh]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "seed-only-when-absent idiom (stow.sh) extended to a fifth consumer: the wallpaper pointer, with a WARNING (not loud-exit-1) failure posture since the desktop degrades rather than fails to start"
    - "structured boolean 'pending' field on lint exemption entries, replacing reason-string substring matching, to make an opt-in --no-pending assertion possible without regex-over-prose brittleness"

key-files:
  created: []
  modified:
    - .gitignore
    - stow.sh
    - hypr/.config/hypr/scripts/motion-lint
    - .planning/WINDOWS.md

key-decisions:
  - "D-23 confirmed by operator at the Task 1 blocking checkpoint: untrack-and-seed (not exempt-the-path) — the tree gets fixed, the gate keeps telling the truth. Recorded as operator-confirmed, one-way (re-tracking later would mean choosing a new canonical target from arbitrary machine state, not restoring a known one)."
  - "Wallpaper pointer seed uses a WARNING posture, not the motion-file/GTK3-sass seeds' loud exit 1 — the desktop degrades (no wallpaper, no lock background, no Material You source) but nothing in the boot path fails to start without it, the opposite failure class from the config-parse-fatal seeds it sits next to."
  - "--no-pending implemented as a wholly separate early-exit branch inside the same canonical EXEMPTIONS/LINE_EXEMPTIONS python definitions (env-var-gated), not a duplicated list — avoids the drift risk of hand-copying the exemption data a second time while still matching --self-test's 'check argv, branch to separate pass, exit its status' shape."
  - "Ledger reconciliation deviates from the plan's literal 'open_count == 6' automated check: true open_count is 7, because entry 10 (added by 13-01, after this plan's acceptance criterion was authored against a 9-entry ledger) is legitimately open and out of this plan's scope. Documented as a deviation rather than force-marking entry 10 fixed to make a number match — see Deviations below."

requirements-completed: [MOTION-01, MOTION-02]

coverage:
  - id: D1
    description: "Wallpaper pointer (current.jpg) untracked, gitignored, and seeded at install; git tree stays clean across static theme switches with theme-doctor's clean-tree check unmodified"
    requirement: "MOTION-01"
    verification:
      - kind: other
        ref: "git status --porcelain empty after theme-apply dracula AND theme-apply catppuccin; theme-doctor exit 0 (206 passed, 0 failed); stow.sh seed re-verified after deleting local pointer (relative symlink, resolves to a real file); theme-apply materialyou succeeds after reseed; hyprlock.conf's background path (~/Pictures/Wallpapers/current.jpg, line 50) resolves via realpath -e to a real file (hyprlock v0.9.6 has no --verify-config flag)"
        status: pass
    human_judgment: false
  - id: D2
    description: "motion-lint EXEMPTIONS/LINE_EXEMPTIONS reach D-32's end state (3 whole-file + 1 line-level entry, permanent reasons, structured pending:False); --no-pending opt-in assertion added, proven able to fail and proven opt-in; D-18 soak integrity proven (state-dir manifest unchanged across both lint modes)"
    requirement: "MOTION-02"
    verification:
      - kind: other
        ref: "motion-lint (exit 0, 53/0), motion-lint --self-test (exit 0, 11/0), motion-lint --no-pending (exit 0); flip-to-pending run exited 1 naming the offending entry, flip-back byte-identical to original + exit 0; default run confirmed still exit 0 while an entry was flipped to pending (opt-in proof); python assertions on entry/pending-field counts and stale-string absence; sha256 manifest of ~/.local/state/theme/ (hyprland-motion.conf included) byte-identical before/after both lint modes"
        status: pass
    human_judgment: false
  - id: D3
    description: "WINDOWS.md ledger reconciled — entries 1, 2, 8 marked fixed with stated reasons; entry 9 deliberately left open (deferred to 13-07); entry 10 left open (out of this plan's scope, added after this plan's acceptance criterion was authored)"
    verification:
      - kind: other
        ref: "gsd-tools windows fixed 1 / 2 / 8; resulting ledger: fixed_count 3, open_count 7 (total_count 10)"
        status: pass
    human_judgment: true
    rationale: "The plan's literal automated check asserts open_count == 6, computed against a 9-entry ledger snapshot at authoring time. Entry 10 was added later by sibling plan 13-01 and is legitimately open, out of scope for this plan. A human should confirm the ledger's actual state (fixed: 1,2,8; open: 3,4,5,6,7,9,10) matches intent even though the literal number differs from the plan's stale hardcoded check."

# Metrics
duration: ~25min (across a blocking decision checkpoint pause)
completed: 2026-07-28
status: complete
---

# Phase 13 Plan 06: Wallpaper Pointer Untrack + Motion-Lint Exemption End State Summary

**Untracked and install-seeded the git-committed wallpaper pointer that structurally blocked the 10/10 stress-test gate (D-23, operator-confirmed one-way door), and closed motion-lint's D-32 exemption end state with a new opt-in `--no-pending` zero-pending assertion, reconciling three stale WINDOWS.md ledger entries.**

## Performance

- **Duration:** ~25 min (includes a pause at the plan's Task 1 blocking decision checkpoint for operator confirmation)
- **Completed:** 2026-07-28
- **Tasks:** 2 (Task 1 was a decision checkpoint, not a code task)
- **Files modified:** 4

## Accomplishments

- `wallpapers/Pictures/Wallpapers/current.jpg` is untracked (`git rm --cached`), gitignored, and seeded at install time by a new `stow.sh` seed-only-when-absent block — the clean-tree invariant is now genuinely TRUE (proven across two different static theme switches), not merely unchecked, and `theme-doctor`'s clean-tree check itself was left completely unmodified per D-23's "fix the tree, not the gate" framing
- `motion-lint`'s exemption list reached D-32's end state: the three remaining whole-file entries (swayosd, walker, ags) all carry the same permanent reason (zero motion literals, compositor-delivered motion) instead of the old "pending Phase 13 retrofit"/"no variable mechanism exists" phrasing, each with a structured `pending: False` field; the one `LINE_EXEMPTIONS` entry (wleave's hover rule) is similarly rewritten to a permanent, human-approved-feel reason
- New `motion-lint --no-pending` flag: an opt-in-only assertion (never default behavior) that zero exemption entries carry `pending: True`, proven able to fail (a deliberate flip-to-pending run named the offending entry and exited 1) and proven opt-in (the default `motion-lint` run still exited 0 while that entry was flipped)
- D-18 soak integrity proven mechanically: a sha256 manifest of every file in `~/.local/state/theme/` (including `hyprland-motion.conf`, the soaked artifact plan 13-01 is measuring) is byte-identical before and after running both `motion-lint` and `motion-lint --no-pending`
- WINDOWS.md ledger reconciled: entries 1 (orphaned contract entry, fixed by quick task 260725-vu6), 2 (keybind-doctor's `-j` parse break, repaired in Phase 11), and 8 (animation-count expectation, resolved by this phase's rewrite) marked fixed; entry 9 (theme-stress-test 10/10) deliberately left open, deferred to plan 13-07

## Task Commits

Task 1 was a `checkpoint:decision` (gate="blocking") — no code, no commit. The operator selected `untrack-and-seed` (D-23's recorded choice) after reviewing the reversibility framing and options table.

1. **Task 2: Untrack the wallpaper pointer, ignore it, and seed it at install** - `ac5c067` (fix)
2. **Task 3: Lint exemption end state, the --no-pending assertion, and ledger reconciliation** - `0ab2f74` (feat)

**Plan metadata:** committed alongside this SUMMARY (docs: complete plan)

## Files Created/Modified

- `.gitignore` - added `wallpapers/Pictures/Wallpapers/current.jpg` to the runtime-output exclusion block, with a comment explaining the five runtime writers/readers
- `stow.sh` - new seed-only-when-absent block (placed next to the compiled-stylesheet seed) that recreates `current.jpg` as a relative symlink to the committed default (`catppuccin/5-alien-planet.jpg`) if absent, with a WARNING (not loud exit-1) failure posture
- `hypr/.config/hypr/scripts/motion-lint` - EXEMPTIONS/LINE_EXEMPTIONS reasons rewritten to D-32's permanent phrasing with structured `pending: False` fields; new `--no-pending` opt-in flag (same argv-check shape as `--self-test`); usage doc comment updated
- `.planning/WINDOWS.md` - entries 1, 2, 8 marked `status: fixed` with `resolved_at` timestamps via `gsd-tools windows fixed`

## Decisions Made

- **D-23 (operator-confirmed, one-way):** `untrack-and-seed` selected over `exempt-the-path` at the Task 1 blocking checkpoint. The tree genuinely is dirty after a wallpaper-differing static theme switch, so exempting the path would report clean over a false invariant — the same green-gate-over-broken-reality pattern behind the Phase 6 and Phase 8 failures. Untracking makes the invariant actually true.
- **Seed failure posture:** the wallpaper pointer seed warns (not loud-fails) on absence, unlike the motion-file/GTK3-sass seeds beside it in `stow.sh` — a missing wallpaper degrades the desktop (no wallpaper, no lock background, no Material You source image) but does not prevent Hyprland from starting, the opposite failure class from those two seeds' hard config-parse failures.
- **`--no-pending` shares the canonical EXEMPTIONS/LINE_EXEMPTIONS python definitions via an env-var-gated early-exit branch**, rather than duplicating the exemption list in a second script — avoids a drift risk while still matching `--self-test`'s "check argv, branch to a wholly separate assertion pass, exit its status" shape. (Structurally the function definition had to be relocated earlier in the file, before the `--self-test`/`--no-pending` argv checks, so it is defined before either can call it — a plumbing detail, not a design change.)
- **Ledger reconciliation used the real, current 10-entry ledger, not the plan's stale 9-entry assumption** — see Deviations below for why the literal `open_count == 6` check does not hold.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Comment text accidentally contained the literal string it was disproving**

- **Found during:** Task 3, running the plan's own `'pending Phase 13' not in src` verification check
- **Issue:** My rewritten header comment explaining the D-32 end state said "none of the three carries 'pending Phase 13' phrasing anymore" — which itself contains the exact substring the check asserts is absent, failing the check on a false positive.
- **Fix:** Reworded to "none of the three carries the old temporary-retrofit phrasing anymore" — same meaning, no longer containing the literal banned substring.
- **Files modified:** `hypr/.config/hypr/scripts/motion-lint`
- **Verification:** Re-ran the python assertion; passes.
- **Committed in:** `0ab2f74` (Task 3 commit)

**2. [Rule 3 - Blocking, structural] `_motion_lint_checks` function had to be defined before both `--self-test` and `--no-pending`'s argv checks**

- **Found during:** Task 3, first `--no-pending` test run
- **Issue:** My initial placement of the `--no-pending` argv-check block (right after `--self-test`'s block, before `TARGET_DIR`/`ROOTS` are assigned) called `_motion_lint_checks`, but that bash function wasn't defined until much later in the file — `command not found`.
- **Fix:** Relocated the entire `_motion_lint_checks() { ... }` function definition (and its preceding "Single python pass" comment) to immediately after the `check()` helper, before `run_self_test()`. Both argv-check blocks (`--self-test`, `--no-pending`) now come after the function is defined, so both can call it.
- **Files modified:** `hypr/.config/hypr/scripts/motion-lint`
- **Verification:** `bash -n` syntax check passes; all three invocation modes (`motion-lint`, `--self-test`, `--no-pending`) tested and exit 0.
- **Committed in:** `0ab2f74` (Task 3 commit)

### Deviations Requiring Documentation (not auto-fixed — factual discrepancy in the plan's acceptance criterion)

**3. [Documentation deviation] WINDOWS.md `open_count` is 7, not the plan's literal 6**

- **Found during:** Task 3, running the plan's automated `open_count === 6` node check
- **Issue:** The plan's acceptance criterion (`open_count` is 6, with entries 1/2/8 fixed and 3-7/9 open) was authored against a 9-entry ledger snapshot (per `13-CONTEXT.md`'s D-25: "`open_count` goes 9 → 5" before this plan's own further deferral of entry 9). Since then, sibling plan 13-01 added entry 10 (the D-06 boundary-correction deviation) to the same ledger — a real, currently-open, legitimately out-of-scope-for-13-06 item that the plan's acceptance criterion never accounts for.
- **Resolution:** Marked exactly what the plan's action text specifies as fixed — entries 1, 2, 8 — and left entries 3, 4, 5, 6, 7, 9, **and 10** open. This is the honest ledger state: `total_count: 10`, `fixed_count: 3`, `open_count: 7`. I deliberately did NOT force-mark entry 10 fixed merely to make the literal number 6 — doing so would misrepresent an item this plan never touched, which is precisely the "green gate over false reality" anti-pattern D-25 exists to prevent.
- **Files affected:** `.planning/WINDOWS.md` (no code change needed; this is a documentation/acceptance-criterion note)
- **Recommendation:** A future ledger-count check should assert against the specific entry IDs (1, 2, 8 fixed; not-yet-fixed set unchanged otherwise) rather than a hardcoded total, so it doesn't drift again when a concurrent plan adds a new entry.

---

**Total deviations:** 2 auto-fixed (both Rule 3 - blocking, both structural bugs in my own first-draft implementation, not in the plan) + 1 documented factual discrepancy in the plan's own stale acceptance criterion (not an implementation bug).
**Impact on plan:** No scope creep. The auto-fixes were both required for the new `--no-pending` flag to function at all. The ledger discrepancy is fully explained and the underlying intent (which entries are fixed) is met exactly as the plan's action text specifies.

## Issues Encountered

- `hyprlock --verify-config` (named in the plan's acceptance criteria as one acceptable check) does not exist on this machine's hyprlock v0.9.6 — used the plan's permitted "or an equivalent dry check" alternative instead: confirmed `hyprlock.conf`'s exact background path (`~/Pictures/Wallpapers/current.jpg`, line 50) resolves via `realpath -e` to a real file after the untrack+reseed.
- No other issues — both tasks' automated `<verify>` commands passed on first or second attempt (see auto-fixed deviations above for the two structural fixes needed to make `--no-pending` work).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `theme-doctor` now exits 0 (206 passed, 0 failed, up from the 205/1 baseline measured immediately before this plan — the dirty-tree check is the one that flipped). `motion-lint` and `theme-parity` remain green (53/0 and 2697/0 respectively), matching their pre-plan baselines exactly (no regression).
- The structural blocker on plan 13-07's 10/10 `theme-stress-test` run (WINDOWS.md entry 9's root cause) is now removed — `current.jpg` will no longer dirty the tree on a static theme switch. Entry 9 itself stays open, correctly, until 13-07 actually runs that stress test and proves it end-to-end.
- Phase 13 is **not** complete: plan 13-03 remains open at 1/3 (blocked on an operator-only teardown measurement, per an explicit operator override that let 13-05 and this plan run ahead of it), and plan 13-07 has not started. This plan does not touch any of 13-03's four owned files (`fish/.config/fish/config.fish`, `zshell/.zshrc`, `wleave/.config/wleave/layout.json`, `.planning/PROJECT.md`) — confirmed clean via this plan's own `git diff --stat`, which shows only the four files this plan's frontmatter declares.

---
*Phase: 13-motion-retrofit-existing-surface-sweep*
*Completed: 2026-07-28*

## Self-Check: PASSED

- FOUND: `.gitignore`, `stow.sh`, `hypr/.config/hypr/scripts/motion-lint`, `.planning/WINDOWS.md`, this SUMMARY.md
- FOUND commits: `ac5c067` (Task 2), `0ab2f74` (Task 3), `8a7ade0` (this SUMMARY)
