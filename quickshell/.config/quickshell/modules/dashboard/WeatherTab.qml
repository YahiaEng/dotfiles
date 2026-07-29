// WeatherTab.qml — tab 3 shell (Phase 14 Plan 03, filled by Plan 14-07,
// D-37: current-conditions hero + fixed 8-column hour strip (NOT
// scrollable, D-05) + 5-day row).
//
// Root type Item, filled via anchors.fill: parent by the Loader Dashboard.qml
// places it in — deliberately declares NO implicitWidth/implicitHeight of
// its own (D-04: the drawer frame is fixed, no tab may drive its size).
//
// D-41 widget-state register — "populated" / "pending" / "empty" — carried
// on every one of this phase's nine modules/dashboard/ files.
//
// Property contract: `weatherBackend` is typed `var` rather than a concrete
// type so this stub compiles before 14-07's WeatherBackend has any real
// surface; 14-07 may narrow the type once it does.
import QtQuick
import "../"

Item {
    id: root

    anchors.fill: parent

    // D-41: "populated" | "pending" | "empty"
    property string widgetState: "empty"

    property var weatherBackend: null

    // ── D-41 empty branch ───────────────────────────────────────────────
    Column {
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            text: "Weather\nNot built yet — plan 14-07"
            font.pixelSize: 16
            color: Colours.onSurfaceVariant
        }
    }
}
