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
// swaync-matching windows are not the sender's `expireTimeout`, so there
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

    readonly property color _fill: card._critical ? BarRoles.danger : BarRoles.notifSurface
    readonly property color _fg: card._critical ? BarRoles.onDanger : BarRoles.notifSurfaceFg

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

            // Resolved (not merely "set") icon names for tiers 2/3 — each
            // is only non-empty once the icon theme actually has it, so
            // the cascade below never shows a tier whose Image would just
            // render nothing.
            readonly property string _appIconResolved: card.appIcon.length > 0 ? Quickshell.iconPath(card.appIcon, "") : ""
            readonly property string _desktopEntryIconName: {
                var de = card.notifData && card.notifData.notification ? card.notifData.notification.desktopEntry : "";
                if (!de || de.length === 0)
                    return "";
                var entry = DesktopEntries.byId(de);
                return entry ? entry.icon : "";
            }
            readonly property string _desktopIconResolved: iconSlot._desktopEntryIconName.length > 0 ? Quickshell.iconPath(iconSlot._desktopEntryIconName, "") : ""

            Image {
                id: notifImage
                anchors.fill: parent
                visible: card.image.length > 0
                source: card.image.length > 0 ? card.image : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            Image {
                id: appIconImage
                anchors.fill: parent
                visible: !notifImage.visible && iconSlot._appIconResolved.length > 0
                source: appIconImage.visible ? iconSlot._appIconResolved : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            Image {
                id: desktopIconImage
                anchors.fill: parent
                visible: !notifImage.visible && !appIconImage.visible && iconSlot._desktopIconResolved.length > 0
                source: desktopIconImage.visible ? iconSlot._desktopIconResolved : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            Text {
                anchors.centerIn: parent
                visible: !notifImage.visible && !appIconImage.visible && !desktopIconImage.visible
                text: "notifications"
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                textFormat: Text.PlainText
                color: card._fg
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
                maximumLineCount: 1
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
                elide: card.expanded ? Text.ElideNone : Text.ElideRight
                maximumLineCount: card.expanded ? 0 : 1
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
