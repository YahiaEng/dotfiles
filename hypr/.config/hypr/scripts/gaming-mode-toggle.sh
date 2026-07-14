#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              GAMING MODE TOGGLE (D-26/27/28)          ║
# ║  Runtime-only, reversible. NEVER writes a Hyprland     ║
# ║  config file — every compositor change goes through    ║
# ║  `hyprctl keyword`. The theme-engine OWNS the on-disk   ║
# ║  config files; a toggle that rewrote them would desync ║
# ║  the pipeline (this is the single hardest constraint    ║
# ║  in this script — see 07-07-PLAN.md D-26).             ║
# ╚══════════════════════════════════════════════════════╝
#
# State file: ~/.cache/gaming-mode ("on"/"off"), stow-seeded to "off" and
# unconditionally reset to "off" on every session start (D-28,
# autostart.conf) — a stale ON state means the screen never locks.
#
# FINDING (documented, not a bug): D-26's OFF-path instruction is to read
# the pre-toggle decoration/animation values back from the theme engine's
# rendered `~/.local/state/theme/hyprland.conf` before falling back to
# `hyprctl reload`. Empirically, that file contains ONLY matugen's color
# variables ($primary, $secondary, ...) — rounding/blur/animations/shadow
# are static values in the repo-owned hypr/.config/hypr/hyprland.conf and
# config/animations.conf, which theme-apply never touches. The read-back
# below is therefore expected to find nothing on THIS repo's layout, and
# always falls through to `hyprctl reload` — which is exactly the
# plan's own designated fallback and is provably correct here, since
# `hyprctl reload` re-sources the exact same static config every time
# (the values never vary by theme).

set -euo pipefail

STATE_FILE="$HOME/.cache/gaming-mode"
THEME_HYPRLAND_CONF="$HOME/.local/state/theme/hyprland.conf"

# ── Re-pointed waybar-visibility call (D-03 / P7 D-26). ─────────────────
# This IS the re-point Phase 7 left this thin one-liner for -- waybar
# visibility is now owned exclusively by waybar-visibility.sh (the D-03
# owner). This script must never signal waybar directly again (no raw
# pkill -SIGUSR1/-SIGUSR2 waybar anywhere below). It declares an intent
# ("gaming wants it hidden/shown"); the owner computes the resulting
# state against the other actors (idle, fullscreen, keybind).
_gaming_waybar_toggle() {
    local state="$1" # hide|show
    ~/.config/hypr/scripts/waybar-visibility.sh gaming "$state" 2>/dev/null || true
}

# theme_engine-style atomic state write (commit.sh's temp-file + mv idiom)
# — the menu entry reads this file while this script writes it, so a torn
# read is a real possibility.
_write_state() {
    local value="$1"
    printf '%s\n' "$value" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
}

_read_state() {
    cat "$STATE_FILE" 2>/dev/null || echo "off"
}

# _restore_keyword <hyprctl-path> — best-effort read-back from the theme
# engine's rendered state (D-26: never hardcode restore literals). Prints
# the value if found, prints nothing otherwise (caller falls back to a
# full `hyprctl reload`, see FINDING above).
_restore_keyword() {
    local key="$1"
    local leaf="${key##*:}"
    # Deviation, fix (Rule 1): under `set -euo pipefail`, a `grep -m1`
    # that finds nothing exits 1, and pipefail propagates that as the
    # whole pipeline's exit status even though the trailing `sed` exits 0
    # — the same bug class theme-engine/lib/reload.sh's own comments
    # document at length (e.g. the `(( counter++ ))` note). Since this
    # function legitimately returns empty on a miss (the caller checks
    # `[[ -n "$v" ]]`), the whole pipeline must never be allowed to fail
    # the calling `v="$(...)"` assignment under `set -e`.
    grep -m1 -E "^[[:space:]]*${leaf}[[:space:]]*=" "$THEME_HYPRLAND_CONF" 2>/dev/null \
        | sed -E 's/^[^=]*=[[:space:]]*//' || true
}

gaming_mode_on() {
    # ── Runtime-only eye-candy disable (D-26) — every call is best-effort
    #    per the house `2>/dev/null || true` idiom (theme-engine/lib/gtk.sh).
    hyprctl keyword decoration:blur:enabled 0 2>/dev/null || true
    hyprctl keyword animations:enabled 0 2>/dev/null || true
    hyprctl keyword decoration:shadow:enabled 0 2>/dev/null || true
    hyprctl keyword decoration:rounding 0 2>/dev/null || true

    # ── Idle/lock inhibit: pause hypridle rather than acquire a systemd
    #    inhibitor lock that could outlive this shell. SIGSTOP/SIGCONT is
    #    cleanly reversible and self-heals on session restart (a fresh
    #    session's exec-once spawns a brand-new hypridle process, D-28).
    pkill -STOP -x hypridle 2>/dev/null || true

    # ── Hide waybar: declare the gaming intent to the visibility owner.
    _gaming_waybar_toggle hide

    _write_state "on"

    notify-send -a "Gaming Mode" "Gaming Mode: ON" "Eye-candy disabled, idle-lock inhibited" -i input-gaming -t 2500 2>/dev/null || true
}

gaming_mode_off() {
    # ── Restore eye-candy: attempt a read-back from the theme engine's
    #    rendered state first (D-26); fall back to a full `hyprctl reload`
    #    (re-sources the compositor's whole on-disk config) for any value
    #    that isn't present there. On this repo's layout, none of these
    #    four keys are ever in the rendered hyprland.conf (see FINDING
    #    above), so this always exercises the reload fallback — which is
    #    the plan's own designed, guaranteed-correct path.
    local need_reload=0
    local v

    v="$(_restore_keyword decoration:blur:enabled)"
    if [[ -n "$v" ]]; then
        hyprctl keyword decoration:blur:enabled "$v" 2>/dev/null || true
    else
        need_reload=1
    fi

    v="$(_restore_keyword animations:enabled)"
    if [[ -n "$v" ]]; then
        hyprctl keyword animations:enabled "$v" 2>/dev/null || true
    else
        need_reload=1
    fi

    v="$(_restore_keyword decoration:shadow:enabled)"
    if [[ -n "$v" ]]; then
        hyprctl keyword decoration:shadow:enabled "$v" 2>/dev/null || true
    else
        need_reload=1
    fi

    v="$(_restore_keyword decoration:rounding)"
    if [[ -n "$v" ]]; then
        hyprctl keyword decoration:rounding "$v" 2>/dev/null || true
    else
        need_reload=1
    fi

    if [[ "$need_reload" == "1" ]]; then
        hyprctl reload 2>/dev/null || true
    fi

    # ── Un-inhibit idle/lock.
    pkill -CONT -x hypridle 2>/dev/null || true

    # ── Un-hide waybar: declare the gaming intent cleared.
    _gaming_waybar_toggle show

    # ── Stale-idle fix (D-05 SIGSTOP interaction). gaming_mode_on()
    #    freezes hypridle (pkill -STOP above), so an idle-hide/dim intent
    #    that was already in effect when gaming mode engaged can never be
    #    cleared by hypridle's own on-resume -- that process cannot run
    #    while stopped. During gaming this is harmless (the gaming=hide
    #    intent dominates under D-01's OR-union regardless), but declaring
    #    ONLY "gaming show" here would leave that stale idle=hide intent
    #    standing, and the bar would return dimmed instead of normal.
    #    Toggling gaming mode off IS user input -- by D-02's own rule any
    #    input clears idle-hide -- so this is gaming-mode correctly
    #    reporting that input occurred, not reaching into another actor's
    #    concern. Do NOT remove this second call as "redundant": without
    #    it, gaming-mode-OFF can return a dimmed bar.
    ~/.config/hypr/scripts/waybar-visibility.sh idle show 2>/dev/null || true

    _write_state "off"

    notify-send -a "Gaming Mode" "Gaming Mode: OFF" "Desktop restored to theme defaults" -i input-gaming -t 2500 2>/dev/null || true
}

main() {
    local arg="${1:-}"

    if [[ "$arg" == "status" ]]; then
        _read_state
        exit 0
    fi

    local current
    current="$(_read_state)"

    if [[ "$current" == "on" ]]; then
        gaming_mode_off
    else
        gaming_mode_on
    fi
}

main "$@"
