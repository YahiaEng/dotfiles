---
phase: quick-260820-2yz
plan: 01
subsystem: theme-engine
tags: [tmux, zellij, matugen, theme-engine, contract, stow, retirement-check]
status: complete
dependency-graph:
  requires:
    - phase: quick-260820-0ha
      provides: "zellij as the themed, live-reloading terminal multiplexer surface (contract kdl format, [templates.zellij], commit.sh symlink wiring, stow.sh pre-create)"
  provides:
    - "tmux fully retired from the repo: stow package, matugen template, [templates.tmux], contract.json entry, tmux-set format (both extractors), reload hook, install/stow/.gitignore wiring — all deleted"
    - "Six survivor files (zellij-config.kdl, config.toml, contract.sh, reload.sh, stow.sh, install.sh) restated to explain their own reasoning without naming the retired surface"
    - "retirement-check REGISTRY_RAW carries a permanent, re-runnable tmux entry (status pending) — the eww-scar fix RETIRE-TMUX-04 asked for"
  affects:
    - "theme-engine/.config/theme-engine/contract.json"
    - "theme-engine/.config/theme-engine/lib/contract.sh"
    - "theme-engine/.config/theme-engine/lib/reload.sh"
    - "matugen/.config/matugen/config.toml"
    - "hypr/.config/hypr/scripts/retirement-check"
tech-stack:
  added: []
  patterns:
    - "Role-named tombstones in reload.sh's fan-out (matching the existing RETIRE-02/03/04/06 convention): the removed hook's former slot names the retired surface by ROLE ('the retired multiplexer'), never by name, so retirement-check's own sweep never flags the tombstone as a surviving reference."
    - "Survivor-comment restatement discipline: a comment that explained a SURVIVING mechanism by CONTRAST with a retired one is rewritten to state its own reasoning absolutely, or retargeted to a still-living sibling (fish, fisher, quickshell) — never simply deleted, since deleting it would destroy the recorded WHY."
key-files:
  created:
    - ".planning/quick/260820-2yz-retire-tmux-now-that-zellij-is-the-theme/260820-2yz-SUMMARY.md"
  modified:
    - ".gitignore"
    - "install.sh"
    - "matugen/.config/matugen/config.toml"
    - "matugen/.config/matugen/templates/zellij-config.kdl"
    - "stow.sh"
    - "theme-engine/.config/theme-engine/contract.json"
    - "theme-engine/.config/theme-engine/lib/contract.sh"
    - "theme-engine/.config/theme-engine/lib/reload.sh"
    - "hypr/.config/hypr/scripts/retirement-check"
  deleted:
    - "tmux/.config/tmux/tmux.conf (whole stow package)"
    - "matugen/.config/matugen/templates/tmux-colors.conf"
decisions:
  - "D-01 through D-07 (all operator-locked, applied as written): tmux-set removed from BOTH contract.sh extractors; contract.json 21 -> 20; reload hook removed with no replacement (zellij needs none, measured); tmux dropped from PACMAN_PKGS/AUR_PKGS but no pacman/paru run; stow.sh's tmux plugins pre-create and headless tpm fetch removed, zellij's own pre-create untouched; the six zellij-facing survivor files restated, not deleted; host cleanup documented, never executed."
  - "retirement-check registry entry ships status=pending, not retired — the host-package blocking class runs pacman -Q tmux against the live host, and the package is deliberately still installed there (D-04/D-07). Flipping to retired now would arm the blocking tier against a reference this repo has no authority to clear."
  - "Measured mid-task, not predicted by the plan: the plan's predicted 'one red gate' (stow-link-check flagging the now-dangling ~/.config/tmux/tmux.conf symlink) did NOT occur. stow-link-check derives its sweep-root set from stow.sh's own PACKAGES loop (its own header comment says so), and Task 1 removed tmux from that array — so the sweep no longer visits ~/.config/tmux at all and the dangling symlink is invisible to it. The symlink IS genuinely dangling on the host (confirmed via find -xtype l) and still needs the same operator cleanup command; it just doesn't gate theme-doctor any more."
  - "Also measured, not predicted: retirement-check's systemd-units class (which queries the LIVE host's systemctl --user list-unit-files) picked up 7 active tmux-spawn-*.scope transient units — the operator has a live tmux server (PID confirmed) with 7 open panes running right now. This is real, host-only, non-repo state. retirement-check's own status=pending semantics mean it is reported as [REPORT], never [FAIL], and the tool's own exit code is 0 regardless of blocking-class reference counts while status stays pending — so this does not gate anything, and is if anything stronger evidence that pending (not retired) is the correct status today."
actuals:
  tokens: 10089
  tasks: 3
  commits: 3
metrics:
  duration: "~35 min"
  completed: "2026-08-20"
requirements-completed: [RETIRE-TMUX-01, RETIRE-TMUX-02, RETIRE-TMUX-03, RETIRE-TMUX-04]
---

# Quick Task 260820-2yz: Retire tmux now that zellij is the theme Summary

tmux is fully retired from the repo — stow package, matugen template, contract entry, both
extractor arms, reload hook, and install/stow/.gitignore wiring all deleted in clean-removal
commits; six survivor comments restated to keep their WHY without naming the retired surface;
retirement-check now carries a permanent `pending` registry entry. Tasks 1-3 executed and
verified; Task 4 (the plan's blocking operator checkpoint) is intentionally NOT attempted.

## Performance

- **Duration:** ~35 min
- **Tasks:** 3/4 (Tasks 1-3 complete; Task 4 blocking checkpoint awaiting operator)
- **Files changed:** 11 (2 deleted whole files, 9 modified)
- **Commits:** 3

## Accomplishments

- **Task 1 (`a4194a0` + `6c33c7e`):** Deleted the `tmux/` stow package (1 file, 83 lines) and
  `matugen/.config/matugen/templates/tmux-colors.conf` (86 lines) outright. Dropped
  `[templates.tmux]` from `config.toml`. `contract.json` 21 -> 20 entries, `zellij.kdl`/`kdl`
  entry now last and intact. Removed `tmux-set` from BOTH `contract.sh` extractors
  (`contract_extract_names` and `contract_extract_values`) plus the format-enumeration comment.
  Removed `theme_engine_reload_tmux` (call site, header comment, function body) from
  `reload.sh`, leaving a role-named tombstone ("The retired multiplexer's re-source reload
  hook...") matching the existing RETIRE-02/03/06 convention. Removed `tmux`/
  `tmux-plugin-manager` from `install.sh`'s package arrays, the `tmux` `PACKAGES` entry +
  plugins pre-create + headless tpm fetch block from `stow.sh`, and the plugin-ignore block
  from `.gitignore`.
  - **Split across two commits, documented as a deviation below** — `git add tmux ...` failed
    atomically after `git rm -r tmux` had already removed the path, silently leaving only the
    two whole-file deletions staged for the first commit; the second commit completes the same
    Task 1 removal with the remaining 7 files.
- **Task 2 (`407371d`):** Restated all six survivor-comment sites (RETIRE-TMUX-03):
  `zellij-config.kdl` (fragment-sourcing evidence list, no-reload-hook paragraph, role-
  assignment rule, `default_shell`, `copy_command`, `session_serialization`/keybinds notes),
  `config.toml`'s `[templates.zellij]` closing note, `contract.sh`'s
  `contract_kdl_theme_pairs` + `kdl` value-extractor comments (retargeted to `fish-set` alone),
  `reload.sh`'s zellij no-hook paragraph (kept the fish contrast, restated its own MEASURED-
  decision reasoning), `stow.sh`'s zellij pre-create comment (fold-bug mechanism + placement
  rule both restated as their own reasoning, idiom list retargeted to fisher/quickshell), and
  `install.sh`'s zellij PACMAN_PKGS comment. Registered `tmux|pending|tmux/|260820-2yz` in
  `retirement-check`'s `REGISTRY_RAW`, right after the `eww` entry, with a 7-line explanatory
  comment on why it ships `pending` rather than `retired` (RETIRE-TMUX-04).
- **Task 3 (no commit — permitted per this task's constraints):** Ran
  `~/.config/theme-engine/theme-apply catppuccin` to re-render the live state dir. Ran all
  three static gates and measured the actual numbers (below). Asserted the state dir and all
  six zellij anchors are intact.

## Task Commits

1. **Task 1: Delete the tmux surface and its repo wiring** — `a4194a0` (feat, whole-file
   deletions) + `6c33c7e` (feat, remaining wiring removal — split due to a staging error, see
   Deviations)
2. **Task 2: Restate the survivor comments and register the retirement** — `407371d` (docs)
3. **Task 3: Re-render, measure the gates** — no commit (theme-apply touches only
   `~/.local/state/theme/`, outside the repo; no repo files changed)

_No plan-metadata commit — per this task's explicit constraint, SUMMARY.md and STATE.md are
left for the orchestrator to commit._

## Files Created/Modified

- `tmux/.config/tmux/tmux.conf` — DELETED (whole stow package, 83 lines)
- `matugen/.config/matugen/templates/tmux-colors.conf` — DELETED (86 lines)
- `matugen/.config/matugen/config.toml` — `[templates.tmux]` removed; `[templates.zellij]`
  header restated
- `theme-engine/.config/theme-engine/contract.json` — 21 -> 20 entries
- `theme-engine/.config/theme-engine/lib/contract.sh` — `tmux-set` gone from both extractors;
  `kdl`-comment contrast retargeted to `fish-set`
- `theme-engine/.config/theme-engine/lib/reload.sh` — hook/call site gone, role-named tombstone
  + restated zellij no-hook paragraph
- `install.sh`, `stow.sh`, `.gitignore` — package/stow/ignore wiring gone; zellij comments
  restated
- `hypr/.config/hypr/scripts/retirement-check` — `tmux` registry entry (pending) + explanatory
  comment
- `matugen/.config/matugen/templates/zellij-config.kdl` — six survivor comments restated

## Decisions Made

See the `decisions` frontmatter block above for the full list (D-01 through D-07 applied as
locked; the pending-status rationale; the two measured, plan-unpredicted findings around
stow-link-check's scope derivation and the live tmux server's transient systemd scopes).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Split Task 1's commit into two after an atomic `git add` failure**
- **Found during:** Task 1, committing
- **Issue:** `git add tmux matugen/.../tmux-colors.conf matugen/.../config.toml ...` failed
  with `fatal: pathspec 'tmux' did not match any files` — `git rm -r tmux` had already removed
  the working-tree path, so the bare `tmux` pathspec (intended to mean "the deletion already
  staged by git rm") no longer resolved. Because `git add` treats its whole argument list
  atomically on a pathspec error, none of the other 8 files in that call got staged either —
  the resulting commit (`a4194a0`) silently contained only the two whole-file deletions that
  `git rm` had already staged directly.
- **Fix:** Staged the remaining 7 modified files explicitly by name (no bare `tmux` pathspec
  needed since it was no longer a path) and created a second commit (`6c33c7e`) completing the
  same Task 1 removal. Per this session's git-safety protocol (never amend unless explicitly
  requested), a new commit was used rather than amending `a4194a0`.
- **Files modified:** `.gitignore`, `install.sh`, `matugen/.config/matugen/config.toml`,
  `stow.sh`, `theme-engine/.config/theme-engine/contract.json`,
  `theme-engine/.config/theme-engine/lib/contract.sh`,
  `theme-engine/.config/theme-engine/lib/reload.sh`
- **Verification:** Task 1's full automated verify script (contract.json 20 entries, retired
  format in 0 arms, survivors at 2 each, `bash -n` on all four shell files, hook gone from
  reload.sh) passed after both commits landed.
- **Committed in:** `6c33c7e`

---

**Total deviations:** 1 auto-fixed (1 blocking). No architectural changes, no scope creep —
both commits together read as the single clean removal the plan asked for; only the commit
boundary differs from what was written.

## Issues Encountered

None that blocked progress. Two things were measured during Task 3 that the plan did not
predict — documented in the `decisions` frontmatter and the Gate Results section below, not
treated as defects since both are benign, host-only, non-repo state.

## Gate Results (measured, Task 3)

| Gate | Baseline | Measured | Verdict |
|------|----------|----------|---------|
| theme-doctor | 596 passed, 0 failed | **594 passed, 1 failed** | Below baseline as expected (2 fewer entries render). The one failure is `git status --porcelain is empty` (CLEAN-02) — see below, not the predicted dangling-symlink failure. |
| theme-parity | 1897 / 0 failed | **1809 passed, 0 failed** | Below baseline as expected (tmux-colors.conf's checks gone). |
| colour-lint | 150 / 0 failed | **150 passed, 0 failed** | Unchanged, exactly as predicted (no QML touched). |

### The predicted dangling-symlink failure did NOT occur

The plan predicted `stow-link-check` would flag `~/.config/tmux/tmux.conf` as dangling once
its repo target was deleted. Measured instead: `stow-link-check` derives its sweep-root set
from `stow.sh`'s own `PACKAGES` loop (its own header comment states this explicitly), and
Task 1 removed `tmux` from that array — so the sweep no longer visits `~/.config/tmux` at all.
`theme-doctor`'s `stow-link-check: .config: 48 symlink(s), none dangling` line confirms this.

The symlink IS still genuinely dangling on the host — confirmed directly:
```
$ find ~/.config -xtype l | grep -i tmux
/home/aorus/.config/tmux/tmux.conf
$ test -e ~/.config/tmux/tmux.conf && echo EXISTS || echo DANGLING
DANGLING
```
It just no longer gates any static check. The same host-cleanup command below still applies
for host hygiene.

### theme-doctor's ONE actual failure: CLEAN-02 (git dirty), not the multiplexer

```
[FAIL] git status --porcelain is empty (/home/aorus/dotfiles stays clean)
```
Confirmed the cause is entirely this task's own uncommitted planning artifacts, not the code
changes: `git status --porcelain -- . ':!.planning'` returns **empty** (fully clean); the only
dirty entry in the unrestricted `git status --porcelain` is
`?? .planning/quick/260820-2yz-retire-tmux-now-that-zellij-is-the-theme/` — this task's own
PLAN.md (pre-existing, not authored by this executor) plus this SUMMARY.md, both intentionally
left uncommitted per this task's explicit instruction ("the orchestrator handles the docs
commit"). This will read clean once the orchestrator's docs commit lands — the same benign
pattern the sibling quick task 260819-vas recorded in its own SUMMARY for the same gate.

### retirement-check registry + sweep

```
$ hypr/.config/hypr/scripts/retirement-check --list | grep tmux
  tmux                 status=pending  requirement=260820-2yz own-tree=tmux/

$ hypr/.config/hypr/scripts/retirement-check --self-test
Self-test summary: 5 passed, 0 failed

$ hypr/.config/hypr/scripts/retirement-check tmux --root .
[SKIP] tmux/own-tree: own-tree path(s) not present under .: tmux/
[REPORT] tmux/{layer-window-rules,autostart,keybinds,contract-json,matugen-templates,
                checker-internals,test-fixtures,cross-package-refs,install-stow-lists,
                dbus-activation,xdg-autostart}: 0 reference(s) each
[REPORT] tmux/systemd-units: 7 reference(s)   <- see below, live host state, not a repo defect
[REPORT] tmux/host-package: 1 reference(s)    <- pacman -Q tmux: tmux 3.7_c-1 (predicted, D-07)
Summary: surface=tmux status=pending failed_classes=0
```
All 11 repo-scoped blocking classes are genuinely zero — the sweep is clean. `systemd-units`
surfaced something the plan didn't predict: the operator has a **live tmux server running
right now** (confirmed via `pgrep -a tmux`, PID 151282, 7 active panes), and each pane's
`tmux-spawn-<uuid>.scope` transient systemd unit matches the surface token. Since the registry
entry is `pending`, `retirement-check`'s own logic (`emit_class`) treats every blocking class
as `[REPORT]`, never `[FAIL]`, and the tool's exit code is unconditionally 0 while pending —
confirmed by the `failed_classes=0` line above. This is real, host-only, non-repo evidence and,
if anything, makes the case for `pending` (not `retired`) stronger than the plan's own
prediction: the host doesn't just have the package installed, it's actively in use.

### Zero surviving references, repo-wide

```
$ git grep -n -i tmux -- . ':!.planning' ':!hypr/.config/hypr/scripts/retirement-check'
(no output, exit 1)
```

### State dir + zellij intact (D-06)

```
$ test ! -e ~/.local/state/theme/tmux-colors.conf && echo "no tmux colours file"
no tmux colours file
$ test -s ~/.local/state/theme/zellij.kdl && echo "zellij.kdl non-empty"
zellij.kdl non-empty
$ readlink -f ~/.config/zellij/config.kdl
/home/aorus/.local/state/theme/zellij.kdl
```
All six zellij anchors confirmed present and unchanged: `[templates.zellij]` in `config.toml`,
the `zellij.kdl`/`kdl` entry in `contract.json`, `contract_kdl_theme_pairs` + both `kdl)` arms
in `contract.sh`, the `zellij.kdl` `ln -sf` wiring in `lib/commit.sh`, the `~/.config/zellij`
pre-create in `stow.sh`, and the live resolving symlink above.

## Known Stubs

None. This is a pure removal; nothing new was added that could stub anything.

## Task 4: Checkpoint — NOT attempted, awaiting operator

Per this task's explicit instructions, **Task 4 (`checkpoint:human-verify`, `gate="blocking"`)
was not attempted and is not marked done.** It requires the operator to:

1. **Clear the dangling symlink and orphaned tpm clones** (host hygiene — no longer gates any
   check, per the finding above, but still real dead state on disk):
   ```
   rm -rf ~/.config/tmux
   ```
2. **Re-run the gates and confirm all three green** (theme-doctor should now show 0 failed once
   the docs commit lands and the repo is clean):
   ```
   ~/.config/theme-engine/theme-doctor | tail -3
   ~/.config/theme-engine/theme-parity | tail -3
   ~/.config/hypr/scripts/colour-lint  | tail -3
   ```
3. **Confirm zellij is untouched:** open a kitty window, run `zellij`, split a pane, switch
   themes from the walker picker, confirm the status bar/powerline wedges/pane frames all
   re-theme live with the session open.
4. **Decide on the binaries** (entirely optional):
   ```
   sudo pacman -Rns tmux
   paru -Rns tmux-plugin-manager
   ```
   If run, say so — the `retirement-check` registry entry can then flip from `pending` to
   `retired` (edit `hypr/.config/hypr/scripts/retirement-check`'s `REGISTRY_RAW`, change the
   `tmux` line's second field), which arms its blocking tier and gives theme-doctor a permanent
   PASS block for the surface. Until then `pending` is correct.
5. **Sanity-check the sweep, optionally:**
   ```
   ~/.config/hypr/scripts/retirement-check tmux --root ~/dotfiles
   ```

See the plan's Task 4 `<how-to-verify>` block for the full operator script.

## Self-Check: PASSED

- `tmux/.config/tmux/tmux.conf` — CONFIRMED ABSENT (`git rm` committed in `a4194a0`)
- `matugen/.config/matugen/templates/tmux-colors.conf` — CONFIRMED ABSENT
- `theme-engine/.config/theme-engine/contract.json` has 20 entries, no tmux, zellij/kdl last —
  FOUND
- `theme-engine/.config/theme-engine/lib/contract.sh` has 0 `tmux-set` arms, 2 each for
  `fish-set`/`kdl`/`kitty-kv`/`env-kv` — FOUND
- `theme-engine/.config/theme-engine/lib/reload.sh` has no `theme_engine_reload_tmux` — FOUND
- `hypr/.config/hypr/scripts/retirement-check` registry has a `tmux` entry, `--self-test`
  passes 5/5 — FOUND
- Commit `a4194a0` — FOUND (`git log --oneline --all | grep a4194a0`)
- Commit `6c33c7e` — FOUND
- Commit `407371d` — FOUND

---
*Quick task: 260820-2yz*
*Completed: 2026-08-20*
