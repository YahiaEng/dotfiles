// ToggleState.qml — the sole owner of all six quick-toggle tiles' state
// (Phase 19 Plan 05, D-19-19/QNOTIF-07).
//
// pragma Singleton (below) + qmldir's `singleton` keyword are BOTH
// required for bare `ToggleState.propertyName`-style access to resolve at
// all — the same binary-verified 12-06 finding Colours.qml/Motion.qml/
// Design.qml/NotifServer.qml each restate in their own header. Both are
// present here.
//
// ── Why this file exists (RESEARCH.md Pattern 5) ─────────────────────────
// `QuickToggles.qml` used to OWN this state itself (FileViews, Processes,
// Timers, the D-22 pending model) as an `Item`-rooted component
// instantiated once by the dashboard drawer. Promoting it to a singleton
// is what makes a SECOND instantiation (Plan 19-06's centre footer)
// structurally incapable of drifting from the drawer's own grid: both
// read the SAME property, both call the SAME verb, and there is no
// synchronisation code between them to forget. `QuickToggles.qml` is now
// a pure view — see that file's own header for the reading side of this
// split.
//
// ── Pitfall avoided (RESEARCH.md Pattern 5's own warning, and
//    QuickToggles.qml's OWN prior header comment) ─────────────────────────
// A bare `id`-based lookup across separate registered component types
// (e.g. `dashboardWindow.spacingLg` from inside `QuickToggles.qml`) does
// NOT resolve — only a `pragma Singleton` type resolves that way. This
// file is built directly as that singleton from the start, not as a
// "shared instance passed down via property" that would repeat the
// mistake `QuickToggles.qml`'s own header already recorded once.
//
// ── Backend seams (D-19-19's own text: "delegates its write to the
//    existing per-domain backend it already used; the singleton is the
//    sole owner of the toggle's STATE, not a reimplementation of the
//    domain backends") ────────────────────────────────────────────────────
// `AudioBackend`/`WifiBackend`/`BluetoothBackend` are ordinary (non-
// singleton) types mounted once at shell.qml's root — a singleton cannot
// receive them through the normal instantiation property-passing
// mechanism, so they arrive here as plain settable `property var` handles.
// `QuickToggles.qml` (the ONE place these were already threaded from
// shell.qml -> Dashboard.qml -> DashboardTab.qml before this plan) relays
// its own already-threaded `audioBackend`/`wifiBackend`/`bluetoothBackend`
// properties into this singleton once, at `Component.onCompleted` — this
// reuses the EXISTING threading path rather than adding a second one
// through shell.qml directly, so neither `Dashboard.qml` nor
// `DashboardTab.qml` needed any edit for this plan.
//
// ── DND (D-19-19's own promotion target) ─────────────────────────────────
// DND's truth now comes straight from `NotifServer.dnd` — Plan 19-05's
// own Task 1 server-side work — rather than the retired daemon's client
// subscribe/poll pair `QuickToggles.qml` used to run. Both the read
// (`NotifServer.dnd`) and the write (`NotifServer.toggleDnd()`) go through
// that one singleton, so there is exactly one owner of DND truth in the
// whole shell, not two.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../notifications"

Singleton {
    id: root

    property string homeDir: Quickshell.env("HOME")

    // ── Backend seams (see header) — assigned once by QuickToggles.qml's
    //    own Component.onCompleted, relaying its ALREADY-threaded
    //    properties. Never assigned from anywhere else. ──────────────────
    property var audioBackend: null
    property var wifiBackend: null
    property var bluetoothBackend: null

    // ═══════════════════════════════════════════════════════════════════
    // Backend truth table (D-27, carried over from QuickToggles.qml's own
    // header verbatim — the mapping did not change, only which file owns
    // reading it):
    //
    //   Gaming — exec `gaming-mode-toggle.sh`,
    //            read `cat ~/.cache/gaming-mode 2>/dev/null || echo off`,
    //            lit iff value == "on".
    //   DND    — read `NotifServer.dnd`, write `NotifServer.toggleDnd()`
    //            (D-19-19's own promotion — was an external client, is now the
    //            shell's own persisted server state).
    //   Dark   — `qs ipc call launcher open theme` (quick task 260822-sht,
    //            Task 12 — theme-switch.sh is retired; the native QML
    //            launcher's own Style ▸ Theme picker, PickerMode.qml, is
    //            the sole theme-picker surface now),
    //            read `cat ~/.local/state/theme/mode 2>/dev/null || echo dark`,
    //            lit iff value == "dark".
    // ═══════════════════════════════════════════════════════════════════

    // ── Gaming state reader (bare FileView, Probe.qml's shape) ──────────
    FileView {
        id: gamingFile
        path: root.homeDir + "/.cache/gaming-mode"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string gamingRaw: (gamingFile.text() || "").trim()
    readonly property bool gamingState: (gamingRaw.length > 0 ? gamingRaw : "off") === "on"

    // ── Dark (theme mode) state reader — same shape ─────────────────────
    FileView {
        id: modeFile
        path: root.homeDir + "/.local/state/theme/mode"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string modeRaw: (modeFile.text() || "").trim()
    readonly property bool darkState: (modeRaw.length > 0 ? modeRaw : "dark") === "dark"

    // ── DND state — a direct read of NotifServer's own persisted property.
    //    No subscribe/poll process, no external notification client anywhere in this
    //    file: NotifServer.qml IS the single owner of this fact now. ────
    readonly property bool dndState: NotifServer.dnd

    // ── Truth mirrors (15-07's own shape, carried over verbatim) — Volume/
    //    Wi-Fi/Bluetooth read straight off the threaded-in backends, the
    //    SAME pure-read discipline the file-based tiles above hold: a
    //    press never assigns any of these three. The two fallbacks below
    //    are DELIBERATELY asymmetric, not an oversight: a missing audio
    //    backend falls back to *unmuted* (lit), matching AudioBackend's
    //    own documented `false` mute fallback and the fact that muted is
    //    the exceptional state; a missing wifi or bluetooth backend falls
    //    back to *off* (unlit), because an unlit connectivity tile
    //    understates capability rather than overstating it. ─────────────
    readonly property bool volumeUnmuted: root.audioBackend ? !root.audioBackend.masterMuted : true
    readonly property bool wifiRadioOn: root.wifiBackend ? root.wifiBackend.wifiEnabled : false
    readonly property bool bluetoothAdapterOn: root.bluetoothBackend ? root.bluetoothBackend.adapterEnabled : false

    // ── Unreachable-backend affordance (this plan's own new behaviour) —
    //    a tile whose backend seam is still null (the shell mount itself
    //    broken, per QuickToggles.qml's own prior header framing) renders
    //    disabled with an explanatory tooltip rather than silently
    //    reporting a default value that looks like real truth. Gaming/
    //    DND/Dark have no injected backend to go missing — they read a
    //    file or another singleton, both of which always exist — so only
    //    the three backend-seam tiles can ever be unreachable. ───────────
    function chipReachable(name) {
        switch (name) {
        case "volume": return !!root.audioBackend;
        case "wifi": return !!root.wifiBackend;
        case "bluetooth": return !!root.bluetoothBackend;
        }
        return true;
    }
    function chipUnavailableReason(name) {
        switch (name) {
        case "volume": return "Volume unavailable — this tile's audio backend was not mounted.";
        case "wifi": return "Wi-Fi unavailable — this tile's network backend was not mounted.";
        case "bluetooth": return "Bluetooth unavailable — this tile's Bluetooth backend was not mounted.";
        }
        return "";
    }

    // ═══════════════════════════════════════════════════════════════════
    // The pending model (D-22) — ONE property naming which chip (if any)
    // is currently in flight. The lit state above is read-only and never
    // assigned by a press; this is the whole of what makes drift between
    // two grid VIEWS structurally impossible — there is only ever one of
    // these properties in the whole process, however many QuickToggles
    // instances render it.
    // ═══════════════════════════════════════════════════════════════════
    property string pendingChip: "" // "" | "gaming" | "dnd" | "dark" | "volume" | "wifi" | "bluetooth"

    // Backend watchdog — NOT a motion token, same reasoning QuickToggles.qml's
    // own prior header gave: a timeout riding the motion-scale axis would
    // collapse to zero at `off` and revert a chip before any backend could
    // ever answer.
    readonly property int chipTimeoutMs: 3000

    Timer {
        id: chipWatchdogTimer
        interval: root.chipTimeoutMs
        repeat: false
        onTriggered: root.pendingChip = ""
    }

    onGamingStateChanged: if (root.pendingChip === "gaming") { root.pendingChip = ""; chipWatchdogTimer.stop(); }
    onDarkStateChanged: if (root.pendingChip === "dark") { root.pendingChip = ""; chipWatchdogTimer.stop(); }
    onDndStateChanged: if (root.pendingChip === "dnd") { root.pendingChip = ""; chipWatchdogTimer.stop(); }
    onVolumeUnmutedChanged: if (root.pendingChip === "volume") { root.pendingChip = ""; chipWatchdogTimer.stop(); }
    onWifiRadioOnChanged: if (root.pendingChip === "wifi") { root.pendingChip = ""; chipWatchdogTimer.stop(); }
    onBluetoothAdapterOnChanged: if (root.pendingChip === "bluetooth") { root.pendingChip = ""; chipWatchdogTimer.stop(); }

    // ── Command construction (T-14-13, carried over verbatim) — every
    //    command below is a fixed argv array. Its only computed element is
    //    the home-prefixed script path; every other element is a
    //    double-quoted literal. ────────────────────────────────────────
    Process {
        id: gamingProcess
        running: false
        command: [root.homeDir + "/.config/hypr/scripts/gaming-mode-toggle.sh"]
    }
    // ── Dark chip's process — startDetached(), not `running: true`
    // (render-gate regression fix, carried over from QuickToggles.qml's
    // own prior header: a lifetime-bound `running: true` Process is
    // killed when the drawer that owns its QML object tree is dismissed,
    // but the launcher — summoned via `qs ipc call launcher open theme`
    // (quick task 260822-sht, Task 12; theme-switch.sh is retired) —
    // takes focus and D-13's focus-loss rule dismisses the drawer the
    // instant it does, mid-flight of the very IPC call that would open
    // the launcher's own Style ▸ Theme picker. `startDetached()` launches
    // the same fixed argv fully independent of ANY QML object's lifetime
    // — now doubly so, since this Process lives on the singleton rather
    // than on a destroy-on-dismiss drawer instance, but the detachment is
    // kept for the launcher-focus reason above regardless. ─────────────
    Process {
        id: darkProcess
        command: ["qs", "ipc", "call", "launcher", "open", "theme"]
    }

    function pressGaming() {
        if (root.pendingChip !== "")
            return;
        root.pendingChip = "gaming";
        chipWatchdogTimer.restart();
        gamingProcess.running = true;
    }

    function pressDnd() {
        if (root.pendingChip !== "")
            return;
        root.pendingChip = "dnd";
        chipWatchdogTimer.restart();
        // D-19-19's own promotion: the write goes through NotifServer's
        // own toggle verb, never an external client call from this file.
        NotifServer.toggleDnd();
    }

    function pressDark() {
        if (root.pendingChip !== "")
            return;
        root.pendingChip = "dark";
        chipWatchdogTimer.restart();
        darkProcess.startDetached();
    }

    // ── 15-07 press verbs — shaped exactly like pressGaming() above: return
    //    early if any chip is pending, return early if the backend seam is
    //    null, set the pending name, restart the shared watchdog, then call
    //    the backend's own writer with the negation of the current truth.
    //    The press NEVER assigns the tile's lit state (D-22). ─────────────
    function pressVolume() {
        if (root.pendingChip !== "")
            return;
        if (!root.audioBackend)
            return;
        root.pendingChip = "volume";
        chipWatchdogTimer.restart();
        root.audioBackend.setMasterMuted(root.volumeUnmuted);
    }

    function pressWifi() {
        if (root.pendingChip !== "")
            return;
        if (!root.wifiBackend)
            return;
        root.pendingChip = "wifi";
        chipWatchdogTimer.restart();
        root.wifiBackend.setWifiEnabled(!root.wifiRadioOn);
    }

    function pressBluetooth() {
        if (root.pendingChip !== "")
            return;
        if (!root.bluetoothBackend)
            return;
        root.pendingChip = "bluetooth";
        chipWatchdogTimer.restart();
        root.bluetoothBackend.setAdapterEnabled(!root.bluetoothAdapterOn);
    }

    function chipLitFor(name) {
        switch (name) {
        case "gaming": return root.gamingState;
        case "dnd": return root.dndState;
        case "dark": return root.darkState;
        case "volume": return root.volumeUnmuted;
        case "wifi": return root.wifiRadioOn;
        case "bluetooth": return root.bluetoothAdapterOn;
        }
        return false;
    }

    function pressChipByName(name) {
        switch (name) {
        case "gaming": pressGaming(); break;
        case "dnd": pressDnd(); break;
        case "dark": pressDark(); break;
        case "volume": pressVolume(); break;
        case "wifi": pressWifi(); break;
        case "bluetooth": pressBluetooth(); break;
        }
    }
}
