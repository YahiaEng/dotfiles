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
    # ── Logo selector (quick task 260818-srl) ────────
    # matugen never knows which logo was picked; the selector never touches
    # colours; box-close.awk touches neither — three independent layers,
    # see PLAN.md's "the seam" diagram. This block owns layer 2 only.
    #
    # T-srl-01 (Tampering/Elevation): the state file's content becomes a
    # `--logo <path>` argument. NEVER pass it raw — validate against the
    # enumerated art/sprite set first (fish's `contains`, not string
    # interpolation into a path) and fall back to themed ASCII on anything
    # unrecognised. "Nothing may silently reach the stock builtin arch
    # logo" — the final fallback below is always themed ASCII (arch), even
    # for an unrecognised state value.
    set -l ff_ascii_arts arch star cyberpunk_mask illuminati
    set -l ff_sprite_names pulse sweep glitch scan assemble orbit
    set -l ff_state (cat $HOME/.local/state/theme/fastfetch-logo 2>/dev/null)

    # Real kitty-graphics capability check, not a guess — mirrors the
    # `[[ -n "${KITTY_WINDOW_ID:-}" ]] && command -v kitten` idiom
    # icon-theme-picker.sh:273 already uses (measured reliable there).
    set -l ff_in_kitty 0
    if test -n "$KITTY_WINDOW_ID"; and command -v kitten >/dev/null 2>&1
        set ff_in_kitty 1
    end

    # "random" re-rolls the actual pick into ff_state itself, BEFORE the
    # validation chain below — everything downstream (including the
    # kitty-capability/GIF-readable gate on a sprite pick) still applies to
    # whatever random landed on, so a randomly-picked sprite outside kitty
    # still correctly degrades to themed ASCII rather than skipping that
    # check.
    if test "$ff_state" = random
        if test "$ff_in_kitty" -eq 1
            set ff_state (random choice $ff_sprite_names)
        else
            set ff_state (random choice $ff_ascii_arts)
        end
    end

    set -l ff_logo_type file
    set -l ff_logo_path "$HOME/.config/fastfetch/art/arch.txt"

    # ── Sprite cell reservation (quick task 260818-u6v) ──
    # fastfetch does NOT scale an image logo to a requested cell box: the
    # kitty graphics control it emits is `s=200,v=200` (source pixel size)
    # with no `c=`/`r=` cell-scaling keys, measured identical across every
    # --logo-width value tested. The flags reserve TEXT COLUMNS and move the
    # placement cue; the image is always drawn at its natural pixel size.
    # Without them fastfetch reserved only `ESC[3C` — padding.left alone —
    # and drew the whole info box straight through the sprite.
    #
    # COUPLING, deliberate and documented rather than silent: these two
    # numbers are (sprite canvas px) / (kitty cell px).
    #   cols = 200 / 10 = 20      rows = 200 / 20 = 10
    # The canvas is `S = 200` in theme-engine/lib/fastfetch-sprites.py; the
    # 10x20 px cell follows from `font_size 12.0` in kitty/kitty.conf
    # (measured live: 2440x640 px over 244x32 cells). A materially SMALLER
    # font shrinks the cell, pushes the natural column count above 20, and
    # the clipping returns. Querying the real cell size per shell would cost
    # another ~14ms `kitten` spawn on top of the one icat already pays, which
    # is why this is pinned instead. Change either end -> change both.
    set -l ff_sprite_cols 20
    set -l ff_sprite_rows 10

    if test "$ff_state" = none
        set ff_logo_type none
        set ff_logo_path ""
    else if contains -- "$ff_state" $ff_ascii_arts
        set ff_logo_type file
        set ff_logo_path "$HOME/.config/fastfetch/art/$ff_state.txt"
    else if contains -- "$ff_state" $ff_sprite_names
        set -l ff_gif "$HOME/.local/state/theme/fastfetch/$ff_state.gif"
        # A sprite is selected ONLY if kitty's graphics protocol is
        # actually available AND its GIF exists and is readable —
        # otherwise themed ASCII (arch), never the sprite path and never
        # the builtin logo.
        if test "$ff_in_kitty" -eq 1; and test -r "$ff_gif"
            set ff_logo_type kitty-icat
            set ff_logo_path "$ff_gif"
        end
    end

    # Fresh-install degradation: no theme-apply has ever rendered
    # fastfetch.jsonc yet — run plain fastfetch with no `-c` rather than
    # pointing at a file that doesn't exist. Same voice as the
    # fish-colors.fish guard directly below: a missing render degrades to
    # "the old look", never to a broken shell.
    if test -f $HOME/.local/state/theme/fastfetch.jsonc
        # `--pipe false` is load-bearing (M-4) — fastfetch auto-disables
        # colour when stdout is a pipe; without this flag every colour
        # this template renders is silently stripped before box-close.awk
        # ever sees a byte.
        if test "$ff_logo_type" = none
            fastfetch -c $HOME/.local/state/theme/fastfetch.jsonc \
                --logo-type none \
                --pipe false \
                | awk -f $HOME/.config/fastfetch/box-close.awk
        else if test "$ff_logo_type" = kitty-icat
            # Image logo: fastfetch cannot measure it, so the cell footprint
            # must be declared or the box overlaps the sprite (260818-u6v).
            fastfetch -c $HOME/.local/state/theme/fastfetch.jsonc \
                --logo-type $ff_logo_type --logo $ff_logo_path \
                --logo-width $ff_sprite_cols --logo-height $ff_sprite_rows \
                --pipe false \
                | awk -f $HOME/.config/fastfetch/box-close.awk
        else
            # Text art: fastfetch counts the characters itself, so the width
            # flags are meaningless here and are deliberately not passed.
            fastfetch -c $HOME/.local/state/theme/fastfetch.jsonc \
                --logo-type $ff_logo_type --logo $ff_logo_path \
                --pipe false \
                | awk -f $HOME/.config/fastfetch/box-close.awk
        end
    else
        fastfetch
    end
end

# ── Theme colours (quick task 260818-nwo) ────────────
# Rendered by matugen every theme-apply run into XDG state, same pattern as
# every other themed surface in this repo. Sourced unconditionally (not only
# when interactive) so a non-interactive fish that prints highlighted output
# uses the same palette.
#
# Guarded on existence: on a fresh install this file does not exist until the
# first theme-apply, and fish must not error on first launch. Without it fish
# falls back to its own defaults, where `fish_color_param` is `cyan` — which
# is exactly the unreadable path this file exists to replace, so a missing
# render degrades to "the old look", never to a broken shell.
#
# No `set -U` universals anywhere: universal variables live in fish's own
# state file, outside stow, and would silently outrank this file on any host
# where they had ever been set — the non-reproducible host-only state this
# repo's constraints forbid.
if test -f $HOME/.local/state/theme/fish-colors.fish
    source $HOME/.local/state/theme/fish-colors.fish
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

# ── Editor (parity with .zshrc, quick task 260820-nua) ──
# Unconditional, not inside the interactive block below — EDITOR/VISUAL
# need to be visible to non-interactive invocations too (git, sudoedit,
# any tool that shells out through fish), not just an interactive prompt.
# `vim` (aliased to nvim further down) now resolves to a real binary.
set -gx EDITOR nvim
set -gx VISUAL nvim

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
    curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    # fish's pipeline $status reflects the LAST command (source), not curl —
    # `curl -f | source` on a failed fetch sources empty input, which trivially
    # succeeds, so a plain `and fisher update` would still fire and error with
    # "Unknown command: fisher" (found live via fault injection, WR-01/D-30).
    # $pipestatus[1] is curl's own exit code and is unaffected by that.
    if test $pipestatus[1] -eq 0
        fisher update
    end
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
        and test -d $nvm_data/$nvm_default_version
        nvm use --silent $nvm_default_version
    end

    # ── Aliases (parity with .zshrc) ─────────────────
    alias ls 'ls -lah --color'
    alias vim nvim
    alias c clear
    alias codium 'codium --ozone-platform=wayland'
    alias zed "$HOME/.local/bin/zed"
    alias zel zellij

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
