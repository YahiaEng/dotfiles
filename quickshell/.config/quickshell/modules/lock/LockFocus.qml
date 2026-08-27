// LockFocus.qml — layout E, "Quiet Focus" (quick task 260827-833 Task 5,
// LOCK-01). Built from the design study's own drawing code
// (`.planning/notes/lock-screen-studies.html`, article `s-e`, lines
// 968-1023), not its prose. Two states, not one — the study's own
// framing: "least content, most state machine."
//
// REST: an oversized clock alone (13cqw ≈ 333px cap height on this
// output) with the date beneath it, uppercased and heavily letter-spaced.
// Nothing else visible.
//
// REVEAL: on the first keypress the field rises from `bottom: 7%` at 16%
// width, the avatar and status fade in, and the clock shrinks and moves
// up. The reveal is hooked to `pam.buffer` changing and `pam.state`
// changing (LockSurface's own single focus owner routes every keypress
// through `pam.handleKey` regardless of which layout is loaded — a
// failed attempt also forces the reveal via the `state` hook). After an
// idle timeout with no further change, it recedes back to rest.
//
// ── The mockup's own stated gap is NOT shipped here ─────────────────────
// The study's own "what it costs" note: "a hidden password field is a
// real usability risk on a machine you hand to someone else. Needs a
// visible affordance the ghosted mockup does not yet show." A small
// persistent lock glyph + hint line, visible at low opacity in the rest
// state, is added below for exactly that reason.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../dashboard"

Item {
    id: root

    required property LockPam pam

    // ── Exit ──────────────────────────────────────────────────────────
    // Set by LockSurface while its unlock animation runs, so each layout
    // leaves along the axis it arrived on rather than sharing one flat fade.
    property bool unlocking: false
    property var mediaBackend: null
    property var screen: null

    readonly property real cqw: (root.screen?.width ?? 2560) / 100

    // An explicit lock-side constant, NOT a reach into
    // `Prefs.getValue("osd.hideDelayMs")` — that key belongs to an
    // unrelated surface (the OSD). Its 1200ms default is this constant's
    // "sanity anchor" (same order of magnitude as a deliberate, readable
    // pause), scaled up because a lock's reveal needs to survive a human
    // typing a password, not a single hardware-key tap.
    readonly property int idleTimeoutMs: 6000

    property bool revealed: false

    Timer {
        id: idleTimer
        interval: root.idleTimeoutMs
        onTriggered: root.revealed = false
    }

    Connections {
        function onBufferChanged() {
            root.revealed = true;
            idleTimer.restart();
        }

        function onStateChanged() {
            root.revealed = true;
            idleTimer.restart();
        }

        target: root.pam
    }

    SystemClock {
        id: focusClock
        enabled: true
        precision: SystemClock.Minutes
    }

    SystemClock {
        id: focusDateClock
        enabled: true
        precision: SystemClock.Days
    }

    // ── Rest clock — shrinks and moves up on reveal ─────────────────────
    ColumnLayout {
        id: clockColumn

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.revealed ? root.height * 0.2 : (root.height - implicitHeight) / 2
        spacing: root.cqw * 0.2

        Behavior on y {
            NumberAnimation {
                duration: Motion.spatialMoveDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.spatialMoveEasing
            }
        }

        Text {
            id: focusClockText
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(focusClock.date, "hh:mm")
            color: Colours.primary
            font.pixelSize: root.revealed ? root.cqw * 6 : root.cqw * 13
            font.bold: true

            Behavior on font.pixelSize {
                NumberAnimation {
                    duration: Motion.spatialMoveDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.spatialMoveEasing
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(focusDateClock.date, "dddd d MMMM").toUpperCase()
            color: Colours.onSurfaceVariant
            font.pixelSize: root.cqw * 0.78
            font.letterSpacing: root.cqw * 0.34
        }
    }

    // ── Reveal group — field, avatar, status ────────────────────────────
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.height * 0.07
        spacing: root.cqw * 0.8
        opacity: root.revealed ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.emphasizedInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasizedInEasing
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: root.cqw * 6.4
            implicitHeight: root.cqw * 6.4
            radius: width / 2
            color: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.10)

            Image {
                id: focusFace
                anchors.fill: parent
                source: Quickshell.env("HOME") + "/.face"
                visible: status === Image.Ready
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Text {
                anchors.centerIn: parent
                visible: focusFace.status !== Image.Ready
                text: "person"
                font.family: Design.symbolFontFamily
                font.pixelSize: root.cqw * 3
                color: Colours.onSurfaceVariant
            }
        }

        LockField {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.width * 0.16
            Layout.preferredHeight: root.cqw * 2.1
            pam: root.pam
            fieldRadius: height / 2
        }

        LockStatus {
            Layout.alignment: Qt.AlignHCenter
            pam: root.pam
        }
    }

    // ── Rest-state affordance (fixes the mockup's own stated gap) ──────
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.height * 0.07
        spacing: root.cqw * 0.3
        opacity: root.revealed ? 0 : 0.35
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.emphasizedInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasizedInEasing
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "lock"
            font.family: Design.symbolFontFamily
            font.pixelSize: root.cqw * 1.4
            color: Colours.onSurfaceVariant
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("PRESS ANY KEY TO UNLOCK")
            color: Colours.onSurfaceVariant
            font.pixelSize: root.cqw * 0.58
            font.letterSpacing: root.cqw * 0.14
        }
    }
}
