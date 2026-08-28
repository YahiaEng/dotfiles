pragma Singleton
import QtQuick
// Synthetic singleton (quick task 260828-t22). `nestedRole` is declared on an
// INNER object on purpose: Colours.qml declares its palette inside a nested
// JsonAdapter, and a strict top-level parse would report every consumer of it
// as a violation. This fixture pins the over-approximation.
Singleton {
    id: root
    readonly property color topLevelRole: "#112233"
    function someFunction() { return 1; }
    signal someSignal
    QtObject {
        id: inner
        property string nestedRole: "#445566"
    }
}
