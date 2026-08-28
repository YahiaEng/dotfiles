// modules/appearance/Atelier.qml — the Atelier window (quick task
// 260828-ah9, Task 2, D-01/D-02). One `FloatingWindow` with
// Icons | Fonts | Catalogue tabs, structurally mirroring
// `modules/packages/Workbench.qml` — the keybind path, and the only home
// for the catalogue (Task 3).
//
// ── LIFECYCLE ─────────────────────────────────────────────────────────
// LazyLoader, not a bare FloatingWindow — Workbench's own pattern: the
// window is constructed on first open, so declaring it in shell.qml costs
// nothing until something calls open()/openTab(). The BACKEND
// (AppearanceBackend) is a singleton and lives outside this loader on
// purpose, so closing the window does not discard the icon-theme/font
// model or the Task 3 catalogue's install log.
//
// ── NOTHING HERE RUNS A TRANSACTION ───────────────────────────────────
// `applyIconTheme`/`applyFont` are fixed-argv `--set` calls the backend
// owns. Task 3's catalogue install is its own privilege story — see that
// file's header once it lands.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".."
import "../dashboard"

LazyLoader {
    id: loader

    // Which tab to land on. Set by AppearanceBackend.openAtelier(tab) via
    // shell.qml's Connections block BEFORE the loader activates — applied
    // on an ALREADY-OPEN window too (`item.setTab`), so a second request
    // re-aims it rather than doing nothing, exactly like Workbench's own
    // `openFilter`.
    property string pendingTab: ""

    function open(): void {
        loader.activeAsync = true;
    }

    function openTab(tab: string): void {
        loader.pendingTab = tab || "";
        loader.activeAsync = true;
        if (loader.item && tab)
            loader.item.setTab(tab);
    }

    function close(): void {
        loader.activeAsync = false;
    }

    FloatingWindow {
        id: win

        // ── View state. Declared before anything that reads it at
        //    construction time (this tree's declare-before-use rule). ────
        // Seeded from Prefs so the tab you left on is the tab you return
        // to; `pendingTab` (a request in flight) overrides it in
        // Component.onCompleted below, Workbench's exact
        // `pendingFocus`/`pendingFilter` shape.
        property string tab: Prefs.getValue("appearance.atelierTab")

        function setTab(t) {
            if (t === win.tab)
                return;
            win.tab = t;
            Prefs.setValue("appearance.atelierTab", t);
        }

        title: "Appearance"

        // Frost, matching Workbench.qml's own recorded shape: `color:
        // "transparent"` on the toplevel, the alpha on an interior
        // Rectangle, and the surface colour assigned through a local
        // `property color` — a `Colours` role is a STRING, and
        // `Qt.rgba()` of its `.r`/`.g`/`.b` renders pure black.
        readonly property color surfaceBase: Colours.surfaceVariant
        readonly property real panelSurfaceOpacity: 0.78
        color: "transparent"

        // ── Size — Workbench's own screen-derived formula (70% of the
        //    screen height at 16:9), so the shell's two browse-a-long-list
        //    windows are the same size as each other on any monitor. A
        //    narrower minimum here: two panes, not three. ────────────────
        readonly property int _screenHeight: (win.screen && win.screen.height > 0) ? win.screen.height : 1080
        readonly property real _heightMult: 0.7
        readonly property real _aspectRatio: 16 / 9

        implicitHeight: Math.max(520, Math.round(win._screenHeight * win._heightMult))
        implicitWidth: Math.max(760, Math.round(win.implicitHeight * win._aspectRatio))
        minimumSize.width: 760
        minimumSize.height: 480

        onVisibleChanged: {
            if (!visible)
                loader.activeAsync = false;
        }

        Component.onCompleted: {
            if (loader.pendingTab.length > 0) {
                win.tab = loader.pendingTab;
                loader.pendingTab = "";
            }
        }

        Rectangle {
            id: background
            anchors.fill: parent
            color: Qt.rgba(win.surfaceBase.r, win.surfaceBase.g, win.surfaceBase.b, win.panelSurfaceOpacity)

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }
        }

        // ── Escape, and dismiss-on-click-outside ────────────────────
        // HyprlandFocusGrab, never Qt's attached `Window.active` —
        // `follow_mouse=1` on this host makes that a HOVER signal
        // (Workbench.qml's own round-2 correction, same defect class).
        Item {
            id: focusCatcher
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: loader.activeAsync = false
            Component.onCompleted: forceActiveFocus()
        }

        HyprlandFocusGrab {
            id: grab
            windows: [win]
            active: true
            onCleared: loader.activeAsync = false
        }

        // A grab is EXCLUSIVE (Workbench.qml's own recorded finding): a
        // terminal launched while it is held is input-dead. Task 3's
        // catalogue install hands off to a terminal, so the grab must be
        // released — closing the window — the instant that happens.
        Connections {
            target: AppearanceBackend

            function onTransactionLaunched(kind) {
                loader.activeAsync = false;
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: Design.spacingMd
            spacing: Design.spacingMd

            AtTabBar {
                id: tabBar
                width: parent.width
                currentTab: win.tab
                onTabSelected: tab => win.setTab(tab)
            }

            Loader {
                id: contentLoader
                width: parent.width
                height: parent.height - tabBar.height - Design.spacingMd
                sourceComponent: {
                    switch (win.tab) {
                    case "fonts":
                        return fontsComponent;
                    case "catalogue":
                        return catalogueComponent;
                    default:
                        return iconsComponent;
                    }
                }
            }

            Component {
                id: iconsComponent

                AtIconsTab {
                }
            }

            Component {
                id: fontsComponent

                AtFontsTab {
                }
            }

            Component {
                id: catalogueComponent

                AtCatalogueTab {
                }
            }
        }
    }
}
