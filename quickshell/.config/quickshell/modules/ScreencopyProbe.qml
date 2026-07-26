// ScreencopyProbe.qml — criterion-5 screencopy feasibility instrumentation
// (D-12, 11-05 Task 1)
//
// Second summonable surface, mirroring Probe.qml's D-21 layer-shell
// convention exactly (overlay layer, exclusiveZone: 0, WlrKeyboardFocus.
// OnDemand, HyprlandFocusGrab click-outside dismiss) under its own
// distinct namespace. Renders one live ScreencopyView capture tile per
// currently-open toplevel window (Quickshell.Wayland's ToplevelManager
// singleton + Toplevel model), laid out as a plain grid, each tile
// captioned with the window's own title/appId so a blank tile is
// unambiguously distinguishable from a tile correctly capturing a
// genuinely blank window.
//
// Deliberately unstyled (D-04): QtQuick defaults only, no authored colour
// of any kind. No render-speed counter, timing instrumentation or resource
// readout of any kind is present here — that measurement is OVER-04's
// requirement in Phase 16, and D-12 explicitly forbids pulling it forward.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: screencopyProbeWindow

    // Emitted when HyprlandFocusGrab clears (click-outside dismiss).
    // shell.qml's LazyLoader listens for this to deactivate itself so the
    // wl_surface is actually destroyed, not merely hidden (D-02).
    signal dismissRequested()

    implicitWidth: 900
    implicitHeight: 640

    // D-21: overlay layer, distinct namespace, zero exclusive zone —
    // exactly Probe.qml's convention, under its own namespace.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-screencopy-probe"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0

    // ── Click-outside dismiss (D-03 convention, reused) ──────────────
    HyprlandFocusGrab {
        id: grab
        windows: [ screencopyProbeWindow ]
        active: true
        onCleared: screencopyProbeWindow.dismissRequested()
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Label {
            text: "Screencopy probe (criterion 5 feasibility) — " + winRepeater.count + " window(s) captured live"
        }

        Grid {
            id: tileGrid
            width: parent.width
            columns: 3
            spacing: 12

            Repeater {
                id: winRepeater
                // ToplevelManager (Quickshell.Wayland) is the live registry
                // of every open toplevel window; .toplevels is an
                // UntypedObjectModel of Toplevel objects, each exposed as
                // `modelData` in this delegate — the standard Quickshell
                // pattern for a per-window fan-out.
                model: ToplevelManager.toplevels

                delegate: Column {
                    width: 260
                    height: 200
                    spacing: 4

                    ScreencopyView {
                        width: parent.width
                        height: parent.height - 24
                        // captureSource accepts the Toplevel object itself
                        // (Quickshell.Wayland/ScreencopyView docs) — one
                        // live capture per currently-open window.
                        captureSource: modelData
                        live: true
                    }

                    Label {
                        width: parent.width
                        elide: Text.ElideRight
                        text: (modelData.title !== "" ? modelData.title : (modelData.appId !== "" ? modelData.appId : "unknown"))
                    }
                }
            }
        }
    }
}
