# Architecture Research

**Domain:** Unified dynamic theming for Arch Linux + Hyprland dotfiles
**Researched:** 2026-07-07
**Confidence:** MEDIUM (HIGH for current-repo findings via direct code inspection; LOW-MEDIUM for reference-project claims sourced from web search / DeepWiki summaries — flagged inline)

## Standard Architecture

Every mature Hyprland theming system (Omarchy, JaKooLit/Hyprland-Dots, ML4W, end-4/dots-hyprland) converges on the same five-layer shape, regardless of whether colors come from a hand-picked static palette or a wallpaper-driven generator (matugen/wallust/pywal). This repo already has all five layers — the milestone's job is to make the layers **consistent** and **converge to one code path**, not to invent new architecture.

### System Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│  TRIGGER LAYER                                                        │
│  ┌────────────────┐ ┌──────────────────┐ ┌───────────────────────┐   │
│  │ Walker "Theme   │ │ Walker "Wallpaper │ │ Login (theme-init.sh  │   │
│  │ Switcher" menu  │ │ Picker" menu      │ │ via uwsm autostart)   │   │
│  └────────┬────────┘ └────────┬──────────┘ └───────────┬───────────┘  │
├───────────┴───────────────────┴────────────────────────┴─────────────┤
│  GENERATION LAYER  (branches on mode, converges on output contract)   │
│  ┌─────────────────────────────┐   ┌────────────────────────────┐    │
│  │ STATIC: cp preset files from │   │ DYNAMIC: matugen image      │    │
│  │ themes/{static,css,gtk,...}/ │   │ <wallpaper> renders          │    │
│  │ <name>.* → canonical paths   │   │ templates/*.{conf,css,toml} │    │
│  └───────────────┬─────────────┘   └──────────────┬───────────────┘    │
├──────────────────┴──────────────────────────────────┴─────────────────┤
│  DISTRIBUTION LAYER — single source of truth per app                  │
│  ┌───────────┐┌────────────┐┌───────────┐┌──────────┐┌──────────────┐ │
│  │colors.conf││colors.css  ││colors.css ││colors.css││style.css     │ │
│  │(hypr)     ││(waybar)    ││(swaync)   ││(gtk 3/4) ││(walker,      │ │
│  │           ││            ││           ││          ││literal hex)  │ │
│  └───────────┘└────────────┘└───────────┘└──────────┘└──────────────┘ │
├─────────────────────────────────────────────────────────────────────┤
│  APPLICATION LAYER — each app's own config `source`s / `@import`s     │
│  the canonical color file above; app logic never embeds colors        │
├─────────────────────────────────────────────────────────────────────┤
│  RELOAD / SIGNAL LAYER — fan-out, per-app mechanism                   │
│  hyprctl reload · SIGUSR2 waybar · SIGUSR1 kitty · swaync-client -rs  │
│  · gsettings toggle + gtk.css rebuild (GTK) · full restart (walker)   │
├─────────────────────────────────────────────────────────────────────┤
│  STATE LAYER                                                          │
│  ~/.cache/current-theme · ~/.cache/current-waybar-layout               │
│  (read by theme-init.sh at login to restore last state)               │
└─────────────────────────────────────────────────────────────────────┘
```

**Confidence:** HIGH for this repo's current shape (read directly from `theme-switch.sh`, `theme-init.sh`, `matugen/config.toml`, `gtk-reload.sh`, `walker-restart.sh`, `walker-theme-gen.sh`). MEDIUM for "every mature system converges on this shape" — corroborated by Omarchy (DeepWiki, LOW-confidence secondary source) and JaKooLit/Hyprland-Dots (DeepWiki, LOW-confidence secondary source), which both describe the same trigger→generate→distribute→reload pipeline independently.

### Component Responsibilities

| Component | Responsibility | Current implementation in this repo |
|-----------|----------------|------------------------|
| Trigger scripts | Collect user intent (which theme/wallpaper), never touch app configs directly | `theme-switch.sh` (walker dmenu), `wallpaper-picker.sh`, `theme-init.sh` (login) |
| Generation | Produce canonical per-app color files, either by `cp` from a static preset or by running `matugen image <wallpaper>` against templates | Static: file copy loop in `theme-switch.sh`. Dynamic: `matugen/config.toml` + `matugen/templates/*` |
| Distribution contract | The canonical color file path + variable naming convention every app config depends on | `~/.config/{hypr,waybar,kitty,swaync,wlogout,gtk-3.0,gtk-4.0}/colors.{conf,css}`, `walker/themes/rice/style.css` |
| App configs | Read colors via `source`/`@import`/`@define-color` reference, contain zero hardcoded colors | `hyprland.conf` sources `colors.conf`; waybar/swaync/wlogout CSS `@import "colors.css"` (verify — see Pitfalls) |
| Reload orchestration | Fan out the correct reload mechanism per app after distribution completes | `reload_all()` in `theme-switch.sh`; **reimplemented, not shared, in `theme-init.sh`** |
| GTK subsystem | Bridge GTK's settings-daemon model (gsettings, named theme, dark/light) with the colors.css override model; GTK3 and GTK4/libadwaita need different treatment | `gtk-reload.sh` (partial — toggles gsettings dark-mode + rebuilds `gtk.css`, but `GTK_THEME` name itself is a fixed value `adw-gtk3-dark`, not per-preset) |
| Walker subsystem | Walker (gtk4-layer-shell) does not consume `@define-color` GTK tokens reliably for its own compiled CSS theme — needs a dedicated hex-literal renderer and a full process restart | `walker-theme-gen.sh` (regex-extracts hex from `colors.css`, writes literal-value `style.css`), `walker-restart.sh` (kills socket + process, relaunches via uwsm) |
| State persistence | Record "what is currently applied" so login/session-restore and future UI (waybar module, OSD) can query it without re-deriving | `~/.cache/current-theme`, `~/.cache/current-waybar-layout` |

## Recommended Project Structure

The current repo scatters theme **orchestration logic** inside the `hypr` stow package (`hypr/.config/hypr/scripts/*.sh`), while theme **data** lives in a separate `themes` package and `matugen` package. This is the root structural weakness behind the milestone's bugs: orchestration code that touches waybar/swaync/gtk/walker is owned by the `hypr` package, so there is no single place that "is" the theming system, and no shared library — which is why `reload_all()` exists once in `theme-switch.sh` but is copy-pasted a second time (with drift risk) in `theme-init.sh`.

Recommended reorganization (can be done incrementally, does not require a rewrite):

```
theme/                              # new stow package — the theming ENGINE
├── .config/theme/
│   ├── lib/
│   │   ├── distribute.sh           # static cp OR matugen invoke → canonical color files
│   │   ├── reload.sh               # single fan-out: hyprctl/waybar/kitty/swaync/gtk/walker
│   │   └── gtk.sh                  # gsettings + gtk.css rebuild + light/dark + accent handling
│   ├── apply-theme.sh              # entrypoint: apply-theme.sh <name|materialyou>
│   │                                #   sourced by BOTH the walker picker AND theme-init.sh
│   └── state.sh                    # read/write ~/.cache/current-theme, current-waybar-layout
themes/                             # UNCHANGED — static preset data only (no logic)
matugen/                            # UNCHANGED — dynamic template data only (no logic)
hypr/                               # UNCHANGED — hyprland.conf, keybinds; keybinds call
                                     #   `~/.config/theme/apply-theme.sh` instead of owning logic
waybar/, swaync/, gtk/, walker/,    # UNCHANGED — each owns only its own static config +
kitty/, wlogout/, yazi/             #   a colors.* stub file the engine writes into
```

### Structure Rationale

- **`theme/lib/` as the single engine:** every future add-on (OSD, walker menus, media center) that needs to react to a theme change subscribes to this engine (calls `reload.sh` fragment or is added as one more line in it) instead of every script re-deriving reload logic. This is exactly Omarchy's rationale for centralizing under `~/.config/omarchy/` rather than scattering theme logic across each app's own stow package (DeepWiki, LOW confidence, but directionally consistent with the two-stage-swap pattern below).
- **`apply-theme.sh` as the only entrypoint:** `theme-switch.sh` (interactive) and `theme-init.sh` (login) currently duplicate ~40 lines of "copy files then reload everything" logic. Collapsing both into calls to one shared script removes an entire class of "fixed in one place, still broken in the other" bugs — which is very likely why walker/thunar fixes have not stuck across multiple past commits (`fix: walker and thunar not responding to theme changes`, `fix: gtk themes`, `debug: white theme`).
- **Static preset data and matugen template data stay separate but produce an identical output contract:** both must write to the exact same canonical file paths with the exact same variable names (see `walker-theme-gen.sh`'s `@define-color background/on_surface/primary/...` extraction — these names must exist in *both* `themes/css/<name>.css` and matugen-generated `colors.css`, or the two modes silently diverge). This is a hard constraint from PROJECT.md ("Both static preset themes and matugen dynamic themes work through the same pipeline").

## Architectural Patterns

### Pattern 1: Single Source of Truth Per App, Not Per System

**What:** Each app gets exactly one generated color file (`colors.conf`, `colors.css`, `style.css`) that both the static path and the dynamic (matugen) path write to, using the same variable names. The app's own hand-written config (`hyprland.conf`, `style.css` for waybar, etc.) never contains a literal hex value — it only sources/imports the generated file.
**When to use:** Always, for every app added to the pipeline (including future OSD and media-center widgets).
**Trade-offs:** Requires every app's stylesheet to actually support the include mechanism (`@import`, `source =`, `@define-color`). Apps that don't (Walker's GTK4 CSS engine reportedly does not resolve `@define-color` tokens the way GTK3 does) need a dedicated renderer that resolves variables to literal values at generation time — which is exactly what `walker-theme-gen.sh` already does. Keep that pattern explicit rather than trying to force every app into the same mechanism.

**Example (this repo, matugen side):**
```toml
[templates.hyprland]
input_path = "~/.config/matugen/templates/hyprland-colors.conf"
output_path = "~/.config/hypr/colors.conf"
post_hook = "hyprctl reload || true"
```

### Pattern 2: Mode-Branching Generator, Converging Distributor

**What:** One entrypoint script takes a mode (`static:<name>` or `materialyou`), branches internally only for the *generation* step (file copy vs. `matugen image`), then funnels into one shared "distribute + reload" tail regardless of mode.
**When to use:** Any system supporting both curated presets and generative theming from the same UI.
**Trade-offs:** The branch must fully converge — if the static path additionally does something the dynamic path doesn't (or vice versa), that divergence becomes an intermittent, mode-dependent bug. This repo's current `theme-switch.sh` mostly does this correctly (`apply_static_theme` and `apply_material_you` both end by calling `reload_all()`), but `theme-init.sh` reimplements both branches independently instead of calling the same functions — the exact anti-pattern this section warns against.

### Pattern 3: Reload Strategy Split by App Capability

**What:** Not all apps reload the same way. Classify each integration target into one of three reload strategies and pick per-app, not uniformly:
1. **Live signal reload** — app watches a signal and re-reads config in place. Hyprland (`hyprctl reload`), Kitty (`SIGUSR1`, or better, `kitty @ set-colors --all` via remote control socket for flicker-free reload), Waybar (`SIGUSR2`), SwayNC (`swaync-client -rs`).
2. **Settings-daemon reload** — app doesn't read a file at all, it reads a live gsettings/dconf key and repaints on the settings-changed signal. GTK apps' *dark/light mode* and *icon theme* fall here (`gsettings set org.gnome.desktop.interface color-scheme ...`). Critically, toggling a gsettings key to empty-then-back is a documented trick to force a change-notify even when the target value is unchanged (used in `gtk-reload.sh` for `gtk-theme` already; the missing piece is doing the equivalent for **palette/accent**, not just dark-mode).
3. **Restart-required reload** — app compiles/caches its stylesheet once at startup and has no file-watch or IPC reload path. Walker falls here per this repo's own comments in `walker-restart.sh`; GTK3 daemonized apps like `thunar --daemon` are being treated as restart-required in `gtk-reload.sh`, though GTK3's `~/.config/gtk-3.0/gtk.css` is documented to support live file-monitoring in many GTK3 versions — worth re-verifying before assuming restart is mandatory (flag for pitfalls/phase research, not resolved here).

**Trade-offs:** Restart-required reload is disruptive (loses window state, causes a visible flash) — use it only where signal/settings reload genuinely does not exist, and treat "does this app actually need a restart" as a question to re-verify per app rather than copy the heaviest fix everywhere.

### Pattern 4: GTK Chrome vs. Palette Separation

**What:** Treat "which named GTK theme is active" (chrome: widget shapes, e.g. `adw-gtk3-dark`) as a *different, rarely-changing* setting from "which colors that theme should render" (palette: accent/background/surface, changes every theme switch). GTK3 lets a later-loaded user `gtk.css` redefine `@define-color` tokens the named theme already defined, which is how palette overlay is supposed to work without changing the theme name. GTK4/libadwaita is more restrictive: libadwaita apps largely ignore custom named themes altogether and only respect a constrained `accent-color` enum via `gsettings set org.gnome.desktop.interface accent-color <name>` (libadwaita ≥ 1.6) plus `color-scheme` for dark/light — arbitrary wallpaper-derived hex accents are not fully supported for libadwaita-native (GTK4) apps without per-app CSS injection tricks, and never for sandboxed (Flatpak) apps.
**When to use:** Whenever the stack mixes GTK3 (Thunar, many legacy apps) and GTK4/libadwaita apps (newer GNOME-family apps, potentially Walker's rendering layer).
**Trade-offs:** This means "GTK apps generally follow theme switches" (this milestone's Active requirement) has a ceiling — GTK3 apps can be made to follow the full wallpaper-derived palette; GTK4/libadwaita apps realistically only follow discrete accent-color + dark/light, not arbitrary hex. Roadmap should scope the GTK4 sub-goal accordingly rather than treat it as the same problem as GTK3.

**Confidence:** MEDIUM — corroborated by two independent web sources (GitHub Gradience issue #641, gonwan.com GTK3/GTK4 theming article) describing libadwaita's `adw_style_manager_constructed()` hardcoding `gtk-theme-name` to `Adwaita-empty` and using its own `AdwSettings`/CSS providers layered on top of, not replacing, GTK4's theme mechanism.

## Data Flow

### Theme-switch flow (interactive, via Walker)

```
User: Super+Shift+T
    ↓
theme-switch.sh shows walker --dmenu picker
    ↓
Branch on selection:
  ├─ static preset  → cp themes/{static,css,gtk,kitty,yazi,vscodium}/<name>.* → canonical paths
  └─ Material You    → matugen image <current wallpaper> --source-color-index 0
                        (matugen/config.toml renders every [templates.*] entry,
                         writing directly to canonical paths AND firing its own
                         per-template post_hook, e.g. hyprctl reload, SIGUSR2 waybar)
    ↓ (both branches converge here)
Rebuild gtk.css = colors.css + gtk-base.css (GTK3 and GTK4 separately)
    ↓
reload_all():
  hyprctl reload
  pkill -SIGUSR2 waybar
  pkill -SIGUSR1 kitty
  swaync-client -rs
  gtk-reload.sh     (gsettings toggle, GTK_THEME env re-import, thunar restart)
  walker-restart.sh (kill socket + process, uwsm relaunch)
    ↓
echo "<name>" > ~/.cache/current-theme
```

Note the **double-application risk** in the Material You branch: matugen's own `post_hook`s (defined per-template in `matugen/config.toml`) already fire `hyprctl reload`, `pkill -SIGUSR2 waybar`, `swaync-client -rs`, `gtk-reload.sh`, and `walker-restart.sh` individually as each template renders — and then `theme-switch.sh`'s `reload_all()` fires the *same* set again afterward. This is redundant (not currently harmful beyond a flash/restart-storm) and is a candidate for simplification: pick one place to own reload — either matugen's per-template `post_hook`s, or the orchestrator's `reload_all()`, not both.

### Login/session-restore flow

```
uwsm session start → theme-init.sh (autostart)
    ↓
Read ~/.cache/current-theme (fallback: "catppuccin")
    ↓
Set wallpaper (awww img ~/Pictures/Wallpapers/current.jpg)
    ↓
Re-run the FULL apply logic inline (independently reimplemented —
does not call theme-switch.sh's apply_static_theme/apply_material_you/reload_all)
    ↓
echo "<theme>" > ~/.cache/current-theme
```

### Future add-on flows (planned, not yet built)

- **OSD (volume/brightness):** consumes the same canonical `colors.css`/`colors.conf` as any other app — needs one new matugen template + one new static preset variant + a reload mechanism appropriate to whichever OSD daemon is chosen (e.g. `swayosd-server` — verify whether it hot-reloads its own CSS or needs a restart, this is a build-order dependency, research before implementing).
- **Walker custom menus (power menu, settings, etc. "Omarchy-style"):** these are *new invocations of the existing walker binary* with `--dmenu`, exactly like `theme-switch.sh` and `waybar-switch.sh` already are. They automatically inherit whatever theme walker is currently rendering (`themes/rice/style.css`) — **zero new propagation work**, provided the Walker theming bug is fixed first. This is a strong argument for sequencing: fix Walker's core theme-follow bug before building new Walker-based menus, or the new menus inherit the same "stuck white" bug on day one.
- **Media center (now-playing widget):** if implemented as a Waybar module (e.g. `custom/mpris`), it inherits Waybar's existing `colors.css` automatically — no new integration needed. If implemented as a standalone widget (AGS/eww/GTK), it becomes a brand-new theming target requiring its own template + reload entry, following Pattern 1–3 above.

## Growth / Scope Considerations

| Concern | Today (7 themed apps) | After milestone 2 (10-11 themed surfaces: + OSD, walker menus, media center) |
|---------|------------------------|-------------------------------------------------------------------------------|
| Reload fan-out list | Hardcoded in 2 duplicated places (`theme-switch.sh`, `theme-init.sh`) | Must live in exactly one shared `reload.sh` or every new surface doubles the drift risk |
| Static preset completeness | 6 presets × 6 file types (`static/css/gtk/kitty/yazi/vscodium`) | Each new app adds one more file type per preset — a missing file for one preset silently breaks only that preset (why "both modes work through the same pipeline" must be a checked invariant, not an assumption) |
| Matugen template completeness | 10 `[templates.*]` entries | Same growth; a template output path typo doesn't fail loudly (matugen renders what's configured, silently skips what isn't) |

### Growth priorities

1. **First bottleneck:** logic duplication between the interactive switcher and login-init path. Any new app integration (OSD, media center) added to only one of the two will work after a manual switch but break/mismatch after reboot, or vice versa — an easy, hard-to-notice regression. Fix by extracting a shared library before adding new surfaces.
2. **Second bottleneck:** GTK4/libadwaita's hard ceiling on arbitrary palette theming (Pattern 4). If future add-ons are built as libadwaita apps (common default for new GTK4 tooling), they will hit the same "stuck" symptom Thunar/Walker have now unless scoped to accent-color + dark/light rather than full wallpaper-derived hex.

## Anti-Patterns

### Anti-Pattern 1: Reimplementing the Reload Sequence Per Entrypoint

**What people do:** Write the "apply colors, then reload everything" sequence once in the interactive switcher, then copy-paste a second (subtly different) version into the login/init script.
**Why it's wrong:** This repo's own git history shows this exact failure mode — multiple commits attempting to fix walker/thunar theming, none of which stuck, most plausibly because the fix landed in one script and not the other, or because the two scripts' color-generation steps drifted (e.g. one rebuilds `gtk.css` before restarting Thunar, the other might not).
**Do this instead:** One `apply-theme.sh <mode>` script, sourced/called by both the walker picker and the login autostart. Both callers pass just the theme identifier; all copy/generate/reload logic lives in one place.

### Anti-Pattern 2: Treating CSS-Variable Redefinition as Equivalent to a Live-Reload Signal

**What people do:** Assume that overwriting `colors.css` (which a running app's stylesheet already has loaded) is sufficient — the running process will "just pick it up."
**Why it's wrong:** Whether a running app notices a changed file depends entirely on whether it has a file-watcher on that specific path. GTK3 has partial support for this via its own `gtk.css` monitor; GTK4/libadwaita apps and Walker's compiled theme do not reliably re-read on file change and need an explicit signal (gsettings toggle) or full restart, matching what `walker-restart.sh`'s own comment already states ("Restart Walker service to pick up new CSS").
**Do this instead:** For each app, explicitly document and test which of the three reload strategies (Pattern 3) it needs — don't assume file-write alone is enough, and don't assume restart is always required either (that's needlessly disruptive for apps that do support live signals).

### Anti-Pattern 3: One Named GTK Theme Standing in for the Whole Palette

**What people do:** Hardcode `GTK_THEME=adw-gtk3-dark` everywhere (uwsm env, `theme-init.sh`, `gtk-reload.sh`) and expect per-preset color variation to come entirely from the separately-injected `colors.css`.
**Why it's wrong:** The named theme controls chrome (widget shapes/borders) and is a *legitimate* constant across presets — but conflating "the theme name never changes" with "therefore palette changes must come from CSS injection alone" ignores that libadwaita apps largely ignore that CSS injection (Pattern 4). The palette needs its own explicit propagation path (accent-color gsettings key for GTK4, `@define-color` overlay is fine for GTK3), not a single mechanism assumed to cover both.
**Do this instead:** Split "set GTK_THEME name" (rare, chrome-only) from "set palette" (every switch) and give palette a GTK4-aware path (`gsettings set org.gnome.desktop.interface accent-color ...` where the running libadwaita version supports it) in addition to the GTK3 CSS overlay.

## Integration Points

### External Services / Binaries

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| `matugen` | CLI invoked with wallpaper path; renders all `[templates.*]` from `matugen/config.toml` in one process, firing per-template `post_hook`s | Confidence HIGH (read directly from repo). Consider whether `post_hook`s or the orchestrator's own `reload_all()` should own reload — not both (see Data Flow note). |
| `awww` (wallpaper daemon) | `awww img <path> --transition-*` invoked both from `theme-init.sh` directly and from matugen's `[config.wallpaper]` `command` | Two invocation sites for the same action — confirm they don't race or double-transition when Material You mode also sets a wallpaper. |
| `uwsm` | Wraps every long-lived process launch (`uwsm app -- walker ...`, `uwsm app -- thunar --daemon`, `uwsm app -- waybar ...`) so it's tracked as a systemd scope | Env vars set in `uwsm/.config/uwsm/env*` are only read at session start; mid-session changes (like `GTK_THEME`) need the `systemctl --user import-environment` + `dbus-update-activation-environment` dance already present in `gtk-reload.sh` — this is the correct pattern, keep it when adding new env-dependent apps. |
| `gsettings` / dconf | GTK settings-daemon bridge; only works if `xdg-desktop-portal-gtk` (or equivalent) is running to back the schema | Already noted as a soft-dependency in `gtk-reload.sh` comment ("works if xdg-desktop-portal-gtk is running") — verify this is installed/enabled in `install.sh`, otherwise the entire GTK reload path silently no-ops. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Orchestrator ↔ Hyprland | `colors.conf` file + `hyprctl reload` | Clean, working today per PROJECT.md validated list. |
| Orchestrator ↔ Waybar | `colors.css` file + `SIGUSR2` | Believed working; unverified per PROJECT.md — cheap to confirm since the mechanism is standard and matches Omarchy/JaKooLit precedent. |
| Orchestrator ↔ SwayNC | `colors.css` file + `swaync-client -rs` | Same as Waybar — unverified but low-risk mechanism. |
| Orchestrator ↔ Kitty | `colors.conf` file + `SIGUSR1` | Working today. Consider migrating to `kitty @ set-colors` via the remote-control socket for flicker-free application (kitty must have `allow_remote_control` enabled) — optional polish, not a blocker. |
| Orchestrator ↔ GTK (3 and 4) | `colors.css` → concatenated `gtk.css` + `gsettings` toggle + env re-import | The weakest boundary today — mixes a file-based mechanism (GTK3-oriented) with a settings-daemon mechanism (dark/light only) and doesn't address GTK4/libadwaita's palette ceiling (Pattern 4). This is the boundary the milestone's "GTK apps generally follow theme switches" requirement lives on. |
| Orchestrator ↔ Walker | Literal-hex `style.css` (bespoke renderer) + full process/socket restart | Bespoke because Walker doesn't consume GTK named-color tokens the way GTK3 apps do — this is a deliberate, documented workaround (`walker-theme-gen.sh` header comment), not an accident. Keep this pattern; the bug is more likely in *when/whether* the restart actually fires cleanly (stale socket, timing) than in the renderer design itself. |
| Orchestrator ↔ Thunar | `colors.css` → `gtk.css` (GTK3 path) + forced `thunar --quit` / relaunch | Currently always restarts Thunar rather than relying on GTK3's live file-monitor — worth testing whether restart is actually necessary before keeping it as permanent behavior (adds visible disruption every switch). |

## Sources

- Direct repository inspection (HIGH confidence — primary source): `hypr/.config/hypr/scripts/theme-switch.sh`, `theme-init.sh`, `gtk-reload.sh`, `walker-restart.sh`, `walker-theme-gen.sh`, `waybar-switch.sh`, `wallpaper-switch.sh`; `matugen/.config/matugen/config.toml`; `gtk/.config/gtk-{3,4}.0/{settings.ini,gtk-base.css,colors.css}`; `uwsm/.config/uwsm/env*`; `walker/.config/walker/config.toml`; `stow.sh`, `install.sh`.
- [Theme System Architecture | basecamp/omarchy | DeepWiki](https://deepwiki.com/basecamp/omarchy/7.1-theme-system-architecture) — LOW confidence (secondary/AI-summarized source), used for the two-stage atomic-swap pattern and component-restart cascade concept.
- [Customization and Theming | basecamp/omarchy | DeepWiki](https://deepwiki.com/basecamp/omarchy/6-theming-and-customization) — LOW confidence, limited content returned.
- [Application-Specific Theming | basecamp/omarchy | DeepWiki](https://deepwiki.com/basecamp/omarchy/7.2-terminal-tools-and-utilities) — LOW confidence; GTK theming section not documented in source, noted as a gap.
- [Color and Theme System | JaKooLit/Hyprland-Dots | DeepWiki](https://deepwiki.com/JaKooLit/Hyprland-Dots/3.1-theming-system) — LOW confidence, corroborates the wallpaper→extraction→per-app-files→refresh pipeline shape and SIGUSR1/SIGUSR2 signal convention independently of Omarchy.
- [bug: Custom CSS is not working for GTK4 · Issue #641 · GradienceTeam/Gradience](https://github.com/GradienceTeam/Gradience/issues/641) — LOW confidence per classifier, but a primary GitHub issue describing libadwaita's `adw_style_manager_constructed()` behavior; used for Pattern 4 / Anti-Pattern 3.
- [Themes in Gtk3 and Gtk4 | 0x2B|~0x2B](https://www.gonwan.com/2026/02/17/themes-in-gtk3-and-gtk4/) — LOW confidence per classifier, corroborates the GTK3 vs GTK4/libadwaita distinction independently.
- Matugen GTK4/gsettings integration pattern (accent-color toggle trick) — general web search synthesis, LOW confidence, treat as a lead to verify against matugen's own documentation during phase-specific research, not as settled fact.

---
*Architecture research for: unified Hyprland desktop theming*
*Researched: 2026-07-07*
