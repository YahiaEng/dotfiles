// LockSplit.qml — layout D, "Split Canvas" (quick task 260827-833 Task 4,
// LOCK-01). Built from the design study's own drawing code
// (`.planning/notes/lock-screen-studies.html`, article `s-d`, lines
// 901-967), not its prose. "The only direction with a real point of
// view" (the study's own words) — a hard vertical split, right 38% an
// OPAQUE panel, full-bleed to top/right/bottom, NO rounding, NO blur.
// Left 62% is untouched wallpaper (`backdropIsBlur` is already false for
// this key — LockSurface.qml's own map).
//
// Panel geometry: 973x1440 on this 2560x1440 output (the study's own
// measured figures). Every size below is `root.cqw` scaled
// (`root.screen.width / 100`, the study's own `cqw` unit), matching
// LockRail.qml's precedent from Task 3.
//
// Signature entrance, from the study: the panel wipes in from the right
// edge, and the clock's hour and minute settle a beat apart — driven from
// `Motion.spatialInDuration`/`spatialInEasing` (the wipe) and
// `Motion.staggerOffsetDuration` (the beat), never a literal.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"

Item {
    id: root

    required property LockPam pam
    property var mediaBackend: null
    property var systemResources: null
    property var weatherBackend: null
    property var screen: null

    readonly property real cqw: (root.screen?.width ?? 2560) / 100
    readonly property real panelWidth: (root.screen?.width ?? 2560) * 0.38

    // Deferred: inside `onWidthChanged` a child binding can still observe
    // the OLD value (`child-binding-lags-parent-signal`), so hand the flip
    // to the next tick once the geometry has actually settled.
    function _revealPanel() {
        if (root.width > 0)
            panel.revealed = true;
    }

    onWidthChanged: Qt.callLater(root._revealPanel)
    Component.onCompleted: Qt.callLater(root._revealPanel)

    SystemClock {
        id: splitClock
        enabled: true
        precision: SystemClock.Minutes
    }

    SystemClock {
        id: splitDateClock
        enabled: true
        precision: SystemClock.Days
    }

    Rectangle {
        id: panel

        // Full-bleed to top/right/bottom; NO rounding, NO blur — that is
        // the whole idea of the direction.
        y: 0
        width: root.panelWidth
        height: root.height
        color: Colours.surface

        // Signature move 1/2: wipes in from the right edge, settling flush
        // against it.
        //
        // FIXED 2026-08-27 — this shipped invisible. It previously read
        // `x: root.width` with `Component.onCompleted: wipeAnim.start()`,
        // and a Loader assigns geometry AFTER it constructs its item
        // (`qml-configured-after-construction`). At construction
        // `root.width` is 0, so the animation's `to:` evaluated to
        // `0 - panelWidth` = -972 and drove the panel entirely off-screen
        // to the LEFT — and because starting an animation on `x` destroys
        // the binding on `x`, it never came back. The operator saw the
        // wallpaper and nothing else.
        //
        // Both states are now real numbers on one binding, so `x` is never
        // written imperatively and never loses its binding. `revealed` is
        // flipped only once the Loader has given us a real width.
        property bool revealed: false

        x: revealed ? root.width - root.panelWidth : root.width

        Behavior on x {
            NumberAnimation {
                duration: Motion.spatialInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.spatialInEasing
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.cqw * 3
            anchors.leftMargin: root.cqw * 3.4
            anchors.rightMargin: root.cqw * 3.4
            spacing: 0

            Item { Layout.fillHeight: true }

            Text {
                text: qsTr("LOCKED")
                color: Colours.primary
                font.pixelSize: root.cqw * 0.66
                font.letterSpacing: root.cqw * 0.2
                font.bold: true
            }

            // Signature move 2/2: hour and minute settle a beat apart.
            RowLayout {
                Layout.topMargin: root.cqw
                spacing: root.cqw * 0.4

                Text {
                    id: splitHour
                    text: Qt.formatDateTime(splitClock.date, "hh")
                    color: Colours.primary
                    font.pixelSize: root.cqw * 5.6
                    font.bold: true
                    opacity: 0

                    NumberAnimation on opacity {
                        id: hourAppear
                        to: 1
                        duration: Motion.emphasizedInDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.emphasizedInEasing
                        running: false
                    }
                }
                Text {
                    id: splitMinute
                    text: Qt.formatDateTime(splitClock.date, "mm")
                    color: Colours.onSurface
                    font.pixelSize: root.cqw * 5.6
                    font.bold: true
                    opacity: 0

                    NumberAnimation on opacity {
                        id: minuteAppear
                        to: 1
                        duration: Motion.emphasizedInDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.emphasizedInEasing
                        running: false
                    }
                }
            }

            SequentialAnimation {
                id: clockBeatAnim
                running: false
                ScriptAction { script: hourAppear.start() }
                PauseAnimation { duration: Motion.staggerOffsetDuration }
                ScriptAction { script: minuteAppear.start() }
            }

            Component.onCompleted: clockBeatAnim.start()

            Text {
                Layout.topMargin: root.cqw * 1.1
                text: Qt.formatDateTime(splitDateClock.date, "dddd, d MMMM")
                color: Colours.onSurfaceVariant
                font.pixelSize: root.cqw * 0.86
                font.letterSpacing: root.cqw * 0.05
            }

            Rectangle {
                Layout.topMargin: root.cqw * 2.6
                Layout.bottomMargin: root.cqw * 2.6
                Layout.preferredWidth: root.panelWidth * 0.38 - root.cqw * 6.8
                implicitHeight: Math.max(1, root.cqw * 0.08)
                color: Colours.outline
            }

            RowLayout {
                spacing: root.cqw

                Rectangle {
                    implicitWidth: root.cqw * 3.2
                    implicitHeight: root.cqw * 3.2
                    radius: width / 2
                    color: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.10)

                    Image {
                        anchors.fill: parent
                        source: Quickshell.env("HOME") + "/.face"
                        visible: status === Image.Ready
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    spacing: root.cqw * 0.2

                    Text {
                        text: Quickshell.env("USER")
                        color: Colours.onSurface
                        font.pixelSize: root.cqw
                        font.weight: Font.Medium
                    }
                    Text {
                        text: qsTr("Enter password to unlock")
                        color: Colours.onSurfaceVariant
                        font.pixelSize: root.cqw * 0.66
                    }
                }
            }

            LockField {
                Layout.fillWidth: true
                Layout.topMargin: root.cqw * 1.6
                Layout.preferredHeight: root.cqw * 2.6
                pam: root.pam
                fieldRadius: root.cqw * 0.7
            }

            // Ambient data is demoted to ONE status line — the study's own
            // "what it costs" trade, accepted deliberately for this
            // layout only.
            RowLayout {
                id: ambientRow
                Layout.topMargin: root.cqw * 3.4
                spacing: root.cqw * 1.4

                readonly property var current: root.weatherBackend ? root.weatherBackend.current : null
                readonly property real cpuFrac: root.systemResources ? root.systemResources.cpuFraction : 0
                readonly property bool hasPlayer: root.mediaBackend && root.mediaBackend.hasPlayer === true

                RowLayout {
                    spacing: root.cqw * 0.3
                    Text {
                        text: "◈"
                        color: Colours.tertiary
                        font.pixelSize: root.cqw * 0.62
                    }
                    Text {
                        text: ambientRow.current ? (Math.round(ambientRow.current.temperature) + "° " + ambientRow.current.label) : qsTr("Weather —")
                        color: Colours.onSurfaceVariant
                        font.pixelSize: root.cqw * 0.62
                    }
                }
                RowLayout {
                    spacing: root.cqw * 0.3
                    Text {
                        text: "▲"
                        color: Colours.secondary
                        font.pixelSize: root.cqw * 0.62
                    }
                    Text {
                        text: qsTr("CPU %1%").arg(Math.round(ambientRow.cpuFrac * 100))
                        color: Colours.onSurfaceVariant
                        font.pixelSize: root.cqw * 0.62
                    }
                }
                RowLayout {
                    visible: ambientRow.hasPlayer
                    spacing: root.cqw * 0.3
                    Text {
                        text: "♪"
                        color: Colours.primary
                        font.pixelSize: root.cqw * 0.62
                    }
                    Text {
                        text: root.mediaBackend ? root.mediaBackend.displayTitle : ""
                        color: Colours.onSurfaceVariant
                        font.pixelSize: root.cqw * 0.62
                    }
                }
            }

            LockStatus {
                Layout.topMargin: root.cqw
                Layout.fillWidth: true
                pam: root.pam
            }
        }
    }
}
