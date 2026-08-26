---
quick_id: 260826-th1
date: 2026-08-26
status: complete
commits: [3f30f42c, e7dd2daf]
tags: [thunar, gtk3, matugen, papirus, icon-theme, caelestia]
---

# 260826-th1 — Caelestia's file-manager look, driven by our theme pipeline

## The finding that reframed the task

The operator asked to copy "Caelestia's file explorer". **Caelestia has no
QML file manager — its file explorer is Thunar**, the same one already
installed here. Receipts, from their own repos:

- dots `README.md:197` — `| Super + E | File explorer (default: thunar) |`
- dots `hypr/variables.lua:12` — `fileExplorer = "thunar"`
- dots `manifest.toml:72` — installs the `thunar` package

The look is a ~200-line GTK stylesheet their CLI templates with scheme
colours (`theme.py:307`), plus Papirus folder icons recoloured to the
primary. Nothing to port UI-side. Source vendored with provenance at
`.planning/notes/caelestia-gtk/`.

An earlier reading of the request assumed a QML port of
`components/filedialog/`; that was wrong and would have built the wrong
thing. The correction came from checking the dots repo, not the shell repo.

## Shipped

**`3f30f42c` — Thunar follows the wallpaper palette.** Their `thunar.css` as
a matugen template → `~/.local/state/theme/thunar.css`, imported by one line
in the stowed `gtk-3.0/gtk.css` (which already had a slot for exactly this),
registered in the theme contract as `css-literal`. GTK3 only — Thunar is a
GTK3 app, so their gtk-4.0 copy is deliberately not reproduced.

**`e7dd2daf` — accent-tracked Papirus folders, no root.**

## Two things that were already built

`theme_engine_apply_icon_theme` and `theme_engine_nearest_papirus_color`
(D-17) already existed and were already wired into the pipeline. They were
dormant only because `papirus-folders` was absent and the icon-theme state
said `Adwaita`, which the function early-returns on. This was nearly
rebuilt from scratch — grep before scoping.

## Deliberate divergences from the reference

| Their approach | Why not | What we do |
|---|---|---|
| `surfaceContainerLow` | Does not exist on the static-preset branch. None of the 20 palette JSONs define it, and matugen **fails the whole render** rather than degrading — a wallpaper-only test passes while every static theme breaks. | `surface_variant`, present in all 20 and already this repo's choice for card/sidebar backgrounds. |
| `sudo -n papirus-folders` | Rewrites symlinks in `/usr/share/icons`; its `verify_privileges()` re-execs under sudo unless the theme is in `$HOME`. Means root per theme switch, or a 19MB copy that goes stale. Both host-only state. | A user-level shadow theme of symlinks under the **same theme name**. XDG searches `~/.local/share/icons` first and same-named theme dirs merge, so only folders are overridden. Nothing copied; Papirus updates picked up free. |
| `thunar.css` in gtk-4.0 too | Thunar is GTK3; the GTK4 copy can never match. | GTK3 only. |

## Bug fixed along the way

The hue mapper emitted 3 names that do not exist in Papirus —
`carmine-red` (real name `carmine`), `bright-orange`, `oxidgreen`. Those
hue buckets silently recoloured nothing. Validated the full 23-name emitted
set against the 109 real folder colours; the mismatch set is now empty.

## Verification — live, not inspection

- **`.thunar` is a real style class** (the load-bearing assumption): probed
  with a temporary `background-color: #ff00ff`, then grim + pixel count on
  the focused window — **2,586,501 magenta pixels** on Thunar 4.20.9.
- **The first probe read zero and was WRONG.** `grim` captures a screen
  region; Thunar was behind the terminal and I measured the terminal. The
  negative had no positive control. A second bad probe used CSS `min-width`,
  which Hyprland overrides since it tiles.
- GTK3 parses the rendered sheet with **0 errors**; the full stowed
  `gtk.css` chain resolves through the stow symlink; the provider really
  contains the `.thunar` rules (a failed `@import` is otherwise silent).
- All **29** selector groups are `.thunar`-scoped, checked with a
  brace-depth parser, so no other GTK3 app can be affected.
- Overlay: 938 links, **0** malformed; red/green/blue round-trip relinks
  correctly; empty and unknown colours both remove the overlay so folders
  fall back to stock rather than freezing on the last accent.
- `theme-doctor`: **1168 passed, 2 failed** — see below.

## Pre-existing failures, not caused by this task

`retirement-check waybar/cross-package-refs` reports 2 references:
`bar/TrayCapsule.qml:2` and `bar/qmldir:51`. Both are **prose comments**
explaining the waybar retirement, added by quick task 260823-65s on
2026-08-23 (`git blame` confirms). The gate is matching its own explanatory
text. Left alone deliberately.

The other failure is the clean-tree check, which only fails while this
task's own work is uncommitted.

## Reproducibility

`papirus-folders` **removed** from `install.sh` — no longer a dependency.
`papirus-icon-theme` (pacman) is still required. The icon-theme state is
seeded in `stow.sh` seed-only-when-absent, so a fresh install gets
`Papirus-Dark` and this host carries no hand-written state. Verified the
seed does not clobber an existing choice.

## Not done

The file picker and wallpaper picker (the second task) are untouched.
