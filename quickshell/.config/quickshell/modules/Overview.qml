// Overview.qml — the full-screen workspace overview surface (Phase 16 Plan
// 02, the phase's tracer, OVER-01/OVER-02).
//
// ONE tile only — Hyprland.focusedWorkspace, centred. No grid, no drag, no
// keyboard model: those are later plans expanding out from this proven
// slice (16-02-PLAN.md's objective). Every layer between Super+O and live
// pixels is wired end-to-end here: layer posture, scrim, focus grab,
// dismissal, click-to-focus-and-close, and the `overview` IPC status verb.
//
// This is not a prototype — WorkspaceTile.qml's `workspace` PROPERTY (not
// an internal Hyprland.focusedWorkspace read) is exactly what lets plan
// 16-03 instantiate eleven of these against D-16-01's fixed 5x2+scratchpad
// grid without rewriting this type at all.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "overview"
import "dashboard"

PanelWindow {
    id: overviewWindow

    // shell.qml's LazyLoader listens for this to deactivate itself so the
    // wl_surface is actually destroyed on every dismissal path (D-14), not
    // merely hidden — matching Dashboard.qml/ScreencopyProbe.qml's own
    // proven combination.
    signal dismissRequested()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // ── Layer posture (D-43, inherited) ──────────────────────────────────
    // Overlay layer, zero exclusive zone, namespace named
    // "quickshell-overview" so the family-wide `^quickshell-.*` blur/
    // ignore_alpha layerrules apply automatically (D-42) with no new
    // Hyprland config beyond the per-namespace `fade` animation rule
    // (D-16-24, windowrules.lua). WlrKeyboardFocus.OnDemand: measured
    // ONDEMAND-SUFFICIENT in 16-SPIKE-FINDINGS.md's "VERDICT — keyboard
    // focus posture" — arrow/Escape keys reached a throwaway harness's key
    // handlers with zero prior pointer click under this exact posture, so
    // no Exclusive escalation is taken here.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-overview"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0
    color: "transparent"

    // Full-bleed scrim (D-16-06) — Colours.surface at 0.55 alpha, lower
    // than PanelDialog's 0.78 deliberately: the tiles are the content here,
    // the scrim is context, not cover (16-UI-SPEC.md "Color" section).
    Rectangle {
        anchors.fill: parent
        color: Colours.surface
        opacity: 0.55
    }

    // The tracer's one tile — plan 16-03 replaces this single instance with
    // a Repeater over D-16-01's fixed 10 slots + the scratchpad, reusing
    // WorkspaceTile.qml unchanged.
    WorkspaceTile {
        id: tile
        anchors.centerIn: parent
        width: 480
        height: 270
        captureScale: 480 / Hyprland.focusedMonitor.width
        workspace: Hyprland.focusedWorkspace
        isFocusedWorkspace: true

        // D-16-13/D-16-20 (tile-empty-area case only in this tracer):
        // clicking focuses the workspace and closes the overview in the
        // same gesture (OVER-02).
        onActivated: {
            if (tile.workspace)
                tile.workspace.activate();
            overviewWindow.dismissRequested();
        }
    }

    // D-16-23 check 6's `overview` IPC status verb reads these off the
    // loaded Overview instance — this tracer sums exactly one tile's own
    // counts, the same aggregation shape plan 16-03 reuses for eleven.
    readonly property int tileCount: 1
    readonly property int thumbnailCount: tile.thumbnailCount
    readonly property int thumbnailsWithContent: tile.thumbnailsWithContent

    // ── Click-outside dismiss (D-10 dismissal set) — Dashboard.qml's
    //    proven click-outside/focus-loss combination, reused verbatim. ────
    HyprlandFocusGrab {
        id: grab
        windows: [ overviewWindow ]
        active: true
        onCleared: overviewWindow.dismissRequested()
    }

    // ── Content root (D-10 Esc dismiss) ──────────────────────────────────
    Item {
        id: content
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: overviewWindow.dismissRequested()

        // forceActiveFocus() is required for the key handler above to
        // actually receive events under WlrKeyboardFocus.OnDemand —
        // Dashboard.qml ships the identical mechanism, and
        // 16-SPIKE-FINDINGS.md's ONDEMAND-SUFFICIENT verdict confirmed it
        // live with zero prior pointer interaction.
        Component.onCompleted: content.forceActiveFocus()
    }
}
