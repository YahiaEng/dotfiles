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
# Budget, from measured evidence (D-22-07 Defect 2 repair): the
# run-20260816T191755Z baseline hit the prior 3600s budget with genuine
# forward progress remaining — `podman top` showed paru still mid-batch
# through a cold-cache, no-shared-AUR-cache 31-entry AUR_PKGS list,
# having reached roughly package #14 (vscodium-bin) by the time it was
# inspected ~63-65 minutes in (a few minutes after the host's own 3600s
# timeout had already fired). That is ~14 packages in ~64 minutes, or
# ~4.6 min/package including bootstrap+clone overhead. Task 1 (this same
# plan) removes 2 packages (limine-dracut-support, kernel-modules-hook —
# the ones whose Gradle build was failing) from the container-gate set,
# leaving 29. At the same per-package rate: 29 * 4.6min ≈ 133min ≈
# 7980s for the AUR-install phase alone, plus stow.sh + theme-parity
# (both minutes, not hours, per this script's own header comment) and a
# 30% safety margin for a colder cache / slower mirror than the baseline
# drew: 7980s * 1.3 ≈ 10374s ≈ 10400s. Env-overridable for slower
# hosts/CI or a re-measurement once this repaired harness has its own
# evidence.
CONTAINER_TIMEOUT="${CONTAINER_TIMEOUT:-10400}"

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
# by this script exists ONLY inside the ephemeral container's filesystem
# at /etc/sudoers.d/. The container is started WITHOUT --rm (D-22-07
# Defect 1 repair, below — the harness needs to inspect its exit code
# after a bounded wait) and is instead removed explicitly by a `trap ...
# EXIT INT TERM` cleanup on every exit path. The generator text below
# lands in the gitignored verify/logs/ dir per run and is never a
# repo-tracked sudoers file; no NOPASSWD configuration ever persists on
# the host or beyond a single container's lifetime.
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

# ── Run the whole regression inside one fresh, detached container ──
# No -i / no stdin feed: the script executes from the /logs mount (see
# the post-mortem note above the heredoc).
#
# D-22-07 Defect 1 repair (supersedes the prior attached-and-hope
# approach): baseline run-20260816T191755Z measured, via live `podman
# ps -a` / `podman top` / `podman inspect`, that SIGKILLing an attached
# `podman run` client only detaches the CLI — under rootless podman the
# conmon-owned container keeps running unsupervised (container
# 197980ef926b was confirmed still `running=true`, with `paru` still
# building AUR packages, several minutes after the host script had
# already exited with its own FAIL verdict). The prior comment here
# claimed the outer `timeout` "catches ALL hangs" — that claim is FALSE
# for the containerized workload; it only ever bounded the host-side
# wrapper's own exit. This repair starts the container detached with a
# harness-known identity (`--cidfile`), waits on that identity with a
# bounded `podman wait`, and on budget expiry actively stops the
# container and CONFIRMS via `podman inspect` that it is no longer
# running before the harness does anything else — a stop that is issued
# but not confirmed would reproduce the original defect in a new
# costume.
CID_FILE="$LOG_DIR/container.cid"
rm -f "$CID_FILE"

# Cleanup on every exit path — normal completion, timeout, or this
# script being interrupted. `--rm` was deliberately dropped from the run
# itself (kept on `podman run` it would race the harness's own post-exit
# inspection of the container's state/exit code); removal is instead
# explicit and unconditional here, so cleanup stays deterministic
# regardless of how this script exits. `podman rm -f` operates on the
# container directly (it does not depend on the backgrounded `timeout
# podman wait` pair below having stopped); that background job is also
# best-effort killed here so nothing is left watching a container that
# no longer exists.
# shellcheck disable=SC2329  # invoked indirectly via `trap` below, not called directly
cleanup_container() {
    [[ -n "${WAIT_PID:-}" ]] && kill "$WAIT_PID" &>/dev/null || true
    [[ -f "$CID_FILE" ]] || return 0
    local cid
    cid="$(cat "$CID_FILE" 2>/dev/null)" || return 0
    [[ -n "$cid" ]] || return 0
    podman rm -f "$cid" &>/dev/null || true
}
trap cleanup_container EXIT INT TERM

if ! podman run -d --cidfile="$CID_FILE" \
    -v "$LOG_DIR:/logs:Z" \
    "$IMAGE" bash /logs/container-script.sh > "$LOG_DIR/container-start.log" 2>&1; then
    echo "  [FAIL] podman run -d (log: $LOG_DIR/container-start.log)"
    echo "step=container-run status=fail" >> "$SUMMARY_FILE"
    echo "overall=FAIL" >> "$SUMMARY_FILE"
    exit 1
fi
CID="$(cat "$CID_FILE")"

# Bounded wait, not a sleep-loop assumption of rate: `podman wait`
# blocks until the container exits and prints its exit code on stdout.
# The outer `timeout` is what distinguishes "exited on its own" (podman
# wait returns 0, its stdout is the container's own exit code) from "we
# hit the budget" (the `timeout` wrapper around `podman wait` itself
# returns 124/137 — that is the WAIT expiring, not a signal reaching the
# container, which is exactly the distinction the prior mechanism could
# not make).
#
# Run it as a BACKGROUND job and block on bash's own `wait` builtin
# rather than on `timeout ... podman wait ...` synchronously in the
# foreground — verified live (throwaway container, SIGINT): GNU
# `timeout` isolates its child into a NEW process group by default (its
# own `--foreground` flag documents this — it exists specifically to
# opt OUT of that isolation), so a signal delivered to this script's own
# process group never reaches the `podman wait` child at all. Bash
# additionally defers running a trap for a signal received while blocked
# on a synchronous foreground external command until that command
# exits. Combined, interrupting the prior synchronous form left the
# cleanup trap unexecuted until the full budget elapsed — the very
# defect class this repair exists to close, reproduced in a new costume.
# Bash's `wait` builtin, by contrast, returns immediately when a trapped
# signal arrives, so the trap runs promptly regardless of what the
# backgrounded `timeout`/`podman wait` pair is still doing — cleanup
# does not depend on stopping that pair, only on `podman rm -f "$CID"`
# in the trap, which operates on the container directly.
timeout "$CONTAINER_TIMEOUT" podman wait "$CID" >"$LOG_DIR/container-wait.log" 2>&1 &
WAIT_PID=$!
wait "$WAIT_PID"
WAIT_RC=$?

CONTAINER_TIMED_OUT=0
if [[ "$WAIT_RC" -eq 0 ]]; then
    IN_CONTAINER_RC="$(tail -n1 "$LOG_DIR/container-wait.log" 2>/dev/null)"
else
    if [[ "$WAIT_RC" -eq 124 || "$WAIT_RC" -eq 137 ]]; then
        CONTAINER_TIMED_OUT=1
    fi
    # Budget expired (or `podman wait` itself errored, or this script was
    # interrupted) — actively stop, escalate, and verify. This is the
    # whole point of the repair.
    podman stop --time=30 "$CID" &>/dev/null || true
    if [[ "$(podman inspect -f '{{.State.Running}}' "$CID" 2>/dev/null)" == "true" ]]; then
        podman kill "$CID" &>/dev/null || true
    fi
    # `podman kill` is async — re-inspect on a short bounded poll rather
    # than assuming the signal already landed, and confirm stopped
    # before the harness writes any verdict.
    STOPPED_CONFIRMED=0
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        if [[ "$(podman inspect -f '{{.State.Running}}' "$CID" 2>/dev/null)" != "true" ]]; then
            STOPPED_CONFIRMED=1
            break
        fi
        sleep 1
    done
    if [[ "$STOPPED_CONFIRMED" -eq 0 ]]; then
        echo "container-run: FATAL — container $CID still running after stop+kill+10s verification (repair of D-22-07 Defect 1 itself failed to stop it)" >&2
        IN_CONTAINER_RC=137
    else
        # Preserve the existing exit-code contract (124/137 for timeout)
        # for downstream logic even though the mechanism producing it has
        # changed.
        IN_CONTAINER_RC="$(podman inspect -f '{{.State.ExitCode}}' "$CID" 2>/dev/null || echo 137)"
        [[ "$CONTAINER_TIMED_OUT" -eq 1 ]] && IN_CONTAINER_RC=124
    fi
fi

if [[ "$CONTAINER_TIMED_OUT" -eq 1 ]]; then
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
#
# D-22-07 Defect 2 repair: the double `overall=` line in
# run-20260816T191755Z was the observable signature of the container
# outliving this verdict logic — a still-running container wrote its own
# late verdict into the same file, after the host had already read and
# appended its own. Because the container is now confirmed stopped
# (above) BEFORE this block runs, that late-write race is closed at the
# source: nothing can append to summary.log after this point. The
# `grep -q` below is still guarded defensively — on the (now believed
# unreachable) chance an `overall=` line is already present, the
# conflict is recorded explicitly rather than silently appending a
# duplicate.
FAIL_REASON=""
if [[ "$CONTAINER_TIMED_OUT" -eq 1 ]]; then
    if grep -q '^overall=' "$SUMMARY_FILE" 2>/dev/null; then
        echo "overall-conflict=timeout-after-inner-verdict-already-present" >> "$SUMMARY_FILE"
    else
        echo "overall=FAIL" >> "$SUMMARY_FILE"
    fi
    FAIL_REASON="container run exceeded ${CONTAINER_TIMEOUT}s and was stopped+verified-not-running (timeout) — check the last-running step's log in $LOG_DIR/"
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
