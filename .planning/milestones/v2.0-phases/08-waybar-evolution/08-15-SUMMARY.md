---
phase: 08-waybar-evolution
plan: 15
type: execute
status: complete
completed: 2026-07-15
gap_closure: true
outcome: approved — four-layout redesign closed; UAT gap resolved
requirements: [BAR-01, BAR-03, BAR-05]
---

# 08-15 Summary: close-out (gate fold, re-baseline, UI-SPEC, final sweep)

## Outcome

**APPROVED by the user on sight** (verbatim: **"approved"**) after the final cross-layout sweep
of all four layouts under a dark preset, a light preset, and a dynamic matugen theme. This closes
the 08-UAT blocker gap and **completes Phase 08**.

## Task 1 — fold the lint gate + re-baseline the drift gate

- **`waybar-design-lint` folded into `theme-doctor`** — its 32 per-check results are surfaced as
  theme-doctor lines and fold into the pass/fail tally (theme-doctor now 136 passed). Guarded-skip
  mirrors the other waybar sections (unstowed waybar → SKIP, not FAIL). The "green gates coexisting
  with a broken bar" failure class is now structurally foreclosed: the gate that would have caught
  08-12 runs on every doctor invocation, not only by hand.
- **Equivalence baseline re-captured** (`waybar-equivalence-check --snapshot`) — added `athena`,
  removed the stale `minimal.json` (layout renamed in 08-16). Now **4/0**. The old→new diff was
  read in full before re-baselining; every difference is an intentional change this phase made:
  - **glyph restorations** (08-11): clock/cpu/memory/network/pulseaudio/temperature/mpris/
    custom-power/custom-theme/custom-waybar-layout — empty/blank fields → cmap-verified glyphs.
  - **calendar hex removed** (08-11): hardcoded Catppuccin `<span color='#...'>` → weight/underline
    markup (a core no-hardcoded-hex fix; rendered dark-on-dark on light presets).
  - **gaming-mode `on-click`** added (08-16) + **`custom/notification` `{}`→`{text}`** (08-16).
  - **vertical redesign** (08-14): icon-only cpu/mem/temp + htop on-click + tooltips, `group/audio`
    slider, margins 8→0, width 48→44, clock moved to top.
  No un-planned change appeared in the diff.

## Task 2 — rewrite 08-UI-SPEC.md to what shipped

- Removed the superseded **"No redesign — styling trim"** framing and the rejected OLED deltas
  (`alpha(@background, 0.90)` window slab, transparent-underline active workspace).
- Documented the **per-layout design system** (transparent window; surface on the inner box /
  per-group capsules / per-module pills; one neutral surface via `alpha()` from a real token;
  chroma is layout-owned, not one phase-wide contract; role-names-only; radius scale;
  `min-width` workspace floor; `mix()`-derived hues).
- Corrected the **Color** section: the 19 real tokens listed, the **absence of any
  `surface_container` token** flagged as the phase's most dangerous misconception (WLOG-01
  discard), the `theme.css` alias layer documented, and **glyph-name (not presence) verification**
  made binding with the concrete burn (U+F04FE resolves to `md-target`, not a controller).
- Vertical column width updated to the **observed ~44px**, with the note that waybar's `width`
  key is advisory (content-driven). Status → `shipped`; checker sign-off marked.

## Task 3 — final human sweep (blocking checkpoint)

- **Dynamic constraint verified:** `theme-apply materialyou` (wallpaper-generated palette) → all
  four layouts pass design-lint 32/0 and parse non-empty (no sheet discard). Static presets +
  matugen dynamic both hold.
- All four layouts captured under tokyonight; user swept live under dark + light + dynamic and
  approved. Every original sub-issue confirmed closed **by the user, not by a gate**:
  no dark slab, no missing icons, floating workspaces not compressed, full/athena not an eyesore,
  vertical has no big boxes / bad colour scheme, and the four read as one coherent family.

## Gates (final state)
- `waybar-design-lint`: **32/0** (all four layouts, CHECK A–E).
- `waybar-equivalence-check`: **4/0** against the re-captured baseline.
- `theme-parity`: green across all 22 palettes.
- `theme-doctor`: only the git-clean check fails while work is uncommitted (passes after commit);
  all waybar/design-lint/D-17/CSS-parse checks green.

## Phase 08 — COMPLETE
All of BAR-01/03/05's redesign scope delivered and user-approved. The 08-UAT blocker gap is
resolved. Two follow-ups remain parked (non-blocking): light-preset wallpapers, and an
eww popup-open liveness gate.

## Self-Check: PASSED — user approved the final four-layout sweep (dark + light + dynamic).
