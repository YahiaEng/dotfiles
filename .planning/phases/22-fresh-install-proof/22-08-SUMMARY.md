---
phase: 22-fresh-install-proof
plan: 08
subsystem: infra
tags: [stow, symlinks, theme-doctor, retirement-check, fixtures, sweep-scope]

# Dependency graph
requires:
  - phase: 22-fresh-install-proof
    plan: 02
    provides: "hypr/.config/hypr/scripts/stow-link-check — the dangling-symlink checker this plan corrects the declared scope of"
provides:
  - "stow-link-check with a declared scope that matches its actual scope: .config recursion ownership-gated to real PACKAGES-owned directories (plus a systemd/user/ exception), .local narrowed to the one path any package writes (.local/share/applications), the home root narrowed to a named allowlist (~/.zshrc). Depth-1 .config stays unconditional so a retired package's orphaned top-level link is still caught with no current PACKAGES entry to name it."
  - "A scope exclusion (not an EXEMPTIONS entry) that prunes the checker's own deployed test fixtures out of a normal sweep, keyed on the fixed stow-target relative path rather than fixture names — the phase-blocking self-reference plan 22-02 shipped is closed."
  - "A dev host with zero repository-caused dangling links — the three real retirement orphans (swayosd, wleave, hyprland.conf.bak) are removed and stow-link-check now exits 0 on a real $HOME sweep."
affects: [22-07-fresh-install-proof]

actuals:
  tokens: 6000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Scope exclusion vs EXEMPTIONS entry: a checker's own deployed test fixtures are out of declared sweep TERRITORY (a scope concept), never an EXEMPTIONS entry (reserved for links legitimately dangling BY DESIGN within the repo's own stow output) — same distinction D-22-06 draws, now demonstrated in code rather than just policy."
    - "Ownership-gated recursion with an unconditional depth-1 pass: a sweep root can catch every top-level entry unconditionally (so a RETIRED package's orphaned link stays detected with no current name to allowlist) while gating ONLY the recursive descent beneath it to a data-driven owned-directory list — narrower than either a full recursive sweep or a full name-based allowlist."

key-files:
  created: []
  modified:
    - hypr/.config/hypr/scripts/stow-link-check
    - .planning/phases/22-fresh-install-proof/deferred-items.md

key-decisions:
  - "Split the plan's two SWEEP_ROOTS-touching tasks into three atomic commits by re-deriving Task 1's isolated diff first (fixture exclusion only, against the original .config-recursive/.local-recursive/depth1 roots), committing it, then layering Task 2's root-narrowing on top — rather than committing the single combined edit the implementation naturally produced. Both were independently re-verified against their own <verify> blocks in isolation before each commit, preserving true per-task atomicity."
  - "Narrowed the home root (.) from a blanket depth-1 walk to a named allowlist ({'.zshrc'}), not just an ownership-gated recursion like .config. Justified because, unlike .config (which has a live retired-package-orphan case — swayosd/wleave — a name allowlist would blind), there is no equivalent known orphan at the home-root level, and a blanket depth-1 walk was reporting ~/.steampath, Steam's own artifact, never stow-managed. This was plan task 2 item 4's own explicit instruction (\"scope it to what is actually written\")."
  - "Fixed a Rule-1 bug discovered by this task's own retirement-check re-run: task 2's first-draft comments named the retired \"swayosd\"/\"wleave\" packages literally three times inside stow-link-check itself, tripping retirement-check's cross-package-refs class (6 references, 0 before task 2's edits) — the exact Phase 21 lesson (name retired surfaces by requirement ID, never by package name). Reworded to RETIRE-04/05 before committing task 3; retirement-check --all returned to failed_classes=0."

patterns-established:
  - "Scope-exclusion pruning keyed on a fixed stow-TARGET relative path (not a name pattern) — proven by an independent verification step (a throwaway poisoned-fixture copy placed OUTSIDE the real fixture tree, still correctly reported) that the rule cannot be defeated by renaming or by generically matching 'poisoned'."

requirements-completed: []  # RETIRE-09 intentionally NOT marked complete here — same rationale as 22-02: it is a single, phase-wide requirement that only closes when the actual container/VM proof passes end-to-end. This plan repairs a mechanism the proof depends on (making theme-doctor's stow-link fold actually pass), not the proof itself.

coverage:
  - id: T1
    description: "stow-link-check no longer reports its own deployed test fixtures as findings during a normal $HOME sweep, while --self-test still exercises all six fixtures directly and a poisoned-link copy placed OUTSIDE the fixture tree is still caught"
    requirement: "RETIRE-09"
    verification:
      - kind: automated
        ref: "stow-link-check --self-test -> 6 passed, 0 failed"
        status: pass
      - kind: automated
        ref: "stow-link-check (real $HOME sweep) -> zero FAIL/SCOPE-SKIP lines under tests/stow-link-fixtures/, one SCOPE-SKIP line naming the exclusion and reason"
        status: pass
      - kind: automated
        ref: "stow-link-check --root <throwaway poisoned-link copy outside tests/stow-link-fixtures/> -> FAIL reported (rule keys on scope, not fixture names)"
        status: pass
    human_judgment: false
  - id: T2
    description: "SWEEP_ROOTS narrowed to what stow.sh's PACKAGES loop actually writes (.local/share/applications only, .config recursion ownership-gated, home root named-allowlisted), re-measured directly against every package's shipped tree; the two retirement orphans and the .bak file stay detected"
    requirement: "RETIRE-09"
    verification:
      - kind: automated
        ref: "stow-link-check (real $HOME sweep, before task 3's removal) -> zero findings under ~/.local/share/Steam/, ~/.local/share/containers/, ~/.config/zen/; swayosd/wleave/hyprland.conf.bak still reported FAIL"
        status: pass
      - kind: automated
        ref: "stow-link-check --self-test -> 6 passed, 0 failed"
        status: pass
      - kind: automated
        ref: "stow-link-check --list -> every retained root prints a non-empty justification string"
        status: pass
    human_judgment: false
  - id: T3
    description: "The three repository-caused dangling links (swayosd, wleave, hyprland.conf.bak) are removed from the dev host after independent per-path safety verification; stow-link-check and theme-doctor's stow-link fold both pass clean; deferred-items.md records what was resolved"
    requirement: "RETIRE-09"
    verification:
      - kind: automated
        ref: "test -L && ! test -e confirmed for all three paths immediately before rm (never rm -r); ls -la ~/.config | grep -E 'swayosd|wleave|hyprland.conf.bak' -> no output after removal"
        status: pass
      - kind: automated
        ref: "stow-link-check (real $HOME sweep) -> exit 0, 2 passed, 0 failed, zero findings"
        status: pass
      - kind: automated
        ref: "theme-doctor -> 580 passed, 0 failed (stow-link fold PASS, git-clean invariant PASS once committed)"
        status: pass
      - kind: automated
        ref: "spot-check: ~/.config/hypr/hyprland.lua, ~/.config/walker, ~/.config/gtk-3.0/gtk.css, ~/.config/quickshell/shell.qml all still resolve — no live stow package link disturbed"
        status: pass
    human_judgment: false

duration: ~35min
completed: 2026-08-17
status: complete
---

# Phase 22 Plan 08: stow-link-check Sweep-Scope Correction & Host-Debt Cleanup Summary

**Narrowed `stow-link-check`'s declared sweep scope to match what `stow.sh`'s `PACKAGES` loop actually writes (fixture self-exclusion + `.local`/`.config`/home-root re-scoping), then removed the three real dangling symlinks the corrected sweep confirmed — dropping the real-host finding count from 1095 to 0.**

## Performance

- **Duration:** ~35 min
- **Tasks:** 3 (fixture exclusion, sweep-root narrowing, host cleanup)
- **Files modified:** 2 (`stow-link-check`, `deferred-items.md`)

## Accomplishments

- **Fixture self-reference closed (phase-blocking defect).** `stow-link-check`'s own committed fixtures deploy to `~/.config/hypr/scripts/tests/stow-link-fixtures/` via the hypr package on every machine; a `.config`-recursive sweep was reporting its own five deliberately-poisoned links as real findings on every run, which would have permanently failed `theme-doctor` on every fresh install. Fixed with a scope exclusion (distinct from an `EXEMPTIONS` entry) keyed on the fixed deployment path, printed whenever it fires. Proven not to be a name-based blind spot: a throwaway poisoned-link copy placed outside the fixtures tree is still reported.
- **Sweep roots re-derived from measurement, not trusted from the prior plan.** Enumerated every one of the 17 `PACKAGES` entries' shipped `.config`/`.local`/home-root trees directly. Result: `.local` narrowed from a full recursive sweep to `.local/share/applications` (the one path `vscodium` writes — the prior root was catching 1077 Steam findings and 8 podman findings); `.config` recursion is now ownership-gated to a measured `OWNED_CONFIG_TOP` set (plus a `systemd/user/` exception) rather than descending into every real directory including third-party ones like `zen/`; the home root narrowed from a blanket depth-1 walk to a named allowlist (`.zshrc`, the only top-level dotfile any package ships), removing `~/.steampath` (Steam's own artifact). The `.config` depth-1 pass itself stays deliberately unconditional so a retired package's orphaned top-level link (no current `PACKAGES` entry to name it) is still caught — proven by requiring task 2's own verification to show `swayosd`/`wleave`/`hyprland.conf.bak` still detected before task 3 removed them.
- **Dev host cleaned.** All three real repository-caused dangling links removed after independent `test -L` + non-resolving `test -e` verification on each, using plain `rm` (never `rm -r`). `stow-link-check` now exits 0 with zero findings on the real `$HOME`; `theme-doctor`'s stow-link fold passes; no live stow package link was disturbed (spot-checked hypr, walker, gtk-3.0, quickshell).
- **`deferred-items.md` corrected.** The three real items moved to a Resolved section; the Steam/podman/zen entries reclassified as permanently out-of-scope-by-design (task 2 narrowed the sweep's own declared territory, not merely their absence on this run); the 1095 figure marked historical.

## Task Commits

Each task was committed atomically:

1. **Task 1: Stop the checker reporting its own deployed test fixtures** — `b04da8c` (fix)
2. **Task 2: Narrow the sweep roots to what stow actually writes** — `bd93702` (fix)
3. **Task 3: Remove the three repository-caused dangling links from the dev host** — `164fccc` (fix)

## Files Created/Modified

- `hypr/.config/hypr/scripts/stow-link-check` — fixture scope exclusion (Task 1), ownership-gated `.config` recursion + narrowed `.local`/home-root sweep roots (Task 2), retired-surface prose reworded to requirement IDs (Task 3 fix, see Deviations)
- `.planning/phases/22-fresh-install-proof/deferred-items.md` — the three real items marked Resolved; Steam/podman/zen entries reclassified as out-of-scope-by-design; the 1095 figure marked historical

## Decisions Made

- **Split the naturally-combined Task 1 + Task 2 implementation into two independently-verified commits.** The two changes share the same file and overlapping header comments, but the plan requires them atomic and separately verifiable (Task 2's own `<verify>` block requires the retirement orphans to still be detected — a check that is meaningless unless run against Task 2's own isolated diff). Reverted the file to the pre-edit state, rebuilt Task 1's isolated diff, verified and committed it, then layered Task 2's root-narrowing on top and re-verified before its own commit.
- **Home root narrowed to a named allowlist rather than ownership-gated recursion**, unlike `.config`. `.config` has a live retired-package-orphan case (`swayosd`/`wleave`) a name allowlist would blind; the home root has no equivalent known case, so narrowing to `{'.zshrc'}` (the sole measured top-level dotfile any package ships) loses no real-finding coverage while removing `~/.steampath` — exactly what plan task 2 item 4 asked for ("scope it to what is actually written").

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reworded three literal retired-package-name references in `stow-link-check`'s own comments**
- **Found during:** Task 3 (verifying `theme-doctor`'s stow-link fold and re-running `retirement-check --all`)
- **Issue:** Task 2's first-draft comments explaining why `.config`'s depth-1 pass stays unconditional named the retired `swayosd`/`wleave` packages literally three times inside `stow-link-check` itself. `retirement-check`'s `cross-package-refs` class flagged these as 6 references (3 for each retired surface) — `stow-link-check` postdates `retirement-check`'s `CHECKER_INTERNALS_REL` exclusion list (added in plan 22-02, after that list was authored), so it is not exempted from the scan. This is the exact Phase 21 lesson already recorded in PROJECT.md: name retired surfaces by requirement ID, never by package name, in repo prose.
- **Fix:** Reworded all three references to `RETIRE-04/05` (the requirement IDs Phase 20 retired swayosd/wleave under).
- **Files modified:** `hypr/.config/hypr/scripts/stow-link-check`
- **Verification:** `retirement-check --all` returned to `failed_classes=0`; `theme-doctor` returned to 580 passed / 0 failed once the tree was committed clean.
- **Committed in:** `164fccc` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug introduced by this plan's own Task 2 edit, caught and fixed before Task 3's commit)
**Impact on plan:** Necessary correctness fix — an uncaught literal package-name reference would have left `theme-doctor` failing on this host indefinitely (a self-inflicted repeat of Phase 21's exact failure mode). No scope creep; the fix stayed inside the one file Task 2 already touched.

## Issues Encountered

None blocking. The retirement-check regression above was caught by this task's own verification step (re-running `retirement-check --all` as part of confirming `theme-doctor`'s overall pass) before it could reach a commit, matching the deviation-rule discipline rather than requiring a separate fix-up pass.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `stow-link-check` is fixed on `main` and its scope now matches its declared territory — `theme-doctor` can pass its stow-link fold on a genuinely fresh install for the first time, unblocking plan 22-07's container re-run (which depends on this landing first, per the plan's `<execution_context>`).
- Push to `origin/main` still required before the container tier can see these fixes (`container-run.sh` clones from the real remote) — see Performance Metrics / final commit below.
- The dev host now carries zero repository-caused dangling links; `deferred-items.md` reflects the corrected, resolved state.

---
*Phase: 22-fresh-install-proof*
*Completed: 2026-08-17*

## Self-Check: PASSED

All claimed files verified present on disk (`hypr/.config/hypr/scripts/stow-link-check`, `.planning/phases/22-fresh-install-proof/deferred-items.md`); all 3 claimed commits (`b04da8c`, `bd93702`, `164fccc`) verified present in `git log --oneline --all`.
