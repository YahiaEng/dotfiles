# Phase 16: Workspace Overview - Pattern Map

**Mapped:** 2026-08-03
**Files analyzed:** 8 (of the phase's larger touch-set; remainder follow the same analogs noted below)
**Analogs found:** 7 / 8 (drag-drop has no in-repo precedent)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `quickshell/.config/quickshell/modules/Overview.qml` (new surface) | component | event-driven | `quickshell/.config/quickshell/modules/ScreencopyProbe.qml` | exact (capture) / role-match (surface chrome via Dashboard.qml) |
| `quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml` (new) | component | streaming (live capture) | `quickshell/.config/quickshell/modules/ScreencopyProbe.qml` (Repeater+ScreencopyView block) | exact |
| `quickshell/.config/quickshell/modules/overview/DropHighlight.qml` or inline (new) | component | event-driven | `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` (lit-tile treatment) | role-match |
| Drag-drop logic (inline in `WorkspaceTile.qml`/`Overview.qml`) | component | event-driven | none in repo — stock `DragHandler`/`Drag` only | no analog |
| `quickshell/.config/quickshell/shell.qml` (modified: add loader/shortcut/IpcHandler verb) | provider/route | event-driven | itself — `dashboardLoader`/`wifiPanelLoader` blocks + `panelIpc` `IpcHandler` | exact |
| `quickshell/.config/quickshell/shortcuts.json` (modified) | config | CRUD (declarative manifest) | itself, existing 4 entries | exact |
| `hypr/.config/hypr/config/keybinds.lua` (modified: add `Super+O`) | config | request-response (dispatch) | itself, `Super+1..0` / `Super+Shift+1..0` blocks (lines 215-236) | exact |
| `hypr/.config/hypr/config/windowrules.lua` (modified: add `quickshell-overview` fade rule) | config | CRUD (declarative rule) | itself, `^quickshell-.*` namespace rules (lines 303-321, 357-358, 409-410) | exact |

**Follows the same analogs as above (not separately mapped):** `hypr/.config/hypr/config/permissions.lua` (D-16-09 single-value flip, trivial), `hypr/.config/hypr/scripts/quickshell-doctor` (extend existing check list, follow its own established check pattern), `hypr/.config/hypr/scripts/keybind-doctor` (re-run only, no pattern needed).

## Pattern Assignments

### `modules/Overview.qml` (new surface skeleton)

**Analog:** `modules/ScreencopyProbe.qml` (capture) + `modules/Dashboard.qml` (chrome/lifecycle)

**Layer/surface pattern** — `ScreencopyProbe.qml:24-43`:
```qml
PanelWindow {
    // Emitted when HyprlandFocusGrab clears (click-outside dismiss).
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-screencopy-probe"   // → "quickshell-overview"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    HyprlandFocusGrab { ... }
}
```
`Dashboard.qml:199-205` additionally sets `exclusionMode: ExclusionMode.Normal` and its `HyprlandFocusGrab` block is at `Dashboard.qml:438` — copy the click-outside-dismiss wiring from there since it's the more complete/current one (D-12 notes ScreencopyProbe is "deliberately unstyled").

**Capture-per-window pattern** — `ScreencopyProbe.qml:65-87`:
```qml
Repeater {
    id: winRepeater
    model: ToplevelManager.toplevels   // → per-workspace: HyprlandWorkspace.toplevels
    delegate: Item {
        ScreencopyView {
            captureSource: modelData   // → modelData.wayland (HyprlandToplevel case)
            live: true
        }
    }
}
```
Overview groups by workspace instead of a flat list: iterate `Hyprland.workspaces` (pad IDs 1-10 per D-16-01), then nest `Repeater { model: workspace.toplevels }` binding `captureSource: modelData.wayland`.

**Lifecycle/idle pattern** — `shell.qml:136-144` (LazyLoader gate, mirror exactly):
```qml
LazyLoader {
    id: audioPanelLoader
    active: false
    AudioPanel {
        backend: audioBackendInstance
        onDismissRequested: audioPanelLoader.active = false
    }
}
```
D-32/D-36 zero-idle-footprint requirement: capture must stop when the `LazyLoader` deactivates — `ScreencopyView` instances inside a deactivated `LazyLoader` are destroyed automatically (same mechanism `AudioBackend.panelOpen` relies on for PipeWire polling).

---

### `modules/overview/WorkspaceTile.qml` (new, blank/pending state)

**Analog:** `ScreencopyProbe.qml` (capture binding) — no existing pending/timeout state to copy; build from scratch per D-16-10.

**Blank-tile predicate** (RESEARCH.md Q5, no code analog): `screencopyView.hasContent === false` sustained past a timeout = failed/denied; nothing else distinguishes pending from denied.

---

### Drag-drop interaction (inline, `WorkspaceTile.qml`/`Overview.qml`)

**No analog** — `grep -rl "DragHandler" quickshell/.config/quickshell/modules/` returns no hits. Build from QtQuick's stock `DragHandler`/`Drag` attached property. Reuse `QuickToggles.qml`'s lit-tile treatment (`chipItem.lit`, `litProgress` behavior at `QuickToggles.qml:566-575`) for the drop-target highlight (D-16-14), and `Cascade.qml:65-79` (`seqAnim.bandIndex * Motion.staggerOffsetDuration`) for the D-16-24 row-level entrance stagger if the overview wants an animated open.

---

### `shell.qml` (modified — add loader, shortcut, IpcHandler verb)

**Analog:** itself, existing panel blocks

**LazyLoader + backend gate pattern** — `shell.qml:174-187` (wifi panel, simplest recent example):
```qml
LazyLoader {
    id: wifiPanelLoader
    active: false
    WifiPanel {
        backend: wifiBackendInstance
        onDismissRequested: wifiPanelLoader.active = false
    }
}
```

**GlobalShortcut pattern** — `shell.qml:356-361`:
```qml
GlobalShortcut {
    id: screencopyProbeShortcut
    appid: "quickshell"
    name: "screencopy-probe"
    onPressed: screencopyProbeLoader.active = !screencopyProbeLoader.active
}
```
`Super+O` joins these — 5th entry, matches `screencopy-probe`'s toggle-on-press shape (not the guarded `dashboardShortcut` pattern at `shell.qml:363+`, since D-16-19 exempts the overview from the `fullscreenBlocking` guard).

**IpcHandler verb pattern** — `shell.qml:315-347` (`panelIpc`, `target: "panel"`, `open`/`toggle` functions): D-16-23's capture-check verb copies this shape directly — new function reads `overviewLoader.active` before/after a guarded summon call, same as `panelIpc.open()`.

---

### `hypr/.config/hypr/config/keybinds.lua` (modified)

**Analog:** itself, `Super+1..0` binds (lines 215-224)

Lua multi-modifier `' + '` joining convention (13.1 finding) — mirror the existing bind declaration shape used for `Super+1..0`/`Super+Shift+1..0` when adding `Super+O`. Dispatch string for window-move (OVER-03) must use the Lua-wrapped form confirmed at `keybinds.lua:227-236`:
```lua
hl.dsp.window.move({workspace = N})
```
not the classic `movetoworkspacesilent N,address:...` string — RESEARCH.md Q3 flags the specific-window-targeting field as unverified; Wave 0 spike required before writing this into the plan.

---

### `hypr/.config/hypr/config/windowrules.lua` (modified)

**Analog:** itself, `^quickshell-.*` namespace rules (lines 303-321, 357-358, 409-410)

The existing `^quickshell-.*` blur and `ignore_alpha: 0.5` layerrules cover `quickshell-overview` automatically by namespace match — only a new per-namespace `animation` rule (fade, D-16-24) needs adding, following the same declaration shape as the other per-namespace `animation` entries at lines 303-321.

## Shared Patterns

### Panel surface lifecycle (PanelWindow + WlrLayershell + HyprlandFocusGrab + LazyLoader)
**Source:** `modules/Dashboard.qml:199-205,438` and `shell.qml:136-144`
**Apply to:** `Overview.qml`

### Zero-idle-footprint gating
**Source:** `shell.qml:162-167` (`audioTruthNeeded` pattern — gate backend polling on `loader.active`)
**Apply to:** `Overview.qml`'s `ScreencopyView` instances (must stop capturing when `LazyLoader.active` goes false)

### IpcHandler verb-per-surface
**Source:** `shell.qml:315-347`
**Apply to:** D-16-23's capture-check verb

### Declared-manifest shortcut registration
**Source:** `shell.qml:349-361` + `shortcuts.json` (4 existing entries)
**Apply to:** new `Super+O` shortcut (5th entry)

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Drag-drop interaction (`DragHandler`/`Drag`) | component | event-driven | No `DragHandler` usage anywhere in `quickshell/.config/quickshell/modules/` — build from QtQuick stock API, no in-repo precedent |
| `Hyprland.dispatch()` call site (window move) | service | request-response | No prior QML file in this repo calls `Hyprland.dispatch()` — first use; exact Lua-wrapped dispatch string for non-focused window targeting is unverified (RESEARCH.md Q3, Wave 0 spike required) |

## Metadata

**Analog search scope:** `quickshell/.config/quickshell/modules/` (+ `dashboard/` subdir), `quickshell/.config/quickshell/shell.qml`, `hypr/.config/hypr/config/{keybinds,windowrules,permissions}.lua`
**Files scanned:** `ScreencopyProbe.qml`, `Dashboard.qml`, `shell.qml`, `QuickToggles.qml`, `Cascade.qml`, `keybinds.lua`, `windowrules.lua`
**Pattern extraction date:** 2026-08-03
