// modules/settings/PageCompRegistry.qml — pragma Singleton, the parallel
// list<Component> to PageRegistry.pages (RESEARCH.md pattern #1). Index N
// here is the page rendered for PageRegistry.pages[N] — the two lists MUST
// stay the same length and order; a mismatch renders the wrong page with no
// error (this plan's own key_links).
//
// All four indices are now real components — `placeholderComp` remains
// declared (used by Pages.qml's incubation contract as a safe never-hit
// default) but is no longer referenced in `comps`.
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
    readonly property Component displayInputComp: Component {
        DisplayInputPage {}
    }

    readonly property list<Component> comps: [
        appearanceComp,
        connectivityComp,
        displayInputComp,
        shellBehaviourComp
    ]
}
