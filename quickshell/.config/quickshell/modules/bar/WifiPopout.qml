// WifiPopout.qml — the wifi section's popout body (Phase 18 Plan 14,
// QBAR-09). Follows AudioPopout.qml's own shape: the backend handle is
// taken as a plain property passed down from the capsule, never reached
// for as a singleton; state is bound exactly once; the foot link is wired
// once; every text element declares its format explicitly.
//
// ── Readiness verdict this body relies on ────────────────────────────────
// WifiBackend.readinessState — EXISTS NATIVELY, sourced from
// `Networking.backend` (see that file's own header note for the full
// audit). No latch and no deadline live in this file; none is needed.
//
// Network names and device names are supplied by peers on the air and by
// the devices themselves, so every text element here gets the same
// treatment 18-10 gave tray-supplied text and 18-13 gave audio device
// labels: an explicitly declared plain format, right elision, and a list
// capped at Design.popoutListCap. This file constructs no command, no
// path and no dispatch string, and declares no timing object of any kind.
//
// ── D-15-15 (still binding here) ─────────────────────────────────────────
// This body never writes the backend's scan lifecycle gate and never calls
// a rescan of any kind — it renders only what the shell already observes.
// The saved list below is titled "Saved networks", never "nearby": this
// body cannot honestly claim to show what is nearby without arming the
// scanner, and calling a remembered list "nearby" would be presenting a
// past sweep as a current one (the specific failure T-18-14's own
// prohibitions name).
import QtQuick
import "../"
import "../dashboard"

SectionPopout {
    id: root

    property var wifiBackend: null

    sectionId: "wifi"
    popoutTitle: "Wi-Fi"
    // The same three-way shape 18-08's bar entry uses, read off the same
    // properties, so the bar entry and this header can never disagree
    // about what the radio is doing.
    popoutGlyph: {
        if (!root.wifiBackend || !root.wifiBackend.wifiHardwareEnabled)
            return "wifi_off";
        if (!root.wifiBackend.wifiEnabled)
            return "wifi_off";
        if (!(root.wifiBackend.wifiDevice && root.wifiBackend.wifiDevice.connected === true))
            return "signal_wifi_statusbar_null";
        return "network_wifi";
    }

    bodyState: {
        if (!root.wifiBackend || root.wifiBackend.readinessState === "pending")
            return "pending";
        if (!root.wifiBackend.wifiHardwareEnabled)
            return "failed";
        if (root.wifiBackend.readinessState === "empty")
            return "empty";
        return "populated";
    }
    failedStateGlyph: "wifi_off"
    failedStateText: "Wi-Fi unavailable — turned off by a hardware switch, then reopen this panel."
    emptyStateGlyph: "wifi_off"
    emptyStateText: "No Wi-Fi device found"

    wayfindingLabel: "Open Wi-Fi settings"
    onWayfindingActivated: PopoutController.requestPanel("wifi")

    readonly property var _currentNetwork: root.wifiBackend ? root.wifiBackend.currentNetwork : null
    readonly property var _savedRows: root.wifiBackend ? root.wifiBackend.savedNetworks.slice(0, Design.popoutListCap) : []

    // Never sorts, never starts a scan: a plain opacity bucket over a
    // value that is either already there or absent. Same three-bucket
    // thresholds WifiPanel.qml's own strengthGlyph() and 18-08's own
    // networkOpacity use, spanning the full theoretical 0.0-1.0
    // signalStrength domain.
    function _strengthOpacity(network) {
        if (!network || typeof network.signalStrength !== "number" || isNaN(network.signalStrength) || network.signalStrength < 0)
            return 1;
        var s = network.signalStrength;
        if (s < 0.34)
            return 0.45;
        if (s < 0.67)
            return 0.7;
        return 1;
    }

    // Row-scoped connect failure (D-15-09's shape, carried here) — cleared
    // whenever a different row is pressed, so a stale message never sits
    // under a fresh attempt.
    property var _failedNetwork: null
    property string _failedText: ""

    Connections {
        target: root.wifiBackend
        function onConnectFailed(network, reasonText) {
            root._failedNetwork = network;
            root._failedText = reasonText;
        }
    }

    // ── Current connection row ──────────────────────────────────────────
    Row {
        id: currentRow
        visible: root.bodyState === "populated"
        width: parent.width
        spacing: Design.spacingSm

        Text {
            id: currentGlyph
            anchors.verticalCenter: parent.verticalCenter
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.iconSizeMd
            textFormat: Text.PlainText
            text: "network_wifi"
            opacity: root._strengthOpacity(root._currentNetwork)
            color: Colours.onSurfaceVariant
        }
        Text {
            id: currentLabel
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - currentGlyph.width - Design.spacingSm
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: root._currentNetwork ? root._currentNetwork.name : "Not connected"
            font.pixelSize: Design.fontBody
            font.weight: root._currentNetwork ? Design.weightEmphasis : Design.weightBody
            color: root._currentNetwork ? Colours.onSurface : Colours.onSurfaceVariant
        }
    }

    // ── The radio toggle — the one action worth taking from the bar.
    //    Toggles the settable enable property; the hardware property only
    //    decides whether the toggle is available at all. ────────────────
    Item {
        id: radioTogglePill
        visible: root.bodyState === "populated"
        width: radioToggleLabel.implicitWidth + Design.spacingLg * 2
        height: Design.iconSizeMd + Design.spacingSm * 2

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Colours.surfaceVariant
        }
        Text {
            id: radioToggleLabel
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: (root.wifiBackend && root.wifiBackend.wifiEnabled) ? "Turn Wi-Fi off" : "Turn Wi-Fi on"
            font.pixelSize: Design.fontBody
            color: Colours.onSurfaceVariant
        }
        MouseArea {
            anchors.fill: parent
            enabled: root.wifiBackend ? root.wifiBackend.wifiHardwareEnabled : false
            onClicked: {
                if (root.wifiBackend)
                    root.wifiBackend.setWifiEnabled(!root.wifiBackend.wifiEnabled);
            }
        }
    }

    // ── Saved networks — up to Design.popoutListCap, in the backend's own
    //    first-seen registry order, no comparator sort anywhere. ─────────
    Column {
        id: savedSection
        visible: root.bodyState === "populated"
        width: parent.width
        spacing: Design.spacingXs

        Text {
            id: savedLabel
            textFormat: Text.PlainText
            text: "Saved networks"
            font.pixelSize: Design.fontLabel
            font.weight: Design.weightEmphasis
            color: Colours.onSurfaceVariant
        }

        Repeater {
            model: root._savedRows

            Column {
                id: savedRow
                required property var modelData
                width: parent.width
                spacing: Design.spacingXs

                readonly property bool isFailedRow: root._failedNetwork === savedRow.modelData

                Item {
                    id: savedRowLine
                    width: parent.width
                    height: Design.iconSizeMd + Design.spacingSm * 2

                    Rectangle {
                        anchors.fill: parent
                        radius: Design.spacingSm
                        color: savedRowMouseArea.containsMouse ? Colours.surfaceVariant : "transparent"
                    }

                    Text {
                        id: savedSecurityGlyph
                        anchors.left: parent.left
                        anchors.leftMargin: Design.spacingSm
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        textFormat: Text.PlainText
                        text: (root.wifiBackend && root.wifiBackend.securityKind(savedRow.modelData) === "open") ? "lock_open" : "lock"
                        color: Colours.onSurfaceVariant
                    }

                    Text {
                        id: savedNameText
                        anchors.left: savedSecurityGlyph.right
                        anchors.leftMargin: Design.spacingSm
                        anchors.right: parent.right
                        anchors.rightMargin: Design.spacingSm
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: savedRow.modelData ? savedRow.modelData.name : ""
                        font.pixelSize: Design.fontBody
                        color: Colours.onSurface
                    }

                    MouseArea {
                        id: savedRowMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (!root.wifiBackend)
                                return;
                            root._failedNetwork = null;
                            root._failedText = "";
                            // The exact call shape the panel uses for a
                            // network the machine already knows: an empty
                            // second argument, so the backend calls the
                            // plain (no-psk) connect path and NetworkManager
                            // reuses whatever secret it already has stored
                            // for this profile. A failure whose mapped copy
                            // indicates secrets are needed stops there —
                            // this body has no field to grow for it, and
                            // the wayfinding link is the path for that
                            // case.
                            root.wifiBackend.connect(savedRow.modelData, "");
                        }
                    }
                }

                Text {
                    id: savedRowFailureText
                    visible: savedRow.isFailedRow
                    width: parent.width
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                    text: root._failedText
                    font.pixelSize: Design.fontLabel
                    color: Colours.error
                }
            }
        }

        // The list's own empty case, section-true rather than blank: this
        // body never arms the scanner, so what it can honestly show is
        // what the shell already observes.
        Text {
            id: savedEmptyText
            visible: root._savedRows.length === 0
            width: parent.width
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            text: "No saved networks in range — scan in the dashboard to find more."
            font.pixelSize: Design.fontLabel
            color: Colours.onSurfaceVariant
        }
    }
}
