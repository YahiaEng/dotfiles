// PerfTelemetry.qml — Performance tab layout "telemetry" (quick task
// 260826-rfy, plate P3 in `.planning/notes/dashboard-perf-studies.html`).
//
// Selected by `Prefs.getValue("dashboard.layout.performance")`; the switch
// itself lives in Dashboard.qml's `performanceTabLoader`, so this file knows
// nothing about being one of several layouts. Sibling layout: the original
// five-dial row, still `PerformanceTab.qml`, selected as "dials".
//
// ── What this layout is FOR ─────────────────────────────────────────────
// The design study's measured complaint about the dial row was that all five
// readings are instantaneous and equally weighted, so the pane has no entry
// point and cannot answer "is this climbing?". Here the three fast-moving
// series get a graph and a live endpoint, and the two slow-moving ones drop
// to flat bars — hierarchy by rate of change, not by importance ranking.
//
// ── Frame width: 712, deliberately ──────────────────────────────────────
// `Dashboard.qml` computes `drawerWidth = max(drawerMinWidth(760),
// activeContentWidth + spacingLg*2)`. Anything at or under 712 therefore
// lands the drawer on its 760 floor EXACTLY — the same width DashboardTab
// uses — which is what closes the study's second finding: Performance
// measured 1040 against Dashboard's 760, so crossing tabs animated the
// window 280px wider and back every time. Do not "tidy" this to a
// content-derived width; the number is load-bearing.
//
// WIDTH parity only — deliberate, not an oversight. `DashLanes.qml` has to
// DERIVE its height from `QuickToggles.implicitHeight` (a fixed constant
// there overlaps the toggles onto the card above them — measured on this
// file's sibling during 260826-rfy), so its height is not a compile-time
// number this file could match. The drawer therefore still animates its
// height slightly when crossing between these two tabs. It no longer
// animates its width at all, which was the 280px complaint.
//
// ── Battery ─────────────────────────────────────────────────────────────
// Not a graph and not a tile: a rate-of-charge series would be flat-zero on
// a desktop and the study's own plate showed it as a status line. D-41's
// always-show rule is honoured — the slot is always rendered, it is simply
// rendered as text. This is NOT the D-41 override that plate P1 would need;
// nothing here is hidden when the hardware is absent.
import QtQuick
import "../"

Item {
    id: root

    anchors.fill: parent

    // ── Local design constants, same sourcing as PerformanceTab.qml ─────
    readonly property int spacingXs: Design.spacingXs
    readonly property int spacingSm: Design.spacingSm
    readonly property int spacingMd: Design.spacingMd
    readonly property int spacingLg: Design.spacingLg
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

    // See the header — 712 puts the drawer on its 760 floor.
    readonly property int contentWidth: 712
    readonly property int graphRowHeight: 88
    readonly property int tileRowHeight: 76

    implicitWidth: root.contentWidth + root.spacingLg * 2
    implicitHeight: contentColumn.implicitHeight + root.spacingLg * 2

    // D-21's cascade band list, in read order: the three graphed rows, then
    // the slow-tile row, then the battery line.
    readonly property var cascadeBands: [cpuRow, gpuRow, netRow, slowRow, batteryLine]

    Item {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: root.spacingLg

        implicitHeight: root.graphRowHeight * 3 + root.tileRowHeight
            + root.spacingSm * 3 + root.spacingMd + batteryLine.height

        // ── Three graphed rows ──────────────────────────────────────────
        GraphRow {
            id: cpuRow
            anchors.top: parent.top
            width: parent.width
            label: "CPU"
            symbol: "memory"
            accent: Colours.primary
            series: root.hasReader ? root.systemResources.cpuHistory : []
            capacity: root.hasReader ? root.systemResources.historyLength : 60
            seriesMax: 1
            state_: root.hasReader ? root.systemResources.cpuState : "pending"
            primaryText: root.hasReader ? root.systemResources.formatPercent(root.systemResources.cpuFraction) : ""
            detailText: {
                if (!root.hasReader)
                    return "";
                var r = root.systemResources;
                var parts = [];
                if (isFinite(r.cpuFreqGHz))
                    parts.push(r.cpuFreqGHz.toFixed(1) + " GHz");
                if (isFinite(r.cpuTempCelsius))
                    parts.push(Math.round(r.cpuTempCelsius) + "°C");
                return parts.join(" · ");
            }
        }

        GraphRow {
            id: gpuRow
            anchors.top: cpuRow.bottom
            anchors.topMargin: root.spacingSm
            width: parent.width
            label: "GPU"
            symbol: "desktop_windows"
            accent: Colours.secondary
            series: root.hasReader ? root.systemResources.gpuHistory : []
            capacity: root.hasReader ? root.systemResources.historyLength : 60
            seriesMax: 1
            state_: root.hasReader ? root.systemResources.gpuState : "pending"
            primaryText: root.hasReader ? root.systemResources.formatPercent(root.systemResources.gpuFraction) : ""
            detailText: root.hasReader
                ? (root.systemResources.formatBytes(root.systemResources.gpuUsedBytes) + " / "
                    + root.systemResources.formatBytes(root.systemResources.gpuTotalBytes))
                : ""
            emptyText: "No GPU"
            // The GPU sampler runs on its own 4s timer while CPU/network run
            // on the ~2s fast poll, so this row's buffer advances at half
            // their rate and its trace therefore spans roughly twice the
            // wall time at the same width. Stated rather than corrected:
            // re-pitching per-series would make the rows disagree visually
            // about what one pixel of x means, which is worse than two rows
            // honestly showing "recent history" at their own sampling rate.
        }

        GraphRow {
            id: netRow
            anchors.top: gpuRow.bottom
            anchors.topMargin: root.spacingSm
            width: parent.width
            label: "Network"
            symbol: "swap_vert"
            accent: Colours.tertiary
            secondaryAccent: Colours.secondary
            series: root.hasReader ? root.systemResources.netRxHistory : []
            secondarySeries: root.hasReader ? root.systemResources.netTxHistory : []
            capacity: root.hasReader ? root.systemResources.historyLength : 60
            // A rate has no ceiling to normalise against (D-36), so the
            // scale is the buffer's own running maximum across BOTH
            // directions — one shared ceiling, or the two traces would be
            // drawn to different scales in one box and read as comparable.
            seriesMax: {
                if (!root.hasReader)
                    return 1;
                var r = root.systemResources;
                var floorRate = 1024;
                return Math.max(r.historyMax(r.netRxHistory, floorRate),
                                r.historyMax(r.netTxHistory, floorRate));
            }
            state_: root.hasReader ? root.systemResources.networkState : "pending"
            primaryText: root.hasReader ? root.systemResources.formatRate(root.systemResources.netRxRate) : ""
            secondaryText: root.hasReader ? root.systemResources.formatRate(root.systemResources.netTxRate) : ""
            detailText: ""
        }

        // ── The two slow-moving readings, as flat bars ──────────────────
        Item {
            id: slowRow
            anchors.top: netRow.bottom
            anchors.topMargin: root.spacingSm
            width: parent.width
            height: root.tileRowHeight

            BarTile {
                id: memoryTile
                anchors.left: parent.left
                width: (parent.width - root.spacingSm) / 2
                height: parent.height
                label: "Memory"
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
                anchors.left: memoryTile.right
                anchors.leftMargin: root.spacingSm
                width: memoryTile.width
                height: parent.height
                label: "Storage"
                accent: Colours.tertiary
                fraction: root.hasReader ? root.systemResources.storageFraction : 0
                state_: root.hasReader ? root.systemResources.storageState : "pending"
                valueText: root.hasReader ? root.systemResources.formatPercent(root.systemResources.storageFraction) : ""
                detailText: root.hasReader
                    ? (root.systemResources.formatBytes(root.systemResources.storageUsedBytes) + " / "
                        + root.systemResources.formatBytes(root.systemResources.storageTotalBytes))
                    : ""
            }
        }

        // ── Battery, as an always-present status line (D-41) ────────────
        Row {
            id: batteryLine
            anchors.top: slowRow.bottom
            anchors.topMargin: root.spacingMd
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.spacingXs

            Text {
                width: root.iconSizeMd
                horizontalAlignment: Text.AlignHCenter
                text: (root.hasReader && root.systemResources.batteryState === "populated")
                    ? "battery_full" : "battery_unknown"
                font.family: root.symbolFontFamily
                font.pixelSize: root.iconSizeMd
                color: Colours.outline
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (!root.hasReader)
                        return "Battery unavailable";
                    if (root.systemResources.batteryState !== "populated")
                        return "No battery on this host";
                    return root.systemResources.formatPercent(root.systemResources.batteryFraction)
                        + " · " + root.systemResources.batteryStateText;
                }
                font.pixelSize: root.fontLabel
                font.weight: root.weightBody
                color: Colours.onSurfaceVariant
            }
        }
    }

    // ── One graphed row: identity on the left, trace in the middle, live
    //    figures on the right ─────────────────────────────────────────────
    component GraphRow: Rectangle {
        id: gr

        required property string label
        required property string symbol
        required property color accent
        property color secondaryAccent: gr.accent
        required property var series
        property var secondarySeries: []
        property int capacity: 60
        property real seriesMax: 1
        // Named `state_` and not `state`: `state` is a real QML Item
        // property (the state-machine name) and assigning a D-41 register
        // string to it would silently try to activate a State of that name.
        required property string state_
        property string primaryText: ""
        property string secondaryText: ""
        property string detailText: ""
        property string emptyText: "Unavailable"

        readonly property bool populated: gr.state_ === "populated"

        height: root.graphRowHeight
        radius: Design.popoutCornerRadius
        color: Colours.surfaceVariant

        Row {
            anchors.fill: parent
            anchors.margins: root.spacingMd
            spacing: root.spacingMd

            // identity
            Row {
                width: 116
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.spacingXs

                Text {
                    width: root.iconSizeMd
                    horizontalAlignment: Text.AlignHCenter
                    text: gr.symbol
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.iconSizeMd
                    color: gr.accent
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: gr.label
                    font.pixelSize: root.fontBody
                    font.weight: root.weightBody
                    color: Colours.onSurface
                }
            }

            // trace
            Item {
                width: parent.width - 116 - 132 - root.spacingMd * 2
                height: parent.height

                Sparkline {
                    anchors.fill: parent
                    visible: gr.populated
                    values: gr.series
                    secondaryValues: gr.secondarySeries
                    capacity: gr.capacity
                    maxValue: gr.seriesMax
                    lineColour: gr.accent
                    secondaryLineColour: gr.secondaryAccent
                }

                // Two distinct not-yet states, never one shrug: a populated
                // reader with a buffer too short to draw is COLLECTING and
                // will resolve itself; anything else is the reader's own
                // empty/pending verdict and will not.
                Text {
                    anchors.centerIn: parent
                    visible: !gr.populated || (gr.series ? gr.series.length : 0) < 2
                    text: gr.populated ? "Collecting…" : gr.emptyText
                    font.pixelSize: root.fontLabel
                    font.weight: root.weightBody
                    color: Colours.outline
                }
            }

            // live figures
            Column {
                width: 132
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.spacingXs

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    text: gr.populated ? gr.primaryText : "—"
                    font.pixelSize: root.fontHeading
                    font.weight: root.weightEmphasis
                    color: gr.accent
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    visible: text.length > 0
                    text: gr.populated ? (gr.secondaryText.length > 0 ? gr.secondaryText : gr.detailText) : ""
                    font.pixelSize: root.fontLabel
                    font.weight: root.weightBody
                    color: gr.secondaryText.length > 0 ? gr.secondaryAccent : Colours.onSurfaceVariant
                }
            }
        }
    }

    // ── One slow-moving reading: number, bar, detail ────────────────────
    component BarTile: Rectangle {
        id: bt

        required property string label
        required property color accent
        required property real fraction
        required property string state_
        property string valueText: ""
        property string detailText: ""

        readonly property bool populated: bt.state_ === "populated"

        radius: Design.popoutCornerRadius
        color: Colours.surfaceVariant

        Column {
            anchors.fill: parent
            anchors.margins: root.spacingMd
            spacing: root.spacingXs

            Row {
                width: parent.width
                spacing: root.spacingXs

                Text {
                    anchors.baseline: pctLabel.baseline
                    text: bt.label
                    font.pixelSize: root.fontLabel
                    font.weight: root.weightBody
                    color: Colours.onSurfaceVariant
                }

                Item { width: parent.width - 200; height: 1 }

                Text {
                    id: pctLabel
                    text: bt.populated ? bt.valueText : "—"
                    font.pixelSize: root.fontBody
                    font.weight: root.weightEmphasis
                    color: bt.accent
                }
            }

            // Track is an alpha overlay on onSurface, NOT Colours.surfaceVariant.
            // This tile's own fill already IS surfaceVariant, and 14-10 proved
            // live that a track drawn in a role identical to its backing
            // surface renders invisible — the same trap that made a GPU ring
            // in primaryContainer disappear against its own track.
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
}
