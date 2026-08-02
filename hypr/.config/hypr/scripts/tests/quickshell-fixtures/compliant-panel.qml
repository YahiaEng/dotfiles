// compliant-panel.qml — captured 2026-08-02 as a trimmed excerpt of the
// real, shipped quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml
// (its header comment block plus the `root: PanelDialog {` declaration),
// minimally reduced to the lines this fixture's target check actually
// reads. Provenance: real shipped panel body, not hand-invented syntax.
// Target check: panel-namespace-conformance (source half, via
// _qsd_assert_panel_source). Expected verdict: PASS — the panel body sets
// no WlrLayershell.namespace of its own; it inherits PanelDialog's.
//
// AudioPanel.qml — the audio panel body (Phase 15 Plans 02 and 04,
// PANEL-01/PANEL-02/PANEL-06). Root type `PanelDialog`, so shell.qml's
// `LazyLoader` mounts this directly, exactly the same shape as `Dashboard`.

import QtQuick
import "../../"

PanelDialog {
    id: root

    namespaceSuffix: "audio-panel"
    panelGlyph: ""
    panelTitle: "Audio"

    // No WlrLayershell.namespace assignment anywhere in this file — the
    // shared frame (PanelDialog.qml) owns layer posture exclusively.

    property AudioBackend backend: null

    Column {
        anchors.fill: parent
        Text { text: "master volume placeholder" }
    }
}
