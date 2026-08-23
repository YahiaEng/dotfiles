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

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Design.spacingSm

                    // CORRECTION 1 (CONTEXT.md) — `.icon` is a resolved
                    // image:// URI Quickshell itself supplies; bound
                    // straight to source, exactly as the inline cell does.
                    IconImage {
                        width: Design.iconSizeMd
                        height: Design.iconSizeMd
                        implicitSize: Design.iconSizeMd
                        asynchronous: true
                        source: overflowRow.modelData ? overflowRow.modelData.icon : ""
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
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
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
            }
        }
    }
}
