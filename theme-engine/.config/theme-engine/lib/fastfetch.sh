#!/usr/bin/env bash
# theme-engine/lib/fastfetch.sh — sprite regen on theme switch (quick task
# 260818-srl, Task 2).
#
# Owns exactly one function, called once per theme-apply run, AFTER the
# palette is committed (theme_engine_commit — the generator reads
# palette.json from the LIVE state dir, not the tmp render tree) and BEFORE
# reload (theme_engine_reload). See theme-apply's own call site for why
# that ordering is load-bearing.
#
# T-srl-03 (Denial of Service): bounded to the single ACTIVE sprite only —
# never regenerates all six here (that is the picker's cache-warm job,
# Task 3, run on open, not on every theme switch — 725ms on every switch is
# the cost the operator explicitly rejected). fastfetch-sprites.py's own
# palette-hash sidecar makes a same-palette re-run a ~100ms no-op rather
# than a full ~250ms regen, so even a rapid double theme-apply (e.g. the
# wallpaper picker's live-preview loop) stays cheap.
#
# Best-effort throughout: a generator failure must NEVER fail a theme
# switch — the caller wraps this in `|| true` and this function's own body
# never propagates a python failure past a logged warning. A failed
# regeneration leaves the previous GIF (in the OLD palette) in place, which
# is a strictly better failure mode than a half-written or missing GIF.

FASTFETCH_LOGO_STATE="$HOME/.local/state/theme/fastfetch-logo"
FASTFETCH_SPRITES_PY="$ENGINE_DIR/lib/fastfetch-sprites.py"

# fastfetch's own enumerated sprite set (must stay in sync with
# fastfetch-sprites.py's EFFECT_NAMES and Task 3's picker entries — all
# three are hand-maintained lists of the same six literals by design, the
# same shape this repo already accepts for e.g. the ASCII art set in
# fish/config.fish, rather than inventing a shared-config indirection for
# six names that essentially never change).
FASTFETCH_SPRITE_NAMES=(pulse sweep glitch scan assemble orbit)

# theme_engine_fastfetch_regen
# No arguments — reads the fastfetch-logo state file directly (the same
# theme-orthogonal-axis shape lib/font.sh's theme_engine_read_font and
# lib/wallpaper.sh's last-wallpaper/ readers already use: the picker owns
# writing this file, this function only ever reads it).
theme_engine_fastfetch_regen() {
    local active
    active="$(cat "$FASTFETCH_LOGO_STATE" 2>/dev/null || echo "")"

    [[ -z "$active" ]] && return 0

    local is_sprite=0
    local name
    for name in "${FASTFETCH_SPRITE_NAMES[@]}"; do
        if [[ "$active" == "$name" ]]; then
            is_sprite=1
            break
        fi
    done

    # Not a sprite (an ASCII name, "random", "none", or an unrecognised
    # value) — no-op. ASCII/none/random never need a GIF regenerated; an
    # unrecognised value falls through to themed ASCII at the fish layer
    # (T-srl-01) and has nothing here to regenerate either.
    [[ "$is_sprite" -eq 0 ]] && return 0

    if ! command -v python3 &>/dev/null; then
        echo "theme_engine_fastfetch_regen: python3 not found — sprite left unregenerated (previous GIF, if any, stays in the old palette)" >&2
        return 0
    fi

    if [[ ! -f "$FASTFETCH_SPRITES_PY" ]]; then
        echo "theme_engine_fastfetch_regen: $FASTFETCH_SPRITES_PY not found — sprite left unregenerated" >&2
        return 0
    fi

    # Stderr is captured to a shell variable, not a new top-level file under
    # $STATE_DIR — theme-doctor's D-29 state-manifest gate walks every
    # top-level entry there and fails on anything contract.json doesn't
    # declare, so a bespoke log file here would need its own declaration
    # for no real benefit (this function already prints the failure to
    # stderr on the line below; a persistent artifact isn't needed for a
    # best-effort, never-fails-the-switch regen).
    local sprite_err
    if ! sprite_err="$(python3 "$FASTFETCH_SPRITES_PY" "$active" 2>&1 >/dev/null)"; then
        echo "theme_engine_fastfetch_regen: sprite regen failed for '$active' — previous GIF (if any) left in place: $sprite_err" >&2
        return 0
    fi

    return 0
}
