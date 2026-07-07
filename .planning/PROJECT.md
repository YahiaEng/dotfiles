# Arch + Hyprland Dotfiles

## What This Is

Personal dotfiles for an Arch Linux + Hyprland desktop, managed with GNU stow and installed on fresh systems via a custom `install.sh`. The centerpiece is a dynamic theming system: custom scripts switch between static pre-configured themes and matugen-generated (wallpaper-driven) themes, propagating colors to every desktop component — Hyprland, kitty, waybar, swaync, walker, thunar, GTK apps, wlogout.

## Core Value

One theme switch — static or dynamic — instantly and consistently re-themes the entire desktop, and the whole setup reproduces from scratch with one script.

## Requirements

### Validated

<!-- Existing capabilities that work today. -->

- ✓ Hyprland session with uwsm optimizations — existing
- ✓ Stow-based config application (`stow.sh`) — existing
- ✓ `install.sh` installs packages and applies dotfiles on fresh Arch — existing (needs re-verification)
- ✓ Theme switching updates kitty and Hyprland (borders etc.) — existing
- ✓ Matugen dynamic theme generation from wallpaper — existing (partial propagation)
- ✓ Walker application launcher, swaync notifications, waybar bar, thunar + yazi file managers, wlogout — existing

### Active

<!-- Milestone 1: Fix the theming pipeline + full bug scan -->

- [ ] Walker follows theme switches (currently stuck on default white theme)
- [ ] Thunar follows theme switches (currently stuck on default white theme)
- [ ] GTK apps generally follow theme switches (light/dark + colors)
- [ ] Waybar and swaync verified to re-theme correctly (state currently unknown)
- [ ] One theme switch updates every visible app instantly — no relogin/restart required
- [ ] Both static preset themes and matugen dynamic themes work through the same pipeline
- [ ] Full-repo bug scan: theme pipeline, install.sh, hyprland config, stow setup — all components audited
- [ ] `install.sh` verified to produce a fully working themed setup on a clean Arch system
- [ ] Repo cleanup: dead configs removed (wofi, debug.txt, stray screenshots), stow applies cleanly

<!-- Milestone 2 (expansion — refined after milestone 1): -->

- [ ] OSD indicators for volume/brightness (e.g. swayosd), themed
- [ ] Custom walker menus in the style of Omarchy (power menu, settings, etc.)
- [ ] Media center showing currently playing media, accessible from waybar
- [ ] Visual polish: animations, cohesive styling across all apps
- [ ] More themes: additional static presets, better wallpaper-driven dynamic theming

### Out of Scope

- Wofi — abandoned in favor of walker; its configs will be removed, not fixed
- Supporting other distros/compositors — this is a personal Arch + Hyprland setup
- Lock screen / idle management (hyprlock/hypridle) — not selected for expansion; can be revisited later

## Context

- **Repo layout:** one stow package per app (`hypr/`, `kitty/`, `walker/`, `thunar/`, `gtk/`, `waybar/`, `swaync/`, `matugen/`, `themes/`, `wallpapers/`, `uwsm/`, `vscodium/`, `yazi/`, `zshell/`, `fastfetch/`, `wlogout/`, `wofi/` (dead)), plus `install.sh` and `stow.sh` at the root.
- **Theming pipeline:** matugen (`matugen/.config/matugen/config.toml` + templates) generates colors from wallpaper; custom scripts toggle between static preset themes and dynamic matugen themes.
- **Known broken:** walker and thunar ignore theme switches entirely (stuck white). Recent git history shows multiple fix attempts ("debug: white theme", "fix: gtk themes", "fix: walker and thunar not responding to theme changes") — the root cause is likely in GTK theme propagation and has resisted per-app patching.
- **Known working:** kitty and Hyprland re-theme correctly.
- **Unknown:** waybar and swaync theming state — must be verified during the bug scan.
- **Uncommitted work in tree:** modifications to hypr keybinds/config, install.sh, zshrc, current wallpaper; untracked claude-code-url-handler.desktop and screenshots directory.

## Constraints

- **Tech stack**: Arch Linux, Hyprland, uwsm, stow, matugen — fixed; this project fixes and extends the existing setup, not a rewrite
- **Compatibility**: Theme switching must keep supporting both static preset and matugen dynamic modes through one pipeline
- **Reproducibility**: Everything must be installable on a fresh Arch system via `install.sh` + stow — no manual host-only state

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Walker over wofi as launcher | Wofi abandoned; walker is the active launcher | ✓ Good — wofi configs to be removed |
| Fix bugs before expanding | Theming pipeline is the core value; building on a broken base compounds problems | — Pending |
| Full-repo audit in milestone 1 | Multiple past fix attempts failed; systematic scan beats spot-fixing | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-07-07 after initialization*
