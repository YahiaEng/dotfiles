# Requirements: Arch + Hyprland Dotfiles — v2.0 Desktop Expansion

**Defined:** 2026-07-09
**Core Value:** One theme switch — static or dynamic — instantly and consistently re-themes the entire desktop, and the whole setup reproduces from scratch with one script.

## v2 Requirements

Requirements for the Desktop Expansion milestone. Each maps to roadmap phases.

### Bug Fixes & Performance

- [ ] **FIX-01**: wlogout shutdown completes reliably — root cause of the blank-screen hang diagnosed (keyboard-vs-mouse test, journalctl/coredumpctl) and fixed before any redesign work
- [ ] **FIX-02**: Hyprlock registers the first keystrokes after lock activation — no more failed-auth loops from dropped input (root-caused, not patched around)
- [ ] **FIX-03**: Kitty startup is fast — startup profiled, cause identified, and fixed

### Redesigns

- [ ] **WLOG-01**: wlogout fully redesigned to modern-rice standards — sharp assets (no low-res/stretched images), sleek layout, themed via the shared pipeline
- [ ] **LOCK-01**: Hyprlock redesigned with a modern look, colors sourced from the shared theme pipeline (already wired to `~/.local/state/theme/hyprland.conf`), with a documented lockout-recovery procedure used during testing

### Screenshot Suite

- [ ] **SHOT-01**: User can capture region/window/full-screen screenshots with smooth animations and clear feedback (freeze, save + copy, notification)
- [ ] **SHOT-02**: User can annotate captures (arrows, text, shapes, blur) before saving/copying
- [ ] **SHOT-03**: User can record the screen or a region to video, with GIF export

### Utility Scripts

- [ ] **UTIL-01**: User can pick emoji from a simple, modern picker (walker + elephant-symbols) and have it inserted/copied
- [ ] **UTIL-02**: User can pick any color from the screen (hyprpicker) and get it copied in usable format (hex)
- [ ] **UTIL-03**: User can view recent clipboard history and re-copy any item (walker + elephant-clipboard), with a size cap and wipe policy from day one (no unbounded plaintext secrets)
- [ ] **UTIL-04**: User can select from installed icon themes and apply them to Thunar/GTK live (apply-only; a couple of quality icon themes bundled in install.sh)
- [ ] **UTIL-05**: User can switch nerd fonts across kitty, vscodium, GTK, and waybar from one picker (nerd fonts only, enumerated from installed ttf-*-nerd packages)

### Super-Key Menu

- [ ] **MENU-01**: Tapping $SUPER alone opens the main walker menu (Omarchy-style, custom icons), while ALL existing $SUPER+key combos keep working — verified by a keybind regression sweep
- [ ] **MENU-02**: Utilities submenu invokes the utility scripts (screenshot, emoji, color picker, clipboard, icon theme, font switcher)
- [ ] **MENU-03**: AI dashboard entry — submenu of AI app launchers plus a dedicated pre-configured Hyprland AI workspace
- [ ] **MENU-04**: Game center submenu with launchers (Steam etc.)
- [ ] **MENU-05**: Power menu entry (lock/logout/suspend/reboot/shutdown)
- [ ] **MENU-06**: Settings menu entry (theme switch, wallpaper, network, etc.)
- [ ] **MENU-07**: Keybind cheat-sheet — searchable reference generated from keybinds.conf

### Waybar Evolution

- [ ] **BAR-01**: Waybar has OLED-safe behavior — auto-hide when idle/unneeded plus translucent minimal styling
- [ ] **BAR-02**: Pixel-shift mitigation attempted for static bar elements (best-effort; no reference implementation exists — descope with evidence if infeasible)
- [ ] **BAR-03**: An additional vertical (left) waybar layout exists and works with theme switching
- [ ] **BAR-04**: Media center accessible from waybar integrating mpris players (Spotify, browser/YouTube) — form factor per modern-rice research
- [ ] **BAR-05**: Notification center opens from a waybar button (swaync overlay: view, clear, interact with notifications)

### OSD

- [ ] **OSD-01**: SwayOSD volume/brightness/caps-lock indicators bound to media keys, themed via the shared pipeline (new matugen template + contract.json entry)

### Theming Expansion

- [ ] **THM-01**: Theme pipeline supports light mode — both dark-hardcoded chokepoints fixed (`lib/gtk.sh` gsettings + `gtk-3.0/settings.ini`), mode auto-detected from palette lightness, contract/parity gates extended with a light fixture
- [ ] **THM-02**: Additional popular static presets shipped, including light themes (e.g. catppuccin-latte), as palette JSONs through the existing pipeline
- [ ] **THM-03**: Wallpapers are organized per-theme; with a static theme active the picker restricts choices to that theme's set, with Material You any wallpaper is allowed
- [ ] **THM-04**: Wallpaper picker redesigned to Omarchy-level aesthetics
- [ ] **THM-05**: Zen browser follows theme switches (matugen-rendered userChrome.css into the resolved profile; restart-based reload like other GTK3-class surfaces)

### Tech Debt

- [ ] **DEBT-01**: rsync listed explicitly in install.sh PACMAN_PKGS (v1.0 audit carry-over)

## Future Requirements

Deferred beyond v2.0. Tracked but not in the current roadmap.

- **ICON-BROWSE**: Browse and install NEW icon themes from within the picker (repo/AUR discovery) — apply-only shipped in v2.0
- **POLISH-01**: One cohesive animation/easing language across Hyprland, waybar, walker, swaync, OSD — revisit after v2.0 surfaces exist

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Quickshell/QML custom shell rewrite | Contradicts "extend, don't rewrite"; end-4/Caelestia patterns are aspiration only |
| Full GUI settings app | Settings menu launches existing tools; no custom settings UI |
| Custom AI assistant widgets/sidebars | AI dashboard = launchers + workspace, not built-in assistant UI |
| Gaming-mode session switching | Game center is a launcher submenu, not a session manager |
| Re-theme on every wallpaper auto-cycle | Latency/flicker cost; re-theme only on explicit user action |
| Full GTK4/libadwaita palette theming | Structurally unsupported upstream; dark/light + accent ceiling (validated v1.0) |
| Other distros / compositors | Personal Arch + Hyprland setup |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| (populated by roadmap) | | |

**Coverage:**

- v2 requirements: 30 total
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 30

---
*Requirements defined: 2026-07-09*
