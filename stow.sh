#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              STOW DOTFILES SETUP                     ║
# ║   Creates symlinks from ~/dotfiles → ~/.config       ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

if [[ ! -d "$DOTFILES_DIR" ]]; then
    echo "Error: $DOTFILES_DIR does not exist."
    exit 1
fi

cd "$DOTFILES_DIR"

# ── Stow packages ───────────────────────────────────
PACKAGES=(
    fastfetch
    gtk
    hypr
    kitty
    matugen
    swaync
    theme-engine
    themes
    thunar
    uwsm
    vscodium
    walker
    wallpapers
    waybar
    wlogout
    yazi
    zshell
)

echo "╔══════════════════════════════════════════╗"
echo "║       Stowing dotfile packages...        ║"
echo "╚══════════════════════════════════════════╝"

# Remove and backup existing hyprland conf, if a real (non-stow-owned) file
# exists (Pitfall 2/D-62). The hyprland pacman package ships no default
# config, so a genuinely fresh system has nothing here — the guard skips
# instead of aborting. On a re-run, the path is already a stow-owned
# symlink, so it's left alone (no pointless .bak churn).
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
HYPR_BAK="$HOME/.config/hyprland.conf.bak"
if [[ -e "$HYPR_CONF" && ! -L "$HYPR_CONF" ]]; then
    mv "$HYPR_CONF" "$HYPR_BAK"
fi

for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$pkg" ]]; then
        echo "  → Stowing: $pkg"
        stow --restow "$pkg" --target="$HOME" 2>&1 | sed 's/^/    /'
    else
        echo "  ⚠ Skipping: $pkg (directory not found)"
    fi
done

# ── Make scripts executable ──────────────────────────
echo ""
echo "Making scripts executable..."
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true

# ── Initialize cache ─────────────────────────────────
# Theme state now lives in ~/.local/state/theme/ (D-05) — theme-init.sh
# falls back to catppuccin automatically when no state exists yet (D-10),
# so no pre-seed is needed here.
mkdir -p "$HOME/.cache"
echo "full" > "$HOME/.cache/current-waybar-layout"

# ── Switch to zshell ─────────────────────────────────
# Pitfall 6/D-59: a non-root `chsh` prompts for the invoking user's login
# password via PAM, breaking the strictly-zero-prompts requirement. A
# root-privileged shell change bypasses that PAM prompt entirely.
sudo chsh -s "$(which zsh)" "$USER"

# ── Seed first-boot theme baseline (D-60/WR-07) ──────
# Run theme-apply once now that theme-engine is stowed, so
# ~/.local/state/theme/ exists before first login (first impression is a
# fully themed desktop, not an empty state dir). theme-apply's reload step
# already degrades harmlessly without a running Hyprland session (every
# reload call is `|| true`-guarded internally) — the `|| true` here is
# belt-and-suspenders so a missing entrypoint never aborts stow.sh under
# set -e; the rendered state files are what matters, not the reload.
echo ""
echo "Seeding first-boot theme baseline..."
THEME_APPLY="$HOME/.config/theme-engine/theme-apply"
if [[ -x "$THEME_APPLY" ]]; then
    # theme-apply catppuccin — seeds ~/.local/state/theme/ with the
    # catppuccin baseline before first login.
    "$THEME_APPLY" catppuccin || true
else
    echo "  ⚠ theme-apply not found at $THEME_APPLY — skipping seed"
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║       Dotfiles stowed successfully!      ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Add wallpapers to ~/Pictures/Wallpapers/"
echo "  2. Log into Hyprland"
echo "  3. Use Super+Shift+T to switch themes"
echo "  4. Use Super+Shift+W to switch waybar layouts"
echo "  5. Use Super+Shift+B to pick wallpapers"
