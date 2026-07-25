---
phase: 08-waybar-evolution
plan: 14
type: execute
status: complete
completed: 2026-07-15
gap_closure: true
outcome: approved — vertical rebuilt as a saatvik333-style left column with derived-hue colour
requirements: [BAR-03]
---

# 08-14 Summary: vertical layout rebuild

## Outcome

**APPROVED by the user on sight** (verbatim: **"approved"**) under tokyonight (dark) and
catppuccin-latte (light). Screenshots: `/tmp/bar-vertical-tokyonight.png`,
`/tmp/bar-vertical-catppuccin-latte.png`.

## Design direction (user-supplied reference)

The user directed vertical to be its own design flow, mimicking
**github.com/saatvik333/niri-dotfiles** adjusted to this repo's dynamic theming. That
reference (fetched this session) is a left-positioned, solid, gapless column of **bare
glyphs** (`padding: 6px 0`, no boxes) with **semantic** colour (clock/network/battery states)
and vertical slider drawers. Reproduced faithfully via theme.css role names.

## What shipped

`config-vertical.jsonc` + `style-vertical.css` rebuilt:

- **Solid column flush to the left edge, full height** (margins 0 — "gapless minimal"). Its
  own `@column` surface role (near-opaque `@surface`). Replaces the old floating island.
- **Bare glyphs, no boxes** — the old "big button boxes" (a global `* { font-size: 20px }`
  inflating containers) and the "5-hue stripe rainbow" are gone. 16px glyphs, generous
  vertical spacing, hover-fade.
- **cpu/memory/temperature → icon-only** with the detail in tooltips (reference's bare-glyph
  style; also the plan's Task 1).
- **Reference signatures:** clock stacked HH/MM at the top in accent; a **`group/audio`
  vertical slider drawer** (hover the volume glyph); active workspace carried by glyph
  colour alone (no fill — overrides the shared sheet's `@accent` fill).
- **Column width observed: ~44px** — closes the deferred UAT width question with a real
  measurement, not a guess.

## Two rounds of checkpoint feedback

**Round 2 — "cpu/ram/temp do nothing on hover/click" + "more colour":**
- *Root cause of the dead interaction:* each module was only as wide as its ~16px glyph
  (`padding: 9px 0`), leaving the rest of the 44px column as dead space. Widened to
  `padding: 9px 13px` so the **whole row is the hover/click target**. Added `on-click` →
  `htop` and per-module `tooltip-format`. (Also fixed a self-inflicted bug: an earlier
  bulk `str.replace` — `"format": "{icon}"` matches both `temperature` AND
  `custom/notification` — had injected a Temp tooltip + htop click into the notification
  module; reverted.)
- Added per-glyph colour.

**Round 3 — "over-using the same two colours, add variety":**
- Material You gives only ~4 native hues (primary/secondary/tertiary/error), and
  primary+secondary cluster in one hue family (both blue on tokyonight) — hence "two
  colours". Resolved by **deriving extra distinct hues with GTK CSS `mix()`**:
  `@vhue-purple = mix(@primary, @error, 0.4)`, `@vhue-teal = mix(@secondary, @tertiary, 0.5)`.
  Six hues now spread across the column (blue/cyan/green/purple/teal/red), all still
  theme-derived. **Verified GTK accepts `mix()` in `@define-color`** (theme-doctor
  non-empty-provider check passed — no WLOG-01 sheet discard).

## Gates
- `waybar-design-lint`: **32 passed / 0 failed** — all four layouts fully pass for the first
  time. vertical CHECK A/B/C/D/E green.
- `theme-doctor`: `style-vertical.css` parses non-empty; all vertical modules (incl.
  `group/audio`) resolve. No raw palette tokens.

## Deviations
- Reference-driven redesign supersedes the pre-athena 08-14 plan's austere/neutral intent
  (each layout is its own design flow — the durable 08-13 decision).
- Module arrangement changed (clock→top, audio→slider group) to match the reference flow.

## Self-Check: PASSED — user approved vertical on sight under light + dark.
