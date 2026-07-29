// MediaTab.qml — tab 1 shell (Phase 14 Plan 03, filled by Plan 14-05, D-35:
// Caelestia-style MD3 full player — cover art, type stack, seek slider,
// Material Symbols transport, volume, player-switcher chips).
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
// size above. The full player (cover art, type stack, seek, transport,
// volume, switcher chips) reads roughly square-ish and more compact than the
// Dashboard tab; 14-05 replaces these numbers with a value derived from its
// real layout's own natural size once built.
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

    // Placeholder content-driven size hint (D-04 superseded) — read by
    // Dashboard.qml's activeContentWidth/activeContentHeight, not by this
    // item's own actual geometry above.
    implicitWidth: 900
    implicitHeight: 420

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
