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

    signal close()

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
}
