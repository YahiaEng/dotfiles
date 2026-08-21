// motion-lint fixture (quick-260821-swp, D-28) — CHECK E, poisoned.
// A spatial easing (spatial-in) bound to `opacity` — an effects target.
// CHECK E must FAIL this: a bouncing fade is exactly the hazard the
// spatial/effects split exists to make impossible, and this fixture
// proves the gate actually catches it rather than only passing on clean
// input. Never loaded by any live Quickshell surface — motion-lint
// self-test fixture only.
import QtQuick

Rectangle {
    id: root
    opacity: 1

    Behavior on opacity {
        enabled: Motion.motionEnabled
        NumberAnimation {
            duration: Motion.spatialInDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.spatialInEasing
        }
    }
}
