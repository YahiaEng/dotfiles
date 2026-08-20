// modules/settings/Settings.qml — a real XDG toplevel (FloatingWindow),
// not a layer surface (PD-01, RESEARCH.md A3 — measured live this task:
// class "org.quickshell", takes keyboard focus, both open()/toggle() IPC
// verbs drive it). Root import is plain `import Quickshell` — FloatingWindow
// arrives via `default import Quickshell._Window`
// (/usr/lib/qt6/qml/Quickshell/qmldir:7); do not import Quickshell._Window
// explicitly.
//
// Composition: a left NavRail beside a lazily-incubated Pages host
// (RESEARCH.md pattern, Caelestia's Nexus.qml shape), both driven by one
// SettingsState instance owned here — NOT a singleton, so a
// closed-and-reopened window starts fresh (SettingsState.qml's own header).
import QtQuick
import QtQuick.Window
import Quickshell
import "../"

FloatingWindow {
    id: win

    signal closeRequested()

    // Seeds SettingsState's currentPageIdx on construction only — the
    // shell-root `openSettingsPage()` deep-link's first-open path (see
    // shell.qml). Read once at Component.onCompleted below.
    property int initialPageIdx: 0

    readonly property SettingsState sState: SettingsState {}

    title: "Settings"
    color: Colours.surface
    minimumSize.width: 900
    minimumSize.height: 620
    implicitWidth: 960
    implicitHeight: 640

    readonly property int navRailWidth: 260

    Rectangle {
        id: background
        anchors.fill: parent
        color: Colours.surfaceVariant
    }

    Row {
        anchors.fill: parent

        NavRail {
            id: navRail
            width: win.navRailWidth
            height: parent.height
            sState: win.sState
        }

        Pages {
            id: pagesHost
            width: parent.width - navRail.width
            height: parent.height
            sState: win.sState
        }
    }

    // Esc dismiss — same `content` Item + Keys.onEscapePressed shape
    // PanelDialog.qml:222-227 already uses for its own frame. Declared
    // AFTER the Row above so it never intercepts clicks meant for the nav
    // rail or page content (z-order follows declaration order).
    Item {
        id: escCatcher
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.closeRequested()

        // FIX (tracer checkpoint fail #2, "Esc dead"): a single
        // Component.onCompleted `forceActiveFocus()` races the compositor.
        // MEASURED live: at Component.onCompleted, `Window.window` is
        // still null (the underlying toplevel has not yet become the
        // OS-active window) — that settles ~800ms later, well after this
        // item's own construction, so a one-shot grab can lose the race
        // and leave NO item holding focus, silencing Keys.onEscapePressed
        // with no error. `Window.onActiveChanged` is the standard QtQuick
        // idiom for "(re)claim focus whenever this window becomes the
        // active one" — it fires once when the race resolves in the
        // window's favour, AND again on every later regain (e.g. the user
        // alt-tabs away and back), so Esc keeps working for the whole
        // session rather than only in the lucky-timing case.
        Window.onActiveChanged: {
            if (escCatcher.Window.active)
                escCatcher.forceActiveFocus();
        }
        Component.onCompleted: forceActiveFocus()
    }

    Connections {
        target: win.sState
        function onClose() {
            win.closeRequested();
        }
    }

    Component.onCompleted: win.sState.currentPageIdx = win.initialPageIdx
}
