// Poisoned fixture (Phase 18 Plan 17, GATE-03) — a frame declaring a real
// WlrLayershell.namespace whose FILE is neither a bar-surface registry
// row nor a member of QSD_KNOWN_NONBAR_FRAMES. Replayed by dropping this
// file ALONGSIDE the compliant-bar-qml-root/ tree in --self-test. Proves
// the reverse closure FAILS on a frame nobody registered — the whole
// point of that direction: the forward half alone cannot catch a NEW
// unregistered file, only a missing registered one.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: mysteryWindow
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-bar-mystery"
}
