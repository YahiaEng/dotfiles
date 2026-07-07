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
    local bus_name="dev.benz.walker"
    local log_file="$HOME/.local/state/theme/walker-relaunch.log"

    if [[ ! -f "$walker_dir/style.css" ]]; then
        notify-send -a "Walker" "Warning" "style.css missing after commit — check theme-doctor" -t 2000 2>/dev/null || true
    fi

    # Walker 2.16.2 has no theme hot-reload key (RESEARCH Pitfall W1,
    # verified against src/config.rs at the exact installed tag) — restart
    # is the ONLY mechanism. Do not set any hotreload/hot_reload/live_reload
    # theme key anywhere in this engine.
    killall -q walker 2>/dev/null || true

    # NOTE (deviation, fix(01-03) round 2 — applies to every bounded-poll
    # counter in this file and lib/gtk.sh): use `counter=$(( counter + 1 ))`
    # here, never the terser `(( counter++ ))`. Under `set -e`, a bare
    # `(( expr ))` command's exit status is the FALSY-ness of its numeric
    # result — post-increment evaluates to the value *before* incrementing,
    # so `(( counter++ ))` at counter=0 returns arithmetic 0, i.e. exit
    # status 1, which `set -e` treats as a real command failure and aborts
    # the whole theme-apply script mid-reload (silently skipping the
    # walker relaunch / vscodium step / everything after). Reproduced this
    # round: this is why "walker not running at all" happened — any poll
    # loop whose first check failed (needing a 2nd iteration) blew up the
    # script on its very first increment. `x=$((x+1))` is a plain
    # assignment, whose exit status reflects command success, not the
    # numeric value, so it's `set -e`-safe.
    local waited=0
    while pgrep -x walker >/dev/null 2>&1 && (( waited < 20 )); do
        sleep 0.1
        waited=$(( waited + 1 ))
    done
    if pgrep -x walker >/dev/null 2>&1; then
        # Bounded poll exhausted (T-03-01) — fall through to a forced kill
        # rather than hang the switch on a process that never exits.
        killall -q -9 walker 2>/dev/null || true
    fi

    # ── D-Bus bus-name release gate (deviation, fix(01-03) round 2) ────
    # Empirically reproduced this round: walker is a single-instance
    # GApplication (application_id "dev.benz.walker"); killing the old
    # process does not necessarily release its D-Bus well-known name in
    # the same instant `pgrep` stops seeing the PID — the session bus can
    # take a beat to notice the connection closed (systemd-scope teardown
    # is asynchronous to the D-Bus daemon's own bookkeeping). Relaunching
    # walker while the OLD name registration is still draining produces
    # "Failed to register: Unable to acquire bus name 'dev.benz.walker'"
    # — the new process then runs unregistered (not the true GApplication
    # primary), so future `walker`/`walker --dmenu` invocations can spawn
    # ANOTHER unregistered instance instead of reaching this one, which
    # looks exactly like "walker doesn't follow theme switches" even
    # though a style.css-only theme dir is otherwise fully valid (verified
    # against src/theme/mod.rs: Theme::default() seeds layout/keybind/
    # preview/items, setup_theme_from_path only overrides what's present
    # — no layout.xml is required alongside style.css). Bounded poll on
    # `busctl --user status`, never a fixed sleep; falls through to
    # relaunch after the cap rather than hang the switch indefinitely.
    if command -v busctl >/dev/null 2>&1; then
        local bwaited=0
        while busctl --user status "$bus_name" >/dev/null 2>&1 && (( bwaited < 20 )); do
            sleep 0.1
            bwaited=$(( bwaited + 1 ))
        done
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
            hwaited=$(( hwaited + 1 ))
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

    # Fully detach: redirect stdout away from theme-apply's own descriptors
    # so a long-running walker daemon never holds a caller's pipe open
    # (e.g. when theme-apply is invoked from a script that captures
    # output). stderr is captured to a log file, not discarded, so a
    # registration failure like the one diagnosed above is diagnosable
    # after the fact instead of vanishing silently.
    : > "$log_file" 2>/dev/null || true
    setsid uwsm app -- walker --gapplication-service >/dev/null 2>"$log_file" </dev/null &
    disown

    # ── Post-relaunch liveness + registration verification (deviation) ─
    # A bounded poll confirming BOTH the process is alive AND it actually
    # acquired the bus name — the true definition of "walker is up and
    # will answer the next launch/dmenu invocation", not just "a process
    # named walker exists" (a process that failed to register can still
    # be running unregistered, per the race documented above). Falls
    # through to a loud, persistent notification (not the usual 2-3s
    # toast) if it never comes up healthy, so a stuck launcher is visible
    # instead of silently absent (matches T-03-02's mitigation intent).
    local lwaited=0 walker_up=0
    while (( lwaited < 20 )); do
        if pgrep -x walker >/dev/null 2>&1 \
            && { ! command -v busctl >/dev/null 2>&1 || busctl --user status "$bus_name" >/dev/null 2>&1; }; then
            walker_up=1
            break
        fi
        sleep 0.1
        lwaited=$(( lwaited + 1 ))
    done
    if [[ "$walker_up" != "1" ]]; then
        notify-send -a "Walker" "Error" "Walker failed to come back up after theme switch — see ~/.local/state/theme/walker-relaunch.log" -i dialog-error -t 6000 2>/dev/null || true
    fi

    # Explicit success return: the `if` above has no `else`, so under
    # `set -e` its own exit status (1, when walker_up==1 and the negative
    # test is therefore false) would otherwise become this function's
    # return value as the last-executed statement — silently aborting the
    # whole theme-apply script (skipping the vscodium reload step and any
    # later steps) even on the SUCCESS path. Reproduced and fixed this
    # round — always return 0 once the notify decision has been made.
    return 0
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
