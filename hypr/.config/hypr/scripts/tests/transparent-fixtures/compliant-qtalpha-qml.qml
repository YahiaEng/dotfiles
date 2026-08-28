// Compliant fixture — animated border.color uses Qt.alpha(hue, 0)
// instead of the literal "transparent", so the transition keeps the
// correct hue instead of smearing through black.
import QtQuick

Rectangle {
    id: root

    property bool rowFocused: false

    radius: 12
    color: "transparent"
    border.width: 2
    border.color: root.rowFocused ? Colours.primary : Qt.alpha(Colours.primary, 0)

    Behavior on border.color {
        enabled: Motion.motionEnabled
        ColorAnimation {
            duration: Motion.colourDuration
        }
    }
}
