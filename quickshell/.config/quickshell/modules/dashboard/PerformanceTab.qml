// PerformanceTab.qml — tab 2, filled (Phase 14 Plan 06, D-36, DASH-05),
// grown to five (14-10 Task 2, DASH-09): one row of five MD3 circular
// dials (CPU, Memory, Storage, Battery, GPU) plus an honest network
// up/down rate row — a rate is not a percentage, so it stays two labelled
// readouts, never a sixth dial and never a normalised bar.
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
    //
    // ── 14-09 Task 4 UPDATE (render-gate change request: "shorter and
    //    wider, rings adjusted accordingly") ─────────────────────────────
    // One row of four dials, not a 2x2 grid — see `dialGrid`'s `columns`
    // below. `dialGrid.width` = 224*4 + spacingMd*3 = 944 — this tab's own
    // `implicitWidth` (dialGrid.width + spacingLg*2) is 992, but the LIVE
    // drawer width measures 1040, not 992: `Dashboard.qml`'s own
    // `drawerWidth = activeContentWidth + spacingLg*2` adds the WINDOW's
    // outer chrome margin on top of this tab's own already-self-padded
    // `implicitWidth` — by design (see that file's own header comment: the
    // outer `content` item's margin is "added back on top of the active
    // tab's own desired content size"), not a bug this task introduced.
    // This plan's own predicted "992/38.8%" arithmetic missed that second
    // layer; the actual measured 1040/2560 = 40.6% lands EVEN CLOSER to
    // D-02's original ~40% intent than the prediction did.
    //
    // ── 14-10 Task 2 UPDATE (a fifth dial: GPU usage, DASH-09) ───────────
    // Five dials in one row now, not four — see `dialGrid`'s `columns`
    // below. The human's own instruction was that the width must not
    // increase, so the diameter is retuned down rather than the row simply
    // growing: `deferred-items.md`'s carried-forward arithmetic (5d +
    // 4*spacingMd = 944, the exact content width the four 224px dials
    // already produced) closes at d=176, with ring thickness scaled down
    // proportionally from 14-09's 22: 22 * (176/224) ~= 17. Both numbers
    // are the carried-forward starting point, not re-derived here. The
    // live drawer width (1040, per 14-09 Task 4's own finding about
    // `Dashboard.qml`'s extra outer-chrome layer) is therefore UNCHANGED by
    // this task — only the Performance frame's HEIGHT is expected to
    // shrink, since the dial row's own footprint got shorter; see
    // 14-10-SUMMARY.md for the measured live number.
    readonly property int dialDiameter: 176
    readonly property real dialRingThickness: 17

    // ── D-41 OVERTURNED FOR BATTERY ONLY (operator, 2026-08-26) ─────────
    // This file's own header and 14-10's arithmetic both assume five dials
    // always render, because D-41 said a slot is shown at a fixed footprint
    // regardless of system state. For battery that is now reversed: with no
    // battery hardware the dial is not drawn and the row closes up to four.
    // Every other dial still honours D-41 — GPU in particular still renders
    // its own empty state rather than vanishing.
    //
    // "Not populated" is deliberately NOT the test: a battery that exists
    // but has not been read yet is `pending`, and hiding the dial on the
    // first poll then springing it back would be the very layout jump D-41
    // exists to prevent. Only an affirmative `empty` (no such device)
    // removes it.
    readonly property bool batteryPresent: !root.hasReader
        || root.systemResources.batteryState !== "empty"

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
                // 14-10 Task 2: one row of five, not four — see
                // `dialDiameter`'s own header note above for the width
                // arithmetic this converges on.
                // Follows the dial count, so dropping battery re-centres the
                // row instead of leaving a 176px hole on the right.
                columns: root.batteryPresent ? 5 : 4
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
                //
                // 14-10 Task 2: the fifth dial (GPU) has no unused non-
                // neutral role left to take. The plan's own recorded DEFAULT
                // choice was `primaryContainer` (a real contract role,
                // currently unused on this tab), with a recorded alternative
                // — share `primary` with CPU, the two compute dials — if it
                // read washed out as a ring stroke. It did, and more than
                // "washed out": live-read against the running theme's own
                // `palette.json`, `primaryContainer` (#44475a) is BYTE-
                // IDENTICAL to `Colours.surfaceVariant` (#44475a), the
                // track colour every dial's UNFILLED arc already uses — so
                // the value arc was not merely subdued, it was invisible
                // against its own track. Confirmed live via screenshot
                // before landing on the alternative (see 14-10-SUMMARY.md).
                // Taking the recorded alternative: GPU shares `primary`
                // with CPU.
                // GPU — DASH-09 (14-10 Task 2). ALWAYS present, exactly like
                // the battery dial below: on a machine with no NVIDIA adapter
                // (or with the query binary absent, or reporting no devices,
                // or exiting non-zero — all three land in the same reader-side
                // `gpuState: "empty"`) this dial's empty branch is what renders,
                // at the identical footprint the other four occupy. The five-
                // across geometry and the 1040px frame are therefore never a
                // function of GPU hardware (D-41). Identity icon `desktop_windows`
                // and empty-state icon `desktop_access_disabled` were each
                // confirmed rendering as real glyphs (not missing-glyph boxes)
                // before this dial was written — see 14-10-SUMMARY.md — and
                // `desktop_windows` matches the reference shell's own GPU-tile
                // icon (Caelestia's `Performance.qml`, `gpuCard`).
                //
                // 14-10 Task 4 (render gate): the human set this row's order
                // explicitly — GPU, CPU, Memory, Storage, Battery — so GPU
                // leads. `Grid` lays out in declaration order, so this block's
                // POSITION in the file IS the rendered order; moving a dial
                // means moving its block, nothing else.
                Dial {
                    id: gpuDial
                    diameter: root.dialDiameter
                    ringThickness: root.dialRingThickness
                    label: "GPU"
                    icon: "desktop_windows"
                    accentColor: Colours.outline
                    widgetState: root.hasReader ? root.systemResources.gpuState : "pending"
                    value: root.hasReader ? root.systemResources.gpuFraction : 0
                    valueText: root.hasReader ? root.systemResources.formatPercent(root.systemResources.gpuFraction) : ""
                    detailText: root.hasReader
                        ? (root.systemResources.formatBytes(root.systemResources.gpuUsedBytes) + " / "
                            + root.systemResources.formatBytes(root.systemResources.gpuTotalBytes))
                        : ""
                    emptySymbol: "desktop_access_disabled"
                    emptyText: "No GPU"
                }

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
                // D-41 overturned for battery only — see `batteryPresent`.
                visible: root.batteryPresent
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

            // 14-10 Task 4 (render gate): the human asked for the rate pair to
            // be centred and widened into the empty space this row used to
            // leave. Previously both cells sat flush-left at their MEASURED
            // MINIMUM (`rateCellWidth`, ~150px each), so the pair occupied
            // roughly a third of the 944px row and the rest was dead space.
            // Now the row splits into two equal halves that together span the
            // full dial-grid width, each with its readout centred inside its
            // own half — the pair reads as centred AND the space is consumed.
            //
            // The inner value `Text` keeps its FIXED `rateCellWidth`-derived
            // width, so round 2's anti-reflow guarantee (the row must not
            // shift as magnitudes change) is preserved exactly — the readout
            // is re-centred, never re-measured. Each cell is an `Item` rather
            // than a bare `Column` precisely so its content CAN be
            // anchor-centred: a `Column` is a positioner and manages its own
            // children's `x` directly, so anchoring inside one is the very
            // conflict this file's `contentColumn` note already documents.
            Item {
                id: downloadCell
                anchors.left: parent.left
                width: (dialGrid.width - root.spacingMd) / 2
                height: downloadColumn.height

                Column {
                id: downloadColumn
                anchors.horizontalCenter: parent.horizontalCenter
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
                } // downloadColumn
            }

            Item {
                id: uploadCell
                anchors.left: downloadCell.right
                anchors.leftMargin: root.spacingMd
                width: (dialGrid.width - root.spacingMd) / 2
                height: uploadColumn.height

                Column {
                id: uploadColumn
                anchors.horizontalCenter: parent.horizontalCenter
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
                } // uploadColumn
            }
            } // networkRow
        } // networkRowWrap
    }
}
