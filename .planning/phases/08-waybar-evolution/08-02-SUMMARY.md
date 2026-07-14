---
phase: 08-waybar-evolution
plan: 02
subsystem: infra
tags: [bash, shellcheck, walker, waybar, dynamic-enumeration]

# Dependency graph
requires:
  - phase: 05-light-mode-pipeline-theme-presets
    provides: dynamic palette enumeration precedent (palettes/*.json glob + prettify() idiom, the direct pattern this plan mirrors for D-32)
  - phase: 08-waybar-evolution
    provides: "08-01's shared-include composition (config-*.jsonc layouts) — this plan's enumeration globs exactly those layout files, not modules.jsonc/bar-common.jsonc"
provides:
  - hypr/.config/hypr/scripts/waybar-switch.sh — layouts enumerated from disk (config-*.jsonc glob), menu labels derived from filenames, zero hardcoded layout list
  - hypr/.config/hypr/scripts/waybar-launch.sh — saved layout validated by file-existence + slug guard instead of a hardcoded enum, `full` fallback retained (D-16)
affects: [08-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Disk-truth layout enumeration: glob config-*.jsonc, sort, strip prefix/suffix to recover the slug — identical shape to theme-switch.sh's palette enumeration (Phase 5, D-32's direct precedent)"
    - "Parallel-array label/slug mapping (SLUGS[]/DISPLAYS[]) instead of re-parsing a decorated menu label back into a slug via glob-match case statements"
    - "Slug validation (^[A-Za-z0-9_-]+$) as a mandatory gate before interpolating host-side, user-writable state into a filesystem path"

key-files:
  created: []
  modified:
    - hypr/.config/hypr/scripts/waybar-switch.sh
    - hypr/.config/hypr/scripts/waybar-launch.sh

key-decisions:
  - "Menu-label derivation rule (for 08-05's vertical layout to inherit for free): hyphen -> space, then title-case each word (prettify(), verbatim copy of theme-switch.sh's palette prettify()). No per-layout hardcoded description string; casing and spacing come mechanically from the filename slug."
  - "Selection-to-slug mapping uses parallel SLUGS[]/DISPLAYS[] arrays indexed together, not a reverse string transform or glob-match case statement — the slug is looked up by exact DISPLAYS[i] match, never re-derived from the label text."
  - "waybar-launch.sh keeps `full` as a single hardcoded fallback CONSTANT (D-16) — this is not the hardcoded LIST that D-32 kills; a fresh install and the container/VM gate must land on `full`, never on whichever layout happens to sort first on disk."
  - "Did NOT mark BAR-03 complete in REQUIREMENTS.md, mirroring 08-01's precedent: this plan is the enabling enumeration refactor only. BAR-03's actual deliverable (the vertical layout itself) ships in plan 08-05; marking it complete here would misrepresent that the vertical layout doesn't exist yet."

patterns-established:
  - "waybar-switch.sh/waybar-launch.sh join theme-switch.sh/theme-apply as the third disk-truth-enumeration pair in this repo (palettes -> themes, wallpapers -> wallpaper-picker, now layouts -> waybar). Any future 'switcher' script for a directory of named files should default to this same glob+sort+prettify shape rather than a hardcoded list."

requirements-completed: []  # Intentionally empty — see key-decisions. BAR-03's vertical-layout deliverable ships in plan 08-05; this plan only builds the enumeration substrate it depends on.

coverage:
  - id: D1
    description: "waybar-switch.sh discovers layouts by globbing config-*.jsonc (no hardcoded LAYOUT_LIST or case-mapping), derives menu labels from filenames, and preserves the walker exit-130 cancel contract"
    verification:
      - kind: manual_procedural
        ref: "shellcheck -S error + bash -n clean; grep -cE for hardcoded *\"Minimal\"*/*\"Full\"*/*\"Floating\"* patterns returns 0; grep -q 'rc == 130' matches"
        status: pass
      - kind: manual_procedural
        ref: "Dry-run enumeration extracted verbatim from the committed script (sed range extraction, not re-derivation): produces exactly floating/full/minimal sorted"
        status: pass
      - kind: manual_procedural
        ref: "Forward-compat proof: touched config-zzztest.jsonc + style-zzztest.css, re-ran the enumeration, zzztest appeared with zero script edits, temp files deleted afterward"
        status: pass
    human_judgment: false
  - id: D2
    description: "waybar-switch.sh guards against a zero-layout glob (loud notify-send + exit 1) and against a config file with no matching stylesheet (loud notify-send + exit 1, never an unstyled launch)"
    verification:
      - kind: manual_procedural
        ref: "Isolated guard-logic test: config-zzztest.jsonc present, style-zzztest.css absent — guard condition evaluates true (would exit 1 with error notify); temp file removed afterward"
        status: pass
    human_judgment: false
  - id: D3
    description: "waybar-launch.sh validates the saved layout by testing config-<slug>.jsonc + style-<slug>.css existence on disk instead of a hardcoded minimal|full|floating enum, with a slug-pattern guard against path traversal, and full remains the D-16 fallback constant"
    verification:
      - kind: manual_procedural
        ref: "shellcheck -S error + bash -n clean; grep -cE 'minimal\\|full\\|floating' returns 0; existence-check and slug-validation greps both match"
        status: pass
      - kind: manual_procedural
        ref: "Full 6-row behavior table run against the actual committed validation logic (absent file, 'full', 'floating', 'vertical' w/ no config, '../../etc/passwd', 'nonsense') — every row resolves exactly as the plan's table specifies"
        status: pass
      - kind: manual_procedural
        ref: "Forward-compat proof: config-zzztest.jsonc + style-zzztest.css present, state file contains 'zzztest' — resolves to zzztest with zero script edits, temp files deleted afterward"
        status: pass
    human_judgment: true
    rationale: "The plan's own <verify><human-check> block requires a live Super+B walker session (press Super+B, confirm the picker lists exactly the on-disk layouts with derived labels, Esc cancels silently, selecting one relaunches waybar and the toast names it correctly) — this is phase-level, end-to-end interactive verification that cannot be proven by extracted-logic testing alone."

# Metrics
duration: ~10min
completed: 2026-07-14
status: complete
---

# Phase 8 Plan 2: Dynamic Waybar Layout Enumeration Summary

**Replaced hardcoded three-item layout lists in `waybar-switch.sh` and `waybar-launch.sh` with disk enumeration over `config-*.jsonc`/`style-*.css` pairs, mirroring the exact `palettes/*.json` dynamic-enumeration pattern Phase 5 already established for theme switching (D-32).**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-07-14T00:23:06Z (approx, per STATE.md session start)
- **Completed:** 2026-07-14 (local)
- **Tasks:** 2 completed
- **Files modified:** 2

## Accomplishments
- `waybar-switch.sh`: removed the hardcoded `LAYOUT_LIST` string and the `case "$SELECTED" in *"Minimal"*) ...` glob-match mapping. Layouts are now discovered via a sorted `config-*.jsonc` glob; menu labels are derived from filenames using the same `prettify()` idiom `theme-switch.sh` uses for palettes (hyphen -> space, title-case each word). Selection maps back to a slug via parallel `SLUGS[]`/`DISPLAYS[]` arrays, never a reverse string transform.
- Added two guards to `waybar-switch.sh`: a zero-layout glob now fails loudly (`notify-send` + `exit 1`) instead of silently presenting an empty walker menu, and a selected layout missing its matching stylesheet also fails loudly instead of launching an unstyled bar (T-08-14/T-08-15).
- `waybar-launch.sh`: removed the hardcoded `case "$LAYOUT" in minimal|full|floating) ;; esac` enum. The saved layout is now validated by testing for both `config-<slug>.jsonc` and `style-<slug>.css` on disk. Added a mandatory slug-pattern guard (`^[A-Za-z0-9_-]+$`) that runs BEFORE the existence check, since a traversal value could otherwise resolve to a real file outside `$WAYBAR_DIR` (T-08-13).
- `full` remains a single hardcoded fallback constant in `waybar-launch.sh` per D-16 — deliberately NOT "first layout found," so a fresh install and the container/VM gate keep their current baseline.
- Added `set -uo pipefail` to `waybar-launch.sh` (it previously had no strict-mode line at all). Deliberately did NOT add `-e`, since the script ends in `exec` and must always reach its fallback path even on a transient `cat` failure.
- Verified all acceptance criteria against the actual committed scripts (not re-derivations): the sorted enumeration produces exactly `floating full minimal`; adding a synthetic `config-zzztest.jsonc`/`style-zzztest.css` pair makes `zzztest` appear with zero script edits (both in the switcher's enumeration and the launcher's validation); the missing-stylesheet guard triggers correctly; and the launcher's full 6-row state-file resolution table (absent / `full` / `floating` / `vertical` w/ no config / `../../etc/passwd` / `nonsense`) resolves exactly as specified, including the path-traversal case.
- `hypr/.config/hypr/scripts/waybar-equivalence-check waybar/.config/waybar` remains green (3 PASS / 0 FAIL) — this plan touched only the switcher/launcher scripts, not the layout configs 08-01 refactored.

## Task Commits

1. **Task 1: Dynamic layout enumeration in waybar-switch.sh (the walker picker)** - `fb23e78` (feat)
2. **Task 2: Dynamic layout validation in waybar-launch.sh (the autostart entrypoint)** - `4c11e3e` (feat)

## Files Created/Modified
- `hypr/.config/hypr/scripts/waybar-switch.sh` - Layouts enumerated from disk via sorted `config-*.jsonc` glob; labels derived from filenames; guards against zero-layout glob and config-without-stylesheet
- `hypr/.config/hypr/scripts/waybar-launch.sh` - Saved layout validated by `config-<slug>.jsonc`/`style-<slug>.css` file existence plus a slug-pattern path-traversal guard; `full` fallback retained (D-16); added `set -uo pipefail`

## Decisions Made
- Adopted `theme-switch.sh`'s exact `prettify()` idiom (hyphen -> space, title-case each word) for waybar layout labels rather than inventing a new derivation rule — see key-decisions for the exact rule 08-05's vertical layout will inherit.
- Used parallel `SLUGS[]`/`DISPLAYS[]` index-matched arrays for the selection-to-slug lookup (identical shape to `theme-switch.sh`'s `NAMES[]`/`DISPLAYS[]`), instead of re-parsing the decorated label back into a slug.
- Kept `full` as a single hardcoded fallback constant in `waybar-launch.sh` (D-16) — explicitly not "improved" into "first layout found," since that would silently re-baseline the fresh-install/container-gate default whenever the on-disk sort order changes (e.g. once `config-vertical.jsonc` lands in 08-05).
- Left BAR-03 unchecked in REQUIREMENTS.md, mirroring 08-01's precedent for BAR-01/03/05 — this plan is the enabling enumeration refactor only; the vertical layout itself (BAR-03's actual deliverable) ships in plan 08-05.

## Deviations from Plan

None - plan executed exactly as written. Both tasks' acceptance criteria (shellcheck cleanliness, hardcoded-pattern removal, dry-run enumeration, forward-compat proof, missing-stylesheet guard, and the full 6-row behavior table) were verified directly against the committed scripts with no fixes required.

## Issues Encountered
- Live desktop caution (same as 08-01): this plan ran as a sequential (non-worktree) executor directly on the stow-managed repo, so `~/.config/hypr/scripts/waybar-switch.sh` and `waybar-launch.sh` are immediately live via symlink. Neither script was invoked against the live desktop during verification — all proof was done via extracted-logic testing against temp files and temp state files (not by actually pressing Super+B or restarting waybar) — so no live disruption occurred. The phase-level `<verify><human-check>` (press Super+B, confirm the picker + relaunch + toast) remains outstanding, consistent with 08-01's note that the visual/interactive pass is a phase-level checkpoint, not gated to this specific autonomous plan.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The enumeration substrate is now genuinely dynamic and proven so: plan 08-05 can drop `config-vertical.jsonc` + `style-vertical.css` into `waybar/.config/waybar/` and it will appear in the `Super+B` picker and be launchable at login with zero further script edits, per D-32.
- **Outstanding:** the phase-level live human-verify pass (Super+B through the picker, Esc-cancel, select-and-relaunch with correct toast) is still pending — same phase-wide checkpoint noted in 08-01-SUMMARY.md, not specific to this plan.
- BAR-03 remains `Pending` in REQUIREMENTS.md — correctly, since plan 08-05 delivers the actual vertical layout this enumeration refactor was built to support.

---
*Phase: 08-waybar-evolution*
*Completed: 2026-07-14*
