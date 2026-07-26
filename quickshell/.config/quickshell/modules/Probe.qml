// Probe.qml — the QS-02 human input-viability instrumentation panel (D-03)
//
// One panel, four instruments, nothing more:
//   1. a button whose click increments a counter
//   2. a text field that accepts typed characters
//   3. a label bound through FileView/JsonAdapter to a hand-editable JSON
//      file (~/.local/state/quickshell/probe.json)
//   4. a label showing the name of the screen it is rendering on
//
// Deliberately unstyled (D-04): QtQuick defaults only, no authored colour
// of any kind. This ugliness is intentional — the probe must never be
// mistakable for a shipped surface (Phase 12 owns the QML render-target
// format).
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: probeWindow

    // Emitted when HyprlandFocusGrab clears (click-outside dismiss).
    // shell.qml's LazyLoader listens for this to deactivate itself so the
    // wl_surface is actually destroyed, not merely hidden (D-02).
    signal dismissRequested()

    implicitWidth: 360
    implicitHeight: 260

    // D-21: overlay layer, distinct namespace, zero exclusive zone.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-probe"
    // Explicit keyboardFocus set directly, deliberately not via the
    // window's convenience boolean alias — the docs don't state the exact
    // enum that shorthand maps to, and QS-02 lives or dies on keyboard
    // focus working (RESEARCH.md Anti-Patterns).
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0

    // ── Click-outside dismiss (D-03) ─────────────────────
    HyprlandFocusGrab {
        id: grab
        windows: [ probeWindow ]
        active: true
        onCleared: probeWindow.dismissRequested()
    }

    // ── Hand-edited JSON state (D-03/D-20/QS-04) ─────────
    // Own state directory, never ~/.local/state/theme/. Absent file or
    // absent key renders the JsonAdapter's declared default ("unset")
    // rather than crashing.
    FileView {
        id: probeState
        path: Quickshell.env("HOME") + "/.local/state/quickshell/probe.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: probeAdapter
            property string label: "unset"
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 12

        Row {
            spacing: 8

            Button {
                id: counterButton
                text: "Click me"
                onClicked: counterLabel.count += 1
            }

            Label {
                id: counterLabel
                property int count: 0
                text: "Count: " + count
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        TextField {
            id: probeTextField
            placeholderText: "Type here"
        }

        Label {
            id: stateLabel
            text: "State label: " + probeAdapter.label
        }

        Label {
            id: screenLabel
            text: "Screen: " + (probeWindow.screen ? probeWindow.screen.name : "unknown")
        }
    }
}
