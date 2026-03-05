# ~/.dotfiles/install.sh
#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Starting Arch Linux Wayland Dotfiles Installation..."

# 1. Ensure an AUR helper is installed
if ! command -v yay &> /dev/null; then
    echo "📦 yay (AUR helper) not found. Installing yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    rm -rf /tmp/yay
    echo "✅ yay installed successfully."
else
    echo "✅ yay is already installed."
fi

# 2. Define the packages to install
PACKAGES=(
    # Core Wayland & Hyprland
    hyprland
    hypridle
    hyprlock
    
    # UI Components
    waybar
    swaync
    fuzzel
    kitty
    
    # Theming & Utilities
    stow
    swww              # AUR: Wallpaper daemon
    matugen-bin       # AUR: Material You color generator
    
    # Fonts
    ttf-jetbrains-mono-nerd
)

# 3. Install packages using yay
echo "📥 Installing required packages..."
yay -S --needed --noconfirm "${PACKAGES[@]}"
echo "✅ Packages installed."

# 4. Set up the cache directory for the lockscreen wallpaper
echo "📁 Setting up cache directories..."
mkdir -p ~/.cache

# 5. Deploy configurations using GNU Stow
echo "🔗 Symlinking dotfiles with GNU Stow..."

# Navigate to the dotfiles directory (assuming the script is run from there)
cd "$(dirname "$0")"

# Array of directories to stow
STOW_DIRS=(
    hyprland
    waybar
    fuzzel
    kitty
    swaync
    matugen
    scripts
)

for dir in "${STOW_DIRS[@]}"; do
    echo "  -> Stowing $dir..."
    # -R (restow) ensures clean symlinks even if running the script multiple times
    stow -R "$dir"
done

echo "✅ Dotfiles deployed successfully."

# 6. Final Instructions
echo ""
echo "🎉 Installation Complete! 🎉"
echo "------------------------------------------------------"
echo "To initialize your dynamic theme, run your theme switcher script with a wallpaper:"
echo "  /path/to/your/wallpaper.jpg"
echo ""
echo "Note: Ensure your NVIDIA DRM module (nvidia-drm.modeset=1) is set in your bootloader!"
echo "------------------------------------------------------"