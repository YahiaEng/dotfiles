#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║          ARCH LINUX HYPRLAND SETUP                   ║
# ║   Installs all dependencies for this rice            ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

# ── Flag parsing ─────────────────────────────────────
# --core-only : run only section_core_rice (packages + AUR helper + core
#               post-install tasks). Skips section_hardware and
#               section_personal. Used by the container/VM verification
#               gate (D-52/D-57), where hardware guards and personal
#               config would be meaningless or destructive.
# --help/-h   : print usage and exit 0 before any sudo/pacman call.
# Any other flag is rejected loudly (Security V5) — never silently ignored.
CORE_ONLY=false

usage() {
    cat <<'USAGE'
Usage: install.sh [--core-only] [--help]

  --core-only   Install only the core rice section: pacman + AUR packages,
                AUR-helper bootstrap, audio/dbus-broker services, VSCodium
                extensions. Skips the hardware section (NVIDIA/limine) and
                the personal section (git identity, timezone). Intended
                for the container/VM verification gate.
  --help, -h    Show this help message and exit.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --core-only)
            CORE_ONLY=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "install.sh: unknown flag: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

# ── Official repo packages (core — always installed) ─
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

    # Notifications (IN-11: official extra repo, not AUR)
    swaync

    # Qt Wayland
    qt5-wayland
    qt6-wayland

    # Misc
    libnotify
    python-gobject
    gtk3
    adw-gtk-theme

    # Personal
    zip
    unzip
    libreoffice-fresh
    obsidian

    # DevOps
    ansible
    aws-cli-v2
    kubectl
    github-cli
    vault
    terraform
)

# ── Official repo packages (hardware — NVIDIA GPU only) ─
NVIDIA_PKGS=(
    nvidia-dkms
    nvidia-utils
    libva-nvidia-driver
    egl-wayland
)

# ── AUR packages (core — always installed) ───────────
AUR_PKGS=(
    # Rice
    matugen-bin

    # Walker
    walker
    elephant
    elephant-desktopapplications
    elephant-providerlist
    elephant-calc
    elephant-clipboard
    elephant-symbols
    elephant-menus
    elephant-runner
    elephant-websearch
    elephant-files

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

# ── section_core_rice ─────────────────────────────────
# Mirror sync, AUR-helper bootstrap, pacman + AUR package installs,
# orphan cleanup, audio/dbus-broker services, VSCodium extensions.
# Always runs — this is the section the container/VM gate exercises
# via --core-only, and what a default (no-flag) run always includes.
section_core_rice() {
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

    echo "Installing pacman packages..."
    sudo pacman -Sy --needed --noconfirm "${PACMAN_PKGS[@]}"

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

    # ── Enable dbus-broker (recommended for uwsm) ───────
    echo "Enabling dbus-broker for uwsm..."
    systemctl --user enable --now dbus-broker.service 2>/dev/null || true
    echo ""
}

# ── section_hardware ──────────────────────────────────
# NVIDIA package group and limine bootloader steps — both hardware-guarded
# (D-58): NVIDIA only installs when an NVIDIA GPU is detected via lspci;
# limine steps only run when limine is actually the installed bootloader.
# Skipped entirely under --core-only.
section_hardware() {
    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║     Hardware-specific setup              ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""

    if lspci | grep -qi nvidia; then
        echo "NVIDIA GPU detected — installing NVIDIA packages..."
        sudo pacman -Sy --needed --noconfirm "${NVIDIA_PKGS[@]}"
    else
        echo "No NVIDIA GPU detected — skipping NVIDIA packages."
    fi

    echo ""
    if command -v limine-install &>/dev/null; then
        echo "Updating limine bootloader entries..."
        sudo rm /boot/limine/limine.conf
        sudo limine-install --fallback
        sudo limine-update
        sudo limine-scan
    else
        echo "limine not detected — skipping bootloader update."
    fi
}

# ── section_personal ──────────────────────────────────
# Hardcoded personal config (git identity, timezone) — not meaningful (and
# potentially wrong) inside a disposable container/VM, so this section is
# skipped under --core-only (D-61).
section_personal() {
    echo ""
    echo "Configuring git..."
    git config --global user.name yahiaEng
    git config --global user.email eng-yahia-tarek@outlook.com

    echo ""
    echo "Setting timezone..."
    sudo timedatectl set-timezone Africa/Cairo
}

# ── Main ──────────────────────────────────────────────
section_core_rice

if [[ "$CORE_ONLY" != "true" ]]; then
    section_hardware
    section_personal
fi

echo "Next steps:"
echo "  1. Run './stow.sh' to set up symlinks"
echo "  2. Select 'Hyprland (uwsm-managed)' in your display manager"
echo "  3. Or from TTY: uwsm start hyprland-uwsm.desktop"
