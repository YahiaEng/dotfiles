#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║          BAR ORIENTATION TOGGLE (D-18-30)               ║
# ║   The SOLE writer of the bar's orientation value. The    ║
# ║   reader is the QML entry model, which defaults to the   ║
# ║   horizontal orientation on any unreadable, empty or     ║
# ║   unrecognised value — a failed write here degrades to   ║
# ║   a working bar, never a broken one.                      ║
# ╚══════════════════════════════════════════════════════╝
#
# Supersedes the previous four-layout picker per D-18-30, preserving the
# same discoverable path: reachable from the bar's own settings drawer AND
# the Super-key menu's Settings submenu, both invoking this one script. The
# picker this replaces used to relaunch the surface it controlled after
# every change; this script does neither — it only writes a value. The
# entry model watches that value and re-lays the whole bar live, so no
# process is ever signalled or relaunched from here.
#
# The two-value vocabulary below (horizontal/vertical) is closed by design.
# Adding a third orientation means editing the reader (the entry model)
# FIRST, then this script's SLUGS/DISPLAYS arrays — never the reverse.

set -euo pipefail

STATE_FILE="$HOME/.local/state/quickshell/bar-orientation"

SLUGS=(
    "horizontal"
    "vertical"
)
DISPLAYS=(
    "Horizontal"
    "Vertical"
)

# _apply <slug> — validates BEFORE any path construction or write
# (T-08-05's allowlist-before-use discipline). Only a member of the closed
# two-value case list below ever reaches the state file; every other value
# is rejected with the file left untouched.
_apply() {
    local slug="$1"

    case "$slug" in
        "horizontal")
            ;;
        "vertical")
            ;;
        *)
            notify-send -a "Bar Orientation" "Error" \
                "Unknown orientation '${slug}' — expected horizontal or vertical" \
                -i dialog-error 2>/dev/null || true
            return 1
            ;;
    esac

    mkdir -p "$(dirname "$STATE_FILE")"

    # Atomic temp-file-plus-rename (gaming-mode-toggle.sh's _write_state
    # idiom): the entry model watches this file while this script writes
    # it, so a torn read is a real possibility without this.
    printf '%s\n' "$slug" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

    local display=""
    local i
    for i in "${!SLUGS[@]}"; do
        if [[ "${SLUGS[$i]}" == "$slug" ]]; then
            display="${DISPLAYS[$i]}"
            break
        fi
    done

    # The notification body is always one of the two array literals above,
    # never the raw argument this function was called with.
    notify-send -a "Bar Orientation" "Orientation Changed" "${display}" \
        -i preferences-desktop-display -t 2000 2>/dev/null || true
}

# One entry shape and no other: an argument is always required, applied
# non-interactively. The launcher's picker mode is the only caller that
# builds the two-row list now; anything without an argument is a usage
# error.
main() {
    case $# in
        1)
            _apply "$1"
            ;;
        *)
            echo "bar-orientation.sh: usage: bar-orientation.sh <horizontal|vertical>" >&2
            exit 1
            ;;
    esac
}

main "$@"
