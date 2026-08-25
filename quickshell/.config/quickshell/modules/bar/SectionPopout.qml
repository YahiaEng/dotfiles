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

    // Guards re-entry the way PowerMenu._beginDismiss and Dashboard's own
    // dismiss do — a second dismiss mid-flight must not restart the exit.
    property bool _dismissing: false

    function requestDismiss() {
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
        onTriggered: popoutWindow.dismissFinished()
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

    readonly property int flareRadius: popoutWindow.attached ? Design.attachedCornerRadius : 0

    implicitWidth: popoutWindow.panelWidth
    implicitHeight: popoutWindow.panelHeight + 2 * popoutWindow.flareRadius

    // The panel proper. Everything that used to fill the window now fills
    // this, so the flares have the margin they need to draw into.
    // ── Entrance and exit (quick task 260825-pyf, Task 4) ───────────────
    // `Dashboard.qml`'s own two lines, verbatim in shape:
    //     y: opened ? 0 : -height
    //     opacity: opened ? 1 : 0
    // — a slide along the axis it is attached to, plus a fade, on the
    // spatial register, with the exit running the ENTRANCE easing MIRRORED
    // rather than the shorter out-token (operator round 9, 260823-9ak: the
    // dismiss must be a reverse of the spawn, not a different, faster
    // motion on a different curve family).
    //
    // WHICH AXIS depends on where it is rooted, and that is the whole
    // point: attached, it grows sideways out of the bulge on the bar's
    // edge; unattached, it drops from the top of the Hyprland windows. Both
    // are the dashboard's motion, aimed at the edge this panel actually
    // belongs to.
    //
    // POSITIONED, NOT TRANSFORMED. `panel` carries an explicit x/y/width/
    // height rather than `anchors.fill` plus a Translate, because the two
    // weld flares are SIBLINGS anchored to `panel.top`/`panel.bottom`:
    // anchors track an item's real geometry, so moving `panel.x` carries
    // them along, while a transform would have slid the panel out from
    // under two flares left standing at the bulge. Dashboard.qml's own
    // panel/flare pair is built exactly this way for exactly this reason.
    property bool opened: false
    readonly property bool _slideFromBar: popoutWindow.attached && popoutWindow.vertical

    // ── ARM BEFORE OPENING (quick task 260825-sgm) ──────────────────────
    // `Launcher.qml`'s guard, adopted whole, because this file has now been
    // bitten by the same trap twice and the closed state is what it bites.
    //
    // `PopoutTrigger.qml:173-175` assigns `vertical`, `pinned` and
    // `triggerCentre` onto this item AFTER the component is constructed, and
    // `attached` arrives by Binding. So `_slideFromBar` is FALSE at
    // construction no matter what it will settle to. Round 3 read it at
    // construction and every popout published centre 0, stacking all eight at
    // the top of the bar. Round 4 read it for a closed WIDTH and the reveal
    // ran 360 -> 0 -> 360, so the panel simply appeared. Both bugs are the
    // same shape: a CLOSED value that depends on a loader-assigned property,
    // evaluated at construction, which is the one moment that property is
    // guaranteed wrong.
    //
    // The guard does not try to read those properties earlier. It waits.
    // While `_armed` is false every Behavior in the entrance path is disabled,
    // so the closed offsets track instantly and the panel simply waits
    // off-view whatever they resolve to. `_armAndOpen` flips `opened` only
    // once things have held still, and arms one tick BEFORE that flip so
    // `Behavior.enabled` has already re-evaluated true when the change lands —
    // doing both in one tick leaves that ordering to chance.
    property bool _armed: false

    function _armAndOpen() {
        if (popoutWindow.opened || popoutWindow.panelHeight <= 0 || popoutWindow.panelWidth <= 0)
            return;
        popoutWindow._armed = true;
        // The content stagger starts with the slide, not before it. It used
        // to run at `Component.onCompleted`, one `Qt.callLater` ahead of the
        // open flip, which was near enough to simultaneous to not matter.
        // The flip now waits for the settle, so leaving the cascade behind
        // would play the first band's fade while the panel is still off-view.
        popoutWindow.entranceCascade.run();
        Qt.callLater(function () {
            popoutWindow.opened = true;
        });
    }

    // Debounced: the popout is content-bounded, so its size arrives in stages
    // and flipping at the first non-zero value would slide it a token few px
    // instead of its full width. Each size change restarts the timer, so the
    // slide starts once the size has held still for one interval.
    //
    // `_slideFromBar` restarts it TOO, and that is the half `Launcher.qml`
    // does not need: the launcher branches its direction on a property the
    // shell root owns, while this file's comes from the loader. Re-debouncing
    // on it means a late `vertical` or `attached` cannot land after the arm
    // and animate the wrong axis — the hole the size-only guard would leave.
    Timer {
        id: armSettleTimer
        interval: 60
        repeat: false
        onTriggered: popoutWindow._armAndOpen()
    }
    onPanelHeightChanged: if (!popoutWindow.opened) armSettleTimer.restart()
    onPanelWidthChanged: if (!popoutWindow.opened) armSettleTimer.restart()
    on_SlideFromBarChanged: if (!popoutWindow.opened) armSettleTimer.restart()

    // Hard stop: never leave a popout invisible if the size never settles.
    // Routed through the same path so the arm/flip ordering holds here too.
    Timer {
        id: armHardStop
        interval: 500
        running: !popoutWindow.opened
        repeat: false
        onTriggered: popoutWindow._armAndOpen()
    }

    // ── SLIDE OUT OF THE BULGE (quick task 260825-sgm) ──────────────────
    // OPERATOR: "I want them to be a close copy to the animations of the app
    // dashboard and super+space/super-tab. Meaning the animation starts from
    // the bulge and the dismissal is a reversal of the spawn animation."
    //
    // So this is the dashboard's motion again, with the axis rotated onto the
    // edge this panel actually belongs to. `Dashboard.qml`'s panel is
    // `y: opened ? 0 : -height` off the TOP rail; `Launcher.qml`'s is the same
    // pair off whichever rail is present. Attached here means the RIGHT slab,
    // so the same pair runs on `x`, and the closed offset is `+panelWidth`.
    //
    // WHAT THIS REPLACED, and why the replacement is not a regression to it.
    // Round 4 of 260825-pyf made this a width REVEAL: a container pinned to
    // the surface's right edge whose width grew from zero while the panel
    // inside stayed put. It was built to fix a real complaint — that the
    // weld only arrived in the final frame — but it fixed it by inventing a
    // motion this shell uses nowhere else. The dashboard has exactly the same
    // property (its `AttachedCorner` pair rides its panel and lands with it)
    // and the operator likes the dashboard. Matching it is the request; the
    // late weld is a consequence the reference already has.
    //
    // DISTANCE IS THE PANEL'S OWN WIDTH, NEVER THE SURFACE'S. That is
    // `Launcher.qml`'s hard-won rule, quoted from its own comment: "never
    // derive a layer-shell surface's entrance geometry from that surface's
    // own height. Anchor to the edge and animate a TRANSLATION whose distance
    // depends only on the panel's own height." Layer surfaces are configured
    // in STAGES, so a distance read off the surface tracks a value that keeps
    // growing and drags the panel long after it has opened. `panelWidth` is
    // content-derived and settles once.
    //
    // The surface's right edge is already seated on the bulge's face by
    // `margins.right: PopoutController.rootInset`, and a layer surface clips
    // to its own buffer — so a panel held one full width to the right of its
    // open position is entirely hidden behind the bar, and emerges leftward
    // out of the bulge. The dashboard hides behind the screen edge the same
    // way.
    //
    // `spawnClip` STAYS, stripped to what it is actually needed for: the
    // OPACITY CARRIER. `popoutBackground`, `popoutBorderClip`, the two
    // `AttachedCorner` flares and `content` are SIBLINGS of `panel` anchored
    // to it, not children of it, so they do not inherit `panel`'s opacity —
    // this container is their only common parent. Its `width`, its
    // `Behavior on width` and its `clip` are gone; nothing else moved, which
    // keeps every one of those anchors legal (they may only target a sibling
    // or the parent, and re-parenting six children back out through the
    // interleaved root-level `readonly property` declarations is exactly the
    // move that was caught before it wrote in round 4).
    Item {
        id: spawnClip
        anchors.fill: parent
        opacity: popoutWindow.opened ? 1 : 0

        Behavior on opacity {
            enabled: Motion.motionEnabled && popoutWindow._armed
            NumberAnimation {
                duration: Motion.emphasizedInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: popoutWindow._dismissing ? Motion.emphasizedInReverseEasing : Motion.emphasizedInEasing
            }
        }

    Item {
        id: panel
        width: popoutWindow.panelWidth
        height: popoutWindow.panelHeight

        // POSITIONED, NOT ANCHORED, and not transformed either.
        //
        // Not anchored: an `anchors.right` would OVERRIDE `x`, so the slide
        // below would be inert. The surface's own `implicitWidth` IS
        // `panelWidth`, so `x: 0` already seats the panel flush against the
        // container's right edge — the anchor bought nothing the open value
        // does not already give.
        //
        // Not transformed: the two `AttachedCorner` flares are SIBLINGS
        // anchored to `panel.right`/`panel.top`/`panel.bottom`. Anchors track
        // an item's real geometry and a transform does not, so moving `x`
        // carries the flares while a `Translate` would have slid the panel
        // out from under two flares left standing at the bulge.
        // `Dashboard.qml`'s own panel/flare pair is built this way for this
        // reason. (`Launcher.qml` may use a `Translate` because its
        // background FILLS its panel — it has no sibling to strand.)
        //
        // Both closed offsets are stated unconditionally against
        // `_slideFromBar`, which is safe ONLY because of the arm guard below:
        // while disarmed these snap rather than animate, and any late arrival
        // of `vertical`/`attached` re-debounces the open. Without that guard
        // this would be the construction-time trap for the third time in this
        // file — see `_armAndOpen`.
        //
        // x — the ATTACHED slide, out of the bulge on the right slab.
        //     Distance is `panelWidth`: the panel's own width, never the
        //     surface's (Launcher.qml's rule; staged configures make a
        //     surface-derived distance drag the panel after it has opened).
        x: popoutWindow.opened || !popoutWindow._slideFromBar
            ? 0
            : popoutWindow.panelWidth
        // y — the UNATTACHED drop from the top of the Hyprland windows.
        //     The flare inset is a constant offset, present in both states,
        //     so the panel never lands 24px off its own window.
        y: popoutWindow.flareRadius
            + (popoutWindow.opened || popoutWindow._slideFromBar ? 0 : -popoutWindow.panelHeight)

        // One pair, both axes: the spatial register in, its own mirror out.
        // The reversal costs nothing extra here — the closed offset is the
        // same value in both directions, so the point-reflected curve simply
        // retraces whichever path the entrance took. The entrance overshoot
        // surfaces as a brief recoil at the START of the dismiss; that is the
        // reversal, not a defect (Dashboard.qml says the same of its own).
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
        topRightRadius: popoutWindow.attached ? 0 : Design.popoutCornerRadius
        bottomRightRadius: popoutWindow.attached ? 0 : Design.popoutCornerRadius
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
        anchors.rightMargin: popoutWindow.flareRadius
        clip: true

        GradientBorder {
            id: popoutRim
            x: 0
            y: 0
            width: panel.width
            height: panel.height
            borderWidth: popoutWindow.borderWidth
            // Every corner handed the SAME value the background reads,
            // including the attached squaring — rim and surface must never
            // disagree about the frame's shape.
            topLeftRadius: Design.popoutCornerRadius
            topRightRadius: popoutBackground.topRightRadius
            bottomLeftRadius: Design.popoutCornerRadius
            bottomRightRadius: popoutBackground.bottomRightRadius
        }
    }

    // ── The weld flares (quick task 260825-pyf, Task 4) ─────────────────
    // The concave corners that carry the panel's silhouette into the
    // bulge's, so the two read as one shape. Exactly what
    // `Dashboard.qml`'s own `dashboardFlareLeft`/`Right` pair does where it
    // meets the top rail — the same component, the same inputs, TRANSPOSED
    // for an edge that runs vertically instead of horizontally.
    //
    // ── READ THE edge/side NAMES CAREFULLY, THEY LOOK BACKWARDS ─────────
    // `AttachedCorner` names its two lines for the horizontal case it was
    // written for: `edge` picks which local Y is the attached-edge line and
    // `side` picks which local X is the panel-touching line. Here those
    // ROLES ARE SWAPPED — the attached edge is the bulge's vertical face and
    // the panel-touching lines are horizontal. The shape does not care: a
    // quarter-pipe in a square is fully determined by WHICH CORNER the
    // material hugs, and (edge, side) together pick that corner. So the
    // right combination is chosen by naming the corner, not by reading the
    // property names literally:
    //
    //   panel's TOP-right corner    -> material hugs local (R, R)
    //                               -> touchX = R (side "left"),
    //                                  edgeY  = R (edge "bottom")
    //   panel's BOTTOM-right corner -> material hugs local (R, 0)
    //                               -> touchX = R (side "left"),
    //                                  edgeY  = 0 (edge "top")
    //
    // Hence `edge: "bottom"` on the flare at the panel's TOP. That is not a
    // typo and it is not a bug — inverting it to match the name would put
    // the arc on the wrong diagonal and render a CONVEX lump, which is the
    // failure that file's own header warns "will look deliberate and be
    // wrong". Its sweep-flag derivation covers all four combinations, so
    // both of these resolve through the same formula the dashboard's pair
    // does; nothing new is hand-derived here.
    AttachedCorner {
        id: popoutFlareTop
        visible: popoutWindow.attached
        edge: "bottom"
        side: "left"
        flareRadius: Design.attachedCornerRadius
        anchors.right: panel.right
        anchors.bottom: panel.top
        fillColour: popoutBackground.color
        borderWidth: popoutWindow.borderWidth
        angle: popoutRim.startAngle + popoutRim.angle
        gradientCentre: Qt.point(panel.width / 2 - popoutFlareTop.x, panel.height / 2 - popoutFlareTop.y)
        gradientHalfDiagonal: Math.sqrt(panel.width * panel.width + panel.height * panel.height) / 2
    }

    AttachedCorner {
        id: popoutFlareBottom
        visible: popoutWindow.attached
        edge: "top"
        side: "left"
        flareRadius: Design.attachedCornerRadius
        anchors.right: panel.right
        anchors.top: panel.bottom
        fillColour: popoutBackground.color
        borderWidth: popoutWindow.borderWidth
        angle: popoutRim.startAngle + popoutRim.angle
        gradientCentre: Qt.point(panel.width / 2 - popoutFlareBottom.x, panel.height / 2 - popoutFlareBottom.y)
        gradientHalfDiagonal: Math.sqrt(panel.width * panel.width + panel.height * panel.height) / 2
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
    // ── LIVE, NOT HARDCODED (quick task 260825-pyf, Task 2) ─────────────
    // These were `Design.barSideMargin` (10), chosen because gaps_out was
    // 10 on the day it was measured — and the note above says so, ending
    // "if general:gaps_out changes, this alignment needs revisiting (a QML
    // surface cannot read it live)."
    //
    // It changed. gaps_out is 20 now (operator-confirmed intended,
    // 2026-08-25) with border_size 0, and tiled clients report at=[20,26]
    // against reserved [0,6,50,6]. So every popout was landing 10px inside
    // the window edge it was written to line up with — a real, measurable
    // miss, not a theoretical one.
    //
    // `WindowInset` reads the option live and re-reads it on every
    // Hyprland `configreloaded`, which is exactly when it can change:
    // `lib/reload.sh` runs `hyprctl reload` on every theme and motion
    // apply, re-applying `~/.local/state/hypr/overrides.lua` where
    // gaps_out actually lives on this host.
    //
    // Per-edge, not one number: gaps_out is a four-sided CSS gap, so the
    // top margin asks for the top gap and the right margin asks for the
    // right one. They are equal today; asking correctly costs nothing and
    // stops this file being wrong again the moment they are not.
    readonly property int _horizontalTopMargin: WindowInset.insetFor("top")
    readonly property int _verticalRightMargin: WindowInset.insetFor("right")

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

    // The vertical pair that used to live here — `_verticalDesiredTop` and
    // `_verticalClampedTop`, tracking `triggerCentre` down the bar — is GONE
    // (quick task 260825-pyf, Task 4), not merely unused. Neither posture
    // wants it any more: attached aligns to the bar's own clamped bulge
    // centre (`_attachedClampedTop`), and unattached is pinned to the top of
    // the Hyprland windows by request. Left in place they would have read
    // as the live positioning path to the next person to open this file.
    //
    // The origin-conversion notes above are NOT stale with them: the
    // horizontal pair below still performs exactly that conversion, and the
    // `+ Design.barSideMargin` in it is the same bar-window-to-screen origin
    // those paragraphs were written about.

    // ── ATTACHED vs UNATTACHED (quick task 260825-pyf, Task 4) ──────────
    // Attached: the bar's edge has grown a bulge under this popout and the
    // panel welds to it, the way the dashboard welds to the top rail.
    // Unattached: there is no painted bar edge to weld to, so the panel
    // spawns from the top of the Hyprland windows instead.
    //
    // The predicate is the BAR's, published rather than re-derived here —
    // `rootAttached` is false for every style but Continuous AND for
    // Continuous while the bar is horizontal, because outside that one
    // combination the bar paints no continuous edge at all (`barContent` is
    // a bare Item; the slab and its core are both `visible:
    // _continuousWeld`). Deriving it here from `edgeBarStyle` would get the
    // horizontal case wrong, which is precisely the class of mistake
    // `edgeBarPanelsAttach` already caught once: a predicate that is false
    // for TWO different reasons cannot be re-derived from one of them.
    readonly property bool attached: PopoutController.rootAttached

    // Where the top of the Hyprland windows actually is — the reserved
    // boundary PLUS gaps_out, verified on all four edges against live
    // client geometry (reserved [0,6,50,6] + gap 20 -> at=[20,26], and the
    // far edges match too). The compositor has already placed this surface
    // past the reserved zone, so only the gap is added here; adding the
    // reservation again is the double-count this file's own margin notes
    // record twice.
    readonly property int _windowTopMargin: WindowInset.insetFor("top")

    // Attached, vertical: the panel's own along-axis centre lines up with
    // the BULGE's centre — `rootCentre`, which the bar has already clamped
    // into the slab's straight section. Aligning to this popout's raw
    // `triggerCentre` instead would leave a panel near either end of the bar
    // hanging off the shelf it is meant to sit on.
    readonly property real _attachedTop: PopoutController.rootCentre - popoutWindow.height / 2
    readonly property real _attachedClampedTop: Math.max(popoutWindow._windowTopMargin,
        Math.min(popoutWindow._attachedTop,
                 (popoutWindow.screen ? popoutWindow.screen.height : popoutWindow.height)
                 - popoutWindow.height - popoutWindow._windowTopMargin))

    margins.top: popoutWindow.vertical
        ? (popoutWindow.attached ? popoutWindow._attachedClampedTop : popoutWindow._windowTopMargin)
        : popoutWindow._horizontalTopMargin
    margins.left: popoutWindow.vertical ? 0 : popoutWindow._horizontalClampedLeft
    // Attached: sit the panel's trailing edge exactly on the bulge's face,
    // so the two silhouettes meet and the flares below can weld them.
    // Unattached: the window's own right-edge inset.
    margins.right: popoutWindow.vertical
        ? (popoutWindow.attached ? PopoutController.rootInset : popoutWindow._verticalRightMargin)
        : 0

    // ── Frame-owned constants, re-declared by the SAME names PanelDialog
    //    uses so a body file reads them identically off either frame. ───
    readonly property color surfaceBase: Colours.surface
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

    // FOLDED INTO THE EXISTING HANDLER, not added as a second one (quick
    // task 260825-pyf, Task 1). A second `Component.onCompleted` on the
    // same object is a DUPLICATE SIGNAL HANDLER and QML rejects the file
    // outright — the trap this shell hit twice in one session during
    // 260824-ns3 round 12, on `shell.qml` and `Dashboard.qml` both.
    Component.onCompleted: {
        popoutWindow.entranceCascade.bands = [popoutHeader, bodyColumn, popoutFoot];
        popoutWindow.entranceCascade.armed = true;
        // `run()` is NOT called here any more (quick task 260825-sgm) — see
        // `_armAndOpen`, which fires it in the same tick as the open flip.
        // The bands and the arm flag still belong here: they are inputs the
        // cascade needs to exist before it can be run, and neither depends on
        // anything the loader assigns later.
        // NOTE: the bulge root is NOT published here. See the Bindings
        // below — `triggerCentre` and `vertical` do not exist yet at this
        // point, and reading them here shipped a bug.
        // The open flip is NOT made here, not even deferred by one turn
        // (quick task 260825-sgm). A single `Qt.callLater` commits the closed
        // state before the open one, which is necessary — without it both
        // land in the same frame, the Behaviors see no transition and the
        // panel appears at its final position with no entrance at all — but
        // it is not SUFFICIENT. One turn is not long enough for the loader's
        // `vertical`/`attached` assignments or for the content-bounded size
        // to settle, so the closed state it commits is the wrong one.
        //
        // `armSettleTimer` owns the flip now, through `_armAndOpen`. Started
        // here so a popout whose size never changes after construction still
        // opens; every later size change and every `_slideFromBar` change
        // restarts it, and `armHardStop` is the 500ms backstop.
        armSettleTimer.restart();
    }

    // ── Publishing the bulge root — BINDINGS, NOT A CONSTRUCTION-TIME CALL
    //    (fixed 2026-08-25, operator-reported) ─────────────────────────
    // This was a `publishRoot()` call in `Component.onCompleted`, and it
    // was WRONG in a way that looked plausible and shipped:
    //
    //   PopoutTrigger.qml:173-175 assigns `vertical`, `pinned` and
    //   `triggerCentre` onto the item AFTER the component has been
    //   created. At `Component.onCompleted` all three are still at their
    //   declared defaults — `triggerCentre` is 0 and `vertical` is false.
    //
    // So every popout published centre 0. The bar clamped that into the
    // slab's straight section, which pins it to the same place regardless
    // of which capsule was clicked, and all eight opened stacked near the
    // top of the bar instead of beside their own icon. Reported exactly
    // that way: "all popouts spawn from the same location which is at the
    // top and far away from the bar."
    //
    // The reasoning that produced the bug was that a fresh-per-summon
    // component makes construction time and summon time the same instant.
    // That part is true. What it missed is that the loader's property
    // assignments land AFTER construction — being built at summon time
    // does not mean being CONFIGURED at construction time.
    //
    // Bindings instead, so a later assignment simply flows through. This
    // does not reintroduce the live-scene-mapping hazard the snapshot
    // existed to avoid: `triggerCentre` is bound to the trigger's own
    // `_publishedCentre`, which is already a snapshot taken in
    // `publishAnchor()`. The snapshot lives in PopoutTrigger, where it
    // belongs — forwarding it is not re-measuring it.
    Binding {
        target: PopoutController
        property: "openCentre"
        // RAW: already in the bar window's own space, which is the space
        // the bar wants. Adding barSideMargin here would re-introduce the
        // double-count this file's margin notes record twice.
        value: popoutWindow.triggerCentre
    }
    Binding {
        target: PopoutController
        property: "openExtent"
        // The PANEL's extent, never the window's: while attached the window
        // is `2 * flareRadius` taller, and sizing the bulge to that would
        // make the shelf overhang the panel it roots by a flare at each end.
        // Also inherently late-settling — the popout is content-bounded, so
        // this is 0 until the body's bands have laid out, which is a second
        // reason a one-shot read at construction could never have worked.
        value: popoutWindow.vertical ? popoutWindow.panelHeight : popoutWindow.panelWidth
    }

    // One line per summon, on the shell's existing state-change log idiom.
    // This is the ONLY instrument that can reach an attached popout from
    // outside the session: the surface cannot be summoned without a
    // pointer, so a screenshot needs an operator click, but the log is
    // readable at any time and reports the numbers a screenshot would have
    // to be reverse-engineered into.
    onOpenedChanged: if (popoutWindow.opened) console.log("popout: section=" + popoutWindow.sectionId
        + " attached=" + popoutWindow.attached + " vertical=" + popoutWindow.vertical
        + " triggerCentre=" + popoutWindow.triggerCentre
        + " rootCentre=" + PopoutController.rootCentre.toFixed(1)
        + " rootInset=" + PopoutController.rootInset.toFixed(1)
        + " panel=" + popoutWindow.panelWidth.toFixed(0) + "x" + popoutWindow.panelHeight.toFixed(0)
        + " margins=[t " + popoutWindow.margins.top.toFixed(1) + ", r " + popoutWindow.margins.right.toFixed(1) + "]")


    // The content-level `exitFade` that used to live here is GONE (quick
    // task 260825-pyf, Task 4), replaced by the panel-level slide-and-fade
    // above. Two reasons, not one:
    //
    //  1. It faded `content` only, so the background and rim stayed at full
    //     opacity while the text under them vanished — invisible while the
    //     compositor was fading the whole surface out on top of it, and
    //     immediately visible once the panel started MOVING as well.
    //  2. It ran `emphasizedOut` — the quick-to-leave asymmetry. Operator
    //     round 9 of 260823-9ak overturned exactly that for the dashboard:
    //     the dismiss must be the spawn reversed, same duration, entrance
    //     easing mirrored. This surface now follows the same rule, which is
    //     the whole point of putting it on the dashboard's language.
    //
    // `dismissFinished()` is emitted by `exitHold` above instead.

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
