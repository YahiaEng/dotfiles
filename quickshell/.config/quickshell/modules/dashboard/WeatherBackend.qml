// WeatherBackend.qml — inert shell-root backend stub (Phase 14 Plan 03,
// filled by Plan 14-07, D-29..D-33).
//
// Root type `Scope` (from `Quickshell`, NOT `Item`) — verified present in
// the installed quickshell-core.qmltypes with `children` as its default
// property, which is what lets 14-07's fetch/cache `FileView`/timer be
// declared as plain children later. `Scope` renders nothing and mounts
// cleanly under `ShellRoot` with no window, unlike an `Item`.
//
// `drawerOpen` (D-32) is the lifecycle gate every wave-3 backend carries:
// the ~15-min TTL refresh timer this backend eventually owns may run only
// while this is true, bound by shell.qml to `dashboardLoader.active`
// (D-14). In stub form this backend starts no process, opens no socket,
// reads no file and runs no timer — zero idle footprint is the tracer's
// promise (14-01) and this task must not break it before the widget even
// exists.
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

    // Lifecycle gate (D-32) — bound by shell.qml to dashboardLoader.active.
    // Starts nothing while false.
    property bool drawerOpen: false
}
