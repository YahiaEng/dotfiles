// SectionPopout.qml — the bar's per-section glance surface (Phase 18 Plan
// 13, QBAR-09).
//
// THIS IS A SECOND FRAME, added knowingly against PanelDialog.qml's own
// stated rule that every panel is built FROM it and never from a bespoke
// PanelWindow (D-18-15). The reason: PanelDialog is a fixed-size,
// compositor-centred dialog — reusing it would make the bar's audio pill
// reopen the exact same surface Super+A already opens, which would deliver
// nothing QBAR-09 asks for. The accepted cost, recorded here rather than
// only in a planning document: this frame must be registered in GATE-03's
// structural checks, covered by GATE-04's lint, and kept in visual and
// motion step with PanelDialog.qml BY REVIEW rather than by construction.
// PanelDialog.qml is therefore the file to diff against whenever either
// changes.
//
// PanelDialog is the CONTRAST CASE, not the template: fixed 850x620,
// anchored top only (compositor-centred), zero exclusive zone. This frame
// is a GLANCE surface instead: bounded 300-360px, anchored off the
// trigger entry that opened it, reserving nothing. Task 3 (this same
// plan) adds the four-state body vocabulary and the foot wayfinding link
// back to the full panel family — D-18-17 keeps every dashboard tab and
// every panel's unbounded list; this frame never thins or replaces them.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"
import "../dashboard"

PanelWindow {
    id: popoutWindow

    // ── Public contract surface — read by PopoutTrigger and, from 18-14
    //    onward, five more body files. ───────────────────────────────────
    property string sectionId: ""
    property string popoutTitle: ""
    property string popoutGlyph: ""
    property bool vertical: false
    // The trigger's own scene-space centre along the bar's long axis,
    // published once at summon time (PopoutTrigger.publishAnchor()) —
    // never a live binding, because scene mapping does not re-evaluate
    // when an ancestor moves and the bar never reflows while a popout is
    // open.
    property real triggerCentre: 0
    property bool pinned: false
    default property alias body: bodyColumn.data

    // ── Task 3 — the four-state body vocabulary, copied from
    //    PanelDialog.qml BY NAME rather than paraphrased: the names are
    //    identical on purpose, since reusing the vocabulary verbatim is
    //    one of the few places the two frames can be kept in step by
    //    construction rather than by review (D-18-15's accepted cost). ───
    property string bodyState: "populated"

    function stateColour(state) {
        switch (state) {
        case "populated": return Colours.onSurface;
        case "pending": return Colours.primary;
        case "empty": return Colours.onSurfaceVariant;
        case "failed": return Colours.error;
        default: return Colours.onSurface;
        }
    }

    // Per-instance overridable glyph/text pairs so a body supplies its
    // own words without restructuring the frame — PanelDialog.qml's own
    // emptyStateGlyph/emptyStateText idiom, extended to all three
    // non-populated states. The failure copy defaults to the UI-SPEC
    // sentence shape verbatim: the section name, an em dash, a
    // plain-language reason, then "then reopen this panel." — plain
    // language first and mechanism second.
    property string emptyStateGlyph: "info"
    property string emptyStateText: "Nothing to show"
    property string pendingStateGlyph: "hourglass_empty"
    property string pendingStateText: "Loading…"
    property string failedStateGlyph: "error"
    property string failedStateText: popoutWindow.popoutTitle + " unavailable — something went wrong, then reopen this panel."

    // ── Task 3 — the foot wayfinding link. The whole reason this popout
    //    can stay a glance surface: D-18-17 keeps the dashboard's four
    //    tabs and the panel family's unbounded lists, and this is the
    //    visible path to them, so a popout is never the only place
    //    something can be seen. ─────────────────────────────────────────
    property string wayfindingLabel: "Open in dashboard"
    property bool wayfindingAvailable: true
    property string wayfindingUnavailableReason: ""
    signal wayfindingActivated()

    // Press suppression comes from this early-return guard, NOT from
    // disabling the mouse area below — press suppression and hover
    // reachability are two different requirements satisfied by two
    // different guards, PanelDialog.qml's own Advanced button comment
    // records exactly why: a fully disabled MouseArea also stops
    // receiving hover, which would make the reason UNREACHABLE by hover.
    function activateWayfinding() {
        if (!popoutWindow.wayfindingAvailable)
            return;
        popoutWindow.wayfindingActivated();
    }

    signal dismissRequested()
    signal dismissFinished()

    function requestDismiss() {
        popoutWindow.dismissRequested();
        if (!Motion.motionEnabled) {
            // D-21's `off` collapse, mirrored: no animation, straight to
            // the finished signal.
            popoutWindow.dismissFinished();
            return;
        }
        exitFade.start();
    }

    // Esc routes through this rather than straight to requestDismiss() —
    // the same override seam PanelDialog.qml exposes for a later
    // two-stage Esc. Default body just dismisses.
    function handleEscape() {
        popoutWindow.requestDismiss();
    }

    // ── Layer posture — every line commented against what it differs
    //    from in PanelDialog and why. ────────────────────────────────────
    anchors {
        // Both orientations anchor the top edge. Horizontal ALSO anchors
        // left; vertical ALSO anchors right — differs from PanelDialog's
        // single top anchor (compositor-centred) because this frame must
        // sit next to its trigger, not in the middle of the screen.
        top: true
        left: !popoutWindow.vertical
        right: popoutWindow.vertical
    }

    // A glance surface reserves nothing, so opening one never reflows a
    // window — declared explicitly rather than left at a default.
    exclusiveZone: 0
    // Ignore, NOT PanelDialog's Normal: this frame's margins must measure
    // from the true screen edge to be computable from Design tokens
    // alone. Normal mode would offset every popout by the bar's own
    // 46/50px reservation, which this file would then have to subtract
    // back out. Ignoring other surfaces' reservations still reserves
    // nothing itself (exclusiveZone is 0 above either way).
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-bar-" + popoutWindow.sectionId
    // On demand only when pinned, none otherwise — differs from
    // PanelDialog's permanent OnDemand on purpose: T-18-13-01's whole
    // mitigation is that a mere hover-preview never asks for keyboard
    // focus at all.
    WlrLayershell.keyboardFocus: popoutWindow.pinned ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    // ── Size — content-bounded, never a literal fixed frame like
    //    PanelDialog's 850x620. bodyColumn below carries a fixed inner
    //    width off Design tokens, never off popoutWindow's own resolved
    //    width (that would be circular), so this clamp is deterministic. ─
    implicitWidth: Math.max(Design.popoutMinWidth, Math.min(Design.popoutMaxWidth, bodyColumn.implicitWidth + Design.spacingMd * 2))
    // Header, body, ONE spacing gap, the foot band, and a final spacing
    // gap below it (Task 3 appends the foot band to this sum).
    implicitHeight: Design.popoutHeaderHeight + bodyColumn.implicitHeight + Design.spacingMd + popoutFoot.height + Design.spacingMd

    // ── Anchoring arithmetic — Design tokens plus triggerCentre plus this
    //    window's own screen handle; no literal pixel value anywhere.
    //    Single-edge-margin arithmetic, the same shape D-18-38 fixed for
    //    the bar's own reservation — never doubled. ──────────────────────
    // MEASURED 2026-08-12 (GATE-02 finding F5). These were
    // `barEdgeMargin + barHeight + spacingXs` (52) and
    // `barEdgeMargin + barColumnWidth + spacingXs` (54) — the bar's own extent
    // added on top of an offset the compositor had ALREADY applied. This is an
    // anchored layer surface (top + left/right, exclusiveZone 0), so the
    // compositor already places it past the bar's 48px exclusive zone; adding
    // the extent again double-counted it. `hyprctl layers` returned
    // `quickshell-bar-wifi y=100` against a bar whose bottom edge is 48 — the
    // operator reported it as "the popup cards appear too low". The margin here
    // is therefore only the GAP past the edge the compositor already found,
    // nothing more. BarTooltip.qml:78-90 records the identical failure and the
    // identical correction, found hours earlier on the same layer posture; this
    // file is the sibling that taught it the wrong expression and never got the
    // fix. Keep the two files' shape identical.
    //
    // Then aligned to the WINDOW edge, operator's call 2026-08-12, after a first
    // attempt at 0 was rejected. The reserved boundary and the window edge are
    // NOT the same line, which is the trap here: Hyprland insets tiled windows
    // by general:gaps_out BELOW the reserved zone. MEASURED on this host —
    // reserved [0,48,0,0], gaps_out 10, border_size 3, and a tiled window
    // reporting `at=[13,61] size=[2534,1366]`, so its visible outer border edge
    // is at y=58 and x=10, not 48/0. A margin of 0 put the card at the reserved
    // boundary (measured y=48), floating 10px clear of the window it was meant
    // to line up with.
    //
    // barSideMargin (10) is that inset, and the bar itself already uses it for
    // exactly this alignment on the other axis: the bar measures x=10 w=2540,
    // flush with the window's left and right outer edges. Reusing it here makes
    // the popout's leading edge land on the window's leading edge. It matches
    // gaps_out by value rather than by binding — if general:gaps_out changes,
    // this alignment needs revisiting (a QML surface cannot read it live).
    readonly property int _horizontalTopMargin: Design.barSideMargin
    readonly property int _verticalRightMargin: Design.barSideMargin

    // triggerCentre is ALREADY a scene-absolute coordinate — PopoutTrigger.qml
    // publishes it via mapToItem(null, 0, 0) — so barSideMargin must NOT be
    // added here as an origin. It was, on both axes, until 2026-08-12, which
    // put every popout 10px off the glyph it belongs to.
    //
    // BarTooltip.qml:94-100 records the identical mistake with its own live
    // numbers, taken from the same publisher: "spotify's glyph centre 40
    // against a tooltip centre of 50, discord 68 against 78, steam 96 against
    // 106". That file corrected itself and did not sweep this one — the third
    // time in this family that BarTooltip found a bug, fixed only itself, and
    // left the sibling it had copied the expression FROM still carrying it
    // (see _horizontalTopMargin above for the second).
    //
    // barSideMargin stays in the CLAMP below, where it is a screen-edge inset
    // rather than an origin — that use was always correct and is unchanged.
    // ── Origin conversion, MEASURED 2026-08-13 ──────────────────────────────
    // The paragraph above is right that barSideMargin is not an offset to be
    // guessed at, and wrong that `triggerCentre` is scene-absolute. It is not:
    // PopoutTrigger.publishAnchor() computes it with
    // `triggerRoot.mapToItem(null, 0, 0)`, and `mapToItem(null, ...)` maps into
    // the item's OWN WINDOW — for a bar entry, the bar's PanelWindow. These
    // margins, by contrast, are screen-relative. The two spaces differ by the
    // bar window's own origin along its long axis, which is
    // Design.barSideMargin in BOTH orientations (Bar.qml sets
    // `margins.top: vertical ? barSideMargin : barEdgeMargin` and
    // `margins.left: vertical ? 0 : barSideMargin`, so whichever axis the
    // popout slides along, the offset is barSideMargin).
    //
    // Measured live, vertical, with the audio popout open:
    //   audio trigger true screen centre .......... 1094
    //     (hover-verified: a pointer at screen y=1094 hovers that trigger)
    //   quickshell-bar-audio surface .............. y 917, h 334 -> centre 1084
    // — ten pixels high, the same error and the same cause BarDrawer.qml
    // carried until it was corrected the same day. BarTooltip.qml is NOT
    // corrected here and must not be: its host (BarTooltipHost.qml) already
    // converts the centre before publishing it, so adding the origin again
    // would move every tooltip 10px the other way. The rule across this family
    // is that whoever consumes a raw mapToItem() value converts it exactly
    // once.
    //
    // barSideMargin still appears in the CLAMPS below as a screen-edge inset —
    // a different job, correct before and after.
    readonly property real _horizontalDesiredLeft: popoutWindow.triggerCentre + Design.barSideMargin - popoutWindow.width / 2
    readonly property real _horizontalClampedLeft: Math.max(Design.barSideMargin, Math.min(popoutWindow._horizontalDesiredLeft, (popoutWindow.screen ? popoutWindow.screen.width : popoutWindow.width) - popoutWindow.width - Design.barSideMargin))

    readonly property real _verticalDesiredTop: popoutWindow.triggerCentre + Design.barSideMargin - popoutWindow.height / 2
    readonly property real _verticalClampedTop: Math.max(Design.barSideMargin, Math.min(popoutWindow._verticalDesiredTop, (popoutWindow.screen ? popoutWindow.screen.height : popoutWindow.height) - popoutWindow.height - Design.barSideMargin))

    margins.top: popoutWindow.vertical ? popoutWindow._verticalClampedTop : popoutWindow._horizontalTopMargin
    margins.left: popoutWindow.vertical ? 0 : popoutWindow._horizontalClampedLeft
    margins.right: popoutWindow.vertical ? popoutWindow._verticalRightMargin : 0

    // ── Frame-owned constants, re-declared by the SAME names PanelDialog
    //    uses so a body file reads them identically off either frame. ───
    readonly property color surfaceBase: Colours.surface
    readonly property real panelSurfaceOpacity: 0.78
    readonly property int borderWidth: Design.borderWidth

    // ── Chrome, in PanelDialog's own declaration order so the two files
    //    stay diffable: background, rim, focus grab, cascade, content. ───
    Rectangle {
        id: popoutBackground
        anchors.fill: parent
        // Uniform on all four corners — deliberately NOT PanelDialog's
        // bottom-only rounding, because this surface floats clear of
        // every screen edge and has none to sit flush against.
        radius: Design.popoutCornerRadius
        color: Qt.rgba(popoutWindow.surfaceBase.r, popoutWindow.surfaceBase.g, popoutWindow.surfaceBase.b, popoutWindow.panelSurfaceOpacity)

        // 0.78 sits above the ^quickshell-.* family layer rule's
        // ignore_alpha floor of 0.5 — going under it kills the blur
        // silently.
        Behavior on color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

    GradientBorder {
        id: popoutRim
        anchors.fill: parent
        borderWidth: popoutWindow.borderWidth
        // All four corners handed the SAME Design.popoutCornerRadius the
        // background above reads, so rim and surface can never disagree
        // about the frame's shape.
        topLeftRadius: Design.popoutCornerRadius
        topRightRadius: Design.popoutCornerRadius
        bottomLeftRadius: Design.popoutCornerRadius
        bottomRightRadius: Design.popoutCornerRadius
    }

    // T-18-13-01's whole mitigation, and this plan's single most
    // important safety property: bound to `pinned`, so an unpinned
    // preview holds no grab and requests no keyboard focus — hovering one
    // never takes the next keystroke away from the window the user is
    // typing in.
    HyprlandFocusGrab {
        id: popoutGrab
        windows: [ popoutWindow ]
        active: popoutWindow.pinned
        onCleared: popoutWindow.requestDismiss()
    }

    readonly property Cascade entranceCascade: Cascade {}

    Component.onCompleted: {
        popoutWindow.entranceCascade.bands = [popoutHeader, bodyColumn, popoutFoot];
        popoutWindow.entranceCascade.armed = true;
        popoutWindow.entranceCascade.run();
    }


    // Exit motion — faster than the entrance on purpose, the codebase's
    // existing quick-to-leave asymmetry, read off Motion and never
    // restated as a literal duration here. Copies Cascade's own
    // motion-disabled collapse fence (requestDismiss() above).
    NumberAnimation {
        id: exitFade
        target: content
        property: "opacity"
        to: 0
        duration: Motion.emphasizedOutDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.emphasizedOutEasing
        onFinished: popoutWindow.dismissFinished()
    }

    // ── Whole-surface hover (Phase 18 Plan 13 Task 2, D-18-21) — the
    //    trigger and this popout are ONE hover region held as two
    //    independent booleans; this is the popout's own half, relayed by
    //    PopoutTrigger.qml into PopoutController.popoutEntered()/
    //    popoutExited(). Read-only from outside this file; nothing but
    //    this HoverHandler ever writes it. Attached to `content` (a real
    //    Item filling the window), the same way BarCapsule.qml's own
    //    HoverHandler attaches to its Rectangle root rather than to a
    //    non-Item window type. ────────────────────────────────────────
    readonly property bool hovered: popoutHoverHandler.hovered

    Item {
        id: content
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: popoutWindow.handleEscape()
        Component.onCompleted: content.forceActiveFocus()

        HoverHandler {
            id: popoutHoverHandler
        }

        // ── Header band ───────────────────────────────────────────────
        Item {
            id: popoutHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Design.popoutHeaderHeight

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Design.spacingMd
                anchors.verticalCenter: parent.verticalCenter
                spacing: Design.spacingSm

                Text {
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.iconSizeMd
                    text: popoutWindow.popoutGlyph
                    textFormat: Text.PlainText
                    color: Colours.onSurface
                }
                Text {
                    text: popoutWindow.popoutTitle
                    font.pixelSize: Design.fontHeading
                    font.weight: Design.weightEmphasis
                    textFormat: Text.PlainText
                    color: Colours.onSurface
                }
            }
        }

        // ── Body slot — Task 3 (this same plan) adds a foot band below
        //    this and appends it to entranceCascade.bands, and adjusts
        //    implicitHeight above to include it. Fixed inner width off
        //    Design tokens, never off popoutWindow's own resolved width
        //    (that would be circular) — a glance surface's content is
        //    bounded by construction, so this never needs to grow past
        //    Design.popoutMaxWidth. ───────────────────────────────────
        Column {
            id: bodyColumn
            anchors.top: popoutHeader.bottom
            anchors.left: parent.left
            anchors.leftMargin: Design.spacingMd
            width: Design.popoutMaxWidth - Design.spacingMd * 2
            spacing: Design.spacingMd
        }

        // ── Task 3 — the frame-owned state placeholder. Anchored to the
        //    body REGION rather than declared inside bodyColumn itself,
        //    the same reason PanelDialog.qml's own comment gives:
        //    bodyColumn is content a popout body writes into, while this
        //    placeholder is the frame's own fallback. Visible whenever
        //    the state is not populated — a quiet Material Symbol plus
        //    one line, never a blank body. ─────────────────────────────
        Column {
            id: statePlaceholder
            anchors.centerIn: bodyColumn
            visible: popoutWindow.bodyState !== "populated"
            spacing: Design.spacingSm

            readonly property string _glyph: popoutWindow.bodyState === "pending" ? popoutWindow.pendingStateGlyph
                : popoutWindow.bodyState === "failed" ? popoutWindow.failedStateGlyph
                : popoutWindow.emptyStateGlyph
            readonly property string _text: popoutWindow.bodyState === "pending" ? popoutWindow.pendingStateText
                : popoutWindow.bodyState === "failed" ? popoutWindow.failedStateText
                : popoutWindow.emptyStateText

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: statePlaceholder._glyph
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                textFormat: Text.PlainText
                color: popoutWindow.stateColour(popoutWindow.bodyState)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: statePlaceholder._text
                font.pixelSize: Design.fontBody
                textFormat: Text.PlainText
                color: popoutWindow.stateColour(popoutWindow.bodyState)
            }
        }

        // ── Task 3 — the foot wayfinding link. A plain pill in the
        //    surface-variant role, NEVER accent-toned — PanelDialog.qml's
        //    Advanced button treatment reused exactly, only its position
        //    moves from the header to the foot. ───────────────────────
        // Operator's call, 2026-08-12: the foot was a left-aligned pill
        // carrying its destination as a text label ("Open Wi-Fi settings" and
        // its six siblings). It is now a CENTRED glyph-only pill. Anchored
        // left AND right, where it was previously left only, because a
        // horizontalCenter has nothing to centre within until the item spans
        // the frame's inner width.
        Item {
            id: popoutFoot
            anchors.top: bodyColumn.bottom
            anchors.topMargin: Design.spacingMd
            anchors.left: parent.left
            anchors.leftMargin: Design.spacingMd
            anchors.right: parent.right
            anchors.rightMargin: Design.spacingMd
            height: Design.iconSizeMd + Design.spacingSm * 2

            readonly property real disabledOpacity: 0.38

            Rectangle {
                id: wayfindingPill
                // Was label-width-driven; now a fixed pill sized off the
                // glyph it holds, so all seven popouts show an identically
                // sized control regardless of how long their destination
                // name is.
                width: Design.iconSizeMd + Design.spacingLg
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                radius: height / 2
                color: Colours.surfaceVariant
                opacity: popoutWindow.wayfindingAvailable ? 1 : popoutFoot.disabledOpacity

                Text {
                    id: wayfindingLabelText
                    anchors.centerIn: parent
                    // "more_horiz" is a Material Symbols ligature, verified
                    // PRESENT in the installed MaterialSymbolsRounded variable
                    // font via fontTools before use, alongside a deliberately
                    // nonexistent control name that correctly reported absent.
                    // GATE-02 row A.3's named failure mode is a nonexistent
                    // ligature rendering as its own name in plain text — and
                    // this site is now the ONLY thing in the foot, so that
                    // failure would leave the word "more_horiz" sitting in
                    // every popout.
                    text: "more_horiz"
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.iconSizeMd
                    textFormat: Text.PlainText
                    color: Colours.onSurfaceVariant
                    opacity: popoutWindow.wayfindingAvailable ? 1 : popoutFoot.disabledOpacity
                }

                // The MouseArea itself stays enabled: "a press does
                // nothing at all" is guaranteed by activateWayfinding()'s
                // own early-return guard above, not by disabling this —
                // a disabled MouseArea would also stop receiving hover,
                // making the reason UNREACHABLE, which is exactly what
                // PanelDialog.qml's own Advanced button comment warns
                // against.
                // F2 (quick task 260812-69w) — deliberately LEFT AS a
                // standalone ToolTip, not converted to BarTooltipHost. Same
                // reasoning as AudioPopout.qml's own audioMuteMouseArea
                // comment: this frame is several hundred pixels tall (Task
                // 1's Probe B measured the sibling site's Popup clamp
                // landing at y=60, fully clear of its glyph, in the same
                // window architecture this foot link shares), so there is
                // no overlap here to fix. Orthogonal to the colour fix below
                // (quick-260821-6z1 fix wave) — see ThemedToolTip.qml.
                MouseArea {
                    id: wayfindingMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: popoutWindow.activateWayfinding()
                }
                ThemedToolTip {
                    visible: wayfindingMouseArea.containsMouse
                    // The label VERBATIM, not "Open " + label.toLowerCase().
                    // Every one of the seven wayfindingLabel values already
                    // begins with "Open", so the old expression rendered "Open
                    // open wi-fi settings" — a harmless wording slip while the
                    // label was also drawn on the pill, but this tooltip is now
                    // the only place the destination appears at all, so it has
                    // to read correctly.
                    text: popoutWindow.wayfindingAvailable ? popoutWindow.wayfindingLabel : popoutWindow.wayfindingUnavailableReason
                }
            }
        }
    }
}
