# Stack Research

**Domain:** Arch Linux + Hyprland dotfiles — unified dynamic desktop theming (matugen) + OSD/launcher/media add-ons
**Researched:** 2026-07-07
**Confidence:** MEDIUM (ecosystem claims are web-sourced/LOW-MEDIUM per source hierarchy; every claim about *this repo's actual state* was verified directly on the target machine — pacman, gsettings, dconf, systemctl, running processes — and is treated as HIGH-confidence ground truth, called out explicitly below)

This is not a greenfield stack pick — the stack is fixed (per PROJECT.md constraints). This document verifies that the fixed stack is the correct 2025/2026 standard, and pinpoints exactly where the current pipeline diverges from how each component is supposed to be driven.

## Recommended Stack

### Core Technologies

| Technology | Version (installed) | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| matugen-bin | 4.1.0 | Wallpaper → Material You color extraction, renders arbitrary text templates per app | De facto standard dynamic-theming engine across the 2025/2026 Hyprland rice ecosystem (Omarchy, end-4/dots-hyprland, HyDE, Caelestia, ML4W all use it or a near-identical templating pattern). Rust binary, no runtime deps, fast enough to run synchronously on wallpaper change. Confidence: LOW (websearch, uncorroborated by a second independent source) but consistent with what's already deployed here — no reason to replace it. |
| adw-gtk-theme | **not installed** (should be 6.5-1, official `extra` repo) | GTK3 port of the libadwaita look; the actual theme referenced by `gtk-theme-name=adw-gtk3-dark` in this repo's `gtk-3.0/settings.ini` and by `gsettings gtk-theme` | **Root-cause finding (HIGH confidence, verified directly on this machine):** `pacman -Q adw-gtk3` and `pacman -Q adw-gtk-theme` both fail — the theme is not installed, and `/usr/share/themes` + `~/.local/share/themes` contain no `adw-gtk3-dark` theme at all. GSettings and dconf **already correctly** report `gtk-theme='adw-gtk3-dark'` and `color-scheme='prefer-dark'`, and `xdg-desktop-portal-gtk.service` is active. Since the named theme doesn't exist on disk, every GTK3 app (Thunar) silently falls back to stock Adwaita (white) — this is a strong candidate for the actual root cause of "Thunar stuck on white," independent of any colors.css/gtk.css template logic. `install.sh` lists the AUR package name `adw-gtk3` (line ~150) which **does not exist** under that name in the AUR or official repos — the correct package is `adw-gtk-theme` in the official `extra` repo. This is very likely why it silently never installed. |
| libadwaita | 1.9.2 | GTK4 styling engine used by GTK4/libadwaita apps (Walker, GTK4 file pickers, etc.) | GTK4 apps do not use `gtk-theme-name` at all; they read `color-scheme`/`accent-color` live from `org.gnome.desktop.interface` via the portal, and read custom named-color overrides from `~/.config/gtk-4.0/gtk.css` at startup only. This repo's approach (matugen writes `gtk-4.0/colors.css`, concatenated into `gtk.css`) is the correct, standard pattern for full palette theming beyond what the portal's single accent-color knob offers. |
| GSettings / dconf + xdg-desktop-portal-gtk | dconf 0.49.0, xdg-desktop-portal-gtk 1.15.3 | The live-updating settings layer GTK3/GTK4 apps query on Wayland for theme name, icon theme, cursor, dark/light, and (GNOME47+) accent color | **Verified HIGH confidence:** this layer is already configured correctly in this repo (`gtk-reload.sh` calls `gsettings set org.gnome.desktop.interface ...`) and the portal service is running. Do not add `xsettingsd` — see "What NOT to Use." This part of the pipeline is not the bug. |
| walker | 2.16.2 | Application launcher (GTK4 frontend) | Actively maintained, GTK4 + `gtk4-layer-shell`, the de facto Hyprland launcher successor to wofi/rofi in 2025/2026 rices (Omarchy ships it). Already the chosen tool per PROJECT.md. |
| elephant | 2.21.0 (+ elephant-desktopapplications, elephant-calc, elephant-clipboard, elephant-symbols, elephant-menus) | Walker's backend data-provider daemon (search/apps/clipboard/etc.), separate process communicating over a Unix socket | **Architecture fact (HIGH confidence, verified: both processes running via `uwsm app --`):** modern Walker (2.x) is a thin GTK4 UI on top of this separate `elephant` service — this is a structural change from older single-binary Walker docs/tutorials still circulating online. Any theming or functionality fix must account for **two** processes, not one. Version skew between walker and elephant across an update can break the protocol — pin/update both together. |
| waybar | 0.15.0 | Status bar | Standard Hyprland bar; already chosen. Supports both signal-driven (`SIGUSR2`) and config-driven (`"reload_style_on_change": true`) live CSS reload — this repo's `config-*.jsonc` files do **not** currently set `reload_style_on_change`, relying solely on matugen's `pkill -SIGUSR2 waybar` post_hook, which is valid but should be verified against the known upstream issue where tooltip CSS sometimes doesn't fully refresh via SIGUSR2 (Alexays/Waybar#3986). |
| swaync (SwayNotificationCenter) | 0.12.6 | Notification daemon + control center | Standard Hyprland notification daemon; already chosen. Reload mechanism is `swaync-client -rs` (already used as matugen post_hook, correct pattern) or `swaync-client --reload-config` for config.json changes. Note: swaync's upstream CSS is only tested against default GTK3/Adwaita selectors — heavy custom CSS can require re-verification after a swaync version bump. |

### Supporting Libraries (Milestone 2 add-ons)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| swayosd | 0.3.1 (official `extra` repo) | GTK-based OSD for volume/brightness/capslock, themeable via `~/.config/swayosd/style.css` | For the planned OSD indicators. Runs as a GTK layer-shell popup + a libinput-backend systemd `--user` service that listens for hardware key events directly (works even without a keybind, e.g. hardware volume keys); pair with `swayosd-client --output-volume raise/lower/mute-toggle` and `--brightness raise/lower` bound to `XF86Audio*`/`XF86MonBrightness*` keys in Hyprland. Matches this repo's named-color CSS theming approach exactly, so it slots into the existing matugen template pattern with a new `[templates.swayosd]` entry. |
| playerctl | 2.4.1 (already installed) | CLI/library for MPRIS media-player control | Already present. Backing library for both Waybar's built-in `mpris` module and any custom now-playing script. |
| Waybar `mpris` module (built-in) | ships with waybar 0.15.0 | Now-playing widget in the bar, backed by `libplayerctl` | **Recommended default** for the planned "media now playing" widget — it's a built-in waybar module (no external script to maintain), defaults to `playerctld` which automatically follows whichever player is currently active, and supports per-player icons and click/scroll actions out of the box. Only reach for a custom script-based module (see below) if you need an Omarchy-style popup/panel rather than an inline bar segment. |
| Custom playerctl-backed script module | n/a | Same data, full layout control | Use only if the built-in `mpris` module's inline text format can't express the desired UI (e.g. a click-to-expand "now playing" popover with album art). Waybar's `custom` module type runs a script every N seconds and consumes JSON `{text, tooltip, class}` output; wire `playerctl metadata`/`play-pause`/`next`/`previous` to `on-click`/`on-scroll-up`/`on-scroll-down`. More moving parts to keep themed and maintained than the built-in module — prefer the built-in unless there's a concrete UX reason not to. |
| Walker custom menu layouts (built-in) | walker 2.16.2 | Omarchy-style custom menus (power menu, settings, etc.) inside Walker itself | Walker supports per-provider/per-set custom layouts and a `menus` elephant provider (already enabled in this repo's `config.toml`) driven by simple config, plus Lua-scriptable custom menus for anything more dynamic. This is the standard way Omarchy builds its power-menu/settings-style Walker menus — no separate launcher/menu tool needed. |

### Development / Diagnostic Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| nwg-look | GTK3 settings editor built for wlroots compositors; writes directly to GSettings/dconf, bypassing `gtk-3.0/settings.ini` entirely | Not part of the automated pipeline — use manually during the theming bug-fix phase to distinguish "GSettings is wrong" from "the theme files/CSS are wrong." Given this repo's GSettings values already verified correct, nwg-look would likely confirm the missing-theme-package diagnosis rather than reveal a new issue. |
| `GTK_DEBUG=interactive <app>` (GTK Inspector) | Live-inspect which CSS rules/colors a running GTK3/GTK4 app actually resolved | Best tool for confirming whether Thunar/Walker are loading the intended `gtk.css`/`style.css` at all, vs. loading it but a rule not matching. |
| `dconf-editor` / `dconf dump /org/gnome/desktop/interface/` | Inspect the live GSettings state | Already used during this research to confirm `gtk-theme`, `color-scheme`, `icon-theme` are correctly set — keep using it as the first diagnostic step for any "app didn't re-theme" report, since it isolates GSettings from theme-file problems. |

## Installation

```bash
# Fix the confirmed missing/misnamed package (replace "adw-gtk3" in install.sh AUR_PKGS)
sudo pacman -S adw-gtk-theme          # official extra repo, NOT an AUR package

# Milestone 2 add-ons
sudo pacman -S swayosd
systemctl --user enable --now swayosd-libinput-backend.service
# playerctl already installed; no action needed for the waybar mpris module
# (it ships inside the waybar package itself)
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|--------------------------|
| matugen | pywal / wpgtk | Only if you need Python-ecosystem template hooks or `pywal`'s specific 16-color terminal palette algorithm; both are less actively maintained for Wayland/GTK4 in 2025/2026 and don't have matugen's Material You algorithm or first-class Hyprland templates. Not recommended here — would mean redoing the whole pipeline for no functional gain. |
| GSettings/dconf (already in place) | xsettingsd | Never on this stack — see "What NOT to Use." |
| Waybar built-in `mpris` module | Custom `playerctl`-backed script module | When the desired now-playing UI needs a popover/expanded panel beyond a single bar segment's inline text — otherwise the built-in module is strictly less code to maintain. |
| swayosd | Custom `wob`/`wlogout`-style OSD scripts | Only if you specifically want a minimalist single-bar OSD (`wob`) instead of the fuller GTK popup swayosd provides; swayosd is the more actively developed and more themeable (full CSS) option and already integrates cleanly with the matugen named-color pattern used elsewhere in this repo. |
| nwg-look (diagnostic only) | lxappearance | lxappearance is an X11/Xwayland tool that requires workarounds under wlroots compositors and writes to `settings.ini` rather than GSettings — do not use it for diagnosing this repo's Wayland-native theming pipeline. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|--------------|
| `xsettingsd` | X11-only xsettings daemon; has zero effect on Wayland-native GTK3/GTK4 apps (Thunar under Hyprland reads GSettings, not the X11 xsettings protocol) — a common but outdated "fix" suggested in older forum threads | GSettings/dconf, already correctly configured in this repo — verified directly |
| `adw-gtk3` as an install target (as currently written in `install.sh`'s `AUR_PKGS`) | That package name doesn't exist in the AUR or official repos under that exact name — this is very likely why the theme silently never got installed on this machine | `adw-gtk-theme` (official `extra` repo, pacman, not AUR) |
| Assuming Walker is still a single self-contained binary (per many older Walker tutorials/blog posts) | Walker 2.x is split into `walker` (GTK4 frontend) + `elephant` (backend data daemon over a Unix socket); fixes aimed only at `walker`'s own config/CSS can miss issues actually caused by `elephant` not running, mismatched versions, or a stale socket | Verify both `elephant` and `walker --gapplication-service` are running and version-matched before debugging CSS/theme specifically |
| Restarting only GTK3 apps' CSS files without restarting the process | GTK3 has no live CSS reload API — a new `gtk.css`/`colors.css` is inert until the process restarts | Kill and relaunch the GTK3 app (as `gtk-reload.sh` already does for Thunar) whenever `gtk-3.0/colors.css` changes |
| lxappearance for any Wayland-only diagnosis | X11-oriented, unreliable under Hyprland/wlroots | nwg-look |

## Stack Patterns by Variant

**Because this setup is pure Wayland/Hyprland (no Xorg/XWayland-dependent theming path):**
- Skip any xsettings-daemon-based fix entirely; the correct live-update path is GSettings/dconf + the portal, which this repo's `gtk-reload.sh` already targets correctly.
- Treat GTK3 apps (Thunar) as "restart required after CSS/theme-package change" and GTK4/libadwaita apps (Walker) as "restart required after CSS change, but dark/light + accent color can live-update via the portal if you choose to layer that on later."

**Because Walker is now a client/daemon pair:**
- Any walker-restart script must ensure `elephant` is also healthy (not just relaunch `walker --gapplication-service`) before concluding a theme fix is complete — a stale/mismatched `elephant` won't surface as a CSS problem but can look like one (blank/default UI).

**If Milestone 2 media widget needs richer UI than an inline bar segment:**
- Use a custom `playerctl`-backed waybar `custom` module or a small GTK4 popover, following the same named-color CSS convention as the rest of the stack, rather than introducing a different toolkit/framework just for this widget.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|------------------|-------|
| walker 2.16.2 | elephant 2.21.0 | Both currently installed and running on this machine; keep them upgraded together since they speak a private protocol over a Unix socket — a walker/elephant version skew is a plausible (if unconfirmed) contributor to launcher misbehavior beyond just theming. |
| gtk3 3.24.52 | adw-gtk-theme 6.5-1 | Once installed, `adw-gtk-theme` provides the `adw-gtk3-dark`/`adw-gtk3` theme names already referenced by this repo's `settings.ini` and GSettings — no other config change needed. |
| gtk4 4.22.4 | libadwaita 1:1.9.2-1 | Current libadwaita supports the GNOME47+ accent-color GSettings key; this repo does not currently rely on it (uses full named-color CSS overrides instead), which is the more complete theming approach and should be kept rather than switched to the accent-color API alone. |
| waybar 0.15.0 | `reload_style_on_change` config key | Available in this version; not currently enabled in this repo's `config-*.jsonc` — safe, low-risk addition as a belt-and-suspenders alongside the existing `SIGUSR2` post_hook. |

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

---
*Stack research for: Arch + Hyprland unified dynamic theming*
*Researched: 2026-07-07*
