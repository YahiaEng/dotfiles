// Toast.qml — a reusable transient-notice frame (Phase 19 Plan 05, Task 3;
// 19-UI-SPEC.md § "Toast frame").
//
// A SEPARATE module directory from `modules/notifications/`, deliberately:
// this frame is a general-purpose transient notice — Phase 20's OSD
// indicators reuse it for a value readout — and burying it inside the
// notification module would make that reuse read as a cross-feature
// dependency it is not.
//
// ── Chrome only, no do-not-disturb copy anywhere in this file ────────────
// This file carries a generic content slot (`default property alias body`)
// rather than hardcoded icon/text — Phase 20 is expected to swap the
// content region for a value readout while keeping the frame chrome
// identical, so chrome and content are separable at the type boundary, not
// by editing this file later. The caller (`shell.qml`, this same plan)
// supplies the actual visible children; the do-not-disturb copy strings
// themselves live on `NotifServer.qml` (its own natural owner, since it
// already owns DND), never here.
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
// Slides down + fades in from the top edge on Motion.standardDuration/
// standardEasing (routine register — this fires on an everyday action, a
// DND toggle, not an emphasized one). Exits the same way, self-timed only
// — this surface is never dismissible by click (D-19-36's own "a toast is
// never dismissible by click, only by its own timer, since it is
// feedback, not content").
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

    // True from the moment `show()` first activates the surface until the
    // exit animation (or its motion-disabled collapse) finishes.
    property bool toastActive: false

    function show() {
        var wasActive = toastWindow.toastActive;
        toastWindow.toastActive = true;
        toastDismissTimer.restart();
        if (wasActive)
            return; // already showing — only the timer restarts (see header)
        if (!Motion.motionEnabled) {
            content.opacity = 1;
            contentTranslate.y = 0;
            return;
        }
        content.opacity = 0;
        contentTranslate.y = -Design.spacingMd;
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
        interval: Design.notifToastDurationMs
        repeat: false
        onTriggered: toastWindow.hide()
    }

    // ── Layer posture — top-centre (anchors.top only, so the compositor
    //    horizontally centres the surface — Dashboard.qml's own precedent
    //    for the identical shape), clear of both the top-right popup stack
    //    and the right-edge centre by construction (neither is anchored
    //    here). `ExclusionMode.Normal` (not `Ignore`) so the compositor
    //    auto-clears whichever edge the bar currently reserves, the same
    //    mechanism Dashboard.qml's own `drawerTopMargin` comment records —
    //    this frame needs no bar-orientation branch because of it. ───────
    visible: toastWindow.toastActive
    anchors.top: true
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Normal
    margins.top: Design.barSideMargin
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notif-toast"
    // Never interactive — no click dismissal is possible by design.
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
            y: -Design.spacingMd
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
            to: -Design.spacingMd
            duration: Motion.standardDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }
        onFinished: toastWindow.toastActive = false
    }
}
