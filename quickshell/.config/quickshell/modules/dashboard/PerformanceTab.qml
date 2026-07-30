// PerformanceTab.qml — tab 2, filled (Phase 14 Plan 06, D-36, DASH-05): a
// 2x2 grid of four MD3 circular dials (CPU, Memory, Storage, Battery) plus
// an honest network up/down rate row — a rate is not a percentage, so it is
// two labelled readouts, never a fifth dial and never a normalised bar.
//
// Root type Item, filled via anchors.fill: parent by the Loader Dashboard.qml
// places it in — actual rendered geometry stays anchors.fill-driven,
// unchanged from 14-03. `implicitWidth`/`implicitHeight` below are D-04's
// "no implicit size" prohibition, deliberately reversed at 14-03's render
// gate (see 14-03-SUMMARY.md's Deviations): Dashboard.qml reads them as an
// advisory hint for the drawer's own animated frame target, decoupled from
// this item's actual rendered size. They are now derived from this file's
// own layout's real natural size (`dialGrid`'s own width/height — see the
// round-3 note further down for why this is bound directly to `dialGrid`
// rather than to a layout container's rendered width), replacing 14-03's
// placeholder 1000x360 estimate.
//
// ── Design constants — NOT read off `dashboardWindow` ───────────────────
// Same mechanism gap 14-05's MediaTab.qml and this plan's Dial.qml both
// record: a QML `id` is lexically scoped to its declaring file, and
// `PerformanceTab` is a separate registered component instantiated inside
// `dashboardWindow`'s object tree, not textually nested inside it — so a
// bare `dashboardWindow.spacingLg`-style reference would not resolve. This
// file declares its own copies, sourced from 14-UI-SPEC.md's tables;
// consolidating every tab onto one shared constants surface is 14-08's job
// (consolidation note recorded again in 14-06-SUMMARY.md).
//
// D-41 widget-state register — "populated" / "pending" / "empty" — carried
// on every one of this phase's nine modules/dashboard/ files.
//
// Property contract: `systemResources` is typed `var` (14-03's own choice,
// kept) — the SAME shared instance DashboardTab's resources strip (14-08)
// reads, one poll, not two. Every read below is guarded against this being
// null: the tab is instantiated by a lazy Loader and there is a moment
// before the property arrives where an unguarded read would be a type
// error in the log and a blank pane on screen.
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
import QtQuick
import "../"

Item {
    id: root

    anchors.fill: parent

    // ── Local design constants (see header note above) ──────────────────
    readonly property int spacingXs: Design.spacingXs
    readonly property int spacingMd: Design.spacingMd
    readonly property int spacingLg: Design.spacingLg
    readonly property int fontBody: Design.fontBody
    readonly property int fontLabel: Design.fontLabel
    readonly property int weightBody: Design.weightBody
    readonly property int iconSizeMd: Design.iconSizeMd
    readonly property string symbolFontFamily: Design.symbolFontFamily

    property var systemResources: null

    // Guards every read below against the Loader-timing window where this
    // property hasn't arrived yet — every dial falls back to its own
    // pending state rather than throwing a type error into the log.
    readonly property bool hasReader: root.systemResources !== null && root.systemResources !== undefined

    // D-41: "populated" | "pending" | "empty" — reports the tab's own state
    // from the reader's aggregate self-report, so anything asking this tab
    // "are you populated?" gets an honest answer without re-deriving reader
    // internals.
    property string widgetState: root.hasReader ? root.systemResources.widgetState : "empty"

    // ── D-21's cascade band list (Phase 14 Plan 09) — D-36 read order:
    //    the dial grid, then the network rate row.
    readonly property var cascadeBands: [dialGridRow, networkRowWrap]

    // ── Tab-root layout constants ────────────────────────────────────────
    // 14-UI-SPEC.md's Spacing Scale explicitly carves dial arc radius/
    // stroke width out of the 4px grid as dial-specific render-gate
    // discretion — these are a starting point to be judged at the render
    // gate, not a locked value. Round 2 (render-gate feedback: "the fit is
    // wrong, half of the panel is empty") grows both from round 1's
    // 176/14 — the sanctioned adjustment knob D-06 names for exactly this
    // complaint, rather than tightening the spacing scale itself.
    readonly property int dialDiameter: 224
    readonly property real dialRingThickness: 18

    // Network rate row — width reserved by MEASUREMENT, not hope. The
    // widest realistic rate string at this formatter's own unit stepping
    // (see SystemResources.formatRate: B/s, KB/s, MB/s, GB/s, one decimal).
    readonly property string worstCaseRateText: "999.9 MB/s"
    TextMetrics {
        id: rateMetrics
        font.pixelSize: root.fontBody
        font.weight: root.weightBody
        text: root.worstCaseRateText
    }
    readonly property real rateCellWidth: Math.ceil(rateMetrics.advanceWidth) + root.iconSizeMd + root.spacingXs

    // Natural content size (D-04 reversed, see header) — the outer frame
    // target Dashboard.qml animates to, independent of whatever size this
    // item is actually filling right now. Deliberately bound to `dialGrid`'s
    // OWN natural width/height below, never to `contentColumn`'s actual
    // rendered width — see the round-3 note on `contentColumn` for why.
    implicitWidth: dialGrid.width + root.spacingLg * 2
    implicitHeight: dialGridRow.height + root.spacingLg + networkRowWrap.height + root.spacingLg * 2

    // Round 3 (render-gate defect A: "crammed to the left side, leaving a
    // lot of empty space to the right"). Root cause: `Dashboard.qml`'s
    // `drawerMinWidth` floor (760) reserves room for the 4-tab header and is
    // wider than this tab's own natural content (~560px at the current dial
    // diameter) — so the frame is CORRECTLY wider than the grid needs, and
    // the fix is to center this tab's own content within that width, not to
    // request less of it. A `Column` pins every child's `x` at 0 itself
    // (positioners manage position directly; anchoring a DIRECT Column
    // child conflicts with that and QML warns/refuses it), which is why the
    // grid and the rate row previously sat flush left no matter how wide
    // the frame actually was. This is now a plain `Item` with each section
    // wrapped one level down so IT can anchor-center within the wrapper —
    // and the wrapper's `width` is `parent.width` (this tab's ACTUAL
    // current rendered width, i.e. the frame Dashboard.qml is currently
    // holding — 760 today, or wider still if the known backward-nav pager
    // bug widens it, per round-3 checkpoint instructions: centered either
    // way, never one-sided dead space).
    //
    // `implicitWidth`/`implicitHeight` above stay bound to `dialGrid`'s own
    // NATURAL size (never to a wrapper's frame-derived `width`) precisely
    // because they feed Dashboard.qml's fit-to-content sizing — binding a
    // section's width back to the frame's own current width would
    // reintroduce round 2's self-referential "frame can never shrink to its
    // content" loop that the `dialGrid.width` fix (below, on `networkRow`)
    // already broke once.
    Item {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: root.spacingLg

        // ── Section one — the dial grid ─────────────────────────────────
        Item {
            id: dialGridRow
            anchors.top: parent.top
            width: parent.width
            height: dialGrid.height

            Grid {
                id: dialGrid
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 2
                // Round 2: spacingMd rather than spacingLg between the four
                // dials — a denser cluster (still an already-named scale
                // value, not an invented one) offsetting the diameter
                // growth above, per the Caelestia reference's compact-
                // gauge-cluster composition.
                rowSpacing: root.spacingMd
                columnSpacing: root.spacingMd

                // Each dial's ring/centre-figure/caption-icon carries a
                // DIFFERENT Material role, sourced from the live theme via
                // `Colours` (never a literal) — round 2's "rings should be
                // different colors... to add more life" feedback. Four
                // rings, four of `Colours`' non-neutral roles: primary/
                // secondary/tertiary/error are the only four this token set
                // defines, so battery — the one dial this machine can never
                // show populated — takes the fourth (`error`; thematically
                // apt for a discharge-state readout, and re-tunable in one
                // line if the gate objects).
                Dial {
                    id: cpuDial
                    diameter: root.dialDiameter
                    ringThickness: root.dialRingThickness
                    label: "CPU"
                    icon: "memory"
                    accentColor: Colours.primary
                    widgetState: root.hasReader ? root.systemResources.cpuState : "pending"
                    value: root.hasReader ? root.systemResources.cpuFraction : 0
                    valueText: root.hasReader ? root.systemResources.formatPercent(root.systemResources.cpuFraction) : ""
                    // Round 2 detail: temperature (k10temp, discovered once)
                    // and current frequency (cpu0's cpufreq, a fixed path),
                    // joined only from whichever resolved — neither is load-
                    // bearing for the dial's own populated/empty state.
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
                    emptySymbol: "help"
                    emptyText: "Unavailable"
                }

            Dial {
                id: memoryDial
                diameter: root.dialDiameter
                ringThickness: root.dialRingThickness
                label: "Memory"
                icon: "developer_board"
                accentColor: Colours.secondary
                widgetState: root.hasReader ? root.systemResources.memoryState : "pending"
                value: root.hasReader ? root.systemResources.memoryFraction : 0
                valueText: root.hasReader ? root.systemResources.formatPercent(root.systemResources.memoryFraction) : ""
                detailText: root.hasReader
                    ? (root.systemResources.formatBytes(root.systemResources.memoryUsedBytes) + " / "
                        + root.systemResources.formatBytes(root.systemResources.memoryTotalBytes))
                    : ""
                emptySymbol: "help"
                emptyText: "Unavailable"
            }

            Dial {
                id: storageDial
                diameter: root.dialDiameter
                ringThickness: root.dialRingThickness
                label: "Storage"
                icon: "storage"
                accentColor: Colours.tertiary
                widgetState: root.hasReader ? root.systemResources.storageState : "pending"
                value: root.hasReader ? root.systemResources.storageFraction : 0
                valueText: root.hasReader ? root.systemResources.formatPercent(root.systemResources.storageFraction) : ""
                detailText: root.hasReader
                    ? (root.systemResources.formatBytes(root.systemResources.storageUsedBytes) + " / "
                        + root.systemResources.formatBytes(root.systemResources.storageTotalBytes))
                    : ""
                emptySymbol: "help"
                emptyText: "Unavailable"
            }

            // Battery — on this machine there is no battery hardware, so
            // this dial's empty branch is what actually renders, at the
            // same footprint as the other three. That combination IS this
            // tab's partial state (14-UI-SPEC.md), not a degraded tab. The
            // populated path was separately proven under fault injection
            // at the reader's `batterySource` seam (see 14-06-SUMMARY.md).
            Dial {
                id: batteryDial
                diameter: root.dialDiameter
                ringThickness: root.dialRingThickness
                label: "Battery"
                icon: "battery_full"
                accentColor: Colours.error
                widgetState: root.hasReader ? root.systemResources.batteryState : "pending"
                value: root.hasReader ? root.systemResources.batteryFraction : 0
                valueText: root.hasReader ? root.systemResources.formatPercent(root.systemResources.batteryFraction) : ""
                detailText: root.hasReader ? root.systemResources.batteryStateText : ""
                emptySymbol: "battery_unknown"
                emptyText: "No battery"
            }
            } // dialGrid

        } // dialGridRow

        // ── Section two — the honest network up/down rate row ───────────
        // D-36 is explicit that a rate is not a percentage: two labelled
        // readouts, not a fifth dial and not a normalised bar.
        //
        // Round 3 (defect A, continued): wrapped in `networkRowWrap`, whose
        // `width` is `parent.width` (this tab's ACTUAL current rendered
        // width) purely so `networkRow` itself — still sized off
        // `dialGrid.width`, the round-2 fix, unchanged — can anchor-center
        // within it rather than sit flush left. Same split as
        // `dialGridRow`/`dialGrid` above: the wrapper carries the frame-
        // derived width for centering, the inner item keeps the natural,
        // content-derived width the round-2 fix already established.
        Item {
            id: networkRowWrap
            anchors.top: dialGridRow.bottom
            anchors.topMargin: root.spacingLg
            width: parent.width
            height: networkRow.height

            Item {
            id: networkRow
            anchors.horizontalCenter: parent.horizontalCenter
            // Round 2 fix (the real root cause behind "half the panel is
            // empty"): this was `width: contentColumn.width` — but
            // `contentColumn` anchors.fill's `root`, so that bound back to
            // WHATEVER width the pager frame already happened to be (the
            // PREVIOUS tab's width, since Dashboard.qml sizes the frame
            // FROM this tab's own implicitWidth, which in turn was reading
            // this same value back out of the current frame). A self-
            // referential echo, not a real measurement — Performance's
            // frame width could never actually shrink to its own content.
            // `dialGrid.width` is the real, deterministic natural width of
            // this tab's widest row (purely a function of `dialDiameter`/
            // `columnSpacing`, never of the frame's own current size), so
            // binding here instead breaks the loop and lets the frame
            // genuinely fit the dial grid.
            width: dialGrid.width
            height: Math.max(downloadCell.height, uploadCell.height)

            Column {
                id: downloadCell
                width: root.rateCellWidth
                spacing: root.spacingXs

                Row {
                    id: downloadValueRow
                    spacing: root.spacingXs

                    Text {
                        width: root.iconSizeMd
                        horizontalAlignment: Text.AlignHCenter
                        text: "arrow_downward"
                        font.family: root.symbolFontFamily
                        font.pixelSize: root.iconSizeMd
                        // Round 2: distinct from both the CPU dial's
                        // primary ring and the upload arrow below it, so
                        // the rate row reads as its own coloured accent
                        // rather than a re-use of the dial grid's palette.
                        color: Colours.tertiary
                    }

                    // Fixed-width, right-aligned: the row must not reflow
                    // as the numbers change magnitude (backstop, 14-UI-
                    // SPEC.md's long-text row) — the render gate confirms
                    // this holds across an idle reading and a sustained
                    // transfer.
                    Text {
                        width: root.rateCellWidth - root.iconSizeMd - root.spacingXs
                        horizontalAlignment: Text.AlignRight
                        text: root.hasReader
                            ? root.systemResources.formatRate(root.systemResources.netRxRate)
                            : "—"
                        font.pixelSize: root.fontBody
                        font.weight: root.weightBody
                        color: Colours.onSurface
                    }
                }

                Text {
                    text: "Download"
                    font.pixelSize: root.fontLabel
                    font.weight: root.weightBody
                    color: Colours.onSurfaceVariant
                }
            }

            Column {
                id: uploadCell
                anchors.left: downloadCell.right
                anchors.leftMargin: root.spacingMd
                width: root.rateCellWidth
                spacing: root.spacingXs

                Row {
                    spacing: root.spacingXs

                    Text {
                        width: root.iconSizeMd
                        horizontalAlignment: Text.AlignHCenter
                        text: "arrow_upward"
                        font.family: root.symbolFontFamily
                        font.pixelSize: root.iconSizeMd
                        color: Colours.secondary
                    }

                    Text {
                        width: root.rateCellWidth - root.iconSizeMd - root.spacingXs
                        horizontalAlignment: Text.AlignRight
                        text: root.hasReader
                            ? root.systemResources.formatRate(root.systemResources.netTxRate)
                            : "—"
                        font.pixelSize: root.fontBody
                        font.weight: root.weightBody
                        color: Colours.onSurface
                    }
                }

                Text {
                    text: "Upload"
                    font.pixelSize: root.fontLabel
                    font.weight: root.weightBody
                    color: Colours.onSurfaceVariant
                }
            }
            } // networkRow
        } // networkRowWrap
    }
}
