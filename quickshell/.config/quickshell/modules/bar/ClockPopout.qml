// ClockPopout.qml — the clock section's popout body (Phase 18 Plan 14,
// QBAR-09). Follows WifiPopout.qml's shape as the closest in-plan
// precedent.
//
// ── Readiness verdict this body relies on ────────────────────────────────
// No pending phase exists — this is the one body of the six with no
// backend anywhere in it. There is nothing to be not-yet-resolved about:
// the arithmetic below is pure and synchronous over a date this file is
// handed, so declaring a pending or failed state here would be
// fabricating a state that cannot occur.
//
// ── No second clock ───────────────────────────────────────────────────────
// The current date arrives as a plain handed-down property from the clock
// capsule's own existing time source (ClockActionsCapsule.qml's
// SystemClock) — this file declares no SystemClock, no Timer and no
// Process of any kind. The bar is this phase's first surface with no
// dismissed state, so a second clock here would tick for the whole
// session to answer a question the capsule's clock is already answering.
//
// ── The accepted duplication (recorded per the plan's own instruction) ──
// This file carries a DELIBERATE second copy of the month-grid arithmetic
// that lives in DashboardTab.qml's calendar card. Four reasons, in order:
// (1) the arithmetic is pure, stateless and has no backend, no timer and
// no dependency of any kind, so a copy cannot drift behaviourally the way
// a copy of stateful code would; (2) extracting it into one shared type
// would mean editing a shipped v3.0 surface mid-phase for a refactor with
// no user-visible benefit; (3) therefore the duplication is accepted; and
// (4) the accepted cost is a REVIEW OBLIGATION — the two copies must be
// diffed whenever either changes, and the one place that obligation
// genuinely bites is the locale handling, because the weekend-day rule and
// the two different locale numbering conventions were human-tuned and
// confirmed live in DashboardTab.qml rather than derived from a spec.
import QtQuick
import "../"
import "../dashboard"

SectionPopout {
    id: root

    // Handed down from the clock capsule's own SystemClock — never a
    // second time source declared inside this file.
    property date currentDate

    sectionId: "clock"
    popoutGlyph: "calendar_month"

    readonly property var _localeObj: Qt.locale()
    // Locale.firstDayOfWeek's own 0-6 (Sunday=0) numbering — distinct from
    // Locale.dayName's 1-7 (Monday=1..Sunday=7) numbering used below.
    // DashboardTab.qml's own calendar card confirmed this pairing live;
    // this body carries the identical conversion rather than re-deriving
    // it (see this file's header on the accepted duplication).
    readonly property int _firstDayOfWeek: root._localeObj.firstDayOfWeek
    readonly property int _viewYear: root.currentDate.getFullYear()
    readonly property int _viewMonth: root.currentDate.getMonth()

    popoutTitle: root._localeObj.monthName(root._viewMonth, Locale.LongFormat) + " " + root._viewYear

    // Seven short day-name labels, ordered from the locale's own first day
    // of the week — never an assumed Monday or Sunday. dayNameIdx converts
    // firstDayOfWeek's 0-6 (Sun-based) numbering to dayName's 1-7
    // (Mon=1..Sun=7). isFriday carries this locale's own weekend day,
    // matched on getDay() === 5 — the same numbering calendarDays uses
    // below, carried across from DashboardTab.qml's own round-3 finding.
    readonly property var _weekdayLabels: {
        var arr = [];
        for (var i = 0; i < 7; i++) {
            var dow = (root._firstDayOfWeek + i) % 7;
            var dayNameIdx = dow === 0 ? 7 : dow;
            arr.push({
                text: root._localeObj.dayName(dayNameIdx, Locale.ShortFormat),
                isFriday: dow === 5
            });
        }
        return arr;
    }

    // Leading cells from the previous month — pure date-math, no backend,
    // no state file, no timer, no dependency of any kind.
    readonly property int _leadingCount: {
        var firstOfMonth = new Date(root._viewYear, root._viewMonth, 1);
        var fw = firstOfMonth.getDay();
        return (fw - root._firstDayOfWeek + 7) % 7;
    }

    // Exactly forty-two cells every time (6 rows x 7 columns) — fixing six
    // rows is the whole of the overflow answer: a five-week and a
    // six-week month occupy identical space, so nothing in this body ever
    // moves between months.
    readonly property var _calendarDays: {
        var arr = [];
        for (var i = 0; i < 42; i++) {
            var dayOffset = i - root._leadingCount + 1;
            var cellDate = new Date(root._viewYear, root._viewMonth, dayOffset);
            arr.push({
                day: cellDate.getDate(),
                inMonth: cellDate.getMonth() === root._viewMonth,
                isToday: cellDate.getFullYear() === root.currentDate.getFullYear()
                    && cellDate.getMonth() === root.currentDate.getMonth()
                    && cellDate.getDate() === root.currentDate.getDate(),
                isFriday: cellDate.getDay() === 5
            });
        }
        return arr;
    }

    // Provenance: DashboardTab.qml's own calendarCellSize, the compact
    // calendar card's own row height, cited so the two calendars read at
    // the same rhythm rather than at two different scales.
    readonly property int _cellHeight: 28

    // This is the one body of the six whose state register cannot vary:
    // there is no asynchronous source anywhere in this file, so declaring
    // a pending or failed state here would be fabricating a state that
    // cannot occur. This sentence is this body's own row of Task 1's
    // readiness audit.
    bodyState: "populated"

    wayfindingLabel: "Open dashboard"
    // dashboardWindow.tabIndexDashboard (modules/Dashboard.qml) is 0 —
    // confirmed by reading that file's own declared tab constants rather
    // than counting the tab list by hand.
    onWayfindingActivated: PopoutController.requestDashboard(0)

    Column {
        id: calendarBody
        width: parent.width
        spacing: Design.spacingXs

        Row {
            id: weekdayRow
            width: parent.width

            Repeater {
                model: root._weekdayLabels

                Text {
                    id: weekdayCell
                    required property var modelData
                    width: calendarBody.width / 7
                    height: root._cellHeight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    textFormat: Text.PlainText
                    text: weekdayCell.modelData.text
                    font.pixelSize: Design.fontLabel
                    color: weekdayCell.modelData.isFriday ? BarRoles.warn : BarRoles.capsuleFg
                }
            }
        }

        Grid {
            id: dayGrid
            width: parent.width
            columns: 7

            Repeater {
                model: root._calendarDays
                delegate: Item {
                    id: dayCell
                    required property var modelData
                    width: dayGrid.width / 7
                    height: root._cellHeight

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 4
                        height: width
                        radius: width / 2
                        color: dayCell.modelData.isToday ? BarRoles.accent : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        textFormat: Text.PlainText
                        text: dayCell.modelData.day
                        font.pixelSize: Design.fontBody
                        color: dayCell.modelData.isToday ? BarRoles.onAccent
                            : dayCell.modelData.isFriday ? BarRoles.warn
                            : dayCell.modelData.inMonth ? BarRoles.popoutFg
                            : BarRoles.capsuleFg
                        opacity: dayCell.modelData.inMonth ? 1 : 0.5
                    }
                }
            }
        }
    }

    // No month navigation. No stepping function, no chevrons, no wheel
    // handling — paging months is a detail-surface action and the foot
    // link above is the path to it. The dashboard's own calendar card is
    // where paging lives; its absence here is deliberate, not an
    // oversight.
}
