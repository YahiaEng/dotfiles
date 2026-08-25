// modules/settings/pages/BluetoothPage.qml — page index 5, "Connected
// devices" (quick task 260825-wj2 Task 4, D-8). Split out of
// NetworkPage.qml's own Bluetooth half — moved verbatim, not rewritten:
// the page-level state/helpers, `component DeviceRow`, and the whole
// `SettingsSection { title: "Bluetooth" }` all carry over byte-for-byte
// from NetworkPage.qml (quick-260821-6z1 Task 2/fix wave), with only the
// enclosing `root` changed and one addition — a settings-gear affordance
// per row that opens `BtDeviceInfoPage.qml` (D-8's genuinely-missing
// level; the existing inline discovery/pairing surface below is NOT
// duplicated, D-8).
//
// `bluetoothBackend` reaches here the same way `wifiBackend`/
// `audioBackend` reach their own pages: `SettingsState.bluetoothBackend`,
// relayed from `shell.qml`'s own `bluetoothBackendInstance` — the SAME
// instance the bar's connectivity capsule and dashboard panel already
// share, never a second one. `shell.qml` widens
// `bluetoothBackendInstance.panelOpen` to also cover "this page is open",
// mirroring `settingsShowingNetwork`'s own gate — without it this page's
// device list renders permanently empty (see shell.qml's own comment
// block at the gate).
import QtQuick
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Connected devices"

    readonly property var bluetoothBackend: root.sState.bluetoothBackend

    // ═══════════════════════════════════════════════════════════════════
    // Bluetooth — mirrors BluetoothPanel.qml's own row shape at the same
    // reduced-but-real depth NetworkPage.qml originally carried this at.
    // ═══════════════════════════════════════════════════════════════════
    readonly property bool adapterPresent: root.bluetoothBackend ? root.bluetoothBackend.adapterPresent : false
    readonly property bool adapterBlocked: root.bluetoothBackend ? root.bluetoothBackend.adapterBlocked : false
    readonly property bool adapterEnabled: root.bluetoothBackend ? root.bluetoothBackend.adapterEnabled : false

    property string expandedAddress: ""
    property string confirmingForgetAddress: ""
    property string failedAddress: ""
    property string failedReason: ""

    // Routed through here rather than straight to `backend.pressDevice` —
    // clearing this row's own failure slot the moment a NEW action starts
    // on it is what keeps a stale "Couldn't pair" from lingering under a
    // fresh spinner (BluetoothPanel.qml's own handleRowPress()).
    function handleBtRowPress(device) {
        if (!device || !root.bluetoothBackend)
            return;
        root.failedAddress = "";
        root.failedReason = "";
        root.bluetoothBackend.pressDevice(device);
    }

    // BlueZ icon class used only as a lookup key, never rendered directly
    // (T-15-08) — BluetoothPanel.qml's own deviceGlyph(), copied verbatim.
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

    Connections {
        target: root.bluetoothBackend
        function onDeviceActionFailed(device, reasonText) {
            root.failedAddress = device ? device.address : "";
            root.failedReason = reasonText;
        }
    }

    property bool _bluemanManagerAvailable: true
    Process {
        id: bluemanManagerProbe
        command: ["which", "blueman-manager"]
        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0)
                root._bluemanManagerAvailable = false;
        }
    }
    Process {
        id: bluemanManagerProcess
        command: ["blueman-manager"]
    }

    Component.onCompleted: {
        bluemanManagerProbe.running = true;
    }

    // ── DeviceRow — NetworkPage.qml's own row shape, moved verbatim, plus
    //    ONE addition: a settings-gear affordance (D-8) beside the existing
    //    expand/collapse chevron, opening BtDeviceInfoPage — the reference's
    //    own `BluetoothPage.qml:153` idiom (`root.nState.selectedBtDevice =
    //    …; root.nState.openSubPage(1)`), translated onto this page's own
    //    `sState`. ─────────────────────────────────────────────────────────
    component DeviceRow: Item {
        id: deviceRow

        property var device: null

        readonly property string address: deviceRow.device ? deviceRow.device.address : ""
        readonly property string verb: (root.bluetoothBackend && deviceRow.device) ? root.bluetoothBackend.contextualVerb(deviceRow.device) : ""
        readonly property bool isPending: deviceRow.address !== "" && root.bluetoothBackend && root.bluetoothBackend.pendingAddress === deviceRow.address
        readonly property bool isPendingPair: deviceRow.isPending && root.bluetoothBackend.pendingVerb === "pair"
        readonly property bool isFailed: deviceRow.address !== "" && root.failedAddress === deviceRow.address
        readonly property bool isExpanded: deviceRow.address !== "" && root.expandedAddress === deviceRow.address
        readonly property bool isConfirmingForget: deviceRow.address !== "" && root.confirmingForgetAddress === deviceRow.address
        readonly property bool isConnectedNow: deviceRow.device ? deviceRow.device.connected : false
        readonly property bool batteryAvailable: deviceRow.device ? deviceRow.device.batteryAvailable : false

        width: parent ? parent.width : 0
        implicitHeight: rowColumn.implicitHeight
        height: implicitHeight

        // quick-260821-swp (R-2): implicitHeight is spatial — retargeted
        // onto spatial-move.
        Behavior on implicitHeight {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.spatialMoveDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.spatialMoveEasing
            }
        }

        Column {
            id: rowColumn
            width: parent.width
            spacing: Design.spacingXs

            Item {
                id: collapsedBtRow
                width: parent.width
                height: 40

                // Same border-ring-not-fill discipline as NetworkPage's own
                // NetworkRow, same reason.
                Rectangle {
                    anchors.fill: parent
                    radius: Design.spacingXs
                    color: "transparent"
                    border.width: deviceRow.isConnectedNow ? 2 : 0
                    border.color: Colours.primary
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: infoButton.width + chevronArea.width
                    onClicked: root.handleBtRowPress(deviceRow.device)
                }

                Text {
                    id: btGlyph
                    anchors.left: parent.left
                    anchors.leftMargin: Design.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.iconSizeMd
                    text: root.deviceGlyph(deviceRow.device)
                    color: Colours.onSurfaceVariant
                }

                Text {
                    id: btNameText
                    anchors.left: btGlyph.right
                    anchors.leftMargin: Design.spacingSm
                    anchors.right: btTrailing.left
                    anchors.rightMargin: Design.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    // Explicit plain-text pin (T-15-08) — a device name
                    // is attacker-controllable text arriving over the air.
                    textFormat: Text.PlainText
                    text: deviceRow.device ? deviceRow.device.deviceName : ""
                    font.pixelSize: Design.settingsFontRow
                    color: Colours.onSurface

                    HoverHandler {
                        id: btNameHover
                    }
                    ThemedToolTip {
                        visible: btNameHover.hovered
                        text: btNameText.text
                    }
                }

                Row {
                    id: btTrailing
                    anchors.right: infoButton.left
                    anchors.rightMargin: Design.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Design.spacingSm

                    Row {
                        spacing: Design.spacingSm
                        visible: !deviceRow.isFailed

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: deviceRow.isPending
                            font.family: Design.symbolFontFamily
                            font.pixelSize: Design.iconSizeMd
                            text: "progress_activity"
                            color: Colours.primary
                            opacity: 0.7

                            RotationAnimation on rotation {
                                running: deviceRow.isPending && Motion.motionEnabled
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: Motion.ambientDuration
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !deviceRow.isPending
                            text: deviceRow.verb === "pair" ? "Pair" : deviceRow.verb === "connect" ? "Connect" : deviceRow.verb === "disconnect" ? "Disconnect" : ""
                            font.pixelSize: Design.settingsFontRow
                            color: Colours.primary

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.handleBtRowPress(deviceRow.device)
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: deviceRow.isPendingPair
                            text: "Cancel"
                            font.pixelSize: Design.settingsFontRow
                            color: Colours.onSurfaceVariant

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.bluetoothBackend && root.bluetoothBackend.cancelPair(deviceRow.device)
                            }
                        }
                    }

                    // *Failed* — scoped to this row only, with an
                    // explicit Retry (G-15-8's own addition): the row
                    // stays pressable and `handleBtRowPress()` already
                    // clears this row's failure slot before re-invoking,
                    // matching BluetoothPanel.qml's own failedRow.
                    Row {
                        visible: deviceRow.isFailed
                        spacing: Design.spacingSm

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: 140
                            horizontalAlignment: Text.AlignRight
                            text: root.failedReason
                            font.pixelSize: Design.settingsFontSub
                            color: Colours.error
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Retry"
                            font.pixelSize: Design.settingsFontRow
                            color: Colours.primary

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.handleBtRowPress(deviceRow.device)
                            }
                        }
                    }
                }

                // Device info affordance (D-8) — sets the selection then
                // opens the sub-page, the reference's own
                // `BluetoothPage.qml:153` idiom.
                Item {
                    id: infoButton
                    anchors.right: chevronArea.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Design.iconSizeMd + Design.spacingSm
                    height: parent.height
                    visible: deviceRow.device !== null

                    Text {
                        anchors.centerIn: parent
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        text: "settings"
                        color: infoHover.hovered ? Colours.primary : Colours.onSurfaceVariant
                    }
                    HoverHandler {
                        id: infoHover
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.sState.selectedBtDevice = deviceRow.device;
                            root.sState.openSubPage(1);
                        }
                    }
                }

                Item {
                    id: chevronArea
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Design.iconSizeMd + Design.spacingSm
                    height: parent.height

                    Text {
                        anchors.centerIn: parent
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        text: deviceRow.isExpanded ? "expand_less" : "expand_more"
                        color: Colours.onSurfaceVariant
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.expandedAddress = deviceRow.isExpanded ? "" : deviceRow.address;
                            root.confirmingForgetAddress = "";
                        }
                    }
                }
            }

            // Expansion — battery (only when available), address, and a
            // separated Forget. Renders in place, below the row, inside
            // this page's own scroll body — no popup of any kind.
            Column {
                width: parent.width
                spacing: Design.spacingXs
                visible: deviceRow.isExpanded

                Text {
                    visible: deviceRow.batteryAvailable
                    text: deviceRow.device ? "Battery " + Math.round(deviceRow.device.battery) + "%" : ""
                    font.pixelSize: Design.settingsFontSub
                    color: Colours.onSurfaceVariant
                }
                Text {
                    // Explicit plain-text pin (T-15-08) — the MAC
                    // address is over-the-air text like the name above.
                    textFormat: Text.PlainText
                    text: deviceRow.device ? deviceRow.device.address : ""
                    font.pixelSize: Design.settingsFontSub
                    color: Colours.onSurfaceVariant
                }

                Row {
                    visible: !deviceRow.isConfirmingForget
                    Text {
                        text: "Forget"
                        font.pixelSize: Design.settingsFontSub
                        color: Colours.error

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.confirmingForgetAddress = deviceRow.address
                        }
                    }
                }
                Row {
                    visible: deviceRow.isConfirmingForget
                    spacing: Design.spacingSm

                    Text {
                        width: parent.width - btForgetYes.implicitWidth - btForgetNo.implicitWidth - Design.spacingSm * 2
                        textFormat: Text.PlainText
                        text: "Forget " + (deviceRow.device ? deviceRow.device.deviceName : "") + "?"
                        font.pixelSize: Design.settingsFontSub
                        color: Colours.onSurface
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        id: btForgetYes
                        text: "Forget"
                        font.pixelSize: Design.settingsFontSub
                        font.weight: Design.weightEmphasis
                        color: Colours.error

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.bluetoothBackend.forget(deviceRow.device);
                                root.confirmingForgetAddress = "";
                            }
                        }
                    }
                    Text {
                        id: btForgetNo
                        text: "Cancel"
                        font.pixelSize: Design.settingsFontSub
                        color: Colours.onSurfaceVariant

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.confirmingForgetAddress = ""
                        }
                    }
                }
            }
        }
    }

    SettingsSection {
        title: "Bluetooth"
        icon: "bluetooth"

        ToggleRow {
            label: "Bluetooth"
            visible: root.adapterPresent && !root.adapterBlocked
            subtext: root.adapterEnabled ? "On" : "Off"
            checked: root.adapterEnabled
            onToggled: (value) => root.bluetoothBackend && root.bluetoothBackend.setAdapterEnabled(value)
        }
        InfoRow {
            visible: !root.adapterPresent
            label: "No Bluetooth adapter found"
            subtext: "This machine has no Bluetooth controller Quickshell can see."
        }
        InfoRow {
            visible: root.adapterPresent && root.adapterBlocked
            label: "Bluetooth is blocked"
            subtext: "Switched off by rfkill (a hardware or software block) — run \"rfkill unblock bluetooth\" in a terminal, or check for a physical switch, then reopen this page."
        }
        InfoRow {
            visible: root.adapterPresent && !root.adapterBlocked && !root.adapterEnabled
            label: "Turn on Bluetooth to manage devices"
            subtext: "Paired and nearby devices appear here once Bluetooth is on."
        }

        Column {
            width: parent.width
            spacing: Design.spacingXs
            visible: root.adapterPresent && !root.adapterBlocked && root.adapterEnabled

            Repeater {
                model: root.bluetoothBackend ? root.bluetoothBackend.connectedDevices : []
                delegate: DeviceRow {
                    device: modelData
                }
            }
            Repeater {
                model: root.bluetoothBackend ? root.bluetoothBackend.pairedDevices : []
                delegate: DeviceRow {
                    device: modelData
                }
            }
            Repeater {
                model: root.bluetoothBackend ? root.bluetoothBackend.discoveredDevices : []
                delegate: DeviceRow {
                    device: modelData
                }
            }

            Text {
                visible: root.bluetoothBackend
                    ? (root.bluetoothBackend.connectedDevices.length === 0 && root.bluetoothBackend.pairedDevices.length === 0 && root.bluetoothBackend.discoveredDevices.length === 0 && !root.bluetoothBackend.discovering)
                    : false
                text: "No paired devices"
                font.pixelSize: Design.settingsFontRow
                color: Colours.onSurfaceVariant
            }

            Row {
                width: parent.width
                spacing: Design.spacingSm

                // The ONLY call site of `startDiscovery()` on this page,
                // matching BluetoothPanel.qml's own single-call-site
                // discipline.
                Text {
                    visible: !(root.bluetoothBackend && root.bluetoothBackend.discovering)
                    text: "Add device"
                    font.pixelSize: Design.settingsFontRow
                    font.weight: Design.weightEmphasis
                    color: Colours.primary

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.bluetoothBackend && root.bluetoothBackend.startDiscovery()
                    }
                }
                Text {
                    visible: root.bluetoothBackend ? root.bluetoothBackend.discovering : false
                    text: "Searching for devices…"
                    font.pixelSize: Design.settingsFontSub
                    color: Colours.onSurfaceVariant
                }
                Text {
                    visible: root.bluetoothBackend ? root.bluetoothBackend.discovering : false
                    text: "Stop"
                    font.pixelSize: Design.settingsFontSub
                    color: Colours.onSurfaceVariant

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.bluetoothBackend && root.bluetoothBackend.stopDiscovery()
                    }
                }
            }
        }

        NavRow {
            label: "Advanced Bluetooth settings"
            subtext: root._bluemanManagerAvailable
                ? "Opens the full Bluetooth manager for less common options."
                : "blueman-manager is not installed."
            onActivated: if (root._bluemanManagerAvailable)
                bluemanManagerProcess.startDetached()
        }
    }
}
