---
phase: 12-unified-design-token-pipeline
plan: 03
subsystem: theming
tags: [jq, hyprland, gtk4-css, bash, matugen, contract-json, design-tokens]

# Dependency graph
requires:
  - phase: 12-01
    provides: quickshell/.config/quickshell/modules/qmldir (unrelated surface; no shared code with this plan)
provides:
  - "motion.json: the single hand-authored two-layer (durations + easings) + trimmed-semantic motion-token source"
  - "lib/motion.sh: theme_engine_read_motion_scale, theme_engine_validate_motion_values, theme_engine_render_motion_files"
  - "Three rendered motion targets under ~/.local/state/theme/: motion.json (QML), gtk-4.0-motion.css, hyprland-motion.conf"
  - "contract.json engine_owned_files array — single source for commit.sh's rsync excludes AND theme-doctor's new state-manifest gate"
  - "Two new contract.sh format tags: css-vars, hypr-motion (plus scss-vars, closing a pre-existing ags.scss gap)"
  - "theme-doctor D-29 state-manifest gate, proven to fail on an undeclared file before being trusted to pass"
affects: [12-04, 12-05, 12-06, 12-07, 12-08, 13-motion-retrofit]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Motion is the third theme-orthogonal state axis (after icon-theme, font-choice) — own state file, excluded from rsync --delete, re-rendered every run regardless of theme/mode"
    - "One array (engine_owned_files) drives two consumers (commit.sh excludes, theme-doctor gate) so they cannot drift — same shape contract.json already used for render targets"
    - "Single shared jq TSV computation feeds all three motion render targets plus the D-09 WARN pass, so they can never disagree with each other"

key-files:
  created:
    - theme-engine/.config/theme-engine/motion.json
    - theme-engine/.config/theme-engine/lib/motion.sh
    - .planning/phases/12-unified-design-token-pipeline/deferred-items.md
  modified:
    - theme-engine/.config/theme-engine/lib/generate.sh
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/lib/contract.sh
    - theme-engine/.config/theme-engine/theme-parity
    - theme-engine/.config/theme-engine/lib/commit.sh
    - theme-engine/.config/theme-engine/theme-doctor

key-decisions:
  - "floor_ms lives in motion.json as data (not a motion.sh shell constant) — the multiplier table and the floor retune together as a data edit"
  - "engine_owned_files entries are stored as bare names; commit.sh excludes them uniformly without a trailing slash (verified empirically that rsync --exclude=name matches both a file and a directory of that name)"
  - "ags.scss (pre-existing AGS-applet render target) was never in contract.json's files[] array — closed with a new scss-vars format rather than left as permanent dead zone in the new D-29 gate"

requirements-completed: [TOKEN-03]

coverage:
  - id: D1
    description: "One theme-apply run renders motion.json, gtk-4.0-motion.css and hyprland-motion.conf from the single motion.json source"
    requirement: "TOKEN-03"
    verification:
      - kind: integration
        ref: "theme-apply catppuccin && ls ~/.local/state/theme/{motion.json,gtk-4.0-motion.css,hyprland-motion.conf}"
        status: pass
      - kind: integration
        ref: "Hyprland --verify-config -c <throwaway sourcing hyprland-motion.conf>"
        status: pass
      - kind: integration
        ref: "python3 headless Gtk.CssProvider().load_from_path(gtk-4.0-motion.css)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Two renders of the same motion.json at the same scale produce byte-identical output"
    requirement: "TOKEN-03"
    verification:
      - kind: integration
        ref: "cmp across two independent mktemp -d renders of all three targets"
        status: pass
    human_judgment: false
  - id: D3
    description: "Empty/zero-semantic motion.json fails the render loudly and writes nothing"
    requirement: "TOKEN-03"
    verification:
      - kind: unit
        ref: "theme_engine_render_motion_files against an empty file and a {semantic:{}} fixture — both return non-zero, no out_dir created"
        status: pass
    human_judgment: false
  - id: D4
    description: "Motion targets are full contract.json files[] entries validated by theme-parity through purpose-built css-vars/hypr-motion extractors"
    requirement: "TOKEN-03"
    verification:
      - kind: integration
        ref: "theme-parity (1894 passed / 0 failed, up from 1542/0 baseline)"
        status: pass
    human_judgment: false
  - id: D5
    description: "engine_owned_files drives both commit.sh's exclusions and theme-doctor's new D-29 state-manifest gate, proven to fail before being trusted to pass"
    requirement: "TOKEN-03"
    verification:
      - kind: integration
        ref: "touch ~/.local/state/theme/zz-undeclared-probe -> theme-doctor FAILs naming it; removed -> PASSes"
        status: pass
      - kind: integration
        ref: "motion-scale sentinel + current-theme + logs/ all survive a live theme-apply run"
        status: pass
    human_judgment: false

duration: 40min
completed: 2026-07-26
status: complete
---

# Phase 12 Plan 03: Unified Design-Token Pipeline — Motion Spine Summary

**One hand-authored `motion.json` renders through a new `motion.sh` emitter to three binary-verified targets (Hyprland bezier fragment, GTK4 CSS custom properties, QML JSON) via `theme-apply`'s existing entrypoint, with all three brought inside `contract.json`'s manifest and a new `engine_owned_files` array closing the D-29 state-drift bug class across both `commit.sh` and a new `theme-doctor` gate.**

## Performance

- **Duration:** ~40 min
- **Started:** 2026-07-26T19:20:00Z (approx.)
- **Completed:** 2026-07-26T19:57:46Z
- **Tasks:** 3
- **Files modified:** 8 (2 new, 6 modified) + 1 deviation log

## Accomplishments

- `motion.json` authored as the sole two-layer (durations + easings) + trimmed-semantic (D-25) motion-token source, with the four motion-scale presets and the 40ms D-09 collapse floor carried as data.
- `lib/motion.sh` created: closed-set scale reader (D-21), a D-02(a) render-time validator that catches malformed easings, unresolvable semantic references, and non-positive resolved durations before a single byte is written, and a renderer emitting all three targets from one shared jq computation.
- `theme-apply` end-to-end proven: Hyprland's own binary accepts the emitted fragment (`--verify-config`), GTK4's own `CssProvider` parses the CSS fragment non-empty, and the QML JSON target is well-formed with a 6-element bezier array per semantic entry.
- `contract.json`/`contract.sh`/`theme-parity` extended with two new format tags (`css-vars`, `hypr-motion`) so the motion targets get exactly the same name-set/semantic-value parity rigor as every colour target — 1894 passed / 0 failed (up from the 1542/0 baseline).
- `engine_owned_files` closes D-29 for good: one array now drives both `commit.sh`'s rsync exclusions and a new `theme-doctor` gate that FAILs naming any undeclared file under `$STATE_DIR` — proven to fail on a deliberately planted probe file before being trusted to pass.

## Task Commits

1. **Task 1: One motion source, three render targets, end to end through theme-apply** - `b455fca` (feat)
2. **Task 2: Bring the motion targets inside contract.json with two new format extractors** - `9283e9f` (feat)
3. **Task 3: engine_owned_files — one array driving both commit.sh's exclusions and a new state-manifest gate** - `42055dc` (feat)

**Plan metadata:** committed alongside this SUMMARY (see final-commit step)

## Files Created/Modified

- `theme-engine/.config/theme-engine/motion.json` - hand-authored two-layer + semantic motion-token source
- `theme-engine/.config/theme-engine/lib/motion.sh` - reader, D-02(a) validator, and three-target renderer
- `theme-engine/.config/theme-engine/lib/generate.sh` - sources motion.sh, calls the render function as a third theme-orthogonal-axis sibling, propagates its failure
- `theme-engine/.config/theme-engine/contract.json` - 4 new `files[]` entries (3 motion + `ags.scss`), new `engine_owned_files` array
- `theme-engine/.config/theme-engine/lib/contract.sh` - `css-vars`/`hypr-motion`/`scss-vars` extractor branches; `contract_engine_owned_files`/`contract_state_metadata_files` helpers
- `theme-engine/.config/theme-engine/theme-parity` - `enforce_emptiness` extended to the three new format tags
- `theme-engine/.config/theme-engine/lib/commit.sh` - exclusion mechanism now array-driven from `contract.json`, aborts on an empty/unreadable array instead of a bare `--delete`
- `theme-engine/.config/theme-engine/theme-doctor` - new D-29 state-manifest gate
- `.planning/phases/12-unified-design-token-pipeline/deferred-items.md` - logs one pre-existing, out-of-scope git-clean finding (see Deviations)

## Decisions Made

- `floor_ms` lives in `motion.json` as data, not a `motion.sh` shell constant — matches the plan's explicit instruction that the multiplier table and the floor retune together as a data edit rather than a code edit.
- `engine_owned_files` entries are stored as bare names (no directory trailing slash); verified empirically via a throwaway rsync run that `--exclude=name` (no slash) protects both a file and a directory of that name identically to the historical `--exclude=name/` — this removed the need for any per-entry directory/file bookkeeping in `commit.sh`.
- `contract_engine_owned_files`/`contract_state_metadata_files` were added to `contract.sh` (rather than re-parsing `contract.json` directly in `commit.sh`/`theme-doctor`) so the "one array, two consumers, cannot drift" guarantee actually holds at the code level, following the existing `contract_files`/`contract_presence_only_files` precedent.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1/2 - Pre-existing drift closed by the new gate] `ags.scss` was never a `contract.json` files[] entry**
- **Found during:** Task 3, while proving the new D-29 state-manifest gate against the live `$STATE_DIR`
- **Issue:** `ags.scss` (a real matugen-rendered target for the Phase 10 AGS media applet, confirmed via `matugen/config.toml`'s `[templates.ags]` and its own colour content) had zero `contract.json` coverage — no format tag, no parity checking, and it would have permanently tripped the new state-manifest gate as an "unaccounted" file forever, defeating the gate's purpose. The plan's own Task 3 action text explicitly anticipates and authorizes exactly this: "reconcile any genuine resident that is missing from the array rather than relaxing the check to make it pass."
- **Fix:** Added `ags.scss` to `contract.json`'s `files[]` with a new `scss-vars` format (`$name: value;` SCSS variable syntax, distinct from `hypr-motion`'s `bezier =`/`$name = value` shapes), matching `contract.sh` extractor branches, and added `scss-vars` to `theme-parity`'s `enforce_emptiness` set.
- **Files modified:** `contract.json`, `lib/contract.sh`, `theme-parity`
- **Verification:** `theme-parity` gained the new `ags.scss` parity checks with zero failures (1894/0 total); `contract_extract_names`/`contract_extract_values` against the live `~/.local/state/theme/ags.scss` return the expected 19 names with no empty values.
- **Committed in:** `9283e9f` (Task 2 commit — bundled there since it's the same "bring a render target inside the contract" shape as the motion targets)

**2. [Rule 3 - acceptance-criterion literal] Reworded a historical comment in `commit.sh`**
- **Found during:** Task 3, running the exact `grep -c -- '--exclude=logs/'` acceptance-criterion command
- **Issue:** The pre-existing D-40 deviation comment's prose contained the literal string `--exclude=logs/`, which the acceptance criterion greps for verbatim to confirm the flag is no longer hardcoded as executable text — the comment's prose accidentally matched even though the actual `rsync` flag was already array-driven.
- **Fix:** Reworded the comment to describe the same fact ("excluding the logs directory is required") without the literal flag string. No behavior change.
- **Files modified:** `lib/commit.sh`
- **Verification:** `grep -c -- '--exclude=logs/' lib/commit.sh` now returns `0`.
- **Committed in:** `42055dc` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (1 pre-existing-drift closure, 1 acceptance-criterion wording fix)
**Impact on plan:** Both were necessary for the plan's own stated success criteria (a truly complete D-29 state-manifest accounting; a literally-passing acceptance command) and introduced no scope creep beyond what Task 3's own action text already authorized.

## Issues Encountered

- The sandbox's default shell for `Bash` tool calls is `zsh`, under which `contract.sh`'s `${BASH_SOURCE[0]}`-based path resolution silently breaks (`CONTRACT_LIB_DIR`/`CONTRACT_JSON` resolve incorrectly, surfacing as a spurious "command not found: jq" from inside a broken function). All manual verification of `contract.sh` functions was run via explicit `bash -c '...'` to avoid this — no repo code was affected, since `theme-apply`/`theme-doctor`/`theme-parity` all have `#!/usr/bin/env bash` shebangs and are always invoked as bash regardless of the caller's interactive shell.
- STATE.md's precondition ("theme-doctor exits 0, 136 passed / 0 failed") was already stale at plan start: an untracked file unrelated to this plan (`vscodium/.local/share/applications/Vampire Survivors.desktop`, confirmed pre-existing via `git log --diff-filter=A` returning no adding commit) makes the CLEAN-02 git-clean check FAIL regardless of this plan's changes. Logged to `deferred-items.md` per the scope-boundary rule rather than fixed — not this plan's file, not this plan's task.

## Known Stubs

None — every target this plan claims to deliver is fully wired and exercised end-to-end (rendered, parsed by the real consuming binary/library, and parity-checked). Consumption of the new motion tokens by `hyprland.conf`'s `source =` line, `animations.conf`'s `enabled` key, and wleave's CSS retrofit are explicitly out of scope for this plan (reserved for Phase 13 per D-04/D-19) — not stubs, deliberate fencing already documented in the plan's own objective and `assumption_delta_decision`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `theme-doctor`: **140 passed / 1 failed** — the 1 failure is the pre-existing, unrelated untracked-file git-clean finding described above (not a regression from this plan; every other check, including the 3 new motion-file existence checks and the new state-manifest gate, is green). Baseline for later plans in this phase to assert against: **140** (once the stray file is resolved by its owner, this becomes 141/0).
- `theme-parity`: **1894 passed / 0 failed** (up from the 1542/0 baseline recorded at v3.0 scoping) — this is the number later plans (12-04's D-31 byte-identity assertion across all 22 palettes) should assert against.
- The motion pipeline's architectural spine (source -> transform -> three formats -> atomic commit -> manifest -> gates) is now proven end-to-end on one real `theme-apply` run and is the shape every later plan in this phase expands outward from.
- `engine_owned_files` is now the single source both `commit.sh` and `theme-doctor` read — any future engine-owned state file (a future motion-scale picker, or anything Phase 13/14 introduces) is a one-line `contract.json` addition, not a new hand-added `--exclude` flag to remember.
- `deferred-items.md` (new, this plan) carries forward the one unrelated stray-file finding for whoever owns it; it does not block Phase 12's remaining plans.

---
*Phase: 12-unified-design-token-pipeline*
*Completed: 2026-07-26*

## Self-Check: PASSED

- FOUND: theme-engine/.config/theme-engine/motion.json
- FOUND: theme-engine/.config/theme-engine/lib/motion.sh
- FOUND: .planning/phases/12-unified-design-token-pipeline/deferred-items.md
- FOUND commit: b455fca (Task 1)
- FOUND commit: 9283e9f (Task 2)
- FOUND commit: 42055dc (Task 3)
