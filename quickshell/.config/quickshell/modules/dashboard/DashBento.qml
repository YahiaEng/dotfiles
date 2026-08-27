// DashBento.qml — Dashboard tab layout "bento" (quick task 260827-50i,
// plate D1 "Caelestia Bento" in `.planning/notes/dashboard-perf-studies.html`).
//
// Selected by `Prefs.getValue("dashboard.layout.dash")`; the switch lives in
// Dashboard.qml's `dashboardTabLoader`, so this file knows nothing about being
// one of three layouts. Siblings: `DashboardTab.qml` ("column", the original
// single column) and `DashLanes.qml` ("lanes", the current default).
//
// ── What this layout is FOR ─────────────────────────────────────────────
// The reference's own grid, ported: weather and identity across the top, a
// stacked clock / calendar / resource rail beneath, media spanning the full
// height down the right.
//
// ── The trick, and why Design.qml grew a rounding scale for it ──────────
// Every cell here is painted the SAME fill. The only thing stopping six
// identical rectangles from reading as a spreadsheet is that each carries a
// visibly different corner radius — 18 for the narrow rails, 28 for calendar
// and identity, 42 for weather, 56 for media.
//
// That is doing work colour would normally do. The reference separates these
// cells with `m3surfaceContainer`, a role sitting between surface and
// surfaceVariant — and this shell's theme pipeline does not generate one
// (confirmed absent from `Colours.qml`, which publishes surface and
// surfaceVariant and nothing between). Adding one would mean touching every
// template in the theme pipeline, so this direction leans entirely on radius
// and gap instead. That is the study's own stated fallback for this plate,
// not an improvisation here.
//
// ── Frame width: WIDE family, 944 of content, drawer lands at 1040 ──────
// `drawerWidth = max(760, activeContentWidth + spacingLg*2)` and
// `activeContentWidth` IS this tab's `implicitWidth`, which already includes
// this tab's own `panelPadding * 2` — so 944 resolves to 1040.
//
// This is deliberately NOT the 712 the other three layouts declare. The study
// designs two width families and says so in this plate's own spec note: "It
// settles at 1040 — which fixes the frame jump only if Performance also lands
// at 1040 (P1 does; P2/P3/P4 don't). These two tabs have to be chosen
// together."
//
// So: this file and `PerfCards.qml` are the WIDE family and share 944;
// `DashLanes`, `PerfTelemetry` and `PerfArcs` are the NARROW family and share
// 712. Picking within a family does not animate the drawer's width. Picking
// across them does, which is a property of the plates rather than a defect
// introduced here. Compressing this plate to 712 was considered and rejected:
// the media column alone is 236, which would leave 460 for a row that has to
// carry a 250px weather cell plus an identity cell with a 92px avatar and
// three lines of text.
//
// ── One measured divergence from the plate: where the toggles go ────────
// The study folds the quick toggles into the media column's foot, drawn there
// as three generic 38px tiles. This shell's `QuickToggles` is not three tiles
// — it is a six-chip row (`chipModel` has six entries) that divides its own
// width evenly, each chip 72px tall with a glyph, a label and in three cases a
// chevron. In a 236px media column that is ~27px per chip.
//
// So the toggles run across the FOOT OF THE LEFT STACK instead, at the full
// 692, which is more room than the shipped "lanes" layout gives them (356),
// not less. The media cell then spans all three left-stack rows rather than
// two. Everything else about the grid is the plate as drawn.
//
// D-41 widget-state register carried, as on every composed tab.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root

    anchors.fill: parent

    // ── Passed-in backends. Every one is `var` and null-guarded: this item
    //    is built by a Loader and there is a window before the assignments
    //    land. Fully-qualified `root.` is used at every mount site below —
    //    QuickToggles declares identically named properties and a bare RHS
    //    would resolve to ITS own unassigned copy under innermost-scope-wins
    //    lookup, which is the shadowing bug Dashboard.qml's header records.
    property var mediaBackend: null
    property var systemResources: null
    property var weatherBackend: null
    property var audioBackend: null
    property var wifiBackend: null
    property var bluetoothBackend: null
    property int mediaTabIndex: -1
    property int performanceTabIndex: -1

    // Deep-link signals, same contract DashboardTab and DashLanes publish so
    // the Loader in Dashboard.qml binds to any layout unchanged.
    signal tabRequested(int index)
    signal panelRequested(string name)

    readonly property bool hasMedia: root.mediaBackend !== null && root.mediaBackend !== undefined
    readonly property bool hasReader: root.systemResources !== null && root.systemResources !== undefined
    readonly property bool hasWeather: root.weatherBackend !== null && root.weatherBackend !== undefined

    // D-41: the clock and calendar are pure date arithmetic with no backend,
    // so this tab can never legitimately be "empty" — same reasoning, and the
    // same verdict, as DashLanes.
    readonly property string widgetState: "populated"

    // ── Design constants ────────────────────────────────────────────────
    readonly property int panelPadding: Design.panelPadding
    readonly property int spacingXs: Design.spacingXs
    readonly property int spacingSm: Design.spacingSm
    readonly property int spacingMd: Design.spacingMd
    readonly property int spacingLg: Design.spacingLg
    readonly property int fontDisplay: Design.fontDisplay
    readonly property int fontHeading: Design.fontHeading
    readonly property int fontBody: Design.fontBody
    readonly property int fontLabel: Design.fontLabel
    readonly property int weightBody: Design.weightBody
    readonly property int weightEmphasis: Design.weightEmphasis
    readonly property int weightDisplay: Design.weightDisplay
    readonly property int iconSizeMd: Design.iconSizeMd
    readonly property string symbolFontFamily: Design.symbolFontFamily

    // The four radii the plate is built on — the whole separation trick.
    readonly property int radiusRail: Design.roundingSm      // 18
    readonly property int radiusPanel: Design.roundingMd     // 28
    readonly property int radiusWeather: Design.roundingLg   // 42
    readonly property int radiusMedia: Design.roundingXl     // 56

    // See the header — WIDE family.
    readonly property int contentWidth: 944
    readonly property int mediaCellWidth: 236
    readonly property int leftStackWidth: root.contentWidth - root.mediaCellWidth - root.spacingMd

    // Row 0 cells.
    readonly property int weatherCellWidth: 250
    readonly property int avatarSize: 92
    readonly property int topRowHeight: root.avatarSize + root.spacingLg * 2

    // Row 1 cells.
    readonly property int clockCellWidth: 104
    readonly property int railCellWidth: 82
    readonly property int calendarCellWidth: root.leftStackWidth - root.clockCellWidth
        - root.railCellWidth - root.spacingMd * 2

    // A smaller day cell than "lanes" uses (40): this calendar is far wider
    // than that one, so square-ish cells would make the card taller than the
    // rest of the grid needs it to be, and the plate's row heights are what
    // hold the composition together.
    readonly property int calendarDayHeight: 32
    readonly property int calendarCellGap: 4

    readonly property int artSize: 170

    // Every height below is DERIVED, never hand-picked. 260826-rfy shipped
    // fixed 176/88 heights that clipped a play button and overflowed a ring
    // column by 9px — measured on a live capture, not estimated.
    readonly property int middleRowHeight: Math.max(calendarColumn.implicitHeight + root.spacingMd * 2,
                                                    railColumn.implicitHeight + root.spacingMd * 2)
    readonly property int contentHeight: root.topRowHeight + root.spacingMd
        + root.middleRowHeight + root.spacingMd + toggles.implicitHeight

    implicitWidth: root.contentWidth + root.panelPadding * 2
    implicitHeight: root.contentHeight + root.panelPadding * 2

    // D-21 cascade band list, in reading order: top row left-to-right, then
    // the middle row, then the toggles, then the media column beside them.
    readonly property var cascadeBands: [weatherCell, identityCell, clockCell, calendarCell, railCell, toggles, mediaCell]

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    // ── Current theme, for the identity cell's third line ───────────────
    // AppearancePage.qml:66-72's pattern verbatim (itself Probe.qml's
    // `.text()` pattern): the state file the theme pipeline actually owns,
    // under `~/.local/state/theme/`, NEVER `~/.cache/current-theme` — that
    // one is a plausible-looking orphan that will happily return a stale
    // name for ever.
    FileView {
        id: currentThemeFile
        path: Quickshell.env("HOME") + "/.local/state/theme/current-theme"
        watchChanges: true
        onFileChanged: reload()
        // A machine that has never run a theme switch has no such file, and
        // the identity line simply says "Hyprland". Not worth a log line.
        printErrors: false
    }
    readonly property string currentThemeName: (currentThemeFile.text() || "").trim()

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: root.panelPadding

        // ══ LEFT STACK — three rows ═══════════════════════════════════
        Item {
            id: leftStack
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.leftStackWidth

            // ── Weather, the largest non-media radius ──────────────────
            Rectangle {
                id: weatherCell
                anchors.left: parent.left
                anchors.top: parent.top
                width: root.weatherCellWidth
                height: root.topRowHeight
                radius: root.radiusWeather
                color: Colours.surfaceVariant

                readonly property var current: root.hasWeather ? root.weatherBackend.current : null

                Row {
                    anchors.centerIn: parent
                    width: parent.width - root.spacingLg * 2
                    spacing: root.spacingMd

                    // Every colour property on ConditionGlyph defaults to
                    // "transparent", so a call site that sets only
                    // `symbolName`/`pixelSize` renders an INVISIBLE glyph.
                    // These four bindings are WeatherTab.qml's own, reused
                    // verbatim rather than re-derived — the same mistake was
                    // shipped once on the "lanes" weather card and had to be
                    // fixed on 2026-08-27.
                    ConditionGlyph {
                        anchors.verticalCenter: parent.verticalCenter
                        symbolName: weatherCell.current ? weatherCell.current.symbol : "help"
                        pixelSize: root.fontDisplay + root.spacingMd
                        baseFillAxis: 1
                        singleToneColor: weatherCell.current
                            ? (WeatherPalette.forSymbol(weatherCell.current.symbol) || Colours.primary)
                            : Colours.primary
                        sunColor: WeatherPalette.sun
                        moonColor: WeatherPalette.night
                        cloudColor: WeatherPalette.cloudLit
                        conditionLabel: weatherCell.current ? weatherCell.current.label : ""
                        tooltipDelay: Design.tooltipDelayMs
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.spacingXs

                        Text {
                            text: weatherCell.current && root.hasWeather
                                ? root.weatherBackend.formatTemperature(weatherCell.current.temperature)
                                : "—"
                            font.pixelSize: root.fontDisplay
                            font.weight: root.weightDisplay
                            color: Colours.primary
                        }

                        Text {
                            width: root.weatherCellWidth - root.spacingLg * 2
                                - root.spacingMd - root.fontDisplay - root.spacingMd
                            elide: Text.ElideRight
                            text: {
                                if (!root.hasWeather)
                                    return "Weather unavailable";
                                if (!weatherCell.current)
                                    return "No reading yet";
                                return weatherCell.current.label;
                            }
                            font.pixelSize: root.fontLabel
                            font.weight: root.weightBody
                            color: Colours.onSurfaceVariant
                        }
                    }
                }
            }

            // ── Identity ───────────────────────────────────────────────
            Rectangle {
                id: identityCell
                anchors.left: weatherCell.right
                anchors.leftMargin: root.spacingMd
                anchors.right: parent.right
                anchors.top: parent.top
                height: root.topRowHeight
                radius: root.radiusPanel
                color: Colours.surfaceVariant

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: root.spacingLg
                    spacing: root.spacingLg

                    // ~/.face is the reference's own convention for a user
                    // avatar, and there is no guarantee the file exists —
                    // this host may well not have one. A missing image is
                    // the DESIGNED state, not a failure: the circle keeps
                    // its footprint and shows a person glyph, so the row
                    // beside it never shifts.
                    Item {
                        width: root.avatarSize
                        height: root.avatarSize

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.10)
                        }

                        Image {
                            id: faceImage
                            anchors.fill: parent
                            source: Quickshell.env("HOME") + "/.face"
                            visible: false
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: root.avatarSize * 2
                            sourceSize.height: root.avatarSize * 2
                            asynchronous: true
                        }

                        // Circular crop, using the exact pattern DashLanes'
                        // media art proves on this stack: an invisible
                        // LAYERED rounded rect as the mask, composited by
                        // MultiEffect. The mask Rectangle needs
                        // `layer.enabled` — without it the effect samples an
                        // unrendered item and the image disappears entirely
                        // rather than being cropped.
                        Rectangle {
                            id: faceMask
                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                            layer.enabled: true
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: faceImage
                            maskEnabled: true
                            maskSource: faceMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            visible: faceImage.status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: faceImage.status !== Image.Ready
                            text: "person"
                            font.family: root.symbolFontFamily
                            font.pixelSize: root.fontDisplay
                            color: Colours.onSurfaceVariant
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.spacingXs

                        Text {
                            text: Quickshell.env("USER") || "user"
                            font.pixelSize: root.fontHeading
                            font.weight: root.weightBody
                            color: Colours.onSurface
                        }

                        // "up 4h 12m · Arch Linux". Both halves are new in
                        // this task and both fail quiet — an unreadable
                        // /proc/uptime or /etc/os-release leaves an empty
                        // string and this line composes around it rather
                        // than printing a placeholder.
                        Text {
                            text: {
                                if (!root.hasReader)
                                    return "";
                                var parts = [];
                                if (root.systemResources.uptimeText !== "")
                                    parts.push("up " + root.systemResources.uptimeText);
                                if (root.systemResources.distroName !== "")
                                    parts.push(root.systemResources.distroName);
                                return parts.join(" · ");
                            }
                            visible: text.length > 0
                            font.pixelSize: root.fontLabel
                            font.weight: root.weightBody
                            color: Colours.onSurfaceVariant
                        }

                        // The compositor and the live theme. Both are facts
                        // this shell already knows without asking anything:
                        // it IS the Hyprland session, and the theme name is
                        // the one the theme pipeline last wrote.
                        Text {
                            text: "Hyprland" + (root.currentThemeName !== "" ? " · " + root.currentThemeName : "")
                            font.pixelSize: root.fontLabel
                            font.weight: root.weightBody
                            color: Colours.onSurfaceVariant
                        }
                    }
                }
            }

            // ── Clock, stacked HH / ••• / MM ───────────────────────────
            Rectangle {
                id: clockCell
                anchors.left: parent.left
                anchors.top: weatherCell.bottom
                anchors.topMargin: root.spacingMd
                width: root.clockCellWidth
                height: root.middleRowHeight
                radius: root.radiusRail
                color: Colours.surfaceVariant

                Column {
                    anchors.centerIn: parent
                    spacing: 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(systemClock.date, "HH")
                        font.pixelSize: root.fontDisplay + root.spacingSm
                        font.weight: root.weightDisplay
                        color: Colours.secondary
                        lineHeight: 1.0
                    }

                    // The reference's separator: three dots where a colon
                    // would be, stacked rather than beside, which is what
                    // lets the digits be this large in a 104px rail.
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "•••"
                        font.pixelSize: root.fontHeading
                        font.weight: root.weightBody
                        color: Colours.primary
                        lineHeight: 1.1
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(systemClock.date, "mm")
                        font.pixelSize: root.fontDisplay + root.spacingSm
                        font.weight: root.weightDisplay
                        color: Colours.secondary
                        lineHeight: 1.0
                    }
                }
            }

            // ── Calendar ───────────────────────────────────────────────
            Rectangle {
                id: calendarCell
                anchors.left: clockCell.right
                anchors.leftMargin: root.spacingMd
                anchors.top: weatherCell.bottom
                anchors.topMargin: root.spacingMd
                width: root.calendarCellWidth
                height: root.middleRowHeight
                radius: root.radiusPanel
                color: Colours.surfaceVariant

                // ── Date arithmetic, carried across from DashLanes.qml
                //    unchanged. Pure maths: no backend, no state file, no
                //    timer.
                property int viewYear: systemClock.date.getFullYear()
                property int viewMonth: systemClock.date.getMonth()

                readonly property var localeObj: Qt.locale()
                // 0-6, Sunday-based — a DIFFERENT convention from
                // Locale.dayName's 1-7 Monday-based numbering used below.
                // Two conventions on the same type; verified live, not
                // assumed.
                readonly property int firstDayOfWeek: calendarCell.localeObj.firstDayOfWeek
                readonly property string monthLabel:
                    calendarCell.localeObj.monthName(calendarCell.viewMonth, Locale.LongFormat)
                    + " " + calendarCell.viewYear

                readonly property var weekdayLabels: {
                    var arr = [];
                    for (var i = 0; i < 7; i++) {
                        var dow = (calendarCell.firstDayOfWeek + i) % 7;
                        var dayNameIdx = dow === 0 ? 7 : dow;
                        arr.push({
                            text: calendarCell.localeObj.dayName(dayNameIdx, Locale.ShortFormat),
                            isFriday: dow === 5
                        });
                    }
                    return arr;
                }

                readonly property int leadingCount: {
                    var firstOfMonth = new Date(calendarCell.viewYear, calendarCell.viewMonth, 1);
                    var fw = firstOfMonth.getDay();
                    return (fw - calendarCell.firstDayOfWeek + 7) % 7;
                }

                // Exactly 42 cells (6 rows x 7) every month, so a five-week
                // and a six-week month occupy identical space and nothing
                // below the card ever moves.
                readonly property var calendarDays: {
                    var arr = [];
                    for (var i = 0; i < 42; i++) {
                        var dayOffset = i - calendarCell.leadingCount + 1;
                        var cellDate = new Date(calendarCell.viewYear, calendarCell.viewMonth, dayOffset);
                        arr.push({
                            day: cellDate.getDate(),
                            inMonth: cellDate.getMonth() === calendarCell.viewMonth,
                            isToday: cellDate.getFullYear() === systemClock.date.getFullYear()
                                && cellDate.getMonth() === systemClock.date.getMonth()
                                && cellDate.getDate() === systemClock.date.getDate(),
                            // This locale's weekend day, matched on the real
                            // weekday regardless of leading/trailing status.
                            isFriday: cellDate.getDay() === 5
                        });
                    }
                    return arr;
                }

                readonly property real cellWidth:
                    (calendarCell.width - root.spacingMd * 2 - root.calendarCellGap * 6) / 7

                Column {
                    id: calendarColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: root.spacingMd
                    anchors.rightMargin: root.spacingMd
                    spacing: root.spacingSm

                    Item {
                        width: parent.width
                        height: root.iconSizeMd

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: calendarCell.monthLabel
                            font.pixelSize: root.fontBody
                            font.weight: root.weightBody
                            color: Colours.onSurface
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "scroll to change month"
                            font.pixelSize: root.fontLabel
                            font.weight: root.weightBody
                            color: Colours.outline
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: root.calendarCellGap

                        Repeater {
                            model: calendarCell.weekdayLabels
                            delegate: Text {
                                required property var modelData
                                width: calendarCell.cellWidth
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.text
                                font.pixelSize: root.fontLabel
                                font.weight: root.weightBody
                                color: modelData.isFriday ? Colours.primary : Colours.outline
                            }
                        }
                    }

                    Grid {
                        columns: 7
                        rowSpacing: root.calendarCellGap
                        columnSpacing: root.calendarCellGap

                        Repeater {
                            model: calendarCell.calendarDays
                            delegate: Item {
                                id: dayCell
                                required property var modelData
                                width: calendarCell.cellWidth
                                height: root.calendarDayHeight

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: Math.min(parent.width, parent.height)
                                    height: width
                                    radius: width / 2
                                    visible: dayCell.modelData.isToday
                                    color: Colours.primary
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: dayCell.modelData.day
                                    font.pixelSize: root.fontLabel + 2
                                    font.weight: dayCell.modelData.isToday ? root.weightEmphasis : root.weightBody
                                    color: {
                                        if (dayCell.modelData.isToday)
                                            return Colours.onPrimary;
                                        if (!dayCell.modelData.inMonth)
                                            return Colours.outline;
                                        if (dayCell.modelData.isFriday)
                                            return Colours.primary;
                                        return Colours.onSurface;
                                    }
                                }
                            }
                        }
                    }
                }

                // Declared LAST so it stacks above the cells, and NoButton so
                // it never swallows a click a future child wants — it exists
                // only to read the wheel.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: (wheel) => {
                        var delta = wheel.angleDelta.y;
                        if (delta === 0)
                            return;
                        var next = new Date(calendarCell.viewYear,
                                            calendarCell.viewMonth + (delta > 0 ? -1 : 1), 1);
                        calendarCell.viewYear = next.getFullYear();
                        calendarCell.viewMonth = next.getMonth();
                    }
                }
            }

            // ── Resource rail ──────────────────────────────────────────
            Rectangle {
                id: railCell
                anchors.right: parent.right
                anchors.top: weatherCell.bottom
                anchors.topMargin: root.spacingMd
                width: root.railCellWidth
                height: root.middleRowHeight
                radius: root.radiusRail
                color: Colours.surfaceVariant

                Column {
                    id: railColumn
                    anchors.centerIn: parent
                    spacing: root.spacingMd

                    MiniResource {
                        accent: Colours.primary
                        fraction: root.hasReader ? root.systemResources.cpuFraction : 0
                        populated: root.hasReader && root.systemResources.cpuState === "populated"
                    }

                    MiniResource {
                        accent: Colours.secondary
                        fraction: root.hasReader ? root.systemResources.memoryFraction : 0
                        populated: root.hasReader && root.systemResources.memoryState === "populated"
                    }

                    MiniResource {
                        accent: Colours.tertiary
                        fraction: root.hasReader ? root.systemResources.storageFraction : 0
                        populated: root.hasReader && root.systemResources.storageState === "populated"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: root.tabRequested(root.performanceTabIndex)
                }
            }

            // ── Quick toggles, across the stack's foot ─────────────────
            // See the header for why these are here rather than in the media
            // column the plate draws them in.
            QuickToggles {
                id: toggles
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                audioBackend: root.audioBackend
                wifiBackend: root.wifiBackend
                bluetoothBackend: root.bluetoothBackend
                onPanelRequested: (name) => root.panelRequested(name)
                height: implicitHeight
            }
        }

        // ══ MEDIA — the largest radius, spanning the full height ═══════
        Rectangle {
            id: mediaCell
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.mediaCellWidth
            radius: root.radiusMedia
            color: Colours.surfaceVariant

            readonly property bool populated: root.hasMedia && root.mediaBackend.widgetState === "populated"

            Column {
                id: mediaColumn
                anchors.centerIn: parent
                width: parent.width - root.spacingLg * 2
                spacing: root.spacingSm

                Item {
                    width: root.artSize
                    height: root.artSize
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.10)
                    }

                    Image {
                        id: artImage
                        anchors.fill: parent
                        source: mediaCell.populated && root.hasMedia ? root.mediaBackend.artPath : ""
                        visible: false
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: root.artSize * 2
                        sourceSize.height: root.artSize * 2
                        asynchronous: true
                    }

                    // Same layered-mask + MultiEffect pattern as the avatar
                    // above and as DashLanes' own art — `layer.enabled` on
                    // the mask is load-bearing.
                    Rectangle {
                        id: artMask
                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                        layer.enabled: true
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: artImage
                        maskEnabled: true
                        maskSource: artMask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                        visible: artImage.status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: artImage.status !== Image.Ready
                        text: "music_note"
                        font.family: root.symbolFontFamily
                        font.pixelSize: root.fontDisplay
                        color: Colours.onSurfaceVariant
                    }
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: mediaCell.populated && root.hasMedia ? root.mediaBackend.displayTitle : "Nothing playing"
                    font.pixelSize: root.fontBody
                    font.weight: root.weightBody
                    color: Colours.onSurface
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    visible: text.length > 0
                    text: mediaCell.populated && root.hasMedia ? root.mediaBackend.displayArtist : ""
                    font.pixelSize: root.fontLabel
                    font.weight: root.weightBody
                    color: Colours.onSurfaceVariant
                }

                // Progress. Track is alpha over onSurface, NOT surfaceVariant
                // — this cell's own fill already IS surfaceVariant, and a
                // track drawn in a role identical to its backing surface
                // renders invisible. Proven live in 14-10 and hit twice more
                // since.
                Rectangle {
                    width: parent.width
                    height: root.spacingSm
                    radius: height / 2
                    color: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.14)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, mediaCell.positionFraction))
                        height: parent.height
                        radius: parent.radius
                        color: Colours.primary

                        Behavior on width {
                            NumberAnimation {
                                duration: Motion.standardDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.standardEasing
                            }
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.spacingMd

                    TransportButton {
                        glyph: "skip_previous"
                        diameter: root.iconSizeMd + root.spacingSm
                        onActivated: {
                            if (root.hasMedia)
                                root.mediaBackend.previousTrack();
                        }
                    }

                    TransportButton {
                        glyph: (root.hasMedia && root.mediaBackend.playing) ? "pause" : "play_arrow"
                        diameter: root.iconSizeMd + root.spacingLg
                        filled: true
                        onActivated: {
                            if (root.hasMedia)
                                root.mediaBackend.playPause();
                        }
                    }

                    TransportButton {
                        glyph: "skip_next"
                        diameter: root.iconSizeMd + root.spacingSm
                        onActivated: {
                            if (root.hasMedia)
                                root.mediaBackend.nextTrack();
                        }
                    }
                }
            }

            // Guarded division, not a bare ratio: a player reporting a zero
            // or absent length would otherwise produce NaN, and a NaN width
            // silently collapses the fill to nothing with no error.
            //
            // The properties are `positionSeconds`/`lengthSeconds` — checked
            // against MediaBackend.qml:444 and :520, not assumed from the
            // shorter names an MPRIS reader might plausibly have used.
            readonly property real positionFraction: {
                if (!mediaCell.populated || !root.hasMedia)
                    return 0;
                var len = root.mediaBackend.lengthSeconds;
                if (!(len > 0))
                    return 0;
                return root.mediaBackend.positionSeconds / len;
            }

            // D-39/D-40 deep link: the compact widget opens its own full tab.
            // Declared last so it sits above the transport buttons, and it
            // deliberately accepts only a click on the cell BACKGROUND — the
            // transport row's own MouseAreas are children of the Column above
            // and grab first.
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: root.tabRequested(root.mediaTabIndex)
            }
        }
    }

    // ── One transport control ──────────────────────────────────────────
    component TransportButton: Item {
        id: tb
        required property string glyph
        property int diameter: 32
        property bool filled: false
        signal activated

        width: tb.diameter
        height: tb.diameter

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: tb.filled
                ? Colours.primary
                : Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.10)
        }

        Text {
            anchors.centerIn: parent
            text: tb.glyph
            font.family: root.symbolFontFamily
            font.pixelSize: tb.diameter * 0.55
            color: tb.filled ? Colours.onPrimary : Colours.onSurface
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tb.activated()
        }
    }

    // ── One rail ring ──────────────────────────────────────────────────
    // No caption: the rail is 82px wide and the plate labels these by colour
    // and order, not by text. `collapseEmptyLines` is what makes that free —
    // without it Dial reserves its caption line whether or not it has text,
    // which is the 18px that overflowed a card during 260826-rfy.
    component MiniResource: Dial {
        id: mr
        required property bool populated

        diameter: root.iconSizeMd + root.spacingLg
        ringThickness: root.spacingXs + 2
        collapseEmptyLines: true
        centerFontSize: root.fontLabel
        label: ""
        icon: ""
        detailText: ""
        // This dial sits ON a `surfaceVariant` cell, so Dial's default track
        // (also surfaceVariant) is invisible — measured, not assumed.
        trackColor: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.14)
        widgetState: mr.populated ? "populated" : "pending"
        value: mr.populated ? mr.fraction : 0
        valueText: mr.populated && root.hasReader
            ? Math.round(mr.fraction * 100) + "" : ""

        property real fraction: 0
        property color accent: Colours.primary
        accentColor: mr.accent
    }
}
