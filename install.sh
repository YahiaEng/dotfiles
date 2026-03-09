#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║          ARCH LINUX PACKAGE INSTALLER                 ║
# ║   Installs all dependencies for this rice             ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

echo "╔══════════════════════════════════════════╗"
echo "║   Installing Hyprland Rice Dependencies   ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Check for yay/paru ───────────────────────────────
AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
else
    echo "⚠  No AUR helper found. Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin && makepkg -si --noconfirm
    AUR_HELPER="yay"
fi

echo "Using AUR helper: $AUR_HELPER"
echo ""

# ── Official repo packages ──────────────────────────
PACMAN_PKGS=(
    # Hyprland ecosystem
    hyprland
    hyprlock
    hypridle
    xdg-desktop-portal-hyprland

    # Bar, launcher, notifications
    waybar
    wofi

    # Terminal
    kitty

    # Wallpaper
    swww

    # Utilities
    grim
    slurp
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
    jq
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

    # File manager
    thunar

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
)

echo "Installing pacman packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# ── AUR packages ─────────────────────────────────────
AUR_PKGS=(
    swaync
    matugen-bin
    bibata-cursor-theme
    zsh
    fzf
    oh-my-posh
    zoxide
)

echo ""
echo "Installing AUR packages..."
$AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     All packages installed successfully!  ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Run './stow.sh' next to set up symlinks."
