// BarTooltip.qml — the escaping tooltip surface (quick task 260812-69w, F2).
//
// Task 1's Probe B measured this live rather than assumed it: a
// QtQuick.Controls ToolTip is a Popup, a Popup is clamped to its own
// window, and Bar.qml's horizontal window is only Design.barHeight (42)
// tall. Assigning ToolTip.y=60 from inside that window resolved back to
// y=-2 — the clamp is real. A property nobody set was never the whole
// story; the container cannot hold the fix, so this file is a container
// that can: an anchored layer-shell surface, sibling to the bar rather
// than inside it.
//
// Layer posture copied from BarDrawer.qml line for line, for the same
// reasons that file's own header states — `exclusiveZone: 0` as a bare
// literal (GATE-03's forward closure greps for that literal form on every
// `noreserve` row), `exclusionMode: ExclusionMode.Ignore`,
// `WlrLayershell.layer: WlrLayer.Overlay`,
// `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None`, `focusable: false`,
// `color: "transparent"`.
//
// Namespace prefix `quickshell-bartip-` is load-bearing, not a style
// choice — the same reasoning BarDrawer.qml's own header records for
// `quickshell-bardrawer-`: quickshell-doctor's
// _qsd_assert_bar_surface_registry_live requires every live bar-family
// namespace to match EXACTLY ONE registry row. SectionPopout's own row
// stores the pattern prefix `quickshell-bar-`, which matches ANY string
// beginning with that prefix plus at least one character. A namespace of
// the shape `quickshell-bar-…` here would therefore match BOTH that row
// and this file's own row, be counted `unmatched`, and fail the live half
// the moment a tooltip is actually shown. `quickshell-bartip-…` still
// starts with `quickshell-bar` (so the broad bar-family candidate net
// still captures it) and with `quickshell-` (so the family-wide
// blur/ignore_alpha Hyprland layer rules still apply), while resolving to
// exactly one row. Do not "tidy" this prefix.
//
// Anchoring is SectionPopout.qml's own expression pair, transcribed
// rather than re-derived — diff this block against SectionPopout.qml
// lines 167-178 whenever either changes, the same instruction
// BarDrawer.qml carries against the same source. Single-edge margin
// arithmetic, never doubled.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../dashboard"

PanelWindow {
    id: tooltipRoot

    // ── Public contract — set entirely by BarTooltipHost. ───────────────
    property string text: ""
    property bool vertical: false
    property real triggerCentre: 0
    property string tipId: ""

    // ── Layer posture — copied from BarDrawer.qml. ───────────────────────
    anchors {
        top: true
        left: !tooltipRoot.vertical
        right: tooltipRoot.vertical
    }

    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-bartip-" + tooltipRoot.tipId
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false
    color: "transparent"

    // ── Geometry — content-sized: the label plus Design.spacingSm per
    //    side horizontally, Design.spacingXs per side vertically. ────────
    implicitWidth: tipLabel.implicitWidth + Design.spacingSm * 2
    implicitHeight: tipLabel.implicitHeight + Design.spacingXs * 2

    // ── Anchoring arithmetic — SectionPopout.qml's own expression pair,
    //    transcribed verbatim in shape. Single-edge-margin arithmetic,
    //    never doubled (the same shape D-18-38 fixed for the bar's own
    //    reservation). ──────────────────────────────────────────────────
    readonly property int _horizontalTopMargin: Design.barEdgeMargin + Design.barHeight + Design.spacingXs
    readonly property int _verticalRightMargin: Design.barEdgeMargin + Design.barColumnWidth + Design.spacingXs

    readonly property real _horizontalDesiredLeft: Design.barSideMargin + tooltipRoot.triggerCentre - tooltipRoot.width / 2
    readonly property real _horizontalClampedLeft: Math.max(Design.barSideMargin, Math.min(tooltipRoot._horizontalDesiredLeft, (tooltipRoot.screen ? tooltipRoot.screen.width : tooltipRoot.width) - tooltipRoot.width - Design.barSideMargin))

    readonly property real _verticalDesiredTop: Design.barSideMargin + tooltipRoot.triggerCentre - tooltipRoot.height / 2
    readonly property real _verticalClampedTop: Math.max(Design.barSideMargin, Math.min(tooltipRoot._verticalDesiredTop, (tooltipRoot.screen ? tooltipRoot.screen.height : tooltipRoot.height) - tooltipRoot.height - Design.barSideMargin))

    margins.top: tooltipRoot.vertical ? tooltipRoot._verticalClampedTop : tooltipRoot._horizontalTopMargin
    margins.left: tooltipRoot.vertical ? 0 : tooltipRoot._horizontalClampedLeft
    margins.right: tooltipRoot.vertical ? tooltipRoot._verticalRightMargin : 0

    // ── Chrome — one Rectangle, one Text. Every colour routes through
    //    BarRoles.* (D-20) — this file is new and is deliberately NOT
    //    added to quickshell-doctor's QSD_BAR_COLOUR_ROLE_EXEMPT array.
    //    BarRoles.capsule is 0.85 alpha, comfortably above the
    //    ^quickshell-.* family layer rule's ignore_alpha floor of 0.5 —
    //    no fill in this file may drop below that floor. No HoverHandler,
    //    no MouseArea, no Timer, no second positioner: this surface
    //    displays a string and nothing else. ───────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: Design.barCapsuleRadius
        color: BarRoles.capsule
    }

    Text {
        id: tipLabel
        anchors.centerIn: parent
        text: tooltipRoot.text
        textFormat: Text.PlainText
        font.pixelSize: Design.barBodySize
        color: BarRoles.capsuleFg
    }
}
