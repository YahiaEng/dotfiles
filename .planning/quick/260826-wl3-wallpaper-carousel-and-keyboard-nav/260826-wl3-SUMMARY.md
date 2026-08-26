---
quick_id: 260826-wl3
date: 2026-08-26
status: complete
commits: [33293992, b5471223]
tags: [quickshell, qml, launcher, pathview, wallpaper, keyboard-nav]
---

# 260826-wl3 — wallpaper carousel + keyboard-reachable tiles

## The mis-port this corrects

260826-pk2 ported Caelestia's **settings** wallpaper grid
(`modules/nexus/pages/wallandstyle/`) and dismissed
`modules/launcher/WallpaperList.qml` as "the launcher's wallpaper mode
(inline list)". That was the wrong file. The launcher one is the strip that
spawns from the bar's bottom bulge, scrolls left/right, and updates the
desktop live — the picker the operator meant.

Both now exist and serve different jobs:

| Surface | Job | Opened by |
|---|---|---|
| Launcher carousel | fast pick-and-go, live preview | Super+W, Style ▸ Wallpaper |
| Settings ▸ Wallpaper grid | browse everything, categories, Browse-from-anywhere | Settings, `qs ipc call settings openPage wallpaper` |

## The carousel

`modules/launcher/WallpaperMode.qml` — a **PathView**, which is the whole
trick: `preferredHighlightBegin`/`End` both `0.5` plus
`StrictlyEnforceRange` pins the current tile to the centre and moves the
content under it; `pathItemCount` is forced **odd** so a true centre exists.
Current tile scales to 1, on-path neighbours to 0.8, off-path to 0.

**Live preview is a preview, not an apply.** Scrolling sends one `awww img`
IPC message — the same mechanism `wallpaper-picker.sh`'s fzf preview has
always used — debounced so a held arrow does not queue a transition per
intermediate tile. It deliberately does *not* run the theme pipeline; a
matugen run per scroll step costs seconds each. Enter/click commits through
`--set`, which does the full apply including the palette. Leaving without
committing restores what was on screen.

**Keyboard nav needed no `Launcher.qml` change**: declaring `columns: count`
makes the existing `moveSelectionColumn()` treat the strip as one row, so
Left/Right walk and wrap it.

`wallpaper-switch.sh` retargeted again — both surfaces route through it, so
`keybinds.lua` and `MenuTree.qml` stay untouched.

## The keyboard gap, and the second bug behind it

Tiles now implement the same duck-typed contract as every row primitive
(`focusable` / `rowFocused` / `activated`), and both grids became **eager
`Grid`s** — a virtualising `GridView` creates delegates lazily, so the
collected focus set would change size as the user scrolls. Safe now because
the collapsing category model made the set small; the original
"~90 entries" reason for virtualising no longer applies.

That alone did **not** work. Measured: **2 focusables** on the wallpaper
page — the InfoRow and the Motion toggle, every tile missing. `Pages.qml`
collects the focus set at page-swap time, and the tiles are Repeater
delegates over data an async `--list` fills in *later*. Added
`SettingsState.focusRowsInvalidated()`, emitted by the page when its model
lands and answered by `Pages.qml` with a `Qt.callLater` re-collect.
Re-measured: **19**.

## Three defects found by looking, with four green gates

1. **The strip rendered ONE tile.** A fixed 176px thumb makes `itemWidth`
   208 against a 608px panel: `floor(608/208) = 2`, and the odd-count rule
   knocks 2 down to 1. Thumb is now derived from available width.
2. **Seeding to the active wallpaper silently never matched.**
   `~/Pictures/Wallpapers` is a **stow symlink**, so `readlink -f` returns
   `/home/aorus/dotfiles/wallpapers/...` while the configured dir is the
   symlink path — the prefix test could never hit. Now defers to
   `wallpaper-picker.sh --active`, which already resolves both sides.
3. **The live tile rendered as an empty rectangle** — `Image` cannot decode
   an mp4. It shows the extracted poster frame, as the settings tile does.

Each was found by capturing the running surface or by instrumenting and
reading `quickshell.log`; none is visible to any gate.

## Verification

On screen: three tiles, centre scaled and ringed, seeded on the active
`dracula/arch.png`, real thumbnails including the live entry.
Gates: `qml-import-check` 0/143, `settings-index-check` 178/0,
`colour-lint` 425/0, `motion-lint` 612/0. Log clean below the restart marker
with both surfaces open. Wallpaper restored to its pre-testing value.

## Operator verification — results

| Check | Result |
|---|---|
| Left/Right moves selection, desktop follows | ✅ passed |
| Escape restores the previous wallpaper | ✅ passed |
| Tiles take focus in Settings ▸ Wallpaper | ✅ passed |
| Search filters the strip | ❌ **filtered apps instead** — fixed in `b5471223` |
| Live wallpapers visible in the picker | ❌ **not visible** — fixed in `b5471223` |

## Follow-up round (`b5471223`)

**Search switched to the app list mid-type.** `LauncherState._routeQuery()`
re-routes on every keystroke and exempted exactly one mode with a one-off
`if (mode === modeMenu)`. Every other mode reached by IPC or the menu — i.e.
every mode that filters *itself* rather than being entered by a typed prefix
— got bounced to apps on the first character. Generalised that into a
`_stickyModes` set (menu, wallpaper, updates, systeminfo) rather than adding
a second `if` beside the first. The placeholder is mode-aware now too.

**Live wallpapers had two causes.** The first *was* the search bug: with 88
wallpapers in a 3-wide strip and no working filter, the three live entries
sat ~40 keypresses away with no way to jump to them. The second is that the
carousel only ever drew a still — it now animates, gated to the **centred**
tile, so exactly one video decodes however long the strip is (a tighter
bound than the settings grid's viewport test). Neighbours keep their poster.

Verified on screen: typing "live" filters to exactly the three live entries,
and the centred tile shows a different frame from its poster-holding
neighbours. Escape closed the launcher and the restore put `dracula/arch.png`
back.
