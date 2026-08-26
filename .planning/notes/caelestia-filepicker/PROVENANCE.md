# Caelestia file picker + wallpaper picker — vendored source

Fetched 2026-08-26 from `caelestia-dots/shell` @ **1d0e5a5** for quick task
260826-pk2. Vendored because a "follow the reference" task without the real
files invents a plausible design and reports it as the reference.

| File | Role |
|------|------|
| `FileDialog.qml` | LazyLoader + FloatingWindow 1000x600 shell |
| `Sidebar.qml` | places rail, `Sizes.sidebarWidth` 230 |
| `HeaderBar.qml` | up button + breadcrumb trail |
| `FolderContents.qml` | grid body, `Sizes.itemWidth` 103 |
| `DialogButtons.qml` | filter readout + Cancel/Select |
| `CurrentItem.qml` | inverse-rounded selection detail tab |
| `Sizes.qml` | itemWidth 103, sidebarWidth 230 |
| `WallpaperSelect.qml` | wallpaper root page (Browse/Random, featured, grid) |
| `WallpaperCategory.qml` | per-category sub-page |
| `WallItem.qml` | the wallpaper tile |

## Their C++ dependency, and what replaces it

`FolderContents.qml` and the wallpaper pages import `Caelestia.Models` for
`FileSystemModel` / `FileSystemEntry`, from their compiled Quickshell plugin.
This repo has no such plugin and is not adding one.

- File listing -> `Qt.labs.folderlistmodel` (installed here, verified at
  `/usr/lib/qt6/qml/Qt/labs/folderlistmodel`).
- Wallpaper listing -> this repo's existing
  `wallpaper-picker.sh --list/--active/--set`, which already returns
  `theme/name.ext` relpaths and knows which entries are live.

Cost of the model swap: `FolderListModel` has no `mimeType`, so per-file
icons key off the suffix instead. Thumbnails are unaffected.

## Token mapping

| Caelestia | ours |
|-----------|------|
| `Tokens.spacing.extraSmall/small/medium/large` 4/8/12/16 | `Design.spacingXs/Sm/Md/Lg` 4/8/16/24 |
| `Tokens.rounding.medium/large/largeIncreased/extraLarge` 12/16/20/28 | literals at the same values |
| `Colours.tPalette.m3surfaceContainer` | `Colours.surfaceVariant` |
| `Colours.palette.m3onSurfaceVariant` | `Colours.onSurfaceVariant` |
| `StateLayer` | `MouseArea` + a `Behavior on color` through `Motion` |

Their spacing scale is 4/8/12/16; ours is 4/8/16/24. Medium therefore maps
16 where they use 12 — noted so a future diff against upstream does not read
as a mistake.
