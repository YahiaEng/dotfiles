// TrayPopout.qml — the tray capsule's overflow popout (quick task
// 260823-65s, D-1). Lists the 4th-and-later SystemTray item once
// TrayCapsule.qml's inline row (inlineLimit 3) is full, reusing the
// existing PopoutController/SectionPopout machinery rather than a second
// popout mechanism — same shape as EthernetPopout.qml, the smallest
// SectionPopout body in this directory.
//
// Colours here follow EthernetPopout's own layer (Colours.onSurface /
// Colours.onSurfaceVariant) — this is dashboard-scale popout content, not
// bar chrome, and carries the same named quickshell-doctor exemption
// EthernetPopout and its other siblings already carry (bar-colour-role-
// routing; see that script's QSD_BAR_COLOUR_ROLE_EXEMPT array).
//
// Threat T-65s-01: `title`/`id` are attacker-influenced — any app can
// publish them. Every Text below declares textFormat: Text.PlainText and
// elides; no tray string is ever used to construct a command, path or
// dispatch string.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../"
import "../dashboard"

SectionPopout {
    id: root

    // The 4th-and-later tray items, handed down by TrayCapsule.qml. `[]`
    // is an ordinary value here, never an error — the same contract
    // EthernetPopout's own device-handle property carries.
    property var overflowItems: []

    // Icon tint (260823-65s round 3, rebuilt round 4) — the SAME Prefs key
    // TrayCapsule.qml reads, so the two surfaces never disagree on mode.
    // Colour source is this popout's OWN content role (Colours.onSurface,
    // the same colour rowLabel below already uses), never BarRoles —
    // that role belongs to the bar window, not this one (EthernetPopout's
    // own colour layer, which this file already follows for everything
    // else). See TrayCapsule.qml's own header comment for the full round-4
    // rebuild reasoning (the operator-measured "monochrome and desaturated
    // look identical" defect, and why a mask-based silhouette replaces the
    // unverified colorization-amount approach).
    readonly property string _trayIconTint: Prefs.getValue("bar.tray.iconTint")
    readonly property bool _tintMonochrome: root._trayIconTint === "monochrome"
    readonly property bool _tintDesaturate: root._trayIconTint === "desaturate"
    readonly property bool _tintActive: root._tintMonochrome || root._tintDesaturate

    sectionId: "tray"
    popoutTitle: "System tray"
    popoutGlyph: "expand_more"

    bodyState: root.overflowItems.length > 0 ? "populated" : "empty"
    emptyStateGlyph: "apps"
    emptyStateText: "No further tray icons"

    wayfindingLabel: "Open in dashboard"
    wayfindingAvailable: false
    wayfindingUnavailableReason: "The dashboard has no system-tray panel"

    // ── Body — one row per overflow item ─────────────────────────────────
    Column {
        width: parent.width
        spacing: Design.spacingSm

        Repeater {
            model: root.overflowItems
            delegate: Item {
                id: overflowRow
                required property var modelData

                width: parent ? parent.width : 0
                height: Math.max(Design.iconSizeMd, rowLabel.implicitHeight)

                // Title, falling back to id, falling back to an em dash —
                // never the string "undefined".
                readonly property string _titleText: {
                    var t = overflowRow.modelData ? overflowRow.modelData.title : "";
                    if (t !== undefined && t !== null && t !== "")
                        return String(t);
                    var i = overflowRow.modelData ? overflowRow.modelData.id : "";
                    if (i !== undefined && i !== null && i !== "")
                        return String(i);
                    return "—";
                }

                // ── Tooltip text (Task 3 operator feedback, 260823-65s) —
                //    same tooltipTitle/title/tooltipDescription contract as
                //    TrayCapsule.qml's inline cells, so overflowed items do
                //    not lose data the protocol hands us just because they
                //    already show a plain-text title inline (tooltipDescription
                //    is never shown any other way in this row).
                readonly property string _tooltipTitle: (overflowRow.modelData && overflowRow.modelData.tooltipTitle) ? overflowRow.modelData.tooltipTitle : ""
                readonly property string _tooltipBase: overflowRow._tooltipTitle !== "" ? overflowRow._tooltipTitle : overflowRow._titleText
                readonly property string _tooltipDescription: (overflowRow.modelData && overflowRow.modelData.tooltipDescription) ? overflowRow.modelData.tooltipDescription : ""
                readonly property string _tooltipText: {
                    if (overflowRow._tooltipDescription !== "" && overflowRow._tooltipDescription !== overflowRow._tooltipBase)
                        return overflowRow._tooltipBase + "\n" + overflowRow._tooltipDescription;
                    return overflowRow._tooltipBase;
                }

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Design.spacingSm

                    // CORRECTION 1 (CONTEXT.md) — `.icon` is a resolved
                    // image:// URI Quickshell itself supplies; bound
                    // straight to source, exactly as the inline cell does.
                    // Tint mechanism identical to TrayCapsule.qml's own
                    // (see that file's own header comment for the full
                    // round-4 reasoning): "off" paints this IconImage
                    // directly; "monochrome" reads it as an ALPHA MASK
                    // ONLY over a flat fill; "desaturate" reads it as a
                    // plain saturation:-1.0 source. Never painted itself
                    // while either Loader below is active.
                    IconImage {
                        id: overflowIcon
                        width: Design.iconSizeMd
                        height: Design.iconSizeMd
                        implicitSize: Design.iconSizeMd
                        asynchronous: true
                        source: overflowRow.modelData ? overflowRow.modelData.icon : ""
                        visible: !root._tintActive
                        layer.enabled: root._tintActive
                    }

                    // The "monochrome" mode's ONLY colour source — never
                    // painted itself (visible: false always, so Row
                    // excludes it from layout unconditionally), fed into
                    // the mask MultiEffect below as `source`. Colours.onSurface
                    // is this popout's own content role (matches rowLabel
                    // below), never BarRoles.
                    Rectangle {
                        id: overflowSilhouetteFill
                        width: Design.iconSizeMd
                        height: Design.iconSizeMd
                        color: Colours.onSurface
                        visible: false
                        layer.enabled: root._tintMonochrome
                    }

                    // "monochrome" — the same NotifGroup.qml/NotifCard.qml
                    // picture-masking MultiEffect shape TrayCapsule.qml's
                    // own identical block reuses: `source` is the flat
                    // fill, `maskSource` is the icon (its ALPHA channel
                    // only), so the result is a flat silhouette by
                    // construction. Row excludes an invisible child AND
                    // its spacing, so visible/width/height are all gated
                    // on _tintMonochrome to reserve ZERO Row space
                    // whenever this mode is not active.
                    Loader {
                        visible: root._tintMonochrome
                        width: root._tintMonochrome ? Design.iconSizeMd : 0
                        height: root._tintMonochrome ? Design.iconSizeMd : 0
                        active: root._tintMonochrome
                        sourceComponent: MultiEffect {
                            anchors.fill: parent
                            source: overflowSilhouetteFill
                            maskEnabled: true
                            maskSource: overflowIcon
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                        }
                    }

                    // "desaturate" — greyscale, nothing else. No
                    // colorization tint, per the operator's own word
                    // choice (see TrayCapsule.qml's header comment for
                    // why the previous build's re-tint collapsed this
                    // mode into monochrome).
                    Loader {
                        visible: root._tintDesaturate
                        width: root._tintDesaturate ? Design.iconSizeMd : 0
                        height: root._tintDesaturate ? Design.iconSizeMd : 0
                        active: root._tintDesaturate
                        sourceComponent: MultiEffect {
                            anchors.fill: parent
                            source: overflowIcon
                            saturation: -1.0
                        }
                    }

                    Text {
                        id: rowLabel
                        anchors.verticalCenter: parent.verticalCenter
                        width: Design.popoutMaxWidth - Design.spacingMd * 2 - Design.iconSizeMd - Design.spacingSm
                        text: overflowRow._titleText
                        font.pixelSize: Design.fontBody
                        color: Colours.onSurface
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                }

                // Same three gestures as an inline cell (CORRECTIONs 2/3),
                // passing THIS popout's own window as display()'s parent.
                MouseArea {
                    id: overflowRowMouseArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    // Needed for containsMouse below (the tooltip's hover
                    // signal) — verified this changes no click behaviour.
                    hoverEnabled: true
                    onClicked: (mouse) => {
                        if (!overflowRow.modelData)
                            return;
                        if (mouse.button === Qt.MiddleButton) {
                            overflowRow.modelData.secondaryActivate();
                            return;
                        }
                        var origin = overflowRow.mapToItem(null, 0, overflowRow.height);
                        if (mouse.button === Qt.RightButton) {
                            overflowRow.modelData.display(QsWindow.window, origin.x, origin.y);
                            return;
                        }
                        // Left button.
                        if (overflowRow.modelData.onlyMenu)
                            overflowRow.modelData.display(QsWindow.window, origin.x, origin.y);
                        else
                            overflowRow.modelData.activate();
                    }
                }

                // ThemedToolTip, NOT BarTooltipHost — this row renders
                // inside SectionPopout's own window, several hundred
                // pixels tall (measured for the sibling popouts:
                // popoutH=334), so the QQC2 Popup clamp BarTooltipHost
                // exists to work around lands clear of this row with
                // nothing to fix (BarTooltipHost.qml's own header names
                // AudioPopout.qml/SectionPopout.qml as exactly this
                // family, and both already use ThemedToolTip — this row
                // follows that established, colour-token-bound precedent
                // rather than reaching for the bar-window mechanism).
                ThemedToolTip {
                    visible: overflowRowMouseArea.containsMouse && overflowRow._tooltipText !== ""
                    text: overflowRow._tooltipText
                }
            }
        }
    }
}
