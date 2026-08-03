// DragGhost.qml — the cursor-following still snapshot (Phase 16 Plan 06,
// D-16-12/D-16-14). Overview.qml instantiates exactly one of these; the
// drag session it belongs to lives in Overview.qml, not here — this type
// only draws whatever session state it is told about.
//
// WHAT THIS IS NOT: a second capture path. The visible snapshot is a fresh
// `WindowThumbnail` instance (`liveCapture: false`, a single explicit
// `captureFrame()` call per drag) — the SAME type the grid itself uses,
// with a different capture mode, per this plan's own
// <assumption_delta_decision> ("It is not a fourth way to draw a window;
// it is the general representation with a different capture mode and a
// different transform"). Falling back to WindowThumbnail's own pending/
// failed placeholder chrome when no frame has landed is therefore free —
// it is the SAME state machine 16-05 already built, not a second one.
//
// WHY A `Loader` AROUND THE INNER THUMBNAIL, NOT A PLAIN INSTANCE: this
// ghost is reused across every drag in one summon (Overview.qml
// instantiates exactly one). WindowThumbnail's own `_everPopulated` is
// deliberately STICKY FORWARD (16-05's own documented shape) — reassigning
// `toplevel` on a persistent instance would NOT reset it, so a second drag
// of a window whose capture had not yet landed would incorrectly inherit
// the FIRST drag's "populated" verdict (and stale texture) the instant it
// started. Forcing the `Loader` to rebuild its `sourceComponent` on every
// `beginDrag()` call creates a genuinely fresh `WindowThumbnail` — and
// therefore a genuinely fresh three-state machine — per drag, without
// touching WindowThumbnail.qml's own sticky-forward contract, which every
// OTHER consumer (the grid) still relies on unchanged.
import QtQuick
import QtQuick.Effects
import "../"
import "../dashboard"

Item {
    id: root

    property var toplevel: null
    // The origin tile's own on-screen bounds (scene coordinates) — where a
    // cancelled drag animates back to. Set once per drag by beginDrag(),
    // never by the live cursor-follow path.
    property point originGlobal: Qt.point(0, 0)
    property size originSize: Qt.size(0, 0)
    // True for the whole span between a drag starting and it resolving
    // (drop or cancel) — drives visibility together with the return
    // animation below, which must keep the ghost visible for its own
    // duration even after `active` has already gone false.
    property bool active: false

    // D-16-12: 5% lift — a subtle "picked up" cue, not an exaggerated zoom
    // that would fight the snapshot's own already-small size
    // (16-UI-SPEC.md "Drag visuals").
    readonly property real liftScale: 1.05

    visible: root.active || returnAnimX.running || returnAnimY.running
    z: 1000

    width: root.originSize.width
    height: root.originSize.height
    scale: root.liftScale
    transformOrigin: Item.Center

    // ── The still snapshot, reusing WindowThumbnail's own type ───────────
    Loader {
        id: ghostLoader
        anchors.fill: parent
        sourceComponent: ghostThumbComponent
    }

    Component {
        id: ghostThumbComponent
        WindowThumbnail {
            toplevel: root.toplevel
            // Never the live view (D-16-12) — a single explicit
            // captureFrame() call (below, in beginDrag()) is the only way
            // this instance ever gets a frame.
            liveCapture: false
            x: 0
            y: 0
            width: root.width
            height: root.height
        }
    }

    // ── Soft drop shadow, MD3 elevation-3 weight ──────────────────────────
    // (16-UI-SPEC.md "Drag visuals": ~0.35 opacity black, ~8px blur radius.)
    // `MultiEffect` already ships in this repo for masking (DashboardTab.qml/
    // MediaTab.qml) — this is the "genuinely appropriate use" the UI-SPEC
    // header names, applied to a floating dragged element rather than a
    // static ring (GradientBorder.qml's own prior MultiEffect mask attempt
    // was rejected for a different reason — corner aliasing on a stroke —
    // unrelated to whether MultiEffect itself is trustworthy here).
    MultiEffect {
        anchors.fill: ghostLoader
        source: ghostLoader.item
        visible: !!ghostLoader.item
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.35)
        shadowOpacity: 0.35
        shadowBlur: 0.5
        shadowVerticalOffset: 2
        shadowHorizontalOffset: 0
        z: -1
    }

    // ── Live cursor-follow — imperative, deliberately NOT a property
    //    binding. A `Behavior on x/y` would add interpolation lag while
    //    live-following the cursor, which is exactly wrong for a drag
    //    (the whole reason a still snapshot is cheap enough to move at
    //    165Hz is that it moves 1:1, no animation in the loop). The
    //    animation only belongs to the CANCEL path below. ─────────────────
    function beginDrag(draggedToplevel, origin, size) {
        root.toplevel = draggedToplevel;
        root.originGlobal = origin;
        root.originSize = size;
        root.active = true;
        returnAnimX.stop();
        returnAnimY.stop();
        root.x = origin.x;
        root.y = origin.y;
        // Force a genuinely fresh WindowThumbnail (see header note above),
        // then trigger its one-shot capture.
        ghostLoader.sourceComponent = null;
        ghostLoader.sourceComponent = ghostThumbComponent;
        if (ghostLoader.item)
            ghostLoader.item.captureFrame();
    }

    function moveTo(pos) {
        // Cursor-centred: the ghost's midpoint tracks the pointer.
        root.x = pos.x - root.width / 2;
        root.y = pos.y - root.height / 2;
    }

    // A missed drop, a same-tile no-op, or a failed dispatch — D-16-14's
    // "cancels at zero cost": snap back to the origin tile on the standard
    // pair, then hide (the `visible` binding above clears itself the
    // instant both anims finish).
    function cancelDrag() {
        root.active = false;
        returnAnimX.to = root.originGlobal.x;
        returnAnimY.to = root.originGlobal.y;
        returnAnimX.start();
        returnAnimY.start();
    }

    // A successful drop — the window already moved, so there is nothing to
    // animate back to; hide immediately.
    function completeDrag() {
        root.active = false;
        returnAnimX.stop();
        returnAnimY.stop();
    }

    NumberAnimation {
        id: returnAnimX
        target: root
        property: "x"
        duration: Motion.standardDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.standardEasing
    }
    NumberAnimation {
        id: returnAnimY
        target: root
        property: "y"
        duration: Motion.standardDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.standardEasing
    }
}
