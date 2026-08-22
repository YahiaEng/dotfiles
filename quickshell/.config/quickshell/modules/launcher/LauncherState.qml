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
//
// ── Prefix router (quick task 260822-sht, Task 2) ─────────────────────
// Restores all six routes the retired `config.toml` declared
// (`[[providers.prefixes]]`): `=` calc, `/` files, `:` clipboard,
// `.` symbols, `;` providerlist, `@` websearch. `_routeQuery()` runs on
// every `query` change and derives `mode` from the FIRST character of the
// raw typed text — an empty query always routes back to apps mode.
// Clipboard (`:`) and symbols (`.`) route to real mode NAMES here even
// though their result-view components don't exist until Tasks 8 and 7 —
// Launcher.qml's mode Loader falls back to an inline placeholder for any
// mode with no real component yet, so the router is complete NOW and
// Tasks 7/8 are pure additions (register a real component, no router
// change) rather than edits to this file, per this task's own plan text.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // ── Modes ─────────────────────────────────────────────────────────
    readonly property string modeApps: "apps"
    readonly property string modeCalc: "calc"
    readonly property string modeFiles: "files"
    readonly property string modeClipboard: "clipboard"
    readonly property string modeSymbols: "symbols"
    readonly property string modeProviderList: "providerlist"
    readonly property string modeWebSearch: "websearch"

    property string mode: root.modeApps

    // Prefix character -> mode name. `;` (providerlist) is the entry
    // point that LISTS this table; it is not itself a target of any
    // OTHER route, so it only appears as a key here, never a value.
    readonly property var _prefixRoutes: ({
            "=": root.modeCalc,
            "/": root.modeFiles,
            ":": root.modeClipboard,
            ".": root.modeSymbols,
            ";": root.modeProviderList,
            "@": root.modeWebSearch
        })

    function _routeQuery() {
        const q = root.query;
        if (q.length === 0) {
            root.mode = root.modeApps;
            return;
        }
        const routed = root._prefixRoutes[q.charAt(0)];
        root.mode = routed !== undefined ? routed : root.modeApps;
    }

    // ── Search state ─────────────────────────────────────────────────
    property string query: ""
    onQueryChanged: root._routeQuery()

    // The raw `query` text with a resolved route's own prefix character
    // stripped off — what CalcMode/FilesMode/WebSearchMode etc. actually
    // evaluate (`=2+2` routes to calc mode with `queryArg === "2+2"`).
    // Apps mode and an unrecognised/no-prefix query both read the query
    // verbatim (no prefix to strip).
    readonly property string queryArg: {
        const q = root.query;
        if (q.length > 0 && root._prefixRoutes[q.charAt(0)] !== undefined)
            return q.slice(1);
        return q;
    }

    // ── Menu navigation stack (Task 3 pushes/pops submenu nodes here;
    //    declared now, empty, so this file is the single seam every
    //    later mode plugs into rather than each mode inventing its own
    //    navigation state). ───────────────────────────────────────────
    property var navStack: []

    // ── Pending-mode handoff (quick task 260822-sht, Task 2) ──────────
    // Set by shell.qml's `launcherIpc.open(mode)` BEFORE the LazyLoader
    // activates, so a summon can request a specific starting mode (e.g. a
    // future menu leaf or Super+C wanting clipboard mode directly).
    // Consumed and cleared by `reset()` below — a request that arrives
    // with no corresponding summon (nothing ever calls reset()) simply
    // sits unread, which is harmless since the NEXT summon still consumes
    // and clears it correctly.
    property string pendingMode: ""

    // Called by Launcher.qml on every summon (LazyLoader construction)
    // and on every dismiss, so a surface never reopens mid-query or
    // mid-drill-down from a previous session. Applying `pendingMode`
    // AFTER clearing `query` matters: clearing `query` itself runs
    // `_routeQuery()` (via `onQueryChanged`) and resets `mode` to apps —
    // the explicit `pendingMode` assignment below is a second, LATER
    // write that wins, so a requested starting mode is never clobbered
    // by the query-clear's own apps-mode default.
    function reset() {
        root.query = "";
        root.navStack = [];
        if (root.pendingMode.length > 0) {
            root.mode = root.pendingMode;
            root.pendingMode = "";
        } else {
            root.mode = root.modeApps;
        }
    }
}
