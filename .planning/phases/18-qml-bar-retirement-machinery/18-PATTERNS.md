# Phase 18: QML Bar & Retirement Machinery - Pattern Map

**Mapped:** 2026-08-10
**Files analyzed:** 15 (new + modified)
**Analogs found:** 13 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `quickshell/.config/quickshell/modules/Bar.qml` | component (surface root) | event-driven | `quickshell/.config/quickshell/modules/Overview.qml` | exact (single-`PanelWindow`/`WlrLayershell` posture) |
| `quickshell/.config/quickshell/modules/bar/BarCapsule.qml` | component | transform | `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` (segmented-pill idiom) | role-match |
| `quickshell/.config/quickshell/modules/bar/BarEntryModel.qml` | model | transform | `quickshell/.config/quickshell/modules/Overview.qml` (`workspaceForSlot`/fixed-slot resolution functions) | partial-match |
| `quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml` | component | event-driven | `quickshell/.config/quickshell/modules/Overview.qml` (workspace resolution + dispatch + live icon/window model) | role-match |
| `quickshell/.config/quickshell/modules/bar/TrayCapsule.qml` | component | event-driven | none in-repo (first `SystemTray`/`DBusMenu` consumer) — see "No Analog Found" | no analog |
| `quickshell/.config/quickshell/modules/bar/HotZone.qml` | component (input-only surface) | event-driven | none in-repo (first present-only-while-hidden surface) — see "No Analog Found" | no analog |
| `quickshell/.config/quickshell/modules/bar/SectionPopout.qml` | component (new frame) | request-response | `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml` | contrast case (deliberately NOT reused, per D-18-15) |
| `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` (MODIFIED) | service | streaming | itself, pre-repoint (bash-poll reader → native `Mpris` singleton) | exact (same file, repointed) |
| `quickshell/.config/quickshell/modules/dashboard/Design.qml` (MODIFIED) | config | — | itself (append-only token additions) | exact |
| `quickshell/.config/quickshell/shell.qml` (MODIFIED) | provider/router (shell root) | event-driven | itself — `openPanel()`/`panelIpc`/`overviewIpc`/`Connections{onRawEvent}` patterns | exact |
| `hypr/.config/hypr/scripts/bar-visibility.sh` (RENAMED from `waybar-visibility.sh`) | service (single-owner state machine) | CRUD (flock'd RMW over flat files) | itself pre-rename | exact (only actuation call swapped) |
| `hypr/.config/hypr/scripts/retirement-check` | utility (checklist) | batch | `theme-engine/.config/theme-engine/theme-doctor`'s fold pattern + `hypr/.config/hypr/scripts/waybar-visibility.sh`'s `<source>` allowlist validation | role-match |
| `theme-engine/.config/theme-engine/theme-doctor` (MODIFIED) | config/utility (fold site) | batch | itself — `waybar-design-lint` fold (~660) / `motion-lint` fold (~681) | exact |
| `hypr/.config/hypr/scripts/quickshell-doctor` (MODIFIED) | test/utility | batch | itself — `_qsd_check_*` + `check()` + `_qsd_check_reserved_array_manifest_coverage` (the check GATE-03 must invert, not extend) | exact |
| `hypr/.config/hypr/scripts/quickshell-launch.sh` (MODIFIED, or superseded by unit) | config | — | itself; new artifact `quickshell.service` has **no unit-file analog in this repo** — see "No Analog Found" | no analog for the unit; script itself is self-analog |

## Pattern Assignments

### `quickshell/.config/quickshell/modules/Bar.qml` (component, event-driven)

**Analog:** `quickshell/.config/quickshell/modules/Overview.qml`

**Imports pattern** (Overview.qml:19-24):
```qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "overview"
import "dashboard"
```
Bar.qml should mirror this shape: `import "bar"` (its own component dir) alongside `import "dashboard"` for `Design`/`Colours`/`Motion`.

**Layer posture / core pattern** (Overview.qml:26-56, and the RESEARCH.md-verified skeleton at 18-RESEARCH.md lines 420-441):
```qml
PanelWindow {
    id: barWindow
    anchors { top: true; left: true; right: true }   // horizontal; swap to top/bottom/right for vertical (D-18-13)
    WlrLayershell.layer: WlrLayer.Top          // NOT Overlay — always-on chrome, not a transient dialog
    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: Design.barHeight + Design.barEdgeMargin   // 46 — single margin, D-18-38 correction, NOT *2
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
}
```
No `Variants` fan-out — QS-03 is permanently dropped (D-13). This is the single most load-bearing thing to copy: Overview.qml's own header comment (lines 36-44 concept, `shell.qml` too) documents the FM2 per-screen fan-out failure this must not reproduce.

**Dispatch pattern (workspace click, QBAR-03)** (Overview.qml:216-243, `activateTile`/`dispatchWorkspaceFocus`):
```qml
function dispatchWorkspaceFocus(slotIndex) {
    if (!overviewWindow.isValidWorkspaceToken(id)) {   // T-16-25: validate before interpolating
        console.warn("...refusing workspace focus — slot index out of range");
        return false;
    }
    Hyprland.dispatch("hl.dsp.focus({workspace=" + String(id) + "})");
    return true;
}
```
Copy the validate-before-interpolate discipline verbatim for the bar's own click-to-switch handler — this is also the Security Domain V5 control RESEARCH.md calls out.

**Fullscreen-intent reporting (D-18-28)** — copy from `shell.qml:343-357`:
```qml
readonly property bool fullscreenBlocking: (Hyprland.activeToplevel?.lastIpcObject?.fullscreen ?? 0) === 2
Connections {
    target: Hyprland
    function onRawEvent(event) {
        if (event.name === "fullscreen") {
            Hyprland.refreshToplevels();
        }
    }
}
```
Bar.qml (or a `Connections` block at shell.qml root) reuses this exact combination to call `bar-visibility.sh fullscreen hide|show` — replacing the standalone `waybar-fullscreen-watch.sh` process (D-18-28).

**Error handling / catch-state pattern**: Overview.qml's `wholeGridCatchVisible`/`wholeGridCatch` Rectangle (lines 938-1012) is the established "whole-surface catch state" shape: never on `opacity` of an ancestor (regression fixed 72d04cd, see comment lines 965-974 — alpha goes into `Qt.rgba(...)`, never on the Rectangle's own `opacity`, because that also fades child text). The bar's per-capsule error state (Interaction States table, UI-SPEC) is simpler (`Colours.error`-tinted glyph only) but must follow the same "alpha in the colour, not the item" rule if any bar element ever needs a translucent error backing.

---

### `quickshell/.config/quickshell/modules/bar/BarCapsule.qml` (component, transform)

**Analog:** `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` (segmented-pill idiom) + `Overview.qml`'s mode-indicator pill (lines 645-664)

**Core pill pattern** (Overview.qml:645-664):
```qml
Rectangle {
    id: modeIndicator
    width: modeIndicatorLabelText.implicitWidth + Design.spacingMd * 2
    height: modeIndicatorLabelText.implicitHeight + Design.spacingXs * 2
    radius: height / 2
    color: Colours.surfaceVariant
    Text {
        anchors.centerIn: parent
        font.pixelSize: Design.fontLabel
        color: Colours.onSurfaceVariant
    }
}
```
`radius: height / 2` is the exact idiom UI-SPEC's `barCapsuleRadius` token cites (`QuickToggles.qml`/`Overview.qml`'s "full pill" convention, confirmed live at `QuickToggles.qml:1005` too). Fill `Colours.surfaceVariant` at rest, `Colours.surface` on hover — same `Behavior on color` idiom as `PanelDialog.qml:170-177`.

**Hover/active state Behavior pattern** (`PanelDialog.qml:170-177`):
```qml
Behavior on color {
    enabled: Motion.motionEnabled
    ColorAnimation {
        duration: Motion.standardDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.standardEasing
    }
}
```

---

### `quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml` (component, event-driven)

**Analog:** `quickshell/.config/quickshell/modules/Overview.qml`

**Live workspace resolution** (Overview.qml:172-201):
```qml
function workspaceForSlot(slotId) {
    var list = Hyprland.workspaces.values;
    for (var i = 0; i < list.length; i++) {
        if (list[i].id === slotId) return list[i];
    }
    return null;
}
function isFocusedSlot(slotId) {
    return !!(Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === slotId);
}
```
This is the direct template for D-18-12's fixed-height-slot + `+N` overflow model — read live `Hyprland.workspaces.values`/`.toplevels.values` (Overview.qml:304-309, `toplevelsForSlot`) the same way, capped at the slot's rendering capacity instead of Overview's unlimited thumbnail row.

**Per-app icon fallback (D-18-02 partial-resolution state, mirrors UI-SPEC E2 partial)**: no direct analog exists for a per-app glyph map in QML — seed from `waybar/.config/waybar/config-athena.jsonc`'s `window-rewrite` table (Claude's Discretion, CONTEXT.md), falling back to the same `"apps"` Material Symbol placeholder the tray uses for a broken pixmap (UI-SPEC's own cross-reference, "one placeholder glyph across the whole bar, not two conventions").

---

### `quickshell/.config/quickshell/modules/bar/TrayCapsule.qml` (component, event-driven)

**No direct analog** — first `SystemTray`/`DBusMenu` consumer in this repo. Build from the verified `.qmltypes` pattern already captured in RESEARCH.md's Pattern 2 (Code Examples section, `18-RESEARCH.md` lines 264-301):
```qml
import Quickshell.Services.SystemTray
import Quickshell.DBusMenu
import Quickshell

Repeater {
    model: SystemTray.items
    delegate: Item {
        required property var modelData
        MouseArea {
            anchors.fill: parent
            onClicked: modelData.activate()
            onSecondaryClicked: menuOpener.open()
        }
        QsMenuOpener {
            id: menuOpener
            menu: modelData.menu
        }
    }
}
```
**Open question (RESEARCH.md A1):** the exact `QsMenuEntry` click-trigger invokable was not confirmed in the scanned `.qmltypes` — verify against Quickshell's own upstream example shells before wiring the click handler; do not invent one.

**Structural precedent for bounded-growth-then-scroll** (`trayMaxExtent`): no existing QML file has this exact shape; nearest conceptual sibling is `PanelDialog.qml`'s `Flickable`/`bodyFlick` (lines 317-333) for "unbounded content in a bounded frame" — reuse `Flickable`/`boundsBehavior: Flickable.StopAtBounds` internally once the tray's icon row exceeds `trayMaxExtent`.

---

### `quickshell/.config/quickshell/modules/bar/HotZone.qml` (component, event-driven)

**No direct analog** — first "present only while hidden, input-only" surface. Structurally closest is the `LazyLoader`-per-surface summon idiom in `shell.qml` (lines 56-63, 70-92, 136-144, etc.) — created/destroyed via `active`, never merely hidden:
```qml
LazyLoader {
    id: someLoader
    active: false
    SomeSurface { onDismissRequested: someLoader.active = false }
}
```
`HotZone.qml` inverts this shape: it should be active *only while the bar is in a hidden state*, mounted via the same `LazyLoader.active` binding pattern so it costs zero timers/objects while the bar is visible (QBAR-11's zero-idle discipline). No existing input-only (`WlrKeyboardFocus.None`, click/hover-only) `PanelWindow` exists in this repo to copy chrome from — this is a bare `PanelWindow` with `color: "transparent"`, `exclusiveZone: 0`, spanning the full physical edge per D-18-25, containing only a `HoverHandler`/`MouseArea`.

---

### `quickshell/.config/quickshell/modules/bar/SectionPopout.qml` (component, request-response)

**Analog (contrast case, per D-18-15):** `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml`

Reuse verbatim:
- **Dismissal** (`PanelDialog.qml:200-208`, `HyprlandFocusGrab` + `dismissRequested()`):
```qml
HyprlandFocusGrab {
    id: grab
    windows: [ panelWindow ]
    active: true
    onCleared: panelWindow.requestDismiss()
}
```
- **Translucent background + rim** (`PanelDialog.qml:160-198`, `Qt.rgba(surfaceBase..., panelSurfaceOpacity)` + `GradientBorder`) — reuse `GradientBorder` component unchanged, same `borderWidth: Design.borderWidth`.
- **Entrance cascade** (`PanelDialog.qml:210-219`, `Cascade{}` + `Component.onCompleted` arming).
- **Namespace convention** (`PanelDialog.qml:130`, `WlrLayershell.namespace: "quickshell-" + panelWindow.namespaceSuffix`) → popout uses `"quickshell-bar-<section>"` per UI-SPEC.

**Deliberately DO NOT copy:**
- Fixed 850×620 size (`panelWidth`/`panelHeight`, lines 65-66) — popout is `popoutMinWidth`–`popoutMaxWidth` (300–360px), content-bounded.
- `anchors.top: true` only + compositor-centred posture (line 123) — popout anchors per-orientation off its triggering capsule (UI-SPEC "Anchoring per orientation").
- Bottom-only corner rounding (lines 160-167) — popout is uniformly rounded (`popoutCornerRadius`, all four corners), since it floats clear of every edge unlike `PanelDialog`.
- The Advanced-button chrome (lines 258-313) — popout instead gets a smaller "Open in dashboard" wayfinding link at the *foot*, not the header, reusing only the `Colours.surfaceVariant` pill + `disabledOpacity` (0.38) treatment (lines 287-303).

**Fourth-state placeholder grammar** (`PanelDialog.qml:335-366`, `emptyStatePlaceholder`) — reuse this exact "quiet Material Symbol + one line" shape for the popout's error state text, per UI-SPEC's Copywriting Contract.

---

### `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` (MODIFIED — service, streaming)

**Analog:** itself, pre-repoint. No Read was performed on the current body this session (out of budget), but RESEARCH.md's Code Examples section (lines 458-473) gives the exact repoint target:
```qml
import Quickshell.Services.Mpris
// Mpris.players is an UntypedObjectModel of MprisPlayer, exposing:
// identity, position, length, volume, trackTitle, trackArtist, trackArtists,
// trackAlbum, trackAlbumArtist, trackArtUrl, playbackState (Enum), loopState,
// shuffle, *Supported flags, play()/pause()/stop()/togglePlaying().
```
Preserve `MediaBackend.qml`'s existing `drawerOpen`-gated public property surface (consumed today by `Dashboard.qml`'s Media tab, per `shell.qml:104-107`) — only the internal reader swaps from `media-status.sh watch` (subprocess) to the native singleton; the gate gets **widened** to include "the bar is mounted" per D-18-05, which is the exact always-on-cost tradeoff Pitfall 7 in RESEARCH.md names explicitly — record it, don't let it be incidental.

---

### `quickshell/.config/quickshell/shell.qml` (MODIFIED — provider/router)

**Analog:** itself.

**Backend-mounting-at-root pattern** (`shell.qml:94-129`, `MediaBackend`/`WeatherBackend`/`SystemResources` mounted as root siblings, not inside a `LazyLoader`):
```qml
MediaBackend {
    id: mediaBackendInstance
    drawerOpen: dashboardLoader.active
}
```
Bar.qml is mounted the same way — NOT inside a `LazyLoader`, since D-18's whole premise is "always active, never destroyed" (the phase's own named inversion of every prior surface's summon-on-demand shape).

**Gate-widening pattern** (`shell.qml:146-167`, `audioTruthNeeded`):
```qml
readonly property bool audioTruthNeeded: dashboardLoader.active || audioPanelLoader.active
AudioBackend {
    id: audioBackendInstance
    panelOpen: root.audioTruthNeeded
}
```
The bar's own readouts widen this pattern again — e.g. `readonly property bool audioTruthNeeded: dashboardLoader.active || audioPanelLoader.active || true /* bar always live */` — but per Pitfall 7 this must be a **named, recorded** cost in the plan, not a silent side-effect of wiring the easy way.

**IPC handler pattern** (`shell.qml:369-401`, `panelIpc`):
```qml
IpcHandler {
    id: panelIpc
    target: "panel"
    function open(name: string): string { ... }
    function toggle(name: string): string { ... }
}
```
`bar-visibility.sh`'s new `qs ipc call` actuation target should be a sibling `IpcHandler` (e.g. `target: "bar"`, verbs `show`/`hide`/`hideIdle`) following this exact shape — plain property reads before/after, no direct external write to loader/window state from outside the handler.

**Fullscreen guard pattern** (`shell.qml:312-357`, `openPanel()`/`fullscreenBlocking`) — see Bar.qml section above; this is the shared source.

---

### `hypr/.config/hypr/scripts/bar-visibility.sh` (RENAMED from `waybar-visibility.sh`)

**Analog:** itself, pre-rename — the whole file is kept, per D-18-27 ("script stays sole owner... only actuation changes").

**Structure to preserve verbatim:**
- Flock'd RMW (`_acquire_lock`, lines 116-119) — single advisory lock serializing the whole compute→actuate critical section.
- Atomic unique-temp+mv writes (`_write_intent`/`_write_override`/`_write_actuated`/`_write_css`, lines 121-168).
- `<source>` allowlist validation BEFORE path construction (main()'s case statement, lines 300-333) — T-08-05 precedent, cited directly by RESEARCH.md's Security Domain V5 row as the pattern `retirement-check`'s `<surface-name>` arg must mirror.
- `_compute()`'s base-union / override-staleness logic (lines 178-230) — untouched.

**The only edit — actuation swap** (`_actuate()`, lines 236-271): replace
```bash
pkill -SIGUSR2 waybar 2>/dev/null || true
pkill -SIGUSR1 waybar 2>/dev/null || true
```
with `qs ipc call bar show|hideIdle|hide` (verb names TBD to match the new `IpcHandler` above). The `IDLE_DIM_OPACITY`/CSS-writing machinery (`_write_css`, `VISIBILITY_CSS`) is retired outright per D-18-23 — `hidden-idle` becomes a QML property flip, not a CSS opacity rule; delete `_write_css` and `VISIBILITY_CSS` rather than repointing them.

---

### `hypr/.config/hypr/scripts/retirement-check` (NEW)

**Analog:** `theme-engine/.config/theme-engine/theme-doctor`'s fold pattern (for the two-tier PASS/FAIL/REPORT output shape) + `hypr/.config/hypr/scripts/waybar-visibility.sh`'s allowlist validation (for the `<surface-name>` argument).

**Fold-compatible output contract**, matching what `theme-doctor` already expects to consume (per `theme-doctor:660-679`, the `waybar-design-lint` fold, and RESEARCH.md's own pre-written fold snippet at lines 475-493):
```bash
# retirement-check emits lines theme-doctor folds via:
case "$_rc_line" in
    *"[PASS]"*) check "retirement-check: ${_rc_line#*\[PASS\] }" "0" ;;
    *"[FAIL]"*) check "retirement-check: ${_rc_line#*\[FAIL\] }" "1" ;;
    *)          echo "  $_rc_line" ;;   # [REPORT]-tier (D-18-37's non-blocking .planning/ tier) passes through unfolded
esac
```
So `retirement-check` itself must print `[PASS]`/`[FAIL]` for the blocking tier (D-18-37) and a distinct marker (e.g. `[REPORT]`) for the non-blocking `.planning/`-prose tier, mirroring `motion-lint`'s own `[EXEMPT]`/`[WARN]` convention (deliberately NOT folded into PASS, per theme-doctor:687-689 comment — "an exemption is acknowledged debt, not a passing check").

**Argument validation** (`<surface-name>` before any path/grep-target construction) — copy `waybar-visibility.sh`'s case-statement-rejects-before-use discipline (lines 300-333) directly; RESEARCH.md's Security Domain table names this exact requirement.

---

### `theme-engine/.config/theme-engine/theme-doctor` (MODIFIED — fold site)

**Analog:** itself — the `waybar-design-lint` fold (lines 660-679) and `motion-lint` fold (lines 681-703) are the two existing instances of the exact pattern D-18-35 requires `retirement-check` to follow a third time, plus a fourth instance (`hypr-equivalence-check` fold, lines 705-714+) already exists as of Phase 14. Insert the `retirement-check` fold immediately after these three, using the verbatim snippet under `retirement-check`'s own Pattern Assignment above. The hardcoded waybar block at ~467-559 (per CONTEXT.md's canonical_refs) is what D-18-36 requires `retirement-check` itself to catch as a stray reference — do not simply delete that block without first confirming `retirement-check --all` flags it.

---

### `hypr/.config/hypr/scripts/quickshell-doctor` (MODIFIED — GATE-03 structural checks)

**Analog:** itself — `_qsd_check_*` registration pattern + `check()` helper (lines 201-211) + `_qsd_valid_token()` allowlist guard (lines 219-221).

**Registration shape to copy** (any of `_qsd_check_panel_namespace_conformance` at line 609, `_qsd_check_overview_namespace_conformance` at 846, etc. — all share this call-then-register shape at lines 1634-1637/1861-1867):
```bash
_qsd_check_<new_check_name>() {
    # ... compute ok=0|1 ...
    check "<description>" "$ok"
}
# near the bottom, alongside the existing call list:
_qsd_check_<new_check_name>
```

**The check that MUST be inverted, not extended (Pitfall 6):** `_qsd_check_reserved_array_manifest_coverage` (line 966) currently asserts "summoning every manifest surface leaves `monitors -j`'s `reserved` array byte-identical" (D-21's "stays unclaimed" invariant). QBAR-01 makes this assertion permanently false by design. GATE-03 must **rewrite** this check's assertion to "the bar's own reservation exists and is stable across `hyprctl reload` / QML hot reload" (QBAR-12's literal text) rather than layering a second, contradictory check beside it.

**Token-validation discipline** (`_qsd_valid_token`, line 219-221) — any new manifest-derived token (e.g. a popout's `namespaceSuffix`) reaching a `hyprctl`/dispatch argv must pass through this same `^[A-Za-z0-9_-]+$` allowlist before use, per RESEARCH.md's Security Domain table.

---

### `hypr/.config/hypr/scripts/quickshell-launch.sh` (MODIFIED) / `quickshell.service` (NEW, D-18-40)

**Analog for the script:** itself — guard-then-exec shape (lines 27-34), log rotation (17-25), `QSG_RENDER_LOOP=threaded` export (56) all stay. If the systemd-unit path (D-18-40) is taken, this script becomes the unit's `ExecStart=` target (still `exec quickshell -p "$CONFIG_DIR"`, unchanged), with `uwsm app --` removed from `autostart.lua` for quickshell specifically.

**No analog for `quickshell.service` itself** — see "No Analog Found" below; D-18-40 explicitly names `waybar.service` (a **packaged, upstream-shipped, currently-unused** unit, confirmed via `systemctl --user cat waybar.service` per RESEARCH.md Runtime State Inventory) as the shape to copy, but that file is not part of this repo's own tree (it ships inside the `waybar` pacman package, being deleted by RETIRE-02) — it cannot be Read from this repo and must be sourced live via `systemctl --user cat waybar.service` at implementation time, or reconstructed from RESEARCH.md's quoted fields (`Restart=on-failure` under `[Service]`).

---

## Shared Patterns

### Layer-shell posture (`WlrLayershell` + `PanelWindow`)
**Source:** `quickshell/.config/quickshell/modules/Overview.qml:26-56`, `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml:122-132`
**Apply to:** `Bar.qml`, `SectionPopout.qml`, `HotZone.qml`
```qml
WlrLayershell.layer: WlrLayer.Top   // or .Overlay for popout/hotzone, matching PanelDialog's Overlay
WlrLayershell.namespace: "quickshell-<suffix>"
WlrLayershell.keyboardFocus: WlrKeyboardFocus.None   // or .OnDemand for popout (needs Esc/click-outside)
exclusiveZone: <0 for popout/hotzone, Design.barHeight+Design.barEdgeMargin for the bar>
color: "transparent"
```

### Dismissal (`HyprlandFocusGrab` + `dismissRequested()`)
**Source:** `PanelDialog.qml:200-208`, `Overview.qml:1014-1021`
**Apply to:** `SectionPopout.qml` (pinned state, D-18-22)
```qml
signal dismissRequested()
HyprlandFocusGrab {
    windows: [ thisWindow ]
    active: true
    onCleared: thisWindow.dismissRequested()
}
```

### Motion `Behavior on color`
**Source:** `PanelDialog.qml:170-177`
**Apply to:** every hover/active-state transition on `BarCapsule.qml`, `SectionPopout.qml`
```qml
Behavior on color {
    enabled: Motion.motionEnabled
    ColorAnimation { duration: Motion.standardDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.standardEasing }
}
```

### Entrance cascade
**Source:** `Overview.qml:58-100`, `PanelDialog.qml:210-219`
**Apply to:** `SectionPopout.qml` entrance (D-18-15's UI-SPEC-specified `emphasizedIn`/`emphasizedOut` pair)
```qml
readonly property Cascade entranceCascade: Cascade {}
Component.onCompleted: {
    thisWindow.entranceCascade.bands = [ ... ];
    thisWindow.entranceCascade.armed = true;
    thisWindow.entranceCascade.run();
}
```

### Single-owner visibility state machine (flock'd RMW + per-source intent files)
**Source:** `hypr/.config/hypr/scripts/waybar-visibility.sh` (whole file), second instance `wallpaper-visibility.sh`
**Apply to:** `bar-visibility.sh` (kept wholesale, only actuation edited)

### Doctor-fold (PASS/FAIL line consumption into a running tally)
**Source:** `theme-engine/.config/theme-engine/theme-doctor:660-714` (three existing instances)
**Apply to:** `retirement-check`'s fold into `theme-doctor` (RETIRE-01/D-18-35)

### `_qsd_check_*` structural-check registration
**Source:** `hypr/.config/hypr/scripts/quickshell-doctor:201-211, 609+`
**Apply to:** every new GATE-03 check

### Validate-before-interpolate (command/dispatch-string injection guard)
**Source:** `Overview.qml:802-826` (`isValidWorkspaceToken`, `dispatchWindowMove`'s `/^0x[0-9a-fA-F]+$/` regex check), `quickshell-doctor:219-221` (`_qsd_valid_token`), `waybar-visibility.sh:300-333` (`<source>` case-statement allowlist)
**Apply to:** workspace-click dispatch in `WorkspaceCapsule.qml`, any manifest-derived token reaching `hyprctl`/`Hyprland.dispatch`/`qs ipc call` in `Bar.qml` or `quickshell-doctor`'s new checks, and `retirement-check`'s `<surface-name>` argument.

## No Analog Found

Files/artifacts with no close match in the codebase (planner should use RESEARCH.md's Code Examples / verified `.qmltypes` citations instead):

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `quickshell/.config/quickshell/modules/bar/TrayCapsule.qml` | component | event-driven | First `Quickshell.Services.SystemTray` + `Quickshell.DBusMenu`/`QsMenuOpener` consumer in this repo — no prior tray UI exists in QML (waybar's tray module is JSONC/GTK, not a QML analog). Build from RESEARCH.md's directly-`.qmltypes`-verified Pattern 2 code example instead. |
| `quickshell/.config/quickshell/modules/bar/HotZone.qml` | component | event-driven | First "present only while hidden, input-only surface on the physical screen edge" pattern — every existing surface is either always-absent-until-summoned (`LazyLoader`) or always-present (none, until this phase). Nearest structural cousin is the `LazyLoader.active` toggle idiom, cited above, but the surface's own content (a bare hit-test-only `PanelWindow`) has no precedent to copy chrome from. |
| `quickshell.service` (new systemd `--user` unit, D-18-40) | config (unit file) | — | **No systemd `--user` unit file exists anywhere in this repo's own tree.** Every autostart entry uses `uwsm app -- <script>` (`hypr/.config/hypr/config/autostart.lua:42/48/55/60/65`), producing transient scopes with no `Restart=` directive — confirmed explicitly in RESEARCH.md Pitfall 8/Common Pitfalls as "zero existing precedent in this repo for a custom systemd `--user` unit." The one cited shape to copy (`waybar.service`, `Restart=on-failure`) ships inside the `waybar` pacman package itself, not this repo, and is being deleted by RETIRE-02 in this same phase — read it live via `systemctl --user cat waybar.service` before it is uninstalled, or reconstruct from RESEARCH.md's quoted `[Service]` block. |

## Metadata

**Analog search scope:** `quickshell/.config/quickshell/{shell.qml,modules/**}`, `hypr/.config/hypr/scripts/{waybar-visibility.sh,quickshell-launch.sh,quickshell-doctor,motion-lint}`, `theme-engine/.config/theme-engine/theme-doctor`, `waybar/.config/waybar/config-athena.jsonc` (referenced, not re-read this session — already fully quoted in CONTEXT.md/UI-SPEC.md)
**Files scanned:** `Overview.qml` (1078 lines, full read), `shell.qml` (466 lines, full read), `PanelDialog.qml` (393 lines, full read), `waybar-visibility.sh` (336 lines, full read), `quickshell-launch.sh` (59 lines, full read), `QuickToggles.qml` (targeted grep, pill idiom confirmed at line 1005), `theme-doctor` (targeted read, lines 655-714, fold pattern), `quickshell-doctor` (targeted read, lines 195-234 + grep of all `_qsd_check_*` registrations)
**Pattern extraction date:** 2026-08-10

---

## PATTERN MAPPING COMPLETE

**Phase:** 18 - QML Bar & Retirement Machinery
**Files classified:** 15
**Analogs found:** 13 / 15

### Coverage
- Files with exact/role-match analog: 11
- Files with partial/contrast-case analog: 2 (`BarEntryModel.qml` partial; `SectionPopout.qml` is a deliberate contrast case against `PanelDialog.qml` per D-18-15)
- Files with no analog: 2 (`TrayCapsule.qml`, `HotZone.qml`) + 1 non-QML artifact (`quickshell.service` unit file)

### Key Patterns Identified
- The bar copies `Overview.qml`'s single-`PanelWindow`/no-`Variants` posture verbatim, only setting `exclusiveZone` non-zero (46px, single-margin per D-18-38) where every prior surface used 0.
- Every new hover/dismiss/entrance-motion behavior on `SectionPopout.qml` reuses `PanelDialog.qml`'s exact mechanisms (`HyprlandFocusGrab`, `Cascade`, `Behavior on color`) while deliberately rejecting its fixed-size/bottom-rounded/centred frame shape — the popout is a second frame by design (D-18-15), brought into visual parity by construction wherever possible.
- `bar-visibility.sh` is a rename-and-repoint of `waybar-visibility.sh`'s existing flock'd, atomic-write, allowlist-validated state machine — the RMW/lock/atomic-write core is untouched; only `_actuate()`'s two `pkill` lines become `qs ipc call`.
- `retirement-check` and GATE-03's new `quickshell-doctor` checks both follow the two existing structural conventions in this repo (`theme-doctor`'s PASS/FAIL fold; `quickshell-doctor`'s `_qsd_check_*`/`check()`/`_qsd_valid_token` registration) rather than inventing new tooling shapes.
- Tray/menu (SystemTray+DBusMenu) and the hot-zone reveal surface are genuinely novel in this repo — no QML analog exists; both must be built from RESEARCH.md's directly-`.qmltypes`-verified code examples, not from an existing file.

### File Created
`/home/aorus/dotfiles/.planning/phases/18-qml-bar-retirement-machinery/18-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can now reference analog patterns in PLAN.md files.
