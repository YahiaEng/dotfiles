---
phase: 18-qml-bar-retirement-machinery
plan: 20
subsystem: infra
tags: [waybar, quickshell, retirement-check, theme-engine, matugen, systemd, stow]

requires:
  - phase: 18-qml-bar-retirement-machinery
    provides: "18-06's retirement-check tool and its committed pre-deletion baseline; 18-19's GATE-02 human render-gate pass authorising deletion"
provides:
  - "waybar fully retired: package, config, contract entries, matugen template, checkers and fixtures all removed"
  - "retirement-check's waybar registry row flipped pending -> retired, arming the blocking tier permanently"
  - "contract.json at 22 files[] / 1 presence_only_files / 11 engine_owned_files, RETIRE-08's running total"
  - "Super+B repointed at bar-orientation.sh; theme-stress-test's materialyou sentinel repointed at palette.json"
  - "README.md, VERIFICATION.md and .claude/CLAUDE.md's bar-related sections updated to describe the Quickshell bar"
affects: [19-swaync-retirement, 20-swayosd-wleave-ags-retirement, 21-retire-08-contract-close]

actuals:
  tokens: 73000
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns:
    - "Comment-scrub rule: rewrite the reasoning, drop the retired name, keep the fact — applied across 28 files; facts that could not survive the rename (upstream citations, deleted-file line numbers, raw captured IPC strings) moved to this SUMMARY's scrubbed-history section instead of being destroyed."

key-files:
  created:
    - .planning/phases/18-qml-bar-retirement-machinery/18-RETIREMENT-AFTER-waybar.md
  modified:
    - waybar/ (deleted, 12 files)
    - hypr/.config/hypr/scripts/waybar-design-lint (deleted)
    - hypr/.config/hypr/scripts/waybar-equivalence-check (deleted)
    - hypr/.config/hypr/scripts/waybar-launch.sh (deleted)
    - hypr/.config/hypr/scripts/waybar-switch.sh (deleted)
    - matugen/.config/matugen/config.toml
    - matugen/.config/matugen/templates/waybar-colors.css (deleted)
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/theme-doctor
    - theme-engine/.config/theme-engine/theme-parity
    - theme-engine/.config/theme-engine/theme-stress-test
    - theme-engine/.config/theme-engine/lib/{motion,font,commit,reload,contract,generate,gtk}.sh
    - hypr/.config/hypr/config/{windowrules,autostart,keybinds}.lua
    - hypr/.config/hypr/scripts/retirement-check
    - install.sh
    - stow.sh
    - README.md
    - VERIFICATION.md
    - .claude/CLAUDE.md

key-decisions:
  - "Repointed Super+B at bar-orientation.sh instead of deleting the bind (D-18-30) — the discoverable orientation-picker path survives with the same keybind."
  - "Repointed theme-stress-test's materialyou sentinel at palette.json's .primary instead of any surviving gtk-css sheet, since swaync/swayosd/wleave are themselves retired later this milestone and would only relocate the breakage."
  - "own-tree's [SKIP] verdict in the after-run is the correct, permanent terminal state for a genuinely deleted surface, not a gap — recorded as such rather than forced toward the plan's literal '0 SKIP' target."
  - "The one surviving [FAIL] (a stale transient systemd scope coincidentally named after the deleted autostart line, now hosting unrelated media-player.py processes) was investigated and left untouched — killing/restarting unrelated live processes was not authorised by this plan."
  - "docs staleness scope was extended mid-plan by explicit user request after the checkpoint: README.md, VERIFICATION.md and .claude/CLAUDE.md's bar-related sections were updated to describe the Quickshell bar, committed separately from the retirement work itself."

patterns-established:
  - "Generic-launch idiom for future retirements (RETIRE-03..06, Phases 19-21): repoint sentinels/citations at surfaces guaranteed to survive the whole milestone (palette.json, not another doomed gtk-css sheet), and move any fact that can't survive a rename into the plan's SUMMARY rather than deleting it."

requirements-completed: [RETIRE-01, RETIRE-02]

duration: ~50min active work (checkpoint wait for sudo excluded)
completed: 2026-08-12
status: complete
---

# Phase 18 Plan 20: Waybar Retirement Summary

**Waybar's package, config tree, 9 contract.json entries, 4 checker blocks and every layer/autostart/keybind/matugen/systemd reference removed in one commit, with retirement-check's registry row flipped to `retired` — RETIRE-02 closed, RETIRE-01's before/after gate both run and recorded.**

## Performance

- **Duration:** ~50 min active work across two sessions (a mid-plan checkpoint paused for the user's interactive `sudo pacman -Rns waybar`)
- **Completed:** 2026-08-12
- **Tasks:** 3 (Task 1 read-only; Task 2 and Task 3 each produced commits)
- **Files modified:** ~72 across all commits (17 deleted, ~55 edited)

## Accomplishments

- Deleted the entire `waybar/` stow package (12 files), its four own-named scripts, its matugen template + config block, and uninstalled the `waybar` pacman package from the host (`pacman -Q waybar` now errors "package not found").
- `contract.json` reduced from 29/2/12 to 22/1/11 (`files[]`/`presence_only_files`/`engine_owned_files`) — the running total RETIRE-08 (Phase 21) will start its own count from.
- Removed waybar's four functional blocks from `theme-doctor`, six sass-compile rows from `motion.sh`, six sheet names from `theme-parity`, the font-render stanza from `font.sh`, the state-file carve-out from `commit.sh`, and the SIGUSR2 signal from `reload.sh` — five consumers of the same seven contract names, all edited together in one commit.
- Repointed rather than deleted: Super+B now launches `bar-orientation.sh` (D-18-30); `theme-stress-test`'s materialyou/materialyou-light sentinel now reads `palette.json`'s `.primary` (proven value-identical to the old source before the change: `#cba6f7` both).
- Scrubbed every comment-only reference to waybar across 28 files found by `retirement-check waybar`'s own `[FAIL]` output (matugen-templates, checker-internals, test-fixtures, cross-package-refs classes) — rewriting reasoning, dropping the retired name, keeping the fact.
- Flipped `retirement-check`'s registry row `waybar: pending -> retired` in the same commit as the deletion, arming the blocking tier permanently.
- Ran both halves of RETIRE-01's gate: the before-run (Task 1, against `pending`, 0 FAIL / 16 REPORT) and the after-run (Task 3, against `retired`, 13 PASS / 1 architectural SKIP / 1 unrelated transient-scope FAIL) — both committed as paired artifacts.
- (Authorised scope extension, post-checkpoint) Updated README.md, VERIFICATION.md and `.claude/CLAUDE.md`'s bar-related sections to describe the Quickshell bar instead of the retired waybar three-layout Walker switcher.

## Task Commits

Each task was committed atomically:

1. **Task 1: Pre-deletion baseline run and manifest reconciliation** — read-only, no commit (working tree confirmed unchanged before and after)
2. **Task 2: The deletion commit** — `1489453` (feat) — config, contract and package removed together, registry flipped
3. **Task 3: Scrub the residual references** — `41951f3` (docs) — 28 files, comment-only rewrites
4. **After-run artifact** — `519f3cc` (docs) — `18-RETIREMENT-AFTER-waybar.md`
5. **Authorised docs update** — `52735da` (docs) — README.md, VERIFICATION.md, `.claude/CLAUDE.md`

**Plan metadata:** (this commit, following this SUMMARY)

_Note: the host-side `pacman -Rns waybar` uninstall itself was run directly by the user between commits 3 and 4, at a `checkpoint:human-action` gate — this agent has no interactive sudo on this host._

## Files Created/Modified

- `.planning/phases/18-qml-bar-retirement-machinery/18-RETIREMENT-AFTER-waybar.md` — the after-run transcript, paired with 18-06's committed before-run baseline
- `waybar/` (12 files, deleted) — the whole stow package
- `hypr/.config/hypr/scripts/waybar-{design-lint,equivalence-check,launch.sh,switch.sh}` (deleted) — the four own-named scripts
- `matugen/.config/matugen/config.toml` — removed `[templates.waybar]` block; `templates/waybar-colors.css` deleted
- `theme-engine/.config/theme-engine/contract.json` — 29→22 `files[]`, 2→1 `presence_only_files`, 12→11 `engine_owned_files`
- `theme-engine/.config/theme-engine/{theme-doctor,theme-parity,theme-stress-test}` — four functional blocks, six sheet names, sentinel repoint
- `theme-engine/.config/theme-engine/lib/{motion,font,commit,reload,contract,generate,gtk}.sh` — sass-compile rows, render stanza, state-file carve-out, signal fan-out, comment scrubs
- `hypr/.config/hypr/config/{windowrules,autostart,keybinds}.lua` — 2 layer rules removed, autostart line removed, Super+B repointed
- `elephant/.config/elephant/menus/settings.toml` — superseded "Waybar layout" entry removed
- `hypr/.config/hypr/scripts/retirement-check` — registry row flipped `pending`→`retired`
- `hypr/.config/hypr/scripts/tests/quickshell-fixtures/*.json` (6 files) — namespace entries removed
- `hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-quickshell-windowrules.lua` — distractor namespace renamed `waybar`→`walker`
- `hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh` — `run_waybar_suite` and its dispatch arm removed, `theme-switch` suite intact
- `install.sh`, `stow.sh` — package/stow-list entries, layout/visibility-CSS/sass-compile seeds removed; closing hint text repointed to Super+B
- 22 further files (comment-only scrubs): see Task Commits' `41951f3`
- `README.md`, `VERIFICATION.md`, `.claude/CLAUDE.md` — bar-related sections updated (authorised scope extension)

## Decisions Made

See `key-decisions` in frontmatter. In addition:

- Task 1's precondition (GATE-02 authorisation) was independently re-verified before any deletion: `18-GATE-02-RECORD.md`'s `## Deletion Authorisation` read `RETIRE-02 AUTHORISED — sha 2644ae0...`, and `git diff --quiet 2644ae0 -- quickshell/.config/quickshell/` exited 0 (nothing changed under the QML bar since the authorising sha).
- The `checkpoint:decision` for the one-way deletion door was resolved to `proceed` per the orchestrator's explicit pre-authorisation (the user had already sat GATE-02's fifteen-gesture render pass) — not auto-selected blind; both authorisation conditions above were mechanically re-confirmed first.

## Deviations from Plan

### Auto-fixed / handled issues

**1. [Rule 3 - Blocking] `retirement-check --list`'s output format doesn't match the plan's assumed pipe-delimited grep syntax**
- **Found during:** Task 1 and Task 2 acceptance-criteria verification
- **Issue:** The plan's own acceptance criteria use `retirement-check --list | grep -E '^waybar\|' | cut -d'|' -f2`, assuming pipe-delimited output. The actual (pre-existing, 18-06-authored) `--list` implementation prints space-formatted `status=X` pairs, not pipe-delimited fields — this grep silently returns empty, not an error.
- **Fix:** Verified the underlying requirement (registry row reads `retired`, six others `pending`) via the actual output format (`grep -E '^\s*waybar\s' | grep -o 'status=[a-z]*'`) instead of "fixing" already-correct, already-shipped retirement-check code to match a plan typo.
- **Files modified:** none (retirement-check's `--list` implementation is correct and untouched)
- **Verification:** `bash retirement-check --list` manually inspected; registry substance confirmed correct both before and after Task 2's flip.

**2. [Rule 4-adjacent — architectural, reported not silently forced] `own-tree` class cannot ever read `[PASS]` for a genuinely deleted surface**
- **Found during:** Task 3
- **Issue:** `scan_own_tree()` returns `[SKIP]` whenever none of the registered own-tree globs exist on disk — which is the *only* reachable terminal state once a surface's own tree is truly gone. The plan's literal "14 PASS / 0 FAIL / 0 SKIP" target is architecturally unreachable for this one class.
- **Fix:** None applied — recorded the true, correct result (`[SKIP]`, not a forced `[PASS]`) in `18-RETIREMENT-AFTER-waybar.md` with the reasoning, per the orchestrator's explicit instruction not to round it toward the plan's target.
- **Files modified:** none (this is a report-time finding, not a code change)

**3. [Rule 3 - Blocking, resolved via checkpoint] Host pacman uninstall required interactive sudo this agent doesn't have**
- **Found during:** Task 2, Group J
- **Issue:** `sudo -n pacman -Rns --noconfirm waybar` failed ("a password is required"); no NOPASSWD sudoers rule exists for this host.
- **Fix:** Completed every git-trackable part of Task 2 and committed it, then issued a `checkpoint:human-action`. The user ran `sudo pacman -Rns waybar` directly; the orchestrator confirmed `pacman -Q waybar` now errors and `waybar.service` is gone from `systemctl --user list-unit-files`.
- **Files modified:** none directly (host state only)
- **Verification:** re-ran `retirement-check waybar` post-uninstall; `host-package` class now reads `[PASS]`.

**4. [Found, reported, not swept] A stale transient systemd scope coincidentally named after the deleted autostart line**
- **Found during:** Task 3's after-run
- **Issue:** `systemctl --user list-unit-files` still shows `app-Hyprland-waybar\x2dlaunch.sh-11fe048f.scope`, a *transient* scope (no unit file, no package behind it) whose name was assigned by `uwsm` when the now-deleted `uwsm app -- waybar-launch.sh` autostart line last ran. Its live CGroup tracks two unrelated `media-player.py` processes, not any waybar binary (`pgrep waybar` returns nothing).
- **Fix:** None — investigated and left untouched. Killing/restarting the processes inside it to force the scope's name to disappear was not authorised by this plan's scope (criticality note: "Do NOT widen scope"; T-18-20-06). It will clear on its own at the next login/logout cycle.
- **Files modified:** none
- **Documented in:** `18-RETIREMENT-AFTER-waybar.md`

**5. [Rule 2 - Missing critical, package.md's own scope carve-out] `_gaming_waybar_toggle` function renamed to `_gaming_bar_toggle`**
- **Found during:** Task 3 (`gaming-mode-toggle.sh` was in the cross-package-refs worklist)
- **Issue:** The function name itself (not just a comment) contained the retired surface's name.
- **Fix:** Renamed `_gaming_waybar_toggle` → `_gaming_bar_toggle` and updated both call sites in the same file.
- **Files modified:** `hypr/.config/hypr/scripts/gaming-mode-toggle.sh`
- **Verification:** `bash -n` passes; both call sites confirmed updated via grep.

---

**Total deviations:** 5 (1 verify-script format mismatch worked around, 1 architectural finding reported, 1 sudo blocker resolved via checkpoint, 1 unrelated live artifact reported not swept, 1 function rename)
**Impact on plan:** No scope creep — all five stayed within the plan's own file lists and named surfaces, or were explicitly the finding/reporting behaviour the plan's own prohibitions require.

## Scrubbed history

Facts that could not survive the comment-name rename (Task 3's rule: rewrite the reasoning, drop the retired name, keep the fact) — recorded here verbatim rather than destroyed, per the plan's own instruction.

- **`~/.local/state/theme/waybar-visibility.css`** — the exact former filename of the visibility-state CSS stub `bar-visibility.sh`'s header comment now describes generically. Present-and-empty from 18-15 onward (the four `style-*.scss` sheets' final `@import`), deleted outright by this plan (Group J) once those sheets died in Group A.
- **`waybar-fullscreen-watch.sh`** — the exact former filename of the standalone socket2 fullscreen listener `bar-watchdog.sh` now describes as "the retired fullscreen-watch script." Deleted by 18-15 (D-18-28), not this plan; its shape is inherited by `bar-watchdog.sh`'s own `python3 - <<'PYEOF'` idiom, citable at `git show adce9e6^:hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh`.
- **Upstream citation for `WorkspaceCapsule.qml`'s workspace-slot precedence table** — the live-observation methodology (repeated `hyprctl dispatch` state changes, `grim` frame-by-frame diffing) was cross-checked against `Alexays/Waybar` (github.com/Alexays/Waybar) v0.15.0's own `Workspace::selectIcon()` C++ source, confirmed byte-identical to the installed binary via `strings $(which waybar)`, and against that binary's own `--log-level trace` output. `WorkspaceCapsule.qml` now describes this generically as "the upstream v0.15.0 source" / "that retired bar's own `--log-level trace`" with this citation preserved here.
- **`Design.qml`'s bar-scoped type/padding parity tokens' exact source citations** (now generalized to "exact retired-stylesheet file+line citations... recorded in 18-20-SUMMARY.md"):
  - `barGlyphSize` (16) ← `waybar/.config/waybar/style-athena.scss:400` (`font-size: 16px` on every glyph-only module)
  - `barBodySize` (13) ← `style-athena.scss:31` (`* { font-size: 13px }`)
  - `barCapsulePadding` (6) ← `style-athena.scss:76/112/150/216/264/293` (`padding: 6px 6px` on every group capsule)
- **`shell.qml`'s captured raw socket2 IPC event strings** proving maximize/fullscreen are indistinguishable on this Hyprland build: the byte-identical sequence `"fullscreen>>1"`, `"closelayer>>waybar"`, `"openlayer>>waybar"` — captured live via a raw socket read (not documentation), reproduced across three separate windows (tiled Zen, tiled kitty, floating kitty). `shell.qml` now describes this as "a byte-identical socket2 IPC event sequence naming the retired bar's own layer" with the exact strings preserved here.
- **`quickshell.service`'s exact shape-ancestor unit name** — copied from the package-shipped `waybar.service` (packaged under `/usr/lib/systemd/user/`, `disabled`; inspected via `systemctl --user cat waybar.service`). `quickshell.service`'s comments now say "the retired bar's own packaged unit" throughout; the exact unit name (`waybar.service`) is preserved here, and that file is now gone from disk since the package uninstall.
- **`theme-engine/.config/theme-engine/lib/contract.sh`'s example filename** — the historical Rule-1 bug this comment documents (a file with motion but no colour `@import` making `grep -q` fail with no match) was found against `waybar-modules.css`, an included partial by design. Now described generically as "the retired bar's modules stylesheet."
- **`wleave/.config/wleave/style.css`'s mix() idiom citation** — the exact Phase 8-14 `mix()` idiom this file's two-hue CONTAINER-level treatment follows was first established in `waybar/.config/waybar/theme.css` lines ~165-172 (now deleted). `style.css` now describes this generically as "the retired bar's own theme sheet, lines ~165-172."

## Issues Encountered

See "Deviations from Plan" above — all five items there were also the issues encountered; none required problem-solving beyond what's documented there (a checkpoint pause for sudo, and two report-not-fix findings).

## User Setup Required

None — the one host-side action this plan required (`sudo pacman -Rns waybar`) was already completed by the user at the mid-plan checkpoint.

## Documentation findings beyond this plan's authorised scope

Found while editing `.claude/CLAUDE.md` under the authorised extension, but left untouched since they weren't among the four items named: the file's opening paragraph (line 7) still lists "waybar" among live desktop components propagated by the theming pipeline, and several Sources/websearch-citation lines (62, 64, 72, 91, 100, 109, 112, 116) still reference waybar in a research-citation context. These are historical research artifacts and prose, not the Core Technologies/Supporting Libraries rows the user named — flagged here for a future, separately-scoped docs pass rather than swept into this one.

`README.md`'s keybindings table and `stow.sh`'s closing hint text both claim `Super + Shift + B` for two different things (README: "Wallpaper picker"; the live `bar-visibility.sh` bind is actually "Toggle bar visibility") — this mismatch predates this plan and is unrelated to waybar retirement; not fixed here since it's outside the four named items, but worth a separate look.

## Next Phase Readiness

- `contract.json` stands at 22/1/11 — Phase 21's RETIRE-08 close should expect to start its own count from this total (removing the remaining 5 `files[]` entries: `swaync.css`, `swaync-style.css`, `swayosd.css`, `wleave.css`, `ags.scss`).
- `retirement-check`'s registry: `waybar` reads `retired`; `swaync`, `swayosd`, `wleave`, `ags`, `wlogout`, `eww` still read `pending` — 18-06's standing warning holds: `wlogout` and `eww` must not be tidied to `retired` while they still carry references (RETIRE-07, Phase 20).
- D-18-33's temporary notification-bell binding (`swaync-client -swb`) was not touched by this plan and still reaches its target — confirmed via `bash -n`/content review of the swaync-launch/bell-related scripts touched in Task 3; Phase 19 owns swapping what sits behind it.
- The QML bar is now the sole bar on this host with no fallback — any future regression is a `git revert` of the deletion commit plus a `pacman -S waybar`/`stow waybar`/`theme-apply` reinstall, not a layout switch.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-12*
