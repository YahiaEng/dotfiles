// modules/packages/WbSidebar.qml — the workbench's sources rail.
//
// Every row is a FILTER over one model, never a separate query: the
// backend holds all 1420 records and each row here narrows them. That is
// why the counts can be live and exact rather than "about" — they are
// the length of the list the row would show.
//
// The one exception is Repos, which reads the 15,412-entry catalogue.
// That is fetched on demand (Workbench.setFilter) rather than at startup,
// because nothing else needs it and it is the only list here big enough
// to be worth deferring.
import QtQuick
import ".."
import "../dashboard"

Item {
    id: root

    required property var bench

    implicitWidth: 200
    width: 200

    readonly property var backend: root.bench.backend

    // Declared before the Repeater below reads it at construction time.
    readonly property var sources: [
        {
            id: "all",
            label: "All",
            glyph: "▦",
            count: root.backend.installedCount,
            tone: "normal"
        },
        {
            id: "explicit",
            label: "Explicit",
            glyph: "★",
            count: root.backend.explicitCount,
            tone: "normal"
        },
        {
            id: "aur",
            label: "AUR",
            glyph: "▲",
            count: root.backend.foreignCount,
            tone: "aur"
        },
        {
            id: "orphans",
            label: "Orphans",
            glyph: "⊘",
            count: root.backend.orphans.length,
            tone: "alert"
        },
        {
            id: "updates",
            label: "Updates",
            glyph: "⟳",
            count: root.backend.pendingCount,
            tone: "accent"
        },
        {
            id: "repos",
            label: "Repos",
            glyph: "⌕",
            count: root.backend.catalogue.length,
            tone: "normal"
        }
    ]

    function _toneColour(tone, active) {
        if (active)
            return Colours.onPrimaryContainer;
        if (tone === "alert")
            return Colours.error;
        if (tone === "accent")
            return Colours.primary;
        if (tone === "aur")
            return Colours.tertiary;
        return Colours.onSurfaceVariant;
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.surface, 0.55)
    }

    Column {
        anchors.fill: parent
        anchors.margins: Design.spacingSm
        spacing: 2

        Text {
            text: "Packages"
            font.pixelSize: Design.settingsFontRow
            font.weight: Design.weightEmphasis
            color: Colours.onSurface
            leftPadding: Design.spacingSm
            topPadding: Design.spacingSm
            bottomPadding: Design.spacingSm
        }

        Repeater {
            model: root.sources

            delegate: Rectangle {
                id: srcRow
                required property var modelData

                readonly property bool active: root.bench.filter === srcRow.modelData.id

                width: root.width - Design.spacingSm * 2
                height: 34
                radius: 12
                color: srcRow.active ? Colours.primaryContainer : (srcArea.containsMouse ? Qt.alpha(Colours.onSurface, 0.06) : "transparent")

                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.colourDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.colourEasing
                    }
                }

                MouseArea {
                    id: srcArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.bench.setFilter(srcRow.modelData.id)
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Design.spacingSm
                    anchors.rightMargin: Design.spacingSm
                    spacing: Design.spacingSm

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        horizontalAlignment: Text.AlignHCenter
                        text: srcRow.modelData.glyph
                        font.pixelSize: Design.settingsFontSub
                        color: root._toneColour(srcRow.modelData.tone, srcRow.active)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 18 - countLabel.width - Design.spacingSm * 2
                        text: srcRow.modelData.label
                        font.pixelSize: Design.settingsFontSub
                        font.weight: srcRow.active ? Design.weightEmphasis : Design.weightBody
                        color: srcRow.active ? Colours.onPrimaryContainer : Colours.onSurface
                        elide: Text.ElideRight
                    }

                    Text {
                        id: countLabel
                        anchors.verticalCenter: parent.verticalCenter
                        // The Repos row shows nothing until the catalogue
                        // is actually loaded — a "0" there would read as
                        // "no packages in the repos", which is false.
                        text: (srcRow.modelData.id === "repos" && !root.backend.catalogueProbed) ? "" : srcRow.modelData.count.toString()
                        font.pixelSize: Design.fontLabel
                        color: srcRow.active ? Colours.onPrimaryContainer : Colours.outline
                    }
                }
            }
        }

        Rectangle {
            width: root.width - Design.spacingSm * 2
            height: 1
            color: Colours.outline
            opacity: 0.35
        }

        // ── Update check ────────────────────────────────────────────
        Rectangle {
            width: root.width - Design.spacingSm * 2
            height: 34
            radius: 12
            color: checkArea.containsMouse ? Qt.alpha(Colours.onSurface, 0.06) : "transparent"

            MouseArea {
                id: checkArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.backend.refreshUpdates()
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: Design.spacingSm
                anchors.rightMargin: Design.spacingSm
                spacing: Design.spacingSm

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    horizontalAlignment: Text.AlignHCenter
                    text: "⟳"
                    font.pixelSize: Design.settingsFontSub
                    color: Colours.onSurfaceVariant
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.backend.updatesProbed ? "Check for updates" : "Checking…"
                    font.pixelSize: Design.settingsFontSub
                    color: Colours.onSurface
                    elide: Text.ElideRight
                }
            }
        }

        Item {
            width: 1
            height: Design.spacingSm
        }

        // ── Footprint, stated once ──────────────────────────────────
        // The one number in this window that answers a question nothing
        // else on this machine answers: where the disk went.
        Column {
            x: Design.spacingSm
            spacing: 1

            Text {
                text: root.backend.formatSize(root.backend.totalSizeMiB)
                font.pixelSize: Design.settingsFontRow
                font.weight: Design.weightEmphasis
                color: Colours.onSurface
            }

            Text {
                text: "across " + root.backend.installedCount + " packages"
                font.pixelSize: Design.fontLabel
                color: Colours.outline
            }
        }
    }

    // A transaction is running — ours or someone else's. Stated here
    // rather than only on the buttons it disables, so the reason a
    // button is dead is visible without hovering it.
    Rectangle {
        visible: root.backend.dbLocked
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Design.spacingSm
        height: lockText.implicitHeight + Design.spacingSm * 2
        radius: 10
        color: Colours.error

        Text {
            id: lockText
            anchors.fill: parent
            anchors.margins: Design.spacingSm
            text: "pacman is running.\nActions are paused."
            wrapMode: Text.WordWrap
            font.pixelSize: Design.fontLabel
            color: Colours.onError
        }
    }
}
