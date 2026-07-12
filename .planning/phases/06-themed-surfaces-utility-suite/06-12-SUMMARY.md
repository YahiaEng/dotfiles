---
phase: 06-themed-surfaces-utility-suite
plan: 12
subsystem: infra
tags: [install.sh, hyprlock, matugen, aur-helper, theme-pipeline]

# Dependency graph
requires:
  - phase: 06-04
    provides: hyprlock-colors.conf render target and hyprlock.conf themed input-field block (FIX-02 hardening)
  - phase: 06 (code review)
    provides: CR-04 and WR-01 findings from 06-REVIEW.md
provides:
  - install.sh cleanup step uses $AUR_HELPER (paru or yay) instead of a hardcoded paru literal
  - hyprlock placeholder_text color rendered from the theme pipeline instead of a hardcoded Catppuccin hex
affects: [install, hyprlock, matugen-templates]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Bare (non-rgba) stripped-hex render variables for contexts (pango span foreground=) that cannot consume rgba() wrapper syntax"

key-files:
  created: []
  modified:
    - install.sh
    - matugen/.config/matugen/templates/hyprlock-colors.conf
    - hypr/.config/hypr/hyprlock.conf

key-decisions:
  - "hyprlock-colors.conf now emits both an rgba()-wrapped $on_surface_variant (for hyprlock's native color= keys) and a bare $on_surface_variant_hex (for the pango span foreground= attribute, which needs a raw hex escaped by hyprlock's ## convention) — same source color, two render forms for two consumer syntaxes"

patterns-established:
  - "When a single palette color must feed both a hyprlock rgba() key and a pango span hex literal, render both forms from the template rather than string-manipulating one at runtime"

requirements-completed: [LOCK-01]

coverage:
  - id: D1
    description: "install.sh cleanup (orphan-removal, cache-clean) uses $AUR_HELPER instead of a literal paru, so a yay-only fresh install no longer aborts under set -euo pipefail during cleanup"
    requirement: "LOCK-01"
    verification:
      - kind: unit
        ref: "bash -n install.sh && grep -F '\"$AUR_HELPER\" -R --noconfirm \"${ORPHANS[@]}\"' install.sh && grep -F '\"$AUR_HELPER\" -Sc --noconfirm' install.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "hyprlock placeholder_text color is rendered from the theme pipeline ($on_surface_variant_hex) instead of a hardcoded Catppuccin Mocha hex, so it re-themes under any static or dynamic preset"
    requirement: "LOCK-01"
    verification:
      - kind: unit
        ref: "grep -F '\\$on_surface_variant_hex = {{colors.on_surface_variant.default.hex_stripped}}' matugen/.config/matugen/templates/hyprlock-colors.conf && grep -F 'foreground=\"##\\$on_surface_variant_hex\"' hypr/.config/hypr/hyprlock.conf"
        status: pass
      - kind: integration
        ref: "theme-apply catppuccin rendered ~/.local/state/theme/hyprlock.conf with '$on_surface_variant_hex = a6adc8' present"
        status: pass
    human_judgment: true
    rationale: "Light/dark placeholder-text contrast is a visual legibility check (06-VERIFICATION.md human_verification #1) that requires a human to view the rendered lock screen under both a light and dark preset — automation only proves the value is sourced from the pipeline, not that it reads legibly."

# Metrics
duration: 8min
completed: 2026-07-12
status: complete
---

# Phase 06 Plan 12: Gap Closure — install.sh AUR Helper Indirection & Hyprlock Placeholder Theming Summary

**Fixed install.sh's hardcoded `paru` in cleanup (yay-safe reproducibility, CR-04) and hyprlock's hardcoded Catppuccin placeholder hex (pipeline-sourced, WR-01)**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-12T19:43:00Z
- **Completed:** 2026-07-12T19:51:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- install.sh's orphan-removal and cache-clean steps now use `"$AUR_HELPER"` (detected as `paru` or `yay`) instead of a hardcoded `paru` literal, so the script no longer crashes under `set -euo pipefail` on a yay-only system during cleanup
- hyprlock's password-field placeholder text now sources its color from a new `$on_surface_variant_hex` variable rendered by the theme pipeline, replacing a hardcoded Catppuccin Mocha hex (`#a6adc8`) that never re-themed
- Verified end-to-end by running `theme-apply catppuccin`, confirming the rendered `~/.local/state/theme/hyprlock.conf` defines `$on_surface_variant_hex = a6adc8`

## Task Commits

Each task was committed atomically:

1. **Task 1: Use $AUR_HELPER instead of literal paru in install.sh cleanup (CR-04)** - `d761046` (fix)
2. **Task 2: Theme the hyprlock placeholder color via the render target (WR-01)** - `7eefcde` (fix)

_No TDD tasks in this plan; both were mechanical single-file corrections._

## Files Created/Modified
- `install.sh` - Cleanup block (orphan-removal, cache-clean) now uses `"$AUR_HELPER"` instead of a literal `paru`; adjacent comments updated to match. AUR-helper detection/bootstrap block (lines 253-270) left unchanged.
- `matugen/.config/matugen/templates/hyprlock-colors.conf` - Added `$on_surface_variant_hex = {{colors.on_surface_variant.default.hex_stripped}}` (bare stripped-hex, no rgba wrapper) alongside the existing `$on_surface_variant` line.
- `hypr/.config/hypr/hyprlock.conf` - `placeholder_text` span's `foreground` attribute changed from the literal `##a6adc8` to `##$on_surface_variant_hex`; all other input-field keys (FIX-02 hardening: `check_text`, `fail_text`, `ignore_empty_input`) left verbatim.

## Decisions Made
- Rendered the placeholder color as a second, bare-hex variable (`$on_surface_variant_hex`) rather than reusing/reformatting the existing `$on_surface_variant` rgba() variable at runtime — hyprlock's pango span `foreground=` attribute needs a raw hex string (escaped via hyprlock's `##` convention), not an `rgba(...)` value, so the two consumer syntaxes each get their own render form from the same source palette key.

## Deviations from Plan

None - plan executed exactly as written. Both tasks were mechanical, single-file corrections exactly as scoped; no auto-fixes, no blocking issues, no architectural questions.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CR-04 and WR-01 gap-closure items from 06-REVIEW.md are now closed; both were the last two open code-review findings for Phase 6.
- The visual light/dark placeholder-contrast check remains tracked as human_verification #1 in 06-VERIFICATION.md (not blocking — automated source-of-truth verification for this fix is complete).
- Phase 6 (themed-surfaces-utility-suite) has no further plans; this was the final gap-closure plan (12 of 12).

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-12*

## Self-Check: PASSED

All modified files confirmed present on disk; all task and metadata commit hashes (`d761046`, `7eefcde`) confirmed in git log.
