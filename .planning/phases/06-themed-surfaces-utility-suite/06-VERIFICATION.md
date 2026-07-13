---
phase: 06-themed-surfaces-utility-suite
verified: 2026-07-13T08:10:00Z
status: gaps_found
score: 3/7 must-haves verified
behavior_unverified: 1
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/7
  gaps_closed:
    - "WLOG-01: wlogout/.config/wlogout/style.css's 8 `::after`/`content` rulesets (lines 42-77) removed by 06-16; independently reproduced here — Gtk.CssProvider().load_from_path() on the live deployed stylesheet now yields 4589 bytes / 0 parse errors (was 0 bytes / 8 fatal errors). All six wlogout/layout `text` fields now carry Nerd Font glyphs (were empty strings)."
    - "06-17 warnings (color-picker stdout misclassification, clipboard-wipe empty-db set -e abort, mktemp trap-cleanup gaps in font-switcher.sh/icon-theme-picker.sh, record-toggle.sh pgrep argv[0] over-matching) — independently spot-checked in source, all four fixes present as described."
    - "06-18 warnings (reload.sh's `grep -c ... || echo 0` two-line-string arithmetic-abort idiom, commit.sh's walker-relaunch.log deletion on every commit) — independently confirmed fixed in source."
  gaps_remaining:
    - "SHOT-01/02/03 live interactive capture/annotate/record flow still not exercised (unchanged from previous round — cannot safely script an interactive Wayland picker/satty UI without side-effect risk); all required binaries (hyprshot, satty, gpu-screen-recorder, hyprpicker, wtype, vlc, vlc-plugins-all, ffmpeg) confirmed installed on this machine"
  regressions: []
gaps:
  - truth: "Volume, brightness, and caps-lock changes show a themed SwayOSD indicator bound to the media keys, re-themed by the pipeline like every other surface (OSD-01, roadmap Success Criterion 2)"
    status: failed
    reason: "hypr/.config/hypr/config/keybinds.conf lines 160-161 bind XF86MonBrightnessUp/Down directly to `brightnessctl -e4 -n2 set 5%±`, bypassing swayosd-client entirely — confirmed via grep on the live file. Only volume/mute/mic-mute (lines 149-152) route through swayosd-client and get the themed pill; brightness changes produce NO OSD indicator at all. This directly contradicts the roadmap's own Success Criterion 2 wording ('Volume, brightness, and caps-lock changes show a themed SwayOSD indicator'). This is a new finding from the fresh 06-REVIEW.md (WR-07), not caught by any prior verification round, and not addressed by any of the 06-16..06-19 gap-closure plans (none touch keybinds.conf's brightness lines)."
    artifacts:
      - path: "hypr/.config/hypr/config/keybinds.conf"
        issue: "Lines 160-161: brightness keys call brightnessctl directly instead of swayosd-client --brightness raise/lower"
      - path: "swayosd/.config/swayosd/style.css"
        issue: "Not currently deployed under ~/.config on this dev machine (swayosd IS listed in stow.sh PACKAGES and tracked in git; `stow -n swayosd` simulates cleanly with no conflicts, so this is a dev-machine deployment-staleness issue, not a missing-from-code defect — but theme-doctor's [SKIP] on this exact condition (WR-04) means a completely unthemed live OSD currently passes the health gate as green, which is itself a gate-integrity gap worth closing alongside the brightness fix)"
    missing:
      - "Rebind XF86MonBrightnessUp/Down to `swayosd-client --brightness raise` / `--brightness lower` (06-REVIEW.md WR-07's documented fix) so brightness changes render the themed pill like volume/mute/mic-mute already do"
      - "Change theme-doctor's not-deployed-stylesheet case from [SKIP] to a hard FAIL (or an explicit 'all stow packages deployed' check), per 06-REVIEW.md WR-04, so an unthemed live surface cannot pass the health gate silently"
  - truth: "User can invoke ... an icon-theme picker that applies to Thunar/GTK live (UTIL-04, roadmap Success Criterion 4)"
    status: failed
    reason: "theme_engine_nearest_icon_variant (theme-engine/.config/theme-engine/lib/gtk.sh:389-416) computes an 'ideal' color name from papirus-folders' 23-name vocabulary (carmine-red, oxidgreen, breeze, nordic, ...) but compares it against Tela/Colloid's actual installed variant names (Tela-blue, Tela-nord, Colloid-teal, ...), which use a disjoint vocabulary — confirmed by reading both enums directly. The exact-match branch at gtk.sh:409-410 therefore essentially never hits, and the fallback at gtk.sh:415 (`printf '%s\\n' \"${installed[0]}\"`) silently returns whatever icon-theme directory `find` enumerates first (no `sort`), replacing the user's explicit pick with a nondeterministic one on every theme switch. Separately, generate.sh:119-143 writes the RAW state-file icon-theme value into gtk-3.0/gtk-4.0 settings.ini, while gtk.sh:306 writes the SUBSTITUTED (possibly-wrong) name into gsettings — so GTK3 apps (Thunar) and GTK4/portal apps can end up on two different icon themes after a single theme switch. install.sh explicitly bundles both affected families (tela-icon-theme, colloid-icon-theme-git, per 06-01-PLAN.md), so this is not a hypothetical edge case. This is a new finding from the fresh 06-REVIEW.md (CR-01), not caught by any prior verification round (all of which only checked that the picker script itself writes a state file, never traced the gtk.sh consumer logic), and not addressed by any of the 06-16..06-19 gap-closure plans."
    artifacts:
      - path: "theme-engine/.config/theme-engine/lib/gtk.sh"
        issue: "Lines 389-416 (theme_engine_nearest_icon_variant) and 294-307 (call site): vocabulary mismatch makes the fallback branch the de-facto default path, fallback is nondeterministic (no sort), and callers treat any non-empty fallback return as an authoritative override of the user's pick"
      - path: "theme-engine/.config/theme-engine/lib/generate.sh"
        issue: "Lines 119, 137-143 write the unsubstituted state-file icon-theme name into settings.ini, diverging from gtk.sh's substituted gsettings write for the same theme-switch event"
    missing:
      - "Per 06-REVIEW.md CR-01's documented fix: sort installed variants for determinism, and on no-exact-match return NOTHING (not installed[0]) so the caller keeps the user's own pick instead of silently substituting an arbitrary one"
      - "Keep generate.sh's settings.ini write and gtk.sh's gsettings write in lockstep — same source value for a given theme-switch event, so GTK3 (Thunar) and GTK4/portal apps never disagree on the active icon theme"
  - truth: "Every remaining desktop surface is ... validated by theme-parity under both light and dark (phase goal's closing clause, and roadmap Success Criterion 1's 'verified under both light and dark themes')"
    status: failed
    reason: "theme-engine/.config/theme-engine/theme-doctor:36-37 hardcodes an exact-match check for `gsettings gtk-theme == adw-gtk3-dark`. lib/gtk.sh:22-25 (and generate.sh's settings.ini equivalent) deliberately set gtk-theme to `adw-gtk3` (no `-dark` suffix) whenever the committed mode marker is `light` — confirmed directly in source. Phase 05 shipped six light presets (catppuccin-latte, gruvbox-light, tokyonight-day, rosepine-dawn, kanagawa-lotus, materialyou-light). On a fully-correct, live LIGHT-mode desktop, theme-doctor — the project's own canonical health gate, run at the start of every verification round in this phase's history — prints `[FAIL] gsettings gtk-theme = adw-gtk3-dark (got: adw-gtk3)` and exits non-zero. This does not currently manifest on THIS machine because it is committed to a dark preset (catppuccin) right now, but the bug is deterministic and will fire the instant any of the six light presets is activated — verified by direct code inspection of the mode-branching logic in gtk.sh, not merely inferred. This is a new finding from the fresh 06-REVIEW.md (CR-02), not caught by any of the 4 prior verification rounds (all of which ran theme-doctor only in the machine's persistent dark-mode state), and not addressed by any of the 06-16..06-19 gap-closure plans. Distinct from theme-parity (the separate script, confirmed 1542/0 pass across ALL fixtures including every light preset) — this gap is specifically in theme-doctor's mode-awareness, the health gate the phase goal's closing clause implicitly depends on for confidence."
    artifacts:
      - path: "theme-engine/.config/theme-engine/theme-doctor"
        issue: "Lines 40-42 (per 06-REVIEW.md's line numbering) hardcode the dark-mode-only gtk-theme value with no mode branch"
    missing:
      - "Read the committed mode marker (same source gtk.sh already uses) and assert the mode-correct expected value: adw-gtk3-dark for dark mode, adw-gtk3 for light mode (06-REVIEW.md CR-02's documented fix)"
deferred: []
behavior_unverified_items:
  - truth: "User can capture region/window/full-screen screenshots (animation, freeze, save + copy, notification), annotate them, and record screen/region to video with GIF export (SHOT-01/02/03, roadmap Success Criterion 3)"
    test: "Press Print / Shift+Print / Ctrl+Print / Alt+Print and exercise the full capture -> satty annotate -> save+copy flow; drag-record a region and a full monitor via Alt+Print, export a GIF from the resulting notification, and play the .mp4 back in VLC."
    expected: "Each Print-key variant fires (code:107 bind); hyprshot --raw pipes a valid raw image into satty; satty opens, annotates, saves to ~/Pictures/Screenshots, and copies with exactly one notification; gpu-screen-recorder starts/stops cleanly; the exported GIF and the .mp4 both play back without a missing-codec error."
    why_human: "Interactive Wayland capture UI (region-select, satty's annotate toolbar) requires a real keypress-driven interaction that cannot be safely scripted without risking a hang or an unintended file/clipboard side effect. All underlying binaries (hyprshot, satty, gpu-screen-recorder, hyprpicker, wtype, vlc, vlc-plugins-all, ffmpeg) and the code:107 keybinds are confirmed present and syntactically sound (bash -n clean, hyprctl configerrors empty), but this specific flow has not been re-exercised live since 06-14/06-15 shipped the fixes that made it possible."
human_verification: []
---

# Phase 6: Themed Surfaces & Utility Suite Verification Report

**Phase Goal:** Every remaining desktop surface is redesigned and re-themed, and a full suite of everyday utility tools ships — all following the established @import-from-state-dir pattern and validated by theme-parity under both light and dark.
**Verified:** 2026-07-13T08:10:00Z
**Status:** gaps_found
**Re-verification:** Yes — round 5, after gap-closure plans 06-16 (WLOG-01 CSS-parse blocker), 06-17 (4 script warnings), 06-18 (2 theme-engine lib warnings), and 06-19 (GTK CSS-parse regression guard). The prior round's sole blocker (WLOG-01) is confirmed fixed. However, a fresh, independent code review (`06-REVIEW.md`, run at current HEAD after all four gap-closure plans landed) surfaced 2 NEW critical defects and multiple new warnings that no prior round caught. This verification independently reproduced the two criticals and one of the new warnings (brightness-bypass) that together falsify roadmap Success Criteria 2 and 4 and the phase goal's light/dark validation clause — the reason overall status remains `gaps_found` rather than advancing to `passed`.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | wlogout and hyprlock both show a modern redesigned look with sharp assets/colors sourced live from the pipeline, verified under both light and dark, lockout-recovery documented (WLOG-01, LOCK-01) | ✓ VERIFIED | **wlogout (previously FAILED, now fixed):** `wlogout/.config/wlogout/style.css`'s 8 invalid `::after`/`content` rulesets are gone. Independently reproduced: `Gtk.CssProvider().load_from_path(~/.config/wlogout/style.css)` (GTK 3.24.52, the live deployed file, symlinked via stow) now returns **4589 bytes, 0 parse errors** (was 0 bytes / whole-sheet-discarded). All six `wlogout/layout` `text` fields carry populated Nerd Font glyphs (were empty strings). theme-parity confirms `wlogout.css present` across all 20 fixtures including every light preset (catppuccin-latte, gruvbox-light, etc.). **hyprlock (unchanged):** `hyprlock.conf` line 177 sources `##$on_surface_variant_hex` from the render target; human UAT (`06-UAT.md` Test 1) previously confirmed legible placeholder-text contrast under a live light theme. |
| 2 | Volume, brightness, and caps-lock changes show a themed SwayOSD indicator bound to media keys, re-themed by the pipeline (OSD-01) | ✗ FAILED | **New finding, independently confirmed.** `keybinds.conf` lines 160-161: brightness keys (`XF86MonBrightnessUp/Down`) call `brightnessctl` directly, never `swayosd-client` — confirmed via grep on the live file. Only volume/mute/mic-mute route through the themed pill. This directly contradicts the roadmap's own wording ("Volume, brightness, and caps-lock..."). Additionally, `swayosd/style.css` is not currently deployed under `~/.config` on this dev machine (though `swayosd` is listed in `stow.sh` and `stow -n swayosd` simulates cleanly — a deployment-staleness issue, not a code-absence one) and `theme-doctor` [SKIPs] rather than fails on that condition, meaning a fully unthemed live OSD can pass the health gate as green. `swayosd-server` IS running live on this machine right now (`pgrep -af swayosd` shows PID present, unlike the previous round). |
| 3 | User can capture/annotate/record screenshots and video with GIF export (SHOT-01/02/03) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Unchanged from previous round — no regression. All required binaries confirmed installed (hyprshot, satty, gpu-screen-recorder, hyprpicker, wtype, vlc, vlc-plugins-all, ffmpeg). `code:107` Print-family binds confirmed parsing with `hyprctl configerrors` empty. All three capture scripts confirmed using `hyprshot ... --raw \| satty ...` (grep + `bash -n` clean). Live interactive flow still not exercised — routed to human verification (Step 8). |
| 4 | User can invoke emoji/color/clipboard/icon-theme/font pickers, icon-theme picker applies to Thunar/GTK live (UTIL-01..05) | ✗ FAILED (partial — UTIL-04 only) | **New finding, independently confirmed.** `theme_engine_nearest_icon_variant` (`gtk.sh:389-416`) compares an "ideal" color computed from papirus-folders' vocabulary against Tela/Colloid's disjoint variant-naming vocabulary — the exact-match branch essentially never hits, so the nondeterministic fallback (`installed[0]`, no `sort`) silently overrides the user's explicit icon-theme pick on every switch. Separately, `generate.sh` writes the raw state value into `settings.ini` while `gtk.sh` writes the substituted value into `gsettings`, so GTK3 (Thunar) and GTK4 can diverge. `install.sh` explicitly bundles both affected families (tela-icon-theme, colloid-icon-theme-git per `06-01-PLAN.md`), so this is a live, reachable defect, not a hypothetical. UTIL-01 (emoji), UTIL-02 (color, human-UAT-confirmed pass), UTIL-03 (clipboard cap+wipe), and UTIL-05 (font switcher) are unchanged and unaffected — confirmed via regression grep (no overlap with the touched files this round). |
| 5 | Zen browser re-themes on switch; swayosd/zen/hyprlock are contract.json targets passing theme-parity (THM-05 + contract) | ✓ VERIFIED | `contract.json` unchanged, 17 entries confirmed including `hyprlock.conf`, `swayosd.css`, `zen-userchrome.css`, `satty.toml`. Live re-run this session: **theme-parity 1542 passed, 0 failed** — no regression, covers all fixtures including all 6 light presets. |
| 6 | The project's health-gate (theme-doctor) correctly validates the pipeline under both light and dark modes (phase goal's closing clause, tied to roadmap Success Criterion 1's "verified under both light and dark themes") | ✗ FAILED | **New finding, independently confirmed via source inspection.** `theme-doctor:36-37` hardcodes `gsettings gtk-theme == adw-gtk3-dark`, an exact match. `gtk.sh:22-25` deliberately sets `adw-gtk3` (no `-dark`) whenever the committed mode is `light` — confirmed directly in source. Phase 05 shipped 6 light presets. Does not manifest on THIS machine right now (committed to dark/catppuccin), but is a deterministic bug that will red-flag theme-doctor the moment any light preset is activated. Distinct from `theme-parity` (the separate script, confirmed passing across every light fixture) — the gap is specifically in the health-check tool the phase's own reproducibility story leans on. |
| 7 | A fresh install.sh run reproducibly installs every dependency regardless of AUR helper (paru or yay) | ✓ VERIFIED | `bash -n install.sh` exits 0. AUR_HELPER-parameterized cleanup lines unchanged. `vlc`, `vlc-plugins-all`, `xdg-user-dirs` confirmed present in `PACMAN_PKGS` (06-15). **Warning (not blocking):** `ffmpeg` is a direct runtime dependency of `gif-export.sh` (invoked twice, no guard) but only reaches the machine transitively via `ffmpegthumbnailer`/`vlc` — not itself listed in `PACMAN_PKGS`, so `verify_packages`'s explicit ghost-package gate cannot catch a future dependency-graph change that drops the transitive edge (06-REVIEW.md WR-11). `ffmpeg` IS present on this machine currently. |

**Score:** 3/7 truths verified (#1, #5, #7), 3/7 FAILED (#2, #4, #6 — all newly-surfaced, code-confirmed defects unaddressed by any of the 06-16..06-19 gap-closure plans), 1/7 present + wired with interactive runtime behavior not exercisable in this session (#3).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `wlogout/.config/wlogout/style.css` | Parses cleanly in GTK3, no invalid constructs | ✓ VERIFIED | 4589 bytes, 0 parse errors (live-tested) |
| `wlogout/.config/wlogout/layout` | All 6 buttons carry Nerd Font glyph text | ✓ VERIFIED | Confirmed via cat |
| `hypr/.config/hypr/config/keybinds.conf` | Volume, brightness, mic-mute all route through swayosd-client | ✗ FAILED | Volume/mute/mic-mute wired (lines 149-152); brightness NOT wired (lines 160-161, uses brightnessctl directly) |
| `theme-engine/.config/theme-engine/lib/gtk.sh` | Icon-theme substitution never silently overrides the user's pick, GTK3/GTK4 stay in sync | ✗ STUB (effectively) | Fallback branch (`installed[0]`, no sort) is the de-facto default path for Tela/Colloid due to vocabulary mismatch; overrides user pick nondeterministically; diverges from generate.sh's settings.ini write |
| `theme-engine/.config/theme-engine/theme-doctor` | Validates gtk-theme correctly in both light and dark mode | ✗ STUB (effectively) | Hardcodes dark-mode-only expected value; will false-FAIL on any of Phase 05's 6 light presets |
| `theme-engine/.config/theme-engine/contract.json` | 17 entries incl. swayosd.css, zen-userchrome.css, hyprlock.conf, satty.toml | ✓ VERIFIED | Confirmed unchanged |
| `swayosd/.config/swayosd/style.css` | Deployed under ~/.config and themes the OSD pill | ⚠️ Not deployed on this machine | Package listed in stow.sh, `stow -n swayosd` simulates cleanly (no conflicts) — dev-machine staleness, not a missing-from-code defect. theme-doctor SKIPs rather than FAILs on this condition (gate-integrity gap, WR-04). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `keybinds.conf` volume/mute/mic-mute keys | `swayosd-client` → `swayosd-server` | D-Bus | ✓ WIRED | Lines 149-152 confirmed |
| `keybinds.conf` brightness keys | `swayosd-client` | — | ✗ NOT_WIRED | Lines 160-161 call `brightnessctl` directly, bypassing swayosd entirely |
| `icon-theme-picker.sh` state file | `gtk.sh` gsettings write | `theme_engine_nearest_icon_variant` substitution | ⚠️ PARTIAL | State file correctly persists the user's pick, but gtk.sh's consumer logic can silently substitute a different (nondeterministic) value for Tela/Colloid before writing gsettings |
| `icon-theme-picker.sh` state file | `generate.sh` settings.ini write | direct passthrough | ✓ WIRED (but diverges from gtk.sh's path above) | generate.sh writes the RAW value; gtk.sh writes the SUBSTITUTED value — same theme-switch event, two different names can land in GTK3 vs GTK4 |
| `wlogout/layout` action `text` fields | rendered button labels | GTK3 `button label` CSS rule | ✓ WIRED | Glyphs populated, stylesheet now parses and the `button label { font-family; font-size: 28px }` rule applies |
| `keybinds.conf` Print-family (`code:107`) | `capture-*.sh` / `record-toggle.sh` | `bind = <mod>, code:107, exec, ...` | ✓ WIRED | `hyprctl configerrors` empty (unchanged, regression-checked) |

### Data-Flow Trace (Level 4)

Not applicable — Phase 6 artifacts are shell scripts, CSS/config templates, and systemd unit invocations, not components rendering dynamic application state from a data source.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| wlogout CSS parses in GTK3 (live deployed file) | `Gtk.CssProvider().load_from_path('~/.config/wlogout/style.css')` | 4589 bytes, 0 parse errors | ✓ PASS |
| `install.sh` and all touched-this-round scripts syntax validity | `bash -n <file>` (12 files) | exit 0 for all | ✓ PASS |
| theme-parity full contract run | `bash theme-engine/.config/theme-engine/theme-parity` | 1542 passed, 0 failed | ✓ PASS |
| theme-doctor health check | `bash theme-engine/.config/theme-engine/theme-doctor` | 39 passed, 1 failed (git-dirty only — 3 untracked files unrelated to phase code) | ✓ PASS (of what it checks; see Truth #6 for what it does NOT correctly check) |
| Brightness keys route through swayosd-client | `grep -n "XF86MonBrightness" keybinds.conf` | Both lines call `brightnessctl` directly | ✗ FAIL — confirms WR-07 |
| Icon-theme vocabulary overlap (papirus-folders enum vs Tela/Colloid installed names) | Direct source read of both enums | Disjoint vocabularies confirmed | ✗ FAIL — confirms CR-01 |
| theme-doctor gtk-theme check is mode-aware | Direct source read of `theme-doctor:36-37` vs `gtk.sh:22-25` | Hardcoded `adw-gtk3-dark`, no mode branch | ✗ FAIL — confirms CR-02 |
| All required capture/OSD binaries installed | `command -v` for 7 binaries | All present | ✓ PASS |
| Live Print-key capture / recording / satty annotate flow | (interactive, not run) | — | ? SKIP — cannot script an interactive Wayland picker without side-effect risk; routed to human verification |
| `git status --porcelain` clean | `git status --porcelain` | 3 untracked files (05-PATTERNS.md, 06-PATTERNS.md, csv) | Confirmed unrelated to phase 6 code — theme-doctor's single failure is legitimate-but-irrelevant to this phase's deliverables |

### Probe Execution

No `scripts/*/tests/probe-*.sh` convention or phase-declared probes found in this repo for Phase 6. Step 7c: SKIPPED (no probe-* scripts declared or discovered).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| WLOG-01 | 06-03, 06-16 | wlogout redesign | ✓ SATISFIED | Truth #1 — CSS-parse blocker fixed and independently confirmed |
| LOCK-01 | 06-02, 06-04, 06-12 | hyprlock redesign | ✓ SATISFIED | Truth #1, human UAT pass (unchanged) |
| OSD-01 | 06-01, 06-02, 06-06, 06-13 | SwayOSD wiring | ✗ BLOCKED | Truth #2 — brightness never routes through swayosd; REQUIREMENTS.md marks "Complete", contradicted by live grep evidence |
| THM-05 | 06-02, 06-06 | Zen browser theming | ✓ SATISFIED | Truth #5 |
| SHOT-01 | 06-01, 06-05, 06-11, 06-14 | Screenshot capture | ✓ SATISFIED (code); behavior unverified this session | Truth #3 |
| SHOT-02 | 06-02, 06-05, 06-11, 06-14 | Screenshot annotation | ✓ SATISFIED (code); behavior unverified this session | Truth #3 |
| SHOT-03 | 06-01, 06-05, 06-11, 06-14, 06-15 | Screen/region recording + GIF | ✓ SATISFIED (code); behavior unverified this session | Truth #3 |
| UTIL-01 | 06-01, 06-09 | Emoji picker | ✓ SATISFIED | Truth #4 |
| UTIL-02 | 06-01, 06-09, 06-11 | Color picker | ✓ SATISFIED | Truth #4, human UAT pass |
| UTIL-03 | 06-09 | Clipboard history cap+wipe | ✓ SATISFIED | Truth #4 |
| UTIL-04 | 06-01, 06-07, 06-10 | Icon-theme picker | ✗ BLOCKED | Truth #4 — nondeterministic fallback silently overrides user pick for Tela/Colloid; REQUIREMENTS.md marks "Complete", contradicted by source-level evidence |
| UTIL-05 | 06-01, 06-08, 06-10 | Nerd-font switcher | ✓ SATISFIED | Truth #4, regression-checked |

**No orphaned requirements** — all 12 IDs from REQUIREMENTS.md's Phase 6 mapping appear in at least one plan's `requirements:` frontmatter across all 19 plans, cross-checked directly. REQUIREMENTS.md marks all 12 "Complete" — this verification **disagrees on OSD-01 and UTIL-04**: both have code present and previously believed correct, but source-level evidence (independently confirmed here, not merely taken from 06-REVIEW.md's word) proves each does not fully deliver what its Success Criterion describes. Neither checkbox should be trusted until the corresponding fix lands and is re-verified.

### Anti-Patterns Found

No `TBD`/`FIXME`/`XXX` markers found in any phase-6 file. `TODO`/`HACK`/`PLACEHOLDER` also absent. `mktemp ... XXXXXX` template patterns in color-picker.sh, wallpaper-picker.sh, font-switcher.sh, icon-theme-picker.sh are `mktemp`'s own placeholder syntax, not debt markers.

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `hypr/.config/hypr/config/keybinds.conf` | 160-161 | Brightness keys bypass swayosd-client entirely | 🛑 **Blocker** (WR-07, new) | Half of "volume, brightness, caps-lock" OSD-01 promise unmet — see Truth #2 |
| `theme-engine/.config/theme-engine/lib/gtk.sh` | 389-416 | Icon-theme fallback vocabulary mismatch + nondeterministic override + GTK3/GTK4 write desync | 🛑 **Blocker** (CR-01, new) | UTIL-04's "applies to Thunar/GTK live" broken for Tela/Colloid, both explicitly bundled — see Truth #4 |
| `theme-engine/.config/theme-engine/theme-doctor` | 36-37 | Hardcoded `adw-gtk3-dark` check, no mode branch | 🛑 **Blocker** (CR-02, new) | Health gate false-fails on every Phase-05 light preset — see Truth #6 |
| `theme-engine/.config/theme-engine/theme-doctor` | 233-258 | GTK4 half of the new CSS-parse guard (06-19) is a no-op — connects no `parsing-error` signal, GTK4 never empties a provider on a rule error | ⚠️ Warning (WR-02, new) | 3 GTK4 sheets (walker, swayosd, gtk-4.0) get zero parse-error detection despite the guard's comment claiming coverage |
| `theme-engine/.config/theme-engine/theme-doctor` | 226-228 | `[SKIP]` (not `[FAIL]`) when a pipeline-owned stylesheet is absent from `~/.config` | ⚠️ Warning (WR-04, new) | A completely unthemed, undeployed surface can pass the health gate green — reproduced live for swayosd/style.css on this machine |
| `theme-engine/.config/theme-engine/lib/reload.sh` | 33 | Headless guard uses `&&` (needs both vars empty) instead of checking `WAYLAND_DISPLAY` alone | ⚠️ Warning (WR-01, new — reintroduces the INST-03 hang risk on a real TTY login where D-Bus is set but no compositor is running) | Guard defeated in the exact scenario it was added for |
| `theme-engine/.config/theme-engine/lib/reload.sh` | 167 | Zen self-heal `ln -sf` unconditionally unlinks any pre-existing `userChrome.css` with no backup | ⚠️ Warning (WR-08, new) | A user's hand-written userChrome.css is destroyed unrecoverably on the first theme switch |
| `hypr/.config/hypr/scripts/emoji-picker.sh` | 229-240 | Claims "typed and copied" even on the wtype-absent copy-only degraded path | ⚠️ Warning (WR-09, new) | Misleading notification; also `wl-copy` unguarded |
| `install.sh` | (PACMAN_PKGS) | `ffmpeg` reaches the machine only transitively (via ffmpegthumbnailer/vlc), not declared directly despite being a hard dependency of `gif-export.sh` | ⚠️ Warning (WR-11, new) | `verify_packages`'s ghost-package gate cannot catch a future graph change that drops the transitive edge |
| `swayosd/.config/swayosd/style.css` | 35-47 | Omits `segmentedprogress`/`segment`/`:disabled` selectors the installed swayosd 0.3.1 actually renders | ⚠️ Warning (WR-05, new) | Segmented volume indicator and the muted-state visual cue fall back to unthemed GTK4 defaults |
| `hypr/.config/hypr/scripts/clipboard-wipe.sh` | 11-38 | Confirm dialog can render, then the destructive `cliphist wipe` call dies at exit 127 with no notification if cliphist is absent | ⚠️ Warning (WR-06, new) | User believes a wipe succeeded when the script actually crashed silently |

### Human Verification Required

None required as a blocking item this round — all remaining `human_needed`-class items are captured in `behavior_unverified_items` (Step 3/8) rather than as separate human-verification asks, since Step 9's decision tree routes to `gaps_found` regardless (3 FAILED truths outrank the 1 present-behavior-unverified truth). The SHOT-01/02/03 interactive flow should still be exercised by a human once the 3 gaps above are closed:

### 1. Live Print-key capture/annotate/record flow

**Test:** Press Print / Shift+Print / Ctrl+Print / Alt+Print and exercise the full capture → satty annotate → save+copy flow; drag-record a region and a full monitor via Alt+Print, export a GIF, and play the .mp4 back in VLC.
**Expected:** Each Print-key variant fires; satty opens, annotates, saves + copies with one notification; recordings and GIFs play back without a missing-decoder error.
**Why human:** Interactive Wayland capture UI, not scriptable without side-effect/hang risk.

### Gaps Summary

**Three new Critical/Blocker-class defects, all surfaced by the fresh `06-REVIEW.md` and independently confirmed here via direct source and live-system inspection, prevent `passed` status this round:**

1. **OSD-01 half-delivered (WR-07):** brightness keys bypass `swayosd-client` entirely — confirmed by grep — so the roadmap's literal "Volume, brightness, and caps-lock" wording is only 2/3 true. `swayosd/style.css` is also not currently deployed on this dev machine (staleness, not a code gap), and `theme-doctor`'s `[SKIP]` on that condition (WR-04) means the health gate cannot catch this class of problem even when it does occur in the field.

2. **UTIL-04 icon-theme picker is silently unreliable for the bundled Tela/Colloid families (CR-01):** a vocabulary mismatch between the color-matching logic and the actual installed variant names makes the nondeterministic fallback the de-facto default path, silently overriding the user's explicit pick on every theme switch, and can desync GTK3 (Thunar) from GTK4.

3. **The project's own health gate cannot validate light mode (CR-02):** `theme-doctor` hardcodes a dark-mode-only expected GTK theme value, so it will false-FAIL on every one of Phase 05's six light presets — directly undermining the phase goal's own closing clause ("validated by theme-parity under both light and dark"), even though the separate `theme-parity` script itself does pass cleanly across all light and dark fixtures (1542/0, confirmed live).

**The previous round's sole blocker (WLOG-01) is genuinely and completely fixed** — independently re-verified via a live GTK3 CSS parse of the deployed stylesheet (4589 bytes, 0 errors, was 0 bytes / 8 errors). 06-17 and 06-18's warning fixes are also independently confirmed present and correct in source, with no regressions detected in theme-parity (1542/0, unchanged) or in any of the 12 syntax-checked scripts.

**SHOT-01/02/03's live interactive flow remains unexercised** (unchanged from every prior round — same class of risk, no safe non-mutating test available) and is tracked as `behavior_unverified`, not a blocker.

**Recommended next step:** a small gap-closure plan addressing WR-07 (rebind brightness keys through `swayosd-client`), CR-01 (fix the icon-variant fallback per 06-REVIEW.md's documented patch), and CR-02 (make `theme-doctor`'s gtk-theme check mode-aware) — all three fixes are narrowly scoped and independently described with concrete patches in `06-REVIEW.md`. WR-04 (SKIP→FAIL for undeployed pipeline-owned stylesheets) is a natural companion fix to WR-07 since it closes the exact blind spot that let the brightness gap ship unnoticed.

---

_Verified: 2026-07-13T08:10:00Z_
_Verifier: Claude (gsd-verifier)_
