---
quick_id: 260828-75k
slug: package-manager-and-browser-as-a-qml-pan
date: 2026-08-28
status: complete
commits:
  - 8ab83760  # design study, five directions
  - 5c42c89a  # decision record: D4 main, D1 rescoped, D5 repairs
  - 8dfc9f24  # PackagesBackend + bar count fix
  - 36358e9d  # D4 workbench
  - a919de9b  # D5 popout
  - 3fd055bd  # D3 launcher route
  - 6ad0e674  # D1 settings page
  - da0f8133  # interim summary
  - 974edb22  # r1: size, dismissal, icons, UpdatesPage absorbed, keybind
  - 45401821  # r2: real click-outside, pane resize, fonts, scrollbars
  - 711e2460  # r3: `pkg` word route painted, scene-anchored resize
artifact: https://claude.ai/code/artifact/b5a9b93e-9d3a-48ca-b2c6-90c3e16cc6e3
operator_status: ALL CONFIRMED — "pkg prefix coloring works, resizing is smooth now"
---

# Package manager & browser as a QML panel

An Octopi replacement: four surfaces over one backend. Octopi is off the disk.

## What ships

| Piece | Files |
|---|---|
| Backend singleton | `modules/packages/PackagesBackend.qml` |
| D4 workbench (main) | `modules/packages/{Workbench,WbSidebar,WbTable,WbDetail,WbButton}.qml` |
| D5 popout | `modules/bar/UpdatesPopout.qml` + `modules/bar/SystemCapsule.qml` |
| D3 `pkg` route | `modules/launcher/PkgMode.qml` + `LauncherState`/`Launcher`/`MenuTree`/`MenuMode` |
| D1 settings page | `modules/settings/pages/PackagesPage.qml` |
| Keybind | `Super+P` (pseudotiling moved to `Super+Shift+P`) |
| Retired | `settings/pages/UpdatesPage.qml`, `launcher/UpdatesMode.qml`, Octopi + 3 packages |

## The defect the feature request uncovered

The bar's updates pill was **AUR-blind** — `SystemCapsule.qml` polled
`checkupdates` alone, so it read **3** while **4** were pending. Fixed at the
source: one backend runs both probes and four surfaces read it.

## Measurements that shaped the design

- `pacman -Qi` → all 1420 records, every field, **0.20 s / 1.33 MB**. No cache
  file, no daemon, no incremental load.
- `pacman -Sl` → 15,412 entries in **0.17 s**. Loaded at startup once the
  deferred version was caught printing "local" as every package's source.
- `pacman -Rs --print --print-format '%n %v'` → the **full removal cascade,
  unprivileged**. 6 orphans → 11 real removals. This is what justified D4.
- `expac` is NOT installed and nothing here needs it. No new package.

## Traps worth remembering

1. **`find … | head` truncated a survey and I drew an architectural conclusion
   from it — twice.** Every module dir has a qmldir; the "is not a type"
   failures were undeclared types, not scanner synthesis. Two files were
   misfiled under that false rationale before it was caught.
2. **Menu leaf labels carry invisible Nerd Font glyphs** (U+F021). An edit
   matched on the visible label silently no-ops. Anchor on machine-written
   fields and read the file back.
3. **`follow_mouse=1` makes Qt's `Window.active` a HOVER signal**, not a click
   signal. Click-outside needs `HyprlandFocusGrab`.
4. **A drag delta measured in the dragged thing's own frame drifts with
   speed.** Anchor on scene coordinates captured at press.
5. **pacman writes the `error:` summary to stderr but the `:: … required by`
   reasons to stdout.** Reading one stream loses half the message.
6. **qmllint is blind here** — rc=0 on a truncated file, verified with a
   positive control. The hot-reload line in `~/.cache/quickshell.log` is the
   only real QML validator, and it needs no restart.

## Gates at close

colour-lint 536/0 · motion-lint 721/0 · qml-import-check 0 unresolved/180 ·
settings-index-check 191/0 · keybind-doctor 13/0 · hypr-equivalence 3 PASS/0 FAIL
(both config additions recorded in that gate's accepted-changes tables).

`quickshell-doctor` NOT run — it restarts the shell from inside, operator-only.

## Nothing is owed
