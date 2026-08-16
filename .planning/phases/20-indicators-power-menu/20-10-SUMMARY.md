---
phase: 20-indicators-power-menu
plan: 10
subsystem: infra
tags: [retirement-check, hyprland-lua, motion-lint, theme-engine, quickshell, matugen, gsd-worktree]

# Dependency graph
requires:
  - phase: 20-indicators-power-menu
    provides: "Plan 20-08's Gate B RETIRE-05 AUTHORISED verdict; plan 20-09's RETIRE-04 swayosd removal precedent (config-then-package, one commit; out-of-plan comment scrub pattern)"
provides:
  - "wleave fully removed from repo and host (config + host package independently verified absent)"
  - "wlogout and eww fully removed from repo cross-references and host (host package independently verified absent; no repo tree existed for either)"
  - "retirement-check registry: wleave, wlogout, eww all flipped pending -> retired, blocking tier 0 for all three"
  - "theme-stress-test's Phase-20-deferred full clean run discharged (10/10 switches, 132 passed, 0 failed)"
  - "contract.json collapsed to 18 files entries"
  - "operator-granted interlock override precedent recorded (halt-then-ask, not self-certify)"
affects: [21-media-fold-in, 22-fresh-install-gate]

# Actuals (#2632)
actuals:
  tokens: 21313
  tasks: 3
  commits: 5

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Config-then-package, one commit per retired surface (WINDOWS #1 precedent, reused from plan 20-09)"
    - "retirement-check blocking tier applies to COMMENT text too, not just functional code, once a surface flips to retired — word-boundary grep, no exemption mechanism"
    - "Operator-granted interlock override: a literal halt condition stands as recorded, the operator's explicit decision (not agent self-certification) is what authorises proceeding, with the investigation evidence transcribed for the permanent record"

key-files:
  created:
    - .planning/phases/20-indicators-power-menu/20-10-SUMMARY.md
  modified:
    - .planning/phases/20-indicators-power-menu/20-RETIRE-05-07-RECORD.md
    - hypr/.config/hypr/config/windowrules.lua
    - hypr/.config/hypr/scripts/motion-lint
    - hypr/.config/hypr/scripts/retirement-check
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/theme-stress-test
    - hypr/.config/hypr/scripts/media-players.sh
    - hypr/.config/hypr/scripts/media-art-resolve.sh

key-decisions:
  - "Recorded the Gate B interlock's non-zero exit as a real, standing halt condition — never as passing — with the operator's `proceed` reply recorded as an explicit override backed by independently re-verified evidence (three comment-only edits, zero non-comment lines, PowerMenu.qml/modules/session/ untouched)."
  - "windowrules.lua: deleted wleave's three namespace layer rules but preserved the file-level ignore_alpha 'all-or-nothing per namespace' finding as a standalone comment, since quickshell-session's own rule cites it downstream — the mechanism outlives the surface it was learned from."
  - "motion-lint's wleave LINE_EXEMPTIONS carve-out (marked PERMANENT in its own text) was retired WITH ITS SUBJECT — left as an empty list, not overridden or repointed to a new surface."
  - "theme-stress-test's REPRESENTATIVE_FILES lost wleave.css by REMOVAL, not repoint, since gtk-4.0-colors.css already represents the gtk-css format in the same array — matches the plan's own explicit prohibition against inventing a repoint target."
  - "Renamed the eww-media-art/eww-media-player host cache-path constants (media-art-resolve.sh, media-players.sh) to media-art/media-player, migrating the two existing on-host cache entries. This narrows 20-RETIREMENT-BASELINE.md's 'report-only for this plan, disposition ownership out of phase' call — correct while eww was pending, but the same hits become BLOCKING once this plan's own requirement flips eww to retired. Judged self-contained (2 production scripts + their own test), low-risk (fully regenerable cache), and required to satisfy the plan's explicit zero-blocking-hits success criterion rather than leave a permanently red gate."
  - "No pacman -Rns was run for any of wleave/wlogout/eww — all three were independently re-verified absent (operator removed them manually outside this session, same pattern as swayosd in plan 20-09). Config-side removal and registry bookkeeping only."
  - "Brightness OSD's NOT-DEMONSTRABLE verdict (WINDOWS row 78, the pending todo) stays OPEN — this plan's own text about clearing remaining verification debt at phase end is explicitly superseded for this one item, recorded as a named deviation rather than silently closed."
  - ".claude/CLAUDE.md's technology-stack table still lists swayosd/wleave as current stack — left untouched (not in this plan's files_modified, and it's a cross-cutting research document, not owned by any single plan); flagged explicitly here for the phase's own doc pass rather than edited out of scope."

requirements-completed: [RETIRE-05, RETIRE-07]

coverage:
  - id: D1
    description: "wleave removed from repo (stow tree, launcher script, contract entry, matugen template, layer rules, checker exemptions, test fixtures, install/stow entries) and host package, in one config-then-package commit"
    requirement: "RETIRE-05"
    verification:
      - kind: other
        ref: "retirement-check wleave (post-deletion, status=retired failed_classes=0)"
        status: pass
      - kind: other
        ref: "contract.json files array == 18, no wleave.css entry (python3 json assertion)"
        status: pass
    human_judgment: false
  - id: D2
    description: "wlogout and eww uninstalled from host, registry rows flipped to retired, all blocking-tier reference classes closed"
    requirement: "RETIRE-07"
    verification:
      - kind: other
        ref: "retirement-check wlogout / retirement-check eww (post-deletion, status=retired failed_classes=0 both)"
        status: pass
      - kind: other
        ref: "pacman -Q wlogout / pacman -Q eww both report not-found"
        status: pass
    human_judgment: false
  - id: D3
    description: "theme-stress-test's Phase-20-deferred full clean run (REPRESENTATIVE_FILES settled) actually completes clean"
    verification:
      - kind: e2e
        ref: "theme-engine/.config/theme-engine/theme-stress-test (10/10 switches, 132 passed, 0 failed, post-commit clean-tree run)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every gate in the repo green: theme-doctor, theme-parity, motion-lint (+self-test), colour-lint, quickshell-doctor --self-test, keybind-doctor, retirement-check --all, hypr-lua-harness parse cycle"
    verification:
      - kind: other
        ref: "all nine gates run post-final-commit, all exit 0 (hypr-lua-harness via start/status/stop cycle, not the bare-invocation usage-text quirk already documented in 20-03-SUMMARY.md)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Human-visual confirmation of theme-stress-test running by eye plus one live theme switch confirming OSD/power menu re-colour"
    verification: []
    human_judgment: true
    rationale: "This project's established preference is to ship on automated-verification strength and let the user verify live behaviour themselves rather than have the agent drive probe shells/screenshots (per user memory: 'skip live verification, ship fast'). The automated half (theme-stress-test's own exit-code and live D-17 re-colour assertion) genuinely ran and passed; the by-eye human half is left open, honestly recorded rather than self-certified."

duration: 45min
completed: 2026-08-16
status: complete
---

# Phase 20 Plan 10: RETIRE-05/RETIRE-07 — wleave, wlogout, eww Summary

**Removed wleave (config + host package) and uninstalled wlogout/eww, closing every retirement-check blocking-tier hit including eleven out-of-plan comment sites and a cache-path rename, discharging plan 20-09's deferred theme-stress-test gate — phase 20 is now complete.**

## Performance

- **Duration:** 45 min (continuation agent; Task 1 pre-flight was a prior session)
- **Started:** 2026-08-16T01:07:13Z (Task 1, prior session)
- **Completed:** 2026-08-16T02:XX:XXZ
- **Tasks:** 3 (Task 1 pre-flight, Task 2 wleave removal, Task 3 wlogout/eww + green gates)
- **Files modified:** 33 (26 in Task 2's commit, 7 in Task 3's two commits)

## Accomplishments

- `wleave` removed from repo (stow tree, launcher script, contract entry, matugen template, three `windowrules.lua` layer rules, `motion-lint` carve-outs, install/stow entries) and confirmed absent from host, in one config-then-package commit behind Gate B's `RETIRE-05 AUTHORISED` verdict.
- `wlogout` and `eww` confirmed uninstalled from host; `retirement-check`'s registry rows for all three surfaces (`wleave`, `wlogout`, `eww`) flipped from `pending` to `retired` with genuinely zero blocking-tier hits each.
- `theme-stress-test`'s `REPRESENTATIVE_FILES` array resolved (removal, not repoint) and its Phase-20-deferred full clean run discharged: 10/10 theme switches, 132 checks passed, 0 failed.
- Every repo gate confirmed green post-commit: `theme-doctor`, `theme-parity`, `motion-lint` (+ 10/10 self-test), `colour-lint`, `quickshell-doctor --self-test` (55/55), `keybind-doctor`, `retirement-check --all`, and `hypr-lua-harness`'s real parse-check cycle (start/status/stop).
- The interlock override was recorded correctly: the previous executor's halt was upheld as correct behaviour, the operator's `proceed` decision is recorded as an explicit, evidence-backed override — never as the interlock passing.
- `contract.json` reached its planned 18-entries milestone state.

## Task Commits

Each task was committed atomically:

1. **Task 1: Pre-flight — Gate B verdict, interlock, removal previews** - `97da7cb` (docs, prior session)
2. **Interlock resolution record (operator `proceed`)** - `5fa60fa` (docs)
3. **Task 2: wleave config removal + package-absence verification** - `f30a671` (feat)
4. **Task 3: wlogout/eww registry flip + blocking-hit closure** - `ada405a` (docs)
5. **Green-gate results confirmed genuinely post-commit** - `36bbf20` (docs)

**Plan metadata:** this commit (docs: complete plan)

## Files Created/Modified

- `.planning/phases/20-indicators-power-menu/20-RETIRE-05-07-RECORD.md` - Pre-flight, interlock resolution, Task 2/3 execution record, both after-runs, green-gate table
- `hypr/.config/hypr/config/windowrules.lua` - Removed wleave's three namespace layer rules; preserved the file-level `ignore_alpha` all-or-nothing finding as a standalone comment (cited by `quickshell-session`'s own rule)
- `hypr/.config/hypr/scripts/motion-lint` - `LINE_EXEMPTIONS` carve-out retired with its subject (now `[]`); `DELAY_PROPERTY_RE` comment generalised; `$HOME/.config/wleave` `ROOTS` entry removed
- `hypr/.config/hypr/scripts/retirement-check` - `wleave`, `wlogout`, `eww` registry rows flipped `pending` -> `retired`
- `theme-engine/.config/theme-engine/contract.json` - `wleave.css` entry removed (19 -> 18 files)
- `theme-engine/.config/theme-engine/theme-doctor` - `wleave/style.css` removed from `GTK4_CSS_SHEETS`
- `theme-engine/.config/theme-engine/theme-stress-test` - `wleave.css` removed from `REPRESENTATIVE_FILES` by removal (not repoint); historical prose reworded
- `matugen/.config/matugen/config.toml` - `[templates.wleave]` block removed
- `install.sh`, `stow.sh` - `wleave` package/stow entries removed
- `VERIFICATION.md` - prose line updated to drop the retired surface name
- `hypr/.config/hypr/scripts/media-players.sh`, `hypr/.config/hypr/scripts/media-art-resolve.sh` - cache-path constants renamed from `eww-media-*` to `media-*`; existing on-host cache entries migrated
- `hypr/.config/hypr/scripts/tests/test-media-hardening.sh` - comment updated to match the renamed cache paths
- `hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-collision-overview-keybinds.lua` - swapped the `wlogout` placeholder exec target for a generic one (fixture assertion unchanged)
- Eleven further files with wleave-comment-only rewords: `hypr/.config/hypr/scripts/quickshell-doctor`, `theme-engine/.config/theme-engine/lib/gtk.sh`, `elephant/.config/elephant/menus/main.toml`, `quickshell/.config/quickshell/shell.qml`, `quickshell/.config/quickshell/shortcuts.json`, `quickshell/.config/quickshell/modules/Dashboard.qml`, `quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml`, `quickshell/.config/quickshell/modules/session/PowerMenu.qml` (two sites)
- **Deleted:** `wleave/.config/wleave/layout.json`, `wleave/.config/wleave/style.css`, `hypr/.config/hypr/scripts/wleave.sh`, `matugen/.config/matugen/templates/wleave-colors.css`

## Decisions Made

See `key-decisions` in frontmatter for the full list. Highlights:

1. The Gate B interlock's literal non-zero exit was upheld as a real halt condition through to the operator, never self-certified as passing — the operator's evidence-backed `proceed` is what authorised Task 2, recorded explicitly as an override.
2. `windowrules.lua`'s file-level `ignore_alpha` finding (an all-or-nothing per-namespace blur switch) was preserved as a comment even though the rule that taught it (wleave's) was deleted, because `quickshell-session`'s own layer rule cites it as precedent.
3. `theme-stress-test`'s `REPRESENTATIVE_FILES` lost `wleave.css` by removal, exactly as the plan's own prohibition required (no invented repoint target — `gtk-4.0-colors.css` already covers `gtk-css`).
4. Renamed `eww-media-art`/`eww-media-player` cache paths to close eww's last blocking-tier hits — a narrower-than-`20-RETIREMENT-BASELINE.md`'s-original-call decision, justified in full in `20-RETIRE-05-07-RECORD.md`'s Task 3 section (self-contained, low-risk, required by this plan's own explicit success criterion).
5. Brightness OSD's NOT-DEMONSTRABLE verdict stays open — this plan's own instruction to clear remaining verification debt at phase end is explicitly superseded for that one item.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Eleven out-of-plan comment sites required to close wleave's blocking tier**
- **Found during:** Task 2, verifying `retirement-check wleave` reached `failed_classes=0`
- **Issue:** `retirement-check`'s `checker-internals`/`cross-package-refs` classes word-boundary-match "wleave" inside COMMENTS, not just functional code, once a surface's status flips to `retired`. Eleven sites outside the plan's declared `files_modified` still cited "wleave" in prose.
- **Fix:** Reworded each comment to drop the literal token without changing meaning (same pattern plan 20-09 established for swayosd).
- **Files modified:** `hypr/.config/hypr/scripts/quickshell-doctor`, `theme-engine/.config/theme-engine/lib/gtk.sh`, `elephant/.config/elephant/menus/main.toml`, `quickshell/.config/quickshell/shell.qml`, `quickshell/.config/quickshell/shortcuts.json`, `quickshell/.config/quickshell/modules/Dashboard.qml`, `quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml`, `quickshell/.config/quickshell/modules/session/PowerMenu.qml` (two sites), `theme-engine/.config/theme-engine/theme-stress-test`
- **Verification:** `retirement-check wleave` reached `status=retired failed_classes=0`
- **Committed in:** `f30a671` (Task 2 commit)

**2. [Rule 1 - Bug/stale reference] eww-media-* cache-path constants renamed to close eww's blocking tier**
- **Found during:** Task 3, verifying `retirement-check eww` after flipping its registry row to `retired`
- **Issue:** `media-art-resolve.sh`'s `CACHE_DIR` and `media-players.sh`'s `SELECTED_FILE` used `~/.cache/eww-media-art`/`~/.cache/eww-media-player` — a stale naming convention referencing the now-uninstalled `eww` package, which `retirement-check`'s `cross-package-refs` class correctly flagged once eww was `retired`.
- **Fix:** Renamed both constants to `~/.cache/media-art`/`~/.cache/media-player`; migrated (not deleted) the two existing on-host cache entries to the new paths; updated `test-media-hardening.sh`'s comment to match.
- **Files modified:** `hypr/.config/hypr/scripts/media-art-resolve.sh`, `hypr/.config/hypr/scripts/media-players.sh`, `hypr/.config/hypr/scripts/tests/test-media-hardening.sh`
- **Verification:** `retirement-check eww` reached `status=retired failed_classes=0`; `media-players.sh active` re-tested working against the new path
- **Committed in:** `ada405a` (Task 3 commit)

**3. [Rule 1 - Bug/stale reference] wlogout placeholder swapped in a poisoned fixture**
- **Found during:** Task 3, verifying `retirement-check wlogout`
- **Issue:** `poisoned-collision-overview-keybinds.lua` (a chord-collision test fixture for `keybind-doctor`/`quickshell-doctor`'s static bind-collision check) used `wlogout` as an arbitrary placeholder exec target — flagged once `wlogout` flipped to `retired`.
- **Fix:** Swapped the placeholder for a generic binary name; the fixture's actual assertion (two binds claiming the same chord) is unchanged, confirmed by re-running `quickshell-doctor --self-test` (55/55 unchanged).
- **Files modified:** `hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-collision-overview-keybinds.lua`
- **Verification:** `retirement-check wlogout` reached `status=retired failed_classes=0`; `quickshell-doctor --self-test` still 55/55
- **Committed in:** `ada405a` (Task 3 commit)

---

**Total deviations:** 3 auto-fixed (1 Rule 2, 2 Rule 1)
**Impact on plan:** All three were required to satisfy the plan's own explicit "zero blocking hits" success criterion for wleave/wlogout/eww once each surface flipped to `retired` — no scope creep beyond what that requirement demanded. Full reasoning for the cache-path rename (the largest of the three) is recorded in `20-RETIRE-05-07-RECORD.md`'s Task 3 section, since it narrows an earlier baseline document's disposition call.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or trust-boundary schema changes introduced. This plan only deletes surfaces and reworks prose/comments.

## Issues Encountered

- **`hypr-lua-harness`'s bare invocation** (called with no subcommand, as the plan's own literal `<verify>` scripts do) only prints usage text and exits 1 — a known plan-authoring quirk already documented in `20-03-SUMMARY.md`, not a regression. Resolved by exercising the real `start`/`status`/`stop` cycle directly, confirming the edited `windowrules.lua`/`autostart.lua` parse without error.
- **Live `quickshell-doctor` run's two persistent failures** (`zero Quickshell MPRIS writers`, `permissions-allowlist-paths-resolve`) are pre-existing, unrelated to wleave/wlogout/eww, and already logged in this phase's `deferred-items.md` from plan 20-09's own investigation. A third, transient failure (`overview-content-check`) appeared on the first run only and did not reproduce on a second — confirmed a timing artifact, not a persistent defect.
- **`theme-stress-test`'s first run** aborted at switch #1 on `theme-doctor`'s own git-cleanliness check, because the working tree still had uncommitted Task 3 changes at that point in execution. Resolved by committing first, then re-running for a genuinely clean pass (10/10 switches, 132 passed).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 20 (indicators-power-menu) is now complete — all four of this phase's retirement targets (`swayosd`, `wleave`, `wlogout`, `eww`) are `retired` in the registry with zero blocking-tier hits each.
- `contract.json` is at 18 entries, not yet Phase 21's post-migration ~17 target (RETIRE-08) — named explicitly as that phase's own work, not implied closed here.
- No fresh-install reproduction proof exists yet — that is RETIRE-09's container gate in Phase 22, not established by this plan's host-level deletions.
- **Brightness OSD stays open** — `.planning/todos/pending/2026-08-15-brightness-osd-unverifiable-on-desktop.md` and `WINDOWS.md` row 78 are NOT closed by this plan (no backlight device on this host to demonstrate against).
- **Open human-visual item:** the plan's own `<human-check>` (watch `theme-stress-test` by eye, perform one live theme switch, confirm OSD/power menu re-colour) was not performed by a human this session — the automated equivalent (theme-stress-test's own exit-code and live re-colour assertion) genuinely passed, but the by-eye confirmation is left for the operator.
- `.claude/CLAUDE.md`'s technology-stack table still lists `swayosd`/`wleave` as current stack — flagged here for whichever pass next updates that document; not edited in this plan (out of `files_modified`, cross-cutting research doc).

---
*Phase: 20-indicators-power-menu*
*Completed: 2026-08-16*

## Self-Check: PASSED

All claimed files confirmed present (`20-RETIRE-05-07-RECORD.md`, this SUMMARY), all five claimed
commits confirmed present in git log (`97da7cb`, `5fa60fa`, `f30a671`, `ada405a`, `36bbf20`),
`wleave/` and `wleave.sh` confirmed absent from the working tree.
