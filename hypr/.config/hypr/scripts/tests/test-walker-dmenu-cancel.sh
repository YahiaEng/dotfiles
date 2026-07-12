#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║        WALKER DMENU EXIT-CODE CHECKER (05-05)         ║
# ║  Hermetic checker for the Esc-cancel error-toast gap   ║
# ║  (UAT Test 4 / WR-04). Stubs walker + notify-send on a  ║
# ║  temp PATH and drives theme-switch.sh / waybar-switch.sh ║
# ║  non-interactively to assert the three-way exit-code     ║
# ║  branch: walker 130 = silent cancel, other nonzero =      ║
# ║  loud failure, 0 = normal selection flow.                 ║
# ╚══════════════════════════════════════════════════════╝
#
# Usage: test-walker-dmenu-cancel.sh [theme-switch|waybar]
#   With no argument: runs both suites.
#
# Report-only — never mutates real theme/waybar state; walker and
# notify-send are shimmed on a prepended PATH, and the theme-switch
# success case runs under a fully isolated temp HOME.
#
# Intentionally NOT `set -e`: sub-script invocations are expected to
# exit nonzero in several cases, and this checker must keep running
# afterward to assert on that exit code (see plan Task 1).
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SCRIPTS_DIR="$(cd -- "$SCRIPT_DIR/.." &>/dev/null && pwd)"
THEME_SWITCH="$SCRIPTS_DIR/theme-switch.sh"
WAYBAR_SWITCH="$SCRIPTS_DIR/waybar-switch.sh"

PASS=0
FAIL=0

# check DESC OK — OK is "0" for pass, any other value for fail (mirrors the
# repo's theme-parity checker convention).
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

# ── Hermetic shims (walker, notify-send) on a temp PATH ────────────────
SHIMDIR="$(mktemp -d)"
TMP_DIRS=("$SHIMDIR")

cleanup() {
    local t
    for t in "${TMP_DIRS[@]}"; do
        rm -rf "$t"
    done
}
trap cleanup EXIT

cat > "$SHIMDIR/walker" <<'SHIM'
#!/usr/bin/env bash
# Test shim: prints WALKER_OUT (if set) then exits WALKER_RC. Never reads
# stdin — the real callers' input is small enough (<1 KB) to never block on
# the pipe buffer, so this is safe.
if [[ -n "${WALKER_OUT+x}" ]]; then
    printf '%s\n' "$WALKER_OUT"
fi
exit "${WALKER_RC:-0}"
SHIM
chmod +x "$SHIMDIR/walker"

cat > "$SHIMDIR/notify-send" <<'SHIM'
#!/usr/bin/env bash
# Test shim: appends one line per invocation to NOTIFY_LOG, then exits 0.
echo "notify-send: $*" >> "${NOTIFY_LOG:?NOTIFY_LOG not set}"
exit 0
SHIM
chmod +x "$SHIMDIR/notify-send"

NOTIFY_LOG="$SHIMDIR/notify.log"
APPLY_LOG="$SHIMDIR/apply.log"
: > "$NOTIFY_LOG"
: > "$APPLY_LOG"

# ── theme-switch suite ──────────────────────────────────────────────────
run_theme_switch_suite() {
    echo ""
    echo "-- theme-switch.sh --"

    # Case 1: cancel (walker exits 130, no output) — must exit 0, no toast.
    : > "$NOTIFY_LOG"
    local rc=0
    PATH="$SHIMDIR:$PATH" WALKER_RC=130 NOTIFY_LOG="$NOTIFY_LOG" \
        bash "$THEME_SWITCH" </dev/null || rc=$?
    local ok=1
    [[ $rc -eq 0 ]] && ok=0
    check "theme-switch cancel (walker rc=130): sub-script exits 0 (got $rc)" "$ok"
    ok=1
    [[ ! -s "$NOTIFY_LOG" ]] && ok=0
    check "theme-switch cancel (walker rc=130): notify-send not invoked" "$ok"

    # Case 2: hard failure (walker exits 127 — binary missing) — must exit
    # 1 and fire exactly one toast (WR-04 intent preserved).
    : > "$NOTIFY_LOG"
    rc=0
    PATH="$SHIMDIR:$PATH" WALKER_RC=127 NOTIFY_LOG="$NOTIFY_LOG" \
        bash "$THEME_SWITCH" </dev/null || rc=$?
    ok=1
    [[ $rc -eq 1 ]] && ok=0
    check "theme-switch hard-failure (walker rc=127): sub-script exits 1 (got $rc)" "$ok"
    local lines
    lines="$(wc -l < "$NOTIFY_LOG")"
    ok=1
    [[ $lines -eq 1 ]] && ok=0
    check "theme-switch hard-failure (walker rc=127): notify-send invoked exactly once (got $lines)" "$ok"

    # Case 3: success — a real selection maps back to its basename and
    # execs theme-apply unchanged. Runs under an isolated temp HOME with a
    # single seeded palette and a stub theme-apply.
    local tmphome
    tmphome="$(mktemp -d)"
    TMP_DIRS+=("$tmphome")
    mkdir -p "$tmphome/.config/theme-engine/palettes"
    echo '{}' > "$tmphome/.config/theme-engine/palettes/matte-black.json"
    cat > "$tmphome/.config/theme-engine/theme-apply" <<EOF
#!/usr/bin/env bash
echo "apply:\$1" >> "$APPLY_LOG"
exit 0
EOF
    chmod +x "$tmphome/.config/theme-engine/theme-apply"

    : > "$NOTIFY_LOG"
    : > "$APPLY_LOG"
    rc=0
    HOME="$tmphome" PATH="$SHIMDIR:$PATH" WALKER_RC=0 WALKER_OUT="Matte Black" \
        NOTIFY_LOG="$NOTIFY_LOG" bash "$THEME_SWITCH" </dev/null || rc=$?
    ok=1
    [[ $rc -eq 0 ]] && ok=0
    check "theme-switch success: sub-script exits 0 (got $rc)" "$ok"
    ok=1
    grep -qx 'apply:matte-black' "$APPLY_LOG" && ok=0
    check "theme-switch success: theme-apply invoked with mapped basename matte-black" "$ok"
}

# ── waybar-switch suite ─────────────────────────────────────────────────
run_waybar_suite() {
    echo ""
    echo "-- waybar-switch.sh --"

    # Case 1: cancel (walker exits 130) — must exit 0, no toast, no
    # dead-code cancel path.
    : > "$NOTIFY_LOG"
    local rc=0
    PATH="$SHIMDIR:$PATH" WALKER_RC=130 NOTIFY_LOG="$NOTIFY_LOG" \
        bash "$WAYBAR_SWITCH" </dev/null || rc=$?
    local ok=1
    [[ $rc -eq 0 ]] && ok=0
    check "waybar cancel (walker rc=130): sub-script exits 0 (got $rc)" "$ok"
    ok=1
    [[ ! -s "$NOTIFY_LOG" ]] && ok=0
    check "waybar cancel (walker rc=130): notify-send not invoked" "$ok"

    # Case 2: hard failure (walker exits 1 — dead elephant) — must exit 1
    # and fire exactly one toast, never a silent swallow.
    : > "$NOTIFY_LOG"
    rc=0
    PATH="$SHIMDIR:$PATH" WALKER_RC=1 NOTIFY_LOG="$NOTIFY_LOG" \
        bash "$WAYBAR_SWITCH" </dev/null || rc=$?
    ok=1
    [[ $rc -eq 1 ]] && ok=0
    check "waybar hard-failure (walker rc=1): sub-script exits 1 (got $rc)" "$ok"
    local lines
    lines="$(wc -l < "$NOTIFY_LOG")"
    ok=1
    [[ $lines -eq 1 ]] && ok=0
    check "waybar hard-failure (walker rc=1): notify-send invoked exactly once (got $lines)" "$ok"
}

echo "test-walker-dmenu-cancel — walker exit-code branch checker"

case "${1:-both}" in
    theme-switch) run_theme_switch_suite ;;
    waybar) run_waybar_suite ;;
    both) run_theme_switch_suite; run_waybar_suite ;;
    *)
        echo "Usage: $(basename -- "$0") [theme-switch|waybar]" >&2
        exit 2
        ;;
esac

echo ""
echo "Summary: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
exit $?
