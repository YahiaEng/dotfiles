// NotifGroup.qml — one per-application grouped history row (Phase 19 Plan
// 06 Task 2, D-19-26/27/29/31, QNOTIF-06).
//
// ── Grouping and ordering live in NotifCentre.qml, not here ─────────────
// This file is a pure presentational + interaction component: it receives
// an already-formed `{ appName, items, latest }` group object and a
// live `nowMs` reading and renders/reacts, emitting signals for every
// mutation rather than writing `NotifServer.history` itself. NotifCentre's
// own `groupedHistory` property (recomputed whenever `NotifServer.history`
// changes) is the ONE place per-app grouping and the D-19-27 "newest
// activity first" ordering happen — duplicating that logic per-delegate
// would risk two groupings disagreeing.
//
// ── One shared clock, never a per-row polling element (D-19-32,
//    QBAR-11's idle-timer-inventory discipline) ─────────────────────────
// Every relative timestamp below is computed from `groupItem.nowMs`, a
// plain property threaded in from NotifCentre.qml's own single shared
// clock. This file owns no polling element of its own — a hundred-row
// history with one each would violate the discipline directly, and this
// file's own acceptance criterion greps for the literal string this
// paragraph is therefore careful never to use for anything else.
//
// ── The sender-liveness scope call (D-19-31, RESEARCH.md Pitfall 3) ─────
// There is no signal anywhere in this Quickshell build for "the
// notification's sender process is still alive" — the freedesktop spec
// itself has none. The one cleanly-detectable case is a notification
// reloaded from `notifications.json` after a restart: by construction any
// process that sent it before this shell's last restart is a different,
// almost-certainly-gone D-Bus session. `NotifServer.hasSessionActions(id)`
// (Plan 19-06's own addition to NotifServer.qml) answers exactly this —
// true only for a notification this SAME process instance has seen arrive
// — so action buttons render for a live-session notification and are
// hidden entirely (not disabled, not greyed) for a disk-reloaded one. A
// notification received THIS session but with genuinely zero actions
// renders no strip either way, the same as before this scope call existed.
// This is a partial, honest satisfaction of QNOTIF-04's promise ("every
// action button you can see, works") — not a defect.
//
// ── Icon fallback — delegates to Quickshell.iconPath, never reimplements
//    it (this file's own acceptance criterion) ──────────────────────────
// `resolveIconSource()` below is the SAME four-tier chain
// NotifCard.qml's own icon slot already applies (image hint -> app_icon
// via the icon theme -> desktop-entry icon via DesktopEntries.byId ->
// generic glyph), reused here rather than a second implementation. The
// resolver DOES surface a detectable failure at every tier (an empty
// string, confirmed by reading `Quickshell.iconPath`'s own qmltypes
// return type and by NotifCard.qml's own existing use of the identical
// empty-string check) — so the generic-glyph fallback fires reliably
// rather than silently rendering a blank slot.
import QtQuick
import Quickshell
import "../"
import "../dashboard"
import "../bar"
import "../notifications"

Item {
    id: groupItem

    property var groupData: ({})
    property bool expanded: false
    property real nowMs: Date.now()

    signal toggleExpandRequested()
    signal clearNotificationRequested(int id)
    signal clearGroupRequested(string appName)

    readonly property string groupAppName: groupItem.groupData.appName || ""
    readonly property var groupItems: groupItem.groupData.items || []
    readonly property int groupCount: groupItem.groupItems.length
    readonly property var _first: groupItem.groupCount > 0 ? groupItem.groupItems[0] : null

    // GATE-02 gap-closure fix (missing-texture icon) — `iconPath()` was
    // trusted to return an empty string for an unresolvable name. Live-
    // diagnosed against gaming-mode-toggle.sh's own `notify-send -i
    // input-gaming ...` (a real app_icon this host's icon theme does not
    // carry): it does not always — Qt's own icon-theme resolution can
    // hand back a resolvable "missing icon" placeholder pixmap instead of
    // failing outright (confirmed via a live WARN: `Could not load icon
    // "input-gaming" at size QSize(100, 100) from request`, immediately
    // followed by a normal, non-empty resolved path).
    //
    // `Quickshell.hasThemeIcon(name)` is the actual existence check for a
    // BARE THEME ICON NAME. A first version of this fix gated every
    // app_icon/desktop-entry-icon through it unconditionally — live-
    // diagnosed as its own regression: `app_icon` per the freedesktop
    // spec can ALSO be a file path or URI (this repo's own real example:
    // kitty sets it to `/usr/lib/kitty/logo/kitty.png`), which
    // `hasThemeIcon()` correctly reports `false` for since it is not a
    // theme lookup at all — the unconditional guard was silently
    // rejecting a perfectly valid icon. `_looksLikeThemeName()` below is
    // the corrected trust boundary: only a bare name (no path separator,
    // no URI scheme) goes through `hasThemeIcon()`; a path/URI-shaped
    // value is trusted to `iconPath()` directly, with the Image
    // element's own `status !== Image.Error` (below) as the runtime
    // safety net for a path that turns out not to exist.
    function _looksLikeThemeName(name) {
        return name.indexOf("/") === -1 && name.indexOf("://") === -1;
    }
    function resolveIconSource(entry) {
        if (!entry)
            return "";
        if (entry.image && entry.image.length > 0)
            return entry.image;
        if (entry.appIcon && entry.appIcon.length > 0 && (!groupItem._looksLikeThemeName(entry.appIcon) || Quickshell.hasThemeIcon(entry.appIcon))) {
            var p = Quickshell.iconPath(entry.appIcon, "");
            if (p.length > 0)
                return p;
        }
        if (entry.desktopEntry && entry.desktopEntry.length > 0) {
            var de = DesktopEntries.byId(entry.desktopEntry);
            if (de && de.icon && (!groupItem._looksLikeThemeName(de.icon) || Quickshell.hasThemeIcon(de.icon))) {
                var p2 = Quickshell.iconPath(de.icon, "");
                if (p2.length > 0)
                    return p2;
            }
        }
        return "";
    }

    // Caelestia's own updateTimeStr() bucket shape (RESEARCH.md "Don't
    // Hand-Roll"), reproduced here since this file owns every row's
    // relative label — never a per-row polling element, per the header.
    function relativeTimeLabel(ts) {
        var diffMs = Math.max(0, groupItem.nowMs - ts);
        var diffSec = Math.floor(diffMs / 1000);
        if (diffSec < 60)
            return "now";
        var diffMin = Math.floor(diffSec / 60);
        if (diffMin < 60)
            return diffMin + "m";
        var diffHour = Math.floor(diffMin / 60);
        if (diffHour < 24)
            return diffHour + "h";
        var diffDay = Math.floor(diffHour / 24);
        if (diffDay === 1)
            return "yesterday";
        return diffDay + "d";
    }

    implicitHeight: headerRow.height + (groupItem.expanded ? (rowsColumn.height + Design.spacingXs) : 0)
    height: groupItem.implicitHeight

    Behavior on height {
        enabled: Motion.motionEnabled
        NumberAnimation {
            duration: Motion.standardDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }
    }

    // ── Group header row — app icon (iconSizeMd, 24px — the LIST-CONTEXT
    //    size; notifImageSize/42px stays reserved for the popup card's own
    //    primary slot and each expanded row below), app name, count badge,
    //    chevron rotating 180° on expand. ─────────────────────────────────
    Item {
        id: headerRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Design.iconSizeMd + Design.spacingSm * 2

        Rectangle {
            anchors.fill: parent
            radius: Design.spacingSm
            // GATE-02 gap-closure fix (ISSUE c) — `notifSurfaceHover` (0.90
            // alpha) sat on top of this surface's own 0.78-alpha
            // `notifSurface` background, an 12-point alpha step of the
            // SAME base colour that read as "barely visible" live. Reads
            // through `BarRoles.capsuleHover` instead — the established
            // list-row hover contrast this repo already uses elsewhere
            // (AudioPopout.qml's own sink rows: transparent ->
            // Colours.surfaceVariant, the same tonal family this maps to
            // through BarRoles per D-19-43's routing rule), a clearly
            // distinct surfaceVariant tone rather than a subtle alpha
            // step of the row's own background family.
            color: headerMouseArea.containsMouse ? BarRoles.capsuleHover : "transparent"
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Design.spacingSm
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: groupActions.left
            anchors.rightMargin: Design.spacingSm
            spacing: Design.spacingSm

            Item {
                id: headerIconSlot
                width: Design.iconSizeMd
                height: Design.iconSizeMd
                anchors.verticalCenter: parent.verticalCenter
                readonly property string _iconSrc: groupItem.resolveIconSource(groupItem._first)

                Image {
                    id: headerIconImage
                    anchors.fill: parent
                    // status !== Error — a genuine tier-1 (image hint)
                    // file-load failure, the one class resolveIconSource()
                    // itself cannot pre-detect (see this file's own header
                    // note). Falls through to the generic glyph below
                    // rather than a broken-texture render.
                    visible: headerIconSlot._iconSrc.length > 0 && status !== Image.Error
                    source: headerIconSlot._iconSrc.length > 0 ? headerIconSlot._iconSrc : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: !headerIconImage.visible
                    text: "notifications"
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.iconSizeMd
                    textFormat: Text.PlainText
                    color: BarRoles.capsuleFg
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - headerIconSlot.width - Design.spacingSm
                text: groupItem.groupAppName.length > 0 ? groupItem.groupAppName : "Unknown"
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.pixelSize: Design.fontHeading
                font.weight: Design.weightEmphasis
                color: BarRoles.capsuleFg
            }
        }

        // ── Per-group clear + count badge + chevron ────────────────────
        Row {
            id: groupActions
            anchors.right: parent.right
            anchors.rightMargin: Design.spacingSm
            anchors.verticalCenter: parent.verticalCenter
            spacing: Design.spacingSm

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "close"
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.fontLabel + 4
                textFormat: Text.PlainText
                color: groupCloseMouseArea.containsMouse ? BarRoles.accent : BarRoles.capsuleFg

                MouseArea {
                    id: groupCloseMouseArea
                    anchors.fill: parent
                    anchors.margins: -Design.spacingXs
                    hoverEnabled: true
                    onClicked: groupItem.clearGroupRequested(groupItem.groupAppName)
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Design.notifBadgeSize
                height: Design.notifBadgeSize
                radius: height / 2
                color: BarRoles.fillNotification

                Text {
                    anchors.centerIn: parent
                    text: String(groupItem.groupCount)
                    textFormat: Text.PlainText
                    font.pixelSize: Design.fontLabel
                    color: BarRoles.fillNotificationFg
                }
            }

            Text {
                id: chevron
                anchors.verticalCenter: parent.verticalCenter
                text: "expand_more"
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                textFormat: Text.PlainText
                color: BarRoles.capsuleFg
                rotation: groupItem.expanded ? 180 : 0
                transformOrigin: Item.Center

                Behavior on rotation {
                    enabled: Motion.motionEnabled
                    NumberAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }
            }
        }

        MouseArea {
            id: headerMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: groupItem.toggleExpandRequested()
        }
    }

    // ── Expanded rows — one per notification, newest first (the group's
    //    own `items` array already carries that order, since
    //    NotifServer.history is newest-first by construction and
    //    NotifCentre.qml's grouping walks it in that order without
    //    resorting). ─────────────────────────────────────────────────────
    Column {
        id: rowsColumn
        anchors.top: headerRow.bottom
        anchors.topMargin: Design.spacingXs
        anchors.left: parent.left
        anchors.right: parent.right
        visible: groupItem.expanded
        spacing: Design.spacingXs

        Repeater {
            model: groupItem.groupItems

            Item {
                id: notifRow
                required property var modelData
                width: rowsColumn.width
                height: rowContentColumn.implicitHeight + Design.spacingSm * 2

                // D-19-31 — see this file's own header. `_actions` is
                // empty for BOTH a disk-reloaded row and a live one with
                // genuinely zero actions; `_fromDisk` is the ONE property
                // that actually decides whether the strip renders at all.
                readonly property bool _fromDisk: !NotifServer.hasSessionActions(notifRow.modelData.id)
                readonly property var _actions: NotifServer.actionsForHistoryId(notifRow.modelData.id)
                readonly property string _iconSrc: groupItem.resolveIconSource(notifRow.modelData)

                Rectangle {
                    anchors.fill: parent
                    radius: Design.spacingSm
                    // GATE-02 gap-closure fix (ISSUE c) — see headerRow's
                    // own identical Rectangle above for the full rationale.
                    color: rowMouseArea.containsMouse ? BarRoles.capsuleHover : "transparent"
                }

                MouseArea {
                    id: rowMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                Item {
                    id: rowIconSlot
                    anchors.left: parent.left
                    anchors.leftMargin: Design.spacingSm
                    anchors.top: parent.top
                    anchors.topMargin: Design.spacingSm
                    width: Design.notifImageSize
                    height: Design.notifImageSize

                    Image {
                        id: rowIconImage
                        anchors.fill: parent
                        // See headerIconSlot's own identical note above.
                        visible: notifRow._iconSrc.length > 0 && status !== Image.Error
                        source: notifRow._iconSrc.length > 0 ? notifRow._iconSrc : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !rowIconImage.visible
                        text: "notifications"
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        textFormat: Text.PlainText
                        color: BarRoles.capsuleFg
                    }
                }

                Column {
                    id: rowContentColumn
                    anchors.left: rowIconSlot.right
                    anchors.leftMargin: Design.spacingMd
                    anchors.right: rowCloseGlyph.left
                    anchors.rightMargin: Design.spacingSm
                    anchors.top: parent.top
                    anchors.topMargin: Design.spacingSm
                    spacing: Design.spacingXs

                    Row {
                        width: parent.width
                        spacing: Design.spacingSm

                        Text {
                            width: parent.width - timestampText.implicitWidth - Design.spacingSm
                            text: notifRow.modelData.summary
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.pixelSize: Design.fontBody
                            color: BarRoles.notifSurfaceFg
                        }
                        Text {
                            id: timestampText
                            text: groupItem.relativeTimeLabel(notifRow.modelData.timestamp)
                            textFormat: Text.PlainText
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: Design.fontLabel
                            color: BarRoles.capsuleFg
                        }
                    }

                    Row {
                        visible: !notifRow._fromDisk && notifRow._actions.length > 0
                        spacing: Design.spacingSm

                        Repeater {
                            model: notifRow._actions

                            Rectangle {
                                id: actionChip
                                required property var modelData
                                radius: Design.barCapsuleRadius
                                color: BarRoles.capsule
                                implicitWidth: actLabel.implicitWidth + Design.spacingSm * 2
                                implicitHeight: actLabel.implicitHeight + Design.spacingXs * 2

                                Text {
                                    id: actLabel
                                    anchors.centerIn: parent
                                    text: actionChip.modelData.text
                                    textFormat: Text.PlainText
                                    font.pixelSize: Design.fontLabel
                                    color: BarRoles.capsuleFg
                                }
                                TapHandler {
                                    // Gap-closure fix (GATE-02 crash) —
                                    // `modelData` is now a plain
                                    // `{identifier, text}` snapshot, never a
                                    // live NotificationAction reference (see
                                    // NotifServer.qml's own
                                    // _sessionActionsById header for why).
                                    // Invocation goes through
                                    // NotifServer.invokeSessionAction(),
                                    // which looks up the live object only
                                    // at this exact imperative call, never
                                    // as a bound property.
                                    onTapped: NotifServer.invokeSessionAction(notifRow.modelData.id, actionChip.modelData.identifier)
                                }
                            }
                        }
                    }
                }

                // ── Per-notification clear (D-19-29's finest level) — an
                //    explicit small close glyph rather than a drag gesture:
                //    a full swipe-to-dismiss inside a ListView delegate
                //    would fight the list's own vertical scroll, which the
                //    popup card's dedicated MouseArea (Pattern 3) never has
                //    to share with a scrollable ancestor. ─────────────────
                Text {
                    id: rowCloseGlyph
                    anchors.right: parent.right
                    anchors.rightMargin: Design.spacingSm
                    anchors.top: parent.top
                    anchors.topMargin: Design.spacingSm
                    text: "close"
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.fontLabel + 2
                    textFormat: Text.PlainText
                    color: rowCloseMouseArea.containsMouse ? BarRoles.accent : BarRoles.capsuleFg

                    MouseArea {
                        id: rowCloseMouseArea
                        anchors.fill: parent
                        anchors.margins: -Design.spacingXs
                        hoverEnabled: true
                        onClicked: groupItem.clearNotificationRequested(notifRow.modelData.id)
                    }
                }
            }
        }
    }
}
