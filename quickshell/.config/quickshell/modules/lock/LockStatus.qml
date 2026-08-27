// LockStatus.qml — shared failure/state message, all five lock layouts
// render this rather than each rolling their own (quick task 260827-833
// Task 1, LOCK-01). Two-layer structure per
// `caelestia-lock/center/StateMessage.qml`: a failure message in
// `Colours.error` (flash-then-recede on `pam.flashMsg`) and a caps-lock
// line in `Colours.onSurfaceVariant` underneath it. Caps Lock is sourced
// from this repo's own `modules/osd/CapsLockBackend.qml`
// (`readonly property bool on`) rather than Caelestia's `Hypr` singleton,
// which does not exist here.
//
// `CapsLockBackend.qml` exposes `checkNow()` but runs no Timer of its
// own — `Osd.qml`'s header explains why (one shared ticker, not a Timer
// per consumer). This file owns its OWN small poll Timer, at the OSD's
// own 250ms cadence, rather than reaching into Osd.qml's ticker — and it
// is self-gating on zero-idle grounds: `LockStatus` only exists for the
// lifetime of a loaded lock layout, which only exists while the session
// is actually locked (`WlSessionLock.surface` is a per-screen Component
// the compositor instantiates on lock, not before), so this Timer never
// runs while unlocked.
pragma ComponentBehavior: Bound

import QtQuick
import "../"
import "../osd"

Item {
    id: root

    required property LockPam pam

    implicitWidth: Math.max(errorText.implicitWidth, capsText.implicitWidth)
    implicitHeight: errorText.implicitHeight + capsText.implicitHeight

    readonly property string msg: {
        if (pam.state === LockPam.Error)
            return qsTr("Error: %1").arg(pam.passwd.message);
        if (pam.state === LockPam.Failed)
            return qsTr("Incorrect password. Please try again.");
        if (pam.state === LockPam.MaxTries)
            return pam.lockMessage || qsTr("Maximum password attempts reached.");
        return "";
    }

    CapsLockBackend {
        id: capsLock
    }

    Timer {
        interval: 250
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: capsLock.checkNow()
    }

    readonly property string stateMsg: capsLock.on ? qsTr("Caps lock is ON.") : ""

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2

        Text {
            id: errorText

            anchors.horizontalCenter: parent.horizontalCenter
            text: root.msg
            color: Colours.error
            font.pixelSize: 13
            visible: text.length > 0
            horizontalAlignment: Text.AlignHCenter

            Connections {
                function onFlashMsg() {
                    flashAnim.restart();
                }

                target: root.pam
            }

            SequentialAnimation {
                id: flashAnim

                loops: 2
                NumberAnimation {
                    target: errorText
                    property: "opacity"
                    to: 0.3
                    duration: Motion.staggerOffsetDuration
                }
                NumberAnimation {
                    target: errorText
                    property: "opacity"
                    to: 1
                    duration: Motion.staggerOffsetDuration
                }
            }
        }

        Text {
            id: capsText

            anchors.horizontalCenter: parent.horizontalCenter
            text: root.stateMsg
            color: Colours.onSurfaceVariant
            font.pixelSize: 12
            visible: text.length > 0 && root.msg.length === 0
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
