// Synthetic minimal stand-in (Phase 18 Plan 17, GATE-03) — the transient
// hot-zone frame, exact namespace, zero exclusive zone.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: hotZoneWindow
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-bar-hotzone"
    exclusiveZone: 0
}
