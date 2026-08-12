// Synthetic minimal stand-in (Phase 18 Plan 17, GATE-03; row added by quick
// task 260812-59l) — the transient vertical-drawer-host family, computed
// namespace suffix, zero exclusive zone.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: drawerRoot
    property string drawerId: "launcher"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-bardrawer-" + drawerRoot.drawerId
}
