// Compliant fixture — a conditional `color:` branch uses the literal
// "transparent", but nothing animates the `color` property in this same
// block (only `opacity` is animated here) — a non-animated transparent
// literal never interpolates through black, so it must NOT be flagged.
import QtQuick

Rectangle {
    id: root

    property bool active: false

    radius: 6
    color: root.active ? Colours.primary : "transparent"
    opacity: root.active ? 1 : 0.45

    Behavior on opacity {
        enabled: Motion.motionEnabled
        NumberAnimation {
            duration: Motion.colourDuration
        }
    }
}
