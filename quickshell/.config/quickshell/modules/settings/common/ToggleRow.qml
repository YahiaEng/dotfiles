// modules/settings/common/ToggleRow.qml — label + subtext + a switch pill.
// Same `Control` + never-anchor-contentItem discipline as SelectRow.qml/
// NavRow.qml (see SelectRow.qml's header for the full QQC2 trap
// reasoning) — the switch indicator is a plain Rectangle/handle pair, not
// QtQuick.Controls' own Switch, so there is no second contentItem to
// fight.
import QtQuick
import QtQuick.Controls
import "../../"
import "../../dashboard"

Control {
    id: root

    property string label: ""
    property string subtext: ""
    property bool checked: false
    signal toggled(value: bool)

    // Two-pane keyboard focus (Pages.qml's own `_collectFocusableRows`
    // marker + externally-written visual state) — see Pages.qml's header
    // for the full design. `focusable` is a plain readonly marker, not a
    // real QML `Item.focus`/`activeFocus` participant: this shell's rail
    // selection is already virtual (index-driven), so the content pane
    // follows the same idiom rather than mixing two focus models.
    readonly property bool focusable: true
    property bool rowFocused: false

    implicitWidth: parent ? parent.width : 400
    implicitHeight: 56
    padding: Design.spacingMd

    // Focus ring: border COLOR only, never width/padding/scale — a
    // geometry-affecting focus visual is exactly the hover-flicker
    // feedback-loop class this same wave root-caused and fixed
    // elsewhere in this module (SelectRow.qml's dropdown highlight).
    // Width stays a constant 2px always; only the color's alpha/hue
    // toggles, so the row's own footprint never moves under a
    // stationary cursor or a focus change.
    background: Rectangle {
        radius: 12
        color: "transparent"
        border.width: 2
        border.color: root.rowFocused ? Colours.primary : "transparent"

        Behavior on border.color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

    contentItem: Item {
        id: rowContent
        implicitHeight: Math.max(labelCol.implicitHeight, switchPill.implicitHeight)

        Column {
            id: labelCol
            anchors.left: parent.left
            anchors.right: switchPill.left
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
            id: switchPill
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 48
            implicitHeight: 28
            radius: height / 2
            color: root.checked ? Colours.primary : Colours.surfaceVariant

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }

            Rectangle {
                id: handle
                width: 22
                height: 22
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                x: root.checked ? parent.width - width - 3 : 3
                color: root.checked ? Colours.onPrimary : Colours.onSurfaceVariant

                Behavior on x {
                    enabled: Motion.motionEnabled
                    NumberAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.toggled(!root.checked)
            }
        }
    }
}
