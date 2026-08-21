// modules/settings/NavRail.qml — scrollable Repeater over
// PageRegistry.pages (RESEARCH.md pattern #3, Caelestia's NavLocations).
// Category grouping is expressed as corner radii, not section headers:
// isCategoryStart/isCategoryEnd compare `category` against the
// neighbouring index, and the four corner radii derive from
// isCurrentPage/isCategoryStart/isCategoryEnd, each behind a Behavior
// reading Motion.standardDuration/standardEasing.
//
// ── Search (quick-260821-6z1 Task 3, D-06/F-01/R-4) — a TextField pinned
//    above the page-list Flickable, backed by `sState.searchText`.
//    Two separate Columns share the Flickable's content area, toggled by
//    `visible` on whether `searchText` is empty — the page-list Column
//    (unchanged) and a search-results Column driven by
//    `sState.searchResults` (RowIndex.qml's matches). This achieves the
//    same "switch what the rail shows" behaviour the plan describes as a
//    model swap, without forcing one delegate to branch between two
//    entirely different data shapes (nav entries carry icon/category;
//    search rows carry pageIdx/section/keywords). A result delegate shows
//    the row's own label with its PAGE's label as secondary text, and
//    clicking it calls `sState.selectSearchResult(row)` — which sets the
//    jump key, clears the search text, and navigates, all in one place
//    (SettingsState.qml). The TextField is a QQC2 control in colour-lint's
//    blind spot (§6.1) — Q-1/Q-5 from <qqc2_contract> apply: background
//    and text colours are explicit `Colours.*`, never inherited from the
//    Qt style, and the background is never anchored to the Control's own
//    geometry.
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

    Column {
        id: railColumn
        anchors.fill: parent
        anchors.margins: Design.spacingSm
        spacing: Design.spacingSm

        TextField {
            id: searchField
            width: parent.width
            placeholderText: "Search settings"
            onTextChanged: root.sState.searchText = text
            font.pixelSize: Design.fontBody
            color: Colours.onSurface
            placeholderTextColor: Colours.onSurfaceVariant
            leftPadding: Design.spacingMd
            rightPadding: Design.spacingMd
            topPadding: Design.spacingSm
            bottomPadding: Design.spacingSm

            // Q-1 — explicit background, never inherited from the Qt
            // style. Q-5 — the background is sized from the Control's
            // own `implicitWidth`/`implicitHeight` via padding, never
            // anchored against `searchField`'s own geometry.
            background: Rectangle {
                implicitHeight: 40
                radius: 12
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
            }
        }

        // ── Fix WR-01 (quick-260821-6z1 code review) — the field used to
        //    be `text: root.sState.searchText` PLUS the write-back above,
        //    a one-way binding + manual write-back combo. Per QML binding
        //    semantics, `TextInput`'s own internal `setText()` on the
        //    user's FIRST keystroke is itself a property WRITE, and any
        //    write to a property currently holding a declarative binding
        //    destroys that binding — from that point on `searchField.text`
        //    was a plain unbound property that never tracked
        //    `sState.searchText` again. `SettingsState.selectSearchResult()`
        //    clears `searchText` to close the result list after a click,
        //    and every OTHER consumer (`pageColumn.visible`,
        //    `flick.contentHeight`, `searchColumn`) is a genuine live
        //    binding and correctly reverted — only this field's own
        //    displayed text stayed stale. Fixed by driving the field
        //    IMPERATIVELY from `sState.searchText` changes instead of a
        //    declarative `text:` binding: `onTextChanged` above still
        //    propagates the user's own typing up to `sState` exactly as
        //    before, and this `Connections` block propagates DOWN
        //    whenever `sState.searchText` changes for a reason other than
        //    this field's own typing (a search-result click, or any
        //    future non-typing writer). The `!==` guard makes the two
        //    directions idempotent — no infinite ping-pong, since setting
        //    a QML property to its own current value never re-fires the
        //    change signal.
        Connections {
            target: root.sState
            function onSearchTextChanged() {
                if (searchField.text !== root.sState.searchText)
                    searchField.text = root.sState.searchText;
            }
        }

        Flickable {
            id: flick
            width: parent.width
            height: parent.height - searchField.height - railColumn.spacing
            contentHeight: root.sState.searchText.length > 0 ? searchColumn.implicitHeight : pageColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: pageColumn
                visible: root.sState.searchText.length === 0
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

                        width: pageColumn.width
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

            Column {
                id: searchColumn
                visible: root.sState.searchText.length > 0
                width: flick.width
                spacing: Design.spacingXs

                Repeater {
                    model: root.sState.searchResults

                    delegate: Rectangle {
                        id: resultItem

                        required property var modelData

                        width: searchColumn.width
                        height: 56
                        radius: 12
                        color: "transparent"
                        border.width: 2
                        border.color: resultHover.containsMouse ? Colours.primary : "transparent"

                        Behavior on border.color {
                            enabled: Motion.motionEnabled
                            ColorAnimation {
                                duration: Motion.standardDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.standardEasing
                            }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: Design.spacingMd
                            anchors.rightMargin: Design.spacingMd
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: resultItem.modelData.label
                                font.pixelSize: Design.fontBody
                                color: Colours.onSurface
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: (PageRegistry.pages[resultItem.modelData.pageIdx] ? PageRegistry.pages[resultItem.modelData.pageIdx].label : "")
                                font.pixelSize: Design.fontLabel
                                color: Colours.onSurfaceVariant
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        MouseArea {
                            id: resultHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.sState.selectSearchResult(resultItem.modelData)
                        }
                    }
                }

                Text {
                    visible: root.sState.searchResults.length === 0
                    text: "No matches"
                    font.pixelSize: Design.fontBody
                    color: Colours.onSurfaceVariant
                    width: searchColumn.width
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
