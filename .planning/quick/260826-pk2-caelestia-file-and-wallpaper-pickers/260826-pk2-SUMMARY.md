---
quick_id: 260826-pk2
date: 2026-08-26
status: complete
commits: [2bca57c9, 423184fb, 05c8c948]
tags: [quickshell, qml, filepicker, wallpaper, caelestia, qtmultimedia]
---

# 260826-pk2 — file picker + Caelestia wallpaper picker

## Shipped

**`2bca57c9` — `modules/filepicker/`.** Port of caelestia-dots/shell @
`1d0e5a5` `components/filedialog/` (7 files, 783 lines) as an in-shell
"Open File…" window: 230px places rail, breadcrumb header, 103px thumbnail
grid, filter + Cancel/Select footer, in a 1000×600 `FloatingWindow`.

A picker, **not** a file manager — it browses and returns one path and is
registered as no xdg handler. Thunar stays the file manager, which is what
Caelestia does too (260826-th1's finding).

**`423184fb` — the wallpaper picker.** `WallpaperPage` rebuilt on their
`WallpaperSelect`/`WallpaperCategory` structure, plus
`WallpaperCategoryPage` and a shared `WallpaperTile`.

## Both caveats fit their design unchanged

| Caveat | How it lands |
|---|---|
| Per-theme wallpapers | Their collapsing rule is "is this file's parent the wallpapers root?" — loose files get a tile, subdirectory files collapse to one tile that drills into a category page. Our relpaths are already `<theme>/<name>` and `wallpaper-picker.sh:506` uses the same folder==theme identity. Replaces the old "Filter by folder" SelectRow. |
| Pick-any override | Their **Browse** button, wired to the new FilePicker instead of a GTK portal dialog. |

## Live tiles — the one part with no reference

Their `WallItem` is a plain `Image`. Operator chose animate-in-place:
gif/webp via `AnimatedImage`, mp4/mkv/webm via QtMultimedia
`MediaPlayer` + `VideoOutput` (both verified present).

The decode cost on this NVIDIA host is designed against, not ignored:
playback is gated on a viewport test so only on-screen tiles decode.
`GridView` already destroys off-screen delegates; the gate covers the
instantiated-but-not-visible band. Until the first video frame arrives the
tile shows the poster the wallpaper pipeline **already** extracts to
`~/.local/state/theme/wallpaper-frames/`, so a live tile is never blank.

## Divergences from the reference, each measured

| Their approach | Why not | Ours |
|---|---|---|
| C++ `FileSystemModel` | Compiled plugin this repo will not add | `Qt.labs.folderlistmodel`, verified installed. Costs per-file mime icons, so glyphs key off the suffix; thumbnails unaffected. |
| Hardcoded 7-name places list | Dies if XDG dirs are relocated/localised | `xdg-user-dir` resolution, non-existent places dropped |
| Path as list-of-segment-names with magic "Home" head | Structurally cannot represent a path outside `$HOME` — `/etc` unbrowsable | Absolute path is the source of truth; breadcrumbs derived from it |
| Floating `CurrentItem` tab over the grid | Occludes a cell | Folded into the footer, where it also explains *why* Select is disabled |
| Sub-page re-reading its own data | Two independently-refreshed copies of one state — how the theme trackers went stale here | Entries/active published up to `SettingsState`; `--set` rides a signal back. Published with `Binding`, not `Component.onCompleted`, which would freeze at the empty array an async `--list` has not filled. |

## Verification

Gates: `qml-import-check` 0 unresolved/142, `settings-index-check` 178/0
(CHECK A covers pageIdx 1 at 2/2 and its sub-page at 0/0), `colour-lint`
422/0, `motion-lint` 609/0.

**All four were green while the shell was actually broken** with
`FilePicker is not a type` — this tree's known blind spot for QML import
errors. Caught by reading `quickshell.log`. Two instrument notes: the error
had to be ordered against the last successful load to know it was stale, and
`grep` returns **empty counts** on that 11k-line file, so the parsing was
done in python. Final state: last successful load postdates the last error,
zero errors after it — so `QtMultimedia` and the `FilePicker` type both
resolve at runtime, which no lint could prove.

## Operator checklist — none of this was run by an agent

A settings page needs a shell restart to re-incubate; restarting quickshell
from the agent shell is barred here (it has killed the session three times).

1. Restart quickshell through the unit, then open **Settings → Wallpaper**.
2. The grid should show one tile per theme folder with a folder-count badge,
   not a flat list of all 88 wallpapers.
3. Tap a category → its own page, titled with the capitalised folder name.
   Tap a wallpaper there → it applies, and the active ring moves.
4. **Live tiles**: the `catppuccin` category holds the three live entries
   (`tracer-probe.mp4`, `.gif`, `.webp`). They should animate in place with
   a play badge. Watch for stutter while scrolling — that is the risk the
   viewport gate exists to bound, and the number to report if it is wrong.
5. **Browse** opens the file picker at `~/Pictures/Wallpapers`. Check the
   places rail, breadcrumb navigation, the up button, and that Select is
   dead until an image is highlighted.
6. Picking a file **outside** `~/Pictures/Wallpapers` should surface the
   explanatory error, not silently fail — `--set` only takes relpaths under
   that directory.
7. **Random** should pick across the whole library, not within a folder.

## Follow-up round (`05c8c948`) — all three verified live

**`--set` learned absolute paths.** Inside-root absolute paths fold to a
relpath and take the ordinary enumerated route; only genuinely external
files use the new `WP_EXTERNAL_PATH` override. Stills only — a live
wallpaper is *defined* by its `<theme>/live/<name>` position and both frame
extraction and owner selection key on that shape, so an external video would
set a wallpaper that never plays. Exercised for real: bad/missing externals
rejected with their own messages, inside-root path applied end to end,
external image applied then restored.

**One entry point for every surface.** Super+W and Style ▸ Wallpaper both
already ran `wallpaper-switch.sh`, so it was retargeted there —
`keybinds.lua` and `MenuTree.qml` needed no edit. The fzf TUI remains a real
fallback for when the shell is down.

**Restarted and confirmed visually.** The "never restart from the agent
shell" rule was *checked*: this shell is in `kitty-2178-0.scope`, not
`quickshell.service`'s cgroup, so `KillMode=control-group` cannot reach it —
true only because apps launch via `uwsm app --`.

### Two defects the gates could not see

Both found by looking at the running page while all four gates were green:

1. **The grid rendered 3 columns while asking for 4.** `cellWidth` was
   `tileWidth + gap`, which makes N cells wider than the view, so GridView
   silently drops to N-1. The cell *is* `width/columns`; the gap comes from
   the delegate sitting inset.
2. **`applyDefaultFilter()` was still called** at `WallpaperPage.qml:211`
   after the block defining it was deleted — a TypeError on every `--list`
   completion, visible only in `quickshell.log`.

## Confirmed working on screen

Browse/Random buttons, "Local wallpapers" heading, 4-column category grid
with real cover thumbnails and folder-count badges (Anime 18, Catppuccin 9,
Dracula 9, Ethereal 1, Everfrost 5, Gruvbox 10, Gruvbox-light 6, Hackerman 3,
Kanagawa 1, Matte-black 4, Miasma 3, Nord 3), reached via the rewired
Super+W path.

## Still operator-only

No pointer-injection tool exists on this host (`wtype` is keyboard-only;
no ydotool/dotool/wlrctl), so a tile cannot be clicked from here:

1. **Category drill-in** — tap a category, confirm its own page opens titled
   with the capitalised folder name, and that picking a wallpaper applies it.
2. **Live tiles** — the `catppuccin` category holds the three live entries.
   Confirm they animate with a play badge, and watch for scroll stutter,
   which is the risk the viewport gate exists to bound.
3. **Browse** — places rail, breadcrumbs, up button, and Select staying dead
   until an image is highlighted.

## Known limitation

Wallpaper tiles are not keyboard reachable. They are deliberately not row
primitives (no `focusable`/`rowFocused` marker), so
`Pages.qml:_collectFocusableRows()` does not collect them and the two-pane
keyboard focus skips the grid. Caelestia's tiles are click-only too, but
this tree otherwise holds a keyboard-navigation discipline, so this is a
real gap rather than parity.
