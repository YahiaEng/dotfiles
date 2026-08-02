// WifiPanel.qml — the wifi panel body (Phase 15 Plans 03 and 05,
// PANEL-03/PANEL-06). Root type `PanelDialog`, mirroring `AudioPanel.qml`'s
// own shape so all three panel instances read as one component with three
// contents (PANEL-06) — same frame, same header band, same dismissal set.
//
// 15-03 shipped the two D-15-26 off-state branches and the real, empty,
// scrollable body slot only. 15-05 (this plan, Task 2) fills that slot: the
// scan in-progress line, the refresh control, and the grouped stable list
// with its focal current-connection row. Task 3 adds the row verbs, the
// inline password flow, in-flight/failure and Forget.
//
// ── Hierarchy pattern mirrored from 15-04's render-gate fix (binding,
//    15-05-PLAN.md's inherited contract) ────────────────────────────────
// 15-04's audio panel render gate FAILED on a missing pinned/list boundary
// marker and an under-weighted primary control; the fix — an
// outline-hairline-plus-label boundary and extra weight on the panel's own
// primary control — was declared the pattern every later panel in this
// phase must mirror against its OWN primary control and its OWN list. This
// panel has no separate pinned block (D-15-16 achieves the same focal-point
// effect through ORDERING, not a non-scrolling region — UI-SPEC's own
// per-panel-focal-point table names "the current-connection row at the top
// of the grouped list" as this panel's focal point), so the pattern is
// realized wifi-natively: the current-connection row IS the weighted
// primary control (a `Colours.surfaceVariant` fill the other groups do not
// carry), and the hairline-plus-label boundary marker is applied between
// EVERY group transition (Saved, Other networks) rather than once, since
// this list has more than one internal boundary to name.
import QtQuick
import QtQuick.Controls
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

    // Matches AudioPanel.qml's own constant name and value — every
    // interactive row across the three panels shares one row-height token.
    readonly property int controlRowHeight: 32

    // ── strengthGlyph(network) — the never-sorting strength glyph
    //    (D-15-16: rendered per row, takes no part in ordering). Uses the
    //    SAME ligature name at every strength ("network_wifi", already
    //    verified present in the installed font's post table alongside
    //    this repo's existing "wifi"/"wifi_off" ligatures) and encodes the
    //    bucket through the returned OPACITY rather than swapping to a
    //    second glyph name — the same technique QuickToggles.qml's
    //    FILL-axis interpolation and this repo's Colours-role convention
    //    both already rely on: modulate a proven surface rather than risk
    //    an unverified per-bar-count ligature name reading as tofu.
    //    Thresholds span the full theoretical 0.0-1.0 domain (Task 1
    //    measurement 1's declared range for `signalStrength`), not just
    //    this session's observed 0.24-0.49 slice, so a stronger network
    //    arriving later still buckets correctly. Returns -1 when the
    //    network reports no usable strength value (E3 `partial` backstop)
    //    so the caller can render the row without the glyph entirely. ────
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

    // ── groupHeader — the hairline-plus-label boundary marker mirrored
    //    from 15-04's render-gate fix (AudioPanel.qml's `sectionDivider`),
    //    applied between every group transition here since this list has
    //    more than one internal boundary to name (Saved, Other networks —
    //    Connected needs none, it directly follows the progress line at
    //    the top of the list). ─────────────────────────────────────────
    component GroupHeader: Column {
        property string label: ""
        width: parent ? parent.width : 0
        spacing: root.spacingXs

        Rectangle {
            width: parent.width
            height: 1
            color: Colours.outline
        }
        Text {
            text: parent.label
            font.pixelSize: root.fontLabel
            font.weight: root.weightEmphasis
            color: Colours.onSurfaceVariant
        }
    }

    // ── NetworkRow — one line, always (UI-SPEC E3 `zero-one-many`, count
    //    invariant, no singular/plural branch). Left to right: the
    //    never-sorting strength glyph, the elided SSID with its full-name
    //    tooltip (E3 `long-text`, NEW locked contract). The current
    //    connection's row alone carries `emphasized: true` — the
    //    `Colours.surfaceVariant` fill the other groups do not carry,
    //    mirroring 15-04's primary-control weight differentiation against
    //    THIS panel's own focal point (UI-SPEC Dimension 2). Rows are
    //    keyed by the network OBJECT (`network: modelData` bound at each
    //    Repeater's delegate site) — two rows can legitimately carry the
    //    same SSID and neither may act on the other. Task 3 adds the
    //    trailing verb/expansion region; this task reserves no space for
    //    it yet. ─────────────────────────────────────────────────────────
    component NetworkRow: Item {
        id: networkRow

        property var network: null
        property bool emphasized: false

        readonly property real strengthGlyphOpacity: root.strengthGlyph(networkRow.network)
        readonly property bool hasStrength: networkRow.strengthGlyphOpacity >= 0

        width: parent ? parent.width : 0
        height: root.controlRowHeight

        Rectangle {
            anchors.fill: parent
            radius: root.spacingXs
            color: networkRow.emphasized ? Colours.surfaceVariant : "transparent"
        }

        Text {
            id: strengthIcon
            anchors.left: parent.left
            anchors.leftMargin: root.spacingSm
            anchors.verticalCenter: parent.verticalCenter
            width: networkRow.hasStrength ? root.iconSizeMd : 0
            visible: networkRow.hasStrength
            horizontalAlignment: Text.AlignHCenter
            font.family: root.symbolFontFamily
            font.pixelSize: root.iconSizeMd
            // "network_wifi" — verified present in the installed Material
            // Symbols Rounded font's `post` table, the SAME ligature
            // rendered at every bucket (see strengthGlyph()'s own header
            // note for why opacity carries the bucket instead of a second
            // glyph name).
            text: "network_wifi"
            opacity: networkRow.hasStrength ? networkRow.strengthGlyphOpacity : 1
            color: Colours.onSurfaceVariant
        }

        Text {
            id: ssidText
            anchors.left: strengthIcon.right
            anchors.leftMargin: root.spacingSm
            anchors.right: parent.right
            anchors.rightMargin: root.spacingSm
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            text: networkRow.network ? networkRow.network.name : ""
            font.pixelSize: root.fontBody
            font.weight: root.weightBody
            color: Colours.onSurface

            MouseArea {
                id: ssidHoverArea
                anchors.fill: parent
                hoverEnabled: true
                ToolTip.visible: ssidHoverArea.containsMouse
                ToolTip.text: ssidText.text
                ToolTip.delay: Design.tooltipDelayMs
            }
        }
    }

    // ── Branch 3 (populated) — the network list. 15-03 left this real and
    //    empty; this task fills it with the scan in-progress line, the
    //    refresh control, and the grouped stable list. Task 3 adds the row
    //    verbs, the password flow, in-flight/failure and Forget on top of
    //    this same structure. ─────────────────────────────────────────
    Item {
        id: listBodySlot
        width: parent.width
        height: listColumn.implicitHeight
        visible: root.panelState === "populated"

        Column {
            id: listColumn
            width: parent.width
            spacing: root.spacingSm

            // ── The in-progress line (D-15-15, UI-SPEC E3 `loading`) and
            //    the refresh control, pinned as the first element of this
            //    list — a fixed-height row whose own visibility toggling
            //    never reflows the group list below it (opacity carries
            //    the on/off language, not `visible`). No text accompanies
            //    the line — the Copywriting Contract says the line is the
            //    whole message. ─────────────────────────────────────────
            Item {
                id: progressLine
                width: parent.width
                height: root.iconSizeMd

                Item {
                    id: progressTrack
                    anchors.left: parent.left
                    anchors.right: refreshControl.left
                    anchors.rightMargin: root.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    height: 3
                    opacity: (root.backend && root.backend.scanning) ? 1 : 0

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Colours.surfaceVariant
                    }

                    Rectangle {
                        id: progressSegment
                        height: parent.height
                        radius: height / 2
                        color: Colours.primary
                        // At `off` motion scale the SequentialAnimation
                        // below never runs (Motion.motionEnabled false) —
                        // the line must still say something true, so it
                        // renders as a static full-width bar rather than
                        // vanishing: "scanning" is information and reduced
                        // motion is not a reason to withhold it (same
                        // fallback voice QuickToggles.qml records for its
                        // own pending-pulse layer at `off`).
                        width: Motion.motionEnabled ? progressTrack.width * 0.3 : progressTrack.width
                        x: 0

                        SequentialAnimation {
                            running: (root.backend && root.backend.scanning) && Motion.motionEnabled
                            loops: Animation.Infinite
                            NumberAnimation {
                                target: progressSegment
                                property: "x"
                                from: 0
                                to: progressTrack.width - progressSegment.width
                                duration: Motion.emphasizedInDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.emphasizedInEasing
                            }
                            NumberAnimation {
                                target: progressSegment
                                property: "x"
                                from: progressTrack.width - progressSegment.width
                                to: 0
                                duration: Motion.emphasizedOutDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.emphasizedOutEasing
                            }
                        }
                    }
                }

                // Ships because Task 1's measurement 2 confirmed the
                // scan-flag toggle produces a genuinely fresh scan (the
                // list clears to 0 within ~200ms of disabling and
                // repopulates within 300ms-1.5s of re-enabling, still
                // growing 4.5s later as new APs are discovered — see
                // 15-05-SUMMARY.md Task 1). Stays available regardless of
                // whether a scan is currently in flight.
                Text {
                    id: refreshControl
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "refresh"
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.iconSizeMd
                    color: Colours.onSurfaceVariant

                    MouseArea {
                        id: refreshMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: if (root.backend) root.backend.rescan()
                        ToolTip.visible: refreshMouseArea.containsMouse
                        ToolTip.text: "Rescan"
                        ToolTip.delay: Design.tooltipDelayMs
                    }
                }
            }

            // ── The grouped list (D-15-16) — current, then saved, then
            //    the rest. Three Repeaters, each bound to a plain JS array
            //    on the backend (the grouping work produces those arrays
            //    already, sidestepping the raw-model-binding question
            //    entirely). Rendered as one block (D-15-08): no cascade
            //    band, no per-row entrance animation. ────────────────────
            Column {
                id: networkList
                width: parent.width
                spacing: root.spacingSm

                // Group 1 — Connected. The panel's declared focal point
                // (UI-SPEC Dimension 2): D-15-16's ordering puts "what am
                // I connected to right now" first by construction. No
                // GroupHeader above it — it directly follows the progress
                // line, the top of this list.
                Text {
                    id: connectedLabel
                    text: "Connected"
                    visible: root.backend ? !!root.backend.currentNetwork : false
                    font.pixelSize: root.fontLabel
                    font.weight: root.weightEmphasis
                    color: Colours.onSurfaceVariant
                }
                Repeater {
                    model: (root.backend && root.backend.currentNetwork) ? [root.backend.currentNetwork] : []
                    delegate: NetworkRow {
                        network: modelData
                        emphasized: true
                    }
                }

                // Group 2 — Saved.
                GroupHeader {
                    label: "Saved"
                    visible: root.backend ? root.backend.savedNetworks.length > 0 : false
                }
                Repeater {
                    model: root.backend ? root.backend.savedNetworks : []
                    delegate: NetworkRow {
                        network: modelData
                        emphasized: false
                    }
                }

                // Group 3 — Other networks.
                GroupHeader {
                    label: "Other networks"
                    visible: root.backend ? root.backend.otherNetworks.length > 0 : false
                }
                Repeater {
                    model: root.backend ? root.backend.otherNetworks : []
                    delegate: NetworkRow {
                        network: modelData
                        emphasized: false
                    }
                }
            }

            // ── Zero-result state (backstop, UI-SPEC E3 `empty`'s
            //    third sub-case) — the radio is on, the panel is in the
            //    populated branch, and a completed scan found nothing.
            //    The refresh control above stays visible; this is not the
            //    off-branch composition, the radio is working and the
            //    panel is scanning. ────────────────────────────────────
            Item {
                id: zeroResultState
                width: parent.width
                height: zeroResultText.implicitHeight + root.spacingMd * 2
                visible: root.backend
                    ? (!root.backend.currentNetwork && root.backend.savedNetworks.length === 0 && root.backend.otherNetworks.length === 0)
                    : false

                Text {
                    id: zeroResultText
                    anchors.centerIn: parent
                    text: "No networks found"
                    font.pixelSize: root.fontBody
                    color: Colours.onSurfaceVariant
                }
            }
        }
    }

    // Only the branch actually visible at mount time enters the cascade —
    // the other two are inert Items with no visible content to animate.
    // Evaluated once, at construction, matching AudioPanel.qml's own
    // single-array-literal shape.
    bodyCascadeBands: root.radioBlockedBranch ? [hardwareBlockedBranch] : (root.radioOffBranch ? [softOffBranch] : [listBodySlot])
}
