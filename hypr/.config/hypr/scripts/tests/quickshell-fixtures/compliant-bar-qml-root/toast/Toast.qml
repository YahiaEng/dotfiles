// Synthetic minimal stand-in (Phase 19 registry rows, added 2026-08-14) —
// the transient toast frame, exact namespace, zero exclusive zone.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: toastWindow
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notif-toast"
    exclusiveZone: 0
}
