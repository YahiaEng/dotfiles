# Caelestia GTK/Thunar reference — vendored source

Fetched 2026-08-26 for the Thunar restyle task. Vendored because a
"follow the reference" task without the actual files invents a plausible
design and reports it as the reference (standing rule).

| Repo | Commit | Used for |
|------|--------|----------|
| caelestia-dots/shell | `1d0e5a5` | (picker work, separate task) |
| caelestia-dots/caelestia (dots) | `58ea6ec` | Super+E binding, package manifest, Thunar config |
| caelestia-dots/cli | `eff0c7e` | `apply_gtk()`, thunar.css + gtk.css templates |

## The finding

Caelestia's "file explorer" is **Thunar**, not a QML app:

- dots `README.md:197` — `| Super + E | File explorer (default: thunar) |`
- dots `hypr/variables.lua:12` — `fileExplorer = "thunar"`
- dots `manifest.toml:72` — installs the `thunar` package

The look comes entirely from `thunar.css` (vendored here as
`thunar.css.tmpl`), which their CLI renders with scheme colours in
`apply_gtk()` and writes next to `gtk.css`; `gtk.css:21` pulls it in with
`@import "thunar.css";`.

## Template variable mapping

Their `{{ $role }}` → our matugen `{{colors.<role>.default.hex}}`:

| Caelestia | ours |
|-----------|------|
| `$surface` | `colors.surface` |
| `$surfaceContainerLow` | `colors.surface_container_low` |
| `$primary` | `colors.primary` |
| `$onSurface` | `colors.on_surface` |

All four verified to render from matugen 4.1.0 on this host.

## Deliberate divergence: no `sudo`

Their `sync_papirus_colors()` (see `theme.py.excerpt`) shells out to
`sudo -n papirus-folders -C <colour> -u`, which re-points folder symlinks
inside `/usr/share/icons/`. That is host-only state requiring root, which
this repo's reproducibility constraint forbids.

Measured alternative: Papirus `folder.svg` is itself a symlink to
`folder-<colour>.svg`, so a **user-level icon theme** in
`~/.local/share/icons/` that `Inherits=Papirus-Dark` and overrides only the
folder symlinks achieves the same result with no root and no AUR package.
197 semantic folder names × 6 size buckets.
