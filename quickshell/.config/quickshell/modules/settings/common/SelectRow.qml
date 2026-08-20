// modules/settings/common/SelectRow.qml — label + subtext + a dropdown
// pill (RESEARCH.md pattern #4, Caelestia's SelectRow). A `Control`
// subclass, per this plan's own row-type discipline — and therefore
// subject to the QQC2 `contentItem`-anchoring trap (MEMORY
// qqc2-contentitem-anchors-break-sizing): the fix taken here is to NEVER
// anchor `contentItem` itself against the Control's own geometry (Control
// already sizes `contentItem` from `availableWidth`/`availableHeight` via
// its padding once no such override exists) — only the CHILDREN inside
// contentItem are anchored, which is ordinary and safe.
import QtQuick
import QtQuick.Controls
import "../../"
import "../../dashboard"

Control {
    id: root

    property string label: ""
    property string subtext: ""
    // Each entry: { value: "<raw>", display: "<label>" }
    property var model: []
    property string currentValue: ""
    signal selected(value: string)

    readonly property string currentDisplay: {
        for (var i = 0; i < root.model.length; i++) {
            if (root.model[i].value === root.currentValue)
                return root.model[i].display;
        }
        return root.currentValue;
    }

    // Two-pane keyboard focus — see Pages.qml's header for the full
    // design; ToggleRow.qml's own header has the geometry-stability
    // reasoning for the border-color-only focus ring. Distinct from this
    // row's OWN dropdown-popup highlight fix below (a completely
    // separate Menu/MenuItem concern) — this ring is on the ROW itself.
    readonly property bool focusable: true
    property bool rowFocused: false

    implicitWidth: parent ? parent.width : 400
    implicitHeight: 56
    padding: Design.spacingMd

    // ── Row hover fix (operator burst-screenshot + PIL pixel-sample,
    //    fourth live-pass) — the wrong element was being fixed for three
    //    rounds: the operator's "menu items" report was ALWAYS about the
    //    page rows (this file, ToggleRow/SliderRow/NavRow), not the
    //    dropdown popup those rounds all targeted. MEASURED: the page
    //    pane paints `Colours.surfaceVariant` (Settings.qml's own window
    //    background) and this row's own hover state had nothing to show
    //    against it — there was no row-level hover indicator here at
    //    all before this fix (only `dropdownPill`'s own click MouseArea
    //    existed, scoped to the pill, not the row). A `HoverHandler` is
    //    the right tool: passive, non-exclusive, does not compete with
    //    `dropdownPill`'s own MouseArea underneath it for click/hover
    //    delivery the way a second whole-row MouseArea would.
    //    Coexistence with keyboard focus, decided deliberately: the ring
    //    shows when EITHER `rowFocused` (keyboard) OR hover is true —
    //    one shared visual for "this is the row you'd act on next,"
    //    matching the operator's own request that hover LOOK LIKE
    //    keyboard selection instead of inventing a second style.
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
        implicitHeight: Math.max(labelCol.implicitHeight, dropdownPill.implicitHeight)

        Column {
            id: labelCol
            anchors.left: parent.left
            anchors.right: dropdownPill.left
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

        // dropdownPill contrast fix (same live-pass, same root cause):
        // MEASURED via PIL pixel-sample — `Colours.surfaceVariant` fill
        // on a `Colours.surfaceVariant` pane rendered as bare text, zero
        // visible pill boundary. `Colours.outline` border added, the
        // SAME role/width `optionsMenu`'s own popup background below
        // already uses against this identical pane color.
        Rectangle {
            id: dropdownPill
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Math.max(120, valueText.implicitWidth + Design.spacingLg * 2)
            implicitHeight: 36
            radius: height / 2
            color: Colours.surfaceVariant
            border.width: 1
            border.color: Colours.outline

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }

            Text {
                id: valueText
                anchors.centerIn: parent
                text: root.currentDisplay
                font.pixelSize: Design.fontBody
                color: Colours.onSurfaceVariant
            }

            MouseArea {
                anchors.fill: parent
                onClicked: optionsMenu.popup()
            }
        }
    }

    // Operator live-pass item 10 (FAIL — "the theme selection menu is
    // hardcoded and does not re-theme with theme switches") plus the
    // reported hover flicker/inconsistent hitbox: MEASURED root cause,
    // not assumed — read Qt's own installed Basic-style
    // Menu.qml/MenuItem.qml directly. Both `Menu.background`
    // (`color: control.palette.window`) and `MenuItem.background`
    // (`color: control.down ? control.palette.midlight : control.highlighted
    // ? control.palette.light : "transparent"`) use the QQC2 SYSTEM
    // PALETTE — zero literals in this repo's own QML, which is exactly
    // why colour-lint (which greps only OUR files) never caught it. This
    // is a measured, named colour-lint blind spot, recorded as a
    // follow-up in the SUMMARY rather than silently worked around.
    //
    // The "hitbox seems inconsistent" half: the default delegate's
    // `implicitWidth`/`implicitHeight` derive from
    // `implicitContentWidth`/`implicitBackgroundWidth`, which change as
    // each item's OWN text metrics resolve — different labels (e.g.
    // "Off" vs "Material You Light (Dynamic)") got different implicit
    // sizes, so the highlighted rectangle's bounds visibly jumped
    // between items instead of holding one fixed width. Fixed here with
    // an explicit `implicitWidth: optionsMenu.width` on every item, so
    // every row shares the exact same hit region regardless of its own
    // label length — this part held up across two further live-passes,
    // not revisited since. `highlighted` is QQC2's own canonical,
    // built-in hover/keyboard-nav-selection property (confirmed live in
    // the installed style's own MenuItem.qml) — used directly here
    // rather than a hand-rolled MouseArea, which would fight the Menu's
    // own internal ListView hover tracking.
    //
    // The "appearing and disappearing" flicker itself SURVIVED this fix
    // (operator, second live-pass) and a further dynamic-cursors A/B
    // test (operator, third live-pass — see the MenuItem `background`
    // below for the full finding and the border-ring fix that
    // ultimately replaced this section's original fill-based one).
    Menu {
        id: optionsMenu

        implicitWidth: Math.max(200, dropdownPill.implicitWidth)

        background: Rectangle {
            implicitWidth: optionsMenu.implicitWidth
            radius: 12
            color: Colours.surfaceVariant
            border.width: 1
            border.color: Colours.outline
        }

        Repeater {
            model: root.model

            MenuItem {
                id: menuItem
                required property var modelData
                text: modelData.display

                implicitWidth: optionsMenu.implicitWidth
                implicitHeight: 40

                contentItem: Text {
                    text: menuItem.text
                    color: Colours.onSurfaceVariant
                    font.pixelSize: Design.fontBody
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    leftPadding: Design.spacingMd
                    rightPadding: Design.spacingMd
                }

                // ── Item 3 hover-flicker — THIRD re-check (operator,
                //    third live-pass) ───────────────────────────────────
                // Dynamic-cursors was A/B-tested live by the coordinator
                // (disabled, oracle-verified, operator confirmed no
                // tilt) and STILL flickered — exonerated, re-enabled.
                // Not this plugin.
                //
                // Operator's own request, verbatim: "changing the hover
                // appearance to match that of selecting with keyboard (a
                // colorful border)" — the keyboard `rowFocused` ring
                // (ToggleRow.qml/SliderRow.qml/NavRow.qml/this row's own
                // outer Control, all elsewhere in this file) reads as
                // stable to the operator; this popup's own FILL never
                // did. Visual consistency between the two selection
                // mechanisms is now the spec, so this background is a
                // border ring, styled IDENTICALLY to `rowFocused`
                // above — `Colours.primary`, constant 2px width, no fill.
                //
                // Restart-animation hypothesis (coordinator's third
                // lead): does the `Behavior` reset from its ORIGINAL
                // start value on every re-trigger, rather than
                // redirecting smoothly from wherever it currently is?
                // MEASURED, not assumed: a temporary per-event color log
                // (Console: "ANIMTRACE", removed after use) driven by 5
                // rapid keyboard Down presses (fired faster than
                // `Motion.standardDuration`, so any settled item's
                // transition should overlap the next one if this were
                // going to happen at all) showed a single clean,
                // monotonic alpha ramp for the item `currentIndex`
                // settled on (30 samples, ~6ms apart, alpha rising
                // strictly 0xac->0xfe with zero backtracking) — the
                // Behavior redirects correctly, it does not restart.
                // Kept the `Behavior` here on that basis, matching every
                // other `rowFocused` ring in this module.
                background: Rectangle {
                    radius: 8
                    color: "transparent"
                    border.width: 2
                    border.color: menuItem.highlighted ? Colours.primary : "transparent"

                    Behavior on border.color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }
                }

                onTriggered: root.selected(modelData.value)
            }
        }
    }
}
