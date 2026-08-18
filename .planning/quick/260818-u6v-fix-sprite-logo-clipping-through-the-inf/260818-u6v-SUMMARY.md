---
quick_id: 260818-u6v
date: 2026-08-18
mode: quick
status: complete
one_liner: sprite logos no longer draw through the info box — fastfetch reserves text columns only, never scaling the image, so the natural cell footprint must be declared; satan_cross dropped from the picker
---

# Quick Task 260818-u6v — Summary

Two operator-reported defects in `260818-srl`, both closed.

## Defect 1 — sprite GIFs drew through the info box

### Root cause

`--logo-width`/`--logo-height` were never set anywhere. The decisive measurement
is the kitty graphics control string, identical in every variant tested:

```
a=T,q=2,f=24,t=s,s=200,v=200,S=120000,I=<id>
```

`s=200,v=200` is the **source pixel size** and there are **no `c=`/`r=`
cell-scaling keys**. So `--logo-width` does not resize the image — it reserves
text columns and moves the placement cue. The image is always drawn at its
natural pixel size.

Indent mechanism per path, captured from a real kitty window:

| path | mechanism | uniform |
|---|---|---|
| ASCII (`file`) | 41 real spaces = 37 art cols + 2 + 2 | yes |
| `none` | column 0 | yes |
| sprite (`kitty-icat`) | `ESC[3C` — cursor-forward 3, `padding.left` alone | — |

Cell geometry measured live: 2440x640 px over 244x32 cells = **10 x 20 px**.
A 200x200 sprite therefore occupies **20 cols x 10 rows**. fastfetch reserved 3.

### Fix

`--logo-width 20 --logo-height 10` on the `kitty-icat` branch only. Verified: the
offset moves 3 -> 23 and every line, top `┌` rule included, lands uniformly at
`ESC[23C`.

Not applied to the `file` or `none` branches — fastfetch measures text art itself
and the flags are meaningless there. The invocation is now a three-way branch with
that reasoning stated at each arm.

### Documented coupling

The two numbers are `S/10` and `S/20`, pinned as named constants
(`ff_sprite_cols`/`ff_sprite_rows`) with the derivation written out at the call
site **and** beside `S` in the generator, so a future canvas change cannot silently
reintroduce the defect. Correct only while the canvas is 200x200 and kitty's cell
is 10x20 px, which follows from `font_size 12.0`. A materially smaller font raises
the natural column count above 20 and the clipping returns. Querying the real cell
size per shell would cost another ~14ms `kitten` spawn on top of the one icat
already pays — hence pinned, not queried.

### Not implicated

`box-close.awk` was suspected and cleared: it measures from the first `│`, which
stays correct on `ESC[3C`-prefixed lines, and the graphics payload line carries no
`│` so it passes through untouched. Left alone.

## Defect 2 — satan_cross dropped from the picker

71 columns against arch 37, cyberpunk_mask 44, illuminati 48, star 52 — it pushed
the box far right of every other entry. Removed from the selector's `ff_ascii_arts`
and the picker's `ASCII_NAMES`/`ASCII_NAMES_P`; header and list comment 13 -> 12.

`art/satan_cross.txt` **stays on disk and committed** — the operator asked to remove
the option, not the art.

A stale prose comment in `matugen/config.toml` cited satan_cross as a live example
of why all nine logo colour slots are defined. Corrected rather than deleted: the
nine-slot rule now reads as the reason an art can be added or re-offered without
touching the template, with satan_cross named as the standing case in point.

## Verified live (real kitty window, output captured to file)

| state | result | box offset |
|---|---|---|
| `pulse` | sprite renders, graphics payload present | `ESC[23C` uniform |
| `arch` | themed ASCII | 41 spaces |
| `satan_cross` | falls through to themed arch | 41 spaces |
| `bogus-value` | falls through to themed arch | 41 spaces |
| `none` | no logo | column 0 |

Nothing reaches the stock builtin logo. Confirmed by colour, not by shape: an early
`oooooo` glyph check false-positived because the themed `arch.txt` is built on the
same classic arch shape. The themed art carries 19 `$N` runs and renders **4 distinct
truecolors**; the builtin would render as a single ANSI colour.

Measurement discipline: every live check ran inside a real kitty window with stdout
redirected to a file. fastfetch detects its terminal by climbing the process tree, so
probing from an agent's own shell reports the wrapper, icat fails, and it silently
falls back to the builtin logo — the exact failure mode that produced a wrong
`terminalfont` claim earlier in this session.

## Gates

theme-doctor 582/0, keybind-doctor 14/0, hypr-equivalence-check 3 PASS / 0 FAIL,
theme-parity, stow-link-check, colour-lint. Syntax: `fish -n`, `bash -n`,
`py_compile` all clean.

## Files

- `fish/.config/fish/config.fish` — sprite cell reservation, three-way invocation branch, satan_cross removed
- `theme-engine/.config/theme-engine/lib/fastfetch-sprites.py` — coupling note beside `S`
- `hypr/.config/hypr/scripts/fastfetch-logo-picker.sh` — satan_cross removed, 13 -> 12
- `matugen/.config/matugen/config.toml` — stale prose corrected

Commit: `e7de955`
