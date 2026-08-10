# TOKEN-06 Verdict — Spring Physics vs. MD3 Bezier Baseline (Phase 12 Plan 08, D-26)

**Verdict: MD3 bezier baseline retained. Spring physics NOT adopted.**

This is a recorded **no**, not an "inconclusive" — the comparison was built, run, and judged.
Per TOKEN-06's own wording ("adopted only if a human side-by-side comparison judges it better
than the MD3 baseline"), a comparison that returns "no" **satisfies** the requirement; it does
not leave it unmet. See "What this verdict does and does not close off" below for the one
narrower, forward-looking reading this result supports.

## What was compared

`Probe.qml`'s token inspector (built in 12-06) gained a `Spring / MD3` toggle beside its
existing "Replay motion" button, plus a label naming which variant was currently wired to the
row. All three semantic-pair swatches (`standard`, `emphasized-in`, `emphasized-out`) render
either:

- the existing MD3 bezier variant — a `NumberAnimation on x` reading `Motion.<pair>Duration`
  and `Motion.<pair>Easing` (unchanged since 12-06), or
- a new `SpringAnimation` variant — same swatch, same `x` property, same `0 -> 80` range, same
  trigger button; the only variable was the interpolation.

No curve fitting was performed (D-26 forbids it structurally: nothing exports springs to the
bezier targets, so there is no consumer that needs a spring expressed as four control points).
`motion.json`, `motion.sh`, the GTK4 target and the Hyprland target were untouched by this plan.

## The spring parameters actually used

```
spring: 300
damping: 20
mass: 1
```

These were **tuned by feel, not against a specification**. 12-RESEARCH.md's Assumptions Log
(A1) could not confirm Material 3 Expressive's official spring-physics constants from any
primary source — `androidx`'s `MotionScheme.kt` exact spring values were not retrievable through
any tool available during research. Separately, QML's `SpringAnimation` uses a physical
spring-constant parameterisation (`spring`/`damping`/`mass`) that is not the same parameterisation
Compose uses (`stiffness`/`dampingRatio`) — there is no 1:1 numeric port between the two even if
Compose's reference values had been available. The 300/20/1 starting point was RESEARCH's own
"tunable-by-feel" recommendation (spring in the low hundreds, damping in the mid-teens to
mid-twenties for a default, non-bouncy feel), not a verified MD3 value.

## The human's reported judgement

The side-by-side was run interactively: the toggle was flipped back and forth several times
against the same three swatches, motion axis confirmed at `normal`.

**User's verdict, verbatim:**

> MD3 is better. Spring is too fast

**Adoption call:** MD3 bezier baseline retained. Spring physics NOT adopted.

## Reading the verdict: tuning symptom, not a mechanism rejection

The stated reason is that the spring read **too fast** — not wobbly, not badly-settling, not
"springs are wrong for this kind of surface in principle." That is a tuning symptom, not a
mechanism one. Combined with the parameter provenance above, two facts sit together here:

1. The tested spring instance (`spring: 300, damping: 20, mass: 1`) was rejected by human
   judgement for reading too fast.
2. Those parameters were tuned by feel because Material 3 Expressive's official spring
   constants could not be confirmed from any primary source, and QML's spring parameterisation
   differs from Compose's anyway — so there was no principled target to tune toward in the
   first place.

The honest conclusion those two facts support is narrower than "spring physics is worse than
bezier for this pipeline." It is: **this particular, unsourced guess at spring parameters was
judged worse, and the project currently has no sourced basis on which to tune a better one.**
Overstating this into a general verdict against spring physics as a mechanism would misrepresent
what was actually tested; softening it into "inconclusive" would misrepresent that a clear
adoption call was in fact made and recorded.

## What this verdict does and does not close off

- **Does not adopt springs anywhere.** No other surface's animation changed because of this
  plan, and nothing in Phase 12 or later depends on this outcome (standing constraint 5,
  D-26). Phase 14's dashboard drawer builds on the MD3 bezier baseline like everything else in
  this pipeline.
- **Does not bar a future revisit.** If a primary source for Material 3 Expressive's spring
  constants ever surfaces (a confirmed `androidx` `MotionScheme.kt` value, or an equivalent
  authoritative reference), a future phase is free to re-attempt this comparison with a
  principled target instead of a feel-tuned guess — the toggle instrument built for this plan
  is retained (see 12-08-SUMMARY.md) specifically to make that re-attempt cheap.
- **Does bar re-rolling the same guess.** Retuning `spring`/`damping`/`mass` by feel again,
  without a sourced target, would just be repeating this exact experiment and should not be
  expected to produce a different, more defensible answer than this one did.

## Bound, restated

This verdict is a recording, not a mandate. Adopting spring physics anywhere is later-phase
work, contingent on a sourced target existing — not a default outcome of this plan closing.
No phase or requirement was ever allowed to depend on TOKEN-06's answer, and none does.

---
*Phase: 12-unified-design-token-pipeline*
*Plan: 08*
*Recorded: 2026-07-27*
