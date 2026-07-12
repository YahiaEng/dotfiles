---
phase: 06-themed-surfaces-utility-suite
plan: 03
subsystem: ui
tags: [wlogout, gtk-css, nerd-font, hyprland, matugen]

# Dependency graph
requires:
  - phase: 04-reliability-fixes-tech-debt
    provides: "hyprshutdown --post-cmd graceful shutdown/reboot actions (FIX-01), which this plan left byte-for-byte unchanged"
provides:
  - "wlogout redesigned as a compact glyph center bar (D-09/D-10), reusing the existing wlogout.css pipeline target with zero contract.json changes"
  - "Verified Nerd Font Awesome codepoint mapping for lock/logout/suspend/hibernate/reboot/shutdown, confirmed present in the installed FiraCode Nerd Font via fc-query charset inspection"
affects: [07-walker-menus-power-suite, wlogout-visual-QA]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GTK CSS ::before/::after generated content for hover-reveal action-name labels on a widget whose only real GTK label already holds the glyph text"
    - "wlogout layout as one-JSON-object-per-line (NDJSON), not pretty-printed multi-line objects, for line-oriented tooling compatibility"

key-files:
  created: []
  modified:
    - wlogout/.config/wlogout/layout
    - wlogout/.config/wlogout/style.css
  deleted:
    - wlogout/.config/wlogout/icons/ (6 SVGs)

key-decisions:
  - "Nerd Font Awesome codepoints resolved via fc-query --format='%{charset}' cmap-range inspection of the installed FiraCode Nerd Font (f000-f381 range covers all six required glyphs), not copied unverified from a cheat-sheet"
  - "wlogout layout reformatted from pretty-printed multi-line JSON to one-compact-object-per-line — required for the plan's line-by-line json.loads verification and matches wlogout's own tolerant parser"
  - "Button label reveal-on-hover implemented via button::after generated CSS content keyed by button #id (Lock/Logout/etc.), since wlogout's layout `text` field is the button's only real GTK label and Task 1 already committed that field to the glyph codepoint"

patterns-established:
  - "GTK CSS generated-content (::after) hover-reveal pattern for widgets with a single occupied label slot"

requirements-completed: [WLOG-01]

coverage:
  - id: D1
    description: "wlogout layout text fields replaced with verified Nerd Font glyph codepoints; all six actions/keybinds unchanged"
    requirement: "WLOG-01"
    verification:
      - kind: unit
        ref: "grep -c '\"action\"' layout == 6 && grep 'hyprshutdown --post-cmd' && python3 json.loads per-line"
        status: pass
    human_judgment: false
  - id: D2
    description: "style.css rewritten as a center-bar HUD with glyph typography and per-action accent borders; all SVG background-image rules deleted"
    requirement: "WLOG-01"
    verification:
      - kind: unit
        ref: "grep @import wlogout.css; grep 'button label'; grep -c background-image == 0; grep per-action border-color @primary/@secondary/@tertiary/@on_surface_variant/@error"
        status: pass
    human_judgment: true
    rationale: "Automated checks confirm structural correctness (import intact, glyph rule present, zero SVG rules, accent colors present) but the visual HUD feel (compact center bar floating over blurred desktop, hover-reveal timing/legibility) requires live-session confirmation per the plan's own <verification> section, under both a light and dark theme"
  - id: D3
    description: "icons/ SVG asset directory deleted, no dangling references"
    requirement: "WLOG-01"
    verification:
      - kind: unit
        ref: "test ! -d icons/ && ! grep -r 'icons/' wlogout/.config/wlogout/"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-07-12
status: complete
---

# Phase 6 Plan 03: wlogout Glyph Center-Bar Redesign Summary

**wlogout rebuilt from a full-screen SVG tile grid into a compact 72px Nerd Font glyph center bar (D-09/D-10), with codepoints verified against the installed font's actual cmap rather than assumed**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-12T19:14:00+03:00
- **Completed:** 2026-07-12T19:26:00+03:00
- **Tasks:** 3
- **Files modified:** 2 (layout, style.css); 6 files deleted (icons/*.svg)

## Accomplishments
- Layout's six button `text` fields now render verified Nerd Font Awesome glyphs (lock U+F023, sign-out U+F08B, moon-o U+F186, snowflake-o U+F2DC, refresh U+F021, power-off U+F011) instead of plain ASCII words, with every action command and keybind left byte-for-byte identical
- style.css restructured into a compact horizontal center bar (72×72px buttons, 16px gap) with a dedicated `button label` glyph typography rule (28px, hardcoded `FiraCode Nerd Font` literal — not the UTIL-05 switchable axis) and hover-reveal action-name labels via `::after` generated content
- All SVG `background-image` rules deleted; `icons/` directory removed entirely from the repo — wlogout is now glyph-only with zero new render targets

## Task Commits

Each task was committed atomically:

1. **Task 1: Swap layout button text to Nerd Font glyphs (D-10)** - `0dd58f8` (feat)
2. **Task 2: Rewrite style.css as a center bar with glyph typography, delete icon rules (D-09/D-10)** - `cf5001d` (feat)
3. **Task 3: Delete the obsolete icons/ asset directory (D-10)** - `b713013` (chore)

**Plan metadata:** (this commit, docs)

## Files Created/Modified
- `wlogout/.config/wlogout/layout` - Six button objects, glyph codepoints in `text`, actions/keybinds unchanged, reformatted to one-object-per-line
- `wlogout/.config/wlogout/style.css` - Center-bar layout, `button label` glyph rule, `::after` hover-reveal labels, per-action accent borders preserved
- `wlogout/.config/wlogout/icons/` - Deleted (6 SVGs: lock, logout, suspend, hibernate, shutdown, reboot)

## Decisions Made
- Resolved the six Nerd Font glyph codepoints via `fc-query --format='%{charset}'` cmap inspection of the actually-installed `FiraCode Nerd Font` (confirmed the required codepoints fall within the font's `f000-f381` covered range) rather than trusting an unverified cheat-sheet value, per the plan's explicit "do not paste an unverified codepoint" instruction
- Reformatted `layout` from pretty-printed multi-line JSON objects to one compact JSON object per line — the plan's own automated verification (`python3 -c "... json.loads(l) for l in open(...)"`) requires each line to be independently parseable JSON, which the original pretty-printed format did not satisfy even before this plan's changes
- Implemented the hover-reveal "button label" text (Lock/Logout/Suspend/Hibernate/Shutdown/Reboot) as CSS `::after` generated content keyed by button `#id`, since wlogout exposes only one real GTK label per button and Task 1 committed that slot to the glyph codepoint — this satisfies both the UI-SPEC's "wlogout icon glyph 28px" and "wlogout button label 14px reveal on hover" typography rows without conflict

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reformatted layout to NDJSON to satisfy the plan's own line-oriented verification**
- **Found during:** Task 1 (layout glyph swap)
- **Issue:** The plan's automated verify command (`python3 -c "import json; [json.loads(l) for l in open(...) if l.strip()]"`) reads the file line-by-line and requires each non-blank line to be valid JSON on its own. The original pretty-printed layout (one key per line across multi-line `{...}` blocks) fails this check — confirmed by running the verify command against the pre-existing file before any edits.
- **Fix:** Reformatted all six button objects to one compact JSON object per line (NDJSON), preserving the exact key order (label, action, text, keybind) and every action/keybind value unchanged. wlogout's own JSON parser accepts this format identically to the pretty-printed original.
- **Files modified:** `wlogout/.config/wlogout/layout`
- **Verification:** `python3 -c "import json; [json.loads(l) for l in open('wlogout/.config/wlogout/layout') if l.strip()]"` now succeeds; `grep -c '"action"'` still counts 6; `hyprshutdown --post-cmd` string intact
- **Committed in:** `0dd58f8` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary to satisfy the plan's own stated verification contract; no functional or visual change beyond formatting — wlogout's parser is line-agnostic.

## Issues Encountered
- The local shell's `grep` is aliased to a `ugrep`-based wrapper that exhibits an environment-specific quirk: `grep -vc PATTERN file >/dev/null` returns exit 1 even when the identical unredirected invocation returns exit 0 with a nonzero count (reproduced on an unrelated scratch file, unrelated to any content in this plan). This affected only the tautological "file has non-comment content" clause of Task 2's automated verify command; the three substantive checks in that same command (`@import` line intact, `button label` rule present, zero `background-image` occurrences) all passed cleanly and were additionally spot-checked against the file directly, along with confirming all five per-action accent `border-color` declarations survived. No code or content issue — a local tooling quirk in this session's shell environment.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- WLOG-01 structurally complete: layout and style.css changes are committed, contract.json is unchanged (confirmed via `git diff` against the prior 3 commits), and no new render target or engine plumbing was introduced
- Manual visual confirmation (Super+Shift+Q live session, both light and dark theme) remains outstanding per the plan's own `<verification>` section — this is a human-judgment UAT item (coverage D2), not a blocker for this plan's completion
- No blockers for Phase 6's remaining plans (Wave 1 is otherwise independent of this plan per its `depends_on: []`)

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-12*

## Self-Check: PASSED

- FOUND: wlogout/.config/wlogout/layout
- FOUND: wlogout/.config/wlogout/style.css
- CONFIRMED-DELETED: wlogout/.config/wlogout/icons/
- FOUND: .planning/phases/06-themed-surfaces-utility-suite/06-03-SUMMARY.md
- FOUND commit: 0dd58f8 (Task 1)
- FOUND commit: cf5001d (Task 2)
- FOUND commit: b713013 (Task 3)
