// poisoned-own-namespace-panel.qml — derived from compliant-panel.qml
// (itself a trimmed excerpt of the real, shipped AudioPanel.qml) with
// exactly one defect introduced: a WlrLayershell.namespace assignment
// copied from PanelDialog.qml's own real line (`WlrLayershell.namespace:
// "quickshell-" + panelWindow.namespaceSuffix`, quickshell/.config/
// quickshell/modules/dashboard/PanelDialog.qml line 130) added directly
// inside the panel BODY file, where the shared frame — not the body —
// must be the sole owner. Target check: panel-namespace-conformance
// (source half). Expected verdict: FAIL — a panel that sets its own
// namespace can land anywhere, which is exactly what this fixture proves
// the check catches.
//
// AudioPanel.qml — the audio panel body (Phase 15 Plans 02 and 04,
// PANEL-01/PANEL-02/PANEL-06). Root type `PanelDialog`.

import QtQuick
import "../../"

PanelDialog {
    id: root

    namespaceSuffix: "audio-panel"
    panelGlyph: ""
    panelTitle: "Audio"

    // POISON: a panel body file must never set this directly — only the
    // shared frame (PanelDialog.qml) is allowed to.
    WlrLayershell.namespace: "quickshell-rogue-panel"

    property AudioBackend backend: null

    Column {
        anchors.fill: parent
        Text { text: "master volume placeholder" }
    }
}
