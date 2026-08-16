#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║          CONTAINER-RUN (D-52/D-54)                    ║
# ║  Keeper installer-regression harness. Rerunnable, like ║
# ║  theme-doctor. Reproduces install.sh --core-only +     ║
# ║  stow.sh + theme-parity from a real remote git clone   ║
# ║  inside a fresh archlinux/archlinux podman container.  ║
# ╚══════════════════════════════════════════════════════╝
#
# Usage: verify/container-run.sh [--cold]
#
#   --cold   Mount no host package caches at all — reproduces the original
#            from-scratch behaviour byte-for-byte (22-09 perf). Use this to
#            keep the cold-cache build path exercisable so a stale cache can
#            never permanently hide a broken PKGBUILD. Without this flag,
#            the run mounts the host's real pacman/paru caches READ-ONLY
#            (source: 23 GB / 8.4 GB of real, hard-to-rebuild dev-machine
#            state — see the cache-mount block below) plus a persistent,
#            gitignored, container-writable pair under verify/cache/ for
#            anything the run downloads or clones that was not already
#            cached. Every run logs which mode it used and which paths were
#            mounted (`cache-mode=`/`cache-*=` lines in summary.log), so a
#            fast cached run is never later mistaken for a full cold proof.
#
# What this proves (INST-03, container tier): the hardened installer
# (Phase 3 plans 03-01/03-02/03-03) reproduces the fully themed desktop's
# non-graphical prerequisites from scratch — a genuine `git clone` of the
# real remote (D-56, not a dev-machine re-stow), `install.sh --core-only`
# (pacman/AUR package installs + the hard-fail verify_packages table),
# `stow.sh` (idempotent symlinks + first-boot theme seed), a blocking
# `retirement-check --all` run INSIDE the container (D-22-05 — its
# host-package class asserts against the REPRODUCED system, not the dev
# host, which still has old packages installed), a blocking
# `stow-link-check` dangling-symlink sweep over the freshly-stowed tree
# (D-22-06), `theme-doctor` (D-22-08, BLOCKING against the committed
# allowlist at verify/theme-doctor-session-allowlist.txt — see below),
# and `theme-parity` (headless-safe render/output-contract gate).
#
# What this does NOT prove: theme-doctor's three genuinely
# session-dependent checks (gsettings gtk-theme, walker process running,
# elephant process running) legitimately cannot pass in a headless
# container with no running Hyprland session and no D-Bus session bus —
# each is admitted by a source-justified entry in
# verify/theme-doctor-session-allowlist.txt (D-22-09/10), a committed,
# byte-exact-matched allowlist, never fitted to whatever happened to go
# red. Every OTHER theme-doctor failure — roughly 575 headless-safe file
# and lint checks — now blocks this harness's exit code, for the first
# time. The graphical VM procedure in VERIFICATION.md remains the tier
# that proves the three allowlisted checks pass with a live session and a
# human's own eyes (D-53).
#
# Exit code: 0 only if clone + install.sh --core-only + stow.sh +
# retirement-check --all + stow-link-check + theme-doctor (against the
# allowlist) + theme-parity all succeed AND summary.log affirmatively
# records overall=PASS. Nonzero on any failure, a missing summary
# verdict, or a container-rc/summary mismatch. This is a hard gate (D-64
# spirit) — no warn-and-continue path for the gating steps, and no
# verdict is trusted from the container exit code alone (see the
# false-pass post-mortem below).

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# ── Argument parsing (22-09 perf) ─────────────────────────
# Only one flag exists. Anything else is a hard error rather than a
# silently-ignored typo.
COLD_RUN=0
for arg in "$@"; do
    case "$arg" in
        --cold)
            COLD_RUN=1
            ;;
        -h | --help)
            sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "container-run: unknown argument: $arg (see --help)" >&2
            exit 1
            ;;
    esac
done

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

# ── Host cache resolution (22-09 perf) ────────────────────
# Resolved rather than hardcoded where a standard tool exists. pacman-conf
# reads the real, possibly-customized CacheDir from /etc/pacman.conf;
# XDG_CACHE_HOME is the standard override point for paru's own cache root
# (paru has no equivalent introspection command).
PACMAN_CACHE_HOST="$(pacman-conf CacheDir 2>/dev/null | head -n1)"
PACMAN_CACHE_HOST="${PACMAN_CACHE_HOST:-/var/cache/pacman/pkg}"
PARU_CACHE_HOST="${XDG_CACHE_HOME:-$HOME/.cache}/paru"

# Writable, PERSISTENT (survives across runs — the point of "reuse"),
# gitignored container-scoped cache pair. Never the same path as the host
# caches above: pacman/paru write new downloads/clones here, the host
# caches above are mounted read-only and are never a write target.
#
# Cleanup note: the container script chowns these to its own `builder`
# user (a subordinate-range uid under rootless podman, proven live —
# without the chown, `builder` gets "Permission denied" writing here at
# all). A later plain `rm -rf verify/cache/` as the host user will
# therefore fail partway through; use `podman unshare rm -rf
# verify/cache/` (proven live to work) or sudo. This has no bearing on
# T-22-09-DESTRUCT — that threat is about the READ-ONLY host caches
# below, which no in-container process, chowned or not, can write to.
CONTAINER_CACHE_DIR="$SCRIPT_DIR/cache"
PACMAN_CACHE_WRITE="$CONTAINER_CACHE_DIR/pacman-write"
PARU_CACHE_WRITE="$CONTAINER_CACHE_DIR/paru-write"

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

# ── Cache mount plan (22-09 perf) ─────────────────────────
# Built once, used both for the podman invocation below and for the
# summary.log record — evidence read months later must never leave a
# reader guessing whether a fast run was a real from-scratch proof.
CACHE_MOUNT_ARGS=()
if [[ "$COLD_RUN" -eq 1 ]]; then
    CACHE_MODE="cold"
else
    CACHE_MODE="warm"
    mkdir -p "$PACMAN_CACHE_WRITE" "$PARU_CACHE_WRITE"
    # T-22-09-DESTRUCT: host caches are `:ro`. Writes go only to the
    # separate, container-scoped directories created above.
    CACHE_MOUNT_ARGS+=(
        -v "$PACMAN_CACHE_HOST:/caches/pacman-ro:ro,Z"
        -v "$PARU_CACHE_HOST:/caches/paru-ro:ro,Z"
        -v "$PACMAN_CACHE_WRITE:/caches/pacman-write:Z"
        -v "$PARU_CACHE_WRITE:/caches/paru-write:Z"
    )
fi

mkdir -p "$LOG_DIR"
echo "Logs: $LOG_DIR"
{
    echo "# container-run summary — $TIMESTAMP"
    echo "cache-mode=$CACHE_MODE"
    if [[ "$CACHE_MODE" == "warm" ]]; then
        echo "cache-pacman-ro=$PACMAN_CACHE_HOST"
        echo "cache-paru-ro=$PARU_CACHE_HOST"
        echo "cache-pacman-write=$PACMAN_CACHE_WRITE"
        echo "cache-paru-write=$PARU_CACHE_WRITE"
    fi
} > "$SUMMARY_FILE"
echo "Cache mode: $CACHE_MODE"

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

# D-22-04 Task 2: the allowlist-matching logic below (theme-doctor step)
# must be byte-exact and prefix-anchored — no case folding, no Unicode
# normalisation, no whitespace collapsing. Setting LC_ALL=C here, once,
# for the whole in-container script guarantees every subsequent bash
# string slice/compare (`${var:0:n}`, `[[ == ]]`) operates on bytes, not
# locale-dependent characters, without scattering the assignment.
export LC_ALL=C

REPO_URL="https://github.com/yahiaeng/dotfiles"
GATE_FAIL=0
# D-22-04 Task 2: explicit in-container clone path. The clone lands in the
# `builder` user's home (see the `git clone` step below), but THIS script
# itself runs as root — a bare $HOME here resolves to /root, not
# /home/builder. Every existing step that needs the clone reaches it
# through `su - builder -c`; the two new blocking steps below (and the
# theme-doctor allowlist read) need to read repository files directly
# from this root-level script, so the path is named explicitly here
# rather than assumed from $HOME.
CLONE_DIR="/home/builder/dotfiles"

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

# ── Host cache reuse, pacman half (22-09 perf) ────────────────────────
# Self-detecting on the mount's actual presence, not on an expanded host
# variable — this heredoc is intentionally single-quoted (see the note
# above it), so every $VAR here resolves INSIDE the container. Must run
# BEFORE the bootstrap `pacman -Sy` below so the very first sync already
# consults the read-only host mirror. pacman.conf's CacheDir directive is
# consulted in the order listed and pacman downloads to the first entry
# it can write to (pacman.conf(5)) — listing the read-only host mirror
# first means anything the developer's own machine already built or
# downloaded is found there and never re-fetched; anything new lands in
# the second, writable, host-persisted directory, which never touches
# the read-only mount (T-22-09-DESTRUCT).
if [[ -d /caches/pacman-ro && -d /caches/pacman-write ]]; then
    printf 'CacheDir = /caches/pacman-ro/\nCacheDir = /caches/pacman-write/\n' >> /etc/pacman.conf
fi

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
    # 22-09 perf: the writable cache mounts are host directories owned by
    # the container's mapped root (== the host user under rootless
    # podman); `builder` maps to a different, subordinate-range uid and
    # has no write access to them by default — proven live (throwaway
    # container) to fail `mkdir` with "Permission denied" before this
    # chown. Root can always write regardless of ownership, so this only
    # matters for paru's builder-run clones, but pacman-write is chowned
    # too for consistent, non-root-owned host-side artifacts.
    [[ -d /caches/pacman-write ]] && chown -R builder:builder /caches/pacman-write
    [[ -d /caches/paru-write ]] && chown -R builder:builder /caches/paru-write
fi

# ── Host cache reuse, paru half (22-09 perf) ──────────────────────────
# paru has no pacman-style multi-directory CacheDir; its reusable state
# (cloned AUR PKGBUILD trees under .../paru/clone) lives at a single
# directory a -git package's pkgver() must be free to update via `git
# pull`, so it cannot be the read-only mount itself. Best-effort,
# skip-what-already-exists seed (`cp -an`, GNU coreutils, no rsync
# dependency) copies the developer's real clone cache into the writable,
# host-persisted directory once per run; paru is then pointed at that
# writable directory for the rest of the run via XDG_CACHE_HOME (below,
# at the install.sh invocation). A seed failure is NOT fatal — caching
# is an optimization, not a correctness requirement of this gate.
if [[ "$GATE_FAIL" -eq 0 && -d /caches/paru-ro && -d /caches/paru-write ]]; then
    su - builder -c "mkdir -p /caches/paru-write/clone && cp -an /caches/paru-ro/clone/. /caches/paru-write/clone/ 2>/dev/null; exit 0" \
        > /logs/01b-paru-cache-seed.log 2>&1
    echo "step=paru-cache-seed status=attempted rc=$?" >> /logs/summary.log
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
# XDG_CACHE_HOME repoints paru's own cache root at the writable,
# host-persisted directory (seeded above) only when cache reuse is
# active; under --cold (or if the mount is simply absent) builder falls
# through to its normal ~/.cache, exactly today's from-scratch behaviour.
if [[ "$GATE_FAIL" -eq 0 ]]; then
    PARU_CACHE_ENV=""
    if [[ -d /caches/paru-write ]]; then
        PARU_CACHE_ENV="export XDG_CACHE_HOME=/caches/paru-write; "
    fi
    if log_step "install.sh --core-only" /logs/03-install.log \
        su - builder -c "${PARU_CACHE_ENV}cd ~/dotfiles && chmod +x install.sh stow.sh && ./install.sh --core-only"; then
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

# ── retirement-check --all: BLOCKING, INSIDE the container (D-22-05) ────
# retirement-check's host-package class runs `pacman -Q <surface>` against
# the machine it executes on — running it here asserts against the
# REPRODUCED system, precisely what SC-2 asks for and what the developer
# host cannot answer (the dev host still has the old packages installed).
# Its other 13 classes run against the freshly-cloned, freshly-stowed
# tree. Invoked through the STOWED path (not the clone path) via
# `su - builder -c` so $HOME resolves to the builder's home and
# retirement-check's own DOTFILES_DIR default ($HOME/dotfiles) resolves
# to the real clone. Log numbered 04a- (not renumbering 05/06) so
# historical run directories stay comparable.
if [[ "$GATE_FAIL" -eq 0 ]]; then
    if log_step "retirement-check --all" /logs/04a-retirement-check.log \
        su - builder -c '$HOME/.config/hypr/scripts/retirement-check --all'; then
        echo "step=retirement-check status=ok" >> /logs/summary.log
    else
        echo "step=retirement-check status=fail" >> /logs/summary.log
        GATE_FAIL=1
    fi
fi

# ── stow-link-check: BLOCKING dangling-symlink sweep (D-22-06) ──────────
# Closes SC-2's symlink clause on the REPRODUCED system, not the dev
# host — sweeps the builder's freshly-stowed $HOME (no argument = real
# deployed targets). Log numbered 04b- for the same reason as above.
if [[ "$GATE_FAIL" -eq 0 ]]; then
    if log_step "stow-link-check" /logs/04b-stow-link-check.log \
        su - builder -c '$HOME/.config/hypr/scripts/stow-link-check'; then
        echo "step=stow-link-check status=ok" >> /logs/summary.log
    else
        echo "step=stow-link-check status=fail" >> /logs/summary.log
        GATE_FAIL=1
    fi
fi

# ── theme-doctor: BLOCKING against a committed allowlist (D-22-08). ─────
# Every [FAIL] theme-doctor reports (roughly 578 checks, the overwhelming
# majority file/lint checks that pass fine headless) now gates this
# harness's exit code UNLESS it is admitted by an entry in the committed
# allowlist (verify/theme-doctor-session-allowlist.txt) — a byte-exact,
# prefix-anchored match under LC_ALL=C (set once, at the top of this
# script), never a glob or regex. A missing, unreadable or malformed
# allowlist FAILS CLOSED (T-22-04-FAILOPEN): this step never silently
# degrades back to the old informational behaviour. The graphical VM gate
# (VERIFICATION.md) remains the tier that proves every one of these
# checks passes with a live session and a human's own eyes (D-53) — this
# step only proves the ~575 headless-safe checks pass, plus that the
# admitted session-dependent failures are exactly the three named ones
# and nothing new.
if [[ "$GATE_FAIL" -eq 0 ]]; then
    su - builder -c 'cd ~/dotfiles && $HOME/.config/theme-engine/theme-doctor' \
        > /logs/05-theme-doctor.log 2>&1
    TD_RC=$?

    ALLOWLIST_FILE="$CLONE_DIR/verify/theme-doctor-session-allowlist.txt"
    TD_STEP_OK=1
    TD_FAIL_REASON=""

    # CR-02 fix: theme-doctor's own contract is exit 0 (every check passed)
    # or exit 1 (some [FAIL] present, which the allowlist scan below then
    # adjudicates) — those are the only two legitimate outcomes. TD_RC was
    # previously captured only for the human-readable log line below and
    # never gated on: if theme-doctor never ran at all (missing binary,
    # `su - builder -c` itself failing, an early `source` failure), the log
    # is empty, the allowlist scan below finds zero [FAIL] lines, and the
    # step silently reported status=ok allowed=0 blocking=0 — a false PASS
    # indistinguishable from "everything genuinely passed."
    if [[ "$TD_RC" -ne 0 && "$TD_RC" -ne 1 ]]; then
        TD_STEP_OK=0
        TD_FAIL_REASON="theme-doctor exited $TD_RC (expected 0 or 1) — it did not run to completion"
    fi

    # CR-02 fix, second half: a 0/1 exit code alone is still not proof
    # theme-doctor ran to completion (the same "never trust the exit code
    # alone" discipline this script already applies to its own
    # summary.log verdict later in this file). Require the log to
    # affirmatively contain theme-doctor's own final tally line before
    # trusting the allowlist scan below — a plausible-but-empty or
    # truncated log must not be treated as success. Guarded so it never
    # overwrites a more specific reason already set above.
    if [[ "$TD_STEP_OK" -eq 1 ]] && ! grep -qE '^Summary: [0-9]+ passed, [0-9]+ failed$' /logs/05-theme-doctor.log; then
        TD_STEP_OK=0
        TD_FAIL_REASON="theme-doctor's log never reached its own 'Summary: N passed, M failed' line — it did not run to completion"
    fi

    if [[ "$TD_STEP_OK" -eq 1 && ! -r "$ALLOWLIST_FILE" ]]; then
        TD_STEP_OK=0
        TD_FAIL_REASON="allowlist file missing or unreadable at $ALLOWLIST_FILE"
    fi

    declare -a AL_PREFIX=() AL_CLASS=() AL_SRC=() AL_REASON=() AL_MATCHED=()
    if [[ "$TD_STEP_OK" -eq 1 ]]; then
        _al_lineno=0
        while IFS= read -r _al_raw || [[ -n "$_al_raw" ]]; do
            _al_lineno=$((_al_lineno + 1))
            [[ -z "$_al_raw" ]] && continue
            [[ "$_al_raw" =~ ^[[:space:]]*# ]] && continue
            [[ "$_al_raw" =~ ^[[:space:]]*$ ]] && continue

            # WR-02 fix: count only the delimiters BEFORE the reason column
            # begins (the first 3 pipes), not every `|` byte in the raw
            # line. The header documents `reason` as free-text prose with
            # no restriction against containing a literal `|` — the prior
            # exact-4 count treated any such pipe as an extra field and
            # hard-failed the whole gate on legitimate data. `read` with
            # fewer target vars than delimited fields already absorbs
            # everything past the 3rd delimiter into the last var verbatim
            # (including any further `|` bytes), so "at least 4 fields" is
            # the correct check — a record with FEWER than 4 (missing a
            # required column) is still rejected below.
            _al_nf=$(($(printf '%s' "$_al_raw" | tr -cd '|' | wc -c) + 1))
            if [[ "$_al_nf" -lt 4 ]]; then
                TD_STEP_OK=0
                TD_FAIL_REASON="malformed allowlist record at line $_al_lineno (expected at least 4 pipe-delimited fields, got $_al_nf): $_al_raw"
                break
            fi

            IFS='|' read -r _al_p _al_c _al_s _al_r <<< "$_al_raw"

            if [[ -z "$_al_p" || "${#_al_p}" -lt 12 ]]; then
                TD_STEP_OK=0
                TD_FAIL_REASON="malformed allowlist record at line $_al_lineno (match_prefix empty or under 12 bytes): $_al_raw"
                break
            fi
            case "$_al_c" in
                no-session-bus | no-compositor | no-display | no-user-session) ;;
                *)
                    TD_STEP_OK=0
                    TD_FAIL_REASON="malformed allowlist record at line $_al_lineno (bad reason_class '$_al_c'): $_al_raw"
                    break
                    ;;
            esac
            if [[ -z "$_al_s" || -z "$_al_r" ]]; then
                TD_STEP_OK=0
                TD_FAIL_REASON="malformed allowlist record at line $_al_lineno (empty source_ref or reason): $_al_raw"
                break
            fi

            AL_PREFIX+=("$_al_p")
            AL_CLASS+=("$_al_c")
            AL_SRC+=("$_al_s")
            AL_REASON+=("$_al_r")
            AL_MATCHED+=("0")
        done < "$ALLOWLIST_FILE"
    fi

    TD_ALLOWED=0
    TD_BLOCKING=0
    if [[ "$TD_STEP_OK" -eq 1 ]]; then
        while IFS= read -r _td_line; do
            case "$_td_line" in
                *"[FAIL]"*)
                    _td_desc="${_td_line#*\[FAIL\] }"
                    _td_matched_idx=-1
                    for _td_i in "${!AL_PREFIX[@]}"; do
                        _td_p="${AL_PREFIX[$_td_i]}"
                        if [[ "${_td_desc:0:${#_td_p}}" == "$_td_p" ]]; then
                            _td_matched_idx="$_td_i"
                            break
                        fi
                    done
                    if [[ "$_td_matched_idx" -ge 0 ]]; then
                        echo "  [ALLOWED] $_td_desc (${AL_CLASS[$_td_matched_idx]})"
                        AL_MATCHED[$_td_matched_idx]=1
                        TD_ALLOWED=$((TD_ALLOWED + 1))
                    else
                        echo "  [BLOCKING] $_td_desc"
                        TD_BLOCKING=$((TD_BLOCKING + 1))
                    fi
                    ;;
            esac
        done < /logs/05-theme-doctor.log

        for _td_i in "${!AL_PREFIX[@]}"; do
            if [[ "${AL_MATCHED[$_td_i]}" -eq 0 ]]; then
                echo "  [UNUSED] ${AL_PREFIX[$_td_i]}"
            fi
        done
    fi

    echo ""
    if [[ "$TD_STEP_OK" -eq 1 && "$TD_BLOCKING" -eq 0 ]]; then
        echo "step=theme-doctor status=ok allowed=$TD_ALLOWED blocking=0" >> /logs/summary.log
        echo "=== theme-doctor: allowed=$TD_ALLOWED blocking=0 (rc=$TD_RC) ==="
    else
        [[ -z "$TD_FAIL_REASON" ]] && TD_FAIL_REASON="$TD_BLOCKING failure(s) not covered by the committed allowlist"
        echo "step=theme-doctor status=fail allowed=$TD_ALLOWED blocking=$TD_BLOCKING" >> /logs/summary.log
        echo "=== theme-doctor: FAILED — $TD_FAIL_REASON ==="
        tail -n 40 /logs/05-theme-doctor.log || true
        GATE_FAIL=1
    fi
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
    "${CACHE_MOUNT_ARGS[@]}" \
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
