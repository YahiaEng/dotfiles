//@ pragma UseQApplication
// FIX (quick task 260823-65s, Task 3 operator feedback) — required so
// TrayCapsule.qml/TrayPopout.qml's right-click display() can render a
// platform (DBusMenu) menu at all. Measured: right-clicking a tray item
// produced six repetitions in ~/.cache/quickshell.log of "Cannot display
// PlatformMenuEntry as quickshell was not started in QApplication mode" —
// proof the MouseArea and display() call were already correct; only the
// application class was wrong. This pragma is SHELL-WIDE, not tray-local:
// it switches Quickshell's underlying Qt application class for every
// surface this root owns (bar, notification server/popups/centre, OSD,
// launcher, dashboard, settings) — re-verify the whole shell, not just
// the tray, every time this line is touched.
//
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
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "modules"
import "modules/dashboard"
import "modules/bar"
import "modules/notifications"
import "modules/toast"
import "modules/centre"
import "modules/osd"
import "modules/session"
import "modules/settings"
import "modules/launcher"

ShellRoot {
    id: root

    // ── Edge bar enable flag (quick task 260823-9ak, Task 4, R2/R3) ─────
    // Read ONCE here — the single resolution point both EdgeBar loaders
    // below AND Launcher.qml's direction branch (Task 6, via a property
    // threaded onto the launcher instance) read, never a second
    // `Prefs.getValue` call re-derived at another call site.
    readonly property bool edgeBarEnabled: Prefs.getValue("edgeBar.enabled")

    // Selected-tab memory (D-14, Phase 14 Plan 03): the dashboard drawer's
    // LazyLoader destroys the surface on dismiss, so this is the only
    // thing that outlives it — Dashboard.qml seeds its pager from this on
    // summon and reports every change back via tabSelected. Session-level
    // memory only (CONTEXT.md's discretion note); never persisted to disk.
    property int dashboardTabIndex: 0

    // Mirrors Dashboard.qml's own `tabIndexMedia` constant (D-15's fixed
    // tab order: Dashboard, Media, Performance, Weather — Media is index
    // 1). That property lives on the Dashboard instance itself, which is
    // unreachable from here before the drawer is first summoned (the
    // LazyLoader below has no `item` until `active` is true) — the same
    // reason MediaPopout.qml's own wayfinding handler already passes a
    // literal `1` with an identical comment rather than a cross-file
    // property reference (modules/bar/MediaPopout.qml:125-128). Declared
    // here, once, so `mediaShortcut` below references this named constant
    // rather than repeating that literal at a second site.
    readonly property int dashboardTabIndexMedia: 1

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

    // ── Notification centre (Phase 19 Plan 06, D-19-14, QNOTIF-06) — the
    //    third top-level frame in this shell, mounted unconditionally like
    //    NotifPopupStack/Toast above rather than behind a LazyLoader: its
    //    own header explains why (history/DND must never depend on this
    //    window's existence). `audioBackend`/`wifiBackend`/
    //    `bluetoothBackend` are threaded in exactly as Dashboard's own
    //    instantiation below does, so its footer's shared toggle grid
    //    (Task 3) can relay them into ToggleState the same way
    //    QuickToggles.qml's drawer instance already does — a second
    //    instantiation re-asserting the identical object reference, by
    //    that file's own design, never a second source.
    NotifCentre {
        id: notifCentreInstance
        audioBackend: audioBackendInstance
        wifiBackend: wifiBackendInstance
        bluetoothBackend: bluetoothBackendInstance
        // Quick task 260819-6oy — the News tab's feed-fetcher seam.
        newsBackend: newsBackendInstance
        // GATE-02 round 11 — terminus of the centre's chevron relay, the
        // same `openPanel(name)` the dashboard's own identical grid
        // already terminates on (line ~270). openPanel owns the guard and
        // the loader lookup exactly once; nothing is duplicated here.
        onPanelRequested: name => root.openPanel(name)
    }

    // ── Notification suppression fullscreen input (Phase 19 Plan 05,
    //    QNOTIF-10) — a `Binding`, never an imperative write, mirroring
    //    this file's own `PopoutController.barSettled` binding below.
    //    `fullscreenBlocking` (declared further down this file) is the
    //    single existing owner of "is a fullscreen client focused"
    //    (RESEARCH.md Pattern 6) — NotifServer.qml deliberately recomputes
    //    nothing of its own; it only receives this value.
    Binding {
        target: NotifServer
        property: "fullscreenBlocking"
        value: root.fullscreenBlocking
    }

    // ── Do-not-disturb toast (Phase 19 Plan 05, Task 3, D-19-36) — one
    //    always-mounted Toast instance (the surface exists for the
    //    process lifetime, matching NotifPopupStack's own always-on
    //    posture; it stays invisible until `show()` is called). The
    //    icon glyph and the two copy strings are local shell.qml state,
    //    bound reactively into the toast's own static content below —
    //    this is what makes `Toast.qml` itself carry zero do-not-disturb
    //    strings (its own header explains why) while still supplying
    //    genuinely reactive content per this file's own single instance.
    property string dndToastGlyph: "do_not_disturb_on"
    property string dndToastHeading: ""
    property string dndToastBody: ""

    Toast {
        id: dndToast

        Text {
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.iconSizeMd
            text: root.dndToastGlyph
            color: BarRoles.notifSurfaceFg
        }
        Column {
            spacing: Design.spacingXs
            Text {
                text: root.dndToastHeading
                font.pixelSize: Design.fontBody
                font.weight: Design.weightEmphasis
                color: BarRoles.notifSurfaceFg
            }
            Text {
                text: root.dndToastBody
                font.pixelSize: Design.fontLabel
                color: BarRoles.notifSurfaceFg
            }
        }
    }

    Connections {
        target: NotifServer
        function onDndToggled(newValue, heading, body) {
            root.dndToastGlyph = newValue ? "do_not_disturb_on" : "do_not_disturb_off";
            root.dndToastHeading = heading;
            root.dndToastBody = body;
            dndToast.show();
        }
    }

    // ── OSD indicators (Phase 20 Plan 04 tracer, QOSD-01/QOSD-03) — a
    //    second `Toast` instance (D-20-02/D-20-04), always-mounted like
    //    the DND toast above rather than behind a LazyLoader: the OSD must
    //    react to a volume/brightness/caps-lock change at any moment for
    //    the whole session, not only while some other surface is open.
    //    `audioBackend` is threaded in exactly as `Bar`/`Dashboard` below
    //    already do — Osd.qml never mounts its own AudioBackend.
    Osd {
        id: osdInstance
        audioBackend: audioBackendInstance
        // D-20-31 (Phase 20 Plan 07) — the OSD's own cross-surface
        // suppression gate, bound to the power menu's LazyLoader `active`
        // rather than a second, independently-tracked "is the menu open"
        // flag. See Osd.qml's own header for the full reasoning, including
        // why the notification centre does NOT get the same treatment.
        powerMenuOpen: powerMenuLoader.active
    }

    // ── Brightness IPC surface (Phase 20 Plan 05, QOSD-01/QOSD-04 — Rule 2
    //    deviation, missing critical functionality, see 20-05-SUMMARY.md).
    //    `.planning/todos/pending/2026-08-15-brightness-osd-unverifiable-
    //    on-desktop.md`'s option (a): route the WRITE through
    //    `BrightnessBackend` so the backend itself remains the OSD
    //    trigger's sole emitter (D-20-05's "trigger is backend state,
    //    never the keybind" stays literally true), rather than option
    //    (b) (poll while visible) — chosen because this repo already has
    //    a proven, zero-new-process actuation path for exactly this shape
    //    (`bar-visibility.sh`'s own `qs ipc call bar <verb>` precedent,
    //    itself run from a Hyprland keybind's `exec_cmd`), so no new
    //    mechanism is introduced, only a second target on the SAME
    //    mechanism. `BrightnessBackend.adjust(steps)` already applies
    //    `Design.barScrollStepPercent` (5) internally — the identical
    //    step size the raw `brightnessctl ... set 5%+/-` exec it replaces
    //    used, so this is a trigger-path fix, not a behaviour change.
    //    `raise`/`lower` (not `show`/anything CLI11 could collide with —
    //    T-18-17's own finding) return a string for a bounded caller to
    //    log, mirroring `overviewIpc.toggle()`'s own shape below. ───────
    IpcHandler {
        id: osdIpc
        target: "osd"

        function raise(): string {
            BrightnessBackend.adjust(1);
            return "raised";
        }
        function lower(): string {
            BrightnessBackend.adjust(-1);
            return "lowered";
        }
    }

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

        // ── Centre toggle verb (Phase 19 Plan 06, D-19-16) — extends this
        //    SAME "notifs" target rather than minting a second one, per
        //    RESEARCH.md's own "IPC handler shape" example, which already
        //    reserved this target for exactly this verb. Calls
        //    notifCentreInstance's own toggle() directly (below, same
        //    file) rather than re-deriving its open/close logic here —
        //    this IPC verb and the GlobalShortcut below share that one
        //    implementation. The bell in ClockActionsCapsule.qml cannot
        //    reach this window instance (a different file, mounted inside
        //    Bar.qml) and instead calls NotifServer's own public verbs
        //    directly — the same two calls toggle()'s own body makes,
        //    just inlined at that one cross-file call site. ──────────────
        function toggleCentre(): string {
            notifCentreInstance.toggle();
            return NotifServer.centreOpen ? "open" : "closed";
        }
    }

    // ── Prefs IPC surface (quick-260821-6z1 Task 1, D-02) — mirrors the
    //    `notifs` target's own shape immediately above: a mechanical,
    //    screenshot-free way to drive `Prefs.getValue`/`Prefs.setValue`
    //    directly — the SAME functions a settings row's own handler calls,
    //    not a synthetic stand-in for them. Also a genuinely useful
    //    scripting surface on its own, consistent with this repo's
    //    "write configs humans will edit" convention. `set()` coerces its
    //    string argument to bool/number/string, since IPC callers (a shell
    //    script, `qs ipc call`) can only ever pass strings — a settings
    //    row calls `Prefs.setValue()` directly with an already-typed
    //    value and does not go through this coercion at all. ────────────
    IpcHandler {
        id: prefsIpc
        target: "prefs"

        // Fix (verifier's low-severity finding, quick-260821-6z1 fix
        // wave): an unannotated return type made QML's own qmltc/qmlsc
        // treat every call site as needing a runtime coercion to `void`,
        // logging an `ERROR`-level "should be coerced to void because the
        // function called is insufficiently annotated" line on every
        // `qs ipc call prefs set ...` — pure log noise (the return value
        // was still used correctly), but this project debugs through that
        // exact log channel. `_coerce` genuinely returns bool, number, OR
        // string depending on its input, so `var` is the correct
        // annotation — not `bool`/`real`/`string` alone.
        function _coerce(s: string): var {
            if (s === "true")
                return true;
            if (s === "false")
                return false;
            if (/^-?\d+$/.test(s))
                return parseInt(s, 10);
            if (/^-?\d*\.\d+$/.test(s))
                return parseFloat(s);
            return s;
        }

        function get(key: string): string {
            return String(Prefs.getValue(key));
        }

        function set(key: string, value: string): bool {
            return Prefs.setValue(key, prefsIpc._coerce(value));
        }

        function keys(): string {
            return Prefs.listKeys();
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

    // ── News backend (quick task 260819-6oy) — the notification centre's
    //    News-tab feed fetcher. Mounted here, a sibling of WeatherBackend
    //    above, despite its only consumer being NotifCentre's own News tab
    //    (modules/centre/NewsPane.qml) — modules/dashboard/ is the repo's
    //    backend home regardless of consumer (AudioBackend's own
    //    precedent). Gated on NotifServer.centreOpen (D-32) rather than
    //    dashboardLoader.active: zero network while the centre is closed.
    //    Do NOT add `newsBackend: newsBackendInstance` to the NotifCentre
    //    block below yet — that property does not exist until this quick
    //    task's Task 4 lands it.
    NewsBackend {
        id: newsBackendInstance
        centreOpen: NotifServer.centreOpen
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
        // Phase 20 Plan 06 Task 2 (QPOWER-01/D-20-22) — the bar's
        // `powerCell` relays through PopoutController -> Bar.qml's third
        // summon seam (see both files' own comments) to reach this one
        // verb, the same `togglePowerMenu()` the keybind and the QML menu
        // already call.
        onPowerMenuRequested: root.togglePowerMenu()
        // Operator request (2026-08-21): the bar's settings glyph reaches
        // the same `openSettings()` verb Super+comma and the QML menu
        // already call — never a second summon path.
        onSettingsRequested: root.openSettings()
    }

    // ── Edge bar (quick task 260823-9ak, Task 3+4, R1/R2/R3/R4/D-2) — two
    //    always-on strips, top and bottom. Gated on `root.edgeBarEnabled`
    //    via a LazyLoader, PER INSTANCE (not a shared wrapper Item) so
    //    EACH strip's own wl_surface is destroyed when disabled — R3
    //    demands OFF unmount entirely (a mounted-but-`visible:false`
    //    layer surface keeps its `exclusiveZone`, which would silently
    //    fail R3's "exactly today's behaviour" requirement). Otherwise
    //    the same permanent-while-on posture `barInstance` above and the
    //    notification popup stack already use — never behind a loader
    //    keyed on anything transient.
    LazyLoader {
        id: edgeBarTopLoader
        active: root.edgeBarEnabled

        EdgeBar {
            id: edgeBarTop
            bottom: false
        }
    }
    LazyLoader {
        id: edgeBarBottomLoader
        active: root.edgeBarEnabled

        EdgeBar {
            id: edgeBarBottom
            bottom: true
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
    //
    // ── Phase 19 Plan 06 widening — the centre's own volume/mic sliders ──
    // NotifServer.centreOpen joins the OR-chain for the identical reason
    // dashboardLoader.active already does: CentreFooter's sliders read
    // AudioBackend.masterVolume/inputVolume, which are only live while
    // this gate is true (A6, this file's own PwObjectTracker precedent).
    // Without this, the centre's sliders would show frozen defaults while
    // open — the exact "separate, disagreeing volume state" QNOTIF-08
    // forbids. NotifCentre is never behind a LazyLoader (D-19-14's
    // always-on posture), so `centreOpen` — not a loader's own `active` —
    // is the only signal available here for "is the centre currently
    // showing".
    // ── Phase 20 Plan 04 widening — the OSD's own state-driven trigger ───
    // D-20-05 requires an external `wpctl` call or a bar scroll to raise
    // the IDENTICAL indicator a hardware key does — which is only
    // possible if AudioBackend's PwObjectTracker holds the default sink
    // LIVE for the whole session (A6, this file's own PwObjectTracker
    // precedent above), not merely while some other surface happens to be
    // open. `osdInstance` above is a permanent, always-mounted surface
    // (never behind a LazyLoader, matching the bar's own `requiresAudio`
    // shape), so this term is unconditionally true rather than gated on a
    // loader's `active` the way every other term in this OR-chain is.
    readonly property bool osdNeedsAudioTruth: true

    readonly property bool audioTruthNeeded: dashboardLoader.active || audioPanelLoader.active || barInstance.requiresAudio || NotifServer.centreOpen || root.osdNeedsAudioTruth

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

    // ── Settings → Network page inline wiring (quick-260821-6z1 fix wave,
    //    operator request: "make wifi and bluetooth options open
    //    inline"). NetworkPage.qml is a SECOND consumer of these same
    //    backend instances (never a second WifiBackend/BluetoothBackend —
    //    the AudioPage precedent's own rule), so `panelOpen` must widen
    //    to cover "the settings window is open and showing the Network
    //    page (pageIdx 4, `<page_map>`)" — without this, both backends'
    //    live truth (wifi scanning, bluetooth's device model) stays off
    //    while NetworkPage.qml is the one actually rendering it, and the
    //    inline list would always read empty. Null-guarded: `settingsLoader.item`
    //    does not exist until the loader has actually incubated its
    //    content. ─────────────────────────────────────────────────────────
    // The Network page's index is LOOKED UP by its stable `slug`, never
    // hardcoded. `settings-index-check` guards PageRegistry/PageCompRegistry/
    // RowIndex against index drift, but it cannot see a literal index living
    // over here in shell.qml — a page reorder would silently gate these
    // backends on the wrong page, leaving the inline list empty with no
    // error. Same two-stage slug resolution `openSettingsPage()` uses below
    // (:850). -1 when absent, which no currentPageIdx can equal.
    readonly property int networkPageIdx: {
        for (var i = 0; i < PageRegistry.pages.length; i++) {
            if (PageRegistry.pages[i].slug === "network")
                return i;
        }
        return -1;
    }

    readonly property bool settingsShowingNetwork: settingsLoader.active && settingsLoader.item !== null && settingsLoader.item.sState.currentPageIdx === root.networkPageIdx

    WifiBackend {
        id: wifiBackendInstance
        panelOpen: wifiPanelLoader.active || root.settingsShowingNetwork
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
        // Same widening as WifiBackend above, same reason — discovery
        // itself stays opt-in (BluetoothBackend.qml's own `startDiscovery()`
        // is still the only call site), but the device model and adapter
        // state need to be live while this page is showing it.
        panelOpen: bluetoothPanelLoader.active || root.settingsShowingNetwork
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

    // ── Launcher (quick task 260822-sht — the native QML launcher that
    //    replaced the retired external launcher + backend daemon) ────────
    // Same summon-via-LazyLoader mechanism as the panels/overview above.
    // Stages 1-2 (Tasks 1-9) built this surface alongside the still-live
    // retired launcher, by design (the plan's own ordering constraint —
    // retiring the old surface's binds and process is Task 10, and the
    // rest of the retired tree is deleted in Task 12); that overlap is
    // now fully resolved.
    LazyLoader {
        id: launcherLoader
        active: false

        Launcher {
            // Threaded from the single shell-root resolution point (Task
            // 4/6, D-5) — Launcher.qml has no `root` id of its own to
            // read (a separate document's ids are not visible there).
            edgeBarEnabled: root.edgeBarEnabled
            onDismissRequested: launcherLoader.active = false
        }
    }

    // dashboardShortcut's own toggle-with-fullscreenBlocking-guard shape,
    // reused verbatim: an already-open launcher always closes, a closed
    // one only opens when not fullscreen-blocked.
    GlobalShortcut {
        id: launcherShortcut
        appid: "quickshell"
        name: "launcher"
        onPressed: {
            if (launcherLoader.active) {
                launcherLoader.active = false;
            } else if (!root.fullscreenBlocking) {
                launcherLoader.active = true;
            }
        }
    }

    // ── Launcher IPC (quick task 260822-sht, Task 2) ──────────────────────
    // `panelIpc`'s own shape (functions only, below), reused for the
    // launcher: this handler must live in shell.qml's own permanently-
    // mounted scope rather than inside Launcher.qml itself, because
    // Launcher.qml is destroyed whenever `launcherLoader.active` is false
    // (D-14's zero-idle doctrine) — an IpcHandler declared inside it would
    // cease to exist the moment the surface is closed, and could never
    // SUMMON a closed launcher, only control an already-open one.
    //
    // `open(mode)` sets `LauncherState.pendingMode` BEFORE activating the
    // loader, so `LauncherState.reset()` (called from Launcher.qml's own
    // `Component.onCompleted` on every fresh summon) picks it up and opens
    // directly in that mode rather than always landing on apps mode — the
    // seam Tasks 7-9's menu leaves and Task 8's Super+C repoint use to
    // request a specific starting mode. Reuses `launcherShortcut`'s own
    // fullscreenBlocking guard rather than writing `launcherLoader.active`
    // a second, divergent way.
    IpcHandler {
        id: launcherIpc
        target: "launcher"

        function open(mode: string): string {
            LauncherState.pendingMode = mode && mode.length > 0 ? mode : "";
            if (!launcherLoader.active && !root.fullscreenBlocking)
                launcherLoader.active = true;
            return launcherLoader.active ? "launcher" : "";
        }

        // An already-open launcher closes unconditionally, matching
        // `launcherShortcut`'s own close branch (closing is deliberately
        // ungated, D-11). Otherwise defers to `open()` above.
        function toggle(): string {
            if (launcherLoader.active) {
                launcherLoader.active = false;
                return "";
            }
            return launcherIpc.open("");
        }
    }

    // ── Launcher menu-mode shortcut (quick task 260822-sht, Task 3) ───────
    // Super-tap (`keybinds.lua`'s `SUPER_L` release bind) needs to open the
    // launcher directly into menu mode (D-2's 9 verb-based roots) rather
    // than the default apps mode `launcherShortcut` above opens into. A
    // bare `GlobalShortcut`'s `onPressed` carries no argument, so this
    // cannot reuse `launcherShortcut`'s own name/handler — it is a
    // DISTINCT shortcut name that sets `LauncherState.pendingMode` BEFORE
    // activating the loader, mirroring `launcherShortcut`'s own toggle-
    // with-fullscreenBlocking-guard shape otherwise. Phase 7's
    // launcher/menu split is preserved: Super+Space stays apps-only, this
    // bind stays menu-only, and this rebuild does not collapse them into
    // one entry point.
    GlobalShortcut {
        id: launcherMenuShortcut
        appid: "quickshell"
        name: "launcher-menu"

        // ── Both edges, deliberately (fix: "Super-tap does nothing") ──────
        // This is the ONLY bind in keybinds.lua that uses `release = true`
        // (line 82) — the Super-TAP edge, which D-02 needs so a tap can be
        // told apart from Super held for any other combo. The handler
        // originally implemented `onPressed` alone, so the shortcut fired on
        // an edge nothing was listening for and the tap silently did nothing.
        //
        // The predecessor bind worked because it was a plain `exec_cmd(...)`
        // process spawn of the retired external launcher — no protocol
        // edges involved at all.
        // Routing the same bind through `global` put it on the
        // hyprland-global-shortcuts protocol, where press and release are
        // DISTINCT signals: `bar-reveal` (line ~1429) is bound to this SAME
        // physical chord on the press edge and has always handled both, which
        // is the proof both edges reach a client.
        //
        // Which edge a release-bound `global` dispatch delivers was NOT
        // verifiable from here — reproducing it needs a real Super keypress,
        // and this host has no input-injection tool (wtype misroutes to the
        // focused toplevel). So rather than guess an edge and ship a
        // coin-flip, both are wired to one handler and `_lastToggleMs` makes
        // a double delivery idempotent: if the protocol turns out to send
        // both edges for this bind, the second lands inside the window and is
        // dropped instead of immediately re-closing what the first opened.
        readonly property int _tapDebounceMs: 250
        property real _lastToggleMs: 0

        function _toggleMenu() {
            const now = Date.now();
            if (now - launcherMenuShortcut._lastToggleMs < launcherMenuShortcut._tapDebounceMs)
                return;
            launcherMenuShortcut._lastToggleMs = now;

            if (launcherLoader.active) {
                launcherLoader.active = false;
            } else if (!root.fullscreenBlocking) {
                LauncherState.pendingMode = LauncherState.modeMenu;
                launcherLoader.active = true;
            }
        }

        onPressed: launcherMenuShortcut._toggleMenu()
        onReleased: launcherMenuShortcut._toggleMenu()
    }

    // ── Power menu (Phase 20 Plan 06, the power half's tracer, QPOWER-01)
    // ────────────────────────────────────────────────────────────────────
    // Same summon-via-LazyLoader mechanism as the panels/overview above —
    // the dialog exists only while summoned. Exempt from `fullscreenBlocking`
    // for the same reason the overview is (D-16-19, above): a
    // session-ending action must remain reachable from inside a fullscreen
    // app, arguably more than navigation is — refusing it would trap the
    // user rather than merely inconvenience them.
    LazyLoader {
        id: powerMenuLoader
        active: false

        PowerMenu {
            onDismissRequested: powerMenuLoader.active = false
        }
    }

    // D-20-32 (Phase 20 Plan 07) — opening the menu dismisses live
    // notification popups. All three of this surface's entry points
    // (Super+Shift+Q's GlobalShortcut, the QML menu's dispatch, and the
    // bar's `powerCell`) already converge on THIS one function (see the
    // comments beside each), so gating the dismissal here — on the
    // OPENING transition only, never on close — is the single place both
    // cross-surface effects for this plan fire from, rather than one call
    // per entry point. Nothing is lost: NotifServer.qml's own
    // `dismissAllPopups()` only clears the ON-SCREEN stack; every
    // notification is already recorded into `history` unconditionally on
    // arrival (D-19-07), before this function is ever reachable.
    function togglePowerMenu() {
        var opening = !powerMenuLoader.active;
        powerMenuLoader.active = opening;
        if (opening)
            NotifServer.dismissAllPopups();
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

    // ── Settings window (quick task 260820-sqd, Task 1, D-02/PD-01) ──────
    // A real XDG toplevel (`FloatingWindow`), not a layer surface — the
    // same summon-via-LazyLoader mechanism as every other surface here,
    // but with no `WlrLayershell` namespace to register in
    // quickshell-doctor's QSD_BAR_SURFACE_ROWS (that registry keys on a
    // layer surface's namespace, which a toplevel does not have).
    // `settingsInitialPageIdx` mirrors `dashboardTabIndex`'s own shape
    // above: the ONLY way to seed which page the window opens on, read
    // once at construction via `initialPageIdx` (Settings.qml), never
    // pushed imperatively into an item that may not exist yet the instant
    // the loader activates.
    property int settingsInitialPageIdx: 0

    LazyLoader {
        id: settingsLoader
        active: false

        Settings {
            initialPageIdx: root.settingsInitialPageIdx
            // Task 13 (D-01 bundle 4) — threads the shell's SINGLE
            // AudioBackend instance into the settings window the same way
            // every other consumer below (dashboardLoader, audioPanelLoader,
            // NotifCentre, Osd) already receives it — never a second
            // instance. `audioTruthNeeded`'s own OR-chain already includes
            // `root.osdNeedsAudioTruth`, an unconditional `true` (the OSD's
            // own always-on requirement), so AudioBackend's live PipeWire
            // tracking is ALREADY permanently on — no gate widening needed
            // here, only the relay.
            audioBackend: audioBackendInstance
            // quick-260821-6z1 fix wave (operator: "make wifi and
            // bluetooth options open inline") — same relay shape as
            // audioBackend above, but THESE two backends' `panelOpen`
            // gate DOES widen (see `root.settingsShowingNetwork` beside
            // wifiBackendInstance/bluetoothBackendInstance above) since
            // neither is unconditionally live the way audio is.
            wifiBackend: wifiBackendInstance
            bluetoothBackend: bluetoothBackendInstance
            // Operator live-pass item "opens on last tab" (root-caused
            // live, not assumed): `settingsInitialPageIdx` is a
            // shell-root property that ONLY the `openPage()` deep-link
            // path writes — nothing ever reset it back afterward, so it
            // leaked into every SUBSEQUENT open (even a bare Super+comma
            // press), not just the deep-linked one. Confirmed with a
            // temporary diagnostic: after one `openPage "shell"` call,
            // `initialPageIdx` read back as 3 on every later open. Reset
            // it to 0 on every close, so only an open that IMMEDIATELY
            // follows a fresh `openPage()` call ever starts anywhere but
            // Appearance.
            onCloseRequested: {
                settingsLoader.active = false;
                root.settingsInitialPageIdx = 0;
            }
            // Task 2 (ConnectivityPage) — routes through the SAME guarded
            // summon function every other panel entry point uses
            // (audioPanelShortcut, the drawer's own chevrons); never a
            // direct loader-active write from here.
            onPanelRequested: (name) => root.openPanel(name)
        }
    }

    // The single guarded summon function every entry point below defers
    // to — GlobalShortcut, the `settings` IpcHandler, and the QML menu's
    // Settings leaf (`qs ipc call settings open`, MenuTree.qml). An
    // already-open window ALWAYS closes,
    // whatever is fullscreen behind it (D-02/D-06's "pressing it again
    // closes it"), mirroring `dashboardShortcut`'s own onPressed shape
    // above verbatim.
    function openSettings() {
        if (settingsLoader.active) {
            settingsLoader.active = false;
        } else if (!root.fullscreenBlocking) {
            settingsLoader.active = true;
        }
    }

    // Deep-link to a settings page by name (F-05's foundation, extended by
    // quick-260821-6z1 Task 2's ten-page split, PD-03) — resolves the
    // name via a TWO-STAGE rule (both documented on PageRegistry.qml's own
    // header): exact `slug` match FIRST (the new, precise per-page keys),
    // then `category` first-match-wins by index SECOND (the four legacy
    // keys this function accepted before the split — `appearance`,
    // `connectivity`, `display`, `shell` — which must keep resolving to
    // whichever page is first in `pages[]` carrying that category). Seeds
    // `settingsInitialPageIdx` for a first-open, and pushes directly into
    // the live SettingsState when the window is already open (safe: the
    // item is guaranteed to exist once `active` was already true on a
    // prior frame, unlike the just-activated case above).
    function openSettingsPage(name) {
        var idx = -1;
        for (var i = 0; i < PageRegistry.pages.length; i++) {
            if (PageRegistry.pages[i].slug === name) {
                idx = i;
                break;
            }
        }
        if (idx === -1) {
            for (var j = 0; j < PageRegistry.pages.length; j++) {
                if (PageRegistry.pages[j].category === name) {
                    idx = j;
                    break;
                }
            }
        }
        if (idx === -1)
            return false;
        root.settingsInitialPageIdx = idx;
        if (!settingsLoader.active) {
            if (root.fullscreenBlocking)
                return false;
            settingsLoader.active = true;
        } else if (settingsLoader.item) {
            settingsLoader.item.sState.currentPageIdx = idx;
        }
        return true;
    }

    GlobalShortcut {
        id: settingsShortcut
        appid: "quickshell"
        name: "settings"
        onPressed: root.openSettings()
    }

    // ── Settings IPC surface — `open()`/`toggle()`/`openPage(name)`,
    //    mirroring `panelIpc`'s own shape: every verb defers to the
    //    guarded summon functions above, never writes `settingsLoader.active`
    //    directly. ────────────────────────────────────────────────────────
    IpcHandler {
        id: settingsIpc
        target: "settings"

        function open(): string {
            var wasActive = settingsLoader.active;
            root.openSettings();
            return (settingsLoader.active !== wasActive) ? "settings" : "";
        }

        function toggle(): string {
            return settingsIpc.open();
        }

        function openPage(name: string): string {
            return root.openSettingsPage(name) ? name : "";
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
        //
        // Named `toggle()` (quick task 260823-9ak, Task 5, R5) rather than
        // inlined directly on `onPressed`, mirroring `launcherMenuShortcut`'s
        // own `_toggleMenu()` shape below — so the top edge-bar strip's
        // dwelled-hover signal (EdgeBar.qml's `bulgeHoverTriggered`) can
        // call the SAME code path the keybind runs, never a second,
        // divergent `dashboardLoader.active` write.
        function toggle() {
            if (dashboardLoader.active) {
                dashboardLoader.active = false;
            } else if (!root.fullscreenBlocking) {
                dashboardLoader.active = true;
            }
        }
        onPressed: dashboardShortcut.toggle()
    }

    // ── Edge bar hover reveal (quick task 260823-9ak, Task 5, R5/R6) ─────
    // `Connections.target` re-binds automatically as each LazyLoader's
    // `.item` goes null/non-null across an enable/disable toggle (Task 4),
    // and gracefully no-ops while null — so these two blocks need no
    // `edgeBarEnabled` guard of their own. Top strip reuses
    // `dashboardShortcut`'s own toggle path (R5); bottom strip reuses
    // `launcherMenuShortcut`'s own `_toggleMenu()` verbatim (R6), which
    // already sets `LauncherState.pendingMode = LauncherState.modeMenu`
    // before opening — so the bottom edge opens MENU mode, not apps mode.
    Connections {
        target: edgeBarTopLoader.item
        function onBulgeHoverTriggered() {
            dashboardShortcut.toggle();
        }
    }
    Connections {
        target: edgeBarBottomLoader.item
        function onBulgeHoverTriggered() {
            launcherMenuShortcut._toggleMenu();
        }
    }

    // D-21-12 (Phase 21 Plan 07, QMEDIA-01): restores reachability for the
    // retired standalone media card's own opener (RETIRE-06), which died
    // with the Phase 18 bar retirement (RETIRE-02) and has had no caller since
    // (21-BEHAVIOUR-BASELINE.md D-01). Opens the dashboard DIRECTLY on the
    // Media tab — reuses the existing loader-open path (`dashboardLoader`)
    // and the existing initial-tab-index parameter (`root.dashboardTabIndex`)
    // rather than any new machinery, mirroring `onDashboardRequested`
    // above (the bar's own wayfinding handler for the same summon shape).
    // Toggle-with-fullscreen-guard shape is copied verbatim from
    // `dashboardShortcut` above: D-21-12's own text describes only the
    // open behaviour, not close, so toggle is the consistent choice
    // against its sibling shortcuts rather than a bare "open" — a small
    // resolved call, recorded here rather than left to read as an
    // accident. On open the tab index is forced to Media every time
    // (never left at whatever tab was last open), on an already-open
    // drawer this always closes it, matching `dashboardShortcut`'s own
    // "never trap a summoned drawer" rule (D-11).
    GlobalShortcut {
        id: mediaShortcut
        appid: "quickshell"
        name: "media"
        onPressed: {
            if (dashboardLoader.active) {
                dashboardLoader.active = false;
            } else if (!root.fullscreenBlocking) {
                root.dashboardTabIndex = root.dashboardTabIndexMedia;
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

    // ── Notification centre (Phase 19 Plan 06, D-19-16) — `N` matches the
    //    outgoing daemon's own Super+N chord (keybinds.lua, repointed by
    //    this same plan from an exec_cmd shelling to an external client onto
    //    this GlobalShortcut). No fullscreen refusal guard, matching the
    //    overview's own reasoning above rather than the dashboard's: a
    //    notification is not an interruption a fullscreen game needs
    //    protecting from in the same way a drawer is — it is the surface
    //    that already suppressed itself while fullscreen (QNOTIF-10) — and
    //    an already-open centre must always be closable regardless.
    GlobalShortcut {
        id: notifCentreShortcut
        appid: "quickshell"
        name: "notif-centre"
        onPressed: notifCentreInstance.toggle()
    }

    // ── Power menu (Phase 20 Plan 06, QPOWER-01/D-20-22) — repoints the
    //    retired GTK4 power-menu surface's own Super+Shift+Q chord
    //    (keybinds.lua) onto this GlobalShortcut, that surface
    //    RETIRE-05-deleted (Phase 20 Plan 10). All three consumers this
    //    plan repoints (this bind, the QML menu's power entry, the
    //    bar's `powerCell`) call `root.togglePowerMenu()` above — one
    //    verb, three callers, per D-17's declared-manifest mechanism. ────
    GlobalShortcut {
        id: powerMenuShortcut
        appid: "quickshell"
        name: "power-menu"
        onPressed: root.togglePowerMenu()
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
