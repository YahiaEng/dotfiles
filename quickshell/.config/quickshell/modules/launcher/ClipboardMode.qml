// ClipboardMode.qml — `:` prefix / Tools ▸ Clipboard result view (quick
// task 260822-sht, Task 8, Stage 2 dmenu-consumer migration, consumer 7
// of 7 — `keybinds.lua`'s Super+C pipeline, plus the identical pipeline
// embedded as the Tools ▸ Clipboard menu action).
//
// D-5's own four-verb `cliphist` contract, used verbatim, not re-derived:
//   - list:      `cliphist list`
//   - restore:   `printf '<entry>' | cliphist decode | wl-copy`
//   - delete one: `echo '<entry>' | cliphist delete`
//   - wipe all:  `cliphist wipe` (routed to Task 6's ConfirmMode, below)
// `<entry>` is the RAW line `cliphist list` prints for that row (an
// opaque id+tab+preview string cliphist itself parses back apart) — this
// file never splits or re-derives it, it is passed straight through via
// `Process.write()` (no shell interpolation, so no quoting-injection
// concern even though clipboard content is fully attacker/user
// controlled).
//
// Text-only. Image previews are OUT — DQ-2, the named first follow-up.
// This file does not special-case image rows at all: whatever raw
// preview text `cliphist list` prints for an entry (its own placeholder
// marker for a binary entry, unchanged from today) is what renders, and
// selecting it still restores correctly because the decode verb handles
// the binary case itself. No thumbnail decode path, no temp-file
// lifecycle. That deferral is recorded in the task's own summary, not
// here.
//
// Duck-typed interface Launcher.qml's generic keyboard-nav glue reads:
// `currentIndex`, `count`, `activate()`.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "."

Item {
    id: root

    width: parent ? parent.width : 0
    height: Math.min(320, Math.max(root.count, 1) * 40)

    property var _entries: []

    // Pinned "Wipe all…" row first, exactly like MenuMode.qml's own
    // pinned back row — routes to Task 6's ConfirmMode rather than
    // duplicating a destructive-confirm prompt here.
    readonly property var _rows: {
        const rows = [
            {
                _kind: "wipeall"
            }
        ];
        for (let i = 0; i < root._entries.length; i++)
            rows.push({
                _kind: "entry",
                raw: root._entries[i]
            });
        return rows;
    }

    property int currentIndex: 0
    readonly property int count: root._rows.length
    onCountChanged: {
        if (root.currentIndex >= root.count)
            root.currentIndex = 0;
    }

    function _refresh() {
        listProcess.running = false;
        listProcess.running = true;
    }

    Component.onCompleted: root._refresh()

    Process {
        id: listProcess
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            id: listCollector
        }
        onExited: exitCode => {
            root._entries = exitCode === 0 ? (listCollector.text || "").split("\n").filter(function (l) {
                return l.length > 0;
            }) : [];
        }
    }

    // `onStarted` (not an immediate `.write()` after `running = true`) —
    // the child process is guaranteed spawned by the time this signal
    // fires, where a same-tick write is a real ordering race against
    // process startup.
    Process {
        id: restoreProcess
        command: ["sh", "-c", "cliphist decode | wl-copy"]
        stdinEnabled: true
        onStarted: restoreProcess.write(root._pendingRestore)
    }
    property string _pendingRestore: ""

    Process {
        id: deleteProcess
        command: ["cliphist", "delete"]
        stdinEnabled: true
        onStarted: deleteProcess.write(root._pendingDelete)
        onExited: exitCode => root._refresh()
    }
    property string _pendingDelete: ""

    function activate() {
        const row = root._rows[root.currentIndex];
        if (!row)
            return;

        if (row._kind === "wipeall") {
            LauncherState.mode = "clipboardwipe";
            return;
        }

        root._pendingRestore = row.raw;
        restoreProcess.running = false;
        restoreProcess.running = true;
        if (typeof root.dismissCallback === "function")
            root.dismissCallback();
    }

    property var dismissCallback: null

    function _deleteRow(index) {
        const row = root._rows[index];
        if (!row || row._kind !== "entry")
            return;
        root._pendingDelete = row.raw + "\n";
        deleteProcess.running = false;
        deleteProcess.running = true;
    }

    ListView {
        id: clipboardListView
        anchors.fill: parent
        clip: true
        interactive: false
        model: root._rows
        currentIndex: root.currentIndex

        delegate: Rectangle {
            id: clipboardDelegate
            required property var modelData
            required property int index

            width: clipboardListView.width
            height: 40
            radius: 8
            color: root.currentIndex === clipboardDelegate.index ? Colours.surfaceVariant : "transparent"

            Text {
                anchors.left: parent.left
                anchors.right: deleteButton.visible ? deleteButton.left : parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 12
                text: clipboardDelegate.modelData._kind === "wipeall" ? "Wipe all…" : clipboardDelegate.modelData.raw
                color: clipboardDelegate.modelData._kind === "wipeall" ? Colours.error : Colours.onSurface
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                id: deleteButton
                visible: clipboardDelegate.modelData._kind === "entry"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 12
                text: "close"
                font.family: Design.symbolFontFamily
                font.pixelSize: 16
                color: Colours.onSurfaceVariant

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: root._deleteRow(clipboardDelegate.index)
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: deleteButton.visible ? deleteButton.width + 16 : 0
                onClicked: {
                    root.currentIndex = clipboardDelegate.index;
                    root.activate();
                }
            }
        }
    }
}
