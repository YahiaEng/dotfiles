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
    ags
    elephant
    eww
    fastfetch
    fish
    gtk
    hypr
    kitty
    matugen
    swaync
    swayosd
    theme-engine
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

# Pre-create fish's plugin dirs as real directories so stow links individual
# files instead of dir-folding ~/.config/fish into the repo — fisher writes
# generated plugin files (fisher.fish, nvm.fish, ...) into these dirs at
# first run, and they must live host-side, never inside the repo tree
# (git-clean invariant).
mkdir -p "$HOME/.config/fish/functions" "$HOME/.config/fish/conf.d" "$HOME/.config/fish/completions"

# THM-01/D-08: pre-create the gtk-3.0/gtk-4.0 config dirs as real
# directories, same rationale as the fish dirs above — settings.ini is now
# a rendered state-dir target symlinked in by commit.sh (never stow-
# tracked content), and it must land in a real directory, never inside the
# repo via a folded stow symlink.
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

# BAR-04/D-19: pre-create eww's config dir as a real directory, same
# rationale as fish/gtk-3.0/gtk-4.0 above. Empirically, eww's SCSS @import
# resolves its "../../" relative path lexically against the given config
# path rather than a canonicalized realpath, so a folded stow symlink
# (`~/.config/eww` -> the repo dir) does NOT actually break the import in
# this eww version (Task 5, verified against installed 0.6.0). This
# pre-create is kept anyway as defense-in-depth against a future eww
# version canonicalizing that path (the exact class of upstream-version
# assumption Task 3/5 warn against elsewhere in this plan) — it costs
# nothing and matches the established repo-wide convention.
mkdir -p "$HOME/.config/eww"

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
# WR-05: seed only when absent — stow.sh is re-runnable, and an
# unconditional write clobbers the user's currently selected layout.
[[ -f "$HOME/.cache/current-waybar-layout" ]] || echo "full" > "$HOME/.cache/current-waybar-layout"

# D-27/D-28: seed-only-when-absent (same idiom as above) — guarantees the
# gaming-mode state file exists on a fresh install so gaming-mode-toggle.sh
# never has to handle a missing-file case on first read. This is NOT the
# D-28 session reset (that's the unconditional autostart.conf exec-once
# hook) — re-running stow.sh mid-session must never clobber an active
# toggle's state.
[[ -f "$HOME/.cache/gaming-mode" ]] || echo "off" > "$HOME/.cache/gaming-mode"

# BAR-01/D-03/D-06: seed the visibility owner's exclusive CSS override
# file empty, same seed-only-when-absent idiom as above — every
# style-{full,athena,floating,vertical}.css @imports this file LAST, and an
# unresolvable @import makes GTK3 discard the WHOLE stylesheet. Never
# unconditional: waybar-visibility.sh (the sole writer) may have a live
# idle-dim rule in here already on a stow.sh re-run, and clobbering it
# would desync the owner's actuated state from what's on screen.
mkdir -p "$HOME/.local/state/theme"
[[ -f "$HOME/.local/state/theme/waybar-visibility.css" ]] || : > "$HOME/.local/state/theme/waybar-visibility.css"

# ── Switch to zshell ─────────────────────────────────
# Pitfall 6/D-59: a non-root `chsh` prompts for the invoking user's login
# password via PAM, breaking the strictly-zero-prompts requirement. A
# root-privileged shell change bypasses that PAM prompt entirely.
# WR-03: guarded — the shell change is cosmetic relative to the first-boot
# theme seed below, so a missing zsh or a failed sudo/chsh must never abort
# the script under set -e before that seed runs.
if command -v zsh >/dev/null 2>&1; then
    sudo chsh -s "$(command -v zsh)" "$USER" || echo "  ⚠ chsh failed — change shell manually" >&2
else
    echo "  ⚠ zsh not installed — skipping shell change" >&2
fi

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
