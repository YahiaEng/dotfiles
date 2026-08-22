// WebSearchMode.qml — `@` prefix result view (quick task 260822-sht, Task
// 2). Single-result: opens `LauncherState.queryArg` as a web search in the
// system default browser on Enter, matching the retired `websearch`
// provider's own single-action behaviour.
//
// `Qt.openUrlExternally()` is the QML-native "hand this URL to the
// default handler" call, already used elsewhere in this shell for the
// identical purpose (NewsPane.qml, NotifCard.qml) — no new Process/binary
// dependency needed for this mode.
//
// Duck-typed interface Launcher.qml's generic keyboard-nav glue reads:
// `currentIndex`, `count`, `activate()` — same one-row shape as
// CalcMode.qml.
import QtQuick
import ".."
import "."

Item {
    id: root

    width: parent ? parent.width : 0
    height: 56

    readonly property string searchQuery: LauncherState.queryArg.trim()

    readonly property int currentIndex: 0
    readonly property int count: root.searchQuery.length > 0 ? 1 : 0

    function activate() {
        if (root.searchQuery.length === 0)
            return;
        Qt.openUrlExternally("https://www.google.com/search?q=" + encodeURIComponent(root.searchQuery));
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Colours.surfaceVariant
        visible: root.searchQuery.length > 0

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 16
            text: "Search the web for “" + root.searchQuery + "”"
            color: Colours.onSurface
            font.pixelSize: 15
            elide: Text.ElideRight
        }
    }
}
