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
# theme-parity all succeed. Nonzero on any of those four failing. This is
# a hard gate (D-64 spirit) — no warn-and-continue path for the four
# gating steps.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_URL="https://github.com/yahiaeng/dotfiles"
IMAGE="docker.io/archlinux/archlinux:latest"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="$SCRIPT_DIR/logs/run-${TIMESTAMP}"
SUMMARY_FILE="$LOG_DIR/summary.log"

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

# ── Run the whole regression inside one fresh container ──
# The entire clone -> install -> stow -> verify sequence runs as a single
# heredoc script piped to `bash -s` inside the container over stdin (no
# host temp file, no fragile -c quoting). The heredoc delimiter is quoted
# ('CONTAINER_SCRIPT') so none of it is expanded by the outer host shell —
# every $VAR below is resolved INSIDE the container, not on the host.
#
# Trust boundary (T-03-04-NOPASS): the NOPASSWD sudoers drop-in created
# below exists ONLY inside this ephemeral, --rm'd container's filesystem.
# It is never written to any repo-tracked file and never persists past
# this single `podman run` invocation.
if podman run --rm -i \
    -v "$LOG_DIR:/logs:Z" \
    "$IMAGE" bash -s <<'CONTAINER_SCRIPT'
set -uo pipefail

REPO_URL="https://github.com/yahiaeng/dotfiles"
GATE_FAIL=0

log_step() {
    # log_step <name> <logfile> -- <cmd...>
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
#    never written to any host path). ───────────────────────────────────
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
then
    IN_CONTAINER_RC=0
else
    IN_CONTAINER_RC=$?
fi

echo ""
echo "╔══════════════════════════════════════════╗"
if [[ "$IN_CONTAINER_RC" -eq 0 ]]; then
    echo "║   container-run: PASS                    ║"
else
    echo "║   container-run: FAIL                    ║"
fi
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Machine-readable summary: $SUMMARY_FILE"
echo "Per-step logs: $LOG_DIR/"
[[ -f "$SUMMARY_FILE" ]] && cat "$SUMMARY_FILE"

exit "$IN_CONTAINER_RC"
