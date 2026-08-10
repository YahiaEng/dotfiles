---
status: passed
status_qualifier: passed_under_two_operator_waivers
phase: 13-motion-retrofit-existing-surface-sweep
verified: 2026-07-28
verifier: orchestrator (gsd-verifier agent deliberately not spawned — see Method)
plans_complete: 7/7
requirements: [MOTION-01, MOTION-02, MOTION-03, MAINT-02, MAINT-03]
waivers: 2
waived_gates: [D-19/D-20 motion soak gate, WR-04 teardown-hazard measurement]
requirements_not_closed: [MAINT-02]
---

# Phase 13 Verification — Motion Retrofit & Existing-Surface Sweep

## Verdict

Phase 13 is marked **complete under two explicit operator waivers**. It did not pass on its
own terms. Both waived gates are recorded below as open debt, not as satisfied criteria.

## Method

The `gsd-verifier` agent was deliberately not spawned. Its outcome was predetermined: it would
have returned `gaps_found` on the two gates the operator had already consciously waived, which
routes to `/gsd-plan-phase 13 --gaps` and reopens the phase — the opposite of the decision that
was made. This record is written directly instead, and states the gaps plainly rather than
routing them.

Mechanical gates below were re-measured by the orchestrator, not taken from agent reports.

## Mechanical gates — all green, measured 2026-07-28

| Gate | Result |
|------|--------|
| `theme-stress-test` | exit 0 — **10/10 switches, 162 passed, 0 failed** (first full run this milestone) |
| `motion-lint` | exit 0 — 53 passed, 0 failed |
| `motion-lint --no-pending` | exit 0 — zero pending exemptions (D-33) |
| `theme-parity` | exit 0 — 2697 passed, 0 failed across 22 render dirs |
| `theme-doctor` | exit 0 — 206 passed, 0 failed |
| `git status --porcelain` | empty |

## Waiver 1 — D-19/D-20 motion soak gate (plan 13-07, Task 1)

**Status: WAIVED by explicit operator decision, 2026-07-28. Not passed.**

The soak floor required 3 distinct desktop sessions. Measured: **1** — `Hyprland` ran as a
single unbroken process (PID 966, started 2026-07-26 22:31:07) across one boot, and that
session *predates* the soak clock (2026-07-27T03:40:53Z). No A/B comparison flips were
performed. No motion was judged.

`13-MOTION-SOAK-VERDICT.md` records all 13 motions as `NOT ASSESSED — soak gate waived`.
No motion carries a `keep` verdict.

**Consequence:** the "looked fine at review, wrong in daily use" failure mode that D-19/D-20
exist to catch is **not ruled out** for any of the 13 retrofitted motions. MOTION-03's literal
render-gate wording was satisfied by 13-01, 13-02 and 13-05; its soak-depth intent was not.

## Waiver 2 — WR-04 teardown-hazard measurement (plan 13-03, Task 2)

**Status: NOT PERFORMED. Blocking gate waived by explicit operator decision, 2026-07-28.**

The measurement required a human at a TTY running `uwsm stop` with a stopwatch. It was never
run. Task 3 therefore resolved to the conservative no-change default —
`wleave/.config/wleave/layout.json` is byte-unchanged — which is **not** Branch B, since
Branch B requires evidence of falsification that does not exist.

**Consequence:** the logout teardown hazard is **unresolved** — neither confirmed nor
falsified. Logout remains on the bare path by default, not by finding. **MAINT-02 is not
closed**: WR-01, WR-02 and WR-03 are fixed and fault-injection proven (`baae579`); WR-04 is
open. Reproduction steps are preserved in `13-03-PLAN.md` Task 2.

## Delivered

| Req | State |
|-----|-------|
| MOTION-01 | Complete — Hyprland animations on shared curve set |
| MOTION-02 | Complete — waybar, swaync, walker, SwayOSD, wleave, AGS media card all token-driven |
| MOTION-03 | Render gates complete (13-01, 13-02, 13-05); **soak depth waived** |
| MAINT-02 | **Not closed** — 3 of 4 WR items fixed, WR-04 open |
| MAINT-03 | Complete — icon-theme picker browse/install |

Also landed: the D-21 A/B toggle removed from the shipped tree per its standing prohibition;
`current.jpg` untracked, gitignored and install-seeded (D-23, one-way, operator-confirmed);
motion-lint at D-32's exemption end state; WINDOWS.md entries 1, 2, 8 and 9 closed.

## Carried forward

1. **WR-04 teardown measurement** — unresolved hazard, steps in `13-03-PLAN.md` Task 2.
2. **Motion soak** — 13 motions unassessed; re-soak needs 3 fresh compositor sessions.
3. **WINDOWS.md entry 10** — opened by 13-01 after 13-06/13-07's acceptance criteria were
   authored; legitimately open and out of scope for this phase.
