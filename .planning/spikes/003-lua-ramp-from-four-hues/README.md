---
spike: 003
idea: themed-nvim
name: lua-ramp-from-four-hues
type: standard
validates: "Given the 9-role matugen palette, when Lua derives a syntax ramp at load time, then 8+ token types are distinguishable across dark, light and Material You palettes"
verdict: VALIDATED
related: [001, 002]
tags: [nvim, theming, palette, colour, contrast, accessibility]
---

# Spike 003: Deriving a Syntax Ramp From Four Hues

## What This Validates

**Given** the 9-role matugen palette, **when** Lua derives a syntax ramp at load
time, **then** ten token types are distinguishable and readable across dark,
light and wallpaper-driven palettes.

The roles carry roughly four real hues plus greys. Syntax highlighting wants ten
colours you can tell apart at a glance. matugen templates cannot do colour
math — but the nvim colorscheme is Lua, so it can.

**Visual result:** https://claude.ai/code/artifact/d41819ca-15f4-4c95-a5c8-883d112a9807

## How to Run

```
nvim -l check.lua             # all 20 palettes    -> results.json
nvim -l calibrate-metric.lua  # what the numbers mean
python3 make-preview.py       # rebuild preview.html
```

## The Palette Range Being Tested

20 palettes, **5 light and 15 dark**, spanning `vantablack` (pure `#000000`,
luminance 0.0) to `rosepine-dawn` (0.96). Anything that works across that range
works.

## Investigation Trail

**1. First ramp: 12/20 — and the score was meaningless.**

Initial approach: map roles to slots, rotate hues for the ones the palette does
not have, then push lightness until each clears a contrast floor. Scored 12/20
against a separation threshold of 40.

**That 40 was invented.** Before trusting it, the metric got calibrated against
colours whose answer is already known:

```
pure red vs pure green                        650.0
gruvbox red vs green                          245.4
gruvbox yellow vs orange (adjacent, usable)   123.2
gruvbox blue vs aqua (its TIGHTEST real pair)  86.9
two near-identical greys (unusable)             4.7
identical                                       0.0
```

A hand-tuned scheme's closest pair scores **87**. A threshold of 40 was roughly
half that — so "12 passing" meant twelve palettes cleared a bar that does not
mean legible. Threshold moved to **70**, and the honest score of the first ramp
was worse than reported.

This is the same class of error as verifying the wrong axis: the criterion was
true, measured, and reported — and still answered nothing.

**2. Why the failures failed.** `vantablack` scored **0** on keyword/constant.
The cause is structural: `spin` preserved saturation, and rotating the hue of a
fully desaturated colour does nothing at all. `matte-black` showed the same at 5.

**3. Second ramp: saturation floor, monochrome mode, repair pass.** Hue spins
gained a saturation floor so they land somewhere; palettes with no usable hue got
a separate lightness-based path; and a repair pass nudged the closest pair apart
until everything cleared the bar. **18/20 at the honest threshold of 70.**

The repair was then improved to try several candidate moves and keep whichever
lifted the worst pair most, rather than always spinning a fixed amount — and to
stop honestly when nothing improves rather than looping. nord 43 → 60,
vantablack 6 → 30.

**4. Operator decision: monochrome themes stay monochrome.**

vantablack could have been forced to clear the bar by injecting saturation — but
that destroys the reason someone picks a pure black-and-white theme. Operator
decision (2026-08-20): **keep it monochrome, separate tokens with bold and
italic instead.**

First attempt at this scored 60: `keyword` and `fn` sat on different brightness
steps but were **both bold**, and near the top of the range there is no
luminance headroom left for two bold slots one step apart to stay distinct.

The fix was to make every slot a unique **(tier, attribute)** pair, with
same-attribute slots at least a tier apart:

```
dim    3.5   comment  italic        operator  -
mid    8.0   variable -             string    italic
             number   bold          constant  bold italic
bright 19.0  err      -             type      italic
             keyword  bold          fn        bold italic
```

`vantablack` went **30 → 60 → 186**, and stayed genuinely monochrome:

```
comment  #636363 italic      err      #f2f2f2 -
operator #636363 -           type     #f2f2f2 italic
variable #a1a1a1 -           keyword  #f2f2f2 bold
string   #a1a1a1 italic      fn       #f2f2f2 bold italic
number   #a1a1a1 bold
constant #a1a1a1 bold italic
```

The checker was updated to match: two slots differing in bold/italic are
distinguishable even when their colours are close, so those pairs no longer count
as collisions.

## Results

**VALIDATED — 19 of 20 palettes.**

Contrast is met everywhere: every slot clears 4.5:1 against its own background
(3.0:1 for comments and operators, which are meant to recede). The light/dark
split is handled by one code path, because the lightness walk moves *away* from
the background whichever side it starts on.

**The one that does not clear the bar: `nord`, at 60 against a threshold of 70.**
Not a bug. nord is deliberately low-contrast and tightly hued — its roles are all
cool blues and greens, so there is little hue space to spread into. Forcing
saturation would cost exactly the character that keeping vantablack grey
preserves. Options if it matters later: accept nord as a deliberately soft
palette, or give its tightest pair an attribute the way monochrome palettes do.

**Carried into the build:**

1. The colorscheme derives its ramp in Lua at load time. matugen only ever writes
   the ~9 role colours — it never needs to know about syntax slots.
2. Monochrome palettes are detected (max role saturation < 0.20) and separated by
   brightness tiers plus bold/italic, never by injected hue.
3. Any separation threshold must be calibrated against a real scheme. 70 comes
   from gruvbox's tightest pair at 87; it is not a guess.
4. Comments get italic by convention in every palette, not just monochrome ones.

**Minor gotcha noted:** an empty Lua table serialises to a JSON *array*, not an
object, so `attrs` entries with no flags come back as `[]` when round-tripped
through JSON. Irrelevant for the real build — the palette stays in Lua — but it
bit the analysis scripts here.
