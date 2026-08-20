// modules/settings/common/SliderRow.qml — label + subtext + a value slider.
// Same `Control` + never-anchor-contentItem discipline as SelectRow.qml —
// see that file's header for the full QQC2 trap reasoning. Not consumed
// until Task 3 (Display + input's pointer-sensitivity row); declared now
// per this plan's own "declare the whole row-type family in Task 2"
// instruction so Task 3 has no `common/qmldir` edit of its own to make.
import QtQuick
import QtQuick.Controls
import "../../"
import "../../dashboard"

Control {
    id: root

    property string label: ""
    property string subtext: ""
    property real from: 0
    property real to: 1
    property real value: 0
    property real stepSize: 0.01
    signal moved(value: real)

    implicitWidth: parent ? parent.width : 400
    implicitHeight: 64
    padding: Design.spacingMd

    contentItem: Column {
        id: rowContent
        spacing: Design.spacingXs

        Row {
            width: parent.width
            spacing: Design.spacingMd

            Text {
                width: parent.width - valueLabel.implicitWidth - Design.spacingMd
                text: root.label
                font.pixelSize: Design.fontBody
                color: Colours.onSurface
                elide: Text.ElideRight
            }
            Text {
                id: valueLabel
                text: root.value.toFixed(2)
                font.pixelSize: Design.fontLabel
                color: Colours.onSurfaceVariant
            }
        }

        Text {
            visible: root.subtext.length > 0
            text: root.subtext
            font.pixelSize: Design.fontLabel
            color: Colours.onSurfaceVariant
            width: parent.width
            elide: Text.ElideRight
        }

        Slider {
            id: slider
            width: parent.width
            from: root.from
            to: root.to
            value: root.value
            stepSize: root.stepSize
            onMoved: root.moved(slider.value)

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 4
                radius: 2
                color: Colours.surfaceVariant

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: Colours.primary
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: 18
                height: 18
                radius: height / 2
                color: Colours.primary
            }
        }
    }
}
