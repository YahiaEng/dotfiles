// modules/settings/common/ToggleRow.qml — label + subtext + a switch pill.
// Same `Control` + never-anchor-contentItem discipline as SelectRow.qml/
// NavRow.qml (see SelectRow.qml's header for the full QQC2 trap
// reasoning) — the switch indicator is a plain Rectangle/handle pair, not
// QtQuick.Controls' own Switch, so there is no second contentItem to
// fight.
import QtQuick
import QtQuick.Controls
import "../../"
import "../../dashboard"

Control {
    id: root

    property string label: ""
    property string subtext: ""
    property bool checked: false
    signal toggled(value: bool)

    // Bug 2 re-check (operator: "still flashes... shows one state for a
    // split second before switching to the correct one"). The prior
    // round's fix (defaulting `checked`'s backing value to `false` and
    // dimming the row via `opacity`) was not enough — the switch pill
    // still RENDERED a state (transparent-ish but still visibly a
    // pill in the "off" position) before the real read landed, so the
    // flip was still visible. Per the coordinator's own instruction:
    // make the flash impossible BY CONSTRUCTION, not just less
    // noticeable — `showState` defaults to `true` (harmless for every
    // OTHER ToggleRow usage, which has no async-load gate at all) and
    // this row's own consumer binds it to a `*Loaded` flag; while
    // false, the pill is not rendered at all, so there is no state
    // — right or wrong — for a flash to show.
    property bool showState: true

    // ── Initial-load animation fix (operator SQDDIAG trace, natural
    //    scroll — mechanism caught directly in the log): real value is
    //    `true`; the trace shows `switchPill color-would-be=surfaceVariant`
    //    at hidden construction, then in the SAME tick as reveal —
    //    `checked false->true`, `showState=true`,
    //    `color-would-be=primary`. The `Behavior on color` captures that
    //    change (OFF -> ON) the instant it happens, and the pill becomes
    //    VISIBLE mid-animation — the operator watches OFF-colored paint
    //    fade to ON. Not a wrong value; the FIRST paint after load was
    //    never meant to animate at all.
    //
    //    Gating `Behavior.enabled` on a flag flipped in the SAME tick as
    //    `checked`/`showState` does NOT work — the Behavior captures the
    //    change when the property WRITES, and a same-tick flag flip
    //    can't guarantee it runs first. `_settled` is instead flipped
    //    via `Qt.callLater` (MEMORY child-binding-lags-parent-signal's
    //    own deferral idiom) — the NEXT event-loop tick, strictly AFTER
    //    this tick's `checked`/`color`/`x` writes have already resolved
    //    with the Behavior still off, so the first real paint SNAPS to
    //    the correct color/position with zero animation. Every
    //    SUBSEQUENT user-driven toggle, once `_settled` is true, animates
    //    normally.
    //
    //    Handles BOTH shapes of ToggleRow usage: rows with no async-load
    //    gate at all (`showState` stays permanently `true`, e.g. "Do not
    //    disturb" — settles via `Component.onCompleted`, since
    //    `showState` never changes to trigger `onShowStateChanged`) and
    //    rows WITH a loading gate like this one (`showState` starts
    //    `false`, flips `true` once — settles via `onShowStateChanged`
    //    the first time it goes true, which is exactly the tick that
    //    needs protecting).
    property bool _settled: false
    function _settle() {
        if (!root._settled)
            Qt.callLater(function () {
                root._settled = true;
            });
    }

    Component.onCompleted: {
        if (root.showState)
            root._settle();
    }
    onShowStateChanged: {
        if (root.showState)
            root._settle();
    }

    // Two-pane keyboard focus (Pages.qml's own `_collectFocusableRows`
    // marker + externally-written visual state) — see Pages.qml's header
    // for the full design. `focusable` is a plain readonly marker, not a
    // real QML `Item.focus`/`activeFocus` participant: this shell's rail
    // selection is already virtual (index-driven), so the content pane
    // follows the same idiom rather than mixing two focus models.
    readonly property bool focusable: true
    property bool rowFocused: false

    implicitWidth: parent ? parent.width : 400
    implicitHeight: 56
    padding: Design.spacingMd

    // Focus ring: border COLOR only, never width/padding/scale — a
    // geometry-affecting focus visual is exactly the hover-flicker
    // feedback-loop class this same wave root-caused and fixed
    // elsewhere in this module (SelectRow.qml's dropdown highlight).
    // Width stays a constant 2px always; only the color's alpha/hue
    // toggles, so the row's own footprint never moves under a
    // stationary cursor or a focus change.
    //
    // Row hover (operator burst-screenshot + PIL pixel-sample, fourth
    // live-pass): this row never had any row-level hover indicator at
    // all before this fix — only `switchPill`'s own click MouseArea
    // existed, scoped to the pill. A `HoverHandler` is passive/non-
    // exclusive, so it does not compete with that MouseArea for
    // hover/click delivery. Coexistence with keyboard focus, decided
    // deliberately: the ring shows when EITHER `rowFocused` (keyboard)
    // OR hover is true — one shared visual, matching the operator's own
    // request that hover look like keyboard selection.
    HoverHandler {
        id: rowHover
    }

    background: Rectangle {
        radius: 12
        color: "transparent"
        border.width: 2
        border.color: (root.rowFocused || rowHover.hovered) ? Colours.primary : "transparent"

        Behavior on border.color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

    contentItem: Item {
        id: rowContent
        implicitHeight: Math.max(labelCol.implicitHeight, switchPill.implicitHeight)

        Column {
            id: labelCol
            anchors.left: parent.left
            anchors.right: switchPill.left
            anchors.rightMargin: Design.spacingMd
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: root.label
                font.pixelSize: Design.fontBody
                color: Colours.onSurface
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                visible: root.subtext.length > 0
                text: root.subtext
                font.pixelSize: Design.fontLabel
                color: Colours.onSurfaceVariant
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Same sweep, same root cause: the OFF state's `surfaceVariant`
        // fill was invisible against the surfaceVariant pane (only the
        // ON/primary state had any visible boundary). Outline border
        // added — same role this file's own `optionsMenu` popup and
        // `dropdownPill` use against this identical pane color.
        Rectangle {
            id: switchPill
            visible: root.showState
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 48
            implicitHeight: 28
            radius: height / 2
            color: root.checked ? Colours.primary : Colours.surfaceVariant
            border.width: 1
            border.color: Colours.outline

            // `_settled` gate (see this file's own header for the full
            // finding): disabled until one tick after the row's first
            // real reveal, so the FIRST paint snaps directly to the
            // correct color — no animation to catch a wrong-then-
            // corrected value mid-flight.
            Behavior on color {
                enabled: root._settled && Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }

            Rectangle {
                id: handle
                width: 22
                height: 22
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                x: root.checked ? parent.width - width - 3 : 3
                color: root.checked ? Colours.onPrimary : Colours.onSurfaceVariant

                // Same class, same gate: a knob sliding left-to-right on
                // first reveal is the identical "animation captured an
                // initial-load correction" bug as the pill's own color.
                Behavior on x {
                    enabled: root._settled && Motion.motionEnabled
                    NumberAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.toggled(!root.checked)
            }
        }
    }
}
