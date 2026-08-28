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
import ".."
import "../dashboard"

Item {
    id: root

    required property var bench

    readonly property var backend: root.bench.backend

    // ── Column geometry, derived from the table width. Declared above
    //    everything that reads it at construction time.
    readonly property int colTick: 22
    readonly property int colVersion: 116
    readonly property int colSize: 88
    readonly property int colSource: 66
    readonly property int gap: Design.spacingSm
    readonly property int colName: Math.max(120, root.width - Design.spacingMd * 2 - root.colTick - root.colVersion - root.colSize - root.colSource - root.gap * 4)

    function _sortGlyph(key) {
        if (root.bench.sortKey !== key)
            return "";
        return root.bench.sortDesc ? " ↓" : " ↑";
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
            color: Qt.alpha(Colours.onSurface, 0.07)

            Row {
                anchors.fill: parent
                anchors.leftMargin: Design.spacingSm + 4
                anchors.rightMargin: Design.spacingSm + 4
                spacing: Design.spacingSm

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⌕"
                    font.pixelSize: Design.settingsFontRow
                    color: Colours.primary
                }

                TextInput {
                    id: queryInput
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 40
                    text: root.bench.query
                    onTextChanged: root.bench.query = text
                    font.pixelSize: Design.settingsFontSub
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
                    text: root.bench.selected.length > 0 ? "▣" : "▢"
                    font.pixelSize: Design.fontLabel
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

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: headCell.modelData.align
                        text: headCell.modelData.label.toUpperCase() + root._sortGlyph(headCell.modelData.key)
                        font.pixelSize: 10
                        font.letterSpacing: 0.8
                        color: root.bench.sortKey === headCell.modelData.key ? Colours.primary : Colours.outline
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
            color: Qt.alpha(Colours.outline, 0.4)
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


        delegate: Rectangle {
            id: row
            required property var modelData

            readonly property bool ticked: root.bench.isSelected(row.modelData.name)
            readonly property bool focused: root.bench.focusName === row.modelData.name

            width: list.width
            height: 26
            radius: 6
            color: row.focused ? Colours.primaryContainer : (rowArea.containsMouse ? Qt.alpha(Colours.onSurface, 0.05) : "transparent")

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
                        text: row.ticked ? "▣" : "▢"
                        font.pixelSize: Design.fontLabel
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
                            font.pixelSize: Design.settingsFontSub
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
                                font.pixelSize: 10
                                color: Colours.tertiary
                            }

                            Text {
                                visible: row.modelData.orphan
                                text: "orphan"
                                font.pixelSize: 10
                                color: Colours.error
                            }

                            Text {
                                visible: !!row.modelData.update
                                text: "update"
                                font.pixelSize: 10
                                color: Colours.primary
                            }

                            Text {
                                visible: row.modelData.installed && root.bench.filter === "repos"
                                text: "installed"
                                font.pixelSize: 10
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
                    font.pixelSize: Design.fontLabel
                    color: row.modelData.update ? Colours.primary : Colours.outline
                    elide: Text.ElideRight
                }

                Text {
                    width: root.colSize
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: row.modelData.sizeMiB > 0 ? root.backend.formatSize(row.modelData.sizeMiB) : "—"
                    font.pixelSize: Design.fontLabel
                    color: Colours.onSurfaceVariant
                }

                Text {
                    width: root.colSource
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: row.modelData.source
                    font.pixelSize: Design.fontLabel
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
