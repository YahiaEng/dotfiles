// modules/appearance/AtTabBar.qml — the Atelier's Icons/Fonts/Catalogue
// tab strip (quick task 260828-ah9, Task 2). A plain Item-rooted
// component, not borrowed from `modules/packages/WbButton.qml` — this
// module owns its own button shape rather than importing a sibling one.
import QtQuick
import ".."
import "../dashboard"

Item {
    id: root

    property string currentTab: "icons"
    signal tabSelected(string tab)

    readonly property var _tabs: [
        {
            id: "icons",
            label: "Icons"
        },
        {
            id: "fonts",
            label: "Fonts"
        },
        {
            id: "catalogue",
            label: "Catalogue"
        }
    ]

    implicitHeight: 40

    // Operator round 3, item 1 — the same collision as the Icons/Fonts
    // rails, on the same body panel: `surfaceVariant` == `primaryContainer`
    // == `secondaryContainer` in the live palette, so the strip needs its
    // own `Qt.alpha(Colours.surface, 0.55)` backdrop before a
    // container-role selection can read against it — `WbSidebar.qml:87`'s
    // exact fix, applied here too.
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Qt.alpha(Colours.surface, 0.55)
    }

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Design.spacingXs
        spacing: Design.spacingSm

        Repeater {
            model: root._tabs

            delegate: Rectangle {
                id: tabDelegate
                required property var modelData

                readonly property bool selected: root.currentTab === tabDelegate.modelData.id

                width: tabLabel.implicitWidth + Design.spacingLg
                height: 32
                radius: 10
                // Operator round 3, item 1 — WbSidebar.qml:117's exact
                // shape: selection is `primaryContainer`, hover is a flat
                // 6% onSurface tint, rest is transparent.
                //
                // Operator round 4, item 3 — same split as the Icons/
                // Fonts rails: the active TAB switches instantly (no
                // Behavior), HOVER keeps the animated `Behavior on
                // color`. Round 3's combined binding cross-faded a tab
                // switch over 300ms too.
                color: "transparent"

                Rectangle {
                    id: selectFill
                    anchors.fill: parent
                    radius: parent.radius
                    visible: tabDelegate.selected
                    color: Colours.primaryContainer
                }

                Rectangle {
                    id: hoverFill
                    anchors.fill: parent
                    radius: parent.radius
                    visible: !tabDelegate.selected
                    color: tabArea.containsMouse ? Qt.alpha(Colours.onSurface, 0.06) : Qt.alpha(Colours.onSurface, 0)

                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.colourDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.colourEasing
                        }
                    }
                }

                Text {
                    id: tabLabel
                    anchors.centerIn: parent
                    text: tabDelegate.modelData.label
                    color: tabDelegate.selected ? Colours.onPrimaryContainer : Colours.onSurfaceVariant
                    font.pixelSize: Design.settingsFontSub
                    textFormat: Text.PlainText

                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.colourDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.colourEasing
                        }
                    }
                }

                MouseArea {
                    id: tabArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.tabSelected(tabDelegate.modelData.id)
                }
            }
        }
    }
}
