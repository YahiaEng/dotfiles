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
import Quickshell.Io
import "modules"
import "modules/dashboard"
import "modules/bar"
import "modules/notifications"

ShellRoot {
    id: root

    // Selected-tab memory (D-14, Phase 14 Plan 03): the dashboard drawer's
    // LazyLoader destroys the surface on dismiss, so this is the only
    // thing that outlives it — Dashboard.qml seeds its pager from this on
    // summon and reports every change back via tabSelected. Session-level
    // memory only (CONTEXT.md's discretion note); never persisted to disk.
    property int dashboardTabIndex: 0

    // Home-directory accessor (Phase 18 Plan 15) — the same
    // `Quickshell.env("HOME")` idiom QuickToggles.qml/PanelDialog.qml
    // already use for their own fixed-argv Process commands, reused here
    // rather than a second accessor.
    property string homeDir: Quickshell.env("HOME")

    // ── Notification server (Phase 19 Plan 01 tracer, QNOTIF-01,
    //    T-19-02) — a live reference at root scope, not behind any
    //    LazyLoader and carrying no `active` property, forcing the
    //    pragma-Singleton's construction at shell start rather than
    //    lazily on whichever surface first touches it. NotifPopupStack
    //    (this same plan's Task 3) becomes the real per-frame consumer of
    //    NotifServer.popups; this binding exists independently so the
    //    D-Bus name is claimed and held for the whole process lifetime
    //    even before that surface exists.
    readonly property int notifServerUnreadCount: NotifServer.unreadCount

    // ── Notification popup stack (Phase 19 Plan 01 tracer, QNOTIF-02) —
    //    mounted unconditionally at root, matching Bar.qml's own
    //    always-on posture rather than a summon-via-LazyLoader shape: a
    //    notification can arrive at any moment for the whole session,
    //    not only while some other surface is open (this plan's own
    //    key_links). Its own ListView content — empty by default — is
    //    what keeps it visually inert until a real notification exists.
    NotifPopupStack {}

    // ── Notification test IPC surface (Phase 19 Plan 04, Task 3 — Rule 2
    //    deviation, missing critical functionality) — the plan's own
    //    fault-injection fixture (notif-fault-inject) needs a mechanical,
    //    screenshot-free way to read the popup stack's count/index/text
    //    and to invoke a tracked notification's own action exactly the way
    //    a real card's action-button TapHandler would. No such surface
    //    existed before this plan. RESEARCH.md's own "IPC handler shape"
    //    code example already reserves a `notifs` IpcHandler target for
    //    the centre/DND verbs a later plan adds — this extends that SAME
    //    target rather than minting a second one, with only the verbs
    //    this fixture needs today. `invokeAction` calls the real
    //    `NotificationAction.invoke()` method (the same one a card's own
    //    action-button TapHandler calls), not a synthetic bus signal, so
    //    the fixture exercises the shell's actual code path rather than
    //    standing in for it.
    IpcHandler {
        id: notifsIpc
        target: "notifs"

        function count(): int {
            return NotifServer.popups.length;
        }
        function historyCount(): int {
            return NotifServer.history.length;
        }
        function indexOf(id: int): int {
            for (var i = 0; i < NotifServer.popups.length; i++) {
                if (NotifServer.popups[i].notifId === id)
                    return i;
            }
            return -1;
        }
        function textOf(id: int): string {
            var idx = notifsIpc.indexOf(id);
            if (idx === -1)
                return "";
            return NotifServer.popups[idx].summary + "|" + NotifServer.popups[idx].body;
        }
        function invokeAction(id: int, identifier: string): bool {
            var idx = notifsIpc.indexOf(id);
            if (idx === -1)
                return false;
            var actions = NotifServer.popups[idx].actions;
            for (var i = 0; i < actions.length; i++) {
                if (actions[i].identifier === identifier) {
                    actions[i].invoke();
                    return true;
                }
            }
            return false;
        }
    }

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
            // 15-07 — the same three panel backends threaded into the
            // drawer's quick-toggle grid so its Volume/Wi-Fi/Bluetooth
            // tiles read live truth without touching a service singleton.
            audioBackend: audioBackendInstance
            wifiBackend: wifiBackendInstance
            bluetoothBackend: bluetoothBackendInstance
            onDismissRequested: dashboardLoader.active = false
            onTabSelected: (index) => root.dashboardTabIndex = index
            // 15-07 — the ONLY place panelRequested becomes a summon. No
            // guard, no loader lookup here: openPanel() below owns both,
            // exactly once (Flagged Assumption 2's resolution).
            onPanelRequested: (name) => root.openPanel(name)
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
        // Widened by Phase 18 Plan 05's bar always-on charge — see the
        // named comment block beside audioTruthNeeded below for the full
        // reasoning; the same charge applies here.
        drawerOpen: dashboardLoader.active || barInstance.requiresMedia
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
        // Widened by Phase 18 Plan 05's bar always-on charge — see the
        // named comment block beside audioTruthNeeded below for the full
        // reasoning; the same charge applies here.
        drawerOpen: dashboardLoader.active || barInstance.requiresResources
    }

    // ── QML bar (Phase 18 Plan 01 tracer, QBAR-01; wired up in full by
    //    Plan 05, QBAR-02) ────────────────────────────────────────────────
    // Mounted unconditionally, a direct ShellRoot child and sibling of the
    // backend instances above — deliberately the FIRST surface in this
    // file NOT behind a LazyLoader, NOT behind a GlobalShortcut, and NOT
    // behind an IpcHandler, with no `active` property at all. Every prior
    // surface here follows a summon-on-demand shape; this is the phase's
    // named inversion of that shape (Bar.qml's own header comment repeats
    // the same reasoning). The bar's visibility control arrives in 18-15
    // as a `bar` IPC handler, not as a loader toggle.
    //
    // The five backend handles are bound in once here — the same
    // mount-backends-at-the-root-once shape this file's own comment above
    // (MediaBackend/WeatherBackend/SystemResources) already established —
    // so wave 3 (18-08..18-11) inherits live backend access without any
    // of them touching this file. onPanelRequested routes through the
    // single guarded summon path (openPanel(), reused verbatim, never
    // reimplemented); onDashboardRequested mirrors the dashboard's own
    // existing summon shape (set the tab index, then activate the loader).
    Bar {
        id: barInstance
        audioBackend: audioBackendInstance
        mediaBackend: mediaBackendInstance
        systemResources: systemResourcesInstance
        wifiBackend: wifiBackendInstance
        bluetoothBackend: bluetoothBackendInstance
        // Phase 18 Plan 15 (QBAR-07) — a binding, never an external write.
        // The same shape the backend gate properties above already use.
        visibilityState: root.barVisibilityState
        // Phase 18 Plan 16 (QBAR-08) — the whole composition. BarReveal is
        // a pure function of live pointer/modifier state; 18-15 already
        // folded revealOverride into barRendered and excluded it from
        // zoneReserved, so nothing in Bar.qml itself changes to make
        // reveal work. See BarReveal.qml's own header for the full
        // ownership statement.
        revealOverride: BarReveal.revealActive
        onPanelRequested: (name) => root.openPanel(name)
        onDashboardRequested: (tabIndex) => {
            root.dashboardTabIndex = tabIndex;
            dashboardLoader.active = true;
        }
    }

    // ── Hot zone (Phase 18 Plan 16, QBAR-08) — mounted behind a loader
    //    keyed on the INVERSE of the owner's base visible state: present
    //    in EITHER hidden state, absent whenever the owner says visible.
    //    Deliberately bound to hidden-ness rather than to which driver
    //    caused it — the shell holds one state string, not a driver, and
    //    binding to a driver would invent a coupling 18-15 does not offer.
    //    In the idle-hidden state the strip is provably unreachable: the
    //    pointer movement that would reach it clears the idle intent first
    //    through hypridle's own on-resume listener — so the arming here is
    //    correct but the reachable function is the hard-hidden state.
    LazyLoader {
        id: hotZoneLoader
        active: root.barVisibilityState !== "visible"

        HotZone {}
    }

    // ── D-18-19's latch driver (Phase 18 Plan 16, Task 3) — the OTHER
    //    half of the seam Task 1's revealOverride binding above completes:
    //    a binding, never a pair of edge handlers, so a transition that
    //    completes instantly under disabled motion cannot be missed the
    //    way an edge handler registered a frame late could. 18-15 declared
    //    both operands and deliberately shipped no writer of its own so
    //    ownership of the popout singleton's settle latch would land here,
    //    and here only — completing the three-plan chain 18-13 started.
    Binding {
        target: PopoutController
        property: "barSettled"
        value: barInstance.barRendered && !barInstance.barTransitionRunning
    }

    // ── Audio panel (Phase 15 Plan 02 tracer, PANEL-02/PANEL-06) ─────────
    // Same summon-via-LazyLoader mechanism as the dashboard drawer above.
    // `AudioBackend`'s `panelOpen` gate is bound to this loader's own
    // `active`, so the backend's `PwObjectTracker` — and therefore all
    // PipeWire polling — tracks zero nodes while the panel is dismissed.
    LazyLoader {
        id: audioPanelLoader
        active: false

        AudioPanel {
            backend: audioBackendInstance
            onDismissRequested: audioPanelLoader.active = false
        }
    }

    // 15-07 Task 1, branch B taken — measured live: with the drawer open
    // and the audio panel closed, AudioBackend's PwObjectTracker (gated on
    // `panelOpen` alone) tracks zero nodes, so `defaultSink.audio` stays
    // null and the Volume tile's `masterMuted` read is frozen at its
    // `false` fallback regardless of the real sink state — `wpctl
    // set-mute @DEFAULT_AUDIO_SINK@ toggle` from a terminal did not move
    // the tile. `audioTruthNeeded` widens the gate to "some summoned
    // surface is reading live audio truth" — the drawer's Volume tile is
    // the second such surface, alongside the audio panel itself. The wifi
    // and bluetooth backends' gates are left untouched (see AudioBackend.qml
    // vs WifiBackend.qml/BluetoothBackend.qml): those two already expose
    // their enable-state as plain, ungated bindings onto their service
    // singletons, and widening THEIR gates would start the scanner/
    // discovery whenever the drawer is open, which D-15-15/D-15-18 forbid.
    // This does not edit AudioBackend.qml itself — 15-02/15-04 own that
    // file outright; it only changes which loaders feed its own gate.
    // ── Phase 18 Plan 05 — the bar's permanent always-on charge ──────────
    // This is where the shell's backend gates first widen to
    // permanently-live: the always-on bar now keeps audio, media and
    // system-resources truth live for the whole session, not merely while
    // a summoned surface is open. The widening condition is derived from
    // the one entry list (BarEntryModel.requiresAudio/requiresMedia/
    // requiresResources, re-exported through barInstance) rather than
    // hand-set per backend, so the charge is enumerable and re-narrowable
    // from a single place. 18-BAR-IDLE-BASELINE.md is the pre-widening
    // reading and 18-18's soak diffs against it, so this is a named
    // charge against QBAR-11, not an unexplained creep.
    //
    // WifiBackend and BluetoothBackend are deliberately left untouched:
    // their gates start scanning and discovery, which D-15-15/D-15-18
    // forbid running always-on (see this file's own comment block above,
    // beside audioTruthNeeded's original declaration) — the bar reads
    // only those two backends' ungated connection-state bindings.
    readonly property bool audioTruthNeeded: dashboardLoader.active || audioPanelLoader.active || barInstance.requiresAudio

    AudioBackend {
        id: audioBackendInstance
        panelOpen: root.audioTruthNeeded
    }

    // ── Wifi panel (Phase 15 Plan 03, PANEL-03/PANEL-06) ─────────────────
    // Same summon-via-LazyLoader mechanism as the audio panel above.
    // `WifiBackend`'s `panelOpen` gate is bound to this loader's own
    // `active` — 15-05's scanner inherits the same zero-idle-on-dismiss
    // gate without shell.qml needing to change again.
    LazyLoader {
        id: wifiPanelLoader
        active: false

        WifiPanel {
            backend: wifiBackendInstance
            onDismissRequested: wifiPanelLoader.active = false
        }
    }

    WifiBackend {
        id: wifiBackendInstance
        panelOpen: wifiPanelLoader.active
    }

    // ── Bluetooth panel (Phase 15 Plan 03, PANEL-04/PANEL-06) ────────────
    // Same summon-via-LazyLoader mechanism as the wifi panel above.
    // `BluetoothBackend`'s `panelOpen` gate is bound to this loader's own
    // `active` — 15-06's discovery inherits the same zero-idle-on-dismiss
    // gate without shell.qml needing to change again. With this the third
    // and final namespace this phase adds is complete.
    LazyLoader {
        id: bluetoothPanelLoader
        active: false

        BluetoothPanel {
            backend: bluetoothBackendInstance
            onDismissRequested: bluetoothPanelLoader.active = false
        }
    }

    BluetoothBackend {
        id: bluetoothBackendInstance
        panelOpen: bluetoothPanelLoader.active
    }

    // ── Workspace overview (Phase 16 Plan 02, the phase's tracer,
    //    OVER-01/OVER-02) ────────────────────────────────────────────────
    // Same summon-via-LazyLoader mechanism as the panels above — a
    // full-screen surface this time, so there is no backend to gate: the
    // ScreencopyView instances inside Overview.qml's tile are destroyed
    // with the wl_surface itself on every dismissal path (D-14/D-32/D-36
    // zero-idle doctrine), the same guarantee the panels get from backend
    // gating by a different mechanism.
    LazyLoader {
        id: overviewLoader
        active: false

        Overview {
            onDismissRequested: overviewLoader.active = false
        }
    }

    // D-16-19: the overview is deliberately exempt from the
    // `fullscreenBlocking` guard every other summonable surface here
    // respects. The drawer and panels are informational/control surfaces
    // where popping over a game is an interruption; the overview is a
    // navigation surface, and navigation is what is needed most while
    // trapped in a fullscreen app — `Super+2` already works while
    // fullscreen, so refusing `Super+O` while allowing it would block the
    // escape hatch while leaving the fire exit open.
    function toggleOverview() {
        overviewLoader.active = !overviewLoader.active;
    }

    // D-16-23 check 6's capture-check verb — the same `IpcHandler` pattern
    // as `panelIpc` below (one handler, one target, functions only), so a
    // blank grid is machine-detectable rather than dependent on someone
    // noticing.
    IpcHandler {
        id: overviewIpc
        target: "overview"

        // Mirrors panelIpc.open()'s before/after read shape: a plain
        // property read before and after the guarded toggle, never a
        // direct write to overviewLoader.active from in here.
        function toggle(): string {
            var wasActive = overviewLoader.active;
            root.toggleOverview();
            return (overviewLoader.active !== wasActive) ? "overview" : "";
        }

        function status(): string {
            if (!overviewLoader.active || !overviewLoader.item)
                return "active=false tiles=0 windows=0 withContent=0";
            var ov = overviewLoader.item;
            return "active=true tiles=" + ov.tileCount + " windows=" + ov.thumbnailCount + " withContent=" + ov.thumbnailsWithContent;
        }
    }

    // ── Panel family — the single guarded summon path (PANEL-06, binding
    //    correction over 15-PATTERNS.md's own wrong inline snippet: the
    //    DASH-08 guard lives inside `openPanel(name)` and nowhere else, so
    //    every summon path — this plan's Super+A, 15-07's tile chevron,
    //    15-08's retired-bar IPC call — shares the one guard.) ───────────
    function closeAllPanels() {
        audioPanelLoader.active = false;
        wifiPanelLoader.active = false;
        bluetoothPanelLoader.active = false;
    }

    // Name-to-loader resolution, shared by openPanel() below and the
    // shell-root IPC surface's toggle() verb (Phase 15 Plan 03, Task 1) —
    // one mapping, two callers, rather than a second switch duplicated
    // inside the handler. An unrecognised name resolves to null.
    function panelLoaderFor(name) {
        if (name === "audio")
            return audioPanelLoader;
        if (name === "wifi")
            return wifiPanelLoader;
        if (name === "bluetooth")
            return bluetoothPanelLoader;
        return null;
    }

    function openPanel(name) {
        var targetLoader = root.panelLoaderFor(name);
        // An unrecognised name resolves to null and does nothing at all.
        if (!targetLoader)
            return;

        // An already-open panel always closes, whatever is fullscreen
        // behind it — the refusal guard must never trap a summoned panel,
        // mirroring dashboardShortcut's own existing rule.
        if (targetLoader.active) {
            root.closeAllPanels();
            return;
        }
        // Otherwise, refuse entirely over a fullscreen/maximized client —
        // no notification, no sound, no visible acknowledgement (DASH-08's
        // whole point).
        if (root.fullscreenBlocking)
            return;

        root.closeAllPanels();
        targetLoader.active = true;
    }

    // ── DASH-08 fullscreen refusal guard (D-11, Phase 14 Plan 01) ───────
    // LIVE FINDING, not an assumption (three independent proofs this
    // session on Hyprland 0.56.1): "maximize" (hl.dsp.window.fullscreen(1))
    // and "true fullscreen" (hl.dsp.window.fullscreen(0)) are
    // INDISTINGUISHABLE on this build. Both report
    // fullscreen:2/fullscreenClient:2 in hyprctl -j clients/activewindow;
    // both clear `hyprctl -j monitors`' reserved array to [0,0,0,0]; both
    // emit a byte-identical socket2 IPC event sequence naming the retired
    // bar's own layer (captured live via a raw socket read, not read from
    // documentation — the exact quoted event strings are recorded in
    // 18-20-SUMMARY.md's scrubbed-history section). Reproduced across
    // three separate windows (a tiled Zen window, a tiled kitty window,
    // and a genuinely floating kitty window) — not a fluke of one client.
    //
    // Consequence: D-11's literal "maximized windows (bar visible) do not
    // block" carve-out is NOT implementable on this build — Hyprland
    // exposes no signal anywhere in its IPC surface to discriminate the
    // two states, so this guard blocks on the only value Hyprland ever
    // reports for either state (2). This is, ironically, the MOST faithful
    // reading of D-11's own stated rationale ("matches the retired bar's
    // existing fullscreen-withdraw behavior") — that existing behavior,
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

    // ══════════════════════════════════════════════════════════════════
    // Bar visibility conversation (Phase 18 Plan 15, QBAR-07) — the
    // shell's entire half of the single-owner claim. The on-disk
    // bar-visibility.sh script alone decides; everything below only
    // reflects that decision (the `bar` IpcHandler) or reports one fact
    // the owner cannot observe on its own (fullscreen intent, via the
    // reporter). Nothing here originates a hide/show decision.
    // ══════════════════════════════════════════════════════════════════

    property string barVisibilityState: "visible"

    // The ONLY writer of barVisibilityState in the entire shell — its
    // only callers are the three write verbs on barIpc below. Nothing on
    // the bar itself (no hover, no focus event, no timer, no popout) may
    // call this function, because the moment a second writer exists the
    // single-owner claim is false. An unknown value is refused and logged
    // to the console, leaving the current state standing rather than
    // falling through toward a hidden default.
    function setBarVisibility(next) {
        if (next !== "visible" && next !== "hidden-idle" && next !== "hidden-hard") {
            console.warn("setBarVisibility: refusing unknown state '" + next + "'");
            return;
        }
        root.barVisibilityState = next;
        console.log("bar: visibility=" + next + " zone=" + (next === "hidden-hard" ? "released" : "reserved"));
    }

    // ── The `bar` IPC target — three fixed no-argument write verbs
    //    (deliberately narrower than one verb parsing a state name, so
    //    there is no parseable input on this channel at all) plus one
    //    read-only status verb. `status()` exists so the owner's own
    //    `status` verb and this property can be compared directly — the
    //    two must always print the same string, and that equality IS how
    //    single ownership is proven rather than asserted. ───────────────
    IpcHandler {
        id: barIpc
        target: "bar"

        function show(): string {
            root.setBarVisibility("visible");
            return root.barVisibilityState;
        }
        function hideIdle(): string {
            root.setBarVisibility("hidden-idle");
            return root.barVisibilityState;
        }
        function hideHard(): string {
            root.setBarVisibility("hidden-hard");
            return root.barVisibilityState;
        }
        function status(): string {
            return root.barVisibilityState;
        }
    }

    // ── Fullscreen intent reporter (D-18-28) — replaces the retired
    //    standalone fullscreen-watcher socket2 listener script. Reports
    //    on the CHANGE of the already-derived `fullscreenBlocking` value
    //    above rather than inside the Hyprland Connections block's own
    //    onRawEvent handler — that block's refresh is asynchronous and
    //    the value is not yet current at the instant the raw event
    //    arrives; that existing block is left exactly as it is, since it
    //    is what makes the value current in the first place. Inherits the
    //    same maximize-versus-fullscreen ambiguity already recorded above
    //    `fullscreenBlocking` — the retired watcher had it too, and this
    //    plan does not introduce it. While the shell is down nothing
    //    reports fullscreen at all, which is exactly why the startup
    //    resync below exists. Two fixed-argv Process objects, deliberately
    //    never one object with a mutated command, so no element of either
    //    argv is ever computed. ─────────────────────────────────────────
    Process {
        id: fullscreenHideProcess
        command: [root.homeDir + "/.config/hypr/scripts/bar-visibility.sh", "fullscreen", "hide"]
    }
    Process {
        id: fullscreenShowProcess
        command: [root.homeDir + "/.config/hypr/scripts/bar-visibility.sh", "fullscreen", "show"]
    }
    function reportFullscreenIntent() {
        if (root.fullscreenBlocking)
            fullscreenHideProcess.startDetached();
        else
            fullscreenShowProcess.startDetached();
    }
    onFullscreenBlockingChanged: root.reportFullscreenIntent()

    // ── Startup resync — a shell restart cannot leave the bar stranded
    //    with a stale intent from a crash. Declares fullscreen intent
    //    FIRST, then forces a reassert through a single non-repeating
    //    one-shot below (Component.onCompleted): a `fullscreen=hide`
    //    intent that outlived a crash would otherwise still be on disk,
    //    and a reassert reading it first would hide a bar with no
    //    fullscreen window on screen. The quarter second exists solely so
    //    the detached intent write above lands before the forced read
    //    below. This Timer is explicitly exempt from the phase's
    //    zero-idle discipline because it does not repeat — it fires once
    //    per shell start and is inert forever after, which is not the
    //    recurring cost that discipline polices. ──────────────────────
    Process {
        id: reassertProcess
        command: [root.homeDir + "/.config/hypr/scripts/bar-visibility.sh", "reassert"]
    }
    Timer {
        id: startupReassertTimer
        interval: 250
        repeat: false
        running: false
        onTriggered: reassertProcess.startDetached()
    }
    Component.onCompleted: {
        // Order is load-bearing — see the comment above.
        root.reportFullscreenIntent();
        startupReassertTimer.running = true;
    }

    // ── Shell-root IPC surface (Phase 15 Plan 03, Task 1) — the seam every
    //    entry point that is not Super+A reaches a panel through. Both
    //    verbs route their summon half through `openPanel()` above, so the
    //    fullscreen refusal guard it owns is read in exactly one place;
    //    neither verb reads that guard itself and neither writes a
    //    loader's `active` property directly — `toggle()`'s close branch
    //    defers to `closeAllPanels()`, the very function `openPanel()`'s
    //    own already-open branch already calls. Neither return value is
    //    ever surfaced as on-screen feedback — the refusal stays silent by
    //    design.
    IpcHandler {
        id: panelIpc
        target: "panel"

        // Resolves the name, calls the guarded summon function above, and
        // reports whether the panel's active state actually changed.
        // Reading `targetLoader.active` before and after is a plain
        // property read, never a direct write.
        function open(name: string): string {
            var targetLoader = root.panelLoaderFor(name);
            if (!targetLoader)
                return "";
            var wasActive = targetLoader.active;
            root.openPanel(name);
            return (targetLoader.active !== wasActive) ? name : "";
        }

        // An already-open panel closes via `closeAllPanels()` rather than
        // a direct `active` write here. Otherwise defers to `open()`
        // above. Closing is deliberately ungated (D-11's own comment on
        // this file), matching `dashboardShortcut`'s and
        // `audioPanelShortcut`'s own close behaviour.
        function toggle(name: string): string {
            var targetLoader = root.panelLoaderFor(name);
            if (!targetLoader)
                return "";
            if (targetLoader.active) {
                root.closeAllPanels();
                return name;
            }
            return panelIpc.open(name);
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

    // D-15-04 — the keybind asymmetry, one documented sentence: Super+A is
    // the only panel keybind: of the three panels only the audio mixer
    // displaces a daily-opened application (pavucontrol), the free
    // plain-Super single letters on this host are A, G, H, J, K, M, O and
    // U — W, B and V are all taken among 67 mainMod binds — so D-09's
    // first-letter mnemonic convention can be honoured for exactly one of
    // the three, and minting Super+Shift+W/Super+Shift+B for the other two
    // would give three sibling panels built from one shared component
    // visibly inconsistent chord shapes.
    GlobalShortcut {
        id: audioPanelShortcut
        appid: "quickshell"
        name: "audio-panel"
        // Calls openPanel() and never touches audioPanelLoader.active
        // directly — the DASH-08 guard lives inside openPanel() exactly
        // once (binding correction over 15-PATTERNS.md).
        onPressed: root.openPanel("audio")
    }

    // D-16-18: `Super+O` sits beside `Super+D` (Dashboard) and `Super+A`
    // (Audio), honouring D-09's first-letter mnemonic. `O` is confirmed
    // free among this host's remaining plain-Super letters. Calls
    // toggleOverview() directly (not openPanel()) — the overview is not a
    // member of the guarded panel family and, per D-16-19, deliberately
    // consults no fullscreen guard at all.
    GlobalShortcut {
        id: overviewShortcut
        appid: "quickshell"
        name: "overview"
        onPressed: root.toggleOverview()
    }

    // ── Held-Super reveal (Phase 18 Plan 16, QBAR-08) — SHIPPED. ─────────
    // The sole writer of BarReveal.superHeld. 18-16 drafted this block and
    // reverted it: keybind-doctor's chord-collision check compared
    // (modmask, key) WITHOUT the release flag, so the press bind below and
    // the pre-existing Super-tap RELEASE bind read as one chord claimed
    // twice. That was a checker limitation, not a real conflict — the same
    // script's shadow check has always distinguished binds by
    // (modmask, key, keycode, release). The collision check now compares
    // the edge too, and `shortcuts.json`'s bar-reveal entry declares
    // `"release": false` to claim the press edge explicitly, so the two
    // binds are different tuples on both sides of the cross-check.
    //
    // Both edges genuinely exist on the QML side: the installed Hyprland
    // GlobalShortcut type declares `pressed`/`released` signals (read from
    // its own qmltypes, not assumed), correcting RESEARCH.md's Open
    // Question 2 — that scan was incomplete, not wrong about the risk.
    //
    // setSuperHeld() rather than a direct property write, so BarReveal
    // keeps exactly one write site for superHeld no matter how many edges
    // call in. The hover half (HotZone.qml) reports through
    // BarReveal.reportHover() on the same principle and is untouched here;
    // BarReveal composes the two into revealCondition itself.
    GlobalShortcut {
        id: barRevealShortcut
        appid: "quickshell"
        name: "bar-reveal"
        onPressed: BarReveal.setSuperHeld(true)
        onReleased: BarReveal.setSuperHeld(false)
    }
}
