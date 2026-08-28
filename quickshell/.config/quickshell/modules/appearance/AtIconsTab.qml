// modules/appearance/AtIconsTab.qml — the Atelier's Icons tab (quick task
// 260828-ah9, Task 2; rebuilt operator round 1, defect 2e).
//
// M1 — MEASURED, not a style choice: `Papirus`, `Papirus-Dark` and
// `Papirus-Light` are byte-identical (same MD5) at every 48x48 icon
// probed. The variants override only their 16/18/22/24px glyphs, so a
// grid rendered at 48px cannot distinguish them — every preview here is
// requested at 22px, never 48. `AppearanceBackend.previewFor(theme)` is
// the ONLY source for the per-cell rows; this file never shells out
// itself.
//
// M3 — no icon name exists in all eight installed themes on this host
// (Adwaita ships no `utilities-terminal`; AdwaitaLegacy is PNG-only;
// breeze is missing others). A probe that resolved to `-` renders a
// visible placeholder cell, never an empty gap — coverage is information
// to show, not hide, and the rail's own count row states it as a number
// too ("10/12").
//
// ── OPERATOR ROUND 1 (defect 2e) ────────────────────────────────────────
// The old surface was a bare GridView with no detail pane and no compare
// — every theme got its own tiny 22px grid, which is exactly the layout
// M1 exists to argue against (too small to actually judge). Rebuilt as
// the study's own `.fontsplit` shape: a resizable LEFT rail (name +
// coverage count) and a full-size detail pane on the right, with a
// working "Compare with <baseline>" control built entirely from
// `previewFor()`'s already-cached per-theme rows — no new backend verb.
import QtQuick
import ".."
import "../dashboard"

Item {
    id: root

    readonly property var _themes: AppearanceBackend.iconThemes

    property string selectedTheme: ""

    readonly property string _effectiveSelected: {
        if (root._themes.length === 0)
            return "";
        if (root.selectedTheme.length > 0 && root._themes.indexOf(root.selectedTheme) >= 0)
            return root.selectedTheme;
        if (root._themes.indexOf(AppearanceBackend.iconThemeName) >= 0)
            return AppearanceBackend.iconThemeName;
        return root._themes[0];
    }

    // The comparison baseline — "Papirus" when it is installed and is
    // not itself the selection (the study's own example: Papirus-Dark
    // compares against Papirus), else the first other installed theme.
    readonly property string _baseline: {
        if (root._themes.length < 2)
            return "";
        if (root._themes.indexOf("Papirus") >= 0 && "Papirus" !== root._effectiveSelected)
            return "Papirus";
        for (var i = 0; i < root._themes.length; ++i)
            if (root._themes[i] !== root._effectiveSelected)
                return root._themes[i];
        return "";
    }

    function _coverageFor(theme) {
        var rows = AppearanceBackend.previewFor(theme);
        var c = 0;
        for (var i = 0; i < rows.length; ++i)
            if (rows[i].path !== "-")
                c++;
        return c;
    }

    // Resizable rail width (defect 2c/2e), persisted like
    // `packages.sidebarWidth` — same [150, 460] clamp, same 220 default
    // seeded from the study's own `.fontsplit` 210px column.
    property int railWidth: Math.max(150, Math.min(460, Prefs.getValue("appearance.iconsRailWidth")))

    function setRailWidth(w) {
        var clamped = Math.max(150, Math.min(460, Math.round(w)));
        if (clamped === root.railWidth)
            return;
        root.railWidth = clamped;
        Prefs.setValue("appearance.iconsRailWidth", clamped);
    }

    Text {
        anchors.centerIn: parent
        visible: root._themes.length === 0
        text: AppearanceBackend.iconThemesProbed ? "No icon themes found" : "Loading icon themes…"
        color: Colours.outline
        font.pixelSize: Design.settingsFontSub
    }

    Row {
        anchors.fill: parent
        visible: root._themes.length > 0
        spacing: 0

        // ── Left rail — theme name + coverage count. ──────────────────
        ListView {
            id: rail
            width: root.railWidth
            height: parent.height
            clip: true
            model: root._themes

            delegate: Rectangle {
                id: railRow
                required property string modelData

                readonly property bool selected: railRow.modelData === root._effectiveSelected
                readonly property bool active: railRow.modelData === AppearanceBackend.iconThemeName
                readonly property var _rows: AppearanceBackend.previewFor(railRow.modelData)
                readonly property int _coverage: root._coverageFor(railRow.modelData)

                width: rail.width
                height: 44
                radius: 10
                color: railRow.selected ? Colours.surfaceVariant : "transparent"

                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.colourDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.colourEasing
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Design.spacingSm
                    spacing: Design.spacingXs

                    Text {
                        width: parent.width - covLabel.implicitWidth - Design.spacingXs
                        text: railRow.modelData
                        color: railRow.active ? Colours.primary : Colours.onSurface
                        font.pixelSize: Design.settingsFontSub
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    Text {
                        id: covLabel
                        text: railRow._coverage + "/" + railRow._rows.length
                        color: Colours.onSurfaceVariant
                        font.pixelSize: Design.fontLabel
                        textFormat: Text.PlainText
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.selectedTheme = railRow.modelData
                }
            }
        }

        AtRailGrip {
            id: grip
            height: parent.height
            startWidth: root.railWidth
            onDragged: proposedWidth => root.setRailWidth(proposedWidth)
        }

        // ── Right pane — the selected theme's detail + compare. ────────
        Column {
            id: detail
            width: parent.width - rail.width - grip.width
            height: parent.height
            padding: Design.spacingMd
            spacing: Design.spacingMd

            property bool compareOn: false

            readonly property var _rows: AppearanceBackend.previewFor(root._effectiveSelected)
            readonly property var _baseRows: detail.compareOn && root._baseline.length > 0 ? AppearanceBackend.previewFor(root._baseline) : []
            readonly property int _coverage: root._coverageFor(root._effectiveSelected)
            // How many of the 12 probes resolve to a DIFFERENT path than
            // the baseline theme — the working compare this defect asks
            // for, built entirely from two cached `previewFor()` calls,
            // no new backend verb.
            readonly property int _diffCount: {
                if (!detail.compareOn || detail._baseRows.length === 0)
                    return 0;
                var n = 0;
                for (var i = 0; i < detail._rows.length && i < detail._baseRows.length; ++i)
                    if (detail._rows[i].path !== detail._baseRows[i].path)
                        n++;
                return n;
            }

            onCompareOnChanged: {
                if (detail.compareOn && root._baseline.length > 0)
                    AppearanceBackend.previewFor(root._baseline);
            }

            Row {
                width: detail.width - detail.padding * 2
                spacing: Design.spacingSm

                Text {
                    width: parent.width - coverageSummary.implicitWidth - Design.spacingSm
                    text: root._effectiveSelected
                    color: Colours.onSurface
                    font.pixelSize: Design.fontHeading
                    font.bold: true
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                Text {
                    id: coverageSummary
                    anchors.verticalCenter: parent.verticalCenter
                    text: detail._coverage + "/" + detail._rows.length + " probes"
                    color: Colours.onSurfaceVariant
                    font.pixelSize: Design.fontLabel
                    textFormat: Text.PlainText
                }
            }

            Text {
                width: detail.width - detail.padding * 2
                text: "22px — every theme in this shell is previewed here, never at 48px (M1: three of eight are identical at 48)"
                color: Colours.outline
                font.pixelSize: Design.fontLabel
                wrapMode: Text.WordWrap
                textFormat: Text.PlainText
            }

            // The selected theme's own 22px probe row.
            Grid {
                width: detail.width - detail.padding * 2
                columns: 6
                rowSpacing: Design.spacingSm
                columnSpacing: Design.spacingSm

                Repeater {
                    model: detail._rows

                    delegate: Item {
                        id: probeCell
                        required property var modelData
                        required property int index

                        readonly property bool _hit: probeCell.modelData.path !== "-"
                        readonly property bool _differs: detail.compareOn && detail._baseRows.length > probeCell.index && detail._baseRows[probeCell.index].path !== probeCell.modelData.path

                        width: (detail.width - detail.padding * 2 - Design.spacingSm * 5) / 6
                        height: width

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: "transparent"
                            border.width: probeCell._differs ? 2 : 0
                            border.color: Colours.primary
                        }

                        Image {
                            anchors.fill: parent
                            anchors.margins: probeCell._differs ? 3 : 0
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

            // Baseline row, shown only while comparing — the same probe
            // set for `_baseline`, so the two rows line up cell-for-cell.
            Column {
                width: detail.width - detail.padding * 2
                visible: detail.compareOn && root._baseline.length > 0
                spacing: Design.spacingXs

                Text {
                    text: root._baseline + " (baseline) — " + detail._diffCount + " of " + detail._rows.length + " differ"
                    color: Colours.onSurfaceVariant
                    font.pixelSize: Design.fontLabel
                    textFormat: Text.PlainText
                }

                Grid {
                    width: parent.width
                    columns: 6
                    rowSpacing: Design.spacingSm
                    columnSpacing: Design.spacingSm

                    Repeater {
                        model: detail._baseRows

                        delegate: Item {
                            id: baseCell
                            required property var modelData

                            readonly property bool _hit: baseCell.modelData.path !== "-"

                            width: (detail.width - detail.padding * 2 - Design.spacingSm * 5) / 6
                            height: width

                            Image {
                                anchors.fill: parent
                                visible: baseCell._hit
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                                sourceSize.width: baseCell.width * 2
                                sourceSize.height: baseCell.height * 2
                                source: baseCell._hit ? ("file://" + baseCell.modelData.path) : ""
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: !baseCell._hit
                                radius: 3
                                color: Qt.alpha(Colours.outline, 0.25)
                            }
                        }
                    }
                }
            }

            // ── Variant bar — Apply (selecting a rail row no longer
            //    applies immediately, matching the Fonts tab's own
            //    select-then-act split) and the working Compare toggle. ──
            Row {
                spacing: Design.spacingSm

                Rectangle {
                    id: applyChip
                    radius: 99
                    color: Qt.alpha(Colours.primary, 0.16)
                    border.width: 1
                    border.color: Colours.primary
                    width: applyLabel.implicitWidth + Design.spacingMd
                    height: applyLabel.implicitHeight + Design.spacingSm

                    Text {
                        id: applyLabel
                        anchors.centerIn: parent
                        text: "Apply"
                        color: Colours.primary
                        font.pixelSize: Design.fontLabel
                        textFormat: Text.PlainText
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: AppearanceBackend.applyIconTheme(root._effectiveSelected)
                    }
                }

                Rectangle {
                    id: compareChip
                    visible: root._baseline.length > 0
                    radius: 99
                    color: detail.compareOn ? Qt.alpha(Colours.primary, 0.16) : "transparent"
                    border.width: 1
                    border.color: detail.compareOn ? Colours.primary : Qt.alpha(Colours.outline, 0.5)
                    width: compareLabel.implicitWidth + Design.spacingMd
                    height: compareLabel.implicitHeight + Design.spacingSm

                    Text {
                        id: compareLabel
                        anchors.centerIn: parent
                        text: "Compare with " + root._baseline
                        color: detail.compareOn ? Colours.primary : Colours.onSurfaceVariant
                        font.pixelSize: Design.fontLabel
                        textFormat: Text.PlainText
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: detail.compareOn = !detail.compareOn
                    }
                }
            }
        }
    }
}
