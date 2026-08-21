# 260821-swp — Design Brief

Operator-approved design for replacing the motion **scale** axis with an animation
**style** axis. Every decision below was settled with the operator in the session that
created this task. **Do not re-litigate them, and do not re-derive the measured facts** —
they were probed live against this machine's own Hyprland and Qt on 2026-08-21.

## The four locked decisions

| Decision | Answer |
|---|---|
| **Axis shape** | One "Animation style" picker **replaces** the "Animation speed" picker. Each style carries its OWN duration table, so the multiplier axis is absorbed. `off`/`reduced` do **not** become styles — they move to a separate reduced-motion accessibility control. |
| **Style scope** | A style may change (a) easing curves, (b) durations, (c) Hyprland window/workspace entry shape. |
| **Slate** | `md3` (default), `smooth`, `snappy`, `bouncy`, `wavy`. |
| **Structure** | A `styles` object in `motion.json`. Adding a 6th style later must be a **JSON edit only** — no QML, Lua or shell change. |

## Why this reverses a prior removal (state it in the SUMMARY)

- Plan **13-07** deliberately deleted `motion.json`'s `curve_sets` and five `x-*` character
  easings. Its stated reason was that they were *a measuring instrument, never a user-facing
  setting*. This task makes them exactly that, so the reversal is coherent and intentional.
- **TOKEN-06**'s "MD3 is better. Spring is too fast" verdict was recorded explicitly as a
  **tuning-parameter rejection, not a mechanism rejection**, with a future revisit left open.

Neither blocks this work. Reference both so the reversal is on the record.

## Measured facts — trust these, do not re-derive

Probed live on **Hyprland 0.56.2** and **Qt 6.11.2** on this host.

### The current axis is intensity, not style

`motion.json`'s `scales` is `{multiplier, animations_enabled}` — a pure **duration scalar**.
Animation *shape* is fixed MD3 today and cannot vary at all.

### There are only TWO live targets

Hyprland (Lua curves + 15 animation leaves) and QML (`Motion.qml` → 133 call sites).

The GTK4 `:root` motion CSS and the GTK3 `_motion.scss` partial are **still emitted but have
zero real consumers** — swaync, wleave and waybar were all retired. The only remaining
`var(--motion-*)` references in the repo are motion-lint's own fixtures under
`hypr/.config/hypr/scripts/tests/motion-fixtures/`. **Do not invent consumers for them.**

### Hyprland supports native SPRING curves

```lua
hl.curve("name", { type = "spring", stiffness = N, dampening = N, mass = N })
```

- The field is spelled **`dampening`**, not `damping`.
- All three of `stiffness`/`dampening`/`mass` are **required** — omitting any is an error.
- A leaf references a spring through a **separate field**: `hl.animation({ ..., spring = "name" })`.
  Passing a spring name as `bezier =` fails with `no such bezier`.
- Hyprland's own error text is the giveaway: **`bezier or spring is required`**.

### Overshoot beziers are accepted

`{ type = "bezier", points = { {0.05, 0.9}, {0.1, 1.15} } }` registers and reads back `Y1:1.15`.

### Qt 6.11.2 capability (confirmed in `builtins.qmltypes`)

- Easing types `OutBack` / `OutElastic` / `OutBounce` (+ `InOut`/`OutIn` variants) all present.
- Easing properties: `amplitude`, `overshoot`, `period`, `bezierCurve`.
- `SpringAnimation` params are `velocity` / `spring` / `damping` / `epsilon` / `modulus` / `mass`
  — the stiffness parameter is named **`spring`**, NOT `stiffness` (see `12-RESEARCH.md:51`).

### Valid Hyprland style strings — probed per leaf, and they DIFFER per leaf

```
windows:     popin, popin N%, slide, slide <dir>, gnomed, slidefade, slidevert
             ("fade" -> unknown style)

workspaces:  slide, slidevert, fade, slidefade, slidefadevert, slidefade N%
             ("popin" and "gnomed" -> unknown style)
```

Validate **per leaf family**. There is no single shared list.

### easeOutBounce is NOT expressible in Hyprland

Ball-drop bounce is neither a cubic bezier nor a spring. Qt has it natively; Hyprland has no
mechanism for it. **"Bouncy" here means overshoot-and-settle** (easeOutBack / underdamped
spring), never ball-bounce. Do not add a ball-bounce style.

### QML consumption shape

133 sites use `easing.type: Easing.BezierSpline` + `easing.bezierCurve: Motion.<x>Easing`.
A non-bezier style therefore needs `Motion.qml` to expose an easing **type** as well as a curve.
Precedent for exactly that indirection already exists:
`Design.barDrawerEasingType` (`modules/dashboard/Design.qml:226`, `Easing.OutCubic`, 8 call sites).

`Motion.qml`'s `_pairNames` array is read **positionally** by its aliases — any new semantic key
must be **appended**, never inserted.

## Style intent — tune the numbers, keep the character

| Style | Character | windows | workspaces |
|---|---|---|---|
| `md3` | decelerate, lands exactly, no overshoot (today's behaviour = baseline) | `popin 60%` | `slide` |
| `smooth` | critically damped, longest, no overshoot | `slidefade` | `slidefade` |
| `snappy` | short, fast rise, ~3% overshoot | `popin 80%` | `slide` |
| `bouncy` | ~8% overshoot, settles once | `popin 0%` | `slidevert` |
| `wavy` | low dampening, overshoot + undershoot | `popin 0%` | `slidefadevert` |

Adapted from SwiftUI's `smooth`/`snappy`/`bouncy` spring presets and MD3 Expressive's
**spatial-vs-effects split**. Steal that split: apply overshoot **only to spatial motion**
(position/size), **never to effects** (fade/colour/opacity) — a bouncing fade reads as broken.

## Gate risks to handle explicitly

1. **`hyprctl animations -j` cannot see spring curves.** It reports only bezier control points
   (`X0`/`Y0`/`X1`/`Y1`). A spring accepted with `ok` never appears in that curve array —
   verified. `hypr-equivalence-check` compares that array, so it **structurally cannot see
   spring curves**. Same blind-spot class as the colour-lint/tooltip miss. Either keep the slate
   bezier-only, or extend the gate through another channel — **state which, and say plainly what
   the gate can and cannot see.**
2. **motion-lint CHECK A / B / C must stay green.** New `Motion.qml` property names must be added
   to motion-lint's QML definition set (`load_qml_defs`, ~line 290) or CHECK A reports dangling
   references.
3. **`motion-switch.sh` validates against `.scales` keys** before writing state. That validation
   must retarget to `.styles`, and the state file plus its closed-set reader
   (`_read_motion_scale`, currently hardcoding `off|reduced|normal|lively`) must move with it.
4. **`WindowManagerPage.qml` parses `--list` output** with `/^\s{2}(\S+)\s+\(x/`. That
   `(x<multiplier>)` shape disappears with the multiplier — the `--list` format and the parser
   must change **together**.
5. **`Prefs` is `watchChanges:false`** — stop the shell before hand-editing any prefs JSON.
6. **Restart quickshell AFTER the final edit**, and read `~/.cache/quickshell.log` **by offset**
   (record `wc -l` BEFORE the restart), never by tail — stale ERROR blocks produce false failures.

## Verification

This is a look-and-feel change. It needs an **operator render-and-judge pass per style** on both
targets: a window opening, a workspace switch, a notification arriving, a bar drawer sliding.
**Do not claim a style works from static gates alone.**
