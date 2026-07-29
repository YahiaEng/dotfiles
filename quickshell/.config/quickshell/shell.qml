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
import QtQml
import Quickshell
import Quickshell.Hyprland
import "modules"
import "modules/dashboard"

ShellRoot {
    id: root

    // Selected-tab memory (D-14, Phase 14 Plan 03): the dashboard drawer's
    // LazyLoader destroys the surface on dismiss, so this is the only
    // thing that outlives it — Dashboard.qml seeds its pager from this on
    // summon and reports every change back via tabSelected. Session-level
    // memory only (CONTEXT.md's discretion note); never persisted to disk.
    property int dashboardTabIndex: 0

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

    // Dashboard drawer (Phase 14 tracer, D-09/D-14/DASH-01): the same
    // summon-via-LazyLoader mechanism as the two probes above. Deactivating
    // destroys the wl_surface rather than hiding it, so `hyprctl layers -j`
    // goes empty on every dismissal path (D-14). Single instance — no
    // per-screen Variants fan-out, per D-14/QS-03 (PROJECT.md D-13).
    LazyLoader {
        id: dashboardLoader
        active: false

        Dashboard {
            initialTabIndex: root.dashboardTabIndex
            mediaBackend: mediaBackendInstance
            weatherBackend: weatherBackendInstance
            systemResources: systemResourcesInstance
            onDismissRequested: dashboardLoader.active = false
            onTabSelected: (index) => root.dashboardTabIndex = index
        }
    }

    // Shared data backends (D-14, Phase 14 Plan 03) — mounted once at the
    // shell root, siblings of dashboardLoader rather than inside it, so
    // they warm-hold/settle independently of the drawer surface's own
    // destroy-on-dismiss lifecycle. drawerOpen gates each backend's
    // eventual timer/process so nothing runs while the drawer is closed
    // (zero idle footprint, matching the tracer's own promise). Mounting
    // both here — rather than letting 14-05/14-07 each mount their own —
    // is the scope correction 14-03-PLAN.md records: it is what leaves
    // those two plans exactly one file each to touch, so wave 3 can run in
    // parallel.
    MediaBackend {
        id: mediaBackendInstance
        drawerOpen: dashboardLoader.active
    }

    WeatherBackend {
        id: weatherBackendInstance
        drawerOpen: dashboardLoader.active
    }

    // Round-3 render-gate correction (14-06, defect B — "warm cache across
    // opens"): moved here from inside Dashboard.qml for EXACTLY the reason
    // this comment block already states for MediaBackend/WeatherBackend
    // above — mounting inside the LazyLoader means the whole reader is
    // destroyed and rebuilt on every dismiss, so "keep the last-known
    // reading in memory across a close/reopen" is structurally impossible
    // from in there: there is no "last known" once the instance holding it
    // no longer exists. `drawerOpen` still gates every timer/process
    // exactly as before (D-36's zero-idle doctrine is untouched — polling
    // still stops dead on dismiss); only the VALUES now genuinely survive
    // the dismiss-and-resummon cycle, the way MediaBackend/WeatherBackend's
    // already do.
    SystemResources {
        id: systemResourcesInstance
        drawerOpen: dashboardLoader.active
    }

    // ── DASH-08 fullscreen refusal guard (D-11, Phase 14 Plan 01) ───────
    // LIVE FINDING, not an assumption (three independent proofs this
    // session on Hyprland 0.56.1): "maximize" (hl.dsp.window.fullscreen(1))
    // and "true fullscreen" (hl.dsp.window.fullscreen(0)) are
    // INDISTINGUISHABLE on this build. Both report
    // fullscreen:2/fullscreenClient:2 in hyprctl -j clients/activewindow;
    // both clear `hyprctl -j monitors`' reserved array to [0,0,0,0]; both
    // emit the byte-identical "fullscreen>>1"/"closelayer>>waybar"
    // "openlayer>>waybar" socket2 IPC event sequence (captured live via a
    // raw socket read, not read from documentation). Reproduced across
    // three separate windows (a tiled Zen window, a tiled kitty window,
    // and a genuinely floating kitty window) — not a fluke of one client.
    //
    // Consequence: D-11's literal "maximized windows (bar visible) do not
    // block" carve-out is NOT implementable on this build — Hyprland
    // exposes no signal anywhere in its IPC surface to discriminate the
    // two states, so this guard blocks on the only value Hyprland ever
    // reports for either state (2). This is, ironically, the MOST faithful
    // reading of D-11's own stated rationale ("matches waybar's existing
    // fullscreen-withdraw behavior") — that existing waybar behavior,
    // proven live this session, ALSO does not distinguish maximize from
    // fullscreen. Flagged prominently in 14-01-SUMMARY.md for operator
    // review at the phase's end-of-phase human verification; not silently
    // absorbed.
    //
    // Fails OPEN, not closed (deliberate, D-11's own recorded assumption):
    // optional chaining means a null/absent toplevel or missing field
    // evaluates to false, so the drawer opens rather than becoming
    // permanently unsummonable if the IPC read is ever momentarily
    // unavailable — failing closed would sacrifice DASH-01 to protect
    // DASH-08.
    readonly property bool fullscreenBlocking: (Hyprland.activeToplevel?.lastIpcObject?.fullscreen ?? 0) === 2

    // Hyprland.activeToplevel.lastIpcObject can lag the instant a
    // fullscreen toggle fires; force a refresh on the compositor's own
    // "fullscreen" socket2 event (event name confirmed live this session
    // via a raw socket read — not assumed) so the guard reads current
    // state at the moment Super+D is pressed.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "fullscreen") {
                Hyprland.refreshToplevels();
            }
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

    GlobalShortcut {
        id: dashboardShortcut
        appid: "quickshell"
        name: "dashboard"
        // An already-open drawer always closes, whatever is fullscreen
        // behind it — the refusal guard must never trap a summoned drawer
        // (D-11). Otherwise, only open when fullscreenBlocking is false;
        // when blocked, do nothing at all — no notification, no sound, no
        // visible acknowledgement (DASH-08's whole point).
        onPressed: {
            if (dashboardLoader.active) {
                dashboardLoader.active = false;
            } else if (!root.fullscreenBlocking) {
                dashboardLoader.active = true;
            }
        }
    }
}
