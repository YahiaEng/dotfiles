// Poisoned fixture — mirrors NavRow.qml's real pre-fix (round 5) shape:
// an animated border.color ternary uses the literal "transparent" as its
// off-branch. Must be flagged.
import QtQuick

Rectangle {
    id: root

    property bool rowFocused: false

    radius: 12
    color: "transparent"
    border.width: 2
    border.color: (root.rowFocused || hoverArea.containsMouse) ? Colours.primary : "transparent"

    Behavior on border.color {
        enabled: Motion.motionEnabled
        ColorAnimation {
            duration: Motion.colourDuration
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
