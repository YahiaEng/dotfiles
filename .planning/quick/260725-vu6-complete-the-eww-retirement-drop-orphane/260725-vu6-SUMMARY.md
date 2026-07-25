---
phase: quick-260725-vu6
plan: 01
subsystem: theming
tags: [matugen, hyprland, stow, waybar, ags, shellcheck, jq]

requires: []
provides:
  - "theme-doctor and theme-parity no longer red on the orphaned eww.scss contract entry"
  - "eww fully retired from contract.json, lib/contract.sh, lib/reload.sh, stow.sh, install.sh, windowrules.conf, the repo tree, and this host's ~/.config"
  - "stale eww-referencing comments across matugen/autostart/media-status/waybar/ags corrected to describe the AGS media applet as it exists today"
affects: [theme-engine, stow, install, hyprland-windowrules, waybar, ags]

tech-stack:
  added: []
  patterns:
    - "contract.json files[] is the single source of truth theme-doctor/theme-parity both read via lib/contract.sh — removing an array entry removes the check entirely rather than flipping it to pass, so passed-count stays flat while failed-count drops."

key-files:
  created: []
  modified:
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/lib/contract.sh
    - theme-engine/.config/theme-engine/lib/reload.sh
    - stow.sh
    - install.sh
    - hypr/.config/hypr/config/windowrules.conf
    - matugen/.config/matugen/config.toml
    - hypr/.config/hypr/config/autostart.conf
    - hypr/.config/hypr/scripts/media-status.sh
    - waybar/.config/waybar/config-athena.jsonc
    - waybar/.config/waybar/style-athena.css
    - waybar/.config/waybar/config-vertical.jsonc
    - ags/.config/ags/style.scss

key-decisions:
  - "Unstowed eww on this host (stow -D) before git rm -r eww, per the plan's ordering requirement — stow.sh's PACKAGES/pre-create block and install.sh's AUR_PKGS entry were removed in the same task."
  - "Left ~/.cache/eww-media-player and ~/.cache/eww-media-art path literals untouched in media-players.sh/media-art-resolve.sh — live runtime state consumed by ags/lib/media.ts, out of scope to rename."
  - "theme-doctor's git-clean check is left failing (1/135) — caused by the user's own pre-existing uncommitted wallpaper/monitor changes, explicitly out of scope per the plan's constraints."

requirements-completed: [QUICK-EWW-RETIRE]

coverage: []

duration: ~20min
completed: 2026-07-25
status: complete
---

# Quick Task 260725-vu6: Complete the eww retirement, drop orphaned contract entry Summary

**Dropped the orphaned `eww.scss` contract entry (and its two dead format-parser branches plus a dead reload branch), unstowed and deleted the retired `eww` package/AUR dep/layerrules, and corrected every stale comment left dangling by the 10-06 retirement — clearing all 22 theme-parity failures and 1 of 2 theme-doctor failures.**

## Performance

- **Duration:** ~20 min
- **Tasks:** 3
- **Files modified:** 13 (3 in Task 1, 3 modified + 3 deleted in Task 2, 7 in Task 3)

## Accomplishments

- `theme-parity`: **1542 passed, 0 failed** (was 1542 passed, 22 failed)
- `theme-doctor`: **135 passed, 1 failed** (was 135 passed, 2 failed) — the one remaining failure is the pre-existing, out-of-scope `git status --porcelain is empty` check
- `eww` fully retired: gone from `contract.json`, `lib/contract.sh`, `lib/reload.sh`, `stow.sh`'s `PACKAGES` array and config-dir pre-create, `install.sh`'s `AUR_PKGS`, `windowrules.conf`'s layerrules, the repo tree (`eww/` deleted via `git rm -r`), and this host's `~/.config` (unstowed then `rmdir`'d)
- Every stale eww-referencing comment across `matugen/config.toml`, `autostart.conf`, `media-status.sh`, both waybar athena files, `config-vertical.jsonc`, and `ags/style.scss` rewritten to describe the current AGS media applet on its own terms

## Task Commits

1. **Task 1: Re-verify no live consumer, then cut the retired target out of the theme pipeline** — `cd4a1b2` (fix)
2. **Task 2: Remove the stow package, the AUR dependency, the inert layerrules — and unstow this host** — `bb76d29` (chore)
3. **Task 3: Sweep the stale comments and prove the retirement is complete** — `090d531` (docs)

## Files Created/Modified

- `theme-engine/.config/theme-engine/contract.json` — `files[]` 18 → 17 entries; removed the `eww.scss`/`scss-kv` entry (last array element, trailing comma fixed on `satty.toml`)
- `theme-engine/.config/theme-engine/lib/contract.sh` — removed both `scss-kv)` dispatcher branches (`contract_extract_names`, `contract_extract_values`); both LOUD `*)` catch-alls untouched
- `theme-engine/.config/theme-engine/lib/reload.sh` — removed the dead `eww reload` guarded block; exactly one blank line preserved between the swayosd block's closing `fi` and the AGS comment
- `stow.sh` — removed `eww` from `PACKAGES`; removed the `BAR-04/D-19` comment block + `mkdir -p "$HOME/.config/eww"`, restoring a single blank line between the gtk pre-create and the `for pkg` loop
- `install.sh` — removed the `Media center` comment block + `eww` from `AUR_PKGS`; `aylurs-gtk-shell`/AGS block left fully intact
- `hypr/.config/hypr/config/windowrules.conf` — removed the `eww-media-popup` blur rule + its 4-line comment, removed the matching `ignore_alpha 0.5` line, reworded the `ags-media` blur rule's comment to drop its dangling "eww-media-popup rule above" cross-reference; the `ignore_alpha 0.25`/`ags-media` comment block (which belongs to a different rule) and the `wleave` rules are untouched
- `eww/.config/eww/{eww.scss,eww.yuck,assets/blank.png}` — deleted (`git rm -r eww`) after `stow -D eww --target="$HOME"` unlinked the three host symlinks and the emptied `~/.config/eww` was `rmdir`'d
- `matugen/.config/matugen/config.toml` — reworded the AGS-template tombstone/reload-note comments to drop the eww naming and the now-nonexistent reload.sh branch reference
- `hypr/.config/hypr/config/autostart.conf` — reworded the AGS daemon rationale comment to stand on its own
- `hypr/.config/hypr/scripts/media-status.sh` — reworded the header comment: stdout is now described as consumed by `ags/lib/media.ts` (`STATUS_SH`), not an eww `deflisten` payload
- `waybar/.config/waybar/config-athena.jsonc`, `style-athena.css` — `custom/media` described as the AGS media applet opener, not the eww popup opener
- `waybar/.config/waybar/config-vertical.jsonc` — dropped the dangling reference to the deleted `eww.yuck` file from the icon-provenance note, kept the substantive point about the icon
- `ags/.config/ags/style.scss` — rewrote the import-depth comment (why this file's `@import` is 4 levels) and the card-border comment to stand on their own, without the eww/waybar contrast

## Task 1 Consumer Classification Table

| Location | Classification | Disposition |
|---|---|---|
| `theme-engine/.config/theme-engine/contract.json` (`files[]` last entry, `scss-kv`) | orphaned declaration, no live consumer (matugen template already removed 10-06) | removed (Task 1) |
| `theme-engine/.config/theme-engine/lib/contract.sh` (`scss-kv)` in `contract_extract_names`/`contract_extract_values`) | dead dispatcher branches, sole consumer was the contract entry above | removed (Task 1) |
| `theme-engine/.config/theme-engine/lib/reload.sh` (`command -v eww && pgrep -x eww` guarded block) | dead reload branch, no `eww` daemon left to reload | removed (Task 1) |
| `eww/.config/eww/{eww.scss,eww.yuck,assets/blank.png}` | retired package tree; `.yuck` header itself states it holds no active widgets | removed (Task 2) |
| `stow.sh` (`PACKAGES` array entry + `BAR-04/D-19` pre-create block) | live stow-package registration for the retired target | removed (Task 2) |
| `install.sh` (`AUR_PKGS` entry + comment block) | live AUR dependency for the retired target | removed (Task 2) |
| `hypr/.config/hypr/config/windowrules.conf` (`eww-media-popup` blur + `ignore_alpha 0.5` layerrules) | inert layerrules — no client claims the `eww-media-popup` namespace any more | removed (Task 2) |
| `waybar/.config/waybar/{config-athena.jsonc,style-athena.css,config-vertical.jsonc}` | **stale comments only** — confirmed no code path invokes the `eww` binary from any of them; `on-click` for `custom/media` is `ags request -i media toggle-media` (verified in `modules.jsonc`) | reworded (Task 3) |
| `ags/.config/ags/style.scss` | **stale comments only** — three comments explaining import-depth/border convention by contrast with the deleted eww.scss | reworded (Task 3) |
| `matugen/.config/matugen/config.toml`, `hypr/.config/hypr/config/autostart.conf`, `hypr/.config/hypr/scripts/media-status.sh` | **stale comments only** — rationale/provenance notes naming the retired toolkit or a now-removed reload branch | reworded (Task 3) |
| `hypr/.config/hypr/scripts/media-players.sh` (`SELECTED_FILE="$HOME/.cache/eww-media-player"`) | **live runtime `~/.cache/` path literal** — read/written by the AGS media stack via `ags/.config/ags/lib/media.ts` | **left untouched** (out of scope, residual) |
| `hypr/.config/hypr/scripts/media-art-resolve.sh` (`CACHE_DIR="$HOME/.cache/eww-media-art"`) | **live runtime `~/.cache/` path literal** — same as above | **left untouched** (out of scope, residual) |
| `ags/.config/ags/@girs/**` (vendored GTK typings) | incidental mixed-case substrings (`previewWidget`, `FocusNewWindows`) inside a 145k-line vendored tree, unrelated to the retired toolkit | not touched, correctly excluded from every sweep |

The mandatory `grep -rn` sweep for the retired binary invoked as a bare command word across `hypr/`, `waybar/`, `ags/`, `matugen/`, `install.sh`, `stow.sh` returned only the lines this plan removes (stow.sh `PACKAGES`, install.sh `AUR_PKGS`, windowrules.conf layerrules) — no other invocation exists anywhere in the repo.

## Enumerated Residual References (deliberate, out of scope)

1. `hypr/.config/hypr/scripts/media-players.sh:24` — `SELECTED_FILE="$HOME/.cache/eww-media-player"`
2. `hypr/.config/hypr/scripts/media-art-resolve.sh:20` — `CACHE_DIR="$HOME/.cache/eww-media-art"`

Both are live runtime state paths read and written today by the AGS media stack (`ags/.config/ags/lib/media.ts`). Renaming them is a runtime-state change outside this task's scope — it would silently reset the user's persisted player selection/art cache on next run. Left byte-for-byte unchanged, exactly as the plan's constraints require.

## Before/After Gate Numbers

| Gate | Before | After |
|---|---|---|
| `theme-doctor` | 135 passed, 2 failed | **135 passed, 1 failed** |
| `theme-parity` | 1542 passed, 22 failed | **1542 passed, 0 failed** |
| `theme-stress-test` | not run pre-task | run; aborted at switch #1 on the strict-exit-0 `theme-doctor` check (see below) |
| Broken symlinks under `~/.config` (maxdepth 3) | 2 (`hyprland.conf.bak`, `zen/.../lock`) | **2 — unchanged, no collateral damage** |
| `contract.json` `files[]` length | 18 | **17** |
| `hyprctl configerrors` | (not checked pre-task) | empty — no errors, before and after every reload in this plan |

**`theme-doctor` still reports exactly one failure, and it is not a regression:** `[FAIL] git status --porcelain is empty (/home/aorus/dotfiles stays clean)`. This is caused entirely by the user's own pre-existing uncommitted changes (`hypr/.config/hypr/config/monitors.conf`, numerous added/deleted files under `wallpapers/Pictures/Wallpapers/`, the deleted `.planning/HANDOFF.json`, and the untracked `csv` file) — none of which this plan touched, staged, or committed. This run never claims a fully green doctor.

**`theme-stress-test`** ran its precondition checks (all passed) and completed switch #1 (`theme-apply catppuccin` succeeded, reload fan-out clean including the zen-not-launched no-op), then aborted on its own strict gate `switch #1: theme-doctor passes (strict exit 0, D-66)` — which fails for the identical git-clean reason above, not for anything related to this retirement. Per the plan's own guidance this class of failure is pre-existing and out of scope; it was not chased further.

## Decisions Made

- Unstowed `eww` on this host (`stow -n -v -D` dry run confirmed only the 3 expected unlinks, then the real `stow -D`) **before** `git rm -r eww`, matching the plan's hard ordering requirement.
- Left the two `~/.cache/eww-media-*` path literals untouched — documented above as a deliberate, reported residual rather than silently renamed.
- `theme-doctor`'s git-clean failure is left exactly as found; no attempt was made to "fix" it by touching the user's unrelated dirty files.

## Deviations from Plan

### Auto-fixed Issues

None — Rules 1-3 were not triggered; every task executed as specified.

### Noted Discrepancies (documented, not corrected)

1. **Plan's top-level `<verification>` step 5 says `contract.json` `files[]` length should be 18** ("`jq . theme-engine/.config/theme-engine/contract.json` — valid JSON, `files[]` length 18"), which contradicts Task 1's own `<verify>`/`<done>` sections (both explicitly require **17**, "18 → 17 entries", "files[] holds 17 entries"). The actual, correct, and verified value is **17** — Task 1's more specific gate (and the actual math: removing one entry from 18 gives 17) is authoritative. Treated as a stale typo in the plan's summary verification block, not acted on.
2. **`sass --no-source-map "$HOME/.config/ags/style.scss" /dev/null`** (Task 3's third verify line) fails on this host: `Error: Can't find stylesheet to import` for the `@import "../../../../.local/state/theme/ags.scss"` line. Root-caused and confirmed **pre-existing and unrelated to Task 3's comment-only edit**: `~/.config/ags` is a whole-directory stow symlink (`~/.config/ags -> ../dotfiles/ags/.config/ags`), and bare `sass` CLI does not resolve that directory symlink when computing the relative import's base directory from a literal absolute path — it only resolves correctly when the process's actual working directory is obtained via `getcwd()` (e.g. `cd` into the real directory then pass a relative filename), which is exactly what AGS's own Go bundler does via `filepath.EvalSymlinks` before compiling (per the file's own comment, unedited in substance). Verified this is not a regression by testing the identical command against the pre-Task-3 file content (`git show HEAD~1:ags/.config/ags/style.scss`) copied to an unrelated path — it fails identically. Verified the SCSS content itself is valid by invoking `sass` from inside the real directory with a relative path (`cd "$HOME/.config/ags" && sass --no-source-map style.scss /dev/null`), which succeeds cleanly (only the expected deprecation warning, no error) — confirming the comment-only edit did not break compilation; only the literal verify command's invocation style (absolute path through a dir-folded stow symlink) doesn't match how `sass` or AGS actually resolve it. Not treated as a task failure per the "report, don't work around" instruction — no functional line was touched to "fix" this, since doing so would be outside Task 3's comment-only scope.

---

**Total deviations:** 0 auto-fixed. 2 discrepancies noted and reported per the constraints' "report, don't work around" instruction — neither required or received a code change.
**Impact on plan:** None on the plan's actual gates (theme-doctor/theme-parity/hyprctl configerrors/completion grep all pass as specified). Both discrepancies are documentation/verification-script artifacts, not functional regressions.

## Issues Encountered

None beyond the two noted discrepancies above.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- All three of this project's core regression gates are now trustworthy for eww-retirement purposes: `theme-parity` is fully green (0/22 failures), `theme-doctor`'s only remaining failure is the user's own pre-existing uncommitted dirt (unrelated, not to be "fixed" by an automated task), and `theme-stress-test` runs cleanly through its preconditions and first real switch before hitting that same pre-existing gate.
- STATE.md's "Open — carried into v3.0" blockers #1 (orphaned contract entry) and #3 (stale layerrules) are both fully resolved by this task and should be marked closed.
- Recommended next step for whoever picks this up: `git add`-and-commit the user's own pre-existing dirt (or explicitly decide to discard/relocate it) so `theme-doctor`'s git-clean check can finally pass too — that is a user decision, not something this task was authorized to make.

## Self-Check: PASSED

All 3 task commits (`cd4a1b2`, `bb76d29`, `090d531`) found in `git log --oneline --all`. All 13 modified files confirmed present on disk. `eww/` confirmed absent from the repo tree. `~/.config/eww` confirmed absent from the host.

---
*Quick task: 260725-vu6*
*Completed: 2026-07-25*
