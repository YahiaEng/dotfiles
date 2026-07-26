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

    // QS-03 per-screen fan-out (D-12, Phase 12 arrangement B — arrangement
    // A, a Variants+LazyLoader fan-out declared here in shell.qml,
    // reproduced 11-QUICKSHELL-EVIDENCE.md's FM2 post-hotplug visibility
    // break verbatim and was reverted). The fan-out now lives entirely
    // inside modules/Probe.qml (rooted at `Variants` instead of
    // `PanelWindow`), so shell.qml touches the local `Probe` type exactly
    // once, same as the pre-Phase-12 single-screen design. `probeInstance`
    // exposes a shared `active` property and `dismissRequested` signal
    // that Probe.qml's own per-screen delegates all bind to/emit.
    Probe {
        id: probeInstance
        onDismissRequested: probeInstance.active = false
    }

    // Criterion-5 screencopy feasibility probe (11-05 Task 1), same
    // summon-via-LazyLoader mechanism as the probe above, second
    // GlobalShortcut/manifest entry proving D-17's declared-manifest
    // mechanism scales to a second surface. Structurally untouched by
    // this plan (QS-03 changes the probe's fan-out only) — kept on its
    // original single-LazyLoader shape as a control.
    LazyLoader {
        id: screencopyProbeLoader
        active: false

        ScreencopyProbe {
            onDismissRequested: screencopyProbeLoader.active = false
        }
    }

    GlobalShortcut {
        id: probeShortcut
        appid: "quickshell"
        name: "probe"
        onPressed: probeInstance.active = !probeInstance.active
    }

    GlobalShortcut {
        id: screencopyProbeShortcut
        appid: "quickshell"
        name: "screencopy-probe"
        onPressed: screencopyProbeLoader.active = !screencopyProbeLoader.active
    }
}
