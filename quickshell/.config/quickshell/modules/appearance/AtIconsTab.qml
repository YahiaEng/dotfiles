// modules/appearance/AtIconsTab.qml — the Atelier's Icons tab (quick task
// 260828-ah9, Task 2). A GridView of installed icon themes, each cell a
// 22px, 12-probe preview grid.
//
// M1 — MEASURED, not a style choice: `Papirus`, `Papirus-Dark` and
// `Papirus-Light` are byte-identical (same MD5) at every 48x48 icon
// probed. The variants override only their 16/18/22/24px glyphs, so a
// grid rendered at 48px cannot distinguish them — this grid renders at
// 22px, never 48. `AppearanceBackend.previewFor(theme)` is the ONLY
// source for the per-cell rows; this file never shells out itself.
//
// M3 — no icon name exists in all eight installed themes on this host
// (Adwaita ships no `utilities-terminal`; AdwaitaLegacy is PNG-only;
// breeze is missing others). A probe that resolved to `-` renders a
// visible placeholder cell, never an empty gap — coverage is information
// to show, not hide, and the per-theme count row states it as a number
// too ("10/12").
import QtQuick
import ".."
import "../dashboard"

Item {
    id: root

    readonly property var _themes: AppearanceBackend.iconThemes

    Text {
        anchors.centerIn: parent
        visible: root._themes.length === 0
        text: AppearanceBackend.iconThemesProbed ? "No icon themes found" : "Loading icon themes…"
        color: Colours.outline
        font.pixelSize: Design.settingsFontSub
    }

    GridView {
        id: grid
        anchors.fill: parent
        clip: true
        cellWidth: 216
        cellHeight: 188
        model: root._themes

        delegate: Rectangle {
            id: cell
            required property string modelData

            readonly property bool active: cell.modelData === AppearanceBackend.iconThemeName
            // M1/M3: the ONLY call site for previewFor() in this file —
            // one request per theme, cached by the backend, so scrolling
            // the grid back and forth never re-shells out.
            readonly property var _rows: AppearanceBackend.previewFor(cell.modelData)
            readonly property int _coverage: {
                var c = 0;
                for (var i = 0; i < cell._rows.length; ++i)
                    if (cell._rows[i].path !== "-")
                        c++;
                return c;
            }

            width: grid.cellWidth - Design.spacingSm
            height: grid.cellHeight - Design.spacingSm
            radius: 14
            color: Colours.surfaceVariant

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: cell.active ? 2 : 0
                border.color: Colours.primary
            }

            Column {
                anchors.fill: parent
                anchors.margins: Design.spacingSm
                spacing: Design.spacingXs

                Row {
                    width: parent.width
                    spacing: Design.spacingXs

                    Text {
                        width: parent.width - coverageText.implicitWidth - Design.spacingXs
                        text: cell.modelData
                        color: cell.active ? Colours.primary : Colours.onSurface
                        font.pixelSize: Design.settingsFontSub
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    Text {
                        id: coverageText
                        text: cell._coverage + "/" + cell._rows.length
                        color: Colours.onSurfaceVariant
                        font.pixelSize: Design.fontLabel
                        textFormat: Text.PlainText
                    }
                }

                Grid {
                    id: previewGrid
                    width: parent.width
                    columns: 6
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: cell._rows

                        delegate: Item {
                            id: probeCell
                            required property var modelData

                            readonly property bool _hit: probeCell.modelData.path !== "-"

                            width: (previewGrid.width - previewGrid.columnSpacing * 5) / 6
                            height: width

                            Image {
                                anchors.fill: parent
                                visible: probeCell._hit
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                                sourceSize.width: probeCell.width * 2
                                sourceSize.height: probeCell.height * 2
                                source: probeCell._hit ? ("file://" + probeCell.modelData.path) : ""
                            }

                            // M3: a genuine miss is shown, not hidden.
                            Rectangle {
                                anchors.fill: parent
                                visible: !probeCell._hit
                                radius: 3
                                color: Qt.alpha(Colours.outline, 0.25)
                            }
                        }
                    }
                }
            }

            // Activating leaves the window open — this is the browse
            // surface; the launcher's `icon` route is the one that
            // dismisses on commit.
            MouseArea {
                anchors.fill: parent
                onClicked: AppearanceBackend.applyIconTheme(cell.modelData)
            }
        }
    }
}
