// modules/settings/common/NavRow.qml — label + subtext + a
// chevron-trailing button that launches something (RESEARCH.md pattern
// #4, Caelestia's NavRow). Same `Control`-subclass + never-anchor-
// contentItem discipline as SelectRow.qml — see that file's header for the
// full reasoning.
import QtQuick
import QtQuick.Controls
import "../../"
import "../../dashboard"

Control {
    id: root

    property string label: ""
    property string subtext: ""
    signal activated()

    // Two-pane keyboard focus — see Pages.qml's header for the full
    // design; ToggleRow.qml's own header has the geometry-stability
    // reasoning for the border-color-only focus ring (merged below into
    // this row's `background`).
    readonly property bool focusable: true
    property bool rowFocused: false

    implicitWidth: parent ? parent.width : 400
    implicitHeight: 56
    padding: Design.spacingMd

    contentItem: Item {
        id: rowContent
        implicitHeight: Math.max(labelCol.implicitHeight, chevron.implicitHeight)

        Column {
            id: labelCol
            anchors.left: parent.left
            anchors.right: chevron.left
            anchors.rightMargin: Design.spacingMd
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: root.label
                font.pixelSize: Design.fontBody
                color: Colours.onSurface
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                visible: root.subtext.length > 0
                text: root.subtext
                font.pixelSize: Design.fontLabel
                color: Colours.onSurfaceVariant
                elide: Text.ElideRight
                width: parent.width
            }
        }

        Text {
            id: chevron
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.iconSizeMd
            text: "chevron_right"
            color: Colours.onSurfaceVariant
        }
    }

    // Row hover fix (operator burst-screenshot + PIL pixel-sample,
    // fourth live-pass) — MEASURED root cause, not the popup this
    // module's prior three fix rounds all targeted: the page pane
    // paints `Colours.surfaceVariant` (Settings.qml's own window
    // background) and this row's OWN hover fill was the SAME
    // `Colours.surfaceVariant` — invisible by construction, confirmed
    // by pixel sample (fill == pane, identical RGB). Replaced with the
    // same border-ring language every other row in this module uses.
    // Coexistence with keyboard focus, decided deliberately: the ring
    // shows when EITHER `rowFocused` (keyboard) OR `hoverArea.containsMouse`
    // is true — one shared visual, matching the operator's own request
    // that hover look like keyboard selection rather than a second style.
    background: Rectangle {
        color: "transparent"
        radius: 12
        border.width: 2
        border.color: (root.rowFocused || hoverArea.containsMouse) ? Colours.primary : "transparent"

        Behavior on border.color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.activated()
    }
}
