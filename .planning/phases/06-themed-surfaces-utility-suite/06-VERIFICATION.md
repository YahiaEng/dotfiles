---
phase: 06-themed-surfaces-utility-suite
verified: 2026-07-13T01:11:42Z
status: gaps_found
score: 4/7 must-haves verified
behavior_unverified: 2
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 10/10 (present-or-verified split under prior wording; re-scored below under 7 roadmap-level truths)
  gaps_closed:
    - "Print-family binds (Print/Shift+Print/Ctrl+Print/Alt+Print) rebound to physical code:107, confirmed present in keybinds.conf and parsing cleanly on a live Hyprland 0.55.4 session (hyprctl configerrors empty)"
    - "hyprshot's broken short -r flag replaced with the working --raw long form in all three capture scripts (capture-region.sh, capture-full.sh, capture-window.sh), confirmed via grep and bash -n"
    - "vlc, vlc-plugins-all, and xdg-user-dirs added to install.sh PACMAN_PKGS, confirmed present in install.sh; vlc/vlc-plugins-all now installed on this machine (xdg-user-dirs still absent here — this dev machine predates a fresh install.sh run, not a code defect)"
    - "Hyprlock placeholder-text contrast under light theme: confirmed PASS by human UAT (06-UAT.md Test 1)"
  gaps_remaining:
    - "OSD-01 runtime behavior (key press -> audio change + themed pill; theme switch -> pill re-themes) still not live-exercised — swayosd is now installed and swayosd-libinput-backend.service is confirmed active, but swayosd-server has no live process on this machine because the current Hyprland session predates the 06-13 autostart.conf fix (exec-once only fires at compositor startup) — needs a session restart/relogin to exercise, not a code defect"
    - "SHOT-01/02/03 live capture/record/annotate flow not re-exercised since the 06-14 code fix — all required binaries (hyprshot, satty, gpu-screen-recorder, hyprpicker, wtype) are now installed on this machine, but a live keypress/capture test was not attempted here per verification's no-side-effects constraint (interactive Wayland picker would block and cannot be safely automated)"
  regressions:
    - "WLOG-01 (Truth #1): NEW critical defect found by fresh 06-REVIEW.md (CR-01) and independently reproduced here — wlogout/.config/wlogout/style.css lines 42-77 use `::after`/`content`, which GTK3 has no support for. Confirmed empirically on this exact machine (GTK 3.24.52, wlogout 1.2.2) that a single such parse error causes GTK's CssProvider to discard the ENTIRE stylesheet, not just the offending rule — none of wlogout's custom styling (colors, HUD layout, glyph sizing, per-action accents) applies; wlogout falls back to stock GTK widget theming. This was NOT caught by prior verification rounds (which only checked file presence/@import text via grep, never ran the CSS through an actual GTK parser) and is not addressed by 06-14 or 06-15 (out of their scope). This directly falsifies roadmap Success Criterion #1 ('wlogout ... show[s] ... colors sourced live from the shared theme pipeline')."
gaps:
  - truth: "wlogout shows a modern center-bar HUD with sharp Nerd Font glyph buttons, colors live from the pipeline (WLOG-01)"
    status: failed
    reason: "wlogout/.config/wlogout/style.css contains 8 `::after`/`content` rulesets (lines 42-77) that GTK3 cannot parse (no ::after pseudo-element, no content property support). Empirically reproduced on this machine: loading the deployed stylesheet through Gtk.CssProvider (GTK 3.24.52, the same API wlogout 1.2.2 uses per upstream main.c) raises 'Invalid name of pseudo-class' and CssProvider.to_string() returns completely EMPTY — confirming the entire stylesheet (including the @import of the live theme palette, the button/window base rules, and the per-action accent-border rules, all of which appear BEFORE the offending rules in the file) is discarded, not just the 8 broken rulesets. wlogout therefore renders with zero custom styling: no themed colors, no HUD glyph sizing, no per-action borders/hover states, no dim scrim override — stock GTK widget theme only."
    artifacts:
      - path: "wlogout/.config/wlogout/style.css"
        issue: "Lines 42-77: `button::after`, `button:hover::after, button:focus::after`, and six `#<action>::after { content: \"...\" }` rulesets — all invalid GTK3 CSS constructs that poison the entire provider load"
    missing:
      - "Delete all `::after`/`content` rulesets from wlogout/.config/wlogout/style.css (per 06-REVIEW.md CR-01's documented fix)"
      - "If per-action hover labels are still wanted, use wlogout's native `text` field in wlogout/.config/wlogout/layout (currently all six actions have `\"text\": \"\"`) and style it with a plain `button label {}` rule instead of generated content"
      - "Re-verify with zero GTK CSS parse errors after the fix, e.g.: `python3 -c \"import gi; gi.require_version('Gtk','3.0'); from gi.repository import Gtk; Gtk.CssProvider().load_from_path('$HOME/.config/wlogout/style.css')\"` should produce no exception, and `CssProvider().to_string()` should be non-empty and contain the button/window rules"
behavior_unverified_items:
  - truth: "Volume, brightness, and caps-lock changes show a themed SwayOSD indicator bound to the media keys, re-themed by the pipeline like every other surface (OSD-01)"
    test: "Log out and back in (or restart Hyprland) so autostart.conf's `exec-once = uwsm app -- swayosd-server` actually fires in this session, then press XF86AudioRaiseVolume/Lower/Mute/MicMute and confirm the volume/mute change happens AND a themed SwayOSD pill renders; switch themes and confirm the pill's palette updates live; press caps-lock with no keybind bound and confirm the pill still appears (via swayosd-libinput-backend.service)."
    expected: "Each key press performs the audio change and renders a themed pill matching the active palette; the pill re-themes after a theme switch without logout; caps-lock shows the pill via the libinput backend alone."
    why_human: "swayosd 0.3.1 IS installed on this machine and `swayosd-libinput-backend.service` IS confirmed active (systemctl status: active/running, enabled), so the install.sh half of OSD-01 is now live-proven. However `swayosd-server` (the D-Bus daemon autostart.conf launches) has no running process on this machine — the live Hyprland session (uptime since 2026-07-11) predates autostart.conf's 06-13 edit (mtime 2026-07-13), and exec-once only fires at compositor startup, so the fix cannot self-activate mid-session. Manually starting swayosd-server ourselves would violate the verification constraint against starting servers/services and could conflict with the session's eventual real exec-once launch."
  - truth: "User can capture region/window/full-screen screenshots (freeze, save+copy, notify), annotate, and record screen/region to video with GIF export (SHOT-01/02/03)"
    test: "Press Print / Shift+Print / Ctrl+Print / Alt+Print and confirm each opens satty with the frozen capture (region/window/full) or starts/stops a recording; confirm satty's Enter action saves to ~/Pictures/Screenshots AND copies to clipboard with exactly one notification, with no 'Unrecognized image file format' or getopt errors in the terminal."
    expected: "Each Print-key variant fires its bound script (code:107 keycode match); hyprshot --raw pipes a valid raw image into satty; satty opens, saves, and copies without errors."
    why_human: "hyprshot, satty, gpu-screen-recorder, hyprpicker, and wtype are now ALL installed on this machine (unlike prior verification rounds) and `hyprctl configerrors` is clean for the new code:107 binds on the live session, but the interactive capture flow (region-select, satty's annotate UI) requires a real keypress-driven UI interaction that cannot be safely scripted without risking a hang or an unintended file/clipboard side effect, which this verification pass must not create."
human_verification:
  - test: "Press Print / Shift+Print / Ctrl+Print / Alt+Print and exercise the full capture -> satty annotate -> save+copy flow; separately drag-record a region and a full monitor via Alt+Print, then open the resulting file in VLC."
    expected: "Each Print-key variant fires; satty opens with the frozen image and saves to ~/Pictures/Screenshots with one notification; recordings play back in VLC without a missing-decoder error."
    why_human: "Interactive capture UI and video playback verification, not scriptable without side effects. Both underlying UAT-blocking bugs (Print binds unfiring, hyprshot -r getopt bug, missing vlc-plugins-all) are now code-fixed per 06-14/06-15 and statically confirmed (grep + bash -n + live hyprctl configerrors), but not yet re-exercised live since the fix."
  - test: "Log out/in (or reboot) and press a volume/mute/mic-mute key, then press caps-lock with no other input; switch themes and press a volume key again."
    expected: "Each key press performs the audio change and shows a themed SwayOSD pill; caps-lock shows the pill via the libinput backend; the pill's colors update after a theme switch without logout."
    why_human: "swayosd-server has no running process in the CURRENT session because the session predates the 06-13 autostart.conf fix (exec-once fires only at compositor start) — needs a fresh session to exercise. swayosd-libinput-backend.service is independently confirmed active right now via systemctl."
---

# Phase 6: Themed Surfaces & Utility Suite Verification Report

**Phase Goal:** Every remaining desktop surface is redesigned and re-themed, and a full suite of everyday utility tools ships — all following the established @import-from-state-dir pattern and validated by theme-parity under both light and dark.
**Verified:** 2026-07-13T01:11:42Z
**Status:** gaps_found
**Re-verification:** Yes — round 4, after gap-closure plans 06-14 (Print-key `code:107` binds + `hyprshot --raw`) and 06-15 (vlc/vlc-plugins-all/xdg-user-dirs in install.sh), which closed all three UAT gaps from round 3's live smoke test. This round's fresh, independent code review (`06-REVIEW.md`) surfaced a NEW critical defect (CR-01, wlogout) not caught by any prior round; this verification independently reproduced it empirically and it is the reason overall status is `gaps_found` rather than `passed`/`human_needed`.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | wlogout shows a modern center-bar HUD with sharp Nerd Font glyph buttons, colors live from the pipeline (WLOG-01) | ✗ FAILED | **Empirically reproduced on this machine.** `wlogout/.config/wlogout/style.css` lines 42-77 contain 8 `::after`/`content` rulesets, invalid in GTK3 CSS. Loading the deployed stylesheet (`~/.config/wlogout/style.css`, GTK 3.24.52, wlogout 1.2.2's own `gtk_css_provider_load_from_path` API) via `python3-gi` raises `Invalid name of pseudo-class` at line 42, and `CssProvider.to_string()` returns completely empty — confirming GTK3 discards the WHOLE stylesheet on this single parse error, not just the offending rules. Control test against waybar's 3 stylesheets (same GTK3 engine, same @import pattern) loaded cleanly with non-empty `to_string()` output, isolating this as a wlogout-specific defect, not an environment artifact. Net effect: wlogout renders with stock GTK widget styling only — no themed colors, no HUD glyph sizing, no per-action accent borders, no dim scrim override. This is a NEW finding from the fresh `06-REVIEW.md` (CR-01), not caught by any prior verification round (which only grep-checked `@import` text, never parsed the CSS). |
| 2 | hyprlock shows a redesigned, info-rich lock screen sourced entirely from the theme pipeline (no hardcoded literals), lockout-recovery documented (LOCK-01) | ✓ VERIFIED | `hyprlock.conf` line 177 `foreground="##$on_surface_variant_hex"`, rendered from `hyprlock-colors.conf`'s `on_surface_variant.default.hex_stripped`. hyprlock uses its own config format (not GTK CSS), unaffected by the wlogout CSS-parsing class of bug. Human UAT (`06-UAT.md` Test 1, 2026-07-13) confirms: "Switch to a light theme... lock the screen... result: pass" — placeholder-text contrast confirmed legible in a live light-theme lock. Not touched by 06-14/06-15 — regression-checked (unchanged since round 3). |
| 3 | Volume, brightness, and caps-lock changes show a themed SwayOSD indicator bound to the media keys, re-themed by the pipeline like every other surface (OSD-01) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Code fix from 06-13 remains in place and unchanged by 06-14/06-15: `autostart.conf:36` `exec-once = uwsm app -- swayosd-server`; `install.sh:341-342` enables `swayosd-libinput-backend.service` on the system bus via `sudo`, non-silenced; `reload.sh` swayosd block restarts `swayosd-server`. **New on this machine:** swayosd 0.3.1 is now installed and `systemctl status swayosd-libinput-backend.service` shows **active (running), enabled** — live proof that the install.sh half of the fix works. However `pgrep -af swayosd` shows only the libinput backend running, not `swayosd-server` — because this Hyprland session's uptime predates autostart.conf's edit (session started 2026-07-11, file mtime 2026-07-13), so `exec-once` never fired for it. The key-press -> pill render and theme-switch -> re-theme behaviors remain unexercised pending a session restart. |
| 4 | User can capture region/window/full-screen screenshots (freeze, save+copy, notify), annotate, and record screen/region to video with GIF export (SHOT-01/02/03) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | 06-14/06-15 fixes confirmed present: `keybinds.conf` lines 65-68 bind all four Print-family chords to `code:107` (physical keycode, bypasses XKB keysym translation); `hyprctl configerrors` is empty on this live Hyprland 0.55.4 session, confirming the binds parse with zero config errors. All three capture scripts use `hyprshot ... --raw \| satty ...` (grep-confirmed, no lingering short `-r` anywhere). `install.sh` now lists `vlc`, `vlc-plugins-all`, `xdg-user-dirs` in `PACMAN_PKGS`. On this machine, hyprshot/satty/gpu-screen-recorder/hyprpicker/wtype/vlc/vlc-plugins-all are ALL now installed (a first — no prior round had any of these present). Live keypress/capture behavior was not exercised this round (interactive UI, cannot be safely scripted without side effects) — same class of "presence checks missed it before" truth that already burned this exact flow twice (round 3's UAT found the Print-key and getopt bugs that grep/wiring checks had missed), so this stays present-but-behavior-unverified rather than counted as fully VERIFIED. |
| 5 | User can invoke an emoji picker, color picker, clipboard-history picker (capped + wipe policy), icon-theme picker (applies to Thunar/GTK live), and a nerd-font switcher (kitty/vscodium/GTK/waybar) (UTIL-01..05) | ✓ VERIFIED | Emoji (Super+Z), color (Super+X), clipboard cap (`cliphist -max-items 100 store`) + wipe policy, icon-theme picker (Super+Shift+Z), font switcher (Super+Shift+X) wiring all unchanged since round 3 — regression-checked (06-14/06-15 touched only keybinds.conf's Print-family section, the 3 capture scripts, and install.sh's PACMAN_PKGS array; no overlap). Human UAT (`06-UAT.md` Test 2) independently confirms: "Color picker is a pass." |
| 6 | Zen browser re-themes on theme switch (userChrome.css, restart-based reload); swayosd/zen/hyprlock are contract.json targets passing theme-parity (THM-05 + contract) | ✓ VERIFIED | `contract.json` still has 17 entries including `hyprlock.conf`, `swayosd.css`, `zen-userchrome.css`, `satty.toml` — confirmed unchanged. Live `theme-parity` re-run this session: **1542 passed, 0 failed** — no regression from 06-14/06-15. `theme-doctor` re-run: 31/32 passed (the 1 fail is the expected `git status --porcelain is empty` check — this session has untracked scratch files unrelated to phase 6, same as every prior round). |
| 7 | A fresh install.sh run reproducibly installs every dependency regardless of AUR helper (paru or yay) | ✓ VERIFIED | Lines unchanged: `"$AUR_HELPER" -R --noconfirm "${ORPHANS[@]}"` / `"$AUR_HELPER" -Sc --noconfirm`. `bash -n install.sh` exits 0, covering the new 06-15 PACMAN_PKGS additions with no syntax regression. Note: `xdg-user-dirs` is added to install.sh's package list (confirmed via grep) but is not yet installed on THIS dev machine (`pacman -Q xdg-user-dirs` fails) — expected, since this machine has not had a fresh `install.sh` run since 06-15 landed; not a code defect. |

**Score:** 4/7 truths verified, 2 present + wired with runtime behavior not yet exercisable in this session (behavior_unverified: 2), 1 FAILED (WLOG-01 — new critical regression, CR-01).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `wlogout/.config/wlogout/style.css` | Themed HUD styling, no invalid GTK3 constructs | ✗ STUB (effectively) | File exists, has substantive content, but 8 `::after`/`content` rulesets make GTK3 discard the entire stylesheet at load — net runtime effect is equivalent to an empty/broken stylesheet |
| `hypr/.config/hypr/config/keybinds.conf` | Print-family binds match physical keycode 107 | ✓ VERIFIED | 4 `code:107` binds present (lines 65-68); `hyprctl configerrors` empty on live session |
| `hypr/.config/hypr/scripts/capture-{region,full,window}.sh` | Use `hyprshot --raw`, save to `~/Pictures/Screenshots` | ✓ VERIFIED | All three use `--raw` long form; `bash -n` clean; `SCREENSHOT_DIR="$HOME/Pictures/Screenshots"` consistent across all three |
| `install.sh` | vlc, vlc-plugins-all, xdg-user-dirs in PACMAN_PKGS | ✓ VERIFIED | Lines 155-162, comment-documented; `bash -n install.sh` exits 0 |
| `hypr/.config/hypr/config/autostart.conf`, `theme-engine/.../reload.sh` | swayosd-server launched/restarted correctly | ✓ VERIFIED (code); ⚠️ session-stale (runtime) | Code present and correct; not yet exercised in this session (session predates the fix) |
| `theme-engine/.config/theme-engine/contract.json` | 17 file entries including swayosd.css, zen-userchrome.css, hyprlock.conf, satty.toml | ✓ VERIFIED | Confirmed unchanged |
| `hyprlock.conf`, `waybar/style-*.css`, emoji/color/clipboard/icon/font pickers | All prior-verified artifacts | ✓ VERIFIED (regression) | None touched by 06-14/06-15's scope; waybar CSS files independently re-confirmed to load cleanly through GTK3 (control test against the broken wlogout file) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `wlogout/layout` action `text` fields | rendered button labels | GTK3 `button label` CSS rule | ⚠️ PARTIAL | `text` fields are all `""` (relying entirely on the now-broken `::after` hover-reveal for labels); with the stylesheet discarded, even the base `button label { font-family; font-size: 28px }` glyph-sizing rule (line 36-39) does not apply either |
| `keybinds.conf` Print-family (`code:107`) | `capture-*.sh` / `record-toggle.sh` | `bind = <mod>, code:107, exec, ...` | ✓ WIRED | Confirmed via `hyprctl configerrors` empty on live session |
| `capture-*.sh` | `satty` | `hyprshot ... --raw \| satty --filename -` | ✓ WIRED | Grep + `bash -n` confirm the pipe uses the working long-form flag in all three scripts |
| `install.sh` PACMAN_PKGS | `vlc`/`vlc-plugins-all`/`xdg-user-dirs` | `pacman -Sy --needed` | ✓ WIRED | Package list entries confirmed; live `pacman -Q` shows vlc/vlc-plugins-all already installed on this machine (xdg-user-dirs pending a fresh install.sh run) |
| `keybinds.conf` XF86Audio*/MicMute | `swayosd-client` -> `swayosd-server` | D-Bus, server launched by autostart | ✓ WIRED (code); ⚠️ no live server process this session | Same as round 3's finding, now further confirmed: `swayosd-libinput-backend.service` (the OTHER half) is independently live-verified `active` |

### Data-Flow Trace (Level 4)

Not applicable — Phase 6 artifacts are shell scripts, CSS/config templates, and systemd unit invocations, not components rendering dynamic application state from a data source.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `install.sh` syntax validity (incl. new vlc/xdg-user-dirs entries) | `bash -n install.sh` | exit 0 | ✓ PASS |
| Capture scripts syntax validity | `bash -n capture-{region,full,window}.sh` | exit 0 (all 3) | ✓ PASS |
| Print-family `code:107` binds parse cleanly on live Hyprland | `hyprctl configerrors` | empty (exit 0) | ✓ PASS |
| `--raw` long form used everywhere, no broken `-r` remaining | `grep -rn "hyprshot.*-r\b" capture-*.sh` | no functional match (only a comment reference) | ✓ PASS |
| wlogout CSS actually parses in GTK3 | `Gtk.CssProvider().load_from_path('~/.config/wlogout/style.css')` (GTK 3.24.52, installed wlogout 1.2.2's own API) | `Invalid name of pseudo-class` error; `to_string()` empty | ✗ FAIL — new blocker (CR-01), see gap |
| waybar CSS (same GTK3 engine, same @import pattern) parses cleanly — control test | `Gtk.CssProvider().load_from_path()` on all 3 waybar stylesheets | loaded OK, non-empty `to_string()` for all 3 | ✓ PASS (isolates the defect to wlogout only) |
| theme-parity full contract run | `bash theme-engine/.config/theme-engine/theme-parity` (headless) | 1542 passed, 0 failed | ✓ PASS |
| theme-doctor health check | `bash theme-engine/.config/theme-engine/theme-doctor` (headless) | 31 passed, 1 failed (git-dirty only, expected/unrelated) | ✓ PASS |
| swayosd-libinput-backend.service live state | `systemctl status swayosd-libinput-backend.service` | active (running), enabled | ✓ PASS |
| swayosd-server live process | `pgrep -af swayosd` | only libinput backend found, no swayosd-server | ? SKIP — session predates the 06-13 autostart fix; routed to human verification |
| Live Print-key capture / recording / satty annotate flow | (interactive, not run) | — | ? SKIP — cannot script an interactive Wayland picker without side-effect/hang risk; routed to human verification |

### Probe Execution

No `scripts/*/tests/probe-*.sh` convention or phase-declared probes found in this repo for Phase 6 (this project's verification surface is `theme-parity`/`theme-doctor`, both run above as behavioral spot-checks). Step 7c: SKIPPED (no probe-* scripts declared or discovered).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| WLOG-01 | 06-03 | wlogout redesign | ✗ BLOCKED | Truth #1 — CSS parse defect discards entire stylesheet; REQUIREMENTS.md marks this "Complete" but that is contradicted by live empirical evidence |
| LOCK-01 | 06-02, 06-04, 06-12 | hyprlock redesign, dedicated target, lockout-recovery, full pipeline-sourced colors | ✓ SATISFIED | Truth #2, human UAT pass |
| OSD-01 | 06-01, 06-02, 06-06, 06-13 | SwayOSD wiring | ✓ SATISFIED (code); behavior unverified this session | Truth #3 |
| THM-05 | 06-02, 06-06 | Zen browser theming | ✓ SATISFIED | Truth #6 |
| SHOT-01 | 06-01, 06-05, 06-11, 06-14 | Screenshot capture | ✓ SATISFIED (code); behavior unverified this session | Truth #4 |
| SHOT-02 | 06-02, 06-05, 06-11, 06-14 | Screenshot annotation | ✓ SATISFIED (code); behavior unverified this session | Truth #4 |
| SHOT-03 | 06-01, 06-05, 06-11, 06-14, 06-15 | Screen/region recording + GIF + codecs | ✓ SATISFIED (code); behavior unverified this session | Truth #4 |
| UTIL-01 | 06-01, 06-09 | Emoji picker | ✓ SATISFIED | Truth #5 |
| UTIL-02 | 06-01, 06-09, 06-11 | Color picker | ✓ SATISFIED | Truth #5, human UAT pass |
| UTIL-03 | 06-09 | Clipboard history cap+wipe | ✓ SATISFIED | Truth #5 |
| UTIL-04 | 06-01, 06-07, 06-10 | Icon-theme picker | ✓ SATISFIED | Truth #5 |
| UTIL-05 | 06-01, 06-08, 06-10 | Nerd-font switcher | ✓ SATISFIED | Truth #5 |

**No orphaned requirements** — all 12 IDs from REQUIREMENTS.md's Phase 6 mapping appear in at least one plan's `requirements:` frontmatter across all 15 plans (06-01 through 06-15), cross-checked directly. REQUIREMENTS.md marks all 12 "Complete" — this verification **disagrees on WLOG-01**: the code exists and was previously believed correct, but a live GTK3 CSS-parse test (not performed by any prior round) proves the feature does not actually render as designed. REQUIREMENTS.md's WLOG-01 checkbox should not be trusted until CR-01 is fixed and re-verified.

### Anti-Patterns Found

No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` markers found in any of the 37 phase-6 files reviewed (autostart.conf, keybinds.conf, windowrules.conf, hyprlock.conf, all capture/picker/switcher scripts, install.sh, kitty.conf, matugen templates, swayosd/style.css, theme-engine lib files, waybar CSS, wlogout files).

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `wlogout/.config/wlogout/style.css` | 42-77 | `::after`/`content` — GTK3-unsupported, poisons entire stylesheet parse | 🛑 **Blocker** (CR-01, new) | wlogout renders completely unthemed — see Truth #1 gap |
| `hypr/.config/hypr/scripts/color-picker.sh` | 25-32 | Misclassifies real hyprpicker failures as silent user-cancel (hyprpicker logs only to stdout, script reads stderr) | ⚠️ Warning (carried, 06-REVIEW WR-01) | Genuine picker failures produce no error notification |
| `hypr/.config/hypr/scripts/clipboard-wipe.sh` | 12 | `set -euo pipefail` aborts silently before the confirm dialog when cliphist db is empty | ⚠️ Warning (carried, 06-REVIEW WR-02) | Super+Shift+C becomes a silent no-op on fresh install / after a wipe |
| `theme-engine/.config/theme-engine/lib/reload.sh` | 119 | `grep -c ... \|\| echo 0` can yield a two-line `"0\n0"` string, breaking a subsequent `-eq` arithmetic test under `set -e` | ⚠️ Warning (carried, 06-REVIEW WR-03) | Narrow trigger (malformed/empty installs.ini); aborts the Zen reload step |
| `hypr/.config/hypr/scripts/font-switcher.sh`, `icon-theme-picker.sh` | multiple | No `trap ... EXIT` cleanup for mktemp artifacts (unlike sibling pickers) | ⚠️ Warning (carried, 06-REVIEW WR-04) | Leaks temp scripts/cache dirs on abnormal exit |
| `hypr/.config/hypr/scripts/record-toggle.sh` | 36,46,51,55-56 | `pgrep/pkill -f "^gpu-screen-recorder"` unbounded prefix also matches sibling GSR UI/GTK/notification binaries | ⚠️ Warning (carried, 06-REVIEW WR-05) | Could kill the wrong process or invert start/stop state if those siblings are ever installed |
| `theme-engine/.config/theme-engine/lib/commit.sh` | 70-73 | rsync `--delete` exclusion list missing `walker-relaunch.log` | ⚠️ Warning (carried, 06-REVIEW WR-06) | Diagnostics file deleted on every commit; bounded impact (recreated on next reload) |
| Various (9 items) | — | Documentation drift, stale comments, minor deprecation warnings, install-order nits | ℹ️ Info | Non-functional |

None of the Warning/Info items are new blockers for the phase goal; they are pre-existing, carried, and out of 06-14/06-15's scope. The one new Critical (CR-01) is the sole blocker in this round.

### Human Verification Required

### 1. Live Print-key capture / recording / annotate / playback flow

**Test:** Press Print / Shift+Print / Ctrl+Print / Alt+Print and exercise the full capture -> satty annotate -> save+copy flow; drag-record a region and a full monitor via Alt+Print, then open the resulting file in VLC.
**Expected:** Each Print-key variant fires; satty opens with the frozen image and saves to `~/Pictures/Screenshots` with exactly one notification; recordings play back in VLC without a missing-decoder error.
**Why human:** Interactive capture UI and video playback, not scriptable without side effects. Both underlying UAT-blocking bugs (Print binds unfiring, hyprshot's `-r` getopt bug, missing `vlc-plugins-all`) are code-fixed per 06-14/06-15 and statically confirmed (grep + `bash -n` + live `hyprctl configerrors`), but not yet re-exercised live since the fix.

### 2. Live SwayOSD key-press and theme-switch re-theme

**Test:** Log out/in (or reboot) so `exec-once = uwsm app -- swayosd-server` fires in a fresh session, then press a volume/mute/mic-mute key and a caps-lock press (no keybind needed); switch themes and press a volume key again.
**Expected:** Each key press performs the audio change and shows a themed SwayOSD pill; caps-lock shows the pill via the libinput backend alone; the pill's colors update after a theme switch without logout.
**Why human:** `swayosd-server` has no running process in the CURRENT session because the session predates the 06-13 autostart.conf fix — needs a fresh session to exercise. `swayosd-libinput-backend.service` is independently confirmed active right now via `systemctl status`.

### Gaps Summary

**One new Critical blocker (CR-01) prevents `passed` status this round: wlogout renders completely unthemed.** `wlogout/.config/wlogout/style.css` uses 8 GTK3-unsupported `::after`/`content` rulesets (lines 42-77), intended to reveal an action-name label on hover. GTK 3.24.52 does not merely ignore these rulesets — it discards the ENTIRE stylesheet on the first parse error, which was empirically reproduced on this exact machine using the same CSS-loading API wlogout 1.2.2 itself uses. The result: none of wlogout's custom design applies — no themed colors (`@background`/`@primary`/etc. via the state-dir `@import`), no HUD glyph sizing, no per-action accent borders or hover states. This directly falsifies roadmap Phase 6 Success Criterion #1 ("wlogout ... show[s] ... colors sourced live from the shared theme pipeline") and Truth #1 (WLOG-01). This defect predates 06-14/06-15 (it was introduced in 06-03 and has been present through every prior verification round) but was never caught because prior rounds only grep-checked for the `@import` line's text presence, never actually ran the stylesheet through a GTK CSS parser. It was surfaced by this round's independent `06-REVIEW.md` code review and is now independently confirmed here.

**06-14 and 06-15's gap closures are confirmed complete and correct at the code level; runtime behavior remains unexercised** for OSD-01 (session predates the autostart fix) and SHOT-01/02/03 (interactive UI, no safe non-mutating test available this round) — both are legitimate `human_needed` items, not blockers, and are the same class of "needs a live keypress on real hardware" item carried from every prior round, now narrowed because the required binaries are finally all installed on this machine.

**Recommended next step:** a small gap-closure plan to delete the `::after`/`content` rulesets from `wlogout/.config/wlogout/style.css` (see `06-REVIEW.md` CR-01's documented fix — the base button/color styling is unaffected once the invalid rules are removed; the hover-label feature itself is structurally unimplementable via CSS generated content in GTK3 and should either be dropped or reimplemented via wlogout's native `text` field in `wlogout/.config/wlogout/layout`).

---

_Verified: 2026-07-13T01:11:42Z_
_Verifier: Claude (gsd-verifier)_
