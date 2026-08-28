---
quick_id: 260829-prc
title: Add the Precise style — constant velocity, symmetric in and out
status: complete
completed: 2026-08-29
commits: [15c07425]
operator_decision: "Build D. Precise — chosen from rendered curves"
gates: "motion-lint 811/0; --self-test 12/12; hypr-equivalence 3/0 per style; quickshell-doctor 28/0; colour-lint 572/0; keybind-doctor 13/0"
---

# 260829-prc — SUMMARY

## Two empty axes, not one

Picked the way `gravity` was — by measuring the gap, not choosing a mood.

**Shape.** Every other style is a curve that decelerates. Not one moves at a
constant speed, which is exactly why `linear` and `css-linear` sat in the base
easings table used by **zero** styles.

| style | covers by t=10% |
|---|---|
| md3 | 62% |
| snappy | 51% |
| bouncy | 41% |
| zen | 32% |
| **precise** | **10%** |
| gravity | 1% |

**Symmetry.** Every other style is slow-in/fast-out:

| style | in | out | ratio |
|---|---|---|---|
| bouncy | 450 | 150 | 3.00 |
| md3 | 400 | 200 | 2.00 |
| snappy | 200 | 100 | 2.00 |
| gravity | 550 | 300 | 1.83 |
| zen | 500 | 350 | 1.43 |
| **precise** | **250** | **250** | **1.00** |

Nothing else in the set enters and leaves in the same time.

## Curve

`[0.12, 0.12, 0.88, 0.88]` rather than a true linear `[0, 0, 1, 1]`: a true
linear starts and stops with infinite jerk and reads as cheap rather than
deliberate. This holds constant velocity across the middle and rounds only the
two ends.

## Uniformity is the identity

Every easing name is the same curve; every Hyprland leaf the same speed. The
statement is that **no channel is treated more dramatically than another** —
which is also why the emphasized pair needed no separate thought: the 260829-wvy
derivation (emphasized = the spatial pair clamped into `[0,1]`) returns the same
curve here, there being no overshoot to clamp.

Its leaves deliberately carry **no `style` key**. A style's leaf entry replaces
the base entry wholesale, so omitting it drops base's `popin 60%` and takes
Hyprland's own plain default — undecorated, which is the point.

## Token band renumbered while it was one commit old

Appending `micro5 = 70` and `extra-long6 = 1100` left the bands out of magnitude
order (45/60/80/100/**70**) — a smell a future contributor would trip on. Bands
now ascend properly:

- `micro` 45 / 60 / **70** / 80 / 100
- `extra-long` 700 / 800 / 900 / 1000 / **1100** / 1200

`bouncy` and `gravity` were repointed to their **unchanged values** under new
names. No style's timing moved; verified by re-rendering all six.

## The set now

| style | signature |
|---|---|
| md3 | M3 reference, monotonic, default and fallback |
| snappy | shortest (100–200ms), slight overshoot |
| bouncy | the visible arc (peak 1.097) |
| gravity | weight — starts at 1%, exits accelerating |
| **precise** | **constant velocity, the only symmetric in/out** |
| zen | longest, the only multi-segment curves, Caelestia port |

All six render with zero `configerrors` and pass `hypr-equivalence` 3/0
individually — the first time every style has been verified against the
baseline rather than just the active one.
