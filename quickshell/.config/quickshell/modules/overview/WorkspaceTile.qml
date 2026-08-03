// WorkspaceTile.qml — one workspace's live window thumbnails (Phase 16 Plan
// 02 tracer, D-16-01/D-16-02/D-16-07 subset).
//
// Renders every window on `workspace` as a live ScreencopyView positioned
// and scaled at its real `hyprctl clients` geometry (D-16-02) — a tile is a
// true miniature of the workspace, recognisable by shape alone, not text.
// `workspace` is a PROPERTY, never an internal `Hyprland.focusedWorkspace`
// read — this is what lets plan 16-03 instantiate eleven of these against
// eleven different workspaces without touching this type at all
// (16-CONTEXT.md's promoted (window identity, workspace-target) model).
//
// D-16-20/D-16-05 note: thumbnails carry no click handler in this tracer —
// only the MouseArea behind them (whole-tile click -> activated(), which
// Overview.qml wires to workspace.activate() + dismiss). Plan 16-05 adds
// per-window click parity; nothing here needs to change for that to land.
import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland
import "../"
import "../dashboard"

Item {
    id: root

    // The HyprlandWorkspace this tile renders, or null for an unoccupied
    // slot. A property (not a read off Hyprland.focusedWorkspace) so this
    // type stays reusable across every numbered/scratchpad tile plan 16-03
    // grids out.
    property var workspace: null
    property real captureScale: 1
    property bool isFocusedWorkspace: false

    // Multi-monitor honesty (D-16-04): a window's `at` coordinates are
    // monitor-relative in real Hyprland geometry, so they must be offset by
    // the owning monitor's own x/y before scaling into tile-local space.
    // Defaults to the focused monitor; unexercised on this single-monitor
    // host but correct the moment a second display is connected.
    property var monitor: Hyprland.focusedMonitor
    readonly property real monitorX: root.monitor ? root.monitor.x : 0
    readonly property real monitorY: root.monitor ? root.monitor.y : 0

    signal activated()

    // D-16-02: a window positioned partly offscreen, sized larger than the
    // monitor, or carrying stale coordinates must crop at the tile edge
    // instead of painting over its neighbours.
    clip: true

    // Local, non-hoisted constant — QuickToggles.qml's own `chipRadius`
    // precedent (16-UI-SPEC.md's Spacing Scale "Exceptions" note). No other
    // consumer needs a tile-scaled radius yet.
    readonly property int tileRadius: 12

    Rectangle {
        anchors.fill: parent
        radius: root.tileRadius
        color: Colours.surface
        border.width: Design.borderWidth
        border.color: Colours.outline
    }

    // Whole-tile click target BEHIND the thumbnails (D-16-20's "click a
    // tile's empty area focuses the workspace" meaning). Declared before
    // the Repeater below so it paints — and, if anything above it ever
    // gains its own input handling, loses input priority to — the
    // thumbnails, not the other way around.
    MouseArea {
        anchors.fill: parent
        onClicked: root.activated()
    }

    Repeater {
        id: windowRepeater
        model: root.workspace ? root.workspace.toplevels : null

        delegate: Item {
            id: windowDelegate

            // Exposed so the aggregate counts below can read this
            // instance's live `hasContent` without a second lookup path.
            property alias captureView: captureView

            // Guard every lastIpcObject read — a toplevel can exist before
            // its IPC object lands, and `at`/`size` can be individually
            // absent even once lastIpcObject itself is non-null.
            readonly property var ipc: modelData ? modelData.lastIpcObject : null
            readonly property var at: (ipc && ipc.at) ? ipc.at : [0, 0]
            readonly property var size: (ipc && ipc.size) ? ipc.size : [0, 0]

            x: (at[0] - root.monitorX) * root.captureScale
            y: (at[1] - root.monitorY) * root.captureScale
            width: Math.max(0, size[0] * root.captureScale)
            height: Math.max(0, size[1] * root.captureScale)

            ScreencopyView {
                id: captureView
                anchors.fill: parent
                // Bug found at the Task 3 render gate (2026-08-03): with
                // ONLY anchors.fill: parent set, ScreencopyView paints its
                // captured buffer at native/source resolution and relies on
                // an ancestor's clip:true to crop the overflow, rather than
                // auto-scaling to its own item bounds — with 3+ windows open
                // this made the largest/nearest window visually swallow the
                // whole tile, looking exactly like "only shows the current
                // window" even though windowRepeater.count and every
                // delegate's own x/y/width/height were already correct
                // (confirmed live via temporary diagnostic logging before
                // this fix, not guessed). `constraintSize` — settable,
                // present in the qmltypes specifically "for scaling the
                // capture into a tile" (16-RESEARCH.md Q1) — is the property
                // that actually controls the painted scale; reproduced live
                // with 3 real, non-overlapping windows before shipping this.
                constraintSize: Qt.size(windowDelegate.width, windowDelegate.height)
                // HyprlandToplevel.wayland is exactly the object type
                // ScreencopyView.captureSource accepts (16-CONTEXT.md's
                // verified installed API surface) — no IPC text parsing.
                captureSource: modelData ? modelData.wayland : null
                live: true
            }
        }
    }

    // Aggregated live counts (D-16-23 check 6's `overview` IPC status verb
    // reads these off Overview.qml, which sums across tiles). A JS-loop
    // binding tracks every property it reads during evaluation as a
    // dependency, so this stays live without a manual per-item signal wire
    // -up — the same aggregation shape plan 16-03 reuses for eleven tiles.
    readonly property int thumbnailCount: windowRepeater.count
    readonly property int thumbnailsWithContent: {
        var n = 0;
        for (var i = 0; i < windowRepeater.count; i++) {
            var item = windowRepeater.itemAt(i);
            if (item && item.captureView && item.captureView.hasContent)
                n++;
        }
        return n;
    }
}
