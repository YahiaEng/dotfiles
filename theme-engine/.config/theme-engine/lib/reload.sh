#!/usr/bin/env bash
# theme-engine/lib/reload.sh — the ONLY reload fan-out owner (D-04/PIPE-02)
#
# Runs exactly once, only after commit.sh has successfully moved rendered
# output into ~/.local/state/theme/ — never against half-rendered state.
# No other file in this repo may invoke hyprctl reload / pkill -SIGUSR* /
# the vscodium merge — this is the single owner (matugen's post_hooks
# were stripped in Plan 01-02 Task 1 specifically so this is the only
# place any of that fires).
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
    # GTK gsettings, and even the file-only vscodium merge are all
    # skipped here). With no session,
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

    # ── nvim (themed-nvim idea, quick task 260820-nua) ──────────────
    # Grouped here with the other terminal-surface reloads, next to the
    # kitty signal. Unlike zellij (which watches its own config file) or
    # fish (which reads at shell start and never re-themes an already-open
    # shell), a running nvim never re-reads anything on its own — it needs
    # to be told, which is what this block does.
    #
    # MEASURED (SPIKE-002): the default nvim server socket needs no
    # `--listen` flag — every instance already listens at
    # $XDG_RUNTIME_DIR/nvim.<pid>.<n>, so a plain glob enumerates every
    # live one. MEASURED (SPIKE-002): a socket left behind by a crashed
    # instance fails to connect in ~4ms rather than hanging — this repo has
    # a scar from a reload hook that once blocked 45+ minutes on a dead
    # endpoint (the INST-03 gate hang), so this block is both `timeout`-
    # bounded AND `|| true`-guarded, belt-and-braces even though the
    # measured failure mode is already fast.
    for _nvim_sock in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/nvim.*; do
        [[ -S "$_nvim_sock" ]] || continue
        timeout 1 nvim --server "$_nvim_sock" --remote-expr "execute('colorscheme rice')" >/dev/null 2>&1 || true
    done

    # The retired multiplexer's re-source reload hook (grouped with kitty,
    # the other terminal surface this fan-out reloads) stood here until
    # quick task 260820-2yz removed it. Nothing replaces it: the
    # multiplexer surface that is themed today (zellij) watches its own
    # config and live-reloads a running session by itself — see its own
    # no-hook paragraph immediately below for the measured evidence — so a
    # theme switch needs no signal, no client call and no restart on its
    # behalf.
    # The retired notification daemon's reload step stood here until
    # Phase 19 Plan 19-08 Task 5 (RETIRE-03). Nothing replaces it: the
    # QML shell owns notifications in-process now and re-reads its own
    # palette through Colours.qml on file change, so a theme switch
    # needs no signal, no client call and no restart on its behalf.

    # D-05, quick task 260820-0ha: zellij deliberately has NO hook here —
    # this is a MEASURED decision, not an oversight. Unlike fish (which
    # gets none because it re-reads at shell start, so existing shells are
    # deliberately not re-themed), zellij gets none for a DIFFERENT
    # reason: it is the only surface here that watches its own config file
    # and live-reloads a running session by itself. Measured through the
    # real mechanism this session — commit.sh's rsync replacing the
    # symlink target's inode — with a PTY probe against a running session:
    # the new colour's SGR appeared and the old one was entirely gone, no
    # restart. Adding a hook here would be redundant work on every theme
    # switch for a surface that already reloads itself.

    # ── GTK (gsettings toggle + env propagation + Thunar daemon) ──
    theme_engine_gtk_reload

    # The retired external launcher's own restart-only reload step (kill/
    # relaunch with a bounded poll for process exit and a backend-daemon
    # health check before declaring success) stood here until quick task
    # 260822-sht (Task 11) removed it along with the surface it targeted.
    # Nothing replaces it: the native QML launcher that replaced it lives
    # inside the same Quickshell shell process the bar/notifications/OSD
    # already run in, and re-reads its own palette through `Colours.qml`
    # on file change natively, the same reason the OSD fan-out step below
    # is also absent.

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
