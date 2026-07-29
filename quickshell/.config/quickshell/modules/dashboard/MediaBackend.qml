// MediaBackend.qml — inert shell-root backend stub (Phase 14 Plan 03, filled
// by Plan 14-05, D-35).
//
// Root type `Scope` (from `Quickshell`, NOT `Item`) — verified present in
// the installed quickshell-core.qmltypes with `children` as its default
// property, which is what lets 14-05's `Process` be declared as a plain
// child later. `Scope` renders nothing and mounts cleanly under `ShellRoot`
// with no window, unlike an `Item`, which would be a warning waiting to
// happen with no PanelWindow of its own.
//
// `drawerOpen` (D-32/D-36) is the lifecycle gate every wave-3 backend
// carries: the media watch process/timer this backend eventually owns may
// run only while this is true, bound by shell.qml to
// `dashboardLoader.active` (D-14). In stub form this backend starts no
// process, opens no socket, reads no file and runs no timer — zero idle
// footprint is the tracer's promise (14-01) and this task must not break it
// before the widget even exists.
//
// D-35's two hard fences, named here (not demonstrated) so 14-05's executor
// meets them in the file before writing a line:
//   1. The drawer is a THIRD READER of the one existing media backend
//      (media-status.sh/media-players.sh) — never a second one.
//   2. The tab designs to the EXISTING media-status.sh payload contract —
//      no media-status.sh extensions this phase.
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

    // Lifecycle gate (D-32/D-36) — bound by shell.qml to
    // dashboardLoader.active. Starts nothing while false.
    property bool drawerOpen: false
}
