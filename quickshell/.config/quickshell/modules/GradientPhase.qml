// GradientPhase.qml — the shell's ONE scrolling-accent clock.
//
// Every surface that paints the primary/secondary/tertiary accent gradient
// scrolling along its own long axis reads its phase from here instead of
// running a private NumberAnimation. Sibling singleton to Colours.qml and
// Motion.qml, registered in modules/qmldir the same way.
//
// WHY THIS EXISTS (quick task 260824-ns3, operator round 2 on Continuous).
// Two surfaces cannot be made to agree on a moving gradient by giving each
// its own animation: `loops: Animation.Infinite` from 0 to 1 keeps perfect
// RATE but inherits whatever offset their start times differed by, and the
// edge bar strips load through a LazyLoader while the bar does not — so the
// offset is nonzero, arbitrary, and constant. On Continuous the bar paints
// the weld that continues the top/bottom strip through its own body, and a
// constant phase offset there is a hard colour seam at the junction. One
// clock removes the drift by construction rather than by trying to start
// two animations together.
//
// It also silently fixes something nobody had reported: the top and bottom
// strips were already drifting against each other for the same reason. They
// are far enough apart that it never read as a fault, but they are now in
// step.
//
// PERIOD IS NOT HERE ON PURPOSE. Phase is dimensionless (0..1) and shared;
// the period is per-surface (a strip's period is its own length) and each
// consumer supplies its own. A consumer that must MATCH another surface's
// gradient — the Continuous weld is the only one today — takes that other
// surface's period and maps its own coordinates into that surface's space,
// which is a geometry question, not a timing one.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // 0 -> 1, one full period per cycle. Consumers multiply by their own
    // period and use ShapeGradient.RepeatSpread, so a wrap is seamless.
    property real phase: 0

    NumberAnimation on phase {
        running: Motion.motionEnabled
        from: 0
        to: 1
        duration: Motion.borderRotateDuration
        loops: Animation.Infinite
        easing.type: Easing.Linear
    }
}
