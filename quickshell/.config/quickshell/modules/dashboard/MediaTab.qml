// MediaTab.qml — tab 1 shell (Phase 14 Plan 03, filled by Plan 14-05, D-35:
// Caelestia-style MD3 full player — cover art, type stack, seek slider,
// Material Symbols transport, volume, player-switcher chips).
//
// Root type Item, filled via anchors.fill: parent by the Loader Dashboard.qml
// places it in — deliberately declares NO implicitWidth/implicitHeight of
// its own (D-04: the drawer frame is fixed, no tab may drive its size).
//
// D-41 widget-state register — "populated" / "pending" / "empty" — carried
// on every one of this phase's nine modules/dashboard/ files.
//
// Property contract: `mediaBackend` is typed `var` rather than a concrete
// type so this stub compiles before 14-05's MediaBackend has any real
// surface; 14-05 may narrow the type once the backend does. This is the
// SAME shared instance DashboardTab's compact media widget reads (D-35's
// hard fence: the drawer is a THIRD reader of the one existing media
// backend, never a second one).
import QtQuick
import "../"

Item {
    id: root

    anchors.fill: parent

    // D-41: "populated" | "pending" | "empty"
    property string widgetState: "empty"

    property var mediaBackend: null

    // ── D-41 empty branch ───────────────────────────────────────────────
    Column {
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            text: "Media\nNot built yet — plan 14-05"
            font.pixelSize: 16
            color: Colours.onSurfaceVariant
        }
    }
}
