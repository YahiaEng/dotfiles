// modules/settings/NavRail.qml — scrollable Repeater over
// PageRegistry.pages (RESEARCH.md pattern #3, Caelestia's NavLocations).
// Category grouping is expressed as corner radii, not section headers:
// isCategoryStart/isCategoryEnd compare `category` against the
// neighbouring index, and the four corner radii derive from
// isCurrentPage/isCategoryStart/isCategoryEnd, each behind a Behavior
// reading Motion.standardDuration/standardEasing.
import QtQuick
import QtQuick.Controls
import "../"
import "../dashboard"

Item {
    id: root

    required property SettingsState sState

    Rectangle {
        anchors.fill: parent
        color: Colours.surface
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: Design.spacingSm
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column
            width: flick.width
            spacing: Design.spacingXs

            Repeater {
                model: PageRegistry.pages

                delegate: Rectangle {
                    id: navItem

                    required property var modelData
                    required property int index

                    readonly property bool isCurrentPage: root.sState.currentPageIdx === index
                    readonly property bool isCategoryStart: index === 0 || PageRegistry.pages[index - 1].category !== modelData.category
                    readonly property bool isCategoryEnd: index === PageRegistry.pages.length - 1 || PageRegistry.pages[index + 1].category !== modelData.category

                    width: column.width
                    height: 56
                    color: isCurrentPage ? Colours.secondaryContainer : "transparent"

                    topLeftRadius: isCurrentPage ? 20 : (isCategoryStart ? 16 : 4)
                    topRightRadius: navItem.topLeftRadius
                    bottomLeftRadius: isCurrentPage ? 20 : (isCategoryEnd ? 16 : 4)
                    bottomRightRadius: navItem.bottomLeftRadius

                    Behavior on topLeftRadius {
                        enabled: Motion.motionEnabled
                        NumberAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }
                    Behavior on bottomLeftRadius {
                        enabled: Motion.motionEnabled
                        NumberAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }
                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Design.spacingMd
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Design.spacingSm

                        Text {
                            font.family: Design.symbolFontFamily
                            font.pixelSize: Design.iconSizeMd
                            text: navItem.modelData.icon
                            color: navItem.isCurrentPage ? Colours.onSecondaryContainer : Colours.onSurface
                        }
                        Text {
                            text: navItem.modelData.label
                            font.pixelSize: Design.fontBody
                            font.weight: navItem.isCurrentPage ? Design.weightEmphasis : Design.weightBody
                            color: navItem.isCurrentPage ? Colours.onSecondaryContainer : Colours.onSurface
                        }
                    }

                    MouseArea {
                        id: navMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.sState.goToPage(navItem.index)
                        ToolTip.visible: navMouseArea.containsMouse
                        ToolTip.text: navItem.modelData.description
                        ToolTip.delay: Design.tooltipDelayMs
                    }
                }
            }
        }
    }
}
