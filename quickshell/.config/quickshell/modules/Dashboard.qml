// Dashboard.qml — the dashboard drawer's tracer surface (Phase 14 Plan 01,
// DASH-01/DASH-08). This is the whole "Super+D summons the drawer" path's
// production surface, not a prototype: the PanelWindow this file creates is
// the one plans 14-03..14-09 build their tabs inside, `quickshell-dashboard`
// is the namespace Phases 15/16 inherit by naming their own surfaces
// `quickshell-<surface>` (D-42), and the constants declared on this window
// root are read by every later widget rather than re-declared.
//
// Layer posture, focus mechanics and dismiss wiring are reused VERBATIM from
// ScreencopyProbe.qml/Probe.qml's QS-02-proven combination (WlrLayer.Overlay
// + WlrKeyboardFocus.OnDemand + HyprlandFocusGrab bound to this window) —
// this closes D-12's named research item with a live result, not a
// prediction. Single instance, no per-screen `Variants` fan-out: QS-03's
// per-screen mounting gap is an accepted permanent limitation on this
// quickshell 0.3.0-2 build (D-13, PROJECT.md), and D-14 does not ask for a
// multi-monitor summon here.
//
// Geometry (D-01/D-02/D-03/D-04): only anchors.top is set, so the compositor
// centres the window horizontally; exclusiveZone 0 + ExclusionMode.Normal
// mean the drawer reserves nothing but still respects waybar's own
// reservation, landing flush below the bar with zero per-layout offset
// logic. Width/height are locked at 850x860 — a token-level constant, not a
// computed value (D-02's ~40%x~60% ratio drifts slightly on this host's
// 2560x1440 primary vs. the 2160x1440 reference; the pixel values are
// honoured as written per 14-01-PLAN.md's flagged assumption).
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: dashboardWindow

    // Emitted on every dismissal path (Super+D toggle, Esc, click-outside,
    // focus-loss). shell.qml's dashboardLoader listens for this to
    // deactivate itself, which destroys the wl_surface (D-14) rather than
    // merely hiding it.
    signal dismissRequested()

    // Only anchors.top — left/right/bottom stay false so the compositor
    // horizontally centres the window (D-01).
    anchors.top: true

    // ── Locked geometry (D-02/D-04) — one constant per axis, read by
    //    plans 14-03..14-08 rather than re-declared. ─────────────────────
    readonly property int drawerWidth: 850
    readonly property int drawerHeight: 860
    implicitWidth: drawerWidth
    implicitHeight: drawerHeight

    // Reserve nothing (D-03/D-08/D-43): the drawer holds zero exclusive
    // zone on any edge waybar reserves, but ExclusionMode.Normal means it
    // still respects what waybar already reserves, so the compositor places
    // the drawer flush below the bar automatically.
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Normal

    // ── Layer posture (D-42/D-43) — the namespace scheme Phases 15/16
    //    inherit by naming their own surfaces `quickshell-<surface>`. ─────
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-dashboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Only the background Rectangle below paints — the window itself stays
    // transparent so the bottom-only rounding is visible (D-03/D-07).
    color: "transparent"

    // ── Drawer-family constants (D-06 8dp spacing scale + 14-UI-SPEC.md's
    //    four-role type scale), declared exactly once here — plans
    //    14-03..14-08 read them off `dashboardWindow` instead of
    //    re-declaring their own. ──────────────────────────────────────────
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 16
    readonly property int spacingLg: 24
    readonly property int spacingXl: 32

    readonly property int fontDisplay: 32
    readonly property int fontHeading: 20
    readonly property int fontBody: 16
    readonly property int fontLabel: 12
    readonly property int weightDisplay: Font.Medium
    readonly property int weightEmphasis: Font.DemiBold
    readonly property int weightBody: Font.Normal
    readonly property real lineHeightTight: 1.2
    readonly property real lineHeightNormal: 1.5

    readonly property int cornerRadius: 28
    readonly property real drawerSurfaceOpacity: 0.78
    readonly property color surfaceBase: Colours.surface

    // ── Background (D-03/D-07): the window's own footprint IS the drawer
    //    rectangle — bottom-only rounding, translucent over the compositor
    //    blur Task 2 turns on for this namespace, no scrim anywhere (D-08).
    Rectangle {
        id: background
        anchors.fill: parent
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: dashboardWindow.cornerRadius
        bottomRightRadius: dashboardWindow.cornerRadius
        color: Qt.rgba(dashboardWindow.surfaceBase.r, dashboardWindow.surfaceBase.g, dashboardWindow.surfaceBase.b, dashboardWindow.drawerSurfaceOpacity)

        // Probe.qml lines 229-240's exact shape — the Phase 12 theme-switch
        // crossfade reaches the drawer too. Only the six allowed Motion.*
        // names may be read; motionScale/pairs are motion-lint CHECK A
        // dangling references on this build.
        Behavior on color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

    // ── Dismiss wiring (D-12/D-13) — Probe.qml/ScreencopyProbe.qml's
    //    existing, QS-02-proven combination reused verbatim: click-outside
    //    and focus-loss both land on the same signal, D-13's
    //    deprecated-blind coexistence rule with zero edits to swaync,
    //    walker or wleave.
    HyprlandFocusGrab {
        id: grab
        windows: [ dashboardWindow ]
        active: true
        onCleared: dashboardWindow.dismissRequested()
    }

    // ── Content root (D-10 Esc dismiss) ─────────────────────────────────
    Item {
        id: content
        anchors.fill: parent
        anchors.margins: dashboardWindow.spacingLg
        focus: true

        Keys.onEscapePressed: dashboardWindow.dismissRequested()

        // forceActiveFocus() is required for the key handler above to
        // actually receive events under WlrKeyboardFocus.OnDemand.
        Component.onCompleted: content.forceActiveFocus()

        // ── Placeholder pane — Plan 14-03 replaces this wholesale with the
        //    header TabBar and the four-pane SwipeView; nothing else may
        //    consume it or grow around it. ─────────────────────────────────
        Column {
            anchors.centerIn: parent
            spacing: dashboardWindow.spacingSm

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Dashboard"
                font.pixelSize: dashboardWindow.fontHeading
                font.weight: dashboardWindow.weightEmphasis
                color: Colours.onSurface
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "tracer slice — Phase 14 Plan 01"
                font.pixelSize: dashboardWindow.fontLabel
                color: Colours.onSurface
            }
        }
    }
}
