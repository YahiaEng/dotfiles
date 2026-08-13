---
phase: 19-notification-server-centre
plan: 03
subsystem: theme-engine
tags: [wallpaper, symlink, gitignore, stow, theme-stress-test, hypr-equivalence-check, contract.json]

requires:
  - phase: 19-notification-server-centre (plan 19-02)
    provides: GATE-01 render-count baseline and LEDGER-04 dispositions this plan runs alongside (wave 1, no direct dependency)
provides:
  - Active-wallpaper pointer relocated from the stow-managed wallpapers directory to engine-owned state (~/.local/state/theme/current.jpg), with every consumer repointed and the .gitignore exemption deleted (D-19-45)
  - theme-stress-test's REPRESENTATIVE_FILES set corrected to the 4 entries D-19-46 names, with the retiring notification daemon's stylesheet dropped before its render template is deleted in plan 19-08
  - A diagnosed, documented, pre-existing blocker (hypr-equivalence-check baseline staleness) that keeps theme-stress-test from a full clean run, isolated from and independent of this plan's own changes
affects: [19-08 (depends on this plan's REPRESENTATIVE_FILES change landing before the swaync template is deleted), 20, 21, 22 (all run gates against theme-stress-test / theme-doctor)]

actuals:
  tokens: 6791
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Engine-owned state constant declared independently (same literal, not sourced) in every consumer that cannot guarantee sourcing order with lib/wallpaper.sh — matches this repo's pre-existing WALLPAPER_DIR/LAST_WALLPAPER_DIR convention in wallpaper-picker.sh"
    - "contract.json's engine_owned_files array is the single source of truth for both commit.sh's rsync --delete exclusions and theme-doctor's D-29 state-manifest gate — a new engine-owned state file needs exactly one array entry, never two hand-synced lists"

key-files:
  created:
    - .planning/phases/19-notification-server-centre/deferred-items.md
  modified:
    - theme-engine/.config/theme-engine/lib/wallpaper.sh
    - theme-engine/.config/theme-engine/theme-stress-test
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/lib/generate.sh
    - theme-engine/.config/theme-engine/theme-doctor
    - theme-engine/.config/theme-engine/theme-apply
    - hypr/.config/hypr/hyprlock.conf
    - hypr/.config/hypr/scripts/theme-init.sh
    - hypr/.config/hypr/scripts/wallpaper-picker.sh
    - hypr/.config/hypr/scripts/hypr-equivalence-check
    - stow.sh
    - .gitignore
    - thunar/.config/Thunar/uca.xml
    - .planning/WINDOWS.md

key-decisions:
  - "current.jpg's new home is ~/.local/state/theme/current.jpg — the same engine-owned state directory already holding wallpaper-frames/, last-wallpaper/ and current-theme, reusing D-07's precedent rather than inventing a new location"
  - "Added current.jpg to contract.json's engine_owned_files (not in the plan's files_modified list) — without it, commit.sh's rsync --delete strips the new pointer on every theme-apply, and it is NEVER recreated when the target theme is materialyou/materialyou-light (autoset no-ops for both names) — verified live: a materialyou-to-materialyou re-apply is the exact scenario that would have silently broken the lock screen and Material You palette source"
  - "Did NOT weaken, skip, or route around hypr-equivalence-check to force theme-stress-test green — fixed its stale baseline PATH (a real, narrow bug) but left its stale baseline CONTENT untouched, since resolving it safely requires the established surgical single-record technique (14-10/16-04 precedent) plus a judgment call this plan should not make unilaterally"
  - "LEDGER-07 requirement is NOT marked complete in REQUIREMENTS.md — theme-stress-test does not yet reach the full clean run the requirement's own wording demands, and marking it complete would misrepresent that"

requirements-completed: []

coverage:
  - id: D1
    description: "Active-wallpaper pointer moved to ~/.local/state/theme/current.jpg; every consumer (wallpaper.sh's 3 symlink sites, hyprlock.conf, theme-init.sh, wallpaper-picker.sh + its 3 generated sub-scripts, generate.sh, theme-doctor, stow.sh's fresh-install seed, Thunar's Set-as-Wallpaper action) repointed; .gitignore exemption deleted; contract.json's engine_owned_files extended so the pointer survives commit.sh's rsync --delete"
    requirement: LEDGER-07
    verification:
      - kind: manual_procedural
        ref: "5 consecutive `theme-engine/theme-apply` runs (dracula, materialyou, gruvbox, materialyou again, catppuccin) — readlink -f resolved to a real file every time, git status --porcelain empty after every run including mid-sequence, and the pointer specifically survived the materialyou-to-materialyou re-apply's rsync --delete"
        status: pass
      - kind: other
        ref: "grep -rn 'current\\.jpg' repo-wide (excluding the 5 files that legitimately still reference the literal) returns zero hits; grep -c 'ln -sfr' wallpaper.sh returns 3, none referencing WALLPAPER_DIR; grep -c 'name \"current.jpg\"' returns 0 in both wallpaper.sh and wallpaper-picker.sh; grep -c the old .gitignore block returns 0; bash -n clean on all 6 touched shell scripts"
        status: pass
    human_judgment: false
  - id: D2
    description: "theme-stress-test's REPRESENTATIVE_FILES reduced to the 4 entries D-19-46 names (hyprland-tokens.lua, wleave.css, gtk-4.0-colors.css, kitty.conf); both commentary blocks updated with no residual mention of the retired daemon's name anywhere in the file, comments included; lands before plan 19-08 deletes the render template"
    requirement: LEDGER-07
    verification:
      - kind: other
        ref: "grep -ci 'swaync' theme-stress-test returns 0; grep -q for the exact 4-entry array literal succeeds; bash -n exits 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "theme-stress-test reaches a full 10-switch run to exit 0 with zero failures, tree clean throughout — the plan's own stated success bar for LEDGER-07"
    requirement: LEDGER-07
    verification: []
    human_judgment: true
    rationale: "NOT achieved. theme-doctor (strict exit 0 required by the stress test's own D-66 gate) reports 3 failures, all from hypr-equivalence-check — a pre-existing, out-of-scope regression gate for the unrelated Phase 13.1 Hyprland Lua migration. Root cause fully diagnosed (see Deviations below and deferred-items.md) but deliberately not fixed here: the safe remediation needs a judgment call (which live bind/animation differences are intentional since Phase 15) this plan should not make unilaterally, plus a newly-discovered structural incompatibility (col.active_border/col.inactive_border can only ever match the one theme the baseline was captured under) that needs its own scoped fix. A human must decide whether to prioritize that separate fix before LEDGER-07 can be marked closed."
---

# Phase 19 Plan 03: Wallpaper Pointer Relocation & Stress-Test Set Correction Summary

**Moved the active-wallpaper symlink out of the stow tree into `~/.local/state/theme/current.jpg` and corrected theme-stress-test's representative-file set — but theme-stress-test still cannot reach a clean run, because of an isolated, pre-existing, out-of-scope `hypr-equivalence-check` baseline problem this plan diagnosed but did not fix.**

## Performance

- **Duration:** ~40 min
- **Started:** 2026-08-13T09:32:00Z
- **Completed:** 2026-08-13T10:05:00Z
- **Tasks:** 3 (2 fully complete, 1 partially complete with a documented, out-of-scope blocker)
- **Files modified:** 14 (13 source + WINDOWS.md), 1 file created (deferred-items.md)

## Accomplishments

- The active-wallpaper pointer is genuinely engine-owned state now: `lib/wallpaper.sh`'s one new `CURRENT_WALLPAPER_LINK` variable (`~/.local/state/theme/current.jpg`) drives all three symlink-repoint call sites, and every other consumer in the repo — found by a repo-wide grep, not just the plan's own read_first list — was repointed to match: `hyprlock.conf`, `theme-init.sh`, `wallpaper-picker.sh` (its main script plus its three generated ENUM/PREVIEW/LIVE sub-scripts), `generate.sh`'s Material You wallpaper source, `theme-doctor`'s live-frame gate, `stow.sh`'s fresh-install seed, and Thunar's "Set as Wallpaper" custom action.
- The `.gitignore` exemption block for `wallpapers/Pictures/Wallpapers/current.jpg` is deleted outright (not commented out) — the structural fix D-19-45 requires instead of keeping the exemption.
- Found and fixed a real bug the move would otherwise have introduced: `current.jpg` was not in `contract.json`'s `engine_owned_files`, so `commit.sh`'s `rsync --delete` would have stripped the pointer on every `theme-apply` and never recreated it when the target theme is `materialyou`/`materialyou-light` (autoset no-ops for both). Verified live that this exact scenario (a materialyou-to-materialyou re-apply) now leaves the pointer intact.
- `theme-stress-test`'s `REPRESENTATIVE_FILES` array now holds exactly the 4 entries D-19-46 names, with both commentary blocks rewritten to describe the current set (no residual mention of the retired daemon anywhere in the file, comments included) — lands ahead of plan 19-08's template deletion as required.
- Diagnosed, root-caused, and partially fixed a real supporting bug found while running the stress test live: a leaked `media-player.py` process pair (orphaned from waybar's Phase-18 retirement) was keeping a stale systemd scope alive, tripping theme-doctor's retirement-check — killed, scope garbage-collected.
- Diagnosed and fixed `hypr-equivalence-check`'s stale baseline PATH (broken by the v3.0 milestone archive moving the whole 13.1 phase directory) — the check now finds its committed baseline instead of reporting "absent."
- Diagnosed but deliberately did NOT fix `hypr-equivalence-check`'s baseline CONTENT staleness (binds.json/animations.json/options.jsonl divergence, plus a newly-discovered structural incompatibility between its theme-coupled border-color comparison and any multi-theme stress run) — documented exhaustively in `deferred-items.md` and WINDOWS.md entry #71, since it predates this plan (tracked since Phase 15) and needs a domain judgment call this plan should not make unilaterally.

## Task Commits

Each task was committed atomically:

1. **Task 1: Move the active-wallpaper pointer out of the stow tree into engine-owned state** - `d0c3f0a` (feat)
2. **Task 2: Drop the retiring daemon's stylesheet from the stress test's representative set** - `e474a6a` (fix)
3. **Task 3 (partial — diagnostic fix found live during the run):** repoint hypr-equivalence-check's stale baseline path - `37249ea` (fix)

_Task 3's own literal deliverable (a full clean `theme-stress-test` run) was not achieved — see Deviations and the coverage block's D3 entry. No source file changes were made to force a pass; the two commits above are genuine, narrowly-scoped bug fixes found while diagnosing the failure._

**Plan metadata:** (this commit)

## Files Created/Modified

- `theme-engine/.config/theme-engine/lib/wallpaper.sh` - New `CURRENT_WALLPAPER_LINK` var; all 3 symlink-repoint sites retargeted; dead `! -name "current.jpg"` exclusion removed
- `theme-engine/.config/theme-engine/contract.json` - `current.jpg` added to `engine_owned_files` (Rule 2 — missing critical functionality, not in the plan's files_modified list)
- `theme-engine/.config/theme-engine/lib/generate.sh` - `WALLPAPER_LINK` repointed (independent literal — theme-parity sources this file without wallpaper.sh)
- `theme-engine/.config/theme-engine/theme-doctor` - Live-frame gate's `current.jpg` resolution repointed; check message reworded
- `theme-engine/.config/theme-engine/theme-apply` - Comment repointed (no longer names a stow-tree path)
- `theme-engine/.config/theme-engine/theme-stress-test` - `REPRESENTATIVE_FILES` reduced to 4 entries per D-19-46; both commentary blocks rewritten
- `hypr/.config/hypr/hyprlock.conf` - `background.path` repointed
- `hypr/.config/hypr/scripts/theme-init.sh` - `WALLPAPER` var repointed
- `hypr/.config/hypr/scripts/wallpaper-picker.sh` - `CURRENT_LINK` repointed; 3 dead `! -name "current.jpg"` exclusions removed; ENUM/PREVIEW/LIVE generated sub-scripts repointed via the sourced library var (with literal fallback)
- `hypr/.config/hypr/scripts/hypr-equivalence-check` - [Rule 3 deviation] baseline-path resolution repaired to follow the v3.0 milestone archive
- `stow.sh` - Fresh-install wallpaper-pointer seed repointed and its guard condition updated
- `.gitignore` - Wallpaper runtime-pointer exemption block deleted entirely
- `thunar/.config/Thunar/uca.xml` - "Set as Wallpaper" custom action's `ln -sf` target repointed
- `.planning/phases/19-notification-server-centre/deferred-items.md` - New: full diagnosis of the hypr-equivalence-check blocker
- `.planning/WINDOWS.md` - New ledger entry #71 (unrun-verify) for the same

## Decisions Made

- `CURRENT_WALLPAPER_LINK="$HOME/.local/state/theme/current.jpg"` chosen as the new location — same directory D-07 already established for engine-owned state, reused rather than inventing a new one.
- Every consumer outside `lib/wallpaper.sh` independently declares the same literal rather than sourcing it, matching this repo's pre-existing convention (`wallpaper-picker.sh`'s own `WALLPAPER_DIR`/`LAST_WALLPAPER_DIR`) and specifically required for `generate.sh`, which `theme-parity` sources without `wallpaper.sh` in the same process.
- `current.jpg` added to `contract.json`'s `engine_owned_files` — a Rule 2 deviation (missing critical functionality) discovered by reading `commit.sh`'s rsync-exclusion mechanism and confirmed by live reproduction, not by assumption.
- Chose NOT to re-baseline or otherwise silence `hypr-equivalence-check` — matches this plan's own instruction ("do not adjust the script's assertions to make it pass") and the established project precedent that baseline drift gets a surgical, judgment-reviewed fix, never a wholesale re-snapshot.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] `current.jpg` missing from `contract.json`'s `engine_owned_files`**
- **Found during:** Task 1, while tracing `commit.sh`'s `rsync -a --delete` exclusion mechanism to confirm the new state-dir location was actually safe
- **Issue:** Without an exclusion entry, `commit.sh`'s `rsync --delete` (which runs on every `theme-apply`, before `autoset`) would strip the newly-relocated pointer on every switch. Worse: `theme_engine_wallpaper_autoset` no-ops for both `materialyou`/`materialyou-light` names, so nothing would recreate it after a Material You apply — silently breaking the lock-screen background and the Material You palette source itself
- **Fix:** Added `"current.jpg"` to `contract.json`'s `engine_owned_files` array — the same data-driven mechanism that already feeds both `commit.sh`'s exclude flags and `theme-doctor`'s D-29 state-manifest gate
- **Files modified:** `theme-engine/.config/theme-engine/contract.json`
- **Verification:** Live-reproduced the exact failure scenario (materialyou -> materialyou re-apply) after the fix — pointer survived; `theme-doctor`'s state-manifest gate reports all 35 state-dir entries accounted for
- **Committed in:** `d0c3f0a` (Task 1 commit)

**2. [Rule 3 - Blocking] Leaked `media-player.py` processes tripping theme-doctor's retirement-check**
- **Found during:** Task 3's first live full stress-test run
- **Issue:** Two orphaned `media-player.py` processes (dead code with zero references anywhere in the current codebase — a leftover from the eww-era media popup, retired Phase 10) were still running under a systemd scope originally created by `waybar-launch.sh`, which was deleted in Phase 18's retirement (RETIRE-02). The live scope tripped `theme-doctor`'s `retirement-check: waybar/systemd-units`.
- **Fix:** `kill -9` on both PIDs; systemd garbage-collected the now-empty transient scope automatically
- **Files modified:** none (runtime cleanup only)
- **Verification:** `systemctl --user list-units --all | grep waybar` and `list-unit-files | grep waybar` both return nothing after the kill; `theme-doctor`'s retirement-check for `waybar/systemd-units` now passes
- **Committed in:** n/a (no file change)

**3. [Rule 3 - Blocking] `hypr-equivalence-check`'s baseline path stale since the v3.0 milestone archive**
- **Found during:** Task 3's first live full stress-test run
- **Issue:** The v3.0 milestone archive (commit `cf26332`) moved the whole `13.1-hyprland-lua-config-migration` phase directory from `.planning/phases/` to `.planning/milestones/v3.0-phases/`, but `hypr-equivalence-check`'s hardcoded `DEFAULT_BASELINE_DIR` never tracked that move — every check-mode run since the archive hit D-10's "absent baseline is a FAIL, never a SKIP" path for a reason unrelated to whatever the live config actually diverges on
- **Fix:** The script now prefers the live `phases/` location (for a future phase capturing a baseline the same way while still active) and falls back to the archived `milestones/` location — robust to the same archive workflow moving it again
- **Files modified:** `hypr/.config/hypr/scripts/hypr-equivalence-check`
- **Verification:** Re-ran the check directly — it now finds and reads the baseline (reporting real content differences instead of "absent")
- **Committed in:** `37249ea`

---

**Total deviations:** 3 auto-fixed (1 missing critical, 2 blocking)
**Impact on plan:** All three were necessary for correctness (deviation 1 is load-bearing for D-19-45 itself) or to make an honest diagnosis of Task 3's failure possible (deviations 2-3). None weakened any assertion or routed around a real check. No scope creep beyond what was required to either complete D-19-45/D-19-46 correctly or to accurately diagnose why the stress test still cannot pass.

## Issues Encountered

**`theme-stress-test` cannot reach a full clean run — root cause fully isolated, deliberately not fixed.** After the deviations above, `theme-doctor` reports exactly 3 failures (down from an initial mix that also included the two now-fixed issues), all three from `hypr-equivalence-check`'s `binds.json`/`animations.json`/`options.jsonl` sub-checks. This is:

- **Pre-existing and unrelated to D-19-45/D-19-46** — confirmed by running `theme-doctor` in isolation and by direct `theme-apply` cycling, both of which show the wallpaper-pointer and representative-file-set fixes work correctly on their own (git tree stays clean throughout, the pointer survives a commit.sh rsync cycle).
- **Already tracked as long-standing debt** — first documented in `15-audio-connectivity-panels/deferred-items.md` (Phase 15, Super+A keybind drift), remediated twice via a surgical single-record baseline insertion (14-10, 16-04), and now stale again after 3 further phases (16, 17, 18) of legitimate Hyprland changes.
- **Compounded by a newly-discovered structural issue**: the `options.jsonl` comparison of `col.active_border`/`col.inactive_border` is theme-coupled — the baseline was captured under one theme's border-gradient colors, so this specific sub-check can only ever pass when the live theme matches the baseline's, meaning it cannot pass across `theme-stress-test`'s own 10-switch multi-theme rotation even after a fully fresh re-baseline, unless the comparator gains a theme-aware exemption.

Full diagnosis, evidence, and a suggested fix are in `.planning/phases/19-notification-server-centre/deferred-items.md` and WINDOWS.md ledger entry #71 (kind `unrun-verify`, status `open`).

**LEDGER-07 requirement is left unmarked (`- [ ]`) in REQUIREMENTS.md** — it is not truthfully closed while `theme-stress-test` cannot reach the full clean run its own wording demands. This is a deliberate choice, not an oversight: D-19-45 and D-19-46 (this plan's actual scope) are both correctly implemented and verified, but the requirement's stated bar is broader than this plan's scope turned out to require to satisfy in full.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 19-04 through 19-07 have no dependency on this plan and are unaffected.
- Plan 19-08 (`depends_on: [19-01, 19-02, 19-03, 19-04, 19-05, 19-06]`) can proceed on this plan's actual deliverable: `REPRESENTATIVE_FILES` no longer references the retiring notification daemon's stylesheet, so 19-08's template deletion will not retroactively break the stress test's representative set.
- **Blocker for full LEDGER-07 closure, not for 19-08:** a future plan (or a `/gsd-debug` session) needs to either (a) perform the surgical `hypr-equivalence-check` baseline update following the 14-10/16-04 precedent, reviewing each live bind/animation difference against its originating phase before blessing it, and (b) decide how to handle the theme-coupled border-color comparison structurally. Until then, `theme-stress-test` will keep aborting at switch #1 on every full run, for a reason unrelated to wallpaper pointers or the notification-server migration this phase is otherwise about.

---
*Phase: 19-notification-server-centre*
*Completed: 2026-08-13*

## Self-Check: PASSED

- Created files verified on disk: `deferred-items.md`, `19-03-SUMMARY.md`
- All 3 task commits verified in `git log`: `d0c3f0a`, `e474a6a`, `37249ea`
- Spot-checked content: `CURRENT_WALLPAPER_LINK` present in `wallpaper.sh`, `"current.jpg"` present in `contract.json`'s `engine_owned_files`, the 4-entry `REPRESENTATIVE_FILES` literal present in `theme-stress-test`, `_LIVE_BASELINE_DIR` fallback present in `hypr-equivalence-check`
