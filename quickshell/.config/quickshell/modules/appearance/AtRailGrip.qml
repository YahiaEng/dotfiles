// modules/appearance/AtRailGrip.qml — the Atelier's resizable-rail grip
// (quick task 260828-ah9, operator round 1, defects 2c/2e). Mirrors
// `modules/packages/Workbench.qml`'s own `sideGrip` + `gripArea` EXACTLY:
// a scene-anchored drag delta (`mapToItem(null, mouse.x, 0).x`), captured
// once on press together with the rail's width AT press — never a delta
// measured in the dragged item's own moving frame, which drifts with
// pointer speed as the rail resizes underneath it (Workbench.qml's own
// round-2 correction, same defect class).
//
// Shared by AtIconsTab/AtFontsTab/AtCatalogueTab rather than three copies
// of the same MouseArea math that could silently diverge — the grip
// PROPOSES a width via `dragged(...)`; the owning tab does its own
// clamping and Prefs write, exactly the way `WbSidebar` leaves clamping
// to `Workbench.qml`'s `setSidebarWidth`.
import QtQuick
import ".."
import "../dashboard"

Item {
    id: grip

    // The rail width the drag should measure from — set by the owner on
    // every open/resize, read once per press.
    property int startWidth: 0

    signal dragged(int proposedWidth)

    width: 6

    Rectangle {
        anchors.centerIn: parent
        width: 2
        height: parent.height
        color: gripArea.containsMouse || gripArea.pressed ? Colours.primary : Qt.alpha(Colours.outline, 0.35)

        Behavior on color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.colourDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.colourEasing
            }
        }
    }

    MouseArea {
        id: gripArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.SizeHorCursor

        property real pressSceneX: 0
        property int pressWidth: 0

        onPressed: mouse => {
            gripArea.pressSceneX = gripArea.mapToItem(null, mouse.x, 0).x;
            gripArea.pressWidth = grip.startWidth;
        }

        onPositionChanged: mouse => {
            if (!gripArea.pressed)
                return;
            var sceneX = gripArea.mapToItem(null, mouse.x, 0).x;
            grip.dragged(gripArea.pressWidth + (sceneX - gripArea.pressSceneX));
        }
    }
}
