// modules/filepicker/FpFooter.qml — filter readout plus Cancel/Select.
//
// Ported from caelestia-dots/shell @ 1d0e5a5
// (components/filedialog/DialogButtons.qml). Theirs renders the filter as
// a static label; this one also carries the current selection's name,
// which is where Caelestia puts a separate floating `CurrentItem` tab
// overlaying the grid. One readout is enough and it cannot occlude a cell.
import QtQuick
import ".."
import "../dashboard"

Rectangle {
    id: root

    required property var picker

    signal cancelled
    signal confirmed

    implicitHeight: inner.implicitHeight + Design.spacingMd * 2
    color: Colours.surfaceVariant

    Row {
        id: inner

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Design.spacingMd
        spacing: Design.spacingSm

        Text {
            id: filterCaption

            anchors.verticalCenter: parent.verticalCenter
            text: "Filter:"
            color: Colours.onSurface
            font.pixelSize: Design.settingsFontSub
        }

        Rectangle {
            id: filterField

            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, inner.width - filterCaption.width - cancelBtn.width - selectBtn.width - Design.spacingSm * 3)
            height: 38
            radius: 12
            color: Colours.surface
            clip: true

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Design.spacingMd
                elide: Text.ElideRight
                color: Colours.onSurfaceVariant
                font.pixelSize: Design.settingsFontSub
                // Names the live selection when there is one, so the button
                // state is explainable — "Select" being dead with a file
                // apparently highlighted is otherwise a mystery.
                text: {
                    const e = root.picker.currentEntry;
                    if (e && !e.isDir)
                        return root.picker.selectionValid ? e.name : (e.name + " — not a " + root.picker.filterLabel.toLowerCase().replace(/s$/, ""));
                    return root.picker.filterLabel + " (" + root.picker.nameFilters.join(", ") + ")";
                }
            }
        }

        Rectangle {
            id: cancelBtn

            anchors.verticalCenter: parent.verticalCenter
            width: cancelText.implicitWidth + Design.spacingMd * 2
            height: 38
            radius: 12
            color: cancelHover.containsMouse ? Colours.surface : "transparent"

            Text {
                id: cancelText

                anchors.centerIn: parent
                text: "Cancel"
                color: Colours.onSurface
                font.pixelSize: Design.settingsFontSub
            }

            MouseArea {
                id: cancelHover

                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.cancelled()
            }
        }

        Rectangle {
            id: selectBtn

            anchors.verticalCenter: parent.verticalCenter
            width: selectText.implicitWidth + Design.spacingMd * 2
            height: 38
            radius: 12
            color: root.picker.selectionValid ? Colours.primary : Colours.surface
            opacity: root.picker.selectionValid ? 1 : 0.5

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }

            Text {
                id: selectText

                anchors.centerIn: parent
                text: "Select"
                color: root.picker.selectionValid ? Colours.onPrimary : Colours.onSurfaceVariant
                font.pixelSize: Design.settingsFontSub
                font.weight: Design.weightEmphasis
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.picker.selectionValid
                onClicked: root.confirmed()
            }
        }
    }
}
