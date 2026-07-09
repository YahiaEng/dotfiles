# Arch + Hyprland Dotfiles

## What This Is

Personal dotfiles for an Arch Linux + Hyprland desktop, managed with GNU stow and installed on fresh systems via a custom `install.sh`. The centerpiece is a dynamic theming system: a consolidated `theme-engine` stow package with a single `theme-apply` entrypoint renders both static presets and matugen-generated (wallpaper-driven) themes through one pipeline into `~/.local/state/theme/`, propagating colors live to every desktop component — Hyprland, kitty, waybar, swaync, walker, thunar, GTK3/GTK4 apps, wlogout, yazi, vscodium. The whole setup reproduces unattended on a fresh Arch system (proven in a container gate + graphical VM).

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
- ✓ Static presets and matugen dynamic themes proven one pipeline — identical file structure, variable name-sets, well-formed values across all 7 render targets (`contract.json` + `theme-parity`, 217/217 green) — Validated in Phase 2
- ✓ Repeated switching stays correct: 10 consecutive static↔dynamic switches with Thunar and Walker open leave every app correctly themed (`theme-stress-test` D-41 clean gate 140/140 + human visual sign-off) — Validated in Phase 2
- ✓ `install.sh` + `stow.sh` produce a fully working themed setup on a genuinely fresh Arch system — container gate PASS (run-20260709T060703Z, theme-parity 287/0) + graphical VM human sign-off — v1.0
- ✓ Repo cleanup: dead configs removed (wofi, debug.txt, stray screenshots, retired scripts); `git status` stays clean after theme switches — v1.0

### Active

<!-- Milestone 2 (expansion — to be refined via /gsd-new-milestone): -->

- [ ] OSD indicators for volume/brightness (e.g. swayosd), themed
- [ ] Custom walker menus in the style of Omarchy (power menu, settings, etc.)
- [ ] Media center showing currently playing media, accessible from waybar
- [ ] Visual polish: animations, cohesive styling across all apps
- [ ] More themes: additional static presets, better wallpaper-driven dynamic theming

### Out of Scope

- Wofi — abandoned in favor of walker; configs removed in v1.0
- Supporting other distros/compositors — this is a personal Arch + Hyprland setup
- Lock screen / idle management (hyprlock/hypridle) — not selected for expansion; can be revisited later
- Full GTK4/libadwaita palette theming — structurally unsupported upstream; dark/light + accent is the documented ceiling (validated in v1.0)
- Re-theme on every wallpaper auto-cycle — latency/flicker cost; re-theme only on explicit user action

## Current State

**Shipped: v1.0 Theme Pipeline Repair (2026-07-09)** — 3 phases, 9 plans, 98 commits, 160 files (+13,636 / −1,176) over 3 days. All 19 v1 requirements verified; milestone audit passed.

- **Repo layout:** one stow package per app (`hypr/`, `kitty/`, `walker/`, `thunar/`, `gtk/`, `waybar/`, `swaync/`, `matugen/`, `theme-engine/`, `themes/`, `wallpapers/`, `uwsm/`, `vscodium/`, `yazi/`, `zshell/`, `fastfetch/`, `wlogout/`), plus `install.sh`, `stow.sh`, and `verify/` (container gate harness) at the root. The dead `wofi/` package was removed in v1.0.
- **Theming pipeline:** `theme-engine/` owns everything — `theme-apply <name>` renders static presets and Material You through the same matugen templates into `~/.local/state/theme/` (10-file output contract in `contract.json`), owns the single reload fan-out, and keeps generated output out of the git tree. `theme-doctor`, `theme-parity`, and `theme-stress-test` are rerunnable regression gates.
- **Reproducibility:** `install.sh` (flagged sections, hardware guards, hard-fail package verify) + `stow.sh` (idempotent, zero-prompt, first-boot theme seed) proven unattended in a podman container gate and a graphical VM with human sign-off.
- **Tech debt (non-blocking, carried into v2):** rsync not explicit in install.sh PACMAN_PKGS (arrives transitively); GTK3 windows stay stale until closed (accepted upstream limitation); theme-doctor session checks are graphical-tier-only by design.

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
| Restart-based reload for Walker/Thunar (no hot-reload) | walker 2.16.2 has no hotreload key; GTK3 has no live CSS reload API — hardened restarts with health gates beat imaginary APIs | ✓ Good — Phase 1; stale-until-closed caveat accepted |
| `contract.json` as single source of truth for the 10-file output contract | One manifest consumed by theme-doctor and theme-parity prevents checker/renderer drift | ✓ Good — Phase 2; parity 217/0 dev, 287/0 container |
| Two-tier INST-03 gate (container + graphical VM) | Container proves unattended install/stow/parity headless; VM proves the visual result — neither alone suffices | ✓ Good — Phase 3; gate runs caught 6 real fresh-install defects |
| Generated theme output lives in `~/.local/state/theme/`, never in git | Keeps `git status` clean after every switch; repo holds templates, not artifacts | ✓ Good — Phase 1/3; enforced by git-clean invariant in stress test |
| Headless guard in reload fan-out | `swaync-client -rs` hangs forever without a session bus; early-return keeps container installs unattended | ✓ Good — quick 260709-buf |

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
*Last updated: 2026-07-09 after v1.0 milestone*
