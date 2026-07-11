---
phase: 05-light-mode-pipeline-theme-presets
plan: 02
subsystem: theming
tags: [bash, matugen, palette-json, stow, walker, jq, python3]

# Dependency graph
requires:
  - phase: 05-light-mode-pipeline-theme-presets (plan 01)
    provides: "theme_engine_detect_mode (lib/mode.sh), materialyou-light as a valid theme-apply entry, mode marker written into the render tree before commit"
provides:
  - "14 new standalone palette JSONs (9 Omarchy-lineup dark + 5 canonical-upstream light), all matching the existing 20-key matugen schema"
  - "theme-parity: dynamic palettes/*.json TARGETS enumeration (permanent fix for the hardcoded-array drift risk), materialyou-light accepted in the single-target allowlist, and a mode-fixture section proving THM-01 SC 2 (catppuccin=dark, catppuccin-latte=light)"
  - "theme-stress-test: dynamic STATIC_PRESETS enumeration, even-position materialyou/materialyou-light alternation, sentinel-extraction fix so materialyou-light doesn't abort every run"
  - "theme-switch.sh: dynamic 22-entry walker picker derived from palettes/*.json + both Material You entries, index-matched display/name mapping (no hardcoded case ladder)"
  - "themes/ legacy stow package deleted; stow.sh PACKAGES array and the live ~/.config/themes symlink cleaned up"
affects: [05-03-wallpaper-sets, 05-04-wallpaper-picker]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Palette authoring method: primary/secondary/tertiary/error/outline sourced directly from a theme's own real named accent colors (upstream colors.toml ANSI slots or the framework's own named palette); surface_variant/*_container/on_surface_variant computed via a deterministic linear RGB blend (background/foreground at documented ratios) only when no clean named upstream equivalent exists — never invented arbitrarily"
    - "Light-preset authoring: role mapping copied verbatim from the dark sibling's exact key→upstream-color-name assignment, substituting the light variant's own upstream hex — for kanagawa-lotus specifically, roles were pinned by replicating the exact ANSI term-slot position the dark kanagawa.json used (e.g. crystalBlue's 'blue slot' -> lotusBlue4), not by picking visually-similar lotus colors ad hoc"
    - "Dynamic palettes/*.json glob enumeration is now the ONLY pattern used across the whole pipeline (theme-apply, theme-parity, theme-stress-test, theme-switch.sh) — the two remaining hardcoded preset-name arrays (RESEARCH Pitfall 2) are gone"

key-files:
  created:
    - theme-engine/.config/theme-engine/palettes/matte-black.json
    - theme-engine/.config/theme-engine/palettes/osaka-jade.json
    - theme-engine/.config/theme-engine/palettes/ristretto.json
    - theme-engine/.config/theme-engine/palettes/everfrost.json
    - theme-engine/.config/theme-engine/palettes/kanagawa.json
    - theme-engine/.config/theme-engine/palettes/hackerman.json
    - theme-engine/.config/theme-engine/palettes/miasma.json
    - theme-engine/.config/theme-engine/palettes/ethereal.json
    - theme-engine/.config/theme-engine/palettes/vantablack.json
    - theme-engine/.config/theme-engine/palettes/catppuccin-latte.json
    - theme-engine/.config/theme-engine/palettes/rosepine-dawn.json
    - theme-engine/.config/theme-engine/palettes/gruvbox-light.json
    - theme-engine/.config/theme-engine/palettes/tokyonight-day.json
    - theme-engine/.config/theme-engine/palettes/kanagawa-lotus.json
  modified:
    - theme-engine/.config/theme-engine/theme-parity
    - theme-engine/.config/theme-engine/theme-stress-test
    - hypr/.config/hypr/scripts/theme-switch.sh
    - stow.sh
  deleted:
    - themes/.config/themes/** (36 files — legacy per-app static theme package)

key-decisions:
  - "9 dark Omarchy presets: primary/secondary/tertiary/error/outline pulled directly from each theme's real upstream colors.toml ANSI accent slots (never invented); surface_variant/primary_container/secondary_container computed as background blended 15% toward foreground, on_surface_variant as foreground blended 30% toward background, tertiary_container as tertiary blended 50% toward background — a single deterministic formula applied uniformly since none of these container/variant roles exist as named values in Omarchy's 16-slot colors.toml"
  - "hackerman and vantablack have no red/error hue anywhere in their upstream palettes (verified via colors.toml + btop.theme) — error was mapped to each theme's own highest-contrast/attention accent (hackerman: the bright cyan used as btop's hi_fg highlight; vantablack: the brightest visible gray) rather than inventing a literal red, per-theme judgment call"
  - "kanagawa-lotus's primary/secondary/tertiary/error/outline were pinned by replicating the exact ANSI term-slot POSITION the dark kanagawa.json (Task 1) used against kanagawa.nvim's own wave/lotus term[] tables (blue slot, yellow slot, magenta slot, red slot, bright-black slot) rather than picking visually-similar lotus colors ad hoc — this resolved cleanly because kanagawa.nvim publishes explicit wave/lotus term[] arrays with matching slot order"
  - "Rosé Pine Dawn's RESEARCH Assumption A1 gap (highlight_low/med/high hex values) resolved directly from rose-pine/neovim's palette.lua (highlight_high = #cecacd) rather than re-deriving from the partial WebFetch captured during research"
  - "[Rule 1 - Bug] theme-stress-test's get_expected_sentinel_normalized extended to also match materialyou-light in its waybar.css-read branch — without this fix, wiring materialyou-light into the even-position rotation (Task 3 action 2) would make every materialyou-light switch look up a nonexistent palettes/materialyou-light.json and abort the whole stress-test run"

patterns-established:
  - "Palette container/variant computation formula: blend(background, foreground, 0.15) for surface_variant/*_container panel shades, blend(foreground, background, 0.30) for on_surface_variant, blend(tertiary, background, 0.50) for tertiary_container — reusable for any future preset transcribed from a small named-color source that lacks M3-style container roles"

requirements-completed: [THM-02, THM-01]

coverage:
  - id: D1
    description: "All 9 Omarchy-lineup dark presets (matte-black, osaka-jade, ristretto, everfrost, kanagawa, hackerman, miasma, ethereal, vantablack) exist as palette JSONs matching the 20-key schema and pass theme-parity individually"
    requirement: THM-02
    verification:
      - kind: integration
        ref: "jq -S '.colors | keys' comparison against rosepine.json for all 9 (byte-identical) + `theme-parity <name>` per-name run — all 9 exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "All 5 canonical-light presets (catppuccin-latte, rosepine-dawn, gruvbox-light, tokyonight-day, kanagawa-lotus) exist as standalone palette JSONs matching the 20-key schema and pass theme-parity individually"
    requirement: THM-02
    verification:
      - kind: integration
        ref: "jq -S '.colors | keys' comparison against rosepine.json for all 5 (byte-identical) + `theme-parity <name>` per-name run — all 5 exit 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "theme_engine_detect_mode classifies every one of the 20 shipped palettes correctly: exactly the 5 light presets return light, all 15 others return dark, zero misclassifications, no mode override key needed"
    requirement: THM-01
    verification:
      - kind: integration
        ref: "Live loop over palettes/*.json through theme_engine_detect_mode — 20/20 correct (5 light, 15 dark)"
        status: pass
    human_judgment: false
  - id: D4
    description: "theme-parity with no argument covers every palette JSON dynamically plus materialyou and materialyou-light (22 targets), and asserts a dark fixture (catppuccin) and a light fixture (catppuccin-latte)"
    requirement: THM-01
    verification:
      - kind: integration
        ref: "Full theme-parity run — 22 targets rendered, 1102 checks, 0 failed; mode-fixture section confirms catppuccin=dark and catppuccin-latte=light"
        status: pass
    human_judgment: false
  - id: D5
    description: "theme-stress-test enumerates static presets dynamically from palettes/*.json and alternates materialyou with materialyou-light on even positions"
    requirement: THM-02
    verification:
      - kind: integration
        ref: "bash -n pass + grep confirms dynamic palettes/*.json glob enumeration and materialyou-light in the even-position sequence builder (live 10-switch run deferred to phase verification since it mutates the desktop, per plan's own verify note)"
        status: pass
    human_judgment: false
  - id: D6
    description: "The walker theme picker (theme-switch.sh) offers every palette plus both Material You entries (22 total), with no hardcoded 7-name case ladder"
    requirement: THM-02
    verification:
      - kind: integration
        ref: "Dry-run of the picker's name-generation logic — 22 display/name pairs produced (20 palettes + materialyou + materialyou-light); grep confirms no `case \"$SELECTED\" in` ladder remains"
        status: pass
    human_judgment: false
  - id: D7
    description: "The legacy themes/ stow package is deleted and stow.sh no longer lists it"
    requirement: THM-02
    verification:
      - kind: integration
        ref: "`git rm -r themes/` (36 files) + stow -D themes + PACKAGES array edit; repo-wide grep for the legacy config path returns nothing; live ~/.config/themes symlink removed"
        status: pass
    human_judgment: false

duration: ~30min
completed: 2026-07-12
status: complete
---

# Phase 5 Plan 2: Static Preset Expansion Summary

**Expanded the static preset library from 6 to 20 palette JSONs (9 Omarchy-lineup dark + 5 canonical-upstream light), fixed the two hardcoded preset-name arrays that would have silently excluded them from every gate, and deleted the legacy per-app themes/ stow package.**

## Performance

- **Duration:** ~30 min
- **Completed:** 2026-07-12T01:51:06+03:00
- **Tasks:** 3
- **Files modified:** 54 (14 created, 4 modified, 36 deleted)

## Accomplishments
- 9 new dark palette JSONs transcribed directly from Omarchy's upstream `colors.toml` per theme (matte-black, osaka-jade, ristretto, everfrost, kanagawa, hackerman, miasma, ethereal, vantablack) — `primary`/`secondary`/`tertiary`/`error`/`outline` sourced from each theme's real ANSI accent slots, container/variant roles computed via a documented deterministic blend formula, all verified against `rosepine.json`'s exact 20-key schema and passing `theme-parity` individually.
- 5 new light palette JSONs (catppuccin-latte, rosepine-dawn, gruvbox-light, tokyonight-day, kanagawa-lotus) authored by copying each dark sibling's exact key→named-color role mapping and substituting the light variant's own official upstream hex values (fetched live from catppuccin/palette, rose-pine/neovim, ellisonleao/gruvbox.nvim, folke/tokyonight.nvim, rebelot/kanagawa.nvim). No nord-light or dracula-light/alucard.json — neither family has a free canonical light variant.
- Mode classification (`theme_engine_detect_mode`) verified across all 20 shipped palettes with zero misclassifications and zero `"mode"` override keys needed — the perceptual-lightness fallback alone correctly separates the 5 light presets from the 15 dark ones.
- `theme-parity`'s and `theme-stress-test`'s hardcoded preset-name arrays (RESEARCH Pitfall 2) replaced with dynamic `palettes/*.json` glob enumeration, matching `theme-apply`'s own pattern — every current and future preset is now automatically covered by both gates. `theme-parity` also gained a mode-fixture section (report-only, same accumulator) proving THM-01 SC 2: every rendered target writes a light/dark mode file, and the two pinned fixtures (catppuccin=dark, catppuccin-latte=light) both pass. Full run: 22 targets, 1102 checks, 0 failed.
- `theme-switch.sh` rewritten to generate its picker list dynamically from `palettes/*.json` basenames plus both Material You entries (22 total), with prettified display names mapped back to the exact palette basename via a parallel index-matched array — no reverse string-transform ambiguity, and `theme-apply` still re-validates the final name regardless (defense in depth).
- Legacy `themes/` stow package (36 files, zero references anywhere else in the repo — reconfirmed via a fresh grep) deleted; `stow.sh`'s `PACKAGES` array and the live `~/.config/themes` symlink cleaned up.

## Task Commits

1. **Task 1: Transcribe the 9 Omarchy-lineup dark presets as palette JSONs (D-01)** - `376bfa6` (feat)
2. **Task 2: Author the 5 canonical light presets and validate mode classification across all palettes (D-02/D-03/D-06)** - `967752b` (feat)
3. **Task 3: Dynamic gate coverage, picker surface, and legacy themes/ deletion (Pitfall 2, D-04)** - `b17658d` (feat)

**Plan metadata:** (this commit, docs)

## Files Created/Modified
- `theme-engine/.config/theme-engine/palettes/{matte-black,osaka-jade,ristretto,everfrost,kanagawa,hackerman,miasma,ethereal,vantablack}.json` - NEW: 9 Omarchy-lineup dark presets
- `theme-engine/.config/theme-engine/palettes/{catppuccin-latte,rosepine-dawn,gruvbox-light,tokyonight-day,kanagawa-lotus}.json` - NEW: 5 canonical light presets
- `theme-engine/.config/theme-engine/theme-parity` - dynamic TARGETS enumeration, materialyou-light in the single-target allowlist, new mode-fixture section
- `theme-engine/.config/theme-engine/theme-stress-test` - dynamic STATIC_PRESETS enumeration, materialyou/materialyou-light even-position alternation, sentinel-extraction fix for materialyou-light
- `hypr/.config/hypr/scripts/theme-switch.sh` - rewritten: dynamic 22-entry picker list, index-matched display/name mapping
- `stow.sh` - `themes` removed from PACKAGES array
- `themes/.config/themes/**` - DELETED (36 files, legacy per-app static theme package)

## Decisions Made
- Palette container/variant roles (surface_variant, primary_container, secondary_container, on_surface_variant, tertiary_container) for all 14 new presets were computed via a single deterministic linear-RGB blend formula (documented above) rather than hand-picked per theme — Claude's Discretion per CONTEXT.md ("Omarchy palette transcription details... key mapping" and lightness-detection math were both explicitly left to the planner/executor), applied uniformly for consistency and auditability.
- hackerman and vantablack's `error` key was mapped to each theme's own highest-contrast accent (not a literal red) since neither upstream palette contains any red/warm hue at all — verified by inspecting both `colors.toml` and `btop.theme` before concluding no red exists.
- kanagawa-lotus's five accent roles were pinned by matching the exact ANSI term-slot position the dark kanagawa.json used against kanagawa.nvim's own `wave`/`lotus` term[] arrays, rather than picking visually similar lotus colors — this was possible because kanagawa.nvim publishes explicit per-variant term[] tables with matching slot order, giving a non-arbitrary mapping.
- Rosé Pine Dawn's missing `highlight_high` hex (RESEARCH Assumption A1) was resolved directly from `rose-pine/neovim`'s `palette.lua` (`#cecacd`) during this execution rather than left as a placeholder.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] theme-stress-test's sentinel-extraction didn't recognize materialyou-light**
- **Found during:** Task 3 (wiring materialyou-light into the even-position sequence rotation)
- **Issue:** `get_expected_sentinel_normalized` only special-cased the literal `"materialyou"`; every other name (including the newly-introduced `materialyou-light`) fell into the static-preset branch and looked up `palettes/materialyou-light.json`, which does not exist. Once materialyou-light entered the alternating sequence, every such switch would fail sentinel extraction and abort the entire stress-test run.
- **Fix:** Extended the branch condition to `[[ "$name" == "materialyou" || "$name" == "materialyou-light" ]]`, reusing the existing waybar.css-read path for both.
- **Files modified:** `theme-engine/.config/theme-engine/theme-stress-test`
- **Verification:** `bash -n` passes; the function's only call site (inside the switch loop) now handles both literals identically to the pre-existing materialyou path.
- **Committed in:** `b17658d` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary correctness fix for a bug this plan's own materialyou-light rotation change would otherwise have introduced. No scope creep — no other file or behavior touched.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Preset library now stands at 20 palette JSONs (14 new + 6 pre-existing), all covered by dynamic `theme-parity`/`theme-stress-test`/`theme-switch.sh` enumeration — no further array maintenance needed when Plan 05-03 adds wallpaper sets per preset.
- Plan 05-03 (wallpaper sets) can now rely on every preset name in `palettes/*.json` having a corresponding entry across the whole pipeline; the strict `Wallpapers/<preset-name>/` naming convention (D-09) can proceed against this now-complete preset list, including the `everfrost` vs `everforest` naming decision already locked by D-01/D-09 in this plan's own action text.
- `theme-stress-test`'s live 10+-switch run (which now includes materialyou-light in its rotation) was not executed in this plan per its own verification note (it mutates the live desktop) — recommended as part of phase-level verification/UAT before Phase 5 closes.

---
*Phase: 05-light-mode-pipeline-theme-presets*
*Completed: 2026-07-12*
