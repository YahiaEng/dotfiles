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
//
// ── Focus-retention MEASUREMENTS (third tracer-checkpoint round,
//    2026-08-20). Reproduction throughout: open Settings with the cursor
//    confirmed OUTSIDE its bounds, dispatch
//    `hl.dsp.focus({window="class:^(kitty)$"})` (the compositor's own
//    focus path — the measurable proxy for a real follow_mouse hover
//    stealing focus, since `hl.dsp.cursor.move` warps do NOT drive
//    Hyprland's focus system at all: measured 3x, including a warp
//    squarely inside another window's bounds, zero effect on
//    `hyprctl activewindow`), then read `hyprctl activewindow -j` and try
//    the candidate close path.
//    - `stayfocused` window rule: DOES NOT EXIST in this build's Lua
//      vocabulary. `hl.window_rule({..., stayfocused = true})` throws
//      "unknown field 'stayfocused'" directly from Hyprland's own
//      validator — also tried forcefocus/keepfocus/keep_focus/
//      force_focus/pin_focus/focus_lock, all rejected the same way. Dead.
//    - Reactive re-dispatch alone (`Window.onActiveChanged` -> re-issuing
//      `hl.dsp.focus` at self, no grab): `Window.active` (Qt's own
//      belief) flips back to true, but `hyprctl activewindow`
//      (Hyprland's authoritative state) stays on the window that stole
//      focus. 4/4 clean trials: Esc did not survive a genuine focus
//      steal with only this in place.
//    - `HyprlandFocusGrab` (below), added on top of the above: the
//      earlier round's revert was an UNTESTED fear, not a measurement,
//      and was wrong. Measured: it correctly ignores the Theme
//      dropdown's own Menu popup (no false `onCleared` across a
//      popup()/close() cycle). Against the focus-steal reproduction,
//      `hyprctl activewindow` STILL moves to the other window and
//      `onCleared` does NOT fire — but Esc closes the window anyway,
//      12/12 clean trials, with the window confirmed still open right up
//      to the Escape press (no premature close via `onCleared`). Reading:
//      `hyprland-focus-grab-v1` captures wl_keyboard routing at a lower
//      protocol layer than window activation — `activewindow` is
//      reporting which window LOOKS focused, not which surface actually
//      receives the next key event once a grab is active. `activewindow`
//      is therefore NOT a reliable proxy for keyboard delivery once a
//      grab is in play, which is exactly what makes this fix work.
//    - `Super+comma` (the same `openSettings()` toggle a real
//      GlobalShortcut press invokes) ALSO survives a genuine focus steal,
//      7/7 clean trials, with or without the grab: it is
//      compositor-dispatched, bypassing wl_seat keyboard-focus routing
//      entirely. Kept as the documented alternate close path.
import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Hyprland
import "../"

FloatingWindow {
    id: win

    signal closeRequested()

    // Task 2 (ConnectivityPage) — re-emitted from SettingsState's own
    // signal of the same shape (see SettingsState.qml's header); shell.qml
    // listens on this and calls the guarded `openPanel(name)`.
    signal panelRequested(name: string)

    // Seeds SettingsState's currentPageIdx on construction only — the
    // shell-root `openSettingsPage()` deep-link's first-open path (see
    // shell.qml). Read once at Component.onCompleted below.
    property int initialPageIdx: 0

    // Task 13 (D-01 bundle 4) — relayed onto `sState` at construction, the
    // same shape `initialPageIdx` already uses. `AudioPage.qml` reads
    // `sState.audioBackend` — pages are incubated with only `{ sState }`
    // (Pages.qml's own `incubateObject` call), so the state object is the
    // only channel a dynamically-incubated page has back to this window.
    property var audioBackend: null
    // quick-260821-6z1 fix wave — same relay shape as audioBackend above,
    // for NetworkPage.qml's own inline Wi-Fi/Bluetooth controls.
    property var wifiBackend: null
    property var bluetoothBackend: null

    readonly property SettingsState sState: SettingsState {
        audioBackend: win.audioBackend
        wifiBackend: win.wifiBackend
        bluetoothBackend: win.bluetoothBackend
    }

    // ── Window identity and size (quick task 260825-v3u, operator D-2) ───
    //    Both dimensions come from Caelestia's `NexusTokens`
    //    (plugin/src/Caelestia/Config/tokens.hpp:212-220), read from source
    //    rather than eyeballed: heightMult 0.7, ratio 16/9, minWidth 800,
    //    minHeight 500. `Nexus.qml` derives its own implicitHeight the same
    //    way. This file's header already recorded that its composition came
    //    from that window; the sizing now comes from there too.
    //
    //    SCREEN-RELATIVE, NOT A FIXED PAIR, and that is the point of copying
    //    the formula rather than its output: 960x640 was 37% of the width of
    //    this 2560x1440 host and would be a different fraction of every other
    //    display the shell is ever installed on. On this host the formula
    //    resolves to 1792x1008.
    //
    //    `screen` (WindowInterface's own QuickshellScreenInfo, verified
    //    against /usr/lib/qt6/qml/Quickshell/_Window/quickshell-window.qmltypes)
    //    is null until the window is mapped, so it is guarded rather than
    //    dereferenced: an unguarded `win.screen.height` throws at
    //    construction and QML then leaves implicitHeight at 0 permanently —
    //    the undefined-branch-destroys-the-binding failure this repo has
    //    already shipped once. 1080 is the fallback, giving 1344x756.
    readonly property int _screenHeight: (win.screen && win.screen.height > 0) ? win.screen.height : 1080
    readonly property real _heightMult: 0.7
    readonly property real _aspectRatio: 16 / 9

    // The current page's name rides in the title, as Caelestia's
    // WindowFactory.qml does ("Nexus — %1"), so the window is identifiable
    // from a taskbar or an alt-tab list rather than reading "Settings" on
    // all ten pages. Index-guarded: `currentPageIdx` is seeded from
    // `initialPageIdx` and could in principle arrive out of range.
    title: {
        var pages = PageRegistry.pages;
        var idx = win.sState ? win.sState.currentPageIdx : 0;
        return (idx >= 0 && idx < pages.length) ? "Settings — " + pages[idx].label : "Settings";
    }
    color: Colours.surface
    minimumSize.width: 800
    minimumSize.height: 500
    implicitHeight: Math.max(500, Math.round(win._screenHeight * win._heightMult))
    implicitWidth: Math.max(800, Math.round(win.implicitHeight * win._aspectRatio))

    // Proportional, so the rail keeps its share of a window that is now
    // screen-sized. Caelestia uses `min(maxNavWidth, width / 3)`; the divisor
    // here is 4 rather than 3 because their nav rows are a taller, more
    // spacious shape than this rail's compact list — width/3 of 1792 would be
    // 597px of mostly empty rail. width/4 keeps the rail at roughly the 27%
    // share it had at 960x640, and the 340 cap stops it growing without limit
    // on an ultrawide.
    // `win.width` is 0 until the window is mapped; falling back to
    // implicitWidth keeps the rail from rendering at zero width for the
    // first frame and shoving the whole Row.
    readonly property int navRailWidth: Math.min(340, Math.round(Math.max(win.width, win.implicitWidth) / 4))

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

        // Arrow-key nav rail selection (Dashboard.qml:725-726's own
        // clamped-arrow idiom, translated from its horizontal Left/Right
        // tab strip to this vertical rail's Up/Down): each press moves
        // and IMMEDIATELY activates the adjacent page — no separate
        // highlight-then-commit step, matching both Dashboard's own
        // direct-activate model and this rail's existing click behaviour
        // (a NavRail click also activates immediately). Clamped at both
        // ends: at index 0 an Up press and at index 3 a Down press change
        // nothing.
        //
        // SPEC CORRECTION (operator, second live-pass): the first Left/
        // Right attempt mirrored Up/Down as a second page-switch axis —
        // wrong model. The operator's own words: "I want left/right
        // arrows to move between the left side and right side of the
        // options menu." This is TWO-PANE FOCUS, not paging: Right moves
        // keyboard focus from the rail INTO the content pane (Pages.qml's
        // own row-focus tracking, since these rows use this shell's
        // existing virtual-selection idiom — the rail itself is not a
        // real QML focus chain either, see NavRail.qml); Left returns
        // focus to the rail. Up/Down navigate WITHIN whichever pane
        // currently holds focus: rail entries (unchanged, above) when the
        // rail holds it, content-pane rows (`pagesHost.moveContentRow`)
        // when the content pane does.
        Keys.onUpPressed: {
            if (pagesHost.contentFocused)
                pagesHost.moveContentRow(-1);
            else
                win.sState.goToPage(Math.max(0, win.sState.currentPageIdx - 1));
        }
        Keys.onDownPressed: {
            if (pagesHost.contentFocused)
                pagesHost.moveContentRow(1);
            else
                win.sState.goToPage(Math.min(PageRegistry.pages.length - 1, win.sState.currentPageIdx + 1));
        }
        Keys.onLeftPressed: pagesHost.exitContent()
        Keys.onRightPressed: pagesHost.enterContent()

        // Fix WR-02 (code review, quick-260821-6z1 fix wave) — the
        // two-pane focus ring above had no way to ACT on the row it
        // highlighted. Dispatches to whichever row currently holds
        // `contentRowIdx`, via `Pages.qml`'s own duck-typed
        // `activateContentRow()` — see that function's header for which
        // row types respond and why SliderRow is a named, sized
        // follow-up rather than handled here.
        Keys.onReturnPressed: pagesHost.activateContentRow()
        Keys.onEnterPressed: pagesHost.activateContentRow()
        Keys.onSpacePressed: pagesHost.activateContentRow()

        // Re-claims QML-level focus every time this window (re)gains real
        // OS activation — fixes the original construction-time race
        // (Component.onCompleted alone can fire before
        // `Window.window` even exists, ~150ms window, measured in the
        // second tracer-checkpoint round). Alone, this does not survive a
        // genuine external focus steal — the `HyprlandFocusGrab` below is
        // what makes Esc survive that case (see the file header's
        // measurements for both).
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
        function onPanelRequested(name) {
            win.panelRequested(name);
            win.closeRequested();
        }
    }

    // Click-outside-dismiss (D-06 discretion, matching Dashboard.qml:526's
    // own HyprlandFocusGrab + onCleared shape) AND the mechanism that
    // makes Esc survive a genuine focus steal (see the file header's
    // measurements — `onCleared` itself never fires for a focus() steal,
    // but the grab's own wl_keyboard capture is what keeps Escape
    // reaching this window regardless). The click-outside half of this
    // specifically is NOT machine-verified end to end: it needs a real
    // mouse click, which no tool on this host can synthesize.
    HyprlandFocusGrab {
        id: grab
        windows: [win]
        active: true
        onCleared: win.closeRequested()
    }

    Component.onCompleted: win.sState.currentPageIdx = win.initialPageIdx
}
