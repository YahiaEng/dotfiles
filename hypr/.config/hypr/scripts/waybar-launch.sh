#!/usr/bin/env bash
# Launches waybar with the last-used layout, defaulting to 'full'.
#
# D-32: the saved layout is validated by disk-truth (does the
# config-<slug>.jsonc + compiled waybar-style-<slug>.css pair actually
# exist?), never a hardcoded enum — a fresh 4th layout on disk becomes
# valid with zero script edits.
# D-16: `full` remains the deliberate, hardcoded fallback constant — a
# fresh install and the unattended container/VM gate must always land on
# `full`, never on "whichever layout sorts first on disk".
#
# 13-05: waybar now launches from the sass-COMPILED state-dir sheet, not
# the repo-stowed source (which is no longer even a .css file — it's a
# .scss that theme_engine_compile_gtk3_stylesheets renders into
# $STATE_DIR/waybar-style-<slug>.css on every theme-apply). The
# disk-truth check below is extended to validate BOTH files, not just
# the config, because a missing compiled sheet previously fell back to
# the default layout whose sheet could be equally missing (D-05: a
# session with no bar and no error to search for is worse than a failed
# install) — see the final fallback below for the case neither exists.
#
# No `-e`: this script ends in `exec`; an `-e` abort on a transient `cat`
# failure must never leave the session with no bar — the fallback path
# has to always be reachable.
set -uo pipefail

WAYBAR_DIR="$HOME/.config/waybar"
STATE_DIR="$HOME/.local/state/theme"
STATE_FILE="$HOME/.cache/current-waybar-layout"
DEFAULT_LAYOUT="full"

LAYOUT=$(cat "$STATE_FILE" 2>/dev/null || echo "$DEFAULT_LAYOUT")

# ── Path-traversal guard (T-08-13/T-13-22) ───────────────────
# $LAYOUT is host-side, user-writable state interpolated into two
# filesystem paths below — reject anything that isn't a bare slug BEFORE
# it ever touches a path. An existence check alone is not sufficient: a
# traversal value could resolve to a real file outside $WAYBAR_DIR/$STATE_DIR.
if [[ ! "$LAYOUT" =~ ^[A-Za-z0-9_-]+$ ]]; then
    LAYOUT="$DEFAULT_LAYOUT"
fi

# ── Disk-truth validation (D-32, extended 13-05/T-13-24) ─────────────
# Valid iff BOTH the repo-stowed config AND the COMPILED state-dir sheet
# exist. An existence check alone is never the only defence (T-13-22) —
# the traversal guard above already ran first.
if [[ -f "$WAYBAR_DIR/config-${LAYOUT}.jsonc" && -f "$STATE_DIR/waybar-style-${LAYOUT}.css" ]]; then
    : # $LAYOUT resolves to a real, styled layout — keep it
else
    LAYOUT="$DEFAULT_LAYOUT"
fi

# ── Missing-compiled-sheet degrade (D-05/T-13-24) ─────────────────────
# Even the default layout's compiled sheet can be absent (a fresh install
# before the first theme-apply, or a broken compile). Rather than exec'ing
# waybar with a -s flag pointed at a file that doesn't exist (waybar would
# either refuse to start or start fully unstyled with no diagnostic any
# operator would think to search for), degrade visibly: emit the missing
# path and the remedy to stderr, and start waybar config-only so the bar
# still appears.
if [[ ! -f "$STATE_DIR/waybar-style-${LAYOUT}.css" ]]; then
    echo "waybar-launch.sh: missing compiled stylesheet $STATE_DIR/waybar-style-${LAYOUT}.css — run 'theme-apply <theme>' to render it. Starting waybar unstyled (config only)." >&2
    exec waybar -c "$WAYBAR_DIR/config-${LAYOUT}.jsonc"
fi

exec waybar -c "$WAYBAR_DIR/config-${LAYOUT}.jsonc" \
       -s "$STATE_DIR/waybar-style-${LAYOUT}.css"
