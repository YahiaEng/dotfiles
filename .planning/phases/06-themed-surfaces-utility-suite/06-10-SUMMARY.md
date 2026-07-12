---
phase: 06-themed-surfaces-utility-suite
plan: 10
subsystem: theming
tags: [hyprland, waybar, kitty, theme-engine, fzf, contract-testing]

# Dependency graph
requires:
  - phase: 06-themed-surfaces-utility-suite
    provides: icon-theme-picker.sh (06-07), font-switcher.sh (06-08), theme-engine font.sh axis (06-08)
provides:
  - Floating-kitty launcher wrappers giving both fzf pickers a controlling TTY (CR-02 closed)
  - waybar-font.css as the sole font-family owner across all three waybar layouts (CR-01 closed)
  - theme-doctor presence coverage for the two font render targets (WR-07 closed)
affects: [06-11, 06-12, phase-06-secure-phase, phase-06-verify-work]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Floating-kitty launcher wrapper (uwsm app -- kitty --class ... -- <script>) as the standard pattern for giving a TTY-dependent fzf picker script a controlling terminal, now used by wallpaper-switch.sh, icon-theme-switch.sh, font-switch.sh"
    - "presence_only_files in contract.json for state-dir fragments that need existence checks but have no color-declaration content suitable for theme-parity's semantic-value parity layer"

key-files:
  created:
    - hypr/.config/hypr/scripts/icon-theme-switch.sh
    - hypr/.config/hypr/scripts/font-switch.sh
  modified:
    - hypr/.config/hypr/config/keybinds.conf
    - hypr/.config/hypr/config/windowrules.conf
    - waybar/.config/waybar/style-full.css
    - waybar/.config/waybar/style-minimal.css
    - waybar/.config/waybar/style-floating.css
    - theme-engine/.config/theme-engine/lib/font.sh
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/lib/contract.sh
    - theme-engine/.config/theme-engine/theme-doctor

key-decisions:
  - "Font render targets (kitty-font.conf, waybar-font.css) added to a new presence_only_files array, kept OUT of contract.json's files array — they carry no color-declaration content that theme-parity's name-set/semantic-value parity extractors require, so adding them there would break the parity gate rather than extend it"
  - "Wrapper scripts mirror wallpaper-switch.sh's exact shape (uwsm app -- kitty --class ... -o background_opacity=0.85 -o font_size=11 -- <picker>) rather than inventing a new launcher pattern"

patterns-established:
  - "Any future TTY-dependent fzf picker gets its own <name>-switch.sh floating-kitty wrapper + matching windowrule, keybinds point at the wrapper not the raw picker script"

requirements-completed: [UTIL-04, UTIL-05]

coverage:
  - id: D1
    description: "Super+Shift+Z opens a floating kitty running icon-theme-picker.sh (real TTY, kitten icat previews work)"
    requirement: "UTIL-04"
    verification:
      - kind: unit
        ref: "test -x icon-theme-switch.sh && bash -n icon-theme-switch.sh && grep icon-theme-picker.sh in wrapper && grep wrapper path in keybinds.conf && grep windowrule class in windowrules.conf"
        status: pass
    human_judgment: true
    rationale: "Automated checks confirm the wiring (executable, syntactically valid, keybind retargeted, windowrule present) but cannot confirm the actual Hyprland runtime behavior (floating kitty opens, fzf renders, icat preview displays) without a live compositor session"
  - id: D2
    description: "Super+Shift+X opens a floating kitty running font-switcher.sh (real TTY, live font specimen preview works)"
    requirement: "UTIL-05"
    verification:
      - kind: unit
        ref: "test -x font-switch.sh && bash -n font-switch.sh && grep font-switcher.sh in wrapper && grep wrapper path in keybinds.conf && grep windowrule class in windowrules.conf"
        status: pass
    human_judgment: true
    rationale: "Automated checks confirm the wiring but cannot confirm live Hyprland runtime behavior without a graphical session"
  - id: D3
    description: "A font switch actually changes waybar's font on full/minimal/floating layouts because waybar-font.css is the sole font-family owner"
    requirement: "UTIL-05"
    verification:
      - kind: unit
        ref: "grep -c font-family returns 0 in all three style-*.css files; waybar-font.css @import retained; font.sh bash -n passes"
        status: pass
    human_judgment: true
    rationale: "Static CSS analysis confirms the shadowing literal is gone and the import is retained, but confirming the rendered font actually appears different in a running waybar process requires a live visual check"
  - id: D4
    description: "theme-doctor presence-checks kitty-font.conf and waybar-font.css without affecting theme-parity's 0-failed color-contract run"
    verification:
      - kind: unit
        ref: "jq presence_only_files == kitty-font.conf,waybar-font.css; contract_files count unchanged at 17; theme-parity headless run: 1542 passed, 0 failed"
        status: pass
    human_judgment: false

# Metrics
duration: 8min
completed: 2026-07-12
status: complete
---

# Phase 06 Plan 10: Gap Closure — Picker TTY Wiring, Waybar Font Ownership, theme-doctor Font Presence Summary

**Closed CR-02 (fzf pickers had no controlling TTY), CR-01 (waybar's hardcoded font-family literal shadowed the font-switch mechanism), and WR-07 (theme-doctor had no presence coverage for font render targets) — the invocation and render-sink bugs blocking UTIL-04/UTIL-05 are now fixed.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-12T19:29:00Z (approx, per STATE.md init timestamp)
- **Completed:** 2026-07-12T19:37:00Z
- **Tasks:** 3
- **Files modified:** 11 (2 created, 9 modified)

## Accomplishments
- icon-theme-switch.sh and font-switch.sh wrap their respective fzf pickers in `uwsm app -- kitty`, mirroring wallpaper-switch.sh's precedent exactly — both pickers now have a real controlling TTY
- Super+Shift+Z and Super+Shift+X keybinds retargeted at the new wrappers; matching float windowrules added for the `icon-theme-picker` and `font-switcher` kitty classes
- Removed the hardcoded `font-family` literal from all three waybar stylesheets (style-full.css, style-minimal.css, style-floating.css) — waybar-font.css (the @import'd render target) is now the sole owner of waybar's font-family, so font switches actually propagate
- Added `presence_only_files` to contract.json + `contract_presence_only_files()` helper in contract.sh + a second presence-check loop in theme-doctor, giving the two theme-invariant font fragments (kitty-font.conf, waybar-font.css) health-gate coverage without touching theme-parity's color-contract `files` array
- Verified theme-parity still reports 0 failed (1542 passed) after the contract.json change — no regression

## Task Commits

Each task was committed atomically:

1. **Task 1: Give the icon-theme and font pickers a controlling TTY via floating-kitty launcher wrappers (CR-02)** - `788563d` (feat)
2. **Task 2: Remove the waybar font-family literal so waybar-font.css owns the font (CR-01)** - `8b4d21e` (fix)
3. **Task 3: Add theme-doctor presence coverage for the font render targets without touching the parity gate (WR-07)** - `0ac9676` (feat)

**Plan metadata:** (to follow — final docs commit)

## Files Created/Modified
- `hypr/.config/hypr/scripts/icon-theme-switch.sh` - NEW floating-kitty launcher wrapper (class `icon-theme-picker`) running icon-theme-picker.sh
- `hypr/.config/hypr/scripts/font-switch.sh` - NEW floating-kitty launcher wrapper (class `font-switcher`) running font-switcher.sh
- `hypr/.config/hypr/config/keybinds.conf` - Super+Shift+Z/X binds retargeted at the two new wrappers
- `hypr/.config/hypr/config/windowrules.conf` - added float windowrules for `icon-theme-picker` and `font-switcher` classes
- `waybar/.config/waybar/style-full.css` - removed shadowing `font-family` line from local `* {}` block
- `waybar/.config/waybar/style-minimal.css` - removed shadowing `font-family` line from local `* {}` block
- `waybar/.config/waybar/style-floating.css` - removed shadowing `font-family` line from local `* {}` block
- `theme-engine/.config/theme-engine/lib/font.sh` - corrected stale comment describing waybar-font.css cascade ordering (no longer load-bearing since the local literal is gone)
- `theme-engine/.config/theme-engine/contract.json` - added `presence_only_files: [kitty-font.conf, waybar-font.css]`
- `theme-engine/.config/theme-engine/lib/contract.sh` - added `contract_presence_only_files()` helper
- `theme-engine/.config/theme-engine/theme-doctor` - added second presence-check loop over `contract_presence_only_files`

## Decisions Made
- Font render targets kept out of contract.json's `files` array and placed in a new `presence_only_files` array instead, since they have no color-declaration content theme-parity's extractors require — this avoids breaking the currently-green parity gate while still closing the presence-coverage gap
- Wrapper scripts replicate wallpaper-switch.sh's exact shape rather than introducing a new launcher pattern, keeping the codebase's picker-invocation convention consistent

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CR-01, CR-02, and WR-07 gaps from 06-REVIEW.md are now closed; UTIL-04 and UTIL-05 are fully reachable and effective
- Remaining gap-closure plans 06-11 and 06-12 can proceed independently — no shared file conflicts with this plan's changes
- Live/human verification of the actual Hyprland runtime behavior (floating kitty opening, fzf rendering, waybar font visibly changing) is still recommended at the phase's end-of-phase UAT gate, since this plan's automated checks only prove static wiring correctness

## Self-Check: PASSED

All created files exist (icon-theme-switch.sh, font-switch.sh) and all three task commits (788563d, 8b4d21e, 0ac9676) are present in git history.

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-12*
