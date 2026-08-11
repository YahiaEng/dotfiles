// Synthetic minimal stand-in (Phase 18 Plan 17, GATE-03) — the
// pre-existing shared panel frame (D-15-02/D-15-03), NOT a bar-family
// frame and NOT a registry row: proves the reverse-closure's
// QSD_KNOWN_NONBAR_FRAMES exemption works rather than flagging every
// pre-existing summonable frame as an unregistered surprise.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: panelWindow
    property string namespaceSuffix: "audio-panel"
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-" + panelWindow.namespaceSuffix
}
