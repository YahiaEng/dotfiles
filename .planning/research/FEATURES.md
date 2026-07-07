# Feature Research

**Domain:** Polished Hyprland/Arch ricing dotfiles (unified dynamic theming, launcher, bar, OSD, media)
**Researched:** 2026-07-07
**Confidence:** LOW-MEDIUM (web search only, no MCP docs/context7 access this run; corroborated across 3+ independent projects — Omarchy, end-4/dots-hyprland, HyDE, caelestia-dots, ML4W — so cross-checked findings are treated as MEDIUM, single-source claims as LOW per source hierarchy)

## Feature Landscape

### Table Stakes (Users Expect These)

Features that, if missing or broken, make a themed Hyprland rice feel unfinished — this is where every reference project (Omarchy, HyDE, end-4, caelestia, ML4W) agrees.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| One theme switch re-themes every visible app, live, no relogin | This is the entire premise of a "themed rice" — Omarchy's `colors.toml` fans out to terminal/btop/Hyprland/Hyprlock/notifications/waybar/launcher in one action; if one app lags behind, the whole system reads as broken | HIGH | This project's core known gap: walker + thunar stuck white, waybar/swaync unverified. Fixing this is prerequisite to everything else in this research |
| GTK3 + GTK4 app theming (not just custom-CSS apps) | Users run GTK file managers, image viewers, etc.; a themed desktop with one obviously off-brand white app breaks immersion instantly | MEDIUM-HIGH | Standard mechanism: `gsettings set org.gnome.desktop.interface gtk-theme/color-scheme/icon-theme` via a matugen post-hook, requires `xdg-desktop-portal-gtk` running so already-open apps pick it up. XFCE apps (Thunar) additionally read `xfconf`/`xsettingsd`, not pure gsettings — likely root cause of Thunar staying white even after GTK css/colors.css regenerate |
| Consistent color source of truth across static + dynamic modes | Every polished setup (Omarchy, HyDE) uses ONE palette definition per theme that every app template reads from, whether the palette came from a wallpaper (matugen) or a hand-picked static theme | MEDIUM | This repo already does this correctly in principle via `matugen/.config/matugen/config.toml` templates; static presets need to produce the same template inputs so both paths are truly one pipeline |
| OSD for volume/brightness (and ideally caps/num lock) | Every reference setup treats this as base-level UX; hitting a volume key with zero on-screen feedback feels like a broken/incomplete desktop | LOW-MEDIUM | `swayosd` is the de facto standard (used directly or forked by Omarchy). Install via pacman, enable `swayosd-libinput-backend.service`, bind `swayosd-client --output-volume raise/lower/mute-toggle` and `--brightness +N/-N` to `XF86Audio*`/`XF86MonBrightness*` keys, style via `~/.config/swayosd/style.css` (themeable like any GTK-CSS component) |
| Working app launcher with fuzzy search, calc, emoji | Walker (or wofi/rofi equivalents) with basic providers is assumed present in any modern Hyprland setup | LOW (already have) | Already implemented via walker; theming is the gap, not functionality |
| Power/session menu (logout, reboot, shutdown, lock) | Universal expectation — every desktop needs a themed way to end a session | LOW (already have via wlogout) | Wlogout already exists; needs to be in the matugen template fan-out like everything else |
| Notification center that matches theme | swaync/mako must re-theme with the rest of the desktop; unthemed notification popups are highly visible and jarring | MEDIUM | swaync theming state is "unverified" per PROJECT.md — must be confirmed as part of the bug scan before building new features on top |
| Reproducible fresh install (script + stow, no manual host state) | Table stakes for any "dotfiles as a system" project, and explicitly called out as a milestone-1 requirement here | HIGH | `install.sh` must leave a system in the exact same themed state as a live-tweaked one — no missing `gsettings` defaults, systemd service enables, or one-time manual steps |
| Waybar shows core system status (workspaces, clock, tray, audio, network, battery) | Base expectation of any tiling WM bar; this repo already has it | LOW (already have) | Verify it re-themes; don't rebuild functionality that exists |

### Differentiators (Competitive Advantage)

Features that separate a "fine" rice from a genuinely polished one — this is where the milestone-2 scope (OSD, menus, media, polish, themes) lives, and where this project should decide what "done" looks like without chasing every competitor feature.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Omarchy-style custom Walker menus (system menu, settings shortcuts, keybind viewer) | Turns Walker from "just a launcher" into a full control surface — Omarchy binds separate keybinds to app-launch, system menu, power menu, and keybind-viewer, each just a differently-themed/invoked Walker instance or Elephant custom menu | MEDIUM | Walker's backend (`elephant`) supports custom menus as Lua scripts in `~/.config/elephant/menus/` (`Name`, `Icon`, `Action` with `%VALUE%` templating, `GetEntries()` returning `Text`/`Subtext`/`Value`/`Icon` rows) triggered by prefix chars configured in `walker/config.toml`. "If you can write a shell command that outputs data, you can turn it into a Walker menu" — cheap to add incrementally (keybind cheat-sheet first, then power/system menu) once base Walker theming is fixed |
| Waybar "now playing" media widget | Visually signals a "complete" desktop; near-universal in polished Hyprland setups (caelestia's media dashboard, end-4's MPRIS work, community waybar-mpris configs) | LOW-MEDIUM | Prefer Waybar's **native** `mpris` module (bundled with recent waybar builds, backed by `playerctld`) over third-party scripts: supports `format`/`format-paused`, `player-icons`, `status-icons`, `ignored-players`, and defaults to whatever is currently playing. Native module is the lower-maintenance, better-supported choice vs custom shell-script modules |
| Cohesive animation/motion language (bar, launcher, OSD, notifications) | What makes end-4/caelestia-style setups feel "alive" rather than static; a consistent easing/duration language across Hyprland window animations, waybar transitions, and OSD popups reads as intentional design | MEDIUM | Hyprland has native animation config (bezier curves, per-window-rule); OSD/CSS-based apps (swaync, waybar, walker) get their own transition rules. Keep it to ONE shared "feel" (e.g. one bezier curve reused everywhere) rather than per-app bespoke animation — matches this project's "cohesive styling" goal without needing a QML shell rewrite |
| Expanded static theme presets + smarter wallpaper-driven extraction | More themes = more perceived polish and personalization, a headline feature for HyDE ("vast array of themes... themepatcher... community gallery") and Omarchy (19 built-in themes) | LOW per theme, MEDIUM for tooling | Cheapest lever once the pipeline is fixed: each new static preset is "just" a new set of template inputs through the existing matugen template fan-out. Consider a `themepatcher`-style helper script (HyDE pattern) so adding a theme is copy-a-folder-and-edit-colors, not touching every app's config by hand |
| Per-theme wallpaper sets / wallpaper cycling tied to theme | Nice UX touch (Omarchy supports save/cycle/deactivate/delete wallpaper sets per theme via Walker) | LOW-MEDIUM | Natural follow-on once "more themes" exists; not required for MVP of milestone 2 |
| Lock screen / idle theming | Every competitor reference (Omarchy's Hyprlock, HyDE) treats this as part of "every visible surface matches," but this project has explicitly deferred it | N/A | Already correctly scoped OUT for this milestone per PROJECT.md — do not silently pull it back in scope while doing the theming/OSD work, even though it's adjacent |
| AI sidebar / assistant integration (Gemini/Ollama/OpenRouter) | end-4/dots-hyprland's most distinctive differentiator | HIGH | Explicitly not part of this project's stack/goals — flagged here only so it's a clear non-goal, not an oversight |
| Full custom shell (Quickshell/QML) replacing waybar+walker+swaync | caelestia's and (partly) end-4's approach: one unified "brain" process for bar+launcher+notifications+dashboard, extremely cohesive, visually best-in-class | VERY HIGH | This is a from-scratch framework choice, not a feature — would mean abandoning waybar/walker/swaync entirely. Explicitly out of scope for a project whose stated constraint is "fixes and extends the existing setup, not a rewrite" |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|------------------|-------------|
| Custom hand-rolled OSD (own GTK/CSS popup for volume/brightness) | Feels more "in-house" / fully custom-themed | Duplicates a well-solved, actively-maintained problem (SwayOSD); reinventing it burns time on daemon/keybind edge cases (multi-monitor, debounce, mute state) that swayosd already handles | Use SwayOSD and theme its CSS via the existing matugen template pipeline, same as every other app |
| Per-app bespoke theming scripts (one-off script per app instead of one templated pipeline) | Feels like the fastest fix when one app (e.g. Thunar) resists theming | This is exactly the pattern that produced the current bug: git history shows repeated one-off "fix: gtk themes", "fix: walker and thunar" attempts that didn't stick, because they patched symptoms instead of the shared GTK/portal propagation mechanism | Fix the root cause once (gsettings + portal + xfconf path for XFCE apps) inside the existing matugen post-hook pipeline, not a new script per broken app |
| Rewriting the shell in Quickshell/QML (caelestia/end-4 style) to "solve" theming | Looks tempting after seeing how cohesive caelestia's unified shell looks | Massive scope explosion — replaces waybar, walker, and swaync simultaneously, contradicts the stated constraint of extending (not rewriting) the existing stack, and introduces an entirely new toolchain (Quickshell + QML) this project has no experience-cost budget for | Keep the current app choices; achieve cohesion through the shared color/animation pipeline, not a shell rewrite |
| "Real-time everything" wallpaper-driven re-theme on every wallpaper cycle | Sounds appealing for a dynamic desktop | Matugen color generation + full app reload has real latency/flicker cost; doing it on every wallpaper auto-cycle (vs. explicit user-triggered theme switch) risks visible stutter/relayout across waybar/hypr and defeats "instant" table-stakes expectation | Trigger full re-theme only on explicit user action (theme switch command/menu), keep wallpaper cycling separate from the "commit to this palette" action unless the user explicitly opts into cycling-triggers-retheme |
| Chasing every competitor feature (AI sidebar, weather widget, system dashboard, custom panel families) | Reference projects like end-4/caelestia have many extra widgets that look impressive | Scope creep unrelated to this project's core value ("one theme switch reproducibly re-themes everything"); adding unrelated widgets before the theming pipeline is verified compounds risk | Finish table stakes (full propagation + reproducible install) first; treat extra widgets as separate, later, individually-scoped features |

## Feature Dependencies

```
Fix GTK/XFCE theme propagation (root-cause: gsettings + portal + xfconf)
    └──requires──> One shared matugen template pipeline for static + dynamic themes (already exists, needs static-theme parity)
                       └──requires──> waybar/swaync theming verified (unknown state today)

Repo cleanup (remove wofi, dead configs)
    └──independent of, but should precede──> install.sh fresh-install verification (avoid re-verifying dead paths)

install.sh fresh-install verification
    └──requires──> Fixed theme propagation (else "verified" install just reproduces the white-walker/thunar bug)

SwayOSD (OSD indicators)
    └──enhances──> full theme propagation (its CSS must be added to the matugen template fan-out)
    └──independent of──> Walker menus, media widget (can be built in parallel once base theming is fixed)

Omarchy-style Walker menus (system/power/keybind menus)
    └──requires──> Walker base theming fixed (else new menus inherit the same white-theme bug)
    └──enhances──> overall "polish" perception

Waybar "now playing" media widget
    └──requires──> waybar theming verified (new module must inherit correct colors, not hardcoded ones)
    └──independent of──> Walker menus, OSD

Cohesive animation/motion polish
    └──enhances──> all of the above (applied last, across whichever components already work)

More themes (static presets + better wallpaper extraction)
    └──requires──> One shared matugen template pipeline fully working across ALL apps
                       (adding themes before the pipeline is fixed just multiplies the number of broken states)

Lock screen theming (hyprlock/hypridle)
    └──explicitly OUT OF SCOPE this milestone──> do not let OSD/menu/media work quietly pull this back in
```

### Dependency Notes

- **Everything in milestone 2 requires the milestone-1 theming fix first.** SwayOSD, new Walker menus, and the waybar media widget are all new UI surfaces that will read colors from the same matugen templates/GTK settings currently failing for walker and thunar. Building them before the root-cause fix means shipping more surfaces with the same white-theme bug.
- **Repo cleanup and install.sh verification are sequenced, not parallel-safe.** Verifying a fresh install against a repo that still contains dead wofi configs risks validating paths that will be deleted; clean first, then verify.
- **OSD, Walker menus, and the media widget are mutually independent** once the theming root cause is fixed — they can be built and verified in any order or in parallel phases.
- **"More themes" is the highest-leverage but last-recommended item** in milestone 2: it's cheap per-theme once the pipeline is trustworthy, but each new theme is also a new thing that can go stale if built before propagation is fully fixed.

## MVP Definition

### Launch With (Milestone 1 — must ship before milestone 2 starts)

- [ ] Walker follows theme switches — table stakes, currently broken
- [ ] Thunar follows theme switches — table stakes, currently broken
- [ ] Waybar + swaync theming verified (fixed if broken) — table stakes, unknown state
- [ ] One theme switch updates every visible app live, no relogin — the entire value proposition
- [ ] Static presets and matugen dynamic themes share one pipeline — required so future themes/features don't fork logic
- [ ] Full-repo bug scan across theme pipeline, install.sh, hypr config, stow — prevents whack-a-mole fixes
- [ ] install.sh verified on a clean Arch system to produce the fully-themed result — reproducibility is a stated core value
- [ ] Repo cleanup (wofi removal, dead configs, stray files) — reduces surface area for future bugs

### Add After Validation (Milestone 2)

- [ ] SwayOSD volume/brightness indicators, themed via the now-trustworthy pipeline — trigger: milestone 1 done
- [ ] Omarchy-style custom Walker menus (power menu, system menu, optionally keybind viewer) — trigger: Walker theming confirmed fixed
- [ ] Waybar native `mpris` "now playing" widget — trigger: waybar theming confirmed fixed
- [ ] Cohesive animation/motion polish across bar/launcher/OSD/notifications — trigger: all target components exist and are themed correctly (polish is applied last)
- [ ] One or two additional static theme presets to prove the pipeline generalizes — trigger: pipeline fix complete

### Future Consideration (v2+, explicitly not this milestone)

- [ ] Larger theme gallery / theme-patcher tooling (HyDE-style) — defer until the 1-2 new presets prove the pipeline holds up
- [ ] Per-theme wallpaper cycling/sets — defer until "more themes" exists
- [ ] Lock screen (hyprlock/hypridle) theming — explicitly deferred per PROJECT.md, revisit in a later milestone
- [ ] Any AI assistant integration or full Quickshell/QML shell rewrite — not aligned with this project's stated constraint of extending the existing stack

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Fix walker/thunar/GTK theme propagation | HIGH | HIGH | P1 |
| Verify waybar/swaync theming | HIGH | MEDIUM | P1 |
| install.sh fresh-install verification | HIGH | MEDIUM-HIGH | P1 |
| Repo cleanup (dead configs, wofi removal) | MEDIUM | LOW | P1 |
| SwayOSD themed OSD | HIGH | LOW-MEDIUM | P2 |
| Omarchy-style Walker menus | MEDIUM-HIGH | MEDIUM | P2 |
| Waybar now-playing media widget | MEDIUM | LOW-MEDIUM | P2 |
| Cohesive animation/motion polish | MEDIUM | MEDIUM | P2 |
| Additional static theme presets | MEDIUM | LOW per theme | P2 |
| Theme-patcher tooling / theme gallery | LOW-MEDIUM | MEDIUM-HIGH | P3 |
| Per-theme wallpaper sets | LOW | LOW-MEDIUM | P3 |
| Lock screen theming | MEDIUM | MEDIUM | P3 (deferred) |
| AI sidebar / full shell rewrite | LOW (for this project) | VERY HIGH | Not planned |

**Priority key:**
- P1: Must have — milestone 1, fixes the broken core
- P2: Should have — milestone 2, the stated expansion scope
- P3: Nice to have — explicitly deferred or lower-value future work

## Competitor Feature Analysis

| Feature | Omarchy | end-4/dots-hyprland | HyDE | caelestia-dots | ML4W | Our Approach |
|---------|---------|----------------------|------|-----------------|------|--------------|
| Theme switching mechanism | Single `colors.toml` per theme fans out via templates to terminal/bar/launcher/notifications/lock screen; switch via Walker menu, live reload | Material You dynamic color gen (QML) built into the shell itself; runtime panel-family switching | Wallpaper/theme fed through a "themepatcher" per-app, curated theme gallery, modular scripts separate from dotfiles | Material Design 3 dynamic color extraction as part of one unified Quickshell "brain" | GUI settings app + Walker experimental support for switching | Already matugen-templated for most apps; fix propagation gaps (walker/thunar/GTK) rather than adopt a new mechanism |
| OSD | SwayOSD (forked/bundled), themed per-theme | Custom QML OSD as part of shell | Not confirmed in search (likely swayosd or custom) | Built into unified shell dashboard | Not primary focus | Adopt SwayOSD (industry-standard, low complexity, matugen-themeable) rather than build custom |
| Launcher / menus | Walker with prefix-based providers (`.` files, `:` emoji, `=` calc, `$` clipboard) + custom system/power/keybind menus per keybind | Custom QML sidebar/launcher, deeply integrated with the shell | Rofi-based (traditionally), curated via themepatcher | Built-in launcher as part of unified shell | Walker (experimental) / rofi | Already on Walker; add Omarchy-style custom menus via Elephant's Lua menu system once base theming fixed |
| Media widget | Not a headline Omarchy feature (search didn't surface one) | MPRIS integration work-in-progress for reliable cross-source detection | Not confirmed | Media controller in system panel with CPU/GPU/RAM/weather | Not confirmed | Use waybar's native `mpris` module — simpler than a custom shell dashboard, fits "extend don't rewrite" constraint |
| Visual polish / animation | Consistent theme-wide styling + Hyprland animation presets | High: custom QML panel animations, "usability-first" positioning | "Polished animations, cohesive design language" per marketing | High: "fluid, morphing shell" is the core pitch | Standard Hyprland animations | Achieve via one shared bezier/animation language across Hyprland + CSS apps; skip a shell rewrite |
| Install/reproducibility | Full opinionated distro-level installer (highest bar, out of scope for us) | Install script, but positions itself as "usability-first" over full-distro | Convenient install script + Hyde-Ext for restore/upgrade | Install script for the shell package | GUI installer app | Keep `install.sh` + stow, but raise its verification bar to match reproducibility expectations these projects set |

## Sources

- [Dotfiles · The Omarchy Manual · DHH](https://learn.omacom.io/2/the-omarchy-manual/65/dotfiles) — LOW confidence (web search summary, not primary doc fetch)
- [basecamp/omarchy discussion #191 — Manage your OWN dotfiles with symlinks?](https://github.com/basecamp/omarchy/discussions/191) — LOW
- [Awesome Omarchy - Curated Arch Linux/Hyprland Themes & Tools](https://awesome-omarchy.com/) — LOW
- [Preconfigured setups – Hyprland Wiki](https://wiki.hypr.land/Getting-Started/Preconfigured-setups/) — MEDIUM (official Hyprland wiki)
- [end-4/dots-hyprland GitHub](https://github.com/end-4/dots-hyprland) — LOW (search summary, not repo fetch)
- [Feature Roadmap issue #2082 — end-4/dots-hyprland](https://github.com/end-4/dots-hyprland/issues/2082) — LOW
- [Usage | illogical-impulse (end-4 wiki)](https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/02usage/) — LOW
- [HyDE Project (GitHub org)](https://github.com/HyDE-Project) — LOW
- [HyDE 2025 Update blog](https://blog.da4ndo.com/hyde-2025-update-the-most-aesthetic-dynamic-and-minimal-hyprland-experience) — LOW
- [caelestia-dots/shell GitHub](https://github.com/caelestia-dots/shell) — LOW
- [caelestia-dots/shell README](https://github.com/caelestia-dots/shell/blob/main/README.md) — LOW
- [ML4W OS — Walker configuration docs](https://ml4w.com/os/configuration/walker) — LOW
- [ErikReider/SwayOSD GitHub](https://github.com/ErikReider/SwayOSD) — MEDIUM (project's own README, cross-checked against 2 independent Hyprland setup guides)
- [Dark mode switching - ArchWiki](https://wiki.archlinux.org/title/Dark_mode_switching) — MEDIUM (ArchWiki, generally reliable)
- [InioX/matugen-themes GitHub](https://github.com/InioX/matugen-themes) — LOW
- [Waybar Wiki — Module: MPRIS](https://github.com/Alexays/Waybar/wiki/Module:-MPRIS) — MEDIUM (official Waybar wiki)
- [waybar-mpris(5) — Arch manual pages](https://man.archlinux.org/man/extra/waybar/waybar-mpris.5.en) — MEDIUM (Arch man pages)
- [Custom Walker Menus with Lua | Hans Schnedlitz](https://www.hansschnedlitz.com/writing/2026/02/22/custom-walker-menus-with-lua) — LOW (personal blog, but detailed and internally consistent with Walker/Elephant docs)
- [A comprehensive walker guide for omarchy — basecamp/omarchy discussion #2835](https://github.com/basecamp/omarchy/discussions/2835) — LOW
- [Walker Providers docs](https://walkerlauncher.com/docs/providers) — MEDIUM (official Walker docs)
- Existing repo state (`matugen/.config/matugen/config.toml`, `gtk/.config/gtk-{3,4}.0/`, `thunar/.config/`) — inspected directly, HIGH confidence for what currently exists in this repo

---
*Feature research for: Hyprland/Arch dynamic-theming dotfiles (unified theme propagation, launcher menus, OSD, media widget, visual polish)*
*Researched: 2026-07-07*
