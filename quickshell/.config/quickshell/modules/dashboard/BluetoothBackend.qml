// BluetoothBackend.qml — the bluetooth panel's BlueZ adapter (Phase 15 Plan
// 03 built the lifecycle gate and the power write; Phase 15 Plan 06 — this
// revision — fulfils the members 15-03 reserved and left undeclared).
//
// Root type `Scope` (from `Quickshell`, NOT `Item`) — the same twin shape as
// `WifiBackend.qml`, so the two connectivity backends read as one grammar.
// This file needs no subprocess, no parser and no timer beyond the one
// watchdog below — imports stay at QtQuick, Quickshell (for Scope) and
// Quickshell.Bluetooth, and nothing else. It launches no `Process` at all,
// which is a stronger statement than fixed-argv discipline: every read and
// every write in this file crosses straight into the native BlueZ binding
// Quickshell.Bluetooth exposes, never a command-line wrapper (Prohibition
// P1).
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Scope {
    id: root

    // ── Lifecycle gate — bound by shell.qml to bluetoothPanelLoader.active.
    //    15-03 declared this gate before it had a consumer; this plan is
    //    that consumer (see `onPanelOpenChanged` below, which stops
    //    discovery the instant this goes false). ─────────────────────────
    property bool panelOpen: false

    // ── The default adapter — a nullable pointer, and the ONE place this
    //    repo names the singleton's adapter pointer. Plain (non-readonly)
    //    so the no-adapter branch can be proven by a temporary override on
    //    a host that has a real controller, the same named-seam discipline
    //    14-06 used for the battery dial on a machine with no battery. The
    //    committed default MUST bind to the singleton; no literal override
    //    may remain in the committed file. ───────────────────────────────
    property var adapter: Bluetooth.defaultAdapter

    // True only when the seam is neither null nor undefined. Every other
    // read of `adapter` in this file or in the panel goes through this
    // first, except `adapterEnabled` immediately below, which is itself
    // guarded by optional chaining.
    readonly property bool adapterPresent: root.adapter !== null && root.adapter !== undefined

    // Optional chaining with an explicit false default — an absent adapter
    // yields false rather than a binding error, so the no-adapter branch
    // renders with zero type errors in the log (D-15-26's own acceptance
    // criterion, not just an implementation nicety).
    readonly property bool adapterEnabled: root.adapter?.enabled ?? false

    // ── G-15-2 gap closure (15-12) — why this file now reads the state
    //    enum, having previously read only the bool ─────────────────────
    // `adapterEnabled` collapses TWO distinct adapter states — `Disabled`
    // and `Blocked` — into one indistinguishable `false`. An rfkill
    // soft-blocked adapter (this host's own persistent state) and a plainly
    // powered-off adapter read identically through that one bool, so the
    // panel could not tell "press Enable and it will work" apart from
    // "press Enable and BlueZ will refuse the write" — which is exactly
    // what made the Enable button inert on this host. `15-API-PROBE.md:22`
    // had already measured `state: Blocked` as the live distinguishing
    // signal, before this panel was built, and it went unused.
    //
    // The installed qmltypes exposes `state` (readonly,
    // `BluetoothAdapterState::Enum`, bindable, notify `stateChanged`)
    // alongside `enabled` — enum values `[Disabled, Enabled, Enabling,
    // Disabling, Blocked]`, `Blocked == 4`. A plain declarative binding on
    // `adapter.state` picks up `stateChanged` with no manual `Connections`
    // block — the same reactive mechanism `adapterEnabled` above already
    // relies on for `enabledChanged`.
    //
    // Guarded by `adapterPresent` first, exactly as every other read of
    // `adapter` in this file is (this property's own header note, above),
    // with optional chaining as a second line of defence: an absent
    // adapter yields `undefined !== Blocked`, i.e. `false`, rather than a
    // binding error — the no-adapter branch keeps rendering with zero type
    // errors in the log (D-15-26's own acceptance criterion, restated here
    // because this property inherits it).
    readonly property bool adapterBlocked: root.adapterPresent && (root.adapter?.state === BluetoothAdapterState.Blocked)

    // ── The only place in this repo that powers the adapter from QML —
    //    15-03's Enable button calls it, 15-07's Bluetooth tile will call
    //    the same function. Returns immediately when no adapter is
    //    present. ───────────────────────────────────────────────────────
    //
    // G-15-2 (15-12) added the `adapterBlocked` guard below. It fires ONLY
    // on the power-ON path (`on === true`): a power-OFF request against a
    // blocked adapter is already a no-op at the binding, so a symmetric
    // guard on the off path would silently change 15-07's Bluetooth
    // quick-toggle's behaviour, which calls this same function, for no
    // reason tied to this gap. This is PRESS SUPPRESSION, not the
    // affordance — the affordance (rendering Enable present-but-disabled
    // with a reason) is 15-12's Task 2, in `BluetoothPanel.qml`. Both are
    // required: this guard alone would leave a working-looking button that
    // silently does nothing (the original bug); the disabled rendering
    // alone, without this guard, would leave a hit region that still
    // reaches the refusing binding and re-spams the log with "Cannot
    // enable adapter because it is blocked by rfkill." on every press.
    function setAdapterEnabled(on) {
        if (!root.adapterPresent)
            return;
        if (on && root.adapterBlocked)
            return;
        root.adapter.enabled = on;
    }

    // ═══════════════════════════════════════════════════════════════════
    // 15-06 — grouped device collections (D-15-18's ordering)
    //
    // All three partition the SAME iteration order — the adapter's own
    // device model, read through `.devices.values` (15-API-PROBE.md's A3
    // verdict: `UntypedObjectModel` has no `.count`/`.get(i)`; `.values` is
    // an array-like object supporting `.length`, index access and
    // `Array.prototype` methods including `.filter`, proven live against
    // 11 real PipeWire nodes and reactive on rebind — the same mechanism
    // this file relies on for these three bindings to stay live as devices
    // appear, connect and disconnect). `.filter()` preserves source order;
    // nothing here sorts, by name, by signal, by recency or by battery.
    // A device that changes group does so because a predicate flipped, not
    // because anything reordered it, and its former group's peers keep
    // their positions — that is what makes the ordering truth hold.
    // ═══════════════════════════════════════════════════════════════════
    readonly property var connectedDevices: root.adapterPresent
        ? root.adapter.devices.values.filter(function (d) {
              return d && d.connected;
          })
        : []
    readonly property var pairedDevices: root.adapterPresent
        ? root.adapter.devices.values.filter(function (d) {
              return d && (d.bonded || d.paired) && !d.connected;
          })
        : []
    readonly property var discoveredDevices: root.adapterPresent
        ? root.adapter.devices.values.filter(function (d) {
              return d && !d.connected && !d.bonded && !d.paired;
          })
        : []

    // ── Address-keyed identity (T-15-08's spoofing half) ─────────────────
    // The device NAME is never an identity: two headsets of the same model
    // can and do report the same `deviceName`, and BlueZ's address is the
    // only thing guaranteed to distinguish them. Every verb, the pending
    // slot, and every row lookup in the panel resolves through this
    // function rather than through a name comparison.
    function deviceByAddress(address) {
        if (!address || !root.adapterPresent)
            return null;
        var all = root.adapter.devices.values;
        for (var i = 0; i < all.length; i++) {
            if (all[i] && all[i].address === address)
                return all[i];
        }
        return null;
    }

    // ── The contextual verb, decided once (D-15-19) — the row's label and
    //    the row's press both read THIS function, so they can never
    //    disagree across a state change landing between render and press. ─
    function contextualVerb(device) {
        if (!device)
            return "";
        if (!device.bonded && !device.paired)
            return "pair";
        if (device.connected)
            return "disconnect";
        return "connect";
    }

    // ── The single in-flight action slot — QuickToggles.qml's `pendingChip`
    //    idiom generalized from a chip name to a device address, kept
    //    deliberately single-slot: the press guard below starts at most one
    //    action at a time, one radio serves one conversation, and a
    //    map-shaped slot would buy concurrency the hardware does not offer
    //    while making the inference machine below considerably harder to
    //    reason about. ─────────────────────────────────────────────────
    property string pendingAddress: ""
    property string pendingVerb: "" // "" | "pair" | "connect" | "disconnect"
    property bool pendingUserCancelled: false
    readonly property var pendingDevice: root.pendingAddress !== "" ? root.deviceByAddress(root.pendingAddress) : null

    // `pressDevice` is the row's one call site — it reads `contextualVerb`'s
    // answer and dispatches, opening with the press guard: a second press
    // on a row already in flight, or a press on any OTHER row while one
    // action is in flight, starts nothing at all.
    function pressDevice(device) {
        if (!device)
            return;
        if (root.pendingAddress !== "")
            return;
        var verb = root.contextualVerb(device);
        if (verb === "pair")
            root.pair(device);
        else if (verb === "connect")
            root.connect(device);
        else if (verb === "disconnect")
            root.disconnect(device);
    }

    // ── The two named watchdog constants — deliberately generous. A
    //    watchdog that fires before BlueZ's own pairing-agent timeout would
    //    render a failure while BlueZ is still legitimately waiting for the
    //    peer, turning the safety net into the bug it exists to prevent.
    //    Task 3 measures a real pairing's duration against `pairWatchdogMs`
    //    and raises it (recording the measurement) if the real duration
    //    ever exceeds it. ──────────────────────────────────────────────
    readonly property int pairWatchdogMs: 90000
    readonly property int connectWatchdogMs: 20000

    // Declares `interval:` and never a duration property — a watchdog
    // riding the motion-scale axis would collapse to zero at the `off`
    // setting and resolve a pending action before any backend could
    // answer, the same reason QuickToggles.qml's `chipWatchdogTimer`
    // carries this comment. On expiry it clears the slot and emits
    // `deviceActionFailed` with the same reason text the verb's own
    // inference would have used — the answer to RESEARCH Pitfall 2's named
    // warning sign, a row stuck spinning forever because a wedged BlueZ
    // never delivers a transition.
    Timer {
        id: deviceWatchdogTimer
        interval: root.pairWatchdogMs
        repeat: false
        onTriggered: {
            var dev = root.pendingDevice;
            var verb = root.pendingVerb;
            root.pendingAddress = "";
            root.pendingVerb = "";
            root.pendingUserCancelled = false;
            if (dev)
                root.deviceActionFailed(dev, verb === "pair" ? "Couldn't pair" : "Couldn't connect");
        }
    }

    // ── The single seam every present and future consumer of a failed
    //    bluetooth action listens on. `Quickshell.Bluetooth` exposes no
    //    failure signal of its own — this is inferred, not native. ───────
    signal deviceActionFailed(var device, string reasonText)

    // ── The five verbs. Every one calls the native invokable member the
    //    installed qmltypes confirms (`device.connect()`, `.disconnect()`,
    //    `.pair()`, `.cancelPair()`, `.forget()` — all no-argument instance
    //    methods, per `/usr/lib/qt6/qml/Quickshell/Bluetooth/
    //    quickshell-bluetooth.qmltypes`). 15-API-PROBE.md's A4 verdict
    //    (measured against the wifi surface, and this backend's own read of
    //    the same qmltypes pattern) is that the plain invokable is the real
    //    actor — there is no `request*` signal on `BluetoothDevice` at all,
    //    so no such ambiguity exists here the way it did for
    //    `WifiNetwork`. Not one of these five may shell out — not to
    //    `bluetoothctl`, not to `rfkill`, not to anything; Prohibition P1
    //    fences the whole file and there is a native member for every read
    //    and every write this backend performs. ──────────────────────────
    function pair(device) {
        if (!device)
            return;
        root.pendingAddress = device.address;
        root.pendingVerb = "pair";
        root.pendingUserCancelled = false;
        deviceWatchdogTimer.interval = root.pairWatchdogMs;
        deviceWatchdogTimer.restart();
        device.pair();
    }

    // Sets `pendingUserCancelled` BEFORE calling the native cancel — the
    // order matters, because the transition it triggers may arrive
    // synchronously and the pairing branch of the inference (below) reads
    // this flag to decide whether a resolved-false `pairing` is a genuine
    // failure or the user's own Cancel.
    function cancelPair(device) {
        if (!device)
            return;
        root.pendingUserCancelled = true;
        device.cancelPair();
    }

    function connect(device) {
        if (!device)
            return;
        root.pendingAddress = device.address;
        root.pendingVerb = "connect";
        root.pendingUserCancelled = false;
        deviceWatchdogTimer.interval = root.connectWatchdogMs;
        deviceWatchdogTimer.restart();
        device.connect();
    }

    function disconnect(device) {
        if (!device)
            return;
        root.pendingAddress = device.address;
        root.pendingVerb = "disconnect";
        root.pendingUserCancelled = false;
        deviceWatchdogTimer.interval = root.connectWatchdogMs;
        deviceWatchdogTimer.restart();
        device.disconnect();
    }

    // `forget` does NOT claim the pending slot: forgetting removes the
    // device from the bonded set, so the model itself (the device leaving
    // `pairedDevices`/`connectedDevices`) is the acknowledgement and there
    // is nothing to wait for.
    function forget(device) {
        if (!device)
            return;
        device.forget();
    }

    // ═══════════════════════════════════════════════════════════════════
    // The inference (RESEARCH Pitfall 2's recipe, implemented exactly).
    // `Quickshell.Bluetooth` exposes no counterpart to Networking's
    // `connectionFailed`/`reason` — failure here is inferred from watching
    // the ONE device with an action in flight (`pendingDevice`) transition,
    // never re-derived per row. `target: root.pendingDevice` means this
    // block re-targets itself to exactly the address the pending slot
    // names, and detaches (fires nothing) once the slot clears.
    // ═══════════════════════════════════════════════════════════════════
    Connections {
        id: actionWatcher
        target: root.pendingDevice

        // Pairing. React only when the pending verb is "pair" and the
        // device's own pairing flag has JUST returned to false — a rising
        // edge (false -> true, when the pair attempt begins) is not this
        // branch's business and is skipped by the `dev.pairing` guard.
        function onPairingChanged() {
            if (root.pendingVerb !== "pair")
                return;
            var dev = root.pendingDevice;
            if (!dev || dev.pairing)
                return;
            deviceWatchdogTimer.stop();
            var wasCancelled = root.pendingUserCancelled;
            var bondedNow = dev.bonded;
            root.pendingAddress = "";
            root.pendingVerb = "";
            root.pendingUserCancelled = false;
            if (bondedNow)
                return; // succeeded — emit nothing
            if (wasCancelled)
                return; // the user's own Cancel is not a failure — emit nothing
            root.deviceActionFailed(dev, "Couldn't pair");
        }

        // Connecting / Disconnecting. Deliberately NO cancel caveat on the
        // connect branch: the native surface offers no user-cancel path for
        // connect the way it does for pair (there is no `cancelConnect()`
        // on `BluetoothDevice`), so any Connecting -> Disconnected
        // transition can be read as failure without ambiguity.
        function onStateChanged() {
            var dev = root.pendingDevice;
            if (!dev)
                return;
            if (root.pendingVerb === "connect") {
                if (dev.state === BluetoothDeviceState.Connected) {
                    deviceWatchdogTimer.stop();
                    root.pendingAddress = "";
                    root.pendingVerb = "";
                    root.pendingUserCancelled = false;
                } else if (dev.state === BluetoothDeviceState.Disconnected) {
                    deviceWatchdogTimer.stop();
                    root.pendingAddress = "";
                    root.pendingVerb = "";
                    root.pendingUserCancelled = false;
                    root.deviceActionFailed(dev, "Couldn't connect");
                }
            } else if (root.pendingVerb === "disconnect") {
                // A failed disconnect gets the watchdog's silent clear and
                // NO failed state: the UI-SPEC Copywriting Contract locks
                // words for a failed pair and a failed connect but none for
                // a failed disconnect, and this plan has no authority to
                // mint new locked copy on its own. That asymmetry is
                // deliberate, not an omission — raised as an explicit
                // question at Task 4's render gate rather than answered
                // unilaterally here.
                if (dev.state === BluetoothDeviceState.Disconnected) {
                    deviceWatchdogTimer.stop();
                    root.pendingAddress = "";
                    root.pendingVerb = "";
                    root.pendingUserCancelled = false;
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // Discovery — opt-in, lifecycle-bound (D-15-18, T-15-04's mitigation).
    //
    // The wifi panel scans continuously for its whole open lifetime; this
    // panel does not discover at all until the user presses "Add device".
    // That asymmetry is deliberate. A bluetooth inquiry contends with the
    // same radio that is carrying an A2DP stream, so continuous discovery
    // can stutter the very audio the panel was opened to manage — and the
    // daily case, reconnecting known headphones, needs ZERO discovery to
    // succeed. Doing the wifi thing here would let the panel damage the
    // connection it exists to manage. Discovery is therefore opt-in, and it
    // stops when the panel closes.
    //
    // The installed qmltypes (`/usr/lib/qt6/qml/Quickshell/Bluetooth/
    // quickshell-bluetooth.qmltypes`) exposes discovery as a plain
    // read/write boolean property on `BluetoothAdapter` — `discovering`
    // (`read: discovering`, `write: setDiscovering`) — NOT a start/stop
    // method pair. `startDiscovery()`/`stopDiscovery()` below are this
    // file's own wrapper functions over that one property, kept as named
    // functions (rather than letting callers write `adapter.discovering`
    // directly) so `startDiscovery()` can be grepped for exactly one call
    // site repo-wide. Recorded here as a durable finding for 15-07's
    // Bluetooth tile, which reads this same answer.
    // ═══════════════════════════════════════════════════════════════════
    readonly property bool discovering: root.adapter?.discovering ?? false

    // `startDiscovery()` has exactly one call site in this whole repo: the
    // "Add device" press BluetoothPanel.qml builds. Nothing else may start
    // an inquiry — not panel open, not a timer, not a retry, not a failed
    // connect.
    function startDiscovery() {
        if (!root.adapterPresent)
            return;
        root.adapter.discovering = true;
    }

    function stopDiscovery() {
        if (!root.adapterPresent)
            return;
        root.adapter.discovering = false;
    }

    // This is not decoration. This backend is a shell-root sibling that
    // SURVIVES the panel's destruction, so without this handler a dismissed
    // panel would leave an inquiry running against the radio indefinitely —
    // precisely the denial-of-service shape T-15-04 names, and precisely
    // what the mitigation "discovery is bound to panelOpen so it stops on
    // dismiss" means mechanically.
    onPanelOpenChanged: if (!root.panelOpen)
        root.stopDiscovery()
}
