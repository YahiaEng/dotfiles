// Toast.qml — a reusable transient-notice frame (Phase 19 Plan 05, Task 3;
// 19-UI-SPEC.md § "Toast frame"). Parameterised on edge/interactive/
// namespace/dismiss-interval (Phase 20 Plan 04, D-20-02/D-20-04) — see the
// <assumption_delta_decision> in that plan for why this became a promote
// rather than an add-alongside: `Toast.qml` is now a generic
// transient-notice frame with the do-not-disturb toast as one instance
// (every new property defaults to that instance's own pre-existing
// literal, so `shell.qml`'s DND `Toast` block is byte-identical before and
// after this change) and the OSD (`modules/osd/Osd.qml`) as a second.
//
// A SEPARATE module directory from `modules/notifications/`, deliberately:
// this frame is a general-purpose transient notice and burying it inside
// the notification module would make the OSD's reuse read as a
// cross-feature dependency it is not.
//
// ── Chrome only, no do-not-disturb copy anywhere in this file ────────────
// This file carries a generic content slot (`default property alias body`)
// rather than hardcoded icon/text, so chrome and content are separable at
// the type boundary. The caller (`shell.qml`'s DND instance, or
// `Osd.qml`) supplies the actual visible children; the do-not-disturb copy
// strings themselves live on `NotifServer.qml` (its own natural owner,
// since it already owns DND), never here.
//
// ── One surface, replaced in place — never stacked ───────────────────────
// `show()` sets `toastActive` true and (re)starts the auto-dismiss timer.
// If the surface is ALREADY active, `show()` only restarts the timer — it
// does NOT replay the entrance animation, because the caller's own bound
// content (declared once, reactive to whatever state it reads) has
// already updated by the time `show()` is called again; replaying the
// slide+fade here would look like a flicker on a surface that never
// actually left the screen. This is the entire mechanism behind "a second
// toast while one is showing replaces the first in place and restarts the
// timer, rather than stacking two" — there is structurally only ever one
// surface, one Timer, one exit animation.
//
// ── Motion (19-UI-SPEC.md) ────────────────────────────────────────────────
// Slides/fades in from its anchored edge (top for the DND toast, bottom
// for the OSD — see `edge` below) on Motion.standardDuration/
// standardEasing (routine register — this fires on an everyday action,
// not an emphasized one). Exits the same way, self-timed by default.
//
// ── Interactivity (Phase 20 Plan 04, D-20-07) ─────────────────────────────
// The frame is still NEVER dismissible by click, only by its own timer —
// that half of D-19-36's original claim is unchanged for every instance,
// interactive or not. What narrows: the DND toast (`interactive: false`,
// the default) carries no pointer surface at all, exactly as before —
// "feedback, not content" stays literally true for it. An
// `interactive: true` instance (the OSD) additionally accepts pointer
// input for VALUE ADJUSTMENT (its own content, e.g. a slider drag) and
// DWELL CONTROL (hover pauses the auto-dismiss timer; leaving resumes it
// with the time REMAINING, not a fresh interval — Caelestia's own
// behaviour, a named divergence from end-4's hide-on-hover). Neither of
// those is a click-to-dismiss gesture, so the original claim narrows to
// cover both instances rather than being contradicted by either.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"
import "../dashboard"
import "../bar"

PanelWindow {
    id: toastWindow

    // ── Public content slot — see header. ────────────────────────────────
    default property alias body: bodyRow.data

    // ── Parameterisation (Phase 20 Plan 04) — every property below
    //    defaults to the DND toast's own pre-existing literal, so
    //    `shell.qml`'s DND instance needs zero changes and stays
    //    byte-identical. ─────────────────────────────────────────────────
    // Which edge the frame anchors to and slides from — "top" (default,
    // the DND toast) or "bottom" (the OSD, D-20-01's bottom-centre anchor).
    property string edge: "top"
    // See the header's "Interactivity" section — gates the hover-pause
    // HoverHandler below. Default false: the DND toast carries no pointer
    // surface at all, unchanged from before this property existed.
    property bool interactive: false
    // The layer-shell namespace this instance registers under. Default is
    // the DND toast's own pre-existing literal.
    property string layerNamespace: "quickshell-notif-toast"
    // Per-instance auto-dismiss duration. Default is the DND toast's own
    // pre-existing token — `Design.osdHideDelayMs` (1200) coexists on this
    // one frame type via the OSD's own override, never a second Timer.
    property int dismissDurationMs: Design.notifToastDurationMs

    // True from the moment `show()` first activates the surface until the
    // exit animation (or its motion-disabled collapse) finishes.
    property bool toastActive: false

    // Absolute epoch-ms deadline the dismiss timer is counting down to,
    // valid only while `toastDismissTimer` is running. The hover-pause
    // handler below reads this to compute the REMAINING time on leave,
    // rather than resuming with a fresh full interval (D-20-07).
    property real _dismissDeadlineMs: 0

    function _armDismissTimer(ms) {
        var clamped = Math.max(1, ms);
        toastDismissTimer.interval = clamped;
        toastWindow._dismissDeadlineMs = Date.now() + clamped;
        toastDismissTimer.restart();
    }

    function show() {
        var wasActive = toastWindow.toastActive;
        toastWindow.toastActive = true;
        toastWindow._armDismissTimer(toastWindow.dismissDurationMs);
        if (wasActive)
            return; // already showing — only the timer restarts (see header)
        if (!Motion.motionEnabled) {
            content.opacity = 1;
            contentTranslate.y = 0;
            return;
        }
        content.opacity = 0;
        contentTranslate.y = toastWindow.edge === "bottom" ? Design.spacingMd : -Design.spacingMd;
        entranceAnim.start();
    }

    function hide() {
        if (!Motion.motionEnabled) {
            toastWindow.toastActive = false;
            return;
        }
        exitAnim.start();
    }

    Timer {
        id: toastDismissTimer
        repeat: false
        onTriggered: toastWindow.hide()
    }

    // ── Hover-pause/resume (Phase 20 Plan 04, D-20-07) — only wired up
    //    when `interactive` is true, so the DND toast gets no
    //    HoverHandler at all and its behaviour is unchanged. Pauses
    //    (stops, remaining time preserved) on hover-in; resumes with the
    //    time REMAINING on hover-out — never a reset to a fresh interval.
    HoverHandler {
        id: toastHoverHandler
        enabled: toastWindow.interactive
        onHoveredChanged: {
            if (!toastWindow.interactive || !toastWindow.toastActive)
                return;
            if (toastHoverHandler.hovered) {
                toastDismissTimer.stop();
            } else {
                var remaining = toastWindow._dismissDeadlineMs - Date.now();
                toastWindow._armDismissTimer(remaining);
            }
        }
    }

    // ── Layer posture — top-centre by default (anchors.top only, so the
    //    compositor horizontally centres the surface — Dashboard.qml's
    //    own precedent for the identical shape), clear of both the
    //    top-right popup stack and the right-edge centre by construction
    //    (neither is anchored here). The OSD anchors bottom-centre instead
    //    (`edge: "bottom"`, D-20-01) — the mirrored bottom margin reuses
    //    `Design.barSideMargin`, the SAME token this frame's own top
    //    margin already uses, never a new margin token.
    //    `ExclusionMode.Normal` (not `Ignore`) so the compositor
    //    auto-clears whichever edge the bar currently reserves, the same
    //    mechanism Dashboard.qml's own `drawerTopMargin` comment records —
    //    this frame needs no bar-orientation branch because of it. ───────
    visible: toastWindow.toastActive
    anchors.top: toastWindow.edge === "top"
    anchors.bottom: toastWindow.edge === "bottom"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Normal
    margins.top: toastWindow.edge === "top" ? Design.barSideMargin : 0
    margins.bottom: toastWindow.edge === "bottom" ? Design.barSideMargin : 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: toastWindow.layerNamespace
    // Keyboard focus is NEVER claimed, interactive or not — the OSD wants
    // pointer input (drag a slider, hover to pause dismiss), never
    // keyboard focus. This is what keeps click-to-dismiss impossible on
    // every instance (see header).
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false
    color: "transparent"

    // ── Sizing — content-hugging, capped at notifToastMaxWidth (320px). ──
    implicitWidth: Math.min(Design.notifToastMaxWidth, bodyRow.implicitWidth + Design.spacingMd * 2)
    implicitHeight: bodyRow.implicitHeight + Design.spacingMd * 2

    // ── Chrome — the SAME roles/tokens the popup card and centre use
    //    (19-UI-SPEC.md's own instruction), so all three read as one
    //    system: BarRoles.notifSurface/notifSurfaceFg, GradientBorder rim
    //    at Design.borderWidth, Design.popoutCornerRadius (uniform —
    //    floats clear of every edge). ─────────────────────────────────────
    Rectangle {
        id: toastBackground
        anchors.fill: parent
        radius: Design.popoutCornerRadius
        color: BarRoles.notifSurface
    }

    GradientBorder {
        anchors.fill: parent
        borderWidth: Design.borderWidth
        topLeftRadius: Design.popoutCornerRadius
        topRightRadius: Design.popoutCornerRadius
        bottomLeftRadius: Design.popoutCornerRadius
        bottomRightRadius: Design.popoutCornerRadius
    }

    // ── Content — a translate + opacity pair animated together, entrance
    //    on show() (guarded against replay while already active), reverse
    //    on hide(). ─────────────────────────────────────────────────────
    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        transform: Translate {
            id: contentTranslate
            y: toastWindow.edge === "bottom" ? Design.spacingMd : -Design.spacingMd
        }

        Row {
            id: bodyRow
            anchors.centerIn: parent
            spacing: Design.spacingSm
        }
    }

    ParallelAnimation {
        id: entranceAnim
        NumberAnimation {
            target: content
            property: "opacity"
            to: 1
            duration: Motion.standardDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }
        NumberAnimation {
            target: contentTranslate
            property: "y"
            to: 0
            duration: Motion.standardDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation {
            target: content
            property: "opacity"
            to: 0
            duration: Motion.standardDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }
        NumberAnimation {
            target: contentTranslate
            property: "y"
            to: toastWindow.edge === "bottom" ? Design.spacingMd : -Design.spacingMd
            duration: Motion.standardDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }
        onFinished: toastWindow.toastActive = false
    }
}
