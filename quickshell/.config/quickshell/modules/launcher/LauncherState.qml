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
import Quickshell.Io

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
    // `+` packages (quick task 260828-75k). Appended, never inserted —
    // this file's own standing instruction. `+` reads as "add a package"
    // and was the only unclaimed character that does; the study drew this
    // route as `pkg `, but every route here is a single character keyed on
    // charAt(0) below, and a word prefix would need a second routing shape
    // maintained beside the first.
    readonly property string modePkg: "pkg"
    // Menu mode (quick task 260822-sht, Task 3) — the 9 D-2 verb-based
    // roots, drilled via `LauncherState.navStack` and rendered by
    // `MenuMode.qml`. Reached only via `pendingMode` on a fresh summon
    // (the Super-tap bind, `keybinds.lua`) — never via a typed prefix
    // character, per `_routeQuery()`'s own guard below.
    readonly property string modeMenu: "menu"

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
            "@": root.modeWebSearch,
            "+": root.modePkg
        })

    // Menu mode is intentionally EXEMPT from prefix routing (quick task
    // 260822-sht, Task 3) — inside a submenu, `query` is what
    // `MenuMode.qml` fuzzy-filters the CURRENT level's rows against
    // (D-2's own "typed input preserved across levels" requirement), not
    // a route selector. Without this guard, typing "c" to filter down to
    // "Colour picker" would hit the router's own no-match branch and kick
    // the surface back to apps mode mid-search — the ONE behaviour this
    // guard exists to prevent. Also skips the empty-query "return to
    // apps" default: clearing the search field to re-browse a submenu's
    // full row list must not exit menu mode either.
    // Modes that OWN their query text and must never be re-routed. A mode
    // reached by IPC or by the menu (rather than by typing a prefix) uses
    // the search field to filter ITSELF, so bouncing it back to apps on the
    // first keystroke breaks it — measured: typing in the wallpaper
    // carousel switched the panel to the app list mid-search. `menu` was
    // already exempt as a one-off `if`; this generalises that instead of
    // adding a second special case beside it.
    readonly property var _stickyModes: ({
            "menu": true,
            "wallpaper": true,
            // "updates" RETIRED 2026-08-28 — System > Updates now opens the
            // package workbench (MenuTree `workbench: "updates"`).
            "systeminfo": true
        })

    function _routeQuery() {
        if (root._stickyModes[root.mode] === true)
            return;
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

    // ── Clipboard restore/delete processes (quick task 260822-sht, bug 1
    //    fix) — hosted here, NOT on ClipboardMode.qml's own Item ─────────
    // Both write the picked entry to the child's STDIN
    // (`cliphist decode | wl-copy` / `cliphist delete`), so
    // `Quickshell.execDetached` (no stdin handle at all) cannot carry
    // them — see PickerMode.qml's own header for the wider bug this quick
    // task fixes site by site. Restore fires from ClipboardMode.qml's own
    // `activate()`, which immediately calls `dismissCallback()`
    // afterwards, same one-shot shape as every other leaf mode; delete
    // fires from a row's own delete affordance WITHOUT dismissing (the
    // picker stays open to keep browsing), so an unrelated Escape/
    // click-outside a beat later would tear down ClipboardMode.qml's own
    // Item mid-write with no `dismissCallback()` of its own to defer.
    // Hosting both `Process` objects here, on the singleton every
    // launcher summon shares, is the one fix that closes BOTH races: this
    // object is never destroyed, so a `Process` declared on it outlives
    // every open/close cycle of the launcher surface that triggers it.
    property string _pendingClipboardRestore: ""

    Process {
        id: clipboardRestoreProcess
        command: ["sh", "-c", "cliphist decode | wl-copy"]
        stdinEnabled: true
        onStarted: clipboardRestoreProcess.write(root._pendingClipboardRestore)
    }

    function restoreClipboardEntry(raw) {
        root._pendingClipboardRestore = raw;
        clipboardRestoreProcess.running = false;
        clipboardRestoreProcess.running = true;
    }

    property string _pendingClipboardDelete: ""

    // ClipboardMode.qml's own `_refresh()` listens for this (via a
    // `Connections` block) to re-run `cliphist list` once the delete has
    // actually completed — it cannot just call `_refresh()` synchronously
    // after `deleteClipboardEntry()` returns, since the delete itself is
    // now async on a `Process` this file owns, not one ClipboardMode.qml
    // can attach its own `onExited` to directly.
    signal clipboardEntryDeleted()

    Process {
        id: clipboardDeleteProcess
        command: ["cliphist", "delete"]
        stdinEnabled: true
        onStarted: clipboardDeleteProcess.write(root._pendingClipboardDelete)
        onExited: exitCode => root.clipboardEntryDeleted()
    }

    function deleteClipboardEntry(raw) {
        root._pendingClipboardDelete = raw + "\n";
        clipboardDeleteProcess.running = false;
        clipboardDeleteProcess.running = true;
    }
}
