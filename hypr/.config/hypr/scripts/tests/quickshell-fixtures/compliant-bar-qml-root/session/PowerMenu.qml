// Synthetic minimal stand-in (Phase 20 Plan 06 Task 2, D-20-33) — the
// power menu's registry row (session/PowerMenu.qml|quickshell-session|
// exact|3|noreserve|transient). Mirrors toast/Toast.qml's own shape in
// this same fixture directory (a direct WlrLayershell.namespace literal
// plus a literal exclusiveZone: 0), since the real PowerMenu.qml declares
// both directly rather than forwarding them from an instanced parent the
// way osd/Osd.qml does — no fallback marker exercised by this fixture.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: powerWindow
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-session"
    exclusiveZone: 0
}
