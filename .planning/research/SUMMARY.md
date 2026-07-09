# Project Research Summary: v2.0 Desktop Expansion

**Project:** Arch + Hyprland Dotfiles — Desktop Expansion
**Domain:** Personal Wayland desktop rice (theme-driven utilities, menus, and desktop automation)
**Researched:** 2026-07-09
**Confidence:** MEDIUM-HIGH overall

## Executive Summary

The v2.0 Desktop Expansion is a **disciplined, architecture-respecting extension** of an already-working v1.0 theme-engine that consolidates color propagation across 10 desktop surfaces. The research confirms that every major feature group (screenshot utilities, emoji/clipboard pickers, Omarchy-style Super-menu, waybar variants, light themes, Zen browser theming) integrates cleanly into the existing stow + matugen pipeline without architectural rewrite, **provided a strict sequencing discipline is followed**: bug fixes first, light-mode plumbing before light presets, menu framework before menu content, and isolated testing of integration points that have footguns (wlogout hang, hyprlock lockout, $SUPER-tap keybind interaction).

The research identifies six critical pitfalls — each with clear prevention strategies — that could derail phases if not actively managed. Stack choices are mature and verified (satty, wf-recorder, hyprpicker, swayosd all confirmed official-repo packages with clear integration patterns), and the feature set is well-scoped (table stakes only in MVP, explicit deferral of scope creep like popover media widgets).

**Key recommendation:** Follow the suggested phase structure (Bug Fixes → Light/Dark Plumbing → Presets & Wallpapers → Surfaces & Utilities → Menu Framework → Menu Content → Waybar Evolution), with explicit research spikes for Zen browser profile-path resolution and OLED auto-hide behavior.

## Key Findings

### Recommended Stack

**Six new core packages** (all official Arch except hyprpicker from AUR):
- **satty** (0.21.1) — Screenshot annotation, GTK4 + libadwaita, consistent with existing walker stack
- **wf-recorder** (0.6.0) — Screen/region video recording (mp4)
- **gifski** (1.34.0) — High-quality GIF conversion from recorded video
- **hyprpicker** (0.4.7, AUR) — Color picker, officially maintained by Hyprland org
- **swayosd** (0.3.1) — Themed volume/brightness/caps-lock OSD, CSS-theming
- **Nerd fonts** (ttf-jetbrains-mono-nerd, ttf-hack-nerd, ttf-cascadia-code-nerd) — Font family switcher pool

**Two existing packages already solve features:** `elephant-symbols` provides emoji picker; `elephant-clipboard` provides clipboard history — both already installed.

**Critical finding:** The `themes/.config/themes/` directory is dead code (zero references in any script) — do not add new presets there. All live static-preset content lives in `theme-engine/.config/theme-engine/palettes/*.json`.

### Expected Features

**Table stakes (P1 — launch with MVP):**
- Screenshot capture + annotation + recording (grim+slurp+satty+wf-recorder)
- Clipboard history picker (walker+elephant-clipboard)
- Emoji picker (walker+elephant-symbols)
- SwayOSD themed indicators
- Waybar notification-center button
- Waybar built-in mpris now-playing module
- Icon theme picker + Papirus bundled

**Differentiators (P2 — high-value features):**
- Omarchy-style Super-key hierarchical menu with custom icons
- Theme-scoped wallpaper picker (per-theme directories, static-restricts)
- Zen browser theming (requires profile-path research spike)
- Waybar vertical layout + OLED-safe behavior

**Deferred out of scope:**
- Quickshell/QML custom shell replacement
- Full GUI settings app
- Gaming-mode session switching
- Popover/album-art media widget

### Architecture Approach

The existing v1.0 theme-engine (**not being rewritten**) consists of: (1) thin trigger scripts (`theme-apply <name>`); (2) central `theme-engine/` with `generate.sh` → `commit.sh` → `reload.sh`; (3) `contract.json` as single source of truth for 10 output files; (4) stowed app configs that `@import`/`source`/symlink from state-dir.

**New components integrate cleanly:**
- New themed surfaces become new matugen template entries + contract entries
- Utility scripts extend `hypr/.config/hypr/scripts/`
- Super-menu uses walker's already-installed `menus` provider (elephant-menus)
- Waybar vertical layout is a new config-pair only (no new matugen templates)

### Critical Pitfalls & Prevention

1. **wlogout/uwsm shutdown hang has multiple root causes** — Isolate via keyboard test, coredumpctl, journalctl inspection before redesign work. **Prevention:** Must diagnose before redesign; wrong fix trades one hang for another.

2. **hyprlock redesign can lock you out** — New color-source paths or image references are crash triggers. **Prevention:** Keep second TTY logged in before every test; document recovery commands.

3. **$SUPER-tap menu submap can break entire keybind set** — Exit bind without explicit escape key traps user. **Prevention:** Test exit bind first in isolation; full sweep of existing $SUPER+key bindings before shipping.

4. **Light themes expose GTK3/GTK4 propagation split** — Portal broadcasts live-update GTK4 but not GTK3 (settings.ini). **Prevention:** Extend contract.json + theme-parity gate to include light fixture before shipping light presets.

5. **Clipboard history stores passwords/tokens plaintext** — Every clipboard entry (text+images) persists. **Prevention:** Size cap + wipe policy are launch requirements, not follow-up hardening.

6. **elephant/walker version skew silently breaks custom menus** — Private socket protocol, version mismatch produces blank items (not error). **Prevention:** Pin walker + all elephant-* packages together; add health-gate check to theme-doctor.

## Implications for Roadmap

### Suggested Phase Structure

**Phase A: Bug Fixes** (wlogout hang, hyprlock keystroke-drop, kitty startup)
- De-risks base before layering new features; isolated config/script changes, no new packages
- Wlogout redesign/hyprlock theming deferred until fixes proven working

**Phase B: Light/Dark Mode Plumbing** (gtk.sh mode detection, settings.ini hardcode removal)
- HARD DEPENDENCY before light presets can ship correctly
- Auto-detect theme mode from rendered palette lightness
- Extend contract.json + theme-parity to cover light-mode output

**Phase C: New Static Presets incl. Light Themes** (content work)
- Depends on Phase B; add light-mode variants (catppuccin-latte, etc.) as new palette JSON files; zero architecture work

**Phase D: New Themed Surfaces & Utility Scripts Suite**
- Independent; follows established patterns
- SwayOSD (new template+contract), hyprlock redesign (modify), utilities (screenshot, emoji, clipboard, color picker, icon-theme, font switcher)
- **Zen browser needs research spike:** profile-path resolution, native vs flatpak, graceful "profile doesn't exist yet"

**Phase E: Wallpaper & Theme-Scoped Management**
- Per-theme wallpaper subdirectories; picker respects theme restriction (static mode only; matugen unrestricted)
- Depends on Phase C (meaningful once light presets exist)

**Phase F: Walker Menu Framework** (HARD DEPENDENCY for Phase G)
- Keybind repoint (bare $SUPER-tap → walker menu)
- New elephant menus stow content
- Full exit-bind test + existing $SUPER+key regression sweep

**Phase G: Menu Tree Content** (Utilities, Keybinds, Settings, AI Dashboard, Game Center, Power)
- Depends on Phase F; populates menu with submenus wrapping Phase D utilities

**Phase H: Waybar Evolution** (vertical layout, media center, notification center, OLED-safe behavior)
- Independent architecturally; moderate complexity
- Vertical layout: new config-pair, full module re-test (not copy-paste)
- **OLED auto-hide needs research spike:** hypridle availability, idle integration, pixel-shift feasibility

### Phase Ordering Rationale

- **Strict dependencies enforced:** Light plumbing before presets; menu framework before content; wallpaper restriction meaningful only after light presets exist
- **Bug fixes first:** De-risks remaining work; redesigns deferred until underlying reliability proven
- **New surfaces grouped together:** All follow proven @import-from-state-dir pattern; confirms pipeline extends cleanly before attempting more complex work
- **Waybar independent:** Can run in parallel if desired, but requires careful testing of vertical module stacking and SIGUSR2 reload with multiple bars

### Research Flags

Phases likely needing deeper research during planning:
- **Zen browser:** Profile-path resolution (native vs flatpak), graceful handling of "profile doesn't exist yet" (chicken-and-egg: profile needs Zen to be launched once first)
- **OLED auto-hide:** No precedent in this repo's existing idle infrastructure; needs investigation of hypridle availability and mechanism

Phases with standard patterns (skip deep research): bug fixes (well-documented upstream issues), light/dark plumbing (two code locations, proven pattern extension), presets (pure content addition), wallpaper dirs (filesystem-native), menu framework (direct Omarchy pattern), menu content (straightforward submenu definitions).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| **Stack** | **HIGH** | All core packages verified directly via `pacman -Si` on target machine; hyprpicker via AUR RPC. Version compatibility checked. |
| **Features** | **MEDIUM** | Cross-referenced across 5 reference rices (Omarchy, HyDE, end-4, Caelestia, ML4W); corroborated multi-source but websearch-sourced. Some specifics need machine verification. |
| **Architecture** | **HIGH** | Sourced from direct repository inspection; dead-code finding verified via grep. Two claims (elephant-menus format, Zen userChrome.css) need phase-level research. |
| **Pitfalls** | **MEDIUM-HIGH** | Critical pitfalls corroborated across 2+ GitHub issues. Prevention strategies documented. |

**Overall: MEDIUM-HIGH** — Roadmap is structurally sound and dependency-aware; execution risk manageable if research spikes (Zen profile, OLED auto-hide) completed before the relevant phase planning.

### Gaps to Address

- **Zen profile-path resolution:** `profiles.ini` parsing, native vs flatpak, graceful "doesn't exist yet" — research spike required
- **OLED auto-hide mechanism:** hypridle availability, idle integration — research spike required
- **swayosd CSS hot-reload:** Behavior not verified on actual machine version; impacts reload.sh design
- **elephant-menus format:** schema, icon-name vs absolute-path support — needs `elephant generatedoc` verification on-machine
- **Waybar mpris module current state:** Confirm existing `media-player.py` role before media-center design

## Sources

- `.planning/research/STACK.md` — package names/versions verified via `pacman -Si`/`-Q` and AUR RPC on the target machine (HIGH); tool-choice comparisons via websearch (LOW-MEDIUM)
- `.planning/research/FEATURES.md` — cross-referenced across Omarchy, HyDE, end-4/dots-hyprland, Caelestia, ML4W via websearch/DeepWiki/GitHub (LOW-MEDIUM)
- `.planning/research/ARCHITECTURE.md` — direct repository inspection of theme-engine, contract.json, stowed configs (HIGH); elephant-menus schema and Zen theming via websearch (LOW)
- `.planning/research/PITFALLS.md` — websearch, several findings corroborated by 2+ independent GitHub issues (LOW-MEDIUM)
