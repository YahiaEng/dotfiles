#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║           BAR WATCHDOG FIXTURE HARNESS (QBAR-11)        ║
# ║  Proves bar-watchdog.sh's event parse, exact-match       ║
# ║  namespace trap, recovery argv and rate limit against    ║
# ║  a fixture AF_UNIX socket and PATH-shimmed hyprctl/       ║
# ║  systemctl — never the real compositor or user manager.  ║
# ╚══════════════════════════════════════════════════════╝
#
# Cases A-H, each independent, each with a bounded timeout so a hung
# watchdog fails this harness instead of hanging it.
#
# Design note: the fixture server paces its own event writes internally
# (in python, via time.sleep between sendall calls) rather than being fed
# live from bash through a FIFO. A bash-side FIFO relay requires an open
# writer fd to be held across multiple sends without an intermediate
# close (a FIFO reader sees EOF the instant its writer count drops to
# zero), and coordinating that against the server's own accept()/open()
# blocking points proved to be a real, load-sensitive race — it hung
# intermittently in early testing. Letting python own the whole
# event-timeline removes the cross-process handoff entirely: bash starts
# the server, waits for the socket file, then runs the watchdog
# synchronously (bounded by `timeout`) and inspects what happened after
# the server's connection closes.
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SCRIPTS_DIR="$(cd -- "$SCRIPT_DIR/.." &>/dev/null && pwd)"
WATCHDOG="$SCRIPTS_DIR/bar-watchdog.sh"

PASS=0
FAIL=0

check() {
    local desc="$1"
    local ok="$2"
    if [[ "$ok" == "0" ]]; then
        echo "  [PASS] $desc"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $desc"
        FAIL=$((FAIL + 1))
    fi
}

TMP="$(mktemp -d)"
cleanup() {
    [[ -n "${SERVER_PID:-}" ]] && kill "$SERVER_PID" 2>/dev/null
    rm -rf "$TMP"
}
trap cleanup EXIT

FAKE_SIG="fixture-sig"
SOCK_DIR="$TMP/hypr/$FAKE_SIG"
mkdir -p "$SOCK_DIR"
SOCK_PATH="$SOCK_DIR/.socket2.sock"

BIN_DIR="$TMP/bin"
mkdir -p "$BIN_DIR"

SYSTEMCTL_LOG="$TMP/systemctl.log"
: > "$SYSTEMCTL_LOG"

cat > "$BIN_DIR/systemctl" <<'SHIM'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SYSTEMCTL_LOG_FILE"
exit 0
SHIM
chmod +x "$BIN_DIR/systemctl"

write_hyprctl_absent() {
    cat > "$BIN_DIR/hyprctl" <<'SHIM'
#!/usr/bin/env bash
if [[ "$1" == "layers" ]]; then
    cat <<'JSON'
{
  "DP-1": {
    "levels": {
      "0": [],
      "1": [{"namespace": "quickshell-bar-hotzone"}],
      "2": [{"namespace": "quickshell-bardrawer-audio"}]
    }
  }
}
JSON
    exit 0
fi
exit 0
SHIM
    chmod +x "$BIN_DIR/hyprctl"
}

write_hyprctl_present() {
    cat > "$BIN_DIR/hyprctl" <<'SHIM'
#!/usr/bin/env bash
if [[ "$1" == "layers" ]]; then
    cat <<'JSON'
{
  "DP-1": {
    "levels": {
      "0": [],
      "1": [{"namespace": "quickshell-bar-hotzone"}],
      "2": [{"namespace": "quickshell-bar"}]
    }
  }
}
JSON
    exit 0
fi
exit 0
SHIM
    chmod +x "$BIN_DIR/hyprctl"
}

write_hyprctl_fail() {
    cat > "$BIN_DIR/hyprctl" <<'SHIM'
#!/usr/bin/env bash
exit 1
SHIM
    chmod +x "$BIN_DIR/hyprctl"
}

write_hyprctl_nonjson() {
    cat > "$BIN_DIR/hyprctl" <<'SHIM'
#!/usr/bin/env bash
echo "not json at all"
exit 0
SHIM
    chmod +x "$BIN_DIR/hyprctl"
}

export PATH="$BIN_DIR:$PATH"
export SYSTEMCTL_LOG_FILE="$SYSTEMCTL_LOG"
export XDG_RUNTIME_DIR="$TMP"
export HYPRLAND_INSTANCE_SIGNATURE="$FAKE_SIG"
# Global debounce compression for every case except E (which sets its own
# tighter override to demonstrate the harness controls it independently)
# — otherwise every case would need to hold its fixture connection open
# for the shipped 3.0s default, making this harness needlessly slow. This
# is a test-methodology choice, not a behavior under test.
export BAR_WATCHDOG_DEBOUNCE_SEC=0.4

# start_fixture SPACING SETTLE event1 [event2 ...]
#   SPACING: seconds slept between each sent event
#   SETTLE:  seconds slept after the last event before closing the
#            connection — must exceed the active debounce so the pending
#            evaluation actually fires before EOF is observed
# Binds a fresh fixture socket at $SOCK_PATH, accepts exactly one
# connection, sends each event line with SPACING between them, sleeps
# SETTLE, then closes. Sets $SERVER_PID.
start_fixture() {
    local spacing="$1" settle="$2"
    shift 2
    rm -f "$SOCK_PATH"
    python3 - "$SOCK_PATH" "$spacing" "$settle" "$@" <<'PYEOF' &
import socket
import sys
import time
import os

sock_path = sys.argv[1]
spacing = float(sys.argv[2])
settle = float(sys.argv[3])
events = sys.argv[4:]

if os.path.exists(sock_path):
    os.unlink(sock_path)

srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
srv.bind(sock_path)
srv.listen(1)

conn, _ = srv.accept()
try:
    for line in events:
        conn.sendall((line + "\n").encode())
        time.sleep(spacing)
    time.sleep(settle)
    conn.close()
except OSError:
    pass
srv.close()
try:
    os.unlink(sock_path)
except OSError:
    pass
PYEOF
    SERVER_PID=$!
    for _ in $(seq 1 50); do
        [[ -S "$SOCK_PATH" ]] && break
        sleep 0.05
    done
}

reap_fixture() {
    wait "$SERVER_PID" 2>/dev/null || true
    SERVER_PID=""
}

# run_watchdog MODE SPACING SETTLE [event1 ...]
# Starts the fixture, runs the watchdog synchronously (bounded by
# `timeout`) so it observes exactly the scripted event sequence then a
# clean EOF, and reaps the fixture server. Sets $RUN_OUT / $RUN_RC.
run_watchdog() {
    local mode="$1" spacing="$2" settle="$3"
    shift 3
    start_fixture "$spacing" "$settle" "$@"
    RUN_OUT="$(timeout 10 "$WATCHDOG" $mode 2>&1)"
    RUN_RC=$?
    reap_fixture
}

echo "test-bar-watchdog — fixture harness (QBAR-11 / WINDOWS row 67)"

# ── Case A: event parse, dry-run, bar absent -> WOULD RESTART, zero shim calls
echo ""
echo "-- Case A: event parse (dry-run, bar absent) --"
write_hyprctl_absent
: > "$SYSTEMCTL_LOG"
run_watchdog "--dry-run" 0.3 0.8 "monitorremoved>>DP-1"
check "Case A: dry-run logs event seen" "$(echo "$RUN_OUT" | grep -q 'event seen: monitorremoved' && echo 0 || echo 1)"
check "Case A: dry-run logs WOULD RESTART" "$(echo "$RUN_OUT" | grep -q 'WOULD RESTART' && echo 0 || echo 1)"
shim_calls="$(wc -l < "$SYSTEMCTL_LOG" | tr -d ' ')"
check "Case A: systemctl shim invoked zero times in dry-run" "$([[ "$shim_calls" -eq 0 ]] && echo 0 || echo 1)"

# ── Case B: exact-match trap — siblings-only fixture reads absent ──────
echo ""
echo "-- Case B: exact-match trap (siblings only) --"
write_hyprctl_absent
"$WATCHDOG" --check >/tmp/case_b_out 2>&1
rc=$?
check "Case B: --check exits 1 (absent) against sibling-only namespaces" "$([[ $rc -eq 1 ]] && echo 0 || echo 1)"
check "Case B: --check prints 'absent'" "$(grep -qx 'absent' /tmp/case_b_out && echo 0 || echo 1)"

# ── Case C: present is left alone ───────────────────────────────────────
echo ""
echo "-- Case C: present -> no action, zero shim calls --"
write_hyprctl_present
"$WATCHDOG" --check >/tmp/case_c_out 2>&1
rc=$?
check "Case C: --check exits 0 (present)" "$([[ $rc -eq 0 ]] && echo 0 || echo 1)"
check "Case C: --check prints 'present'" "$(grep -qx 'present' /tmp/case_c_out && echo 0 || echo 1)"

: > "$SYSTEMCTL_LOG"
run_watchdog "" 0.3 0.8 "monitorremoved>>DP-1"
shim_calls_c="$(wc -l < "$SYSTEMCTL_LOG" | tr -d ' ')"
check "Case C: watch mode with bar present logs no-action" "$(echo "$RUN_OUT" | grep -q 'no action' && echo 0 || echo 1)"
check "Case C: watch mode with bar present invokes shim zero times" "$([[ "$shim_calls_c" -eq 0 ]] && echo 0 || echo 1)"

# ── Case D: recovery argv, default watch mode ───────────────────────────
echo ""
echo "-- Case D: recovery argv (watch mode, bar absent) --"
write_hyprctl_absent
: > "$SYSTEMCTL_LOG"
run_watchdog "" 0.3 0.8 "monitorremoved>>DP-1"
shim_line_count_d="$(wc -l < "$SYSTEMCTL_LOG" | tr -d ' ')"
check "Case D: systemctl shim invoked exactly once" "$([[ "$shim_line_count_d" -eq 1 ]] && echo 0 || echo 1)"
check "Case D: recorded argv is exactly '--user restart quickshell.service'" "$(grep -qx -- '--user restart quickshell.service' "$SYSTEMCTL_LOG" && echo 0 || echo 1)"

# ── Case E: rate limit — compressed tunables, 4 events -> 2 shim calls ──
echo ""
echo "-- Case E: rate limit (compressed tunables) --"
write_hyprctl_absent
: > "$SYSTEMCTL_LOG"
export BAR_WATCHDOG_DEBOUNCE_SEC=0.3
export BAR_WATCHDOG_MIN_INTERVAL_SEC=0.5
export BAR_WATCHDOG_MAX_RESTARTS=2
export BAR_WATCHDOG_WINDOW_SEC=60
run_watchdog "" 0.6 0.9 \
    "monitorremoved>>DP-1" "monitoradded>>DP-1" \
    "monitorremoved>>DP-1" "monitoradded>>DP-1"
export BAR_WATCHDOG_DEBOUNCE_SEC=0.4
unset BAR_WATCHDOG_MIN_INTERVAL_SEC BAR_WATCHDOG_MAX_RESTARTS BAR_WATCHDOG_WINDOW_SEC
shim_line_count_e="$(wc -l < "$SYSTEMCTL_LOG" | tr -d ' ')"
check "Case E: exactly two shim invocations from four events" "$([[ "$shim_line_count_e" -eq 2 ]] && echo 0 || echo 1)"
check "Case E: log states the limit was reached" "$(echo "$RUN_OUT" | grep -q 'rate limit reached' && echo 0 || echo 1)"

# ── Case F: indeterminate fails safe ────────────────────────────────────
echo ""
echo "-- Case F: indeterminate (hyprctl exit 1 / non-JSON) --"
write_hyprctl_fail
"$WATCHDOG" --check >/tmp/case_f1_out 2>&1
rc=$?
check "Case F: hyprctl exit 1 -> --check exits 2" "$([[ $rc -eq 2 ]] && echo 0 || echo 1)"
check "Case F: hyprctl exit 1 -> --check prints 'indeterminate'" "$(grep -qx 'indeterminate' /tmp/case_f1_out && echo 0 || echo 1)"

: > "$SYSTEMCTL_LOG"
run_watchdog "" 0.3 0.8 "monitorremoved>>DP-1"
shim_calls_f1="$(wc -l < "$SYSTEMCTL_LOG" | tr -d ' ')"
check "Case F: hyprctl exit 1 -> logs indeterminate, zero shim calls" "$(echo "$RUN_OUT" | grep -q 'indeterminate' && [[ "$shim_calls_f1" -eq 0 ]] && echo 0 || echo 1)"

write_hyprctl_nonjson
"$WATCHDOG" --check >/tmp/case_f2_out 2>&1
rc=$?
check "Case F: non-JSON output -> --check exits 2" "$([[ $rc -eq 2 ]] && echo 0 || echo 1)"
check "Case F: non-JSON output -> --check prints 'indeterminate'" "$(grep -qx 'indeterminate' /tmp/case_f2_out && echo 0 || echo 1)"

: > "$SYSTEMCTL_LOG"
run_watchdog "" 0.3 0.8 "monitorremoved>>DP-1"
shim_calls_f2="$(wc -l < "$SYSTEMCTL_LOG" | tr -d ' ')"
check "Case F: non-JSON -> logs indeterminate, zero shim calls" "$(echo "$RUN_OUT" | grep -q 'indeterminate' && [[ "$shim_calls_f2" -eq 0 ]] && echo 0 || echo 1)"

# ── Case G: ignored events never trigger a check ────────────────────────
echo ""
echo "-- Case G: ignored events (activewindow, workspace) --"
write_hyprctl_absent
: > "$SYSTEMCTL_LOG"
run_watchdog "--dry-run" 0.3 0.8 "activewindow>>foo,bar" "workspace>>3"
shim_calls_g="$(wc -l < "$SYSTEMCTL_LOG" | tr -d ' ')"
check "Case G: no evaluation/restart from ignored events" "$(echo "$RUN_OUT" | grep -q 'WOULD RESTART' && echo 1 || echo 0)"
check "Case G: systemctl shim invoked zero times" "$([[ "$shim_calls_g" -eq 0 ]] && echo 0 || echo 1)"

# ── Case H: EOF breaks the loop, exits 0, no spin ───────────────────────
echo ""
echo "-- Case H: EOF (server closes connection) --"
write_hyprctl_absent
start_fixture 0.1 0.2
start_t=$(date +%s.%N)
RUN_OUT="$(timeout 10 "$WATCHDOG" 2>&1)"
rc=$?
end_t=$(date +%s.%N)
reap_fixture
elapsed="$(awk -v a="$start_t" -v b="$end_t" 'BEGIN{printf "%.2f", b-a}')"
check "Case H: watchdog exits 0 on EOF" "$([[ $rc -eq 0 ]] && echo 0 || echo 1)"
check "Case H: exits within a few seconds of EOF (does not spin)" "$(awk -v e="$elapsed" 'BEGIN{exit !(e < 5.0)}' && echo 0 || echo 1)"

echo ""
echo "Summary: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
exit $?
