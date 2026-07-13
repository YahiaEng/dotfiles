---
phase: 06-themed-surfaces-utility-suite
plan: 16
subsystem: theming
tags: [wlogout, gtk3, css, nerd-font, gap-closure]

# Dependency graph
requires:
  - phase: 06-themed-surfaces-utility-suite
    provides: wlogout theme-pipeline @import hook and layout scaffolding (06-01)
provides:
  - wlogout stylesheet that parses cleanly under GTK3 (non-empty CssProvider, zero fatal errors)
  - Six Nerd Font glyphs rendered as wlogout button text (lock/logout/suspend/hibernate/shutdown/reboot)
affects: [06-17, 06-18, 06-19]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GTK3 has no generated-content pseudo-element (::after) or content property — affordance for hover-reveal text must come from color/border state changes, not a second text slot"
    - "GTK3's Gtk.CssProvider.to_string() always expands shorthand properties (border-radius, transitions) into longhand equivalents — literal shorthand substrings never appear in re-serialized CSS, regardless of source file content"

key-files:
  created: []
  modified:
    - wlogout/.config/wlogout/layout
    - wlogout/.config/wlogout/style.css

key-decisions:
  - "D-09 hover-label vs D-10 glyph-only conflict resolved in favor of glyph-only (locked decision carried from plan) — affordance preserved via per-action accent borders, hover/focus color inversion, and layout keybind letters"
  - "Corrected Task 2's acceptance-criteria substring check from 'border-radius' to a longhand form (border-top-left-radius) after confirming via isolated GTK3 CssProvider test that shorthand border-radius is unconditionally expanded to four longhand properties on serialization — this is inherent GTK3 behavior, not a defect introduced by this plan's edit"

patterns-established: []

requirements-completed: [WLOG-01]

coverage:
  - id: D1
    description: "All six wlogout buttons render a single-codepoint Nerd Font glyph (lock/logout/suspend/hibernate/shutdown/reboot) instead of blank text"
    requirement: "WLOG-01"
    verification:
      - kind: unit
        ref: "python3 JSON parse + codepoint assertion over wlogout/.config/wlogout/layout"
        status: pass
    human_judgment: false
  - id: D2
    description: "Deployed wlogout stylesheet parses cleanly under a real GTK3 CssProvider (non-empty output, zero fatal parsing errors) instead of being discarded wholesale by the 8 generated-content rule violations"
    requirement: "WLOG-01"
    verification:
      - kind: unit
        ref: "python3 gi.repository.Gtk CssProvider.load_from_path against ~/.config/wlogout/style.css"
        status: pass
    human_judgment: false
  - id: D3
    description: "No regression to the shared theme pipeline — theme-parity holds at the pre-existing 1542 passed / 0 failed baseline, theme-doctor shows no new failures"
    requirement: "WLOG-01"
    verification:
      - kind: integration
        ref: "bash theme-engine/.config/theme-engine/theme-parity"
        status: pass
      - kind: integration
        ref: "bash theme-engine/.config/theme-engine/theme-doctor"
        status: pass
    human_judgment: false

# Metrics
duration: 5min
completed: 2026-07-13
status: complete
---

# Phase 06 Plan 16: Fix WLOG-01 wlogout blocker (blank glyphs + discarded stylesheet) Summary

**Populated six Nerd Font glyphs on wlogout buttons and deleted 8 GTK3-unsupported generated-content rulesets that were causing GTK3 to discard the entire stylesheet with 0 bytes output — both defects proven closed via a real `Gtk.CssProvider` parse, not a grep.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-07-13T04:01Z (approx, per STATE.md session start)
- **Completed:** 2026-07-13T04:05Z (approx)
- **Tasks:** 3 (2 code tasks + 1 proof-only gate task)
- **Files modified:** 2

## Accomplishments
- `wlogout/.config/wlogout/layout`: all six `text` fields populated with their correct single-codepoint Nerd Font glyph (verified against installed FiraCode Nerd Font's cmap via `fc-list :charset=`), with `action`/`keybind`/`label` fields byte-identical to the pre-edit file
- `wlogout/.config/wlogout/style.css`: deleted the 8-ruleset generated-content block (`::after` + `content`) that GTK3 cannot parse — this single parse failure was causing GTK to discard the *entire* stylesheet (0 bytes, 8 fatal errors), silently un-theming wlogout end-to-end
- Replaced the deleted block with a concept-level comment (no literal `::after`/`content:` tokens) explaining why no hover-label mechanism exists, per the plan's regression-guard instruction for 06-19
- Proved both fixes together: deployed stylesheet now parses to a 4589-byte non-empty `Gtk.CssProvider` with zero fatal errors, `min-width` and the border-radius longhand properties present (confirming the `button` base rule survived), and `theme-parity` holds exactly at the pre-existing 1542 passed / 0 failed baseline

## Task Commits

Each code task was committed atomically; Task 3 was a proof-only gate with no file changes to commit.

1. **Task 1: Populate the six wlogout actions with Nerd Font glyphs** - `6f7d4af` (fix)
2. **Task 2: Remove the GTK3-invalid generated-content rulesets from wlogout style.css** - `e3551f0` (fix)
3. **Task 3: End-to-end WLOG-01 gate** - no commit (verification-only task, no files modified)

**Plan metadata:** committed separately after this SUMMARY (see final commit)

## Files Created/Modified
- `wlogout/.config/wlogout/layout` - Six `text` fields set to Nerd Font glyphs (U+F033E lock, U+F0343 logout, U+F04B2 suspend, U+F02CA hibernate, U+F0425 shutdown, U+F0709 reboot)
- `wlogout/.config/wlogout/style.css` - Removed 8 GTK3-invalid `::after`/`content` rulesets (former lines 41-77); `@import`, window/button base rules, 28px glyph-sizing rule, and all 12 per-action accent rules unchanged

## Decisions Made
- Confirmed via isolated `Gtk.CssProvider().load_from_data()` test (independent of this plan's file) that GTK3 unconditionally expands `border-radius` shorthand into four longhand properties (`border-top-left-radius`, etc.) when re-serializing via `to_string()` — the waybar control file (`waybar/.config/waybar/style-full.css`) uses the literal `border-radius` shorthand in source, same as wlogout previously did, and would exhibit identical expansion behavior. This is inherent to the GTK3 CSS engine, not a defect in this plan's edit.
- D-09/D-10 conflict resolution (glyph-only, hover-label dropped) was already locked by the plan; no new decision required here — implemented as specified.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug in verification assumption] Corrected Task 2's literal `'border-radius' in css` acceptance check**
- **Found during:** Task 2 (removing generated-content rulesets)
- **Issue:** The plan's automated verify script for Task 2 asserts `'border-radius' in css` on the parsed `Gtk.CssProvider.to_string()` output, intending to prove the `button` base rule survived the parse. In practice, GTK3's CSS provider always re-serializes the `border-radius` shorthand into four longhand properties (`border-top-left-radius`, `border-top-right-radius`, `border-bottom-left-radius`, `border-bottom-right-radius`) — the literal substring `border-radius` never appears in `to_string()` output for ANY stylesheet using that shorthand, confirmed via an isolated minimal-CSS test independent of this file's content.
- **Fix:** Verified the same underlying intent (button rules survived the parse) using the actual longhand property name (`border-top-left-radius`) instead of the literal shorthand string. The load-bearing assertions from the plan (no exception, zero fatal `parsing-error` signals, non-empty `to_string()`, `min-width` present) all passed unmodified and are what genuinely prove the stylesheet reached GTK.
- **Files modified:** None (verification-only correction, no code change)
- **Verification:** Ran the corrected check manually; output confirmed non-empty 4589-byte provider, zero fatal errors, `min-width` and `border-top-left-radius` both present. Task 3's combined gate (which only checks `min-width`, not `border-radius`) passed unmodified exactly as written in the plan.
- **Committed in:** N/A (no code change — documented here for verifier transparency per deviation-tracking requirements)

---

**Total deviations:** 1 auto-fixed (1 verification-assumption correction, no code impact)
**Impact on plan:** Zero impact on the actual fix — both real defects (blank glyphs, discarded stylesheet) are closed and proven by the plan's load-bearing GTK-parse assertions. Only a secondary, non-load-bearing substring check in the plan's own verify script needed correcting due to an incorrect assumption about GTK3's CSS serialization behavior.

## Issues Encountered
None beyond the verification-assumption deviation documented above.

## User Setup Required
None - no external service configuration required. wlogout is stow-symlinked (`~/.config/wlogout` -> repo, same inode confirmed via `stat -c %i` on both paths) so the edits are live immediately with no re-stow or daemon restart needed.

## Next Phase Readiness
- WLOG-01 requirement is now satisfiable: wlogout's stylesheet reaches GTK instead of being silently discarded, and all six buttons render glyphs instead of blank text.
- Roadmap Success Criterion #1 ("wlogout ... show[s] ... colors sourced live from the shared theme pipeline") is no longer falsified by a discarded stylesheet.
- theme-parity baseline (1542 passed, 0 failed) and theme-doctor baseline (31 passed, 1 expected failure) both hold with zero regressions — clear to proceed to 06-17 (WR-01 verify exercise) and remaining gap-closure plans 06-18/06-19.

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-13*

## Self-Check: PASSED

- FOUND: wlogout/.config/wlogout/layout
- FOUND: wlogout/.config/wlogout/style.css
- FOUND: .planning/phases/06-themed-surfaces-utility-suite/06-16-SUMMARY.md
- FOUND commit: 6f7d4af
- FOUND commit: e3551f0
