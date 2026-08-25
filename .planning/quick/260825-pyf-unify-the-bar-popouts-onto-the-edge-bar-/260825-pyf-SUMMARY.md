---
quick_id: 260825-pyf
slug: unify-the-bar-popouts-onto-the-edge-bar-
date: 2026-08-25
status: incomplete
---

# Unify the bar popouts onto the edge-bar language — SUMMARY

Code complete across all five tasks. **The attached posture has not been seen
yet** — see "What is not verified" below; it is a host limitation, not a
shortcut.

## What shipped

`f1e0cc3f` — rooting, the live window inset, and the IPC seam.
`e7b77e24` — the bulge, the weld, and the motion.

**All eight popouts are one frame**, so this is one frame change plus wiring.
The bar's edge swells into a bulge under the open popout; the panel welds to it
and slides out; with no bar edge to weld to, the panel spawns from the top of
the Hyprland windows.

## The three findings worth not re-deriving

**1. The bulge did not need new geometry.** The slab is a vertical run with pill
caps and a bulge on its inner face — precisely what `edgebarpath.js`'s
`buildOutline` already draws. Reusing it gets the rails' fillet radii, the
golden test's coverage and its derived sweep flags for free. Verified BEFORE
adopting: with `bulge: false` it reproduces `_weldRoundedRect(52, 1440, 26)`
exactly — identical bbox, identical shape, differing only in drawing each cap as
two quarter arcs, which is what keeps every arc inside `_arcCentre`'s
quarter-circle domain. Measured after the swap: slab rims still at 2502–2505 and
2550–2553.

**2. Quickshell's IPC surface is fixed at process START.** Hot reload does not
re-register it. Proven with a positive control rather than inferred from one
failure: a probe function added to the *already registered* `bar` target also
failed to appear, so this is not something about the new handler. The new
`popout` target is therefore correct code that goes live at the next shell
restart. A bare "my new target didn't show up" would have looked like a bug in
the handler.

**3. `reserved` is `[left, top, right, bottom]`.** My first probe assumed
`[left, right, top, bottom]`, "confirmed" itself on the left edge and reported a
34px mismatch on the top. Checking all four edges at once settled it: window edge
= `reserved` + `gaps_out` holds exactly on every edge (0+20=20, 6+20=26,
2560−50−20=2490, 1440−6−20=1414). **A one-edge check would have shipped the
wrong index order.**

## A pre-existing defect found by measuring

`SectionPopout.qml` wrote its own fuse: *"It matches gaps_out by value rather
than by binding — if general:gaps_out changes, this alignment needs revisiting
(a QML surface cannot read it live)."*

It changed. `gaps_out` is 20 now (operator-confirmed intended), `border_size` 0,
clients at `[20,26]`. **Four surfaces align to the window edge and all four are
wrong:**

| File | Has | Should be | Off by |
|------|-----|-----------|--------|
| `bar/SectionPopout.qml` | 10 | 20 | 10px — **fixed here** |
| `Dashboard.qml:330` `drawerTopMargin` | 10 | 20 | 10px — not touched |
| `launcher/Launcher.qml:159` `drawerTopMargin` | 10 | 20 | 10px — not touched |
| `centre/NotifCentre.qml:194` | 13 | 20 | 7px — not touched |

New singleton `modules/WindowInset.qml` reads `general:gaps_out` live and
re-reads on every Hyprland `configreloaded` — which is exactly when it changes,
since `lib/reload.sh` runs `hyprctl reload` on every theme and motion apply and
that re-applies `overrides.lua`, where `gaps_out` lives on this host.

Only `SectionPopout` is wired. **The other three are deliberately left alone** —
they are a real defect but not what was asked for, and moving three panels 10px
unasked is the operator's call. Each is a one-line change to
`WindowInset.insetFor("top")`.

Two parsing shapes were measured, not assumed: `gaps_out` comes back as
`{"css": "20 20 20 20"}` with **no `int` key at all**, `border_size` as
`{"int": 0}`. The first draft guessed a `custom` key with an `int` fallback and
both were wrong.

`border_size` is exposed but NOT folded into `inset`: at border 0 this host
cannot distinguish the two definitions of a window's edge, and the two existing
comments in this tree **disagree** about whether Hyprland's `at` includes the
border. Picking a side on an untestable host is how the hardcoded 13 got there.

## Scope consequence, recorded not assumed

Attached is **Continuous-only**, because outside Continuous the bar paints no
edge at all (`barContent` is a bare `Item`; slab and core are both `visible:
_continuousWeld`). So segmented, halo, brackets and `off` all take the unattached
posture. Only `off` was named in the request; the other three follow from the
same fact.

## What is NOT verified — and why

**The attached popout has never been rendered.** Bar popouts are the only
summonable surfaces in this shell with no IPC target, `hl.dsp.movecursor` is nil
on this build, and `wtype` types into the focused window — so there is no way to
put one on screen from here. The `popout` IPC target added in `f1e0cc3f` fixes
this permanently but needs a shell restart to register, and restarting quickshell
from the agent shell kills the session (standing rule, broken three times).

Verified so far: every file loads with `Configuration Loaded` and no new
warning; the slab is byte-unchanged with no popout open; `reserved` still
`[0,6,50,6]`; all five gates green with no count fallen.

**Operator check, one click:** click any bar capsule (wifi, bluetooth, clock…)
to pin its popout, and leave it open. Then the panel should sit against a shelf
that has grown out of the bar's edge, square-cornered on the bar side, with a
concave flare at its top-right and bottom-right, having slid out leftward. With
the edge bar set to `off` it should instead drop from the top of the windows.

## Gates — once each, all green

| Gate | Result | Was |
|------|--------|-----|
| quickshell-doctor | 28 / 0 | 28 |
| colour-lint | 365 / 0 | 362 |
| motion-lint | 552 / 0 | 549 |
| settings-index-check | 121 / 0 | 121 |
| keybind-doctor | 13 / 0 | 13 |

Counts rose with the new files; none fell.

## Carried

- The three unfixed `gaps_out` consumers above.
- The `popout` IPC target is inert until the next shell restart.
- Horizontal bar: never attached (the weld requires vertical), so popouts there
  keep today's posture with the corrected inset. Not separately exercised.


---

# Round 2 — operator feedback (2026-08-25 evening)

Reported: *"All popouts spawn from the same location which is at the top and far
away from the bar."* Correct, and it was my bug.

## The cause, and the reasoning error behind it

`SectionPopout` published its bulge root from `Component.onCompleted`. But
`PopoutTrigger.qml:173-175` assigns `vertical`, `pinned` and `triggerCentre`
onto the item **after** creating it. At construction all three were still at
their declared defaults, so every popout published a centre of **0**; the bar
clamped that into the slab's straight section, which is one fixed position
regardless of which capsule was clicked.

The reasoning that produced it: *a fresh-per-summon component makes construction
time and summon time the same instant.* That is true, and it is not the point.
The loader's property assignments land **after** construction — being BUILT at
summon time is not being CONFIGURED at construction time.

Now `Binding`s, so a later assignment simply flows through. This does not
reintroduce the hazard the snapshot existed to avoid: the snapshot lives
upstream in `PopoutTrigger._publishedCentre`, and forwarding a snapshot is not
re-measuring it. `openExtent` had a second, independent reason to be late — the
popout is content-bounded, so its size is 0 until the body lays out.

## Second request: the config panels

Audio, wifi and bluetooth now spawn from the bulge exactly as the dashboard
does. Verified by measurement, per the operator's standing rule:

- **Surface moved from `830,16 850x620` to `806,6 898x620`** — welded to the
  rail (y 16 → 6), widened by exactly 2×24 for the flares, panel still centred
  at 830.
- **Flare, raw pixel dump with a positive control** (row y=3 = pure wallpaper,
  luminance 538). The gradient rim sits at x=813 on row y=6, 821 at y=10, 825 at
  y=14, and reaches the panel's own edge by y=18 — a concave arc at full 24px
  width against the rail, tapering to nothing. *An earlier binary threshold
  clipped the arc's anti-aliased tip and read 13px; the raw dump corrected it.*
- **The top rail's bulge follows the open surface**, sized off PanelDialog's own
  `panelWidth` — the panels are 850 against the dashboard's 760, so a fixed
  bulge left them overhanging their own root by 45px a side.
- **Dashboard regression check:** its own y=6 transitions are byte-identical
  before and after (854, 864/865, 1645/1646, 1656).

## The exit was not actually playing — found only by measuring

`openPanel` closes via `closeAllPanels()`, which set `active = false` directly
and destroyed the surface on the first frame of its exit. **Measured 112ms
against a 500ms spatial-in token.**

That was the *main* path: Super+A, the tile chevrons and the IPC verb all route
through it, while only Esc and focus-loss reached `requestDismiss()`. The
animation would have looked broken exactly where it is used most and correct
where it is used least. After the fix: **576ms**.

## Closing is split, and a gate is why

A genuine dismiss animates; a close that is **replacing** one panel with another
is instant. `quickshell-doctor` caught the reason rather than my eye:
`cross[count=2]`. All three panels are the same 850px frame in the same centred
position, so an animated overlap reads as a glitch, not a crossfade — and it
broke D-15-25's at-most-one-panel invariant.

The doctor's post-dismiss settle went 0.3s → 1.0s. That **widens the settle, it
does not weaken the assertion**: the invariant is still zero panels once nothing
is open, and a panel that never closes is still caught, because 1.0s is far past
any exit the motion tokens can produce.

## Gates — once each

doctor 28/0 (re-run after the one real failure it caught), colour-lint 365/0,
motion-lint 552/0, settings-index 121/0, keybind-doctor 13/0,
hypr-equivalence 3/0. `reserved` still `[0,6,50,6]`.

## Still outstanding — CLOSED BY ROUND 4 (superseded 2026-08-25)

**What this said, and it is no longer true:** "The attached popout has still
never been rendered. The fix above is code-evident, not pixel-verified."

Round 4 rendered it and measured it. The reveal was captured from the shell's
own `console.log` — the width ran `w=8 -> 15 -> 22 -> ... -> 357` with
`clip=true` — and the same round diagnosed the flare tab by a controlled
comparison on real pixels, reading ~606 (the bar's rim blue) with the bulge on
against 132-139 (background) with it forced to zero. Neither measurement is
available to a surface that never painted.

The instrument note in that round is the part worth carrying forward: `grim`
cannot be raced against a 500ms animation at ~150ms per capture, so
time-varying behaviour is measured through `console.log`, not screenshots.

Nothing from this section is open.
