---
phase: 06-themed-surfaces-utility-suite
plan: 07
subsystem: theming
tags: [bash, fzf, gsettings, papirus-folders, gtk, matugen, icon-theme]

# Dependency graph
requires:
  - phase: 06-01
    provides: contract.json / theme-engine lib scaffolding this plan edits
provides:
  - Theme-orthogonal icon-theme state axis (~/.local/state/theme/icon-theme), read by generate.sh, excluded from commit.sh's rsync --delete
  - theme_engine_apply_icon_theme in gtk.sh (papirus-folders folder-accent for Papirus, nearest-fixed-variant gsettings swap for Tela/Colloid)
  - hypr/.config/hypr/scripts/icon-theme-picker.sh — fzf-in-kitty picker with a montage icon-grid preview
affects: [theme-engine, gtk, icon-theme-picker, font-switcher (UTIL-05, shares the same D-19/D-20 pattern)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Theme-orthogonal state axis: independent state file read inside the SAME render function that already owns the settings key, excluded from commit.sh's rsync --delete (D-19, first established for last-wallpaper/, now reused for icon-theme)"
    - "fzf-in-floating-kitty picker with montage-built icon-grid preview + kitten icat/chafa two-tier fallback (D-20, wallpaper-picker.sh pattern)"
    - "Hue-bucket hex-to-fixed-enum dispatch (theme_engine_gtk4_accent's shape) reused for papirus-folders' 23-name enum and for Tela/Colloid nearest-installed-variant lookup"

key-files:
  created:
    - hypr/.config/hypr/scripts/icon-theme-picker.sh
  modified:
    - theme-engine/.config/theme-engine/lib/generate.sh
    - theme-engine/.config/theme-engine/lib/commit.sh
    - theme-engine/.config/theme-engine/lib/gtk.sh

key-decisions:
  - "Icon-theme picker enumerates real installed themes via an index.theme/Directories= directory scan (not a hardcoded Papirus/Tela/Colloid allowlist) — a Breeze/Breeze-Dark KDE dependency already installed on this dev machine legitimately surfaces in the picker too, which is correct real-enumeration behavior, not scope creep"
  - "theme_engine_nearest_icon_variant enumerates actual '<base>-*' installed directories at runtime rather than a hardcoded Tela/Colloid variant name list, per RESEARCH.md Open Question 1 — Tela/Colloid/papirus-folders remain uninstalled on this dev machine (deferred install, matching the precedent already set for satty in 06-02), so every new gtk.sh code path was validated for graceful best-effort no-op behavior via command -v guards, not a live papirus-folders/gsettings run"
  - "Preview grid uses a curated list of near-universal freedesktop icon names (folder/user-home/apps/mimetypes/etc.) validated as real existing files before use, falling back to a sorted apps/ glob if fewer than 4 are found — gives a more recognizable grid than blind alphabetical ordering while staying Security-Domain-V5 compliant (every montage input is a real, existing file)"

patterns-established: []

requirements-completed: [UTIL-04]

coverage:
  - id: D1
    description: "generate.sh renders gtk-icon-theme-name from the icon-theme state file (default Adwaita) into both gtk-3.0 and gtk-4.0 settings.ini, replacing the hardcoded Adwaita literal that caused Pitfall 6"
    requirement: "UTIL-04"
    verification:
      - kind: integration
        ref: "manual: sourced lib/generate.sh with a fake HOME + icon-theme=Tela-blue, called theme_engine_render_gtk_settings directly, confirmed both settings.ini files render gtk-icon-theme-name=Tela-blue"
        status: pass
    human_judgment: false
  - id: D2
    description: "commit.sh excludes icon-theme from its rsync --delete so the axis survives every theme switch"
    requirement: "UTIL-04"
    verification:
      - kind: integration
        ref: "manual: simulated commit.sh's exact rsync invocation against a populated fake STATE_DIR with icon-theme/current-theme/logs/last-wallpaper present and a rendered_dir lacking icon-theme; confirmed icon-theme (and the other three excluded paths) survive the sync"
        status: pass
    human_judgment: false
  - id: D3
    description: "gtk.sh dispatches papirus-folders (hue-bucket named color) for Papirus/-Dark/-Light and a nearest-installed-variant gsettings icon-theme swap for Tela/Colloid, both best-effort and never blocking gtk_reload"
    requirement: "UTIL-04"
    verification:
      - kind: unit
        ref: "manual: sourced lib/gtk.sh, called theme_engine_nearest_papirus_color against sample hex values (verified degree-bucket assignment against python colorsys); called theme_engine_apply_icon_theme with icon-theme=Papirus-Dark in a fake HOME with no papirus-folders/gsettings installed — confirmed clean no-op exit 0 (best-effort discipline)"
        status: pass
    human_judgment: true
    rationale: "papirus-folders and Tela/Colloid are not installed on this dev machine (deferred install per RESEARCH.md package-legitimacy precedent) — the actual live folder-recolor / gsettings-variant-swap behavior against a real installed Papirus/Tela/Colloid can only be confirmed by a human on a machine with those AUR packages installed and a graphical session running"
  - id: D4
    description: "icon-theme-picker.sh: fzf-in-kitty picker (not walker dmenu) enumerates real installed icon themes, shows a montage icon-grid preview, validates the selection against the enumerated set, persists via the state file, and re-runs theme-apply — never a bare gsettings set"
    requirement: "UTIL-04"
    verification:
      - kind: e2e
        ref: "manual: ran the real script end-to-end against a fake HOME with stubbed fzf/notify-send/theme-apply — confirmed (1) cancel path makes zero state mutations, (2) an unenumerated fzf return is rejected with exit 1 (defense-in-depth validation), (3) a valid Papirus-Dark selection writes the state file atomically and invokes theme-apply with the active preset"
        status: pass
    human_judgment: true
    rationale: "The live fzf UI (kitty-graphics montage preview rendering, keyboard interaction, floating-kitty launch) can only be confirmed visually by a human in a real graphical session — this plan's automated verification covers the script's logic paths (enumeration, validation, persistence, re-apply) but not the rendered UI itself"

# Metrics
duration: 12min
completed: 2026-07-12
status: complete
---

# Phase 06 Plan 07: Icon-Theme Axis Summary

**Theme-orthogonal icon-theme state axis (UTIL-04) closing Pitfall 6: an fzf-in-kitty picker persists icon-theme picks through a state file generate.sh reads and commit.sh's rsync excludes, with gtk.sh tracking folder-accent colors for Papirus (papirus-folders) and nearest-baked-variant swaps for Tela/Colloid.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-12T17:23:07Z
- **Completed:** 2026-07-12T17:35:04Z
- **Tasks:** 3
- **Files modified:** 4 (3 modified, 1 created)

## Accomplishments
- `generate.sh`'s `theme_engine_render_gtk_settings` now reads `~/.local/state/theme/icon-theme` (default Adwaita) and interpolates it into both `gtk-3.0-settings.ini` and `gtk-4.0-settings.ini`, permanently closing Pitfall 6 (the previously hardcoded `gtk-icon-theme-name=Adwaita` literal that silently reverted any pick on the next theme switch)
- `commit.sh`'s rsync gained `--exclude=icon-theme`, so the picker's persisted state file survives every theme-apply's `--delete` step (verified: simulated the exact rsync invocation against a populated fake state dir)
- `gtk.sh` gained `theme_engine_apply_icon_theme` (called from `theme_engine_gtk_reload`), which: writes the base `gsettings icon-theme` value for live GTK4 apply; for Papirus/-Dark/-Light, maps the palette's primary hex to the nearest of papirus-folders' 23 named colors via a hue-bucket dispatch adapted from the existing `theme_engine_gtk4_accent` shape and runs `papirus-folders -C <color> -t <variant>`; for Tela/Colloid, enumerates the ACTUAL installed `<base>-*` icon-theme directories (never a hardcoded variant list) and swaps `gsettings icon-theme` to the nearest-hue installed variant — a full theme-name swap since these ship N separately baked themes with no folder-recolor tool (Pitfall 3)
- `hypr/.config/hypr/scripts/icon-theme-picker.sh` created following the exact `wallpaper-picker.sh` fzf-in-floating-kitty structure (D-20): real-enumeration via an `index.theme`/`Directories=` directory scan (Security Domain V5), a montage-built icon-grid preview with the same `kitten icat`/`chafa` two-tier fallback, empty-state copy when only Adwaita is installed, defense-in-depth re-validation of the fzf return before any use, atomic state-file persistence, and a `theme-apply` re-run (never a bare `gsettings set`)

## Task Commits

Each task was committed atomically:

1. **Task 1: State-driven icon-theme-name in generate.sh + commit.sh exclude** - `4c98f8b` (feat)
2. **Task 2: gtk.sh folder-accent + variant-swap function** - `92c3a8e` (feat)
3. **Task 3: icon-theme-picker.sh fzf-in-kitty picker** - `1715852` (feat)

**Plan metadata:** _pending_ (docs: complete plan, this commit)

## Files Created/Modified
- `theme-engine/.config/theme-engine/lib/generate.sh` - `theme_engine_render_gtk_settings` reads the icon-theme state file and renders it into both settings.ini targets
- `theme-engine/.config/theme-engine/lib/commit.sh` - rsync gained `--exclude=icon-theme` alongside the existing engine-owned-file excludes
- `theme-engine/.config/theme-engine/lib/gtk.sh` - new `theme_engine_apply_icon_theme`, `theme_engine_nearest_papirus_color`, `theme_engine_nearest_icon_variant` functions; call wired into `theme_engine_gtk_reload`
- `hypr/.config/hypr/scripts/icon-theme-picker.sh` - new fzf-in-kitty icon-theme picker script

## Decisions Made
- Icon-theme picker enumerates real installed themes via a directory scan, not a hardcoded Papirus/Tela/Colloid allowlist — a pre-existing Breeze/Breeze-Dark KDE dependency legitimately surfaces in the picker on this dev machine, which is correct behavior for a real-enumeration picker (Security Domain V5), not scope creep.
- `theme_engine_nearest_icon_variant` enumerates actual `<base>-*` installed directories at runtime rather than a hardcoded variant-name list (RESEARCH.md Open Question 1) — since papirus-folders/tela-icon-theme/colloid-icon-theme-git remain uninstalled on this dev machine (deferred-install precedent already established for satty in 06-02), every gtk.sh code path was validated for graceful best-effort no-op behavior rather than a live run.
- Preview grid uses a curated list of near-universal freedesktop icon names (folder, user-home, applications-system, etc.), each individually validated as a real existing file before use, with a sorted-glob fallback if fewer than 4 are found — gives a more recognizable preview than blind alphabetical-first icon selection while staying Security-Domain-V5 compliant.

## Deviations from Plan

None — plan executed exactly as written. All three tasks' `<acceptance_criteria>` were met and independently verified beyond the plan's automated `bash -n`/`grep` checks (see Coverage above for the additional end-to-end and regression tests run).

## Issues Encountered

None. The only notable environment fact (not a blocker): `papirus-folders`, `tela-icon-theme`, and `colloid-icon-theme-git` are declared in `install.sh`'s `AUR_PKGS` (added in an earlier 06-plan) but not yet installed on this dev machine — consistent with the project's established pattern of deferring AUR package installs to a later human-gated step (same precedent as satty in 06-02). Every new code path in `gtk.sh` was written with `command -v` guards so it degrades cleanly to a no-op in their absence, and this was verified directly rather than assumed.

## User Setup Required

None required for this plan's own deliverables. Carried forward from earlier phase-06 plans: `papirus-folders`, `tela-icon-theme`, and `colloid-icon-theme-git` still need their AUR package-legitimacy human-verify checkpoint and `install.sh` run before the folder-accent-tracking and Tela/Colloid variant-swap code paths in `gtk.sh` produce live, visible effects (they currently no-op cleanly).

## Next Phase Readiness

UTIL-04 (icon theme picker) is functionally complete and independently verified end-to-end at the script-logic level. Live-UI and live-papirus-folders/Tela/Colloid-variant-swap behavior need a human pass in a graphical session with the AUR packages installed — flagged in `coverage` above as `human_judgment: true` items for the phase's UAT pass, not blockers to proceeding.

## Self-Check: PASSED

All created/modified files and all four task/summary commit hashes verified present on disk and in git log:
- `hypr/.config/hypr/scripts/icon-theme-picker.sh`, `theme-engine/.config/theme-engine/lib/{generate,commit,gtk}.sh`, `.planning/phases/06-themed-surfaces-utility-suite/06-07-SUMMARY.md` — all FOUND
- `4c98f8b`, `92c3a8e`, `1715852`, `6b4823d` — all FOUND
