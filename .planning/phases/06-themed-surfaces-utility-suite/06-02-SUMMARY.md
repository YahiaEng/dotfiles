---
phase: 06-themed-surfaces-utility-suite
plan: 02
subsystem: theming-pipeline
tags: [matugen, theme-engine, contract-json, hyprlock, swayosd, zen-browser, satty, css-literal, hypr-vars, toml]

# Dependency graph
requires:
  - phase: 05-light-mode-pipeline-theme-presets
    provides: dynamic palettes/*.json enumeration consumed automatically by theme-parity for every new contract target
provides:
  - "4 new matugen render targets (hyprlock-colors.conf, swayosd-colors.css, zen-userchrome.css, satty-colors.toml) registered in config.toml + contract.json"
  - "contract.json files array grown 13->17 (D-30 reconciliation)"
  - "commit.sh satty symlink wiring (~/.config/satty/config.toml -> $STATE_DIR/satty.toml)"
  - "theme-parity green across all 17 targets, 22 palettes (incl. catppuccin dark + catppuccin-latte light fixtures)"
affects: [06-04-hyprlock, 06-05-satty-screenshot-suite, 06-06-swayosd-zen]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "hypr-vars format (hyprlock-colors.conf) — verbatim copy of hyprland-colors.conf's 19-key $key = rgba(hex_stripped ff) shape, minus the $image line"
    - "gtk-css @define-color format (swayosd-colors.css) — verbatim copy of swaync-colors.css's 19-key shape"
    - "css-literal format (zen-userchrome.css) — :root CSS custom properties + var(--key) chrome selectors, same style as walker-style.css's non-@define-color approach"
    - "toml format (satty-colors.toml) — [general] static behavior block + [color-palette] pipeline-themed 7-swatch array, palette entries use {{colors.KEY.default.hex}} (# prefix) + literal 'ff' suffix, not hex_stripped"

key-files:
  created:
    - matugen/.config/matugen/templates/hyprlock-colors.conf
    - matugen/.config/matugen/templates/swayosd-colors.css
    - matugen/.config/matugen/templates/zen-userchrome.css
    - matugen/.config/matugen/templates/satty-colors.toml
  modified:
    - matugen/.config/matugen/config.toml
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/lib/commit.sh

key-decisions:
  - "satty palette entries render via {{colors.KEY.default.hex}}ff (hex already carries the # prefix) instead of hex_stripped+ff — satty's hex_color Rust crate requires a leading '#' on RRGGBBAA values; hex_stripped would have produced an unparseable palette. Verified against the live upstream github.com/gabm/Satty config.toml (installed candidate 0.21.1, official extra repo) fetched during execution, not just the plan's own hex_stripped example."
  - "satty [general] keys sourced from the live upstream config.toml rather than a local `satty --help` run, since satty is not installed on this dev machine yet (its install is scoped to a later plan) — initial-tool=\"arrow\", early-exit=[\"all\"], actions-on-enter=[\"save-to-clipboard\",\"save-to-file\"] implement D-02's 'default tool arrow, Enter/Ctrl+C = copy+save+exit' behavior using the confirmed-real modern schema (actions-on-enter, not the deprecated singular action-on-enter)."
  - "zen-userchrome.css chrome selectors authored fresh against standard Firefox-family chrome IDs (#nav-bar, #TabsToolbar, #sidebar-box, #urlbar-background, .tabbrowser-tab[selected]) since no existing analog exists in this repo (PATTERNS.md confirms 'no analog' for Zen selector authoring) — scoped strictly to D-27's chrome-colors-only boundary, no new-tab-page or deep element styling."
  - "hyprlock-colors.conf omits $image (per plan's explicit instruction) and $shadow (hyprland-colors.conf's literal, non-palette-driven extra) — only the 19 palette-driven keys, since hyprlock's background-path wiring is out of scope for this plan (deferred to 06-04)."

patterns-established:
  - "New matugen render target = 1 template file + 1 [templates.X] config.toml block + 1 contract.json files entry, all landing in the single Wave-1 'hub' plan so no downstream surface plan touches contract.json/config.toml again"
  - "Non-@define-color CSS surfaces (Firefox-family userChrome.css) use the css-literal format: :root custom properties + var(--key) references, matching walker-style.css's established precedent"
  - "New app-config symlink wiring in commit.sh follows the walker/yazi/gtk idempotent ln -sf idiom, guarded by an -L folded-stow-symlink check"

requirements-completed: [LOCK-01, OSD-01, THM-05, SHOT-02]

coverage:
  - id: D1
    description: "4 new matugen templates authored (hyprlock-colors.conf, swayosd-colors.css, zen-userchrome.css, satty-colors.toml) with zero literal-hex leaks outside the documented E53935ff/#E53935ff exemption"
    requirement: "LOCK-01"
    verification:
      - kind: unit
        ref: "theme-engine/.config/theme-engine/theme-parity (color-wellformedness + no-raw-{{-leftover checks across 22 palettes)"
        status: pass
    human_judgment: false
  - id: D2
    description: "contract.json files array grows 13->17 with exactly the 4 new entries; wlogout.css untouched (D-30 reconciliation)"
    requirement: "OSD-01"
    verification:
      - kind: unit
        ref: "jq '.files | length' contract.json == 17; jq count of wlogout.css entries == 1"
        status: pass
    human_judgment: false
  - id: D3
    description: "commit.sh symlinks ~/.config/satty/config.toml to the rendered satty.toml, idempotently and folded-stow-guarded"
    requirement: "SHOT-02"
    verification:
      - kind: unit
        ref: "bash -n theme-engine/.config/theme-engine/lib/commit.sh; manual read of the ln -sf block against the walker/yazi/gtk precedent"
        status: pass
    human_judgment: false
  - id: D4
    description: "theme-parity passes render + key-parity + color-wellformedness for all 17 targets under both catppuccin (dark) and catppuccin-latte (light) fixtures"
    requirement: "THM-05"
    verification:
      - kind: unit
        ref: "theme-engine/.config/theme-engine/theme-parity full run — 1542 passed, 0 failed"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-12
status: complete
---

# Phase 06 Plan 02: Themed Surfaces Contract Registration Summary

**4 new matugen render targets (hyprlock, SwayOSD, Zen chrome, satty) registered in the single Wave-1 hub — contract.json 13->17, theme-parity green across 22 palettes incl. light+dark fixtures**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-07-12
- **Tasks:** 3
- **Files modified:** 7 (4 created, 3 edited)

## Accomplishments
- Authored 4 new matugen templates covering hyprlock's dedicated color file (D-30 decoupling from hyprland.conf), SwayOSD's pill CSS, Zen browser's chrome-colors-only userChrome.css, and satty's annotation config (D-02 behavior + D-31 palette)
- Registered all 4 as `[templates.*]` blocks in matugen/config.toml and as `contract.json` `files` entries (13->17), leaving the pre-existing `wlogout.css` entry untouched per the D-30/Pitfall-1 reconciliation
- Wired satty's config symlink into `commit.sh` following the exact walker/yazi/gtk idempotent `ln -sf` + folded-stow-guard idiom
- Verified all 17 contract targets (including the 4 new ones) render, key-parity-match, and are color-well-formed across all 22 palettes — 1542/1542 theme-parity checks passed, including both the catppuccin (dark) and catppuccin-latte (light) fixtures explicitly called out in the plan's verification

## Task Commits

Each task was committed atomically:

1. **Task 1: Author the 4 new matugen templates (D-24/D-27/D-30/D-31)** - `5b3086a` (feat)
2. **Task 2: Register templates in config.toml, contract.json (13→17), and commit.sh satty symlink (D-30)** - `50e6045` (feat)
3. **Task 3: Verify theme-parity renders all 17 targets under light + dark fixtures (D-29)** - verification-only, no code changes; folded into this SUMMARY commit

## Files Created/Modified
- `matugen/.config/matugen/templates/hyprlock-colors.conf` - New hypr-vars render target, 19 palette keys, no `$image`/`$shadow`
- `matugen/.config/matugen/templates/swayosd-colors.css` - New gtk-css `@define-color` render target, 19 keys
- `matugen/.config/matugen/templates/zen-userchrome.css` - New css-literal render target, `:root` custom properties + chrome-colors-only selector rules
- `matugen/.config/matugen/templates/satty-colors.toml` - New toml render target, `[general]` D-02 behavior + `[color-palette]` D-31 7-swatch array
- `matugen/.config/matugen/config.toml` - Added `[templates.hyprlock|swayosd|zen|satty]` blocks
- `theme-engine/.config/theme-engine/contract.json` - `files` array grown 13->17
- `theme-engine/.config/theme-engine/lib/commit.sh` - Added idempotent satty config symlink wiring

## Decisions Made
- Used `{{colors.KEY.default.hex}}ff` (hex already carries `#`) instead of the plan's own `hex_stripped`-based example for satty's palette array — satty's `hex_color` Rust crate parser requires a leading `#` on `RRGGBBAA` strings (confirmed directly against the live `github.com/gabm/Satty` upstream `config.toml`, fetched during execution since satty is not yet installed on this dev machine). Using `hex_stripped` as originally written in RESEARCH.md/PATTERNS.md/UI-SPEC.md would have rendered an unparseable palette that silently broke satty's annotation-color feature — classified as a Rule 1 (auto-fix bug) correction.
- Sourced satty's `[general]` key names (`initial-tool`, `early-exit`, `actions-on-enter`) from the live upstream `config.toml` rather than a local `satty --help` invocation, since satty isn't installed here yet (install is scoped to a later plan in this phase). This is a stronger source than the plan's suggested "verify-at-execution via `satty --help`" fallback and resolves RESEARCH.md's Assumption A1 without needing the checkpoint that assumption flagged.
- Authored Zen chrome selectors fresh (no existing repo analog per PATTERNS.md) using standard, widely-used Firefox-family chrome IDs, strictly scoped to D-27's chrome-colors-only boundary.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] satty palette hex format corrected from `hex_stripped` to `hex` (with `#` prefix)**
- **Found during:** Task 1 (authoring satty-colors.toml)
- **Issue:** The plan/PATTERNS.md/UI-SPEC.md/RESEARCH.md all specify `{{colors.KEY.default.hex_stripped}}ff` for the satty `[color-palette].palette` array (no `#` prefix). Fetching the live upstream `github.com/gabm/Satty` `config.toml` and inspecting `src/configuration.rs` (`hex_color::HexColor` parser) confirmed satty's TOML palette values must be `#RRGGBBAA` — a bare `RRGGBBAAf` string without `#` would fail to parse, breaking the entire annotation-color feature.
- **Fix:** Used `{{colors.KEY.default.hex}}ff` (matugen's `hex` field already includes `#`) for all 6 templated palette slots, and `#E53935ff` (with `#`) for the true-red literal exemption.
- **Files modified:** `matugen/.config/matugen/templates/satty-colors.toml`
- **Verification:** theme-parity's color-wellformedness + key-parity checks pass for `satty.toml` across all 22 palettes (1542/1542 total); grep for the `E53935ff` exemption still matches (substring-safe).
- **Committed in:** `5b3086a` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary for satty.toml to actually be a valid, parseable config once satty is installed and consumes it (06-05). No scope creep — no new files or targets added beyond the plan's 4.

## Issues Encountered
- satty is not installed on this dev machine (confirmed via `pacman -Q satty` / `command -v satty`), so the plan's "verify exact key spelling via `satty --help`" step could not run locally. Resolved by fetching the live upstream `config.toml` directly from `github.com/gabm/Satty` (internet access was available), which is a stronger ground-truth source than the plan's own hex_stripped example and directly surfaced the `#`-prefix requirement above. Installing satty itself is out of scope for this plan (deferred to whichever later plan in this phase wires the actual screenshot capture scripts).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `contract.json`/`config.toml` are now the single source of truth for all 17 render targets; plans 06-03 through 06-09 can consume the rendered state-dir files (`hyprlock.conf`, `swayosd.css`, `zen-userchrome.css`, `satty.toml`) without touching either hub file again
- 06-04 (hyprlock redesign) still needs to resolve the `$image` background-path wiring for hyprlock's new dedicated color source — explicitly left out of this plan's scope
- 06-05 (satty/screenshot suite) should verify the `[general]` key names against the actually-installed `satty --help` output once the package lands in `install.sh`, as a fast sanity check (not expected to differ from the live upstream source used here, but cheap to confirm)

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-12*

## Self-Check: PASSED

All created files verified present on disk; all task commits (`5b3086a`, `50e6045`) and this SUMMARY's commit (`0cf9efd`) verified present in git log.
