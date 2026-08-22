// ConfirmMode.qml — reusable destructive-confirm rows view (quick task
// 260822-sht, Task 6, Stage 2 dmenu-consumer migration). Two rows, always
// in this order: the non-destructive option first and preselected — the
// UI-SPEC Copywriting Contract `clipboard-wipe.sh` already honoured in
// its own retired comment ("No" listed first so it is the default-
// highlighted dmenu row, never pre-select the destructive option). This
// file never opens with the destructive row under the cursor.
//
// Same D-1 inversion-of-control shape PickerMode.qml documents: the
// launcher owns the confirm, and only invokes the consumer
// non-interactively (`--yes`) on an explicit "Yes" pick. Selecting "No"
// or dismissing with Escape both close the surface with no action taken
// — the whole of the old exit-130 cancel contract, which disappears as a
// concept because there is no second process left to signal.
//
// Duck-typed interface Launcher.qml's generic keyboard-nav glue reads:
// `currentIndex`, `count`, `activate()`.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "."
import "../dashboard"

Item {
    id: root

    width: parent ? parent.width : 0
    height: 40 * 2 + 32

    property var dismissCallback: null

    // "clipboardwipe" is this task's only consumer today; the shape is
    // written generically (message + commandArgv) so a future destructive
    // action can reuse this file the same way "theme"/"barorientation"
    // both reuse PickerMode.qml.
    required property string confirmId

    readonly property bool _isClipboardWipe: root.confirmId === "clipboardwipe"

    readonly property var _rows: ["No", "Yes"]
    property int currentIndex: 0
    readonly property int count: root._rows.length

    property string message: ""
    property bool _countLoaded: false

    function activate() {
        const picked = root._rows[root.currentIndex];
        if (picked === "Yes") {
            const home = Quickshell.env("HOME");
            execProcess.command = root._isClipboardWipe ? [home + "/.config/hypr/scripts/clipboard-wipe.sh", "--yes"] : [];
            if (execProcess.command.length > 0) {
                execProcess.running = false;
                execProcess.running = true;
            }
        }
        if (typeof root.dismissCallback === "function")
            root.dismissCallback();
    }

    Process {
        id: execProcess
    }

    // Same defensive shape `clipboard-wipe.sh` itself used before this
    // task (D-5's list verb: `cliphist list` exits 1 — "please store
    // something first" — on an empty/fresh db, which is not a failure
    // here).
    Process {
        id: countProcess
        command: ["bash", "-c", "cliphist list 2>/dev/null | wc -l | tr -d '[:space:]'"]
        stdout: StdioCollector {
            id: countCollector
        }
        onExited: exitCode => {
            const n = (countCollector.text || "0").trim();
            root.message = "This clears all " + (n.length > 0 ? n : "0") + " saved clipboard entries. This cannot be undone.";
            root._countLoaded = true;
        }
    }

    Component.onCompleted: {
        if (root._isClipboardWipe)
            countProcess.running = true;
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Design.spacingSm

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            text: root.message
            color: Colours.onSurfaceVariant
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            visible: root.message.length > 0
        }

        ListView {
            id: confirmListView
            width: parent.width
            height: 40 * root.count
            clip: true
            interactive: false
            model: root._rows
            currentIndex: root.currentIndex

            delegate: Rectangle {
                id: confirmDelegate
                required property string modelData
                required property int index

                width: confirmListView.width
                height: 40
                radius: 8
                color: root.currentIndex === confirmDelegate.index ? Colours.surfaceVariant : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 12
                    text: confirmDelegate.modelData
                    color: confirmDelegate.modelData === "Yes" ? Colours.error : Colours.onSurface
                    font.pixelSize: 15
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.currentIndex = confirmDelegate.index;
                        root.activate();
                    }
                }
            }
        }
    }
}
