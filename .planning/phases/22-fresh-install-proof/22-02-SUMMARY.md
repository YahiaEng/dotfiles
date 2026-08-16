---
phase: 22-fresh-install-proof
plan: 02
subsystem: infra
tags: [stow, symlinks, theme-doctor, retirement-check, fixtures, self-test]

# Dependency graph
requires:
  - phase: 22-fresh-install-proof
    plan: 01
    provides: baseline evidence that the container gate needs harness repair before this checker's --root-based fixture proof means anything for the container tier
provides:
  - "hypr/.config/hypr/scripts/stow-link-check — a permanent, fixture-backed dangling-symlink sweep over every stow-created target ($HOME/.config recursive, $HOME/.local recursive, $HOME/Pictures/Wallpapers recursive, $HOME/Pictures/Screenshots recursive, $HOME depth-1), with full-chain symlink resolution, a vacuous-green guard, a deny-by-default empty exemption list, and a --self-test replaying six committed fixtures"
  - "theme-doctor's fifth fold — unguarded, headless-safe, so plan 22-04's container step can call it and have it actually execute"
affects: [22-04-fresh-install-proof]

actuals:
  tokens: 5090
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Full-chain symlink resolution via an explicit hop-by-hop walk with a seen-set (never os.path.realpath()'s single-call shortcut), so a symlink loop is detected and reported dangling rather than hanging the sweep"
    - "Vacuous-green guard on a declared sweep-root set, excluding the trivial always-present home root from the presence denominator"

key-files:
  created:
    - hypr/.config/hypr/scripts/stow-link-check
    - hypr/.config/hypr/scripts/tests/stow-link-fixtures/README.md
    - hypr/.config/hypr/scripts/tests/stow-link-fixtures/compliant-resolving-links/
    - hypr/.config/hypr/scripts/tests/stow-link-fixtures/poisoned-dangling-config-link/
    - hypr/.config/hypr/scripts/tests/stow-link-fixtures/poisoned-dangling-systemd-unit/
    - hypr/.config/hypr/scripts/tests/stow-link-fixtures/poisoned-dangling-pictures-link/
    - hypr/.config/hypr/scripts/tests/stow-link-fixtures/poisoned-symlink-chain/
    - hypr/.config/hypr/scripts/tests/stow-link-fixtures/empty-no-roots/
    - .planning/phases/22-fresh-install-proof/deferred-items.md
  modified:
    - theme-engine/.config/theme-engine/theme-doctor

key-decisions:
  - "Declared five sweep roots exactly as D-22-06/the plan's discretion note specifies (.config, .local, Pictures/Wallpapers, Pictures/Screenshots all recursive; . depth-1) rather than narrowing .local to only the vscodium share/applications entry stow.sh actually populates today — the broader declaration matches 'every path stow.sh's PACKAGES loop can write to' and stays correct if a future package adds a second .local target, at the cost of surfacing unrelated host debt (Steam runtime files) when run against this specific dev machine's real $HOME. Documented as an out-of-scope finding, not fixed."
  - "The home root ('.', depth-1) is declared in --list (all five roots visible) but excluded from the vacuous-green guard's presence denominator, since $SWEEP_HOME/. always exists trivially for any valid --root — a root that can never be absent cannot inform a guard whose whole purpose is detecting absence."
  - "Exemption list ships genuinely empty, per D-22-06's explicit instruction to start empty and add an entry only when a real sweep surfaces a link legitimately dangling by design, with the reason written at that moment. The real sweep against this dev host's own $HOME did surface such links (Steam, retired-package leftovers, a browser lock file) but they are host debt outside this repo's own stow-managed surface, not links this repo's own packages create — so no exemption entry was added; logged to deferred-items.md instead."

patterns-established:
  - "Full-chain symlink resolution via explicit hop-by-hop walk + seen-set for loop/dangling-chain detection — reusable pattern for any future checker that must resolve symlink chains without a shell-out to readlink -e"

requirements-completed: []  # RETIRE-09 intentionally NOT marked complete — it is a single, phase-wide requirement (ROADMAP.md: "deliberately a single-requirement phase") that only closes when the actual container/VM proof passes end-to-end. This plan builds one mechanism (SC-2's symlink-absence check) the proof depends on, matching 22-01's same deliberate non-completion.

coverage:
  - id: T1
    description: "Six committed fixture trees exist under hypr/.config/hypr/scripts/tests/stow-link-fixtures/, each a one-artifact mutation of a shared compliant baseline, each recorded as a real symlink (mode 120000) in the git index"
    requirement: "RETIRE-09"
    verification:
      - kind: automated
        ref: "git ls-files -s hypr/.config/hypr/scripts/tests/stow-link-fixtures | grep -c '^120000' -> 16 (>= 6 required)"
        status: pass
      - kind: automated
        ref: "\\ls hypr/.config/hypr/scripts/tests/stow-link-fixtures | grep -vc '^README.md$' -> 6"
        status: pass
    human_judgment: false
  - id: T2
    description: "stow-link-check built with --self-test, --list, --root; full-chain resolution proven against poisoned-symlink-chain; vacuous-green guard proven against empty-no-roots; deterministic across two runs"
    requirement: "RETIRE-09"
    verification:
      - kind: automated
        ref: "stow-link-check --self-test -> Self-test summary: 6 passed, 0 failed, rc=0"
        status: pass
      - kind: automated
        ref: "bash -n stow-link-check && test -x stow-link-check"
        status: pass
      - kind: automated
        ref: "two consecutive --root <compliant-resolving-links> runs byte-identical (DETERMINISTIC printed)"
        status: pass
      - kind: automated
        ref: "--list exits 0, prints all five declared roots; --bogus-flag exits 2; retirement-check --all exits 0 after the new script lands"
        status: pass
    human_judgment: false
  - id: T3
    description: "theme-doctor carries an unguarded fifth fold (colour-lint's shape verbatim); guarded-skip provable via STOW_LINK_CHECK=/nonexistent; three pre-existing folds byte-unchanged; pushed to origin/main"
    requirement: "RETIRE-09"
    verification:
      - kind: automated
        ref: "bash -n theme-doctor; bare run emits 1096 stow-link-check-prefixed lines (>=1 required); STOW_LINK_CHECK=/nonexistent yields exactly one [SKIP] and zero tally lines"
        status: pass
      - kind: automated
        ref: "grep -c HYPRLAND_INSTANCE_SIGNATURE over the new fold's line range -> 0; git diff origin/main shows insertions-only, no deletions in lines 455-600's existing fold bodies"
        status: pass
      - kind: automated
        ref: "retirement-check --all exits 0; git rev-parse HEAD == origin/main; git show origin/main:hypr/.config/hypr/scripts/stow-link-check resolves"
        status: pass
    human_judgment: false

duration: ~25min
completed: 2026-08-16
status: complete
---

# Phase 22 Plan 02: Dangling-Symlink Checker Summary

**Built `stow-link-check`, the first mechanism in this repo for SC-2's symlink clause — full-chain resolution, a vacuous-green guard, six proven fixtures, and an unguarded fifth `theme-doctor` fold that runs headless — then pushed to `origin/main` where plan 22-04's container step can clone it.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 3 (fixture trees, checker build, theme-doctor fold + push)
- **Files created:** 8 fixture-tree paths + `stow-link-check` + `deferred-items.md` (30 files total incl. individual fixture files/symlinks)
- **Files modified:** 1 (`theme-engine/.config/theme-engine/theme-doctor`)

## Accomplishments

- **Six committed fixture trees** under `hypr/.config/hypr/scripts/tests/stow-link-fixtures/`, each a `$HOME`-mirror pointed at via `--root`, each a one-artifact mutation of `compliant-resolving-links`: two dangling-link fixtures per non-`.config` sweep root class (`.config/systemd/user/`, `Pictures/Wallpapers/`), a two-hop symlink-chain fixture proving full resolution beats a one-hop existence test, and an `empty-no-roots` fixture proving the vacuous-green guard. 16 real symlinks committed at git mode `120000`, verified with `git ls-files -s`.
- **`stow-link-check`** — declares five sweep roots as pipe-free structured Python data (mirroring `retirement-check`'s registry idiom): `.config`, `.local`, `Pictures/Wallpapers`, `Pictures/Screenshots` all recursive, plus `.` at depth-1 only. Resolves every symlink's full chain hop-by-hop with an explicit `seen`-set (never `os.path.realpath()`'s single-call shortcut), so a link landing on an existing intermediate whose own target is absent is still reported, and a genuine symlink loop is reported dangling rather than hanging the sweep. `--self-test` replays all six fixtures: **6 passed, 0 failed**. `--list`, `--root <dir>` and bare-invocation-sweeps-`$HOME` all match `retirement-check`'s CLI conventions; an unrecognised flag exits 2.
- **theme-doctor's fifth fold** — copies the `colour-lint` fold's unguarded shape verbatim (`[[ -x "$CHECKER" ]]` only, no live-session guard), inserted after the `retirement-check` fold and before `CLEAN-02`, changing none of the three existing folds (confirmed via `git diff origin/main`, insertions-only). `STOW_LINK_CHECK` env override makes the guarded-skip degradation path itself provable.
- **Pushed to `origin/main`** (`fd8c605`) — mandatory per the plan, since `verify/container-run.sh` clones from the real remote; a locally-committed checker would have been invisible to plan 22-04's container step.

## Task Commits

Each task was committed atomically:

1. **Task 1: six committed fixture trees** — `e62eed2` (test)
2. **Task 2: stow-link-check checker** — `7259c14` (feat)
3. **Task 3: theme-doctor fold + push** — `fd8c605` (feat)

## Files Created/Modified

- `hypr/.config/hypr/scripts/stow-link-check` — the new checker (424 lines: bash CLI dispatch + a single embedded python3 sweep pass)
- `hypr/.config/hypr/scripts/tests/stow-link-fixtures/` — six fixture subtrees + `README.md` expected-verdict table
- `theme-engine/.config/theme-engine/theme-doctor` — new fifth fold, 33 lines inserted, nothing else touched
- `.planning/phases/22-fresh-install-proof/deferred-items.md` — out-of-scope real-host findings (see Deviations below)

## Decisions Made

- **Kept `.local` recursive rather than narrowing it to the one path stow.sh actually populates (`.local/share/applications`).** The plan's own declared sweep-root set specifies `.local` recursive; narrowing it would be quieter on this specific dev host but would silently under-cover a future package that adds a second `.local` target. Left as specified; the noise it currently produces on this host is logged, not treated as a checker defect.
- **`.` (the home root) is listed by `--list` but excluded from the vacuous-green guard's presence denominator.** `$SWEEP_HOME/.` always exists trivially for any valid `--root`/`$HOME`, so counting it toward "roots present" would make the guard structurally unable to ever fire (`empty-no-roots` would falsely pass). Documented in the script's own comments.
- **Exemption list ships empty.** D-22-06 requires starting empty and adding an entry only when a real sweep surfaces a link legitimately dangling by design, with the reason written at that moment. The real sweep against this dev host did surface such links, but they belong to unrelated host software (Steam, a browser lock file) or retired-package leftovers on this one long-lived machine — none of them are this repo's own stow-managed surface, so none earned an exemption entry. Logged to `deferred-items.md` instead of silently exempted or silently fixed.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written; no bugs or blocking issues encountered during the three tasks.

### Out-of-Scope Findings (logged, not fixed)

**1. Real dangling symlinks on this dev host, outside this plan's file scope**
- **Found during:** Task 3, running the folded `theme-doctor` bare against the real `$HOME` (not a fixture)
- **What:** 1095 real dangling symlinks — Steam's own runtime artifacts under `~/.local/share/Steam/`, two retired-package leftover links (`~/.config/swayosd`, `~/.config/wleave`, both deleted from the repo in Phase 20 but never unstowed on this specific host), a stale `~/.config/hyprland.conf.bak` predating the Phase 13.1 Lua migration, and a Zen browser profile lock file.
- **Why not fixed:** None are caused by this plan's changes; none are reachable by the container/VM proof tier this checker exists for (a fresh clone/VM has none of this accumulated state); fixing them would mean mutating live host state and unrelated software (Steam, Zen) entirely outside this plan's declared file scope.
- **Recorded in:** `.planning/phases/22-fresh-install-proof/deferred-items.md`

## Issues Encountered

None blocking. The real-host noise described above was discovered, understood, and correctly scoped out rather than treated as an issue with the new checker.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `stow-link-check` and its `theme-doctor` fold are live on `origin/main` (`fd8c605`) — plan 22-04's container step can now clone and call them; the container's fresh `$HOME` will not carry any of the real-host noise this plan's own verification surfaced, since none of it originates from this repo's stow packages.
- `.planning/phases/22-fresh-install-proof/deferred-items.md` carries the one real-host finding forward in case a future host-hygiene pass wants it.

---
*Phase: 22-fresh-install-proof*
*Completed: 2026-08-16*

## Self-Check: PASSED

All 11 claimed files/paths verified present on disk; all 4 claimed commits verified present in `git log --oneline --all`.
