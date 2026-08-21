// colour-lint fixture (quick-260821-6z1 fix wave).
// Models CHECK D — the bare attached ToolTip shorthand, which lazily
// instantiates QQC2's own default delegate styled from Qt's installed
// style rather than any file in this repo. Never loaded by any live
// Quickshell surface — colour-lint self-test fixture only.
import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: Colours.surface

    MouseArea {
        id: probeArea
        anchors.fill: parent
        hoverEnabled: true
        ToolTip.visible: probeArea.containsMouse // CORRUPTED: was ThemedToolTip
        ToolTip.text: "probe"
        ToolTip.delay: 400
    }
}
