# ── UWSM slices ──────────────────────────────────────
# Parity: the retired .zshrc's APP2UNIT_SLICES (unexported there too)
set -g APP2UNIT_SLICES "a=app-graphical.slice b=background-graphical.slice s=session-graphical.slice"

# The themed greeting is installed after the interactive prompt is initialized.
set -g fish_greeting

# ── Theme colours ────────────
# Rendered by matugen every theme-apply run into XDG state, same pattern as
# every other themed surface in this repo. Sourced unconditionally (not only
# when interactive) so a non-interactive fish that prints highlighted output
# uses the same palette.
# No `set -U` universals anywhere: universal variables live in fish's own
# state file, outside stow, and would silently outrank this file on any host
# where they had ever been set
if test -f $HOME/.local/state/theme/fish-colors.fish
    source $HOME/.local/state/theme/fish-colors.fish
end

# ── Node tooling: nvm.fish (fisher plugin, human-approved) ─
set -g nvm_data $HOME/.config/nvm/versions/node
set -g nvm_default_version v24.18.0

# ── bun ──────────────────────────────────────────────
set -gx BUN_INSTALL $HOME/.bun

# ── Editor ──
# Unconditional, not inside the interactive block below — EDITOR/VISUAL
# need to be visible to non-interactive invocations too (git, sudoedit,
# any tool that shells out through fish), not just an interactive prompt.
# `vim` (aliased to nvim further down) now resolves to a real binary.
set -gx EDITOR nvim
set -gx VISUAL nvim

# ── libvirt (260829-vfi) ─────────────────────────────
# Point virsh/virt-manager at the SYSTEM daemon. A non-root user's virsh
# defaults to qemu:///session — a separate, per-user libvirt with its own
# (empty) domain list — so `virsh start win11-gaming` fails with
# "failed to get domain" even though the domain exists. The VM lives in
# qemu:///system because that is where PCI passthrough, the /etc/libvirt
# hooks and the shared storage pool live; membership of the `libvirt`
# group is what makes reaching it unprivileged.
set -gx LIBVIRT_DEFAULT_URI qemu:///system

# ── PATH ─────────────────────────────────────────────
fish_add_path -g $HOME/.cargo/bin $HOME/.local/bin $BUN_INSTALL/bin $HOME/.spicetify

# ── Plugin bootstrap ──
# On a fresh system, install fisher + the plugins pinned in fish_plugins
if status is-interactive; and not test -e $__fish_config_dir/functions/fisher.fish
    curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source

    if test $pipestatus[1] -eq 0
        fisher update
    end
end

if status is-interactive
    # ── Node tooling activation ───────
    if not set -q nvm_current_version; and functions -q nvm
        and test -d $nvm_data/$nvm_default_version
        nvm use --silent $nvm_default_version
    end

    # ── Aliases (parity with the retired .zshrc) ─────
    alias ls 'ls -lah --color'
    alias vim nvim
    alias c clear
    alias codium 'codium --ozone-platform=wayland'
    alias zed "$HOME/.local/bin/zed"
    alias zel zellij

    # ── Keybindings ──────────────────────────────────

    # ── Shell integrations ─────────────
    fzf --fish | source
    zoxide init --cmd cd fish | source

    if command -q atuin
        atuin init fish | source
    end

    # ── Prompt ─
    if command -q starship
        if not set -q STARSHIP_CONFIG; and test -r "$HOME/.local/state/theme/starship-prompt.toml"
            set -gx STARSHIP_CONFIG "$HOME/.local/state/theme/starship-prompt.toml"
        end
        starship init fish | source
    end

    __fastfetch_setup_greeting
end
