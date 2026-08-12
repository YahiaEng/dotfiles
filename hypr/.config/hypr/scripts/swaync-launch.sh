#!/usr/bin/env bash
# Launches swaync pointed at the sass-compiled state-dir stylesheet
# (D-01/D-34/13-02) — mirrors the retired bar's own launcher's shape
# rather than inlining a path into autostart.conf, which avoids relying
# on shell expansion inside a Hyprland exec-once line and gives the
# missing-sheet case somewhere to degrade.
#
# No `-e`: this script ends in `exec`; an `-e` abort on a transient
# condition must never leave the session with no notification daemon —
# same discipline as that retired launcher (a themed daemon is better
# than none, an unstyled daemon is better than none, "none" is the only
# real failure).
set -uo pipefail

COMPILED_STYLE="$HOME/.local/state/theme/swaync-style.css"

if [[ -f "$COMPILED_STYLE" ]]; then
    exec swaync -s "$COMPILED_STYLE"
else
    # notify-send is not guaranteed to be reachable this early in the
    # session (swaync itself, the notification daemon, has not started
    # yet) — a visible stderr line is the only channel guaranteed to work
    # here. Never abort: an unstyled daemon still gives the user working
    # notifications, which is strictly better than none (D-05's precedent
    # for the retired launcher's own missing-sheet fallback).
    echo "swaync-launch.sh: $COMPILED_STYLE not found — starting swaync unstyled (run theme-apply, or re-run stow.sh)" >&2
    exec swaync
fi
