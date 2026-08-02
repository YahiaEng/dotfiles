// WifiBackend.qml — the wifi panel's NetworkManager adapter (Phase 15 Plan
// 03 tracer, completed by Plan 05 — PANEL-03/PANEL-06). The single shared
// reader/writer the wifi panel consumes for its scan lifecycle, its
// grouped/stable network collections and its four verbs.
//
// Root type `Scope` (from `Quickshell`, NOT `Item`) — mirrors
// `AudioBackend.qml`/`MediaBackend.qml`'s own header rationale exactly: it
// renders nothing and mounts cleanly under `ShellRoot`, unlike an `Item`.
// This file needs no subprocess, no parser and no timer at all — imports
// stay at QtQuick, Quickshell (for Scope) and Quickshell.Networking, and
// nothing else.
//
// ── 15-API-PROBE.md A3 correction, binding on this file ──────────────────
// `Networking.devices` is an `UntypedObjectModel`: no `.count`, no
// `.get(i)`. `.values` is the correct accessor for JS-side iteration
// (array-like: `.length`, index access, `.map`/`.filter`, but
// `Array.isArray()` is false) — see A3 in full. The same shape applies to
// `wifiDevice.networks` below, confirmed live by this plan's own Task 1
// measurement 5.
//
// ── RESEARCH Pitfall 1 — the networking class hierarchy is not flat ──────
// There is no top-level network list and no top-level scanner switch:
// `Networking.devices` must be filtered down to the one `WifiDevice` before
// any scan-related member can be reached at all.
//
// ── 15-API-PROBE.md Open Q1 correction, binding on this file ─────────────
// List order is NOT stable across rescans and network OBJECT IDENTITY does
// NOT survive every rescan — access points churn (appear/disappear), not
// merely reorder. `seenOrder` below is therefore a first-seen REGISTRY,
// diffed against the live model on every `valuesChanged` emission (add
// newly-seen objects at the bottom, drop objects no longer present), never
// a sort and never an assumption that a held reference stays valid forever.
import QtQuick
import Quickshell
import Quickshell.Networking

Scope {
    id: root

    // ── Lifecycle gate — bound by shell.qml to wifiPanelLoader.active. ───
    property bool panelOpen: false

    // ── The one wifi device — resolved by filtering the device model,
    //    never by a flat access (RESEARCH Pitfall 1). `.values` is A3's
    //    measured accessor shape. `null` is an ordinary value here, never
    //    an error — every consumer must handle it as such. ───────────────
    readonly property var wifiDevice: {
        var devices = Networking.devices ? Networking.devices.values : [];
        for (var i = 0; i < devices.length; i++) {
            if (devices[i] && devices[i].type === DeviceType.Wifi)
                return devices[i];
        }
        return null;
    }

    // ── D-15-26 branch inputs — named seams, each defaulting to the real
    //    singleton via a live QML binding. Plain (non-readonly) properties
    //    rather than readonly for exactly one reason: `wifiHardwareEnabled`
    //    is read-only on the singleton itself and this host's radio
    //    reports hard-blocked false with no physical switch to flip, so
    //    the unfixable branch can only be observed by temporarily
    //    overriding this one line — the same named-seam discipline 14-06
    //    used for the battery dial on a machine with no battery. The
    //    committed default MUST bind to the singleton; no literal override
    //    may remain in the committed file. ───────────────────────────────
    property bool wifiEnabled: Networking.wifiEnabled
    property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled

    // ── The only place in this repo that turns the radio on or off from
    //    QML — the panel's Enable button calls it, and 15-07's Wi-Fi tile
    //    will call the same function. ───────────────────────────────────
    function setWifiEnabled(on) {
        Networking.wifiEnabled = on;
    }

    // ═══════════════════════════════════════════════════════════════════
    // Below this line: this plan's additions. Every member 15-03 reserved
    // is now declared under its reserved name (scanning, currentNetwork,
    // savedNetworks, otherNetworks, connect, disconnect, forget,
    // connectFailed). Six further members are ADDITIONS to that surface,
    // named openly rather than smuggled in: seenOrder, cancelConnect,
    // rescan, failReasonText, securityKind, connectingNetwork.
    // ═══════════════════════════════════════════════════════════════════

    // ── D-15-15 scan lifecycle gate — a declarative Binding, not an
    //    imperative write in an onPanelOpenChanged handler, because the
    //    device pointer can change under the panel and a handler would
    //    miss it. `when` null-guards so no binding ever fires against a
    //    null target. ────────────────────────────────────────────────────
    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.panelOpen && root.wifiEnabled
        when: root.wifiDevice !== null
    }

    // Published truth, not the request: reads the device's own flag back
    // through a null guard. There is no per-scan-cycle signal anywhere in
    // this binding, so `scanning` is true for the panel's whole open
    // lifetime rather than pulsing per sweep — UI-SPEC E3's `loading` row.
    readonly property bool scanning: root.wifiDevice ? root.wifiDevice.scannerEnabled : false

    // ── rescan() — the refresh control's single call site. No explicit
    //    scan-trigger method exists on the object graph (measured, see
    //    Measurement 2 below); driving the scan flag false-then-true is
    //    the only lever available. One call site so the mechanism can be
    //    changed in one place if a future build disproves it. ────────────
    function rescan() {
        if (!root.wifiDevice)
            return;
        root.wifiDevice.scannerEnabled = false;
        root.wifiDevice.scannerEnabled = true;
    }

    // ── D-15-16 first-seen ordering registry ──────────────────────────
    // The underlying `networks` model belongs to NetworkManager and may
    // reorder or drop-and-recreate objects on any rescan (Open Q1,
    // measured) — stable ordering cannot be inherited from it, it has to
    // be maintained. `seenOrder` is a plain array of network OBJECTS in
    // first-observed order, diffed (never sorted) on every underlying
    // change: entries no longer present are dropped, newly-seen entries
    // append at the bottom. Identity is the network object, never its
    // `name` — two access points can broadcast the same SSID, and keying
    // on the string would silently merge them (the PANEL-03 adjacency
    // backstop this registry exists to satisfy).
    property var seenOrder: []

    // Manual membership test rather than `.indexOf` — `current` below is
    // an `UntypedObjectModel.values`, proven array-like for `.length`/
    // index access/`.map`/`.filter` (A3) but never proven for `.indexOf`,
    // so this stays inside the measured surface rather than assuming a
    // wider one.
    function _containsRef(list, obj, len) {
        for (var i = 0; i < len; i++) {
            if (list[i] === obj)
                return true;
        }
        return false;
    }

    function _syncSeenOrder() {
        var current = (root.wifiDevice && root.wifiDevice.networks) ? root.wifiDevice.networks.values : [];
        var currentLen = current.length;
        var next = [];
        // Keep existing entries still present, in their existing order —
        // no comparator, no reorder, ever.
        for (var i = 0; i < root.seenOrder.length; i++) {
            if (root._containsRef(current, root.seenOrder[i], currentLen))
                next.push(root.seenOrder[i]);
        }
        // Newly-seen networks append to the bottom, never inserted mid-list.
        for (var j = 0; j < currentLen; j++) {
            if (!root._containsRef(next, current[j], next.length))
                next.push(current[j]);
        }
        root.seenOrder = next;
    }

    // Re-sync whenever the resolved device changes (device pointer can
    // take a moment to resolve after startup) and whenever the live model
    // actually fires — `networks` itself is `isPropertyConstant` on the
    // device (the pointer never changes), so the model's own `valuesChanged`
    // signal is what carries every add/remove.
    onWifiDeviceChanged: root._syncSeenOrder()
    Component.onCompleted: root._syncSeenOrder()

    Connections {
        target: (root.wifiDevice && root.wifiDevice.networks) ? root.wifiDevice.networks : null
        function onValuesChanged() {
            root._syncSeenOrder();
        }
    }

    // ── The three grouped collections (D-15-16) — plain JS arrays derived
    //    by filtering `seenOrder`, which preserves first-seen order inside
    //    every group for free. No comparator-based reordering call exists
    //    anywhere in this file. Bound to arrays rather than the untyped
    //    model deliberately, sidestepping the model-binding half of the
    //    accessor question entirely. ────────────────────────────────────
    readonly property var currentNetwork: {
        for (var i = 0; i < root.seenOrder.length; i++) {
            if (root.seenOrder[i] && root.seenOrder[i].connected)
                return root.seenOrder[i];
        }
        return null;
    }

    readonly property var savedNetworks: {
        var out = [];
        for (var i = 0; i < root.seenOrder.length; i++) {
            var n = root.seenOrder[i];
            if (n && n.known && n !== root.currentNetwork)
                out.push(n);
        }
        return out;
    }

    readonly property var otherNetworks: {
        var out = [];
        for (var i = 0; i < root.seenOrder.length; i++) {
            var n = root.seenOrder[i];
            if (n && n !== root.currentNetwork && !n.known)
                out.push(n);
        }
        return out;
    }

    // ── securityKind(network) — classifies a network so the panel can
    //    tell a passphrase network from one it cannot connect to at all
    //    (P2's "never offer a control that cannot work"). `Unknown` maps
    //    to "open" on purpose: the panel attempts a plain connect, and if
    //    NetworkManager answers NoSecrets the mapped copy "Password
    //    required" is precisely the prompt to expand the field. ─────────
    function securityKind(network) {
        if (!network)
            return "open";
        switch (network.security) {
        case WifiSecurityType.Open:
        case WifiSecurityType.Owe:
            return "open";
        case WifiSecurityType.Sae:
        case WifiSecurityType.Wpa2Psk:
        case WifiSecurityType.WpaPsk:
        case WifiSecurityType.StaticWep:
            return "passphrase";
        case WifiSecurityType.Wpa2Eap:
        case WifiSecurityType.WpaEap:
        case WifiSecurityType.Leap:
        case WifiSecurityType.DynamicWep:
        case WifiSecurityType.Wpa3SuiteB192:
            return "enterprise";
        default:
            return "open";
        }
    }

    // ── The in-flight identity — the failure signal's connection target
    //    and the row-scoped pending key Task 3's panel reads. Cleared on
    //    OBSERVED backend truth (this network's own `connected` becoming
    //    true, or its `connectionFailed` firing, or an explicit cancel) —
    //    never on the write merely returning, matching AudioBackend's own
    //    device-switch truth-driven pattern (15-04-SUMMARY.md). ─────────
    property var connectingNetwork: null

    // ── The four verbs — all take the network object, never an SSID. ────
    function connect(network, psk) {
        if (!network)
            return;
        root.connectingNetwork = network;
        // The single native passphrase call site in the entire repository
        // (Prohibition P3's call-path half; verified exactly one grep hit
        // below). The parameter is used and discarded: not assigned to a
        // property, not appended to any collection, not captured in a
        // closure that outlives this call, and not passed to any
        // diagnostic logging call — there is no diagnostic logging call in
        // this file at all.
        if (psk && psk.length > 0)
            network.connectWithPsk(psk);
        else
            network.connect();
    }

    // The abort path UI-SPEC E4's `loading` row requires. `Quickshell.Networking`
    // exposes no cancel/abort verb by that name — the network's own
    // `disconnect()` is the inferred teardown call (A2's own recorded
    // assumption; Task 3 measures its real effect live before trusting it).
    // Returns whether a call was made at all, so Task 3 can distinguish
    // "aborted" from "there was nothing to abort".
    function cancelConnect(network) {
        if (!network) {
            root.connectingNetwork = null;
            return false;
        }
        network.disconnect();
        root.connectingNetwork = null;
        return true;
    }

    function disconnect(network) {
        if (!network)
            return;
        network.disconnect();
    }

    // D-15-17's own reason, recorded so a later reader does not read this
    // as scope creep: NetworkManager persists a connection profile even
    // when the passphrase was wrong, and a later connect silently reuses
    // the bad PSK — without `forget`, one typo routes the user straight
    // back to nm-connection-editor, the app this phase exists to displace.
    // A4 measured live (15-API-PROBE.md, and re-measured live by this
    // plan's own Task 1 measurement 4): the plain invokable method is the
    // real actor here — the request-prefixed signal on the same object has
    // nothing subscribed to it by default and is inert on its own, never a
    // substitute call path.
    function forget(network) {
        if (!network)
            return;
        network.forget();
    }

    // ── failReasonText(reason) — the locked mapping, implemented verbatim
    //    from the UI-SPEC's Copywriting Contract. The enum's own
    //    stringifier must never appear in this function or anywhere else
    //    this file produces a rendered string (see 15-05-PLAN.md
    //    <binding_corrections>: rendering the raw enum identifier to the
    //    user is exactly the jargon mistake this function exists to
    //    prevent). The raw enum value is recorded in the SUMMARY when a
    //    failure is observed, so the mapping can be audited — never on
    //    screen. ────────────────────────────────────────────────────────
    function failReasonText(reason) {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "Password required";
        case ConnectionFailReason.WifiAuthTimeout:
            return "Wrong password";
        case ConnectionFailReason.WifiClientDisconnected:
        case ConnectionFailReason.WifiClientFailed:
            return "Couldn't connect";
        case ConnectionFailReason.WifiNetworkLost:
            return "Network out of range";
        case ConnectionFailReason.Unknown:
        default:
            return "Couldn't connect";
        }
    }

    // The signal carries already-mapped copy, never an enum, so no
    // consumer can accidentally render the identifier. The PSK is not a
    // parameter of this signal and must never be interpolated into
    // `reasonText` — Prohibition P3's second clause.
    signal connectFailed(var network, string reasonText)

    // Retargets automatically whenever `connectingNetwork` changes.
    // Success and failure are both OBSERVED truth, not the write
    // returning: success clears the in-flight identity so a completed
    // connect never leaves a row looking permanently pending; failure
    // captures the network reference before clearing, so the emitted
    // signal always names the row that actually failed.
    Connections {
        target: root.connectingNetwork

        function onConnectedChanged() {
            if (root.connectingNetwork && root.connectingNetwork.connected)
                root.connectingNetwork = null;
        }

        function onConnectionFailed(reason) {
            var failedNetwork = root.connectingNetwork;
            var text = root.failReasonText(reason);
            root.connectingNetwork = null;
            root.connectFailed(failedNetwork, text);
        }
    }
}
