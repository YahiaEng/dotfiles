// BarDrawer.qml — the shared vertical-orientation drawer host (Phase 18
// Plan 11's Option B, taken as an 18-05 scope correction by quick task
// 260812-59l, GATE-02 row B.4-DRAWER).
//
// D-18-11 requires vertical-orientation drawers to expand inward and
// horizontally — "a floating strip growing leftward over the desktop" —
// not along the 44px bar column. A wlr-layer-shell surface cannot draw
// outside its own buffer, and Bar.qml pins the vertical window to
// Design.barColumnWidth, so no in-bar Item can deliver that shape. This
// file is the missing host: a LazyLoader-gated anchored strip surface,
// mounted once per consumer (LauncherCapsule.qml, ClockActionsCapsule.qml)
// behind the exact shell.qml LazyLoader idiom HotZone.qml already uses
// (D-18-24) — created and destroyed with the expanded state, costing
// nothing while collapsed.
//
// This is an ORDINARY instance type, NOT a singleton — each capsule
// mounts its own LazyLoader-gated instance, never an ambient shared one.
//
// Layer posture copies SectionPopout.qml's; lifecycle discipline (one
// job, nothing else, no click/wheel/drag machinery beyond a single
// HoverHandler) copies HotZone.qml's.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../dashboard"

PanelWindow {
    id: drawerRoot

    // ── Public contract — set entirely by the consuming capsule. ────────
    property string drawerId: ""
    // The trigger cell's own scene-space centre along the bar's long
    // axis, published ONCE at expand time by the consumer (mirroring
    // SectionPopout.qml's triggerCentre / PopoutTrigger.publishAnchor()
    // reasoning verbatim in spirit) — never a live binding, because scene
    // mapping does not re-evaluate when an ancestor moves.
    property real triggerCentre: 0
    // The consumer's own published expandedCrossExtent.
    property int crossExtent: 0
    // The consumer's own published cellPitch.
    property int cellPitch: 0
    // Where the consumer's own Repeater lands.
    default property alias cells: drawerGrid.data
    // The relay — mirrors SectionPopout.qml's `hovered` property exactly.
    readonly property bool hovered: drawerHoverHandler.hovered

    // ── Layer posture — vertical-orientation only. This host is never
    //    mounted in horizontal orientation (each consumer's LazyLoader is
    //    gated on `vertical && expanded`), so there is no orientation
    //    ternary anywhere in this file and none should be added. ────────
    anchors {
        top: true
        right: true
    }

    // Declared as a bare literal, not an expression: the GATE-03 forward
    // closure greps for `exclusiveZone[[:space:]]*:[[:space:]]*0\b` on
    // every `noreserve` row, and the bar's own reservation
    // (QBAR-12's [0,48,0,0] proof) must not move.
    exclusiveZone: 0
    // Ignore, the same reason SectionPopout.qml line 144 gives: margins
    // must measure from the true screen edge to be computable from
    // Design tokens alone.
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    // Prefix is load-bearing, not a style choice: quickshell-doctor's
    // _qsd_assert_bar_surface_registry_live requires every live
    // bar-family namespace to match EXACTLY ONE registry row.
    // SectionPopout's own registry row stores the pattern prefix
    // `quickshell-bar-`, which matches any string beginning with that
    // prefix plus at least one character — a namespace of the shape
    // `quickshell-bar-…` here would therefore match BOTH that row and
    // this file's own row, be counted `unmatched`, and fail the live
    // half. `quickshell-bardrawer-…` still starts with `quickshell-bar`
    // (so the broad `_qsd_bar_family_layer_rows` candidate net still
    // captures it) and with `quickshell-` (so the family-wide blur/
    // ignore_alpha Hyprland layer rules still apply), while resolving to
    // exactly one registry row. Do not "tidy" this prefix.
    WlrLayershell.namespace: "quickshell-bardrawer-" + drawerRoot.drawerId
    // A drawer acts on click through its own cells; it never asks for
    // keyboard focus and holds no focus grab. No HyprlandFocusGrab in
    // this file.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false
    color: "transparent"

    // ── Geometry — a single horizontal row of cells. ─────────────────────
    implicitWidth: drawerRoot.crossExtent
    implicitHeight: drawerRoot.cellPitch

    // ── Anchoring — the shared rule BarDrawer and SectionPopout.qml carry
    //    as ONE anchoring rule, not two (constraint 8): the identical
    //    expression pair, in the identical Design tokens, that
    //    SectionPopout.qml declares at lines 168 (_verticalRightMargin)
    //    and 173-174 (_verticalDesiredTop / _verticalClampedTop). No
    //    shared helper is extracted (constraint 4 forbids the extra file
    //    and qmldir line) — diff this block against SectionPopout.qml
    //    whenever either changes. Single-edge margin arithmetic, never
    //    doubled, the same shape D-18-38 already fixed for the bar's own
    //    reservation. ───────────────────────────────────────────────────
    // Corrected 2026-08-12 with SectionPopout.qml under GATE-02 finding F5,
    // keeping the two files' ONE anchoring rule identical. Was
    // `barEdgeMargin + barColumnWidth + spacingXs` (54): the compositor already
    // offsets an anchored layer surface past the bar's exclusive zone, so adding
    // the bar's own extent again double-counted it. F5 was measured on the
    // horizontal branch (`quickshell-bar-wifi y=100` against a bar bottom edge
    // of 48); this vertical branch is corrected by the same reasoning rather
    // than by its own measurement, so GATE-02's B.4 and B.4-DRAWER rows are the
    // live confirmation. See SectionPopout.qml:167 and BarTooltip.qml:78-90.
    // Then aligned to the WINDOW edge with SectionPopout, operator's call
    // 2026-08-12: the reserved boundary is not the window edge — Hyprland insets
    // tiled windows by general:gaps_out (10) below it, measured on this host as a
    // window outer border edge of y=58 against a reserved top of 48. A margin of
    // 0 lands on the reserved boundary, 10px clear of the window. barSideMargin
    // IS that inset and is what the bar already uses to sit flush with the
    // window's side edges. Keeps the ONE anchoring rule identical; see
    // SectionPopout.qml:167 for the full measurement.
    readonly property int _verticalRightMargin: Design.barSideMargin
    readonly property real _verticalClampedTop: Math.max(Design.barSideMargin, Math.min(Design.barSideMargin + drawerRoot.triggerCentre - drawerRoot.height / 2, (drawerRoot.screen ? drawerRoot.screen.height : drawerRoot.height) - drawerRoot.height - Design.barSideMargin))

    margins.right: drawerRoot._verticalRightMargin
    margins.top: drawerRoot._verticalClampedTop

    // ── Chrome — reads as a continuation of the bar capsule, NOT as a
    //    popout: no header/foot/state-placeholder vocabulary. Every
    //    colour routes through BarRoles.* (D-20) — this file is new and
    //    is deliberately NOT added to quickshell-doctor's
    //    QSD_BAR_COLOUR_ROLE_EXEMPT array. capsule is 0.85 alpha,
    //    comfortably above the ^quickshell-.* family layer rule's
    //    ignore_alpha floor of 0.5. ────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: Design.barCapsuleRadius
        color: BarRoles.capsule
    }

    // ── Contents — one positioner, one hover relay. Nothing else: no
    //    timer, no process, no MouseArea, no second positioner. ────────
    Grid {
        id: drawerGrid
        anchors.fill: parent
        rows: 1
        columns: -1
        spacing: Design.spacingXs
    }

    HoverHandler {
        id: drawerHoverHandler
    }

    // ── Motion — deliberately none. This surface is created and
    //    destroyed by the consumer's LazyLoader, so there is no 0-to-N
    //    width transition to animate (the window simply exists or does
    //    not) — unlike stripHost's container-slide Behavior, which
    //    animates an in-bar Item's geometry. No `Behavior on width`
    //    here. An entrance animation is a separate decision, not shipped
    //    now.
}
