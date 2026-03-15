#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║       VSCODIUM THEME EXTENSIONS INSTALLER             ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

if ! command -v codium &>/dev/null; then
    echo "VSCodium not found. Install it first."
    exit 1
fi

EXTENSIONS=(
    "Catppuccin.catppuccin-vsc"
    "Catppuccin.catppuccin-vsc-icons"
    "dracula-theme.theme-dracula"
    "mvllow.rose-pine"
    "jdinhlife.gruvbox"
    "enkia.tokyo-night"
    "arcticicestudio.nord-visual-studio-code"
)

echo "Installing VSCodium theme extensions..."
for ext in "${EXTENSIONS[@]}"; do
    echo "  → $ext"
    codium --install-extension "$ext" --force 2>/dev/null || true
done

echo ""
echo "All theme extensions installed."
