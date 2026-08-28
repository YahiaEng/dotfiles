// button-lint fixture (260828-ah9). Models a rail-row list delegate:
// `Rectangle` with `radius:` and a direct `MouseArea { onClicked }`, but
// its `Text` children are wrapped inside a `Row` — never a DIRECT child of
// the Rectangle — so this must NOT trip the gate regardless of what its
// MouseArea carries. Never loaded by any live Quickshell surface —
// button-lint self-test fixture only.
import QtQuick

ListView {
    id: railList

    delegate: Rectangle {
        id: railRow
        required property var modelData

        width: 200
        height: 44
        radius: 10
        color: railRow.selected ? "primaryContainer" : "transparent"

        Row {
            anchors.fill: parent

            Text {
                text: railRow.modelData
            }
        }

        MouseArea {
            id: railArea
            anchors.fill: parent
            onClicked: railList.currentIndex = index
        }
    }
}
