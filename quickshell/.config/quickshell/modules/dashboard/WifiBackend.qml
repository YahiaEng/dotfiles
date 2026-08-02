// WifiBackend.qml — the wifi panel's NetworkManager adapter (Phase 15 Plan
// 03, PANEL-03/PANEL-06). The single shared reader/writer the wifi panel
// (and, later, 15-05's scan/list/connect surface) consumes.
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
// `Array.isArray()` is false) — see A3 in full.
//
// ── RESEARCH Pitfall 1 — the networking class hierarchy is not flat ──────
// There is no top-level network list and no top-level scanner switch:
// `Networking.devices` must be filtered down to the one `WifiDevice` before
// any scan-related member (15-05's job) can be reached at all.
import QtQuick
import Quickshell
import Quickshell.Networking

Scope {
    id: root

    // ── Lifecycle gate — bound by shell.qml to wifiPanelLoader.active.
    //    Gates nothing yet: the scanner is 15-05's, and this file must NOT
    //    set scannerEnabled. Declaring the gate now is what lets 15-05 add
    //    the scanner without touching shell.qml. ────────────────────────
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
    //    QML — this plan's Enable button calls it, and 15-07's Wi-Fi tile
    //    will call the same function. An addition to the outline's listed
    //    backend surface, not a rename of anything. ─────────────────────
    function setWifiEnabled(on) {
        Networking.wifiEnabled = on;
    }

    // ── Reserved for 15-05 — named here as the contract that plan adds,
    //    deliberately NOT declared. An empty property pretending to be a
    //    list is precisely the enabled-looking-control-that-cannot-work
    //    failure Prohibition P2 exists to stop:
    //      scanning        - wifiDevice.scannerEnabled, exposed live
    //      currentNetwork  - the connected network, if any
    //      savedNetworks   - known-but-not-currently-visible networks
    //      otherNetworks   - visible-but-not-yet-known networks
    //      connect(network)    - plain invokable (A4's measured call path)
    //      disconnect()
    //      forget(network)
    //      connectFailed        - the ConnectionFailReason -> copy signal
}
