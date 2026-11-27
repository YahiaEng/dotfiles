# 🍚 Hyprland Dotfiles — Material You + Multi-Theme Rice

A modular, Stow-managed Hyprland setup for native Arch Linux and Arch WSL2 featuring **Material You dynamic theming** (via Matugen + awww) alongside **6 hand-crafted static themes**, with theme switching and bar orientation switching through the native QML launcher's own pickers.

## ✨ Features

- **Dynamic Material You theming** — colors auto-generated from your wallpaper via Matugen
- **6 static themes** — Catppuccin Mocha, Dracula, Rosé Pine, Gruvbox Dark, Tokyo Night, Nord
- **Quickshell bar** — horizontal/vertical orientation switching, workspaces, media/connectivity capsule, tray, clock
- **In-shell picker switching** — change themes and bar orientation on the fly, from the native QML launcher
- **Hardware-aware setup** — native GPU and display detection, plus Windows display and connectivity integration in Weaselway
- **Smooth animations** — Material Design 3 inspired bezier curves
- **GNU Stow managed** — clean symlink structure from `~/dotfiles` → `~/.config`
- **Modular Hyprland config** — separate files for monitors, keybinds, animations, window rules

## 📦 Stack

| Component       | Tool                  |
|:----------------|:----------------------|
| Window Manager  | Hyprland              |
| Status Bar      | Quickshell            |
| Launcher        | Quickshell (native QML) |
| Terminal        | Kitty                 |
| Prompt          | Starship              |
| Notifications   | Quickshell            |
| Wallpaper       | awww                  |
| Theming         | Matugen               |
| Lock Screen     | Quickshell (in-process) |
| Idle Daemon     | Hypridle              |
| Dotfile Manager | GNU Stow              |
| Font            | FiraCode Nerd Font    |

## 📂 Structure

```
~/dotfiles/
├── install.sh                          # Native Arch and Arch WSL2 installer
├── stow.sh                             # Symlink setup
├── wsl/                                # Weaselway onboarding and Windows helpers
├── .stow-local-ignore
│
├── hypr/.config/hypr/
│   ├── hyprland.lua                    # Main config
│   ├── config/                         # Monitors, keybinds, animations and window rules
│   ├── hypridle.conf
│   └── scripts/
│       ├── bar-orientation.sh          # Bar orientation switcher (invoked by the launcher's picker)
│       ├── wallpaper-switch.sh         # opens Settings ▸ Wallpaper (fzf TUI fallback)
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
│       └── ...                         # yazi, vscodium, fzf, zen, satty
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

Start with an installed x86-64 Arch Linux system, a regular user with sudo, and internet access. Use the same checkout on either platform. The scripts detect the environment from the running kernel. They install packages and link configuration for the current user.

```bash
git clone https://github.com/YahiaEng/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --plan
./install.sh
./stow.sh
```

`--plan` shows the packages and platform-specific setup without making changes. Rerun the same install and Stow commands to update an existing checkout. Stow keeps your saved theme, monitor overrides, and local VSCodium settings. A fresh profile starts with Catppuccin. Add personal wallpapers under `~/Pictures/Wallpapers/` and use **Style → Wallpaper** to choose one.

On native Arch and Arch WSL2, Hyprland loads dynamic cursors at startup. After a Hyprland upgrade, the next compositor login automatically opens a Kitty window if the plugin needs rebuilding. Enter your sudo password when prompted. The helper rebuilds and loads the plugin, then closes the window. A current build loads silently. On WSL2, reconnecting the Windows viewer can reuse the running compositor, so this check runs when the Linux desktop session itself starts.

### Native Arch

Keep your existing Arch bootloader and display manager. The installer selects Vulkan drivers from the detected PCI graphics devices, selects CPU microcode by vendor, and adds an LTS fallback kernel. It adds Limine integration for an existing Limine installation using its initramfs generator. The bundled single-GPU passthrough hooks target the original NVIDIA desktop's PCI layout and SDDM. The native shell uses NetworkManager, BlueZ and UPower for connectivity and battery status.

Reboot after installing or changing kernel drivers. Log into **Hyprland (uwsm-managed)** in your display manager or run this from a TTY.

```bash
uwsm start hyprland-uwsm.desktop
```

Hyprland detects connected displays and chooses their preferred mode, placement and scale. Use **Setup → Display** to save per-output settings such as a higher refresh rate. If you manage boot entries manually, add the installed LTS kernel to your boot menu before relying on it for recovery.

### Arch WSL2 with Weaselway

For a new instance, run `wsl --install -d archlinux` in Windows PowerShell. Follow Weaselway's Arch instructions to create a regular sudo user and install Git and Python. Use an x86-64 WSL2 instance with systemd, WSLg and Windows interop enabled, plus a Windows graphics driver that exposes `/dev/dxg`. The pinned Weaselway release needs a dxgdrm build for the kernel reported by `uname -r`. [Weaselway's Arch setup](https://github.com/weaselway/weaselway/blob/v1.9.1/distro/README.md) · [dxgdrm kernel builds](https://github.com/weaselway/dxgdrm/releases/tag/v1.4.0)

Run the same install and Stow commands above from a local Windows terminal opened into the distro as your regular user. The installer reuses an existing Weaselway stack or builds it using the pinned upstream Arch installer. It installs this repo's Hyprland session command, Windows Start menu shortcuts and Steam launcher. It can rebuild Weaselway's patched packages when an Arch upgrade replaces them.

After first installing Weaselway, run `wsl --shutdown` from Windows PowerShell so the driver and user groups take effect. Then open **Arch Linux (Hyprland)** from the Windows Start menu or run the command below from a local WSL terminal.

```bash
~/dotfiles/wsl/launch-desktop
```

With Fish as the WSL login shell, opening Arch starts Hyprland on the connected displays. By default, Arch uses up to four active Windows displays and follows the Windows main display. Each display gets one borderless viewer at its current Windows resolution. For a terminal-only session, run `wsl.exe -d archlinux -- env ARCH_WSL_TERMINAL=1 fish -l` from Windows.

| Action | Shortcut |
| --- | --- |
| Switch between Windows and Arch | **Ctrl + Alt + H**, or **System → Show Windows** in the Arch launcher |
| Choose the Linux main display | **Arch Linux - Display settings** in Start, or **Setup → Display** in the Arch launcher |
| Use Arch across both displays | **Arch Linux - Both displays** in Start |
| Use Arch on one display and Windows on the other | **Arch Linux - Primary display** or **Arch Linux - External display** in Start |

In Display settings, **Automatically use connected displays** follows the active Windows displays as they change. Turn it off to choose a fixed set. Choose the **Linux main display** to control where notifications and default dialogs open. **Identify displays** briefly numbers the physical monitors. Every assigned display gets its own bar, workspace icons, and edge rails.

Moving or rotating a display in Windows updates its position and size in Arch. Adding or removing a display briefly reconnects the viewer to the running Hyprland session. If Arch is minimized, it applies display changes when you bring it back. Use **Super + left drag** to move a window, or **Super + Shift + arrow** to move it in a direction.

Arch scales each display automatically using its resolution, physical pixel density when available, and Windows scale setting. The viewer stays at the display's native pixel size. In **Settings → Display**, choose a fixed scale for each display or select **Automatic**. Arch applies the scale live and saves it for that Windows monitor once Hyprland confirms the layout. Quickshell restarts if its bar surfaces fail to settle.

From a terminal, use `wsl/launch-desktop --list-monitors` to find Windows display names. Pass an ordered list such as `wsl/launch-desktop --monitors DISPLAY2,DISPLAY1` with the main display first. Use `wsl/launch-desktop --disconnect` from a WSL terminal to disconnect the viewer. [Weaselway display architecture](https://github.com/weaselway/weaselway/blob/main/ARCHITECTURE.md)

If Windows handles the Super shortcuts, focus the viewer and press **Right Ctrl + Right Shift + G** to toggle keyboard capture. Press **Right Ctrl + Right Shift + M** to return to Windows from the Linux lock screen, or **Right Ctrl + Right Shift + H** for the viewer's shortcuts. [Weaselway viewer input handling](https://github.com/weaselway/freerdp/blob/v1.3.0/client/SDL/SDL3/sdl_input.cpp)

On x86-64 Arch WSL, install Ninja with `sudo pacman -S --needed ninja` if needed, then run `./wsl/install-touch` to build the Weaselway viewer and daemon with native touchscreen forwarding. The build uses the Arch development headers, CMake and Ninja. It disconnects the viewer after both builds succeed. Reopen Arch Linux from Start to use the touchscreen.

Open Steam from the application menu. To refresh just the WSL Steam launcher on an existing install, run `./wsl/install-steam-launcher`. The launcher lets Mesa select GPU acceleration for 64-bit games and keeps Steam's web interface on its software path. Games launched this way get an 8 GB Mesa shader-cache limit. Hyprland also uses Weaselway's hardware cursor plane so Windows can move the pointer between streamed frames.

If Firefox or Zen crashes with the Weaselway Mesa driver, merge the WSL browser policy into the browser's existing enterprise policies to use software WebRender and video decoding. [WSL browser policy](wsl/browser-graphics-policy.json)

The Wi-Fi and Bluetooth hover cards read Windows state when the corresponding Linux device is absent. Their settings buttons open the matching Windows Settings page.

The virtual displays default to 1× scale. The idle lock stays enabled while Windows handles display power and sleep. On an existing install, back up `~/.local/state/hypr/idle-overrides.conf` and reapply your idle settings from the Shell behaviour page to update the generated listeners. Run `ww-start-session stop` from the WSL terminal to end the session.

## ⌨️ Keybindings

| Binding              | Action                    |
|:---------------------|:--------------------------|
| `Super + Return`     | Open Kitty terminal       |
| `Super` (tap)        | Open the menu (native QML launcher) |
| `Super + Q`          | Close window              |
| `Super + F`          | Toggle fullscreen         |
| `Super + V`          | Toggle floating           |
| `Super + L`          | Lock screen               |
| `Super + N`          | Toggle notification center|
| `Super + T`          | **Theme switcher**        |
| `Super + B`          | **Bar orientation switcher**|
| `Super + W`          | **Wallpaper picker**      |
| `Super + C`          | Clipboard history         |
| `Print`              | Screenshot (area select)  |
| `Shift + Print`      | Screenshot (window)       |
| `Ctrl + Print`       | Screenshot (full)         |
| `Super + 1-0`        | Switch workspace 1-10     |
| `Super + Shift + 1-0`| Move window to workspace  |

## 🎨 Theme System

**Static themes** copy pre-defined color files to each app's config directory. **Material You** runs `matugen` against the current wallpaper to generate a fresh palette.

All themes produce the same set of color variables (primary, surface, etc.) so every app stays consistent. The `theme-init.sh` script remembers your last choice and reapplies it on login.

### Adding a new static theme

1. Create `~/.config/themes/static/mytheme.conf` (Hyprland `$variable = rgba(...)` format)
2. Create `~/.config/themes/css/mytheme.css` (`@define-color variable #hex;` format)
3. Create `~/.config/themes/kitty/mytheme.conf` (kitty color format)
4. No menu entry to add — the launcher's Style ▸ Theme picker auto-discovers
   every `theme-engine/palettes/*.json` file on open

## 📄 License

MIT — do whatever you want with it.
