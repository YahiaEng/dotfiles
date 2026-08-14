// Synthetic minimal stand-in (Phase 19 registry rows, added 2026-08-14) —
// the permanent popup stack, exact namespace, zero exclusive zone.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: notifPopupStackWindow
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notif-popups"
    exclusiveZone: 0
}
