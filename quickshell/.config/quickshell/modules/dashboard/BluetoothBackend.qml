// BluetoothBackend.qml — the bluetooth panel's BlueZ adapter (Phase 15 Plan
// 03, PANEL-04/PANEL-06). The single shared reader/writer the bluetooth
// panel (and, later, 15-06's discovery/pair/connect surface) consumes.
//
// Root type `Scope` (from `Quickshell`, NOT `Item`) — the same twin shape as
// `WifiBackend.qml`, so the two connectivity backends read as one grammar.
// This file needs no subprocess, no parser and no timer at all — imports
// stay at QtQuick, Quickshell (for Scope) and Quickshell.Bluetooth, and
// nothing else.
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Scope {
    id: root

    // ── Lifecycle gate — bound by shell.qml to bluetoothPanelLoader.active.
    //    Gates nothing yet: discovery is 15-06's, and this file must NOT
    //    set `discovering` or start any inquiry. Declaring the gate now is
    //    what lets 15-06 bind discovery to it without touching
    //    shell.qml. ─────────────────────────────────────────────────────
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

    // ── The only place in this repo that powers the adapter from QML —
    //    this plan's Enable button calls it, 15-07's Bluetooth tile will
    //    call the same function. Returns immediately when no adapter is
    //    present. ───────────────────────────────────────────────────────
    function setAdapterEnabled(on) {
        if (!root.adapterPresent)
            return;
        root.adapter.enabled = on;
    }

    // ── Reserved for 15-06 — named here as the contract that plan adds,
    //    deliberately NOT declared (Prohibition P2, same reasoning as
    //    WifiBackend.qml):
    //      discovering            - adapter.discovering, exposed live
    //      connectedDevices       - currently-connected paired devices
    //      pairedDevices          - bonded, not-currently-connected devices
    //      discoveredDevices      - visible-but-not-yet-paired devices
    //      startDiscovery()/stopDiscovery()
    //      pair(device)/cancelPair()
    //      connect(device)/disconnect(device)/forget(device)
    //      deviceActionFailed     - the inferred-failure -> copy signal
}
