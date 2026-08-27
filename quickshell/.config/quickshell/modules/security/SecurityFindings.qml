// modules/security/SecurityFindings.qml — plate S2, the default layout.
// A posture verdict, then one severity-ordered feed across all four
// domains (quick task 260827-np1).
//
// The thesis the operator picked this for: the pane exists to answer
// "am I OK?", and a domain-grouped page makes you read four sections to
// find out. Here the answer is the first line, and every finding
// competes on one list worst-first — "no firewall" outranks a disk
// temperature because SecurityBackend.findings is sorted by rank, not by
// domain.
//
// This is a plain Column, NOT a PageBase: SecurityPage.qml owns the page
// chrome and Loader-switches between this and SecuritySections. A layout
// file knows nothing about being one of several.
import QtQuick
import ".."
import "../dashboard"

Column {
    id: root

    width: parent ? parent.width : 400
    spacing: Design.spacingLg

    // ── Posture header ─────────────────────────────────────────────
    Rectangle {
        width: parent.width
        height: postureCol.implicitHeight + Design.spacingLg * 2
        radius: 16
        // Neutral card, severity carried by the shield and the rim —
        // see FindingRow's header on why a tinted back cannot work here.
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

        Row {
            anchors.fill: parent
            anchors.margins: Design.spacingLg
            spacing: Design.spacingLg

            Rectangle {
                id: shield
                width: 54
                height: 54
                radius: 16
                anchors.verticalCenter: parent.verticalCenter
                color: Severity.back(SecurityBackend.worstRank)

                Text {
                    anchors.centerIn: parent
                    font.family: Design.symbolFontFamily
                    font.pixelSize: 28
                    text: Severity.glyph(SecurityBackend.worstRank)
                    color: Severity.fg(SecurityBackend.worstRank)
                }
            }

            Column {
                id: postureCol
                width: parent.width - shield.width - scanBtn.width - parent.spacing * 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: Design.spacingXs

                Text {
                    width: parent.width
                    text: {
                        if (!SecurityBackend.everythingProbed)
                            return "Checking this machine…";
                        var n = SecurityBackend.actionableCount;
                        if (n === 0)
                            return "Nothing needs attention";
                        return n === 1 ? "1 issue needs attention" : n + " issues need attention";
                    }
                    font.pixelSize: Design.settingsFontTitle - 2
                    font.weight: Design.weightEmphasis
                    color: Colours.onSurface
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: SecurityBackend.scanRunning ? "Virus scan running · " + SecurityBackend.scanThreats + " threat(s) so far · you can leave this page" : (SecurityBackend.absentCount > 0 ? SecurityBackend.absentCount + " capability not set up · " + SecurityBackend.healthyCount + " healthy" : SecurityBackend.healthyCount + " healthy")
                    font.pixelSize: Design.settingsFontSub
                    color: Colours.onSurfaceVariant
                    wrapMode: Text.WordWrap
                }

                // Progress — only while a scan runs. Indeterminate,
                // because clamscan does not report a total up front and
                // a fake percentage would be a lie about how long is left.
                Rectangle {
                    visible: SecurityBackend.scanRunning
                    width: parent.width
                    height: 4
                    radius: 999
                    color: Qt.alpha(Colours.outline, 0.35)

                    Rectangle {
                        id: progressBead
                        width: parent.width * 0.28
                        height: parent.height
                        radius: 999
                        color: Severity.scanning

                        XAnimator on x {
                            running: SecurityBackend.scanRunning && Motion.motionEnabled
                            loops: Animation.Infinite
                            from: 0
                            to: progressBead.parent.width - progressBead.width
                            // Loop period, not a transition — see
                            // FindingRow.qml's spinner for the same token.
                            duration: Motion.ambientDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            // Scan / cancel. The same control both ways — a separate
            // Cancel button would be dead weight for the 99% of the time
            // no scan is running.
            Rectangle {
                id: scanBtn
                anchors.verticalCenter: parent.verticalCenter
                width: scanLabel.implicitWidth + Design.spacingLg * 2
                height: 36
                radius: 999
                color: SecurityBackend.scanRunning ? Qt.alpha(Colours.outline, 0.4) : Colours.primary
                visible: SecurityBackend.hasTool("clamav")

                Text {
                    id: scanLabel
                    anchors.centerIn: parent
                    text: SecurityBackend.scanRunning ? "Cancel" : "Scan now"
                    font.pixelSize: Design.settingsFontSub
                    font.weight: Design.weightEmphasis
                    color: SecurityBackend.scanRunning ? Colours.onSurface : Colours.onPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (SecurityBackend.scanRunning)
                            SecurityBackend.cancelScan();
                        else
                            SecurityBackend.startVirusScan();
                    }
                }
            }
        }
    }

    // ── Findings feed ──────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: Design.spacingSm

        Text {
            text: "Findings · worst first"
            font.pixelSize: Design.fontLabel
            font.weight: Design.weightEmphasis
            color: Colours.outline
        }

        Rectangle {
            width: parent.width
            height: feedCol.implicitHeight
            radius: 14
            color: Colours.surfaceVariant

            Column {
                id: feedCol
                width: parent.width

                Repeater {
                    model: SecurityBackend.findings

                    FindingRow {
                        required property var modelData
                        required property int index

                        width: feedCol.width
                        finding: modelData
                        showDomain: true
                        // A stable jump key per finding id — the visible
                        // title is generated from live data and cannot be
                        // one.
                        indexLabel: modelData ? modelData.id : ""
                    }
                }

                // A machine with nothing to report must not render an
                // empty card — that reads as broken rather than as clean.
                Item {
                    width: parent.width
                    height: SecurityBackend.findings.length === 0 ? 88 : 0
                    visible: SecurityBackend.findings.length === 0

                    Text {
                        anchors.centerIn: parent
                        text: SecurityBackend.everythingProbed ? "Nothing to report." : "Checking…"
                        font.pixelSize: Design.settingsFontSub
                        color: Colours.onSurfaceVariant
                    }
                }
            }
        }
    }
}
