// DashLanes.qml — Dashboard tab layout "lanes" (quick task 260826-rfy,
// plate D2 in `.planning/notes/dashboard-perf-studies.html`).
//
// Selected by `Prefs.getValue("dashboard.layout.dash")`; the switch lives in
// Dashboard.qml's `dashboardTabLoader`. Sibling layout: the original single
// column, still `DashboardTab.qml`, selected as "column".
//
// ── The defect this exists to close ─────────────────────────────────────
// `DashboardTab.qml:288` fixes `contentWidth: 400` while `Design.qml:820`
// floors the drawer at `dashboardMinWidth: 760` — so today's dash renders a
// 400px column with 180px of dead frame on each side, permanently. The frame
// is CORRECT (its floor exists to fit the four-tab header); the content
// simply never grew into it. Two lanes consume the whole 712 of usable
// content width without asking the drawer to be any wider.
//
// ── Width 712, deliberately, and shared with PerfTelemetry ─────────────
// `drawerWidth = max(760, activeContentWidth + spacingLg*2)`, so 712 lands
// exactly on the 760 floor. `PerfTelemetry.qml` declares the same 712 for
// the same reason: with both selected, crossing between Dashboard and
// Performance no longer animates the window 280px wider and back, which was
// the study's second measured finding. Changing one without the other
// reopens it.
//
// ── What is NOT duplicated from DashboardTab.qml ────────────────────────
// The calendar's date arithmetic (locale-driven first-day-of-week, the fixed
// 42-cell six-row grid, the Friday weekend rule) is reproduced here rather
// than shared, because extracting it would mean editing the working column
// layout in the same commit that introduces an unverifiable new one. The
// logic is carried across unchanged — including `firstDayOfWeek`'s 0-6
// Sunday-based numbering versus `dayName`'s 1-7 Monday-based numbering,
// which that file records as confirmed live rather than assumed. If "column"
// is eventually retired, this duplication resolves itself; until then the
// two must be changed together.
//
// D-41 widget-state register carried, as on every composed tab.
import QtQuick
import QtQuick.Effects
import Quickshell
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

    // Deep-link signals, same contract DashboardTab publishes so the Loader
    // in Dashboard.qml binds to either layout unchanged.
    signal tabRequested(int index)
    signal panelRequested(string name)

    readonly property bool hasMedia: root.mediaBackend !== null && root.mediaBackend !== undefined
    readonly property bool hasReader: root.systemResources !== null && root.systemResources !== undefined
    readonly property bool hasWeather: root.weatherBackend !== null && root.weatherBackend !== undefined

    // D-41: the tab is populated when anything real is on it. The clock and
    // calendar are pure date arithmetic with no backend, so this tab can
    // never legitimately be "empty" — it reports the strongest state any of
    // its backed widgets reports, and "populated" otherwise.
    readonly property string widgetState: {
        if (root.hasReader && root.systemResources.widgetState === "populated")
            return "populated";
        if (root.hasMedia && root.mediaBackend.widgetState === "populated")
            return "populated";
        return "populated";
    }

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
    readonly property int cardRadius: Design.popoutCornerRadius

    // See the header — 712 puts the drawer on its 760 floor.
    readonly property int contentWidth: 712
    readonly property int leftLaneWidth: 340
    readonly property int rightLaneWidth: root.contentWidth - root.leftLaneWidth - root.spacingMd

    readonly property int clockHeight: 72
    readonly property int weatherCardHeight: 84
    readonly property int mediaCardHeight: 176
    readonly property int resourcesCardHeight: 88
    readonly property int calendarCellSize: 40
    readonly property int calendarCellGap: 4

    // Height is DERIVED from the right lane, never fixed. `QuickToggles`
    // publishes an `implicitHeight` of `chipsRow + spacingSm + presetRow`
    // (its chip row alone is 72), so a hand-picked constant here silently
    // overlaps the bottom-anchored toggles onto the resources card above
    // them — measured, not hypothetical: the first draft of this file fixed
    // 440 and the toggles would have collided by ~76px.
    //
    // The floor keeps the calendar card from being squeezed below its own
    // fixed six-row grid if the toggles ever shrink.
    readonly property int rightLaneNaturalHeight:
        root.weatherCardHeight + root.mediaCardHeight + root.resourcesCardHeight
        + toggles.implicitHeight + root.spacingMd * 3
    readonly property int contentHeight: Math.max(440, root.rightLaneNaturalHeight)

    implicitWidth: root.contentWidth + root.panelPadding * 2
    implicitHeight: root.contentHeight + root.panelPadding * 2

    // D-21 cascade band list, in reading order: left lane top-to-bottom,
    // then right lane top-to-bottom.
    readonly property var cascadeBands: [clockHero, calendarCard, weatherCard, mediaCard, resourcesCard, toggles]

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
        enabled: root.visible
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: root.panelPadding

        // ══ LEFT LANE — time ══════════════════════════════════════════
        Item {
            id: leftLane
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.leftLaneWidth

            Column {
                id: clockHero
                anchors.left: parent.left
                anchors.top: parent.top
                width: parent.width
                height: root.clockHeight
                spacing: root.spacingXs

                Text {
                    text: Qt.formatDateTime(systemClock.date, "HH:mm")
                    font.pixelSize: root.fontDisplay + root.spacingMd
                    font.weight: root.weightDisplay
                    color: Colours.onSurface
                }

                Text {
                    text: Qt.formatDateTime(systemClock.date, "dddd, d MMMM")
                    font.pixelSize: root.fontBody
                    font.weight: root.weightBody
                    color: Colours.onSurfaceVariant
                }
            }

            Rectangle {
                id: calendarCard
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: clockHero.bottom
                anchors.topMargin: root.spacingMd
                anchors.bottom: parent.bottom
                radius: root.cardRadius
                color: Colours.surfaceVariant

                // ── Date arithmetic, carried across from DashboardTab.qml.
                //    Pure maths: no backend, no state file, no timer.
                property int viewYear: systemClock.date.getFullYear()
                property int viewMonth: systemClock.date.getMonth()

                readonly property var localeObj: Qt.locale()
                // 0-6, Sunday-based — a DIFFERENT convention from
                // Locale.dayName's 1-7 Monday-based numbering used below.
                // Two conventions on the same type; DashboardTab.qml records
                // this as verified live, not assumed.
                readonly property int firstDayOfWeek: calendarCard.localeObj.firstDayOfWeek
                readonly property string monthLabel:
                    calendarCard.localeObj.monthName(calendarCard.viewMonth, Locale.LongFormat)
                    + " " + calendarCard.viewYear

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

                readonly property int leadingCount: {
                    var firstOfMonth = new Date(calendarCard.viewYear, calendarCard.viewMonth, 1);
                    var fw = firstOfMonth.getDay();
                    return (fw - calendarCard.firstDayOfWeek + 7) % 7;
                }

                // Exactly 42 cells (6 rows x 7) every month, so a five-week
                // and a six-week month occupy identical space and nothing
                // below the card ever moves.
                readonly property var calendarDays: {
                    var arr = [];
                    for (var i = 0; i < 42; i++) {
                        var dayOffset = i - calendarCard.leadingCount + 1;
                        var cellDate = new Date(calendarCard.viewYear, calendarCard.viewMonth, dayOffset);
                        arr.push({
                            day: cellDate.getDate(),
                            inMonth: cellDate.getMonth() === calendarCard.viewMonth,
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
                    (calendarCard.width - root.spacingMd * 2 - root.calendarCellGap * 6) / 7

                Column {
                    anchors.fill: parent
                    anchors.margins: root.spacingMd
                    spacing: root.spacingSm

                    Item {
                        width: parent.width
                        height: root.iconSizeMd

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: calendarCard.monthLabel
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
                            model: calendarCard.weekdayLabels
                            delegate: Text {
                                required property var modelData
                                width: calendarCard.cellWidth
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
                            model: calendarCard.calendarDays
                            delegate: Item {
                                id: dayCell
                                required property var modelData
                                width: calendarCard.cellWidth
                                height: root.calendarCellSize

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

                // Declared LAST so it stacks above the cells, and
                // NoButton so it never swallows a click that a future
                // child wants — it exists only to read the wheel.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: (wheel) => {
                        var delta = wheel.angleDelta.y;
                        if (delta === 0)
                            return;
                        var next = new Date(calendarCard.viewYear,
                                            calendarCard.viewMonth + (delta > 0 ? -1 : 1), 1);
                        calendarCard.viewYear = next.getFullYear();
                        calendarCard.viewMonth = next.getMonth();
                    }
                }
            }
        }

        // ══ RIGHT LANE — everything glanceable ════════════════════════
        Item {
            id: rightLane
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.rightLaneWidth

            // ── Weather ────────────────────────────────────────────────
            Rectangle {
                id: weatherCard
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: root.weatherCardHeight
                radius: root.cardRadius
                color: Colours.surfaceVariant

                readonly property var current: root.hasWeather ? root.weatherBackend.current : null

                Row {
                    anchors.fill: parent
                    anchors.margins: root.spacingMd
                    spacing: root.spacingMd

                    ConditionGlyph {
                        anchors.verticalCenter: parent.verticalCenter
                        symbolName: weatherCard.current ? weatherCard.current.symbol : "help"
                        pixelSize: root.fontDisplay
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.spacingXs

                        Text {
                            text: weatherCard.current && root.hasWeather
                                ? root.weatherBackend.formatTemperature(weatherCard.current.temperature)
                                : "—"
                            font.pixelSize: root.fontHeading
                            font.weight: root.weightEmphasis
                            color: Colours.primary
                        }

                        Text {
                            width: rightLane.width - root.spacingMd * 3 - root.fontDisplay
                            elide: Text.ElideRight
                            text: {
                                if (!root.hasWeather)
                                    return "Weather unavailable";
                                if (!weatherCard.current)
                                    return "No reading yet";
                                var city = root.weatherBackend.cityLabel;
                                return weatherCard.current.label + (city ? " · " + city : "");
                            }
                            font.pixelSize: root.fontLabel
                            font.weight: root.weightBody
                            color: Colours.onSurfaceVariant
                        }
                    }
                }
            }

            // ── Media ──────────────────────────────────────────────────
            Rectangle {
                id: mediaCard
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: weatherCard.bottom
                anchors.topMargin: root.spacingMd
                height: root.mediaCardHeight
                radius: root.cardRadius
                color: Colours.surfaceVariant

                readonly property bool populated: root.hasMedia && root.mediaBackend.widgetState === "populated"
                readonly property int artSize: 84

                Column {
                    anchors.centerIn: parent
                    width: parent.width - root.spacingMd * 2
                    spacing: root.spacingSm

                    Item {
                        width: mediaCard.artSize
                        height: mediaCard.artSize
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.10)
                        }

                        Image {
                            id: artImage
                            anchors.fill: parent
                            source: mediaCard.populated && root.hasMedia ? root.mediaBackend.artPath : ""
                            visible: false
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: mediaCard.artSize * 2
                            sourceSize.height: mediaCard.artSize * 2
                            asynchronous: true
                        }

                        // Circular crop, using the exact pattern
                        // DashboardTab.qml's compact art already proves on
                        // this stack: an invisible layered rounded-rect as
                        // the mask, composited by MultiEffect. The mask
                        // Rectangle needs `layer.enabled` — without it the
                        // effect samples an unrendered item and the art
                        // disappears rather than being cropped.
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
                            font.pixelSize: root.iconSizeMd
                            color: Colours.onSurfaceVariant
                        }
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: mediaCard.populated && root.hasMedia ? root.mediaBackend.displayTitle : "Nothing playing"
                        font.pixelSize: root.fontBody
                        font.weight: root.weightBody
                        color: Colours.onSurface
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        visible: text.length > 0
                        text: mediaCard.populated && root.hasMedia ? root.mediaBackend.displayArtist : ""
                        font.pixelSize: root.fontLabel
                        font.weight: root.weightBody
                        color: Colours.onSurfaceVariant
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
                            diameter: root.iconSizeMd + root.spacingMd
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

                // D-39/D-40 deep link: the compact widget opens its own full
                // tab. Declared last so it sits above the transport buttons,
                // and it deliberately accepts only a click on the card
                // BACKGROUND — the transport row's own MouseAreas are
                // children of the Column above and grab first.
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: root.tabRequested(root.mediaTabIndex)
                }
            }

            // ── Resources ──────────────────────────────────────────────
            Rectangle {
                id: resourcesCard
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: mediaCard.bottom
                anchors.topMargin: root.spacingMd
                height: root.resourcesCardHeight
                radius: root.cardRadius
                color: Colours.surfaceVariant

                Row {
                    anchors.centerIn: parent
                    spacing: root.spacingLg

                    MiniResource {
                        label: "CPU"
                        accent: Colours.primary
                        fraction: root.hasReader ? root.systemResources.cpuFraction : 0
                        populated: root.hasReader && root.systemResources.cpuState === "populated"
                    }

                    MiniResource {
                        label: "RAM"
                        accent: Colours.secondary
                        fraction: root.hasReader ? root.systemResources.memoryFraction : 0
                        populated: root.hasReader && root.systemResources.memoryState === "populated"
                    }

                    MiniResource {
                        label: "Disk"
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

    // ── One small resource ring ────────────────────────────────────────
    component MiniResource: Column {
        id: mr
        required property string label
        required property color accent
        required property real fraction
        required property bool populated

        spacing: root.spacingXs

        Dial {
            diameter: root.iconSizeMd + root.spacingLg
            ringThickness: root.spacingXs + 2
            accentColor: mr.accent
            widgetState: mr.populated ? "populated" : "pending"
            value: mr.populated ? mr.fraction : 0
            valueText: mr.populated && root.hasReader
                ? root.systemResources.formatPercent(mr.fraction) : ""
            label: ""
            detailText: ""
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: mr.label
            font.pixelSize: root.fontLabel
            font.weight: root.weightBody
            color: Colours.onSurfaceVariant
        }
    }
}
