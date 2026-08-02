// BluetoothPanel.qml — the bluetooth panel body (Phase 15 Plan 03,
// PANEL-04/PANEL-06). Root type `PanelDialog`, deliberately built as
// `WifiPanel.qml`'s twin so the two connectivity panels read as one
// grammar (same frame, same header band, same dismissal set, same branch
// composition shape) — only the copy and the branch predicates differ.
//
// This plan renders the adapter-disabled and no-adapter D-15-26 branches
// and the real, empty, scrollable body slot ONLY. The device list, opt-in
// discovery, the contextual-verb row, chevron expansion, the pairing
// spinner with its Cancel and the inferred-failure recipe are ALL
// 15-06's, including their copy — deliberately absent here, not stubbed.
import QtQuick
import Quickshell.Io
import "../"

PanelDialog {
    id: root

    property var backend: null

    panelTitle: "Bluetooth"
    panelGlyph: "bluetooth"
    namespaceSuffix: "bluetooth-panel"

    // T-15-02's mitigation, same discipline as WifiPanel.qml's
    // advancedCommand: a literal array of double-quoted string literals,
    // assigned exactly once. Never appended to, never interpolated, never
    // joined into a string, never handed to a shell interpreter.
    advancedCommand: ["blueman-manager"]
    advancedAvailable: root._bluemanManagerAvailable
    advancedUnavailableReason: "blueman-manager is not installed"

    // ── D-15-22 availability probe — the same mechanism WifiPanel.qml
    //    uses for nm-connection-editor (a fully literal fixed argv, zero
    //    interpolated elements, started once, fail OPEN). Housed here
    //    rather than in BluetoothBackend.qml for the same reason: that
    //    file is deliberately subprocess-free. ───────────────────────────
    property bool _bluemanManagerAvailable: true

    Process {
        id: bluemanManagerProbe
        command: ["which", "blueman-manager"]
        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0)
                root._bluemanManagerAvailable = false;
        }
    }
    Component.onCompleted: bluemanManagerProbe.running = true

    // ── D-15-26 branch selection — unfixable checked first so it always
    //    wins when both would otherwise apply. Both backend reads are
    //    null-guarded even though `backend` is always set by shell.qml,
    //    matching WifiPanel.qml's own discipline. ─────────────────────
    readonly property bool noAdapterBranch: !(root.backend && root.backend.adapterPresent)
    readonly property bool adapterOffBranch: !root.noAdapterBranch && !(root.backend && root.backend.adapterEnabled)
    // 15-02's four-name vocabulary — both off branches are "empty", the
    // real body slot is "populated". No fifth state name.
    readonly property string panelState: (root.noAdapterBranch || root.adapterOffBranch) ? "empty" : "populated"

    // The body area's own height, computed from the frame's own constants
    // rather than reaching into PanelDialog's private `bodyFlick` id (out
    // of this file's scope) — matches WifiPanel.qml's own approach.
    readonly property int bodyAreaHeight: root.panelHeight - root.headerHeight - (root.panelPadding * 2)

    // ── Branch 1 (unfixable) — no adapter at all, no button ──────────────
    Item {
        id: noAdapterBranchItem
        width: parent.width
        height: root.bodyAreaHeight
        visible: root.noAdapterBranch

        Column {
            anchors.centerIn: parent
            spacing: root.spacingSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "bluetooth_disabled"
                font.family: root.symbolFontFamily
                font.pixelSize: root.iconSizeMd
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No Bluetooth adapter"
                font.pixelSize: root.fontHeading
                font.weight: root.weightEmphasis
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "This device has no Bluetooth hardware"
                font.pixelSize: root.fontBody
                font.weight: root.weightBody
                lineHeight: root.lineHeightNormal
                color: root.stateColour("empty")
            }
        }
    }

    // ── Branch 2 (fixable) — adapter present but powered off, Enable
    //    button ─────────────────────────────────────────────────────────
    Item {
        id: adapterOffBranchItem
        width: parent.width
        height: root.bodyAreaHeight
        visible: root.adapterOffBranch

        Column {
            anchors.centerIn: parent
            spacing: root.spacingSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "bluetooth_disabled"
                font.family: root.symbolFontFamily
                font.pixelSize: root.iconSizeMd
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Bluetooth is off"
                font.pixelSize: root.fontHeading
                font.weight: root.weightEmphasis
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Turn on Bluetooth to see nearby devices"
                font.pixelSize: root.fontBody
                font.weight: root.weightBody
                lineHeight: root.lineHeightNormal
                color: root.stateColour("empty")
            }

            // The branch's one accent use (D-15-26's governing principle:
            // never offer a control that cannot work — this is the ONE
            // control here that can).
            Item {
                id: enableButton
                anchors.horizontalCenter: parent.horizontalCenter
                width: enableLabel.implicitWidth + root.spacingLg * 2
                height: 40

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Colours.primary
                }
                Text {
                    id: enableLabel
                    anchors.centerIn: parent
                    text: "Enable"
                    font.pixelSize: root.fontBody
                    color: Colours.onPrimary
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.backend)
                            root.backend.setAdapterEnabled(true);
                    }
                }
            }
        }
    }

    // ── Branch 3 (populated) — the real, empty, scrollable body slot
    //    15-06 fills with the device list. No placeholder copy, no fake
    //    device row, no discovery control — writing a stand-in version
    //    here only creates work for 15-06 to delete. ────────────────────
    Item {
        id: listBodySlot
        width: parent.width
        visible: root.panelState === "populated"
    }

    // Only the branch actually visible at mount time enters the cascade —
    // matches WifiPanel.qml's own single-array-literal shape.
    bodyCascadeBands: root.noAdapterBranch ? [noAdapterBranchItem] : (root.adapterOffBranch ? [adapterOffBranchItem] : [listBodySlot])
}
