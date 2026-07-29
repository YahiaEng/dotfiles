// PerformanceTab.qml — tab 2 shell (Phase 14 Plan 03, filled by Plan 14-06,
// D-36: four MD3 circular dials — CPU, memory, storage, battery — plus an
// honest network up/down rate row).
//
// Root type Item, filled via anchors.fill: parent by the Loader Dashboard.qml
// places it in — actual rendered geometry is UNCHANGED from Task 2 (still
// anchors.fill: parent, always matching whatever size its Loader currently
// has, including mid-resize-animation).
//
// `implicitWidth`/`implicitHeight` below are D-04's "no implicit size"
// prohibition DELIBERATELY REVERSED at this plan's render gate (checkpoint
// feedback 2026-07-29, see 14-03-SUMMARY.md's Deviations): Dashboard.qml
// reads these as an advisory hint to compute the drawer's own animated frame
// target — a pure metadata read, independent of this item's actual rendered
// size above. Four dials in a row plus a network rate row reads wide and
// short; 14-06 replaces these numbers with a value derived from its real
// dial-grid layout's own natural size once built.
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

    // Placeholder content-driven size hint (D-04 superseded) — read by
    // Dashboard.qml's activeContentWidth/activeContentHeight, not by this
    // item's own actual geometry above.
    implicitWidth: 1000
    implicitHeight: 360

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
