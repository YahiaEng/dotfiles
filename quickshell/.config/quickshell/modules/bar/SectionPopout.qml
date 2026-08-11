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
    implicitHeight: Design.popoutHeaderHeight + bodyColumn.implicitHeight + Design.spacingMd

    // ── Anchoring arithmetic — Design tokens plus triggerCentre plus this
    //    window's own screen handle; no literal pixel value anywhere.
    //    Single-edge-margin arithmetic, the same shape D-18-38 fixed for
    //    the bar's own reservation — never doubled. ──────────────────────
    readonly property int _horizontalTopMargin: Design.barEdgeMargin + Design.barHeight + Design.spacingXs
    readonly property int _verticalRightMargin: Design.barEdgeMargin + Design.barColumnWidth + Design.spacingXs

    readonly property real _horizontalDesiredLeft: Design.barSideMargin + popoutWindow.triggerCentre - popoutWindow.width / 2
    readonly property real _horizontalClampedLeft: Math.max(Design.barSideMargin, Math.min(popoutWindow._horizontalDesiredLeft, (popoutWindow.screen ? popoutWindow.screen.width : popoutWindow.width) - popoutWindow.width - Design.barSideMargin))

    readonly property real _verticalDesiredTop: Design.barSideMargin + popoutWindow.triggerCentre - popoutWindow.height / 2
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
        popoutWindow.entranceCascade.bands = [popoutHeader, bodyColumn];
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
    }
}
