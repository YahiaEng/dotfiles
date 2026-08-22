// LauncherState.qml — the launcher's shared singleton (quick task
// 260822-sht, Task 1). Holds the current mode, the query string and the
// menu navigation stack — this is the seam every later mode (Task 2's
// prefix router, Task 3's menu tree, Tasks 5-9's dmenu-consumer modes)
// plugs into, per this task's own plan text.
//
// pragma Singleton + qmldir's `singleton` keyword are both required for
// bare `LauncherState.query`-style access to resolve at all — see
// Colours.qml's header comment for the binary-verified finding this
// convention rests on (corrects 12-RESEARCH.md Pattern 2).
//
// Task 1 wires exactly one mode ("apps"); Task 2 appends the six prefix
// routes and Task 3 appends "menu" — new mode names are always APPENDED
// to modeNames below, never inserted, mirroring the Motion singleton's own
// append-only `_pairNames` discipline (so nothing that already reads an
// index-based value silently repoints).
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // ── Modes ─────────────────────────────────────────────────────────
    readonly property string modeApps: "apps"

    property string mode: root.modeApps

    // ── Search state ─────────────────────────────────────────────────
    property string query: ""

    // ── Menu navigation stack (Task 3 pushes/pops submenu nodes here;
    //    declared now, empty, so this file is the single seam every
    //    later mode plugs into rather than each mode inventing its own
    //    navigation state). ───────────────────────────────────────────
    property var navStack: []

    // Called by Launcher.qml on every summon (LazyLoader construction)
    // and on every dismiss, so a surface never reopens mid-query or
    // mid-drill-down from a previous session.
    function reset() {
        root.query = "";
        root.mode = root.modeApps;
        root.navStack = [];
    }
}
