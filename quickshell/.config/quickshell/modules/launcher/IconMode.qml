// modules/launcher/IconMode.qml — the `icon` word route (quick task
// 260828-ah9, Task 4, D-01). Specimen's icon-theme half: the fast typed
// path, on `WallpaperMode.qml`'s horizontal-strip shape rather than a
// table — this is a browse-a-few-tiles surface, not a browse-a-long-list
// one.
//
// M1 — MEASURED, not a style choice: at 48px, `Papirus`, `Papirus-Dark`
// and `Papirus-Light` are byte-identical. Each tile's preview grid
// renders at 22px for exactly the same reason `AtIconsTab.qml` does —
// see that file's own header for the full measurement.
//
// The apply Process lives on `AppearanceBackend` (the singleton), never
// here: a component-scoped `Process` dies with its LazyLoader the
// instant the launcher dismisses, killing the apply mid-flight — this
// tree's own standing rule (260822-sht).
import QtQuick
import ".."
import "../dashboard"
import "../appearance"

Item {
    id: root

    // Launcher.qml hands this in — this file has no other way to close
    // the surface it is hosted in (same contract as WallpaperMode's).
    property var dismissCallback: null

    readonly property string pattern: LauncherState.queryArg.trim().toLowerCase()

    readonly property var _themes: AppearanceBackend.iconThemes

    readonly property var filtered: {
        if (root.pattern.length === 0)
            return root._themes;
        const out = [];
        for (let i = 0; i < root._themes.length; ++i)
            if (root._themes[i].toLowerCase().indexOf(root.pattern) >= 0)
                out.push(root._themes[i]);
        return out;
    }

    // ── The duck-typed trio, `WallpaperMode.qml`'s exact
    //    `columns: count` trick — one row, so Left/Right walks the strip
    //    with no change to Launcher.qml's nav code. ────────────────────
    readonly property int count: root.filtered.length
    readonly property int columns: Math.max(1, root.count)
    property int currentIndex: 0

    onPatternChanged: root.currentIndex = 0

    function activate() {
        const name = root.filtered[root.currentIndex];
        if (!name)
            return;
        AppearanceBackend.applyIconTheme(name);
        if (root.dismissCallback)
            root.dismissCallback();
    }

    implicitHeight: strip.implicitHeight

    Row {
        id: strip
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Design.spacingSm
        // implicitHeight is READ-ONLY on a Positioner (Row/Column/Grid/
        // Flow) — it is computed from the tallest child, never settable
        // directly. The 140px tile height below is what actually sizes
        // this.

        Repeater {
            model: root.filtered

            delegate: Rectangle {
                id: tile
                required property string modelData
                required property int index

                readonly property bool current: tile.index === root.currentIndex
                readonly property bool active: tile.modelData === AppearanceBackend.iconThemeName
                readonly property var _rows: AppearanceBackend.previewFor(tile.modelData)

                width: 132
                height: 140
                radius: 14
                color: tile.current ? Colours.surfaceVariant : Qt.alpha(Colours.onSurface, 0.05)

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
                    border.width: tile.active ? 2 : 0
                    border.color: Colours.primary
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: Design.spacingSm
                    spacing: Design.spacingXs

                    Grid {
                        id: previewGrid
                        width: parent.width
                        columns: 4
                        rowSpacing: 3
                        columnSpacing: 3

                        Repeater {
                            model: tile._rows

                            delegate: Item {
                                id: probeCell
                                required property var modelData

                                readonly property bool _hit: probeCell.modelData.path !== "-"

                                width: (previewGrid.width - previewGrid.columnSpacing * 3) / 4
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

                                Rectangle {
                                    anchors.fill: parent
                                    visible: !probeCell._hit
                                    radius: 3
                                    color: Qt.alpha(Colours.outline, 0.25)
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: tile.modelData
                        color: tile.active ? Colours.primary : Colours.onSurface
                        font.pixelSize: Design.fontLabel
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        textFormat: Text.PlainText
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.currentIndex = tile.index;
                        root.activate();
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.count === 0
        text: root.pattern.length === 0 ? "No icon themes found" : ("Nothing matches “" + root.pattern + "”")
        font.pixelSize: Design.settingsFontSub
        color: Colours.outline
        textFormat: Text.PlainText
    }
}
