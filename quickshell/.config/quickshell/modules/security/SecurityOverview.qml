// modules/security/SecurityOverview.qml — the Security Center's one
// settings layout (quick task 260827-np1, operator round 3).
//
// ── WHY ONE LAYOUT AND NOT TWO ────────────────────────────────────────
// This ships as a MERGE of the two plates the operator originally picked,
// because in use they turned out to be redundant rather than
// complementary — operator round 3: "both security layouts feel
// redundant, they should be combined".
//
// What each contributed, and what survived:
//   * S2 "Findings feed"    — the verdict header, and RANKING. Kept.
//   * S1 "Four sections"    — domain grouping. Kept.
//
// The merge orders DOMAINS by their own worst finding, and rows WITHIN a
// domain worst-first. So the thing that needs attention is still the
// first thing you read (S2's whole point), while "how are my disks?"
// stays answerable without filtering a mixed list (S1's whole point).
// Neither layout's value is lost, and there is no picker to maintain.
//
// Ordering still comes from SecurityBackend.findings and is NEVER
// re-derived here — one ordering truth, so this page, the dashboard tab
// and the bar glyph cannot disagree about what is worst.
//
// A plain Column, not a PageBase: SecurityPage.qml owns the page chrome.
import QtQuick
import ".."
import "../dashboard"

Column {
    id: root

    width: parent ? parent.width : 400
    spacing: Design.spacingLg

    // ── SECTION ORDER IS FIXED. THIS IS THE POINT. ────────────────────
    // The first version ordered domains by their own worst finding, so
    // enabling the firewall moved the whole Network section from directly
    // under Overview to below Vulnerabilities — operator round 5. A
    // settings page you navigate by muscle memory must not rearrange
    // itself as live state changes; you go to look at your disks and the
    // heading has moved because something unrelated got better.
    //
    // Severity is still expressed, in the two places where it costs
    // nothing: the verdict header names what is worst globally, and rows
    // are still ranked worst-first WITHIN each section (that ordering
    // comes from SecurityBackend.findings and is never re-derived here).
    // Only the section order is now stable.
    //
    // A domain with nothing to say still earns no heading — the list is
    // filtered, not padded.
    readonly property var domainOrder: ["Malware", "Vulnerabilities", "Network", "Devices"]

    readonly property var orderedDomains: {
        var present = {};
        var f = SecurityBackend.findings;
        for (var i = 0; i < f.length; ++i)
            present[f[i].domain] = true;

        var out = [];
        for (var d = 0; d < root.domainOrder.length; ++d) {
            if (present[root.domainOrder[d]])
                out.push(root.domainOrder[d]);
        }
        // Anything the backend reports under a domain this list does not
        // know about is appended rather than dropped — a new domain must
        // never silently vanish from the page.
        for (var k in present) {
            if (root.domainOrder.indexOf(k) === -1)
                out.push(k);
        }
        return out;
    }

    function _findingsIn(domain) {
        return SecurityBackend.findings.filter(f => f.domain === domain);
    }

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

    // ── Posture header ─────────────────────────────────────────────
    Rectangle {
        width: parent.width
        height: postureCol.implicitHeight + Design.spacingLg * 2
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
                    // While scanning, say what is happening RIGHT NOW.
                    // clamscan spends several seconds loading 3.6M
                    // signatures before touching a file, and a bar with no
                    // caption during that window is indistinguishable from
                    // a hang — which is exactly how the operator read it.
                    text: {
                        if (SecurityBackend.scanRunning) {
                            if (SecurityBackend.scanLoadingDb)
                                return "Loading virus signatures… (this takes a few seconds)";
                            var where = SecurityBackend.scanCurrentPath;
                            if (where.length > 48)
                                where = "…" + where.substring(where.length - 47);
                            return SecurityBackend.scanFilesSeen + " files checked · " + SecurityBackend.scanThreats + " threat(s) · " + where;
                        }
                        // Name the unfixable share explicitly. "17
                        // issues need attention" is true but reads as 17
                        // things you are neglecting, when in fact none of
                        // them can be acted on today. The count stays
                        // honest; the sentence explains it.
                        var parts = [];
                        if (SecurityBackend.unfixableCveCount > 0)
                            parts.push(SecurityBackend.unfixableCveCount + " awaiting an upstream fix");
                        if (SecurityBackend.absentCount > 0)
                            parts.push(SecurityBackend.absentCount + " not set up");
                        parts.push(SecurityBackend.healthyCount + " healthy");
                        return parts.join(" · ");
                    }
                    font.pixelSize: Design.settingsFontSub
                    color: Colours.onSurfaceVariant
                    wrapMode: Text.WordWrap
                }

                // ── Indeterminate bar (operator round 4: "moves to one
                //    end then teleports", and "moves out of bounds" after
                //    reopening the page) ────────────────────────────────
                // Both were the same mistake: `XAnimator on x` with
                // `from`/`to` captured at animation START.
                //   * loops:Infinite RESTARTS at `from`, it does not
                //     reverse — hence the teleport back to the left.
                //   * `to` was frozen at whatever the track width was
                //     when the animation began. Reopening the page starts
                //     it while the width is still 0 or stale, so the bead
                //     later travels to a value that no longer fits —
                //     hence out of bounds. This is the same
                //     configured-after-construction trap recorded for
                //     Loaders.
                // Fix: animate a unitless 0..1 driver and DERIVE x from
                // the live width, so a resize is followed automatically
                // and the value can never exceed the track. The
                // ping-pong is explicit rather than implied.
                Rectangle {
                    id: progressTrack
                    visible: SecurityBackend.scanRunning
                    width: parent.width
                    height: 4
                    radius: 999
                    color: Qt.alpha(Colours.outline, 0.35)
                    clip: true

                    property real sweep: 0

                    SequentialAnimation on sweep {
                        running: progressTrack.visible && Motion.motionEnabled
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: 0
                            to: 1
                            duration: Motion.ambientDuration
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            from: 1
                            to: 0
                            duration: Motion.ambientDuration
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Rectangle {
                        id: progressBead
                        width: Math.max(24, progressTrack.width * 0.28)
                        height: parent.height
                        radius: 999
                        color: Severity.scanning
                        // Bound, never animated directly — this is what
                        // makes a width change safe.
                        x: Math.max(0, (progressTrack.width - width) * progressTrack.sweep)
                    }
                }
            }

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

    // ── Error banner ───────────────────────────────────────────────
    // Operator round 3: pressing Enable on the firewall did nothing and
    // the button silently reset. The cause was a pkexec exit-code
    // misread (127 treated as "cancelled"), but the reason it was
    // INVISIBLE is that nothing ever displayed actionError. A privileged
    // action that fails must say so.
    Rectangle {
        width: parent.width
        visible: SecurityBackend.actionError.length > 0 || SecurityBackend.helperMissing
        height: errCol.implicitHeight + Design.spacingMd * 2
        radius: 14
        color: Severity.back(Severity.rankCritical)
        border.width: 1
        border.color: Severity.rim(Severity.rankCritical)

        Row {
            anchors.fill: parent
            anchors.margins: Design.spacingMd
            spacing: Design.spacingMd

            Text {
                id: errGlyph
                anchors.verticalCenter: parent.verticalCenter
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                text: "error"
                color: Severity.fg(Severity.rankCritical)
            }

            Column {
                id: errCol
                width: parent.width - errGlyph.width - dismissBtn.width - parent.spacing * 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: SecurityBackend.actionError.length > 0 ? "That action did not run" : "Privileged actions are unavailable"
                    font.pixelSize: Design.settingsFontRow
                    color: Colours.onSurface
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: SecurityBackend.actionError.length > 0 ? SecurityBackend.actionError : "The helper at " + SecurityBackend.helperPath + " is not installed. Run install.sh to place it; until then Enable and Install cannot work."
                    font.pixelSize: Design.settingsFontSub
                    color: Colours.onSurfaceVariant
                    wrapMode: Text.WordWrap
                }
            }

            Item {
                id: dismissBtn
                width: SecurityBackend.actionError.length > 0 ? dismissText.implicitWidth + Design.spacingMd : 0
                height: parent.height
                visible: SecurityBackend.actionError.length > 0

                Text {
                    id: dismissText
                    anchors.centerIn: parent
                    text: "Dismiss"
                    font.pixelSize: Design.settingsFontSub
                    color: Colours.onSurfaceVariant
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SecurityBackend.actionError = ""
                }
            }
        }
    }

    // ── Findings, grouped by domain, worst domain first ────────────
    Repeater {
        model: root.orderedDomains

        Column {
            id: section

            required property var modelData

            width: root.width
            spacing: Design.spacingSm

            readonly property var allRows: root._findingsIn(section.modelData)

            // ── Unfixable CVEs collapse into ONE row ─────────────────
            // Operator round 5. On this host all 17 affected packages
            // report status "Vulnerable" with no fixed version, so 17
            // non-actionable rows pushed Network and Devices off the
            // screen entirely. They are still counted in the verdict and
            // still readable one click away — collapsed, never dropped.
            //
            // Collapsing is scoped to CVEs with `fixable === false`.
            // Nothing else in the pane is ever hidden behind a
            // disclosure: every other finding either has a button or
            // names a state you can do something about.
            readonly property var rows: section.allRows.filter(f => !(f.isCve === true && f.fixable === false))
            readonly property var hiddenRows: section.allRows.filter(f => f.isCve === true && f.fixable === false)

            property bool expanded: false

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
                            // The heading already names the domain.
                            showDomain: false
                            indexLabel: modelData ? modelData.id : ""
                        }
                    }

                    // ── The disclosure row ──
                    Item {
                        width: sectionCol.width
                        height: section.hiddenRows.length > 0 ? Math.max(56, discRow.implicitHeight + Design.spacingMd * 2) : 0
                        visible: section.hiddenRows.length > 0

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: Design.spacingXs
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: parent.height - Design.spacingMd
                            radius: 2
                            color: Severity.rim(Severity.rankAbsent)
                        }

                        Row {
                            id: discRow
                            anchors.fill: parent
                            anchors.leftMargin: Design.spacingMd
                            anchors.rightMargin: Design.spacingMd
                            anchors.topMargin: Design.spacingMd
                            anchors.bottomMargin: Design.spacingMd
                            spacing: Design.spacingMd

                            Rectangle {
                                id: discChip
                                width: Design.settingsIconSize
                                height: Design.settingsIconSize
                                radius: 8
                                anchors.verticalCenter: parent.verticalCenter
                                color: Severity.back(Severity.rankAbsent)

                                Text {
                                    anchors.centerIn: parent
                                    font.family: Design.symbolFontFamily
                                    font.pixelSize: Design.fontBody
                                    text: "hourglass_empty"
                                    color: Severity.fg(Severity.rankAbsent)
                                }
                            }

                            Column {
                                width: discRow.width - discChip.width - discChevron.width - discRow.spacing * 2
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: section.hiddenRows.length + (section.hiddenRows.length === 1 ? " vulnerability has no fix yet" : " vulnerabilities have no fix yet")
                                    font.pixelSize: Design.settingsFontRow
                                    color: Colours.onSurface
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    // Say WHY there is nothing to do, so
                                    // this does not read as the pane
                                    // giving up. Arch has acknowledged
                                    // these but has not shipped a fixed
                                    // package; your system is current.
                                    text: section.expanded ? "Arch has acknowledged these but not yet released a fix. Nothing to install." : "Arch has acknowledged these but not yet released a fix — tap to review them."
                                    font.pixelSize: Design.settingsFontSub
                                    color: Colours.onSurfaceVariant
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Text {
                                id: discChevron
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: Design.symbolFontFamily
                                font.pixelSize: Design.iconSizeMd
                                text: "expand_more"
                                color: Colours.onSurfaceVariant
                                rotation: section.expanded ? 180 : 0

                                Behavior on rotation {
                                    enabled: Motion.motionEnabled
                                    NumberAnimation {
                                        duration: Motion.standardDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Motion.standardEasing
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: section.expanded = !section.expanded
                        }
                    }

                    // The collapsed rows themselves.
                    Repeater {
                        model: section.expanded ? section.hiddenRows : []

                        FindingRow {
                            required property var modelData

                            width: sectionCol.width
                            finding: modelData
                            showDomain: false
                            indexLabel: modelData ? modelData.id : ""
                        }
                    }
                }
            }
        }
    }

    // A machine with nothing to report must not render an empty page.
    Item {
        width: parent.width
        height: root.orderedDomains.length === 0 ? 88 : 0
        visible: root.orderedDomains.length === 0

        Text {
            anchors.centerIn: parent
            text: SecurityBackend.everythingProbed ? "Nothing to report." : "Checking…"
            font.pixelSize: Design.settingsFontSub
            color: Colours.onSurfaceVariant
        }
    }
}
