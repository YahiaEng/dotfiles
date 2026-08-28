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

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
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
                color: tabDelegate.selected ? Colours.surfaceVariant : "transparent"

                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.colourDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.colourEasing
                    }
                }

                Text {
                    id: tabLabel
                    anchors.centerIn: parent
                    text: tabDelegate.modelData.label
                    color: tabDelegate.selected ? Colours.primary : Colours.onSurfaceVariant
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
                    anchors.fill: parent
                    onClicked: root.tabSelected(tabDelegate.modelData.id)
                }
            }
        }
    }
}
