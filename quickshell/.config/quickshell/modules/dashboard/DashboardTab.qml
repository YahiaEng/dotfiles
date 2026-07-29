// DashboardTab.qml — tab 0, composed (Phase 14 Plan 08, DASH-03, D-38).
//
// 14-03 created this file as a stub with a placeholder column; 14-04
// mounted the quick-toggle footer beneath it. This plan fills the space
// above that footer with D-38's identity-first single column: a clock/date
// hero, a display-only calendar month grid, a compact media widget and a
// CPU/Memory/Battery resources strip — in that fixed order.
//
// Root type Item, filled via anchors.fill: parent by the Loader Dashboard.qml
// places it in — actual rendered geometry is UNCHANGED from every prior
// plan: still anchors.fill: parent, so this item always matches whatever
// size its Loader currently has, including mid-resize-animation.
//
// ── Deviation (Rule 1 — this plan's own "no implicit size" instruction and
//    its `hyprctl -j layers h==860` acceptance check are BOTH stale) ──────
// 14-08-PLAN.md's Task 1 literally instructs "nothing in this file may
// publish an implicit size" and checks for a drawer height of exactly 860
// (D-02/D-04's ORIGINAL uniform 850x860 frame). That frame was SUPERSEDED
// at 14-03's own render gate (Round 2, APPROVED 2026-07-29, see
// 14-03-SUMMARY.md's key-decisions) in favour of PER-TAB DYNAMIC
// proportions: Dashboard.qml's `activeContentWidth`/`activeContentHeight`
// read `dashboardTabLoader.item.implicitWidth`/`implicitHeight` and animate
// the whole window to match. Every sibling tab built since (MediaTab
// 14-05, PerformanceTab 14-06, WeatherTab 14-07) — and this very file's own
// PRE-14-08 stub — already declare their own implicitWidth/implicitHeight
// for exactly this reason; the file this plan's read_first section
// describes ("its deliberate absence of an implicit size") does not match
// what 14-03/14-04 actually shipped. Omitting implicitWidth/implicitHeight
// here would not make this tab "not drive the drawer's height" — it would
// make `activeContentWidth`/`activeContentHeight` read a plain Item's
// default (0) whenever THIS tab is active, collapsing the frame to its
// floor (760x420) and clipping this composed column, which is a real
// regression, not a safer reading of D-04. Kept, not omitted; recorded
// here and in the SUMMARY rather than silently reinterpreted. The two
// specific automated assertions this contradicts (the implicit-size grep
// and the h==860 layers check) are superseded along with D-02/D-04 itself
// — every other check in this plan's verify blocks is still run and still
// holds.
//
// ── Design-constants consolidation verdict: DEFERRED to 14-09 ───────────
// Read 14-03-SUMMARY.md (the as-built property contract), 14-04/14-05/
// 14-06/14-07-SUMMARY.md's own consolidation notes before writing this:
// none of the four sibling plans found or built a shared mechanism by
// which a separate-file tab type reaches `dashboardWindow`'s spacing/type
// scale — QuickToggles.qml, MediaTab.qml, Dial.qml and PerformanceTab.qml
// all independently declare their OWN local copies of the same constants,
// each recording the identical reason: a QML `id` is lexically scoped to
// its declaring FILE, and every tab type here is a separate registered
// component instantiated inside `dashboardWindow`'s object tree, not
// textually nested inside it, so a bare `dashboardWindow.spacingLg`-style
// reference never resolves. This file follows the same precedent below —
// its own local constants, sourced from 14-UI-SPEC.md's tables. No shared
// mechanism exists to consume, so no sibling file is touched to build one:
// a singleton would need a registration line in `modules/dashboard/qmldir`
// (14-03's frozen manifest, nine types, not this plan's to edit), and a
// property contract onto `dashboardWindow` would need edits to
// `Dashboard.qml` and to four sibling tab files, none of which this plan
// may reach. Verdict: consolidation-deferred-to-14-09, with this exact
// rationale — 14-09's gate sweep is the first point where every file's
// real needs are known at once.
//
// ── D-41 widget-state register ────────────────────────────────────────────
// "populated" / "pending" / "empty" — carried on every one of this phase's
// nine modules/dashboard/ files. This tab is the first composition to
// drive the register from MORE than one widget: the compact media band and
// the resources strip each report their own state independently, and this
// file's own top-level `widgetState` is their aggregate.
//
// ── The calendar's viewed-month lifetime (recorded, not hidden) ───────────
// The viewed month resets to the current month every time this item is
// rebuilt — on every drawer summon (the drawer is destroyed on dismiss,
// D-14) and on every swipe away from and back to this tab (14-03's
// per-tab lazy Loader deactivates an off-screen pane, destroying this
// item). Both are locked lifecycle decisions this plan does not change;
// on a glance surface this is arguably correct, and it is carried to the
// render gate rather than assumed acceptable.
import QtQuick
import Quickshell
// Relative directory import to modules/ (parent) — the same mechanism
// shell.qml's own `import "modules"` uses, resolving Colours/Motion off
// that directory's checked-in qmldir.
import "../"

Item {
    id: root

    anchors.fill: parent

    // ── Property contract (14-03) — unchanged ───────────────────────────
    property var mediaBackend: null
    property var systemResources: null
    property int mediaTabIndex: -1
    property int performanceTabIndex: -1

    // Deep-link signal — the compact media widget and resources strip
    // (Task 2) emit this with a named tab index; Dashboard.qml's Task 2
    // answers it with pager.setCurrentIndex(index).
    signal tabRequested(int index)

    // D-41: "populated" | "pending" | "empty" — this tab's own aggregate
    // self-report, comparisons written out explicitly (register
    // consistency; every one of this phase's nine files carries the same
    // three literal strings).
    readonly property string widgetState: {
        var mediaState = root.mediaBackend ? root.mediaBackend.widgetState : "empty";
        var resourceState = root.systemResources ? root.systemResources.widgetState : "empty";
        if (mediaState === "populated" || resourceState === "populated")
            return "populated";
        if (mediaState === "pending" || resourceState === "pending")
            return "pending";
        return "empty";
    }

    // ── Design constants (see header — consolidation deferred) ──────────
    readonly property int panelPadding: 24 // 14-UI-SPEC.md Spacing Scale "lg"
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 16
    readonly property int spacingXl: 32
    // Vertical gap between this column's four bands and the footer below
    // them — the "one band gap" the plan names distinctly from
    // panelPadding. Reuses the already-named "md" scale token (14-UI-SPEC's
    // "card gaps"), not an invented value.
    readonly property int bandGap: root.spacingMd

    readonly property int fontDisplay: 32
    readonly property int fontHeading: 20
    readonly property int fontBody: 16
    readonly property int fontLabel: 12
    readonly property int weightDisplay: Font.Medium
    readonly property int weightEmphasis: Font.DemiBold
    readonly property int weightBody: Font.Normal

    readonly property int iconSizeMd: 24
    readonly property string symbolFontFamily: "Material Symbols Rounded"
    readonly property int cardRadius: 16

    // Independent natural-width hint (see header deviation note) — NEVER
    // read from any reactive/actual-geometry property, so implicitWidth
    // below cannot become the self-referential loop PerformanceTab's own
    // round-2 fix found and closed. The bands themselves stretch to
    // whatever width the actual frame gives this tab (anchors-driven,
    // below); this constant only feeds the advisory implicitWidth metadata
    // Dashboard.qml reads.
    readonly property int contentWidth: 400

    // ── Band heights (D-05 budget, computed once here per the plan's own
    //    instruction — Task 2 fills the last two bands' CONTENT; their
    //    HEIGHT is fixed now so the whole column's arithmetic is final at
    //    this task). ───────────────────────────────────────────────────
    readonly property int heroHeight: 64
    readonly property int calendarHeaderHeight: 28
    readonly property int calendarWeekdayRowHeight: 18
    readonly property int calendarCellSize: 28
    readonly property int calendarCardPadding: root.spacingSm
    readonly property int calendarCardHeight: root.calendarHeaderHeight + root.spacingXs
        + root.calendarWeekdayRowHeight + root.spacingXs
        + (6 * root.calendarCellSize) + root.calendarCardPadding * 2

    readonly property int compactArtSize: 56
    readonly property int compactMediaPadding: root.spacingSm
    readonly property int compactMediaHeight: root.compactArtSize + root.compactMediaPadding * 2
    // Deliberately bounded, NOT bound to the band's actual stretched
    // width — the compact-width elide backstop (14-UI-SPEC.md) needs a
    // genuinely narrow text column so a long real title/artist actually
    // elides, rather than a wide band that never triggers it.
    readonly property int compactTextWidth: 220

    readonly property int miniDialDiameter: 44
    readonly property int miniRingThickness: 5
    readonly property int resourcesStripPadding: root.spacingSm
    // 40 = Dial.qml's own fixed footprint beyond the ring: spacingXs(4) +
    // captionLine.height(18) + detailLine.height(18) — read directly off
    // Dial.qml's implicitHeight formula, not guessed.
    readonly property int resourcesStripHeight: root.miniDialDiameter + 40 + root.resourcesStripPadding * 2

    readonly property int bodyHeight: root.heroHeight + root.bandGap
        + root.calendarCardHeight + root.bandGap
        + root.compactMediaHeight + root.bandGap
        + root.resourcesStripHeight

    // ── D-05 slack arithmetic (also recorded verbatim in the SUMMARY) ───
    // Four band heights (heroHeight + calendarCardHeight + compactMediaHeight
    // + resourcesStripHeight) + three internal gaps + one gap above the
    // footer (four × bandGap total) + twice panelPadding + the footer's own
    // measured implicitHeight (QuickToggles: chipsRow.height 72 +
    // spacingSm 8 + presetRow.height 48 = 128), against D-02's original
    // 860px anchor less the tab bar height (796) — see SUMMARY for the
    // full numeric readout and the resulting slack percentage.

    implicitWidth: root.contentWidth + root.panelPadding * 2
    implicitHeight: root.panelPadding * 2 + root.bodyHeight + root.bandGap + toggles.implicitHeight

    // ── The clock/date hero's toolkit clock source (D-38) ────────────────
    // Minute precision: a glance clock shows hours and minutes, and this
    // means one wake a minute instead of sixty. `enabled` is bound to this
    // tab's own visibility — 14-03's lazy pane Loader already makes that
    // nearly redundant (this item only exists while it IS the active tab),
    // which is exactly why it costs one line and is worth having as the
    // explicit expression of the zero-idle doctrine. No repeating Timer of
    // any kind is declared in this file.
    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
        enabled: root.visible
    }

    // ── The composed column ──────────────────────────────────────────────
    // Anchored to the tab's top/left/right edges inset by panelPadding, and
    // to the top edge of the footer below (referenced by its own id) less
    // one band gap. The footer's own instance, anchors and inset are
    // unchanged from 14-04 — only an `id` was needed, and it already had one.
    Item {
        id: contentColumn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.panelPadding
        anchors.bottom: toggles.top
        anchors.bottomMargin: root.bandGap

        Column {
            anchors.fill: parent
            spacing: root.bandGap

            // ── 1. Clock/date hero ──────────────────────────────────────
            Item {
                id: heroRow
                width: parent.width
                height: root.heroHeight

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.spacingXs

                    Text {
                        id: timeLabel
                        // Locale-derived short time format — follows the
                        // machine's own locale rather than hardcoding a
                        // twelve- or twenty-four-hour convention.
                        text: Qt.locale().toString(systemClock.date, Qt.locale().timeFormat(Locale.ShortFormat))
                        font.pixelSize: root.fontDisplay
                        font.weight: root.weightDisplay
                        color: Colours.onSurface
                    }
                    Text {
                        id: dateLabel
                        // Locale-derived long date format — same reasoning,
                        // no hardcoded English month name.
                        text: Qt.locale().toString(systemClock.date, Qt.locale().dateFormat(Locale.LongFormat))
                        font.pixelSize: root.fontBody
                        font.weight: root.weightBody
                        color: Colours.onSurfaceVariant
                    }
                }
            }

            // ── 2. Calendar month grid (D-34, D-18) ──────────────────────
            Rectangle {
                id: calendarCard
                width: parent.width
                height: root.calendarCardHeight
                radius: root.cardRadius
                color: Colours.surfaceVariant

                property int viewYear: systemClock.date.getFullYear()
                property int viewMonth: systemClock.date.getMonth()

                function stepMonth(delta) {
                    var d = new Date(calendarCard.viewYear, calendarCard.viewMonth + delta, 1);
                    calendarCard.viewYear = d.getFullYear();
                    calendarCard.viewMonth = d.getMonth();
                }

                readonly property var localeObj: Qt.locale()
                // Locale.firstDayOfWeek uses ITS OWN 0-6 (Sunday=0)
                // numbering — verified live via a throwaway qml6 harness
                // (en_US.UTF-8 on this machine resolves 0, i.e. Sunday) —
                // distinct from Locale.dayName's 1-7 (Monday=1..Sunday=7)
                // numbering used just below. Two different conventions on
                // the same type; confirmed rather than assumed.
                readonly property int firstDayOfWeek: calendarCard.localeObj.firstDayOfWeek

                readonly property string monthLabel: calendarCard.localeObj.monthName(calendarCard.viewMonth, Locale.LongFormat) + " " + calendarCard.viewYear

                // Seven short day-name labels, ordered from the locale's
                // own first day of the week — never assumed Monday or
                // Sunday. dayNameIdx converts firstDayOfWeek's 0-6
                // (Sun-based) numbering to dayName's 1-7 (Mon=1..Sun=7).
                readonly property var weekdayLabels: {
                    var arr = [];
                    for (var i = 0; i < 7; i++) {
                        var dow = (calendarCard.firstDayOfWeek + i) % 7;
                        var dayNameIdx = dow === 0 ? 7 : dow;
                        arr.push(calendarCard.localeObj.dayName(dayNameIdx, Locale.ShortFormat));
                    }
                    return arr;
                }

                // Leading cells from the previous month — pure date-math,
                // no backend, no state file, no timer, no dependency of
                // any kind.
                readonly property int leadingCount: {
                    var firstOfMonth = new Date(calendarCard.viewYear, calendarCard.viewMonth, 1);
                    var fw = firstOfMonth.getDay(); // 0..6, Sunday-based — same numbering as firstDayOfWeek above
                    return (fw - calendarCard.firstDayOfWeek + 7) % 7;
                }

                // Exactly forty-two cells every time (6 rows x 7 columns) —
                // fixing six rows is the whole of the overflow answer: a
                // five-week month and a six-week month occupy identical
                // space, so nothing below the calendar ever moves.
                readonly property var calendarDays: {
                    var arr = [];
                    for (var i = 0; i < 42; i++) {
                        var dayOffset = i - calendarCard.leadingCount + 1;
                        var cellDate = new Date(calendarCard.viewYear, calendarCard.viewMonth, dayOffset);
                        arr.push({
                            day: cellDate.getDate(),
                            inMonth: cellDate.getMonth() === calendarCard.viewMonth,
                            // Matched against the clock's own live date, on
                            // year/month/day — never a cached value.
                            isToday: cellDate.getFullYear() === systemClock.date.getFullYear()
                                && cellDate.getMonth() === systemClock.date.getMonth()
                                && cellDate.getDate() === systemClock.date.getDate()
                        });
                    }
                    return arr;
                }

                // ── Month navigation, and why it is not arrow keys (D-18) ─
                // D-18 made bare arrow keys the tab-cycling gesture — this
                // card installs no key handler of any kind. The wheel is
                // scoped to this card alone (see the MouseArea below).
                property real wheelAccumulator: 0
                // Input-tuning value, deliberately NOT a motion token — one
                // physical wheel notch's angleDelta.y on this hardware.
                readonly property int wheelStepThreshold: 120

                // ── Header row: month label + chevrons ───────────────────
                Item {
                    id: calendarHeaderRow
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: root.calendarCardPadding
                    height: root.calendarHeaderHeight

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: calendarCard.monthLabel
                        font.pixelSize: root.fontHeading
                        font.weight: root.weightEmphasis
                        color: Colours.onSurface
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.spacingXs

                        // One inline component — the same MD3 state-layer
                        // ripple treatment the rest of the drawer uses,
                        // gated on Motion.motionEnabled and the emphasized
                        // motion pair, same shape as ToggleChip/
                        // TransportButton's own ripple.
                        component CalendarChevron: Item {
                            id: chevron
                            width: root.calendarHeaderHeight
                            height: root.calendarHeaderHeight
                            property string glyph: ""
                            signal activated()

                            Rectangle {
                                id: chevronCircle
                                anchors.fill: parent
                                radius: width / 2
                                color: "transparent"
                                clip: true

                                Rectangle {
                                    id: rippleCircle
                                    width: 0
                                    height: 0
                                    radius: width / 2
                                    color: Colours.onSurfaceVariant
                                    opacity: 0
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: chevron.glyph
                                font.family: root.symbolFontFamily
                                font.pixelSize: root.iconSizeMd
                                color: Colours.onSurfaceVariant
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onPressed: (mouse) => {
                                    if (!Motion.motionEnabled)
                                        return;
                                    var d = Math.max(chevronCircle.width, chevronCircle.height) * 2;
                                    rippleCircle.x = mouse.x - d / 2;
                                    rippleCircle.y = mouse.y - d / 2;
                                    rippleCircle.width = 0;
                                    rippleCircle.height = 0;
                                    rippleCircle.opacity = 0.16;
                                    rippleGrowAnim.stop();
                                    rippleFadeAnim.stop();
                                    rippleGrowAnim.to = d;
                                    rippleGrowAnim.start();
                                }
                                onClicked: chevron.activated()

                                NumberAnimation {
                                    id: rippleGrowAnim
                                    target: rippleCircle
                                    properties: "width,height"
                                    duration: Motion.emphasizedInDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Motion.emphasizedInEasing
                                    onFinished: rippleFadeAnim.start()
                                }
                                NumberAnimation {
                                    id: rippleFadeAnim
                                    target: rippleCircle
                                    property: "opacity"
                                    to: 0
                                    duration: Motion.emphasizedOutDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Motion.emphasizedOutEasing
                                }
                            }
                        }

                        CalendarChevron {
                            glyph: "chevron_left"
                            onActivated: calendarCard.stepMonth(-1)
                        }
                        CalendarChevron {
                            glyph: "chevron_right"
                            onActivated: calendarCard.stepMonth(1)
                        }
                    }
                }

                // ── Weekday header + day grid — centered at their own
                //    natural width within the full-width card. ───────────
                Column {
                    anchors.top: calendarHeaderRow.bottom
                    anchors.topMargin: root.spacingXs
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.spacingXs

                    Row {
                        id: weekdayRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: root.calendarWeekdayRowHeight

                        Repeater {
                            model: calendarCard.weekdayLabels
                            delegate: Text {
                                width: root.calendarCellSize
                                height: weekdayRow.height
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: modelData
                                font.pixelSize: root.fontLabel
                                color: Colours.onSurfaceVariant
                            }
                        }
                    }

                    Grid {
                        id: dayGrid
                        anchors.horizontalCenter: parent.horizontalCenter
                        columns: 7

                        // One inline component — three branches: a day in
                        // the viewed month, a leading/trailing day from an
                        // adjacent month (reduced opacity), and today
                        // (filled primary circle) — the one reserved use of
                        // the accent colour in this card.
                        component DayCell: Item {
                            id: dayCell
                            width: root.calendarCellSize
                            height: root.calendarCellSize
                            property int dayNumber: 1
                            property bool inMonth: true
                            property bool isToday: false

                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) - 4
                                height: width
                                radius: width / 2
                                color: dayCell.isToday ? Colours.primary : "transparent"
                                Behavior on color {
                                    enabled: Motion.motionEnabled
                                    ColorAnimation {
                                        duration: Motion.standardDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Motion.standardEasing
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: dayCell.dayNumber
                                font.pixelSize: root.fontBody
                                color: dayCell.isToday ? Colours.onPrimary
                                    : dayCell.inMonth ? Colours.onSurface
                                    : Colours.onSurfaceVariant
                                opacity: dayCell.inMonth ? 1 : 0.5
                                Behavior on color {
                                    enabled: Motion.motionEnabled
                                    ColorAnimation {
                                        duration: Motion.standardDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Motion.standardEasing
                                    }
                                }
                            }
                        }

                        Repeater {
                            model: calendarCard.calendarDays
                            delegate: DayCell {
                                dayNumber: modelData.day
                                inMonth: modelData.inMonth
                                isToday: modelData.isToday
                            }
                        }
                    }
                }

                // Wheel handler scoped to this card alone — declared FIRST
                // (paint order) so the header row's chevrons and the day
                // grid above still receive their own presses; a wheel
                // event over any part of the card (including the plain
                // Rectangle/Text cells, which install no handler of their
                // own) falls through to this MouseArea's onWheel.
                MouseArea {
                    anchors.fill: parent
                    onWheel: (wheel) => {
                        calendarCard.wheelAccumulator += wheel.angleDelta.y;
                        if (calendarCard.wheelAccumulator >= calendarCard.wheelStepThreshold) {
                            calendarCard.stepMonth(-1);
                            calendarCard.wheelAccumulator = 0;
                        } else if (calendarCard.wheelAccumulator <= -calendarCard.wheelStepThreshold) {
                            calendarCard.stepMonth(1);
                            calendarCard.wheelAccumulator = 0;
                        }
                    }
                }
            }

            // ── One reusable tap target, used twice (D-39/D-40) ──────────
            // A rounded surface in the surface-variant role, a pointing-
            // hand hover cursor, an MD3 state-layer ripple clipped to the
            // container, and one deep-link on tap that emits THIS tab's
            // own `tabRequested` signal with the named index — never a
            // bare integer. Writing it once, used by both the compact
            // media band and the resources strip below, is what makes
            // this the deep-link convention Phase 15 inherits rather than
            // two similar widgets.
            component DeepLinkSurface: Rectangle {
                id: linkSurface
                radius: root.cardRadius
                color: Colours.surfaceVariant
                clip: true

                property int targetTabIndex: -1

                Rectangle {
                    id: linkRippleCircle
                    width: 0
                    height: 0
                    radius: width / 2
                    color: Colours.onSurfaceVariant
                    opacity: 0
                }

                // Declared here, FIRST in this component's own body, so
                // any child added at instantiation (the art slot, the text
                // stack, the play/pause control, the mini dials) paints on
                // top of it and is checked first for input — exactly the
                // nested-target rule the compact widget's play/pause
                // control below depends on.
                MouseArea {
                    id: linkMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (mouse) => {
                        if (!Motion.motionEnabled)
                            return;
                        var d = Math.max(linkSurface.width, linkSurface.height) * 2;
                        linkRippleCircle.x = mouse.x - d / 2;
                        linkRippleCircle.y = mouse.y - d / 2;
                        linkRippleCircle.width = 0;
                        linkRippleCircle.height = 0;
                        linkRippleCircle.opacity = 0.1;
                        linkRippleGrowAnim.stop();
                        linkRippleFadeAnim.stop();
                        linkRippleGrowAnim.to = d;
                        linkRippleGrowAnim.start();
                    }
                    onClicked: {
                        if (linkSurface.targetTabIndex >= 0)
                            root.tabRequested(linkSurface.targetTabIndex);
                    }

                    NumberAnimation {
                        id: linkRippleGrowAnim
                        target: linkRippleCircle
                        properties: "width,height"
                        duration: Motion.emphasizedInDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.emphasizedInEasing
                        onFinished: linkRippleFadeAnim.start()
                    }
                    NumberAnimation {
                        id: linkRippleFadeAnim
                        target: linkRippleCircle
                        property: "opacity"
                        to: 0
                        duration: Motion.emphasizedOutDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.emphasizedOutEasing
                    }
                }
            }

            // ── 3. The compact media widget (D-40) ───────────────────────
            // Reads the ONE shared `mediaBackend` instance's already-
            // derived display fields — no second instance, no process, no
            // MPRIS access, no fallback re-derived here. Art + a title/
            // artist stack + one play/pause verb, and nothing else; every
            // other part of the widget deep-links to the Media tab.
            DeepLinkSurface {
                id: compactMedia
                width: parent.width
                height: root.compactMediaHeight
                targetTabIndex: root.mediaTabIndex

                readonly property string mediaState: root.mediaBackend ? root.mediaBackend.widgetState : "empty"
                readonly property bool isPopulated: compactMedia.mediaState === "populated"
                readonly property bool isPending: compactMedia.mediaState === "pending"

                // ── 1. Cover art — fixed square slot, drawer corner
                //      radius, clipping on (D-40's own wording: a square
                //      slot that crops rather than distorts non-square
                //      art — the MediaTab's full circular MultiEffect mask
                //      is a stricter requirement this compact slot does
                //      not carry). The quiet placeholder shows in all
                //      three non-ready cases: loading, empty art path, and
                //      a load failure — one visual, zero layout shift. ───
                Item {
                    id: compactArtSlot
                    anchors.left: parent.left
                    anchors.leftMargin: root.compactMediaPadding
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.compactArtSize
                    height: root.compactArtSize

                    Rectangle {
                        id: compactArtBackground
                        anchors.fill: parent
                        radius: root.cardRadius / 2
                        color: Colours.surface
                        clip: true

                        Image {
                            id: compactArtImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            // Same reasoning 14-05 recorded for the Media
                            // tab's own art resolver: the http(s) cache
                            // path is stable per-track, but the file://
                            // branch passes the player's own path straight
                            // through with no repo-owned cache guarantee —
                            // caching here could show the previous
                            // track's art under a reused path.
                            cache: false
                            source: (compactMedia.isPopulated && root.mediaBackend.artPath) ? ("file://" + root.mediaBackend.artPath) : ""
                            visible: compactArtImage.status === Image.Ready
                        }

                        Text {
                            id: compactArtPlaceholder
                            anchors.centerIn: parent
                            visible: compactArtImage.status !== Image.Ready
                            text: "music_note"
                            font.family: root.symbolFontFamily
                            font.pixelSize: root.compactArtSize * 0.5
                            color: Colours.onSurfaceVariant
                        }
                    }
                }

                // ── 2. Title/artist stack — deliberately bounded to
                //      `compactTextWidth`, not the band's own stretched
                //      width, so a genuinely long title/artist elides
                //      rather than never triggering the compact-width
                //      backstop. Both texts are set to plain text
                //      explicitly (T-14-27): third-party player metadata
                //      must never be interpreted as markup. ─────────────
                Column {
                    id: compactTextStack
                    anchors.left: compactArtSlot.right
                    anchors.leftMargin: root.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.compactTextWidth
                    spacing: root.spacingXs

                    Text {
                        id: compactTitle
                        width: parent.width
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: compactMedia.isPopulated ? (root.mediaBackend.displayTitle || "")
                            : (compactMedia.isPending ? "—" : "Nothing playing")
                        font.pixelSize: root.fontBody
                        font.weight: compactMedia.isPopulated ? root.weightEmphasis : root.weightBody
                        color: compactMedia.isPopulated ? Colours.onSurface : Colours.onSurfaceVariant
                    }
                    // Structurally present at every state (default
                    // visible: true) rather than toggled — an empty
                    // `text` renders nothing but keeps its reserved line
                    // height, which is D-41's "hidden without collapsing"
                    // rule, not a Column exclusion.
                    Text {
                        id: compactArtist
                        width: parent.width
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: (compactMedia.isPopulated && root.mediaBackend.displayArtist !== "") ? root.mediaBackend.displayArtist : ""
                        font.pixelSize: root.fontLabel
                        color: Colours.onSurfaceVariant
                    }
                }

                // ── 3. Play/pause — the one glance-frequency verb this
                //      widget grants (D-40): no skip, no seek, no volume,
                //      no player switcher. The glyph is read from the
                //      backend's playing predicate and never assigned by
                //      the press (D-22) — a command that fails or is
                //      refused leaves the button showing what the player
                //      is actually doing. ───────────────────────────────
                Item {
                    id: compactPlayPause
                    anchors.right: parent.right
                    anchors.rightMargin: root.compactMediaPadding
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40

                    readonly property bool playing: compactMedia.isPopulated && root.mediaBackend.playing

                    Rectangle {
                        id: compactPlayPauseCircle
                        anchors.fill: parent
                        radius: width / 2
                        color: compactMedia.isPopulated ? Colours.primary : Colours.surfaceVariant
                        opacity: compactMedia.isPopulated ? 1 : 0.5
                        Behavior on color {
                            enabled: Motion.motionEnabled
                            ColorAnimation {
                                duration: Motion.standardDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.standardEasing
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: compactPlayPause.playing ? "pause" : "play_arrow"
                            font.family: root.symbolFontFamily
                            font.pixelSize: root.iconSizeMd
                            color: compactMedia.isPopulated ? Colours.onPrimary : Colours.onSurfaceVariant
                        }
                    }

                    // The nested-target rule (D-40) — this MouseArea is a
                    // later sibling than `compactMedia`'s own background
                    // MouseArea (declared inside DeepLinkSurface, above),
                    // so it paints on top and is checked first for input:
                    // a press here is consumed HERE, never reaching the
                    // outer deep-link surface beneath it. Proven live by
                    // pressing repeatedly and confirming the pager never
                    // leaves the Dashboard tab.
                    MouseArea {
                        anchors.fill: parent
                        enabled: compactMedia.isPopulated
                        onClicked: root.mediaBackend.playPause()
                    }
                }
            }

            // ── 4. The resources strip (D-39) ────────────────────────────
            // Three mini-dials — CPU, Memory, Battery — instances of
            // 14-06's own Dial type at a smaller diameter; no arc geometry
            // is written here. Storage and network stay Performance-only.
            // Reads the ONE shared `systemResources` instance's published
            // fractions, per-metric state registers and shared formatters
            // — no second reader, no second poll timer, no metric
            // re-derived here.
            DeepLinkSurface {
                id: resourcesStrip
                width: parent.width
                height: root.resourcesStripHeight
                targetTabIndex: root.performanceTabIndex

                readonly property bool hasResources: root.systemResources !== null && root.systemResources !== undefined
                // A fixed, modest gap rather than a computed edge-to-edge
                // spread: Dial.qml's own caption Row centers icon+label
                // text UNDER each dial's fixed diameter and can overflow
                // that diameter on either side (its own frozen file, not
                // ours to edit) — "Battery" is the widest label, and a
                // wide computed spacing pushed the rightmost dial's
                // caption past this strip's own clipped right edge,
                // truncating "No battery" to "No batter" (caught live,
                // fixed here rather than left for the render gate to
                // catch). A tight, centered cluster with generous side
                // margin keeps every caption's overflow well inside the
                // clip boundary regardless of which label is longest.
                readonly property int dialSpacing: root.spacingXl

                Row {
                    anchors.centerIn: parent
                    spacing: resourcesStrip.dialSpacing

                    Dial {
                        diameter: root.miniDialDiameter
                        ringThickness: root.miniRingThickness
                        label: "CPU"
                        icon: "memory"
                        accentColor: Colours.primary
                        widgetState: resourcesStrip.hasResources ? root.systemResources.cpuState : "pending"
                        value: resourcesStrip.hasResources ? root.systemResources.cpuFraction : 0
                        valueText: resourcesStrip.hasResources ? root.systemResources.formatPercent(root.systemResources.cpuFraction) : ""
                        emptySymbol: "help"
                        emptyText: "Unavailable"
                    }
                    Dial {
                        diameter: root.miniDialDiameter
                        ringThickness: root.miniRingThickness
                        label: "Memory"
                        icon: "developer_board"
                        accentColor: Colours.secondary
                        widgetState: resourcesStrip.hasResources ? root.systemResources.memoryState : "pending"
                        value: resourcesStrip.hasResources ? root.systemResources.memoryFraction : 0
                        valueText: resourcesStrip.hasResources ? root.systemResources.formatPercent(root.systemResources.memoryFraction) : ""
                        // The one detail line worth having at glance size
                        // (plan's own call) — a used-of-total figure
                        // through the shared byte formatter.
                        detailText: resourcesStrip.hasResources
                            ? (root.systemResources.formatBytes(root.systemResources.memoryUsedBytes) + " / "
                                + root.systemResources.formatBytes(root.systemResources.memoryTotalBytes))
                            : ""
                        emptySymbol: "help"
                        emptyText: "Unavailable"
                    }
                    // The strip's own partial state on this machine — no
                    // battery hardware, so this dial's empty branch is
                    // what actually renders, at the same footprint as the
                    // other two (D-41).
                    Dial {
                        diameter: root.miniDialDiameter
                        ringThickness: root.miniRingThickness
                        label: "Battery"
                        icon: "battery_full"
                        accentColor: Colours.error
                        widgetState: resourcesStrip.hasResources ? root.systemResources.batteryState : "pending"
                        value: resourcesStrip.hasResources ? root.systemResources.batteryFraction : 0
                        valueText: resourcesStrip.hasResources ? root.systemResources.formatPercent(root.systemResources.batteryFraction) : ""
                        detailText: resourcesStrip.hasResources ? root.systemResources.batteryStateText : ""
                        emptySymbol: "battery_unknown"
                        emptyText: "No battery"
                    }
                }
            }
        }
    }

    // ── Toggle-block footer (D-38, 14-04) — the tab's base line, unchanged
    //    apart from nothing: it already carried an id. ───────────────────
    QuickToggles {
        id: toggles
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.panelPadding
        height: implicitHeight
    }
}
