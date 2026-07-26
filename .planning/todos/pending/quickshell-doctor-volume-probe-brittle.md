---
id: quickshell-doctor-volume-probe-brittle
created: 2026-07-26
severity: low
source: 12-01 Task 2 session-restart re-proof (post-login quickshell-doctor run)
affects_plans: []
status: pending
---

# `quickshell-doctor`'s one-step-per-press volume probe is over-strict exact-match

**Observed:** post-session-restart `quickshell-doctor` (12-01 Task 2 re-proof) reported

```
[FAIL] one-step-per-press volume probe: measured delta=3276 raw units matches
  recorded baseline=3277
```

**Not a regression, not caused by any 12-01 change.** `quickshell-doctor` was last
modified by Phase 11 commits (9978851, 2529894, 1945a81, 3ec4661, 9b15171); 12-01's own
commit (288e780) touched only `Probe.qml`, `shell.qml`, `qmldir`, and
`12-QS03-EVIDENCE.md` — nothing audio-related.

**Root cause.** The check (`quickshell-doctor` around line 338) is
`[[ "$VOL_DELTA" == "$VOL_BASELINE" ]]` — exact string equality on raw PulseAudio units
against a recorded baseline in `~/.local/state/quickshell/doctor-baseline.json`
(`{"volume_step_delta_raw": 3277}`). The check's own stated purpose is catching a
*doubling* regression (which would read ≈6553 raw units) — a 1-unit delta (3276 vs 3277)
is percentage→raw rounding drift at a different current volume level, not a real
one-step-per-press defect. The gate is stricter than what it actually needs to test.

**Suggested fix (not yet scoped/prioritized):** replace the exact `==` with a small
tolerance band (e.g. `abs(delta - baseline) <= 2` raw units, or a percentage tolerance)
so genuine doubling/halving regressions are still caught while normal rounding drift at
different volume levels does not false-positive.

**Why not fixed immediately:** out of scope for the plan that surfaced it (12-01, QS-03
per-screen fan-out) — flagged per that plan's evidence record and deferred here for
whoever next touches `quickshell-doctor` or a future audio/motion-adjacent phase.
