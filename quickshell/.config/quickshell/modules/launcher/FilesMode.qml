// FilesMode.qml — `/` prefix result view (quick task 260822-sht, Task 2).
// Rows: enumerates `$HOME` via `fd` (installed at `/usr/bin/fd`, verified
// 10.4.2), case-insensitive, bounded depth, capped at 50 results to match
// the retired config's own `max_results = 50`. Enter opens the
// highlighted entry with `xdg-open`, matching the retired `files`
// provider's own open-on-select behaviour.
//
// `fd` exits 0 with empty stdout on zero matches (verified live against
// this host's fd 10.4.2) — no distinct "not found" exit code to special-
// case, unlike `qalc`'s non-zero-on-bad-expression behaviour in
// CalcMode.qml.
//
// Duck-typed interface Launcher.qml's generic keyboard-nav glue reads:
// `currentIndex`, `count`, `activate()` — a rows shape this time, so
// `currentIndex` is mutable and bounded by `count` (Launcher.qml's
// `moveSelection()` clamps it there, mirroring the apps ListView's own
// bounds check).
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "."

Item {
    id: root

    width: parent ? parent.width : 0
    height: Math.min(320, Math.max(resultsList.count, 1) * 40)

    readonly property string pattern: LauncherState.queryArg.trim()
    property var results: []
    property int currentIndex: 0
    readonly property int count: root.results.length

    function activate() {
        const entry = root.results[root.currentIndex];
        if (!entry)
            return;
        openProcess.command = ["xdg-open", entry];
        openProcess.running = false;
        openProcess.running = true;
    }

    onPatternChanged: root._search()
    Component.onCompleted: root._search()

    function _search() {
        root.currentIndex = 0;
        if (root.pattern.length === 0) {
            root.results = [];
            return;
        }
        fdProcess.running = false;
        fdProcess.command = ["fd", "--absolute-path", "--ignore-case", "--max-depth", "6", "--max-results", "50", root.pattern, Quickshell.env("HOME")];
        fdProcess.running = true;
    }

    Process {
        id: fdProcess

        stdout: StdioCollector {
            id: fdCollector
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.results = (fdCollector.text || "").split("\n").filter(function (line) {
                    return line.length > 0;
                });
            } else {
                root.results = [];
            }
        }
    }

    Process {
        id: openProcess
    }

    ListView {
        id: resultsList
        anchors.fill: parent
        clip: true
        model: root.results
        currentIndex: root.currentIndex
        interactive: false

        delegate: Rectangle {
            id: fileDelegate
            required property string modelData
            required property int index

            width: resultsList.width
            height: 40
            radius: 8
            color: root.currentIndex === fileDelegate.index ? Colours.surfaceVariant : "transparent"

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 12
                text: fileDelegate.modelData
                color: Colours.onSurface
                font.pixelSize: 13
                elide: Text.ElideMiddle
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.currentIndex = fileDelegate.index;
                    root.activate();
                }
            }
        }
    }
    // Scroll indicator (quick task 260828-pol). Sibling of the view,
    // never a child: a Flickable/ListView appends Item children to its
    // scrolled contentItem, so a bar declared inside scrolls away.
    ThemedScrollBar {
        flickable: resultsList
    }
}
