// modules/settings/common/SelectRow.qml — label + subtext + a dropdown
// pill (RESEARCH.md pattern #4, Caelestia's SelectRow). A `Control`
// subclass, per this plan's own row-type discipline — and therefore
// subject to the QQC2 `contentItem`-anchoring trap (MEMORY
// qqc2-contentitem-anchors-break-sizing): the fix taken here is to NEVER
// anchor `contentItem` itself against the Control's own geometry (Control
// already sizes `contentItem` from `availableWidth`/`availableHeight` via
// its padding once no such override exists) — only the CHILDREN inside
// contentItem are anchored, which is ordinary and safe.
import QtQuick
import QtQuick.Controls
import "../../"
import "../../dashboard"

Control {
    id: root

    property string label: ""
    property string subtext: ""
    // Each entry: { value: "<raw>", display: "<label>" }
    property var model: []
    property string currentValue: ""
    signal selected(value: string)

    readonly property string currentDisplay: {
        for (var i = 0; i < root.model.length; i++) {
            if (root.model[i].value === root.currentValue)
                return root.model[i].display;
        }
        return root.currentValue;
    }

    implicitWidth: parent ? parent.width : 400
    implicitHeight: 56
    padding: Design.spacingMd

    contentItem: Item {
        id: rowContent
        implicitHeight: Math.max(labelCol.implicitHeight, dropdownPill.implicitHeight)

        Column {
            id: labelCol
            anchors.left: parent.left
            anchors.right: dropdownPill.left
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

        Rectangle {
            id: dropdownPill
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Math.max(120, valueText.implicitWidth + Design.spacingLg * 2)
            implicitHeight: 36
            radius: height / 2
            color: Colours.surfaceVariant

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }

            Text {
                id: valueText
                anchors.centerIn: parent
                text: root.currentDisplay
                font.pixelSize: Design.fontBody
                color: Colours.onSurfaceVariant
            }

            MouseArea {
                anchors.fill: parent
                onClicked: optionsMenu.popup()
            }
        }
    }

    Menu {
        id: optionsMenu

        Repeater {
            model: root.model

            MenuItem {
                required property var modelData
                text: modelData.display
                onTriggered: root.selected(modelData.value)
            }
        }
    }
}
