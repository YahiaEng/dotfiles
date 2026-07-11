---
phase: 05-light-mode-pipeline-theme-presets
plan: 03
subsystem: theming
tags: [bash, stow, matugen, theme-engine, wallpaper]

# Dependency graph
requires:
  - phase: 05-01
    provides: mode.sh, materialyou-light as a valid theme-apply argument, mode-aware GTK propagation, settings.ini rendered contract
  - phase: 05-02
    provides: 20 palette JSONs in theme-engine/.config/theme-engine/palettes/ (incl. 5 light presets), dynamic palette enumeration in theme-parity/theme-stress-test/theme-switch.sh
provides:
  - Strict 1:1 wallpaper-folder-name <-> palette-name convention (rose-pine -> rosepine, tokyo-night -> tokyonight rename)
  - Complete wallpaper folder set: dracula/ (empty) + 5 light-variant folders (catppuccin-latte, rosepine-dawn, gruvbox-light, tokyonight-day, kanagawa-lotus), each seeded with .gitkeep
  - theme_engine_wallpaper_autoset() in lib/wallpaper.sh — static-preset wallpaper auto-set wired into theme-apply
  - Per-theme last-used wallpaper state convention at ~/.local/state/theme/last-wallpaper/<preset>
affects: [05-04 (wallpaper picker redesign builds directly on this folder convention and last-used state)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Static-preset wallpaper auto-set: resolve Pictures/Wallpapers/<name>, prefer validated last-used bare filename, fall back to first-in-folder, keep-current when empty/missing (D-11/D-12)"
    - "Atomic temp-file+mv write-back for per-theme last-used state files (commit.sh idiom reused)"
    - "Bare-filename validation before path join (no slash, must exist in theme dir) — mitigates untrusted state-file content"

key-files:
  created:
    - theme-engine/.config/theme-engine/lib/wallpaper.sh
  modified:
    - theme-engine/.config/theme-engine/theme-apply
    - wallpapers/Pictures/Wallpapers/ (renamed rose-pine->rosepine, tokyo-night->tokyonight; added dracula/, catppuccin-latte/, rosepine-dawn/, gruvbox-light/, tokyonight-day/, kanagawa-lotus/)

key-decisions:
  - "Wallpaper folder names are locked 1:1 to palette JSON basenames with no mapping/manifest file (D-09)"
  - "Empty wallpaper folders (dracula, all 5 light variants) fall open to keep-current rather than erroring (D-12)"
  - "Per-theme last-used wallpaper state is one flat file per theme under ~/.local/state/theme/last-wallpaper/, mirroring the existing current-theme convention"

patterns-established:
  - "Wallpaper auto-set is a no-op for both materialyou and materialyou-light — dynamic mode keeps wallpaper-drives-palette direction; static presets get the new auto-set"

requirements-completed: [THM-03]

coverage:
  - id: D1
    description: "Wallpaper folders renamed to strict 1:1 correspondence with palette names (rosepine, tokyonight) plus dracula/ and 5 light-variant folders created with .gitkeep"
    requirement: "THM-03"
    verification:
      - kind: other
        ref: "manual test -d/-e checks on repo tree and ~/Pictures/Wallpapers live tree, all passed"
        status: pass
    human_judgment: false
  - id: D2
    description: "theme_engine_wallpaper_autoset() auto-sets wallpaper on static theme-apply with last-used-first, first-in-folder fallback, keep-current on empty folder, and no-op for materialyou/materialyou-light"
    requirement: "THM-03"
    verification:
      - kind: other
        ref: "live run: theme-apply catppuccin (repoints + records last-used), repeat run (stable), theme-apply dracula (empty folder, keep-current, exit 0) — all observed directly on the live desktop session"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-11
status: complete
---

# Phase 5 Plan 3: Wallpaper Sets & Auto-Set Summary

**Renamed wallpaper folders to strict 1:1 correspondence with palette names, completed the folder set for all 20 presets, and added `theme_engine_wallpaper_autoset()` so `theme-apply <static-preset>` lands a matching wallpaper alongside the color switch.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-11T22:54:00Z
- **Completed:** 2026-07-11T22:58:35Z
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments
- `rose-pine/` -> `rosepine/`, `tokyo-night/` -> `tokyonight/` renamed via `git mv` (git history preserved as renames, not delete+add)
- Six new wallpaper folders created, each seeded with `.gitkeep`: `dracula/`, `catppuccin-latte/`, `rosepine-dawn/`, `gruvbox-light/`, `tokyonight-day/`, `kanagawa-lotus/`
- Repo restowed so `~/Pictures/Wallpapers/` reflects the renames live; `current.jpg` confirmed still resolving
- New `lib/wallpaper.sh` with `theme_engine_wallpaper_autoset()` wired into `theme-apply` between commit and reload
- Live-verified on the actual desktop session: `theme-apply catppuccin` repoints `current.jpg` into `catppuccin/` and records the chosen filename; a second run is stable (same file chosen); `theme-apply dracula` (empty folder) leaves `current.jpg` untouched and exits 0

## Task Commits

Each task was committed atomically:

1. **Task 1: Rename drifting wallpaper folders and complete the 1:1 folder set (D-09/D-10)** - `9916ca5` (feat)
2. **Task 2: Wallpaper auto-set on static theme-apply with per-theme last-used state (D-11/D-12)** - `1dc0fd6` (feat)

**Plan metadata:** commit pending (docs: complete plan)

## Files Created/Modified
- `theme-engine/.config/theme-engine/lib/wallpaper.sh` - new lib: `theme_engine_wallpaper_autoset(name)` — static-only wallpaper auto-set with validated last-used state and keep-current fallback
- `theme-engine/.config/theme-engine/theme-apply` - sources `lib/wallpaper.sh`; calls the autoset after commit succeeds, before reload
- `wallpapers/Pictures/Wallpapers/rosepine/` - renamed from `rose-pine/` (git rename, 3 files)
- `wallpapers/Pictures/Wallpapers/tokyonight/` - renamed from `tokyo-night/` (git rename, 4 files)
- `wallpapers/Pictures/Wallpapers/dracula/.gitkeep` - new empty folder (falls open per D-12)
- `wallpapers/Pictures/Wallpapers/catppuccin-latte/.gitkeep`, `rosepine-dawn/.gitkeep`, `gruvbox-light/.gitkeep`, `tokyonight-day/.gitkeep`, `kanagawa-lotus/.gitkeep` - new light-variant folders (D-10), empty until user populates

## Decisions Made
- Strict 1:1 folder-name-equals-palette-name convention with no mapping file (D-09) — matches the plan exactly, no deviation
- Per-theme last-used state as one flat file per theme under `~/.local/state/theme/last-wallpaper/<preset>`, mirroring the existing `current-theme` file convention (RESEARCH Open Question 4 resolution, already decided in the plan)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The live verification commands in the plan's `<verify>` block were run directly against the real desktop session (WAYLAND_DISPLAY/DBUS present) rather than simulated, since this environment has a live graphical session. The pre-existing active theme (`dracula`, wallpaper `shaded-landscape.jpg`) was restored after verification: `current-theme` file already read back `dracula` after the final `theme-apply dracula` verification call, and `current.jpg` was explicitly re-linked back to `shaded-landscape.jpg` (dracula's folder is intentionally empty, so auto-set correctly left it untouched at whatever it last pointed to — restoring the original wallpaper required one explicit `ln -sfr` after verification, which is not part of the shipped feature, just test cleanup).

## User Setup Required

None - no external service configuration required. Note: the 6 new/renamed wallpaper folders (`dracula/`, `catppuccin-latte/`, `rosepine-dawn/`, `gruvbox-light/`, `tokyonight-day/`, `kanagawa-lotus/`) are currently empty (`.gitkeep` only) — the user should add wallpaper images to populate them; until then, `theme-apply` for those presets falls open to keep-current (D-12), which is expected behavior, not a defect.

## Next Phase Readiness
Plan 05-04 (wallpaper picker redesign) can build directly on this folder convention: per-theme subfolder scanning and the `last-wallpaper` state file are both established here and ready to be surfaced in the picker UI.

---
*Phase: 05-light-mode-pipeline-theme-presets*
*Completed: 2026-07-11*

## Self-Check: PASSED
