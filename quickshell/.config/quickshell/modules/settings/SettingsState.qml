// modules/settings/SettingsState.qml — mirrors Caelestia's NexusState
// shape (RESEARCH.md's own borrowable pattern #1). A plain QtObject, NOT a
// singleton — one instance per Settings window, owned by Settings.qml, so a
// closed-and-reopened window always starts from page 0 rather than
// remembering a stale selection across window lifetimes.
//
// Every function below is declared ABOVE any construction-time caller in
// this file (MEMORY qml-declare-before-construction-time-use — a
// later-declared member throws "is not a function" and a fallback chain
// turns it into a plausible wrong answer). goToPage is called imperatively
// from NavRail's MouseArea, never at construction time, so this file has no
// such caller today — the discipline is followed anyway since Pages.qml
// (this same directory) DOES call into this type at construction time via
// Component.onCompleted.
import QtQuick

QtObject {
    id: root

    // Extra toplevels that must share the settings window's Hyprland focus
    // grab while they are open (quick task 260826-oyu, defect 2).
    //
    // The grab in Settings.qml captures input EXCLUSIVELY to the surfaces it
    // lists. A second toplevel opened by a page — today the Browse file
    // picker — is not one of them, so the compositor kept routing pointer and
    // scroll to the settings window underneath: the operator could not click
    // or scroll inside the dialog, and a click on it read as a click OUTSIDE
    // the grab and dismissed the whole window.
    //
    // Lives here rather than on the picker so the generic `FilePicker` stays
    // uncoupled from Settings — any page that opens its own toplevel
    // registers it the same way. ALWAYS REASSIGN, never push/splice: this is
    // a `property var` holding a plain JS array, and an in-place mutation
    // emits no change signal, so the grab's binding would never re-evaluate.
    property var extraGrabWindows: []

    property int currentPageIdx: 0

    // Task 13 (D-01 bundle 4) — relayed from Settings.qml at construction
    // (the `SettingsState { audioBackend: win.audioBackend }` binding
    // there). AudioPage.qml reads `sState.audioBackend` rather than
    // instantiating its own AudioBackend — one shell-wide instance, same
    // as every other consumer.
    property var audioBackend: null
    // quick-260821-6z1 fix wave (operator: "make wifi and bluetooth
    // options open inline") — same relay shape as audioBackend above.
    // NetworkPage.qml reads `sState.wifiBackend`/`sState.bluetoothBackend`
    // rather than instantiating its own backends — the SAME instances
    // WifiPanel.qml/BluetoothPanel.qml already share (shell.qml's own
    // wifiBackendInstance/bluetoothBackendInstance), never a second one.
    property var wifiBackend: null
    property var bluetoothBackend: null

    // ── Sub-page mechanism (quick task 260825-wj2 Task 1) — mirrors
    //    Caelestia's NexusState shape. `subPageIdxStack` is REASSIGNED
    //    wholesale by openSubPage/closeSubPage below, never `.push()`/
    //    `.pop()`-mutated in place: QML change notification for a
    //    `property var` fires on reassignment only (this file's own
    //    established rule, restated by `_data` in Prefs.qml). `selectedApp`/
    //    `selectedBtDevice` are the selection a selection-dependent
    //    sub-page reads (AppInfoPage/BtDeviceInfoPage); `pendingSubPageIdx`
    //    is the search deep-link's jump target — set by
    //    `selectSearchResult()` below, consumed by `Pages.qml:_swapTo`
    //    once the target page object exists (D-5).
    property var subPageIdxStack: []
    property var selectedApp: null
    property var selectedBtDevice: null
    // Which wallpaper folder the category sub-page shows (quick task
    // 260826-pk2). Same role as Caelestia's
    // `nState.selectedWallpaperCategory`: a plain string set by the
    // tile that opened the sub-page, read by WallpaperCategoryPage.
    property string selectedWallpaperCategory: ""

    // Wallpaper data published UP from WallpaperPage so its category
    // sub-page reads one source of truth instead of running its own
    // duplicate --list/--active/--set plumbing. Two independently-refreshed
    // copies of the same state is exactly how the theme trackers went stale
    // in this repo before; the sub-page owns no plumbing at all.
    property var wallpaperEntries: []
    property string wallpaperActiveRelpath: ""

    // The sub-page cannot call WallpaperPage's applyWallpaper() directly —
    // it is a sibling in a StackPage, not a child — so the request rides a
    // signal the owning page connects to.
    // Emitted by a page whose focusable rows appear AFTER the page is
    // built — a Repeater over data an async Process fills in. Pages.qml
    // collects the focus set once at page-swap time, so without this a
    // late-arriving grid is permanently unreachable by keyboard (measured:
    // the wallpaper page reported 2 focusables, its InfoRow and toggle,
    // with every tile missing).
    signal focusRowsInvalidated()

    signal wallpaperRequested(string relpath)

    function requestWallpaper(relpath) {
        root.wallpaperRequested(relpath);
    }
    property int pendingSubPageIdx: -1

    signal subPageOpened(idx: int)
    signal subPageClosed()

    // Reassign wholesale (never `.push()`) — see this block's header.
    function openSubPage(idx) {
        root.subPageIdxStack = root.subPageIdxStack.concat([idx]);
        root.subPageOpened(idx);
    }

    // Emit BEFORE popping — mirrors Caelestia's own ordering
    // (`NexusState.qml:31-32`), so a `Connections` handler reacting to the
    // signal still sees the about-to-be-removed index at the top of the
    // stack if it needs it.
    function closeSubPage() {
        root.subPageClosed();
        root.subPageIdxStack = root.subPageIdxStack.slice(0, -1);
    }

    // A page switch abandons any sub-page depth from the PREVIOUS page —
    // mirrors Caelestia's `onCurrentPageIdxChanged: subPageIdxStack.length
    // = 0` exactly. Declared here (this file's own function-grouping
    // discipline) even though it is a handler, not a callable function,
    // since it reads/writes the same property the functions above do.
    onCurrentPageIdxChanged: root.subPageIdxStack = []

    signal close()

    // Search-jump defect 1 (quick-260826-1n9, Task 3) — a same-page
    // result never fires anything without this: QML only emits a
    // property's change signal when the value actually differs, so
    // `goToPage(idx)` below is a silent no-op when `idx === currentPageIdx`
    // (the common case — the window opens on page 0). Pages.qml listens
    // for this signal and re-collects rows directly, the same effect
    // `onCurrentPageIdxChanged` has for a cross-page jump.
    signal rowJumpRequested()

    // ── Search (quick-260821-6z1 Task 3, D-06/F-01/PD-08) — `searchText`
    //    drives NavRail's own model switch (PageRegistry.pages when
    //    empty, `searchResults` below otherwise). `pendingRowLabel` is
    //    the jump key a search-result click sets before calling
    //    `goToPage()`: Pages.qml's `_swapTo()` reads it once the new
    //    page has incubated and re-collected its focusable rows, rings
    //    and scrolls the matching row into view, then clears it — see
    //    that file's own header. Matching is substring, case-insensitive
    //    (PD-08 — not fuzzy: at ~75 rows a wrong fuzzy hit at the top of
    //    the list is worse than a missing substring hit), over
    //    `label + " " + section + " " + keywords`. Declared ABOVE
    //    `goToPage` below is unnecessary here (searchResults has no
    //    construction-time caller in this file), but functions are kept
    //    grouped above every property that reads them for the same
    //    discipline this file's own header already requires. ───────────
    property string searchText: ""
    property string pendingRowLabel: ""

    readonly property var searchResults: {
        var q = root.searchText.trim().toLowerCase();
        if (q.length === 0)
            return [];
        var out = [];
        var rows = RowIndex.rows;
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i];
            var haystack = (row.label + " " + row.section + " " + (row.keywords || "")).toLowerCase();
            if (haystack.indexOf(q) !== -1) {
                out.push(row);
                // Capped at a sane result count — a runaway match list is
                // no more useful than the unfiltered page list it
                // replaces.
                if (out.length >= 20)
                    break;
            }
        }
        return out;
    }

    // Task 2 (ConnectivityPage) — the shared relay every page uses to
    // reach the guarded `openPanel()` summon path, since a dynamically
    // incubated page (Pages.qml) has no direct handle back to Settings.qml
    // or shell.qml. A page calls `sState.panelRequested(name)`;
    // Settings.qml re-emits its own signal of the same shape, and
    // shell.qml's LazyLoader listens and calls `root.openPanel(name)` —
    // never a direct loader-active write from in here (D-04/DASH-08's own
    // single-guard rule).
    signal panelRequested(name: string)

    // Bounds-checked write — an out-of-range index (a typo'd category name
    // upstream, or PageRegistry.pages shrinking under a future edit) is
    // logged rather than silently accepted, per this plan's own "never let
    // a guard return silently" instruction (Pages.qml's own header repeats
    // it).
    function goToPage(idx) {
        if (idx < 0 || idx >= PageRegistry.pages.length) {
            console.warn("SettingsState.goToPage: index out of range: " + idx);
            return;
        }
        root.currentPageIdx = idx;
    }

    // Called from a search-result delegate's click (NavRail.qml) — sets
    // the jump key BEFORE navigating, so Pages.qml's `_swapTo()` sees it
    // already populated once the new page's incubation completes and its
    // own `Component.onCompleted`/`onCurrentPageIdxChanged` path runs
    // `goTo()`. Also clears `searchText`, closing the result list once a
    // result has been chosen — matching a normal nav-rail click's own
    // "the window now shows that page" behaviour.
    // Extended (quick task 260825-wj2 Task 1, D-5) — `jumpSubPageIdx`
    // defaults to `subPageIdx` (both optional, absent means 0/the root
    // page). `pendingSubPageIdx` is set here but NOT acted on here:
    // `openSubPage()` cannot run yet because the target page object does
    // not exist until `Pages.qml:swapAnim`'s `ScriptAction` incubates it —
    // `_swapTo()` is what actually calls `openSubPage(pendingSubPageIdx)`
    // once that incubation has happened.
    function selectSearchResult(row) {
        root.pendingRowLabel = row.label;
        root.searchText = "";
        root.pendingSubPageIdx = (row.jumpSubPageIdx !== undefined) ? row.jumpSubPageIdx : ((row.subPageIdx !== undefined) ? row.subPageIdx : 0);
        // Defect 1 fix — a result on the page ALREADY showing must not go
        // through `goToPage()`: that only writes `currentPageIdx` and QML
        // emits no change signal for a write that doesn't change the
        // value, so `Pages.qml`'s `onCurrentPageIdxChanged` handler (and
        // therefore the whole swap/recollect/scroll chain) would never
        // run at all — the click would do nothing, with `pendingRowLabel`
        // left set to poison the NEXT real page swap. Deliberately NOT
        // "set currentPageIdx = -1 first to force a change signal": that
        // would destroy and re-incubate the current page, losing its
        // scroll position and any live Process/FileView children.
        if (row.pageIdx === root.currentPageIdx)
            root.rowJumpRequested();
        else
            root.goToPage(row.pageIdx);
    }
    // ── External-dialog hold (quick task 260827-np1, operator round 4) ──
    // `Settings.qml`'s HyprlandFocusGrab is EXCLUSIVE. `extraGrabWindows`
    // handles extra QML toplevels (the Browse picker), but an external
    // process's window cannot be added to it — so while a page has spawned
    // one, the grab must be released entirely or every click on that
    // dialog is treated as a click OUTSIDE the grab: the settings window
    // takes focus back and the dialog drops behind it.
    //
    // MEASURED: `pkexec` raises `class polkit-gnome-authentication-agent-1`,
    // title "Authenticate", already floating — so this was never a
    // missing float rule, it was the grab. The operator had to close
    // Settings entirely to reach the password prompt.
    //
    // A page sets this true while its external dialog is up. Kept as a
    // plain bool driven by a `Binding` at the call site so it restores
    // automatically if the page is destroyed mid-action.
    property bool externalDialogOpen: false

}
