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
import "../packages"

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
        // Operator round 3, item 1 — copy WbSidebar.qml's own treatment
        // verbatim rather than inventing a third accent value. In the
        // live Dracula palette `surfaceVariant`/`primaryContainer`/
        // `secondaryContainer` are ALL `#44475a`, and the Atelier's body
        // panel IS `surfaceVariant` (`Atelier.qml`'s `surfaceBase`) — so
        // a container-role selection collides with the panel behind it
        // unless the rail gets its OWN backdrop first. `WbSidebar.qml:87`
        // gives its rail `Qt.alpha(Colours.surface, 0.55)` for exactly
        // this reason; `rail` (the outer Item, not the ListView) carries
        // that background so `Colours.primaryContainer` drawn on top of
        // it is never the same colour as what is behind it.
        Item {
            id: rail
            width: root.railWidth
            height: parent.height

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.surface, 0.55)
            }

            ListView {
                id: railList
                anchors.fill: parent
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
                    // Operator round 3, item 1 — WbSidebar.qml:117's exact
                    // shape: selection is `primaryContainer`, hover is a
                    // flat 6% onSurface tint, rest is transparent. The
                    // round-2 accent-at-13%-plus-2px-bar treatment is
                    // gone — it was reported too bright twice, and the
                    // backdrop above already removes the collision the
                    // accent tint was working around.
                    //
                    // Operator round 4, item 3 — same split as
                    // AtFontsTab.qml's rail: SELECTION is an instant
                    // `visible` toggle (no Behavior), HOVER keeps the
                    // animated `Behavior on color`. Round 3's single
                    // combined `color` binding animated every selection
                    // change too, at `Motion.colourDuration` (300ms) —
                    // that cross-fade on a discrete state change is what
                    // read as "laggy".
                    color: "transparent"

                    Rectangle {
                        id: selectFill
                        anchors.fill: parent
                        radius: parent.radius
                        visible: railRow.selected
                        color: Colours.primaryContainer
                    }

                    Rectangle {
                        id: hoverFill
                        anchors.fill: parent
                        radius: parent.radius
                        visible: !railRow.selected
                        color: railArea.containsMouse ? Qt.alpha(Colours.onSurface, 0.06) : Qt.alpha(Colours.onSurface, 0)

                        Behavior on color {
                            enabled: Motion.motionEnabled
                            ColorAnimation {
                                duration: Motion.colourDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.colourEasing
                            }
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
                            // The APPLIED theme keeps its accent label
                            // colour regardless of selection-for-viewing —
                            // the one marker this file keeps distinguishing
                            // the two states, per the operator's brief.
                            text: railRow.modelData
                            color: railRow.active ? Colours.primary : (railRow.selected ? Colours.onPrimaryContainer : Colours.onSurface)
                            font.pixelSize: Design.settingsFontSub
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }

                        Text {
                            id: covLabel
                            text: railRow._coverage + "/" + railRow._rows.length
                            color: railRow.selected ? Colours.onPrimaryContainer : Colours.onSurfaceVariant
                            font.pixelSize: Design.fontLabel
                            textFormat: Text.PlainText
                        }
                    }

                    MouseArea {
                        id: railArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.selectedTheme = railRow.modelData
                    }
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
                if (detail.compareOn && root._baseline.length > 0) {
                    AppearanceBackend.previewFor(root._baseline);
                    AppearanceBackend.diffPreviewFor(root._baseline);
                }
            }

            // ── Operator round 3, items 2+3 — a real side-by-side
            //    compare, not an asserted `_differs` boolean. Built once
            //    here so the summary text and the Repeater below read the
            //    same probe-paired, sorted list: probes that actually
            //    DIFFER from the baseline render first (the operator's
            //    own brief), everything identical follows.
            readonly property var _pairs: {
                if (!detail.compareOn || detail._baseRows.length === 0)
                    return [];
                var differing = [];
                var same = [];
                for (var i = 0; i < detail._rows.length; ++i) {
                    var sel = detail._rows[i];
                    var base = i < detail._baseRows.length ? detail._baseRows[i] : {
                        probe: sel.probe,
                        path: "-"
                    };
                    var pair = {
                        probe: sel.probe,
                        selPath: sel.path,
                        basePath: base.path,
                        differs: sel.path !== base.path
                    };
                    (pair.differs ? differing : same).push(pair);
                }
                return differing.concat(same);
            }

            // ── The DISTINGUISHING probe set (M1 extended, items 2+3) —
            //    always fetched for the selected theme so the secondary
            //    strip below has something to show even outside Compare;
            //    paired against the baseline once Compare is on. Kept
            //    entirely separate from `_rows`/`_pairs` above so the
            //    primary 12-probe coverage number is never touched by
            //    this addition.
            readonly property var _diffRows: root._effectiveSelected.length > 0 ? AppearanceBackend.diffPreviewFor(root._effectiveSelected) : []
            readonly property var _diffBaseRows: detail.compareOn && root._baseline.length > 0 ? AppearanceBackend.diffPreviewFor(root._baseline) : []
            readonly property int _diffAvailable: {
                var n = 0;
                for (var i = 0; i < detail._diffRows.length; ++i)
                    if (detail._diffRows[i].path !== "-")
                        n++;
                return n;
            }
            readonly property var _diffPairs: {
                var out = [];
                var pairing = detail.compareOn && detail._diffBaseRows.length > 0;
                for (var i = 0; i < detail._diffRows.length; ++i) {
                    var sel = detail._diffRows[i];
                    var base = pairing && i < detail._diffBaseRows.length ? detail._diffBaseRows[i] : null;
                    out.push({
                        probe: sel.probe,
                        selPath: sel.path,
                        basePath: base ? base.path : "-",
                        differs: base !== null && sel.path !== base.path,
                        hasBaseline: base !== null
                    });
                }
                return out;
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

            // ── Primary grid — recognisable names, ALWAYS the selected
            //    theme's own probes (operator round 3, items 2+3: "keep
            //    the primary preview recognisable"). Hidden only while
            //    actively comparing, so the same 12 icons never render
            //    twice — the dedicated side-by-side section below takes
            //    over for that. ─────────────────────────────────────────
            Grid {
                width: detail.width - detail.padding * 2
                visible: !detail.compareOn || root._baseline.length === 0
                columns: 6
                rowSpacing: Design.spacingSm
                columnSpacing: Design.spacingSm

                Repeater {
                    model: detail._rows

                    delegate: Item {
                        id: probeCell
                        required property var modelData

                        readonly property bool _hit: probeCell.modelData.path !== "-"

                        width: (detail.width - detail.padding * 2 - Design.spacingSm * 5) / 6
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

            // ── Compare — a real side-by-side visual (operator round 3,
            //    items 2+3), not an asserted `_differs` boolean: every
            //    probe renders the selected theme's icon NEXT TO the
            //    baseline's, sorted differing-first via `detail._pairs`.
            Column {
                width: detail.width - detail.padding * 2
                visible: detail.compareOn && root._baseline.length > 0
                spacing: Design.spacingSm

                Text {
                    text: detail._diffCount > 0 ? (detail._diffCount + " of " + detail._pairs.length + " differ from " + root._baseline) : (detail._pairs.length + " of " + detail._pairs.length + " identical to " + root._baseline)
                    color: Colours.onSurfaceVariant
                    font.pixelSize: Design.fontLabel
                    textFormat: Text.PlainText
                }

                Column {
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: detail._pairs

                        delegate: Row {
                            id: pairRow
                            required property var modelData

                            width: parent.width
                            height: 40
                            spacing: Design.spacingSm

                            Text {
                                width: 120
                                anchors.verticalCenter: parent.verticalCenter
                                text: pairRow.modelData.probe
                                color: pairRow.modelData.differs ? Colours.onSurface : Colours.onSurfaceVariant
                                font.pixelSize: Design.fontLabel
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }

                            Rectangle {
                                width: 32
                                height: 32
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 6
                                color: "transparent"
                                border.width: pairRow.modelData.differs ? 2 : 0
                                border.color: Colours.primary

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: pairRow.modelData.differs ? 3 : 0
                                    visible: pairRow.modelData.selPath !== "-"
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: 64
                                    sourceSize.height: 64
                                    source: pairRow.modelData.selPath !== "-" ? ("file://" + pairRow.modelData.selPath) : ""
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    visible: pairRow.modelData.selPath === "-"
                                    radius: 3
                                    color: Qt.alpha(Colours.outline, 0.25)
                                }
                            }

                            Rectangle {
                                width: 32
                                height: 32
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 6
                                color: "transparent"

                                Image {
                                    anchors.fill: parent
                                    visible: pairRow.modelData.basePath !== "-"
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: 64
                                    sourceSize.height: 64
                                    source: pairRow.modelData.basePath !== "-" ? ("file://" + pairRow.modelData.basePath) : ""
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    visible: pairRow.modelData.basePath === "-"
                                    radius: 3
                                    color: Qt.alpha(Colours.outline, 0.25)
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: pairRow.modelData.differs ? "differs" : "identical"
                                color: pairRow.modelData.differs ? Colours.primary : Colours.outline
                                font.pixelSize: Design.fontLabel
                                textFormat: Text.PlainText
                            }
                        }
                    }
                }
            }

            // ── Distinguishing probes — operator round 3, items 2+3's
            //    own extra probe set (M1 EXTENDED: `actions/edit-copy`
            //    separates Papirus-Dark, `panel/indicator-messages`
            //    separates Papirus-Light — see AppearanceBackend.qml's
            //    `_DIFF_PROBES` for the measured "why"). A SECONDARY
            //    strip, never a replacement for the recognisable grid
            //    above: always visible so a single theme's own
            //    distinguishing icons show up without needing Compare,
            //    and pairs with the baseline too once Compare is on.
            //    `panel/`'s low coverage (3 of 8 themes) is reported
            //    HONESTLY here — its own count, never folded into the
            //    12-probe coverage above. ──────────────────────────────
            Column {
                width: detail.width - detail.padding * 2
                visible: detail._diffRows.length > 0
                spacing: Design.spacingXs

                Text {
                    text: "Distinguishing probes — " + detail._diffAvailable + " of " + detail._diffRows.length + " available for " + root._effectiveSelected
                    color: Colours.outline
                    font.pixelSize: Design.fontLabel
                    textFormat: Text.PlainText
                }

                Column {
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: detail._diffPairs

                        delegate: Row {
                            id: diffRow
                            required property var modelData

                            width: parent.width
                            height: 36
                            spacing: Design.spacingSm

                            Text {
                                width: 150
                                anchors.verticalCenter: parent.verticalCenter
                                text: diffRow.modelData.probe
                                color: Colours.onSurfaceVariant
                                font.pixelSize: Design.fontLabel
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }

                            Rectangle {
                                width: 28
                                height: 28
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 6
                                color: "transparent"

                                Image {
                                    anchors.fill: parent
                                    visible: diffRow.modelData.selPath !== "-"
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: 56
                                    sourceSize.height: 56
                                    source: diffRow.modelData.selPath !== "-" ? ("file://" + diffRow.modelData.selPath) : ""
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    visible: diffRow.modelData.selPath === "-"
                                    radius: 3
                                    color: Qt.alpha(Colours.outline, 0.25)
                                }
                            }

                            Rectangle {
                                width: 28
                                height: 28
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 6
                                visible: diffRow.modelData.hasBaseline
                                color: "transparent"
                                border.width: diffRow.modelData.differs ? 2 : 0
                                border.color: Colours.primary

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: diffRow.modelData.differs ? 3 : 0
                                    visible: diffRow.modelData.basePath !== "-"
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: 56
                                    sourceSize.height: 56
                                    source: diffRow.modelData.basePath !== "-" ? ("file://" + diffRow.modelData.basePath) : ""
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    visible: diffRow.modelData.basePath === "-"
                                    radius: 3
                                    color: Qt.alpha(Colours.outline, 0.25)
                                }
                            }
                        }
                    }
                }
            }

            // ── Variant bar — Apply (selecting a rail row no longer
            //    applies immediately, matching the Fonts tab's own
            //    select-then-act split) and the working Compare toggle.
            //    Operator round 3, item 1 — every hand-rolled chip here
            //    replaced with `WbButton` (`packages/qmldir`'s one button
            //    shape), rather than a second button language living
            //    beside the shell's own. ─────────────────────────────────
            Row {
                spacing: Design.spacingSm

                WbButton {
                    label: "Apply"
                    tone: "primary"
                    onActivated: AppearanceBackend.applyIconTheme(root._effectiveSelected)
                }

                // Operator round 4, item 1 — wired to `WbButton.active` so
                // Compare visually toggles (renders like hover-at-rest)
                // rather than only changing its own label, per round 3's
                // recorded limitation.
                WbButton {
                    visible: root._baseline.length > 0
                    label: detail.compareOn ? "Hide compare" : "Compare with " + root._baseline
                    tone: "ghost"
                    active: detail.compareOn
                    onActivated: detail.compareOn = !detail.compareOn
                }

                // Operator round 1, defect 1 — proposes a plan; nothing
                // is removed until the confirmation overlay's own
                // explicit Uninstall button is clicked.
                WbButton {
                    label: "Uninstall"
                    tone: "danger"
                    onActivated: AppearanceBackend.proposeUninstallIconTheme(root._effectiveSelected)
                }
            }
        }
    }
}
