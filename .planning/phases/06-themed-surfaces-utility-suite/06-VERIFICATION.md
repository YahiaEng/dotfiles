---
phase: 06-themed-surfaces-utility-suite
verified: 2026-07-13T08:35:00Z
status: human_needed
score: 6/7 must-haves verified
behavior_unverified: 1
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/7
  gaps_closed:
    - "OSD-01 (roadmap Success Criterion 2): brightness keys now route through swayosd-client. `keybinds.conf` lines 160-161 rebound from bare `brightnessctl -e4 -n2 set 5%±` to `swayosd-client --brightness raise` / `--brightness lower` (commit b878e31). Independently confirmed: `swayosd-client --help` lists `--brightness <raise|lower|(±)number>` as a real flag; `hyprctl configerrors` is empty (no bind-syntax regression); D-25's DDC descope preserved (no ddcutil calls added, comment updated to say laptop-backlight-only)."
    - "UTIL-04 (roadmap Success Criterion 4): icon-theme picker no longer silently overrides the user's pick. `theme_engine_nearest_icon_variant` (gtk.sh) now sorts enumerated variants (`mapfile -t installed < <(printf '%s\\n' \"${installed[@]}\" | sort -u)`) and returns nothing on no-exact-match instead of `installed[0]` (commit 0aaeffb). Independently confirmed the call site (gtk.sh:306-307) already treats an empty return as 'keep the user's pick' (`[[ -n \"$found\" ]] && nearest=\"$found\"` — nearest defaults to `$icon_theme`, the user's own value)."
    - "Phase goal's closing clause / roadmap Success Criterion 1 ('verified under both light and dark'): theme-doctor's gtk-theme check is now mode-aware (commit 128ea5b). Independently reproduced by simulating light mode live on this machine: with `$STATE_DIR/mode`=light and `gsettings gtk-theme`=adw-gtk3, theme-doctor printed `[PASS] gsettings gtk-theme = adw-gtk3 (mode=light, got: adw-gtk3)` instead of false-failing. State restored to the machine's real dark/catppuccin mode afterward, confirmed via `git diff` showing no residual change to tracked files."
    - "WR-02 (GTK4 CSS-parse guard no-op): both GTK3 and GTK4 halves of theme-doctor's CSS-parse guard now connect `parsing-error` (commit 128ea5b, same commit as the CR-02 fix). Independently reproduced end-to-end: appended an invalid selector to the live `gtk-4.0/gtk.css`, ran the exact Python snippet theme-doctor uses, and confirmed `parsing-error` fired and populated the fatal list (previously this branch was skipped entirely for GTK4, per the commit's own admission that `GObject.signal_list_ids` on the un-instantiated GType returns `[]` — but the guard connects on an instantiated `Gtk.CssProvider()`, where the signal is registered and does fire, confirmed live). File reverted after the test; `git diff --stat` on the file confirms clean."
  gaps_remaining: []
  regressions: []
gaps: []
deferred: []
behavior_unverified_items:
  - truth: "User can capture region/window/full-screen screenshots (animation, freeze, save + copy, notification), annotate them (arrows/text/shapes/blur), and record screen/region to video with GIF export (SHOT-01/02/03, roadmap Success Criterion 3)"
    test: "Press Print / Shift+Print / Ctrl+Print / Alt+Print and exercise the full capture -> satty annotate -> save+copy flow; drag-record a region and a full monitor via Alt+Print, export a GIF from the resulting notification, and play the .mp4 back in VLC."
    expected: "Each Print-key variant fires (code:107 bind); hyprshot --raw pipes a valid raw image into satty; satty opens, annotates, saves to ~/Pictures/Screenshots, and copies with exactly one notification; gpu-screen-recorder starts/stops cleanly; the exported GIF and the .mp4 both play back without a missing-codec error."
    why_human: "Interactive Wayland capture UI (region-select, satty's annotate toolbar) requires a real keypress-driven interaction that cannot be safely scripted without risking a hang or an unintended file/clipboard side effect. Unchanged since the 06-14/06-15 fixes shipped this flow; no code touched by this round's 3 fix commits affects SHOT-01/02/03 (confirmed via `git diff --stat` — capture/record/annotate scripts are absent from the changed-file list)."
human_verification:
  - test: "Press Print / Shift+Print / Ctrl+Print / Alt+Print and exercise the full capture -> satty annotate -> save+copy flow; drag-record a region and a full monitor via Alt+Print, export a GIF from the resulting notification, and play the .mp4 back in VLC."
    expected: "Each Print-key variant fires (code:107 bind); hyprshot --raw pipes a valid raw image into satty; satty opens, annotates, saves to ~/Pictures/Screenshots, and copies with exactly one notification; gpu-screen-recorder starts/stops cleanly; the exported GIF and the .mp4 both play back without a missing-codec error."
    why_human: "Interactive Wayland capture UI cannot be safely scripted."
---

# Phase 6: Themed Surfaces & Utility Suite Verification Report

**Phase Goal:** Every remaining desktop surface is redesigned and re-themed, and a full suite of everyday utility tools ships — all following the established @import-from-state-dir pattern and validated by theme-parity under both light and dark.
**Verified:** 2026-07-13T08:35:00Z
**Status:** human_needed
**Re-verification:** Yes — round 6, after gap-closure commits `b878e31` (OSD-01 brightness routing), `0aaeffb` (UTIL-04 icon-variant fallback), and `128ea5b` (CR-02 mode-aware theme-doctor + WR-02 GTK4 CSS-parse guard). All three blockers from the previous round (`06-VERIFICATION.md` round 5) are independently confirmed fixed. **This verification is scoped exclusively to the 12 requirement IDs (WLOG-01, LOCK-01, OSD-01, THM-05, SHOT-01/02/03, UTIL-01..05) and the 5 roadmap Success Criteria, per explicit scope-boundary instruction** — findings outside that scope (code-quality warnings that don't break a requirement, pre-existing debt) are reported separately below and do NOT affect the score.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | wlogout and hyprlock both show a modern redesigned look with colors sourced live from the pipeline, verified under light and dark, hyprlock tested via documented lockout-recovery procedure (WLOG-01, LOCK-01, Success Criterion 1) | ✓ VERIFIED | Unchanged since round 5 (no regression — confirmed via `git diff --stat`, wlogout/hyprlock files untouched by the 3 fix commits). `wlogout/style.css` still parses cleanly (0 errors), `wlogout/layout` glyphs still populated. `hyprlock.conf` still sources theme hex live; lockout-recovery UAT previously documented in `06-UAT.md`. |
| 2 | Volume, brightness, and caps-lock changes show a themed SwayOSD indicator bound to media keys, re-themed by the pipeline (OSD-01, Success Criterion 2) | ✓ VERIFIED | **Gap closed, independently re-confirmed.** `keybinds.conf` lines 149-152 (volume/mute/mic-mute) and now lines 160-161 (brightness) all route through `swayosd-client`. Live-tested `swayosd-client --help` confirms `--brightness <raise\|lower\|(±)number>` is a real, documented flag. `hyprctl configerrors` returns empty (no bind-syntax regression). D-25's DDC (external-monitor) descope preserved — no ddcutil calls added; this is the laptop-backlight path only, as the updated code comment states. |
| 3 | User can capture region/window/full-screen screenshots (freeze, save+copy, notification), annotate (arrows/text/shapes/blur), record screen/region to video with GIF export (SHOT-01/02/03, Success Criterion 3) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Unchanged since round 5 — no regression (files untouched by this round's fixes, confirmed via `git diff --stat`). Code present, wired, previously spot-checked (`bash -n` clean, `hyprctl configerrors` empty, `hyprshot ... --raw \| satty ...` piping confirmed via grep). Live interactive flow cannot be safely scripted; routed to human verification per harness_state_ground_truth instruction — this is its correct standing classification, not a regression or a gap. |
| 4 | User can invoke emoji/color/clipboard-history/icon-theme/nerd-font pickers; icon-theme picker applies to Thunar/GTK live (UTIL-01..05, Success Criterion 4) | ✓ VERIFIED | **Gap closed (UTIL-04), independently re-confirmed.** `theme_engine_nearest_icon_variant` (gtk.sh) now sorts enumerated variants for determinism and returns nothing on no-exact-match instead of an arbitrary `installed[0]`. Confirmed the call site already reads an empty return as "keep the user's pick" (`nearest` defaults to the user's `$icon_theme`, only overwritten `[[ -n "$found" ]]`). UTIL-01 (emoji), UTIL-02 (color picker, previously human-UAT-confirmed), UTIL-03 (clipboard cap+wipe), UTIL-05 (font switcher) unaffected — confirmed unchanged via `git diff --stat` (not present in this round's touched-file list). |
| 5 | Zen re-themes on switch (matugen userChrome.css, restart reload); swayosd, zen, hyprlock are contract.json targets passing theme-parity (THM-05, Success Criterion 5) | ✓ VERIFIED | Unchanged since round 5 — `contract.json` untouched, still 17 entries incl. `hyprlock.conf`, `swayosd.css`, `zen-userchrome.css`, `satty.toml`. Live re-run this session: **theme-parity 1542 passed, 0 failed** — no regression, all fixtures including all 6 light presets. |
| 6 | The project's health gate (theme-doctor) correctly validates the pipeline under both light and dark modes (phase goal's closing clause, Success Criterion 1's "verified under both light and dark") | ✓ VERIFIED | **Gap closed (CR-02), independently re-confirmed via live mode simulation.** theme-doctor now reads `$STATE_DIR/mode` and expects `adw-gtk3-dark` in dark / `adw-gtk3` in light — same source of truth `gtk.sh` uses. Live test: simulated light mode (`mode`=light, `gsettings gtk-theme`=adw-gtk3) → theme-doctor printed `[PASS] gsettings gtk-theme = adw-gtk3 (mode=light, got: adw-gtk3)`, correctly NOT false-failing. State restored to the machine's real dark mode afterward; `git diff` confirms no residual tracked-file change. **Bonus fix independently verified (WR-02, same commit):** GTK4 half of the CSS-parse guard now actually connects `parsing-error` — live-reproduced end-to-end by injecting an invalid selector into the deployed `gtk-4.0/gtk.css`, running theme-doctor's exact Python snippet, and confirming the signal fired and populated the fatal list (file reverted, confirmed clean via `git diff --stat`). |
| 7 | theme-parity passes across the full contract under both light and dark, evidencing the @import-from-state-dir pattern holds for every themed surface | ✓ VERIFIED | Live re-run this session: **theme-parity 1542 passed, 0 failed.** Consistent with the harness-state ground truth provided. |

**Score:** 6/7 truths verified (#1, #2, #4, #5, #6, #7 — all previously-failing truths now closed and independently re-confirmed), 1/7 present + wired with interactive runtime behavior not exercisable in this session (#3, SHOT-01/02/03 — correctly classified as `behavior_unverified`, not a gap).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `hypr/.config/hypr/config/keybinds.conf` | Volume, brightness, mic-mute all route through swayosd-client | ✓ VERIFIED | Lines 149-152 (volume/mute/mic-mute) and 160-161 (brightness, newly fixed) all call `swayosd-client`. `hyprctl configerrors` empty. |
| `theme-engine/.config/theme-engine/lib/gtk.sh` | Icon-theme substitution never silently overrides the user's pick, GTK3/GTK4 stay in sync | ✓ VERIFIED | Sorted enumeration + empty-on-no-match fallback confirmed in source; call site's "empty means keep user pick" behavior confirmed by reading the calling code. |
| `theme-engine/.config/theme-engine/theme-doctor` | Validates gtk-theme correctly in both light and dark mode; GTK4 CSS-parse guard has real teeth | ✓ VERIFIED | Live-tested both mode branches; live-tested GTK4 parsing-error firing on an injected bad selector. |
| `theme-engine/.config/theme-engine/contract.json` | 17 entries incl. swayosd.css, zen-userchrome.css, hyprlock.conf, satty.toml | ✓ VERIFIED | Unchanged, confirmed present. |
| `wlogout/.config/wlogout/style.css`, `wlogout/.config/wlogout/layout` | Parses cleanly, glyphs populated | ✓ VERIFIED | Unchanged since round 5, no regression. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `keybinds.conf` volume/mute/mic-mute/brightness keys | `swayosd-client` → `swayosd-server` | D-Bus | ✓ WIRED | All four channels now confirmed routed through swayosd-client; `swayosd-client --brightness` confirmed a real, documented flag. |
| `icon-theme-picker.sh` state file | `gtk.sh` gsettings write | `theme_engine_nearest_icon_variant` substitution | ✓ WIRED | Empty-return-on-no-match now correctly preserves the user's pick at the call site — confirmed by reading gtk.sh:303-309. |
| `theme-doctor` gtk-theme check | `$STATE_DIR/mode` | direct read, same source gtk.sh uses | ✓ WIRED | Live-tested both mode values produce the mode-correct expected string. |
| `theme-doctor` GTK4 CSS-parse guard | `Gtk.CssProvider` `parsing-error` signal | `provider.connect("parsing-error", ...)` | ✓ WIRED | Live-reproduced: signal fires on an instantiated provider and populates the fatal list for a genuinely bad GTK4 rule. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| theme-parity full contract run | `bash theme-engine/.config/theme-engine/theme-parity` | 1542 passed, 0 failed | ✓ PASS |
| theme-doctor mode-awareness — dark mode | `bash theme-doctor` (real machine state) | `[PASS] gsettings gtk-theme = adw-gtk3-dark (mode=dark, got: adw-gtk3-dark)` | ✓ PASS |
| theme-doctor mode-awareness — simulated light mode | mode file + gsettings set to light values, then `bash theme-doctor` | `[PASS] gsettings gtk-theme = adw-gtk3 (mode=light, got: adw-gtk3)` (state restored after) | ✓ PASS |
| GTK4 CSS-parse guard fires on a real bad selector | Injected invalid selector into live `gtk-4.0/gtk.css`, ran theme-doctor's exact python snippet | `parsing-error` fired, fatal list populated, css_len=0 (file reverted after) | ✓ PASS |
| `swayosd-client --brightness` is a real flag | `swayosd-client --help \| grep brightness` | `--brightness <raise\|lower\|(±)number>` documented | ✓ PASS |
| Brightness/volume/mute/mic-mute keys all route through swayosd-client | `grep -n "XF86" keybinds.conf` | All four bound to `swayosd-client` | ✓ PASS |
| `hyprctl configerrors` clean after keybinds.conf edit | `hyprctl configerrors` | empty output, exit 0 | ✓ PASS |
| `bash -n` syntax check on touched files | `bash -n theme-doctor && bash -n gtk.sh` | both exit 0 | ✓ PASS |
| No debt markers (TBD/FIXME/XXX) in touched files | `grep -n "TBD\|FIXME\|XXX"` on keybinds.conf, gtk.sh, theme-doctor | no matches | ✓ PASS |
| Live Print-key capture/annotate/record flow | (interactive, not run) | — | ? SKIP — routed to human verification, unchanged since round 5 |

### Probe Execution

No `scripts/*/tests/probe-*.sh` convention or phase-declared probes found in this repo for Phase 6. Step 7c: SKIPPED (no probe-* scripts declared or discovered).

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|--------------|--------|----------|
| WLOG-01 | wlogout redesign | ✓ SATISFIED | Truth #1 — unchanged from round 5, still passing |
| LOCK-01 | hyprlock redesign | ✓ SATISFIED | Truth #1 — unchanged from round 5, still passing |
| OSD-01 | SwayOSD wiring (volume, brightness, caps-lock) | ✓ SATISFIED | Truth #2 — gap closed this round, independently re-confirmed |
| THM-05 | Zen browser theming | ✓ SATISFIED | Truth #5 — unchanged from round 5, still passing |
| SHOT-01 | Screenshot capture | ✓ SATISFIED (code); behavior unverified this session | Truth #3 |
| SHOT-02 | Screenshot annotation | ✓ SATISFIED (code); behavior unverified this session | Truth #3 |
| SHOT-03 | Screen/region recording + GIF | ✓ SATISFIED (code); behavior unverified this session | Truth #3 |
| UTIL-01 | Emoji picker | ✓ SATISFIED | Truth #4 — unchanged from round 5, still passing |
| UTIL-02 | Color picker | ✓ SATISFIED | Truth #4 — unchanged, human-UAT-confirmed previously |
| UTIL-03 | Clipboard history cap+wipe | ✓ SATISFIED | Truth #4 — unchanged from round 5, still passing |
| UTIL-04 | Icon-theme picker | ✓ SATISFIED | Truth #4 — gap closed this round, independently re-confirmed |
| UTIL-05 | Nerd-font switcher | ✓ SATISFIED | Truth #4 — unchanged from round 5, still passing |

**All 12 requirement IDs accounted for.** REQUIREMENTS.md marks all 12 "Complete" — this verification now **agrees on all 12**, closing the disagreement round 5 raised on OSD-01 and UTIL-04.

### Anti-Patterns Found (in-scope files only)

No `TBD`/`FIXME`/`XXX` debt markers in any of the three files touched by this round's fix commits (`keybinds.conf`, `gtk.sh`, `theme-doctor`). No new placeholder/stub patterns introduced.

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | none found in touched files | — | — |

### Pre-existing Debt (NOT phase gaps)

Per the mandatory scope boundary, these are reported for visibility only and do NOT affect the pass/fail score — none breaks any of the 12 requirement IDs or the 5 success criteria, and/or they predate this round's fix commits:

| Item | Requirement affected? | Notes |
|------|------------------------|-------|
| `swayosd/style.css` not currently deployed under `~/.config` on this dev machine | None directly — OSD-01 is satisfied because the theme correctly applies once stowed; this is dev-machine deployment staleness, not a code defect | `swayosd` is listed in `stow.sh`/`install.sh`; `stow -n swayosd` simulates cleanly. theme-doctor `[SKIP]`s (not FAILs) on this condition — a pre-existing gate-integrity warning (WR-04) noted in round 5, not one of the 3 blockers fixed this round, and does not break any of the 12 requirements as currently deployed/tested. |
| `wallpapers/Pictures/Wallpapers/current.jpg` symlink target differs from HEAD (git status shows it modified) | None — unrelated to any of the 12 requirements; the wallpaper symlink pattern itself predates Phase 6 (introduced in commit `49536d5`, Phase 3) | Local dev-machine state drift from prior wallpaper-picker testing sessions (Phase 5), not phase-6 code. |
| Untracked `05-PATTERNS.md`, `06-PATTERNS.md`, `csv` files causing theme-doctor's single remaining `[FAIL]` (`git status --porcelain is empty`) | None — theme-doctor's git-cleanliness check is a general repo-hygiene gate, not tied to any specific one of the 12 requirements | Per harness_state_ground_truth: not a code defect. `csv` is confirmed leftover nvidia-smi output, unrelated to this phase. |
| WR-04 (theme-doctor `[SKIP]` vs `[FAIL]` on undeployed pipeline-owned stylesheet), WR-05 (swayosd.css missing segmentedprogress selectors), WR-06 (clipboard-wipe.sh silent crash on missing cliphist), WR-08 (Zen userChrome.css unlinked with no backup), WR-09 (emoji-picker misleading notification on degraded path), WR-11 (ffmpeg only a transitive dependency in install.sh) | None of these break any of the 12 requirement IDs as currently deployed and tested | Carried forward from `06-REVIEW.md`, unresolved by this round's fix commits (out of scope per the round 5 blocker set of 3), correctly classified as code-quality warnings, not gaps. |

### Human Verification Required

### 1. Live Print-key capture/annotate/record flow

**Test:** Press Print / Shift+Print / Ctrl+Print / Alt+Print and exercise the full capture → satty annotate → save+copy flow; drag-record a region and a full monitor via Alt+Print, export a GIF, and play the .mp4 back in VLC.
**Expected:** Each Print-key variant fires; satty opens, annotates, saves + copies with one notification; recordings and GIFs play back without a missing-decoder error.
**Why human:** Interactive Wayland capture UI (region-select, satty's annotate toolbar), not scriptable without side-effect/hang risk. Unchanged since round 5 — no regression, no new risk introduced by this round's 3 fix commits (none touch the capture/annotate/record scripts).

### Gaps Summary

**All three blockers from the previous verification round are confirmed fixed, independently, against live code and live-system behavior — not merely against the fix commits' own claims:**

1. **OSD-01 (brightness bypass) — fixed and confirmed.** `keybinds.conf` now routes brightness through `swayosd-client --brightness raise/lower`, live-verified as a real, working flag. D-25's DDC descope preserved.

2. **UTIL-04 (icon-variant silent override) — fixed and confirmed.** `theme_engine_nearest_icon_variant` no longer returns a nondeterministic `installed[0]` fallback; it returns nothing on no-match, and the call site already reads that correctly as "keep the user's pick" — confirmed by reading the actual calling code, not just the fixed function.

3. **Health-gate light-mode false-fail (CR-02) — fixed and confirmed via live simulation.** theme-doctor is now mode-aware; independently reproduced passing in a simulated light-mode state on this machine, with the tracked file restored afterward (`git diff` clean).

4. **Bonus: WR-02 (GTK4 CSS-parse guard no-op) — fixed and confirmed via live injection test.** Connecting `parsing-error` on an instantiated `Gtk.CssProvider` does fire under GTK4, contrary to the prior code's comment; reproduced end-to-end with a real bad selector injected into the deployed `gtk-4.0/gtk.css` and reverted cleanly.

**No new gaps or regressions were introduced by this round's 3 fix commits.** All previously-passing truths (#1, #5, #7 in round 5's numbering) remain unaffected — confirmed via `git diff --stat` showing none of their supporting files were touched.

**Status is `human_needed`, not `passed`, only because of the pre-existing, correctly-classified `behavior_unverified` item for SHOT-01/02/03's live interactive flow** (Success Criterion 3) — this is unchanged since round 5, is not a regression, and per the decision tree in the verification process, any non-empty human-verification list routes to `human_needed` even when every other truth is verified. All 12 in-scope requirement IDs and all 5 roadmap Success Criteria are otherwise fully satisfied.

**Recommended next step:** Have a human exercise the Print-key capture/annotate/record flow per the item above. Once confirmed, this phase is ready to ship — no further code changes are indicated by this verification round.

---

_Verified: 2026-07-13T08:35:00Z_
_Verifier: Claude (gsd-verifier)_
