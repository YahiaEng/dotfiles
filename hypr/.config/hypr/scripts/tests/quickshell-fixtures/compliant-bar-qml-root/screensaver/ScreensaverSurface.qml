// Synthetic minimal stand-in (quick task 260828-so7) — the screensaver's
// registry row (screensaver/ScreensaverSurface.qml|quickshell-screensaver|
// exact|3|noreserve|transient). Mirrors session/PowerMenu.qml's shape in
// this same fixture directory: a direct WlrLayershell.namespace literal
// plus a literal exclusiveZone, declared in its own source rather than
// forwarded from an instanced parent the way osd/Osd.qml does — so no
// fallback marker is exercised here either.
//
// exclusiveZone is -1, NOT 0, matching the real file. That is deliberate
// and is the one thing this fixture adds over PowerMenu.qml's: it is the
// only fixture in this tree exercising _qsd_zone_is_noreserve's `-1`
// branch, which the real screensaver depends on to cover the bar.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: screensaverWindow
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-screensaver"
    exclusiveZone: -1
    exclusionMode: ExclusionMode.Ignore
}
