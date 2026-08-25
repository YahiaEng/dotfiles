---
quick_id: 260825-t6j
date: 2026-08-25
status: complete
description: Reveal the popout solidly from behind the bar and size the bulge to its panel
commits:
  - 2ea71b9f fix(bar): reveal the popout solidly, and size the bulge to its panel
---

# 260825-t6j — Reveal it solidly, and size the bulge to its panel

## The measurements both fixes came from

One `popout:` line and one `barbulge:` line out of `~/.cache/quickshell.log`,
plus `hyprctl layers`. No screenshots — the display sleeps into `FALLBACK` and
`grim` cannot be raced against a 500ms animation at ~150ms per capture.

```
popout: section=media attached=true vertical=true triggerCentre=1002
        rootCentre=1002.0 rootInset=8.0 panel=360x281 margins=[t 838.0, r 8.0]
barbulge: depth=14.0 visible=true weld=true anyOpen=true span=865..1140
```

| quantity | value |
|---|---|
| panel along-axis extent | **281** (screen 862..1143) |
| bulge span | **275** (865..1140) |
| shortfall | **6 = 2 × `edgeBarFilletRadius`** |
| slab flat face / popout right edge | 2502 |
| slab outer edge | 2554 |
| bar layer level / popout layer level | **2 (top) / 3 (overlay)** |

## Point 1 — the geometry was already right; the fade was the defect

> "I want the spawn and dismissal animation to feel like it is extending from
> the bar. Make it so that the panel spawn from behind the bar."

The closed panel already sits one full `panelWidth` right of open, entirely
outside a surface whose right edge is pinned to the slab's flat face at 2502,
so it is wholly hidden and the surface boundary cuts it as it travels. That is
a drawer.

**What contradicted it was `spawnClip.opacity: opened ? 1 : 0`** — the panel
faded across the whole slide, so a solid object emerging from behind a solid
bar was translucent the entire way out. An edge reveal and an opacity ramp are
two transitions doing the same job; the second is what reads as "appearing
beside the bar" instead of "extending from behind it".

Opacity is now `1` while attached. Unattached it stays, and the split is
principled rather than a special case: on that path there is no occluder at all
(the panel drops from the top of the Hyprland windows onto open desktop), so
the fade is the only thing easing it in. `Dashboard.qml` fades for exactly that
reason — it slides from off-screen with nothing behind it to be revealed from —
so this is not a departure from the reference.

### What is NOT possible here, recorded because it looks like the obvious fix

**The bar cannot occlude the popout.** Popout on overlay (3), bar on top (2).
Demoting the popout to level 2 does not help either: within a level wlroots
stacks by creation order, and the popout is built per summon, so it would still
land above a bar that has existed since shell start. Anything lower puts it
under application windows.

**The surface cannot reach behind the bar's body.** `Bar.qml:613-621` already
measured this: margins are subtracted from the **usable area**, not the screen
edge, so `ExclusionMode.Ignore` does not opt out of the bar's own 50px
reservation on this build — `margins.right: 72` landed the edge at 2438
(= 2510 − 72), not 2488. The popout's right edge is pinned at 2502 and the 52px
behind it are unreachable.

So the bar's face *is* the reveal line, and always was. Only the fade needed
removing.

## Point 2 — the bulge was 6px short, and the inset that caused it is gone

> "The bulge width is wrong. It needs to be the same width of its corresponding
> panel."

Correct, and exactly `2 × edgeBarFilletRadius`. Round 4 of 260825-pyf
subtracted it for a real reason: `buildOutline` draws each concave shoulder
**outside** the span it is handed (`edgebarpath.js:186-196` — the flat run
travels to `xr + f` before filleting back to `xr`), so a span at the panel's
extent overshot the panel by `f` at both ends, and in that band the flare's
quarter-pipe fill does not reach — the bulge showed through as a square tab of
bar-coloured pixels, confirmed then by controlled comparison (~606 rim blue vs
132-139 background with the bulge forced off).

That inset made the bulge's total **footprint** match the panel
(275 + 2×3 = 281) while its visible **face** stayed short. The shortfall is the
defect; the trade was the bug.

**Fixed by removing the cause instead of paying for it:** the popout bulge's
own `buildOutline` call now passes `f: 0`. With no shoulder, nothing is drawn
outside the span at all, so the face can be the panel's exact extent *and*
nothing overshoots it. The concave blend is not lost — the popout's two
`AttachedCorner` flares already weld precisely those corners, which is what
they exist for, and a clean butt at the panel's edge is the joint their
quarter-pipes are built to sweep into.

`f` is a per-call parameter (`Bar.qml:893`), so the rails and the static centre
bulge keep `Design.edgeBarFilletRadius` untouched. **The two terms are one
decision**, and the code now says so: any future change restoring a non-zero
`f` on that call must restore the `- edgeBarFilletRadius` term with it.

**`f: 0` was checked in the solver, not assumed.** `_arcCentre`
(`edgebarpath.js:56`) is pure midpoint arithmetic with no division, so
coincident endpoints return that point and `_shoulderSweep` matches the
expected centre exactly — no NaN, no wrong flag. `A 0 0 …` with identical start
and end is omitted per the SVG arc spec rather than being degenerate. Design's
`edgeBarFilletRadius + edgeBarBulgeCornerRadius <= edgeBarBulgeExtra` invariant
holds trivially at 0 + 1 <= 14.

The round-4 comment block arguing for the inset was rewritten rather than left
to contradict the code it sits above.

## Gates

| gate | result |
|---|---|
| `colour-lint` | 365 / 0 |
| `motion-lint` | 552 / 0 |
| `settings-index-check` | 121 / 0 |
| `keybind-doctor` | 13 / 0 |
| `hypr-equivalence-check` | 3 / 0 |
| `qmllint` | 0 on `SectionPopout.qml` and `Bar.qml` |

Shell hot-reloaded clean — `Configuration Loaded` with no error from either
file. (The `NotifCentre.qml:1092` missing-image warning is pre-existing and
unrelated.)

**`quickshell-doctor` was not run.** It restarts quickshell at line 1590 and
killed the session earlier today; it is operator-only from here.

## Outstanding — operator

- **The bulge width is verifiable from the log without a screenshot.** Open the
  media popout and read the `barbulge:` line: it should now report
  `span=862..1143` (extent 281), against `865..1140` (275) before.
- **The tab is the risk to watch.** If a small bar-coloured tab reappears beside
  a flare's arc, `f: 0` did not fully remove the outside-the-span drawing. Named
  fallback: restore the `- Design.edgeBarFilletRadius` inset, which trades the
  width back.
- **`quickshell-doctor`** still unrun against these changes.
