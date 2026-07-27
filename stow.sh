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
    fastfetch
    fish
    gtk
    hypr
    kitty
    matugen
    quickshell
    swaync
    swayosd
    theme-engine
    thunar
    uwsm
    vscodium
    walker
    wallpapers
    waybar
    wleave
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

# D-19: pre-create ~/.config/quickshell as a real directory, same
# rationale as fish/gtk-3.0/gtk-4.0 above — a genuinely fresh target keeps
# quickshell/ eligible for stow's whole-directory fold (a single symlink
# at ~/.config/quickshell), but this repo's convention (and the phase 11
# tracer's own verification) expects per-file symlinks
# (~/.config/quickshell/shell.qml itself resolving as a symlink), so the
# parent must already exist as a real directory before stow runs.
mkdir -p "$HOME/.config/quickshell"

# 13-02: pre-create swaync.service's systemd drop-in directory as a REAL
# directory — a stow/systemd interaction discovered empirically this plan,
# not a style preference: systemd 261 silently ignores an entire .d
# drop-in directory when it is itself a symlink (verified directly —
# `systemctl --user show swaync.service -p DropInPaths` stayed EMPTY with
# stow's normal whole-directory fold in place, and only became non-empty
# once the parent existed as a real directory before stow ran). Same
# pre-create-before-stow idiom as fish/gtk-3.0/gtk-4.0/quickshell above:
# with the real directory already present, stow descends into it and
# symlinks only override.conf, which systemd DOES trust. Any FUTURE
# stowed systemd unit/drop-in in this repo needs the same treatment — see
# 13-02-SUMMARY.md for the full DropInPaths= empty-vs-populated evidence.
mkdir -p "$HOME/.config/systemd/user/swaync.service.d"

for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$pkg" ]]; then
        echo "  → Stowing: $pkg"
        # CR-02: under `set -euo pipefail`, a stow conflict on ANY package
        # here (non-zero exit propagating through the `| sed` pipe) would
        # abort the WHOLE script before ever reaching the motion-file seed
        # below — silently skipping the one seed step this file's own
        # comments call the most critical, "must fail loudly, not silently"
        # write. `if ! ... ; then` short-circuits set -e's abort for just
        # this one pipeline so one package's conflict doesn't take down
        # every later package (and the motion seed) with it; re-running
        # stow.sh after resolving the conflict is the existing, documented
        # recovery path (WR-05: seed only when absent — stow.sh is
        # re-runnable).
        if ! stow --restow "$pkg" --target="$HOME" 2>&1 | sed 's/^/    /'; then
            echo "  ⚠ stow failed for $pkg — continuing with remaining packages" >&2
        fi
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

# D-06/D-07: seed the motion-scale axis to its default, same seed-only-
# when-absent idiom as above — an absent file already reads as "normal"
# through theme_engine_read_motion_scale's closed case, but a fresh
# install should have the file present rather than relying on every
# reader's fallback branch being exercised correctly on day one.
[[ -f "$HOME/.local/state/theme/motion-scale" ]] || echo "normal" > "$HOME/.local/state/theme/motion-scale"

# D-30: seed the three rendered motion files by INVOKING motion.sh's own
# renderer — never a hand-authored stub. A stub is a second source of
# truth that goes stale the instant Phase 13 points Hyprland's
# `animation =` assignment lines at generated curves; D-30's whole point
# is that motion.json stays the ONLY place these numbers are written.
# This is the one seed among all the ones in this file whose absence is
# worst: a missing hyprland-motion.conf is a hard `source=` globbing
# error, and an absent/never-rendered motion-scale leaves $motion_enabled
# undefined in animations.conf ("cannot parse as an int") — both are
# config-parse failures that keep Hyprland from starting at all, debugged
# from a TTY, not a graceful degrade. The unconditional `|| true` guard on
# the surrounding block still applies (this must never abort stow.sh under
# set -e), but unlike the other seeds here, a failure here is loud, not
# silent — WR-07's "first impression is a themed desktop" only holds if
# this succeeds.
if [[ ! -f "$HOME/.local/state/theme/hyprland-motion.conf" ]] || \
   [[ ! -f "$HOME/.local/state/theme/gtk-4.0-motion.css" ]] || \
   [[ ! -f "$HOME/.local/state/theme/motion.json" ]]; then
    MOTION_LIB="$DOTFILES_DIR/theme-engine/.config/theme-engine/lib/motion.sh"
    if [[ -f "$MOTION_LIB" ]]; then
        (
            set -uo pipefail
            STATE_DIR="$HOME/.local/state/theme"
            # shellcheck source=theme-engine/.config/theme-engine/lib/motion.sh
            source "$MOTION_LIB"
            SEED_TMP="$(mktemp -d)"
            trap 'rm -rf "$SEED_TMP"' EXIT
            if theme_engine_render_motion_files "$SEED_TMP"; then
                mkdir -p "$STATE_DIR"
                for mf in motion.json gtk-4.0-motion.css hyprland-motion.conf; do
                    [[ -f "$SEED_TMP$STATE_DIR/$mf" ]] && cp "$SEED_TMP$STATE_DIR/$mf" "$STATE_DIR/$mf"
                done
            else
                echo "  ⚠ motion.sh seed render failed — a fresh install's first Hyprland start WILL fail until theme-apply runs successfully first" >&2
                exit 1
            fi
        ) || echo "  ⚠ motion-file seed did not complete — see error above; Hyprland will NOT start until this is resolved (run theme-apply manually)" >&2
    else
        echo "  ⚠ $MOTION_LIB not found — skipping motion-file seed; Hyprland will NOT start without these files" >&2
    fi
fi

# D-01/D-05/13-02: seed the sass-compiled GTK3 stylesheet(s) by INVOKING
# the real renderer AND the real compiler — never a hand-authored/
# pre-compiled stub. Mirrors the motion-file seed block immediately above,
# same rationale: after swaync's conversion, the file swaync-launch.sh
# points at only exists if sass actually ran — today it is a stow symlink
# present the instant stow.sh runs; after this plan it is a generated
# artifact that must be rendered. Never committing a pre-compiled default
# sheet would make it a second source of truth that goes stale the moment
# a swaync/*.scss edit lands (this repo's most-enforced invariant).
# Deliberately NOT given line 135's `|| true` tolerance (D-05 explicit):
# a silently unstyled desktop with no error to search for is worse than a
# failed install, so a failure here prints a loud, specific message and
# leaves a non-zero trail rather than degrading quietly.
if [[ ! -f "$HOME/.local/state/theme/_motion.scss" ]] || \
   [[ ! -f "$HOME/.local/state/theme/swaync-style.css" ]]; then
    MOTION_LIB="$DOTFILES_DIR/theme-engine/.config/theme-engine/lib/motion.sh"
    if [[ -f "$MOTION_LIB" ]]; then
        (
            set -uo pipefail
            STATE_DIR="$HOME/.local/state/theme"
            # shellcheck source=theme-engine/.config/theme-engine/lib/motion.sh
            source "$MOTION_LIB"
            SEED_TMP="$(mktemp -d)"
            trap 'rm -rf "$SEED_TMP"' EXIT
            if theme_engine_render_motion_files "$SEED_TMP" && theme_engine_compile_gtk3_stylesheets "$SEED_TMP"; then
                mkdir -p "$STATE_DIR"
                for mf in _motion.scss swaync-style.css; do
                    [[ -f "$SEED_TMP$STATE_DIR/$mf" ]] && cp "$SEED_TMP$STATE_DIR/$mf" "$STATE_DIR/$mf"
                done
            else
                echo "  ⚠ GTK3 sass-compile seed failed — swaync will start UNSTYLED (or fail to start, depending on the failure) until theme-apply runs successfully first" >&2
                exit 1
            fi
        ) || echo "  ⚠ GTK3 sass-compile seed did not complete — see error above; run theme-apply manually to resolve" >&2
    else
        echo "  ⚠ $MOTION_LIB not found — skipping GTK3 sass-compile seed; swaync will start unstyled without these files" >&2
    fi
fi

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
