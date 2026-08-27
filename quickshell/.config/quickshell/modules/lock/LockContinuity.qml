// LockContinuity.qml — layout B, the DEFAULT layout (quick task 260827-833
// Task 1, LOCK-01). Reproduces the plan's "current hyprlock composition"
// table read directly off `hypr/.config/hypr/hyprlock.conf`: a centred
// column of clock (96px, primary), date ("dddd, MMMM d", 22px,
// onSurface), now-playing ("Artist — Title", 14px, onSurface, sourced
// from the shell's existing MediaBackend), greeting ("Hi, $USER", 18px,
// secondary), the password field (320x55, rounding 12), then the status
// line.
//
// NO AVATAR — it was rejected by the operator at a live checkpoint and
// deleted from the old lock config; this layout must not reintroduce one.
//
// This is the DEFAULT layout. It was chosen as the default for the
// migration because its composition was mechanical to compare against the
// table above, making a regression easy to spot. The old config it was
// compared against was retired in 260827-ar3; the default simply stayed.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"

Item {
    id: root

    required property LockPam pam

    // ── Exit ──────────────────────────────────────────────────────────
    // Set by LockSurface while its unlock animation runs. Each layout leaves
    // along the axis it arrived on, so unlocking reads as the reverse of
    // locking instead of every surface sharing one flat fade.
    //
    // Driven by a SECOND Translate composed on top of the entrance one: the
    // entrance transforms are property-value-source animations that own their
    // Translate's property outright, so an exit binding on the same property
    // would fight them. Two Translates simply add.
    property bool unlocking: false
    property var mediaBackend: null

    SystemClock {
        id: dateClock

        enabled: true
        precision: SystemClock.Days
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        // Exit LIFTS rather than falls. The entrance rises from below, so
        // continuing upward reads as the stack passing through and away;
        // dropping it back down read as a collapse, which is why it was the
        // one exit that felt wrong.
        transform: Translate {
            y: root.unlocking ? -30 : 0
            Behavior on y {
                NumberAnimation {
                    duration: Motion.emphasizedOutDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.emphasizedOutEasing
                }
            }
        }

        LockClock {
            Layout.alignment: Qt.AlignHCenter
            scale: 1.0

            // Entrance step 0 — the stack rises in sequence rather than the
            // whole surface fading in flat. Property-value-source animations:
            // they self-start at creation and are guaranteed to settle on `to`.
            opacity: 0
            transform: Translate {
                SequentialAnimation on y {
                    PauseAnimation { duration: Motion.staggerOffsetDuration * 0 }
                    NumberAnimation {
                        from: 26
                        to: 0
                        duration: Motion.emphasizedInDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.emphasizedInEasing
                    }
                }
            }
            SequentialAnimation on opacity {
                PauseAnimation { duration: Motion.staggerOffsetDuration * 0 }
                NumberAnimation {
                    from: 0
                    to: 1
                    duration: Motion.emphasizedInDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.emphasizedInEasing
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(dateClock.date, "dddd, MMMM d")
            color: Colours.onSurface
            font.pixelSize: 22

            // Entrance step 1 — the stack rises in sequence rather than the
            // whole surface fading in flat. Property-value-source animations:
            // they self-start at creation and are guaranteed to settle on `to`.
            opacity: 0
            transform: Translate {
                SequentialAnimation on y {
                    PauseAnimation { duration: Motion.staggerOffsetDuration * 1 }
                    NumberAnimation {
                        from: 26
                        to: 0
                        duration: Motion.emphasizedInDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.emphasizedInEasing
                    }
                }
            }
            SequentialAnimation on opacity {
                PauseAnimation { duration: Motion.staggerOffsetDuration * 1 }
                NumberAnimation {
                    from: 0
                    to: 1
                    duration: Motion.emphasizedInDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.emphasizedInEasing
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.mediaBackend && root.mediaBackend.hasPlayer === true
            text: root.mediaBackend ? (root.mediaBackend.displayArtist + " — " + root.mediaBackend.displayTitle) : ""
            color: Colours.onSurface
            font.pixelSize: 14

            // Entrance step 2 — the stack rises in sequence rather than the
            // whole surface fading in flat. Property-value-source animations:
            // they self-start at creation and are guaranteed to settle on `to`.
            opacity: 0
            transform: Translate {
                SequentialAnimation on y {
                    PauseAnimation { duration: Motion.staggerOffsetDuration * 2 }
                    NumberAnimation {
                        from: 26
                        to: 0
                        duration: Motion.emphasizedInDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.emphasizedInEasing
                    }
                }
            }
            SequentialAnimation on opacity {
                PauseAnimation { duration: Motion.staggerOffsetDuration * 2 }
                NumberAnimation {
                    from: 0
                    to: 1
                    duration: Motion.emphasizedInDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.emphasizedInEasing
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Hi, %1").arg(Quickshell.env("USER"))
            color: Colours.secondary
            font.pixelSize: 18
            Layout.topMargin: 8

            // Entrance step 3 — the stack rises in sequence rather than the
            // whole surface fading in flat. Property-value-source animations:
            // they self-start at creation and are guaranteed to settle on `to`.
            opacity: 0
            transform: Translate {
                SequentialAnimation on y {
                    PauseAnimation { duration: Motion.staggerOffsetDuration * 3 }
                    NumberAnimation {
                        from: 26
                        to: 0
                        duration: Motion.emphasizedInDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.emphasizedInEasing
                    }
                }
            }
            SequentialAnimation on opacity {
                PauseAnimation { duration: Motion.staggerOffsetDuration * 3 }
                NumberAnimation {
                    from: 0
                    to: 1
                    duration: Motion.emphasizedInDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.emphasizedInEasing
                }
            }
        }

        LockField {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 320
            Layout.preferredHeight: 55
            Layout.topMargin: 12
            pam: root.pam
            fieldRadius: 12

            // Entrance step 4 — the stack rises in sequence rather than the
            // whole surface fading in flat. Property-value-source animations:
            // they self-start at creation and are guaranteed to settle on `to`.
            opacity: 0
            transform: Translate {
                SequentialAnimation on y {
                    PauseAnimation { duration: Motion.staggerOffsetDuration * 4 }
                    NumberAnimation {
                        from: 26
                        to: 0
                        duration: Motion.emphasizedInDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.emphasizedInEasing
                    }
                }
            }
            SequentialAnimation on opacity {
                PauseAnimation { duration: Motion.staggerOffsetDuration * 4 }
                NumberAnimation {
                    from: 0
                    to: 1
                    duration: Motion.emphasizedInDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.emphasizedInEasing
                }
            }
        }

        LockStatus {
            Layout.alignment: Qt.AlignHCenter
            pam: root.pam
        }
    }
}
