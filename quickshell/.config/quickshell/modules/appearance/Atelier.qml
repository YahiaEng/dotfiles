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
        //    narrower minimum here: two panes, not three. This is now only
        //    the FALLBACK default (operator round 1, defect 4) — see
        //    `atelierWidth`/`atelierHeight` below for the persisted size
        //    this formula seeds on a first run. ─────────────────────────
        readonly property int _screenHeight: (win.screen && win.screen.height > 0) ? win.screen.height : 1080
        readonly property int _screenWidth: (win.screen && win.screen.width > 0) ? win.screen.width : 1920
        readonly property real _heightMult: 0.7
        readonly property real _aspectRatio: 16 / 9
        readonly property int _defaultHeight: Math.max(520, Math.round(win._screenHeight * win._heightMult))
        readonly property int _defaultWidth: Math.max(760, Math.round(win._defaultHeight * win._aspectRatio))

        // Operator round 1, defect 4: the window reset to the
        // screen-derived default on every close/reopen because nothing
        // persisted it. `0` is Prefs' own "unset" sentinel (see
        // `Prefs.qml`'s allowlist comment) — a first run or a stale
        // off-screen value both fall back to the same formula above,
        // and every read is clamped to the current screen's bounds so a
        // value saved on a since-disconnected monitor cannot wedge the
        // window off-screen.
        property int atelierWidth: {
            var stored = Prefs.getValue("appearance.atelierWidth");
            var v = stored > 0 ? stored : win._defaultWidth;
            return Math.max(760, Math.min(win._screenWidth, Math.round(v)));
        }
        property int atelierHeight: {
            var stored = Prefs.getValue("appearance.atelierHeight");
            var v = stored > 0 ? stored : win._defaultHeight;
            return Math.max(480, Math.min(win._screenHeight, Math.round(v)));
        }

        // Called from `onWidthChanged`/`onHeightChanged` below — every
        // live resize (drag-resize, `startSystemResize`, or a compositor
        // move) updates `width`/`height` directly, never `implicitWidth`,
        // so this is the one place that persists what the operator
        // actually left the window at.
        //
        // ── Operator round 2, defect 3 — WHY THE ROUND-1 FIX DID NOT
        //    STICK, and it was not the save path. ────────────────────────
        // `onWidthChanged`/`onHeightChanged` also fire during TEARDOWN:
        // the LazyLoader destroys this window on close, `width`/`height`
        // collapse toward 0 on the way out, and the round-1 body then ran
        // `Math.max(760, 0)` -> 760 and WROTE it. So every close
        // overwrote the operator's real size with the clamp floor. Proof
        // it was the floor and not a failed write: `prefs.json` held
        // exactly `atelierWidth: 760, atelierHeight: 480` — both minimums
        // to the pixel — while `iconsRailWidth: 233` and
        // `catalogueLeftWidth: 432` from the SAME Prefs path had
        // persisted fine.
        //
        // The bug is the clamp itself: clamping turns an INVALID sample
        // into a plausible one, so bad data is indistinguishable from a
        // deliberate minimum. Reject the sample instead. A window that is
        // not visible, or is not yet laid out, has nothing worth saving.
        function _persistSize() {
            if (!win.visible)
                return;
            // Below-minimum is teardown or pre-layout, never a real size:
            // `minimumSize` prevents the compositor from ever handing us
            // one legitimately.
            if (win.width < 760 || win.height < 480)
                return;
            var w = Math.min(win._screenWidth, Math.round(win.width));
            var h = Math.min(win._screenHeight, Math.round(win.height));
            if (w !== win.atelierWidth) {
                win.atelierWidth = w;
                Prefs.setValue("appearance.atelierWidth", w);
            }
            if (h !== win.atelierHeight) {
                win.atelierHeight = h;
                Prefs.setValue("appearance.atelierHeight", h);
            }
        }

        implicitHeight: win.atelierHeight
        implicitWidth: win.atelierWidth
        minimumSize.width: 760
        minimumSize.height: 480

        onWidthChanged: win._persistSize()
        onHeightChanged: win._persistSize()

        // Live counts for the header's sub-line (defect 2a) — read
        // straight off the one backend every surface shares, never a
        // second count kept in sync by hand.
        readonly property int _iconThemeCount: AppearanceBackend.iconThemes.length
        readonly property int _fontFamilyCount: {
            var seen = {};
            var n = 0;
            var arr = AppearanceBackend.fontFamilies;
            for (var i = 0; i < arr.length; ++i) {
                if (!seen[arr[i].family]) {
                    seen[arr[i].family] = true;
                    n++;
                }
            }
            return n;
        }
        readonly property string _headerSub: win._iconThemeCount + " themes · " + win._fontFamilyCount + " families"

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
            // Operator round 1, defect 1: while the uninstall-confirm
            // overlay is showing, Escape cancels THAT (never applies a
            // destructive action by accident) rather than closing the
            // whole window underneath it.
            Keys.onEscapePressed: {
                if (AppearanceBackend.uninstallPlan !== null) {
                    AppearanceBackend.cancelUninstall();
                    return;
                }
                loader.activeAsync = false;
            }
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

        Item {
            id: chrome
            anchors.fill: parent

            // ── Title bar (defects 2a, 3) — the study's own `.surf-hd`:
            //    name on the left, a live count on the right, full-bleed
            //    with a rule beneath it. A MouseArea confined to THIS
            //    Item's bounds gives Windows-10-style drag-to-move —
            //    `startSystemMove()` (verified present on
            //    `FloatingWindowInterface`) — without ever intercepting a
            //    click on the tab strip or any control below it, since
            //    those live in `body` and never overlap `header`.
            Item {
                id: header
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 44

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Qt.alpha(Colours.outline, 0.35)
                }

                Text {
                    id: headerTitle
                    anchors.left: parent.left
                    anchors.leftMargin: Design.spacingMd
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Appearance"
                    font.pixelSize: Design.settingsFontRow
                    font.bold: true
                    color: Colours.onSurface
                    textFormat: Text.PlainText
                }

                Text {
                    id: headerSub
                    anchors.right: parent.right
                    anchors.rightMargin: Design.spacingMd
                    anchors.verticalCenter: parent.verticalCenter
                    text: win._headerSub
                    font.pixelSize: Design.fontLabel
                    color: Colours.onSurfaceVariant
                    textFormat: Text.PlainText
                }

                // Drag-to-move (defect 3). `onPressed`, not `onClicked` —
                // a system move must start on press, exactly like every
                // other window-manager title-bar drag.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onPressed: win.startSystemMove()
                }
            }

            Column {
                id: body
                anchors.top: header.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
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

            // Operator round 1, defect 1 — the uninstall-confirmation
            // overlay. Declared LAST so it paints above the header, tab
            // strip and whichever tab is loaded; `AtUninstallConfirm`
            // itself is invisible whenever `AppearanceBackend.
            // uninstallPlan` is null, so this costs nothing the rest of
            // the time.
            AtUninstallConfirm {
            }
        }
    }
}
