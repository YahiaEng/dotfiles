---
phase: quick-260709-buf
plan: 01
subsystem: infra
tags: [bash, shellcheck, hyprland, swaync, podman, timeout, headless]

requires:
  - phase: quick-260709-a5i
    provides: install.sh AUR_PKGS with alpm_octopi_utils removed, unblocking the INST-03 container gate up to the point where it hung
provides:
  - theme_engine_reload() short-circuits with a headless guard (WAYLAND_DISPLAY / DBUS_SESSION_BUS_ADDRESS both unset) before any reload call fires
  - swaync-client -rs additionally gated on `pgrep -x swaync` and bounded by `timeout 5`
  - verify/container-run.sh bounds the whole podman run in `timeout --kill-after=30 "$CONTAINER_TIMEOUT"` (default 3600s, env-overridable), records a timeout verdict (`overall=FAIL` + named Reason) instead of hanging forever
affects: [theme-engine, verify, INST-03]

tech-stack:
  added: []
  patterns:
    - "Headless-session guard: check WAYLAND_DISPLAY and DBUS_SESSION_BUS_ADDRESS with ${VAR:-} before any session-dependent fan-out under set -u"
    - "Outer timeout wrapper around a single long-running subprocess (podman run) as a blanket hang safety net, rather than per-inner-step timeouts"

key-files:
  created: []
  modified:
    - theme-engine/.config/theme-engine/lib/reload.sh
    - verify/container-run.sh

key-decisions:
  - "Headless guard skips the ENTIRE reload fan-out (including the file-only vscodium merge) rather than selectively skipping only session-dependent calls — simplest correct fix; vscodium merge is idempotent and re-runs on the next real theme switch"
  - "swaync-client -rs kept a second, independent guard (pgrep -x swaync + timeout 5) directly on the line that hung, as belt-and-suspenders beneath the headless guard"
  - "container-run.sh timeout wraps the single outer `podman run` invocation rather than adding per-step timeouts inside the in-container heredoc — catches all future hangs, not only the swaync one"

patterns-established:
  - "Any future session-dependent reload/notification call added to reload.sh must live inside (or after) the headless guard at the top of theme_engine_reload()"

requirements-completed: [INST-03]

coverage:
  - id: D1
    description: "theme_engine_reload returns 0 immediately in a headless env before any reload call fires"
    requirement: "INST-03"
    verification:
      - kind: unit
        ref: "bash -n + shellcheck -S error theme-engine/.config/theme-engine/lib/reload.sh; grep-confirmed WAYLAND_DISPLAY/DBUS_SESSION_BUS_ADDRESS guard precedes hyprctl reload"
        status: pass
    human_judgment: true
    rationale: "Static checks confirm the guard's presence and position, but the actual headless-hang non-reproduction can only be proven by re-running the INST-03 container gate end-to-end (deferred to orchestrator per plan constraints — this quick task explicitly does not run the container gate)"
  - id: D2
    description: "swaync-client -rs only runs when swaync is present and is bounded by a 5s timeout"
    requirement: "INST-03"
    verification:
      - kind: unit
        ref: "grep -Eq 'pgrep -x swaync' and 'timeout 5 swaync-client' in reload.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "container-run.sh fails loudly (overall=FAIL + timeout Reason) instead of hanging forever when a container step blocks"
    requirement: "INST-03"
    verification:
      - kind: unit
        ref: "bash -n + shellcheck -S error verify/container-run.sh; grep-confirmed timeout --kill-after=30 \"$CONTAINER_TIMEOUT\" wraps podman run, CONTAINER_TIMED_OUT branch present"
        status: pass
    human_judgment: true
    rationale: "Static checks confirm the wrapper and verdict logic are wired correctly, but the actual timeout-triggers-FAIL behavior can only be proven by an end-to-end container gate re-run (deferred to orchestrator per plan constraints)"

duration: 6min
completed: 2026-07-09
status: complete
---

# Quick Task 260709-buf: Fix theme-reload headless hang + container gate step timeout Summary

**Headless guard in theme_engine_reload() short-circuits the entire session-dependent fan-out (plus a second swaync-specific pgrep+timeout gate), and container-run.sh now bounds its single podman run with an outer `timeout --kill-after=30` so any future hang fails loudly instead of stalling INST-03's gate indefinitely.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-09T08:37:00+03:00 (approx, per first commit)
- **Completed:** 2026-07-09T08:37:52+03:00
- **Tasks:** 2 completed
- **Files modified:** 2

## Accomplishments

- `theme_engine_reload()` in `theme-engine/.config/theme-engine/lib/reload.sh` now returns 0 immediately, with a clear skip message, when neither `WAYLAND_DISPLAY` nor `DBUS_SESSION_BUS_ADDRESS` is set — before hyprctl reload, waybar/kitty signals, swaync, GTK reload, walker restart, or the vscodium merge ever fire. This directly fixes the INST-03 gate hang (evidence: `verify/logs/run-20260709T042501Z`, `04-stow.log` stuck at "Seeding first-boot theme baseline...", `swaync-client -rs` blocked 45+ minutes).
- `swaync-client -rs` additionally gated on `pgrep -x swaync` and wrapped in `timeout 5` as a second, independent layer directly on the line that hung — belt-and-suspenders beneath the headless guard.
- `verify/container-run.sh` now wraps the single `podman run` invocation in `timeout --kill-after=30 "$CONTAINER_TIMEOUT"` (default 3600s, env-overridable). On expiry (rc 124/137), the script records `step=container-run status=timeout after=${CONTAINER_TIMEOUT}s` in `summary.log` and produces a highest-priority `FAIL_REASON` naming the timeout, while the existing dual-verdict logic (container rc AND `overall=PASS` both required) remains intact as `elif` branches below.
- `theme-engine/.config/theme-engine/theme-apply` is untouched — confirmed via `git diff --name-only` against the pre-task HEAD.

## Task Commits

Each task was committed atomically:

1. **Task 1: Headless guard + swaync hardening in reload.sh** - `1e747eb` (fix)
2. **Task 2: Per-run step timeout in container-run.sh** - `50ad696` (fix)

**Plan metadata:** Docs commit handled by the orchestrator, not this executor (per task constraints).

## Files Created/Modified

- `theme-engine/.config/theme-engine/lib/reload.sh` - Added headless guard at top of `theme_engine_reload()`; hardened `swaync-client -rs` call with `pgrep -x swaync` gate + `timeout 5`
- `verify/container-run.sh` - Added `CONTAINER_TIMEOUT` config (default 3600, env-overridable); wrapped `podman run` in `timeout --kill-after=30`; added `CONTAINER_TIMED_OUT` detection and a highest-priority `FAIL_REASON` branch for timeouts

## Decisions Made

- Headless guard intentionally skips the entire fan-out (including the purely file-based vscodium merge) rather than selectively excluding only the session-dependent calls — simplest correct change (one early return), and the vscodium merge is idempotent so nothing is lost by deferring it to the next real theme switch.
- Outer `timeout` around the single `podman run` call (not per-inner-step timeouts inside the in-container heredoc) — catches all future hangs, not only the one just fixed in reload.sh, with minimal surface area changed.

## Deviations from Plan

None - plan executed exactly as written. Both tasks matched their `<action>` specs precisely; all `<verify>` automated checks passed on first attempt.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Both fixes are committed and ready for the orchestrator to push and relaunch the INST-03 container gate. This quick task deliberately did NOT re-run `verify/container-run.sh` — per task constraints, the orchestrator handles push + gate relaunch, which will be the actual evidence run proving the hang is resolved and any future hang fails loudly instead of stalling.

---
*Phase: quick-260709-buf*
*Completed: 2026-07-09*

## Self-Check: PASSED

- FOUND: theme-engine/.config/theme-engine/lib/reload.sh
- FOUND: verify/container-run.sh
- FOUND: 1e747eb (fix(01-03) commit)
- FOUND: 50ad696 (fix(03-04) commit)
