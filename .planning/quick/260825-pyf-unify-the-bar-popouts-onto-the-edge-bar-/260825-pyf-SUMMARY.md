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
