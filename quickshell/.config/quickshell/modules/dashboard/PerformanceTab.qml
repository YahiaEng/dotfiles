// PerformanceTab.qml — tab 2 shell (Phase 14 Plan 03, filled by Plan 14-06,
// D-36: four MD3 circular dials — CPU, memory, storage, battery — plus an
// honest network up/down rate row).
//
// Root type Item, filled via anchors.fill: parent by the Loader Dashboard.qml
// places it in — deliberately declares NO implicitWidth/implicitHeight of
// its own (D-04: the drawer frame is fixed, no tab may drive its size).
//
// D-41 widget-state register — "populated" / "pending" / "empty" — carried
// on every one of this phase's nine modules/dashboard/ files.
//
// Property contract: `systemResources` is typed `var` rather than a concrete
// type so this stub compiles before 14-06's SystemResources reader has any
// real surface; 14-06 may narrow the type once it does. This is the SAME
// shared instance DashboardTab's resources strip (14-08) reads — one poll,
// not two.
import QtQuick
import "../"

Item {
    id: root

    anchors.fill: parent

    // D-41: "populated" | "pending" | "empty"
    property string widgetState: "empty"

    property var systemResources: null

    // ── D-41 empty branch ───────────────────────────────────────────────
    Column {
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            text: "Performance\nNot built yet — plan 14-06"
            font.pixelSize: 16
            color: Colours.onSurfaceVariant
        }
    }
}
