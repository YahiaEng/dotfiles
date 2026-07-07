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
    #    before declaring success, fully inlined below.
    theme_engine_reload_walker

    # ── VSCodium: both static and dynamic modes now render
    #    vscodium.json through the same matugen template (D-03 parity),
    #    so this step no longer branches on mode — always merge whatever
    #    the engine just committed to the state dir.
    theme_engine_reload_vscodium
}

theme_engine_reload_walker() {
    local walker_dir="$HOME/.config/walker/themes/rice"
    local elephant_sock="/run/user/$(id -u)/elephant/elephant.sock"

    if [[ ! -f "$walker_dir/style.css" ]]; then
        notify-send -a "Walker" "Warning" "style.css missing after commit — check theme-doctor" -t 2000 2>/dev/null || true
    fi

    # Walker 2.16.2 has no theme hot-reload key (RESEARCH Pitfall W1,
    # verified against src/config.rs at the exact installed tag) — restart
    # is the ONLY mechanism. Do not set any hotreload/hot_reload/live_reload
    # theme key anywhere in this engine.
    killall -q walker 2>/dev/null || true

    local waited=0
    while pgrep -x walker >/dev/null 2>&1 && (( waited < 20 )); do
        sleep 0.1
        (( waited++ ))
    done
    if pgrep -x walker >/dev/null 2>&1; then
        # Bounded poll exhausted (T-03-01) — fall through to a forced kill
        # rather than hang the switch on a process that never exits.
        killall -q -9 walker 2>/dev/null || true
    fi

    rm -f "/run/user/$(id -u)/walker/walker.sock" 2>/dev/null || true

    # ── Elephant health gate (SCAN-02, D-25, T-03-02) ──────────────────
    # Verify the backend is healthy — socket present AND `elephant version`
    # responds — BEFORE relaunching walker, so a stale/mismatched elephant
    # is never mistaken for a themed walker (Pitfall W2: 3 configured
    # providers already have no installed elephant package on this repo).
    # Bounded poll, never a fixed sleep; falls through to relaunch after
    # the cap (T-03-01) instead of hanging the switch on a dead elephant —
    # theme-doctor remains the authoritative post-hoc health check (D-25).
    if command -v elephant >/dev/null 2>&1; then
        local hwaited=0
        while { [[ ! -S "$elephant_sock" ]] || ! elephant version >/dev/null 2>&1; } && (( hwaited < 20 )); do
            sleep 0.1
            (( hwaited++ ))
        done

        if [[ -S "$elephant_sock" ]] && elephant version >/dev/null 2>&1; then
            # No documented version-pin/compatibility matrix exists between
            # walker and elephant (RESEARCH "Version compatibility" table —
            # both are independently versioned by the same upstream author,
            # no pin mechanism in install.sh). A responsive `elephant
            # version` is the practical compatibility signal available;
            # log both for diagnostics.
            local elephant_v walker_v
            elephant_v=$(elephant version 2>/dev/null)
            walker_v=$(walker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            : "${elephant_v:=unknown}" "${walker_v:=unknown}"
        else
            notify-send -a "Walker" "Warning" "elephant backend not healthy — launcher may show stale/empty results (see theme-doctor)" -t 3000 2>/dev/null || true
        fi
    fi

    # Fully detach: redirect stdio away from theme-apply's own descriptors
    # so a long-running walker daemon never holds a caller's pipe open
    # (e.g. when theme-apply is invoked from a script that captures output).
    setsid uwsm app -- walker --gapplication-service >/dev/null 2>&1 </dev/null &
    disown
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
