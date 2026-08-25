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

---

# Round 2 — the occlusion direction was wrong

Operator: **"the bulge is now on top of the panels"** and **"the spawn/dismiss
animation should start/end from the right edge of the bar respectively. It
currently starts animating from the rightmost edge of the screen."**

## The bulge report invalidates round 1's central move

Stacking the bar above the popout to hide the parked panel **necessarily** put
the bulge on top of the panel too. They are the same surface, and the bulge
protrudes 14px past the slab's face — exactly where the panel's right edge
lives. Whichever surface is on top owns that band.

Round 1 celebrated this as "un-inverting the weld", citing `Bar.qml`'s note
that the bulge "protrudes OVER the panel". **That note describes the intent;
the operator's eye is the authority on the result.** I treated a comment as
evidence of what should be on screen.

So the stacking is back to baseline — bar and both rails at `Top`, popout at
`Overlay` — and the parked panel is hidden by its own **clip** instead.
`spawnClip` is no longer `anchors.fill: parent`: it is the panel's width
pinned to the surface's left, so its right edge lands on the slab's inner face
and it clips there.

| check | result |
|---|---|
| bulge over the panel (x 2488..2501, panel rows) | **none** — panel-coloured, was bar-coloured |
| popout painting over the bar (x 2502..2554, open vs closed) | only the slab's two 4px rims differ, both bar-coloured cyan, differing solely in the accent gradient's phase |

## The start position was one panel-width short

The closed offset was a bare `panelWidth`, which parks the panel's left edge on
the slab's **inner** face. With the surface extended past the bar and nothing
clipping it, the panel then filled the slab's transparent middle — which is why
it read as coming from the screen edge.

It is now `panelWidth + rootSlabWidth`, so the panel parks on the slab's
**outer** edge — the bar's right edge — and crosses the bar unseen behind the
clip before appearing at its face. Both terms are real extents (the panel's own
width, the bar's published slab width), never the surface's resolved width.

## What survived from round 1

The `exclusiveZone: -1` finding and the extended surface both stay — they are
what let the panel park at the bar's right edge at all. The layer swap did not.

Baseline geometry re-confirmed: bar `2478 0 76 1440`, rails `10 0 2490 16`,
`reserved 0 6 50 6`. The notif-popups tradeoff named in round 1 is gone with
the layer revert.

Bulge span equals panel span on all eight: resources `50..320`, wifi
`1021..1291`, audio `954..1286`, clock `1070..1390`, media `862..1143`,
bluetooth `1102..1222`, ethernet `1103..1281`, tray `862..982`.

Gates re-run once each, all green; `qmllint` 0 on both edited QML files.

---

# Round 3 — the dismiss animation was never ours

Operator: bulge fixed, spawn right. **"The dismiss currently animates all the
way to the rightmost edge of the screen. It should stop at the right edge of
the bar."**

## It was Hyprland's layer-close animation, not our exit

`PopoutController.close()` cleared `openSection`, and every trigger's
`LazyLoader` is keyed on exactly that — so the surface was **destroyed on the
first frame** and `SectionPopout.requestDismiss()` never ran. What was on
screen was the compositor sliding the whole surface off the right of the
output, which is exactly what "all the way to the rightmost edge" describes.

The wiring for the animated path already existed — the trigger connects the
surface's `dismissFinished` to the controller — but **every caller reached
`close()` directly**, so that connection could only fire after something else
had already torn the surface down. Esc and focus-loss were the only routes
through `requestDismiss()`: the animation worked exactly where it was least
used.

Same defect class as the config panels earlier the same day. The rule:

> If a surface owns an exit animation, the property its loader is keyed on must
> be cleared by the **end** of that animation, never by the thing that starts
> it.

## The frames lied and the log did not

A `grim` time-series across the dismissal looked like a clean retraction —
leftmost non-background pixel marching 2142 → 2184 → 2337 → 2490. It was an
artifact: the panel's background is a **gradient**, dark at its left edge, so
as the compositor slid the surface away the dimmest columns crossed the
background threshold first and imitated a retraction.

The probe settled it in one reading: **84 x-change frames inbound, ZERO
outbound**, and no `dismiss.begin` line at all. For anything time-varying the
shell's own `console.log` is the instrument; frames are for static geometry.

## The fix

`close()` now only **asks** — a new `dismissAsked` signal the trigger relays to
the loaded surface's `requestDismiss`. `closeNow()` does the teardown and is
reached only from `dismissFinished`. Motion-off still lands there immediately,
since `requestDismiss` emits `dismissFinished` straight away in that case.
`open()` is untouched, so switching popouts stays an instant replace.

| measurement | result |
|---|---|
| exit frames | 83 (was 0) |
| travel | x 0 → 412, screen left **2142 → 2554** = the bar's right edge |
| `dismiss.end` | `panelX=412.0` — exit completes before teardown |
| posture across the exit | `attached`/`vertical`/`slideFromBar` all true, `implicitWidth` 412, `margins.right` 6 — no mid-exit re-layout |
| slab's transparent middle (2506..2549) during dismissal | clean at every sample |

Invariants re-checked: one popout alive at a time, switching replaces
instantly, close tears down to zero, bulge span still equals panel span
(resources `50..320`, clock `1070..1390`, tray `862..982`).

Gates green once each; `qmllint` 0 on all three files.
