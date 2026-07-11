---
phase: 05-light-mode-pipeline-theme-presets
verified: 2026-07-11T23:52:57Z
status: gaps_found
score: 17/18 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "theme-apply of a static preset auto-sets the wallpaper: last-used for that theme if recorded, else first in the folder (05-03 must_have D-11/D-12; 05-04 must_have 'Selecting a wallpaper from the active static theme's folder records it as that theme's last-used wallpaper')"
    status: failed
    reason: >
      Live-reproduced on this machine (not just code review). `lib/commit.sh`'s
      `rsync -a --delete --exclude=logs/ --exclude=current-theme
      --exclude=.last-render-error.log` has no `--exclude=last-wallpaper/`.
      `last-wallpaper/` is engine-owned state (written by lib/wallpaper.sh and
      wallpaper-picker.sh) that is never part of the matugen-rendered tree, so
      rsync's `--delete` treats it as extraneous and deletes the entire
      directory on every single `theme_engine_commit` — i.e. on every
      theme-apply, including a repeat apply of the SAME theme (commit runs
      before wallpaper_autoset reads the file). Directly reproduced: recorded
      last-wallpaper/catppuccin=4-firewatch.jpg, then re-ran
      `theme-apply catppuccin` (no theme switch) — the explicit recorded pick
      was silently discarded and replaced by the first-sorted image
      (1-totoro.png). Live desktop state was restored after the test. This is
      code-review finding CR-01 (05-REVIEW.md, critical), confirmed live by
      the verifier, not merely a review claim.
    artifacts:
      - path: "theme-engine/.config/theme-engine/lib/commit.sh"
        issue: "rsync --delete lacks --exclude=last-wallpaper/, so the D-11 per-theme last-used wallpaper memory is wiped on every commit and can never persist across a theme-apply"
    missing:
      - "Add --exclude=last-wallpaper/ to the rsync invocation in lib/commit.sh (theme_engine_commit), mirroring the existing logs/ and current-theme excludes"
      - "Re-verify: record a last-used pick, re-apply the same theme (or switch away and back), and confirm the recorded pick is honored instead of falling back to first-in-folder"
human_verification: []
---

# Phase 5: Light Mode Pipeline & Theme Presets Verification Report

**Phase Goal:** The theme pipeline gains full light-mode support and a richer, better-organized preset and wallpaper experience — light themes render correctly across every surface and the wallpaper picker looks the part.
**Verified:** 2026-07-11T23:52:57Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1: Applying a light preset re-themes the whole desktop in light mode; both dark-hardcoded chokepoints (gtk.sh gsettings, gtk-3.0/settings.ini) fixed | ✓ VERIFIED | Live-ran `theme-apply catppuccin-latte`: `~/.local/state/theme/mode`=`light`; `gsettings get color-scheme`=`prefer-light`; `gsettings get gtk-theme`=`adw-gtk3`; rendered `gtk-3.0-settings.ini` contains `gtk-application-prefer-dark-theme=0`/`gtk-theme-name=adw-gtk3`; rendered `gtk-4.0-settings.ini` contains the matching dark-theme=0 line |
| 2 | uwsm env no longer hardcodes GTK_THEME; gtk.sh is single mode-aware owner | ✓ VERIFIED | `uwsm/.config/uwsm/env` has no `export GTK_THEME=` line; `lib/gtk.sh` derives `gtk3_theme` from the committed mode marker and calls `systemctl --user set-environment GTK_THEME=...` |
| 3 | SC2: Mode auto-detected from palette lightness; contract.json + theme-parity gate passes with both a light and a dark fixture | ✓ VERIFIED | Ran `./theme-parity` live: "fixture: catppuccin resolves mode=dark (got 'dark')" PASS, "fixture: catppuccin-latte resolves mode=light (got 'light')" PASS; all 22 targets (20 palettes + materialyou/materialyou-light) individually assert a `mode` file of light\|dark; full run: 1190 passed, 0 failed |
| 4 | SC3: Expanded static preset set including light themes, all shipped as palette JSONs through the existing pipeline | ✓ VERIFIED | `palettes/` contains 20 JSONs (6 pre-existing + 14 new: 9 Omarchy dark + 5 canonical light — catppuccin-latte, rosepine-dawn, gruvbox-light, tokyonight-day, kanagawa-lotus); theme-parity's dynamic enumeration covers all 20 + 2 Material You entries, 0 failed |
| 5 | Mode classification correct for every shipped palette (5 light, 15 dark) | ✓ VERIFIED | theme-parity output shows correct light/dark mode file for all 20 individually-listed palettes; matches the exact 5-light/15-dark split specified in the plan |
| 6 | Legacy `themes/` stow package deleted, stow.sh updated | ✓ VERIFIED | `themes/` does not exist in repo; `stow.sh` PACKAGES array has no `themes` entry |
| 7 | Walker theme picker (theme-switch.sh) offers every palette plus both Material You entries | ✓ VERIFIED | `theme-switch.sh` globs `palettes/*.json` dynamically and appends `materialyou`/`materialyou-light` literals — no hardcoded case ladder |
| 8 | SC4: With a static theme active, picker restricts to that theme's wallpaper set; Material You allows any wallpaper | ✓ VERIFIED | `wallpaper-picker.sh` mode-selection logic confirmed by grep (restricted/fall-open/standard header branches, `maxdepth 2` full enumeration, `ctrl-a:` reload binding); further confirmed via the plan's human checkpoint (05-04-SUMMARY.md: user approved the 8-step walkthrough covering restriction, Ctrl-A, fall-open, and Material You full-browse) |
| 9 | Every wallpaper folder name matches its palette JSON name 1:1 (rosepine, tokyonight renamed; dracula/ + 5 light folders added) | ✓ VERIFIED | `wallpapers/Pictures/Wallpapers/` listing confirms `rosepine/`, `tokyonight/` (no dashed originals), `dracula/`, and all 5 light-variant folders present |
| 10 | Material You entries never auto-set a wallpaper | ✓ VERIFIED | `lib/wallpaper.sh`: `if [[ "$name" == "materialyou" || "$name" == "materialyou-light" ]]; then return 0; fi` — early-return confirmed by grep and reasoning over the code path |
| 11 | theme-apply of a static preset auto-sets the wallpaper: last-used if recorded, else first-in-folder | ✗ FAILED | See `gaps` above (CR-01) — live-reproduced: a recorded last-used pick is silently discarded and replaced by the first-sorted image on the very next theme-apply of the same theme, because `commit.sh`'s `rsync --delete` wipes `last-wallpaper/` on every commit |
| 12 | Wallpaper auto-set never hangs/fails theme-apply in a headless context | ✓ VERIFIED (code inspection) | `lib/wallpaper.sh` guards the `awww` call behind a `WAYLAND_DISPLAY`/`DBUS_SESSION_BUS_ADDRESS` check + `command -v awww`, all best-effort (`|| true`); same shape as the pre-existing `reload.sh` headless guard |
| 13 | SC5: Redesigned wallpaper picker presents wallpapers with Omarchy-level polish (thumbnails/layout) | ✓ VERIFIED | `kitten icat --clear --transfer-mode=memory --unicode-placeholder` present with chafa fallback chain; human checkpoint in 05-04-SUMMARY.md records user approval of the pixel-perfect preview, metadata line, and active marker |
| 14 | fzf colors sourced from the pipeline (fzf-colors.conf); catppuccin hex survives only as `${VAR:-fallback}` | ✓ VERIFIED | All `--color=` lines in wallpaper-picker.sh reference `FZF_COLOR_*` vars with catppuccin hex only inside `${VAR:-...}` defaults (grep-confirmed, no bare literal `--color=` lines) |
| 15 | Selecting a wallpaper under materialyou-light re-runs theme-apply materialyou-light, not materialyou | ✓ VERIFIED | Selection branch: `if [[ "$CURRENT_THEME" == "materialyou" \|\| "$CURRENT_THEME" == "materialyou-light" ]]; then ... theme-apply "$CURRENT_THEME"` — uses the active variable, never a hardcoded literal |
| 16 | Live awww desktop preview on navigate still works (D-13 keeper) | ✓ VERIFIED (human checkpoint) | 05-04-SUMMARY.md records user-approved live walkthrough step 3 ("Navigate with arrows — the desktop behind live-previews each highlighted wallpaper") |
| 17 | All 9 Omarchy-lineup dark presets + 5 canonical light presets match the 20-key schema and pass theme-parity individually | ✓ VERIFIED | Full theme-parity run confirms structural/semantic pass for every one of the 20 palette targets, 0 failed |
| 18 | Static-preset render branch of generate.sh never passes a mode flag to matugen json (Pitfall 1 regression guard) | ✓ VERIFIED | `grep -E '^\s*if ! matugen json' lib/generate.sh` shows no `-m` flag on that invocation |

**Score:** 17/18 truths verified (1 failed — see Gaps)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `theme-engine/.config/theme-engine/lib/mode.sh` | `theme_engine_detect_mode` — single source of truth | ✓ VERIFIED | Present, correct classification logic (materialyou literals, JSON override, colorsys lightness fallback) |
| `theme-engine/.config/theme-engine/lib/generate.sh` | materialyou-light branch, mode marker + settings.ini renderer | ✓ VERIFIED | Confirmed via live temp-dir behavior and contract.json entries |
| `theme-engine/.config/theme-engine/contract.json` | 12→13 files incl. gtk-3.0/4.0-settings.ini, fzf-colors.conf; mode in state_metadata_files | ✓ VERIFIED | `jq '.files | map(.name)'` lists all 13 entries |
| `theme-engine/.config/theme-engine/palettes/catppuccin-latte.json` | light fixture palette, 20-key schema | ✓ VERIFIED | Present, classifies light, passes theme-parity |
| `theme-engine/.config/theme-engine/palettes/vantablack.json` | representative Omarchy dark preset | ✓ VERIFIED | Present, classifies dark, passes theme-parity |
| `theme-engine/.config/theme-engine/theme-parity` | dynamic TARGETS + mode fixture assertions | ✓ VERIFIED | Dynamic glob enumeration confirmed; fixture PASS lines observed live |
| `theme-engine/.config/theme-engine/lib/wallpaper.sh` | `theme_engine_wallpaper_autoset` — per-theme wallpaper selection + last-used state | ⚠️ WIRED BUT BROKEN | Function exists, is called correctly from theme-apply, and its own logic (bare-filename validation, keep-current on empty folder, materialyou no-op) is sound in isolation — but the last-used branch never actually persists across a commit due to CR-01 in commit.sh (a sibling file), so the "last-used" half of its contract cannot function end-to-end |
| `wallpapers/Pictures/Wallpapers/rosepine` | renamed per-theme wallpaper set | ✓ VERIFIED | Exists with prior contents; `rose-pine` gone |
| `wallpapers/Pictures/Wallpapers/catppuccin-latte` | light-variant wallpaper folder | ✓ VERIFIED | Exists (empty, `.gitkeep`) |
| `matugen/.config/matugen/templates/fzf-colors.conf` | FZF_COLOR_* render template | ✓ VERIFIED | 13 shell-sourceable vars render correctly; sourced and validated live |
| `hypr/.config/hypr/scripts/wallpaper-picker.sh` | redesigned picker: icat preview, restriction, theming, marker | ✓ VERIFIED | All structural elements present; visually approved by human checkpoint |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| lib/generate.sh | lib/mode.sh | `theme_engine_detect_mode` call during render | ✓ WIRED | Confirmed via source + live temp-dir render |
| lib/gtk.sh | `~/.local/state/theme/mode` | mode marker read at reload time | ✓ WIRED | Confirmed live: mode flips to light/dark correctly on theme-apply |
| lib/commit.sh | `~/.config/gtk-3.0/settings.ini` | `ln -sf` into state dir | ✓ WIRED | Confirmed: symlink resolves to `~/.local/state/theme/gtk-3.0-settings.ini` |
| theme-parity | palettes/ | glob enumeration builds TARGETS | ✓ WIRED | Confirmed via full-run output naming all 20 palettes + 2 Material You entries |
| theme-switch.sh | palettes/ | dynamic list generation | ✓ WIRED | Confirmed via grep — no hardcoded case ladder |
| theme-apply | lib/wallpaper.sh | `theme_engine_wallpaper_autoset` called after commit, before reload | ✓ WIRED (but downstream state broken) | Call site confirmed; underlying last-used persistence broken by CR-01 in a different file (commit.sh) |
| lib/wallpaper.sh | `~/.local/state/theme/last-wallpaper/<preset>` | atomic temp+mv write | ⚠️ WRITE-ONLY | Write succeeds, but the very next `theme_engine_commit` (called before the next autoset) deletes the whole `last-wallpaper/` directory — the write is effectively discarded before it can ever be read back |
| wallpaper-picker.sh | `~/.local/state/theme/fzf-colors.conf` | sourced at startup with fallback | ✓ WIRED | Confirmed via live source test |
| wallpaper-picker.sh | theme-apply | re-runs active dynamic variant on selection | ✓ WIRED | Confirmed via grep of selection branch |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|--------------|------------|--------------|--------|----------|
| THM-01 | 05-01, 05-02 | Theme pipeline supports light mode; dark chokepoints fixed; mode auto-detected; contract/parity gates extended | ✓ SATISFIED | Truths 1-3, 18 verified live |
| THM-02 | 05-02 | Additional popular static presets shipped incl. light themes | ✓ SATISFIED | Truths 4-6, 17 verified |
| THM-03 | 05-03, 05-04 | Wallpapers organized per-theme; static theme restricts picker; Material You unrestricted | ⚠️ PARTIALLY SATISFIED | Folder org + restriction UI verified (truths 8-10), but the last-used wallpaper sub-behavior explicitly required by the 05-03/05-04 plans' own must_haves (D-11) is broken (truth 11 FAILED) |
| THM-04 | 05-04 | Wallpaper picker redesigned to Omarchy-level aesthetics | ✓ SATISFIED | Truths 13-16 verified, human-approved |

No orphaned requirements — all 4 phase requirement IDs (THM-01 through THM-04) are declared across the 4 plans and match REQUIREMENTS.md's Phase 5 traceability row exactly.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `theme-engine/.config/theme-engine/lib/commit.sh` | 53-55 | Missing `--exclude=last-wallpaper/` on `rsync --delete` | 🛑 Blocker | Silently defeats the D-11 last-used wallpaper feature end-to-end (see Gaps) |
| `hypr/.config/hypr/scripts/wallpaper-picker.sh` | 173, 212, 235 | Hardcoded `$HOME/Pictures/Wallpapers` duplicated in PREVIEW/LIVE heredocs instead of interpolating `$WALLPAPER_DIR` | ⚠️ Warning | Maintainability only — currently correct because the constant hasn't changed; would silently desync if `WALLPAPER_DIR` is ever edited (review WR-02, not a truth failure today) |
| `hypr/.config/hypr/scripts/theme-switch.sh` | 1, 42-43 | No `set -euo pipefail`; a failed `walker --dmenu` invocation looks like a silent user-cancel | ⚠️ Warning | UX robustness gap introduced/touched by this phase (05-02 modified this file); does not block any stated phase truth today (review WR-04) |

Pre-existing issues flagged by 05-REVIEW.md but NOT introduced by this phase (verified via `git log --follow`, unmodified by phase 5's diffs to those files): WR-01 (`uwsm/env` unquoted `QT_QPA_PLATFORM=wayland;xcb`), WR-03 (`stow.sh` unguarded `sudo chsh`), WR-05 (`stow.sh` unconditional waybar-layout reset). Not counted as phase-5 gaps since they predate this phase's edits to those files, but noted for completeness.

### Human Verification Required

None outstanding — the two behaviors that require human judgment (picker visual polish, live awww preview) were already exercised and approved during phase execution via the Plan 05-04 Task 4 human checkpoint, recorded in 05-04-SUMMARY.md with explicit `human_judgment: true` coverage entries. No further human verification items were identified.

### Gaps Summary

One blocker: `lib/commit.sh`'s `rsync -a --delete` is missing `--exclude=last-wallpaper/`, so the entire `last-wallpaper/` state directory is deleted on every `theme_engine_commit` — which fires on every single `theme-apply`, including a repeat apply of the same theme. This directly falsifies the must-have truth (declared by both 05-03-PLAN.md and 05-04-PLAN.md) that a static theme's auto-set wallpaper prefers the last-used pick when one is recorded: the record never survives to be read. I reproduced this live on the machine (not just relying on 05-REVIEW.md's finding): recorded a pick, re-applied the same theme with no intervening switch, and watched the pick get silently discarded in favor of the first-sorted image. Live desktop state was restored afterward.

This is a one-line fix (add `--exclude=last-wallpaper/` to the rsync invocation, mirroring the existing `logs/` and `current-theme` excludes) with an existing, well-understood template in the same file's own comments (the file documents fixing this exact bug class twice already for `logs/` and `current-theme`). Everything else in the phase — light-mode propagation (gtk.sh/settings.ini/uwsm-env), mode auto-detection with contract/parity light+dark fixtures, the 14 new palette JSONs, wallpaper folder reorganization, the restriction/fall-open picker UI, and the Omarchy-level picker redesign — is verified working, live-tested, or human-approved.

---

_Verified: 2026-07-11T23:52:57Z_
_Verifier: Claude (gsd-verifier)_
