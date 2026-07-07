#!/usr/bin/env bash
# theme-engine/lib/reload.sh — the ONLY reload fan-out owner (D-04/PIPE-02)
#
# Runs exactly once, only after commit.sh has successfully moved rendered
# output into ~/.local/state/theme/ — never against half-rendered state.
# No other file in this repo may invoke hyprctl reload / pkill -SIGUSR* /
# swaync-client -rs / a walker restart / the vscodium merge — this is the
# single owner (matugen's post_hooks were stripped in Plan 01-02 Task 1
# specifically so this is the only place any of that fires).

STATE_DIR="$HOME/.local/state/theme"

# theme_engine_reload
theme_engine_reload() {
    # ── Signal-reloaded surface (D-21: flips in <1s) ──────────────
    hyprctl reload >/dev/null 2>&1 || true
    pkill -SIGUSR2 waybar 2>/dev/null || true
    pkill -SIGUSR1 kitty 2>/dev/null || true
    swaync-client -rs >/dev/null 2>&1 || true

    # ── GTK (gsettings toggle + env propagation + Thunar daemon) ──
    theme_engine_gtk_reload

    # ── Walker: restart-only, no hotreload_theme key exists in
    #    walker 2.16.2 (Pitfall W1) — hardened kill/relaunch with a
    #    bounded poll for process exit and an elephant health check
    #    before declaring success, folding in walker-restart.sh's logic.
    theme_engine_reload_walker

    # ── VSCodium: both static and dynamic modes now render
    #    vscodium.json through the same matugen template (D-03 parity),
    #    so this step no longer branches on mode — always merge whatever
    #    the engine just committed to the state dir.
    theme_engine_reload_vscodium
}

theme_engine_reload_walker() {
    local walker_dir="$HOME/.config/walker/themes/rice"

    if [[ ! -f "$walker_dir/style.css" ]]; then
        notify-send -a "Walker" "Warning" "style.css missing after commit — check theme-doctor" -t 2000 2>/dev/null || true
    fi

    killall -q walker 2>/dev/null || true

    local waited=0
    while pgrep -x walker >/dev/null 2>&1 && (( waited < 20 )); do
        sleep 0.1
        (( waited++ ))
    done
    if pgrep -x walker >/dev/null 2>&1; then
        killall -q -9 walker 2>/dev/null || true
    fi

    rm -f "/run/user/$(id -u)/walker/walker.sock" 2>/dev/null || true

    # Fully detach: redirect stdio away from theme-apply's own descriptors
    # so a long-running walker daemon never holds a caller's pipe open
    # (e.g. when theme-apply is invoked from a script that captures output).
    setsid uwsm app -- walker --gapplication-service >/dev/null 2>&1 </dev/null &
    disown

    # Bounded poll for elephant health after relaunch — best-effort, never
    # blocks theme-apply's success on this (walker itself may still be
    # starting up; theme-doctor is the authoritative health check, D-25).
    if command -v elephant >/dev/null 2>&1; then
        local ewaited=0
        while ! elephant listproviders >/dev/null 2>&1 && (( ewaited < 20 )); do
            sleep 0.1
            (( ewaited++ ))
        done
    fi
}

theme_engine_reload_vscodium() {
    local settings="$HOME/.config/VSCodium/User/settings.json"
    local theme_data="$STATE_DIR/vscodium.json"

    [[ -f "$theme_data" ]] || return 0

    mkdir -p "$(dirname "$settings")"
    [[ -f "$settings" ]] || echo '{}' > "$settings"

    jq -s '.[0] * .[1]' "$settings" "$theme_data" > "${settings}.tmp" 2>/dev/null \
        && mv "${settings}.tmp" "$settings" \
        || rm -f "${settings}.tmp"
}
