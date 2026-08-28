// button-lint fixture (260828-ah9). A surface using packages/WbButton.qml
// rather than hand-rolling a chip — the sanctioned shape. Never loaded by
// any live Quickshell surface — button-lint self-test fixture only.
import QtQuick
import "../packages"

Item {
    id: root

    Row {
        spacing: 8

        WbButton {
            label: "Apply"
            tone: "primary"
            onActivated: root.applied()
        }

        WbButton {
            label: "Uninstall"
            tone: "danger"
            onActivated: root.uninstalled()
        }
    }

    signal applied
    signal uninstalled
}
