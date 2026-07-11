---
phase: 05-light-mode-pipeline-theme-presets
reviewed: 2026-07-12T00:00:00Z
depth: standard
files_reviewed: 30
files_reviewed_list:
  - hypr/.config/hypr/scripts/theme-switch.sh
  - hypr/.config/hypr/scripts/wallpaper-picker.sh
  - matugen/.config/matugen/config.toml
  - matugen/.config/matugen/templates/fzf-colors.conf
  - stow.sh
  - theme-engine/.config/theme-engine/contract.json
  - theme-engine/.config/theme-engine/lib/commit.sh
  - theme-engine/.config/theme-engine/lib/contract.sh
  - theme-engine/.config/theme-engine/lib/generate.sh
  - theme-engine/.config/theme-engine/lib/gtk.sh
  - theme-engine/.config/theme-engine/lib/mode.sh
  - theme-engine/.config/theme-engine/lib/wallpaper.sh
  - theme-engine/.config/theme-engine/palettes/catppuccin-latte.json
  - theme-engine/.config/theme-engine/palettes/ethereal.json
  - theme-engine/.config/theme-engine/palettes/everfrost.json
  - theme-engine/.config/theme-engine/palettes/gruvbox-light.json
  - theme-engine/.config/theme-engine/palettes/hackerman.json
  - theme-engine/.config/theme-engine/palettes/kanagawa-lotus.json
  - theme-engine/.config/theme-engine/palettes/kanagawa.json
  - theme-engine/.config/theme-engine/palettes/matte-black.json
  - theme-engine/.config/theme-engine/palettes/miasma.json
  - theme-engine/.config/theme-engine/palettes/osaka-jade.json
  - theme-engine/.config/theme-engine/palettes/ristretto.json
  - theme-engine/.config/theme-engine/palettes/rosepine-dawn.json
  - theme-engine/.config/theme-engine/palettes/tokyonight-day.json
  - theme-engine/.config/theme-engine/palettes/vantablack.json
  - theme-engine/.config/theme-engine/theme-apply
  - theme-engine/.config/theme-engine/theme-parity
  - theme-engine/.config/theme-engine/theme-stress-test
  - uwsm/.config/uwsm/env
findings:
  critical: 1
  warning: 5
  info: 9
  total: 15
status: issues_found
---

# Phase 5: Code Review Report

**Reviewed:** 2026-07-12
**Depth:** standard
**Files Reviewed:** 30
**Status:** issues_found

## Summary

Reviewed the light-mode pipeline + theme-presets implementation: the theme-engine libraries (mode detection, generate, commit, GTK propagation, wallpaper autoset), the two Hyprland picker scripts, the matugen config + new fzf template, the output contract and its two verification harnesses, all 14 new palette JSONs, `stow.sh`, and the uwsm env file.

The palette layer is clean: all 20 palettes (14 new) parse as valid JSON, share an identical 21-key color set, contain only well-formed `#rrggbb` values, and every light preset's background clears the `l > 0.5` detection threshold in `lib/mode.sh` (verified by script, not by eye). The engine's atomic render-then-commit shape, name validation before path interpolation, and notification sanitization are all sound.

One critical defect was found: `commit.sh`'s `rsync --delete` erases the engine's own `last-wallpaper/` state directory on every theme switch — the exact bug class the file's own comment documents fixing for `logs/` (D-40) — which silently defeats the per-theme last-wallpaper memory feature (D-11) end-to-end. Five warnings cover a malformed uwsm env assignment that executes a stray token as a command at session start, path-constant duplication inside the picker's embedded scripts, and robustness gaps in `stow.sh` and `theme-switch.sh`.

## Critical Issues

### CR-01: `rsync --delete` in commit.sh wipes `last-wallpaper/` state on every theme switch, defeating the D-11 last-wallpaper feature

**File:** `theme-engine/.config/theme-engine/lib/commit.sh:53-55`
**Issue:** The atomic commit runs:

```bash
rsync -a --delete --exclude=logs/ --exclude=current-theme \
    --exclude=.last-render-error.log \
    "$rendered_dir"/ "$STATE_DIR"/
```

`$STATE_DIR/last-wallpaper/` (written by `lib/wallpaper.sh:15,80-82` and `wallpaper-picker.sh:23,342-344`) is engine-owned state that is **never part of the rendered tree** — matugen and `generate.sh` never produce it. So `--delete` treats it as extraneous and deletes the whole directory on **every** `theme_engine_commit`. This is the identical bug class the comment block at lines 30-44 documents root-causing and fixing for `logs/` (D-40) and for `current-theme` (WR-02) — `last-wallpaper/` was simply missed when it was added in this phase.

Concrete broken flows (traced through `theme-apply`):
1. User picks wallpaper w3 for theme A via the picker → `last-wallpaper/A` records w3. User switches to theme B → commit deletes `last-wallpaper/` entirely. User switches back to A → `theme_engine_wallpaper_autoset` finds no record (`wallpaper.sh:49`) and falls back to the first sorted image. The recorded pick is permanently lost.
2. Even re-applying the **same** theme loses the record: in `theme-apply`, `theme_engine_commit` (line 82) runs **before** `theme_engine_wallpaper_autoset` (line 87), so the record is deleted before autoset reads it — and the desktop wallpaper is actively reverted to the first-sorted image, discarding the user's explicit choice.

The picker-side recording (`wallpaper-picker.sh:339-346`) is therefore effectively write-only; the feature can never work across two switches.

**Fix:**
```bash
rsync -a --delete --exclude=logs/ --exclude=last-wallpaper/ \
    --exclude=current-theme --exclude=.last-render-error.log \
    "$rendered_dir"/ "$STATE_DIR"/
```
Consider also inverting the model to future-proof it: rsync the rendered tree into the state dir and delete only files that are members of `contract.json`'s file list plus `mode`, so newly added engine-owned state can never be silently destroyed by a missing exclude again (third occurrence of this bug class).

## Warnings

### WR-01: Unquoted `;` in uwsm env assignment truncates `QT_QPA_PLATFORM` and executes `xcb` as a command at session start

**File:** `uwsm/.config/uwsm/env:7`
**Issue:** `export QT_QPA_PLATFORM=wayland;xcb` — this file is sourced as shell by uwsm. The unquoted `;` is a command separator: the line sets `QT_QPA_PLATFORM=wayland` (losing the intended `xcb` fallback for Qt apps without Wayland support) and then attempts to **execute `xcb` as a command** on every session startup ("command not found" noise at best; would run an attacker-planted `xcb` from a writable PATH dir at worst).
**Fix:**
```bash
export QT_QPA_PLATFORM="wayland;xcb"
```

### WR-02: Picker's embedded preview/live scripts hardcode the wallpaper path instead of using `$WALLPAPER_DIR`

**File:** `hypr/.config/hypr/scripts/wallpaper-picker.sh:173,212,235`
**Issue:** The main script defines `WALLPAPER_DIR="$HOME/Pictures/Wallpapers"` (line 19) and correctly interpolates it into the ENUM heredoc (line 84). But the PREVIEW and LIVE heredocs are quoted (`<< 'PREVIEW'`, `<< 'LIVE'`) and independently hardcode `FILE="$HOME/Pictures/Wallpapers/$ENTRY"` and `CURRENT_LINK="$HOME/Pictures/Wallpapers/current.jpg"`. If `WALLPAPER_DIR` is ever changed at the top, the list/selection logic follows but previews, live-set, and the active-marker line silently break (preview scripts `exit 0` on the failed `-f` test — no error surfaces). Three divergent copies of one path constant is exactly the duplication-site problem this phase's D-01 discipline removes elsewhere.
**Fix:** Interpolate the resolved dir into both heredocs the same way ENUM does, e.g. start each generated script with an interpolated `WALLPAPER_DIR="$WALLPAPER_DIR"` line (unquoted heredoc delimiter for that first line, or `printf` a prologue) and use `$WALLPAPER_DIR` inside.

### WR-03: `sudo chsh` in stow.sh is unguarded — any failure aborts the script before the first-boot theme seed

**File:** `stow.sh:93`
**Issue:** `sudo chsh -s "$(which zsh)" "$USER"` runs under `set -euo pipefail` with no fallback. If zsh is not yet installed, `$(which zsh)` expands empty and `chsh -s ""` fails; if sudo is unavailable/non-interactive or the user's password entry is locked, `sudo` fails. Either way `set -e` aborts stow.sh **after** stowing but **before** the "Seed first-boot theme baseline" step (lines 103-112), leaving a fresh system with no `~/.local/state/theme/` — the exact first-impression failure that seed step exists to prevent. The shell change is cosmetic relative to the seed and shouldn't be able to torpedo it. (`which` is also non-POSIX; `command -v` is the robust form.)
**Fix:**
```bash
if command -v zsh >/dev/null 2>&1; then
    sudo chsh -s "$(command -v zsh)" "$USER" || echo "  ⚠ chsh failed — change shell manually" >&2
else
    echo "  ⚠ zsh not installed — skipping shell change" >&2
fi
```

### WR-04: theme-switch.sh has no error handling — a failed walker invocation is a silent successful no-op

**File:** `hypr/.config/hypr/scripts/theme-switch.sh:1,42-43`
**Issue:** Unlike every sibling script in this phase (`wallpaper-picker.sh`, `stow.sh`, `theme-apply` all use `set -euo pipefail`), this script sets no shell options. If `walker --dmenu` fails outright (walker not running/installed, elephant socket dead — a failure mode CLAUDE.md explicitly calls out), `$SELECTED` is empty and line 43 `exit 0`s: user presses the keybind, nothing happens, no notification, exit code claims success. Cancellation and hard failure are indistinguishable.
**Fix:** Add `set -euo pipefail`; capture walker's exit status separately from empty selection, e.g.:
```bash
if ! SELECTED=$(printf '%s\n' "${DISPLAYS[@]}" | walker --dmenu --placeholder "Select Theme"); then
    notify-send -a "Theme Switcher" "Error" "walker dmenu failed" -i dialog-error 2>/dev/null || true
    exit 1
fi
[[ -z "$SELECTED" ]] && exit 0   # genuine user cancel
```

### WR-05: stow.sh unconditionally resets the waybar layout cache on every re-run

**File:** `stow.sh:87`
**Issue:** `echo "full" > "$HOME/.cache/current-waybar-layout"` runs unconditionally. stow.sh is explicitly designed to be re-runnable (`--restow`, the "no pointless .bak churn" comment at lines 43-47), but every re-run clobbers the user's currently selected waybar layout back to "full". Initialization should only seed when absent.
**Fix:**
```bash
[[ -f "$HOME/.cache/current-waybar-layout" ]] || echo "full" > "$HOME/.cache/current-waybar-layout"
```

## Info

### IN-01: Stale file-count comment in contract.sh

**File:** `theme-engine/.config/theme-engine/lib/contract.sh:20-21`
**Issue:** `contract_files` doc comment says "the 10 matugen-rendered state-dir files"; contract.json now declares 13 files (11 matugen-rendered + 2 engine-rendered settings.ini). A wrong count in the single-source-of-truth reader invites future off-by-N confusion.
**Fix:** Update the comment, or drop the number entirely ("the contract-declared state-dir files").

### IN-02: `theme_engine_gtk4_accent` Python calls `rgb_to_hls` three times and binds an unused variable

**File:** `theme-engine/.config/theme-engine/lib/gtk.sh:225`
**Issue:** `h, s, l = colorsys.rgb_to_hls(r, g, b)[0], colorsys.rgb_to_hls(r, g, b)[2], colorsys.rgb_to_hls(r, g, b)[1]` computes the conversion three times and `l` is never used afterwards.
**Fix:** `h, _l, s = colorsys.rgb_to_hls(r, g, b)`.

### IN-03: Divergent display-name logic between theme-switch.sh and wallpaper-picker.sh

**File:** `hypr/.config/hypr/scripts/theme-switch.sh:18-27` / `hypr/.config/hypr/scripts/wallpaper-picker.sh:45-59`
**Issue:** The picker special-cases upstream branding ("Rosé Pine Dawn", "Tokyo Night Day"); the theme switcher's `prettify` shows the same themes as "Rosepine Dawn" / "Tokyonight Day". Two UIs render the same theme under different names, and the mapping logic is duplicated rather than shared.
**Fix:** Extract one `theme_display_name` helper (e.g. into a sourceable engine lib) and use it in both scripts.

### IN-04: `PREVIOUS_FILE` is written and deleted but never read — dead state file

**File:** `hypr/.config/hypr/scripts/wallpaper-picker.sh:22,39,296,311,349`
**Issue:** `~/.cache/wallpaper-picker-previous` is written at startup and removed on every exit path, but restore-on-cancel uses the in-memory `$PREVIOUS_WALLPAPER` variable; nothing in the repo reads the file (verified by grep). Dead code unless a crash-recovery consumer is planned.
**Fix:** Remove the file writes/deletes, or document the external consumer that reads it.

### IN-05: theme-stress-test crashes with a bash arithmetic error if the palettes dir is empty

**File:** `theme-engine/.config/theme-engine/theme-stress-test:341`
**Issue:** `${STATIC_PRESETS[$(( static_idx % ${#STATIC_PRESETS[@]} ))]}` — with zero palette files the modulo is a division by zero, aborting under `set -e` with an opaque bash error instead of a clear diagnostic (theme-parity has the equivalent loud guard for an empty contract list at lines 109-112).
**Fix:** After building the array: `(( ${#STATIC_PRESETS[@]} > 0 )) || { echo "theme-stress-test: no palettes found in $PALETTES_DIR" >&2; exit 1; }`.

### IN-06: Misleading errexit comment in `check_theme_doctor`

**File:** `theme-engine/.config/theme-engine/theme-stress-test:222-231`
**Issue:** The comment claims a failing `VAR=$(cmd)` inside the function would abort the script despite the caller testing the function in an `if`. Bash suppresses errexit for the entire call tree executed in a condition context, so the `set +e`/`set -e` toggle is harmless but the justification is wrong — future readers may cargo-cult the wrong mental model.
**Fix:** Correct the comment (keep the toggle as belt-and-suspenders if desired).

### IN-07: Commit-phase failure in theme-apply exits silently with no desktop notification

**File:** `theme-engine/.config/theme-engine/theme-apply:82`
**Issue:** A render failure produces a sanitized `notify-send` (lines 65-79), but if `theme_engine_commit` fails (missing rendered dir, rsync error) `set -e` aborts with stderr only — a keybind-invoked run gives the user zero feedback and possibly a half-updated state dir. Inconsistent failure UX for the later, more dangerous stage.
**Fix:** Wrap the commit call like the generate call: `if ! theme_engine_commit "$NAME" "$TMP_DIR"; then notify-send ... ; exit 1; fi`.

### IN-08: Thunar visible-window invariant silently degrades to an immediate kill when hyprctl/jq are unavailable

**File:** `theme-engine/.config/theme-engine/lib/gtk.sh:64-73,119`
**Issue:** If `hyprctl` or `jq` is missing (or `hyprctl clients` errors), `thunar_has_window` stays 0 and the code proceeds to `thunar --quit` / `killall -9` — closing a visible window, the exact outcome the surrounding design fights to avoid. Same shape in the deferred watcher (lines 173-179). Both tools exist on this host, but the failure direction of the guard is "kill" rather than "skip".
**Fix:** Treat detection-tool absence/failure as "assume a window is open" (defer) rather than "assume none".

### IN-09: theme-parity's shared render log keeps only the last failure across its 22 renders

**File:** `theme-engine/.config/theme-engine/theme-parity:37` / `theme-engine/.config/theme-engine/lib/generate.sh:52-53,63`
**Issue:** Every `matugen` invocation truncates (`2>"$GENERATE_LOG"`) the single `theme-parity-render-error.log`, so when multiple targets fail in one run only the final target's stderr survives — the earlier failures' diagnostics are lost even though each produced a distinct FAIL line.
**Fix:** Append per-target (`2>>"$GENERATE_LOG"` with a target header) or interpolate the target name into the log path for parity runs.

---

_Reviewed: 2026-07-12_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
