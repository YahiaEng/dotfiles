// DashboardTab.qml — tab 0, composed (Phase 14 Plan 08, DASH-03, D-38).
//
// 14-03 created this file as a stub with a placeholder column; 14-04
// mounted the quick-toggle footer beneath it. This plan fills the space
// above that footer with D-38's identity-first single column: a clock/date
// hero, a display-only calendar month grid, a compact media widget and a
// resources strip — in that fixed order. Originally CPU/Memory/Battery
// (this plan's own scope); round 3's render gate added a fourth Storage
// dial (see the round-3 header note below) — see that note before
// assuming this is still three dials.
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
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
// Relative directory import to modules/ (parent) — the same mechanism
// shell.qml's own `import "modules"` uses, resolving Colours/Motion off
// that directory's checked-in qmldir.
import "../"

// ── Render-gate round 2 fixes (2026-07-30) ─────────────────────────────
// Round 1 was NOT approved. Four concrete points, fixed below:
//
//   1. Calendar width — "lots of empty space to its sides." The month
//      grid's per-cell WIDTH now derives from the calendar card's own real
//      (wider-than-planned, D-02 superseded) width divided across 7
//      columns (`calendarCard.cellWidth`), instead of sitting at the fixed
//      `calendarCellSize` centered with large side margins. Per-row HEIGHT
//      stays `calendarCellSize` unchanged, so Task 1's six-row D-05 budget
//      arithmetic is untouched — only the horizontal fill changes.
//
//   2. Media card cover art — "the album art should use the same circular
//      dotted look as the media panel." The compact art slot is redrawn
//      against MediaTab.qml's own round-3/round-4 art treatment: a genuine
//      circle (not a rounded square) with a static dashed ring drawn via
//      QtQuick.Shapes, and a QtQuick.Effects MultiEffect alpha mask for a
//      true circular crop (a plain `clip: true` Rectangle only clips to
//      its bounding box, never to the rounded shape — 14-05's own
//      round-4 finding, reused here rather than rediscovered). Scaled down
//      for this compact card; `compactArtSize` stays the slot's outer
//      bounding box so the band-height arithmetic is unaffected.
//
//   3. Media card transport — "play/pause looks awkward... add next/prev
//      too." `previousTrack()`/`nextTrack()` are added alongside
//      play/pause, grouped as one cluster seated directly after the
//      title/artist stack (not stranded at the card's far edge with a
//      wide dead gap after the text). NOTE — this is a deliberate reversal
//      of 14-08-PLAN.md's own must_haves ("play/pause control and nothing
//      else") and its explicit fence ("any transport verb on the compact
//      widget beyond play/pause... adding them here deletes the reason
//      the deep-link exists"). The render gate is the authoritative
//      arbiter over a plan's frozen must_haves per this workflow's own
//      rules, and the human's literal, direct instruction this round was
//      to add both buttons — recorded here as a deviation carried to the
//      NEXT gate round for explicit re-confirmation, not silently
//      absorbed as if the plan always said this.
//
//   4. Quick-toggle footer affordance — the human's feedback ("a fresh
//      user will not know what their function is") is fixed in
//      QuickToggles.qml itself (14-04's file, outside this plan's declared
//      files_modified) — see that file's own round-2 header note. Recorded
//      here too since it is a deviation from this plan's ownership fence.
// ────────────────────────────────────────────────────────────────────────
//
// ── Render-gate round 3 fixes (2026-07-30) ─────────────────────────────
// Round 2 was APPROVED, including item 3's scope reversal (next/prev
// transport stays permanently). Four more concrete points, fixed below:
//
//   1. Calendar — Friday theme-colored. This locale's own weekend
//      convention (per the human's direct statement) treats FRIDAY as the
//      weekend day, not Saturday/Sunday — matched on the JavaScript Date
//      type's own `getDay() === 5` (0=Sunday..6=Saturday, the ECMA-262
//      standard numbering; Friday is always index 5 regardless of locale,
//      since `getDay()` numbers actual weekdays, not a locale's display
//      order) rather than any hardcoded Saturday/Sunday assumption. Both
//      the weekday header glyph ("Fri") and every Friday day-number cell
//      (in-month and adjacent-month alike) take `Colours.tertiary` — not
//      `primary`, which 14-UI-SPEC.md's Color section reserves to an
//      enumerated list that does not include this. Today's own cell still
//      wins over Friday when the two coincide (today is `primary`,
//      reserved and unconditional).
//
//   2. Hero — current day number theme-colored. The date line under the
//      time now renders as three text runs (prefix / day-number / suffix)
//      instead of one opaque locale string, so only the day-of-month
//      NUMBER itself can be tinted `Colours.tertiary` (matching Friday's
//      own tertiary choice above and Storage's tertiary ring below — one
//      consistent "notable, not primary" accent this round) without
//      hardcoding the locale's own format structure: the split point is
//      found by searching the already-locale-formatted string for the day
//      number as a standalone digit token (word-bounded), never by
//      assuming a fixed position — a locale whose long-date format omits
//      the day as a bare number, or repeats the same digits inside a
//      four-digit year with no separating punctuation, degrades quietly
//      to the whole string in the un-tinted colour rather than mis-
//      colouring an unrelated substring.
//
//   3. Media card — controls placement/stretch. The transport cluster
//      moves back to a right-edge anchor (round 2 moved it to hug the
//      text stack instead; the human's own round-3 wording, "move ... a
//      bit to the right", asks for exactly the position round 2 moved
//      away from) and every button grows — prev/next from 32px to 40px,
//      play/pause from 40px to 56px, and the gap between all three from
//      `spacingXs` to `spacingMd` — so the cluster itself now reads as a
//      deliberate, generously-spaced control group rather than a small
//      huddle of buttons.
//
//   4. Resources strip — spacing + a fourth dial. `dialSpacing` widens
//      (`spacingXl` alone to `spacingXl + spacingMd`) and a Storage mini-
//      dial joins CPU/Memory/Battery, reusing `SystemResources`'
//      `storageFraction`/`storageUsedBytes`/`storageTotalBytes`/
//      `storageState` — the SAME shared instance and the SAME `formatBytes`
//      helper PerformanceTab.qml's own Storage dial already reads, never a
//      second reader. Icon (`storage`) and accent (`Colours.tertiary`) are
//      copied verbatim from PerformanceTab.qml's own per-ring convention
//      (14-06 round 2: primary/secondary/tertiary/error across its four
//      dials) so the mini strip reads as the same dial family, not a
//      second dialect. NOTE — this is a deliberate reversal of
//      14-08-PLAN.md's own explicit fence ("storage and network stay
//      Performance-only... paying glance-rent for two more is exactly
//      what D-39 rejected"), on the human's direct render-gate
//      instruction this round — recorded here as a deviation, same
//      precedent as round 2's transport-cluster reversal. Network is NOT
//      added — the human asked only for storage.
//
// Still open from round 1, not yet explicitly answered by the human and
// re-listed at every gate since: fit/width at the live 2560x1440 monitor
// (D-02 assumed 2160x1440); the calendar's month-reset-on-rebuild
// consequence's acceptability; and the compact widget/resources strip's
// deep-link discoverability (no visual hint either card is tappable).
// ────────────────────────────────────────────────────────────────────────

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
    // Round-2 fix — circular dotted-ring cover art (see file header). This
    // stays the SLOT's outer bounding box, unchanged, so the band-height
    // arithmetic Task 1 fixed still reads off it; the ring sits inside
    // that same box rather than growing it.
    readonly property int compactRingGap: 3
    readonly property int compactRingStrokeWidth: 2
    readonly property int compactArtCircleSize: root.compactArtSize - (root.compactRingGap + root.compactRingStrokeWidth) * 2
    readonly property real compactRingRadius: root.compactArtCircleSize / 2 + root.compactRingGap
    readonly property int compactMediaPadding: root.spacingSm
    readonly property int compactMediaHeight: root.compactArtSize + root.compactMediaPadding * 2
    // Deliberately bounded, NOT bound to the band's actual stretched
    // width — the compact-width elide backstop (14-UI-SPEC.md) needs a
    // genuinely narrow text column so a long real title/artist actually
    // elides, rather than a wide band that never triggers it.
    readonly property int compactTextWidth: 220
    // Round-3 fix (see file header point 3) — prev/next + play/pause
    // transport cluster sizes, grown from round 2's 32/40px and
    // `spacingXs` gap ("move the media control buttons a bit to the
    // right, and stretch them"). Bigger than round 2, still well inside
    // the unchanged 72px `compactMediaHeight` band with room to spare.
    readonly property int compactTransportSize: 40
    readonly property int compactPlayPauseSize: 56
    readonly property int compactTransportSpacing: root.spacingMd

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
                    id: heroTextColumn
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.spacingXs

                    // Locale-derived long date format — same reasoning,
                    // no hardcoded English month name. Kept as its own
                    // property (rather than inline in a Text.text binding)
                    // so the day-number split logic below reads from one
                    // settled value.
                    readonly property string dateFull: Qt.locale().toString(systemClock.date, Qt.locale().dateFormat(Locale.LongFormat))
                    // Round-3 fix — "the current day number ... should also
                    // be theme colored to make it easier to notice." The
                    // day-of-month number, as plain decimal digits, never
                    // the locale's own possibly-padded rendering of it.
                    readonly property string dayNumberText: String(systemClock.date.getDate())
                    // Locates the day number as a STANDALONE digit token
                    // (word-bounded on both sides) inside the already
                    // locale-formatted string, rather than assuming any
                    // fixed position — every locale's long-date format puts
                    // the day number somewhere different (leading, mid,
                    // trailing), and this never hardcodes which. `-1` (not
                    // found — an exotic locale that never renders the day
                    // as a bare digit run, or a false-negative from the
                    // boundary check) degrades quietly to the whole string
                    // in one colour below, never a mis-highlighted
                    // substring.
                    readonly property int dayNumberIndex: {
                        var re = new RegExp("(^|[^0-9])(" + heroTextColumn.dayNumberText + ")([^0-9]|$)");
                        var m = heroTextColumn.dateFull.match(re);
                        return m ? m.index + m[1].length : -1;
                    }
                    readonly property string datePrefix: heroTextColumn.dayNumberIndex >= 0 ? heroTextColumn.dateFull.substring(0, heroTextColumn.dayNumberIndex) : heroTextColumn.dateFull
                    readonly property string dateSuffix: heroTextColumn.dayNumberIndex >= 0 ? heroTextColumn.dateFull.substring(heroTextColumn.dayNumberIndex + heroTextColumn.dayNumberText.length) : ""

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
                    // Round-3 fix — three runs (prefix / day-number /
                    // suffix) instead of one opaque Text, so only the
                    // day-of-month NUMBER takes the tertiary accent
                    // (matching Friday's own tertiary choice in the
                    // calendar below and Storage's tertiary ring in the
                    // resources strip — one consistent accent this round).
                    Row {
                        id: dateLabel
                        spacing: 0

                        Text {
                            text: heroTextColumn.datePrefix
                            font.pixelSize: root.fontBody
                            font.weight: root.weightBody
                            color: Colours.onSurfaceVariant
                        }
                        Text {
                            visible: heroTextColumn.dayNumberIndex >= 0
                            text: heroTextColumn.dayNumberText
                            font.pixelSize: root.fontBody
                            font.weight: root.weightEmphasis
                            color: Colours.tertiary
                        }
                        Text {
                            text: heroTextColumn.dateSuffix
                            font.pixelSize: root.fontBody
                            font.weight: root.weightBody
                            color: Colours.onSurfaceVariant
                        }
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

                // Round-2 fix (render gate) — the grid's per-cell WIDTH now
                // fills the card's own real width instead of sitting at a
                // fixed `calendarCellSize` centered with large side
                // margins (the human's literal complaint: "lots of empty
                // space to its sides"). Height per row stays
                // `calendarCellSize` unchanged so the D-05 six-row budget
                // Task 1 already fixed is untouched — only the horizontal
                // dimension grows to use the tab's actual width.
                readonly property real cellWidth: (calendarCard.width - root.calendarCardPadding * 2) / 7

                readonly property string monthLabel: calendarCard.localeObj.monthName(calendarCard.viewMonth, Locale.LongFormat) + " " + calendarCard.viewYear

                // Seven short day-name labels, ordered from the locale's
                // own first day of the week — never assumed Monday or
                // Sunday. dayNameIdx converts firstDayOfWeek's 0-6
                // (Sun-based) numbering to dayName's 1-7 (Mon=1..Sun=7).
                // Round-3 fix — each entry also carries `isFriday`: this
                // locale's own weekend day (per the human's direct
                // statement), matched on `dow === 5` — `dow` is the SAME
                // 0=Sunday..6=Saturday ECMA-262 `Date.getDay()` numbering
                // used below for `calendarDays`, so Friday is always index
                // 5 regardless of the locale's own DISPLAY order (never a
                // hardcoded Saturday/Sunday assumption).
                readonly property var weekdayLabels: {
                    var arr = [];
                    for (var i = 0; i < 7; i++) {
                        var dow = (calendarCard.firstDayOfWeek + i) % 7;
                        var dayNameIdx = dow === 0 ? 7 : dow;
                        arr.push({
                            text: calendarCard.localeObj.dayName(dayNameIdx, Locale.ShortFormat),
                            isFriday: dow === 5
                        });
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
                                && cellDate.getDate() === systemClock.date.getDate(),
                            // Round-3 fix — this locale's own weekend day
                            // (Friday, per the human's direct statement),
                            // matched on the actual weekday regardless of
                            // month/leading/trailing status, same `getDay()
                            // === 5` numbering `weekdayLabels` above uses.
                            isFriday: cellDate.getDay() === 5
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

                // ── Weekday header + day grid — filling the card's real
                //    width, inset the same amount as the header row above
                //    (round-2 fix; see file header point 1). ────────────
                Column {
                    // Round-2 fix — left/right-anchored to fill the card's
                    // real width (matching calendarHeaderRow's own inset)
                    // instead of centering at the grid's old fixed natural
                    // width, which is what left the large side margins.
                    anchors.top: calendarHeaderRow.bottom
                    anchors.topMargin: root.spacingXs
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.calendarCardPadding
                    anchors.rightMargin: root.calendarCardPadding
                    spacing: root.spacingXs

                    Row {
                        id: weekdayRow
                        width: parent.width
                        height: root.calendarWeekdayRowHeight

                        Repeater {
                            model: calendarCard.weekdayLabels
                            delegate: Text {
                                width: calendarCard.cellWidth
                                height: weekdayRow.height
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: modelData.text
                                font.pixelSize: root.fontLabel
                                // Round-3 fix — Friday (this locale's own
                                // weekend day) takes the tertiary accent.
                                color: modelData.isFriday ? Colours.tertiary : Colours.onSurfaceVariant
                            }
                        }
                    }

                    Grid {
                        id: dayGrid
                        width: parent.width
                        columns: 7

                        // One inline component — three branches: a day in
                        // the viewed month, a leading/trailing day from an
                        // adjacent month (reduced opacity), and today
                        // (filled primary circle) — the one reserved use of
                        // the accent colour in this card.
                        component DayCell: Item {
                            id: dayCell
                            // Round-2 fix — width now takes the
                            // per-instance `cellWidth` (the card's real
                            // width divided across 7 columns) instead of
                            // the fixed `calendarCellSize`; height stays
                            // `calendarCellSize` so the six-row budget is
                            // unaffected — only the grid's horizontal fill
                            // changes. The today circle below sizes off
                            // `Math.min(width, height)`, so it stays the
                            // same diameter it always was (bounded by the
                            // unchanged height), just repositioned across
                            // a wider cell.
                            property real cellWidth: root.calendarCellSize
                            width: dayCell.cellWidth
                            height: root.calendarCellSize
                            property int dayNumber: 1
                            property bool inMonth: true
                            property bool isToday: false
                            // Round-3 fix — this locale's own weekend day
                            // (Friday). Today's own primary highlight still
                            // wins when the two coincide (see the Text
                            // color branch below) — primary stays the one
                            // reserved accent for "today" per 14-UI-SPEC.md.
                            property bool isFriday: false

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
                                // Round-3 fix — Friday takes the tertiary
                                // accent, but only when today's own primary
                                // highlight does not already claim the cell
                                // (today wins; primary is the one reserved
                                // accent for it per 14-UI-SPEC.md).
                                color: dayCell.isToday ? Colours.onPrimary
                                    : dayCell.isFriday ? Colours.tertiary
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
                                isFriday: modelData.isFriday
                                cellWidth: calendarCard.cellWidth
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

            // ── 3. The compact media widget (D-40, round-2 revised) ──────
            // Reads the ONE shared `mediaBackend` instance's already-
            // derived display fields — no second instance, no process, no
            // MPRIS access, no fallback re-derived here. Art + a title/
            // artist stack + a play/pause + prev/next transport cluster
            // (round-2 addition, see file header point 3); every other
            // part of the widget still deep-links to the Media tab.
            DeepLinkSurface {
                id: compactMedia
                width: parent.width
                height: root.compactMediaHeight
                targetTabIndex: root.mediaTabIndex

                readonly property string mediaState: root.mediaBackend ? root.mediaBackend.widgetState : "empty"
                readonly property bool isPopulated: compactMedia.mediaState === "populated"
                readonly property bool isPending: compactMedia.mediaState === "pending"

                // ── 1. Cover art — circular with a dotted ring (round-2
                //      fix, see file header point 2): the same static
                //      idle-silhouette look MediaTab.qml's own art slot
                //      uses (14-05 rounds 3/4) — a genuine circle with a
                //      static dashed ring drawn via QtQuick.Shapes, and a
                //      QtQuick.Effects MultiEffect alpha mask for a true
                //      circular crop (a plain `clip: true` Rectangle only
                //      clips to its bounding box, never to the rounded
                //      shape — 14-05's own round-4 finding). No
                //      cava/audio-analysis service exists in this repo's
                //      backend, so the ring is deliberately static, same
                //      as the Media tab's own. The quiet placeholder still
                //      shows in all three non-ready cases: loading, empty
                //      art path, and a load failure — one visual, zero
                //      layout shift. ───────────────────────────────────
                Item {
                    id: compactArtSlot
                    anchors.left: parent.left
                    anchors.leftMargin: root.compactMediaPadding
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.compactArtSize
                    height: root.compactArtSize

                    // Static dashed ring — declared first so it paints
                    // behind the art circle (MediaTab.qml's own order).
                    Shape {
                        id: compactArtRing
                        anchors.fill: parent
                        asynchronous: true
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: Colours.outline
                            strokeWidth: root.compactRingStrokeWidth
                            capStyle: ShapePath.RoundCap
                            strokeStyle: ShapePath.DashLine
                            dashPattern: [1, 3]

                            startX: compactArtSlot.width / 2 + root.compactRingRadius
                            startY: compactArtSlot.height / 2

                            PathAngleArc {
                                centerX: compactArtSlot.width / 2
                                centerY: compactArtSlot.height / 2
                                radiusX: root.compactRingRadius
                                radiusY: root.compactRingRadius
                                startAngle: 0
                                sweepAngle: 360
                            }

                            Behavior on strokeColor {
                                enabled: Motion.motionEnabled
                                ColorAnimation {
                                    duration: Motion.standardDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Motion.standardEasing
                                }
                            }
                        }
                    }

                    Item {
                        id: compactArtContainer
                        anchors.centerIn: parent
                        width: root.compactArtCircleSize
                        height: root.compactArtCircleSize

                        Rectangle {
                            id: compactArtBackground
                            anchors.fill: parent
                            radius: width / 2
                            color: Colours.surfaceVariant
                        }

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
                            // Rendered only through the MultiEffect mask
                            // below — painting itself here too would
                            // double-draw an unmasked square underneath
                            // the masked circle (14-05 round-4 precedent).
                            visible: false
                        }

                        // Mask shape for MultiEffect below — never painted
                        // itself; `layer.enabled: true` is load-bearing
                        // (14-05 round-4's own finding: an invisible item
                        // with no layer.enabled produces no paint node at
                        // all, so maskSource would read an empty alpha
                        // texture and the masked image would render
                        // nothing).
                        Rectangle {
                            id: compactArtMaskShape
                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                            layer.enabled: true
                        }

                        MultiEffect {
                            id: compactArtMaskedImage
                            anchors.fill: parent
                            source: compactArtImage
                            maskEnabled: true
                            maskSource: compactArtMaskShape
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            visible: compactArtImage.status === Image.Ready
                        }

                        Text {
                            id: compactArtPlaceholder
                            anchors.centerIn: parent
                            visible: compactArtImage.status !== Image.Ready
                            text: "music_note"
                            font.family: root.symbolFontFamily
                            font.pixelSize: root.compactArtCircleSize * 0.42
                            color: Colours.onSurfaceVariant
                        }
                    }
                }

                // ── 2. Title/artist stack — unchanged from Task 2, still
                //      deliberately bounded to `compactTextWidth`, not the
                //      band's own stretched width, so a genuinely long
                //      title/artist elides rather than never triggering
                //      the compact-width backstop. Both texts are set to
                //      plain text explicitly (T-14-27): third-party player
                //      metadata must never be interpreted as markup. ────
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

                // ── 3. Transport cluster (round-2 built it, round-3
                //      repositioned + enlarged it — see file header point
                //      3): previous / play-pause / next, grouped together.
                //      Round 2 seated this cluster directly after the text
                //      stack; round 3's human feedback ("move the media
                //      control buttons a bit to the right, and stretch
                //      them") asks for the opposite direction — anchored
                //      back to the card's own trailing edge, with every
                //      button grown (see `compactTransportSize`/
                //      `compactPlayPauseSize`/`compactTransportSpacing`
                //      above) so the cluster itself reads as a deliberate,
                //      generously-spaced control group rather than a small
                //      huddle of buttons. `previousTrack()`/`nextTrack()`
                //      are the same two dispatches the Media tab already
                //      exposes — no new backend capability invented here.
                //      Play/pause's glyph is still read from the backend's
                //      playing predicate and never assigned by the press
                //      (D-22): a command that fails or is refused leaves
                //      the button showing what the player is actually
                //      doing. Each button carries its own MouseArea
                //      declared as a later sibling than `compactMedia`'s
                //      own background MouseArea (inside DeepLinkSurface),
                //      so a press is consumed HERE and never reaches the
                //      outer deep-link surface — the same nested-target
                //      rule Task 2 proved on the single play/pause
                //      control. Proven live by pressing each button
                //      repeatedly and confirming the pager never leaves
                //      the Dashboard tab. ─────────────────────────────
                Row {
                    id: compactTransportRow
                    anchors.right: parent.right
                    anchors.rightMargin: root.compactMediaPadding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.compactTransportSpacing

                    Item {
                        id: compactPrevButton
                        width: root.compactTransportSize
                        height: root.compactTransportSize
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Colours.surfaceVariant
                            opacity: compactMedia.isPopulated ? 1 : 0.5

                            Text {
                                anchors.centerIn: parent
                                text: "skip_previous"
                                font.family: root.symbolFontFamily
                                font.pixelSize: root.iconSizeMd - 4
                                color: Colours.onSurfaceVariant
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: compactMedia.isPopulated
                            onClicked: root.mediaBackend.previousTrack()
                        }
                    }

                    Item {
                        id: compactPlayPause
                        width: root.compactPlayPauseSize
                        height: root.compactPlayPauseSize
                        anchors.verticalCenter: parent.verticalCenter

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

                        MouseArea {
                            anchors.fill: parent
                            enabled: compactMedia.isPopulated
                            onClicked: root.mediaBackend.playPause()
                        }
                    }

                    Item {
                        id: compactNextButton
                        width: root.compactTransportSize
                        height: root.compactTransportSize
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Colours.surfaceVariant
                            opacity: compactMedia.isPopulated ? 1 : 0.5

                            Text {
                                anchors.centerIn: parent
                                text: "skip_next"
                                font.family: root.symbolFontFamily
                                font.pixelSize: root.iconSizeMd - 4
                                color: Colours.onSurfaceVariant
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: compactMedia.isPopulated
                            onClicked: root.mediaBackend.nextTrack()
                        }
                    }
                }
            }

            // ── 4. The resources strip (D-39, round-3 revised) ───────────
            // Four mini-dials — CPU, Memory, Storage, Battery — instances
            // of 14-06's own Dial type at a smaller diameter; no arc
            // geometry is written here. Network stays Performance-only.
            // Reads the ONE shared `systemResources` instance's published
            // fractions, per-metric state registers and shared formatters
            // — no second reader, no second poll timer, no metric
            // re-derived here. Storage is a round-3 addition (see file
            // header point 4) — a deliberate reversal of this plan's own
            // "storage and network stay Performance-only" fence, on the
            // human's direct render-gate instruction.
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
                // catch). Round-3 fix — widened further ("space the dials
                // more") from `spacingXl` alone to `spacingXl + spacingMd +
                // spacingSm`; still a tight, centered cluster with
                // generous side margin (the card is far wider than the
                // four-dial cluster even at this spacing), so every
                // caption's overflow stays well inside the clip boundary
                // regardless of which label is longest.
                readonly property int dialSpacing: root.spacingXl + root.spacingMd + root.spacingSm

                // Round-3 bug found live (Rule 1 — auto-fixed): adding a
                // populated Storage detail line right next to Memory's own
                // populated detail line exposed that `Dial.qml`'s own
                // `detailLine` Text (frozen sibling file, not ours to
                // edit) publishes NO width constraint of its own — it just
                // centers at its natural content width under the dial's
                // diameter. At this strip's small `miniDialDiameter`
                // (44px) two full "X.X GiB / Y.Y GiB" strings side by side
                // are each far wider than the per-dial pitch and visibly
                // collide/overlap. Shortens the string from the CALLER
                // side instead (the only side this plan may touch):
                // "<used>/<total> <unit>" when both figures share a unit
                // suffix (the overwhelmingly common case — a
                // used/total pair rarely straddles a GiB/TiB boundary),
                // falling back to the full two-unit form only when they
                // genuinely differ, which is meaningfully narrower than
                // repeating the unit twice with " / " between.
                function formatCompactUsedTotal(usedBytes, totalBytes) {
                    if (!root.systemResources)
                        return "";
                    var usedStr = root.systemResources.formatBytes(usedBytes);
                    var totalStr = root.systemResources.formatBytes(totalBytes);
                    var usedParts = usedStr.split(" ");
                    var totalParts = totalStr.split(" ");
                    if (usedParts.length === 2 && totalParts.length === 2 && usedParts[1] === totalParts[1])
                        return usedParts[0] + "/" + totalParts[0] + " " + totalParts[1];
                    return usedStr + " / " + totalStr;
                }

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
                        // through the shared byte formatter, compacted
                        // (round-3 fix, see `formatCompactUsedTotal` above)
                        // so it doesn't collide with Storage's own detail
                        // line at this strip's small dial pitch.
                        detailText: resourcesStrip.hasResources
                            ? resourcesStrip.formatCompactUsedTotal(root.systemResources.memoryUsedBytes, root.systemResources.memoryTotalBytes)
                            : ""
                        emptySymbol: "help"
                        emptyText: "Unavailable"
                    }
                    // Round-3 addition (file header point 4) — reads the
                    // SAME `systemResources.storageFraction`/
                    // `storageUsedBytes`/`storageTotalBytes`/`storageState`
                    // PerformanceTab.qml's own Storage dial already reads;
                    // icon (`storage`) and accent (`Colours.tertiary`) are
                    // copied verbatim from that dial's own convention (14-06
                    // round 2's primary/secondary/tertiary/error mapping)
                    // so this mini strip reads as the same dial family.
                    Dial {
                        diameter: root.miniDialDiameter
                        ringThickness: root.miniRingThickness
                        label: "Storage"
                        icon: "storage"
                        accentColor: Colours.tertiary
                        widgetState: resourcesStrip.hasResources ? root.systemResources.storageState : "pending"
                        value: resourcesStrip.hasResources ? root.systemResources.storageFraction : 0
                        valueText: resourcesStrip.hasResources ? root.systemResources.formatPercent(root.systemResources.storageFraction) : ""
                        // Compacted the same way Memory's detail line is
                        // (round-3 fix, `formatCompactUsedTotal` above) —
                        // these two are the strip's only dials with a
                        // populated detail line, seated right next to each
                        // other.
                        detailText: resourcesStrip.hasResources
                            ? resourcesStrip.formatCompactUsedTotal(root.systemResources.storageUsedBytes, root.systemResources.storageTotalBytes)
                            : ""
                        emptySymbol: "help"
                        emptyText: "Unavailable"
                    }
                    // The strip's own partial state on this machine — no
                    // battery hardware, so this dial's empty branch is
                    // what actually renders, at the same footprint as the
                    // other three (D-41).
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
