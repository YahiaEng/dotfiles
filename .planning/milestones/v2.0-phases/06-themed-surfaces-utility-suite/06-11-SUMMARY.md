---
phase: 06-themed-surfaces-utility-suite
plan: 11
subsystem: utility-scripts
tags: [gpu-screen-recorder, hyprshot, satty, hyprpicker, bash, set-e, error-handling]

# Dependency graph
requires:
  - phase: 06-themed-surfaces-utility-suite
    provides: "06-05's record-toggle.sh and capture-{region,window,full}.sh implementations, 06-09's color-picker.sh implementation, all flagged by 06-REVIEW.md"
provides:
  - "Corrected gpu-screen-recorder region-capture flag shape (`-w region -region <geom>`)"
  - "command -v tool-presence guards on all three capture scripts (hyprshot, satty)"
  - "color-picker.sh success-path exit fixed to 0 regardless of ImageMagick availability"
affects: [phase-08-waybar-recording-indicator]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Tool-presence guard: loop over required binaries with `command -v`, notify-send + exit 1 on absence — placed immediately after `set -euo pipefail`, before any pipeline that would otherwise abort silently"
    - "if-block cleanup instead of trailing &&-list under set -e, when the left-hand condition can legitimately be false on a script's own success path (same fix class as reload.sh)"

key-files:
  created: []
  modified:
    - hypr/.config/hypr/scripts/record-toggle.sh
    - hypr/.config/hypr/scripts/capture-region.sh
    - hypr/.config/hypr/scripts/capture-window.sh
    - hypr/.config/hypr/scripts/capture-full.sh
    - hypr/.config/hypr/scripts/color-picker.sh

key-decisions:
  - "Region capture flag fix mirrors gpu-screen-recorder's actual CLI contract: `-w region` (literal string) plus a separate `-region WxH+X+Y` value, not the geometry passed directly as -w's argument"
  - "Tool-presence guard placed identically in all three capture scripts (hyprshot + satty), reusing color-picker.sh's existing command -v pattern rather than inventing a new convention"

patterns-established:
  - "Missing-binary guard: `for tool in a b; do command -v \"$tool\" || { notify-send ...; exit 1; }; done` immediately after set -euo pipefail"

requirements-completed: [SHOT-03, SHOT-01, SHOT-02, UTIL-02]

coverage:
  - id: D1
    description: "Drag-selected region recording starts successfully via gpu-screen-recorder (region branch uses -w region -region <geom>)"
    requirement: "SHOT-03"
    verification:
      - kind: other
        ref: "bash -n hypr/.config/hypr/scripts/record-toggle.sh && grep -Fq -- '-w region -region \"${target#region:}\"' hypr/.config/hypr/scripts/record-toggle.sh"
        status: pass
    human_judgment: true
    rationale: "gpu-screen-recorder is not installed on this dev machine (per 06-05/06-11 plan notes); the flag shape is corrected and syntax/grep-verified against gpu-screen-recorder's documented CLI, but an actual region recording has not been run end-to-end on real hardware."
  - id: D2
    description: "capture-region.sh, capture-window.sh, capture-full.sh each guard for hyprshot/satty presence and notify-send + exit 1 when absent"
    requirement: "SHOT-01"
    verification:
      - kind: other
        ref: "bash -n <each script> && grep -q 'command -v' && grep -q hyprshot && grep -q satty && grep -q 'not installed'"
        status: pass
    human_judgment: false
  - id: D3
    description: "Screenshot capture scripts distinguish 'tool not installed' (explicit error notification) from 'user cancelled' (silent)"
    requirement: "SHOT-02"
    verification:
      - kind: other
        ref: "Same guard as D2; existing silent-cancel branch (only notify if $FILENAME exists) left untouched"
        status: pass
    human_judgment: false
  - id: D4
    description: "color-picker.sh exits 0 on its own success path even when ImageMagick is unavailable (no swatch generated)"
    requirement: "UTIL-02"
    verification:
      - kind: other
        ref: "bash -n hypr/.config/hypr/scripts/color-picker.sh && grep -q 'if \\[\\[ \"\\$ICON\" != \"color-picker\" \\]\\]; then' hypr/.config/hypr/scripts/color-picker.sh"
        status: pass
    human_judgment: false

# Metrics
duration: 5min
completed: 2026-07-12
status: complete
---

# Phase 06 Plan 11: Gap Closure — Region Recording Flag & Utility Script Error Handling Summary

**Fixed gpu-screen-recorder's region-capture flag shape (`-w region -region <geom>`), added hyprshot/satty presence guards to all three capture scripts, and corrected color-picker.sh's set -e exit-status bug on its success path.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-12T22:39:XX+03:00
- **Completed:** 2026-07-12T22:40:27+03:00
- **Tasks:** 2 completed
- **Files modified:** 5

## Accomplishments
- SHOT-03/CR-03 closed: region-recording's `region:*` branch now passes `-w region -region "${target#region:}"` instead of the geometry as a bare `-w` value, which gpu-screen-recorder's CLI does not accept
- WR-06 closed: capture-region.sh, capture-window.sh, and capture-full.sh each gained a `command -v` presence guard for `hyprshot` and `satty`, firing an explicit `notify-send` error + `exit 1` on a missing tool instead of an identical-looking silent `set -e` abort
- WR-05 closed: color-picker.sh's trailing `[[ "$ICON" != "color-picker" ]] && rm -f "$ICON"` line (which returned exit 1 under `set -e` whenever no swatch was generated, e.g. no ImageMagick) converted to an explicit `if` block so the script's own success path always exits 0

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix the region-capture flag shape for gpu-screen-recorder (CR-03)** - `14d9ba5` (fix)
2. **Task 2: Guard capture scripts against missing tools and fix color-picker success exit (WR-06, WR-05)** - `70ca724` (fix)

**Plan metadata:** (pending — final docs commit below)

## Files Created/Modified
- `hypr/.config/hypr/scripts/record-toggle.sh` - region branch now uses `-w region -region <geom>`; monitor branch unchanged
- `hypr/.config/hypr/scripts/capture-region.sh` - added hyprshot/satty presence guard before the capture pipeline
- `hypr/.config/hypr/scripts/capture-window.sh` - added hyprshot/satty presence guard before the capture pipeline
- `hypr/.config/hypr/scripts/capture-full.sh` - added hyprshot/satty presence guard before the capture pipeline
- `hypr/.config/hypr/scripts/color-picker.sh` - swatch cleanup converted from trailing `&&`-list to `if` block

## Decisions Made
- Reused color-picker.sh's existing `command -v hyprpicker` guard pattern verbatim for the three capture scripts' `hyprshot`/`satty` checks, keeping one consistent missing-tool convention across all utility scripts (see 06-PATTERNS.md)
- No architectural changes; all three tasks were narrow, mechanical script fixes exactly as scoped by the plan

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. gpu-screen-recorder, hyprshot, and satty remain uninstalled on this dev machine (consistent with 06-05's original implementation notes), so the fixes were verified via `bash -n` syntax checks and `grep` assertions per the plan's `<verify>` blocks rather than a live end-to-end recording/capture run. This mirrors the verification approach already used in 06-05 and 06-09 for the same reason.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All three review-flagged gaps (CR-03, WR-06, WR-05) from 06-REVIEW.md are closed
- Phase 8's planned waybar recording indicator can rely on `recording_active()`'s `pgrep -f "^gpu-screen-recorder"` probe, unaffected by this plan's changes
- No blockers for phase completion from this plan

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-12*

## Self-Check: PASSED

All modified files and commit hashes verified present (files: record-toggle.sh, capture-region.sh, capture-window.sh, capture-full.sh, color-picker.sh, 06-11-SUMMARY.md; commits: 14d9ba5, 70ca724, b3ea4b7).
