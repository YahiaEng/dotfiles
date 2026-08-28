// modules/settings/common/TextRow.qml — the seventh row primitive
// (quick-260826-1n9, D-10). Label/subtext left half, borrowed from
// NavRow.qml; an editable right half, borrowed from SelectRow.qml's
// "row with an interactive pill" shape — but the pill itself is a QQC2
// `TextField`, not a Menu popup. No Caelestia convention to copy here:
// `.planning/notes/caelestia-nexus/common/` has NO text-entry row
// primitive at all (measured, this task's own PLAN.md header) — this
// file is designed against this tree's own two existing TextField call
// sites instead: NavRail.qml:48 (the settings search box) and
// NetworkPage.qml:423 (the Wi-Fi password field), both of which render
// correctly today. `SliderRow`'s own QQC2 warning is about `Slider`
// specifically and does not transfer to a control this tree already
// renders in two places.
//
// A `Control` subclass, same discipline as NavRow/SelectRow: NEVER anchor
// `contentItem` itself against the Control's own geometry (MEMORY
// qqc2-contentitem-anchors-break-sizing) — only the CHILDREN inside
// contentItem are anchored, which is ordinary and safe.
//
// Commit semantics (stated because a text row without them silently
// loses edits): commits on Return/Enter and on losing focus; reverts to
// `root.text` on Escape. `committed(value)` fires exactly once per
// commit, and only when the trimmed value actually differs from
// `root.text` — never on every keystroke, since a consumer (Task 7's
// weather-city field) issues a network request on commit.
import QtQuick
import QtQuick.Controls
import "../../"
import "../../dashboard"

Control {
    id: root

    property string label: ""
    // indexLabel (quick-260826-437 D-1) — the string RowIndex keys on and
    // settings-index-check greps for; defaults to `label` so every existing
    // row keeps its exact current jump key. Override only when the displayed
    // `label` is dynamic (e.g. a Repeater over live data).
    property string indexLabel: root.label
    property string subtext: ""
    // The current committed value — a consumer sets this from its own
    // backing store (Prefs, a FileView, …) and reads it back via
    // `committed(value)`; this row never owns the value itself.
    property string text: ""
    property string placeholder: ""
    // Default true — a row shown disabled when a mode toggle (e.g. Task
    // 7's automatic/manual weather-location switch) has it locked.
    property bool editable: true
    signal committed(value: string)

    // Two-pane keyboard focus — see Pages.qml's header for the full
    // design. `focusable`/`rowFocused` keep `Pages._collectFocusableRows()`'s
    // denominator uniform across every row type, exactly as the other six
    // primitives declare it.
    readonly property bool focusable: true
    property bool rowFocused: false

    implicitWidth: parent ? parent.width : 400
    implicitHeight: contentCol.implicitHeight + Design.spacingMd * 2
    padding: Design.spacingMd

    // The duck-type marker `Pages.activateContentRow()`'s `beginEdit`
    // branch keys on (ahead of the generic three, for the same reason
    // the existing `stepUp` branch already is — a genuinely-declared
    // function is either present or `undefined`, no other row type
    // declares it). Focuses the field and selects all, matching the
    // "start editing" affordance a keyboard user expects from Enter/Space
    // on a focused text row.
    function beginEdit() {
        if (!root.editable)
            return;
        textField.forceActiveFocus();
        textField.selectAll();
    }

    // Sync DOWN from an external write to `root.text` (e.g. Task 7's
    // Prefs-backed weather city changing from outside this row) — but
    // never while the field is actively being edited, or a live external
    // change would clobber in-progress typing. Imperative, not a
    // declarative `text: root.text` binding on the TextField itself:
    // NavRail.qml's own header (WR-01) records that a TextInput's first
    // keystroke is itself a property WRITE, which destroys a declarative
    // binding permanently — the same imperative-sync idiom is used here.
    onTextChanged: {
        if (!textField.activeFocus && textField.text !== root.text)
            textField.text = root.text;
    }

    // No `pressed:` wire — this row's click target is the inner TextField,
    // which already paints its own background/state; the shared surface's
    // press fill is simply never driven true here, matching the prior
    // rest/hover/focus-only behaviour exactly.
    background: RowSurface {
        focused: root.rowFocused || textField.activeFocus
    }

    contentItem: Item {
        id: rowContent
        implicitHeight: contentCol.implicitHeight

        Column {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Design.spacingXs

            Text {
                text: root.label
                font.pixelSize: Design.settingsFontRow
                color: Colours.onSurface
                elide: Text.ElideRight
                width: parent.width
            }

            // Q-1/Q-5 (this module's own QQC2 contract, restated by
            // NavRail.qml's header) — explicit background and text
            // colours, never inherited from the Qt style; the background
            // is sized from the TextField's own implicitWidth/Height via
            // padding, never anchored against the field's geometry.
            TextField {
                id: textField
                width: parent.width
                enabled: root.editable
                placeholderText: root.placeholder
                font.pixelSize: Design.settingsFontRow
                color: root.editable ? Colours.onSurface : Colours.onSurfaceVariant
                placeholderTextColor: Colours.onSurfaceVariant
                leftPadding: Design.spacingMd
                rightPadding: Design.spacingMd
                topPadding: Design.spacingSm
                bottomPadding: Design.spacingSm

                background: Rectangle {
                    implicitHeight: 40
                    radius: 10
                    color: Colours.surfaceVariant
                    border.width: 1
                    border.color: Colours.outline

                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.colourDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.colourEasing
                        }
                    }
                }

                function _commit() {
                    var v = textField.text.trim();
                    if (v !== root.text) {
                        root.text = v;
                        root.committed(v);
                    }
                }

                // Consume Return/Enter/Escape here — otherwise an
                // unaccepted key event bubbles to Settings.qml's
                // `escCatcher`, whose own Keys.onReturnPressed/
                // onEscapePressed would fire a completely different
                // action (activateContentRow / close the window or pop a
                // sub-page). Same two-stage-Escape idiom
                // NetworkPage.qml:448's own passwordField already uses.
                Keys.onReturnPressed: function (event) {
                    textField._commit();
                    event.accepted = true;
                }
                Keys.onEnterPressed: function (event) {
                    textField._commit();
                    event.accepted = true;
                }
                Keys.onEscapePressed: function (event) {
                    textField.text = root.text;
                    event.accepted = true;
                }
                onActiveFocusChanged: {
                    if (!textField.activeFocus)
                        textField._commit();
                }

                Component.onCompleted: textField.text = root.text
            }

            Text {
                visible: root.subtext.length > 0
                text: root.subtext
                font.pixelSize: Design.settingsFontSub
                color: Colours.onSurfaceVariant
                width: parent.width
                wrapMode: Text.WordWrap
            }
        }
    }
}
