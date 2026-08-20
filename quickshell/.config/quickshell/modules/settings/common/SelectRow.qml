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

    implicitWidth: parent ? parent.width : 400
    implicitHeight: 56
    padding: Design.spacingMd

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

        Rectangle {
            id: dropdownPill
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Math.max(120, valueText.implicitWidth + Design.spacingLg * 2)
            implicitHeight: 36
            radius: height / 2
            color: Colours.surfaceVariant

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
    // The hover flicker/"hitbox seems inconsistent": the default
    // delegate's `implicitWidth`/`implicitHeight` derive from
    // `implicitContentWidth`/`implicitBackgroundWidth`, which change as
    // each item's OWN text metrics resolve — different labels (e.g.
    // "Off" vs "Material You Light (Dynamic)") got different implicit
    // sizes, so the highlighted rectangle's bounds visibly jumped
    // between items instead of holding one fixed width. Fixed here with
    // an explicit `implicitWidth: optionsMenu.width` on every item, so
    // every row shares the exact same hit region regardless of its own
    // label length. `highlighted` is QQC2's own canonical, built-in
    // hover/keyboard-nav-selection property (confirmed live in the
    // installed style's own MenuItem.qml) — used directly here rather
    // than a hand-rolled MouseArea, which would fight the Menu's own
    // internal ListView hover tracking and is the likely SOURCE of the
    // reported "appearing and disappearing" flicker.
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

                background: Rectangle {
                    radius: 8
                    color: menuItem.highlighted ? Colours.primaryContainer : "transparent"

                    Behavior on color {
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
