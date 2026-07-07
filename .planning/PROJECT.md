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
- ✓ Walker follows theme switches (hardened restart + elephant health gate, widget-tree-correct CSS) — Validated in Phase 1
- ✓ Thunar follows theme switches (adw-gtk-theme installed, deferred daemon-restart watcher) — Validated in Phase 1
- ✓ GTK apps follow theme switches (GTK3 named-color palette; GTK4 dark + accent ceiling documented) — Validated in Phase 1
- ✓ Waybar and swaync re-theme correctly (incl. battery/backlight named-color fix) — Validated in Phase 1
- ✓ One theme switch updates every visible app instantly, no relogin — all ten targets human-verified — Validated in Phase 1
- ✓ Both static preset and matugen dynamic themes run through one `theme-apply` pipeline — Validated in Phase 1
- ✓ Full-repo bug scan (AUDIT.md) — Validated in Phase 1

### Active

<!-- Milestone 1: Fix the theming pipeline + full bug scan -->

- [ ] `install.sh` verified to produce a fully working themed setup on a clean Arch system (carry-over: code review found rsync missing from package lists and an orphan-cleanup abort — CR-01/CR-02 in 01-REVIEW.md, scoped to Phase 3 INST-01)
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
- **Current state:** Phase 1 complete (2026-07-07) — consolidated `theme-engine/` stow package owns rendering (matugen templates → `~/.local/state/theme/`) and the single reload fan-out; all ten targets (Hyprland, waybar, kitty, swaync, wlogout, Thunar/GTK3, GTK4, walker, yazi, vscodium) re-theme live in both static and dynamic modes, human-verified. Root cause of the historic stuck-white bug: the `adw-gtk3` package name in install.sh never existed — the real package is `adw-gtk-theme`.
- **Known deferred:** elephant provider gap (files/menus/providerlist/runner/websearch) and install.sh fresh-install breakers (missing rsync dep, orphan-cleanup abort) → Phase 3 INST-01.
- **Uncommitted work in tree:** modifications to hypr keybinds/config, install.sh, zshrc, current wallpaper; untracked claude-code-url-handler.desktop and screenshots directory.

## Constraints

- **Tech stack**: Arch Linux, Hyprland, uwsm, stow, matugen — fixed; this project fixes and extends the existing setup, not a rewrite
- **Compatibility**: Theme switching must keep supporting both static preset and matugen dynamic modes through one pipeline
- **Reproducibility**: Everything must be installable on a fresh Arch system via `install.sh` + stow — no manual host-only state

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Walker over wofi as launcher | Wofi abandoned; walker is the active launcher | ✓ Good — wofi configs to be removed |
| Fix bugs before expanding | Theming pipeline is the core value; building on a broken base compounds problems | ✓ Good — Phase 1 fixed root cause + consolidated engine |
| Full-repo audit in milestone 1 | Multiple past fix attempts failed; systematic scan beats spot-fixing | ✓ Good — AUDIT.md found the missing-package root cause; broke the patch loop |
| Consolidated theme-engine over per-app scripts | Three duplicated orchestrators kept drifting; one `theme-apply` entrypoint + state-dir contract ends the drift | ✓ Good — Phase 1 |

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
*Last updated: 2026-07-07 after Phase 1 completion*
