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

        // Arrow-key nav rail selection (Dashboard.qml:725-726's own
        // clamped-arrow idiom, translated from its horizontal Left/Right
        // tab strip to this vertical rail's Up/Down): each press moves
        // and IMMEDIATELY activates the adjacent page — no separate
        // highlight-then-commit step, matching both Dashboard's own
        // direct-activate model and this rail's existing click behaviour
        // (a NavRail click also activates immediately). Clamped at both
        // ends: at index 0 an Up press and at index 3 a Down press change
        // nothing.
        Keys.onUpPressed: win.sState.goToPage(Math.max(0, win.sState.currentPageIdx - 1))
        Keys.onDownPressed: win.sState.goToPage(Math.min(PageRegistry.pages.length - 1, win.sState.currentPageIdx + 1))

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
