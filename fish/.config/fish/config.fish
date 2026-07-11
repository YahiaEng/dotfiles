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
# installed Node versions (no re-download). fish sources conf.d/nvm.fish
# (the plugin's own auto-activation guard) BEFORE this file, so by the time
# nvm_default_version is set below, the guard has already run and found it
# unset — it silently skips activation and never re-checks. config.fish
# must therefore activate the default version itself (see the explicit
# `nvm use --silent` call inside the `status is-interactive` block below).
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

# ── Plugin bootstrap (analog: .zshrc's zinit self-clone) ─
# On a fresh system, install fisher + the plugins pinned in fish_plugins
# (nvm.fish) on the first interactive shell — keeps the fresh-install path
# reproducible via install.sh + stow, no manual host-only step (project
# reproducibility constraint). No-op once fisher.fish exists.
if status is-interactive; and not test -e $__fish_config_dir/functions/fisher.fish
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    and fisher update
end

if status is-interactive
    # ── Node tooling activation (closes CR-01) ───────
    # conf.d/nvm.fish's own auto-activation guard already ran before
    # nvm_default_version was set (see comment above), so it no-ops on a
    # fresh shell. Activate explicitly here instead: no-op when nvm.fish
    # isn't bootstrapped yet (`functions -q nvm`) and no-op when a version
    # is already active (`not set -q nvm_current_version`, e.g. inherited
    # from a parent shell). No `set -U` universals — not stow-reproducible.
    if not set -q nvm_current_version; and functions -q nvm
        nvm use --silent $nvm_default_version
    end

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
