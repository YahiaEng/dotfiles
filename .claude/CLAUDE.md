<!-- GSD:project-start source:PROJECT.md -->

## Project

**Arch + Hyprland Dotfiles**

Personal dotfiles for an Arch Linux + Hyprland desktop, managed with GNU stow and installed on fresh systems via a custom `install.sh`. The centerpiece is a dynamic theming system: custom scripts switch between static pre-configured themes and matugen-generated (wallpaper-driven) themes, propagating colors to every desktop component — Hyprland, kitty, thunar, GTK apps, and the Quickshell shell, which since v4.0 owns the bar, notification popups and centre, OSD indicators, power menu, media readout AND the application launcher/menu in one process.

**Core Value:** One theme switch — static or dynamic — instantly and consistently re-themes the entire desktop, and the whole setup reproduces from scratch with one script.

### Constraints

- **Tech stack**: Arch Linux, Hyprland, uwsm, stow, matugen — fixed; this project fixes and extends the existing setup, not a rewrite
- **Compatibility**: Theme switching must keep supporting both static preset and matugen dynamic modes through one pipeline
- **Reproducibility**: Everything must be installable on a fresh Arch system via `install.sh` + stow — no manual host-only state

<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->

## Technology Stack

## Recommended Stack

### Core Technologies

| Technology | Version (installed) | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| matugen-bin | 4.1.0 | Wallpaper → Material You color extraction, renders arbitrary text templates per app | De facto standard dynamic-theming engine across the 2025/2026 Hyprland rice ecosystem (Omarchy, end-4/dots-hyprland, HyDE, Caelestia, ML4W all use it or a near-identical templating pattern). Rust binary, no runtime deps, fast enough to run synchronously on wallpaper change. Confidence: LOW (websearch, uncorroborated by a second independent source) but consistent with what's already deployed here — no reason to replace it. |
| adw-gtk-theme | **not installed** (should be 6.5-1, official `extra` repo) | GTK3 port of the libadwaita look; the actual theme referenced by `gtk-theme-name=adw-gtk3-dark` in this repo's `gtk-3.0/settings.ini` and by `gsettings gtk-theme` | **Root-cause finding (HIGH confidence, verified directly on this machine):** `pacman -Q adw-gtk3` and `pacman -Q adw-gtk-theme` both fail — the theme is not installed, and `/usr/share/themes` + `~/.local/share/themes` contain no `adw-gtk3-dark` theme at all. GSettings and dconf **already correctly** report `gtk-theme='adw-gtk3-dark'` and `color-scheme='prefer-dark'`, and `xdg-desktop-portal-gtk.service` is active. Since the named theme doesn't exist on disk, every GTK3 app (Thunar) silently falls back to stock Adwaita (white) — this is a strong candidate for the actual root cause of "Thunar stuck on white," independent of any colors.css/gtk.css template logic. `install.sh` lists the AUR package name `adw-gtk3` (line ~150) which **does not exist** under that name in the AUR or official repos — the correct package is `adw-gtk-theme` in the official `extra` repo. This is very likely why it silently never installed. |
| libadwaita | 1.9.2 | GTK4 styling engine used by GTK4/libadwaita apps (GTK4 file pickers, nwg-look, etc.) | GTK4 apps do not use `gtk-theme-name` at all; they read `color-scheme`/`accent-color` live from `org.gnome.desktop.interface` via the portal, and read custom named-color overrides from `~/.config/gtk-4.0/gtk.css` at startup only. This repo's approach (matugen writes `gtk-4.0/colors.css`, concatenated into `gtk.css`) is the correct, standard pattern for full palette theming beyond what the portal's single accent-color knob offers. |
| GSettings / dconf + xdg-desktop-portal-gtk | dconf 0.49.0, xdg-desktop-portal-gtk 1.15.3 | The live-updating settings layer GTK3/GTK4 apps query on Wayland for theme name, icon theme, cursor, dark/light, and (GNOME47+) accent color | **Verified HIGH confidence:** this layer is already configured correctly in this repo (`gtk-reload.sh` calls `gsettings set org.gnome.desktop.interface ...`) and the portal service is running. Do not add `xsettingsd` — see "What NOT to Use." This part of the pipeline is not the bug. |
| ~~walker~~ | **RETIRED** (quick task 260822-sht, 2026-08-23) | Was: application launcher (GTK4 frontend) | **Uninstalled from repo AND host.** Replaced by the native QML launcher at `quickshell/.config/quickshell/modules/launcher/` — app search with a fuzzy matcher, a 6-route prefix router (calc/websearch/files/clipboard/symbols/providerlist), the 9 verb-based menu tree, and generic/confirm/emoji/clipboard/keybinds picker surfaces. `retirement-check walker` reports `status=retired failed_classes=0`. Do NOT reintroduce it or reference it as the launcher. |
| ~~elephant~~ | **RETIRED** (quick task 260822-sht, 2026-08-23) | Was: walker's backend data-provider daemon | **Uninstalled from repo AND host**, along with all 10 `elephant-*` provider packages. The launcher now reads `DesktopEntries` directly in-process; there is no second process and no Unix socket. `retirement-check elephant` reports `status=retired failed_classes=0`. Historical note, since much of this file's GTK/theming research predates the retirement: walker 2.x was a thin GTK4 UI over this separate socket-connected daemon, so old findings here that say "account for two processes" describe the retired stack, not the current one. |
| quickshell | (see quickshell/.config/systemd/user/quickshell.service) | Status bar | The QML shell root (`quickshell/.config/quickshell/shell.qml`) renders the bar, panels and overview. RETIRE-02 (Phase 18 Plan 20) retired waybar — the prior status bar — once the Quickshell bar's GATE-02 render gate passed; it is no longer installed on this host. The bar's colors/motion are driven by the same matugen/theme-engine pipeline via `Colours.qml`/`Motion.qml`, hot-reloading QML on file change natively rather than needing a signal-driven CSS reload. |
| quickshell (notification server) | (same shell process as the bar) | Notification daemon + control centre | **RETIRE-03 (Phase 19) retired swaync**, which previously held this role; it is uninstalled from repo *and* host. The Quickshell root now *is* the session's `org.freedesktop.Notifications` server: popups with swipe-dismiss, in-place `replaces_id` updates, action buttons, a slide-out centre with grouped history, and DND that survives a shell restart. There is no `swaync-client` reload hook any more — QML hot-reloads on file change, so the matugen `post_hook` that used to send `swaync-client -rs` is gone with the rest of the surface. Do not reintroduce a GTK3 notification daemon here; the whole-stylesheet-discard failure class that motivated the GTK4/QML moves applies to it. |

### Supporting Libraries (Milestone 2 add-ons)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| QML OSD (built) | `quickshell/.config/quickshell/modules/osd/Osd.qml` + `OsdSliderRow.qml` + `CapsLockBackend.qml` | Volume/brightness/caps-lock indicators | **RETIRE-04 (Phase 20 Plan 09) retired swayosd** and its libinput backend service, config-then-package; it is uninstalled from repo *and* host, and there is no `[templates.swayosd]` matugen entry any more. The indicators are now in-process QML (QOSD-01..04), coloured through `Colours.qml` and animated through `Motion.qml`, driven by `XF86Audio*`/`XF86MonBrightness*` binds in `hypr/.config/hypr/config/keybinds.lua`. **Caveat worth knowing before touching the brightness half:** this dev host has no backlight-class device (`/sys/class/backlight/` is empty), so brightness changes can only be exercised on laptop hardware — the path was operator-verified working on a backlight-equipped laptop on 2026-08-20 (see `.planning/todos/completed/2026-08-15-brightness-osd-unverifiable-on-desktop.md`). |
| playerctl | 2.4.1 (already installed) | CLI/library for MPRIS media-player control | Already present. Backing library for the QML bar's media capsule and the dashboard's media panel. |
| QML media capsule (built) | `quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml` + `modules/bar/MediaPopout.qml` | Now-playing widget in the bar, backed by `libplayerctl` via `modules/dashboard/MediaBackend.qml` | The media readout that a Waybar `mpris` module would have provided now lives directly in the QML bar as a capsule + popout pair, sharing the same `MediaBackend.qml` data source the dashboard's audio panel reads — not a Waybar module, since waybar was retired in Phase 18 Plan 20 (RETIRE-02). |
| ~~Custom playerctl-backed script module~~ | n/a | Superseded | This alternative applied only to a Waybar `custom` module (a script polled every N seconds, emitting JSON `{text, tooltip, class}`) — no longer relevant now that the bar is QML and reads `MediaBackend.qml` directly via Quickshell's own data bindings, not a polled external script. |
| QML menu tree (built) | `quickshell/.config/quickshell/modules/launcher/MenuTree.qml` + `MenuMode.qml` | The Super-tap menu — 9 verb-based roots (Apps, Capture, Tools, Style, Setup, Play, AI, Learn, System) with drill-in/back navigation | Replaced walker's `menus` elephant provider and its 6 TOMLs in quick task 260822-sht; all 30 non-clipboard leaf commands were carried over byte-identical. Add a new entry by editing `MenuTree.qml`'s data model — there is no external menu config any more. Reached via `quickshell:launcher-menu` (Super tap) or `qs ipc call launcher open menu`. |

### Development / Diagnostic Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| nwg-look | GTK3 settings editor built for wlroots compositors; writes directly to GSettings/dconf, bypassing `gtk-3.0/settings.ini` entirely | Not part of the automated pipeline — use manually during the theming bug-fix phase to distinguish "GSettings is wrong" from "the theme files/CSS are wrong." Given this repo's GSettings values already verified correct, nwg-look would likely confirm the missing-theme-package diagnosis rather than reveal a new issue. |
| `GTK_DEBUG=interactive <app>` (GTK Inspector) | Live-inspect which CSS rules/colors a running GTK3/GTK4 app actually resolved | Best tool for confirming whether Thunar or any GTK4 app is loading the intended `gtk.css`/`style.css` at all, vs. loading it but a rule not matching. (The QML launcher is NOT a GTK app — inspect it through `~/.cache/quickshell.log` and `Colours.qml`, not GTK Inspector.) |
| `dconf-editor` / `dconf dump /org/gnome/desktop/interface/` | Inspect the live GSettings state | Already used during this research to confirm `gtk-theme`, `color-scheme`, `icon-theme` are correctly set — keep using it as the first diagnostic step for any "app didn't re-theme" report, since it isolates GSettings from theme-file problems. |

## Installation

# Fix the confirmed missing/misnamed package (replace "adw-gtk3" in install.sh AUR_PKGS)

# Milestone 2 add-ons

# playerctl already installed; the QML bar's media capsule reads it via MediaBackend.qml

# (no bar-side package to install — the readout ships in this repo's quickshell/ tree)

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|--------------------------|
| matugen | pywal / wpgtk | Only if you need Python-ecosystem template hooks or `pywal`'s specific 16-color terminal palette algorithm; both are less actively maintained for Wayland/GTK4 in 2025/2026 and don't have matugen's Material You algorithm or first-class Hyprland templates. Not recommended here — would mean redoing the whole pipeline for no functional gain. |
| GSettings/dconf (already in place) | xsettingsd | Never on this stack — see "What NOT to Use." |
| QML media capsule + popout (`modules/bar/MediaConnectivityCapsule.qml`, `modules/bar/MediaPopout.qml`) | A separate polled script module | Never on this stack — waybar was retired in Phase 18 Plan 20 (RETIRE-02) and there is no bar-side module system to poll into. The capsule reads `modules/dashboard/MediaBackend.qml` directly via Quickshell's data bindings; extend that backend rather than adding an external polling script. |
| QML OSD (`modules/osd/Osd.qml`) | Any external OSD daemon — swayosd, `wob`-style scripts | Never on this stack — RETIRE-04 (Phase 20 Plan 09) deleted the external OSD daemon and its libinput service precisely so the indicators would live in the same process, palette and motion language as the bar. Reintroducing one would re-split the theming pipeline across a second toolkit for no functional gain. Extend `Osd.qml`/`OsdSliderRow.qml` instead. |
| nwg-look (diagnostic only) | lxappearance | lxappearance is an X11/Xwayland tool that requires workarounds under wlroots compositors and writes to `settings.ini` rather than GSettings — do not use it for diagnosing this repo's Wayland-native theming pipeline. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|--------------|
| `xsettingsd` | X11-only xsettings daemon; has zero effect on Wayland-native GTK3/GTK4 apps (Thunar under Hyprland reads GSettings, not the X11 xsettings protocol) — a common but outdated "fix" suggested in older forum threads | GSettings/dconf, already correctly configured in this repo — verified directly |
| `adw-gtk3` as an install target (as currently written in `install.sh`'s `AUR_PKGS`) | That package name doesn't exist in the AUR or official repos under that exact name — this is very likely why the theme silently never got installed on this machine | `adw-gtk-theme` (official `extra` repo, pacman, not AUR) |
| walker / elephant, in any form | Both were RETIRED in quick task 260822-sht (2026-08-23) and uninstalled from repo and host. Reintroducing either re-splits the launcher across a second toolkit and a second process, which is exactly what the migration removed — and would immediately red-light `retirement-check`'s blocking tier | The in-process QML launcher: `quickshell/.config/quickshell/modules/launcher/`. Extend `MenuTree.qml` for menu entries, add a mode Component in `Launcher.qml` for a new surface |
| Restarting only GTK3 apps' CSS files without restarting the process | GTK3 has no live CSS reload API — a new `gtk.css`/`colors.css` is inert until the process restarts | Kill and relaunch the GTK3 app (as `gtk-reload.sh` already does for Thunar) whenever `gtk-3.0/colors.css` changes |
| lxappearance for any Wayland-only diagnosis | X11-oriented, unreliable under Hyprland/wlroots | nwg-look |

## Stack Patterns by Variant

- Skip any xsettings-daemon-based fix entirely; the correct live-update path is GSettings/dconf + the portal, which this repo's `gtk-reload.sh` already targets correctly.
- Treat GTK3 apps (Thunar) as "restart required after CSS/theme-package change" and GTK4/libadwaita apps (GTK4 file pickers, nwg-look) as "restart required after CSS change, but dark/light + accent color can live-update via the portal if you choose to layer that on later." Quickshell surfaces are in neither class — QML hot-reloads on file change.
- Any launcher command that must outlive the surface MUST use `Quickshell.execDetached` (or live on the `LauncherState` singleton if it needs stdin). A component-scoped `Process` is destroyed with the LazyLoader the instant the launcher dismisses, killing its child mid-flight — this silently broke theme switching, emoji typing and clipboard paste during 260822-sht. Apps are launched via `uwsm app -- <id>.desktop` so they get their own systemd scope and survive a shell restart (`quickshell.service` is `KillMode=control-group`).
- Build any new bar widget as a QML capsule under `quickshell/.config/quickshell/modules/bar/`, colored through `Colours.qml` and animated through `Motion.qml`, rather than introducing a different toolkit/framework just for one widget. `colour-lint` (GATE-04) rejects hardcoded colors in QML, so read palette values from `Colours.qml` rather than writing literals.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|------------------|-------|
| ~~walker~~ / ~~elephant~~ | n/a — both RETIRED and uninstalled (260822-sht, 2026-08-23) | The launcher is in-process QML now; there is no second binary and no socket protocol to keep version-matched. |
| gtk3 3.24.52 | adw-gtk-theme 6.5-1 | Once installed, `adw-gtk-theme` provides the `adw-gtk3-dark`/`adw-gtk3` theme names already referenced by this repo's `settings.ini` and GSettings — no other config change needed. |
| gtk4 4.22.4 | libadwaita 1:1.9.2-1 | Current libadwaita supports the GNOME47+ accent-color GSettings key; this repo does not currently rely on it (uses full named-color CSS overrides instead), which is the more complete theming approach and should be kept rather than switched to the accent-color API alone. |
| quickshell | matugen-bin 4.1.0 | The bar reads its palette from `Colours.qml`, regenerated by the matugen/theme-engine pipeline. QML hot-reloads on file change natively, so no signal-driven reload hook is needed — unlike the retired waybar's `SIGUSR2` post_hook, which Phase 18 Plan 20 removed along with the rest of the surface. |

## Sources

- websearch: "matugen dynamic color generation tool Hyprland github version templates" — confidence LOW
- websearch: "GTK3 gtk.css hot reload live theme change without restart" — confidence LOW
- websearch: "GTK4 libadwaita accent color gsettings xdg-desktop-portal wlroots" — confidence LOW
- websearch: "nwg-look GTK theme switcher gsettings dconf wlroots" — confidence LOW
- websearch + webfetch (walkerlauncher.com/docs): Walker/elephant architecture and theming/config keys — confidence LOW
- websearch: "waybar SIGUSR2 reload style.css live theme" (incl. Alexays/Waybar#3986, #3728) — confidence LOW
- websearch: "swaync swaync-client reload css style theming matugen" — confidence LOW
- websearch: "swayosd install Hyprland systemd service volume brightness OSD" — confidence LOW
- websearch: "waybar cava mpris playerctl now playing module custom widget" — confidence LOW
- websearch: "Omarchy basecamp Hyprland theme architecture" (DeepWiki basecamp/omarchy) — confidence LOW
- websearch: "xsettingsd Thunar GTK3 theme Wayland Hyprland gsettings not applying" (incl. Hyprland GH discussions #339, #5867) — confidence LOW
- websearch: "adw-gtk3 theme arch linux official repos pacman package extra" — confidence LOW, but corroborated directly against `pacman -Si adw-gtk-theme` on the target machine (HIGH-confidence direct verification)
- **Direct system verification on target machine (HIGH confidence — ground truth, not a web claim):** `pacman -Q`/`-Qi`/`-Si` for matugen-bin, waybar, swaync, playerctl, gtk3, gtk4, dconf, libadwaita, xdg-desktop-portal-gtk/hyprland, walker, elephant, elephant-*, adw-gtk3, adw-gtk-theme; `gsettings get org.gnome.desktop.interface {gtk-theme,color-scheme,icon-theme}`; `dconf dump /org/gnome/desktop/interface/`; `systemctl --user status xdg-desktop-portal-gtk.service`; `pgrep -fa walker elephant`; repo inspection of `matugen/.config/matugen/config.toml`, `gtk/.config/gtk-{3,4}.0/*`, `hypr/.config/hypr/scripts/{gtk-reload,walker-restart}.sh`, `walker/.config/walker/config.toml`, `thunar/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml`, `install.sh`, `hypr/.config/hypr/config/autostart.conf`

<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:

- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
