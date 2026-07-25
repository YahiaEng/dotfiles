# Phase 5: Light Mode Pipeline & Theme Presets - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-11
**Phase:** 5-Light Mode Pipeline & Theme Presets
**Areas discussed:** Preset lineup, Light-mode behavior, Wallpaper sets & restriction, Picker redesign

---

## Preset lineup

| Option | Description | Selected |
|--------|-------------|----------|
| Match wallpaper dirs (Recommended) | Palette JSON for every staged Omarchy-style folder (~9 new) plus light variants; presets and wallpaper sets 1:1 | ✓ |
| Curated subset | Handful of staged names plus 1-2 light themes | |
| Existing 6 + light variants | No new theme families | |

**User's choice:** Match wallpaper dirs
**Notes:** User asked for a recommendation before choosing; recommendation rested on the folders being deliberately staged, Omarchy palettes being open-source transcription targets, and theme-parity scaling validation for free.

| Option | Description | Selected |
|--------|-------------|----------|
| Latte + Dawn (Recommended) | catppuccin-latte and rose-pine dawn as the two light fixtures | |
| Just catppuccin-latte | Minimum viable light coverage | |
| Light variant for every family | Maximal, but some families have no canonical light variant | |

**User's choice:** Other — "Light variant for every family that has a canonical light variant."
**Notes:** Dark-only families stay dark-only; researcher pins down the canonical list (latte, dawn, gruvbox-light, tokyonight-day, kanagawa-lotus expected).

| Option | Description | Selected |
|--------|-------------|----------|
| Own preset (Recommended) | Standalone palette JSON per light variant; `theme-apply catppuccin-latte`; zero engine plumbing | ✓ |
| Variant flag on family | `theme-apply catppuccin --light` with variant resolution | |
| You decide | Planner picks | |

**User's choice:** Own preset

| Option | Description | Selected |
|--------|-------------|----------|
| Delete it (Recommended) | Remove legacy `themes/` stow package after reference verification | ✓ |
| Keep for now | Leave dormant | |
| You decide | Planner decides | |

**User's choice:** Delete it

---

## Light-mode behavior

| Option | Description | Selected |
|--------|-------------|----------|
| materialyou-light entry (Recommended) | Second dynamic entry, explicit choice, matugen -m light | ✓ |
| Dark-only Material You | Light arrives via static presets only | |
| Auto from wallpaper | Wallpaper lightness picks the scheme automatically | |

**User's choice:** materialyou-light entry

| Option | Description | Selected |
|--------|-------------|----------|
| Auto + override field (Recommended) | Lightness detection default; optional `"mode"` key in palette JSON wins | ✓ |
| Pure auto only | Detection is the single mechanism | |
| You decide | Planner picks | |

**User's choice:** Auto + override field

| Option | Description | Selected |
|--------|-------------|----------|
| Colors + GTK only (Recommended) | Palette, GTK theme name, color-scheme, GTK4 accent; icons untouched (Phase 6 UTIL-04) | ✓ |
| Also flip icon variant | Swap icon theme dark/light variants on mode change | |
| You decide | Planner decides | |

**User's choice:** Colors + GTK only

| Option | Description | Selected |
|--------|-------------|----------|
| Render to state dir (Recommended) | settings.ini becomes matugen template + contract target, symlinked from ~/.config/gtk-3.0/ | ✓ |
| Rely on gsettings only | Drop dark keys, depend on gsettings redundancy (needs research) | |
| You decide | Researcher verifies precedence, planner picks | |

**User's choice:** Render to state dir

---

## Wallpaper sets & restriction

| Option | Description | Selected |
|--------|-------------|----------|
| Folder = preset name (Recommended) | Strict convention, rename drifting folders once, zero mapping code | ✓ |
| Mapping file | Manifest maps preset → folder | |
| You decide | Planner picks | |

**User's choice:** Folder = preset name

| Option | Description | Selected |
|--------|-------------|----------|
| Own folder (Recommended) | Light variants get their own wallpaper folders | ✓ |
| Share family folder | latte falls back to catppuccin/ | |
| Own folder, family fallback | Variant folder if non-empty, else family | |

**User's choice:** Own folder

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-set from theme's set (Recommended) | theme-apply switches wallpaper too; per-theme last-used, first-in-folder fallback | ✓ |
| Keep current wallpaper | Theme switch never touches wallpaper | |
| Notify, don't switch | Notification offers the picker | |

**User's choice:** Auto-set from theme's set

| Option | Description | Selected |
|--------|-------------|----------|
| Fall open + shared pool (Recommended) | Empty set → all wallpapers; loose files/non-preset dirs = shared pool (Material You always, static as fallback) | ✓ |
| Strict sets | Empty folder shows explicit "add wallpapers" message | |
| You decide | Planner picks | |

**User's choice:** Fall open + shared pool

---

## Picker redesign

| Option | Description | Selected |
|--------|-------------|----------|
| Upgraded kitty picker (Recommended) | Keep fzf-in-kitty; kitty graphics protocol previews; keeps live awww desktop preview | ✓ |
| Walker-based picker | GTK4 walker menu with thumbnails; live preview unproven | |
| Custom GTK4 grid app | Purpose-built grid window; most new code | |

**User's choice:** Upgraded kitty picker

| Option | Description | Selected |
|--------|-------------|----------|
| List + large preview (Recommended) | fzf list + large pixel-perfect preview pane + metadata + current marker | ✓ |
| Thumbnail grid | Needs custom kitten/different TUI; research spike | |
| You decide | Planner picks | |

**User's choice:** List + large preview

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, pipeline-themed (Recommended) | fzf colors from state dir via new render target + contract entry | ✓ |
| Kitty inheritance only | Rely on terminal ANSI colors | |
| Leave hardcoded | Keep catppuccin colors | |

**User's choice:** Yes, pipeline-themed

| Option | Description | Selected |
|--------|-------------|----------|
| Set only + toggle (Recommended) | Theme's set by default, keybind to browse all | ✓ |
| Set only, no escape | Strictly the theme's set | |
| All, set highlighted | Everything shown, set grouped on top | |

**User's choice:** Set only + toggle

---

## Claude's Discretion

- Lightness-detection math (palette keys, threshold)
- Per-theme last-used wallpaper state storage format
- fzf color fragment format and palette-role mapping
- Light parity fixture wiring in theme-parity
- Omarchy palette transcription details (source files, key mapping)

## Deferred Ideas

- Icon theme dark/light variant switching on mode change → Phase 6 UTIL-04
- Terminal thumbnail-grid picker layout → only if a future rework moves off fzf
- Walker-based wallpaper picker → Phase 7 menu work could revisit cohesion
