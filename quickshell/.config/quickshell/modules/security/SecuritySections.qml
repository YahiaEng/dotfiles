// modules/security/SecuritySections.qml — plate S1. The domain-grouped
// layout: four sections, one per domain, in the shape
// `UpdatesPage.qml` already proves (quick task 260827-np1).
//
// Kept selectable alongside S2 rather than replaced by it. Two reasons,
// both precedent in this repo: a layout Loader whose component fails
// leaves an empty pane rather than a dead shell, so the other layout is
// the way back out of a bad render; and the two answer different
// questions — S2 answers "am I OK?", this answers "how are my disks?"
// without filtering a merged list.
//
// Reads the SAME `SecurityBackend.findings` the feed does, then buckets
// by domain. It does NOT re-derive severity or re-sort — one ordering
// truth, so the two layouts can never disagree about what is worst.
import QtQuick
import ".."
import "../dashboard"

Column {
    id: root

    width: parent ? parent.width : 400
    spacing: Design.spacingXl

    readonly property var domains: ["Malware", "Vulnerabilities", "Network", "Devices"]

    function _iconFor(domain) {
        switch (domain) {
        case "Malware":
            return "coronavirus";
        case "Vulnerabilities":
            return "shield_question";
        case "Network":
            return "lan";
        default:
            return "hard_drive";
        }
    }

    function _findingsIn(domain) {
        return SecurityBackend.findings.filter(f => f.domain === domain);
    }

    Repeater {
        model: root.domains

        Column {
            id: section

            required property var modelData

            width: root.width
            spacing: Design.spacingSm

            readonly property var rows: root._findingsIn(section.modelData)

            Row {
                spacing: Design.spacingSm

                Text {
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.iconSizeMd
                    text: root._iconFor(section.modelData)
                    color: Colours.onSurfaceVariant
                }
                Text {
                    text: section.modelData
                    font.pixelSize: Design.settingsFontRow
                    font.weight: Design.weightEmphasis
                    color: Colours.onSurfaceVariant
                }
            }

            Rectangle {
                width: parent.width
                height: sectionCol.implicitHeight
                radius: 14
                color: Colours.surfaceVariant

                Column {
                    id: sectionCol
                    width: parent.width

                    Repeater {
                        model: section.rows

                        FindingRow {
                            required property var modelData

                            width: sectionCol.width
                            finding: modelData
                            // The section header already names the
                            // domain; repeating it on every row would be
                            // noise.
                            showDomain: false
                            indexLabel: modelData ? modelData.id : ""
                        }
                    }

                    Item {
                        width: parent.width
                        height: section.rows.length === 0 ? 64 : 0
                        visible: section.rows.length === 0

                        Text {
                            anchors.centerIn: parent
                            text: SecurityBackend.everythingProbed ? "Nothing to report." : "Checking…"
                            font.pixelSize: Design.settingsFontSub
                            color: Colours.onSurfaceVariant
                        }
                    }
                }
            }

            // The scan control belongs to the Malware section here,
            // rather than to a page-level header — this layout has no
            // page-level header by design.
            Rectangle {
                visible: section.modelData === "Malware" && SecurityBackend.hasTool("clamav")
                width: sectionScanLabel.implicitWidth + Design.spacingLg * 2
                height: 36
                radius: 999
                color: SecurityBackend.scanRunning ? Qt.alpha(Colours.outline, 0.4) : Colours.primary

                Text {
                    id: sectionScanLabel
                    anchors.centerIn: parent
                    text: SecurityBackend.scanRunning ? "Cancel scan · " + SecurityBackend.scanFilesSeen + " files" : "Scan now"
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
}
