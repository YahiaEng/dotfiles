// BluetoothPopout.qml — the bluetooth section's popout body (Phase 18 Plan
// 14, QBAR-09). Built as WifiPopout.qml's twin, matching its shape rather
// than reinventing one: the backend handle is a plain property passed down
// from the capsule, state is bound exactly once, the foot link is wired
// once, every text element declares its format explicitly.
//
// ── Readiness verdict this body relies on ────────────────────────────────
// BluetoothBackend.readinessState — DOES NOT EXIST NATIVELY, BUILT (see
// that file's own header note for the full audit): a monotonic latch over
// `Bluetooth.adapters` plus one non-repeating deadline read from
// `Design.backendResolveDeadlineMs` — the one timing object this whole
// plan adds anywhere, and it lives on the backend, not in this file.
//
// ── No discovery, in any form ────────────────────────────────────────────
// This body never calls `startDiscovery()`, never writes the adapter's
// discovery property and never renders the discovered-devices collection.
// BluetoothBackend.qml's own header names `startDiscovery()`'s ONE call
// site in this whole repo as the "Add device" press BluetoothPanel.qml
// builds — that is where adding a device lives, and this body is not a
// second call site of it.
//
// ── No pairing flow ───────────────────────────────────────────────────────
// An unpaired device is never offered here at all (this body's device list
// is built from the connected/paired collections only, which by
// construction excludes anything not already bonded), so pairing's
// multi-step failure vocabulary and its two watchdogs never reach this
// surface.
//
// Device names are supplied by the devices themselves over the air, so
// every text element here gets the same treatment 18-10 gave tray-supplied
// text and 18-13 gave audio device labels: an explicitly declared plain
// format, right elision, a list capped at Design.popoutListCap. This file
// constructs no command, no path and no dispatch string, and declares no
// timing object of any kind.
import QtQuick
import "../"
import "../dashboard"

SectionPopout {
    id: root

    property var bluetoothBackend: null

    sectionId: "bluetooth"
    popoutTitle: "Bluetooth"
    // The same three-way shape 18-08's bar entry uses, read off the same
    // properties, so the bar entry and this header can never disagree.
    popoutGlyph: {
        if (!root.bluetoothBackend || !root.bluetoothBackend.adapterPresent)
            return "bluetooth_disabled";
        if (root.bluetoothBackend.adapterBlocked)
            return "bluetooth_disabled";
        if (!root.bluetoothBackend.adapterEnabled)
            return "bluetooth_disabled";
        return root.bluetoothBackend.connectedDevices.length > 0 ? "bluetooth_connected" : "bluetooth";
    }

    readonly property var _connectedRows: root.bluetoothBackend ? root.bluetoothBackend.connectedDevices : []
    readonly property var _pairedRows: root.bluetoothBackend ? root.bluetoothBackend.pairedDevices : []
    readonly property var _deviceRows: root._connectedRows.concat(root._pairedRows).slice(0, Design.popoutListCap)

    // The two off-state messages read two different facts and must stay
    // two different sentences: a machine with a working adapter and simply
    // nothing paired is not the same story as a machine reporting no
    // adapter at all, and collapsing the two would tell a user with
    // working hardware that it is missing.
    readonly property bool _noAdapter: !root.bluetoothBackend || root.bluetoothBackend.readinessState === "empty"

    bodyState: {
        if (!root.bluetoothBackend || root.bluetoothBackend.readinessState === "pending")
            return "pending";
        if (root.bluetoothBackend.adapterBlocked)
            return "failed";
        if (root._noAdapter)
            return "empty";
        if (root.bluetoothBackend.adapterEnabled && root._connectedRows.length === 0 && root._pairedRows.length === 0)
            return "empty";
        return "populated";
    }
    failedStateGlyph: "bluetooth_disabled"
    failedStateText: "Bluetooth unavailable — a software block is holding the radio off, then reopen this panel."
    emptyStateGlyph: "bluetooth_disabled"
    emptyStateText: root._noAdapter ? "No adapter detected" : "No paired devices — add one in the dashboard"

    wayfindingLabel: "Open Bluetooth settings"
    onWayfindingActivated: PopoutController.requestPanel("bluetooth")

    property string _failedAddress: ""
    property string _failedReason: ""

    Connections {
        target: root.bluetoothBackend
        function onDeviceActionFailed(device, reasonText) {
            root._failedAddress = device ? device.address : "";
            root._failedReason = reasonText;
        }
    }

    function _verbLabel(device) {
        var verb = root.bluetoothBackend ? root.bluetoothBackend.contextualVerb(device) : "";
        if (verb === "connect")
            return "Connect";
        if (verb === "disconnect")
            return "Disconnect";
        return "";
    }

    // ── The adapter toggle — the one action worth taking from the bar. ──
    Item {
        id: adapterTogglePill
        visible: root.bodyState === "populated"
        width: adapterToggleLabel.implicitWidth + Design.spacingLg * 2
        height: Design.iconSizeMd + Design.spacingSm * 2

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: BarRoles.popoutSurfaceVariant
        }
        Text {
            id: adapterToggleLabel
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: (root.bluetoothBackend && root.bluetoothBackend.adapterEnabled) ? "Turn Bluetooth off" : "Turn Bluetooth on"
            font.pixelSize: Design.fontBody
            color: BarRoles.capsuleFg
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.bluetoothBackend)
                    root.bluetoothBackend.setAdapterEnabled(!root.bluetoothBackend.adapterEnabled);
            }
        }
    }

    // ── Devices — up to Design.popoutListCap, connected first then
    //    paired, capped across both together, in the backend's own
    //    published order, no comparator sort anywhere. ───────────────────
    Column {
        id: deviceSection
        visible: root.bodyState === "populated"
        width: parent.width
        spacing: Design.spacingXs

        Repeater {
            model: root._deviceRows

            Column {
                id: deviceRow
                required property var modelData
                width: parent.width
                spacing: Design.spacingXs

                readonly property bool isFailedRow: deviceRow.modelData && root._failedAddress === deviceRow.modelData.address

                Item {
                    id: deviceRowLine
                    width: parent.width
                    height: Design.iconSizeMd + Design.spacingSm * 2

                    Rectangle {
                        anchors.fill: parent
                        radius: Design.spacingSm
                        color: deviceRowMouseArea.containsMouse ? BarRoles.popoutSurfaceVariant : "transparent"
                    }

                    Text {
                        id: deviceNameText
                        anchors.left: parent.left
                        anchors.leftMargin: Design.spacingSm
                        anchors.right: deviceTrailingText.left
                        anchors.rightMargin: Design.spacingSm
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: deviceRow.modelData ? deviceRow.modelData.deviceName : ""
                        font.pixelSize: Design.fontBody
                        color: BarRoles.popoutFg
                    }

                    Text {
                        id: deviceTrailingText
                        anchors.right: parent.right
                        anchors.rightMargin: Design.spacingSm
                        anchors.verticalCenter: parent.verticalCenter
                        textFormat: Text.PlainText
                        text: deviceRow.isFailedRow ? "Retry" : root._verbLabel(deviceRow.modelData)
                        font.pixelSize: Design.fontLabel
                        color: deviceRow.isFailedRow ? BarRoles.danger : BarRoles.accent
                    }

                    MouseArea {
                        id: deviceRowMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (root.bluetoothBackend)
                                root.bluetoothBackend.pressDevice(deviceRow.modelData);
                        }
                    }
                }

                // Row-scoped failure (D-15-09's shape, carried here), the
                // device's own name repeated at this second, independent
                // element so the row it names stays unambiguous even once
                // the collapsed line's own name has scrolled off under
                // elision — the same defence-in-depth 18-10 and 18-13 both
                // give a peer-supplied string, applied a second time here.
                Text {
                    id: deviceFailureText
                    visible: deviceRow.isFailedRow
                    width: parent.width
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: (deviceRow.modelData ? deviceRow.modelData.deviceName : "") + " — " + root._failedReason
                    font.pixelSize: Design.fontLabel
                    color: BarRoles.danger
                }
            }
        }

        // Battery, one row at a time, rendered only for a row that reports
        // one is available — never a zero for a device that reports none.
        Repeater {
            model: root._deviceRows

            Text {
                id: batteryLine
                required property var modelData
                visible: batteryLine.modelData && batteryLine.modelData.batteryAvailable === true
                width: parent.width
                textFormat: Text.PlainText
                text: batteryLine.modelData ? ("Battery " + Math.round(batteryLine.modelData.battery) + "%") : ""
                font.pixelSize: Design.fontLabel
                color: BarRoles.capsuleFg
            }
        }

        // Adapter present and enabled, but genuinely off — not the
        // nothing-here state above (that is reserved for zero paired
        // devices on an ENABLED adapter): this is the same fact the toggle
        // above already states, spelled out once more where the list
        // would otherwise sit blank.
        Text {
            id: adapterOffListText
            visible: root._deviceRows.length === 0 && root.bluetoothBackend && !root.bluetoothBackend.adapterEnabled
            width: parent.width
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            text: "Turn on Bluetooth to see paired devices."
            font.pixelSize: Design.fontLabel
            color: BarRoles.capsuleFg
        }
    }
}
