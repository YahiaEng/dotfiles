#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║   IDLE-OVERRIDES — editable idle/lock timing            ║
# ║   (quick task 260820-sqd, Task 4)                        ║
# ╚══════════════════════════════════════════════════════╝
#
# hypr-overrides.sh's own validate -> apply -> verify -> persist ordering,
# with one addition: idle lock is a SECURITY CONTROL, and PD-03 probe A
# measured that hypridle proceeds with ZERO rules on a broken config
# rather than failing loudly. A corrupt or deleted overrides file must
# never leave the machine unable to lock (T-SQD-08) — so this script
# backs up before writing, and rolls back if the post-restart effective
# rule count is wrong.
#
# `hypridle.service` is inactive/disabled on this host (measured, PD-03
# probe E) — the live process is the uwsm transient scope
# `app-Hyprland-hypridle-*.scope`. `systemctl --user restart hypridle`
# would exit cleanly and change NOTHING. This script kills the running
# process and relaunches it exactly as autostart does
# (`uwsm app -- hypridle`) — hypridle has no SIGHUP handler (PD-03 probe
# D), so a restart is the only path.
#
# Usage:
#   idle-overrides.sh --set <listener>=<seconds> [--set <listener>=<seconds> ...]
#   Listeners: bar-idle, dim, lock, display-off, suspend

set -uo pipefail

STATE_DIR="$HOME/.local/state/hypr"
IDLE_CONF="$STATE_DIR/idle-overrides.conf"
BACKUP="$STATE_DIR/idle-overrides.conf.bak"
FLOOR=30

mkdir -p "$STATE_DIR"

# ── Read the CURRENT effective timeouts out of the state-dir file, so an
#    unspecified --set flag keeps its existing value rather than being
#    silently reset. Parses "timeout = N" following each of the file's
#    five listener blocks, in DECLARATION ORDER (bar-idle, dim, lock,
#    display-off, suspend) — the seed's own fixed order, never reordered
#    by this script. ─────────────────────────────────────────────────────
_current_timeouts() {
    if [[ ! -f "$IDLE_CONF" ]]; then
        echo "120 300 600 900 1800"
        return
    fi
    grep -A1 '^[[:space:]]*listener[[:space:]]*{' "$IDLE_CONF" \
        | grep -oP 'timeout\s*=\s*\K[0-9]+' \
        | tr '\n' ' '
}

# ── Render the five listener blocks from the given timeouts, on the
#    seed's own exact content (comments included) — this is a template
#    substitution, never raw passthrough: the ONLY variable part is the
#    already-validated integer timeout on each block's own line. ────────
_render() {
    local t_bar="$1" t_dim="$2" t_lock="$3" t_off="$4" t_suspend="$5"
    cat <<CONFEOF
# ── Bar idle hide (BAR-01/D-05, repointed Phase 18 Plan 15/QBAR-07) ──
# Declares the "idle" intent to the visibility owner; the owner computes
# the resulting state (D-01's OR-union across idle/fullscreen/gaming) and
# actuates the QML bar over Quickshell IPC. Never calls \`qs ipc call bar\`
# directly. on-resume fires on any keypress/mouse movement, so idle-hide
# clears on any input with no extra machinery (D-02).
listener {
    timeout = $t_bar
    on-timeout = ~/.config/hypr/scripts/bar-visibility.sh idle hide
    on-resume = ~/.config/hypr/scripts/bar-visibility.sh idle show
}

# ── Dim screen (D-30) + screensaver (quick task 260827-b52) ──────────
# D-30 chains the live-wallpaper owner's idle suppression onto THIS
# existing listener rather than adding a new one. hypridle chains
# multiple shell commands on one on-timeout/on-resume line correctly
# (each command fires independently, in order).
#
# The screensaver chains onto the SAME listener, per the operator's own
# ruling ("300 s — together with the dim"). That is why there is no
# t_screensaver knob and no sixth listener: the saver has no independent
# timeout to tune, by design. Moving it later means moving the dim.
#
# The \`&&\` chain is safe here even though this host has NO backlight
# device (/sys/class/backlight/ is empty): measured, a \`brightnessctl -s
# set 30%\` falls through to the first leds-class device it finds and
# exits 0, so the chain never short-circuits before reaching the saver.
# (It currently dims the ethernet port's LAN LED. Harmless, pre-existing,
# and noted here only so the exit code is not re-derived later.)
#
# ⚠ EVERY BACKTICK IN THIS HEREDOC MUST STAY ESCAPED. _render's heredoc
# is <<CONFEOF, NOT <<'CONFEOF', so bash expands its body — an unescaped
# backtick pair is COMMAND SUBSTITUTION, executed at render time. Adding
# this very comment with bare backticks made the script hang: bash forked
# a real \`qs ipc call screensaver show\` and blocked on its pipe with a
# zero-byte .conf.tmp already in place. Escaped, as every other backtick
# in this heredoc already is.
#
# The \`--\` before the target is MANDATORY, not stylistic. On this \`qs\`
# CLI the literal token "show" collides with the \`ipc show\` subcommand
# one level up in CLI11's parser, so \`qs ipc call screensaver show\`
# silently prints the target's interface listing and exits 0 WITHOUT
# calling anything. This repo has been bitten by it once already —
# bar-visibility.sh:254 records the same finding and the same \`--\` fix
# for the bar. Reproduced here before the separator was added: the call
# returned the handler listing and no surface was ever created.
#
# The show call is a no-op when the style picker is
# "off", when a media player is playing, or when a window is fullscreen —
# Screensaver.qml gates all three at its own show() rather than here, so
# a future second trigger inherits the gate.
listener {
    timeout = $t_dim
    on-timeout = brightnessctl -s set 30% && ~/.config/hypr/scripts/wallpaper-visibility.sh idle hide && qs ipc call -- screensaver show
    on-resume = brightnessctl -r && ~/.config/hypr/scripts/wallpaper-visibility.sh idle show && qs ipc call -- screensaver hide
}

# ── Lock screen ─────────────────────────────────────
# The screensaver is torn down BEFORE the lock, and the order matters.
# The lock screen's backdrop is a live ScreencopyView of the output, so
# whatever is on screen when it mounts is what gets blurred behind the
# password field — and since the saver appears at the dim timeout above and
# the lock is the NEXT rung, the saver is always up when this fires.
# Operator: "Our lockscreens now show blurred screensaver instead of
# blurred desktop background."
#
# The \`sleep 0.4\` is NOT superstition. Measured: with the saver up,
# \`hideNow && loginctl lock-session\` still produced a lock screen whose
# blurred backdrop was the saver — a captured lock frame showed the AORUS
# wordmark ghosted behind the clock, even though \`hyprctl layers\` reported
# zero saver surfaces by the time the lock was up. The IPC call returns as
# soon as QML drops the surfaces; the compositor has not finished unmapping
# and recompositing when the lock's ScreencopyView samples the output. 0.4s
# is ~24 frames of margin and is not perceptible before a lock screen.
#
# \`hideNow\`, not \`hide\`: the ordinary dismissal fades out over the motion
# token's duration and only then unmounts, which would leave the screencopy
# capturing a half-faded saver. \`hideNow\` drops the surfaces immediately.
# Screensaver.qml ALSO force-hides on its own \`sessionLocked\` watcher, which
# covers the lock paths that never come through hypridle (the power menu,
# before_sleep_cmd) — this line is the ordering guarantee for THIS path.
listener {
    timeout = $t_lock
    on-timeout = qs ipc call -- screensaver hideNow && sleep 0.4 && loginctl lock-session
}

# ── Turn off display ────────────────────────────────
# Table form is mandatory — the bare-string dpms form is a silent no-op
# under the Lua config manager, and the string TOGGLE form would switch
# the display back OFF on every wake, since wake-on-input has already
# turned it on by the time on-resume runs.
listener {
    timeout = $t_off
    on-timeout = hyprctl dispatch 'hl.dsp.dpms({action="off"})'
    on-resume = hyprctl dispatch 'hl.dsp.dpms({action="on"})'
}

# ── Suspend ──────────────────────────────────────────
listener {
    timeout = $t_suspend
    on-timeout = systemctl suspend
}
CONFEOF
}

main() {
    local cur
    cur=$(_current_timeouts)
    read -r t_bar t_dim t_lock t_off t_suspend <<< "$cur"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --set)
                local pair="$2"
                local key="${pair%%=*}"
                local val="${pair#*=}"
                # T-SQD-08: hard floor. A 1s lock timeout is
                # indistinguishable from a denial of service.
                if ! [[ "$val" =~ ^[0-9]+$ ]]; then
                    echo "idle-overrides.sh: '$val' is not an integer" >&2
                    exit 1
                fi
                if [[ "$val" -lt "$FLOOR" ]]; then
                    echo "idle-overrides.sh: '$key=$val' is below the ${FLOOR}s floor" >&2
                    exit 1
                fi
                case "$key" in
                    bar-idle) t_bar="$val" ;;
                    dim) t_dim="$val" ;;
                    lock) t_lock="$val" ;;
                    display-off) t_off="$val" ;;
                    suspend) t_suspend="$val" ;;
                    *) echo "idle-overrides.sh: unknown listener '$key'" >&2; exit 1 ;;
                esac
                shift 2
                ;;
            *)
                echo "Usage: idle-overrides.sh --set <listener>=<seconds> [...]" >&2
                exit 1
                ;;
        esac
    done

    # Ordering sanity. NOTE: the currently-shipped, correct configuration
    # is dim(300) < lock(600) < display-off(900) < suspend(1800) — dim the
    # screen, THEN lock the session, THEN physically blank the display to
    # save power, THEN suspend. Validated against that real order, not
    # against a "dim < screen-off < lock" reading that would reject the
    # repo's own already-deployed defaults.
    if ! { [[ "$t_dim" -lt "$t_lock" ]] && [[ "$t_lock" -lt "$t_off" ]] && [[ "$t_off" -lt "$t_suspend" ]]; }; then
        echo "idle-overrides.sh: ordering violated — need dim < lock < display-off < suspend (got $t_dim, $t_lock, $t_off, $t_suspend)" >&2
        exit 1
    fi

    # ── Backup before writing (T-SQD-08's rollback target) ───────────────
    [[ -f "$IDLE_CONF" ]] && cp -a "$IDLE_CONF" "$BACKUP"

    # ── Persist atomically, motion-switch.sh:142-143's shape ─────────────
    _render "$t_bar" "$t_dim" "$t_lock" "$t_off" "$t_suspend" > "$IDLE_CONF.tmp" && mv "$IDLE_CONF.tmp" "$IDLE_CONF"

    # ── Apply: kill the running process, relaunch exactly as autostart
    #    does. NEVER systemctl — the unit is inactive on this host. ──────
    pkill -x hypridle 2>/dev/null || true
    sleep 0.3
    uwsm app -- hypridle >/dev/null 2>&1 &
    disown
    sleep 1

    # ── Verify: the effective config parses to a non-zero rule count.
    #    Safe to run standalone (validation already guarantees no timeout
    #    under the floor) — this throwaway instance never claims the
    #    ScreenSaver D-Bus name for long enough to matter, since it exits
    #    on its own after registering rules and hitting the "already
    #    running" conflict. ─────────────────────────────────────────────
    local effective
    effective=$(timeout 2 hypridle -c "$HOME/.config/hypr/hypridle.conf" 2>&1 || true)
    local rule_count
    rule_count=$(printf '%s\n' "$effective" | grep -oP 'found \K[0-9]+(?= rules)' | head -1)

    if [[ -z "$rule_count" || "$rule_count" -eq 0 ]]; then
        echo "idle-overrides.sh: effective config has $rule_count rules after apply — ROLLING BACK" >&2
        if [[ -f "$BACKUP" ]]; then
            mv "$BACKUP" "$IDLE_CONF"
        fi
        pkill -x hypridle 2>/dev/null || true
        sleep 0.3
        uwsm app -- hypridle >/dev/null 2>&1 &
        disown
        exit 1
    fi

    echo "idle-overrides.sh: applied ($rule_count rules) and persisted"
}

main "$@"
