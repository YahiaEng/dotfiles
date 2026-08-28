// Poisoned fixture — mirrors WbButton.qml's real pre-fix (round 5) shape:
// an animated `color` property driven by a multi-line JS function whose
// branches return the literal "transparent". Must be flagged even though
// the transparent branch is not a single-line ternary.
import QtQuick

Rectangle {
    id: root

    property bool live: true
    property bool hovered: false

    radius: 15
    color: {
        if (!root.live)
            return "transparent";
        return root.hovered ? Qt.alpha(Colours.primary, 0.28) : Qt.alpha(Colours.primary, 0.16);
    }
    border.width: 1
    border.color: Colours.outline

    Behavior on color {
        enabled: Motion.motionEnabled
        ColorAnimation {
            duration: Motion.colourDuration
        }
    }
}
