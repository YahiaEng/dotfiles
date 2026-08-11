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
  - "18-FRAME-RATE.md — LEDGER-03 CLOSED: methodology plus the live five-condition campaign (eae9001). 60 fps floor passes; 165 fps target recorded not-resolvable with the sanctioned instrument"
  - "18-BAR-SOAK.md — QBAR-11's aggregated inventory, pre-declared tolerances, and a live re-anchored start capture with a recomputed threshold table (soak end still owed)"
  - "WINDOWS.md rows 51 and 52 closed as fixed; row 63 (sampler debt, Task 5 option-b) and row 64 (the running soak window) appended"
  - "Two corrections downstream plans must honour: the reserved array is [[0,48,0,0]] not [[0,46,0,0]], and the long-lived-child gate intersects by command not pid"
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
  - "SUPERSEDED 2026-08-12 — was: 'status: halted (not complete) — per #2830's machine-read semantics, this correctly blocks 18-19 until this plan is resumed and re-summarized as complete.' That is exactly what happened: the plan was resumed and is now complete, so 18-19 is offered to the executor."
  # ── Resumption decisions, 2026-08-12 ────────────────────────────────
  - "LEDGER-03 was ALREADY closed when the decisions above said it was not — the campaign ran later the same day (eae9001) and 18-FRAME-RATE.md reads 'Status: MEASURED'. The 2026-08-11 decision text describing it as deferred was stale within hours of being written. Lesson recorded because it nearly caused a real error: this resumption was about to file a LEDGER-03 waiver before checking the artifact's own status line."
  - "Task 5 decided by the operator as option-b (record as debt, WINDOWS row 63) rather than option-a (scope-correction plan against 18-05). Rationale: five shipped-and-verified plans depend on shell.qml's current shape at wave 8."
  - "This plan is completed on its settled work while QBAR-11 stays explicitly open in WINDOWS row 64, per the operator's decision to unblock 18-19 now and hold 18-20's irreversible waybar deletion until the soak closes. QBAR-11 is NOT claimed as met."
  - "The soak's long-lived-child gate is respecified to intersect by COMMAND rather than pid — proven necessary live when the swaync-client child re-spawned mid-session and a pid intersection would have reported the subscription dead."
  - "The reserved array is [[0,48,0,0]], not the [[0,46,0,0]] recorded throughout phase 18: Phase 18.1 raised Design.barHeight 40 -> 42 to match upstream Athena. 18-19 and 18-20 both carry the stale 46 and must record the live value with this reason rather than be made to pass."

requirements-completed: [LEDGER-03]

coverage:
  - id: D1
    description: "LEDGER-03 frame-rate measurement — methodology, then the live campaign itself across all five conditions"
    requirement: "LEDGER-03"
    verification: []
    human_judgment: true
    rationale: "CLOSED. The methodology capture (this plan's original scope) was followed later the same day by the real campaign — commit eae9001; 18-FRAME-RATE.md now reads 'Status: MEASURED, 2026-08-11'. All five conditions were exercised live with QSG_RENDER_TIMING=1; the compositor overlay that froze the host in Phase 16 was never retried. 60 fps floor PASSES (0 of 81,261 render-loop iterations over 16.67 ms during a human-driven overview drag at OVER-04's own load floor; worst 12 ms / 83.3 fps). The 165 fps target is recorded NOT RESOLVABLE with the sanctioned instrument — integer-ms bucketing swallows the 156.75 fps threshold and iteration counts are an upper bound on presentation — and is deliberately not claimed as a pass. Task 2's ledger corrections all landed (16-OVER04-MEASUREMENT.md, PROJECT.md, MILESTONES.md); REQUIREMENTS.md was the last holdout and was corrected on 2026-08-12."
  - id: D2
    description: "QBAR-11 aggregated permanent-liveness inventory, pre-declared tolerances, and a live start capture anchoring a real soak window"
    requirement: "QBAR-11"
    verification: []
    human_judgment: true
    rationale: "OPEN BY DESIGN — the inventory and tolerances are complete and the window is running, but QBAR-11 needs a closed soak (end capture + 200-cycle exercise + verdict) and 14400s cannot elapse inside an execution session. Tracked in WINDOWS.md row 64. This is the one item gating 18-20, per the operator's 2026-08-12 decision to complete this plan on its settled work and hold the irreversible waybar deletion until the soak closes."

duration: ~45min (initial) + ~35min (2026-08-12 resumption)
completed: 2026-08-11
resumed: 2026-08-12
status: complete
---

# Phase 18 Plan 18: QML Bar Measurement Methodology — LEDGER-03 Closed, QBAR-11's Window Running

**Everything below the line was written on 2026-08-11, when this plan halted with both campaigns deferred. It is retained verbatim as the historical record. Two of the three open items have since closed — see `## Resumption (2026-08-12)` at the end, which is the current state of this plan.**

**Original headline (2026-08-11):** Both measurement artifacts exist with real, live-captured host facts and a fully specified resume procedure, but neither requirement closes this session: the frame-rate campaign needs the user's live desktop rearranged to OVER-04's load floor, and the soak needs 4+ hours of continued uptime this session cannot wait out — both are recorded as resumable deferred items rather than forced to a fabricated or partial result.

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

---

## Resumption (2026-08-12) — the current state of this plan

This plan halted on 2026-08-11 with three items open: Task 2 (ledger corrections), Task 4
(soak end + verdict) and Task 5 (the blocking sampler decision). Two are now closed and the
third is running. `status` is `complete`; the one genuinely open item is tracked in
`WINDOWS.md` row 64 and gates 18-20, not this plan.

### What closed, and how

**Task 1 + Task 2 — LEDGER-03: CLOSED, and it was already closed when this summary said it
was not.** The frame-rate campaign ran later on 2026-08-11, after this summary was written
(`eae9001`). `18-FRAME-RATE.md` opens with `Status: MEASURED`. All five conditions were
exercised live; the 60 fps floor passes with 0 of 81,261 iterations over 16.67 ms, and the
165 fps target is honestly recorded as not resolvable with the sanctioned instrument rather
than claimed. The three ledger targets Task 2 named — `16-OVER04-MEASUREMENT.md`,
`PROJECT.md`, `MILESTONES.md` — all carry the correction. Only `REQUIREMENTS.md` still read
`Pending`, and was corrected on 2026-08-12 along with `LEDGER-01`, whose four bookkeeping
targets were likewise all already done. `WINDOWS.md` row 51 is marked fixed.

**Task 5 — sampler disposition: CLOSED as debt (`option-b`, operator decision).** The GPU
and network samplers cost 900 `nvidia-smi` spawns/hour that no bar entry consumes;
re-narrowing means a second drawer-only gate expression in `shell.qml`. Recorded as
`WINDOWS.md` row 63 with its measured number, named owner and one-line remedy. `option-a`
— cutting a scope-correction plan against 18-05 at wave 8 — was rejected because five
shipped-and-verified plans depend on `shell.qml`'s current shape. No QML was edited, as
both branches require.

**Task 4 — QBAR-11 soak: OPEN, window re-anchored and running.** See below.

### The soak window had to be re-anchored twice, and why that matters

The original anchor (pid `737907`) went void when `quickshell` restarted during Phase 18.1's
bar rebuild. Re-anchoring on 2026-08-12 surfaced three findings that are worth more than the
capture itself:

1. **waybar was still running** from 18.1's GATE-02 comparison, stacked above the QML bar and
   holding a second exclusive zone — reserved read `[[0,94,0,0]]` instead of `[[0,48,0,0]]`.
   A first capture attempt was discarded rather than anchor a 4-hour window to a two-bar
   state about to change. **waybar autostarts** (`autostart.lua:62` →`waybar-launch.sh`), so
   stopping it by hand is not durable — it returns on every boot until 18-20 deletes that
   line. Any session that needs the shipped single-bar configuration must stop it first.

2. **The long-lived-child gate was specified wrong.** Section four intersects the two
   `pgrep -P` samples *by pid*. The child's pid changed mid-session (`262662` → `424020`)
   while the command stayed `/usr/bin/swaync-client -swb`, so a pid intersection yields the
   empty set and reports "the subscription died" — which Section three calls a finding — for
   a subscription that is alive. Twelve samples at 5-second spacing confirmed a single
   re-spawn, not a loop. **The end capture must intersect on command, not pid.**

3. **The reserved array is `[[0,48,0,0]]`, not the `[[0,46,0,0]]` every earlier phase-18
   artifact records.** Real and intended: Phase 18.1 raised `Design.barHeight` from 40 to
   upstream Athena's own `"height": 42`, and `barEdgeMargin` is 6. `Bar.qml`'s own arithmetic
   comment still claimed 46 and was corrected against the live reading (`aa763b1`).
   **18-19's fingerprint and 18-20's parity statement both name `[0,46,0,0]` and are stale by
   2px** — both predate 18.1. Neither should be made to pass; both should record the live 48
   with this reason.

A third re-anchor was forced at 01:09 by a host reboot. **A valid window needs 4 hours with
no reboot and no `quickshell` restart** — that constraint is the whole difficulty of this
task, not the measurement.

### Honest status of the three anchor readings

Three wake rates now exist under three different conditions and they are **not**
interchangeable: `19.3429`/sec (2026-08-11, void, pre-18.1 build), `13.7567`/sec (two-bar
transient, waybar up), `6.9533`/sec (settled single-bar, post-18.1). The drop is **not**
claimed as an improvement — build, bar geometry and compositor surface count all differ
between them and no differential measurement was run to attribute it. Section three's
tolerance *percentages* were pre-declared and were not re-opened; only the absolute bands
were recomputed against the live anchor, in Section four-bis's "Re-anchored thresholds"
table.

### What is still owed

`18-BAR-SOAK.md` Section five, against the live anchor: the end capture, at least five RSS
samples spaced through the window, the 200-cycle hide/reveal exercise through
`bar-visibility.sh`'s own verbs, and the verdict against the re-anchored thresholds. Until
that closes, **QBAR-11 is open and 18-20 must not run** — deleting waybar removes the
fallback bar, and the soak is the evidence that the replacement holds up over hours.
