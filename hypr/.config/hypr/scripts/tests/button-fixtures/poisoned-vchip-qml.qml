// button-lint fixture (260828-ah9). Reproduces the exact shape of
// AtFontsTab.qml's pre-fix "vchip" — a hand-rolled Rectangle pill with a
// direct Text label and a direct MouseArea{onClicked} carrying no
// hoverEnabled at all. MUST trip the gate. Never loaded by any live
// Quickshell surface — button-lint self-test fixture only (poisoned).
import QtQuick

Flow {
    id: root

    Repeater {
        model: root.variants

        delegate: Rectangle {
            id: vchip
            required property var modelData

            readonly property bool on: vchip.modelData.active

            radius: 99
            color: vchip.on ? "primaryTint" : "transparent"
            width: vchipLabel.implicitWidth + 16
            height: vchipLabel.implicitHeight + 8

            Text {
                id: vchipLabel
                anchors.centerIn: parent
                text: vchip.modelData.behaviour
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.previewBehaviour = vchip.modelData.behaviour;
                    root.applyFont(vchip.modelData.rawName);
                }
            }
        }
    }
}
