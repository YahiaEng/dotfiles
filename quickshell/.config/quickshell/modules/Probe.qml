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
//
// QS-03 per-screen fan-out (D-12, Phase 12 arrangement B — attempted after
// arrangement A reproduced 11-QUICKSHELL-EVIDENCE.md's FM2 post-hotplug
// visibility break: creating a headless output while shell.qml's
// Variants+LazyLoader was active on DP-1 silently blanked every screen's
// surface, permanently, verified directly with hyprctl layers -j staying
// empty across four subsequent shortcut toggles). This file's root type is
// now `Variants` instead of `PanelWindow`; shell.qml touches the local
// `Probe` type exactly once (no wrapping LazyLoader there any more — the
// summon/dismiss LazyLoader now lives per-screen, inside this file's
// delegate, same as arrangement A). `modules/qmldir` (checked in this same
// plan) is the new variable versus 11-04's own attempt at this exact
// shape: an explicit qmldir disables Quickshell's directory-scanner
// synthesis for modules/ entirely (verified via `-v -v` trace: "Found
// qmldir file, qmldir synthesization will be disabled for directory"),
// closing FM1 (the intermittent "Probe is not a type" config-load race)
// regardless of which arrangement owns the per-screen fan-out.
import QtQml
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

Variants {
    id: probeVariants

    // Summon/dismiss state shared across every screen's delegate — not
    // per-screen — so Super+Shift+G toggles every currently-known screen
    // at once. shell.qml's GlobalShortcut flips this property directly;
    // this is the same LazyLoader-per-screen summon shape as arrangement
    // A, just declared inside this file's delegate instead of shell.qml.
    property bool active: false

    // Emitted when any screen's HyprlandFocusGrab clears (click-outside
    // dismiss). shell.qml listens for this to deactivate `active` so every
    // screen's wl_surface is destroyed, not merely hidden (D-02).
    signal dismissRequested()

    model: Quickshell.screens

    delegate: Component {
        LazyLoader {
            // Variants sets `modelData` as an initial property on the
            // delegate root object (not merely a context property for
            // non-Item roots like LazyLoader) — declare it explicitly so
            // Quickshell has somewhere to put it.
            required property var modelData
            active: probeVariants.active

            PanelWindow {
                id: probeWindow

                implicitWidth: 360
                implicitHeight: 260

                // Binds this delegate's own screen from modelData — hotplug
                // order can never change which surface lands on which
                // output (QS-03/ordering).
                screen: modelData

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
                    onCleared: probeVariants.dismissRequested()
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
        }
    }
}
