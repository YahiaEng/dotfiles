#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║          ARCH LINUX HYPRLAND SETUP                   ║
# ║   Installs all dependencies for this rice            ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

echo "╔══════════════════════════════════════════╗"
echo "║   Installing Hyprland Rice Dependencies  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

echo "Synchronizing closest mirrors..."
echo ""
sudo pacman -Sy reflector --needed
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
sudo reflector --verbose --latest 30 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syu

# ── Check for yay/paru ───────────────────────────────
AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
else
    echo "⚠  No AUR helper found. Installing paru..."
    sudo pacman -Sy --needed --noconfirm git base-devel rustup
    rustup default stable
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru && makepkg -si --noconfirm
    AUR_HELPER="paru"
fi

echo ""
echo "Using AUR helper: $AUR_HELPER"
echo ""

# ── Official repo packages ──────────────────────────
PACMAN_PKGS=(
    # Hyprland ecosystem
    hyprland
    hyprlock
    hypridle
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk

    # Session manager
    uwsm
    dbus-broker

    # Bar, launcher, notifications, logout
    waybar
    wofi
    wlogout

    # Terminal
    kitty

    # Wallpaper
    awww

    # Utilities
    grim
    slurp
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
    fastfetch
    fzf
    chafa
    imagemagick
    jq
    psmisc
    stow

    # Audio
    pipewire
    pipewire-pulse
    wireplumber
    pavucontrol

    # Fonts
    otf-firamono-nerd
    ttf-firacode-nerd
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk
    otf-font-awesome

    # File manager
    thunar
    thunar-archive-plugin
    thunar-volman
    tumbler
    gvfs
    gvfs-mtp
    yazi
    ffmpegthumbnailer
    fd
    resvg
    ripgrep
    poppler
    zoxide
    7zip

    # Polkit
    polkit-gnome

    # NVIDIA
    nvidia-dkms
    nvidia-utils
    libva-nvidia-driver
    egl-wayland

    # Qt Wayland
    qt5-wayland
    qt6-wayland

    # Misc
    libnotify
    python-gobject
    gtk3

    # Personal
    zip
    unzip
    libreoffice-fresh
)

echo "Installing pacman packages..."
sudo pacman -Sy --needed --noconfirm "${PACMAN_PKGS[@]}"

# ── AUR packages ─────────────────────────────────────
AUR_PKGS=(
    # Rice
    swaync
    matugen-bin
    adw-gtk3

    # Walker
    walker
    elephant
    elephant-desktopapplications
    elephant-providerlist
    elephant-calc
    elephant-clipboard
    elephant-symbols
    elephant-menus

    # Utils
    bibata-cursor-theme
    alpm_octopi_utils

    # Z-shell
    zsh
    oh-my-posh

    # Limine Bootloader
    limine-dracut-support
    kernel-modules-hook

    # Code editors
    vscodium-bin

    # Browsers
    zen-browser-bin

    # Other
    spotify
    discord
    1password
    octopi
)

echo ""
echo "Installing AUR packages..."
$AUR_HELPER -Sy --needed --noconfirm "${AUR_PKGS[@]}"

echo ""
echo "Removing unused packages and clearing cache..."
paru -R "$(pacman -Qtdq)"
paru -Sc

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     All packages installed successfully! ║"
echo "╚══════════════════════════════════════════╝"
echo ""

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     Post installation tasks              ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Install vscodium theme extensions ────────────────
echo ""
echo "Installing VSCodium theme extensions..."
chmod +x "$HOME"/.config/hypr/scripts/vscodium-extensions.sh || true
"$HOME"/.config/hypr/scripts/vscodium-extensions.sh 2>/dev/null || true

# ── Make sure audio services are enabled ────────────────
echo ""
echo "Enabling audio services..."
systemctl --user enable --now pipewire.service wireplumber.service pipewire-pulse.service

# ── Configure git username and password ────────────────
echo ""
echo "Configuring git..."
git config --global user.name yahiaEng
git config --global user.email eng-yahia-tarek@outlook.com

# ── Enable dbus-broker (recommended for uwsm) ───────
echo "Enabling dbus-broker for uwsm..."
systemctl --user enable --now dbus-broker.service 2>/dev/null || true
echo ""

# ── Update Limine Bootloader entries ────────────────
echo ""
echo "Updating limine bootloader entries..."
sudo rm /boot/limine/limine.conf
sudo limine-install --fallback
sudo limine-update
sudo limine-scan

echo "Next steps:"
echo "  1. Run './stow.sh' to set up symlinks"
echo "  2. Select 'Hyprland (uwsm-managed)' in your display manager"
echo "  3. Or from TTY: uwsm start hyprland-uwsm.desktop"
