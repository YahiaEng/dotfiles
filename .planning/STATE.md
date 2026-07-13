---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Desktop Expansion
current_phase: 06
current_phase_name: themed-surfaces-utility-suite
status: executing
stopped_at: Completed 06-14-PLAN.md
last_updated: "2026-07-13T00:43:16.096Z"
last_activity: 2026-07-13
last_activity_desc: Phase 06 execution started
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 26
  completed_plans: 26
  percent: 60
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-12)

**Core value:** One theme switch — static or dynamic — instantly and consistently re-themes the entire desktop, and the whole setup reproduces from scratch with one script.
**Current focus:** Phase 06 — themed-surfaces-utility-suite

## Current Position

Phase: 06 (themed-surfaces-utility-suite) — EXECUTING
Plan: 3 of 15
Status: Ready to execute
Last activity: 2026-07-13 — Phase 06 execution started

## Performance Metrics

**Velocity:**

- Total plans completed: 16
- Average duration: - min
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 3 | - | - |
| 02 | 2 | - | - |
| 04 | 6 | - | - |
| 05 | 5 | - | - |

**Recent Trend:**

- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
| Phase 01 P01 | 25min | 2 tasks | 2 files |
| Phase 01 P02 | 40min | 3 tasks | 27 files |
| Phase 01 P03 | multi-session | 3 tasks | 9 files |
| Phase 02 P01 | 25min | 3 tasks | 4 files |
| Phase 02 P02 | 11min | 3 tasks | 3 files |
| Phase 03 P01 | 20min | 3 tasks | 8 files |
| Phase 03 P02 | 10min | 3 tasks | 2 files |
| Phase 03 P03 | 55min+continuation | 2 tasks | 2 files |
| Phase 03 P04 | 20min | 3 tasks | 3 files |
| Phase 04 P01 | 50min | 3 tasks | 4 files |
| Phase 04 P02 | 19min | 3 tasks | 2 files |
| Phase 04 P03 | 7min | 3 tasks | 2 files |
| Phase 04 P04 | 25min | 4 tasks | 6 files |
| Phase 04 P05 | 10min | 2 tasks | 2 files |
| Phase 04 P06 | 8min | 2 tasks | 1 files |
| Phase 05 P01 | 20min | 3 tasks | 10 files |
| Phase 05 P02 | 30min | 3 tasks | 54 files |
| Phase 05 P03 | 10min | 2 tasks | 15 files |
| Phase 05 P04 | 10min | 4 tasks | 6 files |
| Phase 05 P05 | 3min | 3 tasks | 3 files |
| Phase 06 P01 | 15min | 2 tasks | 2 files |
| Phase 06 P02 | 15min | 3 tasks | 7 files |
| Phase 06 P03 | 12min | 3 tasks | 2 files |
| Phase 06 P04 | 33min | 2 tasks | 1 files |
| Phase 06 P05 | 30min | 3 tasks | 7 files |
| Phase 06 P06 | 10min | 3 tasks | 3 files |
| Phase 06 P07 | 12min | 3 tasks | 4 files |
| Phase 06 P08 | 22min | 3 tasks | 9 files |
| Phase 06 P09 | 12min | 3 tasks | 6 files |
| Phase 06 P10 | 8min | 3 tasks | 11 files |
| Phase 06 P11 | 5min | 2 tasks | 5 files |
| Phase 06 P12 | 8min | 2 tasks | 3 files |
| Phase 06 P13 | 5min | 3 tasks | 3 files |
| Phase 06 P14 | 3min | 2 tasks | 4 files |
| Phase 06 P15 | 1min | 1 tasks | 1 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table. The v1.0 per-plan decision log was cleared at milestone close (2026-07-09) — full history lives in `.planning/milestones/v1.0-phases/` summaries, `.planning/RETROSPECTIVE.md`, and git history of this file.

- [Phase 04-01]: FIX-01: Shutdown/Reboot fixed with hyprshutdown --post-cmd (official extra repo) — graceful compositor exit before systemd power transition; --vt omitted (needs passwordless chvt sudoers rule, targets exit-to-greeter path)
- [Phase 04-01]: Suspend/Hibernate stay bare systemctl (D-14 audit: they resume into the same session); wleave replacement branch did not fire (wlogout binary not implicated)
- [Phase 04-01]: hyprshutdown added to install.sh PACMAN_PKGS alongside rsync (DEBT-01) — reproducibility constraint
- [Phase 04-02]: FIX-02 root cause revised: hyprlock 0.9.5 silently rejects grace/no_fade_in/no_fade_out/fail_transition — grace was never active (#423 ruled out); real cause is the startup window before the lock surface has keyboard focus; fixed via schema migration + immediate_render + fadeIn disabled
- [Phase 04-02]: Lockout-recovery procedure (second TTY + pkill hyprlock) written before any lock test — reusable by Phase 6 LOCK-01
- [Phase 04-03]: FIX-03 root cause was nvm synchronous sourcing (53.5% cumulative shell-init time, zprof-confirmed) plus oh-my-posh remote GitHub fetch (~214ms) - fixed via nvm/bun lazy-load shim + local theme vendor; shell-init reduced 641ms -> 96ms (-85%), well under the ~400ms D-21 target; fastfetch/disk/gpu/zinit turbo NOT touched - evidence showed none were meaningful cost centers
- [Phase 04-04]: FIX-03 closed with fish adoption (D-08 user decision): fish 32.7ms vs optimized zsh 95.5ms warm (~2.9x) at full D-10 parity; switch is kitty.conf-only (shell fish, no chsh) + install.sh PACMAN_PKGS + stow.sh; zshell retained as TTY/fallback shell (D-11); fisher+nvm.fish human-approved at package-legitimacy gate and self-bootstrapped for fresh-install reproducibility
- [Phase 04-05]: FIX-03 gap closure — fish's own conf.d/nvm.fish activation guard runs before config.fish sets nvm_default_version, so fresh shells silently skipped node activation; fixed with an explicit guarded nvm use --silent inside status is-interactive (04-REVIEW.md CR-01), plus install.sh Next steps now documents the one-time nvm install v24.18.0 provisioning
- [Phase 04-06]: FIX-02 UAT gap closed: hyprlock ENTER-first input drop fixed with general:ignore_empty_input = true (blocks empty-buffer PAM submits) plus input-field:check_text visible checking cue for the remaining wrong-password window; both options pre-verified against installed hyprlock 0.9.5 binary schema via strings
- [Phase 05-01]: gtk.sh becomes the single mode-aware owner of GTK_THEME propagation; uwsm/env's static export was removed to eliminate the second hardcode site (THM-01)
- [Phase 05-01]: settings.ini mode-sensitive lines rendered via shell printf in generate.sh rather than a matugen template, since matugen has no mode-conditional templating primitive
- [Phase ?]: [Phase 05-02]: 9 dark Omarchy presets transcribed with primary/secondary/tertiary/error/outline sourced directly from upstream colors.toml ANSI slots; container/variant roles computed via a documented background/foreground blend formula
- [Phase ?]: [Phase 05-02]: hackerman and vantablack have no red hue upstream — error mapped to each theme's highest-contrast attention accent instead of inventing a literal red
- [Phase ?]: [Phase 05-02]: theme-parity/theme-stress-test/theme-switch.sh all converted to dynamic palettes/*.json glob enumeration, permanently closing RESEARCH Pitfall 2
- [Phase ?]: [Phase 05-02]: legacy themes/ stow package deleted (D-04) after reconfirming zero repo-wide references; stow.sh PACKAGES array and live ~/.config/themes symlink cleaned up
- [Phase 05-03]: Wallpaper folders locked 1:1 to palette JSON basenames with no mapping file (D-09); empty folders (dracula, 5 light variants) fall open to keep-current (D-12); per-theme last-used wallpaper state as one flat file under ~/.local/state/theme/last-wallpaper/<preset>
- [Phase 05]: [Phase 05-04]: fzf-colors.conf added as the 13th pipeline contract file (env-kv format) — locked 60/30/10 slot mapping per UI-SPEC, BG's -1 literal is an intentional exemption from the zero-literal-hex rule
- [Phase 05]: [Phase 05-04]: WALLPAPER_DIR_REAL resolved-symlink base established as the pattern for comparing paths against ~/Pictures (a stow symlink into the repo) — fixes active-wallpaper marker detection
- [Phase 05]: [Phase 05-04]: Post-selection theme-apply re-run always passes the exact active dynamic variant name (materialyou or materialyou-light), never hardcoded (D-05)
- [Phase 05-05]: walker 2.16.2 cancel exit code (130) trusted as sole cancel signal (fzf/skim 128+SIGINT convention); || rc=$? capture keeps set -euo pipefail satisfied
- [Phase 05-05]: powermenu.sh intentionally left unchanged (no set -e, existing empty-output cancel check already correct)
- [Phase ?]: All 16 new packages confirmed official-extra-repo (13) vs AUR (3) per RESEARCH Package Legitimacy Audit
- [Phase ?]: colloid-icon-theme-git (with -git suffix) used, not plain colloid-icon-theme which does not exist on AUR
- [Phase ?]: swayosd-libinput-backend.service enabled unconditionally in section_core_rice so caps-lock OSD works without a keybind (D-23)
- [Phase ?]: satty excluded from stow.sh PACKAGES — its themed config is matugen-rendered TOML symlinked via commit.sh, not a stow @import package
- [Phase 06-02]: satty palette entries use {{colors.KEY.default.hex}}ff (# prefix) not hex_stripped+ff — satty's hex_color Rust crate requires a leading # on RRGGBBAA values, verified against live upstream github.com/gabm/Satty config.toml
- [Phase 06-02]: satty [general] keys sourced from live upstream config.toml since satty isn't installed locally yet; install deferred to a later plan
- [Phase 06-02]: zen-userchrome.css chrome selectors (#nav-bar/#TabsToolbar/#sidebar-box/#urlbar-background/.tabbrowser-tab[selected]) authored fresh, strictly scoped to D-27 chrome-colors-only
- [Phase 06]: Nerd Font glyph codepoints (wlogout) resolved via fc-query cmap inspection of the installed font, not an unverified cheat-sheet copy — UI-SPEC and RESEARCH.md both explicitly declined to hardcode an unverified codepoint
- [Phase 06]: wlogout layout reformatted to one-JSON-object-per-line (NDJSON) to satisfy the plan's line-oriented verification, parser accepts both formats identically — Rule 3 blocking-issue auto-fix
- [Phase 06-04]: hyprlock $image never rendered by 06-02 target; background wired to theme-init/wallpaper.sh-owned current.jpg symlink (D-19), not a template var
- [Phase 06-04]: Avatar (D-12 themed-initial circle) dropped entirely per user rejection at live-lock checkpoint
- [Phase 06-04]: Clock switched to hyprlock's native $TIME12 (12-hour) substitution per user checkpoint request; failed-attempts counter rendered as bracket-fallback $ATTEMPTS[] so it's invisible at zero attempts
- [Phase 06-04]: hyprlang cannot parse literal {{ }} in a label text value (silently falls back to hyprlock's built-in 'Sample Text' default) — playerctl now-playing rebuilt as a brace-free sh -c concatenation
- [Phase 06-05]: hyprshot/satty CLI flags verified against live upstream source (Gustash/Hyprshot, gabm/Satty cli/src/command_line.rs) since neither binary is installed locally yet — same approach 06-02 used for satty's config schema
- [Phase 06-05]: capture-full.sh uses hyprshot -m output -m active (instant, no click) for full-screen; capture-window.sh uses plain -m window (click-to-select); satty runs with --disable-notifications and each capture script fires its own notify-send reusing the pre-existing screenshot.sh wording/icon, only when the output file exists
- [Phase 06-05]: record-toggle.sh's gpu-screen-recorder invocation, slurp region/monitor picker, and SIGINT-bounded-poll stop adapted near-verbatim from the live Omarchy reference (basecamp/omarchy bin/omarchy-capture-screenrecording), fetched this session
- [Phase 06-06]: D-25 descope exercised: ddcutil not installed / no DDC monitor detected — brightness-via-DDC skipped per pre-authorized fallback, brightnessctl binds kept unchanged
- [Phase 06-06]: Zen profile resolution parses installs.ini first (single-section, unconditional Default=), falls back to profiles.ini [General]/ProfileN Default=1; resolved path validated as a real existing subdirectory of ~/.zen before any symlink/write (T-06-10)
- [Phase 06-06]: Fixed an awk double-flush bug in the Zen profiles.ini fallback parser (exit inside a function skipped the state reset, causing END's flush to re-print) — caught via functional testing against synthetic installs.ini/profiles.ini fixtures before commit
- [Phase 06-07]: Icon-theme picker enumerates real installed themes via an index.theme/Directories= directory scan, not a hardcoded Papirus/Tela/Colloid allowlist
- [Phase 06-07]: theme_engine_nearest_icon_variant enumerates actual installed <base>-* directories at runtime (no hardcoded Tela/Colloid variant list); papirus-folders/tela/colloid remain uninstalled on this dev machine, all new gtk.sh paths validated via best-effort no-op behavior
- [Phase ?]: [Phase 06-08]: Nerd Font glyph codepoints for the specimen preview (home/folder/git-branch/terminal/gear) verified present in the installed FiraCode Nerd Font cmap via direct TTF cmap-table parsing, not an unverified cheat-sheet copy
- [Phase ?]: [Phase 06-08]: fc-match -f '%{file}' used to resolve fontconfig family names to file paths for ImageMagick text rendering, since IM's own -font lookup only resolves internal type.xml aliases, not raw fontconfig family strings
- [Phase ?]: [Phase 06-08]: Symbols Nerd Font excluded from the font picker's enumerated set (Rule 2 defensive filter) - glyph-only supplemental font with no letterforms
- [Phase ?]: [Phase 06-09]: walker --dmenu -s symbols source-verified non-functional (dmenu is stdin-only, ignores -s/-m); emoji-picker.sh uses a self-contained curated glyph list through the same walker --dmenu pattern theme-switch.sh already proves, with an exact-line validation gate before wtype
- [Phase ?]: [Phase 06-09]: cliphist wipe joined with ';' not '&&' in wlogout actions so a wipe failure can never block shutdown/reboot/logout
- [Phase ?]: [Phase 06-09]: Super+Shift+C added as the manual clipboard-wipe entry since UI-SPEC's 4-chord table left Super+C itself off-limits to edit
- [Phase 06-10]: Font render targets (kitty-font.conf, waybar-font.css) placed in a new presence_only_files array, kept out of contract.json's files array, since they carry no color-declaration content theme-parity's parity extractors require
- [Phase 06-10]: Wrapper scripts (icon-theme-switch.sh, font-switch.sh) replicate wallpaper-switch.sh's exact uwsm app -- kitty shape rather than inventing a new launcher pattern
- [Phase ?]: 06-11: gpu-screen-recorder region flag corrected to -w region -region <geom>; capture-region/window/full.sh gained hyprshot/satty command -v guards; color-picker.sh success-path cleanup converted to an if-block (set -e exit-status fix class)
- [Phase 06]: Phase 06-12: hyprlock-colors.conf renders both an rgba()-wrapped $on_surface_variant and a bare $on_surface_variant_hex from the same source color, since hyprlock's pango span foreground= needs a raw hex escaped by ## while other keys need rgba()
- [Phase 06-13]: swayosd-server launched via exec-once = uwsm app -- swayosd-server, placed after hypridle and before theme-init — Restores the OSD-01 regression: swayosd-client had no server to talk to on a fresh install
- [Phase 06-13]: swayosd-libinput-backend.service enabled on the system bus (sudo systemctl enable --now) instead of --user, non-silenced failure report — Packaged extra/swayosd unit only exists as a root system service; --user enable always silently no-op'd
- [Phase 06-13]: reload.sh theme-switch restarts swayosd-server itself, not the libinput backend — style.css is only read at swayosd-server startup; the libinput backend has no CSS to reload (06-REVIEW.md WR-01)
- [Phase 06-14]: Print-family binds rebound to code:107 (physical keycode) instead of the Print keysym — deterministically fixes ALT+Print (us XKB keymap resolves Alt+PrtSc to Sys_Req, not Print) and is robust to keyboards with non-standard PrtSc keysym mapping
- [Phase 06-14]: hyprshot invocations switched from -r to --raw in all three capture scripts — hyprshot 1.3.0's getopt optstring declares -r as argument-required while the handler treats it as boolean, so only the long form parses cleanly
- [Phase 06]: [Phase 06-15]: vlc + vlc-plugins-all and xdg-user-dirs added to install.sh PACMAN_PKGS (official extra/core repo packages, not AUR) — closes SHOT-03 UAT gap where fresh installs had no codec able to decode gpu-screen-recorder output

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260709-a5i | Fix install.sh AUR conflict: remove dead alpm_octopi_utils | 2026-07-09 | 0ffa5d9 | [260709-a5i-fix-install-sh-aur-conflict-remove-dead-](./quick/260709-a5i-fix-install-sh-aur-conflict-remove-dead-/) |
| 260709-buf | Fix theme reload headless hang + gate step timeout | 2026-07-09 | 1e747eb, 50ad696 | [260709-buf-fix-theme-reload-headless-hang-gate-step](./quick/260709-buf-fix-theme-reload-headless-hang-gate-step/) |
| 260709-ciu | Make current.jpg wallpaper symlink relative (fresh-install materialyou fix) | 2026-07-09 | 49536d5 | [260709-ciu-fix-host-absolute-wallpaper-symlink-brea](./quick/260709-ciu-fix-host-absolute-wallpaper-symlink-brea/) |

### Pending Todos

[From .planning/todos/pending/ — ideas captured during sessions]

None yet.

### Blockers/Concerns

[Issues that affect future work]

Research flags to resolve during phase planning (from research/SUMMARY.md):

- **Phase 6:** Zen browser profile-path resolution (native vs flatpak, "profile doesn't exist yet" chicken-and-egg) — research spike before THM-05 planning.
- **Phase 8:** OLED auto-hide mechanism (hypridle availability, idle integration, pixel-shift feasibility) — research spike before BAR-01/BAR-02 planning.
- **Phase 7:** elephant/walker version skew silently breaks custom menus — pin walker + elephant-* together and health-gate before shipping MENU-01.
- **Phase 6:** hyprlock lockout-recovery discipline (second TTY logged in) and clipboard size-cap/wipe policy are launch requirements, not follow-ups.

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| v2.0 | OSD, Walker menus, media widget, polish, more themes | Now roadmapped into v2.0 Phases 4-8 | 2026-07-09 |
| Future | ICON-BROWSE (browse/install new icon themes), POLISH-01 (cohesive animation language) | Deferred beyond v2.0 | 2026-07-09 |

## Session Continuity

Last session: 2026-07-13T00:42:48.722Z
Stopped at: Completed 06-14-PLAN.md
Resume file: None
