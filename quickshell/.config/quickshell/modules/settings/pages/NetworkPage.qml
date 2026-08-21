// modules/settings/pages/NetworkPage.qml — page index 4 of the ten-page
// layout (quick-260821-6z1 Task 2 split, D-05/PD-02). Follow-up feature
// wave, operator request verbatim: "make wifi and bluetooth options open
// inline." Same NavRow -> real-controls transformation AudioPage.qml
// (Task 13) already received, over the shell's single WifiBackend/
// BluetoothBackend instances — threaded through
// SettingsState.wifiBackend/.bluetoothBackend the same way
// SettingsState.audioBackend already reaches AudioPage.qml. Settings.qml
// relays both from shell.qml's own wifiBackendInstance/
// bluetoothBackendInstance — the SAME instances the wifi/bluetooth
// panels already share, never a second instance.
//
// WifiPanel.qml and BluetoothPanel.qml are NOT touched by this wave —
// the Audio precedent's own rule ("AudioPanel.qml is not touched at
// all") applies here too. The one change this wave makes OUTSIDE this
// file is in shell.qml: both backends' `panelOpen` gate widens to also
// cover "the settings window is open and showing this page" (see
// shell.qml's own `settingsShowingNetwork`) — without it neither
// backend's live truth (wifi scanning, the bluetooth device model) is
// ever turned on while this page is the one actually rendering it, and
// the inline list would always read empty.
//
// Row-scoped interaction state (expandedNetwork/pendingNetwork/
// failedNetwork for Wi-Fi, expandedAddress/failedAddress for Bluetooth)
// reproduces WifiPanel.qml's/BluetoothPanel.qml's OWN shape deliberately,
// not a re-derived one: WifiPanel.qml keeps its own pendingNetwork/
// failedNetwork copies rather than binding straight to
// `backend.connectingNetwork`, because ITS OWN watchdog timer has to be
// able to resolve a stranded request independently of whatever the
// backend's separately-timed OBSERVED-truth property is doing at that
// moment — two independent timeout mechanisms, so two independent
// copies. This page copies that shape exactly, for the same reason.
//
// Deliberately NOT reproduced here — real capability gaps, not
// omissions of effort, named exactly as the panels already found them:
//   - Hidden Wi-Fi networks: `Quickshell.Networking` exposes no
//     hidden-network API at all (WifiPanel.qml's own T-15-14 header) —
//     joining one needs that file's subprocess-based SSID probe. The
//     "Advanced network settings" row below hands off to the real
//     nm-connection-editor for this case, named honestly in its subtext.
//   - Enterprise (802.1X) Wi-Fi: never connectable from ANY surface —
//     `connectWithSettings` needs a receiver `Quickshell.Networking`
//     does not expose (P2: "never offer a control that cannot work").
//     An enterprise row here shows the same static "Use Advanced to
//     connect" text WifiPanel.qml shows, for the same reason.
//
// Every row's identity is the network/device OBJECT (network) or its
// ADDRESS (bluetooth), never a name string (T-15-08) — an SSID or a
// Bluetooth device name is attacker-controllable text arriving over the
// air, and two rows can legitimately share one.
import QtQuick
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Networking
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Network"

    readonly property var wifiBackend: root.sState.wifiBackend
    readonly property var bluetoothBackend: root.sState.bluetoothBackend

    // ═══════════════════════════════════════════════════════════════════
    // Wi-Fi — mirrors WifiPanel.qml's Task 3 additions at a reduced but
    // real depth (see this file's own header for what's deliberately NOT
    // reproduced).
    // ═══════════════════════════════════════════════════════════════════
    readonly property bool wifiHardwarePresent: root.wifiBackend ? root.wifiBackend.wifiHardwareEnabled : false
    readonly property bool wifiEnabled: root.wifiBackend ? root.wifiBackend.wifiEnabled : false

    property var expandedNetwork: null
    property var pendingNetwork: null
    property var failedNetwork: null
    property string failedText: ""
    property var confirmForgetNetwork: null

    // Backend watchdog — WifiPanel.qml's own `rowWatchdogMs` value,
    // copied verbatim: a stranded pending row must not pulse forever if
    // NetworkManager never answers either way. A `Timer` `interval:`,
    // never a motion token — this is a logic timeout, not motion, and
    // would collapse to zero at the `off` motion scale if it were one.
    readonly property int rowWatchdogMs: 15000
    Timer {
        id: rowWatchdogTimer
        interval: root.rowWatchdogMs
        repeat: false
        onTriggered: root.pendingNetwork = null
    }

    function collapseExpandedRow() {
        root.expandedNetwork = null;
        root.failedNetwork = null;
        root.failedText = "";
    }

    function rowVerbLabel(network) {
        if (!network)
            return "";
        if (network.connected)
            return "Disconnect";
        if (root.wifiBackend && root.wifiBackend.securityKind(network) === "enterprise")
            return "";
        return "Connect";
    }

    function handleRowPress(network) {
        if (!network || !root.wifiBackend)
            return;
        root.confirmForgetNetwork = null;
        if (network.connected) {
            // Ordinary reversible action — deliberately not error-toned
            // (Destructive is reserved for Forget and the failed-state
            // text, never Disconnect).
            root.wifiBackend.disconnect(network);
            return;
        }
        var kind = root.wifiBackend.securityKind(network);
        if (kind === "enterprise")
            return; // P2: never offer a control that cannot work.
        if (kind === "passphrase") {
            root.expandedNetwork = network;
            root.failedNetwork = null;
            root.failedText = "";
            return;
        }
        root.startConnect(network, "");
    }

    function startConnect(network, password) {
        if (!network || !root.wifiBackend)
            return;
        root.pendingNetwork = network;
        root.failedNetwork = null;
        root.failedText = "";
        rowWatchdogTimer.restart();
        // Read at press time by the caller and handed straight through —
        // never assigned to a property on this page, never logged
        // (Prohibition P3, matching WifiBackend.qml's own connect()).
        root.wifiBackend.connect(network, password);
    }

    function handleCancel(network) {
        if (!root.wifiBackend)
            return;
        root.wifiBackend.cancelConnect(network);
        root.pendingNetwork = null;
        rowWatchdogTimer.stop();
    }

    // Success is OBSERVED truth (a row's own `connected` becoming true),
    // never the write merely returning — called from NetworkRow's own
    // `onIsConnectedNowChanged` handler below.
    function markConnectedIfPending(network) {
        if (root.pendingNetwork === network) {
            root.pendingNetwork = null;
            root.expandedNetwork = null;
            rowWatchdogTimer.stop();
        }
    }

    Connections {
        target: root.wifiBackend
        function onConnectFailed(network, reasonText) {
            var wasExpanded = (root.expandedNetwork === network);
            root.pendingNetwork = null;
            rowWatchdogTimer.stop();
            root.failedNetwork = network;
            root.failedText = reasonText;
            if (!wasExpanded && root.wifiBackend && reasonText === root.wifiBackend.failReasonText(ConnectionFailReason.NoSecrets, false))
                root.expandedNetwork = network;
        }
    }

    // Never-sorting strength glyph — WifiPanel.qml's own strengthGlyph(),
    // copied verbatim (see that file's header for the bucket reasoning:
    // opacity carries the bucket, never a second glyph name).
    function strengthGlyph(network) {
        if (!network || typeof network.signalStrength !== "number" || isNaN(network.signalStrength) || network.signalStrength < 0)
            return -1;
        var s = network.signalStrength;
        if (s < 0.34)
            return 0.45;
        if (s < 0.67)
            return 0.7;
        return 1;
    }

    // ── nm-connection-editor availability probe — PanelDialog.qml's own
    //    advancedCommand/startDetached() shape, reproduced directly
    //    (fixed literal argv, never interpolated, started once) so the
    //    hidden/enterprise-networks escape hatch works even if the wifi
    //    panel is never opened in this session. ──────────────────────────
    property bool _nmConnectionEditorAvailable: true
    Process {
        id: nmConnectionEditorProbe
        command: ["which", "nm-connection-editor"]
        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0)
                root._nmConnectionEditorAvailable = false;
        }
    }
    Process {
        id: nmConnectionEditorProcess
        command: ["nm-connection-editor"]
    }

    // ═══════════════════════════════════════════════════════════════════
    // Bluetooth — mirrors BluetoothPanel.qml's own row shape at the same
    // reduced-but-real depth as the Wi-Fi half above.
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
        nmConnectionEditorProbe.running = true;
        bluemanManagerProbe.running = true;
    }

    // ── NetworkRow — the Wi-Fi list's one row shape (current, saved and
    //    other groups all use it), condensed from WifiPanel.qml's own
    //    NetworkRow. ─────────────────────────────────────────────────────
    component NetworkRow: Item {
        id: networkRow

        property var network: null
        property bool emphasized: false

        readonly property string kind: root.wifiBackend ? root.wifiBackend.securityKind(networkRow.network) : "open"
        readonly property bool isConnectedNow: networkRow.network ? networkRow.network.connected : false
        readonly property bool isKnownNetwork: networkRow.network ? networkRow.network.known : false
        readonly property bool isExpanded: root.expandedNetwork === networkRow.network
        readonly property bool isPendingRow: root.pendingNetwork === networkRow.network
        readonly property bool isFailedRow: root.failedNetwork === networkRow.network
        readonly property bool isConfirmingForget: root.confirmForgetNetwork === networkRow.network
        readonly property bool forgetEligible: networkRow.emphasized || networkRow.isKnownNetwork

        readonly property real strengthGlyphOpacity: root.strengthGlyph(networkRow.network)
        readonly property bool hasStrength: networkRow.strengthGlyphOpacity >= 0

        width: parent ? parent.width : 0
        implicitHeight: rowColumn.implicitHeight
        height: implicitHeight

        Behavior on implicitHeight {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }

        onIsConnectedNowChanged: if (networkRow.isConnectedNow)
            root.markConnectedIfPending(networkRow.network)

        Column {
            id: rowColumn
            width: parent.width
            spacing: Design.spacingXs

            Item {
                id: collapsedRow
                width: parent.width
                height: 40

                // Emphasis is a BORDER RING, never a fill — this page's
                // own pane is `Colours.surfaceVariant` (Settings.qml's
                // `background` Rectangle), unlike the panels' own
                // `Colours.surface` pane, and a `surfaceVariant` fill on
                // a `surfaceVariant` pane is invisible by construction
                // (the exact defect class this module's own SliderRow/
                // ToggleRow/SelectRow already root-caused and fixed — see
                // 260821-6z1-SUMMARY.md).
                Rectangle {
                    anchors.fill: parent
                    radius: Design.spacingXs
                    color: "transparent"
                    border.width: networkRow.emphasized ? 2 : 0
                    border.color: Colours.primary
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.handleRowPress(networkRow.network)
                }

                Text {
                    id: strengthIcon
                    anchors.left: parent.left
                    anchors.leftMargin: Design.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    width: networkRow.hasStrength ? Design.iconSizeMd : 0
                    visible: networkRow.hasStrength
                    horizontalAlignment: Text.AlignHCenter
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.iconSizeMd
                    // "network_wifi" — the same never-swapped ligature
                    // WifiPanel.qml's own strengthGlyph() header names;
                    // opacity carries the bucket.
                    text: "network_wifi"
                    opacity: networkRow.hasStrength ? networkRow.strengthGlyphOpacity : 1
                    color: Colours.onSurfaceVariant
                }

                Text {
                    id: ssidText
                    anchors.left: strengthIcon.right
                    anchors.leftMargin: Design.spacingSm
                    anchors.right: trailingActions.left
                    anchors.rightMargin: Design.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    // Explicit plain-text pin (T-19-26) — an SSID is
                    // attacker-controllable text arriving over the air.
                    textFormat: Text.PlainText
                    text: networkRow.network ? networkRow.network.name : ""
                    font.pixelSize: Design.fontBody
                    color: Colours.onSurface

                    HoverHandler {
                        id: ssidHover
                    }
                    ThemedToolTip {
                        visible: ssidHover.hovered
                        text: ssidText.text
                    }
                }

                Row {
                    id: trailingActions
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Design.spacingSm

                    Row {
                        spacing: Design.spacingSm
                        visible: networkRow.kind !== "enterprise"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: networkRow.isPendingRow
                            font.family: Design.symbolFontFamily
                            font.pixelSize: Design.iconSizeMd
                            text: "progress_activity"
                            color: Colours.primary
                            opacity: 0.7

                            RotationAnimation on rotation {
                                running: networkRow.isPendingRow && Motion.motionEnabled
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: Motion.ambientDuration
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !networkRow.isPendingRow
                            text: root.rowVerbLabel(networkRow.network)
                            font.pixelSize: Design.fontBody
                            color: Colours.primary

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.handleRowPress(networkRow.network)
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: networkRow.isPendingRow
                            text: "Cancel"
                            font.pixelSize: Design.fontBody
                            color: Colours.onSurfaceVariant

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.handleCancel(networkRow.network)
                            }
                        }
                    }

                    Text {
                        visible: networkRow.forgetEligible
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Forget"
                        font.pixelSize: Design.fontBody
                        color: Colours.error

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.expandedNetwork = null;
                                root.confirmForgetNetwork = networkRow.network;
                            }
                        }
                    }
                }
            }

            // Enterprise — no field is offered because none could work
            // (P2). Static, never expands; the row's own press does
            // nothing (handleRowPress() early-returns above).
            Text {
                width: parent.width
                visible: networkRow.kind === "enterprise"
                text: "Use Advanced to connect"
                font.pixelSize: Design.fontLabel
                color: Colours.onSurfaceVariant
            }

            // Inline password row — no popup, no dialog, the row itself
            // grows.
            Row {
                width: parent.width
                spacing: Design.spacingSm
                visible: networkRow.isExpanded

                TextField {
                    id: passwordField
                    width: parent.width - connectAction.width - Design.spacingSm
                    height: 36
                    echoMode: TextInput.Password
                    color: Colours.onSurface
                    // Border added — WITHOUT it this fill is the exact
                    // `surfaceVariant`-on-`surfaceVariant` invisible-pill
                    // defect this module's live-pass history already
                    // found four times (SelectRow's dropdown pill,
                    // ToggleRow's switch pill, and others) — the SAME
                    // `Colours.surfaceVariant` fill WifiPanel.qml's own
                    // passwordField uses is safe THERE only because that
                    // panel's own pane is `Colours.surface`, not
                    // `surfaceVariant`.
                    background: Rectangle {
                        radius: Design.spacingXs
                        color: Colours.surfaceVariant
                        border.width: 1
                        border.color: Colours.outline
                    }
                    // First stage of two-stage Escape, mirroring
                    // WifiPanel.qml's own passwordField — consumed here
                    // so the event never reaches the page's own Escape
                    // handling and closes the whole settings window.
                    Keys.onEscapePressed: function (event) {
                        root.collapseExpandedRow();
                        event.accepted = true;
                    }
                    onVisibleChanged: if (passwordField.visible)
                        passwordField.forceActiveFocus()
                }

                Item {
                    id: connectAction
                    width: connectLabel.implicitWidth + Design.spacingMd * 2
                    height: 36

                    readonly property bool enabledNow: passwordField.text.length > 0

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Colours.primary
                        opacity: connectAction.enabledNow ? 1 : 0.38
                    }
                    Text {
                        id: connectLabel
                        anchors.centerIn: parent
                        text: "Connect"
                        font.pixelSize: Design.fontBody
                        color: Colours.onPrimary
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: connectAction.enabledNow
                        onClicked: {
                            // Read at press time and discarded — never
                            // assigned to a property on this page, never
                            // logged (Prohibition P3).
                            var enteredPassword = passwordField.text;
                            passwordField.text = "";
                            root.startConnect(networkRow.network, enteredPassword);
                        }
                    }
                }
            }

            // Row-scoped failure — renders whether or not the password
            // row is expanded; the field (if open) stays open and empty
            // for the correction.
            Text {
                width: parent.width
                visible: networkRow.isFailedRow
                text: root.failedText
                font.pixelSize: Design.fontLabel
                color: Colours.error
            }

            // Forget's inline confirm — never a silent one-press forget.
            Row {
                width: parent.width
                visible: networkRow.isConfirmingForget
                spacing: Design.spacingSm

                Text {
                    width: parent.width - forgetYes.implicitWidth - forgetNo.implicitWidth - Design.spacingSm * 2
                    // Explicit plain-text pin — the SSID embedded in this
                    // confirm string is the same over-the-air value as
                    // `ssidText` above.
                    textFormat: Text.PlainText
                    text: "Forget " + (networkRow.network ? networkRow.network.name : "") + "?"
                    font.pixelSize: Design.fontLabel
                    color: Colours.onSurface
                    wrapMode: Text.WordWrap
                }
                Text {
                    id: forgetYes
                    text: "Forget"
                    font.pixelSize: Design.fontLabel
                    font.weight: Design.weightEmphasis
                    color: Colours.error

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.wifiBackend.forget(networkRow.network);
                            root.confirmForgetNetwork = null;
                        }
                    }
                }
                Text {
                    id: forgetNo
                    text: "Cancel"
                    font.pixelSize: Design.fontLabel
                    color: Colours.onSurfaceVariant

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.confirmForgetNetwork = null
                    }
                }
            }
        }
    }

    // ── DeviceRow — the Bluetooth list's one row shape, condensed from
    //    BluetoothPanel.qml's own DeviceRow. Row identity is the
    //    device's ADDRESS (T-15-08), never its name. ──────────────────────
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

        Behavior on implicitHeight {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
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

                // Same border-ring-not-fill discipline as NetworkRow
                // above, same reason.
                Rectangle {
                    anchors.fill: parent
                    radius: Design.spacingXs
                    color: "transparent"
                    border.width: deviceRow.isConnectedNow ? 2 : 0
                    border.color: Colours.primary
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: chevronArea.width
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
                    font.pixelSize: Design.fontBody
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
                    anchors.right: chevronArea.left
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
                            font.pixelSize: Design.fontBody
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
                            font.pixelSize: Design.fontBody
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
                            font.pixelSize: Design.fontLabel
                            color: Colours.error
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Retry"
                            font.pixelSize: Design.fontBody
                            color: Colours.primary

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.handleBtRowPress(deviceRow.device)
                            }
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
                    font.pixelSize: Design.fontLabel
                    color: Colours.onSurfaceVariant
                }
                Text {
                    // Explicit plain-text pin (T-15-08) — the MAC
                    // address is over-the-air text like the name above.
                    textFormat: Text.PlainText
                    text: deviceRow.device ? deviceRow.device.address : ""
                    font.pixelSize: Design.fontLabel
                    color: Colours.onSurfaceVariant
                }

                Row {
                    visible: !deviceRow.isConfirmingForget
                    Text {
                        text: "Forget"
                        font.pixelSize: Design.fontLabel
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
                        font.pixelSize: Design.fontLabel
                        color: Colours.onSurface
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        id: btForgetYes
                        text: "Forget"
                        font.pixelSize: Design.fontLabel
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
                        font.pixelSize: Design.fontLabel
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
        title: "Wi-Fi"
        icon: "wifi"

        ToggleRow {
            label: "Wi-Fi"
            visible: root.wifiHardwarePresent
            subtext: root.wifiEnabled ? "On — scanning for nearby networks" : "Off"
            checked: root.wifiEnabled
            onToggled: (value) => root.wifiBackend && root.wifiBackend.setWifiEnabled(value)
        }
        InfoRow {
            visible: !root.wifiHardwarePresent
            label: "Wi-Fi hardware is off"
            subtext: "This device's Wi-Fi radio is switched off (airplane mode or a hardware switch) and can't be turned back on from here."
        }
        InfoRow {
            visible: root.wifiHardwarePresent && !root.wifiEnabled
            label: "Turn on Wi-Fi to see nearby networks"
            subtext: "Networks appear here once Wi-Fi is on."
        }

        Column {
            width: parent.width
            spacing: Design.spacingXs
            visible: root.wifiHardwarePresent && root.wifiEnabled

            // Level, not edge (WifiBackend.qml's own `scanning` header):
            // true for this page's whole time with the radio's scanner
            // armed, not a per-cycle pulse.
            Row {
                width: parent.width
                spacing: Design.spacingXs
                visible: root.wifiBackend && root.wifiBackend.scanning

                Text {
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.fontLabel
                    text: "sync"
                    color: Colours.onSurfaceVariant

                    RotationAnimation on rotation {
                        running: root.wifiBackend && root.wifiBackend.scanning && Motion.motionEnabled
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: Motion.ambientDuration
                    }
                }
                Text {
                    text: "Scanning for networks…"
                    font.pixelSize: Design.fontLabel
                    color: Colours.onSurfaceVariant
                }
            }

            Repeater {
                model: (root.wifiBackend && root.wifiBackend.currentNetwork) ? [root.wifiBackend.currentNetwork] : []
                delegate: NetworkRow {
                    network: modelData
                    emphasized: true
                }
            }
            Repeater {
                model: root.wifiBackend ? root.wifiBackend.savedNetworks : []
                delegate: NetworkRow {
                    network: modelData
                }
            }
            Repeater {
                model: root.wifiBackend ? root.wifiBackend.otherNetworks : []
                delegate: NetworkRow {
                    network: modelData
                }
            }

            Text {
                visible: root.wifiBackend
                    ? (root.wifiBackend.wifiDevice !== null && !root.wifiBackend.currentNetwork && root.wifiBackend.savedNetworks.length === 0 && root.wifiBackend.otherNetworks.length === 0 && !root.wifiBackend.scanning)
                    : false
                text: "No networks found yet"
                font.pixelSize: Design.fontBody
                color: Colours.onSurfaceVariant
            }
        }

        NavRow {
            label: "Advanced network settings"
            subtext: root._nmConnectionEditorAvailable
                ? "Hidden networks and workplace (802.1X) logins need the full network editor."
                : "nm-connection-editor is not installed — hidden and workplace networks can't be reached from here."
            onActivated: if (root._nmConnectionEditorAvailable)
                nmConnectionEditorProcess.startDetached()
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
                font.pixelSize: Design.fontBody
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
                    font.pixelSize: Design.fontBody
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
                    font.pixelSize: Design.fontLabel
                    color: Colours.onSurfaceVariant
                }
                Text {
                    visible: root.bluetoothBackend ? root.bluetoothBackend.discovering : false
                    text: "Stop"
                    font.pixelSize: Design.fontLabel
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
