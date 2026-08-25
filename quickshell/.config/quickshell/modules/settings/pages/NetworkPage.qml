// modules/settings/pages/NetworkPage.qml — page index 4 of the settings
// layout (quick-260821-6z1 Task 2 split, D-05/PD-02). Follow-up feature
// wave, operator request verbatim: "make wifi and bluetooth options open
// inline." Same NavRow -> real-controls transformation AudioPage.qml
// (Task 13) already received, over the shell's single WifiBackend
// instance — threaded through SettingsState.wifiBackend the same way
// SettingsState.audioBackend already reaches AudioPage.qml. Settings.qml
// relays it from shell.qml's own wifiBackendInstance — the SAME instance
// the wifi panel already shares, never a second instance.
//
// Wi-Fi ONLY as of quick task 260825-wj2 Task 4 — the Bluetooth half
// (page-level state, DeviceRow, and the whole "Bluetooth" SettingsSection)
// moved out to its own page, `BluetoothPage.qml` ("Connected devices",
// D-8), because Caelestia's own structure gives Bluetooth its own page
// rather than sharing this one. This file's own gate checks that the
// Bluetooth backend relay property is gone entirely after the cut, per
// this quick task's own verify.
//
// WifiPanel.qml is NOT touched by this wave — the Audio precedent's own
// rule ("AudioPanel.qml is not touched at all") applies here too. The one
// change this wave makes OUTSIDE this file is in shell.qml: the backend's
// `panelOpen` gate widens to also cover "the settings window is open and
// showing this page" (see shell.qml's own `settingsShowingNetwork`) —
// without it the backend's live truth (wifi scanning) is never turned on
// while this page is the one actually rendering it, and the inline list
// would always read empty.
//
// Row-scoped interaction state (expandedNetwork/pendingNetwork/
// failedNetwork) reproduces WifiPanel.qml's OWN shape deliberately, not a
// re-derived one: WifiPanel.qml keeps its own pendingNetwork/
// failedNetwork copies rather than binding straight to
// `backend.connectingNetwork`, because ITS OWN watchdog timer has to be
// able to resolve a stranded request independently of whatever the
// backend's separately-timed OBSERVED-truth property is doing at that
// moment — two independent timeout mechanisms, so two independent
// copies. This page copies that shape exactly, for the same reason.
//
// Deliberately NOT reproduced here — real capability gaps, not
// omissions of effort, named exactly as the panel already found them:
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
// Every row's identity is the network OBJECT, never a name string
// (T-15-08) — an SSID is attacker-controllable text arriving over the
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

    // Bluetooth (page-level state, DeviceRow, and the whole "Bluetooth"
    // SettingsSection) moved to BluetoothPage.qml (quick task 260825-wj2
    // Task 4, D-8) — this page is Wi-Fi only from here down.
    Component.onCompleted: {
        nmConnectionEditorProbe.running = true;
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
                    font.pixelSize: Design.settingsFontRow
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
                            font.pixelSize: Design.settingsFontRow
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
                            font.pixelSize: Design.settingsFontRow
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
                        font.pixelSize: Design.settingsFontRow
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
                font.pixelSize: Design.settingsFontSub
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
                        font.pixelSize: Design.settingsFontRow
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
                font.pixelSize: Design.settingsFontSub
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
                    font.pixelSize: Design.settingsFontSub
                    color: Colours.onSurface
                    wrapMode: Text.WordWrap
                }
                Text {
                    id: forgetYes
                    text: "Forget"
                    font.pixelSize: Design.settingsFontSub
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
                    font.pixelSize: Design.settingsFontSub
                    color: Colours.onSurfaceVariant

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.confirmForgetNetwork = null
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
                    font.pixelSize: Design.settingsFontSub
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
                    font.pixelSize: Design.settingsFontSub
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
                font.pixelSize: Design.settingsFontRow
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

}
