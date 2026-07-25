# Phase 5: Light Mode Pipeline & Theme Presets - Context

**Gathered:** 2026-07-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the theme pipeline to full light-mode support and a richer preset + wallpaper experience: fix both dark-hardcoded chokepoints (`lib/gtk.sh` gsettings and `gtk-3.0/settings.ini`), auto-detect theme mode from palette lightness, extend `contract.json` + `theme-parity` with a light fixture, ship an expanded static preset set (including light themes) as palette JSONs through the existing `theme-apply` pipeline, organize wallpapers into per-theme sets with picker restriction (static = theme's set, Material You = anything), and redesign the wallpaper picker to Omarchy-level polish. No new themed app surfaces land here (wlogout/hyprlock/swayosd/zen redesigns are Phase 6); no walker menus (Phase 7); no waybar work (Phase 8).

</domain>

<decisions>
## Implementation Decisions

### Preset lineup (THM-02)
- **D-01:** Ship a palette JSON for every staged wallpaper folder — the Omarchy-style lineup: matte-black, osaka-jade, ristretto, everfrost, kanagawa, hackerman, miasma, ethereal, vantablack — transcribed from Omarchy's published themes, alongside the existing 6 (catppuccin, dracula, gruvbox, nord, rosepine, tokyonight). Presets and wallpaper sets stay 1:1.
- **D-02:** Ship a light variant for every theme family that has a **canonical upstream light variant** (e.g. catppuccin-latte, rose-pine dawn, gruvbox-light, tokyonight-day, kanagawa-lotus). Dark-only families (matte-black, vantablack, …) stay dark-only. The researcher pins down the definitive canonical-light list; do not invent light palettes for families without one.
- **D-03:** Light variants are modeled as **standalone presets** — their own palette JSON (e.g. `catppuccin-latte.json`), applied via `theme-apply catppuccin-latte`. No variant-flag plumbing, no family/sub-palette resolution. Mode detection alone tells the pipeline a preset is light.
- **D-04:** The legacy `themes/` stow package (per-app static theme files under `themes/.config/themes/`) is **deleted this phase**, after the planner verifies nothing references it. "Presets = palette JSONs in theme-engine" is the single source of truth; new presets never add per-app static files.

### Light-mode behavior (THM-01)
- **D-05:** Material You gets light support via an explicit **`materialyou-light`** entry alongside `materialyou` (matugen `-m light` on the same wallpaper). Explicit user choice only — no auto mode flip from wallpaper lightness.
- **D-06:** Mode is auto-detected from palette lightness (background/surface colors) per the roadmap, **plus** an optional `"mode": "light"|"dark"` override key in the palette JSON that wins when present — deterministic escape hatch for edge palettes.
- **D-07:** Light mode flips **colors + GTK signals only**: rendered palette, GTK3 theme name (adw-gtk3-dark ↔ adw-gtk3), gsettings color-scheme (prefer-dark ↔ prefer-light), and the GTK4 accent mapping. Icon/cursor themes are untouched — icon theming is Phase 6 (UTIL-04).
- **D-08:** The `gtk-3.0/settings.ini` chokepoint is fixed by making settings.ini a **rendered contract target**: matugen template rendered into `~/.local/state/theme/`, with `~/.config/gtk-3.0/settings.ini` symlinked there (seeded by `stow.sh`, same pattern as other themed files). The repo tree stays clean on every switch — no in-place edits of stow-tracked files.

### Wallpaper sets & restriction (THM-03)
- **D-09:** Strict convention: `Wallpapers/<preset-name>/` matches the palette JSON name exactly. Rename the drifting folders once (`rose-pine` → `rosepine`, `tokyo-night` → `tokyonight`, etc.). No mapping/manifest file.
- **D-10:** Light variants get their **own wallpaper folders** (e.g. `Wallpapers/catppuccin-latte/`) — no family-folder sharing or fallback resolution. User populates them with light wallpapers.
- **D-11:** `theme-apply <static-preset>` **auto-sets the wallpaper** from that theme's set: remember the last-used wallpaper per theme, fall back to the first in the folder. One action lands a fully coherent desktop (Omarchy-style). (Material You keeps its existing direction: wallpaper drives palette.)
- **D-12:** Fall-open semantics: if a preset's wallpaper folder is empty or missing, the picker falls back to **all** wallpapers — never a dead end. Loose files at the Wallpapers/ root and non-preset dirs (`anime/`, …) form a **shared pool**: always offered under Material You, offered for static themes only as the empty-set fallback.

### Wallpaper picker redesign (THM-04)
- **D-13:** Keep the fzf-in-floating-kitty stack, upgraded: **pixel-perfect previews via the kitty graphics protocol** (kitten icat / `chafa -f kitty`) instead of block art. The live `awww` desktop preview on navigate is a keeper feature — do not lose it.
- **D-14:** Layout: fzf list + **large pixel-perfect preview pane** with filename/resolution metadata and a marker on the currently-active wallpaper. No terminal thumbnail grid (fzf can't; explicitly rejected).
- **D-15:** The picker is **pipeline-themed**: fzf colors sourced from `~/.local/state/theme/` via a new small render target (fzf color fragment + `contract.json` entry) so the picker matches the active theme, including light mode. No hardcoded catppuccin colors remain.
- **D-16:** Restriction UI: with a static theme active the picker opens showing **only that theme's set** (header names the theme), with a keybind (e.g. Ctrl-A) to temporarily browse the full collection. Material You always browses everything.

### Claude's Discretion
- Lightness-detection math (which palette keys, threshold) — planner/executor pick; must classify all shipped palettes correctly given D-06's override escape hatch exists.
- Exact per-theme "last-used wallpaper" state storage (state-dir metadata file naming) — follow existing `current-theme` state conventions.
- fzf color fragment format and which fzf color slots map to which palette roles.
- How the light parity fixture is wired into `theme-parity` (fixture palette choice, assertion set) — success criterion just requires both a light and a dark fixture passing.
- Omarchy palette transcription details (which Omarchy source files to read, key mapping into the ~22-key matugen custom-keyword schema).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — THM-01, THM-02, THM-03, THM-04 definitions
- `.planning/ROADMAP.md` — Phase 5 goal + 5 success criteria (light chokepoints, mode auto-detection, light+dark parity fixtures, picker restriction, picker polish)

### Theme engine (files under change)
- `theme-engine/.config/theme-engine/theme-apply` — single entrypoint; preset validation against `palettes/*.json`; wallpaper auto-set (D-11) hooks in here
- `theme-engine/.config/theme-engine/lib/generate.sh` — matugen render step (`matugen json` for presets, `matugen image` for materialyou); `materialyou-light` (D-05) and mode detection (D-06) land here
- `theme-engine/.config/theme-engine/lib/gtk.sh` — dark-hardcoded chokepoint #1: `color-scheme "prefer-dark"` + `gtk-theme "adw-gtk3-dark"` literals (lines ~21-24); must become mode-aware (D-07)
- `theme-engine/.config/theme-engine/lib/commit.sh` + `lib/reload.sh` — atomic commit and reload fan-out; new render targets flow through both
- `theme-engine/.config/theme-engine/contract.json` — 10-file output contract; grows: settings.ini target (D-08), fzf color fragment (D-15)
- `theme-engine/.config/theme-engine/theme-parity` — parity gate; must pass with a light fixture AND a dark fixture
- `theme-engine/.config/theme-engine/palettes/` — existing 6 palette JSONs; the ~22-key matugen custom-keyword schema all new presets must follow

### GTK chokepoint #2
- `gtk/.config/gtk-3.0/settings.ini` — hardcodes `gtk-application-prefer-dark-theme=1` + `gtk-theme-name=adw-gtk3-dark`; becomes a rendered state-dir target with a stow-seeded symlink (D-08)
- `stow.sh` — seeds first-boot theme state; must seed the new settings.ini symlink

### Wallpaper system
- `hypr/.config/hypr/scripts/wallpaper-picker.sh` — current fzf+chafa picker (hardcoded catppuccin colors, maxdepth-1 scan, awww live preview, materialyou re-apply on select)
- `hypr/.config/hypr/scripts/wallpaper-switch.sh` — floating-kitty launcher wrapper
- `wallpapers/Pictures/Wallpapers/` — staged per-theme folders (incl. Omarchy-named dirs) + loose shared-pool files; folders to be renamed to match palette names (D-09)
- `hypr/.config/hypr/scripts/theme-init.sh` — login-time theme seed; must stay consistent with wallpaper auto-set

### Deletion target
- `themes/` stow package (`themes/.config/themes/{gtk,kitty,yazi,vscodium,css,static}/`) — legacy per-app static theme files, believed unreferenced; verify then delete (D-04)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `theme-apply` render→commit→reload pipeline: adding presets is drop-a-JSON; usage/validation already enumerates `palettes/*.json` dynamically
- `theme-parity` + `contract.json`: structural validation of every new palette is free once the light fixture is added
- `matugen json` custom-keyword path: light presets are just light-valued JSONs through the same templates (`matugen -m light` available for materialyou-light)
- Existing picker's awww live-preview binding (`--bind focus:execute-silent`) — the keeper interaction for the redesign
- `verify/` container gate — reruns install/stow/parity; will exercise the new settings.ini symlink seeding automatically

### Established Patterns
- Rendered-file + state-dir-symlink pattern (kitty, hyprland, waybar all `@import`/source from `~/.local/state/theme/`) — D-08 extends it to settings.ini
- Atomic render-then-commit (D-14 v1.0): mode detection must resolve during render so a failed light render leaves the desktop unchanged
- Headless guards in reload fan-out — any new reload/wallpaper-set step must not hang the container gate (no session bus / no hyprland)
- Git-clean invariant after every switch (stress-test enforced) — rules out in-place edits of stow-tracked files
- Security posture from v1.0: preset names validated against actual palette files before path interpolation — `materialyou-light` needs the same treatment as `materialyou`

### Integration Points
- `lib/gtk.sh` gsettings calls + `uwsm/.config/uwsm/env` GTK_THEME (single source of truth per D-13/PIPE-05 — light mode must respect that propagation design, not add a second hardcode site)
- `wallpaper-picker.sh` ↔ `theme-apply`: picker re-runs `theme-apply materialyou` on select in dynamic mode; with materialyou-light it must re-run the *active* dynamic variant
- Phase 6 depends on this phase's light parity gate to validate its new surfaces under both modes — fixture design should make adding surfaces cheap
- fzf color fragment consumers: currently only the wallpaper picker, but the theme picker / future fzf UIs can source the same fragment

</code_context>

<specifics>
## Specific Ideas

- The wallpaper folders were deliberately staged with Omarchy theme names — the preset lineup should match them 1:1; transcribe palettes from Omarchy's open-source themes rather than inventing colors.
- "Omarchy-style" one-action coherence: applying a theme lands wallpaper + colors together (D-11), like Omarchy's theme switcher.
- The live awww desktop preview while navigating the picker is explicitly valued — the redesign must keep it.
- Pixel-perfect previews via kitty graphics protocol are the intended visual jump from the current chafa block art.

</specifics>

<deferred>
## Deferred Ideas

- Icon theme dark/light variant switching on mode change — deliberately excluded from D-07; Phase 6's UTIL-04 icon-theme picker owns icon theming.
- Terminal thumbnail-grid picker layout — rejected for this phase (fzf can't natively); revisit only if a future picker rework moves off fzf.
- Walker-based wallpaper picker — considered and rejected in favor of the upgraded kitty picker; Phase 7's menu work could revisit cohesion later.

</deferred>

---

*Phase: 5-Light Mode Pipeline & Theme Presets*
*Context gathered: 2026-07-11*
