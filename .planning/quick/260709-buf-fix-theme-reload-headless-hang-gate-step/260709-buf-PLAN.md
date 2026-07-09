---
phase: quick-260709-buf
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - theme-engine/.config/theme-engine/lib/reload.sh
  - verify/container-run.sh
autonomous: true
requirements: [INST-03]
user_setup: []

must_haves:
  truths:
    - "theme_engine_reload returns 0 immediately in a headless env (no WAYLAND_DISPLAY and no DBUS_SESSION_BUS_ADDRESS) before ANY reload call fires"
    - "The swaync-client -rs call only runs when the swaync daemon is present and is bounded by a 5s timeout"
    - "container-run.sh fails loudly (overall=FAIL + timeout Reason) instead of hanging forever when any container step blocks"
  artifacts:
    - theme-engine/.config/theme-engine/lib/reload.sh
    - verify/container-run.sh
  key_links:
    - "stow.sh first-boot seed -> theme-apply catppuccin -> theme_engine_reload headless guard short-circuit"
    - "podman run wrapped in timeout -> IN_CONTAINER_RC 124 -> overall=FAIL verdict path -> Reason mentions timeout"
---

<objective>
Fix the INST-03 container-gate indefinite hang (evidence: verify/logs/run-20260709T042501Z, 04-stow.log stuck at "Seeding first-boot theme baseline...", swaync-client -rs blocked 45+ min).

Two independent, atomic fixes:
1. `reload.sh` — add a headless guard so `theme_engine_reload` skips the whole session-dependent reload fan-out when there is no graphical session, plus belt-and-suspenders on the specific line that hung (`swaync-client -rs`).
2. `container-run.sh` — bound the container run with a timeout so any future hang becomes a loud FAIL instead of stalling the gate forever.

Purpose: The first-boot theme seed in a headless container has nothing to reload (render+commit already happened; next login picks up committed state), yet `swaync-client -rs` blocks forever with no session D-Bus. `|| true` guards failure exits, not hangs. The gate harness had no step timeout, so the hang stalled indefinitely.

Output: Two hardened shell scripts, syntax- and shellcheck-clean, committed as two separate atomic commits per concern. theme-apply is untouched.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.claude/CLAUDE.md

# Fix targets (read the full files before editing — both carry load-bearing
# convention comments that must be respected):
@theme-engine/.config/theme-engine/lib/reload.sh
@verify/container-run.sh

# Context only — the block that triggers the hang (do NOT modify):
@stow.sh
</context>

<tasks>

<task type="auto">
  <name>Task 1: Headless guard + swaync hardening in reload.sh</name>
  <files>theme-engine/.config/theme-engine/lib/reload.sh</files>
  <action>
Two changes inside theme-engine/.config/theme-engine/lib/reload.sh, both in the reload fan-out. Do NOT touch theme-apply, lib/gtk.sh, or any other file.

CHANGE A — headless guard (fix 1). At the very top of the theme_engine_reload() function body, before the first fan-out call (`hyprctl reload` on the current line 16), insert a guard: if BOTH `WAYLAND_DISPLAY` and `DBUS_SESSION_BUS_ADDRESS` are unset or empty, echo a clear one-line skip message (state that there is no graphical session and that the committed state applies at next login) and `return 0`. Use set-u-safe parameter expansion for both env reads (the `${VAR:-}` form) since the file is sourced under set -u. This guard MUST short-circuit the ENTIRE fan-out: hyprctl reload, pkill -SIGUSR2 waybar, pkill -SIGUSR1 kitty, the swaync line, theme_engine_gtk_reload, theme_engine_reload_walker, and theme_engine_reload_vscodium — all of which assume a live Wayland+D-Bus session. Rationale to capture in a brief comment above the guard: render+commit already happened before reload is called, so there is nothing to reload without a session; the swaync-client -rs call in particular blocks forever headless (evidence: the 45+ min INST-03 gate hang) and `|| true` guards failures, not hangs.

Discretion call to document in the comment: the vscodium merge (theme_engine_reload_vscodium) is purely file-based and would itself be headless-safe, but the guard intentionally skips it too — this is the simplest correct change (one early return covering the whole fan-out), and the vscodium file-merge is idempotent and re-runs on the first real, session-backed theme switch, so nothing is lost. State this tradeoff in the comment so the skip is intentional, not an oversight.

CHANGE B — swaync belt-and-suspenders (fix 2). Replace the current unconditional swaync line (line 19: `swaync-client -rs >/dev/null 2>&1 || true`) so the reload only fires when the daemon is actually present AND is bounded by a timeout. Use the file's existing `if pgrep -x <name>; then` convention (matches the walker/elephant bounded-poll style already in this file), not an `A && B || true` one-liner, to keep it shellcheck-clean and readable: gate on `pgrep -x swaync` (redirect its output to /dev/null), and inside the guarded branch call `timeout 5 swaync-client -rs >/dev/null 2>&1 || true` — keep the `|| true`. This must remain set-e-safe: a false `if` condition does not trip set -e, and the guarded call keeps its `|| true`. Do NOT touch any bounded-poll counter here; no loop is being added. (The `counter=$((counter+1))` set-e convention documented in this file applies only if a loop is edited — it is not, so leave every existing counter line verbatim.)

Both changes are surgical: the walker/elephant/vscodium helper functions and every existing comment block stay verbatim except for the two edits above.
  </action>
  <verify>
    <automated>bash -n theme-engine/.config/theme-engine/lib/reload.sh && shellcheck -S error theme-engine/.config/theme-engine/lib/reload.sh && grep -q 'WAYLAND_DISPLAY' theme-engine/.config/theme-engine/lib/reload.sh && grep -q 'DBUS_SESSION_BUS_ADDRESS' theme-engine/.config/theme-engine/lib/reload.sh && grep -Eq 'pgrep -x swaync' theme-engine/.config/theme-engine/lib/reload.sh && grep -Eq 'timeout 5 swaync-client' theme-engine/.config/theme-engine/lib/reload.sh && git diff --name-only | grep -qx 'theme-engine/.config/theme-engine/theme-apply' && echo "THEME-APPLY-MODIFIED-FAIL" || echo "theme-apply untouched OK"</automated>
  </verify>
  <done>
- `bash -n` and `shellcheck -S error` both pass on reload.sh.
- The headless guard (both WAYLAND_DISPLAY and DBUS_SESSION_BUS_ADDRESS checked, `return 0`) sits at the top of theme_engine_reload() before hyprctl reload.
- The swaync-client -rs call is guarded by `pgrep -x swaync` and wrapped in `timeout 5`, `|| true` retained.
- theme-apply and all other files are unmodified (git diff shows only reload.sh in this commit).
- Committed as `fix(01-03): guard theme_engine_reload against headless hang (swaync-client -rs)` (or close), matching the tone of prior commits 1da982c / f83ed9f.
  </done>
</task>

<task type="auto">
  <name>Task 2: Per-run step timeout in container-run.sh</name>
  <files>verify/container-run.sh</files>
  <action>
Bound the container regression run in verify/container-run.sh so a future hang fails loudly instead of stalling the gate forever. This edits only the OUTER harness (the inner heredoc container script is untouched — fix 1 already removes the actual hang; this is the safety net for any unanticipated future hang).

STEP 1 — configurable budget. Near the top config block (alongside REPO_URL / IMAGE / TIMESTAMP, around lines 38-43), add an env-overridable timeout with a generous default: `CONTAINER_TIMEOUT="${CONTAINER_TIMEOUT:-3600}"`. Add a short comment: a full run (pull + install.sh + stow.sh + theme-parity) is minutes, not an hour; anything past this budget means a step hung.

STEP 2 — wrap the run. At the `podman run --rm ... bash /logs/container-script.sh` invocation (currently lines 229-235), prefix `podman` with `timeout --kill-after=30 "$CONTAINER_TIMEOUT"` so podman receives SIGTERM at the budget and SIGKILL 30s later if it does not stop. Keep the existing `if ... then IN_CONTAINER_RC=0; else IN_CONTAINER_RC=$?; fi` structure — `timeout` exits 124 on expiry, which flows into IN_CONTAINER_RC exactly like any other nonzero rc.

STEP 3 — record the timeout in the machine log. Immediately after the run block sets IN_CONTAINER_RC, detect the timeout: set `CONTAINER_TIMED_OUT=1` when IN_CONTAINER_RC is 124 or 137 (SIGKILL fallthrough), else 0. When timed out, append `step=container-run status=timeout after=${CONTAINER_TIMEOUT}s` to "$SUMMARY_FILE" so the failing step is recorded.

STEP 4 — timeout-aware verdict, preserving the existing dual-verdict logic. In the FAIL_REASON if/elif chain (currently lines 246-256), add a NEW highest-priority branch at the top: when CONTAINER_TIMED_OUT is 1, ensure overall=FAIL is present in "$SUMMARY_FILE" (append `overall=FAIL` only if `grep -q '^overall='` finds none, mirroring the existing "no overall= verdict" branch so a genuine PASS line is never double-written), and set FAIL_REASON to a message that explicitly names the timeout and points at the per-step logs for the last-running step (e.g. that the run exceeded ${CONTAINER_TIMEOUT}s and was killed). Leave the existing summary-missing / no-overall / overall=FAIL / rc-mismatch branches unchanged below it as `elif`s. The existing dual-verdict contract still holds: PASS requires container rc 0 AND overall=PASS; a timeout (rc 124/137, non-empty FAIL_REASON) prints FAIL and `exit 1` via the existing tail of the script.

Chosen approach note (document briefly in a comment): an outer `timeout` around the single `podman run` — rather than per-step `timeout` wrappers inside the heredoc — is the simplest correct change and catches ALL hangs (including future ones we have not anticipated), not only the swaync one. The file uses `set -uo pipefail` (no set -e), so the added `grep ... || echo` compounds are safe as written.
  </action>
  <verify>
    <automated>bash -n verify/container-run.sh && shellcheck -S error verify/container-run.sh && grep -Eq 'timeout .*"?\$CONTAINER_TIMEOUT"? .*podman run' verify/container-run.sh && grep -q 'CONTAINER_TIMEOUT' verify/container-run.sh && grep -q 'CONTAINER_TIMED_OUT' verify/container-run.sh && grep -Eiq 'timeout' verify/container-run.sh</automated>
  </verify>
  <done>
- `bash -n` and `shellcheck -S error` both pass on container-run.sh.
- `podman run` is wrapped in `timeout --kill-after=30 "$CONTAINER_TIMEOUT"` with CONTAINER_TIMEOUT defaulting to 3600 and env-overridable.
- On a timeout, summary.log records `step=container-run status=timeout ...` and `overall=FAIL`, and the printed Reason names the timeout.
- The existing dual-verdict logic (container rc AND overall=PASS both required for PASS) is preserved; the four existing FAIL_REASON branches are intact as elifs below the new timeout branch.
- Committed separately as `fix(03-04): bound container-run with a per-run timeout so hangs fail loudly` (or close), matching the tone of prior commits 1da982c / f83ed9f.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| headless env → session-only reload calls | reload.sh fan-out assumes a live Wayland+D-Bus session; invoked headless (stow.sh first-boot seed / container gate) it can block indefinitely |
| in-container script → outer gate harness | a hung inner step must surface to the outer harness as a bounded, loud FAIL |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-buf-01 | Denial of Service | theme_engine_reload swaync-client -rs headless | high | mitigate | Headless guard returns 0 before any fan-out; swaync line additionally gated on `pgrep -x swaync` and bounded by `timeout 5` |
| T-buf-02 | Denial of Service | container-run.sh podman run (no step timeout) | high | mitigate | Wrap podman run in `timeout --kill-after=30 "$CONTAINER_TIMEOUT"`; timeout path records overall=FAIL + timeout Reason |
| T-buf-03 | Tampering | package installs | n/a | accept | No package installs, no new dependencies, no new external surface introduced by this bugfix — nothing to audit |
</threat_model>

<verification>
- `bash -n` passes on both edited scripts.
- `shellcheck -S error` passes on both edited scripts.
- Headless guard grep-confirmed present in reload.sh (both env vars + return 0 before hyprctl reload).
- swaync line grep-confirmed guarded (`pgrep -x swaync` + `timeout 5`) in reload.sh.
- Timeout wrapper grep-confirmed present in container-run.sh (`timeout` + `$CONTAINER_TIMEOUT` + `podman run`), plus CONTAINER_TIMED_OUT handling.
- theme-apply unmodified (git diff scoped to the two target files only).
- Two separate atomic commits (`fix(01-03): ...` for reload.sh, `fix(03-04): ...` for container-run.sh).
</verification>

<success_criteria>
- `theme_engine_reload` short-circuits with `return 0` and a skip message when no graphical session is present, so stow.sh's first-boot seed can never hang on a reload call in a headless container.
- The specific line that hung (`swaync-client -rs`) only fires when swaync is running and is bounded by `timeout 5`.
- `container-run.sh` bounds the container run; a future hang produces `overall=FAIL` and a Reason that names the timeout instead of stalling the gate indefinitely.
- Both scripts pass `bash -n` and `shellcheck -S error`; theme-apply is untouched.
- Do NOT re-run the container gate here — the orchestrator handles push + gate relaunch after this task completes.
</success_criteria>

<output>
Create `.planning/quick/260709-buf-fix-theme-reload-headless-hang-gate-step/260709-buf-SUMMARY.md` when done.
</output>
