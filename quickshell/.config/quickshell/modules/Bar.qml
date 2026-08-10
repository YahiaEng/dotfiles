// Bar.qml — the phase's tracer: one production-quality PanelWindow that
// mounts unconditionally at shell.qml's root (Phase 18 Plan 01, QBAR-01).
//
// This is the repo's first surface with a non-zero exclusive zone AND the
// first with no dismissed state — every prior Quickshell surface
// (Dashboard, the three panels, Overview, Probe) sets exclusiveZone: 0 and
// is LazyLoader-summoned/destroyed on dismiss. Both properties are named
// here because every later plan in this phase inherits them:
//
//   1. exclusiveZone: Design.barHeight = 40, PLUS margins.top:
//      Design.barEdgeMargin = 6, for a live-measured total reservation of
//      46 — this host's LIVE waybar reservation today (`hyprctl monitors
//      -j`'s `reserved` array), not a derivation. LIVE-HOST CORRECTION
//      (Task 2 of this plan, found by measuring rather than trusting the
//      arithmetic): Hyprland's own reservation total is
//      `margins.top + exclusiveZone`, NOT `exclusiveZone` alone — the
//      compositor adds the anchored margin to whatever exclusiveZone value
//      the surface submits. Setting `exclusiveZone: barHeight +
//      barEdgeMargin` (46) ALONGSIDE `margins.top: barEdgeMargin` (6) was
//      the actual doubled-margin bug (measured live: co-existing reading
//      `[[0,98,0,0]]` against waybar's 46, i.e. this surface alone
//      reserving 52, one of the exact wrong values this plan's own Task 2
//      names and tells the executor to stop and correct rather than
//      adjust the expected number). `exclusiveZone: Design.barHeight`
//      alone — mirroring what waybar's own GTK layer-shell binding
//      submits (its own content height, letting the compositor add
//      `margin-top` separately) — reproduces the live baseline exactly:
//      `[[0,92,0,0]]` co-existing with waybar, `[[0,46,0,0]]` with waybar
//      hidden. See 18-01-SUMMARY.md's Deviations section for the full
//      measurement trail.
//   2. No dismissed state: this surface never unmounts for the life of the
//      session, so anything it schedules runs permanently. The clock below
//      is driven by SystemClock rather than a repeating Timer for exactly
//      this reason — the first concrete application of the phase's
//      permanent-liveness discipline (D-32/D-36's zero-idle doctrine,
//      which this surface deliberately does NOT inherit).
//
// Root type is PanelWindow, copying Overview.qml's single-PanelWindow
// posture verbatim (layer posture block, exclusiveZone, the transparent
// fill). Per-screen fan-out (Variants-rooted, QS-03) is permanently
// dropped under D-13 (PROJECT.md Out of Scope) — no fan-out root type may
// be reintroduced here.
//
// Namespace "quickshell-bar" inherits windowrules.lua's
// `^quickshell-.*` family blur rule together with its `ignore_alpha = 0.5`
// floor (hypr/.config/hypr/config/windowrules.lua:397/449) with zero new
// Hyprland config — so no fill on this surface may sit below 0.5 alpha
// without silently killing that blur.
//
// Explicitly NOT built here (each owned by a named later plan): the
// entry-list model and bar/BarCapsule.qml extraction (18-05), any other
// capsule (18-08/09/10/11), vertical orientation (18-05), popouts
// (18-13/14), auto-hide and the `bar` IPC handler (18-15), the hot zone
// (18-16), doctor checks (18-17), the restart unit (18-07, QBAR-10 —
// this surface's own process death is NOT mitigated here).
import QtQuick
import Quickshell
import Quickshell.Wayland
import "dashboard"

PanelWindow {
    id: barWindow

    anchors {
        top: true
        left: true
        right: true
    }

    margins.top: Design.barEdgeMargin
    margins.left: Design.barSideMargin
    margins.right: Design.barSideMargin
    implicitHeight: Design.barHeight

    // ── Layer posture — copies Overview.qml's structural template; the
    //    only property whose VALUE changes is exclusiveZone. ─────────────
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false
    exclusiveZone: Design.barHeight
    exclusionMode: ExclusionMode.Normal
    color: "transparent"

    // Never Overlay: always-on chrome sits below transient dialogs and
    // below an ext-session-lock surface, unlike Overview's deliberately
    // top-most Overlay layer.

    Item {
        id: barContent
        anchors.fill: parent

        Rectangle {
            id: clockCapsule
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Design.barHeight
            radius: Design.barCapsuleRadius
            width: clockText.implicitWidth + Design.spacingSm * 2
            color: Colours.surfaceVariant

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }

            Text {
                id: clockText
                anchors.centerIn: parent
                font.pixelSize: Design.fontLabel
                font.weight: Design.weightBody
                color: Colours.onSurfaceVariant
                text: Qt.formatDateTime(barClock.date, "HH:mm")
            }
        }
    }

    // Event-driven clock, deliberately NOT a repeating Timer: this surface
    // never unmounts, so a 1Hz (or any repeating) Timer would be a
    // permanent session cost for a value that changes once a minute.
    // SystemClock at Minutes precision wakes exactly once per minute —
    // this is the first concrete instance of the phase's named
    // permanent-liveness discipline; later capsules (18-08/09/10/11) are
    // expected to follow the same pattern for their own live readouts.
    SystemClock {
        id: barClock
        enabled: true
        precision: SystemClock.Minutes
    }
}
