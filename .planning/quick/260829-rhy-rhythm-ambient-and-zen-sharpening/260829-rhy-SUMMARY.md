---
quick_id: 260829-rhy
title: Per-style rhythm and ambient; sharpen md3 against zen
status: complete
completed: 2026-08-29
commits: [d1841e98]
gates: "motion-lint 811/0; --self-test 12/12; hypr-equivalence 3/0 under ALL styles; quickshell-doctor 28/0; colour-lint 572/0; theme-doctor 1575/0"
---

# 260829-rhy — SUMMARY

## How the axes were found

Not by brainstorming. By asking, for every lever in `motion.json`, **which ones
has no style ever touched?** Three levers came back untouched by all five
styles: `stagger-offset`, `ambient`, and the `linear`/`css-linear` easings (the
last became 260829-prc).

## 1. Rhythm — the biggest unexploited axis

`stagger-offset` was **50ms in every style and had never been varied** — yet it
is consumed by 11 files plus the shared `Cascade` primitive: the whole lock
screen, power menu, overview, dashboard panels, settings pages, screensaver.

Every style animated each element with its own personality, then choreographed
them all identically. The 7-band dashboard's last band started 300ms behind the
first in all five styles.

| style | stagger | 7-band dashboard: last band starts |
|---|---|---|
| snappy | 45ms | 270ms behind |
| md3 | 50ms | 300ms behind (unchanged reference) |
| zen | 60ms | 360ms |
| bouncy | 80ms | 480ms |
| gravity | 100ms | 600ms |

### This needed new duration tokens

M3's scale starts at `short1` = 50ms — too coarse for five distinct cascade
rhythms when only 50/100/150 are available. `micro1..4` extend the scale below
`short1`.

**45 and not 40 for the tightest:** `floor_ms` IS 40 and every duration is
clamped up to it (`if $scaled < $floor then $floor else $scaled end`), so a
40ms token would be indistinguishable from the floor itself *and* would stop
scaling under the accessibility multiplier. Checked first: nothing in code or
any gate hardcodes duration-token names, only planning docs.

## 2. Ambient — and the coupling it exposed

Also 1000ms in all five. Now 700–1200.

Setting it per style took `hypr-equivalence` from 3/0 to **2/1**, on exactly one
record:

```
leaf record 14 (name='border'): baseline speed=10.0  live speed=12.0
```

Hyprland's `border` leaf read `tokens.motion.speed.ambient` directly in
`animations.lua`. But **`ambient` is a loop period** for continuous QML motion
(breathing, pulsing) and **the border leaf is a one-shot focus-change
transition** — two different things sharing one token. Harmless while every
style used 1000ms; a gate failure the moment the token became per-style.

**Decoupled rather than waived.** The border transition now has its own
`indicators` entry — styles cannot override `indicators` — and keeps the 1000ms
the baseline pins, while `ambient` becomes QML-only, which is what it was always
for. `hypr-equivalence` is now 3/0 under *every* style, where before this task
it was only ever verified under one.

## 3. Sharpening md3 against zen

The operator asked how unique md3 and zen are. Answer: distinct in character —
md3 is the only fully monotonic style (peak 1.000) while zen has the second
biggest overshoot (1.092); md3 front-loads hardest of all (62% by t=10%) and zen
least (32%); zen is the only style on a multi-segment curve.

But 260829-grv had given md3 smooth's durations, and smooth happened to match
zen on **4 of 8 channels** (`standard-slow`, `emphasized-in`, `emphasized-out`,
`colour`). Half of zen's timing signature had stopped contributing.

**Resolved on md3's side, not zen's.** Zen's durations are an exact port of
Caelestia's `tokens.hpp` (`normal` 400, `large` 600, `small` 200,
`expressiveSlowEffects` 300) — the reference wins, so zen was not touched. md3
moved to 500/350/150/250.

md3 and zen now differ on **all 10 channels**. Residual across the whole set is
minor and in pairs that differ hugely in curve character: md3/bouncy share 2 of
10, gravity/zen share 1.

## Trap repeated — a `_comment` string inside an iterated table

`lib/motion.sh` renders `indicators` with `to_entries[] | $v.duration_ms`, so a
`_comment` **string** among the objects breaks the renderer. The file already
warns about exactly this for `semantic`; it is equally true for `indicators`,
and I hit it there. The tell is an empty rendered `motion.json` and a border
speed of `0.0`. Comments belong at the level *above* any table that gets
iterated.
