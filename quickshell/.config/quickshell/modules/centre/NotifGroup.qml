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
// `resolveAppIconSource()` below is the SAME app-icon/desktop-entry chain
// NotifCard.qml's own icon slot already applies (app_icon via the icon
// theme -> desktop-entry icon via DesktopEntries.byId -> empty), reused
// here rather than a second implementation. The resolver DOES surface a
// detectable failure at every tier (an empty string, confirmed by reading
// `Quickshell.iconPath`'s own qmltypes return type and by NotifCard.qml's
// own existing use of the identical empty-string check) — so the generic-
// glyph fallback fires reliably rather than silently rendering a blank
// slot. (Round 5 gap-closure: this used to be one function,
// `resolveIconSource()`, folding the image-hint tier in ahead of these
// two — split apart so the picture feature's badge can address the app-
// icon tier independently of whichever tier the picture itself uses; see
// this file's own round-5 comments on `headerIconSlot`/`rowIconSlot`.)
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
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
    signal clearNotificationRequested(string key)
    signal clearGroupRequested(string appName)

    readonly property string groupAppName: groupItem.groupData.appName || ""
    readonly property var groupItems: groupItem.groupData.items || []
    readonly property int groupCount: groupItem.groupItems.length
    readonly property var _first: groupItem.groupCount > 0 ? groupItem.groupItems[0] : null

    // GATE-02 gap-closure fix (round 4, item 2; widened round 5, item 3)
    // — mirrors NotifCard.qml's own round-4 item-1 treatment exactly: the
    // ONLY urgency-dependent difference anywhere on a centre row is the
    // fallback glyph (swapped to a danger icon for critical urgency),
    // never the row/header chrome itself. Round 4 read only the group's
    // newest (`_first`) item's urgency for the collapsed header — round 5
    // widened this to ANY item in the group, so a critical notification
    // never loses its danger marker at the collapsed level just because a
    // newer, non-critical notification from the same app arrived after it
    // (the popup shows the marker on every individual critical card
    // regardless of recency; the collapsed header, being one icon for a
    // whole group, needs the same "never hide a critical" guarantee, not
    // "only the newest one's urgency counts"). Each expanded row below
    // still independently reads its own `modelData.urgency`.
    readonly property bool _headerCritical: groupItem.groupItems.some(function (item) {
        return item.urgency === NotificationUrgency.Critical;
    })

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
    // GATE-02 gap-closure fix (round 5 — restored "picture" feature). Was
    // one function, `resolveIconSource()`, folding the image-hint tier in
    // ahead of these two into a single combined value. Split apart because
    // both `headerIconSlot` and `rowIconSlot` (below) now need the app-icon
    // tier addressable on its OWN — as the small corner badge that sits
    // over a large picture, and as the slot's own independent fallback
    // when the picture fails to load (e.g. a raw `image-data` notification
    // reloaded after a restart, whose decoded-pixmap URL does not survive
    // the restart) — neither of which the old combined value could express.
    function resolveAppIconSource(entry) {
        if (!entry)
            return "";
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
        // Round-9 tier (see the `_pictureSrc` note below): a themed icon
        // supplied as `notify-send -i <name>` arrives in `image` as an
        // `image://icon/` provider URI, never in `appIcon`. It is excluded
        // from the picture tier there, so it is picked up HERE — otherwise
        // a sender that supplies only that hint (every theme-engine script
        // in this repo) would resolve no icon at all and fall through to
        // the generic glyph, which is a quieter version of the same bug.
        if (entry.image && entry.image.startsWith("image://icon/"))
            return entry.image;
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

    // quick-260821-swp (R-2): height is spatial (size) — retargeted onto
    // spatial-move.
    Behavior on height {
        enabled: Motion.motionEnabled
        NumberAnimation {
            duration: Motion.spatialMoveDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.spatialMoveEasing
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

        // GATE-02 gap-closure fix (round 5, item 1 — SECOND attempt; the
        // round-4 z-order reorder (e5973b8) did NOT fix this live, per
        // direct user re-test). Abandoning the z-order theory entirely in
        // favour of a GEOMETRIC exclusion: rather than trusting paint/
        // hit-test layering to route the click correctly between two
        // overlapping MouseAreas (headerMouseArea's full-fill area and
        // groupCloseMouseArea nested inside groupActions), this MouseArea's
        // own bounds now physically STOP before groupActions begins —
        // `anchors.right: groupActions.left` instead of `parent.right`.
        // There is no pixel where headerMouseArea and anything inside
        // groupActions (close glyph, count badge, chevron) can BOTH claim
        // hit-test ownership, so there is nothing left for any layering
        // rule (correct or not) to get wrong. The chevron gets its own
        // small MouseArea below (also calling toggleExpandRequested()) so
        // the visual "click to expand" affordance it implies still works;
        // the count badge is left non-interactive (informational only,
        // same as before this round).
        MouseArea {
            id: headerMouseArea
            anchors.left: parent.left
            anchors.right: groupActions.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            hoverEnabled: true
            onClicked: groupItem.toggleExpandRequested()
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
                // GATE-02 gap-closure fix (round 5 — picture persistence
                // honesty). PREVIOUSLY this slot used the single combined
                // `resolveIconSource()` string: if `entry.image` was
                // non-empty it was used unconditionally, with NO fallback
                // to the app icon if that image failed to load — the one
                // real-world case this matters for is a raw `image-data`
                // notification reloaded after a restart, whose persisted
                // `image` field is a `image://qsimage/N/M` URL backed by
                // an in-process pixmap decoder that does not survive the
                // restart. Live-confirmed this exact failure: after a
                // restart, such a group's header fell through straight to
                // the generic bell glyph, never trying the app icon that
                // WAS still resolvable (a real file path, unaffected by
                // the restart) — while this file's own row-level slot
                // (below, using the newer split `_pictureSrc`/
                // `_appIconSrc` properties) already handled this
                // correctly. Rewritten to the same three-tier structure
                // the row uses, so the header now falls through to the
                // app icon exactly like the row does, rather than jumping
                // straight to the bell.
                // GATE-02 gap-closure (round 9 — "script notifications have
                // a missing texture for an icon"). `notify-send -i <name>`
                // does NOT populate `appIcon`: Quickshell surfaces a
                // themed icon hint through the `image` property as an
                // `image://icon/<name>` PROVIDER URI (confirmed against
                // the persisted history — every theme-apply/stress-test
                // entry records appIcon:"" and image:"image://icon/...").
                // Round 5's picture feature then treated that icon as a
                // Caelestia-style photo thumbnail: PreserveAspectCrop'd
                // and mask-cropped to a rounded square. An icon-theme SVG
                // carries transparent padding, so cropping it to a square
                // and scaling it up renders as a near-empty box — the
                // reported missing texture — and because appIcon and
                // desktopEntry are both empty for these senders, the
                // corner badge had no source either, so nothing else drew.
                // An `image://icon/` URI is an ICON, not a picture, and is
                // routed to the icon tier below (PreserveAspectFit,
                // unmasked, no badge). A real image hint — file path, data
                // URI, or the image-data pixmap — is untouched and still
                // gets the full picture treatment.
                readonly property string _pictureSrc: (groupItem._first && groupItem._first.image && groupItem._first.image.length > 0 && !groupItem._first.image.startsWith("image://icon/")) ? groupItem._first.image : ""
                readonly property string _appIconSrc: groupItem.resolveAppIconSource(groupItem._first)

                Image {
                    id: headerPictureImage
                    anchors.fill: parent
                    visible: headerIconSlot._pictureSrc.length > 0 && status !== Image.Error
                    source: headerIconSlot._pictureSrc.length > 0 ? headerIconSlot._pictureSrc : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
                Image {
                    id: headerIconImage
                    anchors.fill: parent
                    visible: !headerPictureImage.visible && headerIconSlot._appIconSrc.length > 0 && status !== Image.Error
                    source: (!headerPictureImage.visible && headerIconSlot._appIconSrc.length > 0) ? headerIconSlot._appIconSrc : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: !headerPictureImage.visible && !headerIconImage.visible
                    // GATE-02 gap-closure fix (round 4, item 2) — same
                    // icon-only urgency marker as NotifCard.qml's fallback
                    // glyph; fires only when no real icon/image resolved.
                    text: groupItem._headerCritical ? "error" : "notifications"
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.iconSizeMd
                    textFormat: Text.PlainText
                    color: groupItem._headerCritical ? BarRoles.danger : BarRoles.capsuleFg
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
                // GATE-02 gap-closure fix (round 6, item 2) — destructive
                // hover: this glyph clears the WHOLE app group, so its
                // hover state reads BarRoles.danger, not the neutral
                // BarRoles.accent every other hover in this file uses.
                color: groupCloseMouseArea.containsMouse ? BarRoles.danger : BarRoles.capsuleFg

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

                // quick-260821-swp (R-2): rotation is spatial — retargeted
                // onto spatial-move.
                Behavior on rotation {
                    enabled: Motion.motionEnabled
                    NumberAnimation {
                        duration: Motion.spatialMoveDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.spatialMoveEasing
                    }
                }

                // GATE-02 gap-closure fix (round 5, item 1) — now that
                // headerMouseArea's own bounds stop before groupActions
                // (see its own comment above), the chevron's visual
                // "click to expand/collapse" affordance needs its own
                // explicit hit area to keep working; it never overlaps
                // groupCloseMouseArea (a different Text item entirely,
                // to the chevron's left) so there is nothing here for a
                // layering rule to get wrong.
                MouseArea {
                    id: chevronMouseArea
                    anchors.fill: parent
                    anchors.margins: -Design.spacingXs
                    onClicked: groupItem.toggleExpandRequested()
                }
            }
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
                // GATE-02 gap-closure fix (round 5 — restored "picture"
                // feature; round 4's own item 3 read 19-DISCUSSION-LOG.md
                // as settling this in favour of the single-slot icon-
                // fallback chain, but the user's direct round-5 correction
                // states the Caelestia-style picture WAS agreed during
                // phase discussion and dropped from the written
                // requirements — treated here as a restored requirement,
                // not a fresh design call. `_pictureSrc` is the image-hint
                // tier ALONE (never the combined chain `resolveIconSource`
                // returns) so it can be composed with `_appIconSrc` as a
                // separate badge, matching Caelestia's own notification-row
                // layout as described by the round-5 instruction: a large
                // rounded-square picture at the row's leading edge with the
                // app's own icon as a small badge overlapping its corner —
                // .planning/research/FEATURES.md's own NOTIF section (read
                // again this round) documents Caelestia's icon-plus-ring-
                // progress treatment but is silent on the exact picture/
                // badge composition, so this follows the standard Caelestia
                // layout the round-5 instruction itself specifies where
                // the research is silent.
                readonly property string _pictureSrc: (notifRow.modelData.image && notifRow.modelData.image.length > 0 && !notifRow.modelData.image.startsWith("image://icon/")) ? notifRow.modelData.image : ""
                readonly property string _appIconSrc: groupItem.resolveAppIconSource(notifRow.modelData)
                // GATE-02 gap-closure fix (round 4, item 2) — per-row
                // urgency marker, same icon-only treatment as the header.
                readonly property bool _critical: notifRow.modelData.urgency === NotificationUrgency.Critical

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

                // GATE-02 gap-closure fix (round 5 — restored "picture"
                // feature). Three tiers now share this one slot, in order:
                // (1) the notification's own picture, large and rounded-
                // square-cropped, with the app icon as a small badge over
                // its bottom-right corner; (2) the app icon alone, at the
                // same large size, when there is no picture (the previous
                // behaviour, unchanged in size/position); (3) the generic
                // glyph placeholder when neither resolves. The masking
                // technique (an invisible `layer.enabled: true` Rectangle
                // read as a `MultiEffect.maskSource`) is the SAME pattern
                // already proven in `dashboard/MediaTab.qml`'s own circular
                // album-art crop — reused here with a rounded-square mask
                // instead of a circle, not reinvented.
                Item {
                    id: rowIconSlot
                    anchors.left: parent.left
                    anchors.leftMargin: Design.spacingSm
                    anchors.top: parent.top
                    anchors.topMargin: Design.spacingSm
                    // GATE-02 gap-closure (round 11) — MEASURED, not
                    // estimated. Screenshotted the open centre with grim
                    // against its own hyprctl layer geometry and measured
                    // the rendered icon bounding boxes off the capture:
                    //   group header icon = 18x18 px
                    //   expanded row icon = 32x32 px
                    // The row's icon was rendering nearly DOUBLE its own
                    // group header's, which inverts the hierarchy — a
                    // child row must not out-weigh the group heading it
                    // sits under. Cause: this slot reused
                    // `Design.notifImageSize` (42), which is the POPUP
                    // CARD's image size. That size is correct there (a
                    // popup is a standalone 430px-wide card and the user
                    // confirmed the popup reads fine) and wrong here (a
                    // centre row is single-density history). Now uses the
                    // SAME token the header slot above uses, so the two
                    // agree by construction rather than by coincidence.
                    width: Design.iconSizeMd
                    height: Design.iconSizeMd

                    // ── Tier 1: the picture ──────────────────────────────
                    Image {
                        id: rowPictureImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        source: notifRow._pictureSrc
                        // Painted only through the MultiEffect below —
                        // see MediaTab.qml's own identical note on why an
                        // unmasked double-draw must be avoided.
                        visible: false
                    }
                    Rectangle {
                        id: rowPictureMaskShape
                        anchors.fill: parent
                        radius: Design.spacingSm
                        visible: false
                        // Load-bearing, not decorative — see MediaTab.qml's
                        // own header note: an invisible item with no
                        // `layer.enabled` produces no paint node at all,
                        // which `MultiEffect.maskSource` reads as an EMPTY
                        // mask rather than a full one.
                        layer.enabled: true
                    }
                    MultiEffect {
                        id: rowPictureMasked
                        anchors.fill: parent
                        source: rowPictureImage
                        maskEnabled: true
                        maskSource: rowPictureMaskShape
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                        // A genuine tier-1 load failure (round 3's own
                        // established guard, reused verbatim) falls
                        // through to the app-icon tier below rather than
                        // masking an empty/broken source.
                        visible: notifRow._pictureSrc.length > 0 && rowPictureImage.status === Image.Ready
                    }

                    // ── Tier 2: app icon alone, same slot, same size as
                    //    before this round — unchanged fallback behaviour
                    //    when there is no picture (or it failed to load). ──
                    Image {
                        id: rowIconImage
                        anchors.fill: parent
                        visible: !rowPictureMasked.visible && notifRow._appIconSrc.length > 0 && status !== Image.Error
                        source: !rowPictureMasked.visible && notifRow._appIconSrc.length > 0 ? notifRow._appIconSrc : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }

                    // ── Tier 3: generic glyph placeholder ────────────────
                    Text {
                        anchors.centerIn: parent
                        visible: !rowPictureMasked.visible && !rowIconImage.visible
                        // GATE-02 gap-closure fix (round 4, item 2).
                        text: notifRow._critical ? "error" : "notifications"
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        textFormat: Text.PlainText
                        color: notifRow._critical ? BarRoles.danger : BarRoles.capsuleFg
                    }

                    // ── App-icon badge — Caelestia's own "small app icon
                    //    overlapping the picture's corner" treatment.
                    //    Rendered ONLY when the picture (not the app icon
                    //    itself) occupies the primary slot, so the badge
                    //    never doubles the app icon over itself. A ring
                    //    (`BarRoles.notifSurface`, the same surface the
                    //    whole row already sits on) separates the badge
                    //    visually from the photo beneath it. ─────────────
                    Rectangle {
                        id: rowBadgeFrame
                        visible: rowPictureMasked.visible && notifRow._appIconSrc.length > 0 && rowBadgeImage.status !== Image.Error
                        width: Design.notifBadgeSize
                        height: Design.notifBadgeSize
                        radius: width / 2
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        color: BarRoles.notifSurface

                        Image {
                            id: rowBadgeImage
                            anchors.fill: parent
                            anchors.margins: Design.spacingXs / 2
                            source: notifRow._appIconSrc
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }
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
                    // GATE-02 gap-closure fix (round 6, item 2) — destructive
                    // hover: this glyph clears one notification, so its
                    // hover state reads BarRoles.danger, matching the
                    // group-level close glyph and the clear-all button
                    // above/in NotifCentre.qml.
                    color: rowCloseMouseArea.containsMouse ? BarRoles.danger : BarRoles.capsuleFg

                    MouseArea {
                        id: rowCloseMouseArea
                        anchors.fill: parent
                        anchors.margins: -Design.spacingXs
                        hoverEnabled: true
                        onClicked: groupItem.clearNotificationRequested(notifRow.modelData.key !== undefined ? notifRow.modelData.key : String(notifRow.modelData.id))
                    }
                }
            }
        }
    }
}
