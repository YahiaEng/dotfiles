// PerfCards.qml — Performance tab layout "cards" (quick task 260827-50i,
// plate P1 "Caelestia Cards" in `.planning/notes/dashboard-perf-studies.html`).
//
// Selected by `Prefs.getValue("dashboard.layout.performance")`; the switch
// lives in Dashboard.qml's `performanceTabLoader`. Siblings: "dials"
// (`PerformanceTab.qml`), "telemetry" (`PerfTelemetry.qml`) and "arcs"
// (`PerfArcs.qml`).
//
// ── What this layout is FOR ─────────────────────────────────────────────
// The faithful port, and the study's own note on why the reference moved
// here: at the pinned SHA their Performance tab is cards, with no dial row
// anywhere in it. A hero pair carries CPU and GPU at full weight; storage,
// network and memory drop to a utility row; battery becomes a vertical tank
// down the right edge.
//
// What that buys, in the study's words, is that the tab finally gets an entry
// point AND the network readout gets a proportionate home — a card with a
// history graph instead of a two-figure footnote under a row of dials.
//
// ── Frame width: WIDE family, 944 of content, drawer lands at 1040 ──────
// Same reasoning, same numbers, as `DashBento.qml`'s header — the study
// designs this plate and D1 as a matched pair at one width and says so
// explicitly. This file and DashBento share 944; `DashLanes`,
// `PerfTelemetry` and `PerfArcs` share 712. Picking within a family does not
// animate the drawer's width; picking across them does.
//
// ── Battery: this is the plate the D-41 overturn was taken for ──────────
// Caelestia gates its battery tank on `UPower.displayDevice.isLaptopBattery`,
// so on a desktop it simply does not render and the layout closes up around
// it. D-41 said the opposite — always draw the slot at a fixed footprint —
// which is why the five-dial layout has a permanent "No battery" dial.
//
// The operator overturned D-41 for battery on 2026-08-26, specifically so
// this plate could be ported faithfully. So the tank is absent, not empty, on
// a machine with no battery, and the three utility cards take back its 104px.
// The scope of that overturn is battery only: the GPU hero still renders its
// own empty state rather than vanishing.
//
// The test for absence is the reader's affirmative `empty`, never merely
// "not populated" — a battery still on its first poll reads `pending`, and
// hiding then unhiding the tank would be exactly the layout jump D-41 exists
// to prevent.
//
// ── The morphing usage badge, and what it honestly is ───────────────────
// The reference's signature move on this tab is a usage badge whose SHAPE
// changes with load — `Cookie4Sided` at idle through `Sunny` to `SoftBurst`
// under load. Those are `MaterialShape` presets from a compiled C++ plugin in
// their own `plugin/` tree, which this repo does not have and will not add: a
// build step in front of "the whole setup reproduces from one script" costs
// more than the shape is worth.
//
// So `UsageBadge` below is a Canvas polar blob — radius varies sinusoidally
// with the angle, and both the lobe count and the amplitude rise with load.
// At idle the amplitude is zero and it is a plain circle; under load it grows
// petals. That is a real morph rather than a static stand-in, and it is the
// same "roughly what we'd get without their plugin" the study predicted when
// it drew the badge as a border-radius approximation. It is NOT claimed to be
// their shape.
//
// ── Radii ───────────────────────────────────────────────────────────────
// This plate's drawing uses five one-off radii (26/26/34/26/14) that do not
// map onto the shared ladder Design.qml grew for D1. Rather than mint five
// more constants, the cards use the ladder and preserve the plate's RELATIVE
// ordering: storage is the roundest, memory and the tank are the squarest,
// heroes and network sit between.
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
    readonly property int fontHeading: Design.fontHeading
    readonly property int fontBody: Design.fontBody
    readonly property int fontLabel: Design.fontLabel
    readonly property int weightBody: Design.weightBody
    readonly property int weightEmphasis: Design.weightEmphasis
    readonly property int weightDisplay: Design.weightDisplay
    readonly property int iconSizeMd: Design.iconSizeMd
    readonly property string symbolFontFamily: Design.symbolFontFamily

    property var systemResources: null

    // Same Loader-timing guard every sibling tab carries: this property
    // arrives after construction, and an unguarded read is a type error in
    // the log plus a blank pane on screen.
    readonly property bool hasReader: root.systemResources !== null && root.systemResources !== undefined

    // D-41 register, reported from the reader's own aggregate self-report.
    property string widgetState: root.hasReader ? root.systemResources.widgetState : "empty"

    // See the header — WIDE family.
    readonly property int contentWidth: 944
    readonly property int tankWidth: 104

    // The tank's 104px comes back to the utility cards when it is absent.
    readonly property int stackWidth: root.batteryPresent
        ? root.contentWidth - root.tankWidth - root.spacingMd
        : root.contentWidth

    readonly property int heroCardWidth: Math.floor((root.stackWidth - root.spacingMd) / 2)

    // Storage and memory are equal; network is wider because it carries a
    // graph and three figure rows (the study draws it at flex 1.25).
    readonly property int utilityNarrowWidth:
        Math.floor((root.stackWidth - root.spacingMd * 2) / 3.25)
    readonly property int utilityWideWidth: root.stackWidth - root.spacingMd * 2
        - root.utilityNarrowWidth * 2

    readonly property int heroRingSize: 46
    readonly property int badgeSize: 92
    readonly property int utilityArcDiameter: 104
    readonly property int utilityArcThickness: 9

    implicitWidth: root.contentWidth + root.spacingLg * 2
    implicitHeight: contentColumn.implicitHeight + root.spacingLg * 2

    // D-21's cascade band list, in read order: the hero pair, the utility
    // row, then the tank. The tank is in the list only when it is actually
    // rendered — a hidden band would burn a stagger step on nothing.
    readonly property var cascadeBands: root.batteryPresent
        ? [heroRow, utilityRow, batteryTank]
        : [heroRow, utilityRow]

    // See the header. The affirmative-`empty` test, not "not populated".
    readonly property bool batteryPresent: !root.hasReader
        || root.systemResources.batteryState !== "empty"

    Item {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: root.spacingLg

        implicitHeight: heroRow.height + root.spacingMd + utilityRow.height

        // ══ Left stack — hero pair over utility row ═══════════════════
        Item {
            id: heroRow
            anchors.left: parent.left
            anchors.top: parent.top
            width: root.stackWidth
            // The taller of the pair decides the row and the other fills it.
            // Reading both, not just the first: the GPU card's name line can
            // be absent where the CPU's is present, and assuming they match
            // is exactly the kind of "obviously identical" claim that has
            // shipped a clipped card here before.
            height: Math.max(cpuHero.implicitHeight, gpuHero.implicitHeight)

            HeroCard {
                id: cpuHero
                anchors.left: parent.left
                width: root.heroCardWidth
                height: heroRow.height
                label: "CPU"
                symbol: "memory"
                accent: Colours.primary
                state_: root.hasReader ? root.systemResources.cpuState : "pending"
                fraction: root.hasReader ? root.systemResources.cpuFraction : 0
                deviceName: root.hasReader ? root.systemResources.cpuName : ""
                // The reference's hero shows temperature beside the usage
                // badge, and the bar under it is the TEMPERATURE's own
                // scale, not the usage fraction — 0..100°C. Drawing usage
                // twice on one card would be a plausible-looking lie.
                gaugeLabel: {
                    if (!root.hasReader)
                        return "";
                    var t = root.systemResources.cpuTempCelsius;
                    return isFinite(t) ? (Math.round(t) + "°C") : "";
                }
                gaugeFraction: {
                    if (!root.hasReader)
                        return 0;
                    var t = root.systemResources.cpuTempCelsius;
                    return isFinite(t) ? Math.max(0, Math.min(1, t / 100)) : 0;
                }
            }

            HeroCard {
                id: gpuHero
                anchors.left: cpuHero.right
                anchors.leftMargin: root.spacingMd
                width: root.heroCardWidth
                height: heroRow.height
                label: "GPU"
                symbol: "desktop_windows"
                accent: Colours.secondary
                state_: root.hasReader ? root.systemResources.gpuState : "pending"
                fraction: root.hasReader ? root.systemResources.gpuFraction : 0
                deviceName: root.hasReader ? root.systemResources.gpuName : ""
                emptyText: "No GPU"
                // The GPU has no temperature seam in this reader, so its
                // second gauge is VRAM — a real second dimension, and the
                // one the reference's own GPU card shows.
                gaugeLabel: root.hasReader
                    ? (root.systemResources.formatBytes(root.systemResources.gpuUsedBytes) + " / "
                        + root.systemResources.formatBytes(root.systemResources.gpuTotalBytes))
                    : ""
                gaugeFraction: {
                    if (!root.hasReader)
                        return 0;
                    var total = root.systemResources.gpuTotalBytes;
                    if (!(total > 0))
                        return 0;
                    return Math.max(0, Math.min(1, root.systemResources.gpuUsedBytes / total));
                }
            }
        }

        Item {
            id: utilityRow
            anchors.left: parent.left
            anchors.top: heroRow.bottom
            anchors.topMargin: root.spacingMd
            width: root.stackWidth
            // The tallest of the three decides the row; measured every
            // frame rather than assumed to be the network card.
            height: Math.max(storageCard.implicitHeight, networkCard.implicitHeight, memoryCard.implicitHeight)

            ArcCard {
                id: storageCard
                anchors.left: parent.left
                width: root.utilityNarrowWidth
                height: utilityRow.height
                label: "Storage"
                symbol: "hard_drive_2"
                accent: Colours.tertiary
                cardRadius: Design.roundingLg
                state_: root.hasReader ? root.systemResources.storageState : "pending"
                fraction: root.hasReader ? root.systemResources.storageFraction : 0
                valueText: root.hasReader ? root.systemResources.formatPercent(root.systemResources.storageFraction) : ""
                detailText: root.hasReader
                    ? (root.systemResources.formatBytes(root.systemResources.storageUsedBytes) + " / "
                        + root.systemResources.formatBytes(root.systemResources.storageTotalBytes))
                    : ""
            }

            // ── Network: a card and a history graph, which is the whole
            //    point of this plate for this metric ────────────────────
            Rectangle {
                id: networkCard
                anchors.left: storageCard.right
                anchors.leftMargin: root.spacingMd
                width: root.utilityWideWidth
                height: utilityRow.height
                implicitHeight: networkColumn.implicitHeight + root.spacingMd * 2
                radius: Design.roundingMd
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

                    CardHeading {
                        width: parent.width
                        label: "Network"
                        symbol: "swap_vert"
                        accent: Colours.primary
                    }

                    Item {
                        width: parent.width
                        height: 62

                        Sparkline {
                            anchors.fill: parent
                            visible: networkCard.populated
                            values: root.hasReader ? root.systemResources.netRxHistory : []
                            secondaryValues: root.hasReader ? root.systemResources.netTxHistory : []
                            capacity: root.hasReader ? root.systemResources.historyLength : 60
                            // A rate has no ceiling to normalise against
                            // (D-36), so the scale is the buffer's own
                            // running maximum across BOTH directions — one
                            // shared ceiling, or the two traces would be
                            // drawn to different scales in one box and read
                            // as comparable when they are not.
                            maxValue: {
                                if (!root.hasReader)
                                    return 1;
                                var r = root.systemResources;
                                var floorRate = 1024;
                                return Math.max(r.historyMax(r.netRxHistory, floorRate),
                                                r.historyMax(r.netTxHistory, floorRate));
                            }
                            lineColour: Colours.tertiary
                            secondaryLineColour: Colours.secondary
                        }

                        // Two distinct not-yet states, never one shrug: a
                        // populated reader with a buffer too short to draw is
                        // COLLECTING and will resolve itself; anything else
                        // is the reader's own verdict and will not.
                        Text {
                            anchors.centerIn: parent
                            visible: !networkCard.populated
                                || !root.hasReader
                                || (root.systemResources.netRxHistory
                                    ? root.systemResources.netRxHistory.length : 0) < 2
                            text: networkCard.populated ? "Collecting…" : "Unavailable"
                            font.pixelSize: root.fontLabel
                            font.weight: root.weightBody
                            color: Colours.outline
                        }
                    }

                    FigureRow {
                        width: parent.width
                        label: "Download"
                        accent: Colours.tertiary
                        value_: networkCard.populated
                            ? root.systemResources.formatRate(root.systemResources.netRxRate) : "—"
                    }

                    FigureRow {
                        width: parent.width
                        label: "Upload"
                        accent: Colours.secondary
                        value_: networkCard.populated
                            ? root.systemResources.formatRate(root.systemResources.netTxRate) : "—"
                    }

                    // Since BOOT, not since the shell started — these are the
                    // raw /proc/net/dev counters, and the label says "total"
                    // rather than anything time-bounded that would be untrue.
                    FigureRow {
                        width: parent.width
                        label: "Total"
                        accent: Colours.onSurfaceVariant
                        value_: root.hasReader
                            ? ("↓" + root.systemResources.formatBytes(root.systemResources.netRxTotal)
                                + "  ↑" + root.systemResources.formatBytes(root.systemResources.netTxTotal))
                            : "—"
                    }
                }
            }

            ArcCard {
                id: memoryCard
                anchors.left: networkCard.right
                anchors.leftMargin: root.spacingMd
                width: root.utilityNarrowWidth
                height: utilityRow.height
                label: "Memory"
                symbol: "memory_alt"
                accent: Colours.secondary
                cardRadius: Design.roundingSm
                state_: root.hasReader ? root.systemResources.memoryState : "pending"
                fraction: root.hasReader ? root.systemResources.memoryFraction : 0
                valueText: root.hasReader ? root.systemResources.formatPercent(root.systemResources.memoryFraction) : ""
                detailText: root.hasReader
                    ? (root.systemResources.formatBytes(root.systemResources.memoryUsedBytes) + " / "
                        + root.systemResources.formatBytes(root.systemResources.memoryTotalBytes))
                    : ""
            }
        }

        // ══ Battery tank — absent, not empty, with no battery ══════════
        Rectangle {
            id: batteryTank
            anchors.right: parent.right
            anchors.top: parent.top
            width: root.tankWidth
            height: heroRow.height + root.spacingMd + utilityRow.height
            radius: Design.roundingSm
            color: Colours.surfaceVariant
            clip: true
            visible: root.batteryPresent

            readonly property bool populated: root.hasReader
                && root.systemResources.batteryState === "populated"
            readonly property real level: batteryTank.populated
                ? Math.max(0, Math.min(1, root.systemResources.batteryFraction)) : 0

            // The tank's fill: charge as a rising water level, which is the
            // whole reason this is a tall column rather than another dial.
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * batteryTank.level
                color: Qt.rgba(Colours.secondary.r, Colours.secondary.g, Colours.secondary.b, 0.55)

                Behavior on height {
                    NumberAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }
            }

            Item {
                anchors.fill: parent
                anchors.margins: root.spacingMd

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: root.spacingXs

                    Text {
                        text: batteryTank.populated ? "battery_full" : "battery_unknown"
                        font.family: root.symbolFontFamily
                        font.pixelSize: root.iconSizeMd
                        color: Colours.primary
                    }

                    Text {
                        text: "Battery"
                        font.pixelSize: root.fontLabel
                        font.weight: root.weightBody
                        color: Colours.onSurface
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    spacing: root.spacingXs

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                        text: batteryTank.populated
                            ? root.systemResources.batteryStateText : "reading…"
                        font.pixelSize: root.fontLabel
                        font.weight: root.weightBody
                        color: Colours.onSurfaceVariant
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        text: batteryTank.populated
                            ? root.systemResources.formatPercent(root.systemResources.batteryFraction)
                            : "—"
                        font.pixelSize: root.fontHeading
                        font.weight: root.weightEmphasis
                        color: batteryTank.populated ? Colours.onSurface : Colours.outline
                    }
                }
            }
        }
    }

    // ── One hero: identity ring and name up top, a second gauge and the
    //    morphing usage badge along the bottom ────────────────────────────
    component HeroCard: Rectangle {
        id: hc

        required property string label
        required property string symbol
        required property color accent
        required property string state_
        required property real fraction
        property string deviceName: ""
        property string gaugeLabel: ""
        property real gaugeFraction: 0
        property string emptyText: "Unavailable"

        readonly property bool populated: hc.state_ === "populated"

        radius: Design.roundingMd
        color: Colours.surfaceVariant
        // Derived, never hand-picked: the identity row, the badge, and the
        // padding around them.
        implicitHeight: root.spacingMd + Math.max(root.heroRingSize, identityColumn.implicitHeight)
            + root.spacingMd + root.badgeSize + root.spacingMd

        Row {
            id: identityRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.spacingMd
            spacing: root.spacingSm

            // A small ring repeating the usage figure — the reference's own
            // "the number twice, at two sizes" move, which is what lets the
            // big badge below carry no label of its own.
            Dial {
                diameter: root.heroRingSize
                ringThickness: root.spacingXs + 1
                collapseEmptyLines: true
                label: ""
                icon: ""
                detailText: ""
                valueText: ""
                // This dial sits ON a `surfaceVariant` card, so Dial's
                // default track (also surfaceVariant) would be invisible.
                trackColor: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.14)
                accentColor: hc.accent
                widgetState: hc.populated ? "populated" : "pending"
                value: hc.populated ? hc.fraction : 0

                // The small square the reference puts inside this ring.
                // Positioned against the RING's centre, not the Dial item's:
                // Dial's own height is `diameter + spacingXs + caption +
                // detail`, so even with both lines collapsed a plain
                // `centerIn: parent` sits ~2px low.
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: (root.heroRingSize - height) / 2
                    width: root.spacingMd
                    height: width
                    radius: root.spacingXs + 1
                    color: hc.accent
                }
            }

            Column {
                id: identityColumn
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.spacingXs

                Text {
                    text: hc.label
                    font.pixelSize: root.fontBody
                    font.weight: root.weightBody
                    color: hc.accent
                }

                // `cpuName` is new in this task; `gpuName` already existed.
                // An unreadable name leaves this line out entirely rather
                // than printing a placeholder that looks like a device.
                Text {
                    width: hc.width - root.spacingMd * 2 - root.heroRingSize - root.spacingSm
                    elide: Text.ElideRight
                    visible: text.length > 0
                    text: hc.populated ? hc.deviceName : hc.emptyText
                    font.pixelSize: root.fontLabel
                    font.weight: root.weightBody
                    color: Colours.onSurfaceVariant
                }
            }
        }

        // The second gauge — temperature for CPU, VRAM for GPU. Deliberately
        // NOT the usage fraction again; see each call site.
        Column {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: root.spacingMd
            width: hc.width - root.spacingMd * 2 - root.badgeSize - root.spacingSm
            spacing: root.spacingSm

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: hc.populated ? hc.gaugeLabel : "—"
                font.pixelSize: root.fontBody
                font.weight: root.weightEmphasis
                color: hc.accent
            }

            // Track is alpha over onSurface, NOT Colours.surfaceVariant —
            // this card's own fill already IS surfaceVariant, and a track in
            // a role identical to its backing surface renders invisible.
            Rectangle {
                width: parent.width
                height: root.spacingSm
                radius: height / 2
                color: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.14)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, hc.populated ? hc.gaugeFraction : 0))
                    height: parent.height
                    radius: parent.radius
                    color: hc.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }
                }
            }
        }

        UsageBadge {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: root.spacingMd
            size: root.badgeSize
            accent: hc.accent
            load: hc.populated ? hc.fraction : 0
            valueText: hc.populated
                && root.hasReader ? root.systemResources.formatPercent(hc.fraction) : "—"
        }
    }

    // ── One utility card built around a 270° arc ────────────────────────
    component ArcCard: Rectangle {
        id: ac

        required property string label
        required property string symbol
        required property color accent
        required property string state_
        required property real fraction
        property int cardRadius: Design.roundingMd
        property string valueText: ""
        property string detailText: ""

        readonly property bool populated: ac.state_ === "populated"

        implicitHeight: acColumn.implicitHeight + root.spacingMd * 2
        radius: ac.cardRadius
        color: Colours.surfaceVariant

        Column {
            id: acColumn
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - root.spacingMd * 2
            spacing: root.spacingSm

            CardHeading {
                width: parent.width
                label: ac.label
                symbol: ac.symbol
                accent: ac.accent
            }

            Dial {
                anchors.horizontalCenter: parent.horizontalCenter
                diameter: root.utilityArcDiameter
                ringThickness: root.utilityArcThickness
                // The plate's arcs, same 270° opening as PerfArcs' heroes:
                // start at seven-thirty, close at four-thirty, gap centred
                // on six o'clock.
                startAngle: 135
                sweepAngle: 270
                collapseEmptyLines: true
                label: ""
                icon: ""
                detailText: ""
                centerFontSize: root.fontHeading
                trackColor: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.14)
                accentColor: ac.accent
                widgetState: ac.state_
                value: ac.populated ? ac.fraction : 0
                valueText: ac.valueText
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: ac.populated ? ac.detailText : "Unavailable"
                font.pixelSize: root.fontLabel
                font.weight: root.weightBody
                color: Colours.onSurfaceVariant
            }
        }
    }

    // ── Shared card heading ─────────────────────────────────────────────
    component CardHeading: Row {
        id: ch

        required property string label
        required property string symbol
        required property color accent

        spacing: root.spacingXs

        Text {
            width: root.iconSizeMd
            horizontalAlignment: Text.AlignHCenter
            text: ch.symbol
            font.family: root.symbolFontFamily
            font.pixelSize: root.iconSizeMd
            color: ch.accent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ch.label
            font.pixelSize: root.fontBody
            font.weight: root.weightBody
            color: Colours.onSurface
        }
    }

    // ── One labelled figure in the network card ─────────────────────────
    component FigureRow: Item {
        id: fr

        required property string label
        required property color accent
        required property string value_

        implicitHeight: frLabel.implicitHeight

        Text {
            id: frLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: fr.label
            font.pixelSize: root.fontLabel
            font.weight: root.weightBody
            color: Colours.onSurfaceVariant
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: fr.value_
            font.pixelSize: root.fontLabel
            font.weight: root.weightEmphasis
            color: fr.accent
        }
    }

    // ── The morphing usage badge ────────────────────────────────────────
    // See the header for what this is and is not. The shape is a polar blob:
    // radius varies with angle as `1 + amp * cos(lobes * theta)`, where both
    // `amp` and `lobes` rise with load. At zero load `amp` is zero and this
    // draws a plain circle, which is the reference's own idle shape.
    component UsageBadge: Item {
        id: ub

        property int size: 92
        property color accent: Colours.primary
        // 0..1. Drives BOTH the lobe count and the amplitude, which is what
        // makes the shape read as a reading rather than as decoration.
        property real load: 0
        property string valueText: ""

        width: ub.size
        height: ub.size

        // Animated so the shape MORPHS between readings instead of snapping.
        // The Canvas repaints off this interpolated value, not off `load`
        // directly — binding the paint to the raw reading would step.
        property real animatedLoad: 0
        Behavior on animatedLoad {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
        onLoadChanged: ub.animatedLoad = ub.load
        Component.onCompleted: ub.animatedLoad = ub.load

        onAnimatedLoadChanged: blob.requestPaint()
        onAccentChanged: blob.requestPaint()

        Canvas {
            id: blob
            anchors.fill: parent
            // Same reasoning as Sparkline's: at a repaint per poll the
            // immediate renderer's whole-texture upload is irrelevant, and
            // it avoids the threaded renderer's surface juggling inside a
            // Loader that gets torn down with the drawer.
            renderStrategy: Canvas.Immediate

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.clearRect(0, 0, width, height);

                var cx = width / 2;
                var cy = height / 2;
                var f = Math.max(0, Math.min(1, ub.animatedLoad));
                // Petals grow from 4 to 8 across the range; the amplitude
                // stays small enough that the badge never stops reading as
                // one solid object.
                var lobes = 4 + Math.round(f * 4);
                var amp = 0.10 * f;
                // The base radius shrinks slightly as the amplitude grows so
                // the petals stay inside the item's own box rather than
                // being clipped by it.
                var base = (Math.min(width, height) / 2) / (1 + amp);

                ctx.beginPath();
                var steps = 180;
                for (var i = 0; i <= steps; i++) {
                    var theta = (i / steps) * Math.PI * 2;
                    var r = base * (1 + amp * Math.cos(lobes * theta));
                    var x = cx + r * Math.cos(theta);
                    var y = cy + r * Math.sin(theta);
                    if (i === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.closePath();
                // Alpha over the accent rather than a separate palette role,
                // so the badge stays correct through a theme switch with
                // nothing to re-derive — Sparkline's own fill convention.
                ctx.fillStyle = Qt.rgba(ub.accent.r, ub.accent.g, ub.accent.b, 0.22);
                ctx.fill();
                ctx.strokeStyle = Qt.rgba(ub.accent.r, ub.accent.g, ub.accent.b, 1);
                ctx.lineWidth = 2;
                ctx.lineJoin = "round";
                ctx.stroke();
            }
        }

        Text {
            anchors.centerIn: parent
            text: ub.valueText
            font.pixelSize: root.fontHeading
            font.weight: root.weightEmphasis
            color: ub.accent
        }
    }
}
