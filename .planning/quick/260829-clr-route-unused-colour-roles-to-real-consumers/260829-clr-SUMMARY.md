---
quick_id: 260829-clr
title: Route the unused Material You colour roles to real consumers
status: complete
completed: 2026-08-29
commits: [fd43b509]
gates: "colour-lint 572/0; theme-doctor 1575/0; theme-parity 1897/0"
---

# 260829-clr — SUMMARY

## What the operator asked

"Are we utilizing the new generated colors?" — the palette grew 19 → 33 roles in
260828-u0r and adoption was never swept.

## Answer, measured

**13 of 33 roles had zero consumers.** Counted `Colours.<role>` across 191 QML
files with a parser, excluding `Colours.qml`'s own declarations; `Probe.qml`
reads `Colours.roles` (the list) so it never false-positives.

Five roles now have real consumers:

| role | before | after | where |
|---|---|---|---|
| `surfaceContainerLow` | 0 | 2 | catalogue detail card, catalogue list panel |
| `surfaceContainer` | 0 | 6 | headers, queue card, slider/scrollbar tracks |
| `outlineVariant` | 0 | 8 | dividers |
| `errorContainer` | 0 | 1 | the `dbLocked` banner |
| `onErrorContainer` | 0 | 1 | its text |

Eight remain unused and are reported, not hidden: `surfaceContainerLowest`,
`onBackground`, `scrim`, `shadow`, `surfaceDim`, `surfaceBright`,
`tertiaryContainer`, `onTertiaryContainer`.

## The hypothesis was half right, and the wrong half was the dangerous one

The handoff predicted "components still fake elevation with alpha tints over
`surface`". 24 non-zero `Qt.alpha(Colours.onSurface*, …)` sites exist, but only
**8** are elevation. Ten are **M3 state layers** — `containsMouse ? veil :
transparent`, `pressed ? veil : transparent` — where a low-alpha `onSurface`
veil is precisely what the M3 spec prescribes. Converting those to container
roles would have replaced hover/press feedback with a static fill. Six more are
scrollbar tints, `Qt.tint` seeds and disabled states.

Had the hypothesis been executed as written, 10 surfaces would have lost their
hover state. This is why the handoff's own instruction — "do not treat the
recorded hypotheses as findings" — was worth obeying.

## The mapping is derived, not chosen

Blending each veil over the live `surface` and finding the nearest ladder step:

| veil | renders | nearest step | Δ / 255 |
|---|---|---|---|
| `onSurface @ 0.05` | (50,52,63) | `surfaceContainerLow` (48,50,61) | 3.5 |
| `onSurface @ 0.06` | (52,54,65) | `surfaceContainer` (52,54,65) | **0.0 exact** |
| `onSurface @ 0.07` | (55,56,67) | `surfaceContainer` (52,54,65) | 4.1 |

And for dividers, `Qt.alpha(Colours.outline, 0.4)` over surface renders
(63,71,98) — `outlineVariant` **is** (63,71,98), Δ=0.0. The tree had been
hand-computing that role for months without knowing it existed.

So the swap is visually a no-op on the current theme but becomes theme-correct
everywhere else: the ladder is regenerated per theme, a fixed alpha blend is not.

## Judgment calls, stated

- **Slider/scrollbar tracks stay at `surfaceContainer`,** not the nominally
  correct `surfaceContainerHighest` — that would visibly lighten them. Mapping
  by measured tonal equivalence preserves appearance; the track-role question is
  recorded rather than silently decided.
- **`FindingRow`'s armed destructive button keeps `error`/`onError`.** It is
  high-emphasis on purpose ("the second click is the one that changes the
  system"). Only the informational `dbLocked` banner moved to the container pair.
- **Four dividers get visibly calmer** (Δ86): `AudioPanel:670`,
  `BluetoothPanel:422`, `WifiPanel:682`, `WbSidebar:178` used full-strength
  `outline` for a 1px rule, louder than the spec. This is the one change in this
  task an operator will actually see — flagged for judgment.

## What genuinely has no home

`onBackground` has no consumer and no candidate: `Colours.background` appears
3 times, all as a modal scrim tint, never behind text. Reported rather than
given an invented use.

Out-of-scope finding: those same 3 sites are what `scrim` exists for
(`Qt.alpha(Colours.background, 0.55)` → M3 says `scrim`). Converting them is a
visible change (navy dim → black dim) and `scrim` was explicitly scoped out, so
it stays a note for a future task.
