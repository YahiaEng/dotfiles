// LockField.qml — the shared password field, all five lock layouts render
// this rather than each rolling their own (quick task 260827-833 Task 1,
// LOCK-01).
//
// ── Rewritten 2026-08-27 after operator testing found two defects that
//    affected every layout ────────────────────────────────────────────────
//
// DEFECT 1 — "clicking on the password input does nothing." It did nothing
// because there was nothing to click: the field was a bare `Item` with no
// `MouseArea`, no hover state, no cursor change and no caret. Typing worked
// the whole time (keys are routed by `LockSurface`'s single `focusOwner`),
// so the field was functional but read as dead. Fixed here with a hover
// border, an I-beam cursor and a blinking caret, plus a surface-wide
// click-to-refocus in `LockSurface.qml` so a click anywhere re-asserts
// keyboard focus if anything ever steals it.
//
// DEFECT 2 — "the typing animation is laggy." Three compounding causes,
// all removed:
//   (a) every dot animated for `Motion.standardDuration` (200ms). Typing at
//       a normal ~5 chars/sec starts a new 200ms animation every 200ms, so
//       the row never settles. Dots now use `Motion.spatialOutDuration`
//       (150ms) and only on entry.
//   (b) the ListView bound `width: Math.min(parent.width - 32, contentWidth)`
//       while it was `anchors.centerIn: parent`. Every inserted dot changed
//       contentWidth, which changed width, which re-centred the whole row —
//       relayout on every frame of every transition.
//   (c) `ScriptModel { values: root.pam.buffer.split("") }` rebuilt an array
//       of fresh single-character strings on every keystroke. Duplicate
//       characters ("aaa") make that diff ambiguous, so it degenerates to a
//       full model reset and every delegate is destroyed and recreated.
// A `Repeater` over `pam.buffer.length` has none of these properties: the
// model is an int, adding a character appends exactly one delegate, and the
// row is laid out by a `Row` rather than re-measured against itself.
//
// Removal is deliberately not animated — a `Repeater` drops the delegate
// immediately, which makes Backspace feel instant. That is the right
// trade-off for a password field.

import QtQuick
import "../"

Item {
    id: root

    required property LockPam pam
    property real fieldRadius: 12

    // Fixed delegate capacity — see the Repeater below. Dots past this
    // are simply not drawn; the buffer itself is never truncated.
    readonly property int maxDots: 64

    implicitWidth: 320
    implicitHeight: 55

    readonly property bool interactive: mouse.containsMouse

    readonly property string placeholderText: {
        if (root.pam.passwd.active)
            return qsTr("Loading...");
        if (root.pam.state === LockPam.MaxTries)
            return qsTr("Max tries reached");
        return qsTr("Enter Password...");
    }

    Rectangle {
        id: container

        anchors.fill: parent
        radius: root.fieldRadius
        color: Colours.surfaceVariant

        // The affordance the operator was missing: the field visibly
        // responds to the pointer instead of sitting inert.
        border.width: 1
        border.color: root.interactive ? Colours.primary : Colours.outline

        Behavior on border.color {
            ColorAnimation {
                duration: Motion.colourDuration
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        // Routed through LockPam because every layout already holds one;
        // LockSurface connects it to the single focusOwner.
        onPressed: root.pam.requestFocus()
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

    // Dots + caret, laid out by a Row so nothing re-measures itself.
    Row {
        id: dotRow

        anchors.centerIn: parent
        spacing: 8

        Repeater {
            // FIXED AGAIN 2026-08-27 — "the dots blink with every character".
            // The previous fix used `model: root.pam.buffer.length`, assuming
            // an int model appends one delegate. It does not: changing the
            // count makes Repeater REGENERATE, destroying and recreating every
            // delegate, so all existing dots re-ran their pop-in on each
            // keystroke — read as a blink of the whole row.
            //
            // The model is now a CONSTANT, so no delegate is ever created or
            // destroyed while typing. Each dot decides for itself whether it
            // is part of the current buffer; positioners skip invisible
            // children, so the Row still packs tightly.
            model: root.maxDots

            delegate: Rectangle {
                required property int index

                readonly property bool filled: index < root.pam.buffer.length

                width: 10
                height: 10
                radius: 5
                color: Colours.onSurface
                anchors.verticalCenter: parent.verticalCenter
                visible: filled

                // Only the newly-filled dot animates; every other dot's
                // binding still evaluates to the same value, so it does not
                // re-animate.
                scale: filled ? 1 : 0

                Behavior on scale {
                    NumberAnimation {
                        duration: Motion.spatialOutDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.spatialOutEasing
                    }
                }
            }
        }

        Rectangle {
            id: caret

            width: 2
            height: 18
            radius: 1
            color: Colours.primary
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.pam.passwd.active

            // Durations are derived from tokens rather than written as
            // literals — motion-lint (TOKEN-04) rejects a bare `Nms`.
            SequentialAnimation {
                running: caret.visible
                loops: Animation.Infinite

                NumberAnimation {
                    target: caret
                    property: "opacity"
                    to: 0
                    duration: Motion.standardDuration * 2
                }
                NumberAnimation {
                    target: caret
                    property: "opacity"
                    to: 1
                    duration: Motion.standardDuration * 2
                }
            }
        }
    }
}
