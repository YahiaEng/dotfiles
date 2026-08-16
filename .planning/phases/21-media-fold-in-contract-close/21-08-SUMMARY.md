---
phase: 21-media-fold-in-contract-close
plan: 08
subsystem: theming
tags: [hyprland, quickshell, matugen, theme-engine, retirement, cava, mpris]

requires:
  - phase: 21-media-fold-in-contract-close
    provides: "21-07's Media tab/popout parity build, the Super+M shortcut, and 21-BEHAVIOUR-BASELINE.md's parity checklist this plan's gate judged against"
  - phase: 21-media-fold-in-contract-close
    provides: "21-05/21-06's frost unification and 60-bar cava visualiser, the render-quality half of this plan's combined gate"
provides:
  - "GATE-02 combined render + parity gate record (PASSED WITH FIXES, judged commit 5f38a49)"
  - "Deletion authorisation and operator 'proceed' decision at the one-way door"
  - "The standalone GTK4 media applet (ags/) removed from repo — config, contract entry, and three orphaned scripts, all in one commit"
  - "theme-engine/contract.json reduced 18 -> 17 file entries (RETIRE-08)"
  - "retirement-check registry row ags: pending -> retired"
affects: [22-fresh-install-proof, theme-engine, quickshell-media, retirement-tooling]

actuals:
  tokens: 27181
  tasks: 1
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Retirement registry flip requires closing ALL blocking-domain reference classes to zero, not only the classes the plan's own file list named — re-run retirement-check <surface> after the plan's own edits and iterate until failed_classes=0 (RETIRE-07 precedent, ada405a)"
    - "Historical/provenance comments citing a deleted namespace are rewritten to restate the finding directly or cite a plan ID, never left pointing at a rule that no longer exists"

key-files:
  created:
    - .planning/phases/21-media-fold-in-contract-close/21-PRE-DELETION-SWEEP.txt
  modified:
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/lib/reload.sh
    - theme-engine/.config/theme-engine/theme-parity
    - theme-engine/.config/theme-engine/lib/contract.sh
    - matugen/.config/matugen/config.toml
    - hypr/.config/hypr/config/windowrules.lua
    - hypr/.config/hypr/config/autostart.lua
    - hypr/.config/hypr/config/keybinds.lua
    - hypr/.config/hypr/scripts/retirement-check
    - hypr/.config/hypr/scripts/motion-lint
    - hypr/.config/hypr/scripts/quickshell-doctor
    - hypr/.config/hypr/scripts/tests/test-media-hardening.sh
    - install.sh
    - stow.sh
    - quickshell/.config/quickshell/modules/CavaService.qml
    - quickshell/.config/quickshell/modules/Overview.qml
    - quickshell/.config/quickshell/modules/bar/BarRoles.qml
    - quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml
    - quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml
    - quickshell/.config/quickshell/shell.qml
    - quickshell/.config/quickshell/shortcuts.json
    - quickshell/.config/systemd/user/quickshell.service
    - .gitignore

key-decisions:
  - "Task 1's combined gate ran as an iterative find-fix-reverify loop (12 defects found and fixed across 10 commits, 74c9877..5f38a49), not a single frozen-tree judgment — recorded honestly in 21-GATE-02-RECORD.md rather than claiming a guarantee the walk didn't provide"
  - "Task 2: operator selected 'proceed' — deletion authorised as a one-way door"
  - "Task 3: closed out-of-plan blocking-domain reference-check hits (keybinds.lua, shell.qml, shortcuts.json, CavaService.qml, MediaBackend.qml, quickshell.service, contract.sh, motion-lint, quickshell-doctor, plus 3 QML sites with the literal 'ags-media' namespace string the plan's own file list missed) to bring retirement-check ags to a real clean state, following this repo's own RETIRE-07 precedent rather than leaving the registry flip half-true"
  - "Host package removal (aylurs-gtk-shell) left OUTSTANDING — this session has no interactive sudo credential. Repo-side deletion completed per standing rule 8 ('do the repo-side deletion and report the host step as outstanding')"

requirements-completed: [QMEDIA-01, QMEDIA-02, QMEDIA-03, RETIRE-06, RETIRE-08]

coverage:
  - id: D1
    description: "Combined render + parity gate judged the Media tab/popout replacement against the retiring AGS card in one sitting; PASSED WITH FIXES after 12 defects found and fixed live"
    requirement: "QMEDIA-01"
    verification:
      - kind: manual_procedural
        ref: "21-GATE-02-RECORD.md — operator live walk, both Part A (parity checklist) and Part B (render checks)"
        status: pass
    human_judgment: true
    rationale: "Visual/interactive parity and render-quality judgment against a live desktop — cannot be automated"
  - id: D2
    description: "Operator authorised the irreversible deletion at the one-way-door decision"
    requirement: "RETIRE-06"
    verification:
      - kind: manual_procedural
        ref: "Task 2 resume-signal: 'proceed'"
        status: pass
    human_judgment: true
    rationale: "Irreversible action requiring explicit human authorisation, not an automatable check"
  - id: D3
    description: "Standalone media applet (ags/), its theme-contract entry, matugen template, reload step, layer rules, autostart entry, install/stow entries, and three orphaned scripts removed in one commit; theme contract 18 -> 17 entries; registry flipped to retired"
    requirement: "RETIRE-06"
    verification:
      - kind: other
        ref: "git show --stat 5cb32ed; theme-engine/contract.json file count; retirement-check ags (status=retired)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Theme contract reduced to its post-migration size with the scss-vars format family still represented"
    requirement: "RETIRE-08"
    verification:
      - kind: unit
        ref: "node -e contract.json file-count check (17) and scss-vars-count check (>=1)"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-08-16
status: complete
---

# Phase 21 Plan 08: Combined Deletion Gate and RETIRE-06 Retirement Commit Summary

**Standalone GTK4 media applet (`ags/`) removed from repo in one commit after a combined render+parity gate found and fixed 12 defects live; theme contract reduced 18 → 17 entries; host package removal left outstanding pending operator sudo.**

## Performance

- **Duration:** ~55 min (this session's Task 3 execution; Task 1's gate and Task 2's decision were completed in a prior session — see 21-GATE-02-RECORD.md for that timeline)
- **Started:** 2026-08-16T15:18:00Z (approx, this session)
- **Completed:** 2026-08-16T16:13:17Z
- **Tasks:** 3 (Task 1 combined gate, Task 2 one-way-door decision — both already complete on entry; Task 3 the deletion, executed this session)
- **Files modified:** 37 (1 created, 23 modified, 13 deleted)

## Accomplishments

- **Task 1 (prior session):** Combined render + parity gate walked live against the running AGS card. PASSED WITH FIXES — every one of 16 parity rows and 8 render checks passes at judged commit `5f38a49`, after finding and fixing 12 defects (volume-slider dead zones, a uint/string id-type mismatch that silently discarded every volume write, a self-referential seek-bar binding, a dropdown with no scroll mechanism at all, and more). Full per-defect root-cause table in `21-GATE-02-RECORD.md`.
- **Task 2 (prior session):** Operator authorised the deletion — selected "proceed" at the one-way-door decision.
- **Task 3 (this session):** Executed the deletion as one commit, config-then-package:
  - Pre-deletion sweep captured to `21-PRE-DELETION-SWEEP.txt` — all 16 `retirement-check` reference classes, each with an explicit hit-count or zero-count line, before any edit.
  - Theme contract: removed the `ags.scss`/`scss-vars` entry (18 → 17 entries). Verified before removal that `theme-stress-test`'s `REPRESENTATIVE_FILES` did not name it (a prior retirement broke that test exactly this way).
  - Matugen template block + `ags-colors.scss` deleted. `reload.sh`'s guarded CSS-hot-reload fan-out step deleted (QML surfaces hot-reload natively — nothing replaces it).
  - `windowrules.lua`: both real `ags-media` layer rules deleted; eight comment sites rewritten so each finding (GTK4 opaque-background default, translucency-without-blur, blur-strength-is-global, ignore_alpha-silently-disables-blur, lowering-the-threshold-unlocks-the-range, the FILE-LEVEL FINDING cross-reference) survives under its own name.
  - `install.sh`/`stow.sh`: AUR package entry removed; sass-compiler comment **corrected** (it wrongly attributed `dart-sass` solely to the retiring package — `stow.sh`'s GTK3 seed block shells out to it independently, confirmed byte-unchanged); audio-analyser comment reworded to describe what now consumes it (the QML visualiser).
  - `test-media-hardening.sh` trimmed: checks 1–7 and 11 (exercised the two deleted reader scripts) removed; checks 8/9/9b/10 kept unmodified — live network-forgery protection for the RETAINED album-art resolver. 17/17 checks pass post-trim.
  - `retirement-check` registry row `ags`: `pending` → `retired`.
  - The `ags/.config/ags/` tree (9 git-tracked files, 156 on disk including the gitignored `@girs/` cache) and three orphaned scripts (`media-status.sh`, `media-players.sh`, `media-player.py`) deleted. `media-art-resolve.sh` explicitly retained and verified still executable.
  - **Out-of-plan blocking-domain hits closed** (see Deviations) to bring `retirement-check ags` to a real clean state under the RETIRE-07 precedent, not a vacuous flip.

## Task Commits

1. **Task 1: THE COMBINED GATE** — 10 commits, `74c9877`..`5f38a49` (prior session; see `21-GATE-02-RECORD.md` for the full defect-by-defect list)
2. **Task 2: One-way door decision** — no code commit (checkpoint:decision, operator selected "proceed")
3. **Task 3: The deletion — config then package, one commit** — `5cb32ed` (feat)

**Plan metadata:** this commit (`21-08-SUMMARY.md`, `STATE.md`, `ROADMAP.md`, `REQUIREMENTS.md`) — see final commit below.

## Files Created/Modified

- `.planning/phases/21-media-fold-in-contract-close/21-PRE-DELETION-SWEEP.txt` - full 16-class pre-deletion reference sweep, captured before any edit
- `theme-engine/.config/theme-engine/contract.json` - removed `ags.scss`/scss-vars entry (18 → 17)
- `theme-engine/.config/theme-engine/lib/reload.sh` - removed the AGS CSS-hot-reload fan-out step
- `theme-engine/.config/theme-engine/theme-parity` - reworded format-family comment to cite `_motion.scss`
- `theme-engine/.config/theme-engine/lib/contract.sh` - reworded scss-vars extractor comment (no literal `ags.scss` left)
- `matugen/.config/matugen/config.toml` - removed `[templates.ags]` block + header comment
- `matugen/.config/matugen/templates/ags-colors.scss` - deleted
- `hypr/.config/hypr/config/windowrules.lua` - removed both `ags-media` layer rules; rewrote 8 comment sites
- `hypr/.config/hypr/config/autostart.lua` - removed the AGS autostart line + comment
- `hypr/.config/hypr/config/keybinds.lua` - reworded the Super+M comment's "retiring AGS media card" citation
- `hypr/.config/hypr/scripts/retirement-check` - registry row `ags`: pending → retired
- `hypr/.config/hypr/scripts/motion-lint` - removed the dead `ags/*.scss` EXEMPTIONS entry and `$HOME/.config/ags` ROOTS entry
- `hypr/.config/hypr/scripts/quickshell-doctor` - dropped "AGS" from two prose comments
- `hypr/.config/hypr/scripts/tests/test-media-hardening.sh` - trimmed to surviving album-art-resolver coverage (checks 8/9/9b/10)
- `hypr/.config/hypr/scripts/media-status.sh` - deleted (orphaned reader)
- `hypr/.config/hypr/scripts/media-players.sh` - deleted (orphaned reader)
- `hypr/.config/hypr/scripts/media-player.py` - deleted (pre-existing orphan, zero consumers)
- `install.sh` - removed AUR entry, corrected sass-compiler comment, reworded audio-analyser comment
- `stow.sh` - removed `ags` package-array entry
- `ags/.config/ags/*` (9 tracked files) - deleted
- `quickshell/.config/quickshell/modules/CavaService.qml` - reworded 2 citations of the retired applet's own `lib/cava.ts`
- `quickshell/.config/quickshell/modules/Overview.qml` - reworded 1 literal `ags-media` citation
- `quickshell/.config/quickshell/modules/bar/BarRoles.qml` - reworded 1 literal `ags-media` citation
- `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` - reworded citation of the retired applet's own `lib/media.ts`
- `quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml` - reworded 1 literal `ags-media` citation
- `quickshell/.config/quickshell/shell.qml` - reworded the Super+M comment's "retiring AGS media card" citation
- `quickshell/.config/quickshell/shortcuts.json` - reworded the same citation in the shortcut description
- `quickshell/.config/systemd/user/quickshell.service` - dropped "AGS media applet" from the autostart enumeration comment
- `.gitignore` - removed the now-dead `ags/.config/ags/@girs/` entry

## Decisions Made

- **Task 1 gate ran iteratively, not as a single frozen-tree judgment.** 12 defects were found and fixed live across 10 commits. `21-GATE-02-RECORD.md` records this honestly rather than claiming the "commit judged" guarantee its own template implies — every row was re-verified **after** its fix landed, and the interlock (`git diff --quiet 5f38a49 -- quickshell/.config/quickshell/`) is what Task 3 actually rests on, not the claim that the tree never moved.
- **Task 2:** operator selected "proceed" — deletion authorised.
- **Task 3 scope expansion (see Deviations):** the plan's own Step 3 comment-rewrite list named only `windowrules.lua` (8 sites), `theme-parity` (1 site), and `MediaTab.qml` ("several" — turned out to be zero, already cleaned during Task 1's gate fixes). Re-running `retirement-check ags` after Step 2–6's edits found 4 more failing blocking-domain classes (`keybinds`, `checker-internals`, `cross-package-refs`, `systemd-units`) touching 11 more files the plan's list never named. Closed all of them, following this repo's own RETIRE-07 precedent (`ada405a`, "close blocking hits") rather than landing a registry flip that reads `retired` while the tool's own full scan would still say otherwise.
- **Host package removal deferred.** `aylurs-gtk-shell` (3.1.2-1) is still installed; this session has no interactive sudo password. Per standing rule 8, completed the repo-side deletion and reported the host step as outstanding rather than guessing at how to bypass the missing credential.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1/Rule 2 - Bug/Missing-critical] Closed out-of-plan blocking-domain retirement-check hits before flipping the registry to retired**
- **Found during:** Task 3, after completing the plan's own enumerated Step 2/3 edits
- **Issue:** The plan's Step 3 comment-rewrite list named only `windowrules.lua`, `theme-parity`, and `MediaTab.qml`. Re-running `retirement-check ags` (status flipped to `retired`) surfaced 4 more failing blocking-domain classes: `keybinds.lua:236`, `motion-lint:417/1133`, `quickshell-doctor:11/2961`, `CavaService.qml`, `MediaBackend.qml`, `shell.qml`, `shortcuts.json`, `quickshell.service`, `contract.sh` — plus three literal `ags-media` namespace-string hits in `Overview.qml`, `BarRoles.qml`, `WorkspaceTile.qml` that the plan's own automated `<verify>` grep for `ags-media` (repo-wide, not file-scoped) would itself have failed on had they been left. This repo has an established precedent for exactly this situation: commit `ada405a` (RETIRE-07, wlogout/eww) explicitly closed "two out-of-plan reference classes... to bring each registry row's blocking tier to zero once flipped to `retired`" — the same D-18-37/RETIRE-01 "before/after requirement" this task's own registry flip triggers.
- **Fix:** Reworded each comment site so the finding survives and the name goes (same discipline as the plan's own explicit Step 3 sites); removed the dead `ags/*.scss` motion-lint EXEMPTIONS entry and `$HOME/.config/ags` ROOTS entry (same treatment RETIRE-04/RETIRE-05 gave their own now-dead entries).
- **Files modified:** `hypr/.config/hypr/config/keybinds.lua`, `hypr/.config/hypr/scripts/motion-lint`, `hypr/.config/hypr/scripts/quickshell-doctor`, `quickshell/.config/quickshell/modules/CavaService.qml`, `quickshell/.config/quickshell/modules/Overview.qml`, `quickshell/.config/quickshell/modules/bar/BarRoles.qml`, `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml`, `quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml`, `quickshell/.config/quickshell/shell.qml`, `quickshell/.config/quickshell/shortcuts.json`, `quickshell/.config/systemd/user/quickshell.service`, `theme-engine/.config/theme-engine/lib/contract.sh`, `.gitignore`
- **Verification:** `retirement-check ags` (status=retired) went from `failed_classes=4` to `failed_classes=1` (the one remaining is host-runtime state, see Issue #3 below, not a repo-file fix). Repo-wide `grep -rn "ags-media"` (the plan's own literal automated check) returns 0 hits.
- **Committed in:** `5cb32ed` (part of the single Task 3 commit)

**2. [Rule 1 - Bug] Corrected my own self-inflicted live-desktop theme mutation**
- **Found during:** Task 3, while running `theme-stress-test` as a post-edit verification step
- **Issue:** I ran `theme-stress-test` to double-check the `contract.json`/`theme-parity` edits, not realising the script performs a REAL live `theme-apply` on the operator's running desktop (no dry-run mode). It applied `catppuccin`, then aborted on switch #1 (`theme-doctor` strict-exit check failing — a git-status-dirty false alarm from this task's own in-progress uncommitted edits, not a real theme defect). The operator's desktop was left on `catppuccin` instead of their prior `materialyou`.
- **Fix:** Identified the pre-existing theme (`materialyou`, confirmed from the last successful 10-switch stress run's postcondition, logged earlier the same day) and ran `theme-apply materialyou` to restore it — the same sanctioned mechanism, not a workaround.
- **Files modified:** none (runtime state only — `~/.local/state/theme/current-theme` and its rendered outputs)
- **Verification:** `cat ~/.local/state/theme/current-theme` now reads `materialyou`; quickshell PID unchanged throughout (1668601), confirming no crash/restart occurred.
- **Note for future executors:** `theme-stress-test` is NOT report-only — it mutates the live desktop theme. Use `theme-parity` (genuinely report-only, renders to isolated temp dirs) for contract/format verification instead. This mirrors standing rule 5's "don't restart Quickshell / probe shells" spirit even though the rule's literal text didn't name this specific script.

---

**Total deviations:** 2 — 1 auto-fixed scope-closure (11 files, matching an established repo precedent), 1 self-corrected mistake (no lasting effect).
**Impact on plan:** The scope-closure deviation was necessary for the registry flip to be honest rather than vacuous, and is bounded by direct precedent already established in this exact repo. The theme-stress-test mistake was corrected before it could affect the operator; no residual state changed.

## Issues Encountered

**Host package removal outstanding.** `aylurs-gtk-shell` (3.1.2-1, official AUR package, confirmed via `pacman -Qi`, no reverse dependencies — `Required By: None`, `Optional For: None`) is still installed on this host. `sudo pacman -Rns aylurs-gtk-shell` requires an interactive password this session does not have (`sudo -n` confirmed no passwordless sudo configured). Per standing rule 8, the repo-side deletion was completed and this step is reported as outstanding rather than guessed at.

**Operator action needed:**
```bash
sudo pacman -Rns aylurs-gtk-shell
```
This will also naturally clear the one remaining `retirement-check ags` failure — a live systemd transient scope (`app-Hyprland-ags-656e39eb.scope`) tied to the still-running AGS process (PID 1606, invoked ~5.5h before this commit, presumably left running from the Task 1 gate's live side-by-side comparison). `retirement-check`'s `host-package` class currently reports "no references" for `ags` even though the real package IS installed — this is the documented vacuous-pass the plan itself warned about (`pacman -Q ags` fails since no package is literally named `ags`; the class queries the surface token, not the real package name). Verified independently via the real package name; do not trust that class's PASS here.

**Pre-existing, out-of-scope findings** (not touched, not caused by this task):
- `theme-doctor`'s folded `retirement-check --all` shows `waybar` at `failed_classes=2` (`keybinds`, `cross-package-refs`) — unrelated to this task, no waybar file was touched.
- `hypr-equivalence-check` reports `binds.json: differs from baseline` — the Super+M bind added by Plan 21-07 (a prior plan) is not yet marked "accepted" against the Phase-13.1 baseline. This task's own comment-only edit to that same `keybinds.lua` line did not change the bind's modmask/key/keycode/dispatcher.
- `quickshell-doctor`'s two pre-existing failures (`bar-reserved-zone-stability`, `permissions-allowlist-paths-resolve`) — already flagged in `21-GATE-02-RECORD.md` as "Plan 09's business", unrelated to media/AGS.

All three left for Plan 09 (the "every gate green with committed evidence" plan referenced in `21-GATE-02-RECORD.md`).

## Known Stubs

None.

## User Setup Required

**Manual host action required — cannot be automated from this session:**
```bash
sudo pacman -Rns aylurs-gtk-shell
```
Verification after running it:
```bash
pacman -Q aylurs-gtk-shell   # should fail (package not found)
DOTFILES_DIR=~/dotfiles hypr/.config/hypr/scripts/retirement-check ags   # should print failed_classes=0
```

## Next Phase Readiness

- Repo-side RETIRE-06/RETIRE-08 work is complete and committed. `retirement-check ags` is clean except for host-runtime state (transient systemd scope) tied to the pending package removal above.
- Phase 22 (fresh-install proof) will need the host package removal completed first, or it will inherit `aylurs-gtk-shell` as a stray installed-but-unreferenced package on this specific host — not a repo defect, but worth confirming before that phase's fresh-install verification runs.
- Plan 09 ("every gate green with committed evidence") should pick up: the pre-existing `waybar` retirement-check gap, the `hypr-equivalence-check` Super+M baseline-acceptance gap, and `quickshell-doctor`'s two flaky/pre-existing failures — none introduced by this plan.

---
*Phase: 21-media-fold-in-contract-close*
*Completed: 2026-08-16*

## Self-Check: PASSED

- FOUND: `theme-engine/.config/theme-engine/contract.json`
- FOUND: `hypr/.config/hypr/scripts/tests/test-media-hardening.sh`
- FOUND: `hypr/.config/hypr/scripts/media-art-resolve.sh` (retained, executable)
- FOUND: `.planning/phases/21-media-fold-in-contract-close/21-PRE-DELETION-SWEEP.txt`
- CONFIRMED: `ags/` absent from working tree
- FOUND: commit `5cb32ed` in `git log --oneline --all`
