// modules/appearance/AtCatalogueTab.qml — the Atelier's Catalogue tab
// (quick task 260828-ah9, Task 3, D-04). A two-pane split: a searchable
// list of repo + AUR icon-theme packages above a live, auto-scrolled
// install log. Consumes the standing v5.0 ICON-BROWSE candidate — Task 5
// strikes that row in ROADMAP.md.
//
// PRIVILEGE: NONE HERE. This file only ever reads `AppearanceBackend`'s
// state and calls `installCatalogue()` — every check, the db-lock refusal
// and the terminal handoff live on the backend (see its own header).
import QtQuick
import QtQuick.Controls
import ".."
import "../dashboard"
import "../packages"

Item {
    id: root

    property string query: ""

    readonly property var _filtered: {
        const q = root.query.trim().toLowerCase();
        const all = AppearanceBackend.catalogue;
        if (q.length === 0)
            return all;
        const out = [];
        for (let i = 0; i < all.length; ++i) {
            const c = all[i];
            if (c.name.toLowerCase().indexOf(q) >= 0 || c.description.toLowerCase().indexOf(q) >= 0)
                out.push(c);
        }
        return out;
    }

    function _levelColor(level) {
        if (level === "error")
            return Colours.error;
        if (level === "success")
            return Colours.primary;
        if (level === "warn")
            return Colours.tertiary;
        return Colours.onSurfaceVariant;
    }

    // Resizable left-pane width (defect 2c), persisted like
    // `packages.sidebarWidth`/`packages.detailWidth`. Wider bounds than
    // the Icons/Fonts rails — this pane holds a search box and full
    // result rows, not just a theme/family name.
    property int leftWidth: Math.max(300, Math.min(900, Prefs.getValue("appearance.catalogueLeftWidth")))

    function setLeftWidth(w) {
        var clamped = Math.max(300, Math.min(900, Math.round(w)));
        if (clamped === root.leftWidth)
            return;
        root.leftWidth = clamped;
        Prefs.setValue("appearance.catalogueLeftWidth", clamped);
    }

    // Fetched on demand (never at startup — the backend's own rule), and
    // reconciled against the last install snapshot every time this pane
    // is shown, so a theme installed last session is already reflected.
    Component.onCompleted: {
        if (!AppearanceBackend.catalogueProbed && !AppearanceBackend.catalogueRunning)
            AppearanceBackend.refreshCatalogue();
        AppearanceBackend.reconcileInstall();
    }

    Row {
        anchors.fill: parent
        spacing: 0

        // ── Left pane: search + results ──────────────────────────────
        // Operator round 3, item 1 — the same `Qt.alpha(Colours.surface,
        // 0.55)` backdrop as the Icons/Fonts rails (`WbSidebar.qml:87`'s
        // own treatment), for the identical reason: this pane sits on
        // the Atelier's `surfaceVariant` body panel, which collides with
        // any container-role fill drawn directly on top of it.
        Item {
            id: leftPane
            width: root.leftWidth
            height: parent.height

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.surface, 0.55)
            }

            Column {
            anchors.fill: parent
            spacing: Design.spacingSm

            Rectangle {
                width: parent.width
                height: 40
                radius: 12
                color: Qt.alpha(Colours.onSurface, 0.07)

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Design.spacingSm
                    anchors.rightMargin: Design.spacingSm
                    spacing: Design.spacingSm

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "search"
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.settingsFontSub
                        color: Colours.primary
                    }

                    TextInput {
                        id: queryInput
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 32
                        text: root.query
                        onTextChanged: root.query = text
                        font.pixelSize: Design.fontBody
                        color: Colours.onSurface
                        selectionColor: Colours.primary
                        selectedTextColor: Colours.onPrimary
                        clip: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: queryInput.text.length === 0
                            text: "Search icon-theme packages…"
                            font.pixelSize: Design.settingsFontSub
                            color: Colours.outline
                        }
                    }
                }
            }

            ListView {
                id: resultsList
                width: parent.width
                height: parent.height - 40 - Design.spacingSm
                clip: true
                model: root._filtered

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
                        color: Qt.alpha(Colours.onSurface, 0.06)
                    }
                }

                delegate: Rectangle {
                    id: resultRow
                    required property var modelData

                    width: resultsList.width
                    height: 56
                    radius: 10
                    color: rowArea.containsMouse ? Qt.alpha(Colours.onSurface, 0.05) : "transparent"

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
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: Design.spacingSm
                        spacing: Design.spacingSm

                        Column {
                            width: parent.width - installButton.width - Design.spacingSm
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Row {
                                spacing: Design.spacingXs

                                Text {
                                    text: resultRow.modelData.name
                                    font.pixelSize: Design.settingsFontSub
                                    color: Colours.onSurface
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: resultRow.modelData.source === "aur" ? "AUR" : resultRow.modelData.repo
                                    font.pixelSize: 11
                                    color: resultRow.modelData.source === "aur" ? Colours.tertiary : Colours.outline
                                }

                                Text {
                                    visible: resultRow.modelData.installed
                                    text: "installed"
                                    font.pixelSize: 11
                                    color: Colours.primary
                                }
                            }

                            Text {
                                width: parent.width
                                text: resultRow.modelData.description
                                font.pixelSize: Design.fontLabel
                                color: Colours.onSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }

                        // Operator round 3, item 1 — `WbButton`, not a
                        // hand-rolled Rectangle. There are many of these
                        // per screen (one per result row), so this is
                        // never the pane's SINGLE main action — "ghost",
                        // not "primary". "Installed" is conveyed the same
                        // way every other WbButton conveys an unavailable
                        // action: `enabled: false`.
                        WbButton {
                            id: installButton
                            anchors.verticalCenter: parent.verticalCenter
                            label: resultRow.modelData.installed ? "Installed" : "Install"
                            tone: "ghost"
                            enabled: !resultRow.modelData.installed
                            onActivated: AppearanceBackend.installCatalogue(resultRow.modelData.name, resultRow.modelData.source)
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root._filtered.length === 0
                text: AppearanceBackend.catalogueRunning ? "Searching repos + AUR…" : (AppearanceBackend.catalogueProbed ? "Nothing matches “" + root.query + "”" : "Loading catalogue…")
                font.pixelSize: Design.settingsFontSub
                color: Colours.outline
            }
            }
        }

        AtRailGrip {
            id: grip
            height: parent.height
            startWidth: root.leftWidth
            onDragged: proposedWidth => root.setLeftWidth(proposedWidth)
        }

        // ── Right pane: the live install log ─────────────────────────
        Column {
            id: rightPane
            width: parent.width - leftPane.width - grip.width
            height: parent.height
            spacing: Design.spacingSm

            Item {
                width: parent.width
                height: 24

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Install log"
                    font.pixelSize: Design.settingsFontRow
                    color: Colours.onSurface
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: recheckLabel.implicitWidth + Design.spacingSm
                    height: 22
                    radius: 8
                    color: Qt.alpha(Colours.onSurface, 0.07)

                    Text {
                        id: recheckLabel
                        anchors.centerIn: parent
                        text: "Re-check"
                        font.pixelSize: Design.fontLabel
                        color: Colours.primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: AppearanceBackend.reconcileInstall()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: parent.height - 30
                radius: 12
                color: Qt.alpha(Colours.onSurface, 0.05)

                ListView {
                    id: logList
                    anchors.fill: parent
                    anchors.margins: Design.spacingSm
                    clip: true
                    model: AppearanceBackend.installLog
                    // Auto-scrolled to the newest line — a fresh entry
                    // means the log grew, so `count - 1` is always the
                    // one just appended.
                    onCountChanged: logList.positionViewAtEnd()

                    delegate: Text {
                        required property var modelData
                        width: logList.width
                        text: modelData.text
                        color: root._levelColor(modelData.level)
                        font.pixelSize: Design.fontLabel
                        wrapMode: Text.WordWrap
                        textFormat: Text.PlainText
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: AppearanceBackend.installLog.length === 0
                    text: "Nothing logged yet — install a theme to see the steps here."
                    color: Colours.outline
                    font.pixelSize: Design.fontLabel
                    wrapMode: Text.WordWrap
                    width: parent.width - Design.spacingXl * 2
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
