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

# ── Dim screen (D-30) ────────────────────────────────
# D-30 chains the live-wallpaper owner's idle suppression onto THIS
# existing listener rather than adding a new one. hypridle chains
# multiple shell commands on one on-timeout/on-resume line correctly
# (each command fires independently, in order).
listener {
    timeout = $t_dim
    on-timeout = brightnessctl -s set 30% && ~/.config/hypr/scripts/wallpaper-visibility.sh idle hide
    on-resume = brightnessctl -r && ~/.config/hypr/scripts/wallpaper-visibility.sh idle show
}

# ── Lock screen ─────────────────────────────────────
listener {
    timeout = $t_lock
    on-timeout = loginctl lock-session
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
