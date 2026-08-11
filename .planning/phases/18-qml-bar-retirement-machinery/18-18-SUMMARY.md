---
phase: 18-qml-bar-retirement-machinery
plan: 18
subsystem: infra
tags: [quickshell, qml, hyprland, systemd, measurement, qsg-render-timing, proc, soak]

# Dependency graph
requires:
  - phase: 18-07
    provides: "quickshell.service — the supervised unit whose pid/cgroup/NRestarts this plan's soak anchors to"
  - phase: 18-16
    provides: "HotZone.qml create/destroy lifecycle — the surface the deferred 200-cycle exercise targets"
provides:
  - "18-FRAME-RATE.md — LEDGER-03 measurement methodology, safe host facts, and exact resume commands (no condition measured yet)"
  - "18-BAR-SOAK.md — QBAR-11's aggregated permanent-liveness inventory, pre-declared tolerances, and a real live start capture (soak end deferred)"
  - "Two WINDOWS.md unrun-verify entries (51, 52) making the deferred live campaigns discoverable and resumable"
affects: [18-19]

# Actuals (#2632)
actuals:
  tokens: 9800
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Deferred-live-measurement artifact shape: methodology + safe host facts + honest not-measured status per condition + verbatim resume commands + a WINDOWS.md unrun-verify pointer, rather than a partial/inconsistent measurement or a fabricated number"

key-files:
  created:
    - .planning/phases/18-qml-bar-retirement-machinery/18-FRAME-RATE.md
    - .planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md
  modified:
    - .planning/WINDOWS.md

key-decisions:
  - "This plan's live-intervention tasks (Task 1's stop/restart + unsupervised instrumented instance; Task 4's 4-hour soak wait and 200-cycle exercise) are deferred rather than performed this session, per the orchestrator's explicit standing-preference guidance for this plan run: skip disruptive live/interactive intervention, capture methodology and available readings, record the remainder as a resumable deferred item rather than blocking on wall-clock time or rearranging the user's live desktop."
  - "Task 3 (the aggregated inventory, pre-declared tolerances, and start capture) WAS performed for real — it required no service interruption and no desktop rearrangement, only read-only /proc, ps, hyprctl and systemctl reads against the already-running supervised process, plus one genuine 300-second wake/CPU observation window."
  - "Since C2/C3/C4 (OVER-04's actual load-floor conditions) were not measured, Task 2's ledger corrections (16-OVER04-MEASUREMENT.md, PROJECT.md, MILESTONES.md) were NOT made — writing 'measured' numbers into those files without a real measurement would violate this plan's own prohibition. LEDGER-03 stays open."
  - "Task 5's blocking decision (GPU/network sampler disposition) was not decided — its own text requires 'Task 4 measured what that costs,' and Task 4 did not run. Deciding between option-a/option-b without that number would be presumptuous; left open."
  - "status: halted (not complete) — per #2830's machine-read semantics, this correctly blocks 18-19 (depends_on: [18-02, 18-17, 18-18]) from being offered to the executor until this plan is resumed and re-summarized as complete."

requirements-completed: []

coverage:
  - id: D1
    description: "Frame-rate measurement methodology (Task 1) fully documented with safe host facts captured live, all five conditions honestly marked not-measured with reasons, and exact resume commands recorded"
    requirement: "LEDGER-03"
    verification: []
    human_judgment: true
    rationale: "The deliverable itself is a deferred methodology capture, not a passing measurement — LEDGER-03 is NOT closed by this plan run. A human (with the live desktop available for rearrangement) must run the resume campaign in 18-FRAME-RATE.md before this requirement can be marked complete."
  - id: D2
    description: "QBAR-11 aggregated permanent-liveness inventory, pre-declared tolerances, and a real live start capture (pid, RSS, one confirmed long-lived child, a genuine 300s wake/CPU observation)"
    requirement: "QBAR-11"
    verification: []
    human_judgment: true
    rationale: "The start capture is real and complete, but QBAR-11 requires a closed soak (end capture + verdict) which needs 14400s of continued uptime and a 200-cycle exercise this session could not perform. A human must resume 18-BAR-SOAK.md's Section five once the window elapses before this requirement can be marked complete."

duration: ~45min
completed: 2026-08-11
status: halted
---

# Phase 18 Plan 18: QML Bar Measurement Methodology — LEDGER-03 and QBAR-11 Deferred by Design

**Both measurement artifacts exist with real, live-captured host facts and a fully specified resume procedure, but neither requirement closes this session: the frame-rate campaign needs the user's live desktop rearranged to OVER-04's load floor, and the soak needs 4+ hours of continued uptime this session cannot wait out — both are recorded as resumable deferred items rather than forced to a fabricated or partial result.**

## Performance

- **Duration:** ~45 min (includes a genuine 300-second live wake/CPU observation window)
- **Started:** 2026-08-11T10:13Z (approx)
- **Completed:** 2026-08-11T10:35Z (approx, last commit)
- **Tasks:** 2 of 5 plan tasks produced real artifact content (Task 1 methodology-only, Task 3 in full); Task 2, Task 4 and Task 5 deferred/blocked
- **Files modified:** 3 (2 created, 1 modified)

## Accomplishments

- `18-FRAME-RATE.md` created: the complete LEDGER-03 measurement methodology (sanctioned `QSG_RENDER_TIMING`/`QSG_RENDER_LOOP=threaded` instrument, the forbidden compositor-overlay instrument with the exact incident that forbids it, all five conditions' definitions), safe live host facts (refresh rate `164.99899`Hz, reserved `[[0,46,0,0]]`, `quickshell 0.3.0-2`, `Hyprland 0.56.2`, `NRestarts=0`, current live load `4 windows/4 workspaces` — short of OVER-04's `8`/`3` floor), and the exact verbatim resume commands.
- `18-BAR-SOAK.md` created: QBAR-11's permanent-liveness inventory aggregated from all four upstream sources (18-08's three widened gates + its own updates-poll charge, 18-11's separately-recorded `swaync-client -swb` subscription child, 18-16's hot-zone create/destroy lifecycle, 18-07's zero-added-process fact), the two deliberately un-widened backends (`WifiBackend`/`BluetoothBackend`) as a non-charge, six pre-declared tolerance gates with their one-step-either-side values, and a **real, live start capture**: pid `737907`, RSS `450424` KiB, one confirmed long-lived child (`737957`, verified `/usr/bin/swaync-client -swb` — directly confirms 18-11's finding), and a genuine 300-second (315s actual) wake/CPU observation yielding `19.3429` wakes/sec and `0.002476` cpu-sec/sec.
- The GPU/network-sampler cost (900 `nvidia-smi` spawns/hour, per 18-08's measurement) is restated with its ownership (`shell.qml`, 18-05's frozen file) and left explicitly open pending Task 5, which itself could not run without Task 4's completed verdict.
- Two `WINDOWS.md` unrun-verify entries filed (ids 51, 52) pointing at the exact resume sections in both artifacts, so the deferred campaigns are discoverable rather than silently dropped.

## Task Commits

1. **Task 1 (methodology only — live campaign deferred): capture frame-rate measurement methodology** — `ece64cb` (docs)
2. **Task 3 (real): aggregate liveness inventory, declare tolerances, capture live start reading** — `7230a33` (docs)
3. **WINDOWS.md deferred-item entries** — `72f2fb7` (docs)

**Task 2 (ledger corrections), Task 4 (soak end + cycle exercise + verdict) and Task 5 (blocking decision) did not run** — each is blocked on data this session did not produce (see Deviations).

**Plan metadata:** pending final commit (this SUMMARY + STATE.md + ROADMAP.md)

## Files Created/Modified

- `.planning/phases/18-qml-bar-retirement-machinery/18-FRAME-RATE.md` — methodology, safe facts, deferred status per condition, resume commands
- `.planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md` — aggregated inventory, tolerances, real start capture, deferred soak-end protocol
- `.planning/WINDOWS.md` — entries 51 (frame-rate) and 52 (soak) appended

## Decisions Made

- **Deferred both live-intervention campaigns rather than performing them unattended** — Task 1 requires stopping the production `quickshell.service` and running an unsupervised instrumented instance, plus (for conditions C2/C4) rearranging the user's live desktop to at least 8 mapped windows across at least 3 workspaces (live-checked this session: only 4 windows/4 workspaces present). Task 4 requires 14400 seconds of continued single-pid uptime — genuinely impossible to wait out within one execution session — plus a 200-cycle scripted visibility exercise. This follows the orchestrator's explicit standing-preference guidance for this plan run (skip disruptive live/interactive intervention; capture methodology and available readings; defer the rest with exact resume commands) and this project's own recorded preference against unattended probe-shells/restarts against the live desktop.
- **Task 3 was performed in full, for real** — nothing about it required stopping the service or touching the desktop; it is exclusively read-only `/proc`/`ps`/`hyprctl`/`systemctl` inspection of the already-running supervised process, plus one real 300-second observation window that was actually waited out.
- **Task 2's ledger corrections were not made.** `16-OVER04-MEASUREMENT.md`, `PROJECT.md` and `MILESTONES.md` remain byte-identical to before this plan — writing a "measured" figure into any of them without Task 1 having actually measured OVER-04's load-floor conditions would directly violate this plan's own `must_haves.prohibitions` ("MUST NOT report a number that was not measured"). LEDGER-03 stays open.
- **Task 5's blocking decision was not resolved.** Its own text conditions the choice on "Task 4 measured what that costs" — Task 4 did not run, so no soak-verified sampler cost exists to decide against. Auto-selecting either option (or asking the user to decide) without that number would be presumptuous; the decision is left genuinely open, not defaulted.
- **`status: halted`, not `complete`** — this correctly and mechanically blocks `18-19` (`depends_on: [18-02, 18-17, 18-18]`) from being offered to the executor until this plan is resumed and re-summarized as `complete`, per the summary template's `status: halted` machine-read contract (#2830).

## Deviations from Plan

### Scope reduction applied per explicit run-time policy (not a Rule 1-3 auto-fix; recorded per Rule 4's "ask about architectural changes" — pre-authorized by the orchestrator's checkpoint_policy for this run)

**1. Task 1's live QSG_RENDER_TIMING campaign (all 5 conditions) deferred**

- **Found during:** Task 1 planning — live-checked `hyprctl clients -j` before attempting the campaign
- **Issue:** The plan requires stopping `quickshell.service`, running an unsupervised instrumented instance, and (for C2/C3/C4) rearranging the live desktop to OVER-04's 8-window/3-workspace load floor. Live state this session: only 4 mapped windows across 4 workspaces — short of the floor and requiring visible, disruptive window spawning/movement against the user's actual session. C3 additionally needs literal human-driven pointer input, which the plan's own text already treats as legitimately deferrable.
- **Resolution:** Documented the complete methodology, captured every safe host fact available without disruption, marked all five conditions `not measured` with their specific reasons (never a fabricated or estimated figure), and recorded the exact resume commands verbatim from the plan's own action text.
- **Files modified:** `18-FRAME-RATE.md` (new)
- **Verification:** `grep -c 'not measured' 18-FRAME-RATE.md` confirms every condition is honestly labelled; no `hyprctl eval`/`hyprctl reload` appears anywhere in the "Commands executed" section.
- **Committed in:** `ece64cb`

**2. Task 2's ledger corrections skipped (dependent on deviation 1)**

- **Found during:** Task 2 planning, immediately after Task 1's deferral
- **Issue:** Without Task 1's real numbers, editing `16-OVER04-MEASUREMENT.md`/`PROJECT.md`/`MILESTONES.md` would either fabricate figures or leave the UNMEASURED cells untouched while claiming the task complete — both violate this plan's own honesty requirements.
- **Resolution:** No edit made to any of the three files. LEDGER-03 remains open; `18-FRAME-RATE.md` records the deferral and the exact path back to closing it.
- **Files modified:** none
- **Committed in:** n/a (no change)

**3. Task 4's soak end capture, 200-cycle exercise, and verdict deferred**

- **Found during:** Task 4 planning — its own stated precondition (`ps -o etimes= -p <pid>` ≥ 14400) cannot be satisfied within a single execution session
- **Issue:** The plan's own text is explicit that this precondition must not be worked around ("If the elapsed time is short of 14400 seconds, halt and resume when it is met — do not shorten the window to fit the session"), and the orchestrator's guidance for this run separately instructs not blocking on wall-clock time for the soak.
- **Resolution:** Performed Task 3 (inventory, tolerances, start capture) in full with real data, including a genuine 300-second wake/CPU observation window that WAS waited out live. Documented the soak protocol and exact resume commands for the end capture and 200-cycle exercise as Section five of `18-BAR-SOAK.md`. No `## Soak end` or `## Verdict` section was added — consistent with Task 3's own acceptance criteria (`grep -ciE '^## (Soak end|Verdict)' <artifact>` must return `0` at this stage).
- **Files modified:** `18-BAR-SOAK.md` (new)
- **Verification:** `ps -o etimes= -p 737907` confirmed short of 14400 at the time of writing; the document's Section five carries the exact resume commands verbatim.
- **Committed in:** `7230a33`

**4. Task 5's blocking decision not resolved (dependent on deviation 3)**

- **Found during:** Task 5 planning, immediately after Task 4's deferral
- **Issue:** The decision text conditions the choice on Task 4's measured sampler cost, which does not exist this session (only 18-08's earlier, non-soak-verified figure is available).
- **Resolution:** Left open. `18-BAR-SOAK.md`'s GPU/network-sampler section states the 900/hour figure with its ownership (`shell.qml`, 18-05) and marks the disposition `open, pending Task 5`.
- **Files modified:** none
- **Committed in:** n/a (no change)

---

**Total deviations:** 4, all a single coordinated scope reduction (deferral of the plan's live-intervention and long-wait tasks), none a code change, none a fabricated measurement.
**Impact on plan:** LEDGER-03 and QBAR-11 both remain open. Both deferred campaigns are fully specified and resumable in one sitting each (the frame-rate campaign needs the user present to tolerate desktop rearrangement; the soak needs the 4-hour window to actually elapse, which this session's real start capture has already started counting against — `737907`'s `etimes` at start capture was `1189`s, so roughly `13211`s / ~3h40m more of continued uptime on that exact pid is needed before Task 4's resume commands can run).

## Issues Encountered

- The naive `awk '/voluntary_ctxt_switches/{print $2}'` pattern used during the manual live-terminal exploration matched BOTH `voluntary_ctxt_switches` and `nonvoluntary_ctxt_switches` lines in `/proc/<pid>/status`, because the former is a substring of the latter — this produced a two-line capture into a single shell variable during the first attempt. Caught, understood, and correctly reconstructed by cross-referencing against a second, correctly-scoped `nonvoluntary_ctxt_switches`-only match; the final figures recorded in `18-BAR-SOAK.md` (`34001`/`878` at T0, `39939`/`1033` at T1) are the corrected values. Recorded here so a future session reproducing this pattern uses an anchored match (`^voluntary_ctxt_switches:`, as the resume commands in `18-BAR-SOAK.md` now do) rather than the unanchored form.

## User Setup Required

**Two live campaigns need the user's participation to complete, both fully specified with exact commands:**

1. **Frame-rate campaign** (`18-FRAME-RATE.md`, "Exact commands to run"): needs the user present/aware while `quickshell.service` is stopped and an unsupervised instrumented instance runs for roughly 2 minutes of fixed-window conditions, and needs several extra application windows opened and arranged across 3+ workspaces for the OVER-04-load conditions (closed again afterward). C3 additionally needs the user to literally drag a window tile for 20 seconds while the capture runs.
2. **Soak end capture + 200-cycle exercise** (`18-BAR-SOAK.md`, Section five "Resume commands"): needs `quickshell` pid `737907` to stay up, unrestarted, for at least ~3h40m more from this session's end (14400s total from the `1189`s already elapsed at start capture), then a ~7-13 minute scripted hide/reveal exercise (fully automatable, no user action beyond leaving the machine running).

## Next Phase Readiness

- **Not ready.** `18-19` (`depends_on: [18-02, 18-17, 18-18]`) is blocked by this plan's `status: halted` per the summary template's machine-read contract — it should not be offered to the executor until this plan is resumed.
- Both deferred campaigns are fully specified, low-risk to resume (neither requires re-deriving methodology), and independent of each other — either can be picked up first.
- The soak's pid anchor (`737907`, `NRestarts=0`) is live right now; as long as `quickshell.service` is not restarted, the 4-hour window keeps accumulating even without an active session, and the resume commands in `18-BAR-SOAK.md` Section five can simply be run once `ps -o etimes= -p 737907` reports ≥ 14400.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*

## Self-Check: PASSED

- FOUND: `.planning/phases/18-qml-bar-retirement-machinery/18-FRAME-RATE.md`
- FOUND: `.planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md`
- FOUND commit: `ece64cb`
- FOUND commit: `7230a33`
- FOUND commit: `72f2fb7`
