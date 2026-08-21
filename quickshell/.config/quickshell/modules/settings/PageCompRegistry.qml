// modules/settings/PageCompRegistry.qml — pragma Singleton, the parallel
// list<Component> to PageRegistry.pages (RESEARCH.md pattern #1). Index N
// here is the page rendered for PageRegistry.pages[N] — the two lists MUST
// stay the same length and order; a mismatch renders the wrong page with no
// error (this plan's own key_links). `Component.onCompleted` below asserts
// the length match directly (quick-260821-6z1 Task 2) — cheap insurance
// against the one invariant this module already has.
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
    readonly property Component wallpaperComp: Component {
        WallpaperPage {}
    }
    readonly property Component barComp: Component {
        BarPage {}
    }
    readonly property Component audioComp: Component {
        AudioPage {}
    }
    readonly property Component networkComp: Component {
        NetworkPage {}
    }
    readonly property Component displayComp: Component {
        DisplayPage {}
    }
    readonly property Component inputComp: Component {
        InputPage {}
    }
    readonly property Component windowManagerComp: Component {
        WindowManagerPage {}
    }
    readonly property Component notificationsComp: Component {
        NotificationsPage {}
    }
    readonly property Component sessionComp: Component {
        SessionPage {}
    }

    // Index-locked to PageRegistry.pages, in the identical order documented
    // there: [Appearance, Wallpaper, Bar, Audio, Network, Display, Input,
    // Window manager, Notifications, Session].
    readonly property list<Component> comps: [
        appearanceComp,
        wallpaperComp,
        barComp,
        audioComp,
        networkComp,
        displayComp,
        inputComp,
        windowManagerComp,
        notificationsComp,
        sessionComp
    ]

    Component.onCompleted: {
        if (root.comps.length !== PageRegistry.pages.length)
            console.warn("PageCompRegistry: comps.length (" + root.comps.length + ") != PageRegistry.pages.length (" + PageRegistry.pages.length + ") — a mismatch renders the wrong page with no error");
    }
}
