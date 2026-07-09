# Stack Research: v2.0 Desktop Expansion

**Domain:** Arch Linux + Hyprland dotfiles — desktop utilities, menus, and theme-pipeline surface expansion
**Researched:** 2026-07-09
**Confidence:** MEDIUM (package existence/versions verified directly against `pacman -Si` / AUR RPC on the target machine — HIGH; usage patterns and "which tool wins" judgment calls are web-search-sourced — LOW per source, corroborated where noted)

**Supersedes:** The 2026-07-07 STACK.md (v1.0 Theme Pipeline Repair). That research is preserved in git history; its findings (adw-gtk-theme install fix, walker/elephant architecture, matugen pipeline) are now shipped and validated — see PROJECT.md "Validated" section. This file covers ONLY the NEW stack additions needed for the v2.0 Desktop Expansion milestone and does not repeat already-validated v1.0 findings except where a v2.0 feature changes how an existing tool is used.

**Important ground-truth finding before anything else:** two of the nine planned feature areas are largely already available in this repo via already-installed packages and just need wiring/UI work, not new packages:

- **Emoji picker** — `elephant-symbols` (AUR, already installed) gives native "multi-locale emoji and symbol support" inside walker, already bound to the `.` prefix in `walker/.config/walker/config.toml`. No `bemoji`/`rofimoji` needed.
- **Clipboard history** — `elephant-clipboard` (AUR, already installed) gives native clipboard history inside walker, already bound to the `:` prefix in the same config. `cliphist` (extra, also already installed) is used by a *separate*, redundant keybind (`$mainMod, C` in `keybinds.conf`) that duplicates this — see "What NOT to Use."

## Recommended Stack

### Core Technologies (new packages to add)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **satty** | 0.21.1-1 (official `extra`) | Screenshot annotation (arrows, blur, text, crop) after `grim`/`slurp` capture | Verified directly (`pacman -Si satty`, HIGH confidence). GTK4 + libadwaita — consistent with this repo's existing GTK4 stack (walker) and its named-color CSS theming pattern, unlike GTK3-based `swappy`. Explicitly documented upstream as "inspired by Swappy and Flameshot," an "almost drop-in replacement for swappy" — same pipe pattern (`grim - | satty -f - --copy-command wl-copy`) drops straight into this repo's existing `screenshot.sh`, which already does `grim` + `slurp` capture and just needs an `--annotate` branch added. Confidence: MEDIUM (websearch description, HIGH-confidence direct version verification). |
| **wf-recorder** | 0.6.0-1 (official `extra`) | Screen/region video recording (mp4) for the recording half of the screenshot suite | Verified directly (HIGH confidence — official repo). The established, widely-documented wlroots screen recorder; depends only on ffmpeg libs + pulse, all already satisfiable (`ffmpeg 8.1.2` already installed). `wl-screenrec` (AUR-only, 0.2.0-2, low adoption — checked, exists but far less battle-tested) is reportedly smoother on GPUs with working VAAPI hw-encode, but is AUR-maintenance risk for a "reproduces from scratch" project; not worth it unless recording stutter becomes a measured problem. Confidence: LOW (websearch comparison, uncorroborated) + HIGH (version/repo fact). |
| **gifski** | 1.34.0-2 (official `extra`) | mp4 → high-quality GIF conversion, the "GIF" half of screen recording | Verified directly (HIGH confidence). Purpose-built (libimagequant-based) GIF encoder that produces materially better quality than a plain `ffmpeg -vf palettegen` pipeline, at the cost of one extra pass; ffmpeg is already installed as a dependency of `wf-recorder`, so this is additive not foundational — use `wf-recorder` → mp4 → `gifski` for the "recording + GIF" requirement rather than trying to do GIF encoding live. |
| **hyprpicker** | 0.4.7-1 (AUR) | Color picker (pick a color from anywhere on screen) | Verified directly (HIGH confidence — package exists in AUR with that exact name/version). Built by the Hyprland org itself specifically for wlroots compositors; has `-a`/`--autocopy` (pipes to `wl-copy`, already installed) and `-n`/`--notify` (desktop notification on pick) built in — no extra glue script needed beyond a keybind. This is the de facto standard color picker across the whole Hyprland rice ecosystem. |
| **swayosd** | 0.3.1-1 (official `extra`) | Themed volume/brightness/caps-lock OSD | Not yet installed on the machine (confirmed via `pacman -Q swayosd` failing) despite being fully justified in v1.0 research; carrying it forward as a v2.0 install target since the OSD work is explicitly in this milestone's scope. Styled via `~/.config/swayosd/style.css`, loaded with `swayosd-server -s ~/.config/swayosd/style.css` in `exec-once`; this is the same named-color CSS pattern as every other themed surface in this repo, so it slots into `matugen/config.toml` as a new `[templates.swayosd]` entry rendering into the existing state-dir contract. |
| **ttf-\*-nerd font packages** (curated starter set: `ttf-jetbrains-mono-nerd`, `ttf-hack-nerd`, `ttf-cascadia-code-nerd` — `ttf-firacode-nerd` already installed) | 3.4.0-2 (official `extra`, all of them) | Font pool for the nerd-font switcher | Verified directly: **every** Nerd Font ships as its own official-repo package under the `ttf-<name>-nerd` (or `otf-<name>-nerd`) naming convention — confirmed via `archlinux.org` package search returning 60+ such packages, all `extra`, all version-locked together at `3.4.0-2`/`3.4.0-4`. This means "install more fonts to switch between" is zero AUR risk. The switcher itself is a script, not a package — see Supporting Libraries. |

### Supporting Libraries / Scripts (no new package — build on existing pipeline)

| Library/Approach | Purpose | When to Use |
|---------|---------|-------------|
| `elephant-symbols` (already installed) via walker `.` prefix, or a dedicated `walker -s emoji` set | Emoji picker | Default/primary path. Add a `[sets.emoji]` block to `walker/.config/walker/config.toml` (`providers = ["symbols"]`) so a keybind can invoke it directly (`walker -s emoji`) instead of requiring the user to remember the `.` prefix — mirrors the existing `[sets.runner]` pattern already in this repo's config. |
| `elephant-clipboard` (already installed) via walker `:` prefix, or `walker -s clipboard` | Clipboard history (view + re-copy) | Default/primary path — same `[sets.clipboard]` pattern as above. Retire the redundant `cliphist`-piped keybind (see "What NOT to Use"). |
| `elephant-menus` (already installed, AUR 2.21.0-1) + Lua scripts in `~/.config/elephant/menus/` | Native custom menus (Utilities, AI dashboard, Game center, Power, Settings, Keybind cheat-sheet) with per-entry `Icon` fields, all rendered inside walker | Preferred over an Omarchy-style bash+`walker --dmenu` dispatcher for the v2.0 Super-tap menu **because** it's already installed, already wired into `walker/.config/walker/config.toml`'s `default` provider list, supports icons natively (`Icon = "..."` field per entry, using system icon-theme names — pairs directly with the icon-theme-picker feature), and needs no extra process/parsing glue. Each submenu (Utilities, AI dashboard, Game center, etc.) is one `.lua` file with a `GetEntries()` function; nesting is done by having a `Value`/`Action` in one menu invoke `walker -s <submenu-set>`. Omarchy's own dispatcher-script pattern is the older approach (their walker version predates the mature `elephant-menus`/Lua provider) — do not copy it wholesale for a walker 2.16.2 setup. |
| `bindr` Hyprland keyword | Super-tap-alone → open menu | `bindr = SUPER, Super_L, exec, walker -s mainmenu` (release-triggered bind on the modifier key itself) is the standard, already-documented Hyprland pattern for "tap modifier alone." No `bindr`/xremap/wlr-which-key needed — this is a one-line addition to `hypr/.config/hypr/config/keybinds.conf`, consistent with the file's existing bind conventions (currently only `bind =` is used; `bindr =` would be new syntax to the repo but is standard Hyprland). |
| Custom bash script parsing `keybinds.conf` comments, rendered via `walker --dmenu` or a themed GTK popup | Keybind cheat-sheet | Simplest, zero-new-dependency option: the repo's own `keybinds.conf` already has inline `#` comments next to most binds (see existing `# Switch theme`, `# Switch waybar` etc.) — a script that `grep`s `^bind` lines and their trailing comment and feeds them to `walker --dmenu` (read-only display) matches this repo's existing script conventions (`theme-switch.sh`, `waybar-switch.sh`) exactly. `wlr-which-key` (AUR, 1.3.0-1, only 4 votes) was evaluated and rejected — see "What NOT to Use." |
| `matugen` new `[templates.hyprlock]`, `[templates.swayosd]`, `[templates.zen]` entries in `matugen/config.toml` | Extend the theme pipeline to hyprlock, swayosd, and Zen browser | Each new themed surface is a new template + new `contract.json` entry, following the exact pattern already proven for the 10 existing surfaces (`hyprland`, `waybar`, `kitty`, `swaync`, `yazi`, `vscodium`, `wlogout`, `gtk3`, `gtk4`, `walker`) — this is the correct integration point, not a new theming mechanism. |
| `~/.zen/<profile>/chrome/userChrome.css` (+ `toolkit.legacyUserProfileCustomizations.stylesheets` = `true` in `about:config`, set once via `user.js`) | Zen browser theme-follows pipeline | Zen Browser (verified installed: `zen-browser-bin 1.21.5b-1`, AUR) explicitly dropped WebExtension-based theming — **Pywalfox and Firefox theme extensions do not work on Zen**. The only supported live-theming path is `userChrome.css` in the Firefox-style profile `chrome/` folder. Matugen should render a new `zen-colors.css` template directly into that `chrome/` folder (or into `~/.local/state/theme/zen-colors.css`, `@import`-ed from a static `userChrome.css` stub placed by `stow`) using the same named-CSS-variable convention as the GTK templates. `python-pywalfox` (AUR 2.9.0-1) is NOT the right tool for Zen specifically — see "What NOT to Use." |
| Custom bash script: `fc-list \| grep -i nerd`, then rewrite `kitty.conf font_family`, `gsettings set org.gnome.desktop.interface monospace-font-name`, and VSCodium `settings.json` `editor.fontFamily` | Nerd-font switcher | No dedicated "font manager" tool is needed or recommended — every candidate font is already a discrete official package (see Core Technologies), so switching is just: enumerate installed `*Nerd Font*` families via `fc-list`, present via `walker --dmenu`, then template-write the 3 config touchpoints and trigger the existing per-app reload (kitty: restart per existing "GTK3 has no live reload" pattern already established for other apps; GTK4 apps: gsettings is live). |
| Custom bash script: `gsettings set org.gnome.desktop.interface icon-theme "<name>"` + enumerate `/usr/share/icons` and `~/.local/share/icons` | Icon theme picker (browse/install/apply, incl. to Thunar) | `papirus-icon-theme` (extra, already installed, 20250501-1) is a good default/curated seed; "browse and install new icon themes" is best served by shipping a short curated list (Papirus variants, Tela, etc.) with pacman/AUR names in a picker script rather than embedding a general theme-store client — keeps the reproducibility guarantee (`install.sh` can pre-install the curated set; anything outside it is user-opt-in AUR). This is the exact same GSettings mechanism this repo's `gtk-reload.sh` already uses correctly for the color palette — no new propagation mechanism needed. |
| `waybar` second `config-vertical.jsonc` + `style-vertical.css`, using native `"position": "left"` | Vertical (left) bar layout | Waybar supports `position: left/right/top/bottom` in the same config schema already used; this repo already has a multi-layout switching mechanism (`waybar-switch.sh` + multiple `config-*.jsonc` files) — a vertical layout is one more file in that existing set, not a new mechanism or package. |
| `waybar` built-in `mpris` module (ships in waybar 0.15.0, already installed) | Media center popup — inline bar segment | Confirmed still the recommended default (per v1.0 STACK research, re-verified here): built-in, `libplayerctl`-backed, `playerctld`-following, zero extra script to maintain, supports per-player icons + click/scroll actions. Use for the always-visible bar segment. |
| Custom GTK4 popover (or a `custom` waybar module invoking a small GTK4 script) driven by `playerctl` | Media center popup — expandable panel with album art (Spotify/browser/YouTube) | The built-in `mpris` module is inline-text-only; a click-to-expand panel with album art requires a small custom popover, consistent with how modern rices implement "media center" popups (form factor confirmed via research: expandable GTK popover, not a separate standalone app). Should reuse the shared named-color CSS theming convention, not a different toolkit. |
| `swaync-client -t -sw` bound to a `waybar` `custom` module's `on-click` | Notification center opened from waybar | No new package — `swaync-client` ships with the already-installed `swaync 0.12.6`. The repo already has this exact invocation bound to a Hyprland keybind (`$mainMod, N`); the v2.0 work is exposing the same command as a clickable waybar module/icon, not adding new plumbing. |
| CSS-only auto-hide/transparency + a small idle-triggered position-jitter script | Waybar OLED-safe behavior | No dedicated "OLED burn-in" package exists for Wayland bars (verified — search turned up general OLED-display advice, not bar-specific tooling). Best-practice synthesis from general OLED mitigation research: (1) auto-hide-on-idle is the highest-leverage, lowest-risk option — waybar can be shown/hidden via a small `hyprctl`-driven script on an idle timer, reusing `hypridle` if already present in the repo rather than adding a second idle-watcher; (2) keep the bar's own background at low alpha/dark (already true of this repo's Material You palettes); (3) true "pixel shift" (moving the whole bar a few px periodically) is a nice-to-have, implementable as a cron-like script nudging the bar's margin via `hyprctl` layer rules on a long interval (e.g. every 10 min) — lower priority than auto-hide. Recommend shipping auto-hide + dark/low-alpha as the default, with pixel-shift as an optional toggle. Confidence: LOW (no domain-specific source found; general OLED-care research applied to this context) — flag for validation during phase execution rather than treating as settled. |

### Development / Diagnostic Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `zsh`'s built-in `zprof` + `hyperfine` (verify via `pacman -Si hyperfine`, official `extra`) | Profile kitty's slow startup | Research confirms kitty's own binary startup is rarely the bottleneck — it's almost always the shell (`zsh`) init cost (`compinit` security checks, stacked plugin managers, non-lazy plugin loads) compounded by kitty invoking a login+interactive shell (double init). Profile with `zprof` inside `.zshrc`, benchmark with `hyperfine 'kitty -e true'`, and fix at the shell-config layer (`zshell/` stow package), not by replacing/reconfiguring kitty itself. |
| `GTK_DEBUG=interactive satty` / `... hyprlock` | Verify new themed surfaces actually pick up matugen-rendered colors | Same diagnostic already established and proven useful in v1.0 for Walker/Thunar; reuse for the new hyprlock/swayosd/satty theming work. |

## Installation

```bash
# Core additions — official repos (pacman)
sudo pacman -S --needed \
  satty \
  wf-recorder \
  gifski \
  swayosd

# AUR (yay/paru)
yay -S --needed \
  hyprpicker

# Nerd fonts — curated starter set (all official repo, extend as desired)
sudo pacman -S --needed \
  ttf-jetbrains-mono-nerd \
  ttf-hack-nerd \
  ttf-cascadia-code-nerd \
  ttf-firacode-nerd

# Already installed, verify present in install.sh PACMAN_PKGS/AUR_PKGS:
#   grim, slurp, wl-clipboard, cliphist, playerctl, papirus-icon-theme,
#   noto-fonts-emoji, elephant + elephant-{clipboard,symbols,menus,calc,
#   runner,websearch,providerlist,desktopapplications,files}, walker,
#   zen-browser-bin, ffmpeg
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|--------------------------|
| `satty` (GTK4, extra repo) | `swappy` (GTK3, extra repo) | Only if you specifically want to avoid any GTK4/libadwaita runtime dependency for annotation — not a concern here since GTK4/libadwaita is already core to this repo's stack via Walker. `swappy` is the older, still-maintained tool `satty` was explicitly designed to succeed. |
| `wf-recorder` (extra) | `wl-screenrec` (AUR) | Only if measured stutter with `wf-recorder` on this specific GPU is a real problem AND the GPU has working VAAPI hw-encode — `wl-screenrec` is reported smoother but is AUR-only (extra maintenance/rebuild risk) and far less battle-tested (lower adoption). Don't switch preemptively. |
| `wf-recorder` mp4 → `gifski` | Live/direct GIF capture | `gifski` needs a finished video as input; there's no equivalent "record straight to GIF with comparable quality" tool worth adding — the two-step pipeline is standard practice and keeps quality high. |
| `elephant-menus` + Lua (native walker menus) | Omarchy-style bash + `walker --dmenu` dispatcher script | Use the bash+dmenu approach only for one-off, throwaway pickers (this repo already does this well for `theme-switch.sh`/`waybar-switch.sh`/`powermenu.sh`) — for the *structured, iconized, nested* Super-tap main menu specifically requested in this milestone, native `elephant-menus` is less code and gives real icon support, which the dmenu approach does not. |
| `hyprpicker` | Custom `grim`+`slurp`+pixel-read script | No reason to hand-roll this — `hyprpicker` is purpose-built by the Hyprland org, already has autocopy/notify flags satisfying the "pick from screen" requirement completely. |
| Curated `ttf-*-nerd` package list + fc-list-driven script | A GUI "font manager" app (e.g. gnome-font-viewer) | Not needed — this repo's convention is small custom scripts wired into the theme/reload pipeline, not general-purpose GUI utilities; a GUI font manager also can't apply the font to kitty.conf/VSCodium settings.json itself. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|--------------|
| Adding `bemoji` or `rofimoji` as the emoji picker | Duplicates functionality already provided natively by the already-installed `elephant-symbols` provider, which is already wired into `walker/.config/walker/config.toml` — adds a redundant process/dependency and a second, inconsistently-themed UI surface (rofi/wofi-based) in a repo that has explicitly standardized on walker+elephant and removed wofi. | `elephant-symbols` via the existing `.` prefix, or a new `walker -s emoji` set |
| Keeping the existing `cliphist`-piped keybind (`bind = $mainMod, C, exec, cliphist list \| walker --dmenu \| cliphist decode \| wl-copy`) as the clipboard history mechanism | It's a second, independent clipboard-history store (cliphist's own history file) running in parallel with `elephant-clipboard`'s own history — two clipboard histories that will silently disagree with each other over time; `cliphist` is also piped through `walker --dmenu`, which doesn't get walker's real themed clipboard UI/thumbnails. | Retire the `cliphist` keybind; use `elephant-clipboard` via `:` prefix or a dedicated `walker -s clipboard` set, consistent with the emoji-picker decision above. If `cliphist` truly isn't used anywhere else, consider dropping it from `install.sh` in a later cleanup pass (flag for roadmap, not blocking this research). |
| `wlr-which-key` (AUR, 1.3.0-1) for the keybind cheat-sheet | It's a "keymap manager"/command-execution popup (which-key style — press a key, see and trigger sub-actions), not a read-only reference display; low AUR adoption (4 votes); pulls in a Rust build dependency for something a 20-line bash script covers. Wrong tool for "cheat-sheet," not just a worse one. | A script that parses `keybinds.conf`'s existing inline comments and displays them via `walker --dmenu`, matching this repo's established script conventions |
| `python-pywalfox` for Zen browser theming | Zen Browser has explicitly dropped support for WebExtension-based theming (which Pywalfox depends on) — installing it will not work on Zen specifically, even though the package still functions for stock Firefox/Thunderbird. This is a Zen-specific incompatibility, not a general pywalfox problem. | Matugen template rendering directly into the Zen profile's `chrome/userChrome.css`, with `toolkit.legacyUserProfileCustomizations.stylesheets` enabled once via a `user.js` drop-in |
| `xsettingsd` for any of the new surfaces (icon theme picker, font switcher) | Already established as wrong for this stack in v1.0 research — X11-only, zero effect on Wayland-native GTK apps. Still applies to every new gsettings-touching feature in v2.0. | GSettings/dconf, already correctly wired |
| A general-purpose GUI "icon theme installer/store" app | Overkill and reproducibility-breaking — this repo's core value is "reproduces from scratch via install.sh"; a live theme-store client depends on network state/external services at runtime and can't be scripted into `install.sh`. | A curated list of pacman/AUR icon-theme package names baked into the picker script, pre-installable via `install.sh`; anything beyond that list is a manual, explicitly-opt-in AUR install by the user |
| `steam`/`lutris`/`heroic-games-launcher-bin` as new required packages for "Game center" | None of these are currently installed on this machine, and the milestone's Game Center requirement is a **menu/launcher submenu**, not a mandate to install specific game platforms. Force-installing large gaming stacks in `install.sh` would bloat a personal-desktop reproducibility script with multi-GB dependencies the user may not want on every fresh install. | Build the Game Center submenu to launch whatever's present (desktop-file discovery via `elephant-desktopapplications`, already installed) and treat specific launchers (Steam, Lutris, Heroic) as optional/commented entries in `install.sh`, not hard requirements |

## Stack Patterns by Variant

**If the OLED auto-hide script needs idle detection:**
- Reuse `hypridle` if already present in the repo (check `hypr/.config/hypr/` for an idle daemon config) rather than adding a second idle-watcher.
- Because duplicate idle-detection daemons commonly race/conflict over DPMS and lock state in Hyprland setups.

**If Zen browser's profile path isn't stable across `install.sh` runs:**
- Do not hardcode `~/.zen/<random-profile-id>/`; resolve it at theme-apply time via `zen-browser-bin`'s `profiles.ini`, the same way Firefox-profile tooling does.
- Because the profile directory name is randomly generated per-install and will break the "reproduces from scratch" guarantee if hardcoded.

**If a new nerd font needs to be the kitty default vs. just available for switching:**
- Only rewrite `kitty.conf`'s `font_family` line via the switcher script's template action; don't hand-edit multiple places.
- Because kitty (GTK-adjacent but not GTK) requires a full process restart on font change — same "restart required" pattern already established for GTK3 apps in this repo, so route it through the same kind of reload step, not a live-reload attempt.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|------------------|-------|
| satty 0.21.1-1 | gtk4 4.22.4, libadwaita 1.9.2 (already installed) | Satty's `Depends On` (verified via `pacman -Si`) includes `gtk4`, `libadwaita`, `hicolor-icon-theme` — all already satisfied by this repo's existing GTK4 stack; no version conflict risk. |
| wf-recorder 0.6.0-1 | ffmpeg 8.1.2 (already installed) | wf-recorder's shared-lib deps (`libavcodec.so=62-64` etc.) are satisfied by the already-installed `ffmpeg 2:8.1.2-7`; no separate ffmpeg pin needed. |
| elephant 2.21.0 / elephant-symbols / elephant-clipboard / elephant-menus | walker 2.16.2 | Already-established version-pinning concern from v1.0 research still applies: keep all `elephant-*` AUR packages and `walker` upgraded together, since a skew can break the private socket protocol — this applies equally to the newly-relevant `elephant-symbols`/`elephant-clipboard`/`elephant-menus` providers this milestone now actively depends on for UI, not just background search. |
| zen-browser-bin 1.21.5b-1 | matugen-bin 4.1.0 | No direct package dependency, but the theming *mechanism* is incompatible with the WebExtension-based approach (pywalfox) this repo might otherwise reach for by analogy with other apps — matugen must target `userChrome.css` directly, a first for this repo's template set (all prior templates target native app config formats, not a browser chrome stylesheet). |
| ttf-\*-nerd packages | fontconfig (system) | All Nerd Font packages in the official `extra` repo are version-locked together at `3.4.0-2`/`3.4.0-4` (one shared patch-set release) — safe to mix-and-match any subset without version-skew concerns. |

## Sources

- **Direct system verification on target machine (HIGH confidence — ground truth):** `pacman -Si`/`-Q` for grim, slurp, satty, swappy, wf-recorder, wl-screenrec, cliphist, wl-clipboard, hyprpicker, swayosd, playerctl, bemoji, rofimoji, papirus-icon-theme, ttf-jetbrains-mono-nerd, noto-fonts-emoji, hyprshot, grimblast-git, wtype, ydotool, hyprlock, steam, lutris, heroic-games-launcher-bin, zen-browser(-bin), firefox, gifski, ffmpeg; `archlinux.org` package search for the full `ttf-*-nerd`/`otf-*-nerd` catalogue; AUR RPC v5 `info`/`search` for elephant-* providers, wl-screenrec, bemoji, grimblast, zen-browser(-bin), python-pywalfox, nerdfetch, wlr-which-key; repo inspection of `walker/.config/walker/config.toml`, `hypr/.config/hypr/config/keybinds.conf`, `hypr/.config/hypr/scripts/screenshot.sh`, `matugen/.config/matugen/config.toml`, `theme-engine/.config/theme-engine/contract.json`, `wlogout/.config/wlogout/`.
- websearch: "grim slurp satty swappy screenshot annotation tool Hyprland Wayland current version" — confidence LOW
- websearch: "wf-recorder vs wl-screenrec screen recording Hyprland Wayland GIF video" — confidence LOW
- websearch: "cliphist wl-clipboard clipboard history walker rofi Hyprland" — confidence LOW
- websearch: "hyprpicker color picker Hyprland Wayland AUR pacman" — confidence LOW
- websearch: "emoji picker Wayland Hyprland walker rofi bemoji" — confidence LOW
- websearch + webfetch (walkerlauncher.com/docs/providers): elephant provider catalogue (symbols/emojis, clipboard, menus, calc, runner, files, websearch, providerlist, unicode, playerctl, wireplumber) — confidence LOW-MEDIUM
- webfetch (hansschnedlitz.com): custom Walker Lua menus, icon fields, GetEntries() structure — confidence LOW
- websearch: "swayosd volume brightness OSD theming CSS style.css Hyprland" — confidence LOW
- websearch: "Hyprland bindr keyword tap super key only trigger menu bindings.conf" — confidence LOW
- websearch: "Zen browser theming userChrome.css dynamic colors Linux matugen pywalfox" — confidence LOW
- websearch: "matugen zen browser userChrome.css template github example" — confidence LOW
- websearch: "waybar OLED burn-in mitigation pixel shift auto-hide transparency Wayland bar" — confidence LOW (no domain-specific source found)
- websearch: "waybar vertical left position layout config Hyprland" — confidence LOW
- websearch: "waybar mpris module popup album art now playing widget custom" — confidence LOW
- websearch: "hyprlock matugen dynamic theming config.toml template" — confidence LOW
- websearch: "nerd fonts font switcher script fontconfig gsettings kitty vscodium GTK apply" — confidence LOW
- websearch: "icon theme switcher script papirus tela Thunar gsettings icon-theme apply Linux" — confidence LOW
- websearch: "wlogout redesign icons modern rice Hyprland Omarchy style config example" — confidence LOW
- websearch: "kitty terminal slow startup fix profiling shell integration zsh" — confidence LOW
- websearch: "Omarchy super key tap menu walker custom icons launcher structure basecamp" — confidence LOW
- websearch: "wlr-which-key Hyprland keybind cheatsheet popup Wayland" — confidence LOW

---
*Stack research for: Arch + Hyprland dotfiles — v2.0 Desktop Expansion*
*Researched: 2026-07-09*
