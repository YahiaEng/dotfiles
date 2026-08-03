// compliant-window-thumbnail.qml — trimmed excerpt of the real, shipped
// quickshell/.config/quickshell/modules/overview/WindowThumbnail.qml
// (import lines plus the ScreencopyView instantiation itself), reduced to
// the lines this fixture's target check actually reads. Provenance: real
// shipped source, not hand-invented syntax. Target check:
// single-capture-path, run in isolation (self-test copies this file alone
// into a fresh tmpdir). Expected verdict: PASS — exactly one file in the
// directory instantiates ScreencopyView.

import QtQuick
import Quickshell.Wayland

Item {
    id: root

    property var toplevel: null
    property real captureScale: 1

    ScreencopyView {
        id: captureView
        anchors.fill: parent
        constraintSize: Qt.size(root.width, root.height)
        captureSource: root.toplevel ? root.toplevel.wayland : null
        live: true
    }

    readonly property bool hasContent: captureView.hasContent
}
