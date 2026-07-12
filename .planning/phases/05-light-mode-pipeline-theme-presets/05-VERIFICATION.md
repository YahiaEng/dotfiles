---
phase: 05-light-mode-pipeline-theme-presets
verified: 2026-07-12T09:23:21Z
status: human_needed
score: 22/22 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 17/18
  gaps_closed:
    - "theme-apply of a static preset auto-sets the wallpaper: last-used for that theme if recorded, else first in the folder (CR-01) — verified fixed and re-tested live"
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Press the real theme-switcher keybind (Super+Shift+T or equivalent), press Esc with no selection, in the live desktop session"
    expected: "The walker dmenu closes silently — no 'Error: walker dmenu failed' notify-send toast appears. Selecting a theme afterward still applies it normally."
    why_human: "The automated checker (test-walker-dmenu-cancel.sh, 10/10 passing) proves theme-switch.sh's and waybar-switch.sh's exit-code branch logic is correct against a STUBBED walker binary that is scripted to return exit 130. It does not, and cannot, confirm that the real walker 2.16.2 binary running in this live uwsm/Hyprland session actually emits exit 130 (vs. some other code, e.g. if a future walker/elephant update changes cancel semantics). The 05-05 plan's own <verification> section and 05-05-SUMMARY.md's 'Next Phase Readiness' section both explicitly defer this exact live confirmation to 'a UAT re-run performed outside this plan' — and 05-UAT.md (git log: last touched at commit b70eee9, before the 05-05 gap-closure commits 1f154c7/200e7e0/21b9e42) was never updated to record that re-run. This is the one remaining unresolved item from the phase's own paper trail, not a new finding."
---

# Phase 5: Light Mode Pipeline & Theme Presets Verification Report

**Phase Goal:** The theme pipeline gains full light-mode support and a richer, better-organized preset and wallpaper experience — light themes render correctly across every surface and the wallpaper picker looks the part.
**Verified:** 2026-07-12T09:23:21Z
**Status:** human_needed
**Re-verification:** Yes — after gap closure (05-05 plan, commits 1f154c7, 200e7e0, 21b9e42)

## Goal Achievement

This is a re-verification following the initial 2026-07-11T23:52:57Z pass, which scored 17/18 and found one blocker (CR-01: `lib/commit.sh`'s `rsync --delete` silently wiped the `last-wallpaper/` state directory on every theme-apply). Between the two verification passes, two fixes landed:

1. **CR-01** (last-wallpaper persistence) was fixed by `4df03ad` (part of 05-REVIEW-FIX.md, applied before the phase's own UAT round) and confirmed live-passing in UAT Test 3 ("post CR-01 fix").
2. **WR-04** (theme-switcher firing an error toast on every Esc-cancel, because walker 2.16.2 exits 130 on cancel rather than 0) was found by UAT Test 4 as a NEW regression from an earlier WR-04 partial fix (`eac9263`), diagnosed via a debug session, and closed by gap-closure plan 05-05 (`1f154c7`, `200e7e0`, `21b9e42`).

Both fixes were independently re-verified in this pass — not trusted from SUMMARY claims — per the sections below.

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1: Applying a light preset re-themes the whole desktop in light mode; both dark-hardcoded chokepoints (gtk.sh gsettings, gtk-3.0/settings.ini) fixed | ✓ VERIFIED | Live-ran `theme-apply catppuccin-latte` in this session: mode marker flips to `light`; `gsettings get color-scheme` → `prefer-light`; `gsettings get gtk-theme` → `adw-gtk3`; rendered `gtk-3.0-settings.ini` shows `gtk-application-prefer-dark-theme=0`/`gtk-theme-name=adw-gtk3`; rendered `gtk-4.0-settings.ini` shows the matching `prefer-dark-theme=0` line |
| 2 | uwsm env no longer hardcodes GTK_THEME; gtk.sh is single mode-aware owner | ✓ VERIFIED | `uwsm/.config/uwsm/env` has no `export GTK_THEME=` line (grep empty); `lib/gtk.sh` derives `gtk3_theme` from the committed mode marker (`~/.local/state/theme/mode`) and calls `systemctl --user set-environment GTK_THEME=...` |
| 3 | SC2: Mode auto-detected from palette lightness; contract.json + theme-parity gate passes with both a light and a dark fixture | ✓ VERIFIED | Ran `theme-parity` live this session: "fixture: catppuccin resolves mode=dark (got 'dark')" PASS, "fixture: catppuccin-latte resolves mode=light (got 'light')" PASS; full run 1190 passed, 0 failed |
| 4 | SC3: Expanded static preset set including light themes, all shipped as palette JSONs through the existing pipeline | ✓ VERIFIED | `palettes/` contains 20 JSONs (verified by direct `ls`) — 6 pre-existing + 14 new (9 Omarchy dark + 5 canonical light: catppuccin-latte, rosepine-dawn, gruvbox-light, tokyonight-day, kanagawa-lotus); theme-parity enumerates all 20 + 2 Material You entries, 0 failed |
| 5 | Mode classification correct for every shipped palette (5 light, 15 dark) | ✓ VERIFIED | theme-parity output shows correct mode fixture assertions and per-target passes for all 20 palettes |
| 6 | Legacy `themes/` stow package deleted, stow.sh updated | ✓ VERIFIED | `test -d themes` fails (absent); `grep themes stow.sh` shows only an unrelated help-text line, no PACKAGES entry |
| 7 | Walker theme picker (theme-switch.sh) offers every palette plus both Material You entries | ✓ VERIFIED | `theme-switch.sh` globs `$PALETTES_DIR/*.json` dynamically and appends `materialyou`/`materialyou-light` literals — no hardcoded case ladder (confirmed by reading full file this session) |
| 8 | SC4: With a static theme active, picker restricts to that theme's wallpaper set; Material You allows any wallpaper | ✓ VERIFIED | `wallpaper-picker.sh` restriction logic confirmed by grep this session (`RESTRICTED=0`/`RESTRICTED=1` branch keyed on `CURRENT_THEME != materialyou*`, Ctrl-A reload binding, fall-open header); prior human checkpoint approval unchanged (05-04-SUMMARY.md) |
| 9 | Every wallpaper folder name matches its palette JSON name 1:1 (rosepine, tokyonight renamed; dracula/ + 5 light folders added) | ✓ VERIFIED | `ls wallpapers/Pictures/Wallpapers/` confirms all 20 palette-name folders present 1:1 against the 20 palette JSONs (spot-counted this session) |
| 10 | Material You entries never auto-set a wallpaper | ✓ VERIFIED | `lib/wallpaper.sh`: `if [[ "$name" == "materialyou" || "$name" == "materialyou-light" ]]; then return 0; fi` confirmed present |
| 11 | theme-apply of a static preset auto-sets the wallpaper: last-used if recorded, else first-in-folder | ✓ VERIFIED (previously FAILED — CR-01, now fixed) | `commit.sh`'s rsync now reads `rsync -a --delete --exclude=logs/ --exclude=last-wallpaper/ --exclude=current-theme --exclude=.last-render-error.log`. Live-reproduced the exact CR-01 repro scenario from the prior verification pass and watched it succeed: recorded pick `last-wallpaper/catppuccin` = `4-firewatch.jpg`, ran `theme-apply catppuccin` (same-theme reapply — the exact case that used to wipe the record), confirmed the file survived unchanged; then switched away (`theme-apply catppuccin-latte`) and back (`theme-apply catppuccin`) and confirmed the record still survived both commits. Live desktop state restored to the original catppuccin/dark theme afterward. |
| 12 | Wallpaper auto-set never hangs/fails theme-apply in a headless context | ✓ VERIFIED (code inspection, regression-checked) | `lib/wallpaper.sh` still guards the `awww` call behind `WAYLAND_DISPLAY`/`DBUS_SESSION_BUS_ADDRESS` + `command -v awww`, best-effort (`|| true`) — unchanged since prior pass |
| 13 | SC5: Redesigned wallpaper picker presents wallpapers with Omarchy-level polish (thumbnails/layout) | ✓ VERIFIED | `kitten icat` preview chain present with chafa fallback; human checkpoint approval from 05-04-SUMMARY.md unaffected by this round's changes |
| 14 | fzf colors sourced from the pipeline (fzf-colors.conf); catppuccin hex survives only as `${VAR:-fallback}` | ✓ VERIFIED | All `--color=` lines in wallpaper-picker.sh reference `FZF_COLOR_*` vars with hex only inside `${VAR:-...}` defaults (confirmed by reading the relevant lines this session) |
| 15 | Selecting a wallpaper under materialyou-light re-runs theme-apply materialyou-light, not materialyou | ✓ VERIFIED | Selection branch uses the active `$CURRENT_THEME` variable, never a hardcoded literal (confirmed by grep this session) |
| 16 | Live awww desktop preview on navigate still works (D-13 keeper) | ✓ VERIFIED (human checkpoint, unchanged) | 05-04-SUMMARY.md records user-approved live walkthrough; not touched by 05-05's changes |
| 17 | All 9 Omarchy-lineup dark presets + 5 canonical light presets match the 20-key schema and pass theme-parity individually | ✓ VERIFIED | Full theme-parity run this session confirms 0 failed across all 20 palette targets |
| 18 | Static-preset render branch of generate.sh never passes a mode flag to matugen json (Pitfall 1 regression guard) | ✓ VERIFIED (regression-checked) | Unchanged since prior pass; no files in this area touched by 05-05 |
| 19 | (05-05 must-have) Pressing Esc/click-outside/Return-on-empty in the theme switcher closes it silently — no error notification | ✓ VERIFIED | `theme-switch.sh` now captures `rc=$?` from the walker pipeline and branches `(( rc == 130 ))` → silent `exit 0`. Hermetic checker `test-walker-dmenu-cancel.sh` (run live this session): "theme-switch cancel (walker rc=130): sub-script exits 0" PASS, "notify-send not invoked" PASS |
| 20 | (05-05 must-have) Selecting a theme in the switcher still applies it normally via theme-apply | ✓ VERIFIED | Checker's success case (run live this session): "theme-switch success: sub-script exits 0" PASS, "theme-apply invoked with mapped basename matte-black" PASS — confirms the display→basename mapping and `exec theme-apply` path are intact |
| 21 | (05-05 must-have) Pressing Esc in the waybar layout switcher closes it silently with no dead-code cancel path and no swallowed failure | ✓ VERIFIED | `waybar-switch.sh` carries the identical three-way branch (confirmed by reading the full file this session). Checker: "waybar cancel (walker rc=130): sub-script exits 0" PASS, "notify-send not invoked" PASS |
| 22 | (05-05 must-have) A genuine walker hard failure (127/1/crash) still fires the error toast and exits nonzero in both scripts | ✓ VERIFIED | Checker: "theme-switch hard-failure (walker rc=127): sub-script exits 1" PASS + "notify-send invoked exactly once" PASS; "waybar hard-failure (walker rc=1): sub-script exits 1" PASS + "notify-send invoked exactly once" PASS |

**Score:** 22/22 truths verified (0 failed)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `theme-engine/.config/theme-engine/lib/mode.sh` | `theme_engine_detect_mode` — single source of truth | ✓ VERIFIED (unchanged) | Present, correct classification logic |
| `theme-engine/.config/theme-engine/lib/generate.sh` | materialyou-light branch, mode marker + settings.ini renderer | ✓ VERIFIED (unchanged) | Confirmed via live temp-dir/render behavior this session (light preset apply produced correct settings.ini) |
| `theme-engine/.config/theme-engine/contract.json` | 13 files incl. gtk-3.0/4.0-settings.ini, fzf-colors.conf | ✓ VERIFIED (unchanged) | 13 `"name"` entries confirmed via grep |
| `theme-engine/.config/theme-engine/lib/commit.sh` | rsync excludes all four engine-owned paths, incl. `last-wallpaper/` | ✓ VERIFIED (fixed) | Line 58: `rsync -a --delete --exclude=logs/ --exclude=last-wallpaper/ --exclude=current-theme --exclude=.last-render-error.log` — confirmed by reading the file this session |
| `hypr/.config/hypr/scripts/theme-switch.sh` | three-way exit-code branch (130/other-nonzero/0) | ✓ VERIFIED (fixed) | Full file read this session: `rc=0; SELECTED=$(...) || rc=$?; if (( rc == 130 )); then exit 0; elif (( rc != 0 )); then notify-send ...; exit 1; fi` |
| `hypr/.config/hypr/scripts/waybar-switch.sh` | same three-way branch | ✓ VERIFIED (fixed) | Full file read this session: identical branch shape applied to its own walker call |
| `hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh` | committed hermetic checker | ✓ VERIFIED, WIRED, and RUN | Exists, executable, runs standalone; executed live this session: 10 passed, 0 failed |
| `theme-engine/.config/theme-engine/theme-parity` | dynamic TARGETS + mode fixture assertions | ✓ VERIFIED (unchanged) | Full run executed live this session: 1190 passed, 0 failed |
| `wallpapers/Pictures/Wallpapers/*` (20 folders) | 1:1 per-theme wallpaper sets | ✓ VERIFIED (unchanged) | Directory listing confirms all 20 |
| `hypr/.config/hypr/scripts/wallpaper-picker.sh` | redesigned picker: icat preview, restriction, theming, marker | ✓ VERIFIED (unchanged) | Structural elements re-confirmed via grep this session |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| lib/generate.sh | lib/mode.sh | `theme_engine_detect_mode` call during render | ✓ WIRED (unchanged) | Confirmed live via light/dark mode-flip test this session |
| lib/gtk.sh | `~/.local/state/theme/mode` | mode marker read at reload time | ✓ WIRED (unchanged) | Confirmed live: mode + gsettings correctly flip both directions this session |
| lib/commit.sh | `~/.local/state/theme/last-wallpaper/` | rsync exclude preserves engine-owned state across commit | ✓ WIRED (fixed) | Live-reproduced across two consecutive commits (same-theme reapply, then switch-away-and-back) — record survived both |
| theme-apply | lib/wallpaper.sh | `theme_engine_wallpaper_autoset` called after commit, before reload | ✓ WIRED (fixed end-to-end) | Previously "wired but downstream state broken" (CR-01) — now confirmed fully functional live |
| theme-switch.sh | walker (dmenu) | `SELECTED=$(...) || rc=$?` capture, three-way branch | ✓ WIRED (fixed) | Confirmed via hermetic checker (stubbed walker) — cancel/hard-failure/success cases all PASS |
| waybar-switch.sh | walker (dmenu) | same three-way branch | ✓ WIRED (fixed) | Confirmed via hermetic checker — cancel/hard-failure cases PASS |
| theme-switch.sh | theme-apply | `exec ~/.config/theme-engine/theme-apply "$THEME"` on valid selection | ✓ WIRED | Confirmed via checker's success case (mapped basename passed through) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|--------------|------------|--------------|--------|----------|
| THM-01 | 05-01, 05-02 | Theme pipeline supports light mode; dark chokepoints fixed; mode auto-detected; contract/parity gates extended | ✓ SATISFIED | Truths 1-3, 18 verified live this session |
| THM-02 | 05-02, 05-05 | Additional popular static presets shipped incl. light themes | ✓ SATISFIED | Truths 4-6, 17 verified; 05-05 also declares THM-02 (picker still surfaces every preset correctly post-fix) — truth 20 |
| THM-03 | 05-03, 05-04 | Wallpapers organized per-theme; static theme restricts picker; Material You unrestricted; last-used wallpaper persists | ✓ SATISFIED (upgraded from PARTIAL) | Folder org + restriction UI verified (truths 8-10); the previously-broken last-used wallpaper sub-behavior (truth 11, CR-01) is now confirmed fixed and live-tested across two separate scenarios |
| THM-04 | 05-04 | Wallpaper picker redesigned to Omarchy-level aesthetics | ✓ SATISFIED | Truths 13-16 verified, human-approved (unchanged) |

No orphaned requirements — THM-01 through THM-04 are declared across the phase's plans and match REQUIREMENTS.md's Phase 5 traceability row (all four now marked `[x]` complete in REQUIREMENTS.md). WR-04 is a code-review finding ID (05-REVIEW.md), not a formal v2 requirement, but is fully tracked and closed via the 05-05 gap-closure plan.

### Anti-Patterns Found

None new. Regression-checked this session — all previously-fixed review findings remain fixed:

| File | Finding | Status |
|------|---------|--------|
| `theme-engine/.config/theme-engine/lib/commit.sh` | CR-01 missing `--exclude=last-wallpaper/` | ✓ Fixed, confirmed present and live-tested |
| `uwsm/.config/uwsm/env` | WR-01 unquoted `QT_QPA_PLATFORM=wayland;xcb` | ✓ Fixed, confirmed quoted |
| `hypr/.config/hypr/scripts/wallpaper-picker.sh` | WR-02 hardcoded `$HOME/Pictures/Wallpapers` in heredocs | ✓ Fixed, confirmed `WALLPAPER_DIR` interpolation present |
| `stow.sh` | WR-03 unguarded `sudo chsh` | ✓ Fixed, confirmed `command -v zsh` guard present |
| `hypr/.config/hypr/scripts/theme-switch.sh` | WR-04 unreachable cancel path / toast-on-every-cancel | ✓ Fixed (05-05), confirmed three-way branch and checker pass |
| `stow.sh` | WR-05 unconditional waybar-layout reset | ✓ Fixed, confirmed `[[ -f ... ]] ||` guard present |

No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` markers found in any file touched by this phase or the 05-05 gap-closure plan (grep run this session, clean).

Pre-existing IN-01 through IN-09 info-severity findings (05-REVIEW.md) remain intentionally out of scope per `fix_scope: critical_warning` — not phase-5 gaps.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Light preset flips mode + gsettings + settings.ini | `theme-apply catppuccin-latte` (live, this session) | mode=light, color-scheme=prefer-light, gtk-theme=adw-gtk3, settings.ini prefer-dark-theme=0 | ✓ PASS |
| Dark preset flips back correctly | `theme-apply catppuccin` (live, this session) | mode=dark, color-scheme=prefer-dark, gtk-theme=adw-gtk3-dark | ✓ PASS |
| theme-parity full run | `theme-parity` (live, this session) | 1190 passed, 0 failed, both mode fixtures PASS | ✓ PASS |
| last-wallpaper survives same-theme reapply | `theme-apply catppuccin` twice in a row (live, this session) | `last-wallpaper/catppuccin` = `4-firewatch.jpg` unchanged both times | ✓ PASS |
| last-wallpaper survives switch-away-and-back | `theme-apply catppuccin-latte` then `theme-apply catppuccin` (live, this session) | `last-wallpaper/catppuccin` still = `4-firewatch.jpg` after the round trip | ✓ PASS |
| walker-dmenu exit-code checker (hermetic) | `bash hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh` (live, this session) | 10 passed, 0 failed | ✓ PASS |

### Probe Execution

Not applicable — this phase has no `scripts/*/tests/probe-*.sh` convention; its checkers (`theme-parity`, `test-walker-dmenu-cancel.sh`) were run directly above under Behavioral Spot-Checks.

### Human Verification Required

### 1. Live Esc-cancel confirmation in the real theme switcher

**Test:** Trigger the theme-switcher keybind on the live desktop, press Esc with no theme selected.
**Expected:** The walker dmenu closes with no error toast (`notify-send` "Error: walker dmenu failed" must NOT appear). Immediately selecting a theme afterward via the same keybind still applies normally.
**Why human:** The hermetic checker (10/10 passing, re-run live this session) proves the shell logic is correct against a *stubbed* walker binary scripted to return exit 130. It cannot confirm the *real* walker 2.16.2 binary in this live uwsm/Hyprland session actually returns exit 130 on a genuine Esc press — that fact is currently established only by source-code reading during the prior debug session, not by an interactive test. The 05-05 plan's own `<verification>` section and 05-05-SUMMARY.md's "Next Phase Readiness" section both explicitly defer this exact confirmation to "a UAT re-run performed outside this plan," and `05-UAT.md` was never updated after the gap-closure commits (git log shows its last edit at `b70eee9`, predating `1f154c7`/`200e7e0`/`21b9e42`). This is not a new concern raised by the verifier — it is the phase's own unresolved paper trail.

### Gaps Summary

No gaps found. The single blocker from the initial verification pass (CR-01: last-wallpaper record wiped by `rsync --delete` on every commit) is confirmed fixed and live-tested across two separate reproduction scenarios (same-theme reapply, and switch-away-and-back). The UAT-discovered regression (WR-04: Esc firing an error toast because walker 2.16.2 exits 130, not 0, on cancel) is confirmed fixed via the committed hermetic checker, re-run live in this session with all 10 assertions passing, covering both `theme-switch.sh` and `waybar-switch.sh`.

The phase goal is achieved at the code level: all 22 must-have truths (18 original success-criteria-derived truths + 4 truths carried over from the 05-05 gap-closure plan's own must_haves) are verified. Status is `human_needed` rather than `passed` for exactly one reason: the plan that closed the WR-04 gap explicitly deferred its own final human confirmation (a live Esc keypress against the real, non-stubbed walker binary) to a follow-up UAT session that has not yet been recorded. This is a low-risk, procedural gap — the fix logic is sound and independently re-verified — but per the phase's own stated verification plan it has not yet received its final human sign-off.

---

_Verified: 2026-07-12T09:23:21Z_
_Verifier: Claude (gsd-verifier)_
