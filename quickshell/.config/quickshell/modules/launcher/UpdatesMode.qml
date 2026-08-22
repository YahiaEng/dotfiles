// UpdatesMode.qml — R-1, System ▸ Updates (quick task 260822-sht, Task 4).
// A read-only rows view of pending package updates. Repo updates come
// from `checkupdates` (`pacman-contrib`, installed, already listed at
// `install.sh:161`); AUR updates come from `paru -Qua` (the helper
// `install.sh` bootstraps at line 520-534). Both are read-only queries —
// this surface REPORTS, it does not install. No new package enters
// `install.sh` from this task (verified by its own `<automated>` gate).
//
// `checkupdates` documents exit 2 for "nothing to do" (its own source,
// `$(which checkupdates)` line ~181) — that and any other non-zero exit
// both degrade to "no repo updates", never a distinct error state, the
// same defensive shape `clipboard-wipe.sh` already uses for an empty
// clipboard database. `paru -Qua` is handled identically: a non-zero exit
// with no meaningful stdout means "no AUR updates", not a failure.
import QtQuick
import Quickshell.Io
import ".."
import "."

Item {
    id: root

    width: parent ? parent.width : 0
    height: Math.min(320, Math.max(root._rows.length, 1) * 32)

    property var repoUpdates: []
    property var aurUpdates: []
    property bool _repoDone: false
    property bool _aurDone: false
    readonly property bool loading: !root._repoDone || !root._aurDone

    readonly property var _rows: {
        if (root.loading)
            return [
                {
                    text: "Checking for updates…"
                }
            ];
        if (root.repoUpdates.length === 0 && root.aurUpdates.length === 0)
            return [
                {
                    text: "System is up to date"
                }
            ];
        const rows = [];
        for (let i = 0; i < root.repoUpdates.length; i++)
            rows.push({
                text: root.repoUpdates[i]
            });
        for (let i = 0; i < root.aurUpdates.length; i++)
            rows.push({
                text: root.aurUpdates[i] + "  (AUR)"
            });
        return rows;
    }

    // Duck-typed interface Launcher.qml's generic keyboard-nav glue reads
    // — a read-only report has nothing to activate.
    property int currentIndex: 0
    readonly property int count: root._rows.length
    function activate() {
    }

    Component.onCompleted: {
        repoProcess.running = true;
        aurProcess.running = true;
    }

    Process {
        id: repoProcess

        command: ["checkupdates"]
        stdout: StdioCollector {
            id: repoCollector
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.repoUpdates = (repoCollector.text || "").split("\n").filter(function (line) {
                    return line.length > 0;
                });
            else
                root.repoUpdates = [];
            root._repoDone = true;
        }
    }

    Process {
        id: aurProcess

        command: ["paru", "-Qua"]
        stdout: StdioCollector {
            id: aurCollector
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.aurUpdates = (aurCollector.text || "").split("\n").filter(function (line) {
                    return line.length > 0;
                });
            else
                root.aurUpdates = [];
            root._aurDone = true;
        }
    }

    ListView {
        id: updatesListView
        anchors.fill: parent
        clip: true
        interactive: false
        model: root._rows

        delegate: Item {
            id: updateDelegate
            required property var modelData
            required property int index

            width: updatesListView.width
            height: 32

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 12
                text: updateDelegate.modelData.text
                color: Colours.onSurface
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }
    }
}
