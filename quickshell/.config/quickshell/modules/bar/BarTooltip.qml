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
    // MEASURED 2026-08-12, and the first attempt got this wrong in exactly
    // the way the comment above warns against. These were
    // `barEdgeMargin + barHeight + spacingXs` (52) and
    // `barEdgeMargin + barColumnWidth + spacingXs` (54), transcribed from
    // SectionPopout's shape — but a popout is positioned inside a window
    // that spans the screen, whereas this is an anchored layer surface, and
    // the compositor ALREADY offsets an anchored surface past the bar's
    // 48px exclusive zone. Adding the bar's own extent again double-counted
    // it: tooltips rendered at y=100 (measured via `hyprctl layers`) against
    // a bar whose bottom edge is 48 — about 79px below the glyph being
    // hovered, which is what the operator reported as "way below the
    // cursor". The margin here is therefore only the GAP past the edge the
    // compositor already found, nothing more.
    // Extra leftward step so the tooltip clears a floating host surface
    // (BarDrawer) that its anchor cell lives inside. 0 for every bar-hosted
    // site, which is why those are unchanged. See BarTooltipHost's own
    // `_hostClearance` for how it is derived and why `exclusiveZone` is the
    // discriminator.
    property real hostClearance: 0

    readonly property int _horizontalTopMargin: Design.spacingXs
    readonly property real _verticalRightMargin: Design.spacingXs + tooltipRoot.hostClearance

    // triggerCentre arrives here ALREADY converted to screen space, so this
    // file must NOT add barSideMargin — doing so shifted every tooltip 10px
    // off the glyph it describes (measured 2026-08-12: spotify's glyph centre
    // 40 against a tooltip centre of 50, discord 68 against 78, steam 96
    // against 106). barSideMargin is still correct in the CLAMP below, where
    // it is a screen-edge inset rather than an origin.
    //
    // CORRECTED 2026-08-13 — the conclusion above was right, its stated reason
    // was not, and that wrong reason propagated into BarDrawer.qml and
    // SectionPopout.qml where it caused the very bug it was warning about.
    // `mapToItem(null, ...)` does NOT return a scene-absolute coordinate: it
    // maps into the item's OWN WINDOW. What makes this file correct is that
    // BarTooltipHost.qml converts the value before publishing it (adding
    // QsWindow.window.margins), not that the value was ever screen-absolute.
    // The rule across this family: whoever consumes a raw mapToItem() result
    // converts it exactly once. BarDrawer and SectionPopout convert at the
    // consumer; tooltips convert at the host. Do not add an origin here.
    readonly property real _horizontalDesiredLeft: tooltipRoot.triggerCentre - tooltipRoot.width / 2
    readonly property real _horizontalClampedLeft: Math.max(Design.barSideMargin, Math.min(tooltipRoot._horizontalDesiredLeft, (tooltipRoot.screen ? tooltipRoot.screen.width : tooltipRoot.width) - tooltipRoot.width - Design.barSideMargin))

    readonly property real _verticalDesiredTop: tooltipRoot.triggerCentre - tooltipRoot.height / 2
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
