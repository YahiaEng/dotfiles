---
phase: 06-themed-surfaces-utility-suite
verified: 2026-07-12T22:10:00Z
status: gaps_found
score: 8/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The user can invoke an icon-theme picker and a nerd-font switcher via their assigned keybinds"
    status: failed
    reason: "CR-02 (confirmed by direct grep): Super+Shift+Z (icon-theme-picker.sh) and Super+Shift+X (font-switcher.sh) are bound as direct `exec` targets in keybinds.conf. Both scripts are fzf-in-terminal pickers with no controlling TTY when launched this way — fzf silently fails, the `|| true` swallows the error, and the script exits 0 with nothing selected. The established pattern in this exact repo (wallpaper-switch.sh) wraps the fzf script in `uwsm app -- kitty --class ... -- script.sh` plus a matching windowrule; no such wrapper or windowrule exists for either new picker. Both UTIL-04 and UTIL-05's user-facing invocation is non-functional as wired, even though the underlying picker/state-write/gtk.sh/font.sh logic is correct."
    artifacts:
      - path: "hypr/.config/hypr/config/keybinds.conf"
        issue: "Lines 69, 71 bind directly to icon-theme-picker.sh / font-switcher.sh with no kitty wrapper or windowrule, unlike the wallpaper-switch.sh precedent this plan explicitly cites as its pattern"
      - path: "hypr/.config/hypr/scripts/icon-theme-picker.sh"
        issue: "fzf call has no TTY when launched via bare Hyprland exec"
      - path: "hypr/.config/hypr/scripts/font-switcher.sh"
        issue: "fzf call has no TTY when launched via bare Hyprland exec"
    missing:
      - "A launcher wrapper script (icon-theme-switch.sh / font-switch.sh mirroring wallpaper-switch.sh) that opens a floating kitty running the picker"
      - "keybinds.conf updated to exec the wrapper instead of the picker script directly"
      - "Matching windowrules for the two new floating kitty classes"
  - truth: "The chosen nerd font propagates to all four surfaces: kitty, vscodium, GTK, and waybar"
    status: failed
    reason: "CR-01 (confirmed by direct file read): all three waybar/style-*.css files @import the rendered waybar-font.css, then immediately declare their own local `* { font-family: \"FiraCode Nerd Font\", ... }` rule of equal specificity. CSS cascade rule: for equal-specificity selectors the later rule in document order wins, and @imported rules are inserted at the import position (i.e. before the file's own literal rule) — so the hardcoded literal always wins over the font-switcher's rendered value. Font switching never changes waybar's font on any of the three layouts; kitty/vscodium/GTK are correctly wired."
    artifacts:
      - path: "waybar/.config/waybar/style-full.css"
        issue: "Line 5: hardcoded font-family in `* {}` after both @imports, defeats waybar-font.css"
      - path: "waybar/.config/waybar/style-minimal.css"
        issue: "Same hardcoded font-family pattern"
      - path: "waybar/.config/waybar/style-floating.css"
        issue: "Same hardcoded font-family pattern"
    missing:
      - "Remove the font-family declaration from the local `* {}` block in all three style-*.css files so waybar-font.css is the sole owner"
  - truth: "The user can record a drag-selected screen region to video (screen/region recording per SHOT-03)"
    status: failed
    reason: "CR-03 (confirmed by direct file read): record-toggle.sh's region branch passes the geometry string directly as gpu-screen-recorder's `-w` value (`capture_args=(-w \"${target#region:}\")`). Per gpu-screen-recorder's documented CLI contract, `-w` only accepts a window id / monitor name / screen / focused / portal / the literal string `region` — a geometry string is not a valid `-w` value. Region capture requires `-w region -region WxH+X+Y`. Every drag-selected (non-full-monitor) recording will fail to start. Monitor-target recording is unaffected."
    artifacts:
      - path: "hypr/.config/hypr/scripts/record-toggle.sh"
        issue: "Line 177: region:* case builds capture_args=(-w \"$geometry\") instead of (-w region -region \"$geometry\")"
    missing:
      - "region:*) capture_args=(-w region -region \"${target#region:}\") ;;"
  - truth: "A fresh install.sh run completes end-to-end on a yay-based system without crashing partway through package cleanup (verify_packages, audio/dbus/swayosd service enablement, VSCodium extensions must all still run)"
    status: failed
    reason: "CR-04 (confirmed by direct grep): install.sh explicitly supports both paru and yay as AUR_HELPER (detected and used correctly for the install itself, line 281), but the orphan-removal and cache-clean cleanup steps hardcode the literal `paru` (lines 292, 296) instead of `$AUR_HELPER`. On a yay-only machine — the exact case the yay branch exists for — `paru` is not installed, the command fails, and `set -euo pipefail` aborts the whole script at that point, before swayosd/audio service enablement, VSCodium extension install, and verify_packages ever run. This directly undermines the project's Core Value (\"the whole setup reproduces from scratch with one script\") and this phase's own 06-01 must-have that install.sh reliably provisions every new Phase 6 dependency."
    artifacts:
      - path: "install.sh"
        issue: "Lines 292 and 296 call `paru -R --noconfirm ...` and `paru -Sc --noconfirm` literally instead of `\"$AUR_HELPER\"`"
    missing:
      - "Replace both literal `paru` invocations with `\"$AUR_HELPER\"`"
human_verification:
  - test: "Run hyprlock under a light theme (e.g. catppuccin-latte) and inspect the password-field placeholder text contrast"
    expected: "Placeholder text is legible against the themed input field in both light and dark themes"
    why_human: "WR-01 (confirmed by direct file read): hyprlock.conf line 177 hardcodes `placeholder_text = <span foreground=\"##a6adc8\">` — Catppuccin Mocha's subtext hex — while every other color in the file is a pipeline variable ($primary/$on_surface/etc). This is a literal-color leak that breaks the 'colors sourced live from the shared theme pipeline, verified under both light and dark' success criterion for this one field. Visual legibility on a light surface needs a human/screenshot check, but the code-level violation (hardcoded hex bypassing the render pipeline) is itself already confirmed, not merely suspected."
  - test: "Full end-to-end smoke test of hyprshot -> satty (region/window/full capture), gpu-screen-recorder monitor recording, hyprpicker, and the icon-theme/font pickers on a machine with all Phase 6 packages actually installed"
    expected: "Each Print-key capture opens satty with the frozen screenshot; monitor recording starts/stops via Alt+Print; color picker copies a hex and shows a swatch"
    why_human: "hyprshot, satty, gpu-screen-recorder, hyprpicker, wtype, and the new AUR icon themes are declared in install.sh but NOT installed on this dev/verification machine (per phase context) — code was verified against upstream CLI contracts and cross-referenced by the code review, but no live smoke test was possible in this environment."
---

# Phase 6: Themed Surfaces & Utility Suite Verification Report

**Phase Goal:** Every remaining desktop surface is redesigned and re-themed, and a full suite of everyday utility tools ships — all following the established @import-from-state-dir pattern and validated by theme-parity under both light and dark.
**Verified:** 2026-07-12T22:10:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | wlogout shows a modern center-bar HUD with sharp Nerd Font glyph buttons (no SVG assets), all 6 actions present, colors live from wlogout.css | ✓ VERIFIED | `wlogout/.config/wlogout/layout` — 6 actions with Nerd Font glyph `text` fields, uwsm-audited commands unchanged; `style.css` — center-bar button layout, no `background-image` rules; `wlogout/.config/wlogout/icons` directory confirmed deleted; `style.css` line 1 still `@import url("../../.local/state/theme/wlogout.css")` |
| 2 | hyprlock sources its own dedicated render target, shows info-rich indicators (now-playing, battery, caps-lock, failed-attempts), FIX-02 hardening preserved verbatim, colors live from the pipeline, lockout-recovery procedure documented and followed | ✓ VERIFIED (1 caveat — see human verification #1) | `hyprlock.conf` line 5 `source = ~/.local/state/theme/hyprlock.conf`; `immediate_render = true`, `ignore_empty_input = true`, `check_text`, `fail_text = <i>$FAIL</i>` all present verbatim; now-playing/battery/capslock/failed-attempts label blocks present; 06-04-SUMMARY.md confirms the lockout-recovery (second-TTY) live-lock test was human-approved this session across two feedback rounds. Caveat: `placeholder_text` hardcodes a Catppuccin literal hex instead of a pipeline variable (WR-01) |
| 3 | Volume/mute/mic-mute changes show a themed SwayOSD pill bound to media keys; caps-lock OSD works keylessly; new matugen template + contract.json entry exist | ✓ VERIFIED (brightness descoped, see note) | `keybinds.conf` XF86AudioRaiseVolume/LowerVolume/Mute/MicMute all route through `swayosd-client`; `install.sh` enables `swayosd-libinput-backend.service`; `swayosd/.config/swayosd/style.css` @imports rendered `swayosd.css`; `contract.json` contains `swayosd.css` entry; theme-parity 1542/1542 pass. Brightness is NOT routed through SwayOSD — it stays on `brightnessctl` per D-25, a design decision pre-authorized in 06-CONTEXT.md and exercised with evidence (`ddcutil` not installed, no DDC monitor detected) in 06-06-SUMMARY.md. This is a documented, pre-authorized scope reduction, not an execution defect |
| 4 | User can capture region/window/full-screen screenshots (freeze, save+copy, notify) and annotate (arrows/text/shapes/blur) | ✓ VERIFIED (code-level; tools not installed locally — see human verification #2) | `capture-region.sh`/`capture-window.sh`/`capture-full.sh` pipe `hyprshot -z -r` into `satty --disable-notifications`; `satty-colors.toml` sets `initial-tool = "arrow"`, `actions-on-enter = ["save-to-clipboard","save-to-file"]`, a 7-swatch pipeline-themed annotation palette; commit.sh symlinks `~/.config/satty/config.toml` |
| 5 | User can record screen/region to video and export GIF | ✗ FAILED (region case) | `record-toggle.sh` line 177: region geometry passed directly as `-w` value, which gpu-screen-recorder's CLI contract does not accept for regions (needs `-w region -region <geom>`) — every drag-selected region recording fails to start (CR-03). Monitor-target recording and `gif-export.sh`'s two-pass ffmpeg pipeline are correctly wired |
| 6 | User can invoke an emoji picker (typed+copied) and a screen color picker (hex copied+swatch) | ✓ VERIFIED | `keybinds.conf` Super+Z -> `emoji-picker.sh` (walker --dmenu stdin-list, wtype + wl-copy backup, documented reasoning for why elephant-symbols' native Activate() can't deliver type+copy); Super+X -> `color-picker.sh` (hyprpicker -a -f hex, wl-copy, ImageMagick swatch notify). Both launch via walker/hyprpicker which own their own UI surface — no TTY dependency, unlike the fzf pickers |
| 7 | Clipboard history is capped (~100) and wiped on session end + manual wipe with default-No confirm | ✓ VERIFIED | `autostart.conf`: `cliphist -max-items 100 store` on both text and image watchers; `wlogout/layout`: `cliphist wipe;` prepended to logout/shutdown/reboot action commands; `clipboard-wipe.sh`: `printf 'No\nYes\n' | walker --dmenu` (No listed first/default), only wipes on exact "Yes" |
| 8 | User can invoke an icon-theme picker that applies live to Thunar/GTK, and a nerd-font switcher covering kitty/vscodium/GTK/waybar | ✗ FAILED (invocation + waybar propagation) | Underlying logic is correct: `icon-theme-picker.sh` writes state + re-runs theme-apply; `gtk.sh` dispatches papirus-folders for Papirus vs. full variant-name swap for Tela/Colloid; `generate.sh`/`font.sh` render `kitty-font.conf`/`waybar-font.css`/`gtk-font-name` from state. But (a) both Super+Shift+Z and Super+Shift+X keybinds `exec` the fzf scripts with no controlling TTY and no kitty wrapper (CR-02), so the pickers are unreachable as bound; (b) even when reached, waybar's own hardcoded `font-family` in `style-{full,minimal,floating}.css`'s `* {}` block wins the CSS cascade over the imported `waybar-font.css` (CR-01), so waybar font never actually changes |
| 9 | Zen browser re-themes on theme switch via matugen-rendered userChrome.css, restart-based/notify-only reload; swayosd/zen/hyprlock are all contract.json targets passing theme-parity | ✓ VERIFIED | `zen-userchrome.css` template renders `:root` CSS custom properties from the palette; `reload.sh`'s `theme_engine_reload_zen()` resolves the profile via installs.ini then profiles.ini, validates the path is a real subdir of `~/.zen`, symlinks `userChrome.css`, writes the defensive `user.js` pref, and notifies without ever calling pkill/kill/killall on Zen (confirmed by direct grep — the only `kill`-adjacent text in the file is the D-28 comment describing the constraint). `contract.json` has 17 entries including `hyprlock.conf`, `swayosd.css`, `zen-userchrome.css`, `satty.toml`; live `theme-parity` run: **1542 passed, 0 failed** across all 22 palette fixtures (light + dark) |
| 10 | A fresh install.sh run reproducibly installs every Phase 6 dependency and completes end-to-end regardless of which AUR helper (paru or yay) is present | ✗ FAILED | All 13 official-repo packages (hyprshot, satty, gpu-screen-recorder, swayosd, hyprpicker, wtype, ddcutil, papirus-icon-theme, 5 nerd fonts) confirmed present in `PACMAN_PKGS`; all 3 AUR packages (tela-icon-theme, colloid-icon-theme-git, papirus-folders) confirmed in `AUR_PKGS` gated behind the legitimacy checkpoint; `swayosd-libinput-backend.service` enable confirmed. BUT install.sh lines 292/296 hardcode `paru` for orphan-removal/cache-clean instead of `"$AUR_HELPER"` — on a yay-only system this crashes the script under `set -euo pipefail` before `verify_packages`, service enablement, and VSCodium extension install run (CR-04) |

**Score:** 8/13 must-haves verified (13 = 10 truths above; 8 counted VERIFIED — #5, #8, #10 are FAILED, split across 3 truths but touching 5 distinct roadmap/plan-level must-haves)

### Deferred Items

None — no gaps here are covered by a later phase; all are within-phase implementation defects or a pre-authorized in-phase design descope (brightness/D-25, not listed as a gap).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `wlogout/.config/wlogout/layout`, `style.css` | Center-bar HUD, glyph buttons | ✓ VERIFIED | icons/ dir removed, glyph text fields present |
| `hypr/.config/hypr/hyprlock.conf` | Dedicated render target, info-rich labels, FIX-02 intact | ✓ VERIFIED (WR-01 caveat) | Source swap confirmed; hardcoded placeholder hex is a leak |
| `matugen/.config/matugen/templates/{hyprlock-colors.conf,swayosd-colors.css,zen-userchrome.css,satty-colors.toml}` | 4 new render targets | ✓ VERIFIED | All 4 present, render cleanly (theme-doctor: all 4 rendered files exist; theme-parity: 0 failures) |
| `theme-engine/.config/theme-engine/contract.json` | 17 file entries | ✓ VERIFIED | `python3 -c json.load` confirms exactly 17 entries, matching D-30 |
| `swayosd/.config/swayosd/style.css` | @import + bottom-center pill | ✓ VERIFIED | Confirmed structure matches UI-SPEC 60/30/10 mapping |
| `hypr/.config/hypr/scripts/{capture-region,capture-window,capture-full,record-toggle,gif-export}.sh` | Screenshot + recording suite | ⚠️ PARTIAL | Capture/annotate/GIF-export correct; record-toggle.sh region flag wrong (CR-03) |
| `hypr/.config/hypr/scripts/{emoji-picker,color-picker,clipboard-wipe}.sh` | 3 quick utility pickers | ✓ VERIFIED | All wired and reachable via direct keybind exec (no TTY dependency) |
| `hypr/.config/hypr/scripts/{icon-theme-picker,font-switcher}.sh` | fzf-in-kitty pickers | ⚠️ ORPHANED (keybind-unreachable) | Scripts correct in isolation; keybinds exec them with no TTY (CR-02) |
| `theme-engine/.config/theme-engine/lib/{font.sh,generate.sh,gtk.sh,commit.sh}` | Font + icon-theme state axes | ✓ VERIFIED (waybar sink broken) | kitty/vscodium/GTK render correctly; waybar's own CSS overrides the render (CR-01) |
| `install.sh`, `stow.sh` | Package + service reproducibility | ⚠️ PARTIAL | Packages/service/stow entries all correct; cleanup path crashes on yay (CR-04) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `waybar/style-*.css` `@import` | `~/.local/state/theme/waybar-font.css` | CSS @import | ✗ NOT_WIRED (effectively) | Import present but immediately shadowed by a same-specificity local rule (CR-01) |
| `keybinds.conf` Super+Shift+Z/X | `icon-theme-picker.sh` / `font-switcher.sh` | direct `exec` | ✗ NOT_WIRED | No kitty wrapper / windowrule, unlike the wallpaper-switch.sh precedent (CR-02) |
| `record-toggle.sh` region case | `gpu-screen-recorder -w region -region <geom>` | CLI flag | ✗ NOT_WIRED | Wrong flag shape (CR-03) |
| `install.sh` cleanup | `$AUR_HELPER -R` / `-Sc` | variable indirection | ✗ NOT_WIRED (yay path) | Hardcoded `paru` literal (CR-04) |
| `keybinds.conf` XF86Audio* | `swayosd-client` | direct `exec` | ✓ WIRED | Confirmed |
| `reload.sh` zen block | Zen profile resolution → symlink + notify | filesystem + notify-send | ✓ WIRED | Confirmed, no kill/pkill of Zen |
| `wlogout/layout` logout/shutdown/reboot | `cliphist wipe` | prepended shell command | ✓ WIRED | Confirmed |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|---------------------|--------|
| `waybar/style-*.css` font | `waybar-font.css` @import | `font.sh` renders real chosen font | Yes, but overridden downstream | ⚠️ HOLLOW — render produces real data, but the CSS cascade discards it (CR-01) |
| `hyprlock.conf` indicator labels | `playerctl`, sysfs battery/capslock, `$ATTEMPTS` | live shell `cmd[update:N]` | Yes | ✓ FLOWING |
| `satty-colors.toml` palette | matugen render | live palette per active theme | Yes | ✓ FLOWING (confirmed via theme-parity across 22 fixtures) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| theme-parity across all 17 contract targets, light+dark fixtures | `env -u WAYLAND_DISPLAY -u DBUS_SESSION_BUS_ADDRESS bash theme-engine/.config/theme-engine/theme-parity` | `Summary: 1542 passed, 0 failed` | ✓ PASS |
| theme-doctor state-dir presence/health check | `env -u WAYLAND_DISPLAY -u DBUS_SESSION_BUS_ADDRESS bash theme-engine/.config/theme-engine/theme-doctor` | `Summary: 29 passed, 1 failed` (the 1 failure is "git status --porcelain is empty" — expected, repo has uncommitted work-in-progress, not a phase defect) | ✓ PASS (with expected git-dirty note) |
| waybar font override cascade | `grep font-family waybar/.config/waybar/style-full.css` | Local `* {}` rule present after both @imports | ✗ FAIL — confirms CR-01 |
| icon-theme/font-switcher keybind wrapper | `grep icon-theme-picker\|font-switcher hypr/.config/hypr/config/keybinds.conf` | Direct `exec` to the script, no `uwsm app -- kitty` wrapper | ✗ FAIL — confirms CR-02 |
| record-toggle.sh region capture flag | `grep -A1 'region:\*' hypr/.config/hypr/scripts/record-toggle.sh` | `capture_args=(-w "${target#region:}")` | ✗ FAIL — confirms CR-03 |
| install.sh AUR_HELPER indirection in cleanup | `grep 'paru -R\|paru -Sc' install.sh` | Literal `paru`, not `"$AUR_HELPER"` | ✗ FAIL — confirms CR-04 |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| `theme-engine/.config/theme-engine/theme-parity` | `bash theme-parity` (headless, WAYLAND/DBUS unset) | 1542/1542 | PASS |
| `theme-engine/.config/theme-engine/theme-doctor` | `bash theme-doctor` (headless) | 29/30 (git-dirty only) | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| WLOG-01 | 06-03 | wlogout redesign | ✓ SATISFIED | Truth #1 |
| LOCK-01 | 06-02, 06-04 | hyprlock redesign, dedicated target, lockout-recovery | ✓ SATISFIED (1 caveat: WR-01) | Truth #2 |
| OSD-01 | 06-01, 06-02, 06-06 | SwayOSD wiring | ✓ SATISFIED (brightness pre-authorized descope) | Truth #3 |
| THM-05 | 06-02, 06-06 | Zen browser theming | ✓ SATISFIED | Truth #9 |
| SHOT-01 | 06-01, 06-05 | Screenshot capture | ✓ SATISFIED | Truth #4 |
| SHOT-02 | 06-02, 06-05 | Screenshot annotation | ✓ SATISFIED | Truth #4 |
| SHOT-03 | 06-01, 06-05 | Screen/region recording + GIF | ✗ BLOCKED (region case) | Truth #5 (CR-03) |
| UTIL-01 | 06-01, 06-09 | Emoji picker | ✓ SATISFIED | Truth #6 |
| UTIL-02 | 06-01, 06-09 | Color picker | ✓ SATISFIED | Truth #6 |
| UTIL-03 | 06-09 | Clipboard history cap+wipe | ✓ SATISFIED | Truth #7 |
| UTIL-04 | 06-01, 06-07 | Icon-theme picker | ✗ BLOCKED (keybind unreachable) | Truth #8 (CR-02) |
| UTIL-05 | 06-01, 06-08 | Nerd-font switcher | ✗ BLOCKED (keybind unreachable + waybar dead) | Truth #8 (CR-01, CR-02) |

**Note:** REQUIREMENTS.md currently marks all 12 IDs "Complete" — this verification disputes SHOT-03, UTIL-04, and UTIL-05 as BLOCKED pending the CR-01/CR-02/CR-03 fixes identified by the code review and independently re-confirmed here. No orphaned requirements found — every ID mapped to this phase in REQUIREMENTS.md is claimed by at least one plan's `requirements:` frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `waybar/.config/waybar/style-{full,minimal,floating}.css` | ~5 | Dead CSS override (hardcoded font-family shadows @import) | 🛑 Blocker | UTIL-05 waybar propagation non-functional (CR-01) |
| `hypr/.config/hypr/config/keybinds.conf` | 69, 71 | Keybind launches TTY-dependent script with no terminal wrapper | 🛑 Blocker | UTIL-04/UTIL-05 pickers unreachable (CR-02) |
| `hypr/.config/hypr/scripts/record-toggle.sh` | 177 | Wrong CLI flag shape for region capture | 🛑 Blocker | SHOT-03 region recording fails to start (CR-03) |
| `install.sh` | 292, 296 | Hardcoded `paru` instead of `$AUR_HELPER` | 🛑 Blocker | install.sh crashes on yay systems, breaking reproducibility (CR-04) |
| `hypr/.config/hypr/hyprlock.conf` | 177 | Hardcoded literal hex color bypassing the theme pipeline | ⚠️ Warning | Light-theme placeholder-text contrast/parity leak (WR-01) |
| `hypr/.config/hypr/scripts/color-picker.sh` | 57 | Trailing `&&`-list exit-status bug (`set -e` class) | ⚠️ Warning | Script exits 1 on its own success path when ImageMagick absent (WR-05) |
| `hypr/.config/hypr/scripts/capture-{region,window,full}.sh` | — | No `command -v` guard for hyprshot/satty | ⚠️ Warning | Missing-tool failure looks identical to user-cancel |
| `theme-engine/.config/theme-engine/contract.json` | — | Missing entries for `kitty-font.conf`/`waybar-font.css` | ⚠️ Warning | theme-doctor/theme-parity blind to font-render regressions (WR-07) |

No unresolved `TBD`/`FIXME`/`XXX` debt markers found in the files this phase modified.

### Human Verification Required

### 1. Hyprlock placeholder-text contrast under light theme

**Test:** Switch to a light theme (e.g. `catppuccin-latte`), lock the screen, observe the password-field placeholder text.
**Expected:** Placeholder text should be legible and drawn from the active palette, not a fixed dark-theme hex.
**Why human:** Code-level cause (hardcoded `##a6adc8` literal, WR-01) is already confirmed by direct file read; the visual legibility outcome on a light background still benefits from an eyes-on screenshot check.

### 2. Live smoke test of screenshot/recording/color-picker tools

**Test:** On a machine with hyprshot, satty, gpu-screen-recorder, and hyprpicker actually installed, exercise each Print-key capture, Alt+Print monitor recording, and Super+X color pick.
**Expected:** Each produces the documented UX (freeze → satty annotate → save+copy+notify; recording toggles with notification; hex copied with swatch).
**Why human:** None of these binaries are installed on this verification machine (confirmed via `pacman -Q` failures per phase context) — code was checked against upstream CLI docs/source, not exercised live.

### Gaps Summary

Four blocker-class defects prevent full goal achievement, all independently re-confirmed by direct codebase inspection (matching the prior code review's CR-01 through CR-04):

1. **CR-01 (waybar font dead CSS)** — UTIL-05's "propagates to all four surfaces" truth fails for waybar specifically; kitty/vscodium/GTK are fine.
2. **CR-02 (picker keybinds have no TTY)** — UTIL-04 and UTIL-05 are both unreachable via their assigned keybinds; the underlying picker/state-write/render logic for both is otherwise correct and would work if invoked in a terminal.
3. **CR-03 (region recording flag)** — SHOT-03's region-recording path fails to start; monitor recording and GIF export are unaffected.
4. **CR-04 (install.sh yay crash)** — breaks the project's core reproducibility promise on yay-based systems; unrelated to any single phase requirement but blocks 06-01's "fresh install.sh run" must-have on that AUR-helper path.

All four are narrow, mechanical fixes (a CSS rule removal, a kitty-wrapper script + windowrule addition, a one-line flag fix, and a variable-substitution fix) — none require redesign. WLOG-01, LOCK-01 (minus the WR-01 placeholder caveat), OSD-01 (with the pre-authorized D-25 brightness descope), THM-05, SHOT-01/02, and UTIL-01/02/03 are all fully verified and working as designed, backed by a live theme-parity run of 1542/1542 passing across all 22 palette fixtures in both light and dark.

REQUIREMENTS.md marks SHOT-03, UTIL-04, and UTIL-05 "Complete" — this verification disputes that status pending the CR-01/CR-02/CR-03 closures.

---

_Verified: 2026-07-12T22:10:00Z_
_Verifier: Claude (gsd-verifier)_
