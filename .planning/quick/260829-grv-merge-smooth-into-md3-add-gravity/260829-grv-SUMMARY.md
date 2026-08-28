---
quick_id: 260829-grv
title: Fold smooth into md3; add the Gravity style
status: complete
completed: 2026-08-29
commits: [e298c34b]
operator_decision: "Combine smooth+md3 (keep md3's curves, take smooth's timing); build Gravity"
gates: "motion-lint 811/0; --self-test 12/12; hypr-equivalence 3/0; colour-lint 572/0"
---

# 260829-grv — SUMMARY

## Part 1 — the merge

**Operator:** "Smooth and md3 feel too similar. Combine them."

Correct, and the measurement names the mechanism rather than just agreeing:
**md3 and smooth were the only two monotonic styles in the set.** Both peak
exactly 1.000; every other style overshoots. So they shared one entire
personality niche, and the only thing separating them was tempo — md3 ran
50–100ms faster on *every single channel*:

| channel | md3 | smooth |
|---|---|---|
| standard | 200ms | 250ms |
| spatial-in | 300ms | 400ms |
| spatial-out | 150ms | 200ms |
| spatial-move | 200ms | 250ms |
| colour | 200ms | 300ms |

That is a speed dial wearing two names — precisely what 260821-swp set out to
abolish when it replaced the motion-scale duration multiplier with
style-as-personality. The dial had grown back *inside* the style axis. This is
the same class of finding as 260829-wvy's: a style that is a neighbour plus an
offset is not a style.

**md3 is the survivor** because it is `MOTION_DEFAULT_STYLE`, the fallback
target for any invalid persisted value, and the reference the other styles'
derived emphasized pairs are validated against.

Per the operator's call it keeps its **curves** (`easings` stays `{}` — still
untouched M3 spec, so 260829-wvy's derivation anchor survives) and takes
smooth's **durations**.

### The leaves came for free, and that was worth checking first

I was about to hand md3 a full `hypr_leaves` block copying smooth's speed keys.
Reading `motion.sh` first showed that was unnecessary: **`speed_key` absent means
"use the leaf's own curve name" as the speed name.** md3's `windows_in` has
curve `spatial-in` and no `speed_key`, so it now reads `spatial-in`'s new 400ms
automatically. md3 still overrides zero leaves — structurally simpler than
smooth was, and one less thing to keep in sync.

## Part 2 — Gravity

**Operator:** "If you have any ideas on a unique animation style suggest it."

Rather than pick a mood, I measured which axis the set left **empty**. How much
distance each style covers in the first 10% of its move:

| style | covers by t=10% |
|---|---|
| md3 | 62% |
| snappy | 51% |
| smooth | 44% |
| bouncy | 41% |
| zen | 32% |
| **gravity** | **0.8%** |

Every existing style front-loads. **Nothing in the set starts gently** — so
nothing in the set has weight. That was the gap.

### Curves

```
spatial-in    [0.7, 0, 0.65, 1.15]   peak 1.0135   0.8% by t=10%
spatial-out   [0.6, 0, 0.9, 0.3]     accelerates away — no other style does
spatial-move  [0.7, 0, 0.6, 1.08]    peak 1.0042
standard      [0.65, 0, 0.35, 1]     monotonic
effects       [0.5, 0, 0.4, 1]       monotonic
emphasized-*  = clamp(spatial pair)  per the 260829-wvy derivation
```

### Two things that had to be measured, not assumed

1. **The landing is a thud, not a bounce.** Peak 1.0135 (+1.4%) sits just under
   zen's 1.014 and far below bouncy's 1.097, because mass settles rather than
   springs.
2. **Getting a perceptible settle at all required moving the overshoot late in
   the curve.** A slow start damps a trailing overshoot enormously: the obvious
   first draft `[0.75, 0, 0.25, 1.10]` peaks at only **1.0064**, effectively
   invisible. `x2` had to go from 0.25 to 0.65 before the settle registered.
   Found by searching the curve space against two constraints (slow start,
   target peak), not by eyeballing.

## Result

Five styles, each holding an axis nothing else holds:

| style | signature |
|---|---|
| md3 | M3 reference, monotonic, the default and fallback |
| snappy | shortest (100–200ms), slight overshoot |
| bouncy | the visible arc (peak 1.097) |
| **gravity** | **the only one with weight — starts at 0.8%, exits accelerating** |
| zen | longest, the only multi-segment curves |

Window-open duration remains unique across all five: 400 / 200 / 450 / 550 / 500.
Every style cycled live with zero `hyprctl configerrors`. Left on `gravity` for
the operator to judge.
