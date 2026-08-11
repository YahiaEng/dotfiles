---
phase: 18-qml-bar-retirement-machinery
plan: 07
subsystem: infra
tags: [systemd, quickshell, hyprland, autostart, restart-policy, stow]

# Dependency graph
requires:
  - phase: 18-01
    provides: "Bar.qml — the permanently-mounted PanelWindow whose process death this plan makes recoverable"
provides:
  - "quickshell.service — this repo's first custom systemd --user unit, Restart=on-failure/RestartSec=2/StartLimitIntervalSec=60/StartLimitBurst=5"
  - "quickshell's autostart entry launched via `systemctl --user start quickshell.service` instead of a uwsm scope"
  - "HYPRLAND_INSTANCE_SIGNATURE deterministically imported into the systemd user manager environment ahead of the unit start"
  - "Superseding restart rule: `systemctl --user restart quickshell.service`, not a detached uwsm relaunch"
  - "18-RESTART-PARITY.md — live config proof + a runbook for the deferred destructive restart/rate-limit proof"
affects: [18-08, 18-09, 18-10, 18-11, 18-13, 18-14, 18-15, 18-16, 18-17, 18-18, 18-19, 18-20]

# Actuals (#2632)
actuals:
  tokens: 7222
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Repo-owned systemd --user unit as a supervisor over an existing uwsm-scope-launched autostart script, exec-targeting the unchanged launcher script rather than the binary — first instance of this shape in the repo"
    - "No [Install] section by design, so the unit is structurally unenableable and reproduces via clone + stow + explicit `systemctl --user start` from autostart, never an enable step"

key-files:
  created:
    - quickshell/.config/systemd/user/quickshell.service
    - .planning/phases/18-qml-bar-retirement-machinery/18-RESTART-PARITY.md
  modified:
    - stow.sh
    - hypr/.config/hypr/config/autostart.lua
    - hypr/.config/hypr/scripts/quickshell-launch.sh

key-decisions:
  - "RestartSec=2 / StartLimitIntervalSec=60 / StartLimitBurst=5, chosen against the measured live defaults (100ms / 10s / 5) — reasoning recorded in the unit's own header, not just this plan (D-18-40)"
  - "No [Install] section, no Requisite=, no ExecReload= — three deliberate divergences from the waybar.service shape being copied, each justified inline"
  - "systemctl --user start quickshell.service replaces `uwsm app -- quickshell-launch.sh` on the SAME autostart.lua line, same position — a mechanism-only change, not a D-15/D-35 entry violation"
  - "Destructive live proof (SIGTERM/SIGKILL testing, rate-limit trip, human visual check) deferred to the operator per this session's standing skip-live-verification preference — see Deviations"

patterns-established:
  - "A repo-owned systemd --user unit's header carries its own deviation rationale, its exec-target reasoning, its signal-exemption trap and its chosen-numbers-vs-defaults reasoning inline — not only in the authoring plan — so a future reader of the unit alone has the full picture"

requirements-completed: [QBAR-10]

coverage:
  - id: D1
    description: "quickshell.service exists with the exact 7 directives (PartOf, After, StartLimitIntervalSec, StartLimitBurst, Type, Slice, ExecStart, Restart, RestartSec) at their chosen values, start-limit pair in [Unit] not [Service], no Requisite=, systemd-analyze --user verify clean"
    requirement: "QBAR-10"
    verification:
      - kind: other
        ref: "Task 1 automated <verify> bash block — full grep/awk directive check + systemd-analyze --user verify, run live, all PASS"
        status: pass
    human_judgment: false
  - id: D2
    description: "stow.sh reproducibility: explicit mkdir -p for ~/.config/systemd/user independent of swaync's drop-in pre-create, plus a dated 18-07 audit-note correction; install.sh and the PACKAGES array untouched"
    requirement: "QBAR-10"
    verification:
      - kind: other
        ref: "Task 1 automated <verify> — grep checks for the mkdir -p line, the Phase 19 rationale within 10 preceding lines, the audit-note correction, git diff --name-only install.sh empty — all PASS"
        status: pass
    human_judgment: false
  - id: D3
    description: "autostart.lua's quickshell entry (7th of 17, unmoved) now runs systemctl --user start quickshell.service; the other 12 uwsm launches and all 17 entries are intact; HYPRLAND_INSTANCE_SIGNATURE added to both environment-export lines; quickshell-launch.sh changed by comment only"
    requirement: "QBAR-10"
    verification:
      - kind: other
        ref: "Task 2 automated <verify> bash block — grep/awk counts for mechanism, entry count, position, signature var, D-15/D-35 citation, git diff isolated to comment lines, luac -p syntax check — all PASS"
        status: pass
    human_judgment: false
  - id: D4
    description: "Live unit configuration reads back correctly (Restart=on-failure, RestartUSec=2s, StartLimitIntervalUSec=1min, StartLimitBurst=5, Slice=app-graphical.slice, Requisite= empty) and systemd-analyze --user verify is clean, proven on the real host without disrupting the running desktop"
    requirement: "QBAR-10"
    verification:
      - kind: other
        ref: "18-RESTART-PARITY.md — systemctl --user show/is-enabled/status output captured verbatim, systemd-analyze --user verify exit 0"
        status: pass
    human_judgment: false
  - id: D5
    description: "The bar comes back unaided after a SIGKILL (NRestarts +1, new pid, active state, measured return time), a SIGTERM leaves it stopped, six spaced SIGKILLs drive the unit to failed naming the start limit, and a human watching the screen confirms the clock capsule vanishes and returns unaided"
    requirement: "QBAR-10"
    verification: []
    human_judgment: true
    rationale: "Deliberately deferred to the operator, not run by the executor: this requires repeatedly SIGKILLing the process currently rendering the live desktop bar and driving its unit to a deliberately-broken failed state six times, plus a <human-check> step that can only be satisfied by a human physically watching the screen in real time. Running it unattended risks leaving the operator's live session in a failed-unit/no-bar state with nobody present to confirm recovery — a worse outcome than a documented deferral. A full copy-pasteable runbook is in 18-RESTART-PARITY.md. Logged as WINDOWS.md ledger entry 26 (unrun-verify) so it stays visible at ship time. Precedent: 18-01-SUMMARY.md D3 deferred its own human render-gate pass the identical way."

# Metrics
duration: ~35min
completed: 2026-08-11
status: complete
---

# Phase 18 Plan 07: Quickshell Restart Supervisor (QBAR-10) Summary

**quickshell.service — this repo's first custom systemd `--user` unit — supervises the QML shell root with `Restart=on-failure`, a deliberately-chosen 2-second backoff and a 60-second/5-attempt crash-loop rate limit, cutting the autostart launch path over from a transient uwsm scope on the same unmoved line; live configuration is proven on the real host, and the destructive kill/restart/rate-limit proof is handed to the operator as a runbook rather than run unattended against the live desktop.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-08-11T00:38Z (approx, first task commit)
- **Completed:** 2026-08-11T00:45Z
- **Tasks:** 3 (all completed; Task 3's destructive proof deferred — see Deviations)
- **Files modified:** 5 (2 created, 3 modified)

## Accomplishments

- `quickshell.service` created in the `quickshell` stow package: `Type=simple`, `Slice=app-graphical.slice`, `ExecStart=%h/.config/hypr/scripts/quickshell-launch.sh`, `Restart=on-failure`, `RestartSec=2` under `[Service]`; `PartOf=`/`After=graphical-session.target`, `StartLimitIntervalSec=60`, `StartLimitBurst=5` under `[Unit]` — the start-limit pair deliberately NOT under `[Service]` (deprecated compatibility path). No `[Install]` section, no `Requisite=`, no `ExecReload=` — each omission justified in the unit's own header against the `waybar.service` shape it copies.
- `stow.sh` gained an explicit `mkdir -p "$HOME/.config/systemd/user"`, independent of the swaync drop-in pre-create that currently creates that parent as a side effect (and that Phase 19 deletes), plus a dated 18-07 audit-note correction narrowing the 15-13 "two exceptions" claim to three.
- `autostart.lua`'s quickshell entry (7th of 17, unmoved) now runs `systemctl --user start quickshell.service` instead of `uwsm app -- ~/.config/hypr/scripts/quickshell-launch.sh` — the only entry in the file not launched via a uwsm scope, cited inline against the D-15/D-35 "no entry added/removed/reordered" prohibition since only the mechanism changed. `HYPRLAND_INSTANCE_SIGNATURE` added to both the `import-environment` and `dbus-update-activation-environment` lines, making the compositor socket signature deterministically present in the systemd user manager's environment rather than dependent on uwsm's asynchronous finalize.
- `quickshell-launch.sh` gained header-only text naming the unit as its new caller, the exit-zero-means-no-restart consequence of its two guard paths, and the new restart command — zero executable lines touched.
- `18-RESTART-PARITY.md` records live, non-destructive proof that all five configured values read back correctly via `systemctl --user show`, that `systemd-analyze --user verify` is clean, pre-cutover baseline readings (scope ownership, `quickshell-bar` namespace live, 1 process / 0 children), a live-measured correction to the plan's `static` assumption (actual: `linked` — a stow-symlink artifact, not a bug), and a full copy-pasteable runbook for the destructive proof still owed.

## Task Commits

Each task was committed atomically:

1. **Task 1: The unit — first custom systemd --user unit, and the stow reproducibility guarantee** — `8266efd` (feat)
2. **Task 2: Cut quickshell's launch path over to the unit, environment made deterministic** — `26e0f1d` (feat)
3. **Task 3: Prove it on the live host** — `d5ba161` (docs — partial: live config proof only, destructive proof deferred; see Deviations)

**Plan metadata:** pending final commit (this SUMMARY + STATE.md + ROADMAP.md)

## Files Created/Modified

- `quickshell/.config/systemd/user/quickshell.service` — new unit: restart policy, rate limit, exec target, reasoning header
- `stow.sh` — systemd-user pre-create + dated audit-note correction
- `hypr/.config/hypr/config/autostart.lua` — quickshell launch mechanism swap + signature-var import widening
- `hypr/.config/hypr/scripts/quickshell-launch.sh` — header comment additions only
- `.planning/phases/18-qml-bar-retirement-machinery/18-RESTART-PARITY.md` — new live-proof + runbook document

## Decisions Made

- **`RestartSec=2` / `StartLimitIntervalSec=60` / `StartLimitBurst=5`, not systemd's own defaults (100ms / 10s / 5)** — at the default 10s window, five cycles of even a 2-second backoff plus half a second of process life already exceed the window, so a build that survives half a second per attempt would never trip the limit at all; 60s/5 attempts trips within ~10s of session start for any crash cycle shorter than ~12s, while a rarer crash still recovers indefinitely. Every future supervised daemon in this repo that copies this unit inherits this reasoning, not just the numbers.
- **No `[Install]` section, no enable step** — the unit cannot be enabled even by accident; `autostart.lua` stays the single readable inventory of what a session launches, and the whole guarantee reproduces from clone + `./stow.sh` + a session start with zero host-only systemd state.
- **`systemctl --user restart quickshell.service` supersedes the standing detached-relaunch executor rule (STATE.md, 14-06/15-02)** — a plain `pkill quickshell` sends SIGTERM, which the restart policy exempts and will NOT bring the bar back. This is the single most likely misdiagnosis the rest of this phase can produce; every remaining plan restarting quickshell for verification must use the unit command.
- **Destructive live proof and the human visual check deferred to the operator, not run unattended** — see Deviations below.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 adjacent — documented, not code] `is-enabled` reports `linked`, not the plan's assumed `static`**

- **Found during:** Task 3's live configuration readback
- **Issue:** The plan's `must_haves` and Task 3 acceptance criteria assert `systemctl --user is-enabled quickshell.service` reports `static`. Live measurement shows `linked`.
- **Root cause:** systemd resolves the unit file's realpath before classifying its enablement state. `~/.config/systemd/user/` is a real directory (this plan's own `mkdir -p`), but the file inside it, `quickshell.service`, is itself a stow symlink whose target sits outside every standard systemd unit search path — systemd distinguishes "no `[Install]`, file lives directly in a search path" (`static`) from "unit reached via a symlink resolving outside all search paths" (`linked`).
- **Resolution:** Not a bug, nothing to fix — every stow-managed unit in this repo would report `linked` under the same check, and it is functionally identical to `static` for this plan's actual goal (never `enabled`/`enabled-runtime`, no `WantedBy=`/`.wants/` linkage of any kind, confirmed via `systemctl --user list-unit-files`). Documented in full in `18-RESTART-PARITY.md`.
- **Impact:** None on correctness or reproducibility. The functional guarantee (no accidental enable, no host-only wants-symlink) holds; only the literal string differs from what the plan assumed before this live check ran.

**2. [Deferred, not fixed — documented] Task 3's destructive restart/rate-limit proof and its `<human-check>` were not run by the executor**

- **Found during:** Task 3 planning, before any destructive action was taken
- **Issue:** Task 3's `<action>` requires SIGTERM-ing the process currently rendering the live desktop bar, starting the unit, SIGKILLing it once to prove restart, then six more times spaced to trip the rate limit and drive the unit into a deliberately-`failed` state, followed by recovery — plus a `<human-check>` step ("watch the screen... the clock pill vanishes... reappears... no keystroke, no command in between") that structurally requires a human physically present and watching in real time.
- **Resolution:** Per this session's standing "skip live verification, ship fast — commit code directly and let the user verify; no probe shells, restarts, or screenshots" preference, and because running six deliberate crash cycles against the operator's live bar unattended risks leaving the session in a broken/no-bar state with nobody present to confirm recovery, the executor performed only the non-destructive portion (live `systemctl show`/`is-enabled`/`systemd-analyze verify` checks, all passing) and wrote a full copy-pasteable runbook for the remainder into `18-RESTART-PARITY.md`.
- **Files affected:** None (documentation-only; Tasks 1-2's code changes are unaffected and fully verified)
- **Tracked:** WINDOWS.md ledger entry 26 (`unrun-verify`, phase 18), same pattern as 18-01-SUMMARY.md's D3 deferral of its own human render-gate pass.

---

**Total deviations:** 1 auto-documented (live-measurement correction, not a bug), 1 deliberate deferral (destructive live proof + human visual check, tracked in WINDOWS.md).
**Impact on plan:** Tasks 1-2 (the actual code deliverable — the unit, the reproducibility guarantee, the launch-path cutover) are complete, committed and fully verified against their own automated `<verify>` blocks. Task 3's live proof is real but partial: everything checkable without disrupting the live desktop was checked and passed; the destructive half is handed to the operator as an exact runbook rather than skipped silently.

## Issues Encountered

- Initial unit-header draft for Task 1 contained the literal substring `Requisite=` inside a prose sentence explaining its deliberate omission, which collided with the acceptance criterion `grep -c 'Requisite=' ... returns 0`. Rephrased to `` `Requisite` `` (no trailing `=`) without losing the explanation — self-caught before commit, not a runtime issue.
- `./stow.sh` needed a re-run mid-plan (Task 2's precondition) to link the newly-created unit into `~/.config/systemd/user/`; the run's pre-existing, unrelated `vscodium` stow conflict and `chsh` sudo-password failure both predate this plan and were left untouched (out of scope).

## User Setup Required

**Live restart/rate-limit proof owed** — see `18-RESTART-PARITY.md`'s "Deferred to the operator" section for the exact runbook (8 steps, copy-pasteable) and the `<human-check>` this plan cannot self-certify. Nothing here blocks continuing to the rest of this phase; the code is complete and independently verified.

## Next Phase Readiness

- Every remaining plan in this phase that restarts quickshell for its own verification must use `systemctl --user restart quickshell.service`, never a detached `uwsm app --` relaunch or a plain `pkill` — this supersedes STATE.md's standing 14-06/15-02 rule for quickshell specifically.
- The cutover takes effect at the NEXT Hyprland session start (autostart.lua only runs at `hl.on("hyprland.start", ...)`); the currently-running quickshell process is still scope-launched until then. This is expected, not a defect — 18-RESTART-PARITY.md's runbook Step 3 (`systemctl --user start quickshell.service`) performs the cutover for the current session when the operator is ready to run it.
- Zero-added-process reading (1 process, 0 children) recorded pre-cutover in `18-RESTART-PARITY.md` for 18-18 (QBAR-11) to diff against; the operator should re-confirm `pgrep -c -x quickshell` after running the runbook to close the loop.
- WINDOWS.md ledger entry 26 tracks the deferred destructive proof; entries 24 and 25 (18-01/18-05 human render gates) remain open from prior plans in this same phase — none block continuing.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*

## Self-Check: PASSED

- FOUND: `quickshell/.config/systemd/user/quickshell.service`
- FOUND: `.planning/phases/18-qml-bar-retirement-machinery/18-RESTART-PARITY.md`
- FOUND: `.planning/phases/18-qml-bar-retirement-machinery/18-07-SUMMARY.md`
- FOUND commit: `8266efd`
- FOUND commit: `26e0f1d`
- FOUND commit: `d5ba161`
