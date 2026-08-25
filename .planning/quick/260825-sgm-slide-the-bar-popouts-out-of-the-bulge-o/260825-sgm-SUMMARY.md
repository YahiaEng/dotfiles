---
quick_id: 260825-sgm
date: 2026-08-25
status: complete
description: Slide the bar popouts out of the bulge on the dashboard motion, and clear two stale bookkeeping items
commits:
  - 1ef21341 docs(planning): close two stale bookkeeping records
  - 3469c7d1 fix(bar): slide the popouts out of the bulge, on the dashboard's motion
---

# 260825-sgm — Slide the bar popouts out of the bulge

## What the operator asked for

> "The reveal and dismissal animations for the right bar panels needs
> adjusting. I want them to be a close copy to the animations of the app
> dashboard and super+space/super-tab. Meaning the animation starts from the
> bulge and the dismissal is a reversal of the spawn animation."

## The scope question was real, and I got it wrong first

"Right bar panels" fits two families, and I offered the operator a choice
between them with a description of the config panels that was **factually
wrong** — I claimed they weld to the right rail and animate on a mismatched
axis. They do not. Measured:

- `PanelDialog.qml:172` — `anchors.top: true`, compositor-centred
- `:341`, `:355` — flares declared `edge: "top"`
- `:236` — `y: opened ? 0 : -panelHeight` on `spatialInDuration`, dismiss on
  `spatialInReverseEasing`

The config panels hang off the **top rail's centre bulge**, which is the
dashboard's own bulge, and they already run the dashboard's two lines with the
dashboard's tokens. They already were the close copy. Nothing to do.

The correction cost nothing here because it landed before any code was written,
but the reason it happened is worth keeping: I read `PanelDialog`'s *flare and
weld* code, saw it welded to a rail, and assumed which rail from the fact that
the bar is on the right. The anchor was four lines away and says `top`.

Live geometry, which settles it (`hyprctl layers`, 1920x1080):

| namespace | xywh | what it is |
|---|---|---|
| `quickshell-bar` | `1838 0 76 1080` | the right vertical slab |
| `quickshell-baredge-top` | `10 0 1850 16` | top rail — dashboard + config panels drop from here |
| `quickshell-baredge-bottom` | `10 1064 1850 16` | bottom rail — the launcher rises from here |

`SectionPopout` is the only family welded to the **right** slab
(`anchors.right: vertical` at `:160`, `margins.right: PopoutController.rootInset`
onto the bulge face at `:829`). It was the whole job.

## The reveal was mine, not the operator's

Round 4 of 260825-pyf replaced a translate with a width reveal — a container
pinned to the bar's rim, width growing from zero, panel pinned inside so it
never moved. My stated reason at the time: as a translate, "the flares ride
along so the weld only arrived in the final frame."

**That reason does not survive contact with the reference.** The dashboard's
own `AttachedCorner` pair rides its panel and lands with it, so the dashboard
has exactly the same late weld — and the dashboard is the surface the operator
holds up as correct. I had diagnosed a property of the reference as a defect
and engineered around it, producing a motion this shell uses nowhere else. The
operator's "close copy" is the correction.

Worth naming as a pattern: **a fix invented to solve a problem the reference
also has is not a fix, it is a divergence.** Check whether the thing you are
about to design around is present in the surface you are copying.

## The change

`spawnClip` stripped to what it is genuinely needed for — the opacity carrier.
`popoutBackground`, `popoutBorderClip`, both `AttachedCorner` flares and
`content` are **siblings** of `panel` anchored to it, not children of it, so
they do not inherit `panel`'s opacity; this container is their only common
parent. Its `width`, `Behavior on width` and `clip` are gone. Keeping it in
place also avoids re-parenting six children back out through the interleaved
root-level `readonly property` declarations — the move that was caught by an
assertion before it wrote in round 4.

The slide moved onto `panel.x`:

```qml
x: popoutWindow.opened || !popoutWindow._slideFromBar ? 0 : popoutWindow.panelWidth
```

Positioned, not anchored and not transformed. Not anchored because an
`anchors.right` overrides `x` and would have made the slide inert — and it
bought nothing, since the surface's `implicitWidth` **is** `panelWidth`, so
`x: 0` already seats the panel flush against the rim. Not transformed because
the flares are siblings anchored to `panel.right`/`panel.top`/`panel.bottom`:
anchors track real geometry, a transform does not, so `x` carries the flares
while a `Translate` would have slid the panel out from under two flares left
standing at the bulge. (`Launcher.qml` may use a `Translate` because its
background *fills* its panel — it has no sibling to strand. That asymmetry is
why the two references differ, and it is not a style choice.)

**Distance is `panelWidth`, the panel's own width, never the surface's.** This
is `Launcher.qml:612`'s rule, quoted there verbatim: *"never derive a
layer-shell surface's entrance geometry from that surface's own height. Anchor
to the edge and animate a TRANSLATION whose distance depends only on the
panel's own height."* Layer surfaces are configured in stages, so a
surface-derived distance tracks a value that keeps growing and drags the panel
long after it has opened.

## The construction-time trap, guarded rather than dodged

This file has now been bitten twice by the same shape, and both times it was
the **closed** value:

| round | closed value read at construction | symptom |
|---|---|---|
| 3 | `triggerCentre`/`vertical` for the bulge root | all eight popouts stacked at the top of the bar |
| 4 | `_slideFromBar` for the closed width | width ran 360 → 0 → 360, panel simply appeared |

`PopoutTrigger.qml:173-175` assigns `vertical`, `pinned` and `triggerCentre`
**after** construction; `attached` arrives by Binding. So `_slideFromBar` is
`false` at construction no matter what it settles to, and the closed state is
the one moment it is guaranteed wrong.

Round 4's answer was to make the closed value unconditional. That works but it
is a dodge — it means the closed state can never depend on posture at all,
which here it must (attached slides on `x`, unattached drops on `y`).

`Launcher.qml`'s arm guard is the real answer, adopted whole: `_armed`,
`_armAndOpen()` arming one tick before the flip, a 60ms `armSettleTimer`, and a
500ms `armHardStop`. While disarmed every entrance Behavior is disabled, so the
offsets **snap** rather than animate and the panel simply waits off-view at
whatever they resolve to.

**One half is not in the launcher and had to be added.** The launcher branches
its direction on a property the shell root owns; this file's comes from the
loader. So `_slideFromBar` restarts the settle timer too:

```qml
on_SlideFromBarChanged: if (!popoutWindow.opened) armSettleTimer.restart()
```

Without it a late `vertical` or `attached` could land *after* the arm and
animate the wrong axis — the exact hole a size-only guard leaves.

The entrance cascade moved from `Component.onCompleted` into `_armAndOpen`.
It used to sit one `Qt.callLater` ahead of the open flip, near enough to
simultaneous not to matter; the flip now waits for the settle, so leaving the
cascade behind would have played the first band's fade while the panel was
still off-view.

## Dismissal needed no change

Already correct for the new motion: `_dismissing` is set **before** `opened`
flips (so the first exit runs the mirrored curve, not the entrance one), both
axes read `spatialInReverseEasing`, opacity reads `emphasizedInReverseEasing`,
and `exitHold` is already `max(spatialInDuration, emphasizedInDuration)`. The
reversal costs nothing extra because the closed offset is the same value in
both directions — the point-reflected curve retraces whichever path the
entrance took.

## Gates

Static gates, once each, all green:

| gate | result |
|---|---|
| `colour-lint` | 365 / 0 |
| `motion-lint` | 552 / 0 |
| `settings-index-check` | 121 / 0 |
| `keybind-doctor` | 13 / 0 |
| `hypr-equivalence-check` | 3 / 0 |

`qmllint SectionPopout.qml` exits 0. The exit code is the only channel — it
prints nothing either way — so it was calibrated against a positive control
(a deliberately unbalanced file exits 255) and against `Dashboard.qml`, which
is untouched, known-working, and also exits 255 from unresolved-import noise.
That last one is why 0 on the edited file is the meaningful reading and 255
alone would not have been.

## `quickshell-doctor` KILLED THE SESSION — do not run it from an agent shell

Exit 137, Hyprland down, second session lost today.

**It is not a static gate.** `quickshell-doctor:1590` runs
`systemctl --user restart quickshell.service`, and it also summons live
surfaces (`qs ipc call panel open wifi`, `qs ipc call overview toggle`,
`hyprctl dispatch`) and takes a `grim` capture.

The standing rule "never restart quickshell from the agent shell" already
covered this — transitively. I read it as being about typing the restart
myself and did not check whether a gate I was invoking did it internally.
**A wrapper inherits the hazard of everything it calls**; grep an unfamiliar
gate for `systemctl`, `grim`, `qs ipc call` and `hyprctl dispatch` before
running it. Recorded to project memory.

The other five gates in that directory are pure file readers and are safe.

## Outstanding — operator only

- **`quickshell-doctor`** (28 checks) has not been run against this change.
  It must be run by the operator, not from here.
- **The motion has not been seen.** It is code-evident and parse-clean, but no
  live verification was possible: `hyprctl monitors` reports the output as
  `FALLBACK`, i.e. the display is asleep, and layer surfaces render black in
  that state. `grim` cannot be raced against a 500ms animation anyway
  (~150ms per capture), so if it needs measuring the channel is the shell's
  own `console.log` in `~/.cache/quickshell.log`.
- What to look for: a popout should **emerge leftward out of the bulge**
  rather than grow, and retract back into it on the mirrored curve with a
  brief recoil at the start of the exit — that recoil is the entrance
  overshoot played backwards, not a defect.
