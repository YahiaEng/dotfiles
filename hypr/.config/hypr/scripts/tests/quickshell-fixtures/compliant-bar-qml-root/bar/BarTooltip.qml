// Synthetic minimal stand-in (Phase 18 Plan 17, GATE-03; row added by quick
// task 260812-69w, stub added by quick task 260812-pd5) — the transient
// bar-tooltip family, computed namespace suffix, zero exclusive zone.
//
// Its absence was a real gap, not a cosmetic one: 260812-69w added the
// `bar/BarTooltip.qml|quickshell-bartip-` registry row without adding this
// stub, so the forward closure counted it missing against every fixture root.
// That made `--self-test`'s own COMPLIANT case fail (rows=5 missing=1, where
// the case asserts the source half passes) and left `missing=1` sitting inside
// every poisoned case's result string, where it masked the number those cases
// actually assert on.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: tooltipRoot
    property string tipId: "idleInhibitor"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-bartip-" + tooltipRoot.tipId
}
