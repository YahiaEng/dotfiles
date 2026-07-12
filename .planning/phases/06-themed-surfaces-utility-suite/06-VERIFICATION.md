---
phase: 06-themed-surfaces-utility-suite
verified: 2026-07-12T23:20:00Z
status: gaps_found
score: 9/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 8/13
  gaps_closed:
    - "The user can invoke an icon-theme picker and a nerd-font switcher via their assigned keybinds (CR-02 — floating-kitty wrapper scripts icon-theme-switch.sh/font-switch.sh added, keybinds.conf retargeted, windowrules added)"
    - "The chosen nerd font propagates to all four surfaces: kitty, vscodium, GTK, and waybar (CR-01 — hardcoded font-family literal removed from all three waybar style-*.css files)"
    - "The user can record a drag-selected screen region to video (CR-03 — record-toggle.sh region branch now uses `-w region -region <geom>`)"
    - "A fresh install.sh run completes end-to-end regardless of AUR helper (CR-04 — install.sh cleanup now uses \"$AUR_HELPER\" instead of literal paru)"
    - "Hyprlock placeholder-text color sourced from the theme pipeline instead of a hardcoded Catppuccin hex (WR-01 — new $on_surface_variant_hex render variable, confirmed rendered into state dir)"
  gaps_remaining:
    - "Volume/mute/mic-mute media keys and the caps-lock OSD indicator do not work at all on a fresh install: swayosd-server (the process that both performs the volume change and renders the OSD pill) is never launched anywhere in the repo, and install.sh enables swayosd-libinput-backend.service on the user systemd bus even though that unit only exists on the system bus — both defects newly found by 06-REVIEW.md's post-gap-closure re-review and independently reconfirmed here by direct grep; neither was addressed by gap-closure plans 06-10/06-11/06-12"
  regressions: []
gaps:
  - truth: "Volume, brightness, and caps-lock changes show a themed SwayOSD indicator bound to the media keys, re-themed by the pipeline like every other surface"
    status: failed
    reason: "swayosd-client (bound to XF86AudioRaiseVolume/Lower/Mute/MicMute in keybinds.conf) is a thin D-Bus client — the actual volume change and the OSD pill rendering are both performed by swayosd-server. Repo-wide grep confirms swayosd-server is never launched: it does not appear in autostart.conf, there is no user systemd unit for it, and the swayosd Arch package ships no session-bus D-Bus activation file for the server (only a system-bus unit for the libinput backend). This is a functional regression from the wpctl bindings this phase replaced — on a fresh install, pressing any volume/mute key does nothing at all, and the themed OSD pill (swayosd/style.css, the whole point of OSD-01) never appears. Separately, install.sh:329 runs `systemctl --user enable --now swayosd-libinput-backend.service`, but that unit is packaged system-bus-only (root unit with polkit/udev rules) — the user-bus enable silently fails (swallowed by `2>/dev/null || true`), so the keyless caps-lock OSD path this exact keybinds.conf comment claims is 'handled by swayosd-libinput-backend.service (enabled in install.sh, D-23)' never actually gets enabled. Both defects were newly surfaced by 06-REVIEW.md's re-review (dated after gap-closure plans 06-10/11/12 landed) and are unaddressed by any commit currently in the repo (git log's HEAD is the review-report commit itself, ac63a88, with no fix commit after it)."
    artifacts:
      - path: "hypr/.config/hypr/config/autostart.conf"
        issue: "No exec-once entry launches swayosd-server (or any wrapper around it) — confirmed by grep returning zero matches"
      - path: "install.sh"
        issue: "Line 329: `systemctl --user enable --now swayosd-libinput-backend.service` targets the user bus, but the Arch swayosd package installs this unit only at /usr/lib/systemd/system/ (system bus)"
      - path: "theme-engine/.config/theme-engine/lib/reload.sh"
        issue: "Lines 73-75: `pgrep -x swayosd-server` gate assumes the server might be running, but nothing in the repo ever starts it, so this reload block is permanently a no-op on a fresh install; it also restarts the libinput backend on the same wrong user bus as install.sh"
    missing:
      - "exec-once = uwsm app -- swayosd-server in autostart.conf (or an equivalent launch point)"
      - "install.sh:329 changed to enable the system-bus unit (e.g. `sudo systemctl enable --now swayosd-libinput-backend.service`, not silenced with `|| true`)"
      - "reload.sh's swayosd restart logic corrected to target the right bus/component (see 06-REVIEW.md WR-01 for the specific fix shape: restart swayosd-server itself, which is user-owned and renders the CSS, not the system-bus libinput backend)"
human_verification:
  - test: "Switch to a light theme (e.g. catppuccin-latte), lock the screen, and inspect the password-field placeholder text contrast"
    expected: "Placeholder text is legible against the themed input field in both light and dark themes"
    why_human: "Code-level cause (hardcoded ##a6adc8 literal) is now fixed and confirmed rendering $on_surface_variant_hex from the live palette (verified: ~/.local/state/theme/hyprlock.conf contains '$on_surface_variant_hex = a6adc8' after a theme-apply run) — but actual visual legibility on a light background still needs an eyes-on check, not re-derivable from grep."
  - test: "On a machine with hyprshot, satty, gpu-screen-recorder, hyprpicker, and swayosd actually installed and swayosd-server launched, exercise each Print-key capture, Alt+Print region/monitor recording, Super+X color pick, and (once the swayosd gap above is closed) a volume-key press"
    expected: "Each Print-key capture opens satty with the frozen screenshot; recordings (monitor and drag-selected region) start/stop with a notification; color picker copies a hex and shows a swatch; volume/mute keys show a themed SwayOSD pill"
    why_human: "hyprshot, satty, gpu-screen-recorder, hyprpicker, wtype, and swayosd are declared in install.sh but not installed on this verification machine — code was checked against upstream CLI/package contracts (and cross-referenced by the code review), but no live smoke test was possible in this environment."
---

# Phase 6: Themed Surfaces & Utility Suite Verification Report

**Phase Goal:** Every remaining desktop surface is redesigned and re-themed, and a full suite of everyday utility tools ships — all following the established @import-from-state-dir pattern and validated by theme-parity under both light and dark.
**Verified:** 2026-07-12T23:20:00Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure (plans 06-10, 06-11, 06-12), plus a fresh post-gap-closure code review (06-REVIEW.md) surfaced 2 new Critical findings independently reconfirmed here.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | wlogout shows a modern center-bar HUD with sharp Nerd Font glyph buttons, colors live from the pipeline (WLOG-01) | ✓ VERIFIED | `wlogout/layout` — 6 actions with glyph `text` fields (grep -c text = 6); `wlogout/.config/wlogout/icons` directory confirmed absent; `style.css` line 1 `@import url("../../.local/state/theme/wlogout.css")`. No files in this area touched by gap-closure plans — regression-checked, unchanged since prior verification. |
| 2 | hyprlock shows a redesigned, info-rich lock screen sourced entirely from the theme pipeline (no hardcoded literals), lockout-recovery documented (LOCK-01) | ✓ VERIFIED | `hyprlock.conf` line 177 now reads `foreground="##$on_surface_variant_hex"` (was hardcoded `##a6adc8`); `hyprlock-colors.conf` template renders `$on_surface_variant_hex = {{colors.on_surface_variant.default.hex_stripped}}`; confirmed live-rendered: `~/.local/state/theme/hyprlock.conf` contains `$on_surface_variant_hex = a6adc8`. FIX-02 hardening (`immediate_render`, `ignore_empty_input`, `check_text`, `fail_text`) untouched. Prior lockout-recovery (second-TTY) human approval from 06-04-SUMMARY.md carries forward (regression-checked, file not touched by gap plans). |
| 3 | Volume, brightness, and caps-lock changes show a themed SwayOSD indicator bound to the media keys (OSD-01) | ✗ FAILED | `swayosd-server` is never launched anywhere in the repo (grep across autostart.conf, all *.conf/*.sh finds zero matches except a `pgrep -x` gate in reload.sh that assumes it may already be running). `keybinds.conf:138-141` routes all volume/mute keys through `swayosd-client`, which cannot function without the server — this is a **regression** from the wpctl bindings this phase replaced. Additionally `install.sh:329` enables `swayosd-libinput-backend.service` on the **user** bus, but that unit ships system-bus-only per the Arch package file list (06-REVIEW.md, independently reconfirmed) — the enable silently fails. Both are new findings from the post-gap-closure re-review, unaddressed by any commit since (`git log` HEAD is the review-report commit itself). Brightness remains on `brightnessctl` per pre-authorized D-25 descope (not a gap). |
| 4 | User can capture region/window/full-screen screenshots (freeze, save+copy, notify), annotate, and record screen/region to video with GIF export (SHOT-01/02/03) | ✓ VERIFIED | `record-toggle.sh:177` region branch now reads `capture_args=(-w region -region "${target#region:}")` (was the invalid bare geometry as `-w`'s value) — confirmed via direct read, matches gpu-screen-recorder's documented CLI contract. `capture-{region,window,full}.sh` each gained a `command -v hyprshot`/`satty` presence guard (06-11). `satty-colors.toml`/annotation palette unchanged from prior verification (regression-checked). Live end-to-end run not possible — tools not installed on this machine (see human verification #2). |
| 5 | User can invoke an emoji picker, color picker, clipboard-history picker (capped + wipe policy), icon-theme picker (applies to Thunar/GTK live), and a nerd-font switcher (kitty/vscodium/GTK/waybar) (UTIL-01..05) | ✓ VERIFIED | Emoji (Super+Z) and color (Super+X) pickers unchanged, regression-checked. Clipboard cap (`cliphist -max-items 100 store` in autostart.conf) and wipe (`cliphist wipe` in wlogout actions + `clipboard-wipe.sh` default-No confirm) unchanged. Icon-theme picker (Super+Shift+Z) and font switcher (Super+Shift+X) now reachable: `icon-theme-switch.sh`/`font-switch.sh` wrap the fzf pickers in `uwsm app -- kitty --class ...`, keybinds.conf retargeted, matching float windowrules added (confirmed in windowrules.conf lines 58-72). Waybar font propagation fixed: all three `style-{full,minimal,floating}.css` files no longer hardcode `font-family` in their `* {}` block — `waybar-font.css` (the @import'd render target) is now the sole owner (confirmed by direct read of all 3 files). Two non-blocking quality issues remain open from the fresh re-review (icon-variant fallback edge case, font-filter tofu edge case — see Anti-Patterns). |
| 6 | Zen browser re-themes on theme switch (userChrome.css, restart-based reload); swayosd/zen/hyprlock are contract.json targets passing theme-parity (THM-05 + contract) | ✓ VERIFIED | `zen-userchrome.css` template renders `:root` custom properties; `reload.sh`'s `theme_engine_reload_zen()` unchanged, no `kill`/`pkill`/`killall` targeting Zen (grep confirms only a D-28 comment mentions "kill"). `contract.json` has 17 entries including `hyprlock.conf`, `swayosd.css`, `zen-userchrome.css`, `satty.toml`. Live `theme-parity` re-run this session: **1542 passed, 0 failed** — no regression introduced by gap-closure plans. `theme-doctor` re-run: 31/32 passed (the 1 fail is `git status --porcelain is empty`, expected since this verification session has uncommitted scratch files — not a phase defect). |
| 7 | A fresh install.sh run reproducibly installs every dependency regardless of AUR helper (paru or yay) | ✓ VERIFIED | `install.sh` lines 292/296 now read `"$AUR_HELPER" -R --noconfirm "${ORPHANS[@]}"` and `"$AUR_HELPER" -Sc --noconfirm` (was hardcoded `paru`) — confirmed by direct grep. All 13 official-repo + 3 AUR packages remain correctly declared (unchanged, regression-checked). |

**Score:** 9/10 must-haves verified. 1 blocker remains (Truth #3 — SwayOSD/OSD-01).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `wlogout/.config/wlogout/{layout,style.css}` | Glyph-based HUD, no icon assets | ✓ VERIFIED | Unchanged since prior pass |
| `hypr/.config/hypr/hyprlock.conf` + `matugen/.../hyprlock-colors.conf` | Fully pipeline-sourced colors | ✓ VERIFIED | `$on_surface_variant_hex` variable added and wired |
| `hypr/.config/hypr/scripts/icon-theme-switch.sh` | Floating-kitty wrapper for icon-theme-picker.sh | ✓ VERIFIED | New file, mirrors wallpaper-switch.sh pattern exactly |
| `hypr/.config/hypr/scripts/font-switch.sh` | Floating-kitty wrapper for font-switcher.sh | ✓ VERIFIED | New file, same pattern |
| `hypr/.config/hypr/config/keybinds.conf` | Wrappers bound at Super+Shift+Z/X; swayosd-client on media keys | ⚠️ PARTIAL | Picker binds correct; media-key binds route to a client with no running server (see Truth #3) |
| `hypr/.config/hypr/config/windowrules.conf` | Float rules for icon-theme-picker / font-switcher classes | ✓ VERIFIED | Present, matches wallpaper-picker precedent |
| `waybar/.config/waybar/style-{full,minimal,floating}.css` | No hardcoded font-family; waybar-font.css sole owner | ✓ VERIFIED | Confirmed via direct read of all 3 files |
| `hypr/.config/hypr/scripts/record-toggle.sh` | Region branch uses `-w region -region <geom>` | ✓ VERIFIED | Confirmed line 177 |
| `install.sh` | Cleanup uses `$AUR_HELPER`, not literal `paru`; swayosd-server launched; swayosd-libinput-backend.service on correct bus | ⚠️ PARTIAL | AUR_HELPER fixed; swayosd-server launch missing; libinput-backend service on wrong bus |
| `hypr/.config/hypr/config/autostart.conf` | swayosd-server launched at session start | ✗ MISSING | No entry found anywhere in repo |
| `theme-engine/.config/theme-engine/contract.json` | 17 file entries + presence_only_files for font targets | ✓ VERIFIED | 17 entries confirmed via `json.load`; `presence_only_files: [kitty-font.conf, waybar-font.css]` added by 06-10 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `keybinds.conf` Super+Shift+Z | `icon-theme-switch.sh` -> `icon-theme-picker.sh` | floating kitty exec chain | ✓ WIRED | Confirmed via grep chain |
| `keybinds.conf` Super+Shift+X | `font-switch.sh` -> `font-switcher.sh` | floating kitty exec chain | ✓ WIRED | Confirmed via grep chain |
| `waybar/style-*.css` | `waybar-font.css` (state dir) | @import, no shadowing local rule | ✓ WIRED | Confirmed no `font-family` remains in local `* {}` blocks |
| `keybinds.conf` XF86Audio* | `swayosd-client` -> `swayosd-server` | D-Bus | ✗ NOT_WIRED | Client has no server to talk to — server never launched |
| `install.sh` | `swayosd-libinput-backend.service` | `systemctl --user enable --now` | ✗ NOT_WIRED | Wrong bus (system-only unit), enable call fails silently |
| `record-toggle.sh` region branch | `gpu-screen-recorder -w region -region <geom>` | corrected CLI flag shape | ✓ WIRED | Confirmed matches documented CLI contract |
| `install.sh` cleanup | `$AUR_HELPER` | variable substitution (was literal `paru`) | ✓ WIRED | Confirmed lines 292/296 |

### Behavioral Spot-Checks / Probe Execution

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| theme-parity full contract run | `bash theme-engine/.config/theme-engine/theme-parity` (headless) | 1542 passed, 0 failed | ✓ PASS |
| theme-doctor health check | `bash theme-engine/.config/theme-engine/theme-doctor` (headless) | 31 passed, 1 failed (git-dirty only, expected) | ✓ PASS |
| swayosd-server launch point | `grep -rn "swayosd-server" --include="*.conf" --include="*.sh" .` | Only match: `pgrep -x swayosd-server` gate in reload.sh (no launcher) | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| WLOG-01 | 06-03 | wlogout redesign | ✓ SATISFIED | Truth #1 |
| LOCK-01 | 06-02, 06-04, 06-12 | hyprlock redesign, dedicated target, lockout-recovery, full pipeline-sourced colors | ✓ SATISFIED | Truth #2 |
| OSD-01 | 06-01, 06-02, 06-06 | SwayOSD wiring | ✗ BLOCKED | Truth #3 — swayosd-server never launched, libinput backend on wrong bus |
| THM-05 | 06-02, 06-06 | Zen browser theming | ✓ SATISFIED | Truth #6 |
| SHOT-01 | 06-01, 06-05, 06-11 | Screenshot capture | ✓ SATISFIED | Truth #4 |
| SHOT-02 | 06-02, 06-05, 06-11 | Screenshot annotation | ✓ SATISFIED | Truth #4 |
| SHOT-03 | 06-01, 06-05, 06-11 | Screen/region recording + GIF | ✓ SATISFIED | Truth #4 — CR-03 fixed |
| UTIL-01 | 06-01, 06-09 | Emoji picker | ✓ SATISFIED | Truth #5 |
| UTIL-02 | 06-01, 06-09, 06-11 | Color picker | ✓ SATISFIED | Truth #5 |
| UTIL-03 | 06-09 | Clipboard history cap+wipe | ✓ SATISFIED | Truth #5 |
| UTIL-04 | 06-01, 06-07, 06-10 | Icon-theme picker | ✓ SATISFIED | Truth #5 — CR-02 fixed (invocation now reachable) |
| UTIL-05 | 06-01, 06-08, 06-10 | Nerd-font switcher | ✓ SATISFIED | Truth #5 — CR-01/CR-02 fixed |

**No orphaned requirements** — all 12 IDs from REQUIREMENTS.md's Phase 6 mapping appear in at least one plan's `requirements:` frontmatter.

**Note:** REQUIREMENTS.md currently marks all 12 IDs "Complete," including OSD-01 — this verification disputes OSD-01 as BLOCKED pending the swayosd-server autostart + install.sh bus fixes.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `hypr/.config/hypr/config/autostart.conf` | — (missing) | No launch point for swayosd-server | 🛑 Blocker | OSD-01 — volume/mute keys and OSD pill entirely non-functional (regression from prior wpctl binds) |
| `install.sh` | 329 | `systemctl --user enable --now swayosd-libinput-backend.service` targets the wrong (system) bus | 🛑 Blocker | Caps-lock OSD never actually enabled; silently swallowed by `2>/dev/null \|\| true` |
| `theme-engine/.config/theme-engine/lib/reload.sh` | 73-75 | Restarts the libinput backend (wrong bus, wrong component) instead of the server that owns CSS rendering | ⚠️ Warning | Theme-switch reload for SwayOSD is a no-op even once the above two are fixed, unless also corrected |
| `theme-engine/.config/theme-engine/lib/gtk.sh` | 389-416 | Icon-variant nearest-match fallback silently substitutes `installed[0]` instead of preserving the user's explicit pick when no exact match exists | ⚠️ Warning | Multi-segment variant names (Tela-circle-dark, Colloid-purple-dark) can silently revert a user's icon-theme choice on next switch |
| `hypr/.config/hypr/scripts/emoji-picker.sh` | 229-240 | Notification always claims the emoji was "typed" even when `wtype` is absent and only copy occurred | ⚠️ Warning | Misleading UX, not a functional break |
| `hypr/.config/hypr/scripts/font-switcher.sh` | 49-50 | Tofu filter `grep -vx 'Symbols Nerd Font'` misses "Symbols Nerd Font Mono" | ⚠️ Warning | That one font family remains selectable despite being the exact case the filter exists to exclude |
| `stow.sh` | 132-134 | Printed "Next steps" keybind chords (Super+Shift+T/W/B) don't match actual binds (Super+T/B/W) | ⚠️ Warning | Onboarding instructions wrong for a fresh-install user |
| `hypr/.config/hypr/scripts/clipboard-wipe.sh` | 12, 31 | `set -euo pipefail` aborts silently if cliphist is missing/errors, with no error notification | ⚠️ Warning | User may believe a wipe occurred when it didn't, or keybind silently no-ops |
| `theme-engine/.config/theme-engine/lib/commit.sh` | 70-73 | `walker-relaunch.log` not in rsync `--delete` excludes | ℹ️ Info | Currently benign (recreated on each reload) |
| `theme-engine/.config/theme-engine/lib/contract.sh` | 20, 40 | Stale doc comments (references old "10 files", omits ini-kv/env-kv formats) | ℹ️ Info | Documentation drift only |
| `hypr/.config/hypr/scripts/{font-switcher,icon-theme-picker}.sh` | various | Temp scripts/cache dir not cleaned on abnormal exit (no EXIT trap) | ℹ️ Info | /tmp leak on SIGHUP/set -e failure mid-run |

No unresolved `TBD`/`FIXME`/`XXX` debt markers found in phase-modified files (the only `XXX` matches are `mktemp ... XXXXXX` template placeholders, not debt markers).

### Human Verification Required

### 1. Hyprlock placeholder-text contrast under light theme

**Test:** Switch to a light theme (e.g. `catppuccin-latte`), lock the screen, observe the password-field placeholder text.
**Expected:** Placeholder text is legible and drawn from the active palette, not a fixed hex.
**Why human:** Code-level fix is confirmed (`$on_surface_variant_hex` now renders from the palette; verified present in the live state-dir file) — remaining check is purely visual legibility.

### 2. Live smoke test of screenshot/recording/color-picker/SwayOSD tools

**Test:** On a machine with hyprshot, satty, gpu-screen-recorder, hyprpicker, and swayosd actually installed (and, once the OSD-01 gap is closed, swayosd-server launched), exercise each Print-key capture, region/monitor recording, Super+X color pick, and a volume-key press.
**Expected:** Each produces the documented UX; volume/mute keys show a themed SwayOSD pill once the gap is fixed.
**Why human:** None of these binaries are installed on this verification machine — code was checked against upstream CLI/package contracts, not exercised live.

### Gaps Summary

One blocker-class defect remains, newly surfaced by a post-gap-closure code review and independently reconfirmed here by direct codebase inspection:

**OSD-01 (SwayOSD) is functionally broken on a fresh install.** `swayosd-server` — the process that performs the actual volume change and renders the themed OSD pill — is never launched anywhere in the repo (no `autostart.conf` entry, no user systemd unit). `keybinds.conf` was changed by this phase to route all volume/mute/mic-mute keys through `swayosd-client`, which is a thin D-Bus client with nothing to talk to — this is a **regression** from the previously-working `wpctl` bindings this phase replaced. Separately, `install.sh:329` enables `swayosd-libinput-backend.service` (the keyless caps-lock OSD backend) on the user systemd bus, but that unit is packaged system-bus-only, so the enable silently fails. Both defects were flagged fresh by 06-REVIEW.md's re-review (conducted after gap-closure plans 06-10/06-11/06-12 landed) and remain unaddressed — the repository's current HEAD is the review-report commit itself, with no fix commit following it.

All four gaps from the previous VERIFICATION.md (CR-01 waybar font, CR-02 picker TTY wiring, CR-03 region-recording flag, CR-04 install.sh AUR helper) plus WR-01 (hyprlock hardcoded placeholder hex) are now confirmed fixed by direct inspection — 06-10, 06-11, and 06-12 landed exactly what their summaries claimed, and a full `theme-parity` re-run (1542/1542) confirms no regression was introduced elsewhere.

**This looks like an oversight rather than an intentional deviation** — 06-01-PLAN.md itself specifies the now-confirmed-wrong `systemctl --user enable swayosd-libinput-backend.service` line, and no plan in this phase ever specified an autostart entry for `swayosd-server`. This is a genuine, actionable gap requiring a new gap-closure plan (add `exec-once = uwsm app -- swayosd-server` to autostart.conf; change install.sh:329 to target the system bus with sudo and non-silenced error reporting; correct reload.sh's restart target to the user-owned server process). It is not eligible for an override — Success Criterion #2 is directly and completely unmet as shipped.

---

_Verified: 2026-07-12T23:20:00Z_
_Verifier: Claude (gsd-verifier)_
