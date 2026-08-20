// modules/settings/PageCompRegistry.qml — pragma Singleton, the parallel
// list<Component> to PageRegistry.pages (RESEARCH.md pattern #1). Index N
// here is the page rendered for PageRegistry.pages[N] — the two lists MUST
// stay the same length and order; a mismatch renders the wrong page with no
// error (this plan's own key_links).
//
// Task 1 ships index 0 (Appearance) as a real component; indices 1-3 point
// at `placeholderComp` until Task 2 (Audio & connectivity, Shell
// behaviour) and Task 3 (Display & input) replace them.
pragma Singleton
import QtQuick
import Quickshell
import "pages"

Singleton {
    id: root

    readonly property Component placeholderComp: Component {
        Item {
            // Accepts the same `sState` initial property every real page
            // (PageBase-derived) requires, so `Pages.qml`'s
            // `incubateObject(root, { sState: root.sState })` never fails
            // to assign it just because a slot still points here — the
            // placeholder is unused, but the property must exist.
            property var sState
            anchors.fill: parent
        }
    }

    readonly property Component appearanceComp: Component {
        AppearancePage {}
    }

    readonly property list<Component> comps: [
        appearanceComp,
        placeholderComp,
        placeholderComp,
        placeholderComp
    ]
}
