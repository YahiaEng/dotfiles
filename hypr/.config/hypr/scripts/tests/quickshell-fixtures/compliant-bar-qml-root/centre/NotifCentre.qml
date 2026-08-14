// Synthetic minimal stand-in (Phase 19 registry rows, added 2026-08-14) —
// the permanent notification centre, exact namespace, zero exclusive zone.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: notifCentreWindow
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notif-centre"
    exclusiveZone: 0
}
