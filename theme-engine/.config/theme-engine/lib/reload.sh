#!/usr/bin/env bash
# theme-engine/lib/reload.sh — the ONLY reload fan-out owner (D-04/PIPE-02)
#
# Runs exactly once, only after commit.sh has successfully moved rendered
# output into ~/.local/state/theme/ — never against half-rendered state.
# No other file in this repo may invoke hyprctl reload / pkill -SIGUSR* /
# a walker restart / the vscodium merge — this is the
# single owner (matugen's post_hooks were stripped in Plan 01-02 Task 1
# specifically so this is the only place any of that fires).
#
# Scoping correction (08-03/D-03): this file owns the theme-reload
# fan-out — the set of signals/restarts a THEME SWITCH sends. It does
# NOT claim exclusive ownership of every signal to every process named
# here for all time: hypr/.config/hypr/scripts/bar-visibility.sh (renamed
# from its pre-Phase-18 form, Phase 18 Plan 15/QBAR-07) owns the QML bar's
# VISIBILITY state (show/hide, driven by idle/fullscreen/gaming/keybind
# intents, actuated over Quickshell IPC), a second, disjoint, equally
# idempotent concern. Two owners, two non-overlapping jobs. (This was
# already true before this comment: gaming-mode-toggle.sh has been sending
# bar visibility intents since Phase 7.) RETIRE-02 (18-20) removed this
# file's own signal targeting the now-retired bar directly — the QML bar
# is the sole surviving bar, and its visibility is reasserted through the
# owner's `reassert` verb below rather than a compositor-wide signal.

STATE_DIR="$HOME/.local/state/theme"

# theme_engine_reload
theme_engine_reload() {
    # ── Headless guard (Quick 260709-buf, T-buf-01) ─────────────────
    # Render+commit already happened before this function is ever called
    # (theme-apply's own ordering); the entire fan-out below assumes a
    # live Wayland+D-Bus session (hyprctl, kitty signals,
    # GTK gsettings, walker's D-Bus bus-name dance, and even the
    # file-only vscodium merge are all skipped here). With no session,
    # there is nothing to reload — the committed state is picked up at
    # next login. This matters concretely for stow.sh's first-boot theme
    # seed, which calls theme-apply in a headless container/fresh-install
    # context: the retired notification daemon's own reload client in
    # particular blocked forever there with no session D-Bus (INST-03
    # gate hang, 45+ min, evidence
    # verify/logs/run-20260709T042501Z) — `|| true` only guards a
    # non-zero exit, not a hang. Discretion call: vscodium's merge is
    # purely file-based and would itself be headless-safe, but skipping
    # it too keeps this a single early return covering the whole
    # fan-out (simplest correct fix) — the merge is idempotent and
    # re-runs on the next real, session-backed theme switch, so nothing
    # is lost by skipping it here.
    if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        echo "theme_engine_reload: no graphical session detected — skipping reload fan-out (committed state applies at next login)"
        return 0
    fi

    # ── Signal-reloaded surface (D-21: flips in <1s) ──────────────
    # 13.1-05: reconciled against the Lua config manager's measured
    # re-read semantics, not left as an untested assumption (13.1-03's
    # "Config re-read semantics" investigation, 13.1-LUA-FINDINGS.md,
    # against installed Hyprland 0.56.1-2, commit
    # 5c9377c15f85c50648f35ca5a213754f95b93ca0). Ten consecutive
    # `hyprctl reload` calls against a nested Lua-booted instance left
    # bind count (2 -> 2) and animation-leaf/bezier-curve counts
    # (correctly-indexed measurement: 35/3 -> 35/3) unchanged — CONFIRMED
    # NON-ACCUMULATING, independently corroborated by a window-rule
    # replacement round producing a clean, uncontaminated result with no
    # residual state from the prior rule. `hyprctl reload` fully clears
    # and re-executes the Lua config from scratch each time, the same
    # behaviour this line already relied on for the hyprlang parser.
    # NEGATIVE BRANCH, recorded per D-13/plan precedent (STATE.md): no
    # functional change required here — this line stays exactly as it
    # already was for hyprlang.
    hyprctl reload >/dev/null 2>&1 || true
    # BAR-01/D-03: the retired bar's `pkill -SIGUSR2` reload-and-reset
    # signal lived here until RETIRE-02 (18-20) removed it along with the
    # surface it targeted. `reassert` below targets bar-visibility.sh
    # (renamed, Phase 18 Plan 15/QBAR-07) — it recomputes from the owner's
    # existing intent files and re-actuates the QML bar over IPC if needed,
    # so a shell restart or any other externally-caused reset can never
    # desync the owner's .actuated record from what the QML bar is actually
    # rendering. Best-effort and scoped inside this function's own headless
    # guard above, so it never runs in a session-less context (container/VM
    # gate, fresh install) where there is no bar to actuate anyway.
    "$HOME"/.config/hypr/scripts/bar-visibility.sh reassert 2>/dev/null || true
    pkill -SIGUSR1 kitty 2>/dev/null || true

    # ── tmux (quick task 260819-vas): grouped with kitty, the other
    #    terminal surface this fan-out reloads. Sits after the function's
    #    own headless early-return above, so a theme-apply with no
    #    graphical session skips it — consistent with every other hook
    #    here; a tmux server started later just picks the colours up from
    #    its own config at start, same as any other surface would.
    #
    #    Different from fish (see [templates.fish] in config.toml): fish
    #    is read once at shell start and existing shells are deliberately
    #    NOT re-themed, because a fresh shell is cheap and common. A tmux
    #    server instead holds every option in memory for the life of the
    #    server — sessions routinely outlive a theme switch by days — so
    #    without this hook a long-lived session would keep stale colours
    #    indefinitely. That is precisely why this surface earns a reload
    #    hook and fish does not.
    theme_engine_reload_tmux
    # The retired notification daemon's reload step stood here until
    # Phase 19 Plan 19-08 Task 5 (RETIRE-03). Nothing replaces it: the
    # QML shell owns notifications in-process now and re-reads its own
    # palette through Colours.qml on file change, so a theme switch
    # needs no signal, no client call and no restart on its behalf.

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

    # ── OSD (OSD-01/D-24): Phase 20 (RETIRE-04) replaced the standalone
    #    GTK3 OSD daemon with an in-process QML surface (`Osd.qml`, a
    #    `Toast.qml` instance) owned by the same Quickshell shell process
    #    the bar and notification centre already run in. QML hot-reloads
    #    its own palette through `Colours.qml` on file change natively —
    #    unlike the retired daemon's GTK3 style.css (no live CSS reload
    #    API), there is nothing here that needs a kill/relaunch step on a
    #    theme switch. This fan-out step is intentionally absent, not
    #    silently dropped.
    #
    # RETIRE-06 (Phase 21 Plan 08): the standalone GTK4 media applet's own
    # CSS-only hot-reload step stood here until this plan retired that
    # surface. Nothing replaces it: the dashboard Media tab and bar popout
    # are QML and re-read their own palette through `Colours.qml` on file
    # change natively, the same reason the OSD fan-out step immediately
    # above is also absent.

    # ── Zen browser (THM-05/D-26/D-27/D-28): lazy profile self-heal +
    #    notify-only reload — never kills the browser.
    theme_engine_reload_zen
}

# theme_engine_reload_tmux
# Quick task 260819-vas: re-sources the freshly rendered colours file into
# every LIVE tmux server, so a running session re-themes without a
# restart. Best-effort and silent, like every other hook in this file —
# never fatal to the wider fan-out.
#
# Three guards, in order:
#   1. `command -v tmux` — absent on a host that hasn't installed tmux yet
#      (M-10 — it was entirely undeclared before this task).
#   2. The rendered file existing — a run before the first successful
#      theme-apply (e.g. this very commit, before Task 1's stow ever ran
#      matugen once) is a clean no-op, not an error.
#   3. The tmux socket directory existing, then a per-socket `[[ -S ]]`
#      test — so a host with tmux installed but no server running (the
#      common case) is also a clean, silent no-op.
#
# Iterates every socket under ${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)/ rather
# than only the default one, so a server on a named socket (e.g. one
# started via `tmux -L somename`) re-themes too.
#
# Sources the GENERATED colours file directly
# (~/.local/state/theme/tmux-colors.conf), never tmux.conf itself:
# re-sourcing the whole config would re-execute the tpm `run` line and
# re-source every plugin's *.tmux script on every theme switch, which is
# both wasteful and exactly the kind of extra writer this plan's ordering
# (M-3) is designed to avoid. Sourcing only the colour file makes matugen
# trivially the last writer without depending on any file ordering at all.
theme_engine_reload_tmux() {
    command -v tmux &>/dev/null || return 0

    local colours_file="$STATE_DIR/tmux-colors.conf"
    [[ -f "$colours_file" ]] || return 0

    local sock_dir="${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)"
    [[ -d "$sock_dir" ]] || return 0

    local sock
    for sock in "$sock_dir"/*; do
        [[ -S "$sock" ]] || continue
        tmux -S "$sock" source-file -q "$colours_file" >/dev/null 2>&1 || true
    done

    return 0
}

theme_engine_reload_zen() {
    local zen_root="$HOME/.zen"

    # D-26: lazy self-heal — ~/.zen doesn't exist until Zen has launched
    # at least once. Skip silently (logged, non-fatal) so a machine that
    # has never run Zen never gets a false-alarm toast on every switch.
    if [[ ! -d "$zen_root" ]]; then
        echo "theme_engine_reload_zen: ~/.zen not present — skipping (Zen not yet launched)"
        return 0
    fi

    local zen_real profile_rel=""
    zen_real=$(realpath -m -- "$zen_root")

    # ── Pitfall 5: installs.ini is the authoritative "which profile does
    #    THIS install use" answer on modern Firefox-family browsers —
    #    read it first. Single-user desktop: exactly one install-hash
    #    section is expected, take its Default= unconditionally if so.
    if [[ -f "$zen_root/installs.ini" ]]; then
        local install_sections
        install_sections=$(grep -c '^\[' "$zen_root/installs.ini" 2>/dev/null) || true
        install_sections=${install_sections:-0}
        if [[ "$install_sections" -eq 1 ]]; then
            profile_rel=$(awk '/^Default=/{ sub(/^Default=/, ""); print; exit }' "$zen_root/installs.ini")
        fi
    fi

    # ── Pitfall 5 fallback: legacy profiles.ini — try [General] Default=
    #    first, then any [ProfileN] section flagged Default=1 (its Path=).
    if [[ -z "$profile_rel" && -f "$zen_root/profiles.ini" ]]; then
        profile_rel=$(awk '
            /^\[General\]/ { in_general=1; next }
            /^\[/ { in_general=0 }
            in_general && /^Default=/ { sub(/^Default=/,""); print; exit }
        ' "$zen_root/profiles.ini")

        if [[ -z "$profile_rel" ]]; then
            profile_rel=$(awk '
                function flush() { if (!found && def == 1 && path != "") { print path; found=1 } }
                /^\[Profile/ { flush(); path=""; def=0; next }
                /^\[/ { flush(); path=""; def=0; next }
                /^Path=/ { sub(/^Path=/,""); path=$0 }
                /^Default=1/ { def=1 }
                END { flush() }
            ' "$zen_root/profiles.ini")
        fi
    fi

    if [[ -z "$profile_rel" ]]; then
        echo "theme_engine_reload_zen: could not resolve a default profile from installs.ini/profiles.ini — skipping"
        return 0
    fi

    # ── Security Domain V5/T-06-10: validate the resolved path is a real,
    #    existing subdirectory of ~/.zen before ever using it as a
    #    symlink/write target — never trust the ini value blindly.
    local profile_dir
    profile_dir=$(realpath -m -- "$zen_root/$profile_rel")
    if [[ "$profile_dir" != "$zen_real"/* || ! -d "$profile_dir" ]]; then
        echo "theme_engine_reload_zen: resolved profile path '$profile_dir' is not a valid existing subdirectory of ~/.zen — skipping"
        return 0
    fi

    # ── Self-heal: symlink userChrome.css into the profile's chrome/ dir
    #    (idempotent, D-26 first-time auto-wire) and defensively write the
    #    legacy stylesheets pref (Pitfall 4 — harmless on versions that
    #    ignore it, required on versions that still honor it).
    mkdir -p "$profile_dir/chrome"
    ln -sf "$STATE_DIR/zen-userchrome.css" "$profile_dir/chrome/userChrome.css"

    local user_js="$profile_dir/user.js"
    local pref_line='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
    if [[ ! -f "$user_js" ]] || ! grep -qF "$pref_line" "$user_js" 2>/dev/null; then
        printf '%s\n' "$pref_line" >> "$user_js"
    fi

    # ── D-28: notify-only, NEVER kill/restart Zen — matches the accepted
    #    GTK3 stale-until-closed posture. Silent if Zen isn't running.
    if pgrep -x zen-bin >/dev/null 2>&1; then
        notify-send -a "Zen Browser" "Theme Updated" "Restart Zen to apply the new theme" -i web-browser -t 3000 2>/dev/null || true
    fi

    return 0
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
