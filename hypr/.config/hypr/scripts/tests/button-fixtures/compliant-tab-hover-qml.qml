// button-lint fixture (260828-ah9). Models AtTabBar.qml's tab pill: a
// `Rectangle` with `radius:` and BOTH a direct `Text` child AND a direct
// `MouseArea { onClicked }` child — structurally close to a hand-rolled
// button — but the `MouseArea` sets `hoverEnabled: true` because its
// background depends on `containsMouse`, the real discriminator this gate
// uses to tell a tab/row from a chip. Must NOT trip. Never loaded by any
// live Quickshell surface — button-lint self-test fixture only.
import QtQuick

Repeater {
    id: tabs

    delegate: Rectangle {
        id: tabDelegate
        required property var modelData

        width: tabLabel.implicitWidth + 24
        height: 32
        radius: 10
        color: tabDelegate.selected ? "primaryContainer" : (tabArea.containsMouse ? "hoverTint" : "transparent")

        Text {
            id: tabLabel
            anchors.centerIn: parent
            text: tabDelegate.modelData.label
        }

        MouseArea {
            id: tabArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: tabs.tabSelected(tabDelegate.modelData.id)
        }
    }
}
