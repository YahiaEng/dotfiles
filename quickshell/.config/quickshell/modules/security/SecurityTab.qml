// modules/security/SecurityTab.qml — plate D1, the dashboard drawer's
// fifth tab (quick task 260827-np1).
//
// A five-cell bento: one full-width verdict over four domain cells.
// Reads the SAME `SecurityBackend.findings` the settings page does and
// re-derives nothing, so the drawer and the page can never disagree.
//
// ── WHAT THIS PLATE COSTS, RECORDED WHERE IT IS PAID ──────────────────
// The study called this the one direction that makes an existing defect
// worse, and shipping it does not make that untrue:
//
//   `Dashboard.qml`'s `drawerWidth` is `max(drawerMinWidth,
//   activeContentWidth + spacingLg*2)`, and `activeContentWidth` is the
//   ACTIVE tab's own `implicitWidth`. Tabs therefore disagree about
//   width and the drawer animates between them on every crossing.
//
// So this tab declares `implicitWidth: Design.dashboardMinWidth` — the
// drawer's own floor — rather than a width of its own. That makes
// crossing INTO Security cost no width animation at all. It cannot fix
// the pre-existing Dashboard/Performance disagreement, but it
// deliberately does not add a fifth number to it.
//
// It is also why this tab defaults OFF in Prefs: it is the one surface
// here that adds nothing the bar capsule does not already give, and the
// capsule costs no tab.
import QtQuick
import ".."
import "../dashboard"

Item {
    id: root

    property real settledPaneWidth: 0
    property real settledPaneHeight: 0

    // Match the drawer's floor exactly — see the header.
    implicitWidth: Design.dashboardMinWidth
    implicitHeight: bento.implicitHeight

    function _domainFinding(domain) {
        var f = SecurityBackend.findings.filter(x => x.domain === domain);
        return f.length > 0 ? f[0] : null;
    }

    Column {
        id: bento
        width: parent.width
        spacing: Design.spacingSm

        // ── Verdict, full width ──
        Rectangle {
            width: parent.width
            height: verdictCol.implicitHeight + Design.spacingMd * 2
            radius: 16
            color: Colours.surfaceVariant
            border.width: 1
            border.color: Severity.rim(SecurityBackend.worstRank)

            Behavior on border.color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }

            Column {
                id: verdictCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Design.spacingMd
                anchors.rightMargin: Design.spacingMd
                spacing: Design.spacingXs

                Row {
                    spacing: Design.spacingSm

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: Severity.fg(SecurityBackend.worstRank)
                    }
                    Text {
                        text: "POSTURE"
                        font.pixelSize: Design.fontLabel
                        font.weight: Design.weightEmphasis
                        color: Colours.onSurfaceVariant
                    }
                }

                Text {
                    width: parent.width
                    text: {
                        if (!SecurityBackend.everythingProbed)
                            return "Checking…";
                        var top = SecurityBackend.findings.length > 0 ? SecurityBackend.findings[0] : null;
                        if (!top || top.rank > Severity.rankLow)
                            return "Nothing needs attention";
                        return top.title;
                    }
                    font.pixelSize: Design.fontHeading
                    font.weight: Design.weightEmphasis
                    color: SecurityBackend.worstRank <= Severity.rankLow ? Severity.fg(SecurityBackend.worstRank) : Colours.onSurface
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: SecurityBackend.scanRunning ? "Virus scan running · " + SecurityBackend.scanFilesSeen + " files" : SecurityBackend.actionableCount + " actionable · " + SecurityBackend.absentCount + " not set up · " + SecurityBackend.healthyCount + " healthy"
                    font.pixelSize: Design.fontLabel
                    color: Colours.onSurfaceVariant
                    elide: Text.ElideRight
                }
            }
        }

        // ── Four domain cells, 2x2 ──
        Grid {
            width: parent.width
            columns: 2
            spacing: Design.spacingSm

            Repeater {
                model: ["Malware", "Vulnerabilities", "Network", "Devices"]

                Rectangle {
                    id: cell

                    required property var modelData

                    // NOT `top` — that name collides with a FINAL
                    // property on Item and the whole shell fails to load
                    // with "Cannot override FINAL property". No lint in
                    // this repo can see that; only the hot-reload line in
                    // ~/.cache/quickshell.log reports it.
                    readonly property var topFinding: root._domainFinding(cell.modelData)
                    readonly property int cellRank: cell.topFinding ? cell.topFinding.rank : Severity.rankAbsent

                    width: (bento.width - Design.spacingSm) / 2
                    height: cellCol.implicitHeight + Design.spacingMd * 2
                    radius: 16
                    color: Colours.surfaceVariant

                    Column {
                        id: cellCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Design.spacingMd
                        anchors.rightMargin: Design.spacingMd
                        spacing: Design.spacingXs

                        Row {
                            spacing: Design.spacingSm

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                anchors.verticalCenter: parent.verticalCenter
                                color: Severity.fg(cell.cellRank)
                            }
                            Text {
                                text: cell.modelData.toUpperCase()
                                font.pixelSize: Design.fontLabel
                                font.weight: Design.weightEmphasis
                                color: Colours.onSurfaceVariant
                            }
                        }

                        Text {
                            width: parent.width
                            text: Severity.label(cell.cellRank)
                            font.pixelSize: Design.fontHeading
                            font.weight: Design.weightEmphasis
                            color: Colours.onSurface
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: cell.topFinding ? cell.topFinding.title : "Nothing to report"
                            font.pixelSize: Design.fontLabel
                            color: Colours.onSurfaceVariant
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
