// modules/settings/PageCompRegistry.qml — pragma Singleton, the parallel
// list<Component> to PageRegistry.pages (RESEARCH.md pattern #1). Index N
// here is the page rendered for PageRegistry.pages[N] — the two lists MUST
// stay the same length and order; a mismatch renders the wrong page with no
// error (this plan's own key_links).
//
// Task 1 shipped index 0 (Appearance). Task 2 fills indices 1 (Audio &
// connectivity) and 3 (Shell behaviour); index 2 (Display & input) stays
// on `placeholderComp` until Task 3 — deliberate and visible, not an
// oversight.
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
    readonly property Component connectivityComp: Component {
        ConnectivityPage {}
    }
    readonly property Component shellBehaviourComp: Component {
        ShellBehaviourPage {}
    }

    readonly property list<Component> comps: [
        appearanceComp,
        connectivityComp,
        placeholderComp,
        shellBehaviourComp
    ]
}
