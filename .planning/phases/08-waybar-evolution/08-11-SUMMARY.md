---
phase: 08-waybar-evolution
plan: 11
subsystem: ui
tags: [waybar, gtk3-css, nerd-font, fonttools, matugen, design-system]

# Dependency graph
requires:
  - phase: 08-waybar-evolution (plans 01-10)
    provides: shared modules.jsonc include architecture, matugen waybar.css render target, theme-doctor CSS-parse regression guard
provides:
  - waybar-design-lint — rerunnable 5-check design/token gate (token resolution, alias boundary, transparent window, no literal hex, no empty glyph fields)
  - modules.jsonc with every icon field populated by a cmap-name-verified Nerd Font codepoint
  - theme.css — the single semantic colour alias layer all waybar layout sheets will migrate to in plan 08-12
affects: [08-12, 08-13, 08-14, 08-15]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GTK3 @define-color role-alias layer: `@define-color role alpha(@raw_token, N)` — verified live against Gtk.CssProvider, zero fatal errors"
    - "Rerunnable design/token lint gate in the theme-doctor/waybar-equivalence-check mould: bash wrapper + single python heredoc, TAB-separated CHECK/STATUS/detail lines, [PASS]/[FAIL] tally, nonzero exit on any FAIL"
    - "cmap-name verification (fontTools getBestCmap) as the mandatory acceptance gate for any new glyph codepoint — presence in the font is not sufficient"

key-files:
  created:
    - hypr/.config/hypr/scripts/waybar-design-lint
    - waybar/.config/waybar/theme.css
  modified:
    - waybar/.config/waybar/modules.jsonc
    - waybar/.config/waybar/config-vertical.jsonc
    - waybar/.config/waybar/config-minimal.jsonc

key-decisions:
  - "bar-surface (the translucent island) derives from @surface via alpha(), not a non-existent surface_container token — CORRECTION 1 in 08-11-PLAN.md verified there is no such token in any of the 22 palette JSONs"
  - "waybar-design-lint's CHECK E treats player-icons/status-icons/format-icons dict-and-array entries as unconditional glyph slots (blank is always a bug), and format*-scalar templates as exempt from blank-string failure but not from a leading 2+-space run (the deleted-glyph fingerprint) — this is the only way to keep mpris.format-stopped/status-icons.stopped legitimately empty while still catching cpu/memory/clock/network/pulseaudio's actual bugs"
  - "config-minimal.jsonc's own mpris redefinition was also repaired (deviation, not in files_modified) because whole-key first-defined-wins means modules.jsonc's fix never reaches it, and the plan's own success_criteria requires zero empty glyphs across every config-*.jsonc, not just modules.jsonc + config-vertical.jsonc"

patterns-established:
  - "Design/token regression gates (waybar-design-lint) live in hypr/.config/hypr/scripts/ alongside waybar-equivalence-check, sharing its JSONC comment-stripping algorithm verbatim rather than reimplementing it"

requirements-completed: [BAR-01, BAR-03]

coverage:
  - id: D1
    description: "waybar-design-lint gate built with all 5 checks (token resolution, alias boundary, transparent window, no literal hex, no empty glyph), proven to fail on the pre-fix tree (CHECK D/E) before being trusted"
    requirement: BAR-01
    verification:
      - kind: other
        ref: "hypr/.config/hypr/scripts/waybar-design-lint (self-test run recorded below: 39 FAIL pre-fix, CHECK D/E both fully PASS post-fix)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every empty/blank glyph field in modules.jsonc, config-vertical.jsonc, and config-minimal.jsonc repaired with a cmap-name-verified Nerd Font codepoint (27-entry table below); zero literal hex remaining"
    requirement: BAR-03
    verification:
      - kind: other
        ref: "waybar-design-lint CHECK D + CHECK E (all PASS), theme-doctor D-17 module-gate + CSS-parse guard (96 passed, 1 unrelated FAIL for uncommitted git status)"
        status: pass
    human_judgment: false
  - id: D3
    description: "theme.css semantic alias layer authored — the only waybar file naming a raw matugen token, 8 role aliases derived via alpha()/direct-alias, verified live against a real GTK3 CssProvider with zero fatal parse errors"
    requirement: BAR-01
    verification:
      - kind: other
        ref: "waybar-design-lint CHECK A (theme.css: 9/9 refs resolve), direct Gtk.CssProvider.load_from_path() test (0 fatal, 1318 bytes flattened output)"
        status: pass
    human_judgment: false

duration: 35min
completed: 2026-07-15
status: complete
---

# Phase 08 Plan 11: Waybar Design Gap-Closure Foundations Summary

**Rerunnable design/token lint gate (waybar-design-lint) + a fully-glyphed modules.jsonc (27 cmap-name-verified codepoints) + theme.css semantic alias layer — zero visual design change, all three closing the exact holes that let a "complete failure" bar ship through every prior green gate.**

## Performance

- **Duration:** ~35 min
- **Completed:** 2026-07-15
- **Tasks:** 3/3 completed
- **Files modified:** 5 (2 created, 3 modified)

## Accomplishments

- Built `waybar-design-lint`, a 5-check rerunnable gate (token resolution, alias boundary, transparent window, no literal hex, no empty glyph fields) in the exact bash-wrapper + python-heredoc mould as `theme-doctor`/`waybar-equivalence-check`. Self-tested on the pre-fix tree: 39 FAIL (CHECK D literal hex + CHECK E empty glyphs, exactly as predicted), proving the gate has teeth before being trusted.
- Repaired every confirmed-empty or whitespace-only glyph field across `modules.jsonc`, `config-vertical.jsonc`, and (deviation) `config-minimal.jsonc` — 27 codepoints total, each verified by GLYPH NAME via `fontTools.getBestCmap()` against the installed `FiraCodeNerdFont-Regular.ttf`, not merely confirmed present.
- Removed the hardcoded 5-colour Catppuccin hex block from both calendar tooltips (`modules.jsonc` and `config-vertical.jsonc`), replacing it with weight/underline Pango markup that inherits `color: @fg` from CSS and is automatically correct in light and dark.
- Authored `theme.css`, the sole file permitted to name a raw matugen palette token going forward — 8 role aliases derived via `alpha()`/direct-alias from the 19 real tokens, verified live against a real GTK3 `CssProvider` (0 fatal errors, full flatten).

## Task Commits

1. **Task 1: Assert repo-to-live deployment, then build the waybar-design-lint gate** - `4e0af2e` (feat)
2. **Task 2: Repair every glyph in modules.jsonc against cmap glyph NAMES, not presence** - `3b89773` (fix)
3. **Task 3: Author theme.css — the semantic alias layer** - `41f67c7` (feat)

**Plan metadata:** (this commit, see below)

## Files Created/Modified

- `hypr/.config/hypr/scripts/waybar-design-lint` - New rerunnable 5-check design/token gate (CHECK A-E), executable, accepts optional waybar-dir arg
- `waybar/.config/waybar/modules.jsonc` - Every empty/blank glyph field repaired (mpris, temperature, pulseaudio, cpu, memory, clock, network, custom/theme, custom/waybar-layout, custom/power); calendar hex removed
- `waybar/.config/waybar/config-vertical.jsonc` - Calendar hex block removed (same treatment as modules.jsonc)
- `waybar/.config/waybar/config-minimal.jsonc` - mpris glyph redefinition repaired (deviation — see below)
- `waybar/.config/waybar/theme.css` - New semantic colour alias layer (8 role aliases + geometry-scale documentation)

## Codepoint → Glyph-Name Verification Table

Verified via `fontTools.ttLib.TTFont(...).getBestCmap()` against `/usr/share/fonts/TTF/FiraCodeNerdFont-Regular.ttf`. Every name below was checked against its intended concept before shipping — no codepoint was copied from a cheat-sheet without this step.

**Reference set — already cmap-verified in `config-vertical.jsonc` (08-05), promoted upstream into `modules.jsonc` verbatim:**

| Field | Codepoint | Glyph name | Concept |
|---|---|---|---|
| `cpu.format` | U+F2DB | `fa-microchip` | CPU widget |
| `memory.format` | U+F0C9 | `fa-reorder` | memory widget |
| `temperature.format-icons[0..4]` | U+F2CB / F2CA / F2C9 / F2C8 / F2C7 | `fa-thermometer_empty` / `_quarter` / `_half` / `_three_quarters` / `_full` | 5-step thermometer ramp |
| `pulseaudio.format-muted` | U+F026 | `fa-volume_off` | muted speaker |
| `pulseaudio.format-icons.default[0..2]` | U+F026 / F027 / F028 | `fa-volume_off` / `_low` / `_up` | volume ramp |
| `mpris.player-icons.default` | U+F001 | `fa-music` | generic/unknown player |
| `mpris.player-icons.spotify` | U+F1BC | `fa-spotify` | Spotify |
| `mpris.player-icons.firefox` | U+F269 | `fa-firefox` | Firefox |
| `mpris.player-icons.chromium` | U+F268 | `fa-chrome` | Chromium |
| `mpris.player-icons.mpv` | U+25B6 | `uni25B6` | mpv (already correct, kept) |
| `mpris.status-icons.paused` | U+F04C | `fa-pause` | paused state |
| `network.format-ethernet` | U+F0379 | `md-monitor` | wired connection |
| `network.format-disconnected` | U+F092E | `md-wifi_strength_off_outline` | disconnected |
| `network.format-icons[0..4]` | U+F092F / F091F / F0922 / F0925 / F0928 | `md-wifi_strength_outline` / `_1` / `_2` / `_3` / `_4` | 5-step wifi ramp |

**Not covered by the reference set — picked and name-verified fresh this plan:**

| Field | Codepoint | Glyph name | Concept |
|---|---|---|---|
| `clock.format` / `clock.format-alt` | U+F017 | `fa-clock_o` | clock |
| `custom/theme.format` | U+F042 | `fa-circle_half_stroke` (fa-adjust) | theme toggle — the established split-circle dark/light-mode icon convention |
| `custom/waybar-layout.format` | U+F009 | `fa-th_large` | layout/grid switch |
| `custom/power.format` | U+F011 | `fa-power_off` | power menu (replaces the plain Unicode U+23FB, not a Nerd Font glyph) |

All 27 entries: glyph name matches intended concept, no substitutions needed (unlike 08-05's gaming-mode glyph, which had to be substituted after a name mismatch — none of this plan's picks hit that failure mode).

## Lint Gate Self-Test Evidence

**Pre-fix (Task 1, run immediately after building the gate — before any Task 2/3 edit):**

```
Summary: 17 passed, 39 failed
```
CHECK D (literal hex): FAILED on `config-vertical.jsonc` and `modules.jsonc` (5 Catppuccin hex codes each).
CHECK E (empty glyphs): FAILED on `modules.jsonc` (mpris player-icons/status-icons, temperature/pulseaudio format-icons, cpu/memory/clock/network leading-space fingerprints, custom/theme + custom/waybar-layout whitespace-only) and `config-minimal.jsonc` (its own mpris redefinition, same bug class).
Deployment assertion: `DEPLOY-OK` (confirms `~/.config/waybar` correctly resolves to the in-repo directory — CORRECTION 2 verified, not a repair).

**Post-fix (after Task 2 + Task 3, current tree):**

```
Summary: 23 passed, 9 failed
```
CHECK A: 6/6 PASS (all style sheets + theme.css resolve every referenced colour token).
CHECK D: 11/11 PASS — zero literal hex anywhere in the waybar dir.
CHECK E: 5/5 PASS — zero empty/blank glyph fields across every `config-*.jsonc` + `modules.jsonc`.
CHECK B/C: 9 FAIL, by design — `style-*.css` still reference raw palette tokens directly and `window#waybar` still uses `alpha(@background, 0.90)` rather than `transparent`. This plan makes deliberately NO visual design change; migrating the style sheets to role-name-only + transparent window is plan 08-12's job.

`theme-doctor` run against the full deployed tree: **96 passed, 1 failed** (the 1 failure is `git status --porcelain is empty`, expected during active development with uncommitted work — not a regression). All CSS-parse and D-17 module-gate checks PASS, including the 4 waybar style sheets, confirming zero fatal GTK3 parse errors and full colour-token resolution end to end.

## Decisions Made

- `bar-surface` (the translucent island) derives from `@surface` via `alpha(@surface, 0.55)`, per CORRECTION 1 — there is no `surface_container` token in any of the 22 palette JSONs; verified again directly (`grep -rl surface_container palettes/` returns nothing).
- `waybar-design-lint` CHECK E draws a hard line between GLYPH SLOTS (`player-icons`/`status-icons`/`format-icons` dict-or-array entries — always a bug when blank, one narrow documented exemption) and FORMAT TEMPLATES (scalar `format*` strings — blank is legitimate by design, e.g. `mpris.format-stopped`, but a leading 2+-space run is still the deleted-glyph fingerprint and fails). This is the only design that lets `mpris.status-icons.stopped`/`format-stopped` stay intentionally empty (matching `config-vertical.jsonc`'s own committed rationale) while still catching every real bug the plan describes.
- `network.format-wifi` converted from a static, glyph-less `"  {signalStrength}%"` to `"{icon} {signalStrength}%"` backed by a new 5-step `format-icons` ramp (promoted verbatim from `config-vertical.jsonc`/`config-floating.jsonc`), giving the horizontal/full layout a dynamic signal-strength icon instead of a single static glyph.
- `custom/theme`'s icon was chosen as `fa-adjust`/`fa-circle_half_stroke` (split-circle) over a paintbrush alternative — it's the more universally recognized dark/light theme-toggle icon convention, and both candidates were name-verified before choosing.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - missing critical functionality, own success_criteria] config-minimal.jsonc's mpris redefinition also had empty glyphs**
- **Found during:** Task 2 (first full lint run after fixing modules.jsonc)
- **Issue:** `config-minimal.jsonc` fully redefines the `mpris` module (waybar's whole-key first-defined-wins include semantics), so modules.jsonc's glyph fix never reaches this layout — it would still ship blank player-icons/status-icons.paused. The plan's own `<files>` list for Task 2 names only `modules.jsonc`, but the plan's `<success_criteria>` explicitly requires "Zero empty/whitespace-only glyph fields across modules.jsonc and every config-*.jsonc" — a broader, more authoritative requirement.
- **Fix:** Applied the identical cmap-verified glyphs (U+F001/F1BC/F269/F268 player-icons, U+F04C status-icons.paused) to `config-minimal.jsonc`'s own mpris block, with a comment explaining why this file needed a separate fix.
- **Files modified:** `waybar/.config/waybar/config-minimal.jsonc`
- **Verification:** `waybar-design-lint` CHECK E now passes for `config-minimal.jsonc`.
- **Committed in:** `3b89773` (part of Task 2's commit)

**2. [Rule 3 - blocking issue, verify-script bug] Task 3's own `<verify>` python snippet has a regex-exclusion gap**
- **Found during:** Task 3 verification
- **Issue:** The plan's Task 3 `<verify>` block excludes `{'define','color','import'}` as three separate token strings, but its own regex `@([A-Za-z0-9_-]+)` captures the hyphenated at-rule keyword `define-color` as ONE string (the hyphen is inside the character class). The exclusion set can therefore never match `'define-color'`, so the literal snippet as written FAILS on any theme.css containing `@define-color` lines — i.e. it always fails, since that's the entire content of the file it's checking.
- **Fix:** Re-ran the identical check with only that one regex-exclusion gap closed (added `'define-color'` to the exclusion set) to independently confirm the file's actual correctness. This is not a theme.css content bug — the file's role aliases and token resolution are correct as authored.
- **Files modified:** none (verify-script-only issue, worked around at verification time, not "fixed" in any committed file)
- **Verification:** Corrected check passes: `theme.css roles OK; all refs resolve against the 19 real tokens`. Independently confirmed via a direct `Gtk.CssProvider.load_from_path()` test against the deployed path — 0 fatal parse errors, 1318-byte flattened output containing exactly the 19 real tokens + 8 role aliases.
- **Committed in:** `41f67c7` (documented in the commit message; no separate fix commit needed)

---

**Total deviations:** 2 (1 Rule 2 auto-add for a gap the plan's own success_criteria required, 1 Rule 3 verify-script workaround)
**Impact on plan:** Both necessary for correctness against the plan's own stated acceptance criteria. No scope creep — no visual design changed, only glyph/token correctness.

## Issues Encountered

Initial `Edit` tool calls that typed literal (invisible-to-me) Nerd Font PUA glyph characters directly into `new_string` intermittently failed to persist the intended codepoint (silently produced a no-op edit on the first attempt for the mpris block, though it self-corrected on retry). Switched to explicit `\uXXXX` JSON escape sequences (typed as literal ASCII text) for every subsequent glyph edit, which the Edit tool correctly encodes into the real Unicode character on write — verified byte-for-byte after every edit via a Python read-back (`repr()` of each affected string) before moving to the next field. No incorrect glyph shipped; the affected block was caught and corrected before commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 08-12 (and 08-13/08-14/08-15) can now build the actual visual redesign on top of:
- A `theme-doctor`-proven, zero-fatal-parse-error `theme.css` role-alias layer to migrate `style-*.css` onto (closing CHECK B).
- A `waybar-design-lint` gate that will loudly fail if the redesign reintroduces an unresolvable token, a raw-token reference outside theme.css, a non-transparent `window#waybar`, a literal hex, or a blank glyph.
- A fully-glyphed `modules.jsonc` baseline — no icon-repair work should be needed as part of the visual redesign itself.

No blockers. `waybar-equivalence-check` (a *different*, content-diff gate against a pre-refactor baseline) correctly reports the 3 layouts whose canonical modules changed (full/minimal/vertical) as "differs from baseline" — this is expected drift from this plan's intentional content fixes, not a regression, and the baseline is owned by plan 08-01 (out of scope to re-snapshot here).

---
*Phase: 08-waybar-evolution*
*Completed: 2026-07-15*
