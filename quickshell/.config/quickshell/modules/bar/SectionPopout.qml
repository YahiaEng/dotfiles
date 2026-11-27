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
    // Trigger centre in output coordinates along the bar's length,
    // measured by PopoutTrigger when the panel opens.
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
        case "populated": return BarRoles.popoutFg;
        case "pending": return BarRoles.accent;
        case "empty": return BarRoles.capsuleFg;
        case "failed": return BarRoles.danger;
        default: return BarRoles.popoutFg;
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

    // Guards re-entry the way PowerMenu._beginDismiss and Dashboard's own
    // dismiss do — a second dismiss mid-flight must not restart the exit.
    property bool _dismissing: false

    function requestDismiss() {
        // Teardown race (found 2026-08-28, quick task 260828-pol, by opening
        // and closing all eight bar popouts back to back): the host can
        // unload this surface's LazyLoader while a dismiss is still queued,
        // and a QML `id` naming a destroyed object evaluates to null — so
        // this fired "TypeError: Cannot call method 'dismissRequested' of
        // null" on the way out. Nothing to report when it happens: the
        // surface the caller wanted dismissed is already gone, which is the
        // outcome requestDismiss() exists to produce.
        if (!popoutWindow)
            return;
        popoutWindow.dismissRequested();
        if (!Motion.motionEnabled) {
            // D-21's `off` collapse, mirrored: no animation, straight to
            // the finished signal.
            popoutWindow.dismissFinished();
            return;
        }
        if (popoutWindow._dismissing)
            return;
        // Order matters: the flag must be set BEFORE `opened` flips, because
        // every Behavior above reads it to choose the mirrored easing at the
        // moment the animation starts. Setting it after would run the first
        // exit on the entrance curve.
        popoutWindow._dismissing = true;
        popoutWindow.opened = false;
        exitHold.start();
    }

    // Emits the real `dismissFinished()` only once the exit has actually
    // played, so the host never destroys this surface with a frame of exit
    // still on screen — the property Dashboard.qml's own dismiss relies on.
    //
    // A timer rather than one Behavior's `onRunningChanged`: the slide and
    // the fade run on DIFFERENT tokens (spatial vs emphasized), so there is
    // no single animation whose end is the exit's end. The hold is the
    // longer of the two, read from the tokens rather than restated, so the
    // motion-scale axis still governs it.
    Timer {
        id: exitHold
        interval: Math.max(Motion.spatialInDuration, Motion.emphasizedInDuration)
        repeat: false
        // Same teardown race as requestDismiss() above — the hold can outlive
        // the surface, and `popoutWindow` is null once it is destroyed.
        onTriggered: {
            if (popoutWindow)
                popoutWindow.dismissFinished();
        }
    }

    // Esc routes through this rather than straight to requestDismiss() —
    // the same override seam PanelDialog.qml exposes for a later
    // two-stage Esc. Default body just dismisses.
    function handleEscape() {
        popoutWindow.requestDismiss();
    }

    // ── Layer posture — every line commented against what it differs
    //    from in PanelDialog and why. ────────────────────────────────────
    screen: PopoutController.rootScreen
    anchors {
        top: true
        left: !popoutWindow.vertical
        right: popoutWindow.vertical
    }

    // All margins use the same screen coordinate space as the trigger.
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: -1
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
    // ── PANEL vs WINDOW (quick task 260825-pyf, Task 4) ─────────────────
    // These used to BE the window's implicit size. They are now the
    // PANEL's, and the window is the panel plus room for the weld flares.
    //
    // The flares have to exist, and they have to paint OUTSIDE the panel:
    // `AttachedCorner`'s whole reason for being a separate sibling rather
    // than a property of the panel is that a concave corner cannot be
    // rendered by the panel's own Rectangle and must be drawn beyond its
    // bounds. The dashboard gets that for free — its `panel` is an Item
    // inside a full-screen window. This surface was sized exactly to its
    // content, so there was nowhere for a flare to go, and without one the
    // panel would meet the bulge at a hard corner: precisely the butt joint
    // just removed from the weld corners in 260825-ore.
    //
    // So the window grows by `attachedCornerRadius` at each end of the BAR
    // axis and the panel is inset by the same amount. Only the bar axis:
    // the flares sit at the two corners where the panel meets the bar's
    // edge, which for a vertical bar means above and below it, never
    // further into the screen. And only while attached — unattached the
    // window is exactly its panel again, byte-identical to before.
    readonly property real panelWidth: Math.max(Design.popoutMinWidth, Math.min(Design.popoutMaxWidth, bodyColumn.implicitWidth + Design.spacingMd * 2))
    // Header, body, ONE spacing gap, the foot band, and a final spacing
    // gap below it (Task 3 appends the foot band to this sum).
    readonly property real panelHeight: Design.popoutHeaderHeight + bodyColumn.implicitHeight + Design.spacingMd + popoutFoot.height + Design.spacingMd

    readonly property bool attached: PopoutController.rootAttached
    readonly property int flareRadius: attached ? Design.attachedCornerRadius : 0
    readonly property real slabDepth: attached ? PopoutController.rootSlabWidth : 0

    implicitWidth: popoutWindow.panelWidth + (vertical ? slabDepth : 2 * flareRadius)
    implicitHeight: popoutWindow.panelHeight + (vertical ? 2 * flareRadius : slabDepth)

    property bool opened: false
    property bool _armed: false

    function _armAndOpen() {
        if (popoutWindow.opened || popoutWindow._dismissing || popoutWindow.panelHeight <= 0 || popoutWindow.panelWidth <= 0)
            return;
        popoutWindow._armed = true;
        // The content stagger starts with the slide, not before it. It used
        // to run at `Component.onCompleted`, one `Qt.callLater` ahead of the
        // open flip, which was near enough to simultaneous to not matter.
        // The flip now waits for the settle, so leaving the cascade behind
        // would play the first band's fade while the panel is still off-view.
        popoutWindow.entranceCascade.run();
        Qt.callLater(function () {
            if (!popoutWindow._dismissing)
                popoutWindow.opened = true;
        });
    }

    // Wait for the content size and orientation before starting the slide.
    Timer {
        id: armSettleTimer
        interval: 60
        repeat: false
        onTriggered: popoutWindow._armAndOpen()
    }
    onPanelHeightChanged: if (!popoutWindow.opened) armSettleTimer.restart()
    onPanelWidthChanged: if (!popoutWindow.opened) armSettleTimer.restart()
    onVerticalChanged: if (!popoutWindow.opened) armSettleTimer.restart()
    onAttachedChanged: if (!popoutWindow.opened) armSettleTimer.restart()

    // Hard stop: never leave a popout invisible if the size never settles.
    // Routed through the same path so the arm/flip ordering holds here too.
    Timer {
        id: armHardStop
        interval: 500
        running: !popoutWindow.opened
        repeat: false
        onTriggered: popoutWindow._armAndOpen()
    }

    // Clip the moving panel at the inner edge of the bar. The attached
    // surface starts at the slab's outer edge; its input region starts at
    // the visible body so the transparent overlap never steals hover.
    mask: Region {
        item: popoutInput
    }

    Item {
        id: popoutInput
        x: spawnClip.x + Math.max(0, panel.x)
        y: spawnClip.y + Math.max(0, panel.y)
        width: Math.max(0, Math.min(spawnClip.width, panel.x + panel.width) - Math.max(0, panel.x))
        height: Math.max(0, Math.min(spawnClip.height, panel.y + panel.height) - Math.max(0, panel.y))
    }

    Item {
        id: spawnClip
        y: popoutWindow.vertical ? 0 : popoutWindow.slabDepth
        width: popoutWindow.panelWidth + (popoutWindow.vertical ? 0 : 2 * popoutWindow.flareRadius)
        height: popoutWindow.panelHeight + (popoutWindow.vertical ? 2 * popoutWindow.flareRadius : 0)
        clip: true

    Item {
        id: panel
        width: popoutWindow.panelWidth
        height: popoutWindow.panelHeight
        x: popoutWindow.vertical
            ? (popoutWindow.opened ? 0 : width)
            : popoutWindow.flareRadius
        y: popoutWindow.vertical
            ? popoutWindow.flareRadius
            : (popoutWindow.opened ? 0 : -height)

        Behavior on x {
            enabled: Motion.motionEnabled && popoutWindow._armed
            NumberAnimation {
                duration: Motion.spatialInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: popoutWindow._dismissing ? Motion.spatialInReverseEasing : Motion.spatialInEasing
            }
        }
        Behavior on y {
            enabled: Motion.motionEnabled && popoutWindow._armed
            NumberAnimation {
                duration: Motion.spatialInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: popoutWindow._dismissing ? Motion.spatialInReverseEasing : Motion.spatialInEasing
            }
        }
    }


    // ── Chrome, in PanelDialog's own declaration order so the two files
    //    stay diffable: background, rim, focus grab, cascade, content. ───
    Rectangle {
        id: popoutBackground
        anchors.fill: panel
        // Uniform on all four corners while UNATTACHED — the original
        // reasoning, still true then: the surface floats clear of every
        // screen edge and has none to sit flush against.
        //
        // Attached, the two corners on the bar side square off so the panel
        // and the bulge form one silhouette instead of two shapes touching.
        // Same rule the dashboard applies to its own top pair, and the same
        // reason: a rounded corner against a flat shelf leaves a visible
        // pinch that the flares below then have nothing to weld across.
        radius: Design.popoutCornerRadius
        topLeftRadius: popoutWindow.attached && !popoutWindow.vertical ? 0 : Design.popoutCornerRadius
        topRightRadius: popoutWindow.attached ? 0 : Design.popoutCornerRadius
        bottomRightRadius: popoutWindow.attached && popoutWindow.vertical ? 0 : Design.popoutCornerRadius
        color: Qt.rgba(popoutWindow.surfaceBase.r, popoutWindow.surfaceBase.g, popoutWindow.surfaceBase.b, popoutWindow.panelSurfaceOpacity)

        // 0.78 sits above the ^quickshell-.* family layer rule's
        // ignore_alpha floor of 0.5 — going under it kills the blur
        // silently.
        Behavior on color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.colourDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.colourEasing
            }
        }
    }

    // ── Attached-edge border clip ───────────────────────────────────────
    // `Dashboard.qml`'s `dashboardBorderClip` and `Launcher.qml`'s twin,
    // applied here — this surface shipped without it and the operator
    // reported the exact symptom those two were built to fix: "they have
    // corner flares while still having the old square corners", and "the
    // edge that is attached to the bulge, which is supposed to be gone".
    //
    // Once a flare is welded across a corner, the attached edge and the
    // adjacent `attachedCornerRadius` of BOTH neighbouring sides stop
    // being outer edges of the merged panel+flare silhouette. Draw the
    // ring there anyway and the panel's own border runs straight past the
    // flare's arc as a second parallel rim line — which is precisely what
    // "flares alongside the old geometry" looks like.
    //
    // The right margin alone is enough here, and the asymmetry with the
    // dashboard is worth stating: inset only the RIGHT edge and the clip's
    // origin does not move, so the rim needs no compensating offset. The
    // dashboard insets the TOP, which DOES move its origin down, which is
    // why its own rim carries `y: -attachedCornerRadius` and this one
    // carries nothing.
    Item {
        id: popoutBorderClip
        anchors.fill: panel
        anchors.rightMargin: popoutWindow.vertical ? popoutWindow.flareRadius : 0
        anchors.topMargin: popoutWindow.vertical ? 0 : popoutWindow.flareRadius
        clip: true

        GradientBorder {
            id: popoutRim
            x: 0
            y: -popoutBorderClip.anchors.topMargin
            width: panel.width
            height: panel.height
            borderWidth: popoutWindow.borderWidth
            // Every corner handed the SAME value the background reads,
            // including the attached squaring — rim and surface must never
            // disagree about the frame's shape.
            topLeftRadius: popoutBackground.topLeftRadius
            topRightRadius: popoutBackground.topRightRadius
            bottomLeftRadius: Design.popoutCornerRadius
            bottomRightRadius: popoutBackground.bottomRightRadius
        }
    }

    // Both flares follow the panel's animated geometry.
    Repeater {
        model: popoutWindow.attached ? 2 : 0

        delegate: AttachedCorner {
            id: flare
            required property int index
            readonly property bool first: index === 0

            edge: popoutWindow.vertical && first ? "bottom" : "top"
            side: popoutWindow.vertical || first ? "left" : "right"
            flareRadius: popoutWindow.flareRadius
            x: popoutWindow.vertical
                ? panel.x + panel.width - width
                : (first ? panel.x - width : panel.x + panel.width)
            y: popoutWindow.vertical
                ? (first ? panel.y - height : panel.y + panel.height)
                : panel.y
            fillColour: popoutBackground.color
            borderWidth: popoutWindow.borderWidth
            angle: popoutRim.startAngle + popoutRim.angle
            gradientCentre: Qt.point(panel.x + panel.width / 2 - x, panel.y + panel.height / 2 - y)
            gradientHalfDiagonal: Math.sqrt(panel.width * panel.width + panel.height * panel.height) / 2
        }
    }

    Item {
        id: content
        anchors.fill: panel
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

                ShellText {
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.iconSizeMd
                    text: popoutWindow.popoutGlyph
                    textFormat: Text.PlainText
                    color: BarRoles.popoutFg
                }
                ShellText {
                    text: popoutWindow.popoutTitle
                    font.pixelSize: Design.fontHeading
                    font.weight: Design.weightEmphasis
                    textFormat: Text.PlainText
                    color: BarRoles.popoutFg
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

            ShellText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: statePlaceholder._glyph
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                textFormat: Text.PlainText
                color: popoutWindow.stateColour(popoutWindow.bodyState)
            }
            ShellText {
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
                color: BarRoles.popoutSurfaceVariant
                opacity: popoutWindow.wayfindingAvailable ? 1 : popoutFoot.disabledOpacity

                ShellText {
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
                    color: BarRoles.capsuleFg
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


    // Fit the entire surface, including both flares, on the bar's straight edge.
    readonly property real alongExtent: vertical ? implicitHeight : implicitWidth
    readonly property real screenAlong: screen ? (vertical ? screen.height : screen.width) : alongExtent
    readonly property real alongMargin: Math.min(Design.barSideMargin, Math.max(0, (screenAlong - alongExtent) / 2))
    readonly property var hostBar: PopoutController.activeBar
    readonly property bool fitsWeld: attached && Boolean(hostBar)
        && hostBar.popoutWeldEnd - hostBar.popoutWeldStart >= alongExtent
    readonly property real alongStart: {
        const first = fitsWeld ? Math.ceil(hostBar.popoutWeldStart) : alongMargin;
        const last = fitsWeld ? Math.floor(hostBar.popoutWeldEnd - alongExtent)
                             : screenAlong - alongExtent - alongMargin;
        return Math.max(first, Math.min(Math.round(triggerCentre - alongExtent / 2), last));
    }
    readonly property real acrossStart: attached ? PopoutController.rootOuterInset : PopoutController.rootInset

    margins.top: vertical ? alongStart : acrossStart
    margins.left: vertical ? 0 : alongStart
    margins.right: vertical ? acrossStart : 0

    readonly property color surfaceBase: BarRoles.popoutSurface
    readonly property real panelSurfaceOpacity: 0.78
    readonly property int borderWidth: Design.borderWidth




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
        armSettleTimer.restart();
    }

    Binding {
        target: PopoutController
        property: "openTop"
        value: popoutWindow.alongStart + popoutWindow.flareRadius
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: PopoutController
        property: "openExtent"
        value: popoutWindow.vertical ? popoutWindow.panelHeight : popoutWindow.panelWidth
        restoreMode: Binding.RestoreNone
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

}
