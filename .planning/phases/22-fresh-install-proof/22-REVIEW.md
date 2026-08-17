---
phase: 22-fresh-install-proof
reviewed: 2026-08-17T02:50:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - verify/container-run.sh
  - install.sh
  - hypr/.config/hypr/scripts/stow-link-check
  - theme-engine/.config/theme-engine/theme-doctor
  - verify/theme-doctor-session-allowlist.txt
  - .gitignore
  - hypr/.config/hypr/config/env.lua
  - README.md
  - VERIFICATION.md
findings:
  critical: 2
  warning: 5
  info: 2
  total: 9
status: fixed
fixed_at: 2026-08-17T03:00:00Z
fix_commits:
  CR-01: 599099b
  CR-02: f96484e
  WR-01: 57ab7c2
  WR-02: 621894e
  WR-03: 246f2a8
  WR-04: d1dfdc7
  WR-05: d1dfdc7
  IN-01: skipped
  IN-02: skipped
---

# Phase 22: Code Review Report

**Reviewed:** 2026-08-17T02:50:00Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** fixed (2026-08-17T03:00:00Z) — both Criticals and all 5 Warnings fixed and committed; both Info findings skipped (optional, non-trivial or diff-minimizing). See per-finding "Disposition" lines below.

## Summary

This phase adds five gating steps to `verify/container-run.sh`, a new dangling-symlink checker (`stow-link-check`), a new theme-doctor fold, a committed session-failure allowlist, and an `install.sh` package-scope restructure. The detached-podman lifecycle rework (D-22-07) is sound: the trap-based cleanup, cidfile handling, and the "never trust the container exit code alone" verdict logic are all correctly ordered and I could not construct a leaked-container or corrupted-summary.log scenario against the happy or timeout paths. `install.sh`'s `--core-only` package-scope split is also correct — no packages lost or duplicated, ordering is right, a default run still installs everything.

However, two of the **new gating mechanisms this phase adds can produce a false PASS**, and I was able to **empirically reproduce both** against the actual code (not just reason about them):

1. `stow-link-check`'s python3 sweep engine buffers all findings and only prints them at the very end; if the python3 subprocess crashes or is unavailable for any reason, the wrapping bash never notices and reports `0 passed, 0 failed`, exit 0.
2. `container-run.sh`'s theme-doctor blocking step never checks theme-doctor's own exit code; if theme-doctor fails to run at all, the step is reported `status=ok`.

Both directly undermine this phase's stated purpose (SC-2's "no dangling reference exists / gate is not merely informational") under exactly the conditions a fresh, unfamiliar container environment is most likely to produce (missing interpreter, broken sourcing, a bad path). These are listed as Critical below, with reproduction steps.

## Critical Issues

### CR-01: `stow-link-check` reports a false PASS when its python3 engine crashes or is missing

**Disposition: fixed** (commit `599099b`). `_slc_sweep`'s python body now wraps the sweep in `try/except`, emitting a `FAIL` and exiting 1 on any unhandled exception instead of silently producing zero output; `run_sweep()` now captures the python3 process's own exit status directly (via a real file, not a process substitution) and fails closed — printing an explicit `[FAIL] ... engine crashed or is unavailable` — whenever that exit status is anything other than 0/1, and additionally fails closed if the process produced zero lines of output at all, consistent with the existing denom>0/present_count==0 vacuous-green guard. Reproduced the original false-PASS live (`python3: command not found` → exit 0, `0 passed, 0 failed`) before the fix and reproduced the corrected fail-closed behavior (exit 1, `[FAIL] ... python3 exit 127`) after. `--self-test` stays 6/6; a real `$HOME` sweep stays 2 passed / 0 failed, exit 0.

**File:** `hypr/.config/hypr/scripts/stow-link-check:519-538` (`run_sweep`), `:507-517` (`run_list`), `:153-505` (the python3 heredoc itself)

**Issue:** `run_sweep()` reads `stow-link-check`'s actual findings from `_slc_sweep`'s stdout via a bash process substitution (`done < <(_slc_sweep sweep "$sweep_home")`). The exit status of the underlying `python3` process is never captured or checked — process substitution exit codes are silently dropped by a `while read` loop unless explicitly `wait`-ed on. The python3 heredoc itself (`_slc_sweep`) has no top-level exception handling: every finding is appended to an in-memory `results` list via `emit()`, and the list is only ever flushed to stdout by a single `dump()` call at the very end of the script (in the `sweep` branch, at the bottom of the `for rel_path, rmode, why in SWEEP_ROOTS:` loop). Consequently:

- If `python3` is not on `$PATH` (e.g. a fresh container with an incomplete/broken environment, or `python-gobject`/base python not yet resolved at the moment this runs), the heredoc invocation fails immediately with "command not found" and produces **zero lines of output**.
- If any unhandled exception occurs anywhere in the walk *before* `dump()` is reached (a future code change, an uncaught `OSError` variant, a permission oddity under rootless-podman UID mapping), the same thing happens: zero output.

In both cases `run_sweep`'s loop reads zero lines, `fail_n` stays `0`, and `[[ "$fail_n" -eq 0 ]]` — the function's own return value — is **true**, so `stow-link-check` exits `0`. This is then trusted verbatim both by `verify/container-run.sh`'s blocking step (`log_step "stow-link-check" ... su - builder -c '...stow-link-check'` at container-run.sh:403-411, which gates purely on this exit code) and by `theme-doctor`'s new fold (theme-doctor:616-627, which parses zero `[PASS]`/`[FAIL]` lines and silently contributes nothing to the tally either way).

The one invocation mode that *would* catch a systemically broken python3 (`--self-test`, since fixtures expecting a non-zero exit would then unexpectedly get `0`) is **never run by the automated pipeline** — `container-run.sh` only ever invokes the bare `stow-link-check` (sweep mode), never `--self-test`.

**Reproduced live** (this session, against the actual file):
```
$ mkdir -p /tmp/slc-repro/emptybin && cp /bin/bash /tmp/slc-repro/emptybin/
$ env -i PATH="/tmp/slc-repro/emptybin" /bin/bash -c '
    export PATH="/tmp/slc-repro/emptybin"
    /home/aorus/dotfiles/hypr/.config/hypr/scripts/stow-link-check --root /tmp
    echo "EXIT CODE: $?"
  '
stow-link-check — dangling-symlink sweep
  target: /tmp

.../stow-link-check: line 155: python3: command not found

Summary: 0 passed, 0 failed
EXIT CODE: 0
```
A completely non-functional checker (python3 unavailable) reports `Summary: 0 passed, 0 failed` and **exits 0** — a clean PASS — instead of failing loudly. No dangling link anywhere in the tree was actually checked.

**Fix:** Capture and check the python3 process's own exit status, not just the line count. Two changes make this fail closed:

```bash
_slc_sweep() {
    local mode="$1" sweep_home="${2:-}"
    python3 - "$mode" "$sweep_home" <<'PYEOF'
    ...
PYEOF
}
```
becomes something that lets the caller see the real exit code — e.g. write to a temp file instead of a process substitution, or capture `PIPESTATUS`:

```bash
run_sweep() {
    local sweep_home="$1"
    local pass_n=0 fail_n=0 out_file
    out_file="$(mktemp)"
    trap 'rm -f "$out_file"' RETURN
    _slc_sweep sweep "$sweep_home" > "$out_file"
    local slc_rc=$?
    if [[ "$slc_rc" -ne 0 ]]; then
        printf '  [FAIL] stow-link-check engine crashed or is unavailable (python3 exit %d)\n' "$slc_rc" >&2
        return 1
    fi
    while IFS=$'\t' read -r tag detail; do
        ...
    done < "$out_file"
    ...
}
```
Additionally, wrap the whole python body in a top-level `try/finally: dump()` so partial results are still emitted (and the traceback is visible) even on a genuine bug, rather than relying solely on the bash-side rc check.

---

### CR-02: `container-run.sh`'s theme-doctor step reports a false PASS when theme-doctor itself fails to run

**Disposition: fixed** (commit `f96484e`). The theme-doctor step now gates on `TD_RC` in addition to the allowlist scan: any exit code other than 0 or 1 (theme-doctor's only two legitimate outcomes) fails the step closed and names the observed exit code. On top of that, even a 0/1 exit is no longer trusted alone — the step now requires the log to affirmatively contain theme-doctor's own final `Summary: N passed, M failed` line before trusting the allowlist verdict, mirroring the "never trust the exit code alone" discipline this same file already applies to its own `summary.log` verdict. Reproduced the original false PASS live (`TD_RC=127`, empty log → `status=ok allowed=0 blocking=0`) before the fix and reproduced the corrected fail-closed behavior (`status=fail ... reason=theme-doctor exited 127 ...`) after, using the allowlist-matching bash extracted verbatim from the file, same method the reviewer used.

**File:** `verify/container-run.sh:427-531`

**Issue:** The blocking theme-doctor step captures theme-doctor's own exit code into `TD_RC` (line 430) but **never checks it again** — grep the whole file: `TD_RC` is referenced exactly once more, inside an `echo` string at line 523, purely for human-readable logging. The pass/fail decision at line 521 (`if [[ "$TD_STEP_OK" -eq 1 && "$TD_BLOCKING" -eq 0 ]]`) is based solely on scanning `/logs/05-theme-doctor.log` for lines containing the literal substring `[FAIL]` and checking each against the allowlist. If theme-doctor never runs to completion — the binary is missing (a stow-link failure, a permissions issue), `su - builder -c` itself fails, `source lib/contract.sh`/`lib/wallpaper.sh` fails early, or the script is killed — the log file is empty (or contains no `[FAIL]`-tagged lines), `TD_BLOCKING` stays `0`, and the step is unconditionally reported `status=ok allowed=0 blocking=0`, indistinguishable from "everything genuinely passed." There is no analogue of `stow-link-check`'s own "vacuous-green guard" (`if denom > 0 and present_count == 0: emit FAIL`) for this step — despite that pattern existing elsewhere in this exact phase's own code, it was not applied here.

**Reproduced live** (this session, extracting the exact allowlist-matching bash verbatim from `container-run.sh:427-531` and running it against an empty log with `TD_RC=127`, simulating "theme-doctor never ran"):
```
$ : > /tmp/slc-repro/logs/05-theme-doctor.log   # simulate a crashed/missing theme-doctor
$ TD_RC=127                                      # "command not found"
$ bash td_repro.sh   # container-run.sh's own allowlist-matching logic, unmodified
step=theme-doctor status=ok allowed=0 blocking=0  (TD_RC was 127, log was EMPTY)
```
The harness would proceed straight to the `theme-parity` step and, if that also passes, write `overall=PASS` — a genuine, undetected failure of the harness's single most heavily-engineered new gating step (D-22-08/09/10).

**Fix:** Gate on `TD_RC` in addition to the allowlist scan, and require a sane minimum PASS count as a floor (mirroring the vacuous-green guard `stow-link-check` already uses):

```bash
su - builder -c 'cd ~/dotfiles && $HOME/.config/theme-engine/theme-doctor' \
    > /logs/05-theme-doctor.log 2>&1
TD_RC=$?

# theme-doctor's own contract: exit 0 (all pass) or 1 (some FAIL) are the
# only two legitimate outcomes; anything else means it never completed.
if [[ "$TD_RC" -ne 0 && "$TD_RC" -ne 1 ]]; then
    TD_STEP_OK=0
    TD_FAIL_REASON="theme-doctor exited $TD_RC (expected 0 or 1) — it did not run to completion"
fi

# ... existing allowlist parse/match logic ...

TD_PASS_COUNT="$(grep -c '\[PASS\]' /logs/05-theme-doctor.log || true)"
if [[ "$TD_STEP_OK" -eq 1 && "$TD_PASS_COUNT" -lt 50 ]]; then
    TD_STEP_OK=0
    TD_FAIL_REASON="only $TD_PASS_COUNT [PASS] lines observed (expected several hundred) — theme-doctor likely did not run to completion"
fi
```

## Warnings

### WR-01: `theme-doctor`'s piped `grep -q`/`grep -qx` calls can flip a real match to "not found" under `pipefail`

**Disposition: fixed** (commit `57ab7c2`). All three `printf ... | grep -q...` pipelines replaced with `grep -q... <<< "$var"` here-strings, removing the SIGPIPE hazard entirely (bash writes a here-string to a temp fd, not a live pipe a reader can close early). Validated by running `theme-doctor` itself (not by reading the diff, per the project's own recorded pitfall): `state-manifest: all 30 entries ... accounted for` and `elephant listproviders covers all configured walker providers (missing: none)` both still report `[PASS]` after the edit.

**File:** `theme-engine/.config/theme-engine/theme-doctor:107,313,316`

**Issue:** `theme-doctor` sets `set -uo pipefail` (line 8). Three checks pipe a variable into `grep -q`/`grep -qx`:
```
107:  if ! printf '%s\n' "$KNOWN_STATE_ENTRIES" | grep -qx "$entry"; then
313:  if printf '%s\n' "$ACTIVE_PROVIDERS" | grep -q '^menus:' || pacman -Q elephant-menus >/dev/null 2>&1; then
316:  elif printf '%s\n' "$ACTIVE_PROVIDERS" | grep -qx "$p"; then
```
`grep -q`/`-qx` exits as soon as it finds a match, closing its stdin. If the upstream `printf` is still writing when that happens, it receives SIGPIPE and exits 141; under `pipefail`, the pipeline's reported status becomes the rightmost *non-zero* exit among the pipeline's commands — i.e. `printf`'s 141, even though `grep` itself matched successfully and exited 0. This flips a genuine match into an apparent "not found," which is exactly the trap already recorded in this project's own operating notes ("pipefail + grep -q false-passes gates... validate gate edits"). This produces a spurious FAIL (state-manifest "unaccounted" entry, or a provider-parity "missing" report), not a false PASS — but it is a real, data-length-dependent flakiness bug in a gate this phase newly makes blocking end-to-end via the theme-doctor fold.

**Fix:** Read from a file or here-string instead of a pipe, which removes the SIGPIPE hazard entirely:
```bash
grep -qx "$entry" <<< "$KNOWN_STATE_ENTRIES"
```
or route through `grep -q` with the *producer* on the right instead of the pipe's write side racing a reader that exits early (a here-string avoids the pipe altogether, since bash writes it to a temp fd/file, not a live pipe).

### WR-02: Allowlist field-count validation breaks if a `reason` field legitimately contains `|`

**Disposition: fixed** (commit `621894e`). The field-count check now requires "at least 4" pipe-delimited fields (`-lt 4`) instead of "exactly 4" (`-ne 4`); `read` with fewer target variables than delimited fields already absorbs everything past the 3rd delimiter into `_al_r` verbatim, including any further `|` bytes, so no other logic changed. Verified with a standalone extraction of the parsing logic: a record with a legitimate `|` inside the reason text is now accepted (reason preserves the embedded pipe), and a record with fewer than 4 fields is still correctly rejected.

**File:** `verify/container-run.sh:450-455`

**Issue:**
```bash
_al_nf=$(($(printf '%s' "$_al_raw" | tr -cd '|' | wc -c) + 1))
if [[ "$_al_nf" -ne 4 ]]; then
    TD_STEP_OK=0
    TD_FAIL_REASON="malformed allowlist record at line $_al_lineno ..."
    break
fi
```
Field count is derived by counting *every* `|` byte in the raw line, including any that appear inside the free-text `reason` column itself (the header documents `reason` as "a non-empty sentence" with no restriction against `|`). A future, entirely legitimate edit to `verify/theme-doctor-session-allowlist.txt` whose `reason` prose contains a literal pipe character (e.g. "requires a live session bus | compositor") would be rejected as malformed and hard-fail the *entire* container gate — a spurious hard-FAIL on valid data. This is fail-closed in direction (safer than a false PASS) but is still a real, easily-triggered correctness bug given the reason column is free text written by a human.

**Fix:** Split on the first three `|` only and treat the remainder as the (single) reason field, e.g. `IFS='|' read -r _al_p _al_c _al_s _al_r_rest <<< "$_al_raw"` with `_al_r_rest` being everything after the third `|` (already how `read` behaves when given fewer split variables than delimited fields — the bug is only in the separate `_al_nf` pre-count, which should be removed or capped at "at least 4" rather than "exactly 4").

### WR-03: Cache-directory creation errors are silently ignored, deferring failure to `podman run`

**Disposition: fixed** (commit `246f2a8`). Applied the suggested fix verbatim: `mkdir -p ... || { echo ...; exit 1; }`. A failure to create the writable cache dirs now exits loudly with a named reason instead of silently deferring to `podman run -d`.

**File:** `verify/container-run.sh:157`

**Issue:** `mkdir -p "$PACMAN_CACHE_WRITE" "$PARU_CACHE_WRITE"` has no error handling. Under `set -uo pipefail` (no `-e`), a failure here (permission issue on `verify/cache/`, disk full, etc.) does not stop the script — `CACHE_MOUNT_ARGS` is still populated with all four `-v` entries as if the mkdir succeeded, and the failure only surfaces later, indirectly, via whatever `podman run -d` does when asked to bind-mount a directory it couldn't create (which may itself silently auto-create the mount point, masking the original problem, or may fail with a less clear error than the actual root cause).

**Fix:** `mkdir -p "$PACMAN_CACHE_WRITE" "$PARU_CACHE_WRITE" || { echo "container-run: cannot create writable cache dirs at $CONTAINER_CACHE_DIR" >&2; exit 1; }`

### WR-04: Trap-based cleanup can race the manual stop/kill/confirm sequence on interrupt

**Disposition: fixed** (commit `d1dfdc7`). Took the review's second remedy: `cleanup_container` is now trapped on `EXIT` only; a separate lightweight `record_interrupt` handler is trapped on `INT`/`TERM` and just records which signal fired in `INTERRUPTED_BY_SIGNAL`, without touching the container. `wait "$WAIT_PID"` still returns immediately on the signal exactly as before, so the existing stop→kill→confirm sequence now always runs first, and `cleanup_container` still runs unconditionally on the script's actual `EXIT` as the final safety net — no change to the overall lifecycle guarantees. The verdict block now checks `INTERRUPTED_BY_SIGNAL` and reports an accurate `FAIL_REASON` naming the signal instead of the generic "container script died before finishing" wording. Verified live with a standalone harness reproducing the same trap-registration pattern: `kill -INT $$` while blocked in `wait` sets the flag without terminating the script, and `cleanup_container` still fires on exit.

**File:** `verify/container-run.sh:594-682`

**Issue:** `trap cleanup_container EXIT INT TERM` (line 602) means an INT/TERM delivered while the script is blocked on `wait "$WAIT_PID"` (line 643) can run `cleanup_container` — which does `podman rm -f "$cid"` — *before* the following stop→kill→confirm/`podman inspect` sequence (lines 646-681) executes. Bash runs a pending trap for a caught signal as soon as the interrupted builtin (`wait`) returns and the next command boundary is reached, which can be before `WAIT_RC=$?` is evaluated by the following logic. In practice this doesn't produce a false PASS (the eventual verdict logic still correctly reports FAIL, since no `overall=` line will be present), but it does mean the documented "actively stop, escalate, and verify" narrative doesn't actually run on the interrupt path — the container is just removed out from under it — and the printed `FAIL_REASON` ends up misleadingly worded ("summary.log had no overall= verdict — container script died before finishing" rather than something naming the interrupt).

**Fix:** Either accept this as intentional (cleanup-via-trap is a valid, simpler outcome) and adjust the comment to stop claiming the stop/kill/confirm sequence always runs on every exit path, or make `cleanup_container` a no-op for the INT/TERM case specifically and let the main-line stop/kill/confirm code handle those signals via an explicit signal handler that sets a flag rather than removing the container directly.

### WR-05: The 10-second "still running after kill" fallback path doesn't abort

**Disposition: fixed** (commit `d1dfdc7`). `STOPPED_CONFIRMED -eq 0` now writes an explicit `overall=FAIL` line to `summary.log`, prints the FAIL banner, and `exit 1`s immediately — skipping the verdict-reading logic entirely instead of flowing into it with a synthetic `IN_CONTAINER_RC=137`. `cleanup_container` still runs via the `EXIT` trap (`podman rm -f` can force-remove a still-running container).

**File:** `verify/container-run.sh:663-681`

**Issue:** If `podman kill` genuinely fails to stop the container within the 10×1s poll window, the code prints a `FATAL` message to stderr (line 672) but does **not** `exit` — it falls through, sets `IN_CONTAINER_RC=137`, and continues into the verdict logic as if this were an ordinary timeout. Since SIGKILL cannot be caught or ignored by a well-behaved process (only an uninterruptible D-state task could survive it, which is extremely rare on Linux), this is a low-probability path — but if it ever fires, the container may still be alive and could theoretically still be writing to the shared `/logs/summary.log` bind mount at the same moment the host script begins reading it for its verdict, which is precisely the race D-22-07's whole repair exists to close.

**Fix:** Treat the `STOPPED_CONFIRMED -eq 0` branch as an unconditional hard failure that skips straight to a `FAIL_REASON` and `exit 1`, rather than flowing into the normal verdict-reading logic that assumes the container is confirmed stopped.

## Info

### IN-01: `stow-link-check`'s other theme-doctor-folded sibling checkers share the same "silent-crash" weakness

**Disposition: skipped** — out of the requested fix scope (Info, optional, "fix only if trivial and zero-risk"). This is a systemic pattern across four separate fold sites in `theme-doctor` (motion-lint, colour-lint, retirement-check, hypr-equivalence-check), not a single trivial edit — fixing it properly means auditing and changing four call sites' exit-code handling, each with its own guarded-skip semantics to preserve. Left for a dedicated follow-up rather than folded into this pass.

**File:** `theme-engine/.config/theme-engine/theme-doctor:472-483` (motion-lint), `:538-548` (colour-lint), `:584-594` (retirement-check), `:509-518` (hypr-equivalence-check)

Every fold in `theme-doctor` reads its child checker's output via `while IFS= read -r _line; do case ... esac; done < <("$CHECKER" ...)` without ever checking the checker's own process exit code. If any of these checkers crashes or produces zero lines, the fold contributes neither PASS nor FAIL to the tally — it silently vanishes from the summary rather than being flagged. This is pre-existing precedent (not introduced by this phase), but the newly-added `stow-link-check` fold (theme-doctor:616-627) inherits it too, and is worth fixing alongside CR-01/CR-02 since all three findings share one root cause (child-checker exit codes are never propagated through these fold patterns).

### IN-02: Dead `'depth1'` dispatch branch in `stow-link-check`'s python sweep

**Disposition: skipped** — out of the requested fix scope (Info, optional). Harmless dead code by the reviewer's own assessment; left in place rather than editing a file this pass already changed substantially for CR-01, to keep that diff focused and easy to review.

**File:** `hypr/.config/hypr/scripts/stow-link-check:464-465`

`if rmode == 'depth1': links = list(walk_links_depth1(abs_root))` — no entry in `SWEEP_ROOTS` uses `rmode == 'depth1'` (the four declared roots use `config-scoped`, `recursive` (×2), and `home-named`). The branch and the `walk_links_depth1` function it calls are unreachable. Harmless, but worth removing or documenting as reserved-for-future-use so a reader doesn't waste time looking for its caller.

---

_Reviewed: 2026-08-17T02:50:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
