// WeatherTab.qml — tab 3 shell (Phase 14 Plan 03, filled by Plan 14-07,
// D-37: current-conditions hero + fixed 8-column hour strip (NOT
// scrollable, D-05) + 5-day row).
//
// Root type Item, filled via anchors.fill: parent by the Loader Dashboard.qml
// places it in — actual rendered geometry is UNCHANGED from Task 2 (still
// anchors.fill: parent, always matching whatever size its Loader currently
// has, including mid-resize-animation).
//
// `implicitWidth`/`implicitHeight` below are D-04's "no implicit size"
// prohibition DELIBERATELY REVERSED at this plan's render gate (checkpoint
// feedback 2026-07-29, see 14-03-SUMMARY.md's Deviations): Dashboard.qml
// reads these as an advisory hint to compute the drawer's own animated frame
// target — a pure metadata read, independent of this item's actual rendered
// size above. They are now derived from a natural, non-circular measurement
// (TextMetrics on worst-case hour/day cell content, PerformanceTab.qml's
// established technique) rather than from this item's own current width —
// binding implicitWidth to something that itself depends on the frame width
// Dashboard.qml derives FROM implicitWidth is exactly the self-referential
// loop PerformanceTab's round 2/3 render-gate fixes already found and closed
// once; this file avoids reintroducing it by construction.
//
// ── Design constants — NOT read off `dashboardWindow` ───────────────────
// Same mechanism gap MediaTab.qml/PerformanceTab.qml/Dial.qml all record: a
// QML `id` is lexically scoped to its declaring file, and `WeatherTab` is a
// separate registered component instantiated inside `dashboardWindow`'s
// object tree (via Dashboard.qml's `weatherTabLoader`), not textually
// nested inside it — so a bare `dashboardWindow.spacingLg`-style reference
// would not resolve. This file declares its own copies, sourced from
// 14-UI-SPEC.md's tables; consolidating every tab onto one shared constants
// surface is 14-08's job (consolidation note recorded again in
// 14-07-SUMMARY.md).
//
// D-41 widget-state register — "populated" / "pending" / "empty" — carried
// on every one of this phase's nine modules/dashboard/ files.
//
// Property contract: `weatherBackend` is typed `var` rather than a concrete
// type so this stub compiles before 14-07's WeatherBackend has any real
// surface; every read below is guarded against this being null/undefined —
// the tab is instantiated by a lazy Loader and there is a moment before the
// property arrives where an unguarded read would be a type error in the
// log and a blank pane on screen. A null/undefined backend renders the same
// placeholder the never-cached case does (D-41).
import QtQuick
import "../"

Item {
    id: root

    anchors.fill: parent

    // ── Local design constants (see header note above) ──────────────────
    readonly property int spacingXs: Design.spacingXs
    readonly property int spacingSm: Design.spacingSm
    readonly property int spacingMd: Design.spacingMd
    readonly property int spacingLg: Design.spacingLg
    readonly property int fontDisplay: Design.fontDisplay
    readonly property int fontHeading: Design.fontHeading
    readonly property int fontBody: Design.fontBody
    readonly property int fontLabel: Design.fontLabel
    readonly property int weightDisplay: Design.weightDisplay
    readonly property int weightEmphasis: Design.weightEmphasis
    readonly property int weightBody: Design.weightBody
    readonly property int iconSizeMd: Design.iconSizeMd
    readonly property int heroSymbolSize: 56
    readonly property int cellSymbolSize: 24
    readonly property string symbolFontFamily: Design.symbolFontFamily

    property var weatherBackend: null
    readonly property bool hasBackend: root.weatherBackend !== null && root.weatherBackend !== undefined

    // D-41: "populated" | "pending" | "empty" — mirrors the backend's own
    // aggregate self-report, same convention PerformanceTab.qml's
    // `hasReader`/`widgetState` pairing already established.
    property string widgetState: root.hasBackend ? root.weatherBackend.widgetState : "empty"

    // The never-cached / invalid-coordinates / null-backend placeholder
    // renders whenever there is no payload to show at all — this tab's
    // degraded state is "no data", never a per-slot empty (unlike Media's
    // per-widget D-41 pattern), so the whole three-band composition swaps
    // for one placeholder rather than any single band going empty on its
    // own (D-33/D-41).
    readonly property bool showPlaceholder: !root.hasBackend || !root.weatherBackend.hasPayload

    // ── D-21's cascade band list (Phase 14 Plan 09) — D-37 read order:
    //    current hero, hour strip, day row.
    readonly property var cascadeBands: [heroBand, hourStrip, dayRow]

    readonly property int hourColumns: root.hasBackend ? root.weatherBackend.hourColumns : 8
    readonly property int dayCells: 5

    // ── Natural (non-circular) size estimate feeding implicitWidth/Height
    //    — measured via TextMetrics off worst-case strings, exactly like
    //    PerformanceTab.qml's `rateCellWidth`/`worstCaseRateText` pattern,
    //    so this file's advisory size is never derived from `root.width`/
    //    `root.height` (which Dashboard.qml itself derives FROM it). ──────
    readonly property string worstCaseHourText: "12 AM"
    readonly property string worstCaseHourTemp: "-99°"
    readonly property string worstCaseDayLabel: "Wed"
    readonly property string worstCaseDayRange: "-99° / -99°"

    TextMetrics {
        id: hourLabelMetrics
        font.pixelSize: root.fontLabel
        font.weight: root.weightBody
        text: root.worstCaseHourText
    }
    TextMetrics {
        id: hourTempMetrics
        font.pixelSize: root.fontBody
        font.weight: root.weightBody
        text: root.worstCaseHourTemp
    }
    TextMetrics {
        id: dayLabelMetrics
        font.pixelSize: root.fontBody
        font.weight: root.weightEmphasis
        text: root.worstCaseDayLabel
    }
    TextMetrics {
        id: dayRangeMetrics
        font.pixelSize: root.fontLabel
        font.weight: root.weightBody
        text: root.worstCaseDayRange
    }

    readonly property real naturalHourCellWidth: Math.max(hourLabelMetrics.advanceWidth, hourTempMetrics.advanceWidth, root.cellSymbolSize) + root.spacingXs * 2
    readonly property real naturalDayCellWidth: Math.max(dayLabelMetrics.advanceWidth, dayRangeMetrics.advanceWidth, root.cellSymbolSize) + root.spacingXs * 2
    readonly property real naturalHourStripWidth: root.hourColumns * root.naturalHourCellWidth
    readonly property real naturalDayRowWidth: root.dayCells * root.naturalDayCellWidth + (root.dayCells - 1) * root.spacingXs
    readonly property real naturalHeroWidth: 420

    implicitWidth: Math.max(root.naturalHeroWidth, root.naturalHourStripWidth, root.naturalDayRowWidth) + root.spacingLg * 2
    implicitHeight: heroBand.height + root.spacingMd + hourStrip.height + root.spacingMd + dayRow.height + root.spacingLg * 2

    // ── Content root (D-04: no scrolling surface, panel padding) ────────
    Item {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: root.spacingLg

        // ── Populated bands (D-37) — hero, hour strip, day row ──────────
        // Sizing note: `hourCellWidth`/`dayCellWidth` below are the REAL,
        // render-time cell widths — derived from `contentColumn.width`
        // (this tab's OWN CURRENT width, per 14-UI-SPEC.md's spacing
        // exception formula) — never from the `natural*` measurements
        // above, which exist solely to keep `implicitWidth` non-circular.
        Item {
            id: bandsWrap
            anchors.fill: parent
            visible: !root.showPlaceholder
            opacity: root.showPlaceholder ? 0 : 1
            Behavior on opacity {
                enabled: Motion.motionEnabled
                NumberAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }

            // ── Current hero (D-37) ─────────────────────────────────────
            Item {
                id: heroBand
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: heroInner.height

                Column {
                    id: heroInner
                    width: parent.width
                    spacing: root.spacingMd

                    // Row 1 — condition symbol + temperature/condition stack
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: root.spacingMd

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.showPlaceholder ? "" : (root.weatherBackend.current ? root.weatherBackend.current.symbol : "help")
                            font.family: root.symbolFontFamily
                            font.pixelSize: root.heroSymbolSize
                            // FILL axis: hero carries the filled weight when
                            // the installed build actually drives it
                            // (14-02-SUMMARY.md's fill-axis-renders verdict);
                            // small cell symbols below stay outlined either
                            // way, matching the reference shells' weight
                            // relationship.
                            font.variableAxes: ({
                                "FILL": 1
                            })
                            color: Colours.primary
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0

                            Text {
                                text: root.showPlaceholder ? "—" : root.weatherBackend.formatTemperature(root.weatherBackend.current.temperature)
                                font.pixelSize: root.fontDisplay
                                font.weight: root.weightDisplay
                                color: Colours.onSurface
                            }

                            Text {
                                text: root.showPlaceholder ? "" : root.weatherBackend.current.label
                                font.pixelSize: root.fontHeading
                                font.weight: root.weightEmphasis
                                color: Colours.onSurfaceVariant
                            }
                        }
                    }

                    // Row 2 — feels-like / humidity / wind detail chips
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: root.spacingLg

                        Row {
                            spacing: root.spacingXs
                            Text {
                                text: "thermostat"
                                font.family: root.symbolFontFamily
                                font.pixelSize: root.iconSizeMd
                                color: Colours.primary
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.showPlaceholder ? "—" : root.weatherBackend.formatTemperature(root.weatherBackend.current.feelsLike)
                                font.pixelSize: root.fontBody
                                font.weight: root.weightBody
                                color: Colours.onSurface
                            }
                        }

                        Row {
                            spacing: root.spacingXs
                            Text {
                                text: "water_drop"
                                font.family: root.symbolFontFamily
                                font.pixelSize: root.iconSizeMd
                                color: Colours.secondary
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.showPlaceholder ? "—" : (isFinite(root.weatherBackend.current.humidity) ? Math.round(root.weatherBackend.current.humidity) + "%" : "—")
                                font.pixelSize: root.fontBody
                                font.weight: root.weightBody
                                color: Colours.onSurface
                            }
                        }

                        Row {
                            spacing: root.spacingXs
                            Text {
                                text: "air"
                                font.family: root.symbolFontFamily
                                font.pixelSize: root.iconSizeMd
                                color: Colours.tertiary
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.showPlaceholder ? "—" : root.weatherBackend.formatWind(root.weatherBackend.current.wind)
                                font.pixelSize: root.fontBody
                                font.weight: root.weightBody
                                color: Colours.onSurface
                            }
                        }
                    }

                    // Row 3 — sunrise / sunset + the staleness badge
                    // (anchored on the current-conditions block alone,
                    // D-33 — never elsewhere in this file).
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: root.spacingLg

                        Row {
                            spacing: root.spacingXs
                            Text {
                                text: "wb_twilight"
                                font.family: root.symbolFontFamily
                                font.pixelSize: root.fontLabel + 4
                                color: Colours.onSurfaceVariant
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: (!root.showPlaceholder && root.weatherBackend.current.sunrise) ? root.weatherBackend.formatClock(root.weatherBackend.current.sunrise) : "—:—"
                                font.pixelSize: root.fontLabel
                                font.weight: root.weightBody
                                color: Colours.onSurfaceVariant
                            }
                        }

                        Row {
                            spacing: root.spacingXs
                            Text {
                                text: "bedtime"
                                font.family: root.symbolFontFamily
                                font.pixelSize: root.fontLabel + 4
                                color: Colours.onSurfaceVariant
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: (!root.showPlaceholder && root.weatherBackend.current.sunset) ? root.weatherBackend.formatClock(root.weatherBackend.current.sunset) : "—:—"
                                font.pixelSize: root.fontLabel
                                font.weight: root.weightBody
                                color: Colours.onSurfaceVariant
                            }
                        }

                        // Staleness badge — absent below staleBadgeMs, calm
                        // between the two thresholds, warning tone at and
                        // past staleWarnMs. Copy is byte-identical in both
                        // tones; only `badgeColor` changes (D-33).
                        Text {
                            id: staleBadge
                            readonly property bool showBadge: !root.showPlaceholder && root.weatherBackend.isStale && root.weatherBackend.ageMs >= root.weatherBackend.staleBadgeMs
                            readonly property bool warnTone: showBadge && root.weatherBackend.ageMs >= root.weatherBackend.staleWarnMs
                            visible: showBadge
                            text: root.showPlaceholder ? "" : ("Updated " + root.weatherBackend.formatAge(root.weatherBackend.ageMs) + " ago")
                            font.pixelSize: root.fontLabel
                            font.weight: root.weightBody
                            color: warnTone ? Colours.tertiary : Colours.onSurfaceVariant
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
                }
            }

            // ── The hour strip — fixed 8 columns, NOT scrollable (D-37) ──
            Item {
                id: hourStrip
                anchors.top: heroBand.bottom
                anchors.topMargin: root.spacingMd
                anchors.left: parent.left
                anchors.right: parent.right
                height: hourColumnsRow.height

                // Real, render-time cell width — 14-UI-SPEC.md's own
                // spacing exception formula: the tab's own current width
                // less twice the panel padding, divided by the column
                // count. `contentColumn` above already applied the panel
                // padding via its own anchors.margins, so this is exactly
                // that formula with the padding subtraction already done.
                readonly property real hourCellWidth: contentColumn.width / root.hourColumns

                Row {
                    id: hourColumnsRow
                    width: parent.width

                    Repeater {
                        // Fixed count by construction — always hourColumns
                        // cells whether or not the payload fills them
                        // (D-41, zero-one-many row).
                        model: root.hourColumns

                        delegate: Item {
                            id: hourCell
                            required property int index
                            width: hourStrip.hourCellWidth
                            height: hourCellColumn.height
                            readonly property var entry: (!root.showPlaceholder && root.weatherBackend.hourlyWindow && index < root.weatherBackend.hourlyWindow.length) ? root.weatherBackend.hourlyWindow[index] : null

                            Column {
                                id: hourCellColumn
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: root.spacingXs

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: hourCell.entry ? root.weatherBackend.formatHourLabel(hourCell.entry.time) : "—"
                                    font.pixelSize: root.fontLabel
                                    font.weight: root.weightBody
                                    color: Colours.onSurfaceVariant
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: hourCell.entry ? hourCell.entry.symbol : "help"
                                    font.family: root.symbolFontFamily
                                    font.pixelSize: root.cellSymbolSize
                                    font.variableAxes: ({
                                        "FILL": 0
                                    })
                                    color: hourCell.entry ? Colours.onSurface : Colours.onSurfaceVariant
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: (hourCell.entry && !root.showPlaceholder) ? root.weatherBackend.formatTemperature(hourCell.entry.temperature) : "—"
                                    font.pixelSize: root.fontBody
                                    font.weight: root.weightBody
                                    color: Colours.onSurface
                                }
                            }
                        }
                    }
                }
            }

            // ── The five-day row (D-37) ──────────────────────────────────
            Item {
                id: dayRow
                anchors.top: hourStrip.bottom
                anchors.topMargin: root.spacingMd
                anchors.left: parent.left
                anchors.right: parent.right
                height: dayColumnsRow.height

                readonly property real dayCellWidth: (contentColumn.width - (root.dayCells - 1) * root.spacingXs) / root.dayCells

                Row {
                    id: dayColumnsRow
                    width: parent.width
                    spacing: root.spacingXs

                    Repeater {
                        // Fixed count by construction — always 5 cells
                        // (D-41, zero-one-many row).
                        model: root.dayCells

                        delegate: Item {
                            id: dayCell
                            required property int index
                            width: dayRow.dayCellWidth
                            height: dayCellColumn.height
                            readonly property var entry: (!root.showPlaceholder && root.weatherBackend.dailyWindow && index < root.weatherBackend.dailyWindow.length) ? root.weatherBackend.dailyWindow[index] : null

                            Column {
                                id: dayCellColumn
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: root.spacingXs

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: dayCell.entry ? root.weatherBackend.formatDayLabel(dayCell.entry.date) : "—"
                                    font.pixelSize: root.fontBody
                                    font.weight: root.weightEmphasis
                                    color: Colours.onSurface
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: dayCell.entry ? dayCell.entry.symbol : "help"
                                    font.family: root.symbolFontFamily
                                    font.pixelSize: root.cellSymbolSize
                                    font.variableAxes: ({
                                        "FILL": 0
                                    })
                                    color: dayCell.entry ? Colours.onSurface : Colours.onSurfaceVariant
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: (dayCell.entry && !root.showPlaceholder) ? (root.weatherBackend.formatTemperature(dayCell.entry.tempMax) + " / " + root.weatherBackend.formatTemperature(dayCell.entry.tempMin)) : "—"
                                    font.pixelSize: root.fontLabel
                                    font.weight: root.weightBody
                                    color: Colours.onSurfaceVariant
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── D-41/D-33 empty pane — never-cached / invalid-coordinates /
        //    null-backend placeholder, inside the SAME intact frame (the
        //    frame's height above is computed from the populated bands'
        //    natural sizes regardless of which branch is visible, so the
        //    degraded path is the daily path plus one label, never a
        //    different screen). There is no loading-affordance element of
        //    any kind anywhere in this file — a first fetch in flight with
        //    nothing cached keeps showing this same placeholder (14-UI-
        //    SPEC.md loading row); the absence is the design. ─────────────
        Column {
            id: emptyPane
            anchors.centerIn: parent
            visible: root.showPlaceholder
            opacity: root.showPlaceholder ? 1 : 0
            Behavior on opacity {
                enabled: Motion.motionEnabled
                NumberAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }
            spacing: root.spacingSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "cloud_off"
                font.family: root.symbolFontFamily
                font.pixelSize: root.heroSymbolSize
                color: Colours.onSurfaceVariant
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Weather unavailable"
                font.pixelSize: root.fontBody
                font.weight: root.weightBody
                color: Colours.onSurfaceVariant
            }
        }
    }
}
