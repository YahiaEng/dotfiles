// CalcMode.qml — `=` prefix result view (quick task 260822-sht, Task 2).
// Single-result: spawns `qalc -t <expr>` via a `Process` on every
// `LauncherState.queryArg` change and shows the result. Verified live
// (this task's own plan text and `<automated>` gate): `qalc -t "2+2*10"`
// returns `22`, libqalculate already installed, no new package.
//
// Enter copies the result to the clipboard via `wl-copy` — matches the
// retired `calc` provider's own copy-on-select behaviour (D-5).
//
// Duck-typed interface Launcher.qml's generic keyboard-nav glue reads
// (`_activeItem()`/`moveSelection()`/`activateCurrent()`): `currentIndex`,
// `count`, `activate()`. A single result is always "row 0" when present,
// so `currentIndex` is fixed and `moveSelection()` (never called on this
// mode since `count` never exceeds 1) is simply absent — not needed for
// a one-row view.
import QtQuick
import Quickshell.Io
import ".."
import "."

Item {
    id: root

    width: parent ? parent.width : 0
    height: 56

    readonly property string expression: LauncherState.queryArg.trim()
    property string resultText: ""
    property bool hasResult: false

    readonly property int currentIndex: 0
    readonly property int count: root.hasResult ? 1 : 0

    function activate() {
        if (!root.hasResult)
            return;
        copyProcess.command = ["wl-copy", root.resultText];
        copyProcess.running = false;
        copyProcess.running = true;
    }

    onExpressionChanged: root._recompute()
    Component.onCompleted: root._recompute()

    function _recompute() {
        if (root.expression.length === 0) {
            root.resultText = "";
            root.hasResult = false;
            return;
        }
        // Restart cleanly rather than letting an in-flight query from a
        // previous keystroke race this one — `running = false` on an
        // already-stopped Process is a no-op, so this is safe on the
        // very first call too.
        qalcProcess.running = false;
        qalcProcess.command = ["qalc", "-t", root.expression];
        qalcProcess.running = true;
    }

    Process {
        id: qalcProcess

        stdout: StdioCollector {
            id: qalcCollector
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.resultText = (qalcCollector.text || "").trim();
                root.hasResult = root.resultText.length > 0;
            } else {
                root.resultText = "";
                root.hasResult = false;
            }
        }
    }

    Process {
        id: copyProcess
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Colours.surfaceVariant
        visible: root.expression.length > 0

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 16
            text: root.hasResult ? root.resultText : "…"
            color: Colours.onSurface
            font.pixelSize: 20
            elide: Text.ElideRight
        }
    }
}
