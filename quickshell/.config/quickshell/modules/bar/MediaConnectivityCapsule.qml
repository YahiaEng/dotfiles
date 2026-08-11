// MediaConnectivityCapsule.qml — the media + connectivity slot (Phase 18
// Plan 05, D-18-10). Filled by Phase 18 Plan 08 (QBAR-06).
//
// QBAR-06's connectivity and now-playing readout surface. Four of its five
// entries read handles `BarCapsule` already carries (`mediaBackend`,
// `audioBackend`, `wifiBackend`, `bluetoothBackend`); the fifth (battery)
// reads the native `Quickshell.Services.UPower` singleton directly — no new
// service connection, since `SystemResources.qml` already imports the same
// module elsewhere in this process. This file contains the only unbounded
// string on the entire bar surface (the media track title).
//
// The network and bluetooth entries deliberately read ONLY properties that
// are live without a scan or a discovery sweep, so nothing in this file can
// widen either of those two backends' gates:
//   - network reads `wifiBackend.wifiHardwareEnabled`, `.wifiEnabled`,
//     `.wifiDevice` and the resolved device's OWN `connected` flag — never
//     `currentNetwork` for the connected/disconnected decision (that comes
//     from `seenOrder`, which only populates from a scan). `currentNetwork`
//     is read ONLY to grade an already-connected glyph's opacity by signal
//     strength when it happens to be non-null, exactly WifiPanel.qml's own
//     `strengthGlyph()` idiom (modulate a proven glyph's opacity rather
//     than risk an unverified per-bar-count ligature name).
//   - bluetooth reads `adapterPresent`, `adapterBlocked`, `adapterEnabled`
//     and `connectedDevices.length` — never the sweep-in-progress flag and
//     never either of the two sweep-control methods (named in
//     BluetoothBackend.qml, deliberately not repeated here, since this
//     file is gated on those identifiers being absent from it entirely).
// D-15-15/D-15-18 forbid running either backend's scan/discovery path
// always-on; a later reader adding a signal-strength arc or a
// nearby-network count from a NEW ungated property would be crossing
// exactly the line those decisions draw. Don't.
import QtQuick
import Quickshell.Services.UPower
import "../"
import "../dashboard"

BarCapsule {
    id: root

    capsuleId: "mediaConnectivity"

    // ── The one reusable readout element — same visual language as
    //    SystemCapsule.qml's own Readout: glyph + Design.spacingXs gap +
    //    right-aligned reserved-width value, one bound Grid for the
    //    orientation swap. Declared once here (a second, textually
    //    identical declaration, since QML has no cross-file component
    //    import for an unregistered inline type) and instantiated five
    //    times below — `showValue: false` is what makes network and
    //    bluetooth render glyph-only with zero reserved value width.
    //    `maxWidthVertical` is the one addition SystemCapsule.qml's
    //    element does not need: only the media title requires a SECOND,
    //    narrower width cap in the 44px vertical column — every other
    //    entry's value is already short enough to fit both orientations
    //    at its normal worst-case reservation. ─────────────────────────
    component Readout: Item {
        id: readoutItem

        property string glyph: ""
        property string valueText: ""
        property string maxValueText: ""
        property bool showValue: true
        property bool populated: true
        property bool errored: false
        property bool elideValue: false
        // -1 means "no vertical-specific cap" (the normal case).
        property real maxWidthVertical: -1

        readonly property bool vertical: root.vertical

        implicitWidth: entryGrid.implicitWidth
        implicitHeight: entryGrid.implicitHeight

        TextMetrics {
            id: valueReserve
            font.pixelSize: Design.fontLabel
            font.weight: Design.weightBody
            text: readoutItem.maxValueText
        }

        Grid {
            id: entryGrid
            rows: readoutItem.vertical ? -1 : 1
            columns: readoutItem.vertical ? 1 : -1
            spacing: Design.spacingXs

            Text {
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                text: readoutItem.glyph
                color: readoutItem.errored ? Colours.error : root.contentColour
            }

            Text {
                visible: readoutItem.showValue
                font.pixelSize: Design.fontLabel
                font.weight: Design.weightBody
                color: root.contentColour
                horizontalAlignment: Text.AlignRight
                elide: readoutItem.elideValue ? Text.ElideRight : Text.ElideNone
                width: readoutItem.showValue
                    ? (readoutItem.vertical && readoutItem.maxWidthVertical >= 0
                        ? Math.min(valueReserve.width, readoutItem.maxWidthVertical)
                        : valueReserve.width)
                    : 0
                text: readoutItem.populated ? readoutItem.valueText : "—"
            }
        }
    }

    // ── media ────────────────────────────────────────────────────────────
    // Visible only when a player exists — contributes zero extent and zero
    // spacing otherwise (BarCapsule's own Grid positioner drops a
    // non-visible child's spacing for free). Third-party D-Bus text: a
    // plain `Text` whose `textFormat` is never assigned any rich or markup
    // format, capped at `Design.mediaTitleMaxChars` and elided right — the
    // ONE named truncation exception on the whole bar, legitimate ONLY
    // here because the full title already lives in the media popout
    // (18-14). The capsule's worst-case width is reserved from the CAP,
    // never from the current title, so a long title cannot push the clock
    // or tray sideways.
    readonly property string mediaTitleRaw: root.mediaBackend ? root.mediaBackend.displayTitle : ""
    readonly property string mediaTitleCapped: root.mediaTitleRaw.length > Design.mediaTitleMaxChars
        ? root.mediaTitleRaw.slice(0, Design.mediaTitleMaxChars)
        : root.mediaTitleRaw

    Readout {
        visible: root.mediaBackend ? root.mediaBackend.hasPlayer : false
        glyph: "music_note"
        maxValueText: "M".repeat(Design.mediaTitleMaxChars)
        maxWidthVertical: Design.barColumnWidth
        elideValue: true
        populated: true
        valueText: root.mediaTitleCapped
    }

    // ── audio ────────────────────────────────────────────────────────────
    readonly property bool audioMuted: root.audioBackend ? root.audioBackend.masterMuted : false
    readonly property real audioVolume: root.audioBackend ? root.audioBackend.masterVolume : 0
    readonly property bool audioReady: root.audioBackend ? root.audioBackend.pipewireReady : false

    Readout {
        glyph: root.audioMuted ? "volume_off" : "volume_up"
        maxValueText: "100%"
        populated: root.audioReady
        valueText: root.audioReady ? Math.round(Math.max(0, Math.min(1, root.audioVolume)) * 100) + "%" : ""
    }

    // ── network ──────────────────────────────────────────────────────────
    // Glyph only, no value text, ever. Precedence: hardware radio blocked;
    // radio off; device unresolved-or-on-but-disconnected (the same glyph
    // for both — the pointer's own header comment records it "can take a
    // moment to resolve after startup", and an unresolved device reads to
    // the user exactly like "no connection yet", which is honest rather
    // than inventing an unverified fourth glyph for a transient window);
    // connected. The connected glyph is graded by opacity only when
    // `currentNetwork` happens to be non-null (scan-derived), falling back
    // to full opacity when it is null — correct with no scan ever run,
    // merely prettier after one.
    readonly property bool wifiHwEnabled: root.wifiBackend ? root.wifiBackend.wifiHardwareEnabled : false
    readonly property bool wifiEnabled: root.wifiBackend ? root.wifiBackend.wifiEnabled : false
    readonly property var wifiDevice: root.wifiBackend ? root.wifiBackend.wifiDevice : null
    readonly property bool wifiDeviceConnected: root.wifiDevice ? root.wifiDevice.connected === true : false
    readonly property var wifiCurrentNetwork: root.wifiBackend ? root.wifiBackend.currentNetwork : null

    readonly property string networkGlyph: {
        if (!root.wifiHwEnabled)
            return "wifi_off";
        if (!root.wifiEnabled)
            return "wifi_off";
        if (!root.wifiDeviceConnected)
            return "signal_wifi_statusbar_null";
        return "network_wifi";
    }

    // Never sorts, never starts a scan: a plain opacity bucket over a
    // value that is either already there (`currentNetwork` populated by a
    // PAST scan, if any) or absent. Same three-bucket thresholds
    // WifiPanel.qml's own `strengthGlyph()` uses, spanning the full
    // theoretical 0.0-1.0 signalStrength domain.
    readonly property real networkOpacity: {
        if (!root.wifiDeviceConnected)
            return 1;
        const net = root.wifiCurrentNetwork;
        if (!net || typeof net.signalStrength !== "number" || isNaN(net.signalStrength) || net.signalStrength < 0)
            return 1;
        const s = net.signalStrength;
        if (s < 0.34)
            return 0.45;
        if (s < 0.67)
            return 0.7;
        return 1;
    }

    Readout {
        glyph: root.networkGlyph
        showValue: false
        opacity: root.networkOpacity
    }

    // ── bluetooth ────────────────────────────────────────────────────────
    // Glyph only. No adapter, a blocked adapter and a present-but-off
    // adapter all render the SAME glyph — BluetoothPanel.qml's own three
    // branches (no-adapter/blocked/off) already do exactly this,
    // differentiated only by TEXT the panel shows and this capsule does
    // not carry; the reason-level distinction belongs to the bluetooth
    // popout (18-14), matching that established precedent rather than
    // inventing a fourth bluetooth-prefixed glyph this font does not ship.
    readonly property bool btPresent: root.bluetoothBackend ? root.bluetoothBackend.adapterPresent : false
    readonly property bool btBlocked: root.bluetoothBackend ? root.bluetoothBackend.adapterBlocked : false
    readonly property bool btEnabled: root.bluetoothBackend ? root.bluetoothBackend.adapterEnabled : false
    readonly property int btConnectedCount: root.bluetoothBackend ? root.bluetoothBackend.connectedDevices.length : 0

    readonly property string bluetoothGlyph: {
        if (!root.btPresent)
            return "bluetooth_disabled";
        if (root.btBlocked)
            return "bluetooth_disabled";
        if (!root.btEnabled)
            return "bluetooth_disabled";
        return root.btConnectedCount > 0 ? "bluetooth_connected" : "bluetooth";
    }

    Readout {
        glyph: root.bluetoothGlyph
        showValue: false
    }

    // ── battery ──────────────────────────────────────────────────────────
    // Visible only when the native power singleton's display device is
    // non-null AND reports itself present — D-18-06 read literally. On
    // this host that condition is false and the entry contributes zero
    // extent and zero spacing. No new service connection: `UPower` is
    // already imported by `SystemResources.qml` elsewhere in this process.
    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool batteryPresent: root.batteryDevice !== null
        && root.batteryDevice !== undefined
        && root.batteryDevice.isPresent === true

    readonly property string batteryGlyph: {
        if (!root.batteryPresent)
            return "";
        if (root.batteryDevice.state === UPowerDeviceState.Charging)
            return "battery_charging_full";
        if (root.batteryDevice.percentage <= 15)
            return "battery_alert";
        return "battery_full";
    }

    // Same above-1-is-a-percentage / at-or-below-1-is-a-fraction guard
    // SystemResources.qml's own `batteryFraction` uses, for the same
    // documented reason: the service's own docs never state the range.
    function batteryPercentValue() {
        if (!root.batteryPresent)
            return 0;
        const raw = root.batteryDevice.percentage;
        if (!isFinite(raw) || raw < 0)
            return 0;
        const frac = raw > 1 ? Math.min(1, raw / 100) : Math.min(1, raw);
        return Math.round(frac * 100);
    }

    Readout {
        visible: root.batteryPresent
        glyph: root.batteryGlyph
        maxValueText: "100%"
        populated: true
        valueText: root.batteryPercentValue() + "%"
    }
}
