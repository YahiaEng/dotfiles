// Synthetic minimal stand-in (Phase 18 Plan 17, GATE-03) — the transient
// section-popout family, computed namespace suffix, zero exclusive zone.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: popoutWindow
    property string sectionId: "audio"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-bar-" + popoutWindow.sectionId
}
