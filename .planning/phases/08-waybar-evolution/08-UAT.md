---
status: diagnosed
phase: 08-waybar-evolution
source: [08-VERIFICATION.md]
started: 2026-07-14T20:55:00Z
updated: 2026-07-14T23:59:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Visual/aesthetic pass across all 4 waybar layouts
expected: Every module renders its intended glyph (no tofu), colours resolve to intended palette tokens with no black/unstyled flashes, translucent OLED styling reads correctly — across full/minimal/floating/vertical under one light + one dark preset.
result: issue
reported: "Complete failure. The design looks terrible and modules are missing. There is now a dark bar behind all modules when it shouldn't, THe workspace module of \"floating\" looks copressed and smaller than before. Both \"minimal\" and \"full\" are an eyesore and need a complete redesign. The new \"vertical\" is also awful, big button boxes, terrible color scheme. Use the top rated waybar configurations/rices on github as inspiration and fix the design"
severity: blocker

### 2. Vertical layout width — 66px actual vs UI-SPEC 48px
expected: A live waybar warning reports "Requested width: 48 is less than the minimum width: 66 required by the modules". Decide: either accept 66px as the real content-driven column width (and update the UI-SPEC 48px token to match), or trim a module/padding so the column actually renders at 48px. The bar functions correctly at 66px today; this is a design-intent call, not a pass/fail.
result: skipped
reason: Superseded by the Test 1 redesign — the vertical layout is being rebuilt, so its column width is re-decided by the new design rather than by this question.

### 3. Media popup cursor-anchor mode never tested on real hardware
expected: media-popup-open.sh ships ANCHOR_MODE="fixed" (top-right corner) because it was authored headless — that fixed path was confirmed working live. Flip ANCHOR_MODE to "cursor" and click the media segment from the bar's far-right edge, the bottom edge, and the vertical layout's column; confirm the popup always lands fully on-screen and never straddles a monitor seam. Keep whichever mode you prefer.
result: skipped
reason: Deferred until after the Test 1 redesign lands — re-test cursor-anchor against the rebuilt bar geometry rather than the geometry being replaced.

## Summary

total: 3
passed: 0
issues: 1
pending: 0
skipped: 2
blocked: 0

## Gaps

- truth: "All 4 waybar layouts (full/minimal/floating/vertical) render with correct glyphs, correct palette-token colours, no opaque dark backing, and a visually coherent design under both light and dark presets"
  status: failed
  reason: "User reported: Complete failure. The design looks terrible and modules are missing. There is now a dark bar behind all modules when it shouldn't. The workspace module of 'floating' looks compressed and smaller than before. Both 'minimal' and 'full' are an eyesore and need a complete redesign. The new 'vertical' is also awful, big button boxes, terrible color scheme. Use the top rated waybar configurations/rices on github as inspiration and fix the design"
  severity: blocker
  test: 1
  sub_issues:
    - "Opaque dark bar/backing rendered behind all modules (should be transparent/translucent)"
    - "Modules missing from the bar"
    - "floating: workspace module compressed / smaller than before"
    - "minimal + full: overall aesthetic regression, needs redesign"
    - "vertical: oversized button boxes, poor colour scheme"
  user_direction: "Use top-rated waybar configurations/rices on GitHub as design inspiration"
  root_cause: "Phase 08 applied an OLED-trim spec written for full/minimal onto the floating layout (which is premised on pills over an INVISIBLE bar), painting an opaque slab behind every module; simultaneously it promoted pre-existing zero-glyph module definitions into the shared modules.jsonc and repaired them only in config-vertical.jsonc, leaving full/minimal rendering blank icons; and it introduced a shared module stylesheet whose per-module accent-hue mapping (5 competing hues) becomes visually chaotic once stacked in the new vertical column."
  artifacts:
    - path: "waybar/.config/waybar/style-floating.css"
      issue: "L26-28 window#waybar background flipped from `transparent` to `alpha(@background, 0.90)` (commit b2423b4, OLED trim) — this is the reported dark bar. L162-171 added `padding: 0; margin: 0` to #workspaces button (commit 5add972), collapsing buttons below even the old GTK default — this is the reported compression. L152/L183-188: #workspaces font-size 4px and .occupied color @surface (#1e1e2e) = same color as the new slab, rendering occupied workspaces invisible. L15: `border-radius: 10` missing px unit — invalid declaration."
    - path: "waybar/.config/waybar/modules.jsonc"
      issue: "Zero-character / bare-space icon fields: custom/theme format (L134) and custom/waybar-layout format (L140) are a single U+0020, and both carry a filled @primary pill background — the two most-clickable buttons render as invisible purple blobs. temperature format-icons (L112), pulseaudio format-icons (L120), and mpris player-icons/status-icons (L47-57) are all empty strings. cpu/memory/clock/network formats (L98/104/74/127) lead with two spaces and no glyph. Pre-existing (verified in 8b4d21e) but promoted to the canonical shared definition by 46f6a67 and repaired only in config-vertical.jsonc."
    - path: "waybar/.config/waybar/waybar-modules.css"
      issue: "Highest-leverage file. Binds a different accent hue per module (@tertiary cpu/pulseaudio, @secondary memory/network, @primary temperature, @error power filled, @primary theme/layout filled, @outline gaming = near-invisible) — a 5-hue rainbow that reads as chaos once vertical stacks it. Also L22-29 changed the active workspace from a filled @primary pill to a transparent 2px underline, draining full/minimal of their focal point."
    - path: "waybar/.config/waybar/style-vertical.css"
      issue: "L16-25 `* { font-size: 20px }` plus L58-77 `min-width: 24px; padding: 4px 12px` on every module = the reported big button boxes. Content-driven width forces the column to 66px against a configured 48px."
    - path: "waybar/.config/waybar/style-full.css + style-minimal.css"
      issue: "L18-22 (both): bar chrome washed out — `background: @background` -> `alpha(@background, 0.90)` and a crisp `border-bottom: 3px solid @primary` -> `1px solid alpha(@primary, 0.4)` hairline."
  missing:
    - "Restore `window#waybar { background: transparent; }` in style-floating.css — the visible surface belongs on the module groups, never on the window (universal pattern across every top-rated rice)."
    - "Repair every zero-glyph field in modules.jsonc upstream, using config-vertical.jsonc's already-correct glyph set as the reference (cpu U+F2DB, memory U+F0C9, temp U+F2CB, pulseaudio U+F026, mpris U+F001)."
    - "Restore a `min-width` floor (9-16px) on #workspaces button — the anti-collapse trick that every good config uses after resetting GTK button padding."
    - "Replace the per-module accent-hue mapping in waybar-modules.css with ONE neutral surface; reserve chroma exclusively for state (active workspace, warning, critical)."
    - "Introduce a semantic alias layer (theme.css) so matugen token names appear in exactly one file, mapping @surface_container -> bar surface via alpha() so translucency derives from tokens and works in both light and dark with no branching."
    - "Add `min-height: 0` to the `*` rule (present in every well-rated config; its absence inflates every module)."
    - "Give glyph-only modules their own font-size rather than forcing one global size to serve both 12px text and 20px icons."
    - "Adopt a single radius scale (14 bar / 10 segment / 6 button) instead of the current ad-hoc mix."
    - "Vertical: drop module fills entirely, go icon-only with detail in tooltip-format, stack clock/cpu/memory text with \\n, and style workspace buttons as bare colored glyphs (no box)."
  design_direction: "Translucent island (HANCORE V6.f school): window transparent, surface on `window#waybar > box` (or on .modules-* for floating), one neutral surface derived via alpha(@surface_container, 0.55), chroma only for state. Satisfies OLED + light/dark + matugen simultaneously. Reference repos fetched: basecamp/omarchy, sejjy/mechabar (844*), HANCORE-linux/waybar-themes (531*), JaKooLit/Hyprland-Dots (vertical themes), prasanthrangan/hyprdots, HyDE."
  debug_session: ""
  note: "Deployment caveat surfaced during diagnosis: ~/.config/waybar/* are REGULAR FILES, not stow symlinks (currently byte-identical to the repo). The redesign must confirm how they are synced or repo edits will not reach the live bar."
