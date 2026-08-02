// WifiPanel.qml — the wifi panel body (Phase 15 Plan 03, PANEL-03/PANEL-06).
// Root type `PanelDialog`, mirroring `AudioPanel.qml`'s own shape so all
// three panel instances read as one component with three contents
// (PANEL-06) — same frame, same header band, same dismissal set.
//
// This plan renders the two D-15-26 off-state branches and the real, empty,
// scrollable body slot ONLY. The network list, its scan/progress line, the
// inline password row, connectWithPsk, the failure-reason copy mapping and
// Forget-with-inline-confirm are ALL 15-05's, including their copy —
// deliberately absent here, not stubbed.
import QtQuick
import Quickshell.Io
import "../"

PanelDialog {
    id: root

    property var backend: null

    panelTitle: "Wi-Fi"
    panelGlyph: "wifi"
    namespaceSuffix: "wifi-panel"

    // T-15-02's mitigation, same discipline as AudioPanel.qml's
    // advancedCommand: a literal array of double-quoted string literals,
    // assigned exactly once. Never appended to, never interpolated, never
    // joined into a string, never handed to a shell interpreter.
    advancedCommand: ["nm-connection-editor"]
    advancedAvailable: root._nmConnectionEditorAvailable
    advancedUnavailableReason: "nm-connection-editor is not installed"

    // ── D-15-22 availability probe — the same mechanism AudioBackend.qml
    //    built for pavucontrol (a fully literal fixed argv, zero
    //    interpolated elements, started once, fail OPEN so a probe that
    //    cannot run at all never hides a working button). Housed in the
    //    PANEL file rather than WifiBackend.qml because that file is
    //    deliberately subprocess-free (RESEARCH Pitfall 1's networking
    //    surface has no CLI dependency at all) — this probe is generic
    //    host-binary detection, not a networking read, so it does not
    //    belong on the networking adapter. ───────────────────────────────
    property bool _nmConnectionEditorAvailable: true

    Process {
        id: nmConnectionEditorProbe
        command: ["which", "nm-connection-editor"]
        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0)
                root._nmConnectionEditorAvailable = false;
        }
    }
    Component.onCompleted: nmConnectionEditorProbe.running = true

    // ── D-15-26 branch selection — unfixable checked first so it always
    //    wins when both would otherwise apply. Both backend reads are
    //    null-guarded even though `backend` is always set by shell.qml, so
    //    this file never assumes what it cannot verify locally. ──────────
    readonly property bool radioBlockedBranch: !(root.backend && root.backend.wifiHardwareEnabled)
    readonly property bool radioOffBranch: !root.radioBlockedBranch && !(root.backend && root.backend.wifiEnabled)
    // 15-02's four-name vocabulary — both off branches are "empty", the
    // real body slot is "populated". No fifth state name.
    readonly property string panelState: (root.radioBlockedBranch || root.radioOffBranch) ? "empty" : "populated"

    // The body area's own height, computed from the frame's own constants
    // rather than reaching into PanelDialog's private `bodyFlick` id (out
    // of this file's scope) — lets each branch composition centre itself
    // within the panel's real available body region instead of merely its
    // own intrinsic size.
    readonly property int bodyAreaHeight: root.panelHeight - root.headerHeight - (root.panelPadding * 2)

    // ── Branch 1 (unfixable) — hardware switch, no button ────────────────
    Item {
        id: hardwareBlockedBranch
        width: parent.width
        height: root.bodyAreaHeight
        visible: root.radioBlockedBranch

        Column {
            anchors.centerIn: parent
            spacing: root.spacingSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "wifi_off"
                font.family: root.symbolFontFamily
                font.pixelSize: root.iconSizeMd
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Wi-Fi is off"
                font.pixelSize: root.fontHeading
                font.weight: root.weightEmphasis
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Turned off by a hardware switch"
                font.pixelSize: root.fontBody
                font.weight: root.weightBody
                lineHeight: root.lineHeightNormal
                color: root.stateColour("empty")
            }
        }
    }

    // ── Branch 2 (fixable) — software radio off, Enable button ───────────
    Item {
        id: softOffBranch
        width: parent.width
        height: root.bodyAreaHeight
        visible: root.radioOffBranch

        Column {
            anchors.centerIn: parent
            spacing: root.spacingSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "wifi_off"
                font.family: root.symbolFontFamily
                font.pixelSize: root.iconSizeMd
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Wi-Fi is off"
                font.pixelSize: root.fontHeading
                font.weight: root.weightEmphasis
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Turn on Wi-Fi to see nearby networks"
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
                            root.backend.setWifiEnabled(true);
                    }
                }
            }
        }
    }

    // ── Branch 3 (populated) — the real, empty, scrollable body slot
    //    15-05 fills with the network list. No placeholder copy, no fake
    //    row, no scan/refresh control — writing a stand-in version here
    //    only creates work for 15-05 to delete. ────────────────────────
    Item {
        id: listBodySlot
        width: parent.width
        visible: root.panelState === "populated"
    }

    // Only the branch actually visible at mount time enters the cascade —
    // the other two are inert Items with no visible content to animate.
    // Evaluated once, at construction, matching AudioPanel.qml's own
    // single-array-literal shape.
    bodyCascadeBands: root.radioBlockedBranch ? [hardwareBlockedBranch] : (root.radioOffBranch ? [softOffBranch] : [listBodySlot])
}
