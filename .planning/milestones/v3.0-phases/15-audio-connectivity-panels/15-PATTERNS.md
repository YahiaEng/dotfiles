# Phase 15: Audio + Connectivity Panels - Pattern Map

**Mapped:** 2026-08-01
**Files analyzed:** 9 (new) + 6 (modified)
**Analogs found:** 9 / 9 (all have a strong or exact analog; nothing falls into "no analog")

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml` | shared surface/component (frame) | request-response (layer-shell summon/dismiss) | `quickshell/.config/quickshell/modules/Dashboard.qml` (lines 1-260) | exact — same `PanelWindow`+`WlrLayershell`+`HyprlandFocusGrab` skeleton, parameterized |
| `quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml` | component (panel body) | CRUD (read/write PipeWire state) | `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` (row/chip composition, pending model) + `MediaTab.qml` (tab body shape) | role-match |
| `quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml` | component (panel body) | CRUD + event-driven (scan results, connectionFailed signal) | `QuickToggles.qml` (pending/watchdog/failure display) + `MediaTab.qml` (scrolling list body) | role-match |
| `quickshell/.config/quickshell/modules/dashboard/BluetoothPanel.qml` | component (panel body) | CRUD + event-driven (state-transition inferred failure) | `QuickToggles.qml` (pending/watchdog) + `MediaTab.qml` (list body) | role-match |
| `quickshell/.config/quickshell/modules/dashboard/AudioBackend.qml` | backend/service adapter (reader+writer) | streaming (reactive property bindings, no polling) | `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` | exact — same `Scope` root, `drawerOpen`-style lifecycle gate, fixed-argv discipline (adapted: native binding, no `Process` needed for reads) |
| `quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml` | backend/service adapter | streaming + event-driven | `MediaBackend.qml` (lifecycle-gate shape) + `WeatherBackend.qml` (async/derived-state shape) | role-match |
| `quickshell/.config/quickshell/modules/dashboard/BluetoothBackend.qml` | backend/service adapter | streaming + event-driven | `MediaBackend.qml` (lifecycle-gate shape) | role-match |
| `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` (MODIFIED) | component (grid) | CRUD (toggle state), event-driven (subscribe stream) | itself — extend chipModel 3→6, split press vs chevron | exact (self-modification) |
| `quickshell/.config/quickshell/shell.qml` (MODIFIED) | shell root / composition | request-response (LazyLoader summon) | itself — mirrors existing `dashboardLoader`/`MediaBackend` mounting block (lines 64-118) | exact |
| `quickshell/.config/quickshell/modules/dashboard/qmldir` (MODIFIED) | config (module manifest) | — | itself | exact |
| `quickshell/.config/quickshell/shortcuts.json` (MODIFIED) | config (declared keybind manifest) | — | itself (existing 3-entry array) | exact |
| `hypr/.config/hypr/config/keybinds.lua` (MODIFIED) | config | — | existing `mainMod` bind block | exact |
| `hypr/.config/hypr/config/windowrules.lua` (MODIFIED) | config (layer rules) | — | existing `quickshell-dashboard` / `^quickshell-.*` rule pair (lines 303, 339-340) | exact |
| `waybar/.config/waybar/config-{athena,floating,vertical}.jsonc` + `modules.jsonc` (MODIFIED) | config (click wiring) | request-response | existing `network`/`bluetooth`/`group/audio` on-click definitions | exact |
| `install.sh` (MODIFIED) | config (package manifest) | — | existing `PACMAN_PKGS` entries (`pavucontrol` line ~111, `blueman` line ~212) | exact |
| `hypr/.config/hypr/scripts/quickshell-doctor` (MODIFIED) | test/verification script | batch (summon-and-diff) | itself — existing namespace-conformance / single-Notifications-owner checks | exact |

## Pattern Assignments

### `PanelDialog.qml` (shared frame component, request-response)

**Analog:** `quickshell/.config/quickshell/modules/Dashboard.qml`

**Imports pattern** (lines 46-51):
```qml
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "dashboard"
```

**Surface skeleton to copy wholesale** (lines 53-64, 187-202, verified live source, reproduced exactly in RESEARCH.md Pattern 1):
```qml
PanelWindow {
    id: panelWindow
    signal dismissRequested()
    anchors.top: true
    readonly property int drawerTopMargin: 10
    margins.top: panelWindow.drawerTopMargin

    exclusiveZone: 0
    exclusionMode: ExclusionMode.Normal

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-<panel-name>"   // D-42/D-43 family prefix
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"
}
```
Note D-15-03: PanelDialog reuses `anchors.top: true` only (no width-driven-by-tab logic like Dashboard's `activeContentWidth` — panels are FIXED height/width per D-15-07, so the `Behavior on implicitWidth/implicitHeight` block at Dashboard.qml:170-185 and the whole `drawerWidth`/`drawerHeight` dynamic-geometry mechanism at lines 95-161 should NOT be copied — that machinery exists specifically for Dashboard's per-tab dynamic sizing, which D-15-07 explicitly rejects for panels ("one fixed height shared by all three panels").

**HyprlandFocusGrab pattern** — not shown inline in the read range above but referenced at CONTEXT.md line 482 as `Dashboard.qml:419`:
```qml
HyprlandFocusGrab {
    windows: [ panelWindow ]
    active: true
    onCleared: panelWindow.dismissRequested()
}
```

**Design-token constants block to copy** (lines 204-233) — the same `Design`/`Colours`/`Motion`-derived readonly properties (`spacingXs/Sm/Md/Lg/Xl`, `fontDisplay/Heading/Body/Label`, `weightDisplay/Emphasis/Body`, `cornerRadius: 28`, `surfaceBase: Colours.surface`) should be re-declared on PanelDialog's window root exactly as Dashboard.qml does, so panel body files (`AudioPanel.qml` etc.) read them the same way DashboardTab.qml/MediaTab.qml do off `dashboardWindow`.

**Dismissal wiring pattern** — `shell.qml` LazyLoader pattern below is the corresponding half.

---

### `AudioBackend.qml` / `WifiBackend.qml` / `BluetoothBackend.qml` (backend adapters, streaming)

**Analog:** `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml`

**Root type + lifecycle gate pattern** (lines 1-56):
```qml
import QtQuick
import Quickshell
import Quickshell.Io   // swap for Quickshell.Networking / Quickshell.Bluetooth /
                        // Quickshell.Services.Pipewire in the new backends

Scope {
    id: root
    // Lifecycle gate — bound by shell.qml to the panel's own LazyLoader.active.
    // For Phase 15 this should be `panelOpen`, not `drawerOpen`, gating
    // Networking.devices[wifi].scannerEnabled / Bluetooth.defaultAdapter.discovering
    // per D-15-15/D-15-18's zero-idle-when-closed requirement.
    property bool panelOpen: false

    readonly property string homeDir: Quickshell.env("HOME")
    // ... derived/filtered properties re-exposing only what the panel body needs
}
```

**Deviation from MediaBackend.qml to note explicitly:** MediaBackend.qml's core mechanism is a long-lived subprocess (`media-status.sh --subscribe`) parsed via `SplitParser`, because there is no native QML binding for MPRIS in that phase's design. Phase 15's three backends do NOT need a `Process`/`SplitParser` pair for reads — `Quickshell.Networking`/`Bluetooth`/`Services.Pipewire` are native reactive QML bindings (RESEARCH.md Standard Stack). The correct pattern to copy is only the **shape** (Scope root, lifecycle-gated derived properties, "one shared instance mounted at shell.qml, panel bodies never touch the raw singleton directly") — not the Process/SplitParser mechanics. `QuickToggles.qml`'s DND subscribe/poll fallback pattern (lines 189-242) is the closer analog IF a Wave-0 probe finds any of the three native bindings insufficiently reactive and a CLI-wrapper fallback becomes necessary — but per RESEARCH.md's "Don't Hand-Roll" table this should not be needed.

**Filtering-the-object-graph pattern** (RESEARCH.md Pattern 2, to be implemented fresh — no existing repo analog for `UntypedObjectModel` iteration; flagged as a Wave-0 verification item, not a copy-from-existing-code item):
```qml
import Quickshell.Networking
readonly property var wifiDevice: {
    // resolve Networking.devices -> filter type === DeviceType.Wifi
    // exact accessor shape (.count/.get(i) vs array-like) UNVERIFIED —
    // see RESEARCH.md Pitfall 4, gate this with a live probe first
}
```

---

### `QuickToggles.qml` (MODIFIED — extend to six tiles, split press/chevron)

**Analog:** itself (self-modification), full pending/watchdog/tooltip pattern already in file.

**Pending model to reuse verbatim for the three new tiles** (lines 244-275):
```qml
property string pendingChip: "" // extend enum to include "volume" | "wifi" | "bluetooth"
readonly property int chipTimeoutMs: 3000
Timer {
    id: chipWatchdogTimer
    interval: root.chipTimeoutMs
    repeat: false
    onTriggered: root.pendingChip = ""
}
onGamingStateChanged: if (root.pendingChip === "gaming") { root.pendingChip = ""; chipWatchdogTimer.stop(); }
// mirror for volumeMuted/wifiEnabled/bluetoothEnabled backing properties
```

**Idempotency + press-guard pattern** (lines 322-353):
```qml
function pressGaming() {
    if (root.pendingChip !== "")
        return;
    root.pendingChip = "gaming";
    chipWatchdogTimer.restart();
    gamingProcess.running = true;
}
```
Adapt directly for the Volume/Wi-Fi/Bluetooth tile body-press verbs (mute toggle / radio on-off / adapter on-off).

**Split-affordance requirement (D-15-01):** no existing chip in this file has a chevron sub-affordance yet — this is new UI within the established `ToggleChip` inline component (lines 393-547). The MouseArea/ToolTip/pending-pulse layer structure (lines 436-547) is the base to extend with a second, smaller chevron-hit MouseArea that calls a distinct `openPanel(name)` function rather than `pressChipByName`.

**startDetached() pattern — mandatory for all three panels' Advanced buttons** (lines 292-320, and the `darkProcess`/`pressDark()` pair at 317-353):
```qml
Process {
    id: advancedProcess
    command: [ "pavucontrol" ]   // or nm-connection-editor / blueman-manager, fixed argv, T-14-13
}
function openAdvanced() {
    advancedProcess.startDetached();   // NOT running: true — see QuickToggles.qml:292-316's
                                        // full rationale (focus-stealing app race with
                                        // panel's own destroy-on-dismiss LazyLoader)
}
```

**chipModel array to extend from 3 to 6 entries** (lines 382-388) — add Volume/Wi-Fi/Bluetooth entries in the same `{ name, label, glyph, tooltip }` shape; D-15-21's hard constraint means "Do Not Disturb"'s existing entry (line 386) must be left untouched, not shortened.

---

### `shell.qml` (MODIFIED — mount three panel LazyLoaders + backends)

**Analog:** itself — the existing `dashboardLoader` + `MediaBackend`/`WeatherBackend`/`SystemResources` sibling-mounting block.

**LazyLoader summon pattern to replicate three times** (lines 69-81):
```qml
LazyLoader {
    id: audioPanelLoader   // wifiPanelLoader, bluetoothPanelLoader
    active: false

    AudioPanel {
        // backend: audioBackendInstance
        onDismissRequested: audioPanelLoader.active = false
    }
}
```

**Shared-backend sibling-mount pattern** (lines 93-101, 115-118):
```qml
AudioBackend {
    id: audioBackendInstance
    panelOpen: audioPanelLoader.active
}
```
Per D-15-02, each panel's `HyprlandFocusGrab` clears the drawer's own grab — no extra shell.qml wiring is needed to "close the drawer first"; opening any panel loader is independent, exactly like `dashboardLoader`/`screencopyProbeLoader`/`probeInstance` today (lines 44-81) are three independent LazyLoaders coexisting at the same root.

**GlobalShortcut pattern for `Super+A`** (lines 167-197, the `dashboardShortcut` block is the closest 1:1 analog minus the fullscreen-refusal guard, which does not apply to panels):
```qml
GlobalShortcut {
    id: audioPanelShortcut
    appid: "quickshell"
    name: "audio-panel"
    onPressed: audioPanelLoader.active = !audioPanelLoader.active   // D-15-04: toggle, no fullscreen guard
}
```

---

### `shortcuts.json` (MODIFIED — fourth manifest entry)

**Analog:** itself (existing 3-entry array, verbatim shape).
```json
{
  "appid": "quickshell",
  "name": "audio-panel",
  "chord": { "mods": "SUPER", "key": "A" },
  "description": "Summon the audio mixer panel (PANEL-01/PANEL-02)"
}
```

---

### `windowrules.lua` (MODIFIED — per-namespace layer motion for 3 panels)

**Analog:** itself — `quickshell-dashboard`'s own three rule sites (lines 303, 339-340).
```lua
hl.layer_rule({ match = { namespace = "quickshell-audio-panel" }, animation = "slide" })
-- repeat for quickshell-wifi-panel / quickshell-bluetooth-panel
```
Note: the family-wide `^quickshell-.*` blur/ignore_alpha rules (lines 339, 342 region 359) already cover all three new namespaces automatically — D-42/D-43's whole point is that no new blur/opacity rule is needed, only the per-namespace `animation = "slide"` entry (mirroring line 303) if per-namespace timing/curve tuning is wanted at the render gate (D-15's render-gate discretion note).

---

### `waybar/config-{athena,floating,vertical}.jsonc` + `modules.jsonc` (MODIFIED — click rewiring)

**Analog:** itself — existing `group/audio` (~line 316), `network` (~346), `bluetooth` (~356-357) on-click definitions in `config-athena.jsonc`.

Pattern: on-click values are shell command strings invoking a small script (same convention `quickshell-doctor`'s summon-and-diff already expects to interact with). D-15-05's rewiring should point `network`'s left-click and `bluetooth`'s left-click at a `qs ipc call` (or equivalent GlobalShortcut-trigger) targeting the new wifi/bluetooth panels, while preserving `group/audio`'s existing left-click mute toggle and adding a right-click for the audio panel — mirror the exact on-click/on-click-right key-pair shape already used for `bluetooth`'s existing `rfkill toggle bluetooth` right-click.

---

### `install.sh` (MODIFIED — D-15-23 correction)

**Analog:** itself — `pavucontrol` (line ~111) and `blueman` (line ~212) `PACMAN_PKGS` entries.
```bash
network-manager-applet
```
Add as one bare array entry alongside the two existing lines; no separate hard-fail class needed — `verify_packages()` (install.sh:611-630) already iterates all of `PACMAN_PKGS` + `AUR_PKGS`.

---

### `quickshell-doctor` (MODIFIED — D-15-25 new checks)

**Analog:** itself — existing namespace-conformance check (lines 221-241) and single-`org.freedesktop.Notifications`-owner check (lines 295-304).

Pattern: extend the existing summon-and-diff mechanism (before/during/after `busctl`/`hyprctl -j layers` snapshot diffing) to run once per new panel namespace, reusing the exact assertion shape already proven for the dashboard drawer — do not invent a second verification mechanism.

## Shared Patterns

### Layer-shell surface skeleton (PanelWindow + WlrLayershell + HyprlandFocusGrab)
**Source:** `quickshell/.config/quickshell/modules/Dashboard.qml` lines 53-64, 187-202, and the `HyprlandFocusGrab` block near line 419
**Apply to:** `PanelDialog.qml` (all three panel instances inherit this through composition)

### Truth-driven pending model + backend watchdog (D-22, extended to a fourth "failed" state by D-15-09)
**Source:** `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` lines 244-275 (pendingChip + chipWatchdogTimer), 322-353 (press-guard functions)
**Apply to:** All three panel bodies' row-scoped connect/pair/forget actions, and the extended six-tile grid.

### `startDetached()` for every process that must outlive the summoning surface
**Source:** `QuickToggles.qml` lines 292-320 (full rationale), `darkProcess`/`pressDark()` at 317-353
**Apply to:** All three panels' Advanced buttons (pavucontrol / nm-connection-editor / blueman-manager launches) — mandatory, not discretionary, per D-15-02 making the destroy-on-dismiss race certain to occur on every click.

### Fixed-argv discipline (T-14-13) — no state-derived value ever reaches a command array
**Source:** `QuickToggles.qml` lines 277-320 (comment block + all four `Process` declarations)
**Apply to:** The three Advanced-button `Process` commands. Also the deciding rationale (RESEARCH.md, D-15-14) for why wifi PSK entry must use `WifiNetwork.connectWithPsk()` (native D-Bus call) and never a `Process`-wrapped `nmcli ... password ...` invocation.

### Shared-backend sibling-mount + lifecycle-gate pattern
**Source:** `quickshell/.config/quickshell/shell.qml` lines 64-118 (`dashboardLoader`, `MediaBackend`/`WeatherBackend`/`SystemResources` mounted as siblings, gated by `drawerOpen: dashboardLoader.active`)
**Apply to:** `AudioBackend`/`WifiBackend`/`BluetoothBackend`, each gated by its own panel's `LazyLoader.active` (renamed `panelOpen` per D-15-15/D-15-18's zero-idle-when-closed requirement — scanning/discovery must stop on dismiss).

### Declared-manifest keybind pattern (module registration discipline)
**Source:** `quickshell/.config/quickshell/shortcuts.json` (3-entry array), `quickshell/.config/quickshell/modules/dashboard/qmldir` (module-manifest header comments explaining "a type MUST be registered in the SAME commit that creates it")
**Apply to:** `shortcuts.json`'s fourth entry (`Super+A`) and `qmldir`'s new type registrations for `PanelDialog`/`AudioPanel`/`WifiPanel`/`BluetoothPanel`/`AudioBackend`/`WifiBackend`/`BluetoothBackend` — same same-commit registration rule, same non-singleton instance style (none of the seven new types should carry `singleton`, matching `MediaBackend`/`WeatherBackend`/`SystemResources`/`QuickToggles`'s existing non-singleton entries in qmldir, not `Design`/`WeatherPalette`'s singleton pattern).

### Zero hex/duration literal invariant (motion-lint / colour-lint enforced repo-wide)
**Source:** `15-UI-SPEC.md` Design System section; enforced values live in `Design.qml`, `Colours.qml`, `Motion.qml` (all three read in full by gsd-ui-researcher for the UI-SPEC already produced this phase)
**Apply to:** Every new panel QML file without exception — all spacing via `Design.spacing*`, all colour via `Colours.<role>`, all duration/easing via `Motion.*Duration`/`Motion.*Easing`.

## No Analog Found

None — every file in this phase's scope has at least a role-match analog already committed in the repo. The one genuinely novel piece of logic (`UntypedObjectModel` iteration for `Networking.devices`/`Bluetooth.devices`/`Pipewire.nodes`) has no repo precedent because no prior phase has consumed a native Quickshell service singleton list — RESEARCH.md already flags this as a Wave-0 live-probe item (Pitfall 4), not a "no analog, use RESEARCH.md" gap in the pattern-mapping sense, since RESEARCH.md's own Code Examples section is the fallback source for that one snippet.

## Metadata

**Analog search scope:** `quickshell/.config/quickshell/` (shell.qml, modules/, modules/dashboard/), `hypr/.config/hypr/config/` (keybinds.lua, windowrules.lua), `hypr/.config/hypr/scripts/` (quickshell-doctor), `waybar/.config/waybar/` (config-*.jsonc, modules.jsonc), `install.sh`
**Files scanned:** Dashboard.qml, shell.qml, QuickToggles.qml, MediaBackend.qml, WeatherBackend.qml, qmldir (dashboard + parent), shortcuts.json, windowrules.lua (rule region), config-athena.jsonc (referenced via CONTEXT.md line citations), install.sh (referenced via CONTEXT.md/RESEARCH.md line citations)
**Pattern extraction date:** 2026-08-01
