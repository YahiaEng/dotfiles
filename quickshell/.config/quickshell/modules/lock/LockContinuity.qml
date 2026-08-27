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
// deleted from hyprlock.conf; this layout must not reintroduce one.
//
// This is the DEFAULT layout while hyprlock is still the held Task 8
// fallback: it is the one layout whose composition is mechanical to
// compare against the table above, so a migration regression is easy to
// spot. The operator flips the default once satisfied (operator checklist
// item 9).
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"

Item {
    id: root

    required property LockPam pam
    property var mediaBackend: null

    SystemClock {
        id: dateClock

        enabled: true
        precision: SystemClock.Days
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        LockClock {
            Layout.alignment: Qt.AlignHCenter
            scale: 1.0
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(dateClock.date, "dddd, MMMM d")
            color: Colours.onSurface
            font.pixelSize: 22
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.mediaBackend && root.mediaBackend.hasPlayer === true
            text: root.mediaBackend ? (root.mediaBackend.displayArtist + " — " + root.mediaBackend.displayTitle) : ""
            color: Colours.onSurface
            font.pixelSize: 14
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Hi, %1").arg(Quickshell.env("USER"))
            color: Colours.secondary
            font.pixelSize: 18
            Layout.topMargin: 8
        }

        LockField {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 320
            Layout.preferredHeight: 55
            Layout.topMargin: 12
            pam: root.pam
            fieldRadius: 12
        }

        LockStatus {
            Layout.alignment: Qt.AlignHCenter
            pam: root.pam
        }
    }
}
