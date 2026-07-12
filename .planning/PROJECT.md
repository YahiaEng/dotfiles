# Arch + Hyprland Dotfiles

## What This Is

Personal dotfiles for an Arch Linux + Hyprland desktop, managed with GNU stow and installed on fresh systems via a custom `install.sh`. The centerpiece is a dynamic theming system: a consolidated `theme-engine` stow package with a single `theme-apply` entrypoint renders both static presets and matugen-generated (wallpaper-driven) themes through one pipeline into `~/.local/state/theme/`, propagating colors live to every desktop component — Hyprland, kitty, waybar, swaync, walker, thunar, GTK3/GTK4 apps, wlogout, yazi, vscodium. The whole setup reproduces unattended on a fresh Arch system (proven in a container gate + graphical VM).

## Core Value

One theme switch — static or dynamic — instantly and consistently re-themes the entire desktop, and the whole setup reproduces from scratch with one script.

## Current Milestone: v2.0 Desktop Expansion

**Goal:** Evolve the repaired v1.0 theming foundation into a complete, modern rice — fix the remaining reliability bugs, add the missing desktop utilities and menus, and extend the theme pipeline to every remaining surface.

**Target features:**
- Bug fixes: wlogout shutdown hang, hyprlock first-keystroke drops, kitty slow startup
- Redesigns: wlogout (modern-rice standard), hyprlock (themed surface + new look), wallpaper picker (Omarchy-level aesthetics + theme-aware wallpaper restriction)
- Utility scripts: screenshot full suite (capture/annotate/record), emoji picker, color picker, clipboard history, icon theme picker, nerd-font switcher
- Super-key walker menu (Omarchy-style, custom icons): Utilities, AI dashboard (launcher submenu + dedicated workspace), Game center, power menu, settings menu, keybind cheat-sheet
- Waybar: OLED-safe behavior (research auto-hide/transparency/pixel-shift), vertical (left) layout, media center (mpris — form per research), notification center access (swaync overlay)
- SwayOSD volume/brightness indicators, themed via the shared pipeline
- Theming expansion: more static presets incl. light themes; Zen browser follows theme switches
- Tech-debt carry-over: rsync explicit in install.sh PACMAN_PKGS

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
- ✓ wlogout Shutdown/Reboot complete reliably — `hyprshutdown --post-cmd` graceful compositor exit before the systemd power transition; D-22 5-cycle UAT clean (FIX-01) — Validated in Phase 4
- ✓ Hyprlock registers first keystrokes reliably — schema migration + `immediate_render`, plus `ignore_empty_input`/`check_text` ENTER-first gap closure; D-23 10-trial UAT clean (FIX-02) — Validated in Phase 4
- ✓ Kitty startup is fast — profiled (zprof/hyperfine), shell-init 641ms → 33.9ms via fish adoption (kitty-only, zsh retained as TTY fallback), nvm lazy-load, vendored omp theme (FIX-03) — Validated in Phase 4
- ✓ rsync explicit in install.sh PACMAN_PKGS (DEBT-01, v1.0 tech-debt closed) — Validated in Phase 4
- ✓ Light-mode pipeline: light presets re-theme the whole desktop (mode-aware `gtk.sh`, rendered settings.ini symlinks, `materialyou-light`), mode auto-detected from palette lightness 20/20 (THM-01/THM-02) — Validated in Phase 5
- ✓ Expanded preset lineup: 22 theme targets (15 dark incl. 9 Omarchy transcriptions + 5 canonical light + 2 Material You variants), all through one pipeline with light+dark parity fixtures (THM-03) — Validated in Phase 5
- ✓ Theme-aware wallpaper sets: folders 1:1 with palette names, auto-set on theme-apply with per-theme last-used memory; picker restricted per static theme with Ctrl-A browse-all (THM-04) — Validated in Phase 5
- ✓ Redesigned wallpaper picker: kitty-graphics previews, active marker, metadata line, pipeline-themed fzf colors (13th contract file) — Validated in Phase 5

### Active

<!-- Milestone v2.0 Desktop Expansion -->

- [ ] wlogout menu redesigned to modern-rice standards (reliability fixed in Phase 4)
- [ ] Hyprlock themed via the shared pipeline with a redesigned look (input reliability fixed in Phase 4)
- [ ] Utility scripts: screenshot full suite (capture/annotate/record + animations/feedback), emoji picker, color picker, clipboard history, icon theme picker (Thunar), nerd-font switcher (vscodium/kitty/GTK/etc.)
- [ ] Pressing $SUPER alone opens an Omarchy-style walker menu with custom icons: Utilities, AI dashboard (launchers + workspace), Game center, power, settings, keybind cheat-sheet
- [ ] Waybar: OLED-safe behavior, additional vertical (left) layout, media center (mpris), notification center access
- [ ] SwayOSD volume/brightness indicators, themed
- [ ] Zen browser follows theme switches

### Out of Scope

- Wofi — abandoned in favor of walker; configs removed in v1.0
- Supporting other distros/compositors — this is a personal Arch + Hyprland setup
- Custom AI assistant widgets/sidebars — v2.0's AI dashboard is launchers + a workspace, not built-in assistant UI
- Full GTK4/libadwaita palette theming — structurally unsupported upstream; dark/light + accent is the documented ceiling (validated in v1.0)
- Re-theme on every wallpaper auto-cycle — latency/flicker cost; re-theme only on explicit user action

## Current State

**v2.0 Phase 5 complete (2026-07-12): Light Mode Pipeline & Theme Presets** — 5 plans (incl. 1 gap closure), all four requirements (THM-01..04) verified: 18/18 UAT pass, verification passed, security review clean (14/14 threats closed). The pipeline is now fully mode-aware: 20 palette JSONs + 2 Material You variants render through one pipeline with light+dark parity fixtures (theme-parity 22 targets, 1190 checks, 0 failed); wallpaper sets are theme-scoped with a redesigned kitty-graphics picker; the legacy `themes/` stow package is deleted.

**v2.0 Phase 4 complete (2026-07-11): Reliability Fixes & Tech Debt** — 6 plans (incl. 2 gap closures), all four requirements (FIX-01/02/03, DEBT-01) verified: 4/4 UAT pass, verification passed, security review clean (19/19 threats closed), code review 0 critical. The base is de-risked for the redesign phases. Kitty now launches fish (33.9ms); zsh retained as TTY fallback.

**Shipped: v1.0 Theme Pipeline Repair (2026-07-09)** — 3 phases, 9 plans, 98 commits, 160 files (+13,636 / −1,176) over 3 days. All 19 v1 requirements verified; milestone audit passed.

- **Repo layout:** one stow package per app (`hypr/`, `kitty/`, `walker/`, `thunar/`, `gtk/`, `waybar/`, `swaync/`, `matugen/`, `theme-engine/`, `themes/`, `wallpapers/`, `uwsm/`, `vscodium/`, `yazi/`, `zshell/`, `fastfetch/`, `wlogout/`), plus `install.sh`, `stow.sh`, and `verify/` (container gate harness) at the root. The dead `wofi/` package was removed in v1.0.
- **Theming pipeline:** `theme-engine/` owns everything — `theme-apply <name>` renders static presets and Material You through the same matugen templates into `~/.local/state/theme/` (10-file output contract in `contract.json`), owns the single reload fan-out, and keeps generated output out of the git tree. `theme-doctor`, `theme-parity`, and `theme-stress-test` are rerunnable regression gates.
- **Reproducibility:** `install.sh` (flagged sections, hardware guards, hard-fail package verify) + `stow.sh` (idempotent, zero-prompt, first-boot theme seed) proven unattended in a podman container gate and a graphical VM with human sign-off.
- **Tech debt (non-blocking):** GTK3 windows stay stale until closed (accepted upstream limitation); theme-doctor session checks are graphical-tier-only by design. rsync PACMAN_PKGS debt closed in Phase 4. Advisory review items open: fisher bootstrap curl lacks `-f`, nvm first-run error noise on fresh installs, unguarded uv env source in .zshrc, Logout not wrapped like Shutdown/Reboot (04-REVIEW.md WR-01..04).

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
| `hyprshutdown --post-cmd` for Shutdown/Reboot; suspend/hibernate stay bare | Graceful compositor exit before the systemd power transition kills the FIX-01 hang class; suspend resumes into the same session so wrapping it would log the user out | ✓ Good — Phase 4; D-22 5-cycle UAT clean |
| Verify hyprlock options against the installed binary schema (`strings`) before relying on them | hyprlock 0.9.5 silently rejects unknown options — the original FIX-02 attempt shipped dead config; schema pre-check makes that failure mode impossible | ✓ Good — Phase 4; caught grace/no_fade_in removals, validated ignore_empty_input/check_text |
| Fish as kitty shell via `kitty.conf` only (no chsh); zsh retained for TTY | fish 32.7ms vs optimized zsh 95.5ms at full parity; kitty-only switch keeps TTY recovery on proven zsh if fish config ever breaks | ✓ Good — Phase 4; D-08 user decision, day-one node parity closed in 04-05 |
| Evidence-first perf fixes (zprof/hyperfine/fastfetch --stat before touching anything) | Prior guesses blamed fastfetch/zinit; profiling proved nvm sourcing (53.5%) + remote omp fetch were the real cost — fixes targeted only proven centers | ✓ Good — Phase 4; 641ms → 96ms zsh, then 33.9ms fish |
| Theme mode auto-detected from palette lightness (no override key) | A manual light/dark flag per palette would drift; background-luminance detection classified all 20 palettes correctly | ✓ Good — Phase 5; 20/20, D-06 |
| Dynamic `palettes/*.json` enumeration everywhere (no hardcoded theme lists) | theme-parity, stress test, and picker all drifted when presets were added; glob enumeration closes RESEARCH Pitfall 2 permanently | ✓ Good — Phase 5; adding a preset is now one JSON file |
| Wallpaper folders 1:1 with palette basenames, per-theme last-used state file | No mapping file to maintain; empty folders fall open to keep-current so new presets need no wallpapers up front | ✓ Good — Phase 5; D-09/D-11/D-12 |
| walker exit code 130 trusted as sole cancel signal in dmenu callers | walker 2.16.2 signals Esc via 128+SIGINT, never 0+empty; three-way branch (130 silent, other nonzero loud, 0 proceed) keeps hard failures visible | ✓ Good — Phase 5 gap closure; source-verified + hermetic checker 10/10 |

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
*Last updated: 2026-07-12 after Phase 5 (Light Mode Pipeline & Theme Presets)*
