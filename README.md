# 🍚 Hyprland Dotfiles — Material You + Multi-Theme Rice

A modular, stow-managed Arch Linux rice featuring **Material You dynamic theming** (via Matugen + awww) alongside **6 hand-crafted static themes**, with theme switching and bar orientation switching through custom Walker menus.

## ✨ Features

- **Dynamic Material You theming** — colors auto-generated from your wallpaper via Matugen
- **6 static themes** — Catppuccin Mocha, Dracula, Rosé Pine, Gruvbox Dark, Tokyo Night, Nord
- **Quickshell bar** — horizontal/vertical orientation switching, workspaces, media/connectivity capsule, tray, clock
- **Walker-powered switching** — change themes and bar orientation on the fly
- **NVIDIA optimized** — env variables for 2160×1440 @ 165Hz
- **Smooth animations** — Material Design 3 inspired bezier curves
- **GNU Stow managed** — clean symlink structure from `~/dotfiles` → `~/.config`
- **Modular Hyprland config** — separate files for monitors, keybinds, animations, window rules

## 📦 Stack

| Component       | Tool                  |
|:----------------|:----------------------|
| Window Manager  | Hyprland              |
| Status Bar      | Quickshell            |
| Launcher        | Walker                |
| Terminal        | Kitty                 |
| Notifications   | Quickshell            |
| Wallpaper       | awww                  |
| Theming         | Matugen               |
| Lock Screen     | Hyprlock              |
| Idle Daemon     | Hypridle              |
| Dotfile Manager | GNU Stow              |
| Font            | FiraCode Nerd Font    |

## 📂 Structure

```
~/dotfiles/
├── install.sh                          # Package installer
├── stow.sh                             # Symlink setup
├── .stow-local-ignore
│
├── hypr/.config/hypr/
│   ├── hyprland.conf                   # Main config (sources modules)
│   ├── env.conf                        # NVIDIA + Wayland env vars
│   ├── monitors.conf                   # 2160x1440@165Hz
│   ├── autostart.conf                  # Startup apps
│   ├── animations.conf                 # Smooth bezier animations
│   ├── keybinds.conf                   # All keybindings
│   ├── windowrules.conf                # Float/opacity/layer rules
│   ├── colors.conf                     # Active colors (auto-managed)
│   ├── hypridle.conf
│   ├── hyprlock.conf
│   └── scripts/
│       ├── theme-switch.sh             # Walker theme picker
│       ├── bar-orientation.sh          # Walker bar orientation picker
│       ├── wallpaper-switch.sh         # Walker wallpaper picker + matugen
│       ├── quickshell-launch.sh        # Guarded launcher for the QML shell root
│       ├── theme-init.sh               # Restores theme on login
│       └── screenshot.sh               # grim + slurp screenshots
│
├── quickshell/.config/quickshell/
│   ├── shell.qml                       # Shell root — bar, panels, overview
│   └── modules/
│       ├── bar/                        # Bar capsules (workspace, media, tray, clock)
│       ├── dashboard/                  # Super+D drawer panels
│       └── overview/                   # Super (tap) overview grid
│
├── kitty/.config/kitty/
│   ├── kitty.conf
│   └── colors.conf                     # Active colors (auto-managed)
│
├── matugen/.config/matugen/
│   ├── config.toml                     # Matugen settings + template registry
│   └── templates/                      # Matugen input templates (12 registered)
│       ├── hyprland-colors.lua
│       ├── kitty-colors.conf
│       ├── gtk-colors.css              # Shared by the gtk3 + gtk4 targets
│       ├── qml-palette.json            # Feeds the Quickshell bar's Colours.qml
│       └── ...                         # walker, yazi, vscodium, fzf, hyprlock, zen, satty
│
├── theme-engine/.config/theme-engine/
│   ├── theme-apply                     # The switch entry point (static + dynamic)
│   ├── theme-doctor                    # Pipeline health gate
│   ├── theme-parity                    # Output-contract parity gate
│   ├── contract.json                   # Declared render targets
│   ├── motion.json                     # Shared motion tokens
│   └── palettes/                       # Static per-theme palettes (20 themes)
│
└── wallpapers/Pictures/Wallpapers/     # Your wallpaper collection
```

## 🚀 Installation

```bash
# 1. Clone the repo
git clone https://github.com/<your-user>/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Install dependencies
chmod +x install.sh stow.sh
./install.sh

# 3. Create symlinks
./stow.sh

# 4. Add wallpapers
cp /path/to/your/wallpapers/*.jpg ~/Pictures/Wallpapers/

# 5. Log into Hyprland
# The theme-init script will apply the default (Catppuccin) theme on first login
```

## ⌨️ Keybindings

| Binding              | Action                    |
|:---------------------|:--------------------------|
| `Super + Return`     | Open Kitty terminal       |
| `Super` (tap)        | Open Walker launcher      |
| `Super + Q`          | Close window              |
| `Super + F`          | Toggle fullscreen         |
| `Super + V`          | Toggle floating           |
| `Super + L`          | Lock screen               |
| `Super + N`          | Toggle notification center|
| `Super + Shift + T`  | **Theme switcher**        |
| `Super + B`          | **Bar orientation switcher**|
| `Super + Shift + B`  | **Wallpaper picker**      |
| `Super + C`          | Clipboard history         |
| `Print`              | Screenshot (full)         |
| `Super + Print`      | Screenshot (area select)  |
| `Super + 1-0`        | Switch workspace 1-10     |
| `Super + Shift + 1-0`| Move window to workspace  |

## 🎨 Theme System

**Static themes** copy pre-defined color files to each app's config directory. **Material You** runs `matugen` against the current wallpaper to generate a fresh palette.

All themes produce the same set of color variables (primary, surface, etc.) so every app stays consistent. The `theme-init.sh` script remembers your last choice and reapplies it on login.

### Adding a new static theme

1. Create `~/.config/themes/static/mytheme.conf` (Hyprland `$variable = rgba(...)` format)
2. Create `~/.config/themes/css/mytheme.css` (`@define-color variable #hex;` format)
3. Create `~/.config/themes/kitty/mytheme.conf` (kitty color format)
4. Add a menu entry in `~/.config/hypr/scripts/theme-switch.sh`

## 📄 License

MIT — do whatever you want with it.
