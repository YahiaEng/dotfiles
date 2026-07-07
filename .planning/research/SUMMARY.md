# Project Research Summary

**Project:** Arch Linux + Hyprland dotfiles — unified dynamic desktop theming
**Domain:** Linux desktop ricing / dotfiles infrastructure (matugen dynamic theming, stow-managed, Hyprland ecosystem)
**Researched:** 2026-07-07
**Confidence:** MEDIUM-HIGH (HIGH for all current-repo/live-machine findings via direct verification; MEDIUM for ecosystem/web-sourced claims, corroborated across 3+ independent reference projects)

## Executive Summary

This is a stow-managed Arch Linux + Hyprland dotfiles repo whose core value proposition is "one theme switch re-themes every visible app live, reproducibly from a fresh install." Research confirms the repo already has the correct architecture — the same five-layer pipeline (trigger → generation → distribution → application → reload → state) that every mature reference project (Omarchy, HyDE, end-4/dots-hyprland, caelestia, ML4W) converges on, with matugen as the industry-standard color engine. No rewrite is needed; the milestone's job is consolidation and root-cause bug fixing, not new architecture.

The single most important finding is a verified root cause for the long-standing "Thunar/Walker stuck white" bug: **the `adw-gtk3` theme package is not installed on the target machine** (`pacman -Q` confirms), despite being hardcoded in three config surfaces. GTK3 silently falls back to white Adwaita when a named theme is missing — no error, no log. The install script lists `adw-gtk3` as an AUR package, but that name does not exist; the correct package is `adw-gtk-theme` in the official `extra` repo, which is very likely why it silently never installed. Git history shows 8+ commits patching scripts for this symptom, none touching the dependency layer — a classic misdiagnosis loop that the roadmap must break by checking dependencies first.

Secondary structural risks: reload orchestration is duplicated (not shared) between `theme-switch.sh` and `theme-init.sh`, causing "fixed in one place, still broken in the other" regressions; matugen writes generated output through stow's folded directory symlinks directly into the git tree; `stow.sh` aborts on line one of a genuinely fresh install; and Walker's supported `hotreload_theme` option is unused, replaced by a fragile kill/restart dance that races the `elephant` backend daemon. All are cheap to fix once identified, and all of Milestone 2 (OSD, Walker menus, media widget, more themes) depends on fixing them first — every new surface built before the fix inherits the same broken pipeline.

## Key Findings

### Recommended Stack

The stack is fixed per PROJECT.md and research confirms it is the correct 2025/2026 standard — matugen + waybar + swaync + walker + swayosd is exactly what the leading reference rices use. The one correction is the theme package name, and the one structural fact is that Walker 2.x is a client/daemon pair (`walker` GTK4 frontend + `elephant` backend over a Unix socket), not the single binary older tutorials describe. Full details in `STACK.md`.

**Core technologies:**
- matugen-bin 4.1.0: wallpaper → Material You colors + per-app templates — de facto standard, already deployed, keep
- **adw-gtk-theme (extra repo, NOT the nonexistent AUR name `adw-gtk3`)**: the GTK3 theme every config here references — currently missing; installing it is the likely fix for white Thunar
- walker 2.16.2 + elephant 2.21.0: launcher frontend + backend daemon — must be upgraded together; any restart script must handle both
- waybar 0.15.0 / swaync 0.12.6: bar + notifications — standard signal-based reload (`SIGUSR2`, `swaync-client -rs`) already wired; add waybar's `reload_style_on_change: true` as belt-and-suspenders
- GSettings/dconf + xdg-desktop-portal-gtk: the Wayland-native GTK settings layer — verified already correctly configured; never use `xsettingsd` or `lxappearance` (X11-era dead ends)
- swayosd 0.3.1 (Milestone 2): volume/brightness OSD, CSS-themeable, slots into the existing matugen template pattern
- Waybar built-in `mpris` module (Milestone 2): now-playing widget backed by playerctl 2.4.1 (already installed) — prefer over custom scripts

### Expected Features

Reference-project consensus is that a rice reads as "broken" if any single visible app lags a theme switch — full live propagation is the entire premise, and everything in Milestone 2 depends on it. Full landscape in `FEATURES.md`.

**Must have (table stakes — Milestone 1):**
- One theme switch re-themes every visible app live, no relogin — currently broken (Walker, Thunar); waybar/swaync unverified
- GTK3 + GTK4 app theming via gsettings + portal + CSS overlays
- Static presets and matugen dynamic themes through one shared pipeline
- Reproducible fresh install (`install.sh` + stow) — currently fails on a fresh system
- Repo cleanup (wofi removal, dead configs, leftover `debug.txt`)

**Should have (competitive — Milestone 2):**
- SwayOSD volume/brightness indicators, themed via the pipeline
- Omarchy-style custom Walker menus (power/system/keybind) via elephant's Lua menu system
- Waybar native `mpris` now-playing widget
- Cohesive animation language (one shared bezier/duration across Hyprland + CSS apps)
- 1-2 additional static theme presets to prove the pipeline generalizes

**Defer (v2+):**
- Theme gallery / theme-patcher tooling; per-theme wallpaper sets
- Lock screen (hyprlock/hypridle) theming — explicitly deferred per PROJECT.md
- AI sidebar or Quickshell/QML shell rewrite — explicit non-goals (contradicts "extend, don't rewrite")

### Architecture Approach

The repo already implements the standard five-layer theming architecture; the weakness is that orchestration logic lives scattered inside the `hypr` stow package and is duplicated between the interactive switcher and the login-init script. The recommended (incremental) refactor is a dedicated `theme/` stow package with a shared library — `apply-theme.sh` as the single entrypoint, `lib/reload.sh` as the single reload fan-out, `lib/gtk.sh` for the GTK bridge — called by both the Walker picker and login autostart. Static preset data and matugen templates stay where they are but must produce an identical output contract (same canonical paths, same variable names). Full details in `ARCHITECTURE.md`.

**Major components:**
1. Trigger scripts (theme-switch, wallpaper-picker, theme-init) — collect intent only, never touch app configs
2. Generation (static `cp` OR `matugen image`) — mode-branching, converging on one output contract
3. Distribution contract — one generated color file per app (`colors.conf`/`colors.css`/literal-hex `style.css` for Walker), zero hardcoded hex in app configs
4. Reload orchestration — per-app strategy: live signal (hyprctl/SIGUSR2/swaync-client), settings-daemon (gsettings toggle), or restart-required (Walker, GTK3 apps); must live in exactly one shared script
5. State persistence — `~/.cache/current-theme` read at login

Key constraint (Pattern 4): GTK4/libadwaita apps ignore GTK3-style named themes — they only honor light/dark + accent via portal, plus `@define-color` overrides in `gtk-4.0/gtk.css` at startup. Scope the GTK4 sub-goal accordingly; it is not the same problem as GTK3.

### Critical Pitfalls

Top 5 of 8, all evidence-anchored to this repo/machine (full list in `PITFALLS.md`):

1. **Missing hardcoded theme package silently falls back to white** — `pacman -Q adw-gtk3` fails on this machine right now. Fix package name to `adw-gtk-theme`, install it, and add post-install verification of theming-critical packages to `install.sh` and a defensive check to the theme scripts. Check this FIRST, before touching any propagation script.
2. **Generated output written into the git tree via stow's folded symlinks** — matugen's `output_path`s resolve through whole-directory symlinks into the repo; generated colors get committed as if they were source. Redirect outputs to a non-stowed location (`~/.local/state/theme/`) and have app configs `@import` from there; at minimum `.gitignore` the generated leaves.
3. **`stow.sh` aborts on a genuinely fresh system** — unconditional `mv ~/.config/hypr/hyprland.conf ...` under `set -euo pipefail` fails when nothing has been stowed yet. Guard it, audit all state-assuming operations, and test in a disposable Arch VM (never just `--restow` on the dev machine).
4. **Walker restart races and stale caches** — `hotreload_theme` is unset, so the repo kill/relaunches Walker every switch, racing the `elephant` backend (zero-results symptom that looks like a theme bug). Enable `hotreload_theme = true` and keep walker/elephant lifecycles independent.
5. **GTK3/Thunar restart fragility** — Thunar is a D-Bus single-instance daemon; fixed `sleep 0.5` between quit and relaunch is a race. Replace with a bounded poll for process exit, and restart `tumbler` too.

Also notable: `GTK_THEME` hardcoded in 3 uncoordinated places (consolidate to `uwsm/env`); double reload — matugen per-template `post_hook`s AND `reload_all()` both fire the full reload set (pick one owner).

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Root-Cause Theming Fix (dependencies + pipeline consolidation)
**Rationale:** The verified root cause (missing theme package) plus the structural causes (duplicated orchestration, outputs-in-repo, Walker restart races) explain why 8+ prior fix commits never stuck. Everything else in both milestones depends on this working.
**Delivers:** `adw-gtk-theme` installed + verified; shared `apply-theme.sh`/`reload.sh` engine called by both interactive and login paths; matugen outputs moved out of the stow tree; Walker `hotreload_theme` enabled; hardened Thunar restart (poll, tumbler); single reload owner (post_hooks OR reload_all, not both); `GTK_THEME` consolidated to one source; waybar/swaync re-theme verified with a real Material You switch.
**Addresses:** "Walker/Thunar follow theme switches," "one switch updates everything live," "waybar/swaync verified" (all P1 table stakes)
**Avoids:** Pitfalls 1, 2, 3, 4, 7; Anti-Patterns 1-3 (per-entrypoint reload duplication, CSS-write-as-reload assumption, theme-name-as-palette conflation)

### Phase 2: Pipeline Parity Validation (static ↔ dynamic)
**Rationale:** PROJECT.md hard constraint — both modes must be one pipeline. Cheap once Phase 1's shared engine exists; catches mode-dependent divergences before new surfaces multiply them.
**Delivers:** Every static preset and Material You mode verified to produce identical canonical files (same paths, same variable names) and identical reload behavior; repeated-switch stress test (10x with Thunar/Walker open, 100% correct).
**Uses:** The Phase 1 shared engine; GTK Inspector (`GTK_DEBUG=interactive`) and dconf as diagnostics
**Implements:** Pattern 2 (mode-branching generator, converging distributor) as a checked invariant

### Phase 3: Repo Cleanup + Fresh-Install Verification
**Rationale:** Clean before verifying (avoid validating dead paths); verify after the fix (else a "verified" install just reproduces the white-theme bug). Sequenced, not parallel with Phase 1-2.
**Delivers:** wofi/dead configs/`debug.txt` removed; `stow.sh` fresh-run guards + per-package PASS/FAIL summary; post-install package verification block; full `install.sh` + `stow.sh` run succeeding unattended in a disposable Arch VM/container, producing the fully-themed desktop; `git status` clean after a theme switch.
**Avoids:** Pitfalls 5, 6 (fresh-install abort, partial stow-fold conflicts); "looks done but isn't" traps (restow-on-dev-machine ≠ fresh install)

### Phase 4: SwayOSD Indicators (Milestone 2)
**Rationale:** Lowest-complexity, highest-visibility add-on; first proof the fixed pipeline extends to new surfaces.
**Delivers:** swayosd installed + libinput-backend service enabled; `XF86Audio*`/`XF86MonBrightness*` keybinds; new `[templates.swayosd]` matugen entry + static-preset variants; reload entry added to the shared `reload.sh` (one line, per the Phase 1 design).
**Uses:** swayosd 0.3.1, existing named-color CSS convention

### Phase 5: Walker Menus + Media Widget (Milestone 2, parallel-safe)
**Rationale:** Mutually independent once base theming is fixed; both inherit theme automatically (menus are new invocations of the themed walker binary; the mpris module inherits waybar's colors.css). Zero new propagation work by design.
**Delivers:** Omarchy-style power/system menus (elephant Lua menus, keybind cheat-sheet optional); waybar native `mpris` now-playing module with click/scroll controls.
**Uses:** elephant menu provider (already enabled in config.toml), waybar built-in mpris + playerctld

### Phase 6: Polish + Theme Expansion (Milestone 2 close)
**Rationale:** Polish is applied last, across components that already work; new presets are cheap only once the pipeline is trustworthy (each premature preset is one more broken state).
**Delivers:** One shared animation/easing language across Hyprland + CSS apps; 1-2 new static presets exercising the full template fan-out (including the new swayosd/mpris surfaces).

### Phase Ordering Rationale

- **Dependency-first:** Every Milestone 2 surface reads colors from the pipeline that is currently broken — building them earlier ships more white-themed surfaces (FEATURES.md dependency graph is explicit on this).
- **Consolidate before extend:** The shared `reload.sh`/`apply-theme.sh` engine (Phase 1) is what makes Phases 4-6 one-line integrations instead of new drift risks; growth analysis shows the reload fan-out list is the first bottleneck.
- **Clean → verify → extend:** Repo cleanup precedes install verification (don't verify dead paths); install verification precedes add-ons (reproducibility is a stated core value, and the fresh path currently fails at its first meaningful line).
- **Root-cause discipline:** Phase 1 starts with the dependency check (Pitfall 1) precisely because git history proves script-level patching without it loops forever.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 1:** Verify empirically — does Walker's `hotreload_theme = true` actually remove the restart need? Does GTK3's `gtk.css` file-monitor make the Thunar restart optional? Does `dbus-update-activation-environment` truly eliminate relogin (PROJECT.md promise contradicted by leftover `debug.txt`)? These are 15-minute experiments, but they change the reload design.
- **Phase 4:** Confirm whether swayosd hot-reloads its own CSS or needs a service restart (build-order dependency for its reload.sh entry).

Phases with standard patterns (skip research-phase):
- **Phase 3:** Stow/install guards are ordinary shell hardening; test method (disposable VM) is known.
- **Phase 5:** elephant Lua menus and waybar mpris are well-documented, config-driven features.
- **Phase 6:** Hyprland animation config and CSS transitions are standard; presets are mechanical.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Ecosystem claims web-sourced (LOW-MEDIUM), but every claim about this machine's actual state directly verified (pacman/gsettings/dconf/systemctl/process list) — including the root-cause missing-package finding |
| Features | MEDIUM | Web-only research, but corroborated across 3+ independent reference projects (Omarchy, end-4, HyDE, caelestia, ML4W); repo-state claims verified directly |
| Architecture | MEDIUM-HIGH | Current repo shape HIGH (direct code inspection); "standard five-layer convergence" MEDIUM (two independent secondary sources); GTK4/libadwaita ceiling MEDIUM (two independent sources) |
| Pitfalls | HIGH | Every pitfall anchored to concrete evidence on this exact repo/machine (pacman output, symlink topology, git history, leftover debug artifact) |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- Waybar/swaync re-theming never actually tested end-to-end: mechanism is standard and low-risk, but verify with a real Material You switch during Phase 1/2, not assumed.
- Walker `hotreload_theme` effectiveness unknown: test before deciding whether the restart path can be retired (Phase 1 experiment).
- GTK3 live `gtk.css` monitoring: some GTK3 versions pick up user CSS changes without restart — verify before locking in permanent Thunar restarts (Phase 1 experiment).
- "No relogin required" promise vs. `debug.txt`'s "log out and back in" instruction: verify mid-session env propagation actually works (Phase 1).
- swayosd reload mechanism (hot-reload vs restart): 5-minute doc check during Phase 4 planning.
- Fresh-install unknowns: only discoverable in the disposable-VM run (Phase 3); expect 1-2 additional state-assumption bugs beyond the known `stow.sh` abort.

## Sources

### Primary (HIGH confidence)
- Direct target-machine verification — `pacman -Q/-Qi/-Si` (adw-gtk3 missing, all installed versions), `gsettings`/`dconf dump` (theme keys correct), `systemctl --user` (portal active), process list (walker+elephant running), `ls -la` symlink topology (folded stow dirs, partial Thunar state)
- Direct repo inspection — `theme-switch.sh`, `theme-init.sh`, `gtk-reload.sh`, `walker-restart.sh`, `walker-theme-gen.sh`, `matugen/config.toml`, `gtk/.config/gtk-{3,4}.0/*`, `walker/config.toml`, `uwsm/env*`, `install.sh`, `stow.sh`, git history (8+ failed fix commits), leftover `debug.txt`
- GNU Stow manual — tree-folding/splitting semantics

### Secondary (MEDIUM confidence)
- Hyprland Wiki (preconfigured setups, FAQ) and Hyprland discussions #339/#5867 — GTK theming under Wayland
- Walker official docs (walkerlauncher.com) — providers, `hotreload_theme`, elephant architecture
- Waybar wiki (mpris module) + Arch man pages; ErikReider/SwayOSD README (cross-checked against setup guides)
- ArchWiki — Dark mode switching
- GradienceTeam/Gradience #641 + gonwan.com GTK3/GTK4 article — libadwaita theming ceiling (two independent sources)
- xdg-desktop-portal-hyprland #171, Arch Forums GTK4/nwg-look thread — GTK4 constraints

### Tertiary (LOW confidence)
- DeepWiki summaries of basecamp/omarchy and JaKooLit/Hyprland-Dots theme systems — pipeline-shape corroboration, needs no further validation for roadmap purposes
- Web searches on matugen/pywal/waybar-reload/swaync/Omarchy features; Hans Schnedlitz blog on Walker Lua menus; Omarchy discussions #191/#2835 — validate specifics during phase research where load-bearing

---
*Research completed: 2026-07-07*
*Ready for roadmap: yes*
