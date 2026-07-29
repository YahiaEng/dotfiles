// SystemResources.qml — inert shared resource-reader stub (Phase 14 Plan
// 03, filled by Plan 14-06, D-36/D-39).
//
// Root type `Scope` (from `Quickshell`, NOT `Item`) — verified present in
// the installed quickshell-core.qmltypes with `children` as its default
// property, which is what lets 14-06's poll timers/`FileView`s be declared
// as plain children later. `Scope` renders nothing and mounts cleanly with
// no window, unlike an `Item`.
//
// This is the ONE shared instance both PerformanceTab's four dials
// (14-06) and DashboardTab's resources strip (14-08) read — mounted once
// inside Dashboard.qml (drawer content, not shell-root warm data, so
// destroy-on-dismiss stopping it is the correct lifetime per D-36's
// "polling only while the drawer is open").
//
// `drawerOpen` (D-36) is the lifecycle gate: the ~1-2s CPU/mem/network and
// ~30s storage/battery poll timers this reader eventually owns may run
// only while this is true, bound by Dashboard.qml to the window's own
// visibility. In stub form this reader starts no process, opens no socket,
// reads no file and runs no timer.
//
// D-41 widget-state register — "populated" / "pending" / "empty" — carried
// on every one of this phase's nine modules/dashboard/ files, even the
// non-visual backends, so the vocabulary is uniform across the whole
// module surface.
import Quickshell

Scope {
    id: root

    // D-41: "populated" | "pending" | "empty"
    property string widgetState: "empty"

    // Lifecycle gate (D-36) — bound by Dashboard.qml to the window's own
    // visibility. Starts nothing while false.
    property bool drawerOpen: false
}
