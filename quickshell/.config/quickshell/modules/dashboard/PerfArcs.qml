// PerfArcs.qml — Performance tab layout "arcs" (quick task 260827-50i,
// plate P2 "Weighted Arcs" in `.planning/notes/dashboard-perf-studies.html`).
//
// Selected by `Prefs.getValue("dashboard.layout.performance")`; the switch
// lives in Dashboard.qml's `performanceTabLoader`, so this file knows nothing
// about being one of three layouts. Siblings: `PerformanceTab.qml` ("dials",
// the original five-across row) and `PerfTelemetry.qml` ("telemetry").
//
// ── What this layout is FOR ─────────────────────────────────────────────
// The study's complaint about the dial row was that five identical objects at
// identical weight give the eye no entry point. This is the conservative
// answer to that: keep the ring vocabulary that was already tuned at a render
// gate, but spend it only on the two readings that actually move
// second-to-second. CPU and GPU get 270° arcs at double the visual weight;
// memory, storage and network drop to flat bar-and-number tiles.
//
// The study is explicit about what this plate gives up in exchange: there is
// still no time axis here. If the question is "is this climbing?", the answer
// is the "telemetry" layout, not this one.
//
// ── Frame width: NARROW family, 712 of content, drawer lands at 808 ─────
// `drawerWidth = max(760, activeContentWidth + spacingLg*2)` and
// `activeContentWidth` IS this tab's `implicitWidth`, which already includes
// this tab's own `spacingLg * 2` — so 712 resolves to 808, not 760.
//
// This is the same 712 that `DashLanes.qml` and `PerfTelemetry.qml` declare,
// and it is load-bearing: those three are the NARROW family, and crossing
// between any two of them does not animate the window's width. Do not "tidy"
// this to a content-derived width, and do not change it in one file only.
//
// The two Caelestia-derived layouts (`DashBento.qml`, `PerfCards.qml`) are the
// WIDE family at 944, because the study designs them that way and says so
// itself — "these two tabs have to be chosen together". Crossing between the
// families animates the width; that is a property of the plates, not a defect
// here. See this task's PLAN.md for the full reasoning.
//
// ── Battery — D-41 stays overturned for battery, as in PerfTelemetry ────
// The plate's own words: "Battery stops being a dial and becomes a line of
// text where it belongs." That line is the network tile's foot. When no
// battery is detected the line is not rendered at all, per the operator's
// 2026-08-26 ruling; the tile composes around its absence rather than
// reserving space for a permanent "No battery".
//
// Scope of the overturn is unchanged and still narrow: battery only. The GPU
// arc still renders its own empty state rather than vanishing.
import QtQuick
import "../"

Item {
    id: root

    anchors.fill: parent

    // ── Local design constants, same sourcing as every sibling layout ───
    readonly property int spacingXs: Design.spacingXs
    readonly property int spacingSm: Design.spacingSm
    readonly property int spacingMd: Design.spacingMd
    readonly property int spacingLg: Design.spacingLg
    readonly property int fontDisplay: Design.fontDisplay
    readonly property int fontBody: Design.fontBody
    readonly property int fontLabel: Design.fontLabel
    readonly property int fontHeading: Design.fontHeading
    readonly property int weightBody: Design.weightBody
    readonly property int weightEmphasis: Design.weightEmphasis
    readonly property int iconSizeMd: Design.iconSizeMd
    readonly property string symbolFontFamily: Design.symbolFontFamily

    property var systemResources: null

    // Same Loader-timing guard every sibling tab carries: this property
    // arrives after construction, and an unguarded read is a type error in
    // the log plus a blank pane on screen.
    readonly property bool hasReader: root.systemResources !== null && root.systemResources !== undefined

    // D-41 register, reported from the reader's own aggregate self-report.
    property string widgetState: root.hasReader ? root.systemResources.widgetState : "empty"

    // See the header — NARROW family.
    readonly property int contentWidth: 712

    // ── Plate geometry ─────────────────────────────────────────────────
    // The arc diameter and ring thickness are the study's own numbers for
    // this plate (132 and 13); the rest is derived from them and from the
    // spacing scale, so nothing here is a hand-picked card height. The two
    // row heights below are bindings, not constants, precisely because the
    // last round of this work shipped fixed 176/88 heights that clipped a
    // play button and overflowed a ring column by 9px — measured.
    readonly property int arcDiameter: 132
    readonly property int arcThickness: 13

    // Two hero cards side by side, then three tiles side by side.
    readonly property int heroCardWidth: Math.floor((root.contentWidth - root.spacingMd) / 2)
    // Memory and storage are equal; network is wider because it carries two
    // rate rows plus the battery line, not one number (the study draws it at
    // flex 1.15 against the others' 1).
    readonly property int narrowTileWidth: 216
    readonly property int wideTileWidth: root.contentWidth - root.spacingMd * 2 - root.narrowTileWidth * 2

    implicitWidth: root.contentWidth + root.spacingLg * 2
    implicitHeight: contentColumn.implicitHeight + root.spacingLg * 2

    // D-21's cascade band list, in read order: the hero pair, then the tiles.
    readonly property var cascadeBands: [heroRow, tileRow]

    // The D-41 overturn's single source of truth, verbatim from
    // `PerfTelemetry.qml` — "not populated" is NOT the test. A battery that
    // exists but has not been read yet is `pending`, and hiding the line on
    // the first poll then springing it into existence would be exactly the
    // layout jump D-41 was written to prevent. Only a reader that has
    // affirmatively resolved to `empty` (no such device) removes it.
    readonly property bool batteryPresent: !root.hasReader
        || root.systemResources.batteryState !== "empty"

    Item {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: root.spacingLg

        implicitHeight: heroRow.height + root.spacingMd + tileRow.height

        // ── The two fast-moving readings, as weighted 270° arcs ─────────
        Item {
            id: heroRow
            anchors.top: parent.top
            width: parent.width
            height: cpuHero.height

            HeroArc {
                id: cpuHero
                anchors.left: parent.left
                width: root.heroCardWidth
                label: "CPU"
                accent: Colours.primary
                state_: root.hasReader ? root.systemResources.cpuState : "pending"
                fraction: root.hasReader ? root.systemResources.cpuFraction : 0
                valueText: root.hasReader ? root.systemResources.formatPercent(root.systemResources.cpuFraction) : ""
                // "CPU · 47°C" — the study puts the identity and the
                // temperature together in the arc's own bottom gap, which is
                // the space a 270° sweep exists to open up.
                captionText: {
                    if (!root.hasReader)
                        return "CPU";
                    var t = root.systemResources.cpuTempCelsius;
                    return isFinite(t) ? ("CPU · " + Math.round(t) + "°C") : "CPU";
                }
                // "4.2 GHz · Ryzen 9 7950X" — clock and part name on the
                // card's foot. `cpuName` is new in this task; before it
                // existed this line could only have carried the clock.
                detailText: {
                    if (!root.hasReader)
                        return "";
                    var r = root.systemResources;
                    var parts = [];
                    if (isFinite(r.cpuFreqGHz))
                        parts.push(r.cpuFreqGHz.toFixed(1) + " GHz");
                    if (r.cpuName !== "")
                        parts.push(r.cpuName);
                    return parts.join(" · ");
                }
            }

            HeroArc {
                anchors.left: cpuHero.right
                anchors.leftMargin: root.spacingMd
                width: root.heroCardWidth
                label: "GPU"
                accent: Colours.secondary
                state_: root.hasReader ? root.systemResources.gpuState : "pending"
                fraction: root.hasReader ? root.systemResources.gpuFraction : 0
                valueText: root.hasReader ? root.systemResources.formatPercent(root.systemResources.gpuFraction) : ""
                captionText: "GPU"
                emptyText: "No GPU"
                detailText: {
                    if (!root.hasReader)
                        return "";
                    var r = root.systemResources;
                    var parts = [];
                    parts.push(r.formatBytes(r.gpuUsedBytes) + " / " + r.formatBytes(r.gpuTotalBytes));
                    if (r.gpuName !== "")
                        parts.push(r.gpuName);
                    return parts.join(" · ");
                }
            }
        }

        // ── The three slow-moving readings, as flat tiles ───────────────
        Item {
            id: tileRow
            anchors.top: heroRow.bottom
            anchors.topMargin: root.spacingMd
            width: parent.width
            // The tallest of the three decides the row; the other two fill
            // it. Network is normally the tallest (two rate rows), but that
            // is not assumed — it is measured, every frame.
            height: Math.max(memoryTile.implicitHeight, storageTile.implicitHeight, networkTile.implicitHeight)

            BarTile {
                id: memoryTile
                anchors.left: parent.left
                width: root.narrowTileWidth
                height: tileRow.height
                label: "Memory"
                symbol: "memory_alt"
                accent: Colours.secondary
                fraction: root.hasReader ? root.systemResources.memoryFraction : 0
                state_: root.hasReader ? root.systemResources.memoryState : "pending"
                valueText: root.hasReader ? root.systemResources.formatPercent(root.systemResources.memoryFraction) : ""
                detailText: root.hasReader
                    ? (root.systemResources.formatBytes(root.systemResources.memoryUsedBytes) + " / "
                        + root.systemResources.formatBytes(root.systemResources.memoryTotalBytes))
                    : ""
            }

            BarTile {
                id: storageTile
                anchors.left: memoryTile.right
                anchors.leftMargin: root.spacingMd
                width: root.narrowTileWidth
                height: tileRow.height
                label: "Storage"
                symbol: "hard_drive_2"
                accent: Colours.tertiary
                fraction: root.hasReader ? root.systemResources.storageFraction : 0
                state_: root.hasReader ? root.systemResources.storageState : "pending"
                valueText: root.hasReader ? root.systemResources.formatPercent(root.systemResources.storageFraction) : ""
                detailText: root.hasReader
                    ? (root.systemResources.formatBytes(root.systemResources.storageUsedBytes) + " / "
                        + root.systemResources.formatBytes(root.systemResources.storageTotalBytes))
                    : ""
            }

            // The network tile has no fraction to draw — a rate has no
            // ceiling to normalise against (D-36) — so it is the one tile
            // with rate rows in place of a bar, and it carries the battery
            // line the plate demoted out of the dial row.
            Rectangle {
                id: networkTile
                anchors.left: storageTile.right
                anchors.leftMargin: root.spacingMd
                width: root.wideTileWidth
                height: tileRow.height
                implicitHeight: networkColumn.implicitHeight + root.spacingMd * 2
                radius: Design.roundingSm
                color: Colours.surfaceVariant

                readonly property bool populated: root.hasReader
                    && root.systemResources.networkState === "populated"

                Column {
                    id: networkColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: root.spacingMd
                    spacing: root.spacingSm

                    TileHeading {
                        width: parent.width
                        label: "Network"
                        symbol: "swap_vert"
                        accent: Colours.primary
                    }

                    RateLine {
                        width: parent.width
                        symbol: "arrow_downward"
                        accent: Colours.tertiary
                        text_: networkTile.populated
                            ? root.systemResources.formatRate(root.systemResources.netRxRate) : "—"
                    }

                    RateLine {
                        width: parent.width
                        symbol: "arrow_upward"
                        accent: Colours.secondary
                        text_: networkTile.populated
                            ? root.systemResources.formatRate(root.systemResources.netTxRate) : "—"
                    }

                    // The battery line. Absent entirely on a machine with no
                    // battery — the D-41 overturn — rather than reserving a
                    // slot that will never fill.
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        visible: root.batteryPresent
                        text: {
                            if (!root.hasReader)
                                return "Battery unavailable";
                            if (root.systemResources.batteryState !== "populated")
                                return "Battery reading…";
                            return "Battery " + root.systemResources.formatPercent(root.systemResources.batteryFraction)
                                + " · " + root.systemResources.batteryStateText;
                        }
                        font.pixelSize: root.fontLabel
                        font.weight: root.weightBody
                        color: Colours.onSurfaceVariant
                    }
                }
            }
        }
    }

    // ── One hero: a 270° arc, its reading in the sweep's own gap, and the
    //    device's name along the card's foot ──────────────────────────────
    component HeroArc: Rectangle {
        id: ha

        required property string label
        required property color accent
        required property string state_
        required property real fraction
        property string valueText: ""
        property string captionText: ""
        property string detailText: ""
        property string emptyText: "Unavailable"

        readonly property bool populated: ha.state_ === "populated"

        radius: Design.attachedCornerRadius
        color: Colours.surfaceVariant
        // Derived, never hand-picked: the ring's own height plus the caption
        // that sits in its gap plus the foot line plus padding.
        height: root.spacingMd + heroDial.height + root.spacingXs
            + footText.implicitHeight + root.spacingMd

        Dial {
            id: heroDial
            anchors.top: parent.top
            anchors.topMargin: root.spacingMd
            anchors.horizontalCenter: parent.horizontalCenter

            diameter: root.arcDiameter
            ringThickness: root.arcThickness
            // The plate, in one line. 135° opens the sweep at seven-thirty
            // and 270° closes it at four-thirty, leaving a 90° gap centred on
            // six o'clock — which is the space the caption below sits in.
            startAngle: 135
            sweepAngle: 270
            // Dial's own caption and detail lines are collapsed away: this
            // card draws both itself, because the plate puts the caption
            // INSIDE the ring's gap rather than under the ring.
            collapseEmptyLines: true
            label: ""
            icon: ""
            detailText: ""
            centerFontSize: root.fontDisplay
            // This dial sits ON a `surfaceVariant` card, so Dial's default
            // track (also surfaceVariant) would be invisible — measured
            // during 260826-rfy, the third occurrence of the 14-10 finding.
            // Alpha over onSurface, exactly as BarTile below does.
            trackColor: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.14)
            accentColor: ha.accent
            widgetState: ha.state_
            emptyText: ha.emptyText
            emptySymbol: "help"
            value: ha.populated ? ha.fraction : 0
            valueText: ha.valueText
        }

        // In the sweep's gap, under the figure. Positioned as a fraction of
        // the ring rather than an absolute offset so it tracks `arcDiameter`
        // if that is ever retuned.
        Text {
            anchors.top: heroDial.top
            anchors.topMargin: Math.round(root.arcDiameter * 0.66)
            anchors.horizontalCenter: heroDial.horizontalCenter
            width: ha.width - root.spacingMd * 2
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            visible: ha.populated
            text: ha.captionText
            font.pixelSize: root.fontLabel
            font.weight: root.weightBody
            color: Colours.onSurfaceVariant
        }

        Text {
            id: footText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: root.spacingMd
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: ha.populated ? ha.detailText : ""
            font.pixelSize: root.fontLabel
            font.weight: root.weightBody
            color: Colours.onSurfaceVariant
        }
    }

    // ── One slow reading: heading, number, bar, detail ──────────────────
    component BarTile: Rectangle {
        id: bt

        required property string label
        required property string symbol
        required property color accent
        required property real fraction
        required property string state_
        property string valueText: ""
        property string detailText: ""

        readonly property bool populated: bt.state_ === "populated"

        implicitHeight: btColumn.implicitHeight + root.spacingMd * 2
        radius: Design.roundingSm
        color: Colours.surfaceVariant

        Column {
            id: btColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.spacingMd
            spacing: root.spacingSm

            TileHeading {
                width: parent.width
                label: bt.label
                symbol: bt.symbol
                accent: bt.accent
            }

            Text {
                text: bt.populated ? bt.valueText : "—"
                font.pixelSize: root.fontHeading
                font.weight: root.weightEmphasis
                color: bt.accent
            }

            // Track is an alpha overlay on onSurface, NOT Colours.surfaceVariant.
            // This tile's own fill already IS surfaceVariant, and a track drawn
            // in a role identical to its backing surface renders invisible —
            // proven live in 14-10 and hit twice more since.
            Rectangle {
                width: parent.width
                height: root.spacingSm
                radius: height / 2
                color: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.14)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, bt.populated ? bt.fraction : 0))
                    height: parent.height
                    radius: parent.radius
                    color: bt.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }
                }
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: bt.populated ? bt.detailText : "Unavailable"
                font.pixelSize: root.fontLabel
                font.weight: root.weightBody
                color: Colours.onSurfaceVariant
            }
        }
    }

    // ── Shared tile heading: coloured glyph, on-surface name ────────────
    component TileHeading: Row {
        id: th

        required property string label
        required property string symbol
        required property color accent

        spacing: root.spacingXs

        Text {
            width: root.iconSizeMd
            horizontalAlignment: Text.AlignHCenter
            text: th.symbol
            font.family: root.symbolFontFamily
            font.pixelSize: root.iconSizeMd
            color: th.accent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: th.label
            font.pixelSize: root.fontBody
            font.weight: root.weightBody
            color: Colours.onSurface
        }
    }

    // ── One direction of the network readout ────────────────────────────
    component RateLine: Row {
        id: rl

        required property string symbol
        required property color accent
        required property string text_

        spacing: root.spacingXs

        Text {
            width: root.iconSizeMd
            horizontalAlignment: Text.AlignHCenter
            text: rl.symbol
            font.family: root.symbolFontFamily
            font.pixelSize: root.fontBody
            color: rl.accent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: rl.text_
            font.pixelSize: root.fontBody
            font.weight: root.weightEmphasis
            color: Colours.onSurface
        }
    }
}
