// WindowThumbnail.qml — the single general representation of "a window drawn
// small" (Phase 16 Plan 03, the assumption-delta promotion recorded in
// 16-03-PLAN.md's <assumption_delta_decision>).
//
// Extracted from WorkspaceTile.qml's tracer-inline delegate (16-02). This is
// now the ONLY place in modules/overview/ that instantiates a
// `ScreencopyView` — Task 1's acceptance criteria assert that count is
// exactly 1 across the whole directory, encoding the promotion as a
// contract check rather than a convention a later plan can silently break.
//
// `liveCapture` is the variant switch, deliberately named and defaulted
// rather than left implicit:
// - D-16-07's fallback ladder (snapshot/placeholder/etc. under load) is a
//   property change on THIS type, not a second renderer.
// - D-16-12's drag ghost reuses this exact type with `liveCapture: false`
//   (a still `captureFrame()` snapshot, per 16-UI-SPEC.md's Drag visuals
//   section) instead of building its own capture path.
// - D-16-11 bakes exactly ONE mode into the shipped build (`live: true`
//   everywhere, today) — `liveCapture` is not a user-facing runtime toggle
//   and no settings surface should ever expose it as one. Recorded here so
//   a future reader does not add that knob back in.
//
// Geometry (D-16-02): position/size are read from
// `toplevel.lastIpcObject.at`/`.size`, offset by the owning monitor's own
// origin (multi-monitor honesty, D-16-04) and scaled by `captureScale` —
// identical arithmetic to WorkspaceTile.qml's tracer delegate, just hoisted
// to its own type. Every read is null-guarded: `lastIpcObject` starts as an
// EMPTY object (not null) for a toplevel created after Quickshell's initial
// sync (16-02-SUMMARY.md's confirmed root cause) and never repopulates on
// its own — the caller (WorkspaceTile.qml, via Overview.qml's
// Component.onCompleted) is responsible for calling
// `Hyprland.refreshToplevels()`; this type only guards against the
// consequence, it does not itself trigger the refresh.
import QtQuick
import Quickshell.Wayland

Item {
    id: root

    // The HyprlandToplevel this thumbnail draws, or null.
    property var toplevel: null
    property real captureScale: 1
    // The owning HyprlandMonitor — geometry is offset by its x/y before
    // scaling into tile-local space (D-16-04).
    property var monitor: null
    // The variant switch documented above. Defaults true: D-16-07 says live
    // on every window first.
    property bool liveCapture: true

    // Guard every lastIpcObject read — see the header note above for why
    // this guard exists and what it protects against (a toplevel whose IPC
    // object hasn't landed yet, or has landed but is missing at/size keys).
    readonly property var ipc: root.toplevel ? root.toplevel.lastIpcObject : null
    readonly property var at: (root.ipc && root.ipc.at) ? root.ipc.at : [0, 0]
    readonly property var size: (root.ipc && root.ipc.size) ? root.ipc.size : [0, 0]
    readonly property real monitorX: root.monitor ? root.monitor.x : 0
    readonly property real monitorY: root.monitor ? root.monitor.y : 0

    x: (root.at[0] - root.monitorX) * root.captureScale
    y: (root.at[1] - root.monitorY) * root.captureScale
    width: Math.max(0, root.size[0] * root.captureScale)
    height: Math.max(0, root.size[1] * root.captureScale)

    // The single home of ScreencopyView in modules/overview/ (Task 1's
    // acceptance criteria assert this count directory-wide).
    ScreencopyView {
        id: captureView
        anchors.fill: parent
        // constraintSize is MANDATORY (16-02-SUMMARY.md's confirmed
        // pattern) — without it, the view paints its captured buffer at
        // native/source resolution instead of scaling into this item's own
        // bounds, relying on an ancestor's clip:true to crop the overflow
        // rather than genuinely scaling down.
        constraintSize: Qt.size(root.width, root.height)
        captureSource: root.toplevel ? root.toplevel.wayland : null
        live: root.liveCapture
    }

    // Exposed so WorkspaceTile.qml's aggregate counts can read this
    // instance's live hasContent without a second lookup path — the same
    // shape the tracer's inline delegate exposed via `captureView` alias.
    readonly property bool hasContent: captureView.hasContent
}
