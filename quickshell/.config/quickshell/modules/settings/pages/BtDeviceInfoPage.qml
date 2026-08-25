// modules/settings/pages/BtDeviceInfoPage.qml — sub-page 1 of the
// Connected devices StackPage (quick task 260825-wj2 Task 4, D-8/D-5).
// Selection-dependent: reads `sState.selectedBtDevice`, set by
// BluetoothPage's own per-row settings-gear affordance, and auto-closes if
// that selection is ever lost (the same `onXChanged` auto-close pattern
// AppInfoPage.qml already uses for `selectedApp`). Caelestia's own two
// sub-pages (BtDeviceInfo + a separate BluetoothPairing) are NOT both
// ported (D-8) — this shell's existing Bluetooth surface already does
// discovery/pairing inline, operator-verified, so only the genuinely
// missing level (device info) is built here.
import QtQuick
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Device info"
    isSubPage: true

    readonly property var device: root.sState.selectedBtDevice
    readonly property var bluetoothBackend: root.sState.bluetoothBackend

    onDeviceChanged: if (!root.device)
        root.sState.closeSubPage()

    // Small, self-contained helper — deliberately duplicated from
    // BluetoothPage.qml rather than shared (the same "two separate page
    // objects, not nested scope" reasoning AboutPage.qml's own
    // _fmtBytes/_fmtUptime duplication from SystemInfoMode.qml already
    // applies in this same quick task).
    function deviceGlyph(device) {
        var icon = device ? device.icon : "";
        switch (icon) {
        case "audio-headset":
        case "audio-headphones":
        case "audio-card":
            return "headphones";
        case "input-keyboard":
            return "keyboard";
        case "input-mouse":
            return "mouse";
        case "input-gaming":
            return "sports_esports";
        case "input-tablet":
            return "stylus";
        case "phone":
        case "phone-smartphone":
            return "smartphone";
        case "computer":
            return "computer";
        case "printer":
            return "print";
        case "camera-video":
            return "videocam";
        default:
            return "bluetooth";
        }
    }

    readonly property string _statusText: {
        if (!root.device)
            return "";
        var base = root.device.connected ? "Connected" : ((root.device.bonded || root.device.paired) ? "Paired" : "");
        if (root.device.batteryAvailable)
            base += (base.length > 0 ? " • " : "") + Math.round(root.device.battery) + "%";
        return base;
    }

    Row {
        width: parent ? parent.width : implicitWidth
        spacing: Design.spacingMd

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.settingsIconSize
            text: root.deviceGlyph(root.device)
            color: Colours.onSurfaceVariant
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            // Explicit plain-text pin (T-15-08) — a device name is
            // attacker-controllable text arriving over the air.
            textFormat: Text.PlainText
            text: root.device ? root.device.deviceName : ""
            font.pixelSize: Design.settingsFontTitle
            font.weight: Design.weightEmphasis
            color: Colours.onSurface
        }
    }

    SettingsSection {
        title: "Device"
        icon: "bluetooth"

        InfoRow {
            label: "Address"
            subtext: root.device ? root.device.address : ""
        }
        InfoRow {
            label: "Status"
            subtext: root._statusText
        }
        NavRow {
            // STATIC label (RowIndex's jump key is an exact label match) —
            // the real action verb rides as subtext instead.
            label: "Device action"
            subtext: root.bluetoothBackend && root.device ? root.bluetoothBackend.contextualVerb(root.device) : ""
            onActivated: root.bluetoothBackend && root.device && root.bluetoothBackend.pressDevice(root.device)
        }
        NavRow {
            label: "Forget this device"
            subtext: "Remove this device's pairing"
            onActivated: {
                if (root.bluetoothBackend && root.device) {
                    root.bluetoothBackend.forget(root.device);
                    root.sState.closeSubPage();
                }
            }
        }
    }
}
