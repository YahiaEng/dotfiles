// motion-lint fixture (12-05, D-28).
// Models the Behavior + easing.bezierCurve consumption shape from
// 12-RESEARCH.md Pattern 2 (Quickshell.Singleton FileView/JsonAdapter
// precedent) and Pitfall 4 (Behavior.enabled bound to Motion.motionEnabled
// directly). Duration and easing both come from Motion.<property>
// references derived from motion.json's semantic keys. Never loaded by
// any live Quickshell surface — motion-lint self-test fixture only.
import QtQuick

Rectangle {
    id: root
    property real value: 0

    Behavior on value {
        enabled: Motion.motionEnabled
        NumberAnimation {
            duration: 200 // CORRUPTED: was Motion.standardDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }
    }
}
