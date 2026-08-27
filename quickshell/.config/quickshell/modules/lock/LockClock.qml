// LockClock.qml — shared clock primitive, all five lock layouts instantiate
// this rather than each rolling their own (quick task 260827-833 Task 1,
// LOCK-01). 12-hour format to match what is on screen today (hyprlock's
// `$TIME12`). Hour and minute are two separate `Text` items — hour in
// `Colours.primary`, minute in `Colours.secondary` — per
// `caelestia-lock/center/Clock.qml`, with the AM/PM marker as a separate,
// smaller run, also per that reference. `scale` is a plain multiplier on
// the base 96px hour size (hyprlock.conf's own measured size) so every
// layout can share one primitive at its own scale.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../"

Item {
    id: root

    property real scale: 1.0
    // hyprlock.conf's measured continuity size (96px). Every layout scales
    // off this one base.
    readonly property real baseSize: 96

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    SystemClock {
        id: clock

        enabled: true
        precision: SystemClock.Minutes
    }

    Row {
        id: row

        spacing: 2 * root.scale

        Text {
            id: hourLabel

            text: Qt.formatDateTime(clock.date, "h:")
            color: Colours.primary
            font.pixelSize: root.baseSize * root.scale
            font.family: "FiraCode Nerd Font"
            font.bold: true
        }

        Text {
            id: minuteLabel

            text: Qt.formatDateTime(clock.date, "mm")
            color: Colours.secondary
            font.pixelSize: root.baseSize * root.scale
            font.family: "FiraCode Nerd Font"
            font.bold: true
            anchors.baseline: hourLabel.baseline
        }

        Text {
            id: ampmLabel

            text: Qt.formatDateTime(clock.date, "AP")
            color: Colours.onSurfaceVariant
            font.pixelSize: root.baseSize * root.scale * 0.26
            font.family: "FiraCode Nerd Font"
            font.bold: true
            anchors.bottom: hourLabel.bottom
            anchors.bottomMargin: root.baseSize * root.scale * 0.1
        }
    }
}
