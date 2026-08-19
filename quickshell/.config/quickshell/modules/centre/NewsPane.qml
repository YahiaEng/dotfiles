// NewsPane.qml — the notification centre's News tab (quick task 260819-6oy):
// the source dropdown, the headline list, and six distinct render states.
// Root type `Item`. Not yet reachable from the UI when this file lands —
// NotifCentre.qml (Task 4 of this quick task) mounts it as page 1 of the
// centre's pager. Deliberately verified in isolation first (lint,
// structure, the state matrix below) so this pane's own content is never
// being debugged at the same time as the header restructure.
//
// ── `_hasBackend` discipline ──────────────────────────────────────────
// Every read of `newsBackend` below goes through `root._hasBackend` first
// — the same `hasBackend` guard `WeatherTab.qml` already uses for its own
// backend seam. Colours come from `BarRoles`/`Colours`, spacing and type
// from `Design`, every duration and easing from `Motion` — `colour-lint`
// rejects hardcoded colours, `motion-lint` rejects raw durations. Mint
// nothing new here that those two singletons already provide.
//
// ── The source dropdown is a deliberate inline expand, not a QQC2 popup
//    control ("dropdown" here means a filter, not the in-shell editor the
//    locked design note defers) — identifiers deliberately NOT spelled
//    out verbatim below, see why at the end of this section ─────────────
// Measured (this quick task's own PLAN.md, citing a repo-wide grep): zero
// instances of any of Qt Quick Controls' three floating/overlay selector
// types exist anywhere under `quickshell/`. One of those types rendering
// correctly inside a Wayland layer surface is therefore UNPROVEN on this
// stack, while the inline-expand idiom is already shipped twice inside
// this very window (`NotifGroup.qml`'s own per-app group expand:
// `implicitHeight` grows by the expanded content's own height, animated
// via a `Behavior on height` bound to `Motion.standardDuration`). This
// pane copies that exact shape rather than introducing a first, unproven
// floating overlay. Anyone wanting a real combo-box-style control here
// must measure it inside a layer surface first, not assume it works.
//
// This file's own fence-verification grep (this quick task's PLAN.md,
// Task 3 Verify) asserts a zero-count for those three exact QQC2 type
// names anywhere in this file, so writing them here — even in a warning
// comment — would make an honest gate report a false failure. This
// quick task's PLAN.md is the citable source of truth for their names.
//
// ── The manage-sources editor (quick task 260819-pi3) — the ONE Qt Quick
//    Controls type used in this file is `TextField`, for the rename and
//    add-flow inputs. The floating/overlay-selector fence in the section
//    above is UNCHANGED and this is not an exception to it — a TextField
//    is not a floating/overlay control. The enabling fact is
//    `WifiPanel.qml:993-1015`: a shipped text field inside a layer
//    surface under on-demand keyboard focus, not an assumption; and
//    `NotifCentre.qml:220`'s `WlrKeyboardFocus.OnDemand` is what makes
//    keystrokes reach it at all. The editor overlay itself follows the
//    selector overlay's own shape exactly: an anchored, raised SIBLING
//    of the headline list (never a layout child of `selectorHost`), so
//    opening it moves nothing.
//
// ── The link opener carries no confirm dialog, unlike NotifCard.qml ────
// `NotifCard.qml:570-590` gates its own external-link opener behind an
// "Open link?" confirm step because THOSE links arrive from arbitrary
// local applications through a Markdown allowlist, filtered only at
// RENDER time. News links are filtered at PARSE time instead — every
// entry that reaches `newsBackend.visibleItems` has already passed
// `NewsBackend._parseFeed()`'s acceptance filter (non-empty title AND a
// link starting with `https://`), so a hostile scheme cannot exist in this
// model to be confirmed. This is a reasoned difference, not an oversight —
// do not "restore" the missing dialog here, and do not remove the parse-
// time filter believing this dialog covers it; they are the SAME
// mitigation applied at two different, deliberately chosen points in this
// feature's two panes. (This file's own single call site is below, in the
// headline delegate's MouseArea.)
import QtQuick
import QtQuick.Controls
import "../"
import "../dashboard"
import "../bar"

Item {
    id: root

    property var newsBackend: null
    readonly property bool _hasBackend: root.newsBackend !== null

    // ── ONE place decides the mode (this quick task) — the delegate, the
    //    toggle chip's glyph and the toggle chip's label all read this
    //    single property and can never disagree, the same discipline
    //    `paneState` above already carries. ─────────────────────────────
    readonly property bool _cardMode: root._hasBackend && root.newsBackend.viewMode === "cards"

    // Module-local geometry constant (this quick task) — NOT a new
    // Design.qml token: used in exactly one file, the same precedent
    // ClockPopout.qml's `_cellHeight` and MediaPopout.qml's `_artSize`
    // already set. 76 sits on the repo's 4px grid (76 / 4 = 19).
    readonly property int _thumbSize: 76

    // Compact-mode row rule (operator report 2026-08-19). Module-local
    // for the same reason `_thumbSize` above is, and following the one
    // existing separator in this repo — WeatherTab.qml declares its own
    // `separatorHeight: 1` locally rather than as a Design.qml token, so
    // a token here would be inventing a convention, not following one.
    readonly property int _ruleHeight: 1

    // ── The six render states — exactly ONE place this decision lives,
    //    so the overlays below can never disagree with each other. ──────
    readonly property string paneState: {
        if (!root._hasBackend)
            return "error";
        var b = root.newsBackend;
        if (b.visibleItems.length > 0)
            return "populated";
        if (b.items.length > 0)
            return "filtered-empty";
        if (b.requestsInFlight > 0)
            return "pending";
        if (b.sources.length === 0)
            return "unconfigured";
        if (b.sourcesFailed > 0 && b.sourcesOk === 0)
            return "error";
        return "empty";
    }

    // Relative-age formatter for the headline metadata line and the
    // populated footer — bucketed the same way NotifGroup.qml's own
    // `_relativeAge` reads (now / minutes / hours / days), reused in
    // spirit rather than imported cross-file (NotifGroup's version is
    // private to that file and keyed off its own `nowMs`, this pane has
    // no shared clock of its own to bind to — `Date.now()` at call time is
    // adequate here since headline ages change on the scale of minutes,
    // not seconds).
    function _relativeAge(ms) {
        if (!isFinite(ms) || ms < 0)
            return "";
        var diffMin = Math.floor(ms / 60000);
        if (diffMin < 1)
            return "just now";
        if (diffMin < 60)
            return diffMin + "m ago";
        var diffHour = Math.floor(diffMin / 60);
        if (diffHour < 24)
            return diffHour + "h ago";
        var diffDay = Math.floor(diffHour / 24);
        return diffDay + "d ago";
    }

    // ── Reason-code → sentence map (this quick task) — pane-local so no
    //    UI copy lives in the backend. Covers every reason code
    //    NewsBackend.qml's mutation API and live probe can return: the
    //    rename/add/delete/enable-toggle mutators (Task 1) and the live
    //    feed probe (Task 2). Returns the code verbatim for anything
    //    unmapped so a new code is visible rather than silent.
    function _reasonText(code) {
        switch (code) {
        case "scheme":
            return "URL must start with https://";
        case "duplicate-url":
            return "That feed is already listed";
        case "duplicate-name":
            return "A source with that name already exists";
        case "empty-name":
            return "Give the source a name";
        case "long-name":
            return "Name is too long (max " + (root._hasBackend ? root.newsBackend.maxSourceNameLen : 32) + " characters)";
        case "full":
            return "The list is full (max " + (root._hasBackend ? root.newsBackend.maxSources : 8) + " sources)";
        case "network":
            return "Could not reach that URL";
        case "http":
            return "The feed returned an error" + (root._hasBackend && root.newsBackend.probeDetail !== "" ? " (" + root.newsBackend.probeDetail + ")" : "");
        case "oversize":
            return "The feed is too large";
        case "not-xml":
            // Split out from "not-a-feed" after a live operator test: a URL
            // that redirects to an HTML page parses to nothing at all, which
            // is a different problem from a URL that serves the wrong XML.
            return "That URL returned a web page, not a feed";
        case "not-a-feed":
            return "Not a readable RSS, Atom or RDF feed" + (root._hasBackend && root.newsBackend.probeDetail !== "" ? " (root <" + root.newsBackend.probeDetail + ">)" : "");
        case "parse":
            return "The feed could not be parsed";
        case "no-items":
            return "The feed parsed but carried no usable headlines";
        case "write-failed":
            return "Could not write news-sources.json";
        case "not-found":
            return "That source is no longer in the list";
        case "centre-closed":
            return "Reopen the centre and try again";
        default:
            return code;
        }
    }

    property bool _selectorExpanded: false

    // ── Editor state (this quick task) — D-2: URL handles, not indices,
    //    because a splice() shifts every later index; an armed confirm
    //    or edit holding an index would, after an unrelated delete, arm
    //    a different row. `_editorExpanded` and `_selectorExpanded` are
    //    mutually exclusive — opening either closes the other, mirroring
    //    the single-overlay-at-a-time discipline this pane already
    //    carries. Closing the editor clears both row-scoped states so
    //    reopening it never resurrects a stale confirm or an armed edit
    //    on a row that may no longer even exist. ─────────────────────
    property bool _editorExpanded: false
    property string _confirmRemoveUrl: ""
    property string _editingUrl: ""

    // Module-local geometry constant (D-4) — NOT a new Design.qml token,
    // following the `_thumbSize`/`_ruleHeight` precedent already in this
    // file: used in exactly one file.
    readonly property int _labelCapWidth: 120

    on_SelectorExpandedChanged: if (root._selectorExpanded)
        root._editorExpanded = false
    on_EditorExpandedChanged: {
        if (root._editorExpanded) {
            root._selectorExpanded = false;
        } else {
            root._confirmRemoveUrl = "";
            root._editingUrl = "";
        }
    }

    // ── (a) The source dropdown — inline expand, see header ─────────────
    Column {
        id: selectorHost
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Design.spacingXs

        // ── The filter chip and the view-mode toggle chip sit side by
        //    side. This Row is now selectorHost's ONLY child: the expanded
        //    option list used to be its second, which is exactly what made
        //    expanding push the headline list down (it anchors to
        //    selectorHost.bottom). The list is a sibling overlay below —
        //    see its own note. ──────────────────────────────────────────
        Row {
            id: chipRow
            spacing: Design.spacingSm

            Rectangle {
                id: selectorChip
                color: BarRoles.capsule
                radius: height / 2
                implicitWidth: selectorRow.implicitWidth + Design.spacingMd * 2
                implicitHeight: selectorRow.implicitHeight + Design.spacingXs * 2
                width: implicitWidth
                height: implicitHeight

                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }

                Row {
                    id: selectorRow
                    anchors.centerIn: parent
                    spacing: Design.spacingXs

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "filter_list"
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        textFormat: Text.PlainText
                        color: BarRoles.capsuleFg
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root._hasBackend && root.newsBackend.selectedSource !== "" ? root.newsBackend.selectedSource : "All sources"
                        textFormat: Text.PlainText
                        font.pixelSize: Design.fontBody
                        color: BarRoles.capsuleFg
                        // D-4 — the pixel-side guarantee for operator-
                        // authored names. A character-count rule alone
                        // cannot serve here: Design.qml deliberately pins
                        // no font family (the shell inherits the GTK font
                        // from gsettings), so pixel width per character is
                        // not knowable at plan time. This label previously
                        // had no width and no elide, and drove
                        // selectorChip.implicitWidth directly.
                        width: Math.min(implicitWidth, root._labelCapWidth)
                        elide: Text.ElideRight
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root._selectorExpanded ? "expand_less" : "expand_more"
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        textFormat: Text.PlainText
                        color: BarRoles.capsuleFg
                    }
                }

                MouseArea {
                    id: selectorMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root._hasBackend
                    onClicked: root._selectorExpanded = !root._selectorExpanded
                }
            }

            // ── The view toggle (this quick task) — mirrors selectorChip
            //    exactly (same fill, radius, content-hugging width,
            //    Behavior on color), but it is a TOGGLE, not a dropdown:
            //    one tap flips compact <-> cards directly, no expand step,
            //    no third chrome state. ────────────────────────────────
            Rectangle {
                id: viewToggleChip
                color: BarRoles.capsule
                radius: height / 2
                implicitWidth: viewToggleRow.implicitWidth + Design.spacingMd * 2
                implicitHeight: viewToggleRow.implicitHeight + Design.spacingXs * 2
                width: implicitWidth
                height: implicitHeight

                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }

                Row {
                    id: viewToggleRow
                    anchors.centerIn: parent
                    spacing: Design.spacingXs

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root._cardMode ? "view_agenda" : "view_list"
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        textFormat: Text.PlainText
                        color: BarRoles.capsuleFg
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root._cardMode ? "Cards" : "Compact"
                        textFormat: Text.PlainText
                        font.pixelSize: Design.fontBody
                        color: BarRoles.capsuleFg
                    }
                }

                MouseArea {
                    id: viewToggleMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root._hasBackend
                    onClicked: root.newsBackend.setViewMode(root._cardMode ? "compact" : "cards")
                }
            }

            // ── The gear chip (this quick task) — mirrors viewToggleChip's
            //    shape (same fill, radius, content-hugging width, Behavior
            //    on color) but ICON-ONLY, carrying no label. Icon-only is
            //    load-bearing: the surface is 430px wide inset by
            //    Design.spacingMd each side, and the two existing chips
            //    already consume most of it. Toggles the manage-sources
            //    editor overlay (below), never the filter dropdown.
            Rectangle {
                id: manageChip
                color: BarRoles.capsule
                radius: height / 2
                implicitWidth: manageGlyph.implicitWidth + Design.spacingMd * 2
                implicitHeight: manageGlyph.implicitHeight + Design.spacingXs * 2
                width: implicitWidth
                height: implicitHeight

                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }

                Text {
                    id: manageGlyph
                    anchors.centerIn: parent
                    text: "settings"
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.iconSizeMd
                    textFormat: Text.PlainText
                    color: BarRoles.capsuleFg
                }

                MouseArea {
                    id: manageMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root._hasBackend
                    onClicked: root._editorExpanded = !root._editorExpanded
                }
            }
        }

    }

        // ── The source dropdown — an OVERLAY, not a layout sibling
        //    (operator report 2026-08-19: expanding it "pushes content
        //    down"). It used to be selectorHost's SECOND Column child, so
        //    expanding grew that column and shoved `headlineList` — which
        //    anchors to `selectorHost.bottom` — down the pane. It is now a
        //    SIBLING of the list, anchored under the chip row and painted
        //    over the headlines on a raised `z`, so opening it moves
        //    nothing.
        //
        //    Still not a floating popup control: the header's reason is
        //    unchanged — no such type is proven inside a Wayland layer
        //    surface on this stack, and none is needed. An anchored
        //    sibling with a `z` is the entire mechanism.
        //
        //    It needs its own OPAQUE backing now that it floats over
        //    content: the option rows are transparent until hovered, and
        //    the window's own `notifSurface` is 0.38 alpha (it leans on
        //    compositor blur), so headlines would read straight through a
        //    panel painted with that. `surfaceVariantColour` is the same
        //    palette family the chip itself uses, at full opacity.
        Rectangle {
            id: selectorOverlay
            anchors.top: selectorHost.bottom
            anchors.topMargin: Design.spacingXs
            anchors.left: selectorHost.left
            anchors.right: selectorHost.right
            height: selectorOptions.implicitHeight + Design.spacingSm * 2
            radius: Design.spacingSm
            color: BarRoles.surfaceVariantColour
            z: 10
            visible: opacity > 0
            opacity: root._selectorExpanded ? 1 : 0

            Behavior on opacity {
                enabled: Motion.motionEnabled
                NumberAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }

            Column {
                id: selectorOptions
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Design.spacingSm
                spacing: Design.spacingXs

                Rectangle {
                    width: parent.width
                    height: allOptionRow.implicitHeight + Design.spacingXs * 2
                    radius: Design.spacingSm
                    color: allOptionMouseArea.containsMouse ? BarRoles.capsuleHover : "transparent"

                    Row {
                        id: allOptionRow
                        anchors.left: parent.left
                        anchors.leftMargin: Design.spacingSm
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Design.spacingXs

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "check"
                            font.family: Design.symbolFontFamily
                            font.pixelSize: Design.fontLabel
                            textFormat: Text.PlainText
                            color: BarRoles.accent
                            visible: root._hasBackend && root.newsBackend.selectedSource === ""
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "All sources"
                            textFormat: Text.PlainText
                            font.pixelSize: Design.fontBody
                            color: BarRoles.notifSurfaceFg
                        }
                    }

                    MouseArea {
                        id: allOptionMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (root._hasBackend)
                                root.newsBackend.selectedSource = "";
                            root._selectorExpanded = false;
                        }
                    }
                }

                Repeater {
                    model: root._hasBackend ? root.newsBackend.sources : []

                    delegate: Rectangle {
                        id: sourceOptionRow
                        required property var modelData

                        readonly property int _count: root._hasBackend ? root.newsBackend.items.filter(function (i) {
                            return i.source === sourceOptionRow.modelData.name;
                        }).length : 0

                        width: selectorOptions.width
                        height: sourceOptionContentRow.implicitHeight + Design.spacingXs * 2
                        radius: Design.spacingSm
                        color: sourceOptionMouseArea.containsMouse ? BarRoles.capsuleHover : "transparent"

                        Row {
                            id: sourceOptionContentRow
                            anchors.left: parent.left
                            anchors.leftMargin: Design.spacingSm
                            anchors.right: sourceOptionCount.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Design.spacingXs

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "check"
                                font.family: Design.symbolFontFamily
                                font.pixelSize: Design.fontLabel
                                textFormat: Text.PlainText
                                color: BarRoles.accent
                                visible: root._hasBackend && root.newsBackend.selectedSource === sourceOptionRow.modelData.name
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: sourceOptionRow.modelData.name
                                textFormat: Text.PlainText
                                font.pixelSize: Design.fontBody
                                color: BarRoles.notifSurfaceFg
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            id: sourceOptionCount
                            anchors.right: parent.right
                            anchors.rightMargin: Design.spacingSm
                            anchors.verticalCenter: parent.verticalCenter
                            text: String(sourceOptionRow._count)
                            textFormat: Text.PlainText
                            font.pixelSize: Design.fontLabel
                            color: BarRoles.capsuleFg
                        }

                        MouseArea {
                            id: sourceOptionMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (root._hasBackend)
                                    root.newsBackend.selectedSource = sourceOptionRow.modelData.name;
                                root._selectorExpanded = false;
                            }
                        }
                    }
                }
            }
        }

        // ── The manage-sources editor overlay (this quick task) — an
        //    anchored, raised SIBLING of the headline list, on a HIGHER
        //    z than the filter overlay, exactly the shape anchor 6
        //    requires: opening it moves nothing. Same opaque-backing
        //    reasoning as selectorOverlay above (the window's own
        //    notifSurface is 0.38 alpha and leans on compositor blur).
        Rectangle {
            id: editorOverlay
            anchors.top: selectorHost.bottom
            anchors.topMargin: Design.spacingXs
            anchors.left: selectorHost.left
            anchors.right: selectorHost.right
            height: editorColumn.implicitHeight + Design.spacingSm * 2
            radius: Design.spacingSm
            color: BarRoles.surfaceVariantColour
            z: 11
            visible: opacity > 0
            opacity: root._editorExpanded ? 1 : 0

            Behavior on opacity {
                enabled: Motion.motionEnabled
                NumberAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }

            Column {
                id: editorColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Design.spacingSm
                spacing: Design.spacingSm

                Text {
                    textFormat: Text.PlainText
                    font.pixelSize: Design.fontLabel
                    color: BarRoles.capsuleFg
                    text: "MANAGE SOURCES"
                }

                Repeater {
                    model: root._hasBackend ? root.newsBackend.allSources : []

                    delegate: Rectangle {
                        id: sourceRow
                        required property var modelData

                        width: editorColumn.width
                        implicitHeight: sourceRowColumn.implicitHeight + Design.spacingXs * 2
                        height: implicitHeight
                        radius: Design.spacingSm
                        color: sourceRowHover.containsMouse ? BarRoles.capsuleHover : "transparent"

                        Behavior on implicitHeight {
                            enabled: Motion.motionEnabled
                            NumberAnimation {
                                duration: Motion.standardDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.standardEasing
                            }
                        }

                        // Full-row hover target, declared first
                        // (underneath) so the more specific verb
                        // MouseAreas declared below it in paint order
                        // take priority over their own small regions —
                        // mirrors WifiPanel.qml's rowPressArea idiom.
                        MouseArea {
                            id: sourceRowHover
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        Column {
                            id: sourceRowColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: Design.spacingSm
                            anchors.rightMargin: Design.spacingSm
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Design.spacingXs

                            Row {
                                id: sourceRowMain
                                width: parent.width
                                height: Design.spacingXl
                                spacing: Design.spacingXs

                                Text {
                                    id: toggleGlyph
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: sourceRow.modelData.enabled ? "check_circle" : "radio_button_unchecked"
                                    font.family: Design.symbolFontFamily
                                    font.pixelSize: Design.iconSizeMd
                                    textFormat: Text.PlainText
                                    color: sourceRow.modelData.enabled ? BarRoles.accent : BarRoles.capsuleFg

                                    // No confirm — disable is reversible
                                    // (D-1).
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: if (root._hasBackend)
                                            root.newsBackend.setSourceEnabled(sourceRow.modelData.url, !sourceRow.modelData.enabled)
                                    }
                                }

                                Text {
                                    id: sourceRowName
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - toggleGlyph.width - closeGlyph.width - parent.spacing * 2
                                    text: sourceRow.modelData.name
                                    textFormat: Text.PlainText
                                    elide: Text.ElideRight
                                    font.pixelSize: Design.fontBody
                                    color: BarRoles.notifSurfaceFg
                                    opacity: sourceRow.modelData.enabled ? 1 : 0.5

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            root._editingUrl = sourceRow.modelData.url;
                                            root._confirmRemoveUrl = "";
                                        }
                                    }
                                }

                                Text {
                                    id: closeGlyph
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "close"
                                    font.family: Design.symbolFontFamily
                                    font.pixelSize: Design.iconSizeMd
                                    textFormat: Text.PlainText
                                    color: BarRoles.capsuleFg

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            root._confirmRemoveUrl = sourceRow.modelData.url;
                                            root._editingUrl = "";
                                        }
                                    }
                                }
                            }

                            // ── Inline rename (D-1/D-2) — shown when
                            //    _editingUrl matches this row's url. Same
                            //    shape rules as WifiPanel.qml:993-1015:
                            //    explicit width/height on the control,
                            //    style only its background, never anchor
                            //    its contentItem. ──────────────────────
                            Row {
                                width: parent.width
                                spacing: Design.spacingXs
                                visible: root._editingUrl === sourceRow.modelData.url

                                TextField {
                                    id: renameField
                                    width: parent.width - renameSave.implicitWidth - renameCancel.implicitWidth - parent.spacing * 2
                                    height: Design.spacingXl
                                    maximumLength: root._hasBackend ? root.newsBackend.maxSourceNameLen : 32
                                    color: BarRoles.notifSurfaceFg
                                    background: Rectangle {
                                        radius: Design.spacingXs
                                        color: BarRoles.capsule
                                    }
                                    // Seeded from the row's current name
                                    // when it becomes visible, and takes
                                    // focus immediately — the Phase 11
                                    // QS-02 gate proved a human can type
                                    // into a text field on a layer-shell
                                    // surface under on-demand keyboard
                                    // focus, the enabling fact, not an
                                    // assumption.
                                    onVisibleChanged: if (renameField.visible) {
                                        renameField.text = sourceRow.modelData.name;
                                        renameField.forceActiveFocus();
                                    }
                                    // Consumed here so Escape cancels the
                                    // edit rather than reaching
                                    // NotifCentre.qml's centre-closing
                                    // handler.
                                    Keys.onEscapePressed: function (event) {
                                        root._editingUrl = "";
                                        event.accepted = true;
                                    }
                                }
                                Text {
                                    id: renameSave
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Save"
                                    textFormat: Text.PlainText
                                    font.pixelSize: Design.fontLabel
                                    font.weight: Design.weightEmphasis
                                    color: BarRoles.accent

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (!root._hasBackend)
                                                return;
                                            var result = root.newsBackend.renameSource(sourceRow.modelData.url, renameField.text);
                                            if (result === "ok") {
                                                // Clear FIRST — the write
                                                // triggers a file reload
                                                // which re-derives
                                                // allSources and rebuilds
                                                // every delegate, so any
                                                // edit state left armed
                                                // would be destroyed
                                                // mid-flight anyway.
                                                root._editingUrl = "";
                                            } else {
                                                renameError.text = root._reasonText(result);
                                            }
                                        }
                                    }
                                }
                                Text {
                                    id: renameCancel
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Cancel"
                                    textFormat: Text.PlainText
                                    font.pixelSize: Design.fontLabel
                                    color: BarRoles.capsuleFg

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root._editingUrl = ""
                                    }
                                }
                            }
                            Text {
                                id: renameError
                                width: parent.width
                                visible: root._editingUrl === sourceRow.modelData.url && text !== ""
                                textFormat: Text.PlainText
                                wrapMode: Text.Wrap
                                font.pixelSize: Design.fontLabel
                                color: BarRoles.danger
                            }

                            // ── Inline delete confirm (D-1/D-2, copying
                            //    WifiPanel.qml:1085-1118) — never a
                            //    modal, keyed by url so an index shift
                            //    can never mis-target a row. ────────────
                            Row {
                                width: parent.width
                                spacing: Design.spacingSm
                                visible: root._confirmRemoveUrl === sourceRow.modelData.url

                                Text {
                                    id: removeConfirmLabel
                                    width: parent.width - removeConfirmYes.implicitWidth - removeConfirmNo.implicitWidth - parent.spacing * 2
                                    textFormat: Text.PlainText
                                    wrapMode: Text.WordWrap
                                    text: "Remove " + sourceRow.modelData.name + "?"
                                    font.pixelSize: Design.fontLabel
                                    color: BarRoles.notifSurfaceFg
                                }
                                Text {
                                    id: removeConfirmYes
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Remove"
                                    textFormat: Text.PlainText
                                    font.pixelSize: Design.fontLabel
                                    font.weight: Design.weightEmphasis
                                    color: BarRoles.danger

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (root._hasBackend)
                                                root.newsBackend.removeSource(sourceRow.modelData.url);
                                            root._confirmRemoveUrl = "";
                                        }
                                    }
                                }
                                Text {
                                    id: removeConfirmNo
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Cancel"
                                    textFormat: Text.PlainText
                                    font.pixelSize: Design.fontLabel
                                    color: BarRoles.capsuleFg

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root._confirmRemoveUrl = ""
                                    }
                                }
                            }
                        }
                    }
                }

                // ── The two-stage add flow (paste → probe → name →
                //    commit, this quick task). Nothing is written to disk
                //    until a probe has returned "ok" for the exact URL
                //    being committed, and the name prefilled is the
                //    feed's own title (falling back to the URL hostname)
                //    but is fully editable — the backend's own commit
                //    mutator re-validates it regardless, so the UI is not
                //    the only thing standing
                //    between an empty name and the file. ────────────────
                Row {
                    id: addUrlRow
                    width: parent.width
                    spacing: Design.spacingXs

                    Item {
                        id: addUrlFieldSlot
                        width: parent.width - addUrlAction.implicitWidth - parent.spacing
                        height: Design.spacingXl

                        TextField {
                            id: addUrlField
                            anchors.fill: parent
                            color: BarRoles.notifSurfaceFg
                            background: Rectangle {
                                radius: Design.spacingXs
                                color: BarRoles.capsule
                            }
                            // Any change to the field's text clears the
                            // probe — a stale "ok" must never be
                            // committable against a URL the operator has
                            // since edited.
                            onTextChanged: if (root._hasBackend)
                                root.newsBackend.clearProbe()
                            onAccepted: if (addUrlField.text !== "" && root._hasBackend)
                                root.newsBackend.probeSource(addUrlField.text)
                            Keys.onEscapePressed: function (event) {
                                root._editorExpanded = false;
                                event.accepted = true;
                            }
                        }

                        // Hand-rolled placeholder — not the control's own
                        // placeholder properties: their availability and
                        // their colour knob on this Qt build are
                        // UNMEASURED, and a hand-rolled one is fully
                        // colour-controlled through BarRoles and cannot
                        // fail colour-lint.
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: Design.spacingSm
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Paste feed URL…"
                            textFormat: Text.PlainText
                            font.pixelSize: Design.fontBody
                            color: BarRoles.capsuleFg
                            visible: addUrlField.text === ""
                        }
                    }

                    // Icon-only action chip, enabled only when the field
                    // is non-empty (dimmed via opacity when not, mirroring
                    // WifiPanel.qml:1030-1035's connectAction).
                    Rectangle {
                        id: addUrlAction
                        color: BarRoles.capsule
                        radius: height / 2
                        implicitWidth: addUrlGlyph.implicitWidth + Design.spacingSm * 2
                        implicitHeight: Design.spacingXl
                        width: implicitWidth
                        height: implicitHeight
                        opacity: addUrlField.text !== "" ? 1 : 0.38

                        Text {
                            id: addUrlGlyph
                            anchors.centerIn: parent
                            text: "add"
                            font.family: Design.symbolFontFamily
                            font.pixelSize: Design.iconSizeMd
                            textFormat: Text.PlainText
                            color: BarRoles.capsuleFg
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: addUrlField.text !== "" && root._hasBackend
                            onClicked: root.newsBackend.probeSource(addUrlField.text)
                        }
                    }
                }

                // ── The probe state line ────────────────────────────────
                Row {
                    width: parent.width
                    spacing: Design.spacingXs
                    visible: root._hasBackend && root.newsBackend.probeState !== "idle"

                    Text {
                        id: probeSpinner
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root._hasBackend && root.newsBackend.probeState === "probing"
                        width: visible ? implicitWidth : 0
                        text: "autorenew"
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        textFormat: Text.PlainText
                        color: BarRoles.capsuleFg

                        // The same ambient-loop-token pattern this
                        // pane's own pending overlay spinner already
                        // uses (below, the non-"populated" states).
                        RotationAnimation on rotation {
                            running: root._hasBackend && root.newsBackend.probeState === "probing" && Motion.motionEnabled
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: Motion.ambientDuration
                        }
                    }

                    Text {
                        width: parent.width - probeSpinner.width - parent.spacing
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        font.pixelSize: Design.fontLabel
                        color: root._hasBackend && root.newsBackend.probeState === "failed" ? BarRoles.danger : BarRoles.capsuleFg
                        text: {
                            if (!root._hasBackend)
                                return "";
                            if (root.newsBackend.probeState === "probing")
                                return "Checking feed…";
                            if (root.newsBackend.probeState === "failed")
                                return root._reasonText(root.newsBackend.probeReason);
                            if (root.newsBackend.probeState === "ok")
                                return root.newsBackend.probeItemCount + " headline(s) found";
                            return "";
                        }
                    }
                }

                // ── Stage B — the name row, visible only when the probe
                //    is ok. Seeded from the feed's own title, fully
                //    editable. ─────────────────────────────────────────
                Row {
                    width: parent.width
                    spacing: Design.spacingXs
                    visible: root._hasBackend && root.newsBackend.probeState === "ok"

                    TextField {
                        id: addNameField
                        width: parent.width - addNameSave.implicitWidth - addNameCancel.implicitWidth - parent.spacing * 2
                        height: Design.spacingXl
                        maximumLength: root._hasBackend ? root.newsBackend.maxSourceNameLen : 32
                        color: BarRoles.notifSurfaceFg
                        background: Rectangle {
                            radius: Design.spacingXs
                            color: BarRoles.capsule
                        }
                        onVisibleChanged: if (addNameField.visible && root._hasBackend)
                            addNameField.text = root.newsBackend.probeTitle
                        Keys.onEscapePressed: function (event) {
                            root._editorExpanded = false;
                            event.accepted = true;
                        }
                    }
                    Text {
                        id: addNameSave
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add source"
                        textFormat: Text.PlainText
                        font.pixelSize: Design.fontLabel
                        font.weight: Design.weightEmphasis
                        color: BarRoles.accent

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!root._hasBackend)
                                    return;
                                var result = root.newsBackend.addSource(root.newsBackend.probeUrl, addNameField.text);
                                if (result === "ok") {
                                    addUrlField.text = "";
                                    addNameField.text = "";
                                    root.newsBackend.clearProbe();
                                } else {
                                    // Leave both fields as they are for
                                    // correction.
                                    addError.text = root._reasonText(result);
                                }
                            }
                        }
                    }
                    Text {
                        id: addNameCancel
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Cancel"
                        textFormat: Text.PlainText
                        font.pixelSize: Design.fontLabel
                        color: BarRoles.capsuleFg

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                addUrlField.text = "";
                                addNameField.text = "";
                                if (root._hasBackend)
                                    root.newsBackend.clearProbe();
                            }
                        }
                    }
                }
                Text {
                    id: addError
                    width: parent.width
                    visible: text !== ""
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    font.pixelSize: Design.fontLabel
                    color: BarRoles.danger
                }
            }
        }

    // ── (b) The headline list ────────────────────────────────────────
    ListView {
        id: headlineList
        anchors.top: selectorHost.bottom
        anchors.topMargin: Design.spacingSm
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.paneState === "populated"
        model: root._hasBackend ? root.newsBackend.visibleItems : []
        spacing: Design.spacingSm
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // ── The populated footer line — visible only when it has
        //    something to say (a Column-style "skip when empty" via zero
        //    height, same mechanism 260818-v3m's weather eyebrow relies
        //    on). sourcesFailed wins over isStale: a partial outage is
        //    more actionable information than a plain age readout. ──────
        footer: Item {
            width: headlineList.width
            height: footerLine.text !== "" ? (footerLine.implicitHeight + Design.spacingSm) : 0

            Text {
                id: footerLine
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Design.spacingXs
                textFormat: Text.PlainText
                font.pixelSize: Design.fontLabel
                color: BarRoles.capsuleFg
                text: {
                    if (!root._hasBackend)
                        return "";
                    var b = root.newsBackend;
                    if (b.sourcesFailed > 0)
                        return b.sourcesFailed + " of " + (b.sourcesFailed + b.sourcesOk) + " sources unreachable";
                    if (b.isStale)
                        return "Updated " + root._relativeAge(b.ageMs);
                    return "";
                }
            }
        }

        // ── ONE delegate serves both modes (this quick task) — a second
        //    delegate would be a second place for the row rhythm to
        //    drift, and the whole point is that geometry is identical
        //    between an image row and a glyph row. ────────────────────
        delegate: Item {
            id: headlineDelegate
            required property var modelData
            // Needed by the compact rule below, which must not draw under
            // the last row (a trailing rule reads as a cut-off list).
            required property int index
            width: headlineList.width
            // Compact gained breathing room (operator report 2026-08-19:
            // "separate articles by a line and small padding for better
            // readability") — spacingSm -> spacingSm + spacingXs per side,
            // i.e. 16px of vertical padding to 24px. Deliberately a modest
            // step, not spacingMd*2: at 32px compact would stand within
            // 6px of the 108px card and stop being the DENSE mode, which
            // is the only reason it exists.
            // Cards: max(76, ~70 content) + 32 = 108px, unchanged.
            readonly property int _compactPadV: Design.spacingSm + Design.spacingXs
            height: root._cardMode ? (Math.max(root._thumbSize, headlineContent.implicitHeight) + Design.spacingMd * 2) : (headlineContent.implicitHeight + headlineDelegate._compactPadV * 2)

            Rectangle {
                anchors.fill: parent
                radius: Design.spacingSm
                color: headlineMouseArea.containsMouse ? BarRoles.notifSurfaceHover : "transparent"

                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }
            }

            // ── Compact-only row rule (operator report 2026-08-19) ───────
            //    COMPACT ONLY, by design: in card mode each article
            //    already owns a filled surface, so a rule between cards
            //    would be a second separation mechanism doing the first
            //    one's job. Compact rows are transparent and share one
            //    background, which is exactly why they need the rule.
            //
            //    Never drawn under the LAST row — a trailing rule reads
            //    as a truncated list rather than a divider. Inset to the
            //    same spacingSm the content column uses, so it aligns
            //    with the text above it rather than spanning the pane.
            //
            //    Mirrors the existing separator idiom
            //    (WeatherTab.qml:665-673): a thin Rectangle on
            //    Colours.outline via BarRoles, radius height/2.
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Design.spacingSm
                anchors.rightMargin: Design.spacingSm
                height: root._ruleHeight
                radius: height / 2
                color: BarRoles.outlineColour
                visible: !root._cardMode && headlineDelegate.index < headlineList.count - 1
            }

            // ── The thumbnail slot (this quick task) — mirrors
            //    NotifCard.qml's iconSlot idiom verbatim: ALWAYS reserved,
            //    NEVER blank, the card never changes width. Two tiers,
            //    one shorter than NotifCard's four — there is no
            //    icon-theme tier because a feed has no app_icon
            //    equivalent. ─────────────────────────────────────────────
            Item {
                id: thumbSlot
                anchors.left: parent.left
                anchors.leftMargin: Design.spacingSm
                anchors.verticalCenter: parent.verticalCenter
                visible: root._cardMode
                width: root._cardMode ? root._thumbSize : 0
                height: root._cardMode ? root._thumbSize : 0

                Rectangle {
                    anchors.fill: parent
                    radius: Design.spacingSm
                    color: BarRoles.capsule

                    // Fallback tier — same glyph tab 1 of the centre
                    // carries ("newspaper"), the same idea as NotifCard's
                    // final tier being the generic bell.
                    Text {
                        anchors.centerIn: parent
                        text: "newspaper"
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        textFormat: Text.PlainText
                        color: BarRoles.capsuleFg
                        visible: thumbImage.status !== Image.Ready
                    }

                    // ── THE ZERO-REQUEST RULE — `visible: false` does NOT
                    //    stop an Image from loading; only gating `source`
                    //    does. Qt issues a network request iff `source` is
                    //    non-empty, so `source` — never `visible` — is the
                    //    load-prevention mechanism. Do not "simplify" this
                    //    to a `visible`-only gate; that silently violates
                    //    "compact issues zero image requests". ────────────
                    Image {
                        id: thumbImage
                        anchors.fill: parent
                        clip: true
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        // Decode bounded to the slot regardless of source
                        // dimensions (Ars ships 500x500, BBC 240x135 —
                        // both downscale into 76).
                        sourceSize.width: root._thumbSize
                        sourceSize.height: root._thumbSize
                        visible: status === Image.Ready
                        source: root._cardMode && headlineDelegate.modelData.image ? headlineDelegate.modelData.image : ""
                    }
                }
            }

            Column {
                id: headlineContent
                anchors.left: thumbSlot.right
                anchors.leftMargin: root._cardMode ? Design.spacingMd : 0
                anchors.right: parent.right
                anchors.rightMargin: Design.spacingSm
                anchors.verticalCenter: parent.verticalCenter
                spacing: Design.spacingXs / 2

                Text {
                    width: parent.width
                    text: headlineDelegate.modelData.title
                    // Remote input — plain text only, never rich or styled.
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.pixelSize: Design.fontBody
                    color: BarRoles.notifSurfaceFg
                }

                // ── Compact meta line — today's single Text, unchanged. ──
                Text {
                    width: parent.width
                    visible: !root._cardMode
                    text: headlineDelegate.modelData.dateMs === 0 ? headlineDelegate.modelData.source : headlineDelegate.modelData.source + " · " + root._relativeAge(Date.now() - headlineDelegate.modelData.dateMs)
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    font.pixelSize: Design.fontLabel
                    color: BarRoles.capsuleFg
                }

                // ── Card meta line — source as a capsule, age beside it. ─
                Row {
                    visible: root._cardMode
                    spacing: Design.spacingXs

                    Rectangle {
                        color: BarRoles.capsule
                        radius: height / 2
                        implicitWidth: sourceCapsuleText.implicitWidth + Design.spacingSm * 2
                        implicitHeight: sourceCapsuleText.implicitHeight + Design.spacingXs
                        width: implicitWidth
                        height: implicitHeight

                        Text {
                            id: sourceCapsuleText
                            anchors.centerIn: parent
                            text: headlineDelegate.modelData.source
                            textFormat: Text.PlainText
                            font.pixelSize: Design.fontLabel
                            color: BarRoles.capsuleFg
                            // D-4 — the pixel-side guarantee, same
                            // reasoning as the filter chip's label above.
                            // This capsule previously had neither a width
                            // nor an elide.
                            width: Math.min(implicitWidth, root._labelCapWidth)
                            elide: Text.ElideRight
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: headlineDelegate.modelData.dateMs === 0 ? "" : root._relativeAge(Date.now() - headlineDelegate.modelData.dateMs)
                        textFormat: Text.PlainText
                        font.pixelSize: Design.fontLabel
                        color: BarRoles.capsuleFg
                    }
                }
            }

            MouseArea {
                id: headlineMouseArea
                anchors.fill: parent
                hoverEnabled: true
                // No "Open link?" confirm — see header for why this is a
                // deliberate difference from NotifCard.qml, not a gap.
                onClicked: Qt.openUrlExternally(headlineDelegate.modelData.link)
            }
        }
    }

    // ── (c) The five non-"populated" overlay states — one Column, shown
    //    only when paneState !== "populated". Each branch renders its own
    //    glyph/headline/sub-line per the state matrix (see this quick
    //    task's PLAN.md). ─────────────────────────────────────────────
    Column {
        id: overlayHost
        anchors.top: selectorHost.bottom
        anchors.topMargin: Design.spacingSm
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.paneState !== "populated"

        Item {
            width: parent.width
            height: overlayHost.height

            Column {
                anchors.centerIn: parent
                spacing: Design.spacingMd
                width: parent.width - Design.spacingLg * 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    textFormat: Text.PlainText
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.iconSizeMd * 2
                    color: BarRoles.capsuleFg
                    text: {
                        switch (root.paneState) {
                        case "filtered-empty":
                            return "filter_list";
                        case "pending":
                            return "autorenew";
                        case "error":
                            return "cloud_off";
                        case "unconfigured":
                            return "newspaper";
                        default:
                            return "newspaper";
                        }
                    }

                    RotationAnimation on rotation {
                        // The same ambient-loop-token pattern
                        // WifiPanel.qml's own rescan spinner uses.
                        running: root.paneState === "pending" && Motion.motionEnabled
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: Motion.ambientDuration
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    font.pixelSize: Design.fontHeading
                    font.weight: Design.weightEmphasis
                    color: BarRoles.notifSurfaceFg
                    text: {
                        switch (root.paneState) {
                        case "filtered-empty":
                            return "No headlines from " + (root._hasBackend ? root.newsBackend.selectedSource : "");
                        case "pending":
                            return "Fetching headlines…";
                        case "error":
                            return "Couldn't reach the feeds";
                        case "unconfigured":
                            return "No news sources configured";
                        default:
                            return "No headlines right now";
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    font.pixelSize: Design.fontLabel
                    color: BarRoles.capsuleFg
                    visible: text !== ""
                    text: {
                        if (root.paneState === "filtered-empty")
                            return "Show all sources";
                        if (root.paneState === "error")
                            return (root._hasBackend && root.newsBackend.lastError !== "" ? root.newsBackend.lastError + " — " : "") + "Tap ⟳ to retry";
                        if (root.paneState === "unconfigured")
                            return "Edit ~/.local/state/theme/news-sources.json";
                        if (root.paneState === "empty")
                            return root._hasBackend ? (root.newsBackend.sourcesOk + root.newsBackend.sourcesFailed) + " source(s) checked" : "";
                        return "";
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.paneState === "filtered-empty"
                        onClicked: {
                            if (root._hasBackend)
                                root.newsBackend.selectedSource = "";
                        }
                    }
                }
            }
        }
    }
}
