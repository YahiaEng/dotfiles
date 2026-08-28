// button-lint fixture (260828-ah9). Reproduces the exact shape of
// AtCatalogueTab.qml's pre-fix "Re-check" pill — a hand-rolled Rectangle
// chip, static background, a direct Text label and a direct
// MouseArea{onClicked} with no hoverEnabled at all. MUST trip the gate.
// Never loaded by any live Quickshell surface — button-lint self-test
// fixture only (poisoned).
import QtQuick

Item {
    id: root

    Rectangle {
        anchors.right: parent.right
        width: recheckLabel.implicitWidth + 12
        height: 22
        radius: 8
        color: "flatTint"

        Text {
            id: recheckLabel
            anchors.centerIn: parent
            text: "Re-check"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.reconcile()
        }
    }

    signal reconcile
}
