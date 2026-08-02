# Arch + Hyprland Dotfiles

## What This Is

Personal dotfiles for an Arch Linux + Hyprland desktop, managed with GNU stow and installed on fresh systems via a custom `install.sh`. The centerpiece is a dynamic theming system: a consolidated `theme-engine` stow package with a single `theme-apply` entrypoint renders both static presets and matugen-generated (wallpaper-driven) themes through one pipeline into `~/.local/state/theme/`, propagating colors live to every desktop component — Hyprland, kitty, waybar, swaync, walker, thunar, GTK3/GTK4 apps, wleave, SwayOSD, Zen, the AGS media applet, yazi, vscodium.

On top of that foundation sits a full desktop: 22 theme targets across dark, light and Material You; a four-layout waybar; a $SUPER-tap walker menu wrapping utilities, power, settings, an AI dashboard, a game center and a keybind cheat-sheet; a screenshot/record suite; emoji, color, clipboard, icon-theme and font pickers; and an AGS v3 media card with a cava audio-reactive underlay. The whole setup reproduces unattended on a fresh Arch system (proven in a container gate + graphical VM).

## Core Value

One theme switch — static or dynamic — instantly and consistently re-themes the entire desktop, and the whole setup reproduces from scratch with one script.

## Current Milestone: v3.0 Quickshell Foundation & Motion Language

**Goal:** Establish Quickshell as the shell toolkit and a spring-based motion language shared by every surface, then ship the net-new widgets a top-tier rice has and this one does not — without retiring anything that works today.

**Target features:**
- Quickshell viability gate — human-clicked proof on Hyprland 0.56.0 (layer-shell, pointer input, focus, multi-monitor, hot reload) before anything is built on the toolkit
- Unified design-token pipeline — colour *and* motion from one source, rendered to QML, GTK4 CSS and Hyprland targets. **Baseline: Material 3 Expressive named duration + bezier tokens** (the approach both end-4 and Caelestia actually ship, source-verified, and the vocabulary wleave's `md3_decel` cascade already uses). **Stretch: spring physics** (mass/stiffness/damping) layered on for QML surfaces only, attempted after the token pipeline works — not a blocker for any other phase
- Motion retrofit — the language applied across Hyprland, waybar, swaync, walker, SwayOSD, wleave and the AGS media card
- Dashboard drawer — calendar, weather, system resources, media controls, quick-toggle grid; the first real QML surface
- Audio + connectivity panels — per-app volume mixer, wifi picker, bluetooth manager (displacing pavucontrol / nm-connection-editor / blueman from the daily workflow)
- Workspace overview — full-screen live window thumbnails; **research-gated** on the hyprexpo / `hyprland-toplevel-export-v1` plugin question
- Ambient extras — animated wallpaper, dynamic-cursors; explicitly the first thing cut if the milestone runs long

**Scope boundary — no retirements in v3.0.** waybar, swaync, SwayOSD, wleave, walker/elephant and the AGS media card all keep working throughout. QML only ever *adds* surfaces this milestone. Migrating and retiring the existing shell is v4.0, decomposed deliberately so that no milestone leaves the desktop unusable.

**Phase numbering** continues from v2.0's Phase 10 — v3.0 starts at Phase 11.

**Carried in as candidate scope** (deferred from v2.0, see `milestones/v2.0-REQUIREMENTS.md`):
- **ICON-BROWSE** — browse and install *new* icon themes from within the picker (repo/AUR discovery); v2.0 shipped apply-only
- **POLISH-01** — subsumed by this milestone's motion language, which supersedes it
- `keybind-doctor`'s `hyprctl binds -j` parsing fix for Hyprland 0.56.0
- Phase 4 advisory review items `04-REVIEW.md` WR-01..04
- The container-tier reproducibility rerun (D-34/D-36), unblocked by the v2.0 push

## Requirements

### Validated

<!-- Existing capabilities that work today. -->

- ✓ Hyprland session with uwsm optimizations — existing
- ✓ Stow-based config application (`stow.sh`) — existing
- ✓ `install.sh` installs packages and applies dotfiles on fresh Arch — existing (needs re-verification)
- ✓ Theme switching updates kitty and Hyprland (borders etc.) — existing
- ✓ Matugen dynamic theme generation from wallpaper — existing (partial propagation)
- ✓ Walker application launcher, swaync notifications, waybar bar, thunar + yazi file managers, wleave power menu — existing (power menu migrated wlogout → wleave in Phase 9)
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
- ✓ wlogout redesigned as a compact centre bar with Nerd Font glyphs, colors live from the pipeline (WLOG-01) — Validated in Phase 6
- ✓ Hyprlock redesigned and pipeline-themed: native $TIME12 clock, now-playing/battery labels, `hyprlock-colors.conf` render target (LOCK-01) — Validated in Phase 6
- ✓ SwayOSD volume/brightness/caps-lock indicators, themed and bound to media keys (server autostarted, libinput backend enabled system-wide) (OSD-01) — Validated in Phase 6
- ✓ Zen browser follows theme switches via matugen `userChrome.css` + profile-path resolution (THM-05) — Validated in Phase 6
- ✓ Screenshot suite: region/window/full capture → satty annotate → save+copy, plus region/monitor recording with GIF export and audio-consent picker (SHOT-01/02/03) — Validated in Phase 6
- ✓ Utility pickers: emoji, color, clipboard history (100-item cap + session-end/manual wipe), icon-theme (live to Thunar/GTK), nerd-font switcher (UTIL-01..05) — Validated in Phase 6
- ✓ Theme-doctor CSS-parse regression guard: 6 GTK3 + 3 GTK4 surfaces asserted non-empty provider + zero fatal errors, proven to fail on a poisoned sheet — Validated in Phase 6
- ✓ $SUPER-tap opens an Omarchy-style walker menu — Utilities, AI dashboard (launchers + workspace), Game center, power, settings, searchable keybind cheat-sheet — as elephant TOML providers; app launcher moved to Super+Space, ~48-bind regression sweep clean (MENU-01..07) — Validated in Phase 7
- ✓ Waybar OLED-safe: single-owner `waybar-visibility.sh` fed by hypridle, a Hyprland fullscreen socket2 watcher, gaming-mode and a keybind; translucent low-luminance styling (BAR-01) — Validated in Phase 8
- ✓ Four waybar layouts (full/athena/floating/vertical) composed from one shared `modules.jsonc` + `waybar-modules.css`, each redesigned as its own design flow and user-approved on sight under light, dark and dynamic; guarded by `waybar-equivalence-check` + `waybar-design-lint` in theme-doctor (BAR-03) — Validated in Phase 8
- ✓ Notification center opens from a waybar button (swaync overlay: view, clear, interact), with volume/brightness sliders and an anti-drift toggle grid sharing state with the Super-key menu (BAR-05) — Validated in Phase 8
- ✓ BAR-02 pixel-shift mitigation descoped with a reproducible evidence artifact — waybar's only CSS-actuation path (SIGUSR2) measurably flashes and reflows, killing any CSS-based approach before the 2px question is reached — Validated in Phase 8
- ✓ Power menu on wleave 0.7.1 (GTK4): six per-action hue capsules on `gtk4-layer-shell`, hover/focus name reveal, md3_decel entrance cascade, compositor-layerrule fade exit; GTK3 whole-stylesheet-discard failure class structurally eliminated, `wlogout/` package deleted (WLOG-01 re-delivered) — Validated in Phase 9
- ✓ AGS v3 media card replaces the eww popup: working transport/seek/volume/player-switcher over the unchanged MPRIS bash backend, garuda-style blurred-art overlay with a cava audio-reactive underlay, matugen-themed with runtime `sass` + `apply_css` hot reload, reproducible via install.sh + stow (MEDIA-01..04) — Validated in Phase 10
- ✓ The Hyprland config runs on Lua ahead of the 0.57 hyprlang removal: seven `config/*.lua` modules behind `hyprland.lua`, behavioural equivalence proven against a pre-migration `hyprctl` baseline via `hypr-equivalence-check`, and the theme-engine's two Hyprland-format outputs collapsed into one generated `lua-table` entry (contract 31→29). Legacy `.conf` tree retired; survived a cold boot (MAINT-04) — Validated in Phase 13.1
- ✓ Per-app volume mixing, wifi and bluetooth handled by themed in-shell panels — three panels on one shared `PanelDialog` frame (audio mixer, wifi picker, bluetooth manager), each with the dashboard's animated gradient rim, MD3-paced indeterminate sweeps, row-scoped failure copy and an Advanced escape hatch to pavucontrol/nm-connection-editor/blueman. Wifi joins hidden networks and keeps wrong-password handling inside the panel (nm-applet's secret agent suppressed under stow); bluetooth renders an rfkill-blocked adapter as disabled-with-reason instead of a control that cannot work. 7/7 UAT against real hardware — a real AP, a real hidden network, and a real Bluetooth peer (PANEL-01..06) — Validated in Phase 15 *(with acknowledged gaps: no security review, verifier not re-run over the gap-closure round — see `15-VERIFICATION.md`)*

### Active

<!-- Current scope. Building toward these. REQ-IDs assigned in REQUIREMENTS.md. -->

- [ ] Quickshell proven viable on this Hyprland build before any feature is built on it
- [ ] One token source renders colour + motion to QML, GTK4 CSS and Hyprland bezier without drift
- [ ] Every existing surface animates with the shared spring-derived motion language
- [ ] A dashboard drawer surfaces calendar, weather, resources, media and quick toggles
- [ ] A full-screen workspace overview shows live window thumbnails (research-gated)
- [ ] Ambient extras: animated wallpaper and dynamic cursors (cut candidate)

### Out of Scope

- Wofi — abandoned in favor of walker; configs removed in v1.0
- Supporting other distros/compositors — this is a personal Arch + Hyprland setup
- Custom AI assistant widgets/sidebars — the AI dashboard shipped as launchers + a workspace, not built-in assistant UI
- Full palette theming of *third-party* GTK4/libadwaita apps — structurally unsupported upstream; dark/light + accent is the documented ceiling (validated in v1.0). **Scope narrowed after v2.0:** this never applied to GTK4 surfaces this repo authors itself — Phase 9's wleave and Phase 10's AGS applet both take the full matugen palette through their own stylesheets.
- Re-theme on every wallpaper auto-cycle — latency/flicker cost; re-theme only on explicit user action
- ~~Quickshell/QML custom shell rewrite — contradicts "extend, don't rewrite"; end-4/Caelestia patterns stay aspirational~~ — **REVERSED 2026-07-26 at v3.0 scoping.** Deliberate decision, not drift: the end-4/Caelestia surfaces the project actually wants (shaped/cutout surfaces, spring-physics panels, a full-screen overview) are structurally unreachable from GTK4 CSS, and Phase 8's own BAR-02 evidence artifact already proved waybar's CSS/SIGUSR2 model cannot actuate them. The "extend, don't rewrite" principle is preserved by *decomposing* the rewrite instead of abandoning it: v3.0 adds QML surfaces only and retires nothing, so the working desktop is never put at risk; migration of existing surfaces is deferred to v4.0. Superseded by the v3.0 milestone goal above.
- **Retiring any existing surface during v3.0** — waybar, swaync, SwayOSD, wleave, walker/elephant and the AGS media card all stay live this milestone. Retirement without accumulated QML mileage is how the eww mistake happened; v4.0 owns migration.
- Rebuilding walker/elephant in QML — deferred, undecided. Phase 7 invested 8 plans in the menu tree as elephant TOML providers; whether shell consistency justifies rebuilding fuzzy search, app indexing, clipboard and calc providers is a v4.0+ question.
- Full GUI settings app — the settings menu launches existing tools; no custom settings UI (carried from v2.0 requirements)
- Gaming-mode session switching — the game center is a launcher submenu, not a session manager (carried from v2.0 requirements)
- eww as a widget toolkit — retired in Phase 10 after its popup was proven unable to deliver pointer input on this eww 0.6.0 / Hyprland 0.55.4 build; AGS v3 (GTK4) is the widget toolkit going forward
- **QS-03 — per-screen Quickshell surface fan-out (rendering correctly across every connected monitor, including one hotplugged after startup)** — **accepted as a permanent limitation, 2026-07-26 (D-13, one-way).** The fan-out was re-attempted in Phase 12 with a checked-in `qmldir` (closing the FM1 scanner race) and a per-screen `LazyLoader` under `Variants`, tried in two structurally distinct arrangements under an explicit bounded budget plus an escape-hatch spike — all recorded in `12-QS03-EVIDENCE.md`. Both arrangements reproduced an FM2-class multi-screen surface-creation failure on quickshell 0.3.0-2, re-proven across a real session restart. quickshell 0.3.0-2 is the latest version in the official `extra` repo, so "wait for upstream" was not an available option. The host has one physical monitor (`DP-1`), so the fan-out is unexercised in daily use. **Consequence: Phase 16's full-screen per-monitor overview inherits a shell root that cannot fan out and must solve this itself.**

## Current State

**In progress: v3.0 Quickshell Foundation & Motion Language** — Phase 11 (Quickshell viability gate), Phase 12 (Unified Design-Token Pipeline), Phase 13 (Motion Retrofit & Existing-Surface Sweep), **Phase 13.1 (Hyprland Lua Config Migration, complete 2026-07-28)** and **Phase 14 (Dashboard Drawer, complete 2026-08-01)** done.

**Phase 14** shipped the milestone's first real QML surface: a Super+D four-tab swipeable drawer (Dashboard / Media / Performance / Weather) that reads state the desktop already owns rather than forking it — one MPRIS reader shared with waybar and the AGS card, quick-toggles executing byte-identical scripts to swaync's own grid, zero-idle backends that run no timer or subprocess while the drawer is dismissed. 10 plans, DASH-01..10. Two requirements were minted mid-phase at the human's direction rather than deferred: DASH-09 (a fifth GPU dial, from 14-09's render gate) and DASH-10 (an animated gradient border matching Hyprland's own window border, raised during UAT). DASH-10 needed a token-pipeline change — `lib/motion.sh` now emits the `indicators` bucket to QML, so `border-rotate` is readable there and the drawer's rim stays in step with `borderangle` at every motion scale. Four defects were found and fixed after execution, three of them by the phase-close gates rather than by testing: `quickshell-doctor`'s eight surface summons were silently dead under the Lua config (making one check unpassable and another vacuous), `hypr-equivalence-check` failed spuriously at any non-`normal` motion preset, the calendar chevrons were unclickable behind a fill-parent wheel `MouseArea`, and the Weather tab visibly compressed into place on entry (content re-laid-out 15× per transition). Qt was also found auto-selecting the basic render loop — `QSG_RENDER_LOOP=threaded` took drawer animation from ~60fps to the panel's 165Hz. Gates at close: `theme-doctor` 239/0, `theme-parity` 2608/0, `motion-lint` 85/0, `quickshell-doctor` 13/0, `keybind-doctor` 14/0. UAT 8/8, security 44/45 closed with `threats_open: 0`.

**Phase 13.1** moved the compositor off hyprlang ahead of its 0.57 removal, in 10 plans built around a falsifiable gate rather than a hand-diff: `hypr-equivalence-check` snapshots `hyprctl binds/animations/getoption` and diffs a live session against a committed pre-migration baseline. The cutover is proven (80/80 binds, `options.jsonl` and `animations.json` both PASS under a theme-matched run; the sole remaining diff is two documented `bindm` mouse-field records), survived a genuine cold boot, and the legacy `.conf` tree plus its emitters are retired — contract 31→29, one `lua-table` entry, hyprlock's own `hypr-vars` entry deliberately retained since it has a separate parser. Two Lua-only hazards were found and closed empirically rather than assumed: Lua 5.5 randomizes string-hash seeds so `pairs()` curve registration was non-deterministic per boot (now sorted), and `hl.dsp.dpms` ignores bare-string arguments and merely toggles (`{action="on"}` table form required). Gates at close: `theme-doctor` 206/0, `theme-parity` 2608/0, `motion-lint` 55/0 (+10/0 self-test), `keybind-doctor` 14/0, `theme-stress-test` 162/0. Known debt: waybar 0.15.0's compiled-in workspace-click dispatch is dead until Quickshell replaces it (upstream PR #5013 postdates the release), and `quickshell-doctor` retains 8 legacy dispatch sites.

Phase 12 landed the one-source token pipeline: `theme-engine/motion.json` is the single hand-authored motion source, `lib/motion.sh` renders it to QML, GTK4 CSS and Hyprland in one `theme-apply` run, `motion-switch.sh` gives it a runtime normal/reduced/off axis, and `motion-lint` (folded into `theme-doctor`) refuses any surface hand-rolling a raw or dangling motion value. Quickshell gained live `Colours`/`Motion` singletons reading `~/.local/state/theme/` plus a token inspector. TOKEN-01..05 complete; TOKEN-06 satisfied by a recorded "not adopted" verdict; QS-03 dropped to Out of Scope under D-13. Gates at close: `theme-doctor` 180/0, `theme-parity` 1985/0, `motion-lint` 37/0 (+10/0 self-test), `quickshell-doctor` 13/0.

**Shipped: v2.0 Desktop Expansion (2026-07-25)** — 7 phases (4-10), 64 plans, 444 commits, 488 files (+57,232 / −3,151) over 16 days. All 36 v2 requirements verified; every phase closed `verification_status: passed`; open-artifact audit clear at close.

**Shipped: v1.0 Theme Pipeline Repair (2026-07-09)** — 3 phases, 9 plans, 98 commits, 160 files (+13,636 / −1,176) over 3 days. All 19 v1 requirements verified; milestone audit passed.

- **Repo layout:** one stow package per app (`ags/`, `hypr/`, `kitty/`, `walker/`, `elephant/`, `thunar/`, `gtk/`, `waybar/`, `swaync/`, `swayosd/`, `matugen/`, `theme-engine/`, `wallpapers/`, `uwsm/`, `vscodium/`, `yazi/`, `fish/`, `zshell/`, `fastfetch/`, `wleave/`), plus `install.sh`, `stow.sh`, and `verify/` (container gate harness) at the root. Removed along the way: `wofi/` (v1.0), `themes/` (Phase 5), `wlogout/` (Phase 9), and eww's media popup (Phase 10).
- **Theming pipeline:** `theme-engine/` owns everything — `theme-apply <name>` renders static presets and Material You through the same matugen templates into `~/.local/state/theme/`, owns the single reload fan-out, and keeps generated output out of the git tree. 22 theme targets (15 dark, 5 light, 2 Material You), mode auto-detected from palette lightness. `theme-doctor`, `theme-parity`, `theme-stress-test`, `waybar-equivalence-check`, `waybar-design-lint` and `hypr-equivalence-check` (folded into `theme-doctor`, guarded on a live session) are rerunnable regression gates.
- **Desktop surfaces:** four-layout waybar (full/athena/floating/vertical) with OLED-safe single-owner visibility; wleave power menu (GTK4); hyprlock; SwayOSD; swaync control center; AGS v3 media applet with cava underlay; Zen browser; $SUPER-tap walker/elephant menu tree; screenshot + emoji/color/clipboard/icon/font utility suite.
- **Reproducibility:** `install.sh` (flagged sections, hardware guards, hard-fail package verify) + `stow.sh` (idempotent, zero-prompt, first-boot theme seed) proven unattended in a podman container gate and a graphical VM with human sign-off.
- **Tech debt (non-blocking, carried into v3.0):**
  - GTK3 windows stay stale until closed (accepted upstream limitation); theme-doctor session checks are graphical-tier-only by design.
  - Advisory review items open from Phase 4 (`04-REVIEW.md` WR-01..04): fisher bootstrap curl lacks `-f`, nvm first-run error noise on fresh installs, unguarded uv env source in `.zshrc`, Logout not wrapped like Shutdown/Reboot.
  - Stale `eww-media-popup` layerrules remain in `hypr/.config/hypr/config/windowrules.conf` (lines 259, 272) after Phase 10 retired that window — inert (no client ever claims the namespace) but dead config.
  - The container-tier D-34/D-36 reproducibility rerun has been deferred since Phase 7 pending push authorization; it is unblocked as of the v2.0 push.
  - `theme-stress-test` cannot reach a full 10/10 run while `wallpapers/Pictures/Wallpapers/current.jpg` is a tracked symlink: `lib/wallpaper.sh:65` repoints it on every static theme switch, dirtying the tree and tripping `theme-doctor`'s clean-tree invariant (both checks date to phase 03-03). Found by actually running the committed harness at Phase 12 close — switches 1-4 passed, #5 (`dracula`) failed. Root cause and two fix options in WINDOWS.md #9; owned by Phase 13.

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
| Every themed surface consumes the palette via `@import` from `~/.local/state/theme/`, never a copied file | One render target per surface, zero hex literals in repo stylesheets; adding a surface is a template + contract entry, not a new copy path | ✓ Good — Phase 6; scaled cleanly to 22 targets and to wleave/AGS later |
| Menus built as elephant TOML providers rather than a separate menu tool | Walker's own backend already enumerates providers; a second tool would need its own theming, keybinds and install path | ✓ Good — Phase 7; a stow-parity gap that hid three menus is now closed by a self-healing guard |
| Bare $SUPER tap opens the menu; app launcher moved to Super+Space | Resolved default bind-shadowing on Hyprland 0.55.4 by live keypress testing rather than assumption | ✓ Good — Phase 7; ~48-bind regression sweep found zero regressions |
| Four waybar layouts composed from one shared `modules.jsonc` + `waybar-modules.css` via include/@import | Four copy-pasted layout files drifted constantly; a mechanical resolved-config equivalence gate proves zero behavior change on every edit | ✓ Good — Phase 8; `waybar-equivalence-check` 4/4 |
| BAR-02 pixel-shift descoped with a written evidence artifact instead of silently dropped | Waybar's only CSS-actuation path (SIGUSR2) measurably flashes and reflows — mechanism-independent, so it kills the approach before the 2px question is reached; the requirement itself permitted evidence-backed descope | ✓ Good — Phase 8; reproducible gate table + luminance measurement in `08-BAR-02-EVIDENCE.md` |
| A human render-and-look gate is load-bearing, not a formality | Phase 6 and Phase 8 both shipped visibly broken surfaces through fully green automated gates (CSS parse, shellcheck, theme-doctor, token resolution). Machines prove tokens resolve; only a human judges whether it reads correctly | ✓ Good — adopted Phase 8, formalized Phase 9/10; caught a "complete failure" bar and a real GTK4 assertion-failure bug an easing curve was triggering |
| Migrate to GTK4 for the failure class, not for a feature | GTK3 discards an entire stylesheet on one invalid rule; GTK4 drops only the offending rule. wleave was chosen because it makes WLOG-01 structurally impossible — explicitly *not* to gain per-surface blur, which Hyprland's layerrule set cannot provide to any client | ✓ Good — Phase 9; failure class eliminated, blur expectation correctly pre-empted |
| Fail-fast input-viability gate before building on an unproven toolkit | eww's popup was confirmed unable to deliver pointer input on this build only after a full feature was built on it. Phase 10 put a human-clicked test button at plan 2 with authority to STOP the phase | ✓ Good — Phase 10; gate passed on first click and de-risked the remaining four plans |
| Consumer-check before retiring a toolkit | eww was removed only after grepping every defwindow, script, autostart entry, matugen template and layerrule for live consumers | ⚠ Revisit — Phase 10; the check missed two inert `eww-media-popup` layerrules still in `windowrules.conf` |
| New stow packages must register in `stow.sh` in the same commit that creates them | `ags/` was fully populated but unregistered, so the applet only worked on this host via a manual `stow ags`; a fresh clone would not have reproduced it | ✓ Good — caught by Phase 10 verification and fixed in the same commit; matches the precedent set by eww, elephant and swayosd |
| Adopt Quickshell as the shell toolkit, reversing the v2.0 Out-of-Scope entry | The surfaces the project wants are structurally unreachable from GTK4 CSS — Phase 8's BAR-02 evidence already proved waybar's only actuation path cannot deliver them. Reversing explicitly, with the rewrite decomposed so v3.0 retires nothing, beats either abandoning the goal or letting scope drift into a rewrite unannounced | ✓ Good — Phase 11 viability gate: **PASS**. QS-02's human-clicked pointer/keyboard/dismiss gate passed on first attempt; workspace-overview screencopy feasibility also confirmed. v3.0 continues as roadmapped; Phases 12-17 stand. Full gate table, findings and caveats in `11-QUICKSHELL-EVIDENCE.md` |
| MD3 Expressive tokens are the motion baseline; spring physics is a stretch enhancement for QML only | Initial scoping assumed springs were what gave the flagship rices their feel. Source-reading end-4's and Caelestia's actual QML animation files disproved it — **neither uses `SpringAnimation`**; both ship MD3 named duration+bezier tokens. Springs would be a step beyond the references, not parity, and would make Phase 12 depend on a spring-sampling/least-squares-fitting spike. Baseline-plus-stretch keeps the ceiling without making the milestone hostage to a numerical-methods task | ✓ Resolved — Phase 12 Plan 08 ran the human side-by-side comparison TOKEN-06 requires. **Verdict: MD3 bezier retained, spring physics NOT adopted** ("MD3 is better. Spring is too fast" — a tuning symptom against unsourced feel-tuned parameters, not a mechanism rejection; a future revisit is not barred if a primary source for MD3 Expressive's spring constants ever surfaces). Full reasoning in `12-MOTION-VERDICT.md` |
| One motion source, three render targets, differing by mechanism | QML takes bezier control points through `easing.bezierCurve`, GTK4 takes `cubic-bezier()` through CSS custom properties (`var(--motion-*)`), and Hyprland takes native `bezier =` registry entries — all three read from the one hand-authored `motion.json` source. Same one-source/many-targets shape `contract.json` already uses for colour | ✓ Resolved — Phase 12 shipped and binary-verified all three targets. GTK4 takes `cubic-bezier()` directly (verified to carry overshoot on the installed GTK 4.22.4 — the originally-assumed CSS animation-keyframe technique was never needed, so ROADMAP open question 2 is moot rather than unresolved) and Hyprland takes plain `bezier =` (verified live on 0.56.0, no migration to Lua `hl.curve(...)`, settling ROADMAP open question 3). See `12-03-SUMMARY.md` (motion spine), `12-07-SUMMARY.md` (GTK4 `:root` custom-property reach, binary-verified) |
| v3.0 adds QML surfaces but retires nothing | Retiring a toolkit before accumulating mileage on its replacement is exactly the eww failure. Additive-first keeps the working desktop intact while QML expertise builds, and defers every retirement risk to v4.0 | — Pending |
| WR-04's Logout teardown-hazard measurement (D-29) was **NOT PERFORMED — waived by explicit operator decision** on 2026-07-28 to close Phase 13 | The blocking gate (`13-03-PLAN.md` Task 2) required tearing down the graphical session from a TTY with a stopwatch while a deliberately-unkillable client was running. The operator chose to waive this session-ending measurement rather than run it now. This is a waiver of the gate, not a finding — no measurement was taken, so the hazard is neither confirmed nor falsified | ⚠ Open — Phase 13 (13-03); Logout stays on the bare path (`cliphist wipe; uwsm stop`) **by default, not by evidence**. WR-04 is NOT closed. Exact reproduction steps remain verbatim in `13-03-PLAN.md` Task 2 for whoever picks this up |
| A panel must never offer a control that cannot work | Phase 15's bluetooth Enable button was live but the adapter was rfkill soft-blocked, so the binding refused every write and the press silently did nothing. The fix was not to make the press work — the panel cannot unblock rfkill — but to make the state representable (`adapterBlocked` over the adapter's own enum) and render Enable present-but-disabled with the real reason on hover | ✓ Good — Phase 15 (15-12); the same disabled+hover-reason convention already existed for Advanced and had simply never been applied here |
| When another process owns a prompt, win the ownership or accept it — never fight the z-order | A wrong wifi password surfaced nm-applet's GTK dialog *behind* the panel. No QML change could ever have won: a layer-shell overlay is unconditionally above every XDG toplevel in Hyprland. Wifi was fixed by displacing the agent (a stowed `Hidden=true` autostart override). Bluetooth was measured and NOT fixed the same way — with no agent registered, pairing does not complete at all, so the prompt is load-bearing | ✓ Good — Phase 15 (15-13 wifi); ⚠ Deferred — G-15-7 bluetooth, where containment moves to the notification-server replacement and costs a routing rule instead of a new D-Bus daemon |
| Loop-period tokens must divide the motion multiplier capped at 1.0 | Phase 15 found the wifi scan sweep running a 562ms cycle against MD3's ~2000ms reference, because one-shot transition tokens were bound as an infinite loop period. Worse, since the multiplier multiplies duration, the `reduced` accessibility preset was the *fastest* — a continuous indicator getting more frenetic for users who asked for less motion | ✓ Good — Phase 15 (15-11); reusable shape for any future continuous indicator |
| A one-shot handoff on process exit is not a handoff | The hidden-network feature searched the network list from the probe subprocess's `onExited`, which fires 16–30ms after launch — long before any scan result lands — and never retried. It could not have found *any* hidden network on *any* host. The fix binds the retry to the real results-landed observable (`networks.valuesChanged`) that a sibling plan already used | ✓ Good — Phase 15 (G-15-6, commit 12575ac); caught only because the user supplied a real hidden AP, which the shipping plan had explicitly recorded as unprovable |
| Prefer the measurement over the inherited analogy | G-15-7 looked exactly like the wifi secret-agent problem and the obvious move was to copy the wifi remedy. Measuring first — stop blueman, attempt one pair — showed pairing then fails outright, so copying it would have converted a cosmetic complaint into a functional regression. The same instinct on G-15-6 would have rebuilt a working mechanism on a costlier route | ✓ Good — Phase 15; two near-misses in one phase, both avoided by measuring before acting |

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
*Last updated: 2026-08-02 after Phase 15*
