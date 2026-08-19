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

    property bool _selectorExpanded: false

    // ── (a) The source dropdown — inline expand, see header ─────────────
    Column {
        id: selectorHost
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Design.spacingXs

        // ── The filter chip and the view-mode toggle chip sit side by
        //    side (this quick task) — the inline expand still drops
        //    under this Row as selectorHost's second child. ──────────────
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
        }

        // ── Inline expanded option list — a plain Column, no Popup (see
        //    header). "All sources" first, then each validated source with
        //    its own item count; the current selection carries a check
        //    glyph. Tap sets `newsBackend.selectedSource` and collapses. ──
        Column {
            id: selectorOptions
            width: selectorHost.width
            visible: opacity > 0
            opacity: root._selectorExpanded ? 1 : 0
            spacing: Design.spacingXs

            Behavior on opacity {
                enabled: Motion.motionEnabled
                NumberAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }

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
            width: headlineList.width
            // Compact stays byte-identical to before this quick task.
            // Cards: max(76, ~70 content) + 32 = 108px.
            height: root._cardMode ? (Math.max(root._thumbSize, headlineContent.implicitHeight) + Design.spacingMd * 2) : (headlineContent.implicitHeight + Design.spacingSm * 2)

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
