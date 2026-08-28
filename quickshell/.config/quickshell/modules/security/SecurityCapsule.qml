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
// ── CONSTANT SIZE. THIS IS NOT A STYLE CHOICE. ────────────────────────
// The first version sized itself to its content and collapsed to 0 when
// it had nothing to report. That SHIFTED THE REST OF THE BAR, measured
// on the live vertical bar (2026-08-27, operator-reported):
//
//   endZone is bottom-anchored  — `y: parent.height - height`
//   centerZone is centred IN THE GAP between startZone and endZone —
//   `y: startZone.bottom + ((endZone.y - startZone.bottom) - height) / 2`
//                                                    (Bar.qml:1182-1186)
//
// So this capsule appearing added `30 (pill) + 16 (barCapsuleGap) = 46`
// to endZone's height, endZone.y rose by 46, the gap shrank by 46, and
// centerZone re-centred — moving every centre capsule UP by 46/2 = 23px.
// Measured by A/B capture with `qs ipc call -- prefs set
// security.showCapsule`: two centre landmarks moved 395->372 and
// 724->701, exactly 23px, while startZone (y 54..173) and endZone's own
// items (y 914+) did not move at all.
//
// AND COLLAPSING TO ZERO NEVER FULLY REMOVED THE FOOTPRINT ANYWAY: a
// zero-height child of a Grid still consumes the Grid's `spacing`, so
// the old "hidden" state still cost `barCapsuleGap` (16px). Measured —
// with the capsule item present-but-zero-height the centre landmarks sat
// at y=395, and with it genuinely filtered out of the model they sit at
// y=375. Hiding by collapsing is not the same as not being there.
//
// Every other capsule in this bar is a constant size for this reason.
// This one now is too: one square glyph chip,
// `barGlyphSize + spacingXs*2`, the same shape IdleInhibitorCapsule
// uses. Severity is carried by COLOUR and the detail by the tooltip,
// because a variable-width count ("Scanning" vs "12" vs "1") would
// reflow the HORIZONTAL orientation the same way the collapse reflowed
// the vertical one.
//
// Verified after the fix: three captures ~2s apart with the capsule
// present are pixel-identical (landmarks 355..366 and 684..692 in all
// three), so nothing moves as its state changes. Toggling the pref off
// and on shifts the centre by exactly 20px = (24 + 16) / 2 — a one-time,
// operator-initiated relayout, the same as toggling any other capsule.
//
// The capsule is therefore always present while its pref is on, and
// `bar.capsules.security` is how it goes away entirely — one switch,
// reachable from both Bar -> Capsules and Settings -> Security. When
// there is nothing to report it draws its quietest state rather than
// vanishing — a bar that reflows whenever a scan starts is worse than
// one chip of permanent space.
import QtQuick
import Quickshell
import ".."
import "../dashboard"

Item {
    id: root

    // Severity currently on show. A running scan outranks the findings —
    // it is the transient state the operator most needs to see, and it
    // is the reason this capsule exists.
    readonly property int shownRank: SecurityBackend.scanRunning ? Severity.rankScanning : (SecurityBackend.actionableCount > 0 ? SecurityBackend.worstRank : Severity.rankOk)

    readonly property bool quiet: !SecurityBackend.scanRunning && SecurityBackend.actionableCount === 0

    // CONSTANT. Never bound to content — see the header.
    implicitWidth: Design.barGlyphSize + Design.spacingXs * 2
    implicitHeight: Design.barGlyphSize + Design.spacingXs * 2

    Rectangle {
        id: chip
        anchors.fill: parent
        radius: width / 2

        // Quiet state is a bare glyph on the bar's own ground — no fill,
        // no rim. It occupies its space without asking for attention,
        // which is what lets it stay permanently without becoming the
        // clutter that trains you to ignore a real alert.
        color: root.quiet ? "transparent" : Severity.back(root.shownRank)
        border.width: root.quiet ? 0 : 1
        border.color: root.quiet ? "transparent" : Severity.rim(root.shownRank)

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

        Text {
            id: capsuleGlyph
            anchors.centerIn: parent
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.barGlyphSize
            text: Severity.glyph(root.shownRank)
            // Quiet uses the bar's own muted content colour rather than
            // the "healthy" green: a permanently-green shield reads as a
            // claim this pane cannot honestly make while three scanners
            // may still be uninstalled.
            color: root.quiet ? Colours.onSurfaceVariant : Severity.fg(root.shownRank)

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }

            RotationAnimator on rotation {
                running: SecurityBackend.scanRunning && Motion.motionEnabled
                loops: Animation.Infinite
                from: 0
                to: 360
                // Loop-period token, never a one-shot duration.
                duration: Motion.ambientDuration
            }
        }

        MouseArea {
            id: capsuleMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            // Opens the Security settings page by its own slug, through
            // the shell's existing deep-link verb — no new IPC target.
            //
            // TWO measured details in this one line:
            //   * the verb is `openPage`, not `open` — `settings.open`
            //     takes no argument (shell.qml:1499) and would open the
            //     window on whatever page was last shown.
            //   * the `--` is load-bearing: `qs ipc call <target> <verb>`
            //     silently no-ops on a CLI11 subcommand collision.
            //
            // execDetached, never a component-scoped Process: this
            // capsule lives in the bar and the call must not die with any
            // surface.
            onClicked: Quickshell.execDetached(["qs", "ipc", "call", "--", "settings", "openPage", "security"])

            // Everything the constant-size chip cannot show lives here,
            // which is the trade this shape makes deliberately.
            ThemedToolTip {
                visible: capsuleMouseArea.containsMouse
                text: {
                    if (SecurityBackend.scanRunning)
                        return "Virus scan running — " + SecurityBackend.scanFilesSeen + " files, " + SecurityBackend.scanThreats + " threat(s)";
                    if (SecurityBackend.actionableCount > 0)
                        return SecurityBackend.actionableCount + " issue(s) — " + (SecurityBackend.findings.length > 0 ? SecurityBackend.findings[0].title : "");
                    if (SecurityBackend.absentCount > 0)
                        return SecurityBackend.absentCount + " security tool(s) not set up";
                    return "Nothing needs attention";
                }
            }
        }
    }
}
