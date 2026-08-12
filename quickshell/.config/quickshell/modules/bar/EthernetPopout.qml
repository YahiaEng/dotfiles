// EthernetPopout.qml — the ethernet section's popout body (operator request,
// 2026-08-12). Follows WifiPopout.qml's own shape: the device handle is taken
// as a plain property passed down from the capsule, never reached for as a
// singleton; state is bound exactly once; every text element declares its
// format explicitly.
//
// ── Why this file exists ─────────────────────────────────────────────────
// The ethernet glyph shipped as a bare Readout with no popout and no tooltip,
// sitting immediately beside a network glyph that has both — a glyph whose
// click did nothing, which is what the operator reported during GATE-02's
// iteration-2 sitting.
//
// ── What this body can honestly show, and what it deliberately omits ─────
// MEASURED 2026-08-12 with a temporary ETHPROBE (removed before commit), the
// same discipline the ethernet glyph's own comment records for its predicate.
// `Networking.devices`' Wired entry publishes exactly these:
//
//     name       "eno1"                 the interface
//     linkSpeed  1000        (number)   Mb/s, matches /sys/class/net/eno1/speed
//     hasLink    true                   carrier present
//     connected  true                   NM's own connected flag
//     state      2                      NM device state
//     address    "74:56:3C:5D:91:B2"    the MAC — NOT an IP
//     network    a qs::network::Network whose .name is ALSO "eno1"
//
// And it does NOT publish, at all: `interface`, `ip4`, `ipv4`, `addresses`,
// `activeConnection` — every one of them read back `undefined`. So there is
// no IPv4 address available here, and no NetworkManager connection-profile
// name either (`network.name` mirrors the device name rather than reporting
// the profile, "Fiber" on this host per `nmcli`). Both were considered and
// deliberately dropped rather than shown: reaching them needs an `nmcli`
// spawn, and MediaConnectivityCapsule.qml's own header forbids exactly that
// ("adds NO new service connection … nothing here polls and nothing spawns").
// If an IP is ever wanted here, that constraint has to be amended on purpose,
// not crossed quietly by this file.
//
// This body therefore constructs no command, no path and no dispatch string,
// declares no timing object of any kind, and reads only properties that are
// live without a scan — the same contract every other entry in that capsule
// is held to.
//
// ── The foot link ────────────────────────────────────────────────────────
// Every sibling popout routes its foot to a real dashboard target
// (`requestPanel("wifi")`, `"bluetooth"`, `"audio"`, the Performance and Media
// tabs). There is no wired-network panel in the dashboard, so this one
// declares its wayfinding UNAVAILABLE with a reason rather than pointing at
// the Wi-Fi panel and calling it network settings. SectionPopout dims the pill
// and keeps its MouseArea live precisely so the reason stays reachable.
import QtQuick
import "../"
import "../dashboard"

SectionPopout {
    id: root

    // The Wired device, resolved by the capsule and handed down. `null` is an
    // ordinary value here, never an error — the same contract WifiPopout's own
    // `wifiBackend` carries.
    property var ethernetDevice: null

    sectionId: "ethernet"
    popoutTitle: "Ethernet"
    // "lan" is a Material Symbols ligature, verified PRESENT in the installed
    // MaterialSymbolsRounded variable font via fontTools before use (with a
    // deliberate absent control in the same check). GATE-02 row A.3's named
    // failure mode is a nonexistent ligature rendering as its own name in
    // plain text, so this is checked rather than assumed.
    popoutGlyph: "lan"

    // A card with no device behind it is the designed empty state, never an
    // omitted card — the same three-way shape the bar entry itself uses. The
    // glyph only appears in the bar while a Wired device reports connected, so
    // in practice this branch is reachable mainly by a cable pulled while the
    // card is open.
    bodyState: root.ethernetDevice ? "populated" : "empty"
    emptyStateGlyph: "lan"
    emptyStateText: "No wired connection"

    wayfindingLabel: "Open in dashboard"
    wayfindingAvailable: false
    wayfindingUnavailableReason: "The dashboard has no wired-network panel"

    // ── Derived display values — each one read once, formatted explicitly,
    //    and each with a stated fallback so a missing field renders an em
    //    dash rather than the string "undefined". ──────────────────────────
    readonly property bool _hasLink: root.ethernetDevice ? root.ethernetDevice.hasLink === true : false
    readonly property bool _connected: root.ethernetDevice ? root.ethernetDevice.connected === true : false

    readonly property string _stateText: {
        if (!root.ethernetDevice)
            return "No wired connection";
        if (root._connected)
            return "Connected";
        if (root._hasLink)
            return "Cable connected, not configured";
        return "No link";
    }

    readonly property string _interfaceText: {
        if (!root.ethernetDevice)
            return "—";
        var n = root.ethernetDevice.name;
        return (n === undefined || n === null || n === "") ? "—" : String(n);
    }

    // Reported in Mb/s by the device, so rendered in Mb/s rather than rescaled
    // to Gb/s — the unit the source uses is the unit shown. Guarded on hasLink
    // as well as on the number, because a downed interface reports a stale or
    // zero rate rather than clearing it.
    readonly property string _speedText: {
        if (!root.ethernetDevice || !root._hasLink)
            return "—";
        var s = root.ethernetDevice.linkSpeed;
        if (s === undefined || s === null || !(s > 0))
            return "—";
        return s + " Mb/s";
    }

    // Labelled MAC, never "address" — the field is called `address` on the
    // device and returns a hardware address, and an unlabelled hex string next
    // to a network name is exactly what a reader would mistake for an IP.
    readonly property string _macText: {
        if (!root.ethernetDevice)
            return "—";
        var a = root.ethernetDevice.address;
        return (a === undefined || a === null || a === "") ? "—" : String(a);
    }

    // ── Body ─────────────────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: Design.spacingXs

        Text {
            width: parent.width
            text: root._stateText
            font.pixelSize: Design.fontBody
            font.weight: root._connected ? Design.weightEmphasis : Design.weightBody
            color: root._connected ? Colours.onSurface : Colours.onSurfaceVariant
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        Text {
            width: parent.width
            text: root._interfaceText + " · " + root._speedText
            font.pixelSize: Design.fontLabel
            color: Colours.onSurfaceVariant
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        Text {
            width: parent.width
            text: "MAC " + root._macText
            font.pixelSize: Design.fontLabel
            color: Colours.onSurfaceVariant
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }
}
