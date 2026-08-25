---
quick_id: 260825-x9p
date: 2026-08-25
status: complete
description: Spawn the popouts from behind the bar — layer swap plus a surface that reaches under it
commits:
  - fa3fdb15 feat(bar): spawn the popouts from behind the bar, for real
---

# 260825-x9p — Spawn the popouts from behind the bar

Operator, after I said it could not be done: **"Yes, do it anyway."** It can.
Two separate blockers, each of which I had diagnosed too shallowly.

## Blocker 1 — moving the bar up shifted it, and the fix was to move the rails too

Bar to Overlay with the rails left at Top came back `2478 6 76 1428` instead of
`2478 0 76 1440`: at a higher level it is arranged *after* the Top-level rails
and inherits their 6px reservations, which breaks the Continuous weld. That is
what I reported as fatal.

**Surfaces in the SAME level do not reserve against each other.** Moving the
rails up with the bar restores the baseline exactly:

| surface | before | after |
|---|---|---|
| `quickshell-bar` | `2478 0 76 1440` | `2478 0 76 1440` |
| `quickshell-baredge-top` | `10 0 2490 16` | `10 0 2490 16` |
| `quickshell-baredge-bottom` | `10 1424 2490 16` | `10 1424 2490 16` |
| `reserved` | `0 6 50 6` | `0 6 50 6` |

No separate reserving surface was needed after all — `Bar.qml:88`'s "one
surface cannot do both" still holds, it just never had to be worked around.

## Blocker 2 — `exclusiveZone`, not `ExclusionMode.Ignore`

`Bar.qml:613` blames `Ignore` for margins measuring from the usable area. The
real cause is that an **explicit non-negative `exclusiveZone` overrides the
Ignore mapping**, so the surface keeps being placed inside every other
surface's zone. Measured both ways with `margins.right: 0`:

| `exclusiveZone` | resulting right edge |
|---|---|
| `0` | 2510 — the usable boundary |
| `-1` | **2560 — the true screen edge** |

The popout now runs `-1` **while welded**, anchors to the slab's OUTER edge
(`rootOuterInset`) and widens by the slab's width (`rootSlabWidth`), so its
surface spans `2142..2554` and the closed panel sits genuinely behind the bar.
Unattached keeps `0` so that posture does not move.

Both numbers come from the bar's live geometry, never re-derived from tokens —
this family's whole history of position bugs is second copies of the bar's
arithmetic drifting apart.

### One consequence, and one side effect

`-1` makes every margin screen-relative, so the top rail's reservation moved
**onto the clamp bound** (`_attachedEdgeMargin`) and out of `openTop`. Every
value downstream is now already screen space and exactly one line can get the
conversion wrong.

Side effect worth naming: bottom-clamped popouts used to hang 12px past the
reserved+gap boundary and now sit inside it — the clock moved `1082..1402` to
`1070..1390`.

## The weld was inverted, and this un-inverts it

`Bar.qml` has always said the bulge *"protrudes OVER the panel, exactly as the
top rail's bulge does over the dashboard"*. With the popout above the bar, the
**panel covered the bulge** — the exact opposite of the documented intent, and
nobody had measured it. After the swap, bar-coloured pixels occupy
**x 2488..2501 across the panel's rows**: the bulge sits on top of the panel
where it was always meant to.

This is probably the largest visible part of the change.

## A regression I chased and disproved

The panel's interior looked like bare wallpaper after the swap, which read as
lost frost. It was not. Comparing **identical pixels** across three captures:

| pixel | original | after `f:0` | now |
|---|---|---|---|
| (2495,200) | (63,62,83) | (76,54,77) | (58,65,87) |
| (2480,200) | (39,41,53) | (39,41,53) | (39,41,53) |

The variation is the accent gradient's animated phase, and (2480,200) reads
wallpaper-like in the **original** capture too. I had compared different x
positions across different gradient phases — the panel background is a
gradient, so that comparison was meaningless.

## Verification

Bulge span against panel span, re-measured after the swap — all match:
resources `50..320`, clock `1070..1390`, media `842..1123`, wifi `1001..1271`,
audio `934..1266`, tray `842..962`.

Gates: `colour-lint` 365/0, `motion-lint` 552/0, `settings-index-check` 121/0,
`keybind-doctor` 13/0, `hypr-equivalence-check` 3/0. `qmllint` 0 on every
edited file except `EdgeBar.qml`, which returns 255 **unmodified at HEAD** as
well (import noise, same as `Dashboard.qml`).

## Known tradeoff

The bar now sits above `quickshell-notif-popups` in the same level. Their
surfaces do not overlap visually today — notifications end at x 2500, the slab
starts at 2502 — but an open bulge reaches 2488 and could clip a
notification's right edge by 12px.

## Outstanding

- Operator judgement of the motion now that the panel is genuinely occluded by
  the bar and the bulge paints over it.
- `quickshell-doctor` still unrun against any of today's changes — it restarts
  the shell and is operator-only.
