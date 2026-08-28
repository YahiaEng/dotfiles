---
quick_id: 260829-clr
title: Route the unused Material You colour roles to real consumers
status: in-progress
created: 2026-08-29
operator_decision: "Targeted: elevation + real semantics"
---

# 260829-clr — Route the unused colour roles to real consumers

## Objective

Answer the operator's question "are we utilizing the new generated colors?" with a
measurement, then route the roles that have a genuine semantic home. Approved
scope is TARGETED: the `surfaceContainer*` elevation ladder and
`outlineVariant`/`errorContainer`/`onErrorContainer`/`onBackground` only.
`scrim`, `shadow`, `surfaceDim`, `surfaceBright`, `tertiaryContainer` stay
declared-but-unused until something genuinely needs them.

## Measurement (done before planning — this is the finding, not a hypothesis)

Counted `Colours.<role>` references across 191 QML files, excluding
`Colours.qml`'s own declarations. `Probe.qml` reads `Colours.roles` (the list),
not individual roles, so it never false-positives.

**13 of 33 roles have zero consumers:** `tertiaryContainer`,
`onTertiaryContainer`, `surfaceContainerLowest`, `surfaceContainerLow`,
`surfaceContainer`, `surfaceDim`, `surfaceBright`, `onBackground`,
`outlineVariant`, `errorContainer`, `onErrorContainer`, `scrim`, `shadow`.
`surfaceContainerHigh`/`Highest` have exactly 1 reference each (the settings
nav rail, added by 260828-u0r).

### The hypothesis was half right, and the wrong half matters

The handoff predicted "components still fake elevation with alpha tints over
`surface`". 24 non-zero `Qt.alpha(Colours.onSurface*, …)` sites exist, but they
split into three classes and only ONE is fake elevation:

- **Class A — static elevation fills (8 sites).** A Rectangle that always
  carries this fill. These are the fake elevation. → convert.
- **Class B — M3 state layers (10 sites).** `containsMouse ? veil : transparent`
  and `pressed ? veil : transparent`. A low-alpha `onSurface` veil is *exactly*
  what the M3 state-layer spec prescribes for hover/press. Converting these to
  container roles would break hover feedback. → **do not touch.**
- **Class C — not elevation (6 sites).** Scroll-bar track/handle tints,
  `Qt.tint` seeds, disabled-state fills. → do not touch.

### The mapping is derived, not chosen

Blending each veil over the live `surface` and finding the nearest ladder step:

| veil | renders | nearest step | Δ (0-255) |
|---|---|---|---|
| `onSurface @ 0.05` | (50,52,63) | `surfaceContainerLow` (48,50,61) | 3.5 |
| `onSurface @ 0.06` | (52,54,65) | `surfaceContainer` (52,54,65) | **0.0 exact** |
| `onSurface @ 0.07` | (55,56,67) | `surfaceContainer` (52,54,65) | 4.1 |

So the swap is visually a no-op on the current theme but becomes theme-correct:
the ladder is regenerated per theme, a fixed alpha blend is not.

Same result for dividers: `Qt.alpha(Colours.outline, 0.4)` over surface renders
(63,71,98), and `outlineVariant` **is** (63,71,98) — Δ=0.0. The tree has been
hand-computing `outlineVariant` without knowing the role existed.

## Tasks

### Task 1 — elevation ladder replaces the 8 static veils

| file:line | was | becomes |
|---|---|---|
| `appearance/AtCatalogueTab.qml:114` | `onSurface @ 0.07` | `surfaceContainer` |
| `appearance/AtCatalogueTab.qml:180` | `onSurface @ 0.06` | `surfaceContainer` |
| `appearance/AtCatalogueTab.qml:360` | `onSurface @ 0.05` | `surfaceContainerLow` |
| `appearance/AtCatalogueTab.qml:418` | `onSurface @ 0.05` | `surfaceContainerLow` |
| `packages/WbDetail.qml:214` | `onSurface @ 0.06` | `surfaceContainer` |
| `packages/WbDetail.qml:240` | `onSurface @ 0.07` | `surfaceContainer` |
| `packages/WbTable.qml:72` | `onSurface @ 0.07` | `surfaceContainer` |
| `packages/WbTable.qml:268` | `onSurface @ 0.06` | `surfaceContainer` |

Deliberately NOT promoting the three slider/scrollbar *track* backgrounds
(`AtCatalogueTab:180`, `WbDetail:214`, `WbTable:268`) to
`surfaceContainerHighest`, which is M3's nominal track role: that would visibly
lighten them. Mapping by measured tonal equivalence preserves appearance; the
track-role question is recorded, not silently decided.

### Task 2 — `outlineVariant` takes the dividers

M3 assigns dividers `outlineVariant`, not `outline`. 8 sites:

- Exact/near-exact (already hand-computing the role):
  `Atelier.qml:273` (0.35, Δ7.8), `WbDetail.qml:265` (0.4, Δ0.0),
  `WbDetail.qml:379` (0.4, Δ0.0), `WbTable.qml:226` (0.4, Δ0.0)
- **Visibly calmer** (Δ86 — flag for operator judgment):
  `AudioPanel.qml:670`, `BluetoothPanel.qml:422`, `WifiPanel.qml:682`,
  `WbSidebar.qml:178` — these currently use full-strength `outline` for a
  1px divider, which is louder than the spec.

### Task 3 — `errorContainer`/`onErrorContainer` take the one informational banner

Two Rectangles in the tree are filled with `Colours.error`:

- `packages/WbSidebar.qml:321` — the "pacman is running. Actions are paused."
  banner. Informational, not a call to action → M3's low-emphasis pair
  `errorContainer`/`onErrorContainer`. **Convert.**
- `security/FindingRow.qml:212` — an *armed destructive button*, deliberately
  loud ("the second click is the one that changes the system"). High-emphasis
  `error`/`onError` is correct. **Leave.**

### Task 4 — record what genuinely has no home

`onBackground` has no consumer and no genuine home: `Colours.background` appears
only 3 times, all as a modal scrim tint (`Qt.alpha(Colours.background, 0.55)`),
never behind text. Report it rather than invent a use.

Separately recorded finding, out of approved scope: those same three sites are
what `scrim` exists for. Converting them is a visible change (navy dim → black
dim) and the operator explicitly scoped `scrim` out, so it stays a note.

## Verification

- `colour-lint` green (this task only moves values between `Colours.*` roles;
  it introduces no literals)
- role-reference count re-run: the 5 routed roles move off zero
- `quickshell.log` hot-reload line shows no QML load error
