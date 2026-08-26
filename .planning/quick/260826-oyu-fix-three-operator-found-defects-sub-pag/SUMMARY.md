---
quick_id: 260826-oyu
date: 2026-08-26
status: complete
commits:
  - 672f5b5b  fix(settings): keep pane focus when drilling into a sub-page
  - 7a03a34d  fix(settings): ask the StackView which page is current, not `visible`
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
| 1 | Drilling into a sub-page drops keyboard focus to the rail | TWO causes, one under the other — see below | ✅ operator pass (round 2) |
| 2 | Browse dialog takes no input; clicks hit the window behind | `HyprlandFocusGrab` listed only the settings window | ✅ operator pass |
| 3 | Playing live tile zoomed, right edge cut | element-type-specific; fixed by explicit cover-size + centring | ✅ operator pass |
| 4 | Live wallpapers at the end of the carousel, not with their theme | two independently-sorted `find`s concatenated | ✅ measured + operator pass |

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

## Defect 1 took two rounds, and the second cause is the durable one

**Round 1 (`672f5b5b`) was a real fix and not enough.** `_recollectRows()` ended
with an unconditional `contentFocused = false`, so a sub-page push re-collected
the new rows and then threw focus straight back to the rail. Fixed by carrying
pane focus through push/pop. The operator re-tested: **still failing.**

**Round 2 (`7a03a34d`) found the cause one level down, and it is the interesting
one.** `_collectFocusableRows` inferred "not the current stack element" from
`visible === false`. That inference is **false for the entire length of a push
transition**: `StackPage` pushes with `StackView.PushTransition`, and QQC2 keeps
BOTH the outgoing and incoming items visible while it animates. The re-collect
runs on the next tick — squarely inside that window — so the walk also picked up
the parent page's rows, and in declaration order **those came first**. Focus was
being carried through correctly and then landing on row 0 of the page underneath.

The fix asks the StackView rather than inferring: `currentItem` is set
**synchronously inside `push()`**, before any animation starts, so it is correct
at every instant of the transition. The timing question disappears instead of
being tuned around with a longer delay — which would have "worked" on this
machine and broken on a slower one.

Two holes of the same class were closed with it: `focusRowsInvalidated` now
KEEPS pane focus (it means "my rows changed", not "the user changed page" — as
written it yanked focus away the moment an async model filled), and a focus
request for a page with no rows yet is stashed and applied when they arrive.

**The lesson worth keeping:** round 1's symptom and round 2's symptom are
indistinguishable from the keyboard — both read as "Up/Down does the wrong
thing". A fix that addresses a real cause can leave the report unchanged.

## Honest limits

Nothing here was verified by a gate or by this agent — every one of the four was
confirmed by the operator at the keyboard. A settings row's focus is a virtual
selection rather than a QML focus chain, no pointer injection exists on this
host, and defect 3 was never re-captured after its fix (screen-driving was
stopped at the operator's request mid-task). Defect 4 is the only one with an
independent measurement here: same 88 entries, order-insensitive diff clean.

All four were re-tested by the operator: **defects 2, 3 and 4 passed first time;
defect 1 passed on round 2.**
