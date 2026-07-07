#!/usr/bin/env bash
# theme-engine/lib/commit.sh — atomic commit step (D-14)
#
# Only ever invoked after theme_engine_generate returns 0 — a failed render
# never reaches here, so the live desktop is never touched by a half-
# rendered theme. Moves the rendered tree into ~/.local/state/theme/ and
# wires the two apps with no native import mechanism (walker, yazi — D-07).

STATE_DIR="$HOME/.local/state/theme"

# theme_engine_commit <name> <tmp_dir>
theme_engine_commit() {
    local name="$1"
    local tmp="$2"

    # matugen's -p/--prefix flag prepends $tmp to the ABSOLUTE resolved
    # output_path (~ expands to $HOME first), so the rendered tree lives at
    # $tmp$STATE_DIR, not $tmp itself (verified empirically this session).
    local rendered_dir="$tmp$STATE_DIR"

    if [[ ! -d "$rendered_dir" ]]; then
        echo "commit.sh: rendered output not found at $rendered_dir" >&2
        return 1
    fi

    mkdir -p "$STATE_DIR"

    # Atomic replace: state dir contents only change here, in one step,
    # after a fully successful render (D-14).
    rsync -a --delete "$rendered_dir"/ "$STATE_DIR"/

    # rsync -a syncs the destination directory's own mode from the source
    # (matugen creates $rendered_dir with the process umask, typically
    # 0755) — re-assert user-only permissions AFTER rsync so it isn't
    # silently overwritten (T-02-03: never leave the state dir world-
    # readable/writable).
    chmod 700 "$STATE_DIR"

    echo "$name" > "$STATE_DIR/current-theme"

    # D-07: walker and yazi have no @import/include mechanism, so the
    # engine wires their config path directly to the state-dir output via
    # a symlink. This is idempotent one-time wiring (D-09) — `ln -sf`
    # re-links to the same target on every call, no per-login dance.
    local walker_dir="$HOME/.config/walker/themes/rice"
    mkdir -p "$walker_dir"
    ln -sf "$STATE_DIR/walker-style.css" "$walker_dir/style.css"

    mkdir -p "$HOME/.config/yazi"
    ln -sf "$STATE_DIR/yazi.toml" "$HOME/.config/yazi/theme.toml"
}
