#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║          CONTAINER-RUN (D-52/D-54)                    ║
# ║  Keeper installer-regression harness. Rerunnable, like ║
# ║  theme-doctor. Reproduces install.sh --core-only +     ║
# ║  stow.sh + theme-parity from a real remote git clone   ║
# ║  inside a fresh archlinux/archlinux podman container.  ║
# ╚══════════════════════════════════════════════════════╝
#
# Usage: verify/container-run.sh
#
# What this proves (INST-03, container tier): the hardened installer
# (Phase 3 plans 03-01/03-02/03-03) reproduces the fully themed desktop's
# non-graphical prerequisites from scratch — a genuine `git clone` of the
# real remote (D-56, not a dev-machine re-stow), `install.sh --core-only`
# (pacman/AUR package installs + the hard-fail verify_packages table),
# `stow.sh` (idempotent symlinks + first-boot theme seed), and
# `theme-parity` (headless-safe render/output-contract gate).
#
# What this does NOT prove: theme-doctor's session-dependent checks
# (pgrep walker/elephant, gsettings, D-Bus) legitimately cannot pass in a
# headless container with no running Hyprland session — theme-doctor runs
# here informationally only (never gates this harness's exit code). The
# graphical VM procedure in VERIFICATION.md is the tier that proves those
# checks pass with a live session and a human's own eyes (D-53).
#
# Exit code: 0 only if clone + install.sh --core-only + stow.sh +
# theme-parity all succeed AND summary.log affirmatively records
# overall=PASS. Nonzero on any failure, a missing summary verdict, or a
# container-rc/summary mismatch. This is a hard gate (D-64 spirit) — no
# warn-and-continue path for the gating steps, and no verdict is trusted
# from the container exit code alone (see the false-pass post-mortem
# below).

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_URL="https://github.com/yahiaeng/dotfiles"
IMAGE="docker.io/archlinux/archlinux:latest"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="$SCRIPT_DIR/logs/run-${TIMESTAMP}"
SUMMARY_FILE="$LOG_DIR/summary.log"
CONTAINER_SCRIPT_FILE="$LOG_DIR/container-script.sh"
# A full run (pull + install.sh + stow.sh + theme-parity) is minutes,
# not an hour — anything past this budget means a step hung (Quick
# 260709-buf, T-buf-02). Env-overridable for slower hosts/CI.
CONTAINER_TIMEOUT="${CONTAINER_TIMEOUT:-3600}"

echo "╔══════════════════════════════════════════╗"
echo "║   container-run — installer regression   ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Require podman ────────────────────────────────────
if ! command -v podman &>/dev/null; then
    echo "container-run: podman not found." >&2
    echo "  Install it with: sudo pacman -S --needed podman" >&2
    exit 1
fi

mkdir -p "$LOG_DIR"
echo "Logs: $LOG_DIR"
echo "# container-run summary — $TIMESTAMP" > "$SUMMARY_FILE"

# ── Pull a fresh image every run (no stale cached layers) ─
echo ""
echo "Pulling $IMAGE ..."
if ! podman pull "$IMAGE" > "$LOG_DIR/00-pull.log" 2>&1; then
    echo "  [FAIL] podman pull $IMAGE (log: $LOG_DIR/00-pull.log)"
    echo "step=pull status=fail" >> "$SUMMARY_FILE"
    echo "overall=FAIL" >> "$SUMMARY_FILE"
    exit 1
fi
echo "  [OK] podman pull $IMAGE"
echo "step=pull status=ok" >> "$SUMMARY_FILE"

# ── Write the in-container script into the log dir ───────
# The script runs FROM A FILE over the existing /logs bind mount
# (`bash /logs/container-script.sh`), NOT over the container's stdin.
#
# Post-mortem (run-20260708T220706Z false pass): the first version fed
# this script to `bash -s` via a heredoc over stdin. When a step prompted
# interactively (pacman -Syu without --noconfirm asking "[Y/n]"), the
# prompt read its answer FROM THE REMAINING HEREDOC TEXT — draining
# bash's own unread script. Bash hit EOF mid-script right after setting
# GATE_FAIL=1, never reached `exit "$GATE_FAIL"`, and exited 0 (status of
# its last completed command) — so the outer harness printed PASS on a
# hard install failure. Running the script from a file makes that
# stdin-eating failure mode structurally impossible; `exec </dev/null`
# inside is belt-and-suspenders so no step can block on or consume stdin
# either way. The script file also doubles as preserved evidence of
# exactly what each run executed, alongside its logs.
#
# Trust boundary (T-03-04-NOPASS): the NOPASSWD sudoers drop-in created
# by this script exists ONLY inside the ephemeral, --rm'd container's
# filesystem at /etc/sudoers.d/. The generator text below lands in the
# gitignored verify/logs/ dir per run and is never a repo-tracked
# sudoers file; no NOPASSWD configuration ever persists on the host or
# beyond a single `podman run` invocation.
#
# The heredoc delimiter is quoted ('CONTAINER_SCRIPT') so none of it is
# expanded by the outer host shell — every $VAR below is resolved INSIDE
# the container, not on the host.
cat > "$CONTAINER_SCRIPT_FILE" <<'CONTAINER_SCRIPT'
#!/usr/bin/env bash
set -uo pipefail

# Belt-and-suspenders vs. the run-20260708T220706Z stdin-eating false
# pass: no step in this script may read from stdin. Any command that
# tries to prompt now gets immediate EOF and fails loudly instead of
# consuming input meant for something else.
exec </dev/null

REPO_URL="https://github.com/yahiaeng/dotfiles"
GATE_FAIL=0

log_step() {
    # log_step <name> <logfile> <cmd...>
    local name="$1" logfile="$2"
    shift 2
    echo ""
    echo "=== $name ==="
    if "$@" > "$logfile" 2>&1; then
        echo "  [OK] $name"
        return 0
    else
        local rc=$?
        echo "  [FAIL] $name (exit $rc)"
        tail -n 40 "$logfile" || true
        return "$rc"
    fi
}

# ── Bootstrap: git + base-devel + sudo (needed for makepkg/paru, which
#    refuse to run as root) ────────────────────────────────────────────
if log_step "bootstrap (pacman -Sy git base-devel sudo)" /logs/01-bootstrap.log \
    pacman -Sy --noconfirm --needed git base-devel sudo; then
    echo "step=bootstrap status=ok" >> /logs/summary.log
else
    echo "step=bootstrap status=fail" >> /logs/summary.log
    GATE_FAIL=1
fi

# ── Non-root build user with an ephemeral, container-scoped NOPASSWD
#    sudoers drop-in (T-03-04-NOPASS: generated here, at runtime, inside
#    this disposable container only — never committed to the repo,
#    never active on any persistent machine). ───────────────────────────
if [[ "$GATE_FAIL" -eq 0 ]]; then
    useradd -m builder
    echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder-nopasswd
    chmod 440 /etc/sudoers.d/builder-nopasswd
fi

# ── Real `git clone` from the remote (D-56) — the true fresh-machine
#    story; a stray untracked file on the dev machine would not appear
#    here. ───────────────────────────────────────────────────────────────
if [[ "$GATE_FAIL" -eq 0 ]]; then
    if log_step "git clone (real remote, D-56)" /logs/02-clone.log \
        su - builder -c "git clone --depth 1 '$REPO_URL' ~/dotfiles"; then
        echo "step=clone status=ok" >> /logs/summary.log
    else
        echo "step=clone status=fail" >> /logs/summary.log
        GATE_FAIL=1
    fi
fi

# ── install.sh --core-only: pacman/AUR package installs + the hard-fail
#    verify_packages table (D-63/D-64/D-65) ─────────────────────────────
if [[ "$GATE_FAIL" -eq 0 ]]; then
    if log_step "install.sh --core-only" /logs/03-install.log \
        su - builder -c "cd ~/dotfiles && chmod +x install.sh stow.sh && ./install.sh --core-only"; then
        echo "step=install status=ok" >> /logs/summary.log
    else
        echo "step=install status=fail" >> /logs/summary.log
        GATE_FAIL=1
    fi
fi

# ── stow.sh: idempotent symlinks + first-boot theme seed (D-60/D-62) ────
if [[ "$GATE_FAIL" -eq 0 ]]; then
    if log_step "stow.sh" /logs/04-stow.log \
        su - builder -c "cd ~/dotfiles && ./stow.sh"; then
        echo "step=stow status=ok" >> /logs/summary.log
    else
        echo "step=stow status=fail" >> /logs/summary.log
        GATE_FAIL=1
    fi
fi

# ── theme-doctor: informational only. Its session-dependent checks
#    (pgrep walker/elephant, gsettings, D-Bus bus names) legitimately
#    cannot pass headless with no running Hyprland session — that
#    evidence is the graphical VM gate's job (VERIFICATION.md). Captured
#    for inspection; never gates this harness's exit code. ──────────────
if [[ "$GATE_FAIL" -eq 0 ]]; then
    su - builder -c 'cd ~/dotfiles && $HOME/.config/theme-engine/theme-doctor' \
        > /logs/05-theme-doctor.log 2>&1
    echo "step=theme-doctor status=informational rc=$?" >> /logs/summary.log
    echo ""
    echo "=== theme-doctor (informational, does not gate) ==="
    tail -n 5 /logs/05-theme-doctor.log || true
fi

# ── theme-parity: the primary headless-safe health gate (render-only,
#    output-contract parity across all 7 targets — no live session
#    needed). Hard-gates this harness's exit code. ──────────────────────
if [[ "$GATE_FAIL" -eq 0 ]]; then
    if log_step "theme-parity" /logs/06-theme-parity.log \
        su - builder -c '$HOME/.config/theme-engine/theme-parity'; then
        echo "step=theme-parity status=ok" >> /logs/summary.log
    else
        echo "step=theme-parity status=fail" >> /logs/summary.log
        GATE_FAIL=1
    fi
fi

echo ""
if [[ "$GATE_FAIL" -eq 0 ]]; then
    echo "overall=PASS" >> /logs/summary.log
    echo "container-run (in-container): PASS"
else
    echo "overall=FAIL" >> /logs/summary.log
    echo "container-run (in-container): FAIL"
fi

exit "$GATE_FAIL"
CONTAINER_SCRIPT
chmod +x "$CONTAINER_SCRIPT_FILE"

# ── Run the whole regression inside one fresh container ──
# No -i / no stdin feed: the script executes from the /logs mount (see
# the post-mortem note above the heredoc).
#
# Chosen approach (Quick 260709-buf, T-buf-02): an outer `timeout`
# around the single `podman run` — rather than per-step timeouts inside
# the heredoc — is the simplest correct change and catches ALL hangs
# (including future ones not yet anticipated), not only the swaync one
# fixed separately in reload.sh. SIGTERM at the budget, SIGKILL 30s
# later if podman doesn't stop. `timeout` exits 124 on expiry, which
# flows into IN_CONTAINER_RC exactly like any other nonzero rc.
if timeout --kill-after=30 "$CONTAINER_TIMEOUT" podman run --rm \
    -v "$LOG_DIR:/logs:Z" \
    "$IMAGE" bash /logs/container-script.sh; then
    IN_CONTAINER_RC=0
else
    IN_CONTAINER_RC=$?
fi

# Detect a timeout (124: SIGTERM expiry; 137: SIGKILL fallthrough after
# --kill-after) so the verdict logic below can record it explicitly.
CONTAINER_TIMED_OUT=0
if [[ "$IN_CONTAINER_RC" -eq 124 || "$IN_CONTAINER_RC" -eq 137 ]]; then
    CONTAINER_TIMED_OUT=1
    echo "step=container-run status=timeout after=${CONTAINER_TIMEOUT}s" >> "$SUMMARY_FILE"
fi

# ── Verdict: never trust the container exit code alone ───
# Post-mortem (run-20260708T220706Z): an inner-script early death can
# yield rc 0 without the script ever reaching its own verdict line. PASS
# therefore requires BOTH (a) container rc == 0 AND (b) summary.log
# affirmatively containing overall=PASS. Anything else — missing summary,
# missing overall= line, overall=FAIL, or an rc/summary mismatch — is a
# FAIL with an explicit reason. The outer script also appends
# overall=FAIL itself whenever the inner verdict line is absent, so the
# machine-readable log is never ambiguous.
FAIL_REASON=""
if [[ "$CONTAINER_TIMED_OUT" -eq 1 ]]; then
    grep -q '^overall=' "$SUMMARY_FILE" 2>/dev/null || echo "overall=FAIL" >> "$SUMMARY_FILE"
    FAIL_REASON="container run exceeded ${CONTAINER_TIMEOUT}s and was killed (timeout) — check the last-running step's log in $LOG_DIR/"
elif [[ ! -f "$SUMMARY_FILE" ]]; then
    FAIL_REASON="summary.log missing — container never wrote its log"
elif ! grep -q '^overall=' "$SUMMARY_FILE"; then
    echo "overall=FAIL" >> "$SUMMARY_FILE"
    FAIL_REASON="summary.log had no overall= verdict — container script died before finishing"
elif ! grep -qx 'overall=PASS' "$SUMMARY_FILE"; then
    FAIL_REASON="summary.log records overall=FAIL"
elif [[ "$IN_CONTAINER_RC" -ne 0 ]]; then
    FAIL_REASON="container exited nonzero ($IN_CONTAINER_RC) despite overall=PASS in summary.log"
fi

echo ""
echo "╔══════════════════════════════════════════╗"
if [[ -z "$FAIL_REASON" ]]; then
    echo "║   container-run: PASS                    ║"
else
    echo "║   container-run: FAIL                    ║"
fi
echo "╚══════════════════════════════════════════╝"
if [[ -n "$FAIL_REASON" ]]; then
    echo "Reason: $FAIL_REASON"
fi
echo ""
echo "Machine-readable summary: $SUMMARY_FILE"
echo "Per-step logs: $LOG_DIR/"
[[ -f "$SUMMARY_FILE" ]] && cat "$SUMMARY_FILE"

if [[ -n "$FAIL_REASON" ]]; then
    exit 1
fi
exit 0
