// modules/security/FindingRow.qml — one finding, rendered identically
// wherever it appears (quick task 260827-np1).
//
// Composed the same way `settings/common/InfoRow.qml` is — same paddings,
// same 12px radius, same `focusable`/`rowFocused` markers — so
// `Pages.qml:_collectFocusableRows()`'s denominator stays uniform across
// row types and a finding is reachable by keyboard and by RowIndex
// search, not only by scrolling. It is NOT in settings/common/ because
// it is not a settings row: it carries a severity and an action verb,
// and only the Security Center has those.
//
// ── SEVERITY IS DRAWN ON THE FOREGROUND, NOT THE CARD ─────────────────
// On dracula, `surfaceVariant`/`primaryContainer`/`secondaryContainer`
// are byte-identical, so there is exactly one container tint above
// surface and a severity-tinted card back would render two adjacent
// severities as the same slab. The glyph chip and the left rim carry
// severity here; the card behind stays neutral. Severity.qml's header
// records the measurement.
//
// ── THE ACTION BUTTON IS ARMED, NOT IMMEDIATE ─────────────────────────
// `actionVerb` runs a privileged, state-changing command on the live
// machine — enabling a packet filter, installing a package. A single
// stray click must not do that, so the button arms on first click and
// fires on second, disarming itself after 6s. This mirrors
// `UpdatesPage.qml`'s own two-step arm for per-package updates
// (quick-260826-437 Task 3, D-6), which exists for the same reason.
import QtQuick
import ".."
import "../dashboard"

Item {
    id: root

    // The finding record, as built by SecurityBackend._buildFindings().
    property var finding: null

    readonly property int rank: finding ? finding.rank : Severity.rankAbsent
    readonly property string title: finding ? (finding.title || "") : ""
    readonly property string detail: finding ? (finding.detail || "") : ""
    readonly property string domain: finding ? (finding.domain || "") : ""
    readonly property string actionVerb: finding ? (finding.actionVerb || "") : ""
    readonly property string actionLabel: finding ? (finding.actionLabel || "") : ""

    // Show the domain chip only where the list mixes domains (the S2
    // findings feed). The S1 sections layout groups by domain already, so
    // a chip there would repeat the section header on every row.
    property bool showDomain: true

    // indexLabel — the string RowIndex keys on and settings-index-check
    // greps for. Findings are generated from live data, so their visible
    // `title` is dynamic and cannot be a stable jump key; call sites pass
    // a fixed one.
    property string indexLabel: ""

    readonly property bool focusable: true
    property bool rowFocused: false

    property bool _armed: false

    implicitWidth: parent ? parent.width : 400
    implicitHeight: Math.max(56, contentRow.implicitHeight + Design.spacingMd * 2)
    width: parent ? parent.width : 400

    Timer {
        id: disarmTimer
        interval: 6000
        running: false
        onTriggered: root._armed = false
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "transparent"
        border.width: 2
        border.color: root.rowFocused ? Colours.primary : Qt.alpha(Colours.primary, 0)

        Behavior on border.color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.colourDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.colourEasing
            }
        }
    }

    // Severity rim — a thin left edge, the one place severity touches the
    // card's own geometry.
    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: Design.spacingXs
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height - Design.spacingMd
        radius: 2
        color: Severity.rim(root.rank)
        visible: root.rank <= Severity.rankLow

        Behavior on color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.colourDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.colourEasing
            }
        }
    }

    Row {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: Design.spacingMd
        anchors.rightMargin: Design.spacingMd
        anchors.topMargin: Design.spacingMd
        anchors.bottomMargin: Design.spacingMd
        spacing: Design.spacingMd

        // ── Severity glyph ──
        Rectangle {
            id: glyphChip
            width: Design.settingsIconSize
            height: Design.settingsIconSize
            radius: 8
            anchors.verticalCenter: parent.verticalCenter
            color: Severity.back(root.rank)

            Text {
                anchors.centerIn: parent
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.fontBody
                text: Severity.glyph(root.rank)
                color: Severity.fg(root.rank)

                // A scan in progress is the one rank that earns motion —
                // it is the only state that is actively changing.
                RotationAnimator on rotation {
                    running: root.rank === Severity.rankScanning && Motion.motionEnabled
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    // ambientDuration is the loop-period token —
                    // never a one-shot transition duration. Same idiom
                    // WifiPanel/SelectRow's indeterminate spinners use.
                    duration: Motion.ambientDuration
                }
            }
        }

        // ── Text column ──
        Column {
            id: textCol
            width: parent.width - glyphChip.width - actionSlot.width - parent.spacing * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: root.title
                font.pixelSize: Design.settingsFontRow
                color: Colours.onSurface
                elide: Text.ElideRight
            }

            Row {
                width: parent.width
                spacing: Design.spacingXs

                Rectangle {
                    visible: root.showDomain && root.domain.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: domainText.implicitWidth + Design.spacingSm
                    height: domainText.implicitHeight + 2
                    radius: 4
                    color: Qt.alpha(Colours.outline, 0.28)

                    Text {
                        id: domainText
                        anchors.centerIn: parent
                        text: root.domain.toUpperCase()
                        font.pixelSize: Design.fontLabel - 2
                        color: Colours.onSurfaceVariant
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - (root.showDomain && root.domain.length > 0 ? domainText.implicitWidth + Design.spacingSm + Design.spacingXs : 0)
                    text: root.detail
                    font.pixelSize: Design.settingsFontSub
                    color: Colours.onSurfaceVariant
                    elide: Text.ElideRight
                }
            }
        }

        // ── Action ──
        Item {
            id: actionSlot
            width: root.actionVerb.length > 0 ? actionPill.width : 0
            height: parent.height
            visible: root.actionVerb.length > 0

            Rectangle {
                id: actionPill
                anchors.verticalCenter: parent.verticalCenter
                width: actionText.implicitWidth + Design.spacingMd * 2
                height: 30
                radius: 999
                // Armed state is loud on purpose: the second click is
                // the one that changes the system.
                color: root._armed ? Colours.error : (SecurityBackend.actionRunning ? Qt.alpha(Colours.outline, 0.4) : Colours.primary)

                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.colourDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.colourEasing
                    }
                }

                Text {
                    id: actionText
                    anchors.centerIn: parent
                    text: root._armed ? "Confirm" : root.actionLabel
                    font.pixelSize: Design.settingsFontSub
                    font.weight: Design.weightEmphasis
                    color: root._armed ? Colours.onError : Colours.onPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !SecurityBackend.actionRunning
                    onClicked: {
                        if (root._armed) {
                            root._armed = false;
                            disarmTimer.stop();
                            SecurityBackend.runAction(root.actionVerb);
                        } else {
                            root._armed = true;
                            disarmTimer.restart();
                        }
                    }
                }
            }
        }
    }
}
