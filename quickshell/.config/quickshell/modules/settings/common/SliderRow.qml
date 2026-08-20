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

    // Two-pane keyboard focus — see Pages.qml's header for the full
    // design; ToggleRow.qml's own header has the geometry-stability
    // reasoning for the border-color-only focus ring below.
    readonly property bool focusable: true
    property bool rowFocused: false

    implicitWidth: parent ? parent.width : 400
    implicitHeight: 64
    padding: Design.spacingMd

    // Row hover (operator burst-screenshot + PIL pixel-sample, fourth
    // live-pass): this row had no row-level hover indicator at all
    // before this fix. `HoverHandler` is passive/non-exclusive, so it
    // does not compete with the `Slider`'s own drag/click handling.
    // Coexistence with keyboard focus, decided deliberately: the ring
    // shows when EITHER `rowFocused` (keyboard) OR hover is true — one
    // shared visual, matching the operator's own request that hover
    // look like keyboard selection.
    HoverHandler {
        id: rowHover
    }

    background: Rectangle {
        radius: 12
        color: "transparent"
        border.width: 2
        border.color: (root.rowFocused || rowHover.hovered) ? Colours.primary : "transparent"

        Behavior on border.color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

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

            // Same sweep, same root cause: the unfilled track was
            // `surfaceVariant` on a `surfaceVariant` pane — invisible
            // where the filled (primary) portion doesn't cover it.
            // Outline border added — same role every other fix in this
            // wave uses against this identical pane color.
            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 4
                radius: 2
                color: Colours.surfaceVariant
                border.width: 1
                border.color: Colours.outline

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
