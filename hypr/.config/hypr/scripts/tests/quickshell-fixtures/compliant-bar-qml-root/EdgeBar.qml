// Synthetic minimal stand-in (quick task 260823-9ak, Task 3) — declares its
// computed namespace and its permanent reservation exactly as the real
// EdgeBar.qml does. A second permanent, reserving row alongside Bar.qml's
// own — proving the registry tolerates more than one reserving surface
// (GT-3) without breaking the live half's `permanent == 1` cardinality
// (that count only increments on an EXACT match of "quickshell-bar").
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: edgeBarWindow
    property bool bottom: false
    exclusiveZone: 8
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-baredge-" + (edgeBarWindow.bottom ? "bottom" : "top")
}
