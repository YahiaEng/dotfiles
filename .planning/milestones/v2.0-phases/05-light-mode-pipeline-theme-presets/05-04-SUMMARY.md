---
phase: 05-light-mode-pipeline-theme-presets
plan: 04
subsystem: theming
tags: [bash, fzf, kitty-graphics, matugen, theme-engine, wallpaper-picker]

# Dependency graph
requires:
  - phase: 05-01
    provides: mode.sh, materialyou-light as a valid theme-apply argument, contract.sh format-extractor pattern (env-kv sibling of ini-kv), theme-parity Layer 3 enforce_emptiness format list
  - phase: 05-03
    provides: 1:1 wallpaper-folder-name <-> palette-name convention, per-theme last-used wallpaper state file convention, theme_engine_wallpaper_autoset() precedent for atomic writes
provides:
  - fzf-colors.conf matugen render target (13 FZF_COLOR_* shell-sourceable vars) as the 13th contract file, env-kv format wired through contract.sh/contract.json/theme-parity
  - Redesigned wallpaper-picker.sh — kitty-graphics (kitten icat) pixel-perfect preview pane with chafa/block-art fallback chain, pipeline-sourced fzf theming (fallback-safe for fresh installs), per-theme restriction with Ctrl-A browse-all, visible fall-open for empty folders, active-wallpaper marker, materialyou/materialyou-light-aware re-apply on selection, per-theme last-used recording
affects: [Phase 6+ (any future picker/theming work builds on the 13-file contract and the WALLPAPER_DIR_REAL resolved-symlink pattern)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "env-kv contract format: NAME=\"VALUE\" shell-sourceable assignment lines, quoted values, blank/comment-skipping extractor — sibling to the ini-kv format from Phase 5 Plan 1"
    - "fzf theming via sourced state-dir fragment with ${VAR:-fallback} inline defaults — literals survive only as fresh-install fallbacks, never as the primary source"
    - "kitty-graphics preview chain: kitten icat (primary) -> chafa -f kitty (fallback, same protocol) -> chafa block-art (last resort), verbatim fzf upstream fzf-preview.sh --clear + sed tail-fix technique to prevent stale-image scroll artifacts"
    - "Resolved-symlink base for path comparisons: when a tracked directory (~/Pictures) is itself a stow symlink into the repo, compare against a fully-resolved WALLPAPER_DIR_REAL base, not the literal configured path, or marker/active-file matching silently fails"

key-files:
  created:
    - matugen/.config/matugen/templates/fzf-colors.conf
  modified:
    - matugen/.config/matugen/config.toml
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/lib/contract.sh
    - theme-engine/.config/theme-engine/theme-parity
    - hypr/.config/hypr/scripts/wallpaper-picker.sh

key-decisions:
  - "fzf color slots locked per UI-SPEC Color section 3: FG<-on_background, BG<-literal -1 (terminal transparency kept), BG_PLUS<-surface_variant, HEADER<-on_surface_variant, HL/HL_PLUS/POINTER/MARKER/SPINNER<-tertiary (10% accent group), PROMPT<-primary, INFO<-secondary, BORDER<-outline, FG_PLUS<-on_primary_container"
  - "BG slot's -1 literal is intentionally the only non-color-regex value in the fragment and is explicitly exempted in the theme-parity value check, not a parity gap"
  - "Picker enumeration is exclusively find-output-driven (never free text) both in restricted and full-browse modes, preserving the existing Security Domain V5 discipline"
  - "Post-selection re-apply always passes the exact active dynamic variant name (materialyou or materialyou-light) rather than hardcoding the dark variant (D-05)"
  - "Last-used wallpaper recording on picker selection only fires for in-folder (non-Ctrl-A) picks, keeping the picker as a second writer of the same atomic temp+mv state convention established in 05-03's lib/wallpaper.sh"

patterns-established:
  - "Any future contract-format addition follows the env-kv precedent: extractor branch in contract.sh, entry in contract.json, addition to theme-parity's enforce_emptiness format list, and an explicit exemption note for any structurally-non-color literal in the fragment"
  - "Any script that compares paths against a directory that might itself be a stow symlink must resolve that directory once at startup (WALLPAPER_DIR_REAL-style) and compare against the resolved form everywhere, not the configured path string"

requirements-completed: [THM-04]

coverage:
  - id: D1
    description: "fzf-colors.conf renders as a first-class 13th pipeline contract file (env-kv format) with 12 hex color slots + one -1 literal, validated by theme-parity across every theme including light presets"
    requirement: "THM-04"
    verification:
      - kind: other
        ref: "theme-engine/.config/theme-engine/theme-parity full run: 1190 passed, 0 failed, across the 13-file contract for all palettes (dark + light)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Preview pane renders pixel-perfect via kitty graphics protocol (kitten icat, --clear + sed tail-fix), with chafa-kitty and block-art fallbacks, metadata line (filename/resolution/size), and an active-wallpaper indicator"
    requirement: "THM-04"
    verification:
      - kind: manual_procedural
        ref: "User-run 8-step visual walkthrough on the live Hyprland session (checkpoint Task 4), approved"
        status: pass
    human_judgment: true
    rationale: "Pixel rendering quality, layout aesthetics, and live-preview responsiveness can only be judged by a human looking at the actual compositor output; no automated check can validate kitty-graphics visual correctness."
  - id: D3
    description: "Per-theme restriction with Ctrl-A browse-all escape, visible fall-open header for empty static-theme folders, and unrestricted browsing for both materialyou variants"
    requirement: "THM-04"
    verification:
      - kind: manual_procedural
        ref: "User-run visual walkthrough steps 2, 4, 6, 7 (checkpoint Task 4), approved — catppuccin restricted list, Ctrl-A expansion, catppuccin-latte fall-open header, materialyou full browse"
        status: pass
    human_judgment: true
    rationale: "Confirming the correct header text, folder restriction, and fall-open behavior render correctly in the live floating-kitty picker requires human visual confirmation of the actual UI, not just grep-based structural checks (already covered separately by Tasks 1-3 automated gates)."

duration: 10min (Tasks 1-3 automated) + human checkpoint wait
completed: 2026-07-12
status: complete
---

# Phase 5 Plan 4: Wallpaper Picker Redesign Summary

**Redesigned the wallpaper picker to Omarchy-level polish: pixel-perfect kitty-graphics previews, a new fzf-colors.conf pipeline render target (13th contract file) replacing hardcoded catppuccin fzf theming, per-theme restriction with Ctrl-A browse-all and visible fall-open, an active-wallpaper marker, and materialyou/materialyou-light-aware selection re-apply — all human-verified live on the desktop.**

## Performance

- **Duration:** ~10 min automated (Tasks 1-3, commits 02:03-02:10) + human checkpoint verification wait
- **Started:** 2026-07-12T02:00:00Z (approx, first Task 1 edits)
- **Completed:** 2026-07-12 (checkpoint approved)
- **Tasks:** 4 (3 automated + 1 human-verify checkpoint)
- **Files modified:** 6

## Accomplishments
- New `fzf-colors.conf` matugen template rendering 13 `FZF_COLOR_*` shell-sourceable assignments per the UI-SPEC locked slot mapping; wired into `config.toml`, `contract.sh` (new `env-kv` extractor format), `contract.json` (13th contract file), and `theme-parity` (env-kv added to the Layer 3 enforce list) — full parity run: 1190 passed, 0 failed
- `wallpaper-picker.sh` preview pane replaced with the verbatim fzf-upstream kitty-graphics technique: `kitten icat --clear --transfer-mode=memory --unicode-placeholder` primary, `chafa -f kitty` fallback, block-art chafa last resort, plus the two-sed tail-fix that prevents stale-image scroll artifacts
- All hardcoded `--color` fzf arguments replaced with `FZF_COLOR_*` variables sourced best-effort from the pipeline fragment, catppuccin hexes surviving only as `${VAR:-fallback}` defaults for fresh installs
- Relpath-based enumeration: restricted mode scans only the active static theme's folder (maxdepth 1); full mode scans the Wallpapers root (maxdepth 2, includes the shared/non-preset pool) — both exclusively `find`-driven, no free text
- Mode selection at startup implements all three UI-SPEC header variants: standard, restricted (with Ctrl-A browse-all binding via fzf reload + change-header), and visible fall-open for empty/missing static-theme folders
- Active-wallpaper marker appended to the matching enumeration entry, stripped before any path use in preview/live-preview/selection; preview metadata line shows an active indicator
- Selection flow validates the joined relpath resolves to an existing regular file before `ln -sfr`; post-selection re-apply passes the exact active dynamic variant (`materialyou` or `materialyou-light`, never hardcoded); last-used wallpaper recorded atomically for in-folder (non-Ctrl-A) selections only
- Found and fixed a real cross-symlink bug during Task 3 smoke-testing: `~/Pictures` is itself a stow symlink into the repo, so `readlink -f` on `current.jpg` resolves through the repo path, not the literal `~/Pictures/...` string — marker/active comparisons now resolve a `WALLPAPER_DIR_REAL` base once and compare against that everywhere
- Human checkpoint (Task 4): user ran the full 8-step visual walkthrough on the live Hyprland session and approved — restriction, Ctrl-A browse-all, Esc-restore, light-mode (catppuccin-latte) fall-open header and matching picker chrome colors, materialyou full browse with select-triggers-palette-regeneration, all confirmed working

## Task Commits

Each task was committed atomically:

1. **Task 1: fzf color fragment render target (D-15)** - `e23254e` (feat)
2. **Task 2: Pixel-perfect preview pane + pipeline-sourced fzf theming (D-13/D-14/D-15)** - `1e6b57d` (feat)
3. **Task 3: Theme restriction, fall-open, Ctrl-A, active marker, selection flow (D-16/D-12/D-14/D-11/D-05)** - `4fb7afe` (feat)
4. **Task 4: Checkpoint — visual verification** - approved by user (no code commit; verification-only)

**Plan metadata:** commit pending (docs: complete plan)

## Files Created/Modified
- `matugen/.config/matugen/templates/fzf-colors.conf` - new matugen template, 13 `FZF_COLOR_*` assignments, zero literal hex values (BG's `-1` is the sole literal)
- `matugen/.config/matugen/config.toml` - new `[templates.fzf]` entry, no post_hook (reload.sh retains fan-out ownership)
- `theme-engine/.config/theme-engine/contract.json` - `fzf-colors.conf` entry added, format `env-kv` (13-file contract)
- `theme-engine/.config/theme-engine/lib/contract.sh` - `env-kv` extractor branch in `contract_extract_names`/`contract_extract_values`
- `theme-engine/.config/theme-engine/theme-parity` - `env-kv` added to Layer 3 `enforce_emptiness=1` format list
- `hypr/.config/hypr/scripts/wallpaper-picker.sh` - full redesign: kitty-graphics preview chain, pipeline-sourced theming, relpath enumeration, restriction/fall-open/Ctrl-A, active marker, `WALLPAPER_DIR_REAL`-resolved comparisons, materialyou/materialyou-light-aware selection flow, per-theme last-used recording

## Decisions Made
- fzf color slot mapping followed the UI-SPEC's locked 60/30/10 assignment exactly (see key-decisions in frontmatter) — no deviation from plan
- The BG slot's `-1` literal is an intentional, documented exemption from the "zero literal hex" rule (terminal transparency), not a parity gap
- Cross-symlink resolution fix (`WALLPAPER_DIR_REAL`) was a Rule 1 auto-fix discovered during Task 3 smoke-testing, not called out in the original plan — see Deviations below

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed active-wallpaper marker / path comparisons failing across the `~/Pictures` stow symlink**
- **Found during:** Task 3 (active marker + selection flow implementation)
- **Issue:** `~/Pictures` is itself a stow-managed symlink into this repo's `wallpapers/` package. Resolving `current.jpg`'s target with `readlink -f` follows that symlink through to the repo path, so comparing against the literal configured `~/Pictures/Wallpapers` string never matched — the active-wallpaper marker silently never appeared, and active-indicator detection in the preview metadata line was always false.
- **Fix:** Resolve the Wallpapers directory once at script startup into a `WALLPAPER_DIR_REAL` variable (fully dereferenced) and use that as the comparison base everywhere marker/active logic touches a path, instead of the literal configured directory string.
- **Files modified:** hypr/.config/hypr/scripts/wallpaper-picker.sh
- **Verification:** Live smoke-test on the desktop session confirmed the marker now appears correctly on the active wallpaper's list entry and the preview metadata line shows the active indicator when previewing it.
- **Committed in:** 4fb7afe (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary correctness fix for D-14 (active marker); no scope creep — same task's stated goal, just a real environment condition (stow symlink) the original plan text didn't anticipate.

## Issues Encountered

- During the human checkpoint's live 8-step walkthrough, the desktop's active theme ended the session on `catppuccin` (not `dracula`, which the walkthrough's step 8 offered only as an example restore target). `wallpapers/Pictures/Wallpapers/current.jpg` (a git-tracked relative symlink used for fresh-install reproducibility) now points to `catppuccin/4-firewatch.jpg` as a direct, legitimate result of the user exercising the redesigned picker and `theme-apply` during verification. This is real, intentional use of the shipped feature — not reverted, since the live desktop state is the user's to leave wherever they choose after approving the checkpoint. The symlink change is committed alongside this plan's metadata commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The 13-file pipeline contract (dark + light, fzf included) is fully parity-gated; no further picker work is planned this milestone.
- `WALLPAPER_DIR_REAL`-resolved comparison is now the established pattern for any future script that needs to compare paths against `~/Pictures` or similar stow-managed directories.
- Phase 5 (light-mode-pipeline-theme-presets) is now fully executed across all 4 plans; ready for phase-level review/close-out.

---
*Phase: 05-light-mode-pipeline-theme-presets*
*Completed: 2026-07-12*

## Self-Check: PASSED
