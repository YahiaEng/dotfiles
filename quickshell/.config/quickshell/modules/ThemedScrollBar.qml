// modules/ThemedScrollBar.qml — the shared scroll indicator for every
// Flickable/ListView/GridView in the shell (quick task 260828-nav).
//
// ── WHY THIS EXISTS ────────────────────────────────────────────────────
// Censused before writing it: 39 files in this tree carry a Flickable,
// ListView or GridView; exactly 3 carried a ScrollBar. So 36 scrollable
// surfaces gave the user no indication that there WAS more content, how
// much, or where they were in it. Rather than fix the two the operator
// happened to name, this is the shared primitive so the population gets
// fixed at source (see the settings NavRail and PageBase for the first
// two consumers).
//
// ── DESIGN ─────────────────────────────────────────────────────────────
// Deliberately NOT QtQuick.Controls' ScrollBar: that is a QQC2 Control,
// which colour-lint documents as a blind spot (§6.1) and which brings
// the Qt style's own palette in through the back door. This is a plain
// Rectangle pair driven directly off the Flickable's own
// visibleArea.yPosition/heightRatio, so every colour is an explicit
// `Colours.*` role and there is no style to inherit from.
//
// The bar is "small" by intent (operator's word): 4px at rest, widening
// to 8px on hover, so it reads as an indicator rather than a chrome
// element. It fades out entirely when the content fits.
import QtQuick

Item {
    id: root

    // The Flickable (or ListView/GridView — both derive from Flickable)
    // this bar reports on. Required; there is no sensible default.
    required property Flickable flickable

    // Set false for a purely decorative indicator.
    property bool interactive: true

    readonly property bool scrollable: flickable.contentHeight > flickable.height + 1
    readonly property int restWidth: 4
    readonly property int hoverWidth: 8

    // ── THE GUTTER (quick task 260829-gtr) ─────────────────────────────
    // Measured, not assumed: with the bar anchored to `flickable.right` and
    // nothing reserving space for it, it painted ON TOP of the content in
    // all 20 consumers. In the settings nav rail the row pill spans
    // x 8..588 and the bar landed at 581..584 — inside the pill, 8px short
    // of its own right edge. That is the "scrollbar clipping the menu
    // items" report.
    //
    // The fix reserves width instead of overlaying it. Every one of the 20
    // consumers anchors its Flickable's right edge to a parent (via
    // `anchors.fill` or an explicit `anchors.right`) and NOT ONE sets an
    // explicit `width` — enumerated, not sampled — so narrowing the
    // Flickable propagates to every content binding for free: a Column at
    // `width: flick.width`, a delegate at `ListView.view.width`, all of it.
    // That is why this reserves on the Flickable rather than asking 20 call
    // sites to inset their own content.
    readonly property int gutter: hoverWidth + 4

    // Additive, and it has to be. Two consumers (PageBase, PanelDialog) set
    // `anchors.margins` for their own padding, and in Qt a specific
    // `anchors.rightMargin` OVERRIDES `anchors.margins` for that edge —
    // assigning the gutter alone would silently delete their padding. So
    // the effective margin is read first and the gutter added to it.
    // Guarded because a hot reload re-runs this on a Flickable that may
    // already carry the gutter; without `_reserved` the margin would grow
    // by 12px on every QML save.
    property bool _reserved: false
    Component.onCompleted: {
        if (_reserved || !flickable)
            return;
        const a = flickable.anchors;
        const base = a.rightMargin || a.margins || 0;
        a.rightMargin = base + gutter;
        _reserved = true;
    }

    anchors.right: flickable.right
    anchors.top: flickable.top
    anchors.bottom: flickable.bottom
    // Sits in the reserved gutter, just outside the content's right edge,
    // rather than over it. The 2px keeps it off the very edge of the box.
    anchors.rightMargin: -gutter + 2
    width: hoverWidth
    // Still above the content: a scroll indicator the content can paint
    // over is not an indicator. The gutter means it no longer has to be.
    z: 100
    visible: scrollable

    // ── track ──────────────────────────────────────────────────────────
    Rectangle {
        id: track
        anchors.horizontalCenter: parent.horizontalCenter
        width: handleMouse.containsMouse || handleMouse.pressed ? root.hoverWidth : root.restWidth
        height: parent.height
        radius: width / 2
        color: Qt.alpha(Colours.onSurfaceVariant, 0.12)
        opacity: root.scrollable ? 1 : 0

        Behavior on width {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.spatialMoveDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.spatialMoveEasing
            }
        }
        Behavior on opacity {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }

        // ── handle ─────────────────────────────────────────────────────
        Rectangle {
            id: handle
            width: parent.width
            radius: width / 2
            // A handle shorter than its own width renders as a sliver with
            // a broken cap, so the visible ratio is floored at twice the
            // track width rather than used raw.
            height: Math.max(parent.width * 2, track.height * root.flickable.visibleArea.heightRatio)
            y: root.flickable.visibleArea.yPosition * (track.height - height) / Math.max(0.0001, 1 - root.flickable.visibleArea.heightRatio)
            color: handleMouse.containsMouse || handleMouse.pressed
                 ? Colours.onSurfaceVariant
                 : Qt.alpha(Colours.onSurfaceVariant, 0.45)

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }
        }
    }

    // ── drag ───────────────────────────────────────────────────────────
    // Drag deltas are captured against the TRACK, a frame that does not
    // move while the drag is in flight. Measuring against the handle —
    // which the drag itself relocates — makes the delta speed-dependent
    // and the scroll drift (recorded trap, quick task 260828-75k).
    MouseArea {
        id: handleMouse
        anchors.fill: parent
        enabled: root.interactive && root.scrollable
        hoverEnabled: true
        preventStealing: true

        property real pressYInTrack: 0
        property real pressContentY: 0

        onPressed: mouse => {
            pressYInTrack = mapToItem(track, 0, mouse.y).y;
            pressContentY = root.flickable.contentY;
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            const travel = track.height - handle.height;
            if (travel <= 0)
                return;
            const dy = mapToItem(track, 0, mouse.y).y - pressYInTrack;
            const range = root.flickable.contentHeight - root.flickable.height;
            root.flickable.contentY = Math.max(0, Math.min(range, pressContentY + dy * range / travel));
        }
    }
}
