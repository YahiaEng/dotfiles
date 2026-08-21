// motion-lint fixture (quick-260821-swp, D-28) — CHECK E.
// A spatial easing (spatial-in) bound to a spatial property (x). CHECK E
// must PASS this: overshoot on a position transition is exactly what the
// spatial easing family exists for. Never loaded by any live Quickshell
// surface — motion-lint self-test fixture only.
import QtQuick

Rectangle {
    id: root
    property real x: 0

    Behavior on x {
        enabled: Motion.motionEnabled
        NumberAnimation {
            duration: Motion.spatialInDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.spatialInEasing
        }
    }
}
