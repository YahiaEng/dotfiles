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

    background: Rectangle {
        color: hoverArea.containsMouse ? Colours.surfaceVariant : "transparent"
        radius: 12

        Behavior on color {
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
