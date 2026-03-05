# ❄️ Dynamic Wayland Dotfiles

A highly modular, dynamically themed Arch Linux Wayland setup. Built around **Hyprland** and driven by **GNU Stow**, this environment automatically generates Material You color palettes based on your current wallpaper, seamlessly applying them across the entire UI.

*Optimized for NVIDIA GPUs and high-refresh-rate displays.*

![Desktop Showcase](https://via.placeholder.com/1200x600?text=Insert+Hero+Screenshot+Here)

## ✨ Features

* **Dynamic Theming:** Instant, system-wide color generation using `Matugen` and `swww`.
* **Graceful Fallback:** Beautiful Catppuccin Mocha default theme if no wallpaper is set.
* **NVIDIA Ready:** Pre-configured environment variables and DRM kernel mode settings for glitch-free Wayland.
* **Modular Architecture:** Cleanly separated configuration files managed entirely via `GNU Stow`.
* **Automated Deployment:** Single-command installation script to bootstrap a fresh Arch system.

## 🛠️ The Stack

| Component | Choice | Description |
| :--- | :--- | :--- |
| **Window Manager** | [Hyprland](https://hyprland.org/) | Dynamic Wayland compositor with smooth animations. |
| **Status Bar** | [Waybar](https://github.com/Alexays/Waybar) | Highly customizable Wayland bar with centered workspaces. |
| **Terminal** | [Kitty](https://sw.kovidgoyal.net/kitty/) | GPU-accelerated terminal emulator with transparency. |
| **App Launcher** | [Fuzzel](https://codeberg.org/dnkl/fuzzel) | Blazing fast, Wayland-native application launcher. |
| **Notifications** | [SwayNC](https://github.com/ErikReider/SwayNotificationCenter) | Notification daemon with a drop-down control center. |
| **Lockscreen** | [Hyprlock](https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/) | Secure lockscreen featuring blurred wallpaper backgrounds. |
| **Idle Daemon** | [Hypridle](https://wiki.hyprland.org/Hypr-Ecosystem/hypridle/) | Manages monitor DPMS and auto-locking for power saving. |
| **Theming Engine** | [Matugen](https://github.com/InioX/matugen) | Material You color generation injected directly into configs. |
| **Wallpaper** | [swww](https://github.com/LGFae/swww) | Efficient animated wallpaper daemon. |

## 🚀 Installation

> **Note:** Ensure you have the proprietary NVIDIA drivers installed and `nvidia-drm.modeset=1` enabled in your bootloader parameters before proceeding.

Clone the repository and run the automated installation script:

```bash
git clone [https://github.com/YOUR_USERNAME/dotfiles.git](https://github.com/YOUR_USERNAME/dotfiles.git) ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The script will automatically install required packages via `yay` and use `stow` to link the configurations to your `~/.config` directory.

## 🎨 Applying Themes

To change your wallpaper and instantly theme your entire system (Hyprland borders, Waybar, Fuzzel, Kitty, SwayNC, and Hyprlock), use the included script:

```bash
theme-switcher.sh /path/to/your/wallpaper.png
```

## ⌨️ Keybindings

This setup uses the `SUPER` (Windows) key as the primary modifier.

| Keybind | Action |
| :--- | :--- |
| `SUPER + Return` | Open Kitty Terminal |
| `SUPER + D` | Open Fuzzel App Launcher |
| `SUPER + N` | Toggle SwayNC Control Center |
| `SUPER + L` | Lock Screen (Hyprlock) |
| `SUPER + Q` | Close Active Window |
| `SUPER + V` | Toggle Floating Window |
| `SUPER + F` | Toggle Fullscreen |
| `SUPER + SHIFT + M`| Exit Hyprland |
| `SUPER + [1-5]` | Navigate Workspaces |
| `SUPER + SHIFT + [1-5]` | Move Active Window to Workspace |

## 📁 Repository Structure

```text
~/.dotfiles/
├── fuzzel/            # Launcher configuration
├── hyprland/          # Core WM, env vars, monitors, lock, and idle
├── kitty/             # Terminal emulator settings
├── matugen/           # Material You templates for config injection
├── scripts/           # Custom bash scripts (theme-switcher)
├── swaync/            # Notification daemon and control center
├── waybar/            # Status bar layout and dynamic CSS
├── install.sh         # Automated setup and deployment script
└── README.md          # You are here
```

## 🤝 Acknowledgments

* Inspiration drawn from various amazing setups on `r/unixporn`.
* Color fallback scheme provided by [Catppuccin](https://github.com/catppuccin/catppuccin).