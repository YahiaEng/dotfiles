// modules/settings/common/InfoRow.qml — label + a read-only value, no
// control at all (a fact, not a knob). Not a `Control` subclass — there
// is nothing interactive here, so the QQC2 contentItem trap (SelectRow.qml's
// header) does not apply; a plain `Item` is the honest type. Not consumed
// until Task 3/Task 4 (e.g. Display + input's current-mode readout); declared
// now alongside ToggleRow/SliderRow per this plan's "declare the whole
// row-type family in Task 2" instruction.
import QtQuick
import "../../"
import "../../dashboard"

Item {
    id: root

    property string label: ""
    property string value: ""

    implicitWidth: parent ? parent.width : 400
    implicitHeight: rowLayout.implicitHeight + Design.spacingMd * 2

    Row {
        id: rowLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Design.spacingMd

        Text {
            text: root.label
            font.pixelSize: Design.fontBody
            color: Colours.onSurface
        }
        Text {
            text: root.value
            font.pixelSize: Design.fontBody
            color: Colours.onSurfaceVariant
        }
    }
}
