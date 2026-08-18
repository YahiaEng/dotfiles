// WeatherTab.qml — tab 3 shell (Phase 14 Plan 03, filled by Plan 14-07,
// D-37: current-conditions hero + fixed 8-column hour strip (NOT
// scrollable, D-05) + 5-day row).
//
// Root type Item, filled via anchors.fill: parent by the Loader Dashboard.qml
// places it in.
//
// NOTE — this comment used to end "always matching whatever size its Loader
// currently has, including mid-resize-animation". That is no longer true of
// the HORIZONTAL axis, and that exact behaviour turned out to be the cause of
// the visible entrance jitter on this tab: see `contentColumn`'s own note
// below. `root` itself still fills its Loader; the CONTENT inside it is now
// pinned to this tab's natural width and centred. The vertical axis still
// tracks the Loader mid-animation.
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
//
// ── 14-09 UPDATE — the paragraph above is now historical ─────────────
// The shared constants surface it says does not exist DOES exist as of
// plan 14-09: `Design`, a `pragma Singleton` registered as
// `singleton Design 1.0 Design.qml` in this directory's qmldir. The
// local constant names below are unchanged and every call site still
// reads them off `root`; only their right-hand sides now resolve to
// `Design.*` instead of repeating a literal. The reasoning above about
// id-based lexical scope was correct — it just did not apply to a
// singleton, which is why the consolidation was possible after all.
//
// ── 14-09 Task 4 UPDATE — WeatherPalette + hover tooltips ────────────────
// The Task 4 render-gate change request added condition-glyph colouring
// (`WeatherPalette`, a documented exemption to the repo-wide zero-hex/
// duration-literal invariant — see that file's own header), a hover
// tooltip on every condition glyph (the house pattern already established
// in `QuickToggles.qml`), and a small centred separator between the hour
// strip and the five-day row.
//
// ── 14-10 Task 1 UPDATE — the layered condition glyph ────────────────────
// The three condition-glyph call sites (hero, hour cells, day cells) are
// now instances of `ConditionGlyph` (`modules/dashboard/ConditionGlyph.qml`)
// rather than a bare `Text` each carrying its own colour/tooltip logic. The
// tooltip mechanism — and with it the only use of `QtQuick.Controls` this
// file ever had — now lives inside `ConditionGlyph.qml`, so that import is
// removed here; nothing in this file references `ToolTip` directly anymore.
// Every resolved-colour expression, fill axis and symbol size at each site
// is unchanged from what it was — see `ConditionGlyph`'s own header and
// 14-10-SUMMARY.md for the full record.
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
    // 14-09 Task 4 — see Design.qml's own header for the full record.
    readonly property int tooltipDelayMs: Design.tooltipDelayMs

    // 14-10 Task 1 — the three colours the layered condition-glyph experiment
    // needs, read off WeatherPalette exactly once, here, and handed into all
    // three ConditionGlyph instances below. This is what keeps the palette
    // singleton's documented single-consumer scope intact: it is still
    // consulted from exactly this one file, and now from exactly this one
    // place within it (plus the two pre-existing sunrise/sunset call sites,
    // unchanged by this task).
    readonly property color weatherPaletteSun: WeatherPalette.sun
    readonly property color weatherPaletteMoon: WeatherPalette.night
    readonly property color weatherPaletteCloud: WeatherPalette.cloudLit

    // 14-09 Task 4 — the small centred divider between the hour strip and
    // the five-day row (D-05: geometry, not motion). Deliberately narrow
    // rather than a full-width rule, per the render-gate's own wording.
    readonly property int separatorWidth: 96
    readonly property int separatorHeight: 1

    property var weatherBackend: null
    readonly property bool hasBackend: root.weatherBackend !== null && root.weatherBackend !== undefined

    // Published by Dashboard.qml: the width this tab's root WILL have once the
    // frame settles, available correct on the transition's first frame because
    // it derives from the un-animated target. 0 = not supplied, in which case
    // `contentColumn` falls back to the previous fill-the-current-frame
    // behaviour, so this file still renders standalone (qml6 probes, tests).
    property real settledPaneWidth: 0
    // Vertical counterpart, quick task 260818-nwo — see contentColumn's note.
    property real settledPaneHeight: 0

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

    // The tab's own natural content width, independent of the frame. This is
    // both the advisory hint Dashboard.qml animates the frame toward AND the
    // width `contentColumn` is actually laid out at — see `contentColumn`'s
    // own note for why the two must be the same number.
    readonly property real naturalContentWidth: Math.max(root.naturalHeroWidth, root.naturalHourStripWidth, root.naturalDayRowWidth)

    implicitWidth: root.naturalContentWidth + root.spacingLg * 2
    // 14-09 Task 4: the separator's own height plus one more spacingMd gap
    // (hourStrip -> separator -> dayRow, each edge spacingMd apart) folded
    // into the same non-circular formula as before.
    implicitHeight: heroBand.height + root.spacingMd + hourStrip.height + root.spacingMd + forecastSeparator.height + root.spacingMd + dayRow.height + root.spacingLg * 2

    // ── Content root (D-04: no scrolling surface, panel padding) ────────
    //
    // ── Width is PINNED, not stretched (weather-tab entrance jitter fix) ──
    // This used to be `anchors.fill: parent` + `anchors.margins`, which made
    // the content track the frame WHILE THE FRAME WAS ANIMATING. Because
    // Dashboard.qml destroys and rebuilds this tab on every entry, the tab
    // was constructed at the OUTGOING tab's width and then re-laid-out on
    // every frame of the resize — measured live at 15 relayouts of the 8
    // hour cells and 5 day cells, 992px -> 712px, entering from Performance.
    // On screen that reads as the content visibly compressing into place.
    //
    // It became visible when 14-09 replaced Performance's 2x2 dial grid with
    // a single wide row (~512px -> 992px of content, kept there by 14-10's
    // five dials): Weather is index 3, so its only arrow-key predecessor is
    // Performance, and that change flipped Weather's entry from a ~200px
    // expansion into a ~280px compression. Nothing in this file changed —
    // which is why the Weather tab's own history never explained it.
    //
    // Now the content is laid out ONCE, at the width it will have when the
    // frame SETTLES (`root.settledPaneWidth`, published by Dashboard.qml off
    // the un-animated target), and the animating frame simply closes around
    // it. This is the same number the old fill-plus-margins produced at rest —
    // 664px — so nothing about the settled layout changes; only the fifteen
    // intermediate widths disappear.
    //
    // NOT pinned to `naturalContentWidth`: that is the natural MINIMUM (420px,
    // driven by the hero band), and using it shrank the settled content from
    // 664px to 420px — a real regression caught by measuring the fix rather
    // than assuming it. The advisory `implicitWidth` and the laid-out width
    // are different numbers, and only the former is the natural minimum.
    //
    // Safe without clipping: Dashboard.qml's `drawerMinWidth` (760) floors the
    // frame, and this width is derived from that same frame target, so the
    // content can never be wider than the frame carrying it.
    //
    // ── SECOND PASS (quick task 260818-nwo) — the residual jitter ────────
    // The note above closed with: "The VERTICAL axis deliberately still
    // tracks the frame: the height delta is small, it was not part of the
    // reported symptom, and changing one axis at a time keeps this
    // reviewable." That deferral was reported back as "the weather tab STILL
    // jitters as it settles into place", so this pass finishes the job on
    // both remaining axes.
    //
    // 1. HEIGHT — pinned to `settledPaneHeight`, the exact mirror of the
    //    width fix, published by Dashboard.qml off the same un-animated
    //    target. Checked for a binding loop before writing it: every band
    //    here self-sizes from its own content (`heroInner.height`,
    //    `hourColumnsRow.height`, `dayColumnsRow.height`,
    //    `root.separatorHeight`) and none reads `parent.height`, so this
    //    file's `implicitHeight` does not depend on the height it receives.
    //
    // 2. X POSITION — `anchors.horizontalCenter` was the OTHER half of the
    //    residual, and it was introduced by the first fix itself. Pinning
    //    the width while centring in a frame whose width animates 992 -> 712
    //    keeps the content's SIZE constant but slides its LEFT EDGE every
    //    frame, so the content still visibly travels into place. Anchoring
    //    left at the same margin the old `anchors.fill` + margins used gives
    //    a genuinely static box: constant width, constant x. It lands in the
    //    same settled position, because the settled frame width is the one
    //    the pinned width was derived from.
    //
    // Both fall back to the old frame-tracking behaviour when the settled
    // values are still 0 (before Dashboard.qml has published them), so a
    // first frame never collapses to zero size.
    Item {
        id: contentColumn
        anchors.top: parent.top
        anchors.topMargin: root.spacingLg
        anchors.left: parent.left
        anchors.leftMargin: root.spacingLg
        width: root.settledPaneWidth > 0 ? root.settledPaneWidth - root.spacingLg * 2 : parent.width - root.spacingLg * 2
        height: root.settledPaneHeight > 0 ? root.settledPaneHeight - root.spacingLg * 2 : parent.height - root.spacingLg * 2

        // ── Populated bands (D-37) — hero, hour strip, day row ──────────
        // Sizing note: `hourCellWidth`/`dayCellWidth` below are still the
        // REAL, render-time cell widths derived from `contentColumn.width`
        // per 14-UI-SPEC.md's spacing exception formula — that contract is
        // unchanged. What changed is that `contentColumn.width` is now a
        // constant rather than a value that moves every animation frame, so
        // those cell widths resolve once instead of fifteen times per entry.
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

                        ConditionGlyph {
                            id: heroConditionGlyph
                            anchors.verticalCenter: parent.verticalCenter
                            symbolName: root.showPlaceholder ? "" : (root.weatherBackend.current ? root.weatherBackend.current.symbol : "help")
                            pixelSize: root.heroSymbolSize
                            // FILL axis: hero carries the filled weight when
                            // the installed build actually drives it
                            // (14-02-SUMMARY.md's fill-axis-renders verdict);
                            // small cell symbols below stay outlined either
                            // way, matching the reference shells' weight
                            // relationship. Unchanged from before this task.
                            baseFillAxis: 1
                            // 14-10 Task 1: the same resolved-colour
                            // expression this site always computed, moved
                            // across verbatim as the revert-path colour —
                            // falls back to the themed Colours.primary for
                            // the placeholder/unrecognised-code case, same
                            // fallback discipline at every WeatherPalette
                            // call site in this file.
                            singleToneColor: (!root.showPlaceholder && root.weatherBackend.current) ? (WeatherPalette.forSymbol(root.weatherBackend.current.symbol) || Colours.primary) : Colours.primary
                            sunColor: root.weatherPaletteSun
                            moonColor: root.weatherPaletteMoon
                            cloudColor: root.weatherPaletteCloud
                            conditionLabel: (!root.showPlaceholder && root.weatherBackend.current) ? root.weatherBackend.current.label : ""
                            tooltipDelay: root.tooltipDelayMs
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
                                // 14-09 Task 4: sunrise glyph colour
                                // (WeatherPalette, D-11 exemption) — the
                                // clock text beside it stays themed.
                                color: WeatherPalette.sunrise
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
                                // 14-09 Task 4: sunset glyph colour
                                // (WeatherPalette, D-11 exemption) — the
                                // clock text beside it stays themed.
                                color: WeatherPalette.sunset
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

                // ── Integer cell boundaries (quick task 260818-nwo, round 2)
                // The formula above is the UI-SPEC's own, and it is
                // FRACTIONAL for every column count except exactly 8:
                // 664/8 = 83 but 664/6 = 110.667, 664/7 = 94.857,
                // 664/9 = 73.778, 664/10 = 66.4. `hourColumns` is
                // backend-driven, so the integer case is the exception, not
                // the rule.
                //
                // A fractional cell width puts every cell at a fractional x,
                // and each cell centres its content, so the glyphs inside
                // land on fractional coordinates too. Qt then re-rasterises
                // them at a different subpixel phase as the frame animates —
                // which reads exactly as "the glyphs jitter left and right
                // before settling into place", the residual reported after
                // the width-pinning fix. Pinning the width could never fix
                // this: the width was already constant, it was just not a
                // whole number.
                //
                // Boundaries are rounded CUMULATIVELY rather than each width
                // independently: cell i spans round(i*W/n) to round((i+1)*W/n).
                // Every width is a whole number, every edge is a whole
                // number, and they still sum to exactly W — whereas rounding
                // each width on its own would drift the row's total by up to
                // n/2 px and leave a ragged right edge.
                function cellWidthAt(i) {
                    var w = contentColumn.width;
                    var n = root.hourColumns;
                    if (n <= 0)
                        return 0;
                    return Math.round((i + 1) * w / n) - Math.round(i * w / n);
                }

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
                            width: hourStrip.cellWidthAt(index)
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

                                ConditionGlyph {
                                    id: hourCellGlyph
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    symbolName: hourCell.entry ? hourCell.entry.symbol : "help"
                                    pixelSize: root.cellSymbolSize
                                    baseFillAxis: 0
                                    // 14-10 Task 1: the same resolved-colour
                                    // expression this site always computed,
                                    // moved across verbatim as the
                                    // revert-path colour — the hour/temp
                                    // labels beside it stay themed.
                                    singleToneColor: hourCell.entry ? (WeatherPalette.forSymbol(hourCell.entry.symbol) || Colours.onSurface) : Colours.onSurfaceVariant
                                    sunColor: root.weatherPaletteSun
                                    moonColor: root.weatherPaletteMoon
                                    cloudColor: root.weatherPaletteCloud
                                    conditionLabel: hourCell.entry ? hourCell.entry.label : ""
                                    tooltipDelay: root.tooltipDelayMs
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
            // ── The centred separator (14-09 Task 4) — a small, themed
            //    divider between today's forecast and the 5-day forecast,
            //    not a full-width rule (D-05: geometry, not motion). ───────
            Rectangle {
                id: forecastSeparator
                anchors.top: hourStrip.bottom
                anchors.topMargin: root.spacingMd
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.separatorWidth
                height: root.separatorHeight
                radius: height / 2
                color: Colours.outline
            }

            Item {
                id: dayRow
                anchors.top: forecastSeparator.bottom
                anchors.topMargin: root.spacingMd
                anchors.left: parent.left
                anchors.right: parent.right
                height: dayColumnsRow.height

                readonly property real dayCellWidth: (contentColumn.width - (root.dayCells - 1) * root.spacingXs) / root.dayCells

                // Same integer-boundary treatment as the hour strip above,
                // and this row is the WORSE offender: its width is fractional
                // unconditionally, not just for some counts —
                // (664 - 4*4)/5 = 129.6 at every settled size this tab has.
                // The available span excludes the inter-cell spacing, which
                // the Row adds back as a whole number, so rounding within the
                // span keeps every cell edge integral.
                function cellWidthAt(i) {
                    var avail = contentColumn.width - (root.dayCells - 1) * root.spacingXs;
                    var n = root.dayCells;
                    if (n <= 0)
                        return 0;
                    return Math.round((i + 1) * avail / n) - Math.round(i * avail / n);
                }

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
                            width: dayRow.cellWidthAt(index)
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

                                ConditionGlyph {
                                    id: dayCellGlyph
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    symbolName: dayCell.entry ? dayCell.entry.symbol : "help"
                                    pixelSize: root.cellSymbolSize
                                    baseFillAxis: 0
                                    // 14-10 Task 1: the same resolved-colour
                                    // expression this site always computed,
                                    // moved across verbatim as the
                                    // revert-path colour — the day/temp
                                    // labels beside it stay themed.
                                    singleToneColor: dayCell.entry ? (WeatherPalette.forSymbol(dayCell.entry.symbol) || Colours.onSurface) : Colours.onSurfaceVariant
                                    sunColor: root.weatherPaletteSun
                                    moonColor: root.weatherPaletteMoon
                                    cloudColor: root.weatherPaletteCloud
                                    conditionLabel: dayCell.entry ? dayCell.entry.label : ""
                                    tooltipDelay: root.tooltipDelayMs
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
