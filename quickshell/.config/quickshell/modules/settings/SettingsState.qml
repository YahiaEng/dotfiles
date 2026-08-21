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

    property int currentPageIdx: 0

    // Task 13 (D-01 bundle 4) — relayed from Settings.qml at construction
    // (the `SettingsState { audioBackend: win.audioBackend }` binding
    // there). AudioPage.qml reads `sState.audioBackend` rather than
    // instantiating its own AudioBackend — one shell-wide instance, same
    // as every other consumer.
    property var audioBackend: null

    signal close()

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
    function selectSearchResult(row) {
        root.pendingRowLabel = row.label;
        root.searchText = "";
        root.goToPage(row.pageIdx);
    }
}
