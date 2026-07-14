#!/usr/bin/env bash
# Launches waybar with the last-used layout, defaulting to 'full'.
#
# D-32: the saved layout is validated by disk-truth (does the
# config-<slug>.jsonc + style-<slug>.css pair actually exist?), never a
# hardcoded enum — a fresh 4th layout on disk becomes valid with zero
# script edits.
# D-16: `full` remains the deliberate, hardcoded fallback constant — a
# fresh install and the unattended container/VM gate must always land on
# `full`, never on "whichever layout sorts first on disk".
#
# No `-e`: this script ends in `exec`; an `-e` abort on a transient `cat`
# failure must never leave the session with no bar — the fallback path
# has to always be reachable.
set -uo pipefail

WAYBAR_DIR="$HOME/.config/waybar"
STATE_FILE="$HOME/.cache/current-waybar-layout"

LAYOUT=$(cat "$STATE_FILE" 2>/dev/null || echo "full")

# ── Path-traversal guard (T-08-13) ───────────────────
# $LAYOUT is host-side, user-writable state interpolated into two
# filesystem paths below — reject anything that isn't a bare slug BEFORE
# it ever touches a path. An existence check alone is not sufficient: a
# traversal value could resolve to a real file outside $WAYBAR_DIR.
if [[ ! "$LAYOUT" =~ ^[A-Za-z0-9_-]+$ ]]; then
    LAYOUT="full"
fi

# ── Disk-truth validation (D-32) ─────────────────────
# Valid iff BOTH the config and its stylesheet exist on disk.
if [[ -f "$WAYBAR_DIR/config-${LAYOUT}.jsonc" && -f "$WAYBAR_DIR/style-${LAYOUT}.css" ]]; then
    : # $LAYOUT resolves to a real, styled layout — keep it
else
    LAYOUT="full"
fi

exec waybar -c "$WAYBAR_DIR/config-${LAYOUT}.jsonc" \
       -s "$WAYBAR_DIR/style-${LAYOUT}.css"
