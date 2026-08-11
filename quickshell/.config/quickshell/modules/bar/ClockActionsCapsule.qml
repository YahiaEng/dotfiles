// ClockActionsCapsule.qml — the clock + actions slot (Phase 18 Plan 05,
// D-18-10).
//
// Owner: 18-11 for the five action entries (`gaming`, `notifications`,
// `idleInhibitor`, `settings`, `power`) — the two athena drawers plus the
// four permanent extras.
//
// This one is NOT empty: 18-01's live clock moves here intact, carried
// exactly rather than rebuilt — see the SystemClock declaration below.
import QtQuick
import "../dashboard"

BarCapsule {
    id: clockActionsCapsule
    capsuleId: "clockActions"

    // Event-driven clock, deliberately NOT a repeating Timer: this
    // surface never unmounts, so a 1Hz (or any repeating) Timer would be
    // a permanent session cost for a value that changes once a minute.
    // SystemClock at Minutes precision wakes exactly once per minute —
    // 18-01's own permanent-liveness discipline, carried unchanged across
    // this move.
    SystemClock {
        id: barClock
        enabled: true
        precision: SystemClock.Minutes
    }

    // Line 1 in both orientations: the time itself.
    Text {
        id: clockTimeText
        font.pixelSize: Design.fontLabel
        font.weight: Design.weightBody
        color: clockActionsCapsule.contentColour
        text: Qt.formatDateTime(barClock.date, "HH:mm")
    }

    // Line 2, vertical only (D-18-14's two-stacked-lines form): a short
    // date, sized to fit Design.barColumnWidth with no truncation. Hidden
    // in horizontal, where the capsule stays a single line — and, per the
    // shared chrome's own visibility rule, an invisible child is excluded
    // from the positioner's spacing too.
    Text {
        id: clockDateText
        visible: clockActionsCapsule.vertical
        font.pixelSize: Design.fontLabel
        font.weight: Design.weightBody
        color: clockActionsCapsule.contentColour
        text: Qt.formatDateTime(barClock.date, "ddd")
    }
}
