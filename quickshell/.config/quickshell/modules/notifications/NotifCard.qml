// NotifCard.qml — the popup card body, expanded to its full interaction
// surface (Phase 19 Plan 04, QNOTIF-02/03/04/05, D-19-05..12/40).
//
// Built out from the Phase 19 Plan 01 tracer's compact-only card. Fixed
// `Design.notifSurfaceWidth` (430px) wide, content-driven height — only
// the width is fixed, matching 19-UI-SPEC.md's "Card anatomy" table.
// Fill from `BarRoles.notifSurface`/`notifSurfaceFg` (or the
// `danger`/`onDanger` pair under critical urgency, D-19-11) — never a
// direct `Colours.*` reference or a hex literal (D-19-43, GATE-04).
//
// ── One gesture hit area, two axes (RESEARCH.md Pattern 3, verbatim
//    mechanism) ─────────────────────────────────────────────────────────
// `gestureArea` is the ONLY `MouseArea` this file declares — the card-wide
// drag (X = dismiss, Y = expand), middle-click, and left-click-default-
// action all live on it, disambiguated by whichever threshold fires
// first, never by two overlapping hit areas. Every other tappable element
// (action buttons, the copy-body action, the link-confirm pair) uses
// `TapHandler` instead of a second `MouseArea` — Task 1's own acceptance
// criterion greps this file for `MouseArea` and expects exactly one card-
// level match; nested `TapHandler`s inside the actions strip are declared
// AFTER `gestureArea` so they paint on top and claim their own smaller
// taps first, while `gestureArea` still receives everything else within
// the card body.
//
// ── Dismiss timer as an explicit remaining/resume state machine ─────────
// D-19-06's "hover pauses, leaving resumes — not a reset, not sticky"
// cannot be expressed with a bare declarative `running:` binding (a QML
// `Timer` restarts from zero elapsed on stop+start, and Design's own
// the retired daemon's matching windows are not the sender's `expireTimeout`, so there
// is nothing to re-bind `interval` to for a natural pause/resume). Instead
// `_remainingMs` tracks what is left, `_pauseDismissTimer`/
// `_startDismissTimer` snapshot/restore it against `Date.now()`, and
// `_resetDismissTimer` (D-19-08's own "restarts at the new expire
// timeout") sets it back to the FULL urgency window rather than resuming
// a partial one — the one case that genuinely IS a reset, not a resume.
//
// ── `replaces_id` in-place update (Pattern 2, D-19-08, QNOTIF-05) ──────
// No `isReplace` suppression branch exists anywhere in this file — the
// no-reflow/no-reorder guarantee is structural (NotifData's own wrapper
// reuse, RESEARCH.md Pattern 2), not something this file re-derives. The
// `Connections` block below exists ONLY to restart the dismiss timer on a
// genuine replace (D-19-08's stated behaviour), never to gate animation.
//
// ── T-19-01/T-19-10 (LEDGER-08's mitigation) ─────────────────────────────
// The summary `Text` stays pinned `textFormat: Text.PlainText` — titles
// never carry markdown in this design. The body `Text` now renders through
// `NotifMarkdown.filter()` before `Text.MarkdownText` (T-19-10's
// escape-then-allowlist mitigation) rather than staying plain-text-pinned,
// since D-19-40 requires bold/italic/link rendering — the allowlist filter
// IS this surface's untrusted-string control now, not a blunt format pin.
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../"
import "../dashboard"
import "../bar"

Item {
    id: card

    // The wrapped NotifData instance (never the raw Notification) — set
    // by NotifPopupStack.qml's ListView delegate, mirroring this repo's
    // own `delegate: StreamRow { node: modelData }` idiom
    // (AudioPanel.qml:832).
    property var notifData: null

    readonly property string summary: card.notifData ? card.notifData.summary : ""
    readonly property string body: card.notifData ? card.notifData.body : ""
    readonly property string appIcon: card.notifData ? card.notifData.appIcon : ""
    readonly property string image: card.notifData ? card.notifData.image : ""
    readonly property int urgency: card.notifData ? card.notifData.urgency : NotificationUrgency.Normal
    readonly property int notifId: card.notifData ? card.notifData.notifId : -1
    readonly property var _liveActions: card.notifData ? card.notifData.actions : []

    readonly property bool _critical: card.urgency === NotificationUrgency.Critical
    readonly property bool _low: card.urgency === NotificationUrgency.Low

    // ── GATE-02 gap-closure fix (round 4, item 1) — DESIGN REVERSAL over
    //    round 3's own tiered-surface treatment (c474164, reverted this
    //    round: 65e4787), itself a reversal of D-19-11's original
    //    whole-card danger swap. Direct user instruction this round:
    //    critical notifications keep the IDENTICAL card design as normal
    //    — no separate surface wash, no separate rim, nothing chrome-wide
    //    — the ONLY difference anywhere on the card is the fallback icon
    //    (see iconSlot's own Text below), swapped to a danger glyph.
    //    `_fill`/`_fg` are therefore now UNCONDITIONAL — every urgency
    //    tier reads the exact same two roles. ─────────────────────────
    readonly property color _fill: BarRoles.notifSurface
    readonly property color _fg: BarRoles.notifSurfaceFg

    // ── D-19-05 expanded state — drag-only, never hover-triggered. ──────
    property bool expanded: false

    width: Design.notifSurfaceWidth
    implicitHeight: Math.max(Design.notifImageSize, contentColumn.implicitHeight) + Design.spacingMd * 2
    height: card.implicitHeight

    Rectangle {
        id: background
        anchors.fill: parent
        radius: Design.popoutCornerRadius
        color: card._fill

        Behavior on color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

    GradientBorder {
        anchors.fill: parent
        borderWidth: Design.notifRingStrokeWidth
        topLeftRadius: Design.popoutCornerRadius
        topRightRadius: Design.popoutCornerRadius
        bottomLeftRadius: Design.popoutCornerRadius
        bottomRightRadius: Design.popoutCornerRadius
    }

    // ── The one card-level gesture hit area (Pattern 3) ──────────────────
    MouseArea {
        id: gestureArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        preventStealing: true

        property real _startY: 0

        onEntered: card._pauseDismissTimer()
        onExited: {
            if (!gestureArea.pressed)
                card._resumeDismissTimer();
        }

        drag.target: card
        drag.axis: Drag.XAxis

        onPressed: event => {
            card._pauseDismissTimer();
            gestureArea._startY = event.y;
            if (event.button === Qt.MiddleButton)
                NotifServer.dismiss(card.notifId);
        }
        onReleased: event => {
            if (!gestureArea.containsMouse)
                card._resumeDismissTimer();
            if (Math.abs(card.x) < card.implicitWidth * Design.notifDismissThresholdFraction)
                card.x = 0;
            else
                NotifServer.dismiss(card.notifId);
        }
        onPositionChanged: event => {
            if (gestureArea.pressed) {
                var diffY = event.y - gestureArea._startY;
                if (Math.abs(diffY) > Design.notifExpandThresholdPx)
                    card.expanded = diffY > 0;
            }
        }
        onClicked: event => {
            if (event.button !== Qt.LeftButton)
                return;
            if (card._liveActions.length === 1)
                card._liveActions[0].invoke();
            else
                NotifServer.dismiss(card.notifId);
        }
    }

    Item {
        id: contentArea
        anchors.fill: parent
        anchors.margins: Design.spacingMd

        // ── Icon slot — D-19-12's full four-tier fallback chain: image
        //    hint -> named app_icon via the icon theme -> desktop-entry
        //    icon (via the toolkit's own DesktopEntries resolver, never
        //    hand-rolled desktop-file parsing) -> generic Material Symbols
        //    bell glyph. Every tier renders inside the SAME
        //    notifImageSize slot, never a blank slot, never a card that
        //    changes width. ─────────────────────────────────────────────
        Item {
            id: iconSlot
            anchors.left: parent.left
            anchors.top: parent.top
            width: Design.notifImageSize
            height: Design.notifImageSize

            // ── GATE-02 gap-closure fix (missing-texture icon) ────────────
            // ROOT CAUSE: `Quickshell.iconPath(name, "")` was trusted to
            // return an empty string whenever `name` cannot be resolved.
            // Live-diagnosed: it does not always. `gaming-mode-toggle.sh`'s
            // own `notify-send -i input-gaming ...` sends an app_icon that
            // is not present in the installed icon theme, and Qt's own
            // icon-theme resolution machinery was observed (WARN in
            // ~/.cache/quickshell.log: "Could not load icon "input-gaming"
            // at size QSize(100, 100) from request") to still hand back
            // SOME resolvable path — very likely a generic "missing icon"
            // placeholder pixmap baked in by the theme/Qt's own fallback,
            // which then reports a perfectly normal `Image.status: Ready`
            // and renders as a literal broken-texture glyph, not a QML
            // load failure `visible: length > 0` could ever catch.
            // `Quickshell.hasThemeIcon(name)` (same API family, confirmed
            // present in this build's qmltypes) is the actual existence
            // check — resolution is now gated on THAT, not on whichever
            // string `iconPath()` happens to hand back for a name that
            // does not exist. This applies to both icon-theme tiers (2:
            // app_icon, 3: desktop-entry icon); tier 1 (the image hint,
            // always a raw file path, never an icon-theme lookup) instead
            // gates on the Image element's own `status`, since a missing
            // FILE genuinely does report `Image.Error` with nothing
            // rendered — no icon-theme fallback machinery is in that path
            // to disguise the failure.
            //
            // CORRECTED — the first version of this fix gated every
            // app_icon/desktop-entry-icon through `hasThemeIcon()`
            // unconditionally, which is itself a regression:
            // `app_icon` per the freedesktop spec can ALSO be a file path
            // or URI (this repo's own real example: kitty sets it to
            // `/usr/lib/kitty/logo/kitty.png`), which `hasThemeIcon()`
            // correctly reports `false` for since it is not a theme
            // lookup at all — the unconditional guard silently rejected a
            // perfectly valid icon. `_looksLikeThemeName()` is the
            // corrected trust boundary: only a bare name (no path
            // separator, no URI scheme) goes through `hasThemeIcon()`; a
            // path/URI-shaped value is trusted to `iconPath()` directly,
            // with the Image element's own `status` as the runtime
            // safety net. ─────────────────────────────────────────────
            function _looksLikeThemeName(name) {
                return name.indexOf("/") === -1 && name.indexOf("://") === -1;
            }
            readonly property string _appIconResolved: (card.appIcon.length > 0 && (!iconSlot._looksLikeThemeName(card.appIcon) || Quickshell.hasThemeIcon(card.appIcon))) ? Quickshell.iconPath(card.appIcon, "") : ""
            readonly property string _desktopEntryIconName: {
                var de = card.notifData && card.notifData.notification ? card.notifData.notification.desktopEntry : "";
                if (!de || de.length === 0)
                    return "";
                var entry = DesktopEntries.byId(de);
                return entry ? entry.icon : "";
            }
            readonly property string _desktopIconResolved: (iconSlot._desktopEntryIconName.length > 0 && (!iconSlot._looksLikeThemeName(iconSlot._desktopEntryIconName) || Quickshell.hasThemeIcon(iconSlot._desktopEntryIconName))) ? Quickshell.iconPath(iconSlot._desktopEntryIconName, "") : ""

            // GATE-02 gap-closure fix (round 5 — restored "picture"
            // feature, mirroring NotifGroup.qml's own identical round-5
            // treatment for the centre's rows). Tier 1 (the image hint,
            // `card.image`) is now shown large and rounded-square-cropped
            // via the SAME `MultiEffect`+mask-`Rectangle` technique already
            // proven in `dashboard/MediaTab.qml`'s circular album-art crop
            // (a rounded square here instead of a circle) — not a plain
            // `fillMode: PreserveAspectFit` render as before. `notifImage`
            // itself is now the invisible pixel source the mask reads from,
            // never painted directly (see MediaTab.qml's own note on why
            // painting it too would double-draw an unmasked square under
            // the masked one). Tiers 2-4 (app icon, desktop-entry icon,
            // generic glyph) are unchanged in size/position/order — this
            // is a presentation layer over the same resolve chain, not a
            // new fallback rule.
            Image {
                id: notifImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                source: card.image.length > 0 ? card.image : ""
                visible: false
            }
            Rectangle {
                id: notifImageMaskShape
                anchors.fill: parent
                radius: Design.spacingSm
                visible: false
                // Load-bearing — see MediaTab.qml's own header note: an
                // invisible item with no `layer.enabled` produces no paint
                // node, which `MultiEffect.maskSource` reads as an EMPTY
                // mask rather than a full one.
                layer.enabled: true
            }
            MultiEffect {
                id: notifImageMasked
                anchors.fill: parent
                source: notifImage
                maskEnabled: true
                maskSource: notifImageMaskShape
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                // A genuine tier-1 load failure falls through to the
                // app-icon tier below rather than masking a broken source
                // — the same guard this slot already used before this
                // round, just moved from `notifImage.visible` itself to
                // this masked-output visibility.
                visible: card.image.length > 0 && notifImage.status === Image.Ready
            }
            Image {
                id: appIconImage
                anchors.fill: parent
                visible: !notifImageMasked.visible && iconSlot._appIconResolved.length > 0 && status !== Image.Error
                source: (!notifImageMasked.visible && iconSlot._appIconResolved.length > 0) ? iconSlot._appIconResolved : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            Image {
                id: desktopIconImage
                anchors.fill: parent
                visible: !notifImageMasked.visible && !appIconImage.visible && iconSlot._desktopIconResolved.length > 0 && status !== Image.Error
                source: (!notifImageMasked.visible && !appIconImage.visible && iconSlot._desktopIconResolved.length > 0) ? iconSlot._desktopIconResolved : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            // ── App-icon badge — Caelestia's own "small app icon
            //    overlapping the picture's corner" treatment, identical
            //    to NotifGroup.qml's row-level badge. Shown ONLY when the
            //    picture (not the app icon itself) occupies the primary
            //    slot, so the badge never doubles the app icon over
            //    itself. ─────────────────────────────────────────────────
            Rectangle {
                id: iconBadgeFrame
                readonly property string _badgeSrc: iconSlot._appIconResolved.length > 0 ? iconSlot._appIconResolved : iconSlot._desktopIconResolved
                visible: notifImageMasked.visible && _badgeSrc.length > 0 && iconBadgeImage.status !== Image.Error
                width: Design.notifBadgeSize
                height: Design.notifBadgeSize
                radius: width / 2
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: card._fill

                Image {
                    id: iconBadgeImage
                    anchors.fill: parent
                    anchors.margins: Design.spacingXs / 2
                    source: iconBadgeFrame._badgeSrc
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
            }
            // GATE-02 gap-closure fix (round 4, item 1) — the ONLY urgency-
            // dependent difference anywhere on this card now lives here:
            // the fallback glyph (shown only when none of the three real
            // tiers above resolved) is a danger/warning icon for critical
            // urgency instead of the generic bell, tinted BarRoles.danger
            // so it still reads as an urgency marker without touching the
            // card's own chrome. A real app-supplied icon/image for a
            // critical notification is left exactly as sent — this only
            // replaces what would otherwise be a blank "notifications"
            // bell, per the user's own "swap exactly there" instruction.
            Text {
                anchors.centerIn: parent
                visible: !notifImageMasked.visible && !appIconImage.visible && !desktopIconImage.visible
                text: card._critical ? "error" : "notifications"
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                textFormat: Text.PlainText
                color: card._critical ? BarRoles.danger : card._fg
            }

            // ── Ring progress (D-19-09) — a `hints.value` notification
            //    draws a PathAngleArc ring over the icon slot. Track
            //    `BarRoles.capsuleTrack`, fill `BarRoles.accent`, stroke
            //    `notifRingStrokeWidth` — the exact Dial.qml mechanism
            //    ("Don't Hand-Roll": native Shape geometry, never a raster
            //    Canvas redrawn every frame), sized down to this card's
            //    icon slot instead of a dashboard dial's diameter.
            //    Sender-supplied and CLAMPED into 0..100 on the same
            //    binding chain as the sweep computation, before any
            //    geometry is computed — an unclamped huge number from an
            //    arbitrary session process is a resource-exhaustion path,
            //    not just a rendering artefact (T-19-12). ───────────────
            readonly property var _hints: card.notifData && card.notifData.notification ? card.notifData.notification.hints : ({})
            readonly property bool _hasProgress: iconSlot._hints && iconSlot._hints.value !== undefined && iconSlot._hints.value !== null
            readonly property real _rawProgress: iconSlot._hasProgress ? Number(iconSlot._hints.value) : 0
            readonly property real _clampedProgress: Math.max(0, Math.min(100, isNaN(iconSlot._rawProgress) ? 0 : iconSlot._rawProgress))

            Shape {
                id: ringShape
                anchors.fill: parent
                visible: iconSlot._hasProgress
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: Design.notifRingStrokeWidth
                    strokeColor: BarRoles.capsuleTrack
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: ringShape.width / 2
                        centerY: ringShape.height / 2
                        radiusX: (Design.notifImageSize - Design.notifRingStrokeWidth) / 2
                        radiusY: (Design.notifImageSize - Design.notifRingStrokeWidth) / 2
                        startAngle: 0
                        sweepAngle: 360
                        moveToStart: true
                    }
                }
                ShapePath {
                    strokeWidth: Design.notifRingStrokeWidth
                    strokeColor: BarRoles.accent
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: ringShape.width / 2
                        centerY: ringShape.height / 2
                        radiusX: (Design.notifImageSize - Design.notifRingStrokeWidth) / 2
                        radiusY: (Design.notifImageSize - Design.notifRingStrokeWidth) / 2
                        startAngle: -90
                        sweepAngle: 360 * (iconSlot._clampedProgress / 100)
                        moveToStart: true
                    }
                }
            }
        }

        Column {
            id: contentColumn
            anchors.left: iconSlot.right
            anchors.leftMargin: Design.spacingMd
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: Design.spacingXs

            Text {
                id: summaryText
                width: parent.width
                text: card.summary
                // T-19-01 — pinned plain text, sender-controlled string.
                // Titles never carry markdown in this design.
                textFormat: Text.PlainText
                elide: Text.ElideRight
                // GATE-02 gap-closure (round 7, item 2). Compact stays at
                // one elided line exactly as 19-UI-SPEC.md's N1/long-text
                // rule requires ("Summary elides right at one line
                // (compact)") — the spec deliberately says nothing about
                // the EXPANDED state, and a long title chopped mid-word
                // while the card is deliberately opened to show more is
                // the same "long content looks weird" complaint the body
                // clamp below answers. Two lines expanded, still elided
                // past that so a pathological title cannot grow the card.
                wrapMode: card.expanded ? Text.Wrap : Text.NoWrap
                maximumLineCount: card.expanded ? 2 : 1
                font.pixelSize: Design.fontHeading
                font.weight: Design.weightEmphasis
                color: card._fg
            }
            Text {
                id: bodyText
                width: parent.width
                visible: card.body.length > 0
                // T-19-10 — the allowlist filter runs BEFORE MarkdownText
                // ever sees the sender's string; only bold/italic/link
                // constructs the filter re-permitted can render as
                // anything other than literal escaped text.
                text: NotifMarkdown.filter(card.body)
                textFormat: Text.MarkdownText
                wrapMode: card.expanded ? Text.Wrap : Text.NoWrap
                // GATE-02 gap-closure (round 7, item 2 — "notifications
                // with long content look weird inside the card"). The
                // expanded state was `elide: ElideNone` +
                // `maximumLineCount: 0`, i.e. no bound of any kind: the
                // card's own `implicitHeight` is driven by this column, so
                // a long-bodied notification grew the card without limit
                // and could exceed the screen. Now bounded by
                // `Design.notifBodyMaxLines` with a trailing ellipsis (see
                // that token's own note for why a line clamp rather than
                // the spec's nested Flickable — gesture contention with
                // this card's two drag axes).
                elide: Text.ElideRight
                maximumLineCount: card.expanded ? Design.notifBodyMaxLines : 1
                font.pixelSize: Design.fontBody
                color: card._fg
                linkColor: BarRoles.accent

                onLinkActivated: link => {
                    card._pendingLinkUrl = link;
                    card._linkConfirmVisible = true;
                }
                // Drives the dwell timer directly off the signal's own
                // value rather than a separate onChanged handler on
                // `_hoveredLinkUrl` — `linkHovered` already carries an
                // empty string the moment the pointer leaves a link, so
                // there is exactly one place this state transitions.
                onLinkHovered: link => {
                    card._hoveredLinkUrl = link;
                    if (link.length > 0) {
                        linkDwellTimer.restart();
                    } else {
                        linkDwellTimer.stop();
                        card._linkDwellElapsed = false;
                    }
                }
            }

            // ── D-19-40's link-open confirmation — "Open link?" plus a
            //    confirm/cancel pair in the existing capsule pill
            //    language, anchored under the body text carrying the
            //    link. Clicking a link never opens it immediately (T-19-11
            //    — any process on the session bus can send a notification,
            //    so an unconfirmed click is a one-click launcher for a
            //    sender-chosen URL). ─────────────────────────────────────
            Rectangle {
                id: linkConfirmPill
                visible: card._linkConfirmVisible
                width: parent.width
                radius: Design.barCapsuleRadius
                color: BarRoles.capsule
                implicitHeight: confirmRow.implicitHeight + Design.spacingXs * 2

                Row {
                    id: confirmRow
                    anchors.centerIn: parent
                    spacing: Design.spacingSm

                    Text {
                        text: qsTr("Open link?")
                        textFormat: Text.PlainText
                        font.pixelSize: Design.fontLabel
                        color: BarRoles.capsuleFg
                    }
                    Text {
                        text: qsTr("Yes")
                        textFormat: Text.PlainText
                        font.pixelSize: Design.fontLabel
                        font.weight: Design.weightEmphasis
                        color: BarRoles.accent

                        TapHandler {
                            onTapped: {
                                Qt.openUrlExternally(card._pendingLinkUrl);
                                card._linkConfirmVisible = false;
                            }
                        }
                    }
                    Text {
                        text: qsTr("Cancel")
                        textFormat: Text.PlainText
                        font.pixelSize: Design.fontLabel
                        color: BarRoles.capsuleFg

                        TapHandler {
                            onTapped: card._linkConfirmVisible = false;
                        }
                    }
                }
            }

            // ── D-19-05 expanded state — action buttons + the always-
            //    appended "copy body" action. Never shown compact. ───────
            Row {
                id: actionsRow
                visible: card.expanded && (card._liveActions.length > 0 || card.body.length > 0)
                width: parent.width
                spacing: Design.spacingSm

                Repeater {
                    model: card._liveActions

                    Rectangle {
                        id: actionChip
                        required property var modelData
                        radius: Design.barCapsuleRadius
                        color: BarRoles.capsule
                        implicitWidth: actionLabel.implicitWidth + Design.spacingSm * 2
                        implicitHeight: actionLabel.implicitHeight + Design.spacingXs * 2

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: actionChip.modelData.text
                            textFormat: Text.PlainText
                            font.pixelSize: Design.fontLabel
                            color: BarRoles.capsuleFg
                        }
                        TapHandler {
                            onTapped: actionChip.modelData.invoke()
                        }
                    }
                }

                Rectangle {
                    id: copyBodyChip
                    visible: card.body.length > 0
                    radius: Design.barCapsuleRadius
                    color: BarRoles.capsule
                    implicitWidth: copyLabel.implicitWidth + Design.spacingSm * 2
                    implicitHeight: copyLabel.implicitHeight + Design.spacingXs * 2

                    Text {
                        id: copyLabel
                        anchors.centerIn: parent
                        text: qsTr("Copy")
                        textFormat: Text.PlainText
                        font.pixelSize: Design.fontLabel
                        color: BarRoles.capsuleFg
                    }
                    TapHandler {
                        onTapped: copyBodyProcess.running = true
                    }
                }
            }
        }
    }

    Process {
        id: copyBodyProcess
        running: false
        command: ["wl-copy", card.body]
    }

    // ── D-19-04/D-19-06/D-19-08 dismiss timer state machine ──────────────
    // `_critical` (never starts, no exemption from the height clamp
    // elsewhere) excludes itself from `_fullDismissMs` here — the single
    // place the timer's own running condition is derived.
    readonly property int _fullDismissMs: card._critical ? -1 : (card._low ? 3000 : 5000)
    property int _remainingMs: card._fullDismissMs
    property real _resumeEpoch: 0

    Timer {
        id: dismissTimer
        interval: card._remainingMs > 0 ? card._remainingMs : 1
        running: false
        repeat: false
        onTriggered: {
            // GATE-02 gap-closure fix, structural guarantee — this is the
            // ONLY place a timer ever dismisses a card, so it is also the
            // right place to make "critical never auto-dismisses" true by
            // construction rather than by trusting every scheduling path
            // upstream got a genuine, measured urgency-population race
            // right. A stale/mis-scheduled timer firing on a card that is
            // (at THIS instant) critical is refused rather than acted on.
            if (card._critical)
                return;
            NotifServer.dismiss(card.notifId);
        }
    }

    // ── GATE-02 gap-closure fix — the `!card.notifData` guard below ────────
    // ROOT CAUSE: `notifData` is forwarded onto this card asynchronously by
    // NotifPopupStack.qml's own `Loader.onLoaded` + `Qt.binding()` idiom
    // (19-04-SUMMARY.md's own recorded fix for a DIFFERENT symptom in that
    // same scope-boundary). `Component.onCompleted` below can therefore fire
    // BEFORE `notifData` — and so `urgency`/`_critical`/`_fullDismissMs` —
    // is actually populated. Without this guard, `_startDismissTimer()` ran
    // at that moment against the fallback urgency (Normal), started a real
    // 5000ms `dismissTimer`, and nothing ever corrected it afterward: a
    // readonly property becoming reactively correct later does not retarget
    // an already-running Timer, and no reset hook existed for "notifData
    // just arrived". Empirically this dismissed EVERY critical-urgency card
    // at 5 seconds — confirmed live: NotifServer's own D-Bus arrival log
    // showed `urgency=2` (Critical) correctly received, so the defect was
    // entirely downstream of the server, in this race. Fixed by refusing to
    // start anything until `notifData` is real, and by adding the
    // `onNotifDataChanged` handler below so the FIRST genuine
    // urgency-aware decision is made once it actually arrives, whichever
    // order the two events land in. ─────────────────────────────────────
    // GATE-02 gap-closure fix, second half — measured live via a temporary
    // diagnostic (removed): `card.notifData.urgency` is genuinely read as
    // `Normal` on ONE early evaluation before settling to its real value
    // moments later (Quickshell's own C++ notification object populates
    // `urgency` a beat after the `notification` signal fires, ahead of its
    // own `urgencyChanged` correction) — a sub-race beneath the one this
    // function's `!card.notifData` guard already closes. The existing
    // `Connections.onUrgencyChanged -> _resetDismissTimer()` handler DOES
    // react to that later correction and DOES call back in here with the
    // now-correct `_critical=true` — but the ORIGINAL version of this
    // function only ever *refused to schedule* on that branch, never
    // *cancelled* whatever it may have already scheduled a moment earlier
    // under the stale reading. That left a real, already-ticking 5000ms
    // `dismissTimer` completely undisturbed, which is what dismissed every
    // critical-urgency card at 5 seconds regardless of how many times
    // urgency was later read correctly. Every early-return branch below
    // now explicitly stops the timer, so this function is idempotent
    // under repeated calls with a flip-flopping urgency reading, not just
    // correct on whichever call happens to be last.
    function _startDismissTimer() {
        if (!card.notifData) {
            dismissTimer.stop();
            return;
        }
        if (card._fullDismissMs <= 0) {
            dismissTimer.stop();
            return;
        }
        card._resumeEpoch = Date.now();
        dismissTimer.interval = card._remainingMs > 0 ? card._remainingMs : card._fullDismissMs;
        dismissTimer.restart();
    }
    function _pauseDismissTimer() {
        if (!dismissTimer.running)
            return;
        var elapsed = Date.now() - card._resumeEpoch;
        card._remainingMs = Math.max(1, card._remainingMs - elapsed);
        dismissTimer.stop();
    }
    function _resumeDismissTimer() {
        card._startDismissTimer();
    }
    function _resetDismissTimer() {
        card._remainingMs = card._fullDismissMs;
        card._startDismissTimer();
    }

    Component.onCompleted: card._startDismissTimer()

    // The other half of the gap-closure fix above: if `notifData` arrives
    // AFTER `Component.onCompleted` already ran (and therefore already
    // no-op'd against the `!card.notifData` guard), this is what actually
    // starts the timer — now with the real urgency in hand. `_resetDismissTimer()`
    // (not `_startDismissTimer()` directly) so `_remainingMs` is reset to
    // the freshly-correct `_fullDismissMs` first, exactly as every other
    // "the notification's own facts changed" path below already does.
    onNotifDataChanged: {
        if (card.notifData)
            card._resetDismissTimer();
    }

    // ── D-19-08's "restarts its dismiss timer" — fires on a genuine
    //    `replaces_id` re-send only (these fields never change on a
    //    notification that was not replaced). No animation-suppression
    //    branch exists here or anywhere else in this file — the no-
    //    reflow/no-reorder guarantee is structural (Pattern 2), this
    //    Connections block only owns the timer restart. ──────────────────
    Connections {
        target: card.notifData
        function onSummaryChanged() { card._resetDismissTimer(); }
        function onBodyChanged() { card._resetDismissTimer(); }
        function onUrgencyChanged() { card._resetDismissTimer(); }
        function onActionsChanged() { card._resetDismissTimer(); }
    }

    // ── D-19-40 link hover tooltip — reuses `BarTooltip.qml`'s exact
    //    chrome directly (imported from `../bar`, instantiated here, never
    //    a new registered type — the acceptance criterion this satisfies
    //    is "no new tooltip type is added to any qmldir"). `vertical:
    //    true` pins it to the right edge at the link's own vertical
    //    position, matching how every notification surface already sits
    //    near the right edge; `hostClearance` reuses BarTooltipHost's own
    //    float-vs-reserve discriminator so it clears this floating
    //    window's own width rather than landing under the card. ─────────
    property string _hoveredLinkUrl: ""
    property bool _linkConfirmVisible: false
    property string _pendingLinkUrl: ""
    property real _linkPublishedY: 0
    property bool _linkDwellElapsed: false

    readonly property real _hostClearance: {
        var win = QsWindow.window;
        if (!win || !win.margins)
            return 0;
        if (win.exclusiveZone && win.exclusiveZone > 0)
            return 0;
        return win.margins.right + win.width;
    }

    Timer {
        id: linkDwellTimer
        interval: Design.tooltipDelayMs
        repeat: false
        onTriggered: {
            var win = QsWindow.window;
            var originY = (win && win.margins) ? win.margins.top : 0;
            var scenePos = bodyText.mapToItem(null, 0, bodyText.height / 2);
            card._linkPublishedY = scenePos.y + originY;
            card._linkDwellElapsed = true;
        }
    }

    LazyLoader {
        active: card._linkDwellElapsed && card._hoveredLinkUrl.length > 0

        BarTooltip {
            text: card._hoveredLinkUrl
            vertical: true
            triggerCentre: card._linkPublishedY
            hostClearance: card._hostClearance
            tipId: "notif-link-" + card.notifId
        }
    }
}
