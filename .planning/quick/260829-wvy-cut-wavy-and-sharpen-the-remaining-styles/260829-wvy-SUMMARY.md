---
quick_id: 260829-wvy
title: Cut the wavy motion style; derive each remaining style's emphasized pair
status: complete
completed: 2026-08-29
commits: [e6f03746]
operator_decision: "Cut wavy, sharpen the rest — approved 2026-08-29 after seeing the measurement"
gates: "motion-lint 811/0; motion-lint --self-test 12/12; hypr-equivalence 3/0"
---

# 260829-wvy — SUMMARY

## What the operator asked

"Some animation styles are too similar — remove redundant ones and make the rest
truly unique." Explicitly a taste call needing approval before deleting.

## Measurement first, approval second

Resolved all six styles to real ms and real control points, sampled every
bezier, and computed pairwise distance. The aggregate said **nothing fully
collapsed** — so the handoff's framing ("wavy and snappy share a spatial-in
curve family") was checked per channel instead of trusted.

Per channel, `wavy` owns no curve of its own anywhere:

| channel | wavy | is | maxΔy |
|---|---|---|---|
| `spatial-in` | `[0.1, 0.9, 0.4, 1.254]` | snappy's `[0.1, 0.9, 0.4, 1.12]`, y₂ nudged | 0.060 |
| `spatial-move` | `[0.1, 0.9, 0.4, 1.15]` | snappy's `[0.1, 0.9, 0.4, 1.06]`, y₂ nudged | 0.040 |
| `spatial-out` | `[0.35, 0, 0.7, 1.06]` | smooth's `[0.35, 0, 0.7, 1]` + 0.06 | 0.027 |
| `standard` | — | **not overridden at all** (base, same as md3) | — |

Its timing was the closest pair in the entire set to `smooth` (mean Δ31ms). And
it no longer dips — peak 1.080, settles from above — so **it had stopped
waving**; the name was a lie.

That independently reproduces the operator's own two prior verdicts recorded in
STATE.md: first "will cause motion sickness", then after the retune "reads very
similar to smooth". Two instruments, same answer.

The other five each hold a distinct axis and are kept: **md3** the reference,
**smooth** the only zero-overshoot one, **snappy** the shortest (100–200ms),
**bouncy** the only visible arc (peak 1.097), **zen** the longest and the only
multi-segment curves.

## Removal surface was small, and migration is free

`styles.wavy` in `motion.json`, one keyword string in `RowIndex.qml:189`. No
gate hardcodes it — the `wavy` mention at `Motion.qml:293` is prose *about* a
gate that used to, which is exactly the "a gate greps its own comment" trap.

**No migration code was needed.** `theme_engine_read_motion_style()` validates
the persisted value against `motion.json`'s own `.styles` keys on every call and
falls back to `md3`, so a stored `wavy` self-heals. The style axis was built as
data (D-04) and that property paid off on removal, not just on addition.

## "Make the rest truly unique" — a derived rule, not taste

The real distinctness gap was not between styles' spatial curves (those are
distinct); it was that **the emphasized channel carried no style character at
all**. Only `zen` overrode an emphasized easing. The other five all pointed at
the same base `emphasized-decelerate`/`emphasized-accelerate`, differing only in
duration.

Rather than invent four curves by taste, the relation already in the file was
found and tested:

```
base spatial-in            [0.05, 0.7, 0.1, 1]
base emphasized-decelerate [0.05, 0.7, 0.1, 1]   -> identical

base spatial-out           [0.3, 0, 0.8, 0.15]
base emphasized-accelerate [0.3, 0, 0.8, 0.15]   -> identical
```

The emphasized curves **are** the monotonic form of the spatial ones. So each
style takes its own spatial pair clamped into `[0,1]`. The clamp is also exactly
what preserves the file's invariant that only `spatial-in/out/move` may leave
`[0,1]` — which is why bouncy's 1.85 crest lands at 1.0 here while staying 1.85
in `spatial-in`.

`md3` needs no override: it overrides no spatial easing, so the base pair is
already correct for it by construction. **That is what validated the rule** — the
derivation reproduces M3's own shipped values exactly.

## Result

| channel | shared curves before | after |
|---|---|---|
| `emphasized-in` | 5 of 6 styles shared one | **none — every style distinct** |
| `emphasized-out` | 5 of 6 styles shared one | **none — every style distinct** |

Live state re-rendered and verified under `snappy` (emphasized-in became
`[0.1, 0.9, 0.4, 1.0]`, its own curve, not the shared base), then restored to
`zen`.
