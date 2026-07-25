---
phase: 08-waybar-evolution
plan: 13
type: execute
status: complete
completed: 2026-07-15
gap_closure: true
outcome: approved — floating's colourful identity restored, both reported bugs fixed
requirements: [BAR-01]
---

# 08-13 Summary: floating layout rebuild

## Outcome

**APPROVED by the user on sight** (verbatim: **"approved"**) under tokyonight (dark) and
catppuccin-latte (light). Screenshots: `/tmp/bar-floating-tokyonight.png`,
`/tmp/bar-floating-catppuccin-latte.png`.

## Design correction (important — recorded as a durable decision)

The 08-13 plan (written pre-athena) and my first execution attempt rebuilt floating as
**three austere neutral capsules** inheriting 08-12's "chroma = state only" system, then
carried athena's "filled, but fewer" colour into it. **The user rejected both**: *"Restore
the colourful identity of floating. The 'filled, but fewer' contract I approved was meant
for athena only. Each waybar will be its own separate design flow."*

**Durable decision:** the phase's layouts are NOT bound to one shared colour contract.
`full` = single translucent island; `athena` = neutral discrete capsules + filled-but-fewer;
`floating` = a full rainbow of per-module colour; `vertical` = TBD (08-14). Each is its own
design flow. The 08-12 `<design_system>` block binds only the layouts that opt into it.

## What shipped

`style-floating.css` rewritten to **restore floating's colourful per-module-pill identity**
(a vivid row of individually-hued pills) while fixing only the two reported bugs and making
it gate-clean:

- **Bug 1 — the opaque slab** (`window#waybar { background: alpha(@background,0.90) }`,
  leaked from 08-03's OLED trim): window is **transparent** again; each pill carries its own
  colour, no bar-wide slab.
- **Bug 2 — compressed/4px-speck workspaces** (`font-size: 4px` + `padding/margin: 0`):
  removed; buttons render at a legible 15px with the active workspace as a filled `@accent`
  pill and `@float-a` inactive text.
- **Rainbow routed through role names** — the old raw palette tokens (`@primary`,
  `@tertiary`, `@secondary`, `@error`, ...) that failed CHECK B are replaced by a new
  `theme.css` `@float-*` chip palette ({fill, on-fill} M3 pairs, so every pill's glyph is
  guaranteed-contrast). Clock is a quiet `@float-neutral` anchor amid the colour; power is
  `@danger`. Battery-blink retargeted to role names.
- Invalid `border-radius: 10` (no unit) and `min-height: 10px` module-inflation in the `*`
  reset corrected.

## Gates
- `waybar-design-lint`: floating now passes **CHECK A/B/C/D/E** — the two long-standing
  floating failures are cleared. Phase lint is now **30 pass / 2 fail**, the 2 being
  `style-vertical.css` CHECK B/C (08-14 scope; down from 4).
- `theme-doctor`: `style-floating.css` parses non-empty; D-17 module-gate resolves every
  floating module. (Working-tree-clean check fails only on uncommitted work.)
- Bug-fix assertions pass: window transparent, no 4px font, no zero-padding workspace
  collapse, `min-height: 0`, zero raw palette tokens.

## Deviations
- First attempt (austere 3-capsule) discarded per user direction (see Design correction).
- The plan's `.modules-left/-center/-right` capsule assertion no longer applies — floating
  is per-module pills, not three group capsules.

## Self-Check: PASSED — user approved floating on sight under light + dark.
