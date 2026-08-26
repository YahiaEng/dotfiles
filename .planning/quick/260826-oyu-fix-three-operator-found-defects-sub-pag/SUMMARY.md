---
quick_id: 260826-oyu
date: 2026-08-26
status: complete
commits:
  - 672f5b5b  fix(settings): keep pane focus when drilling into a sub-page
  - b85d990e  fix(settings): let the Browse picker join the window's focus grab
  - bf1dbe98  fix(wallpaper): centre and cover-size live tiles
  - 5d1e7c1a  fix(wallpaper): group live entries with their theme in --list
---

# 260826-oyu — four defects from the operator's live pass

Three came from the handoff checklist, a fourth from the operator mid-task.
**None was reachable by a gate** — all four gates were green throughout.

## What was fixed

| # | Defect | Cause | Verified |
|---|---|---|---|
| 1 | Drilling into a sub-page drops keyboard focus to the rail | `Pages.qml:_recollectRows()` reset `contentFocused` unconditionally | operator re-test |
| 2 | Browse dialog takes no input; clicks hit the window behind | `HyprlandFocusGrab` listed only the settings window | operator re-test |
| 3 | Playing live tile zoomed, right edge cut | element-type-specific; fixed by explicit cover-size + centring | partly — see below |
| 4 | Live wallpapers at the end of the carousel, not with their theme | two independently-sorted `find`s concatenated | **measured** |

## The one that needed real measurement

Defect 3's report was "only a left side portion". The carousel turned out to be
its own control: its frame is **exactly 16:9** and all three live sources measure
**1920x1080** (ffprobe: SAR 1:1, DAR 16:9), so `PreserveAspectCrop` there should
be a *no-op*. A `grim -g` capture of the running surface showed the poster
neighbours whole and the **playing** tile zoomed with its right-hand digit block
clipped — identical geometry, identical fillMode, **element type the only
variable**.

**A hypothesis died on the way, which is why it was worth measuring.** GIF frames
after the first are legally sub-rectangles of the canvas, which would explain a
wrong aspect. `QImageReader` says otherwise: 1920x1080, 150 frames, every frame
full-size. Not that.

What survived is the *signature* — left-anchored overflow. So the fix stops
asking the element to crop and states the geometry: a box sized to cover the
frame, centred, image fitted inside it. Correct aspect → pixel-identical to a
correct crop; wrong aspect → overflow splits evenly, so the worst case is a
centred crop rather than a corner.

## A separate host gap found by the same measurement

**Webp does not decode on this machine at all.** `supportedImageFormats()` has no
webp, `canRead()` is false, and `/usr/lib/qt6/plugins/imageformats/` holds only
gif, ico, jpeg and svg. So `catppuccin/live/tracer-probe.webp` shows its poster
for ever and never animates, and a `.webp` **still** wallpaper could not render in
this shell either. The library holds exactly one webp, which is why it went
unnoticed.

Recorded in `WallpaperTile.qml`'s header, **not** fixed: the missing piece is a
host plugin. Arch's `qt6-imageformats` advertises only TIFF/MNG/TGA/WBMP in its
description, so it is named as a **candidate to verify**, not as the fix. Not
added to `install.sh` on an unverified claim.

## Defect 4 respects an existing decision rather than overwriting it

Live entries measured at 86-88 of 88. The two `find` **passes** stay separate —
D-01/D-03 define "live" by folder, not extension — and only the **order** is
merged under one sort. D-17 (live grouped at the end, discoverable) is preserved
where it was made: the fzf TUI's own enumeration is untouched, because there a
trailing group plus the `▶` marker is how a live entry announces itself. The
carousel draws a play badge on every tile, so an end-group bought it nothing.

Membership proven unchanged — same 88 entries, order-insensitive diff clean — so
`--set`'s re-validation against this set is unaffected.

## Gates, unpiped

`qml-import-check` 0 unresolved / 143 files · `colour-lint` 425/0 ·
`motion-lint` 612/0 · `settings-index-check` 178/0 · `theme-doctor` 1218/0.

## Honest limits

Defects 1 and 2 ship **unverified**. A settings row's focus is a virtual
selection, not a QML focus chain, and no pointer injection exists on this host —
neither is reachable by any tool here. Defect 3 was not re-captured after the
fix: I stopped driving the live surface at the operator's request mid-task.

All three want an operator look.
