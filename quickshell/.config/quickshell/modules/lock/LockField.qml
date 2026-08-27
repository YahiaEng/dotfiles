// LockField.qml — the shared password field, all five lock layouts render
// this rather than each rolling their own (quick task 260827-833 Task 1,
// LOCK-01). Renders `pam.buffer` as one dot per character in a horizontal
// row with an animated insert/remove, following
// `caelestia-lock/center/InputField.qml`'s `ListView` + `ScriptModel`
// shape but drawing plain `Rectangle` circles rather than `MaterialShape`
// (a Caelestia C++ plugin type not installed here) — the animation is
// QtQuick's own `ListView.add`/`.remove`/`.displaced` transitions rather
// than a bespoke shape-morph, which is the idiomatic equivalent already
// used elsewhere in this tree.
//
// Container/dot colours per the plan: container `Colours.surfaceVariant`,
// dots `Colours.onSurface`, placeholder `Colours.outline`, active
// placeholder `Colours.secondary`. Placeholder text switches to
// "Loading..." while `pam.passwd.active` and "Max tries reached" at
// `state === LockPam.MaxTries`, per `caelestia-lock/center/
// InputField.qml`'s `nonAnimPlaceholder`.
//
// Sizing/rounding are the CALLER's concern (each layout sizes its own
// field: continuity is 320x55 rounding 12, the rail is full rail width,
// the split panel uses `.7cqw` rounding, quiet focus rises to 16% width)
// — this component fills whatever width/height its parent gives it.
pragma ComponentBehavior: Bound

import QtQuick
import "../"

Item {
    id: root

    required property LockPam pam
    property real fieldRadius: 12

    implicitWidth: 320
    implicitHeight: 55

    Rectangle {
        id: container

        anchors.fill: parent
        radius: root.fieldRadius
        color: Colours.surfaceVariant
    }

    readonly property string placeholderText: {
        if (root.pam.passwd.active)
            return qsTr("Loading...");
        if (root.pam.state === LockPam.MaxTries)
            return qsTr("Max tries reached");
        return qsTr("Enter Password...");
    }

    Text {
        id: placeholder

        anchors.centerIn: parent
        text: root.placeholderText
        color: root.pam.passwd.active ? Colours.secondary : Colours.outline
        font.pixelSize: 16
        opacity: root.pam.buffer.length > 0 ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

    ListView {
        id: charList

        anchors.centerIn: parent
        width: Math.min(parent.width - 32, contentWidth)
        height: 12
        orientation: ListView.Horizontal
        interactive: false
        spacing: 8

        model: ScriptModel {
            values: root.pam.buffer.split("")
        }

        delegate: Rectangle {
            width: 10
            height: 10
            radius: 5
            color: Colours.onSurface
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        }

        add: Transition {
            NumberAnimation {
                properties: "scale"
                from: 0
                to: 1
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
            NumberAnimation {
                properties: "opacity"
                from: 0
                to: 1
                duration: Motion.standardDuration
            }
        }

        remove: Transition {
            NumberAnimation {
                properties: "scale"
                to: 0
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
            NumberAnimation {
                properties: "opacity"
                to: 0
                duration: Motion.standardDuration
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "x"
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }
}
