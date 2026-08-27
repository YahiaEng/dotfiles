// PerformanceTab.qml — Performance tab layout "dials", and as of quick task
// 260827-50i that means plate **P4 "Tighten What's There"** from
// `.planning/notes/dashboard-perf-studies.html`, NOT the original five-dial
// row it used to be.
//
// ── WHAT CHANGED, and why this is an edit rather than a new file ────────
// The study frames P4 as "the cheap option, included so the others have a
// floor": same parts, retuned. Its whole cost note is "a handful of
// constants… no new roles, no plugin". So it is implemented as a
// transformation of this file rather than as a fifth sibling — writing
// `PerfTight.qml` beside this one would have left the original selectable,
// which is exactly what the operator asked to stop.
//
// The three changes the plate specifies:
//   1. The battery DIAL is gone. It was a 176px slot that on this machine
//      could only ever render "No battery"; battery is now a status line
//      under the network card. This is the D-41 overturn of 2026-08-26
//      applied to the layout that motivated it.
//   2. Dials shrink 176 → 128 and the ring with them, 17 → 13.
//   3. The tab settles at the NARROW family's 712 of content, so the drawer
//      lands at 808 and crossing between tabs stops animating the window
//      280px wider and back. The rate pair stops floating and gets a card.
//
// ── One deliberate departure from the plate's drawing ──────────────────
// The study draws the dials CPU-first and draws the battery line even with
// no battery ("No battery on this host"). Neither is followed here, and both
// for the same reason: a later operator decision outranks the drawing.
//   • Dial ORDER stays GPU, CPU, Memory, Storage — set explicitly by the
//     operator at 14-10 Task 4's render gate. The plate's own "Change" list
//     says nothing about order, so there is no reason to overturn it.
//   • The battery LINE is hidden when no battery is detected, matching
//     `PerfTelemetry`/`PerfArcs`. The 2026-08-26 ruling was "hide it when
//     none is detected", and it postdates the study.
//
// ── Historical, from when this file WAS the five-dial row ──────────────
// Originally: tab 2, filled (Phase 14 Plan 06, D-36, DASH-05), grown to five
// (14-10 Task 2, DASH-09) — one row of five MD3 circular dials (CPU, Memory,
// Storage, Battery, GPU) plus an honest network up/down rate row. A rate is
// not a percentage, so it stays two labelled readouts, never another dial
// and never a normalised bar — that part is unchanged, it just sits in a
// card now.
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
    // 260827-50i: the battery band joins only when it actually renders — a
    // hidden band would burn a stagger step on nothing.
    readonly property var cascadeBands: root.batteryPresent
        ? [dialGridRow, networkRowWrap, batteryLine]
        : [dialGridRow, networkRowWrap]

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
    //
    // ── 260827-50i UPDATE (plate P4) — everything above is now historical
    // The arithmetic above solved for "five dials at a fixed 944 width".
    // P4 drops the battery dial and shrinks the rest, so neither the count
    // nor the 944 survives: FOUR dials at 128 with spacingMd between them is
    // 128*4 + 16*3 = 560, which sits inside the narrow family's 712 rather
    // than defining the width itself. The ring thickness follows the
    // diameter proportionally, exactly as 14-10 scaled it before:
    // 17 * (128/176) ≈ 12.4, and the study's own plate draws 13.
    readonly property int dialDiameter: 128
    readonly property real dialRingThickness: 13

    // ── Frame width: NARROW family, 712 of content, drawer lands at 808 ──
    // This is the plate's headline fix. The width used to be whatever
    // `dialGrid` happened to measure (944 with five 176px dials), which is
    // why crossing between Dashboard and Performance animated the window
    // 280px wider and back on EVERY tab change.
    //
    // Declaring the same 712 that `DashLanes`, `PerfTelemetry` and
    // `PerfArcs` declare removes that entirely. Do not "tidy" this back to a
    // content-derived width, and do not change it in one file only — the
    // narrow family is only a family while all four agree.
    //
    // The dial row (560) is now NARROWER than the frame and centres within
    // it, which is what `dialGridRow`'s wrapper already existed to do.
    readonly property int contentWidth: 712

    // The rate card's own width, from the plate (544 inside its 712). Kept
    // narrower than the frame on purpose: a full-width card for two figures
    // reads as a band across the tab rather than as a card.
    readonly property int rateCardWidth: 544

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
    implicitWidth: root.contentWidth + root.spacingLg * 2
    implicitHeight: dialGridRow.height + root.spacingLg + networkRowWrap.height
        + (root.batteryPresent ? root.spacingMd + batteryLine.height : 0)
        + root.spacingLg * 2

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
                // 260827-50i (plate P4): a flat 4, no longer conditional on
                // battery. The battery dial is gone from this row entirely —
                // it is a status line under the rate card now — so there is
                // no fifth cell whose presence the column count has to
                // track. GPU, CPU, Memory, Storage.
                columns: 4
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

            // 260827-50i (plate P4): the battery Dial that stood here is
            // GONE, not merely hidden. It occupied a full dial slot to say
            // "No battery" on a machine that will never have one — the exact
            // waste the plate's "Change" note names first. Battery is a
            // status line under the rate card now; see `batteryLine`.
            //
            // The populated path this dial used to carry was separately
            // proven under fault injection at the reader's `batterySource`
            // seam (14-06-SUMMARY.md), and that proof still stands — the
            // reading is unchanged, only its presentation moved.
            } // dialGrid

        } // dialGridRow

        // ── Section two — the network rate pair, in a card ─────────────
        // D-36 is explicit that a rate is not a percentage: two labelled
        // readouts, not another dial and not a normalised bar. That part is
        // unchanged from the five-dial era.
        //
        // 260827-50i (plate P4): what changed is that the pair used to FLOAT
        // — two columns centred over dead space, sized off `dialGrid.width`.
        // The plate gives it a card at a fixed 544, so the two figures read
        // as one grouped readout instead of two orphans, and the row stops
        // being a function of the dial grid's width.
        //
        // The wrapper/inner split is kept: the wrapper carries the frame-
        // derived width so the card can anchor-centre within whatever the
        // frame currently is, and the card carries its own fixed natural
        // width. Binding the card's width back to the frame would reintroduce
        // round 2's self-referential "frame can never shrink to its content"
        // loop, which is documented at length on `contentColumn` above.
        Item {
            id: networkRowWrap
            anchors.top: dialGridRow.bottom
            anchors.topMargin: root.spacingLg
            width: parent.width
            height: rateCard.height

            Rectangle {
                id: rateCard
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.rateCardWidth
                height: rateRow.height + root.spacingMd * 2
                radius: Design.roundingSm
                color: Colours.surfaceVariant

                Row {
                    id: rateRow
                    anchors.centerIn: parent
                    spacing: root.spacingMd

                    RateCell {
                        width: (rateCard.width - root.spacingMd * 4 - 1) / 2
                        symbol: "arrow_downward"
                        accent: Colours.tertiary
                        caption: "Download"
                        value_: root.hasReader
                            ? root.systemResources.formatRate(root.systemResources.netRxRate)
                            : "\u2014"
                    }

                    // A hairline divider, the plate's own separator between
                    // the two directions. Alpha over onSurface rather than a
                    // palette role: this card's fill already IS
                    // surfaceVariant, and a rule drawn in a role identical to
                    // its backing surface renders invisible — proven live in
                    // 14-10 and hit twice more since.
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: root.iconSizeMd
                        color: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.14)
                    }

                    RateCell {
                        width: (rateCard.width - root.spacingMd * 4 - 1) / 2
                        symbol: "arrow_upward"
                        accent: Colours.secondary
                        caption: "Upload"
                        value_: root.hasReader
                            ? root.systemResources.formatRate(root.systemResources.netTxRate)
                            : "\u2014"
                    }
                }
            }
        } // networkRowWrap

        // ── Section three — battery, as a status line ───────────────────
        // 260827-50i (plate P4): what is left of the retired battery dial.
        //
        // The plate DRAWS this line even with no battery ("No battery on
        // this host"), but the operator's 2026-08-26 ruling — the same one
        // that authorised retiring the dial — was "hide it when none is
        // detected", and it postdates the study. So the line follows
        // `PerfTelemetry`/`PerfArcs` and disappears entirely.
        //
        // The absence test is the reader's affirmative `empty`, never merely
        // "not populated": a battery that exists but has not been read yet is
        // `pending`, and hiding the line on the first poll then springing it
        // back would be exactly the jump D-41 exists to prevent.
        Row {
            id: batteryLine
            anchors.top: networkRowWrap.bottom
            anchors.topMargin: root.spacingMd
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.spacingXs
            visible: root.batteryPresent

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
                    // The "no battery" copy went with the dial; what remains
                    // is the pre-first-read window.
                    if (root.systemResources.batteryState !== "populated")
                        return "Battery reading\u2026";
                    return root.systemResources.formatPercent(root.systemResources.batteryFraction)
                        + " \u00b7 " + root.systemResources.batteryStateText;
                }
                font.pixelSize: root.fontLabel
                font.weight: root.weightBody
                color: Colours.onSurfaceVariant
            }
        }
    }

    // ── One direction of the rate pair ─────────────────────────────────
    // An Item, not a bare Column: a Column is a positioner that manages its
    // children's `x` directly, so anchoring inside one is the exact conflict
    // `contentColumn`'s own note documents.
    component RateCell: Item {
        id: rc

        required property string symbol
        required property color accent
        required property string caption
        required property string value_

        implicitHeight: rcColumn.height
        height: implicitHeight

        Column {
            id: rcColumn
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.spacingXs

            Row {
                spacing: root.spacingXs

                Text {
                    width: root.iconSizeMd
                    horizontalAlignment: Text.AlignHCenter
                    text: rc.symbol
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.iconSizeMd
                    color: rc.accent
                }

                // Fixed-width, right-aligned: the row must not reflow as the
                // numbers change magnitude (14-UI-SPEC.md's long-text row).
                // `rateCellWidth` is MEASURED off the widest realistic rate
                // string via TextMetrics, never guessed — carried across from
                // the five-dial layout unchanged.
                Text {
                    width: root.rateCellWidth - root.iconSizeMd - root.spacingXs
                    horizontalAlignment: Text.AlignRight
                    text: rc.value_
                    font.pixelSize: root.fontBody
                    font.weight: root.weightBody
                    color: Colours.onSurface
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: rc.caption
                font.pixelSize: root.fontLabel
                font.weight: root.weightBody
                color: Colours.onSurfaceVariant
            }
        }
    }
}
