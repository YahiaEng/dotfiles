// modules/security/SecurityCapsule.qml — plate H1's bar half (quick
// task 260827-np1).
//
// ── THIS IS THE PIECE THAT ANSWERS THE ARCHITECTURE PROBLEM ───────────
// A clamscan runs for minutes. The settings window can be closed the
// moment it starts. Without this capsule there is NOWHERE in the session
// that says a scan is running — the operator's only feedback would be a
// fan spinning up. The scan already outlives its page because
// SecurityBackend is a singleton; this is what makes that fact visible.
//
// ── VISIBILITY RULE: EARN THE SPACE ───────────────────────────────────
// A permanent security chip on a healthy machine is clutter, and clutter
// is how a real alert gets ignored. So the capsule shows itself only
// when it has something to say:
//
//   * a scan is running, or
//   * there is at least one finding at Low or worse.
//
// "Not installed" alone does NOT surface it — an absent scanner is a
// setup task, not an alert, and a capsule that nags about optional tools
// on every fresh install is exactly the boy-who-cried-wolf failure.
// That is why the pref can default ON: on a clean machine it costs no
// bar space at all.
import QtQuick
import Quickshell
import ".."
import "../dashboard"

Item {
    id: root

    // Bar capsules are laid out by their implicit size; collapsing to
    // zero width is how this one takes no space when it has nothing to
    // report. `visible: false` alone would still reserve nothing, but an
    // explicit 0 width keeps neighbouring capsule spacing honest.
    readonly property bool shouldShow: Prefs.getValue("security.showCapsule") === true && (SecurityBackend.scanRunning || SecurityBackend.actionableCount > 0)

    readonly property int shownRank: SecurityBackend.scanRunning ? Severity.rankScanning : SecurityBackend.worstRank

    visible: root.shouldShow
    implicitWidth: root.shouldShow ? pill.implicitWidth : 0
    implicitHeight: root.shouldShow ? pill.implicitHeight : 0

    Rectangle {
        id: pill

        implicitWidth: contentRow.implicitWidth + Design.spacingMd * 2
        implicitHeight: 30
        radius: 999
        color: Severity.back(root.shownRank)
        border.width: 1
        border.color: Severity.rim(root.shownRank)

        Behavior on color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.colourDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.colourEasing
            }
        }
        Behavior on border.color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.colourDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.colourEasing
            }
        }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: Design.spacingSm

            Text {
                id: capsuleGlyph
                anchors.verticalCenter: parent.verticalCenter
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.fontLabel + 2
                text: Severity.glyph(root.shownRank)
                color: Severity.fg(root.shownRank)

                RotationAnimator on rotation {
                    running: SecurityBackend.scanRunning && Motion.motionEnabled
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    // Loop-period token, never a one-shot duration.
                    duration: Motion.ambientDuration
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                // While scanning, the count of files is the only number
                // that is actually moving — a percentage would be
                // invented, since clamscan reports no total up front.
                text: SecurityBackend.scanRunning ? "Scanning" : String(SecurityBackend.actionableCount)
                font.pixelSize: Design.fontLabel
                font.weight: Design.weightEmphasis
                color: Severity.fg(root.shownRank)
            }
        }

        MouseArea {
            id: capsuleMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            // Opens the Security settings page by its own slug, through
            // the shell's existing deep-link verb — no new IPC target to
            // register.
            //
            // TWO measured details in this one line:
            //   * the verb is `openPage`, not `open` — `settings.open`
            //     takes no argument (shell.qml:1499) and would open the
            //     window on whatever page was last shown.
            //   * the `--` is load-bearing: `qs ipc call <target> <verb>`
            //     silently no-ops on a CLI11 subcommand collision. Always
            //     `qs ipc call -- <target> <verb>`.
            //
            // execDetached, never a component-scoped Process: this
            // capsule lives in the bar, and the launched call must not
            // die with any surface.
            onClicked: Quickshell.execDetached(["qs", "ipc", "call", "--", "settings", "openPage", "security"])

            ThemedToolTip {
                visible: capsuleMouseArea.containsMouse
                text: SecurityBackend.scanRunning ? "Virus scan running — " + SecurityBackend.scanFilesSeen + " files, " + SecurityBackend.scanThreats + " threat(s)" : (SecurityBackend.findings.length > 0 ? SecurityBackend.findings[0].title : "Security")
            }
        }
    }
}
