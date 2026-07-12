---
phase: 06-themed-surfaces-utility-suite
plan: 08
subsystem: theming-pipeline
tags: [matugen, kitty, waybar, vscodium, gtk, fzf, fc-list, imagemagick, jq, bash]

# Dependency graph
requires:
  - phase: 06-01
    provides: theme-engine render/commit/reload pipeline (generate.sh, commit.sh, reload.sh) this plan extends
  - phase: 06-07
    provides: theme-orthogonal state-axis pattern (icon-theme picker, Pitfall 6 discipline) this plan replicates for font
provides:
  - lib/font.sh — theme_engine_render_font_files render module (kitty-font.conf + waybar-font.css)
  - generate.sh integration — sources font.sh, calls the render each run, folds font-choice into gtk-font-name
  - commit.sh --exclude=font-choice (theme-orthogonal axis survives rsync --delete)
  - kitty.conf second include + 3 waybar style-*.css second @import (additive, non-sed wire-up)
  - font-switcher.sh — fzf-in-kitty picker with a live rendered specimen preview
affects: [07-walker-menus, 08-waybar-oled]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Theme-orthogonal state axis (font-choice), fourth instance of the last-wallpaper/icon-theme pattern — root-level state file excluded from commit.sh's rsync --delete, read at render time by generate.sh/font.sh"
    - "fc-match -f '%{file}' family-name-to-file-path indirection for ImageMagick text rendering (IM's own -font lookup only resolves its internal type.xml aliases, not fontconfig family names)"

key-files:
  created:
    - theme-engine/.config/theme-engine/lib/font.sh
    - hypr/.config/hypr/scripts/font-switcher.sh
  modified:
    - theme-engine/.config/theme-engine/lib/generate.sh
    - theme-engine/.config/theme-engine/lib/commit.sh
    - kitty/.config/kitty/kitty.conf
    - waybar/.config/waybar/style-full.css
    - waybar/.config/waybar/style-minimal.css
    - waybar/.config/waybar/style-floating.css

key-decisions:
  - "Nerd Font glyph codepoints for the specimen preview (home U+F015, folder U+F07B, git-branch U+E725, terminal U+F489, gear U+F013) verified present in the installed FiraCode Nerd Font's cmap via direct TTF cmap-table parsing this session, not an unverified cheat-sheet copy"
  - "Picker excludes 'Symbols Nerd Font' from the enumerated set (Rule 2 defensive filter) — it is the glyph-only supplemental font with no letterforms; selecting it as a text/code font would render every surface as tofu"
  - "vscodium font propagation owned by font-switcher.sh itself (jq-merge mirroring reload.sh's theme_engine_reload_vscodium idiom), not the engine's reload fan-out — vscodium has no font-key render target, matching the plan's stated discretion"

requirements-completed: [UTIL-05]

coverage:
  - id: D1
    description: "lib/font.sh renders kitty-font.conf + waybar-font.css from the font-choice state (default FiraCode Nerd Font), folds gtk-font-name into generate.sh's existing render_gtk_settings printf"
    requirement: "UTIL-05"
    verification:
      - kind: other
        ref: "isolated render test — theme_engine_generate('catppuccin', tmp) with font-choice=JetBrainsMono Nerd Font produced correct kitty-font.conf/waybar-font.css/gtk-3.0-settings.ini/gtk-4.0-settings.ini content"
        status: pass
      - kind: other
        ref: "bash -n theme-engine/.config/theme-engine/lib/{font,generate,commit}.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "kitty.conf second include + waybar style-*.css second @import wire the rendered font fragments in (additive, never in-place sed of git-tracked stylesheets)"
    requirement: "UTIL-05"
    verification:
      - kind: other
        ref: "grep -c 'include ~/.local/state/theme/kitty' kitty.conf >= 2; grep 'waybar-font.css' in all 3 style-*.css"
        status: pass
    human_judgment: false
  - id: D3
    description: "font-switcher.sh: fzf-in-kitty picker (not walker dmenu) enumerating installed nerd fonts via fc-list, live specimen preview rendered in the previewed family, validates selection, persists atomically, jq-merges vscodium, re-runs theme-apply"
    requirement: "UTIL-05"
    verification:
      - kind: other
        ref: "bash -n font-switcher.sh; standalone enumeration-script test confirmed correct family list + active marker; standalone preview-script test confirmed fc-match+convert produced a valid specimen PNG; standalone jq-merge test confirmed valid vscodium settings.json output"
        status: pass
    human_judgment: true
    rationale: "fzf interactive picker UX (live specimen legibility, header/color theming, keybind feel) and the full live-desktop regression (switch font, switch theme, confirm font survives) require a human running the picker in a real floating-kitty session — not exercisable headlessly without disrupting the live Wayland session this agent is running inside."

# Metrics
duration: 22min
completed: 2026-07-12
status: complete
---

# Phase 6 Plan 8: Nerd Font Switcher Summary

**fzf-in-kitty nerd-font switcher (UTIL-05) with a live rendered specimen preview, wiring a new theme-orthogonal font-choice state axis across kitty, vscodium, GTK, and waybar via a brand-new `lib/font.sh` render module.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-07-12T17:37:36Z
- **Completed:** 2026-07-12T17:46:50Z
- **Tasks:** 3
- **Files modified:** 9 (2 created, 7 modified)

## Accomplishments
- Built `lib/font.sh` — the first genuinely new render path this phase's font axis needed (font is neither matugen-templatable nor a mode signal), rendering `kitty-font.conf` + `waybar-font.css` from `~/.local/state/theme/font-choice` every `theme-apply` run
- Folded `gtk-font-name` into the existing `theme_engine_render_gtk_settings` printf call (Pitfall 6 discipline — one owner per GTK-signal key, never a second parallel settings writer)
- Wired all four hardcode sites: kitty's second `include`, waybar's second `@import` (×3 stylesheets, additive only, never in-place sed), GTK via the state read above, and vscodium via a `jq`-merge the picker itself performs
- Shipped `font-switcher.sh`: fzf-in-floating-kitty (D-20, not walker dmenu) with a live specimen — pangram + code sample + 5 verified Nerd Font glyphs — rendered directly in the previewed family via `fc-match`+ImageMagick, same kitten-icat/chafa fallback chain as `wallpaper-picker.sh`/`icon-theme-picker.sh`
- Verified the full render path end-to-end in an isolated test (font-choice=JetBrainsMono Nerd Font → correct kitty-font.conf/waybar-font.css/gtk-*-settings.ini output), confirming the state-axis mechanism works before committing

## Task Commits

Each task was committed atomically:

1. **Task 1: lib/font.sh render module + generate.sh integration + commit.sh exclude** - `7a4c8cc` (feat)
2. **Task 2: Wire the 4 surfaces (kitty include, waybar @import; GTK done in Task 1)** - `b351057` (feat)
3. **Task 3: font-switcher.sh fzf-in-kitty picker with live specimen** - `8706656` (feat)

## Files Created/Modified
- `theme-engine/.config/theme-engine/lib/font.sh` - `theme_engine_render_font_files`, renders kitty-font.conf + waybar-font.css from font-choice state
- `theme-engine/.config/theme-engine/lib/generate.sh` - sources font.sh, calls the render each run, folds font-choice read into the existing gtk-font-name printf
- `theme-engine/.config/theme-engine/lib/commit.sh` - rsync --delete now excludes font-choice (fourth instance of the last-wallpaper/current-theme/icon-theme bug class)
- `kitty/.config/kitty/kitty.conf` - second `include` of state-dir kitty-font.conf, after the existing colors include
- `waybar/.config/waybar/style-{full,minimal,floating}.css` - second `@import` of waybar-font.css, after the existing colors @import
- `hypr/.config/hypr/scripts/font-switcher.sh` - new fzf-in-kitty picker: enumeration, live specimen preview, validation, atomic persist, vscodium jq-merge, theme-apply re-run, notification

## Decisions Made
- Nerd Font glyph codepoints for the specimen (home/folder/git-branch/terminal/gear) verified present in the installed FiraCode Nerd Font's cmap via a direct Python TTF cmap-table parse this session (all 5 confirmed present) rather than trusting an unverified nerdfonts.com cheat-sheet copy — these come from the Font Awesome/Devicons/Octicons ranges the Nerd Fonts patcher injects verbatim into every patched build, so the codepoints carry over across families
- `fc-match -f '%{file}'` used to resolve a fontconfig family name to its actual .ttf file path before handing it to ImageMagick's `-font` — verified that IM's own `-font <family-name>` lookup only resolves its internal `type.xml` aliases (hyphenated names like `FiraCode-Nerd-Font-Regular`), not raw fontconfig family strings with spaces, so the file-path indirection is required for any dynamically-enumerated family to render correctly
- "Symbols Nerd Font" (the glyph-only supplemental font from `ttf-nerd-fonts-symbols`, confirmed via `fc-list` to have no letterforms) is filtered out of the enumerated picker list — an obviously broken selection no user would intentionally want, added as a Rule 2 defensive filter beyond the plan's literal "enumerate ttf-*-nerd dynamically" instruction
- vscodium's font propagation is owned entirely by `font-switcher.sh` (a `jq`-merge mirroring `reload.sh`'s `theme_engine_reload_vscodium` idiom) rather than the engine's reload fan-out, since vscodium has no font-key render target and this was explicitly Claude's discretion per the plan/RESEARCH

## Deviations from Plan

None - plan executed exactly as written. The Symbols Nerd Font exclusion and the fc-match file-path indirection are implementation details within Task 3's stated scope ("enumerate installed ttf-*-nerd families dynamically... rich preview"), not deviations from the plan's task boundaries.

## Issues Encountered

- ImageMagick's `-font "FiraCode Nerd Font"` (a raw fontconfig family name) failed with "unable to read font" — IM's font-name resolution only matches its own `type.xml`-registered aliases. Resolved by resolving the family to its actual file path via `fc-match -f '%{file}'` first and passing that to `-font` instead; verified working via a standalone `convert` test before wiring it into the preview script.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- UTIL-05 is fully wired end-to-end: font-choice is a persistent, theme-orthogonal state axis that survives every theme switch, and propagates to all four in-scope surfaces (kitty, vscodium, GTK, waybar).
- Live human UAT still outstanding for this plan's D3 deliverable (interactive fzf picker feel, specimen legibility in a real floating-kitty window, and the "switch font → switch theme → font survives" live regression) — deliberately not exercised against the live desktop this agent is running inside, to avoid disrupting the user's active Hyprland session with a walker/kitty/waybar reload fan-out mid-task. Recommend a manual UAT pass (`~/.config/hypr/scripts/font-switcher.sh` from a terminal, or once a keybind is wired in a later plan) before closing out the phase.
- No keybind wired for font-switcher.sh in this plan (matches icon-theme-picker.sh precedent from 06-07 — keybinds.conf wiring is out of this plan's files_modified scope, deferred to a later utility-keybinds plan per RESEARCH's Deferred Ideas note on Phase 7 menu/cheat-sheet wiring).

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-12*

## Self-Check: PASSED

All 9 created/modified files found on disk; all 4 commit hashes (7a4c8cc, b351057, 8706656, af2b75e) found in git log.
