// shell.qml — Quickshell shell root (D-01/D-02/D-19)
//
// Headless by design: this root renders nothing on its own. Its only
// visible surface is modules/Probe.qml, summoned only via the
// GlobalShortcut below (Super+Shift+G, quickshell:probe — see
// hypr/.config/hypr/config/keybinds.conf and
// quickshell/.config/quickshell/shortcuts.json).
//
// LazyLoader with active:false is the summon mechanism (RESEARCH.md
// preferred approach): no wl_surface exists at all until the shortcut
// fires, so `hyprctl layers -j` level 3 stays empty in daily use (D-02).
// Deactivating on dismiss (rather than merely hiding) destroys the
// surface the same way, keeping the click-outside-dismiss path
// mechanically identical to the not-yet-summoned state.
//
// Per D-01 this probe graduates into the permanent shell root rather than
// being deleted — it is not scaffolding. Phase 14's dashboard drawer
// mounts into this same root later.
import Quickshell
import Quickshell.Hyprland
import "modules"

ShellRoot {
    id: root

    LazyLoader {
        id: probeLoader
        active: false

        Probe {
            onDismissRequested: probeLoader.active = false
        }
    }

    GlobalShortcut {
        id: probeShortcut
        appid: "quickshell"
        name: "probe"
        onPressed: probeLoader.active = !probeLoader.active
    }
}
