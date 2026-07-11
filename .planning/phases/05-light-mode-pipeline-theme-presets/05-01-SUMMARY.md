---
phase: 05-light-mode-pipeline-theme-presets
plan: 01
subsystem: theming
tags: [bash, matugen, gsettings, gtk, stow]

# Dependency graph
requires:
  - phase: 01-theme-pipeline-repair
    provides: consolidated theme-engine with contract.json/theme-parity output-contract gating
provides:
  - "theme_engine_detect_mode — single source of truth for light/dark classification"
  - "materialyou-light as a first-class theme-apply entry (matugen -m light)"
  - "mode marker (~/.local/state/theme/mode) written atomically during render, before commit"
  - "mode-aware gtk.sh: color-scheme, GTK3 theme name, and GTK_THEME all flip with mode"
  - "gtk-3.0/4.0 settings.ini as rendered contract targets (ini-kv format), symlinked by commit.sh"
affects: [05-02-static-presets, 05-03-wallpaper-sets, 05-04-wallpaper-picker]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Mode is computed once (mode.sh), never inherited from matugen — static presets get mode via palette lightness/override, materialyou/-light get it via explicit -m flag"
    - "gtk.sh is the single mode-aware owner of GTK_THEME propagation (uwsm/env no longer exports a static value)"
    - "settings.ini follows the walker/yazi rendered-target + seeded-symlink idiom, extended to a new ini-kv contract format"

key-files:
  created:
    - theme-engine/.config/theme-engine/lib/mode.sh
  modified:
    - theme-engine/.config/theme-engine/lib/generate.sh
    - theme-engine/.config/theme-engine/lib/gtk.sh
    - theme-engine/.config/theme-engine/lib/commit.sh
    - theme-engine/.config/theme-engine/lib/contract.sh
    - theme-engine/.config/theme-engine/theme-apply
    - theme-engine/.config/theme-engine/contract.json
    - uwsm/.config/uwsm/env
    - stow.sh
    - gtk/.config/gtk-3.0/settings.ini (deleted, migrated to rendered target)
    - gtk/.config/gtk-4.0/settings.ini (deleted, migrated to rendered target)

key-decisions:
  - "gtk.sh reads the committed mode marker and owns GTK_THEME propagation directly (systemctl --user set-environment); the uwsm/env static export was removed to eliminate the second hardcode site"
  - "settings.ini rendering is shell-side printf in generate.sh, not a matugen template — keeps the mode-conditional decision in engine bash code alongside every other GTK-signal write, since matugen has no mode-conditional templating"
  - "ini-kv contract format skips [section] headers via a leading-character grep class, mirroring the existing kitty-kv extractor's structure"

patterns-established:
  - "theme_engine_detect_mode(name): materialyou literals -> fixed; static preset -> palette 'mode' override then colorsys lightness of background hex; always best-effort (echoes dark on any missing tool/file)"

requirements-completed: [THM-01]

coverage:
  - id: D1
    description: "materialyou-light is a valid theme-apply argument and renders genuinely different output (verified 20+ line kitty.conf diff against materialyou) than the existing materialyou entry"
    requirement: THM-01
    verification:
      - kind: manual_procedural
        ref: "theme_engine_generate materialyou vs materialyou-light in a temp dir; diff kitty.conf — differed; mode marker read 'dark'/'light' respectively"
        status: pass
    human_judgment: false
  - id: D2
    description: "Static-preset render branch never passes a mode flag to matugen json (Pitfall 1 regression guard); mode is computed separately via mode.sh"
    requirement: THM-01
    verification:
      - kind: manual_procedural
        ref: "grep -E '^\\s*if ! matugen json' lib/generate.sh — no -m flag present on that line"
        status: pass
    human_judgment: false
  - id: D3
    description: "gtk.sh flips color-scheme/gtk-theme/GTK_THEME based on the committed mode marker; settings.ini symlinks resolve into the state dir; git status stays clean after a theme-apply"
    requirement: THM-01
    verification:
      - kind: manual_procedural
        ref: "theme-apply dracula (live) -> gsettings color-scheme=prefer-dark, gtk-theme=adw-gtk3-dark, mode=dark; readlink -f on both settings.ini paths resolves into ~/.local/state/theme/; git status --porcelain clean"
        status: pass
    human_judgment: false
  - id: D4
    description: "contract.json/theme-parity extended with both settings.ini targets (ini-kv format) and mode state metadata; single-target parity run for catppuccin exits 0"
    requirement: THM-01
    verification:
      - kind: integration
        ref: "theme-parity catppuccin — 49 passed, 0 failed, 12/12 contract files present including gtk-3.0-settings.ini and gtk-4.0-settings.ini"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-07-12
status: complete
---

# Phase 5 Plan 1: Light Mode Pipeline Core Summary

**Threaded a mode (light/dark) concept through the theme-engine pipeline: `materialyou-light` entry, `mode.sh` lightness/override detection, mode-aware `gtk.sh` gsettings + GTK_THEME propagation, and `settings.ini` migrated to a rendered contract target — closing all three dark-hardcoded chokepoints named in the phase objective.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-07-12T01:34:35+03:00
- **Tasks:** 3
- **Files modified:** 10 (1 created, 7 modified, 2 deleted)

## Accomplishments
- `lib/mode.sh` created: `theme_engine_detect_mode` classifies any theme name as `light`/`dark` — explicit for the two materialyou literals, palette `"mode"` override key next, perceptual-lightness fallback (python3 colorsys, same technique as the existing GTK4 accent mapper) last; always best-effort (never fails the caller).
- `generate.sh` extended: `materialyou-light` renders through `matugen image -m light` (verified to genuinely differ from `materialyou`'s `-m dark`); the static-preset `matugen json` branch is untouched (Pitfall 1 regression guard verified via grep); every successful render now writes the `mode` marker and both `gtk-{3,4}.0-settings.ini` files into the tmp tree before commit (atomic render-then-commit invariant preserved).
- `gtk.sh` is now the single mode-aware owner of GTK_THEME: reads the committed mode marker, derives `color-scheme` (`prefer-light`/`prefer-dark`) and the GTK3 theme name (`adw-gtk3`/`adw-gtk3-dark`), and propagates GTK_THEME via `systemctl --user set-environment` + `dbus-update-activation-environment`. The static `export GTK_THEME=adw-gtk3-dark` line was removed from `uwsm/env` — no second hardcode site remains.
- `commit.sh` wires both rendered `settings.ini` files into `~/.config/gtk-{3,4}.0/` using the exact walker/yazi symlink idiom, with a folded-stow-symlink guard for safe ordering against the stow migration.
- `contract.sh` gained an `ini-kv` format (names + key/value extraction); `contract.json` now lists both settings.ini files and `mode` in `state_metadata_files` — verified end-to-end via a live `theme-parity catppuccin` run (49 passed, 0 failed, 12/12 files present).
- `gtk/.config/gtk-3.0/settings.ini` and `gtk-4.0/settings.ini` removed from the stow-tracked repo tree (content preserved verbatim by the new renderer); `stow.sh` pre-creates both config dirs as real directories; the live machine was migrated (unstow/mkdir/restow + re-apply) and verified: both dirs are real, `gtk.css` remains a stow symlink, `settings.ini` resolves into the state dir, and `git status --porcelain -- gtk/` is clean.

## Task Commits

1. **Task 1: Create lib/mode.sh and extend generate.sh + theme-apply for materialyou-light and mode-resolved renders** - `8c8c1eb` (feat)
2. **Task 2: Make gtk.sh mode-aware, wire commit.sh symlinks, extend contract.sh/contract.json, remove the uwsm GTK_THEME hardcode** - `b91c520` (feat)
3. **Task 3: Migrate settings.ini out of the gtk stow package and unfold the live config dirs (D-08)** - `4b31fe4` (feat)

**Plan metadata:** (this commit, docs)

## Files Created/Modified
- `theme-engine/.config/theme-engine/lib/mode.sh` - NEW: `theme_engine_detect_mode`, single source of truth for light/dark classification
- `theme-engine/.config/theme-engine/lib/generate.sh` - sources mode.sh; materialyou-light -m light branch; writes mode marker + both settings.ini renders after every successful render; new `theme_engine_render_gtk_settings` function
- `theme-engine/.config/theme-engine/lib/gtk.sh` - reads committed mode marker, derives color-scheme/gtk3-theme/GTK_THEME, owns GTK_THEME propagation directly
- `theme-engine/.config/theme-engine/lib/commit.sh` - symlinks both settings.ini into ~/.config/gtk-{3,4}.0/, with a folded-symlink guard
- `theme-engine/.config/theme-engine/lib/contract.sh` - new `ini-kv` format extractor (names + values)
- `theme-engine/.config/theme-engine/theme-apply` - allowlist extended to accept `materialyou-light`
- `theme-engine/.config/theme-engine/contract.json` - +2 settings.ini entries (ini-kv), +`mode` in state_metadata_files
- `uwsm/.config/uwsm/env` - removed the hardcoded `GTK_THEME=adw-gtk3-dark` export
- `stow.sh` - pre-creates gtk-3.0/gtk-4.0 config dirs as real directories
- `gtk/.config/gtk-3.0/settings.ini`, `gtk/.config/gtk-4.0/settings.ini` - deleted (migrated to rendered state-dir targets)

## Decisions Made
- gtk.sh owns GTK_THEME propagation end-to-end (mode-derived, via `systemctl --user set-environment`) rather than merely re-propagating an inherited env value — required because D-07 needs this value to flip with mode, and a second hardcode site (uwsm/env) would violate the single-owner discipline already documented in this codebase.
- settings.ini's mode-sensitive lines are rendered via shell `printf` in `generate.sh`, not a matugen template — matugen has no mode-conditional templating primitive, and this keeps the GTK-signal decision in the same engine-shell layer that already owns every other GTK-signal write (Open Question 3 from RESEARCH.md, resolved in favor of the shell-side option).
- ini-kv format's key/value grep pattern relies on lines starting with a bare identifier character followed by `=` — this naturally skips `[Section]` headers and any future comment lines without needing separate skip logic, mirroring the existing kitty-kv extractor.

## Deviations from Plan

None - plan executed exactly as written. Live-machine migration steps (Task 3, item 3) were performed as instructed and verified against the actual `~/.config/gtk-{3,4}.0` state.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The `mode` marker and extended contract are now available for Plan 05-02 (static preset expansion, including light presets) to build on directly — any new palette JSON with a `"mode": "light"` key or a light background hex will be classified correctly.
- `theme-parity`'s and `theme-stress-test`'s hardcoded preset-name arrays (RESEARCH Pitfall 2) are out of scope for this plan and remain for Plan 05-02, which adds the ~14 new presets those arrays need to enumerate.
- Live desktop is back on its pre-plan theme (dracula, dark mode) with a fully clean `git status`.

---
*Phase: 05-light-mode-pipeline-theme-presets*
*Completed: 2026-07-12*

## Self-Check: PASSED

All 10 created/modified files verified present on disk (plus both settings.ini deletions confirmed); all 3 task commits (8c8c1eb, b91c520, 4b31fe4) verified in git log.
