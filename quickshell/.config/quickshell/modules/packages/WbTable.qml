// modules/packages/WbTable.qml — the search field and the sortable table.
//
// ── R1 "LEDGER" ROWS, THE OPERATOR'S PICK ─────────────────────────────
// Monospace-shaped columns with tabular figures, not cards. A package
// list is a table of names, versions and sizes, and this treatment is the
// only one of the three studied that stays legible at ~26 rows on screen.
// The trade is that state is carried by a coloured word (AUR, orphan,
// update) rather than by a shape.
//
// ── GEOMETRY STABILITY ────────────────────────────────────────────────
// Column widths are computed from the TABLE's own width every frame and
// never from a child, and the selection tick occupies its cell whether or
// not it is ticked. So neither hovering, ticking, nor a value changing
// length can reflow the table — the same discipline every other row and
// ring in this tree is held to.
//
// A ListView, not a Repeater in a Column: 1420 rows must not all be
// instantiated. This is the one list in this window big enough for that
// to matter.
import QtQuick
import QtQuick.Controls
import ".."
import "../dashboard"

Item {
    id: root

    required property var bench

    readonly property var backend: root.bench.backend

    // ── Column geometry, derived from the table width. Declared above
    //    everything that reads it at construction time.
    readonly property int colTick: 22
    // Widened with the type (operator round 2): at the previous 12px meta
    // size these fit, and at 14px they truncated — "lib32-nvidia-utils"
    // showed `multil…` and every kernel version lost its suffix. Sized off
    // the widest real value each column holds on this host rather than by
    // eye: "1:1.2.96.518-2" for version, "885.66 MiB" for size, "multilib"
    // for source.
    readonly property int colVersion: 152
    readonly property int colSize: 104
    readonly property int colSource: 88
    readonly property int gap: Design.spacingSm
    readonly property int colName: Math.max(120, root.width - Design.spacingMd * 2 - root.colTick - root.colVersion - root.colSize - root.colSource - root.gap * 4)

    // Returns a LIGATURE NAME, drawn by its own Text in the symbol font.
    // It cannot be concatenated into the label string: the label renders in
    // the shell's normal family, where "arrow_downward" would appear as
    // those seventeen letters rather than an arrow.
    function _sortGlyph(key) {
        if (root.bench.sortKey !== key)
            return "";
        return root.bench.sortDesc ? "arrow_downward" : "arrow_upward";
    }

    // ── Search ──────────────────────────────────────────────────────
    Rectangle {
        id: searchBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 56
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            anchors.margins: Design.spacingSm
            anchors.leftMargin: Design.spacingMd
            anchors.rightMargin: Design.spacingMd
            radius: 14
            color: Colours.surfaceContainer

            Row {
                anchors.fill: parent
                anchors.leftMargin: Design.spacingSm + 4
                anchors.rightMargin: Design.spacingSm + 4
                spacing: Design.spacingSm

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "search"
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.settingsFontRow
                    color: Colours.primary
                }

                TextInput {
                    id: queryInput
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 40
                    text: root.bench.query
                    onTextChanged: root.bench.query = text
                    font.pixelSize: Design.fontBody
                    color: Colours.onSurface
                    selectionColor: Colours.primary
                    selectedTextColor: Colours.onPrimary
                    clip: true
                    focus: true

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: queryInput.text.length === 0
                        text: root.bench.filter === "repos" ? "Search 15,412 packages in the repos…" : "Filter " + root.bench.rows.length + " packages…"
                        font.pixelSize: Design.settingsFontSub
                        color: Colours.outline
                    }
                }
            }
        }
    }

    // ── Header ──────────────────────────────────────────────────────
    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchBar.bottom
        height: 28

        Row {
            anchors.fill: parent
            anchors.leftMargin: Design.spacingMd
            anchors.rightMargin: Design.spacingMd
            spacing: root.gap

            Item {
                width: root.colTick
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: root.bench.selected.length > 0 ? "check_box" : "check_box_outline_blank"
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.settingsFontSub
                    color: root.bench.selected.length > 0 ? Colours.primary : Colours.outline
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.bench.selected.length > 0)
                            root.bench.clearSelection();
                        else
                            root.bench.selectAllVisible();
                    }
                }
            }

            Repeater {
                model: [
                    {
                        key: "name",
                        label: "Package",
                        w: root.colName,
                        align: Text.AlignLeft
                    },
                    {
                        key: "version",
                        label: "Version",
                        w: root.colVersion,
                        align: Text.AlignLeft
                    },
                    {
                        key: "size",
                        label: "Size",
                        w: root.colSize,
                        align: Text.AlignRight
                    },
                    {
                        key: "source",
                        label: "Source",
                        w: root.colSource,
                        align: Text.AlignLeft
                    }
                ]

                delegate: Item {
                    id: headCell
                    required property var modelData

                    width: headCell.modelData.w
                    height: header.height

                    Row {
                        anchors.fill: parent
                        layoutDirection: headCell.modelData.align === Text.AlignRight ? Qt.RightToLeft : Qt.LeftToRight
                        spacing: 2

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: headCell.modelData.label.toUpperCase()
                            font.pixelSize: 11
                            font.letterSpacing: 0.8
                            color: root.bench.sortKey === headCell.modelData.key ? Colours.primary : Colours.outline
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: text.length > 0
                            text: root._sortGlyph(headCell.modelData.key)
                            font.family: Design.symbolFontFamily
                            font.pixelSize: 12
                            color: Colours.primary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        // Version is not a meaningful sort key — version
                        // strings do not order across packages — so it
                        // sorts by name instead of pretending.
                        onClicked: root.bench.setSort(headCell.modelData.key === "version" ? "name" : headCell.modelData.key)
                    }
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Design.spacingMd
            anchors.rightMargin: Design.spacingMd
            height: 1
            color: Colours.outlineVariant
        }
    }

    // ── Rows ────────────────────────────────────────────────────────
    ListView {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: Design.spacingMd
        anchors.rightMargin: Design.spacingMd
        clip: true
        model: root.bench.rows
        cacheBuffer: 400

            // Thin scrollbar (operator round 2). Sized in its own right so
            // it cannot widen the list it sits over, and faded until the
            // pointer is in the view — visible enough to show position,
            // quiet enough not to compete with the rows.
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 6
                opacity: hovered || pressed ? 1 : 0.45

                Behavior on opacity {
                    enabled: Motion.motionEnabled
                    NumberAnimation {
                        duration: Motion.colourDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.colourEasing
                    }
                }

                contentItem: Rectangle {
                    radius: width / 2
                    color: Colours.primary
                }

                background: Rectangle {
                    radius: width / 2
                    color: Colours.surfaceContainer
                }
            }


        delegate: Rectangle {
            id: row
            required property var modelData

            readonly property bool ticked: root.bench.isSelected(row.modelData.name)
            readonly property bool focused: root.bench.focusName === row.modelData.name

            width: list.width
            height: 32
            radius: 6
            color: row.focused ? Colours.primaryContainer : (rowArea.containsMouse ? Qt.alpha(Colours.onSurface, 0.05) : Qt.alpha(Colours.onSurface, 0))

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }

            MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.bench.focusName = row.modelData.name
            }

            Row {
                anchors.fill: parent
                spacing: root.gap

                // The tick occupies its cell whether ticked or not, so
                // ticking never reflows the row.
                Item {
                    width: root.colTick
                    height: parent.height

                    Text {
                        anchors.centerIn: parent
                        text: row.ticked ? "check_box" : "check_box_outline_blank"
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.settingsFontSub
                        color: row.ticked ? Colours.primary : Qt.alpha(Colours.outline, 0.55)
                    }

                    MouseArea {
                        anchors.fill: parent
                        // Only an installed package can be ticked — the
                        // queue is a removal queue, and a repo-search row
                        // for something not installed has nothing to
                        // remove.
                        enabled: row.modelData.installed
                        onClicked: root.bench.toggleSelected(row.modelData.name)
                    }
                }

                // Name, plus the state words this treatment carries
                // instead of shapes.
                Item {
                    width: root.colName
                    height: parent.height

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        spacing: Design.spacingSm

                        Text {
                            text: row.modelData.name
                            font.pixelSize: Design.fontBody
                            color: row.modelData.installed ? Colours.onSurface : Colours.outline
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, parent.width - tagRow.width - Design.spacingSm)
                        }

                        Row {
                            id: tagRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Design.spacingSm

                            Text {
                                visible: row.modelData.foreign
                                text: "AUR"
                                font.pixelSize: 11
                                color: Colours.tertiary
                            }

                            Text {
                                visible: row.modelData.orphan
                                text: "orphan"
                                font.pixelSize: 11
                                color: Colours.error
                            }

                            Text {
                                visible: !!row.modelData.update
                                text: "update"
                                font.pixelSize: 11
                                color: Colours.primary
                            }

                            Text {
                                visible: row.modelData.installed && root.bench.filter === "repos"
                                text: "installed"
                                font.pixelSize: 11
                                color: Colours.onSurfaceVariant
                            }
                        }
                    }
                }

                Text {
                    width: root.colVersion
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: row.modelData.update ? (row.modelData.update.from + " → " + row.modelData.update.to) : row.modelData.version
                    font.pixelSize: Design.settingsFontSub
                    color: row.modelData.update ? Colours.primary : Colours.outline
                    elide: Text.ElideRight
                }

                Text {
                    width: root.colSize
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: row.modelData.sizeMiB > 0 ? root.backend.formatSize(row.modelData.sizeMiB) : "—"
                    font.pixelSize: Design.settingsFontSub
                    color: Colours.onSurfaceVariant
                }

                Text {
                    width: root.colSource
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: row.modelData.source
                    font.pixelSize: Design.settingsFontSub
                    color: row.modelData.foreign ? Colours.tertiary : Colours.outline
                    elide: Text.ElideRight
                }
            }
        }
    }

    // ── Empty states, each naming its own reason ────────────────────
    Text {
        anchors.centerIn: list
        width: list.width - Design.spacingXl * 2
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        visible: root.bench.rows.length === 0
        font.pixelSize: Design.settingsFontSub
        color: Colours.outline
        text: {
            if (!root.backend.packagesProbed)
                return "Reading the package database…";
            if (root.bench.filter === "repos" && !root.backend.catalogueProbed)
                return "Loading the repo catalogue…";
            if (root.bench.filter === "repos")
                return "Type at least two characters to search 15,412 packages in the repos.";
            if (root.bench.filter === "orphans")
                return "No orphans. Nothing is installed that nothing needs.";
            if (root.bench.filter === "updates")
                return "Up to date — no repo or AUR updates pending.";
            if (root.bench.query.length > 0)
                return "Nothing matches “" + root.bench.query + "” in this view.";
            return "Nothing to show.";
        }
    }
}
