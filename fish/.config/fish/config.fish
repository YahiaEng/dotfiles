# ╔══════════════════════════════════════════════════════╗
# ║                 FISH SHELL CONFIG                    ║
# ║  Ported 1:1 from zshell/.zshrc (Phase 4, D-10 parity)║
# ╚══════════════════════════════════════════════════════╝

# ── UWSM slices ──────────────────────────────────────
# Parity: zshell/.zshrc APP2UNIT_SLICES (unexported there too)
set -g APP2UNIT_SLICES "a=app-graphical.slice b=background-graphical.slice s=session-graphical.slice"

# ── Greeting: fastfetch in interactive shells ────────
# fish's built-in greeting is disabled; fastfetch replaces it.
# `status is-interactive` is the fish equivalent of zsh's `[ -t 0 ]` guard.
set -g fish_greeting
if status is-interactive
    fastfetch
end

# ── Node tooling: nvm.fish (fisher plugin, human-approved) ─
# nvm.fish uses the same version-dir layout as bash/zsh nvm's
# $NVM_DIR/versions/node, so pointing nvm_data there reuses the already
# installed Node versions (no re-download). Activation is PATH-prepend
# only — structurally equivalent to zsh's D-04 lazy-load (no synchronous
# nvm.sh sourcing ever happens in fish).
set -g nvm_data $HOME/.config/nvm/versions/node
set -g nvm_default_version v24.18.0

# ── bun ──────────────────────────────────────────────
set -gx BUN_INSTALL $HOME/.bun

# ── PATH ─────────────────────────────────────────────
# Parity: .zshrc exports for cargo, local bin, bun, spicetify.
# (~/.local/bin is also covered by the uv-generated conf.d/uv.env.fish on
# this host; fish_add_path dedupes, so listing it here keeps the stow
# package self-sufficient on a fresh system.)
fish_add_path -g $HOME/.cargo/bin $HOME/.local/bin $BUN_INSTALL/bin $HOME/.spicetify

if status is-interactive
    # ── Aliases (parity with .zshrc) ─────────────────
    alias ls 'ls -lah --color'
    alias vim nvim
    alias c clear
    alias codium 'codium --ozone-platform=wayland'
    alias zed "$HOME/.local/bin/zed"

    # ── Keybindings ──────────────────────────────────
    # zsh's `bindkey -e` + Ctrl-P/Ctrl-N history search are fish defaults
    # (\cp → up-or-search, \cn → down-or-search) — nothing to configure.
    # History dedup/sharing is likewise built into fish.

    # ── Shell integrations (D-10 parity) ─────────────
    fzf --fish | source
    zoxide init --cmd cd fish | source

    # ── Prompt: oh-my-posh, vendored local theme (D-03/D-10) ─
    # Same JSON vendored by Plan 04-03 into the zshell stow package —
    # shared, no remote URL fetched at shell start.
    oh-my-posh init fish --config $HOME/.config/oh-my-posh/catppuccin.omp.json | source
end
