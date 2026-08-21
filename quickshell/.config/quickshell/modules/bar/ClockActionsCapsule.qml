// ClockActionsCapsule.qml — the clock + actions slot (Phase 18 Plan 05,
// D-18-10).
//
// Owner: 18-11 for the four action entries (`gaming`, `notifications`,
// `settings`, `power`) — the two athena drawers plus three of the four
// permanent extras. The fourth, `idleInhibitor`, relocated to its own
// centre-zone capsule under the GATE-02 fix; see note (a) below.
//
// This one is NOT empty: 18-01's live clock moves here intact, carried
// exactly rather than rebuilt — see the SystemClock declaration below.
//
// ── 18-11 fills the rest of this capsule. Three facts a later reader
//    would otherwise re-litigate: ────────────────────────────────────
// (a) The four action entries below are three of D-18-03's four permanent
//     extras (power, gaming, notifications) plus the settings-drawer
//     trigger. The fourth extra, the idle inhibitor, relocated to its own
//     centre-zone capsule (IdleInhibitorCapsule.qml) under the GATE-02
//     upstream-parity fix — upstream Athena places it in modules-center,
//     immediately right of workspaces (ATHENA-UPSTREAM-SPEC.md), not
//     beside clock/settings on the right. The bulb's backend (the
//     `IdleInhibitor` element and `idleInhibited` property) moved with it;
//     nothing of it remains in this file. The other extra pair's half —
//     the updates count — still lives in the system capsule (18-08),
//     because 18-05's entry list split that pair by kind (readout vs
//     action), not by pairing.
// (b) The notification binding is deliberately temporary and is sealed
//     behind one named component (`NotificationSource` below) so that
//     Phase 19 replaces a backend rather than re-opening a layout that
//     has already passed a render gate.
// (c) This capsule adds exactly one permanent child process to a surface
//     that never unmounts — the notification subscription inside
//     `NotificationSource` — named in source as a charge against QBAR-11
//     that ends when that swap lands.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"
import "../dashboard"
import "../notifications"

BarCapsule {
    id: clockActionsCapsule
    capsuleId: "clockActions"

    // Uniform right-side pitch. Every cell here already carries cellPitch's
    // own spacingXs padding on each side, so a contentGap of spacingSm (8)
    // renders a 16px glyph-to-glyph gap — the SAME 16px barCapsuleGap puts
    // between two capsules, which is what makes the whole right side read as
    // one evenly-spaced row instead of tight clusters with wide seams.
    //
    // spacingXs (4) was tried first, to mirror upstream's `margin: 4px 2px` on
    // these glyphs literally. That is correct upstream, where each glyph is its
    // own module inside a surfaced group; here the capsule is bare and its
    // neighbours sit 16px away, so a 4px internal gap made the actions clump.
    // The operator reported the result as unevenly spaced.
    contentGap: Design.spacingSm

    readonly property string homeDir: Quickshell.env("HOME")

    // 14-02's recorded per-file capability flag — Design.qml's own header
    // note records this is deliberately not a shared token, since it is a
    // claim about the font build rather than a design token.
    readonly property bool fillAxisAvailable: true

    // Event-driven clock, deliberately NOT a repeating Timer: this
    // surface never unmounts, so a 1Hz (or any repeating) Timer would be
    // a permanent session cost for a value that changes once a minute.
    // SystemClock at Minutes precision wakes exactly once per minute —
    // 18-01's own permanent-liveness discipline, carried unchanged across
    // this move.
    SystemClock {
        id: barClock
        enabled: true
        precision: SystemClock.Minutes
    }

    // ── Popout wrapper (Phase 18 Plan 14, QBAR-09) — named seam into this
    //    18-11-owned file. Ownership split, stated so it is never
    //    discovered at merge time: 18-11 owns the clock cell's own two
    //    Text elements below, unchanged in content and appearance; this
    //    plan owns only the PopoutTrigger wrapper around them and the
    //    nested Grid that reproduces the outer positioner's own spacing so
    //    wrapping the pair changes nothing about the rendered bar. Change
    //    nothing else: not the gaming, notification, settings or power
    //    cells, not the settings drawer, not the entry order, not the
    //    notification source component. ─────────────────────────────────
    PopoutTrigger {
        id: clockPopoutTrigger
        // Operator fix wave finding 3 — per-entry hiding, one resolution
        // point (BarEntryModel.entryVisible()). This item is a top-level
        // sibling reparented into BarCapsule's own shared content Grid
        // (the "one positioner" the assembly comment above names), which
        // already excludes an invisible child from layout for free —
        // SystemCapsule.qml's gpu/updates entries already rely on the
        // identical mechanism.
        visible: BarEntryModel.entryVisible("clock")
        sectionId: "clock"
        popoutComponent: Component {
            ClockPopout {
                currentDate: barClock.date
            }
        }

        // Athena's filled `secondary`-hued clock pill (D-13,
        // theme.scss:127-145's "filled, but fewer" trio — clock, updates,
        // notification). Declared BEFORE clockTriggerGrid so it renders
        // behind the clock's own two Text elements by declaration order,
        // with no MouseArea/HoverHandler of its own — it must never
        // become a hit target, since the clock popout trigger's own
        // click/hover contract lives on clockPopoutTrigger, not on this
        // fill. Deliberately a SIBLING of clockTriggerGrid (both direct
        // children of contentHost, a plain Item, not a Positioner) rather
        // than nested inside the Grid itself — a Grid positioner forbids
        // anchors on its own direct children ("Cannot specify anchors
        // for items inside Grid", caught live in plan 18.1-02). Grid
        // (a Positioner) auto-sizes its own width/height to its content,
        // so anchoring to clockTriggerGrid's real width/height here is
        // safe.
        Rectangle {
            id: clockFillPill
            // MEASURED 2026-08-12: centring on clockTriggerGrid put this pill at
            // x=8.0 y=1176.0 (39.1x90) inside a cell at x=2.0 y=1182.0 — offset
            // +6/-6, so it reached x=47.1 past the 44px column and started 6px
            // above the capsule's own top edge. The grid sits 6px right of the
            // cell's centre, so centring on the grid centres on the wrong thing.
            // In vertical, centre on the CELL (this item's parent), which the
            // trigger already sizes to the pill. Both branches name a real
            // object — never `undefined`, which does not clear an anchor.
            // KNOWN RESIDUAL (2026-08-12): in vertical this pill measured x=8.0
            // y=1176.0 (39.1x90) inside a cell at x=2.0 y=1182.0 — offset +6/-6,
            // reaching x=47.1 past the 44px column and 6px above the capsule's top.
            // Centring on `parent` instead FIXED the geometry (measured x=2.0
            // y=1182.0) but introduced "Binding loop detected for property
            // implicitWidth/implicitHeight" at PopoutTrigger.qml[40]: the trigger
            // sizes itself from childrenRect, so a child centred on it makes each
            // depend on the other. Reverted — a loop is worse than the overhang.
            // The fix needs the cell to reserve the pill's padding explicitly
            // rather than inferring its size from the pill.
            anchors.centerIn: clockTriggerGrid
            // Upstream Athena states #clock as PADDING around its text
            // (`padding: 6px 10px 6px 16px`), not as a fixed height, so this
            // derives the same way: content + barCapsulePadding (6) per side.
            //
            // Two earlier shapes were wrong and are recorded so neither is
            // retried: `grid.height + spacingSm * 2` came to ~33px inside a
            // 22px content area and overflowed to the bar's bottom edge (the
            // operator's "the time pill looks out of position"); pinning to
            // barCapsuleHeight (34) then sat flush against that edge with no
            // wallpaper gap and still read as cut off. Deriving from padding
            // leaves the 4px gap Athena's own `margin: 4px 5px` produces.
            // Now that this capsule is unsurfaced, this pill IS the visible
            // module, exactly as upstream's #clock is.
            // spacingLg (24) of horizontal padding, i.e. 12 per side. Athena's
            // #clock carries `padding: 6px 10px 6px 16px` — 26 total — and 24 is
            // the nearest value on the repo's 4px grid. This was spacingMd (16,
            // i.e. 8 per side), which hugged the text and is what the operator
            // reported as the clock pill looking compressed.
            // Horizontal keeps spacingLg (24). VERTICAL cannot afford it:
            // MEASURED 2026-08-12, the pill came to 51.1px against a
            // barColumnWidth of 44 — and after the time line was narrowed to
            // stacked HH/mm, this pill was the LAST thing overflowing the
            // column, the texts inside it all fitting. The 24 traces to athena's
            // `padding: 6px 10px 6px 16px`, which is a horizontal-strip
            // rationale; a 44px column has no room for 12 per side. Vertical
            // therefore reuses barCapsulePadding, the same token the height
            // already derives from, giving a symmetric inset that fits.
            width: clockTriggerGrid.width + (clockActionsCapsule.vertical ? Design.barCapsulePadding * 2 : Design.spacingLg)
            height: clockTriggerGrid.height + Design.barCapsulePadding * 2
            radius: clockActionsCapsule.vertical ? width / 2 : height / 2
            color: BarRoles.fillClock
            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }
        }

        // Phantom right-side padding — measured necessity, not decoration.
        // The pill above is now flush with both edges of its own cell (see
        // clockTriggerGrid's own comment), so this cell carries ZERO
        // built-in padding, unlike every ActionCell (gamingCell immediately
        // after this trigger included), which reserves spacingXs (4px) on
        // each side inside its cellPitch box. Two glyphs that are BOTH
        // zero-padded (every MediaConnectivityCapsule Readout pair) need
        // only contentGap to reach the shared 16px visible pitch; two that
        // are BOTH 4px-padded (every ActionCell pair) also reach it at the
        // SAME contentGap because their two 4px insets sum to the other
        // capsule's whole difference. This pill-to-ActionCell pair is the
        // one boundary with only ONE side padded, so it undershot the
        // shared pitch by exactly that missing 4px (measured: 12px visible
        // where every other adjacent pair measured 16px). A non-rendering
        // spacer the width of that one missing inset closes it — reserving
        // cell width with no drawn content, exactly like BarCapsule's own
        // `visible` contract excludes an empty entry's spacing with no
        // extra code, this does the inverse: adds spacing with no visible
        // content.
        Item {
            id: clockCellRightPad
            // Plain Item, no delegate of its own — draws nothing regardless
            // of `visible`, so that property is left at its default (true)
            // rather than set false: childrenRect (what sizes this cell) is
            // a geometry aggregate, not a positioner, and this repo has no
            // verified guarantee it excludes invisible children the way a
            // Positioner does — leaving visible untouched removes any doubt
            // this spacer's width reaches childrenRect at all.
            x: clockFillPill.x + clockFillPill.width
            // Zero in vertical: this spacer closes a missing HORIZONTAL inset
            // between the clock pill and the cell to its right. In a column
            // there is no cell to its right — the next capsule is below — so the
            // 4px only widened the clock cell, which measured 55.1 against the
            // pill's own 51.1 and pushed the whole capsule past the 44px column.
            width: clockActionsCapsule.vertical ? 0 : Design.spacingXs
            height: 1
        }

        // Reproduces contentGrid's own spacing/orientation formula exactly
        // (Design.spacingSm), so wrapping these two Text elements in one
        // trigger cell leaves the rendered gap between them, and between
        // this cell and the next, byte-identical to before.
        Grid {
            id: clockTriggerGrid
            // Phase 18.1 spacing-probe task, measured via mapToItem: this
            // Grid sits flush at contentHost's own (0,0) origin by default,
            // but clockFillPill above is centred ON this Grid at a width
            // spacingLg (24) WIDER than it — so with this Grid flush-left,
            // the pill bled spacingLg/2 (12px) out the LEFT edge of its own
            // allocated cell (measured: pill x=2302.6875 against a cell/
            // capsule left edge of 2314.6875) while leaving 12px of dead
            // space unused on the right (measured: pill right edge 2380.0
            // against the cell's own right edge of 2392.0). The left bleed
            // ate directly into the fixed 16px barCapsuleGap before this
            // capsule (leaving only a 4px visible gap to the network glyph);
            // the right dead space widened the gap to the gaming glyph to
            // 20px. This offset re-centres the Grid inside the cell the
            // pill's own width already reserves, so the pill renders flush
            // with both cell edges instead of overflowing one and starving
            // the other — the padding VALUE (spacingLg) is unchanged, only
            // where it is centred from.
            //
            // MEASURED 2026-08-13: this offset must be half the pill's OWN
            // horizontal padding, and that padding is orientation-dependent
            // — clockFillPill.width adds spacingLg (24) in horizontal but
            // barCapsulePadding * 2 (12) in vertical, because a 44px column
            // cannot afford 12 per side. A hardcoded spacingLg/2 (12) is
            // therefore correct in horizontal and twice too large in
            // vertical, which put the pill 6px right of its own cell:
            // measured pill x=10.0 w=35.3 (right 45.3) against a cell at
            // x=4.0 w=35.3 (right 39.3) in a 44px column — clipped by 1.3px
            // at the right edge, and the operator's "the clock pill is not
            // centred, it is clipped to the right side".
            //
            // Deriving the offset from the same branch the pill's own width
            // uses keeps the two in lockstep by construction. This is
            // deliberately NOT the other candidate fix (re-anchoring the
            // pill to centre on `parent` instead of this Grid): that one
            // also lands the geometry, but PopoutTrigger sizes itself from
            // childrenRect, so a child centred on it makes each depend on
            // the other and it was reverted on 2026-08-12 for "Binding loop
            // detected for property implicitWidth/implicitHeight" at
            // PopoutTrigger.qml[40]. Moving the Grid changes no dependency
            // edge at all — the pill still centres on the Grid, the Grid
            // still takes a constant x — so there is no cycle to create.
            x: (clockActionsCapsule.vertical ? Design.barCapsulePadding * 2 : Design.spacingLg) / 2
            // F1 (quick task 260812-69w) — Task 1's Probe A measured this
            // Grid sitting flush at contentHost's own local y=0 by
            // default, while clockFillPill (anchors.centerIn:
            // clockTriggerGrid, barCapsulePadding*2 taller than this Grid)
            // overhangs ABOVE that origin: contentHost.childrenRect.y
            // measured -6. contentHost/triggerRoot's own implicitHeight
            // (28, from childrenRect.height) correctly captures the pill's
            // total SIZE but not that ORIGIN, so BarCapsule's outer Grid
            // (which top-aligns this 28px cell against its 24px
            // (cellPitch) ActionCell siblings — every sibling already
            // vertically self-centres its own glyph at local
            // cellPitch/2=12) rendered the clock's pill+text pair 4px
            // higher than its siblings' content centre (measured: clock
            // content sceneY=15 vs ActionCell content sceneY=19).
            // Re-deriving the whole positioner's alignment mode
            // (BarCapsule.qml's contentGrid) was rejected: a
            // vertical-centre change there would ALSO re-centre every
            // other row containing differing-height children (measured
            // live: workspaces' own row mixes 16/20/22px children), moving
            // capsules the operator never flagged — the acceptance bar
            // requires those to show a delta of exactly 0. The fix
            // therefore stays local: target this Grid's own vertical
            // centre at cellPitch/2 (12), the SAME slot centre every
            // ActionCell already centres its own glyph on, instead of at
            // this cell's own (taller, pill-driven) box centre. Vertical
            // orientation is untouched (0, matching its prior default) —
            // Probe A only measured the horizontal misalignment the
            // operator reported, and this Grid's vertical-mode shape
            // (rows=-1, three stacked lines) is a different geometry this
            // fix must not touch.
            y: clockActionsCapsule.vertical ? 0 : (clockActionsCapsule.cellPitch - clockTriggerGrid.height) / 2
            rows: clockActionsCapsule.vertical ? -1 : 1
            columns: clockActionsCapsule.vertical ? 1 : -1
            spacing: Design.spacingXs
            // MEASURED 2026-08-13: a Grid sizes itself to its widest child and
            // defaults every narrower one to AlignLeft. In vertical this Grid
            // stacks three lines — glyph (w=16.0), time (w=14.8) and the day
            // (the widest, which is where the Grid's own 23.3 comes from) — so
            // glyph and time both sat flush left at x=10.0, centred at 18.0 and
            // 17.4 against the Grid's own centre of 21.6. Off by 3.6 and 4.2.
            //
            // This was present before the pill offset above was corrected, but
            // invisible: the pill was itself 6px right, so the contents looked
            // roughly centred INSIDE it by cancellation. Fixing the pill exposed
            // the real misalignment rather than causing it — the operator's "the
            // time is now centered, but the clock glyph and time inside it are
            // now off-center" is exactly that unmasking.
            //
            // Centring the items is the whole fix: the widest child still sets
            // the Grid's width, and every narrower line now centres on the same
            // axis the pill already centres on.
            horizontalItemAlignment: Grid.AlignHCenter

            // Upstream's clock leads with a glyph:
            // `format: "󰃱 <span size='11pt'>{:%H.%M }</span>"`. Ours had none,
            // which the operator reported directly. Rendered as its own Text in
            // Design.symbolFontFamily rather than by pasting upstream's Nerd
            // Font codepoint into the time string: every other glyph in this
            // file is a Material Symbols ligature, and mixing a second glyph
            // font into one pill would depend on font substitution to line up.
            Text {
                id: clockGlyphText
                text: "schedule"
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.barGlyphSize
                color: BarRoles.fillClockFg
                verticalAlignment: Text.AlignVCenter
                height: Design.barGlyphSize
            }

            // Line 1 in both orientations: the time itself.
            Text {
                id: clockTimeText
                font.pixelSize: Design.barBodySize
                // weightBold — Athena's #clock rule is `font-weight: bold`
                // (CSS 700 = Font.Bold). This was weightBody (Normal) with a
                // comment explaining that no bold token existed; the token now
                // exists (Design.qml), so the comment's premise is gone and the
                // operator's "the font is lighter" is fixed at the source
                // rather than approximated with DemiBold.
                font.weight: Design.weightBold
                color: BarRoles.fillClockFg
                // MEASURED 2026-08-12: "HH:mm" at this size and weight renders
                // 61.3px wide, against a barColumnWidth of 44. The whole
                // capsule's content grid took that width and, being centred in
                // a 44px window, sat at x=-9 — every cell in the capsule spilled
                // past both edges of the bar with clip=false. So in VERTICAL the
                // hours and minutes take their own lines: two glyphs of two
                // digits fit the column with room, and D-18-14's
                // "two-stacked-lines" form is honoured more literally than a
                // single wide HH:mm line ever did.
                text: clockActionsCapsule.vertical
                    ? Qt.formatDateTime(barClock.date, "HH") + "\n" + Qt.formatDateTime(barClock.date, "mm")
                    : Qt.formatDateTime(barClock.date, "HH:mm")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                // Fixed single-line height in horizontal (unchanged); content-sized
                // in vertical, because a two-line string inside a 16px box would
                // clip the minutes away entirely — trading a horizontal overflow
                // for a vertical one.
                //
                // contentHeight, NOT implicitHeight: binding a Text's `height` to
                // its own `implicitHeight` is circular, and Qt said so —
                // "Binding loop detected for property height" at this line, on
                // the first reload after the two-line change. contentHeight is
                // derived from the text and font alone, so it closes the loop.
                height: clockActionsCapsule.vertical ? contentHeight : Design.barGlyphSize
            }

            // Line 2, vertical only (D-18-14's two-stacked-lines form): a
            // short date, sized to fit Design.barColumnWidth with no
            // truncation. Hidden in horizontal, where the capsule stays a
            // single line — and, per the shared chrome's own visibility
            // rule, an invisible child is excluded from the positioner's
            // spacing too.
            Text {
                id: clockDateText
                visible: clockActionsCapsule.vertical
                font.pixelSize: Design.barBodySize
                font.weight: Design.weightBody
                color: BarRoles.fillClockFg
                text: Qt.formatDateTime(barClock.date, "ddd")
            }
        }
    }

    // ── Shared geometry for every extra on this capsule — Task 2's
    //    LauncherCell pitch, reused. ────────────────────────────────────
    readonly property int cellPitch: Design.barGlyphSize + Design.spacingXs * 2

    // ── ActionCell — the shared cell shape for every extra: identical
    //    geometry whether available or not, a live hover target at all
    //    times, and no pressed-state visual (this repo keys visual state
    //    off the resulting state change). ────────────────────────────────
    component ActionCell: Item {
        id: cellItem
        // A badged cell widens to hold its count BESIDE the glyph rather than
        // on top of it. Upstream Athena's #custom-notification is a filled
        // pill containing the bell glyph and the count side by side; ours drew
        // a badge circle of implicitHeight spacingMd (16) anchored to the
        // top-right of a cell whose glyph is barGlyphSize (16), so the badge
        // covered the bell exactly — the operator's "the notifications glyph
        // is messed up".
        // MEASURED 2026-08-12: beside-the-glyph is right in horizontal but does
        // not fit the vertical column. A badged cell came to 46.8px wide (24
        // pitch + an 18.8 badge for a two-digit count + 4 gap) against a
        // barColumnWidth of 44 — one digit lands at exactly 44, two or "9+"
        // spill. So the badge keeps its side-by-side placement horizontally and
        // stacks BELOW the glyph vertically: the cell stays one pitch wide and
        // grows downward instead, where there is room.
        //
        // Stacking rather than reverting to the old top-right overlay is
        // deliberate — the overlay is what this comment's own history records as
        // "the notifications glyph is messed up", because badge (spacingMd 16)
        // and glyph (barGlyphSize 16) are the same size, so it covered the bell
        // exactly. Below-the-glyph covers nothing.
        width: clockActionsCapsule.cellPitch + ((cellItem.badgeVisible && !clockActionsCapsule.vertical) ? badge.width + Design.spacingXs : 0)
        height: clockActionsCapsule.cellPitch + ((cellItem.badgeVisible && clockActionsCapsule.vertical) ? badge.height + Design.spacingXs : 0)

        property string glyph: ""
        property string label: ""
        property bool filled: false
        property color tint: clockActionsCapsule.contentColour
        property bool available: true
        property bool badgeVisible: false
        // Opt-out for a cell whose own hover does something more informative
        // than a one-word label. Default true: every extra on this capsule
        // (gaming, bell, power) has no hover behaviour of its own, so its
        // tooltip is the only thing naming it. A cell that EXPANDS on hover is
        // the exception — see settingsTriggerCell's own comment.
        property bool tooltipEnabled: true
        property string badgeText: ""
        // Optional filled background (D-13, only bellCell opts in below).
        // Defaults leave every other ActionCell instance unaffected —
        // Athena has exactly three filled hues and this must not become
        // a fourth.
        property bool fillActive
        property color fillColour: "transparent"
        signal clicked()
        signal rightClicked()

        // D-15-22's present-but-disabled treatment, established by
        // PanelDialog.qml's Advanced button: identical geometry, dropped
        // to this opacity, hover target left live so a tooltip can state
        // the reason. Never removed, never blank, never a dead hit area.
        readonly property real disabledOpacity: 0.38

        // Declared FIRST so it renders behind the glyph below. No
        // MouseArea/HoverHandler of its own — cellMouseArea (below) is
        // the cell's one hit target, unaffected by this addition.
        Rectangle {
            id: cellFillPill
            anchors.fill: parent
            radius: height / 2
            visible: cellItem.fillActive
            color: cellItem.fillColour
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
            id: glyphText
            // Offset left by half the badge's footprint when badged, so the
            // glyph+count pair is optically centred in the widened cell
            // instead of the glyph staying centred and the count hanging off.
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            // Shifted along whichever axis the badge occupies, so the
            // glyph+count pair stays optically centred in the grown cell rather
            // than the glyph holding centre with the count hanging off the end.
            anchors.horizontalCenterOffset: (cellItem.badgeVisible && !clockActionsCapsule.vertical) ? -(badge.width + Design.spacingXs) / 2 : 0
            anchors.verticalCenterOffset: (cellItem.badgeVisible && clockActionsCapsule.vertical) ? -(badge.height + Design.spacingXs) / 2 : 0
            text: cellItem.glyph
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.barGlyphSize
            font.variableAxes: clockActionsCapsule.fillAxisAvailable ? { "FILL": cellItem.filled ? 1 : 0 } : ({})
            color: cellItem.tint
            opacity: cellItem.available ? 1 : cellItem.disabledOpacity
        }

        // Badge overlay — used only by the bell, defaults to invisible
        // for every other cell.
        Rectangle {
            id: badge
            visible: cellItem.badgeVisible
            implicitWidth: Math.max(implicitHeight, badgeLabel.implicitWidth + Design.spacingXs)
            implicitHeight: Design.spacingMd
            width: implicitWidth
            height: implicitHeight
            radius: height / 2
            color: BarRoles.accent
            // Beside the glyph horizontally, BELOW it vertically — never on top
            // of it, which is what anchors.top/right used to do and what laid a
            // 16px circle over a 16px glyph.
            //
            // FIXED 2026-08-13, operator: "when I switch back to horizontal
            // mode, the notification bell is bugged". The previous shape
            // swapped between two anchor SETS, clearing the unused one by
            // assigning `undefined`:
            //
            //     anchors.verticalCenter:   vertical ? undefined : parent.verticalCenter
            //     anchors.horizontalCenter: vertical ? parent.horizontalCenter : undefined
            //
            // Assigning `undefined` to an AnchorLine does NOT reliably clear an
            // anchor that has already been established — this repo measured
            // exactly that during the 2026-08-12 vertical pass, on the popout
            // triggers, and fixed it there the same way. So a bar that STARTED
            // horizontal was fine, and one that had been vertical and came back
            // carried both sets at once: the badge was simultaneously
            // centre-anchored and left-anchored, and fought itself.
            // That is why the defect only ever appeared on the way BACK.
            //
            // Explicit x/y has no such failure mode: a number always replaces
            // the previous number. No cycle is introduced — glyphText's
            // centre OFFSETS read badge.width/height (a size, derived from
            // badgeLabel), while these read glyphText's resolved POSITION, and
            // a size never depends on a position here.
            x: clockActionsCapsule.vertical ? (parent.width - width) / 2 : (glyphText.x + glyphText.width + Design.spacingXs)
            y: clockActionsCapsule.vertical ? (glyphText.y + glyphText.height + Design.spacingXs) : (parent.height - height) / 2

            Text {
                id: badgeLabel
                anchors.centerIn: parent
                text: cellItem.badgeText
                font.pixelSize: Design.barBodySize
                color: BarRoles.onAccent
            }
        }

        MouseArea {
            id: cellMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (!cellItem.available)
                    return;
                if (mouse.button === Qt.RightButton)
                    cellItem.rightClicked();
                else
                    cellItem.clicked();
            }
        }

        // F2 (quick task 260812-69w) — see IdleInhibitorCapsule.qml's own
        // comment for the measured clamp this replaces. The empty-label
        // suppression this ToolTip used to carry as a second condition
        // (`&& cellItem.label !== ""`) is now folded into `active` itself,
        // per the plan's own instruction — a host with nothing to say
        // never arms its dwell timer. `tipId` is keyed off glyph, the one
        // value distinct across every ActionCell instance in this file
        // (gaming/bell/settings/power all carry a different glyph).
        BarTooltipHost {
            anchorItem: cellItem
            text: cellItem.label
            active: cellMouseArea.containsMouse && cellItem.label !== "" && cellItem.tooltipEnabled
            tipId: "clockActions-" + cellItem.glyph
        }
    }

    // ── Power (Phase 20 Plan 06 Task 2, D-20-23) ─────────────────────────
    // powerScriptPath / powerAvailable / powerAvailabilityProbe /
    // powerLaunchProcess are all REMOVED OUTRIGHT, not repointed — the
    // menu is now an in-process QML surface (PowerMenu.qml), so "the
    // power menu is missing" stops being a reachable state, the exact
    // risk `powerAvailabilityProbe`'s own comment used to cite as its
    // reason to exist. `powerCell` below now calls
    // `PopoutController.requestPowerMenu()` in-process instead of
    // launching a script — see PopoutController.qml's own comment for why
    // this reuses the panel/dashboard wayfinding seam rather than a new
    // mechanism.

    // ── Gaming mode — a read-only, compare-only consumer of the state
    //    its owner script writes. No second copy of the on/off logic
    //    exists here; the retired bar's own module carried that same
    //    discipline and it is carried forward, not re-derived. ─────────
    FileView {
        id: gamingStateFile
        path: clockActionsCapsule.homeDir + "/.cache/gaming-mode"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string gamingRaw: (gamingStateFile.text() || "").trim()
    readonly property bool gamingOn: (gamingRaw.length > 0 ? gamingRaw : "off") === "on"

    Process {
        id: gamingLaunchProcess
        command: [clockActionsCapsule.homeDir + "/.config/hypr/scripts/gaming-mode-toggle.sh"]
    }

    // ── The notification bell, and the seam D-18-33 promises. ──────────
    // Every name outside this component's own body MUST stay confined to
    // the five below: unreadCount, dndActive, available, openCentre(),
    // toggleDnd(). Everything else — the subscription argv, the field
    // names its output carries, the open-centre argv, the do-not-disturb
    // argv, the vocabulary of state strings it emits — lives inside this
    // component and nowhere else in this file. This binding is to a
    // package this milestone deletes: if any of it leaks into a binding
    // or a layout expression outside this component, the Phase 19
    // replacement stops being a backend swap and becomes a rewrite of a
    // surface that has already passed its render gate.
    // ── Phase 19 Plan 06 repoint — internals only, per this component's
    //    own contract above. The three Process children and the outgoing
    //    daemon's own CLI argv/vocabulary are gone; every read below binds
    //    live to NotifServer (Plan 19-01/19-05's own singleton) and every
    //    write calls its existing public verbs directly, in-process, with
    //    no subprocess anywhere in either path. `available` has no
    //    failure mode left to represent — NotifServer is a QML singleton
    //    inside this same process, not a CLI backend that can be absent —
    //    so it is now an honest constant `true` rather than a probe
    //    result.
    component NotificationSource: QtObject {
        id: sourceRoot

        readonly property int unreadCount: NotifServer.unreadCount
        readonly property bool dndActive: NotifServer.dnd
        readonly property bool available: true

        function openCentre() {
            if (NotifServer.centreOpen)
                NotifServer.centreOpen = false;
            else
                NotifServer.openCentre();
        }
        function toggleDnd() {
            NotifServer.toggleDnd();
        }
    }

    NotificationSource {
        id: notificationSource
    }

    // ── Do-not-disturb reads as a LIT BELL GLYPH, not an ambient capsule
    //    tint. D-21-27 originally routed dndActive into an instance-level
    //    `color:` override on this capsule's own root BarCapsule object,
    //    washing the whole capsule in accent at 0.28. The operator reversed
    //    that at Plan 05's blocking render gate (2026-08-16): the wash sat
    //    behind and around the opaque clockFillPill, so the tinted region
    //    engulfed the clock even though the pill itself never changed
    //    colour. See D-21-27-R in 21-UI-SPEC.md § DND Capsule Tint.
    //
    //    The replacement is not a new mechanism — it is the accent rule
    //    21-UI-SPEC.md:115 already states ("Accent reserved for: ... lit
    //    toggle chips (Gaming/DND/Dark when ON) ..."), expressed exactly as
    //    gamingCell above already expresses it: a `tint` branch on the one
    //    cell that owns the mode. No capsule-level `color:` override
    //    remains here, so this capsule inherits BarCapsule.qml's shared
    //    expression unmodified again, and BarRoles' dndSurface/dndSurfaceFg
    //    pair is gone with it.
    //
    //    Source of truth is still NotifServer.dnd via the existing
    //    `notificationSource.dndActive` alias — no second state holder.

    // ── The settings drawer — the same five axes D-18-01 names, sharing
    //    Task 2's drawer shape verbatim. Promoting that shape to a
    //    shared type is a named follow-on, not a licence to edit the
    //    frozen manifest here. ──────────────────────────────────────────
    readonly property var settingsAxes: [
        { id: "theme", glyph: "contrast", label: "Theme", script: "theme-switch.sh" },
        { id: "orientation", glyph: "screen_rotation", label: "Bar Orientation", script: "bar-orientation.sh" },
        { id: "font", glyph: "text_fields", label: "Font", script: "font-switch.sh" },
        { id: "icons", glyph: "palette", label: "Icon Theme", script: "icon-theme-switch.sh" },
        { id: "wallpaper", glyph: "wallpaper", label: "Wallpaper", script: "wallpaper-switch.sh" }
    ]

    // ── The public drawer seam — the hover contract below (Phase 18.1
    //    Plan 05, D-16/D-17/D-18) is the one and only implementation
    //    driving these three names. ─────────────────────────────────────
    property bool settingsExpanded: false
    // The trigger cell's own scene-space centre along the bar's long axis
    // — BarDrawer.qml's `triggerCentre` contract, published ONCE per
    // expand rather than a live binding. Mirrors
    // LauncherCapsule.qml's own publishDrawerAnchor() shape-identically.
    property real _publishedDrawerCentre: 0
    function publishDrawerAnchor() {
        clockActionsCapsule._publishedDrawerCentre = settingsTriggerCell.mapToItem(null, 0, 0).y + settingsTriggerCell.height / 2;
    }
    function requestExpand() {
        // Published before `settingsExpanded` is set true, so both the
        // dwell path and any direct caller publish a fresh centre.
        clockActionsCapsule.publishDrawerAnchor();
        clockActionsCapsule.settingsExpanded = true;
    }
    function requestCollapse() {
        clockActionsCapsule.settingsExpanded = false;
    }
    readonly property int expandedCrossExtent: clockActionsCapsule.settingsAxes.length * clockActionsCapsule.cellPitch + (clockActionsCapsule.settingsAxes.length - 1) * Design.spacingXs

    // ── Hover-reveal (Phase 18.1 Plan 05, D-16/D-17/D-18) — mirrors
    //    LauncherCapsule.qml's mechanism shape-identically (same property
    //    names, same timer ids, same tokens) so the two are diffable with
    //    zero behavioural divergence. Both hover sources (the trigger
    //    cell and the drawer strip, wired below) report through
    //    `reportDrawerHover` into the same `drawerHoverActive` boolean,
    //    so the pointer travelling from the trigger to the strip never
    //    reads as a clean exit — a per-surface boolean would defeat the
    //    grace timer below before it ever ran. The settledness read below
    //    reads Bar.qml's own live rendered/transitioning state through
    //    the shared `QsWindow.window` handle (the same reachable path
    //    IdleInhibitorCapsule.qml's own `barIdleInhibitor`'s
    //    `window: QsWindow.window` binding already proves live) —
    //    deliberately NOT the reveal-machine
    //    singleton's own dead settled latch (D-26 fences that one out by
    //    name). This file writes to no reveal-machine state at all: the
    //    bar's own whole-content hover handler already spans the area the
    //    drawer expands inside, so the bar's own re-hide grace already
    //    covers an open drawer with zero new wiring. ─────────────────────
    property bool _triggerHovered: false
    property bool _stripHovered: false
    property bool drawerHoverActive: false
    function reportDrawerHover(source, entered) {
        if (source === "trigger")
            clockActionsCapsule._triggerHovered = entered;
        else if (source === "strip")
            clockActionsCapsule._stripHovered = entered;
        clockActionsCapsule.drawerHoverActive = clockActionsCapsule._triggerHovered || clockActionsCapsule._stripHovered;
    }

    readonly property bool drawerSettled: QsWindow.window ? (QsWindow.window.barRendered && !QsWindow.window.barTransitionRunning) : false

    onDrawerHoverActiveChanged: {
        if (clockActionsCapsule.drawerHoverActive) {
            drawerGraceTimer.stop();
            drawerDwellTimer.restart();
        } else {
            drawerDwellTimer.stop();
            drawerGraceTimer.restart();
        }
    }

    // A drawer that survived into a hidden bar would reappear expanded on
    // the next reveal — QBAR-07's boundary case. Collapse immediately,
    // with no grace, the moment the bar stops being settled.
    onDrawerSettledChanged: {
        if (!clockActionsCapsule.drawerSettled && clockActionsCapsule.settingsExpanded) {
            drawerDwellTimer.stop();
            drawerGraceTimer.stop();
            clockActionsCapsule.requestCollapse();
        }
    }

    Timer {
        id: drawerDwellTimer
        interval: Design.barDrawerDwellMs
        repeat: false
        onTriggered: {
            // Re-evaluated at FIRE time, not only at arm time: a dwell
            // armed while the bar was up must not open a drawer into a
            // bar that began hiding moments later.
            if (clockActionsCapsule.drawerHoverActive && clockActionsCapsule.drawerSettled)
                clockActionsCapsule.requestExpand();
        }
    }

    Timer {
        id: drawerGraceTimer
        interval: Design.barDrawerGraceMs
        repeat: false
        onTriggered: {
            if (!clockActionsCapsule.drawerHoverActive)
                clockActionsCapsule.requestCollapse();
        }
    }

    // One axis cell — an ActionCell that also owns its own script-present
    // probe and its own detached launcher, keyed off its own `axis` data
    // rather than a second literal script name.
    component SettingsAxisCell: ActionCell {
        id: axisCell
        property var axis: ({})
        glyph: axisCell.axis.glyph ? axisCell.axis.glyph : ""
        label: axisCell.axis.label ? axisCell.axis.label : ""

        readonly property string scriptPath: clockActionsCapsule.homeDir + "/.config/hypr/scripts/" + axisCell.axis.script

        Process {
            id: axisAvailabilityProbe
            command: ["test", "-x", axisCell.scriptPath]
            onExited: function (exitCode, exitStatus) {
                axisCell.available = exitCode === 0;
            }
        }
        Process {
            id: axisLaunchProcess
            command: [axisCell.scriptPath]
        }

        Component.onCompleted: axisAvailabilityProbe.running = true

        onClicked: {
            // Every one of these five opens a focus-stealing picker; a
            // lifetime-bound child would be killed the moment
            // requestCollapse() below re-lays this capsule, orphaning
            // the picker in exactly the half-dead state this repo's own
            // recorded regression describes.
            axisLaunchProcess.startDetached();
            clockActionsCapsule.requestCollapse();
        }
    }

    // ── Capsule assembly — declaration order matches 18-05's entry list
    //    (clock above, then gaming, notifications, settings, power), one
    //    positioner (BarCapsule's own content Grid), nothing hidden or
    //    folded in either orientation. The idle inhibitor is no longer
    //    among these cells — see note (a) above; it now assembles inside
    //    IdleInhibitorCapsule.qml. ────────────────────────────────────────

    ActionCell {
        id: gamingCell
        // Operator fix wave finding 3 — per-entry hiding, one resolution
        // point (BarEntryModel.entryVisible()); same Grid-exclusion
        // mechanism as clockPopoutTrigger above.
        visible: BarEntryModel.entryVisible("gaming")
        glyph: "sports_esports"
        label: "Gaming Mode"
        filled: clockActionsCapsule.gamingOn
        tint: clockActionsCapsule.gamingOn ? BarRoles.accent : clockActionsCapsule.contentColour
        onClicked: gamingLaunchProcess.startDetached()
    }

    ActionCell {
        id: bellCell
        // Operator fix wave finding 3 — per-entry hiding, one resolution
        // point (BarEntryModel.entryVisible()); same Grid-exclusion
        // mechanism as clockPopoutTrigger above.
        visible: BarEntryModel.entryVisible("notifications")
        glyph: {
            if (!notificationSource.available)
                return "notifications";
            if (notificationSource.dndActive)
                return "notifications_paused";
            if (notificationSource.unreadCount > 0)
                return "notifications_active";
            return "notifications";
        }
        label: "Notifications"
        filled: notificationSource.unreadCount > 0
        // D-13/QBAR-06: the fill, the badge and the FILL variable axis
        // (via `filled` above) all derive from the ONE
        // notificationSource.unreadCount input — no second source of
        // "there are notifications". dndActive is deliberately NOT added
        // to `filled`/`fillActive`/`badgeVisible` below: do-not-disturb is
        // a mode, not a count, and folding it into any of those three
        // would break that single-input invariant.
        fillActive: notificationSource.unreadCount > 0
        fillColour: BarRoles.fillNotification
        // Four-branch tint: on-fill colour when unread, danger when the
        // source is unavailable (D-24's migration of this branch, landed
        // here rather than migrated twice in Task 3), ACCENT while
        // do-not-disturb is active (D-21-27-R — the lit-toggle-chip rule
        // of 21-UI-SPEC.md:115, mirroring gamingCell's
        // `gamingOn ? BarRoles.accent : contentColour` verbatim), neutral
        // content colour otherwise.
        //
        // The DND branch sits BELOW the unread branch on purpose. When
        // unread > 0 the glyph is drawn on cellFillPill filled
        // BarRoles.fillNotification (= Colours.primary), and BarRoles.accent
        // is ALSO Colours.primary — an accent glyph on that fill would be
        // primary-on-primary and vanish. Nothing is lost by yielding: the
        // glyph SHAPE already carries do-not-disturb unconditionally
        // (`notifications_paused` outranks `notifications_active` in the
        // glyph expression above), so the mode still reads when both are
        // true; only the redundant colour cue defers.
        tint: {
            if (notificationSource.unreadCount > 0)
                return BarRoles.fillNotificationFg;
            if (!notificationSource.available)
                return BarRoles.danger;
            if (notificationSource.dndActive)
                return BarRoles.accent;
            return clockActionsCapsule.contentColour;
        }
        badgeVisible: notificationSource.unreadCount > 0
        badgeText: notificationSource.unreadCount > 9 ? "9+" : String(notificationSource.unreadCount)
        onClicked: notificationSource.openCentre()
        onRightClicked: notificationSource.toggleDnd()
    }

    // The settings strip — a Repeater over settingsAxes inside one
    // axis-bound Grid, the same rows/columns formula BarCapsule uses
    // internally, never a Row/Column pair. Horizontal orientation: the
    // true drawer, complete here. Vertical orientation: hosted by
    // BarDrawer.qml instead (18-11's Option B, taken by quick task
    // 260812-59l, see the LazyLoader mounted after settingsTriggerCell
    // below), because a layer-shell surface cannot render outside its own
    // buffer and Bar.qml pins the vertical window to
    // Design.barColumnWidth — this Item contributes nothing (both
    // dimensions resolve to 0) and its five cells are destroyed, not
    // merely clipped, whenever clockActionsCapsule.vertical is true.
    //
    // GATE-02 round 4: declared BEFORE settingsTriggerCell, not after —
    // this capsule sits in the bar's END zone (anchors.right, Bar.qml),
    // so a Grid's LAST child's right edge is what stays pinned to the
    // window edge as the Grid's own width changes (the same Qt Quick Grid
    // layout arithmetic MediaConnectivityCapsule.qml's audio/connections
    // strips already rely on — see that file's own comment on
    // audioStripHost for the full arithmetic). The FORMER order (trigger
    // then strip) put the strip AFTER the trigger, so growing it pushed
    // powerCell rightward while leaving the trigger's own screen position
    // to drift with everything before it — the operator's "expands in the
    // opposite direction". Declaring the strip first makes it grow
    // LEFTWARD out of a fixed settingsTriggerCell, matching every other
    // right-side drawer on this bar and upstream's own
    // `transition-left-to-right: false` convention. This declaration
    // order is load-bearing and stays exactly as it was.
    Item {
        id: settingsStripHost
        // Operator fix wave finding 3 — per-entry hiding, one resolution
        // point (BarEntryModel.entryVisible()); the "settings" entry is
        // this Item plus settingsTriggerCell below, both gated together
        // so hiding the row removes the trigger AND its expandable strip.
        visible: BarEntryModel.entryVisible("settings")
        clip: true
        width: clockActionsCapsule.vertical ? 0 : (clockActionsCapsule.settingsExpanded ? clockActionsCapsule.expandedCrossExtent : 0)
        height: clockActionsCapsule.vertical ? 0 : clockActionsCapsule.cellPitch

        // GATE-02 round 4: a GTK Revealer slide is one ease-out curve, both
        // directions — see LauncherCapsule.qml's own comment for why the
        // former Motion.emphasizedIn/Out bezier pair is gone (that pairing's
        // acceleration was the operator's "not smooth" report). quick-260821-
        // swp (R-2b): now on `Motion.spatialMoveEasing`, the same retirement
        // of the hardcoded `Design.barDrawerEasingType` Qt enum. Horizontal-
        // only now, but left exactly as it was.
        Behavior on width {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Design.barDrawerTransitionMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.spatialMoveEasing
            }
        }
        Behavior on height {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Design.barDrawerTransitionMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.spatialMoveEasing
            }
        }

        HoverHandler {
            id: settingsStripHoverHandler
            onHoveredChanged: clockActionsCapsule.reportDrawerHover("strip", settingsStripHoverHandler.hovered)
        }

        // Gated behind `!vertical` so the five cells below are destroyed
        // in vertical orientation rather than merely clipped — the same
        // zero-idle-cost discipline BarDrawer.qml's own LazyLoader applies
        // to the surface that replaces this Grid there. `sourceComponent`
        // used explicitly (this repo's own convention for a plain
        // QtQuick.Loader — see Dashboard.qml's dashboardTabLoader).
        Loader {
            id: settingsGridLoader
            anchors.fill: parent
            active: !clockActionsCapsule.vertical
            asynchronous: false

            sourceComponent: Component {
                Grid {
                    id: settingsGrid
                    anchors.fill: parent
                    rows: 1
                    columns: -1
                    spacing: Design.spacingXs

                    Repeater {
                        model: clockActionsCapsule.settingsAxes
                        delegate: SettingsAxisCell {
                            axis: modelData
                        }
                    }
                }
            }
        }
    }

    ActionCell {
        id: settingsTriggerCell
        // Operator fix wave finding 3 — per-entry hiding, one resolution
        // point (BarEntryModel.entryVisible()); paired with
        // settingsStripHost above, same key.
        visible: BarEntryModel.entryVisible("settings")
        glyph: "settings"
        label: "Settings"
        filled: clockActionsCapsule.settingsExpanded
        // 2026-08-13, operator report: "hovering over the settings glyph
        // expands it and shows a tooltip — remove the tooltip as it covers the
        // expanded options". This cell is the one ActionCell whose hover has a
        // richer answer than its own label: the same gesture opens the five-axis
        // settings drawer, and the tooltip then renders over the axis glyphs the
        // hover just revealed. `label` is deliberately KEPT rather than blanked —
        // it is the cell's identity, read by tipId and available to any future
        // consumer; only the tooltip surface is suppressed.
        //
        // Not gated on `settingsExpanded` instead: the tooltip's dwell timer and
        // the drawer's own dwell both arm from the same hover, so a state-gated
        // condition still flashes the tip during the window before the drawer
        // opens. A flat opt-out is the only shape with no flash.
        tooltipEnabled: false
        // NO tint — falls through to ActionCell's default contentColour.
        //
        // Athena colours the settings-drawer trigger glyph @accent
        // unconditionally (style-athena.scss:298), and this file followed it
        // until the operator's call on 2026-08-12: the accent moves to
        // powerCell below. Recorded as a DELIBERATE departure from the
        // reference bar rather than left looking like a port slip, because
        // athena is this phase's own aesthetic baseline — GATE-02 Block A
        // judges every A-row against it — so a reader diffing the two will
        // find this difference and needs to know it was chosen. The rationale
        // is that a permanent accent should mark the one irreversible action
        // on the bar, and opening a settings drawer is not that; invoking the
        // power menu is.
        //
        // `filled` still tracks settingsExpanded, so the trigger keeps its own
        // open/closed state indication — this removes the permanent colour,
        // not the feedback.

        // Operator request (2026-08-21): hover still opens the five-axis
        // drawer; CLICK opens the settings window. The two gestures do not
        // fight — this adds no drawer-state write, so `reportDrawerHover`
        // stays the sole hover relay (D-18-19) and the dwell/settle state
        // machine is untouched. The drawer collapses on hover-exit exactly
        // as it always has. Routed through PopoutController -> Bar.qml ->
        // shell.qml's `openSettings()`, the same verb Super+comma calls,
        // mirroring powerCell's relay rather than inventing a second path.
        onClicked: PopoutController.requestSettings()

        HoverHandler {
            id: settingsTriggerHoverHandler
            onHoveredChanged: clockActionsCapsule.reportDrawerHover("trigger", settingsTriggerHoverHandler.hovered)
        }
    }

    // ── Vertical-orientation drawer host (18-11's Option B, D-18-11,
    //    quick task 260812-59l, closing GATE-02 row B.4-DRAWER) — the
    //    SAME registered BarDrawer type LauncherCapsule.qml mounts, no
    //    second host type (constraint 7). Mounted behind a LazyLoader
    //    keyed on `vertical && settingsExpanded`, so it costs nothing
    //    while collapsed or in horizontal orientation.
    //    `reportDrawerHover` is the sole hover relay (D-18-19) — no
    //    second dwell or grace timer is added here. Reuses
    //    SettingsAxisCell (this file's own inline component). ────────────
    LazyLoader {
        id: verticalSettingsDrawerLoader
        active: clockActionsCapsule.vertical && clockActionsCapsule.settingsExpanded

        BarDrawer {
            drawerId: "settings"
            crossExtent: clockActionsCapsule.expandedCrossExtent
            cellPitch: clockActionsCapsule.cellPitch
            triggerCentre: clockActionsCapsule._publishedDrawerCentre
            onHoveredChanged: clockActionsCapsule.reportDrawerHover("strip", hovered)

            Repeater {
                model: clockActionsCapsule.settingsAxes
                delegate: SettingsAxisCell {
                    axis: modelData
                }
            }
        }
    }

    ActionCell {
        id: powerCell
        // Operator fix wave finding 3 — per-entry hiding, one resolution
        // point (BarEntryModel.entryVisible()). Shipped deliberately:
        // Super+Shift+Q (hypr/config/keybinds.lua:68) opens the identical
        // power menu, so hiding this bar entry removes no capability.
        visible: BarEntryModel.entryVisible("power")
        glyph: "power_settings_new"
        label: "Power Menu"
        // available intentionally left at ActionCell's own default — no
        // `powerAvailable`-shaped binding replaces the deleted probe
        // (D-20-23): an in-process surface has no "missing" state to
        // gate on, and `available: true` here would just be the same
        // dead machinery under a new name.
        // The bar's one permanent accent glyph, moved here from
        // settingsTriggerCell above on the operator's call (2026-08-12) — see
        // that cell's comment for why the departure from athena is recorded
        // rather than silent. Unconditional, not a state indicator, so no
        // ternary: the same shape settings previously used.
        //
        // Deliberately NOT gated on `available`. ActionCell already dims an
        // unavailable cell through its own opacity path, so tinting
        // conditionally here would express the same state twice and, on a host
        // where the power menu is missing, would silently leave the bar with no
        // accent glyph at all.
        tint: BarRoles.accent
        onClicked: PopoutController.requestPowerMenu()
    }
}

