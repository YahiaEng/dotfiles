// poisoned-second-screencopyview.qml — a hypothetical SECOND capture site
// (self-test places this file ALONGSIDE compliant-window-thumbnail.qml in
// the same tmpdir), simulating exactly the failure D-16-23 check 7 exists
// to catch: a future plan that forks the renderer and adds a second,
// singular ScreencopyView instantiation instead of extending
// WindowThumbnail.qml's existing liveCapture variant switch. Target check:
// single-capture-path. Expected verdict: FAIL when present alongside the
// compliant fixture (two instantiation sites, not one).

import QtQuick
import Quickshell.Wayland

Item {
    id: root
    property var toplevel: null

    // POISON: a second ScreencopyView instantiation site in the same
    // directory — the exact "add-alongside" failure this check forbids.
    ScreencopyView {
        id: rogueCaptureView
        anchors.fill: parent
        captureSource: root.toplevel ? root.toplevel.wayland : null
        live: true
    }
}
