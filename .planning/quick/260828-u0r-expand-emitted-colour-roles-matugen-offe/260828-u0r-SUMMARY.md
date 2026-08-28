---
quick_id: 260828-u0r
slug: expand-emitted-colour-roles-matugen-offe
date: 2026-08-28
status: complete
commit: 03081056
related: [260828-nav, 260828-mot, 260828-zsh, 260828-pol]
---

# Quick Task 260828-u0r — SUMMARY

First of **seven** operator-requested quick tasks run in one session. This one
came first because two of the others depended on it.

## What shipped

The QML palette grew from **19 to 33 colour roles**, emitted identically by
both the static-preset and wallpaper-driven branches.

**Added (14):** `surfaceContainerLowest`, `surfaceContainerLow`,
`surfaceContainer`, `surfaceContainerHigh`, `surfaceContainerHighest`,
`surfaceDim`, `surfaceBright`, `outlineVariant`, `scrim`, `shadow`,
`tertiaryContainer`, `onTertiaryContainer`, `errorContainer`,
`onErrorContainer`.

**Files:** `lib/generate.sh` (new `theme_engine_augment_palette`),
`templates/qml-palette.json`, `modules/Colours.qml`, plus three stale
role-count comments corrected in `Colours.qml`, `Probe.qml`, `Severity.qml`.

## The finding that shaped the design

**The static branch already runs through matugen** — `lib/generate.sh:85`
renders presets with `matugen json "$palette" -c "$MATUGEN_CFG"`, the same
config and templates as the dynamic branch. That made "just add lines to the
template" look like the whole job.

**It wasn't: matugen does not synthesize missing roles from a partial
palette.** Probed role-by-role against `catppuccin.json` — every ladder role
answers *"Value does not exist in the context"*, while the four `*Container`
roles the presets already carry resolve fine. So the roles are derived and
handed to matugen as an augmented palette. Presets stay hand-authored at 24
keys; any future preset picks the new roles up automatically.

## Derivations — solved, not chosen

Each ladder role was expressed as a per-channel linear blend of `surface`
toward `on_surface` and the scalar fitted across 3 unrelated matugen source
colours × 2 modes. Channel spread came out mostly **under 0.007**.

| role | dark `t` | light `t` |
|---|---|---|
| `surface_container_lowest` | −0.0274 | −0.0271 |
| `surface_container_low` | +0.0392 | +0.0255 |
| `surface_container` | +0.0591 | +0.0521 |
| `surface_container_high` | +0.1084 | +0.0771 |
| `surface_container_highest` | +0.1605 | +0.1032 |
| `surface_dim` | 0.0000 | +0.1422 |
| `surface_bright` | +0.1819 | 0.0000 |

Reconstructing matugen's own output: **worst per-channel error 9/255, typical
<4/255.** The residual is HCT-vs-sRGB blending (matugen preserves chroma),
worst on warm light palettes — and it only applies to hand-authored static
presets, which have no matugen ground truth to be wrong against.
`outlineVariant` = blend(`outline` → `surface`, t≈0.60). `scrim` = `shadow` =
`#000000` in every mode of every palette. Polarity comes from
`theme_engine_detect_mode` (THM-01), not a re-derivation.

## Verification

- **Cross-branch parity:** 7 sampled themes spanning both branches and both
  polarities render a **byte-identical 33-key set**.
- **No role can render debug magenta:** palette keys, `JsonAdapter`
  declarations, the alias layer and `roles[]` cross-check **33/33** with zero
  set differences in either direction.
- **Gates:** theme-parity **1897/0** (was 1542); theme-doctor **1575/0**;
  colour-lint 572/0; singleton-prop-check 0; qml-import-check 0/192.

## Two instrument failures worth remembering

1. **A zsh loop produced a total false negative.** The first role probe
   reported *every* role missing — including `surface`, which demonstrably
   works. Cause: zsh does not word-split unquoted parameters, so
   `for r in $ROLES` iterated **once** with the whole string as one role name.
   Only the positive control caught it.

2. **A parity check passed vacuously.** The first cross-branch comparison
   printed "IDENTICAL" for all 7 themes while every key count was *empty*
   (wrong palette path). Every comparison was `"" == ""`.

## Deferred, with reason

Of the 31 unemitted roles, 17 remain out: `inverse_surface`,
`inverse_on_surface`, `inverse_primary` (no consumer; `inverse_primary`
measured as *the opposite mode's* `primary`, which a single-mode static preset
cannot supply); the 12 `*_fixed*` roles (MD3's cross-mode accent set, no
consumer, no static source); and `source_color` (generator metadata).

## What this unblocked

`surfaceContainerHigh` is what made the settings NavRail's grouped pills
possible in 260828-nav — the rail's category grouping had been *computed but
invisible* since it was written, because unselected rows were painted fully
transparent and a corner radius needs a fill to be seen.
