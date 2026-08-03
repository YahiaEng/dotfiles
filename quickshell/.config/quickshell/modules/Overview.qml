// Overview.qml — the full-screen workspace overview surface (Phase 16 Plan
// 03, expanding the tracer's single tile into D-16-01's fixed ten-slot
// numbered grid, OVER-01/OVER-02).
//
// Ten WorkspaceTile instances in a fixed 5-column x 2-row arrangement
// mirroring the number row (D-16-01/D-16-03) — every slot renders on every
// summon, occupied or not, so a tile's screen position never moves between
// summons. Plan 16-03 Task 2 adds the eleventh scratchpad tile and the
// row-level entrance cascade; this task's own scope is the ten numbered
// tiles and the fit arithmetic they must close (16-UI-SPEC.md "Grid
// geometry" / "Spacing Scale").
//
// Every layer between Super+O and live pixels is wired end-to-end here:
// layer posture, scrim, focus grab, dismissal, click-to-focus-and-close,
// and the `overview` IPC status verb — all inherited unchanged from the
// tracer (16-02).
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

    // ── Render-gate defect, round 2 root cause (2026-08-03) ──────────────
    // Real root cause of "only shows the current window", confirmed with a
    // per-delegate IPC measurement (x/y/width/height/hasContent/sourceSize
    // per window), not screenshots: HyprlandToplevel.lastIpcObject starts as
    // an EMPTY QVariantMap ({}, rawIpcHasKeys=0 — not null) for any window
    // created after Quickshell's initial sync, and never spontaneously
    // populates — proven by waiting 4+ seconds inside one still-summoned
    // session with zero change. This is the SAME lag shell.qml's own
    // fullscreenBlocking guard already documents and works around
    // ("Hyprland.activeToplevel.lastIpcObject can lag... force a refresh").
    // WorkspaceTile.qml's own `(ipc && ipc.at) ? ipc.at : [0,0]` guard was
    // therefore firing CORRECTLY on an empty object and staying collapsed
    // forever, not corrupting anything — the missing piece was ever asking
    // Hyprland to repopulate it. Concurrent capture itself was never
    // broken: every delegate in that same measurement had hasContent=true
    // with correct, DISTINCT sourceSize values throughout — refuting the
    // "only one concurrent screencopy stream" hypothesis directly.
    Component.onCompleted: Hyprland.refreshToplevels()

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

    // Fixed tile geometry (16-UI-SPEC.md "Grid geometry") — named constants
    // so the fit arithmetic below reads as arithmetic, not magic numbers.
    readonly property int tileWidth: 480
    readonly property int tileHeight: 270
    // 480 / 2560 = 0.1875 on this host — computed, not hardcoded, per
    // D-16-02, so a different monitor width still produces a correct scale.
    readonly property real captureScale: overviewWindow.tileWidth / Hyprland.focusedMonitor.width

    // Resolves a fixed slot id (1..10) against Hyprland's live workspace
    // list, or returns null for an id Hyprland does not yet know about.
    // Hyprland.workspaces itself is never padded — the ten SLOTS are the
    // fixed thing (D-16-01), the workspace behind each is what may be
    // absent.
    function workspaceForSlot(slotId) {
        var list = Hyprland.workspaces.values;
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === slotId)
                return list[i];
        }
        return null;
    }

    function isFocusedSlot(slotId) {
        return !!(Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === slotId);
    }

    // D-16-13/D-16-20: clicking a tile's empty area focuses that workspace
    // and closes the overview in the same gesture (OVER-02). Shared by
    // every numbered tile below rather than repeated ten times.
    function activateTile(workspace) {
        if (workspace)
            workspace.activate();
        overviewWindow.dismissRequested();
    }

    // ── The fixed 5x2 numbered grid (D-16-01) ────────────────────────────
    // Block width: 5*480 + 4*24 = 2496px; height: 2*270 + 24 = 564px;
    // centred with a spacingLg (24px) scrim margin per side — 2544px total
    // on this 2560px display, 16px spare (16-UI-SPEC.md's load-bearing fit
    // arithmetic). Any change to tile width, gap or border must re-run it.
    // A Column of two Rows (not a single Grid) keeps each row independently
    // addressable as its own entrance-cascade band — plan 16-03 Task 2
    // wires that up without restructuring this container.
    Column {
        id: gridBlock
        anchors.centerIn: parent
        spacing: Design.spacingLg

        Row {
            id: rowOne
            spacing: Design.spacingLg

            Repeater {
                id: rowOneRepeater
                model: 5

                delegate: WorkspaceTile {
                    width: overviewWindow.tileWidth
                    height: overviewWindow.tileHeight
                    slotLabel: String(index + 1)
                    captureScale: overviewWindow.captureScale
                    monitor: Hyprland.focusedMonitor
                    workspace: overviewWindow.workspaceForSlot(index + 1)
                    isFocusedWorkspace: overviewWindow.isFocusedSlot(index + 1)
                    onActivated: overviewWindow.activateTile(workspace)
                }
            }
        }

        Row {
            id: rowTwo
            spacing: Design.spacingLg

            Repeater {
                id: rowTwoRepeater
                model: 5

                delegate: WorkspaceTile {
                    width: overviewWindow.tileWidth
                    height: overviewWindow.tileHeight
                    slotLabel: String(index + 6)
                    captureScale: overviewWindow.captureScale
                    monitor: Hyprland.focusedMonitor
                    workspace: overviewWindow.workspaceForSlot(index + 6)
                    isFocusedWorkspace: overviewWindow.isFocusedSlot(index + 6)
                    onActivated: overviewWindow.activateTile(workspace)
                }
            }
        }
    }

    // D-16-23 check 6's `overview` IPC status verb reads these off the
    // loaded Overview instance — summed across all ten tiles so the verb
    // keeps reporting truthfully at ten tiles as it did at one.
    readonly property int tileCount: 10
    readonly property int thumbnailCount: {
        var n = 0;
        for (var i = 0; i < rowOneRepeater.count; i++)
            n += rowOneRepeater.itemAt(i).thumbnailCount;
        for (var i = 0; i < rowTwoRepeater.count; i++)
            n += rowTwoRepeater.itemAt(i).thumbnailCount;
        return n;
    }
    readonly property int thumbnailsWithContent: {
        var n = 0;
        for (var i = 0; i < rowOneRepeater.count; i++)
            n += rowOneRepeater.itemAt(i).thumbnailsWithContent;
        for (var i = 0; i < rowTwoRepeater.count; i++)
            n += rowTwoRepeater.itemAt(i).thumbnailsWithContent;
        return n;
    }

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
