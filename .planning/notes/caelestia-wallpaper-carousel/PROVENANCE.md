# Caelestia wallpaper carousel — vendored source

`caelestia-dots/shell` @ **1d0e5a5**, fetched 2026-08-26 for quick task
260826-wl3.

**This is the picker the operator meant.** An earlier round (260826-pk2)
ported `modules/nexus/pages/wallandstyle/` — the *settings* grid — and
dismissed `modules/launcher/WallpaperList.qml` as "an inline list". Wrong:
the launcher one is the strip that spawns from the bar, scrolls left/right,
and updates the desktop live. Both now exist here and serve different jobs.

| File | Role |
|------|------|
| `WallpaperList.qml` | the `PathView` strip |
| `WallpaperItem.qml` | one tile: scale 1 current / 0.8 on-path / 0 off |
| `Wallpapers.qml.excerpt` | `preview()` / `stopPreview()` — the live-update mechanism |

## The mechanism, in their words

- `PathView`, not `ListView`. `preferredHighlightBegin`/`End` both `0.5`
  plus `StrictlyEnforceRange` pins the current item to the centre and moves
  the content under it.
- `pathItemCount` forced **odd** — an even count has no middle slot.
- `onCurrentItemChanged: Wallpapers.preview(path)` is the live update;
  `Component.onDestruction: Wallpapers.stopPreview()` restores.

## Divergences

| Theirs | Ours | Why |
|---|---|---|
| `Wallpapers.preview()` previews image **and** palette via a C++ colour quantiser | `awww img` previews the image only | We have no quantiser; matching it means a matugen run per scroll step. Commit runs the full pipeline via `--set`. |
| `CachingImage` (C++) | `Image` with `sourceSize` + `smooth: !view.moving` | Same intent, no plugin. |
| Preview state lives in a service singleton | Restore path captured on open, replayed on uncommitted destruction | We have no wallpaper service; this is the smallest thing that cannot leave the desktop on a browsed-past image. |
| Their tile is an `Image` | Live entries show the extracted poster frame | `Image` cannot decode an mp4 — measured, the tile rendered empty. |

## Two bugs this port hit, worth not repeating

1. **A fixed thumb width made only ONE tile show.** `itemWidth` 208 against
   a 608px panel gives `floor(608/208) = 2`, and the odd-count rule knocks 2
   down to 1. The thumb is now derived from the available width.
2. **Seeding to the active wallpaper silently never matched.**
   `~/Pictures/Wallpapers` is a stow symlink into the repo, so
   `readlink -f` returns `/home/aorus/dotfiles/wallpapers/...` while the
   configured dir is the symlink path — the prefix test could never hit.
   Now defers to `wallpaper-picker.sh --active`, which resolves both sides.
