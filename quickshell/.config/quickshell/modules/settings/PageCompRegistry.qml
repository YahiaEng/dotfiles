// modules/settings/PageCompRegistry.qml — pragma Singleton, the parallel
// list<Component> to PageRegistry.pages (RESEARCH.md pattern #1). Index N
// here is the page rendered for PageRegistry.pages[N] — the two lists MUST
// stay the same length and order; a mismatch renders the wrong page with no
// error (this plan's own key_links). `Component.onCompleted` below asserts
// the length match directly (quick-260821-6z1 Task 2) — cheap insurance
// against the one invariant this module already has.
//
// ── Fix WR-03 (quick-260821-6z1 code review) — a length-only assertion
//    passes silently on a same-length REORDER, reproducing exactly the
//    "mismatch renders the wrong page with no error" failure the comment
//    above already warns about. `compSlugs` below is a second, parallel
//    array — one string per `comps[]` entry, in the SAME order — so
//    `Component.onCompleted` can additionally assert per-index IDENTITY
//    against `PageRegistry.pages[i].slug`, not just array length.
//    `settings-index-check`'s own CHECK E (hypr/.config/hypr/scripts/
//    settings-index-check) reads this same array statically and
//    cross-checks it against `PageRegistry.qml`'s `slug:` fields — this
//    file cannot itself go out of sync with the registry it is meant to
//    mirror without BOTH the live warning below and the gate catching it.
pragma Singleton
import QtQuick
import Quickshell
import "pages"
import "common"

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
    // StackPage-wrapped (quick task 260826-pk2) — sub-page 0 is the root
    // WallpaperPage, 1 is a single theme folder's grid. Same declaration
    // shape as appsComp above, which settings-index-check's comp->file
    // parser depends on: one `Component { Xxx {} }` per page, in order,
    // nested inside `StackPage { ... }`.
    readonly property Component wallpaperComp: Component {
        StackPage {
            Component {
                WallpaperPage {}
            }
            Component {
                WallpaperCategoryPage {}
            }
        }
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
    // Connected devices (quick task 260825-wj2 Task 4, D-8) —
    // StackPage-wrapped: sub-page 0 is the root (BluetoothPage), 1 is
    // device info.
    readonly property Component bluetoothComp: Component {
        StackPage {
            Component {
                BluetoothPage {}
            }
            Component {
                BtDeviceInfoPage {}
            }
        }
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
    // Apps (quick task 260825-wj2 Task 2, D-2) — the first StackPage-
    // wrapped comp: sub-page 0 is the root (AppsPage), 1 is All apps, 2 is
    // App info. `settings-index-check`'s comp->file parser (D-4) collects
    // every `*Page` identifier inside this block, in order, skipping the
    // literal `StackPage` — so THIS declaration shape (one `Component { Xxx
    // {} }` per page, nested inside `StackPage { ... }`) is itself part of
    // the gate's contract, not just a style choice.
    readonly property Component appsComp: Component {
        StackPage {
            Component {
                AppsPage {}
            }
            Component {
                AllAppsPage {}
            }
            Component {
                AppInfoPage {}
            }
        }
    }

    readonly property Component servicesComp: Component {
        ServicesPage {}
    }
    readonly property Component languageRegionComp: Component {
        LanguageRegionPage {}
    }
    readonly property Component updatesComp: Component {
        UpdatesPage {}
    }
    // Security Center (quick task 260827-np1). A plain Component, not
    // StackPage-wrapped: the page is flat and has no sub-pages.
    readonly property Component securityComp: Component {
        SecurityPage {}
    }
    readonly property Component aboutComp: Component {
        AboutPage {}
    }

    // Index-locked to PageRegistry.pages, in the identical order documented
    // there: [Appearance, Wallpaper, Bar, Audio, Network, Connected
    // devices, Display, Input, Window manager, Notifications, Session,
    // Apps, Services, Language & region, Updates, About].
    readonly property list<Component> comps: [
        appearanceComp,
        wallpaperComp,
        barComp,
        audioComp,
        networkComp,
        bluetoothComp,
        displayComp,
        inputComp,
        windowManagerComp,
        notificationsComp,
        sessionComp,
        appsComp,
        servicesComp,
        languageRegionComp,
        updatesComp,
        securityComp,
        aboutComp
    ]

    // Index-locked to `comps` above (and therefore to `PageRegistry.pages`
    // too) — one slug per entry, same order. Purely a static identity key
    // for the assertion below and for `settings-index-check`'s CHECK E; it
    // is never read by `Pages.qml` itself, which still indexes `comps`
    // directly.
    readonly property list<string> compSlugs: [
        "appearance",
        "wallpaper",
        "bar",
        "audio",
        "network",
        "bluetooth",
        "display",
        "input",
        "window-manager",
        "notifications",
        "session",
        "apps",
        "services",
        "language-region",
        "updates",
        "security",
        "about"
    ]

    Component.onCompleted: {
        if (root.comps.length !== PageRegistry.pages.length) {
            console.warn("PageCompRegistry: comps.length (" + root.comps.length + ") != PageRegistry.pages.length (" + PageRegistry.pages.length + ") — a mismatch renders the wrong page with no error");
            return;
        }
        // Per-index IDENTITY, not just length (WR-03) — a same-length
        // reorder of either array passes the check above but would still
        // render the wrong page for at least one slug with no error.
        for (var i = 0; i < root.compSlugs.length; i++) {
            if (root.compSlugs[i] !== PageRegistry.pages[i].slug) {
                console.warn("PageCompRegistry: index " + i + " identity mismatch — compSlugs[" + i + "]=\"" + root.compSlugs[i] + "\" != PageRegistry.pages[" + i + "].slug=\"" + PageRegistry.pages[i].slug + "\" — a mismatch renders the wrong page with no error");
            }
        }
    }
}
