# Requirements: Arch + Hyprland Dotfiles

**Defined:** 2026-07-07
**Core Value:** One theme switch — static or dynamic — instantly and consistently re-themes the entire desktop, and the whole setup reproduces from scratch with one script.

## v1 Requirements

Requirements for the bug-fix milestone. Each maps to roadmap phases.

### Theme Propagation

- [ ] **THEME-01**: Walker follows theme switches (static and dynamic) — no more stuck-white launcher
- [ ] **THEME-02**: Thunar follows theme switches with full GTK3 palette (adw-gtk-theme installed and applied)
- [ ] **THEME-03**: GTK4/libadwaita apps follow dark/light mode + accent color, with best-effort `gtk-4.0/gtk.css` overrides (documented as the realistic ceiling)
- [ ] **THEME-04**: Waybar re-themes correctly on switch, verified in both static and dynamic modes
- [ ] **THEME-05**: Swaync re-themes correctly on switch, verified in both static and dynamic modes
- [ ] **THEME-06**: One theme switch updates every visible app live — no relogin or session restart required

### Pipeline Consolidation

- [ ] **PIPE-01**: One shared theme engine (single apply-theme entrypoint + shared reload library) used by both the interactive switcher and login init — no duplicated orchestration
- [ ] **PIPE-02**: Reload fan-out is owned by exactly one place (matugen post_hooks OR the shared reload script, not both)
- [ ] **PIPE-03**: Matugen generated output lives outside the stowed git tree; app configs import from the generated location
- [ ] **PIPE-04**: Static presets and matugen dynamic themes produce an identical output contract (same canonical paths, same variable names) through one pipeline
- [ ] **PIPE-05**: `GTK_THEME` and related theme env vars consolidated to a single source of truth
- [ ] **PIPE-06**: Repeated theme switching is reliable (stress test: 10 consecutive switches with Thunar/Walker open, 100% correct result)

### Bug Scan

- [ ] **SCAN-01**: Full-repo bug audit completed with documented findings across theme pipeline, hyprland config, keybinds, uwsm, stow setup, and install scripts
- [ ] **SCAN-02**: Walker/elephant functional health verified (backend daemon lifecycle, provider packages referenced in config actually present)

### Install & Reproducibility

- [ ] **INST-01**: `install.sh` installs the correct theming-critical packages (`adw-gtk-theme`, not the nonexistent `adw-gtk3`) and verifies critical packages post-install
- [ ] **INST-02**: `stow.sh` completes successfully on a genuinely fresh system (no unguarded operations that assume existing state)
- [ ] **INST-03**: Full `install.sh` + `stow.sh` run verified in a disposable Arch VM/container, producing the fully themed desktop

### Repo Cleanup

- [ ] **CLEAN-01**: Dead configs removed — wofi package, `debug.txt`, stray screenshots, other unused files
- [ ] **CLEAN-02**: `git status` stays clean after a theme switch (no generated files tracked in the repo)

## v2 Requirements

Expansion milestone. Tracked but not in the current roadmap — planned via `/gsd-new-milestone` after v1 ships.

### OSD

- **OSD-01**: SwayOSD volume/brightness indicators bound to media keys, themed via the shared pipeline

### Walker Menus

- **MENU-01**: Power menu (lock/logout/reboot/shutdown) as a walker/elephant menu
- **MENU-02**: System/settings quick menu (theme switch, wallpaper, network, etc.)
- **MENU-03**: Searchable keybind viewer/cheat-sheet menu

### Media

- **MEDIA-01**: Waybar native `mpris` now-playing widget with click/scroll playback controls

### Polish & Themes

- **POLISH-01**: One cohesive animation/easing language across Hyprland, waybar, walker, swaync, OSD
- **THEMES-01**: 1–2 additional static theme presets exercising the full template fan-out
- **THEMES-02**: Per-theme wallpaper sets tied to theme switching

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Wofi launcher fixes | Abandoned in favor of walker; configs removed, not fixed |
| Lock screen / idle theming (hyprlock/hypridle) | Explicitly deferred per PROJECT.md; don't pull back in via adjacent work |
| Full GTK4/libadwaita palette theming | Structurally unsupported upstream; scoped to dark/light + accent (THEME-03) |
| Hand-rolled custom OSD | SwayOSD solves this; reinventing burns time on solved edge cases |
| Quickshell/QML shell rewrite | Contradicts "extend, don't rewrite" constraint; replaces the whole stack |
| AI sidebar / assistant widgets | Not aligned with project goals |
| Re-theme on every wallpaper auto-cycle | Latency/flicker cost; re-theme only on explicit user action |
| Other distros / compositors | Personal Arch + Hyprland setup |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| THEME-01 | Phase 1 | Pending |
| THEME-02 | Phase 1 | Pending |
| THEME-03 | Phase 1 | Pending |
| THEME-04 | Phase 1 | Pending |
| THEME-05 | Phase 1 | Pending |
| THEME-06 | Phase 1 | Pending |
| PIPE-01 | Phase 1 | Pending |
| PIPE-02 | Phase 1 | Pending |
| PIPE-03 | Phase 1 | Pending |
| PIPE-05 | Phase 1 | Pending |
| SCAN-01 | Phase 1 | Pending |
| SCAN-02 | Phase 1 | Pending |
| PIPE-04 | Phase 2 | Pending |
| PIPE-06 | Phase 2 | Pending |
| CLEAN-01 | Phase 3 | Pending |
| CLEAN-02 | Phase 3 | Pending |
| INST-01 | Phase 3 | Pending |
| INST-02 | Phase 3 | Pending |
| INST-03 | Phase 3 | Pending |

**Coverage:**
- v1 requirements: 19 total (note: prior "18 total" was an off-by-one; there are 19 requirement IDs)
- Mapped to phases: 19
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-07*
*Last updated: 2026-07-07 after roadmap creation (traceability populated)*
