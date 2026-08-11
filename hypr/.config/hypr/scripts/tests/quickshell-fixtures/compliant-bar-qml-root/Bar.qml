// Synthetic minimal stand-in (Phase 18 Plan 17, GATE-03) — declares its
// namespace and its conditional zone exactly as the real Bar.qml does.
// The permanent frame, the only row permitted to reserve.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: barWindow
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"
    readonly property int reservedZoneExtent: 46
    exclusiveZone: barWindow.zoneReserved ? barWindow.reservedZoneExtent : 0
    property bool zoneReserved: true
}
