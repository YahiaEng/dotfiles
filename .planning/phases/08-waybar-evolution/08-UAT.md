---
status: testing
phase: 08-waybar-evolution
source: [08-VERIFICATION.md]
started: 2026-07-14T20:55:00Z
updated: 2026-07-14T20:55:00Z
---

## Current Test

number: 1
name: Visual/aesthetic pass across all 4 waybar layouts under a light and a dark preset
expected: |
  Every module renders its intended glyph (no tofu/empty boxes), colours resolve to the intended
  palette tokens with no visible black/unstyled flashes, and the translucent OLED-safe styling reads
  as intended rather than merely "technically non-opaque". Check full, minimal, floating, and vertical
  under at least one light preset and one dark preset (Super+B to switch layout; theme switch to flip
  preset). Pay attention to the gaming-mode glyph (the UI-SPEC pair U+F04FE/F04FF rendered as the
  WRONG icons on the installed font, so a fallback pair shipped) and to the pre-existing empty glyph
  fields in modules.jsonc (mpris/pulseaudio/cpu/memory/temperature) that 08-05 patched only in vertical.
awaiting: user response

## Tests

### 1. Visual/aesthetic pass across all 4 waybar layouts
expected: Every module renders its intended glyph (no tofu), colours resolve to intended palette tokens with no black/unstyled flashes, translucent OLED styling reads correctly — across full/minimal/floating/vertical under one light + one dark preset.
result: [pending]

### 2. Vertical layout width — 66px actual vs UI-SPEC 48px
expected: A live waybar warning reports "Requested width: 48 is less than the minimum width: 66 required by the modules". Decide: either accept 66px as the real content-driven column width (and update the UI-SPEC 48px token to match), or trim a module/padding so the column actually renders at 48px. The bar functions correctly at 66px today; this is a design-intent call, not a pass/fail.
result: [pending]

### 3. Media popup cursor-anchor mode never tested on real hardware
expected: media-popup-open.sh ships ANCHOR_MODE="fixed" (top-right corner) because it was authored headless — that fixed path was confirmed working live. Flip ANCHOR_MODE to "cursor" and click the media segment from the bar's far-right edge, the bottom edge, and the vertical layout's column; confirm the popup always lands fully on-screen and never straddles a monitor seam. Keep whichever mode you prefer.
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
