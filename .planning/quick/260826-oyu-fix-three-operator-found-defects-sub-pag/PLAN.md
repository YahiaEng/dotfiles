---
quick_id: 260826-oyu
date: 2026-08-26
status: in-progress
source: operator live-pass on the 260826-npc handoff checklist (3 checks, 3 defects)
---

# 260826-oyu — the three defects the operator's live pass found

All three came from the checklist handed over after 260826-npc. None was
reachable by a gate; two were found by the operator at the keyboard, the third
was confirmed here by capturing the running surface.

## Defect 1 — drilling into a sub-page drops keyboard focus back to the rail

**Operator:** "Apps > Right arrow > All Apps > up/down arrow will now move
between the tabs instead of moving between the All Apps section."

**Cause, read not guessed — `Pages.qml:235-242`.** `_recollectRows()` ends with:

```qml
root._focusableRows = root._collectFocusableRows(root.currentItem);
root.contentFocused = false;      // <-- unconditional
root.contentRowIdx = -1;
```

`onSubPageOpened` / `onSubPageClosed` (`Pages.qml:517-519`) both route into it.
So the push *correctly* re-collects the sub-page's rows and then immediately
throws focus back to the rail. `Settings.qml:250-262` then takes the `else`
branch and Up/Down pages the rail — exactly what the operator saw.

The reset is right for a **rail-driven page swap** (you were in the rail, you
switched page, focus belongs in the rail). It is wrong for a **sub-page push**,
which is initiated *from* the content pane by activating a row.

**Fix:** `_recollectRows(focusRowIdx)`. Default `-1` keeps today's reset. Sub-page
open passes `0` (ring the new page's first row) and remembers the row it came
from; sub-page close pops that memory and restores it. Only preserve when the
push actually came from the keyboard — a mouse click into a sub-page should not
plant a focus ring the user did not ask for.

## Defect 2 — the Browse dialog takes no input; clicks land on the window behind

**Operator:** "Browse opens dialog window on ~/Pictures/Wallpapers. But I cannot
interact with the dialog window, can't scroll inside and if I click on it
dismisses/clicks on the settings menu behind it."

**Cause — `Settings.qml:308-313`.**

```qml
HyprlandFocusGrab { windows: [win]; active: true; onCleared: win.closeRequested() }
```

The grab captures input **exclusively** to the listed surfaces. `FilePicker` is a
separate `FloatingWindow` toplevel (`filepicker/FilePicker.qml:54`) that is not in
that list, so the compositor keeps routing pointer and scroll to the grabbed
settings window — a click on the picker reads as a click *outside* the grab,
which is why it also dismisses. The symptom matches the mechanism exactly.

**Fix:** the picker joins the grab while it is open. `windows` is a writable
`QObjectList` (verified in
`/usr/lib/qt6/qml/Quickshell/Hyprland/_FocusGrab/quickshell-hyprland-focus-grab.qmltypes`),
and a `FloatingWindow` is already accepted there — `win` itself is one. Routed
through the per-window `SettingsState` both ends already share, so the generic
picker stays uncoupled from Settings.

**Cannot be verified here** — no pointer injection exists on this host. Ships for
an operator re-test, stated as such.

## Defect 3 — a playing live tile is zoomed and clipped; its poster is not

**Operator:** "the animated thumbnail does not show the entire live wallpaper,
only a left side portion of it."

**Confirmed by capture, with a built-in control.** Summoned the carousel, filtered
to the three live entries, captured the layer surface with `grim -g`:

- the two **neighbours** show posters (a plain `Image`) — the full test pattern,
  colour bars, circle, right-hand digit block, bottom rainbow strip
- the **centre** tile is the one playing — visibly zoomed, right-hand digit block
  cut off at the frame edge

`WallpaperMode.qml:220` makes that thumb **exactly 16:9**
(`thumbWidth / 16 * 9`), and all three live files measure **1920x1080**
(`ffprobe`: SAR 1:1, DAR 16:9). A 16:9 source in a 16:9 frame under
`PreserveAspectCrop` needs **zero** crop. Both elements sit on identical geometry
(`anchors.fill: parent`) with the identical `fillMode` value. **The element type
is the only variable**: `Image` is correct, `AnimatedImage`/`VideoOutput` are not.

So the element is resolving a source aspect that is not 16:9. For an animated GIF
that is a known shape of problem — frames after the first are legal sub-rectangles
of the canvas, so a per-frame rect is not the logical size.

**Fix:** stop asking those two elements for the aspect. The poster `Image` in the
same frame already holds the authoritative 1920x1080, so size the animated and
video layers to *cover* the frame from that aspect and centre them, rather than
relying on the toolkit's crop. Applies to both `WallpaperTile.qml` (square frame,
a real crop IS wanted) and `WallpaperMode.qml` (16:9 frame, no crop wanted) —
one expression serves both.

## Verification plan

- Defect 1: static reasoning + operator re-test (no synthetic keyboard for a
  focus ring; `wtype` reaches the launcher but the settings window's row focus
  is a virtual selection, not a QML focus chain).
- Defect 2: operator re-test only. Stated, not hidden.
- Defect 3: re-capture the carousel the same way and compare the playing tile
  against its own neighbours. That comparison is the falsifiable part.
- Gates unpiped after: `qml-import-check`, `colour-lint`, `motion-lint`,
  `settings-index-check`, `theme-doctor`.
