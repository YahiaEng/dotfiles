// Poisoned fixture (Phase 18 Plan 17, GATE-03) — a drop-in replacement
// for the compliant scan-root's bar/HotZone.qml, identical except its
// exclusiveZone is a non-zero literal. HotZone.qml is a registered row
// NOT permitted to reserve (D-18-24: transient, overlay, noreserve).
// Proves the forward-half's reservation-permission guard FAILS when a
// registered noreserve row starts quietly reserving — the structural
// protection QBAR-12's stability assertion depends on, since a second
// reserving surface would move the number that check asserts is stable
// with no way to say where the drift came from.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: hotZoneWindow
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-bar-hotzone"
    exclusiveZone: 12
}
