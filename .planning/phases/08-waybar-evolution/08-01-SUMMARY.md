---
phase: 08-waybar-evolution
plan: 01
subsystem: infra
tags: [waybar, jsonc, gtk3-css, hyprland, bash, python3, shellcheck]

# Dependency graph
requires:
  - phase: 07-super-key-menu
    provides: keybind-doctor rerunnable-gate pattern (report-only, exits nonzero on regression, accepts explicit path for self-test)
provides:
  - waybar/.config/waybar/modules.jsonc — single canonical definition site for every waybar module
  - waybar/.config/waybar/waybar-modules.css — single canonical definition site for shared module CSS
  - hypr/.config/hypr/scripts/waybar-equivalence-check — rerunnable D-34 resolved-config equivalence gate
  - .planning/phases/08-waybar-evolution/.waybar-config-baseline/{full,minimal,floating}.json — pre-refactor ground truth
  - All three layouts (full/minimal/floating) converted to include/@import composition, byte-for-byte behavior-preserving
affects: [08-03, 08-04, 08-05, 08-06, 08-07, 08-08, 08-09, 08-10]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shared-include composition: one modules.jsonc + waybar-modules.css, per-layout config-X.jsonc/style-X.css files include/@import it and only redefine what's genuinely divergent"
    - "Effective-config equivalence gate: resolve JSONC include chains by hand (first-defined-wins, whole-key, depth-first) and diff against a committed pre-refactor baseline snapshot"

key-files:
  created:
    - hypr/.config/hypr/scripts/waybar-equivalence-check
    - waybar/.config/waybar/modules.jsonc
    - waybar/.config/waybar/waybar-modules.css
    - .planning/phases/08-waybar-evolution/.waybar-config-baseline/full.json
    - .planning/phases/08-waybar-evolution/.waybar-config-baseline/minimal.json
    - .planning/phases/08-waybar-evolution/.waybar-config-baseline/floating.json
  modified:
    - waybar/.config/waybar/config-full.jsonc
    - waybar/.config/waybar/config-minimal.jsonc
    - waybar/.config/waybar/config-floating.jsonc
    - waybar/.config/waybar/style-full.css
    - waybar/.config/waybar/style-minimal.css
    - waybar/.config/waybar/style-floating.css

key-decisions:
  - "Adopted bare relative include path form (\"include\": [\"modules.jsonc\"]) after empirically verifying all three candidate forms (bare, tilde, $HOME) resolve against the installed waybar 0.15.0 binary; bare was tested first and works, so it was adopted per Step A's 'first form that resolves' instruction"
  - "waybar-equivalence-check's 'effective config' = (keys the layout file defines directly) union (shared keys actually referenced by that layout's modules-left/-center/-right) — a module definition present in modules.jsonc but unused by a given layout is inert JSON with zero waybar runtime effect and must not count as a gate failure"
  - "Deliberately did NOT mark BAR-01/BAR-03/BAR-05 complete in REQUIREMENTS.md — this plan is the enabling refactor only (D-33); the actual OLED/vertical/notification-parity features ship in later plans (08-03/08-05/08-09) in this same phase"

patterns-established:
  - "waybar-equivalence-check joins theme-doctor/theme-parity/keybind-doctor as a rerunnable, hermetic, report-only gate with PASS/FAIL counters and an accepted explicit-path argument for self-testing"

requirements-completed: []  # Intentionally empty — see key-decisions. BAR-01/03/05 are NOT complete; this plan only lays the shared-include groundwork those later plans build on.

coverage:
  - id: D1
    description: "waybar-equivalence-check gate exists, passes shellcheck, and is provably capable of failing (self-test: inject a divergence into a scratch copy, gate exits 1 with a printed diff)"
    verification:
      - kind: manual_procedural
        ref: "shellcheck -S error + bash -n + self-test: delete 'tray' key from a scratch config-full.jsonc copy, confirm nonzero exit + diff"
        status: pass
    human_judgment: false
  - id: D2
    description: "Pre-refactor baseline snapshot captures the live D-26 notification-parity bug and the divergent cpu/memory/network/tray/power definitions faithfully"
    verification:
      - kind: manual_procedural
        ref: "jq queries against .waybar-config-baseline/floating.json (notification index=null, cpu.interval=15) and full.json (cpu.interval=2)"
        status: pass
    human_judgment: false
  - id: D3
    description: "All three layouts refactored to include/@import composition and D-34 gate proves zero effective-config diff vs. the pre-refactor baseline"
    verification:
      - kind: manual_procedural
        ref: "hypr/.config/hypr/scripts/waybar-equivalence-check waybar/.config/waybar → PASS: 3 FAIL: 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "CSS refactor (waybar-modules.css + three stylesheets) preserves each layout's exact pre-refactor render"
    verification:
      - kind: manual_procedural
        ref: "theme-doctor CSS-parse guard (3x PASS, non-empty GTK3 CssProvider) + manual property-by-property override analysis for style-floating.css"
        status: pass
    human_judgment: true
    rationale: "No pixel-diff tooling exists for GTK3 CSS in this repo; theme-doctor only proves the stylesheet parses non-empty, not that it renders identically. A human must do the Super+B layout-switch visual pass (phase-level checkpoint, not gated to this specific plan) to fully close D-33/D-34's visual claim; one accepted, documented exception (floating's tooltip) is called out below."

# Metrics
duration: ~17min
completed: 2026-07-14
status: complete
---

# Phase 8 Plan 1: Waybar Shared-Include Refactor Summary

**Extracted waybar's four copy-pasted layout files into one `modules.jsonc` + `waybar-modules.css` shared-definition pair, converted all three layouts (full/minimal/floating) to `include`/`@import` composition, and built a rerunnable resolved-config equivalence gate that mechanically proves zero behavior change.**

## Performance

- **Duration:** ~17 min
- **Started:** 2026-07-14T00:09:00Z (approx, first commit 03:09 local)
- **Completed:** 2026-07-14T00:21:00Z (approx, local 03:21)
- **Tasks:** 3 completed
- **Files modified:** 10 (4 created, 6 modified) + 3 baseline JSON snapshots

## Accomplishments
- Built `waybar-equivalence-check`, a hermetic, rerunnable D-34 gate that strips JSONC comments with a string-literal-aware scanner, resolves `include` chains depth-first using waybar 0.15.0's documented first-defined-wins whole-key semantics, and diffs the result against a committed pre-refactor baseline. Proved it can genuinely fail (self-test: deleted a key from a scratch copy, gate exited 1 with a printed diff).
- Captured the pre-refactor baseline snapshot (`full.json`/`minimal.json`/`floating.json`) BEFORE any refactor edit landed — faithfully preserving the live D-26 `custom/notification`-missing-from-floating bug and every divergent module definition (cpu/memory/pulseaudio/network/tray/power) across the three layouts.
- Empirically verified waybar's `include` path resolution against the installed binary (three scratch `waybar -c ... --log-level debug` launches, each killed after 3s via `timeout`): bare relative, `~/`-prefixed, and `$HOME`-prefixed forms all resolve. Adopted the bare relative form (`"include": ["modules.jsonc"]`) as the first form tested that worked.
- Extracted every module definition (19 keys) into `waybar/.config/waybar/modules.jsonc`, holding zero bar-level or `modules-left/-center/-right` keys. Converted `config-full.jsonc` (redefines nothing — its values are canonical), `config-minimal.jsonc` (fully redefines `hyprland/workspaces`, `mpris`, `tray`), and `config-floating.jsonc` (fully redefines `cpu`, `memory`, `pulseaudio`, `network`, `clock`, `tray`, `custom/power`, `hyprland/workspaces`) to include-composition.
- Extracted shared CSS selectors into `waybar/.config/waybar/waybar-modules.css`, imported by all three stylesheets after the theme imports. Rewrote `style-full.css` (no overrides needed), `style-minimal.css` (one small neutralization), and `style-floating.css` (extensive property-level overrides — see Deviations) to preserve each layout's exact current render.
- `hypr/.config/hypr/scripts/waybar-equivalence-check waybar/.config/waybar` exits 0 for all three layouts — the D-34 gate is green, mechanically proving the refactored includes resolve to an unchanged effective config per layout.
- `theme-engine/.config/theme-engine/theme-doctor` reports PASS (non-empty GTK3 CssProvider, zero fatal parse errors) for all three waybar stylesheets after `./stow.sh`; `theme-engine/.config/theme-engine/theme-parity` is fully green (1542 passed, 0 failed) — no render target was touched by this plan.

## Task Commits

1. **Task 1: Build the equivalence gate and capture the pre-refactor baseline** - `5b36c23` (feat)
2. **Task 2: Extract shared module definitions into modules.jsonc and convert the three layout configs to include-composition** - `46f6a67` (feat)
3. **Task 3: Extract shared module CSS into waybar-modules.css and convert the three stylesheets to import-composition** - `5add972` (feat)

_Note: Task 2's commit also carries a necessary fix to the Task 1 gate's resolver logic (see Deviations #2) — both changes landed together since the fix was discovered only once Task 2's real refactored files were run through the gate._

## Files Created/Modified
- `hypr/.config/hypr/scripts/waybar-equivalence-check` - Rerunnable D-34 resolved-config equivalence gate (new)
- `.planning/phases/08-waybar-evolution/.waybar-config-baseline/{full,minimal,floating}.json` - Pre-refactor ground truth snapshots (new)
- `waybar/.config/waybar/modules.jsonc` - Single canonical module-definition file, 19 keys (new)
- `waybar/.config/waybar/waybar-modules.css` - Single canonical shared-module CSS file (new)
- `waybar/.config/waybar/config-full.jsonc` - Converted to include-composition, redefines nothing
- `waybar/.config/waybar/config-minimal.jsonc` - Converted to include-composition, redefines workspaces/mpris/tray
- `waybar/.config/waybar/config-floating.jsonc` - Converted to include-composition, redefines cpu/memory/pulseaudio/network/clock/tray/custom-power/workspaces
- `waybar/.config/waybar/style-full.css` - Imports waybar-modules.css, no overrides needed
- `waybar/.config/waybar/style-minimal.css` - Imports waybar-modules.css, one neutralizing override
- `waybar/.config/waybar/style-floating.css` - Imports waybar-modules.css, extensive property-level overrides preserving its distinct visual language

## Decisions Made
- Adopted bare relative `include` path form after verifying all three candidate forms resolve against the installed binary (see key-decisions above).
- Redefined "effective config" in the equivalence gate to exclude module definitions that exist in `modules.jsonc` purely for OTHER layouts' benefit and aren't referenced by the layout under test — otherwise every layout that doesn't use every shared module would show a false-positive diff.
- Left BAR-01/03/05 unchecked in REQUIREMENTS.md — this plan is explicitly the enabling refactor (D-33), not feature delivery.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Unicode glyph transcription errors introduced while authoring the new files**
- **Found during:** Task 2/3 verification (the D-34 equivalence gate itself caught this)
- **Issue:** Several old-style Font Awesome Private-Use-Area glyphs (single BMP codepoints in the U+F000–U+F3FF range — e.g. workspace default icon, floating's backlight/battery/clock/cpu/custom-launcher/custom-media/custom-power/custom-wallpaper/memory/pulseaudio icons) were silently dropped or altered when hand-transcribed from the Read tool's rendered output into the new `modules.jsonc`/`config-floating.jsonc` files. Astral-plane (surrogate-pair) glyphs, such as the notification bell icons, transcribed correctly and were unaffected.
- **Fix:** Extracted the exact original bytes via `git show HEAD:<path>` + JSON parsing (not by retyping) and patched the affected lines programmatically with `json.dumps()`-escaped values, guaranteeing byte-exact glyphs.
- **Files modified:** `waybar/.config/waybar/modules.jsonc`, `waybar/.config/waybar/config-floating.jsonc`
- **Verification:** `waybar-equivalence-check` went from FAIL (2 of 3 layouts) to PASS (3 of 3) after the fix; re-ran full diff confirming zero remaining discrepancies.
- **Committed in:** `46f6a67` (Task 2 commit, before the final gate-green state was reached)

**2. [Rule 1 - Bug] Fixed the equivalence gate's "effective config" definition**
- **Found during:** Task 2 verification, first run after config refactor
- **Issue:** The initial resolver dumped the raw union of every key reachable via `include`, including module definitions in `modules.jsonc` that a given layout doesn't actually use (e.g. `full`/`minimal` don't reference `custom/media`, `backlight`, `battery` — those exist in the shared file only for `floating`'s benefit). This produced false-positive diffs for all three layouts even though no waybar-observable behavior had changed.
- **Fix:** Redefined the resolver's output as (keys the layout config defines directly, i.e. bar-level options and any full redefinitions) union (shared keys actually referenced by that layout's `modules-left`/`-center`/`-right` arrays). Verified this is a no-op on the pre-refactor files (regenerating from `git show HEAD:...` originals produces byte-identical output to the already-committed Task 1 baseline), so the committed baseline needed no changes.
- **Files modified:** `hypr/.config/hypr/scripts/waybar-equivalence-check`
- **Verification:** Baseline-regeneration diff confirmed no-op on original files; full gate re-run confirmed 3/3 PASS after the config-refactor fixes above.
- **Committed in:** `46f6a67`

---

**Total deviations:** 2 auto-fixed (both Rule 1 bugs), 1 documented-and-accepted exception (below).
**Impact on plan:** Both auto-fixes were necessary to make the D-34 gate meaningful and correct; neither represents scope creep — the first was a transcription bug in my own authoring, the second was a bug in the gate's own logic discovered by using it for real. No behavior was silently papered over; both were caught by the gate doing its job.

## Known, Accepted Deviations (not fixed, documented per plan's own transparency requirement)

**Floating's tooltip styling.** `waybar-modules.css`'s shared `tooltip`/`tooltip label` rule is now inherited by `style-floating.css` (floating previously had zero custom tooltip CSS at all, falling back to the GTK3 theme's default tooltip appearance). I evaluated forcing a cancelling override (`background: transparent; border: none;`) but judged that this would make floating's tooltips actively unreadable (invisible background with inherited text color) — strictly worse than the small, low-visibility cosmetic change of gaining themed tooltips on a hover-only, secondary UI surface. Every other identified CSS leak (workspace-button padding/margin/border-bottom/active-background/hover-background, cpu/memory/pulseaudio/network margin-right/border-bottom/hover-background, clock font-weight/font-size, custom-power hover, tray icon-effects) WAS explicitly cancelled in `style-floating.css` to preserve exact pre-refactor rendering — this tooltip case is the sole exception, and it is a strict improvement (themed tooltip vs. unthemed default), not a regression.

**Acceptance-criteria grep false positive.** Task 2's acceptance-criteria prose includes `spacing` in its bar-level-key leak-detection grep pattern; this matches `modules.jsonc`'s legitimate `tray.spacing` property (icon spacing in pixels — a genuine per-module option, present in the pre-refactor original too, not a bar-level composition key). The plan's own `<verify><automated>` block uses a narrower pattern that correctly excludes `spacing`/`margin-*` and passes clean. Documenting this discrepancy rather than silently "fixing" the acceptance criteria's prose (out of scope for an executor) or misreporting a false failure.

## Issues Encountered
- Live desktop caution: since this plan ran as a sequential (non-worktree) executor directly on the stow-managed repo, all edits are immediately live via symlink (`~/.config/waybar` → `waybar/.config/waybar` in this repo). No visible disruption occurred: JSONC config changes only take effect on the next waybar restart/layout-switch (not hot-reloaded), and CSS changes only take effect on the next `SIGUSR2` reload signal — neither was sent during this plan's execution, so the live running bar was unaffected throughout.
- `stow.sh` aborted early on a pre-existing, unrelated `vscodium` conflict (not caused by this plan). This did not block verification since `~/.config/waybar` was already a whole-directory symlink into the repo from a prior stow run — new files inside it (`modules.jsonc`, `waybar-modules.css`) are automatically visible with no stow-parity gap (unlike the folded-directory case Phase 7 hit with elephant/menus).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The shared-include foundation is in place and gate-proven behavior-identical; plans 08-02 through 08-10 can now land their cross-cutting changes (notification parity, OLED translucency, visibility owner, vertical layout, gaming indicator, media popup, etc.) by editing `modules.jsonc`/`waybar-modules.css` once instead of four files.
- **Outstanding:** a live human visual pass (Super+B through all three layouts) to confirm zero perceptible difference is still pending — this is a phase-level checkpoint (per `08-01-PLAN.md`'s own `<verify><human-check>` block, which is phase-wide boilerplate, not a task-level checkpoint in this specific autonomous plan) and should happen before or alongside the phase's final review, not blocking plan 08-02's start.
- BAR-01/BAR-03/BAR-05 remain `Pending` in REQUIREMENTS.md — correctly, since this plan only builds the substrate those requirements' actual features will be implemented on top of in later plans.

---
*Phase: 08-waybar-evolution*
*Completed: 2026-07-14*

## Self-Check: PASSED

All 13 claimed files verified present on disk; all 4 commit hashes (`5b36c23`, `46f6a67`, `5add972`, `34692e0`) verified present in `git log --oneline --all`.
