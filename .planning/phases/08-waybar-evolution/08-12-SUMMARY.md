---
phase: 08-waybar-evolution
plan: 12
type: execute
status: complete
completed: 2026-07-15
gap_closure: true
outcome: partial-scope — full APPROVED; minimal SUPERSEDED by athena (08-16)
---

# 08-12 Summary: Core Redesign (full + minimal → full approved, minimal superseded)

## Outcome

**`full` layout: APPROVED by the user on sight**, under both dark (tokyonight) and light
(catppuccin-latte) presets, after one rejection-and-fix cycle.

**`minimal` layout: SUPERSEDED.** At this plan's checkpoint the user approved `full` and
directed that `minimal` be scrapped and rebuilt from scratch as a new layout, `athena`,
mimicking github.com/haikal-hakim/athena. That work is planned in **08-16** with design contract
`08-athena-DESIGN.md`. The `style-minimal.css` produced here is throwaway — 08-16 `git mv`s it to
`style-athena.css` and rewrites it. This plan's "minimal approved" success-criterion is therefore
retired, not met, by explicit user redirection.

## What shipped (full)

- **`waybar-modules.css`** (`97ee5ad`) — rewritten as the shared neutral design system:
  transparent window, one `@bar-surface` island on `window#waybar > box`, per-module accent
  rainbow deleted, active workspace restored as the single accent-filled focal point, 14/10/6
  radius scale.
- **`style-full.css` / `style-minimal.css`** (`a389835`) — transparent-window islands.
  `window#waybar { background: transparent }` deletes the `alpha(@background,0.90)` opaque slab
  (the reported "dark bar behind all modules") and the `@primary` hairline 08-03 painted on.
- **`theme.css`** (`7087dd3`) — DEFECT-A fix after user rejection: `fg-dim` rebound from
  `@outline` (a border role, low-contrast by design → illegible on light themes) to
  `@on_surface_variant`; `fg-mute` raised from `alpha(@on_surface,0.55)` to `0.80`.
- **`waybar-modules.css`** (`11f8cfb`) — DEFECT-B audit: `#custom-theme` colour rule confirmed
  never dropped (glyph washout was the contrast collapse, resolved by the DEFECT-A fix).

### Deviations (committed in a389835)
- `theme-engine/lib/commit.sh` — excluded `waybar-visibility.css` from `rsync --delete`, which
  was wiping it every `theme-apply` and crashing waybar via an unresolvable `@import`.
- `style-floating.css` / `style-vertical.css` — import-line swap (`waybar.css` → `theme.css`)
  only; their own redesign remains 08-13/08-14's scope.

## Measured contrast (WCAG, composited through the translucent surface)

| Role | latte (light) | tokyonight (dark) |
|------|---------------|-------------------|
| body `fg` | 7.45:1 ✓ | 11.85:1 ✓ |
| dim (was `@outline`) | 2.02:1 ✗ | 2.14:1 ✗ |
| dim (now `@on_surface_variant`) | 4.61:1 ✓ | 9.06:1 ✓ |
| muted (was 0.55) | 2.58:1 ✗ | 4.27:1 ~ |
| muted (now 0.80) | 4.49:1 ✓ | 7.86:1 ✓ |

## Gates

- `waybar-design-lint`: 28 pass / 4 fail — the 4 being `style-floating.css` + `style-vertical.css`
  CHECK B/C, correctly deferred to 08-13/08-14.
- `theme-doctor`: clean (pre-existing working-tree-cleanliness check aside).

## Self-Check: PASSED (full only; minimal deliberately superseded)

## Follow-on gaps recorded at this checkpoint
- `athena` layout rebuild → **08-16** (design: `08-athena-DESIGN.md`).
- eww media popup dead → `.planning/todos/pending/eww-media-popup-dead.md`.
- swaync intrusive + overlapping notifications → `.planning/todos/pending/swaync-intrusive-overlapping.md`.
- Empty light-preset wallpaper directories (every light theme keeps the prior dark wallpaper) —
  noted for separate triage.
