---
phase: 05-light-mode-pipeline-theme-presets
fixed_at: 2026-07-12T00:00:00Z
review_path: .planning/phases/05-light-mode-pipeline-theme-presets/05-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 5: Code Review Fix Report

**Fixed at:** 2026-07-12
**Source review:** .planning/phases/05-light-mode-pipeline-theme-presets/05-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (fix_scope: critical_warning — 1 Critical + 5 Warnings)
- Fixed: 6
- Skipped: 0
- Out of scope: 9 Info findings (IN-01 through IN-09) — excluded by fix_scope, not attempted

## Fixed Issues

### CR-01: `rsync --delete` in commit.sh wipes `last-wallpaper/` state on every theme switch

**Files modified:** `theme-engine/.config/theme-engine/lib/commit.sh`
**Commit:** 4df03ad
**Applied fix:** Added `--exclude=last-wallpaper/` to the atomic-commit rsync (alongside the existing `logs/`, `current-theme`, and `.last-render-error.log` excludes) so the engine-owned D-11 per-theme last-wallpaper records survive every `theme_engine_commit`. Updated the D-40 comment block: removed the now-false "logs/ is the only engine-owned subdirectory" claim and documented this as the third occurrence of the missing-exclude bug class.

### WR-01: Unquoted `;` in uwsm env truncates `QT_QPA_PLATFORM` and executes `xcb` as a command

**Files modified:** `uwsm/.config/uwsm/env`
**Commit:** d3ae452
**Applied fix:** `export QT_QPA_PLATFORM=wayland;xcb` → `export QT_QPA_PLATFORM="wayland;xcb"`. The full `wayland;xcb` fallback list is now preserved and no stray `xcb` command runs at session start.

### WR-02: Picker's embedded preview/live scripts hardcode the wallpaper path

**Files modified:** `hypr/.config/hypr/scripts/wallpaper-picker.sh`
**Commit:** e365ec3
**Applied fix:** Both generated scripts now get an interpolated prologue — `printf '#!/usr/bin/env bash\nWALLPAPER_DIR=%q\n' "$WALLPAPER_DIR" > "$SCRIPT"` followed by `cat >>` of the original quoted heredoc — and the three hardcoded `$HOME/Pictures/Wallpapers` occurrences (`FILE=` in PREVIEW, `CURRENT_LINK=` in PREVIEW, `FILE=` in LIVE) now reference `$WALLPAPER_DIR`. `%q` keeps the interpolation safe against spaces/metacharacters. Verified the generated prologue parses cleanly with `bash -n`.

### WR-03: Unguarded `sudo chsh` in stow.sh can abort before the first-boot theme seed

**Files modified:** `stow.sh`
**Commit:** b1757be
**Applied fix:** Wrapped the shell change in a `command -v zsh` guard with an `|| echo warning` fallback on the `sudo chsh` call (per the review's suggested snippet), and switched from non-POSIX `which` to `command -v`. Neither a missing zsh nor a failed sudo/chsh can now abort the script under `set -e` before the theme-seed step.

### WR-04: theme-switch.sh silently exits 0 when walker fails

**Files modified:** `hypr/.config/hypr/scripts/theme-switch.sh`
**Commit:** eac9263
**Applied fix:** Added `set -euo pipefail`; replaced the `echo | walker` invocation with `if ! SELECTED=$(printf '%s\n' "${DISPLAYS[@]}" | walker --dmenu ...); then notify-send ... exit 1; fi`, keeping `[[ -z "$SELECTED" ]] && exit 0` for genuine user cancel. Audited the whole script for `set -u`/`set -e` safety: all variables are assigned before use, `NAMES`/`DISPLAYS` are never empty (the two materialyou literals are appended unconditionally before expansion), and the remaining `[[ ... ]] && exit` guards are exempt from errexit as non-final commands in AND lists.

**Note:** if walker's `--dmenu` mode returns nonzero on Esc-cancel (rather than exiting 0 with empty output), a user cancel would surface the error notification. The fix follows the review's prescribed pattern; worth a one-time manual keybind check (press Super+Shift+T, press Esc) to confirm cancel behavior.

### WR-05: stow.sh unconditionally resets the waybar layout cache on every re-run

**Files modified:** `stow.sh`
**Commit:** 30520b8
**Applied fix:** `echo "full" > ...` is now guarded with `[[ -f "$HOME/.cache/current-waybar-layout" ]] ||` so the layout is seeded only when the cache file is absent; re-runs no longer clobber the user's selected layout.

## Skipped Issues

None — all in-scope findings were fixed.

## Out of Scope (Info findings, not attempted)

IN-01 through IN-09 are Info-severity findings excluded by `fix_scope: critical_warning`. They remain open in 05-REVIEW.md: stale contract.sh comment (IN-01), redundant `rgb_to_hls` calls (IN-02), divergent display-name logic (IN-03), dead `PREVIOUS_FILE` state (IN-04), empty-palettes-dir crash in theme-stress-test (IN-05), misleading errexit comment (IN-06), silent commit-phase failure in theme-apply (IN-07), Thunar kill-on-missing-tools guard direction (IN-08), and theme-parity's truncating render log (IN-09).

## Verification

Every fix was verified in two tiers: (1) re-read of the modified section, (2) `bash -n` syntax check of the edited script (all passed; for WR-02 the generated inner-script prologue was additionally exercised standalone with `bash -n`). All six commits were made atomically, one per finding, on an isolated worktree branch fast-forwarded back into `main`; the working tree was clean after the final commit.

---

_Fixed: 2026-07-12_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
