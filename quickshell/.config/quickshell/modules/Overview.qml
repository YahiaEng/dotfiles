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

    // ── Render-gate deviation from 16-UI-SPEC.md (2026-08-03) ────────────
    // UI-SPEC recommended 0.55 (already lower than PanelDialog's own
    // panelSurfaceOpacity/drawerSurfaceOpacity of 0.78). At the Task 3
    // render gate the operator judged the backdrop "too strong" even at
    // 0.55. First attempt (recorded for the record, corrected before
    // shipping): tried lowering ONLY this alpha to 0.35, on the assumption
    // alpha was the sole surface-local lever available since blur strength
    // is global. Screenshot-compared live against the original 0.55 and
    // found this was WRONG — 0.35 sits below the family `^quickshell-.*`
    // `ignore_alpha` floor (0.5, windowrules.lua), which does not soften the
    // blur, it silently DISABLES it — the backdrop read as raw unblurred
    // transparency (ags-media's own documented past mistake, reproduced
    // firsthand rather than assumed). `LayerRule`'s only blur field is a
    // boolean (`hl.meta.lua` line 551); blur intensity has no per-surface
    // knob at all — "turn it down" has exactly one honest answer for this
    // architecture: off. windowrules.lua now pulls D-16-06's own
    // pre-authorized fallback lever #1 (`blur = false`, exact-match
    // override on `quickshell-overview`) instead of chasing an alpha value
    // that either does nothing (above 0.5) or breaks blur outright (below
    // it). With blur off for this namespace, the `ignore_alpha` floor is
    // moot here, so this alpha is free to read as a plain, deliberate tint
    // rather than a frost — 0.45, screenshot-compared before shipping.
    // Named as a property (not an anonymous literal) matching
    // PanelDialog.qml/Dashboard.qml's own panelSurfaceOpacity/
    // drawerSurfaceOpacity convention — a bare numeric opacity constant is
    // established precedent in this repo, not a zero-hex/motion-lint
    // violation (Design.qml carries no opacity token; neither sibling file
    // sources this value from Colours/Design either).
    readonly property real scrimOpacity: 0.45

    // Full-bleed scrim (D-16-06) — the tiles are the content here, the
    // scrim is context, not cover (16-UI-SPEC.md "Color" section).
    Rectangle {
        anchors.fill: parent
        color: Colours.surface
        opacity: overviewWindow.scrimOpacity
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
