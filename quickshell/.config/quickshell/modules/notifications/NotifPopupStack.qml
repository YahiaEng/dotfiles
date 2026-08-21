// NotifPopupStack.qml — the top-right popup stack, the end-to-end proof
// (Phase 19 Plan 01 tracer, QNOTIF-01/02, D-19-01/13).
//
// ── Layer posture and margin derivation (D-19-01) ────────────────────────
// Anchors `top: true, right: true` — the SAME two edges `Bar.qml` itself
// always anchors, in BOTH orientations (`Bar.qml:72-77`: horizontal
// reserves the TOP edge via `exclusiveZone: barHeight` +
// `margins.top: barEdgeMargin`; vertical reserves the RIGHT edge via
// `exclusiveZone: barColumnWidth` + `margins.right: barEdgeMargin`).
//
// `SectionPopout.qml`'s own F5 finding (its header comment, live-measured
// 2026-08-12) establishes the mechanism this file reuses rather than
// re-derives: an anchored layer surface is auto-pushed past ANOTHER
// surface's exclusive-zone reservation on a shared edge by the compositor
// itself — regardless of this surface's own (zero) `exclusiveZone` — and
// adding that reservation again in a margin expression DOUBLE-COUNTS it
// (SectionPopout's own bug, corrected the same day: `y=100` against a
// bar whose bottom edge was 48, from a margin that added the 48 back on
// top of what the compositor had already applied).
//
// Because this surface anchors to BOTH of the edges Bar.qml ever
// reserves, the compositor auto-clears whichever ONE the bar currently
// occupies (top when horizontal, right when vertical) without any
// runtime branch on `Bar`'s own `vertical`/`reservedZoneExtent`
// properties — D-19-01's "only the margin shifts to clear the bar's live
// reserved edge" is therefore satisfied by the compositor's own
// accounting, not by re-deriving Bar's exclusiveZone here. `barSideMargin`
// is the constant GAP past whatever edge the compositor already found —
// the same corrected value SectionPopout's own `_horizontalTopMargin`/
// `_verticalRightMargin` use for the identical reason.
//
// ── QNOTIF-02 — stack and reflow ──────────────────────────────────────────
// A `ListView` bound to a CLAMPED view of `NotifServer.popups` with
// `add`/`move`/`displaced`/`remove` transitions so cards enter and reflow
// on animation rather than snapping. New arrivals prepend (NotifServer.qml's
// own `onNotification` handler), so the ListView's default top-to-bottom
// layout renders the newest card at the top of the stack.
//
// ── D-19-03 depth clamp + "+N more" summary card (Phase 19 Plan 04) ──────
// `NotifServer.popups` itself is NEVER truncated — every notification stays
// real data. Only the DISPLAYED slice is bounded: `_displayModel` below is
// the first `visibleCount` wrappers, plus one plain-JS-object overflow
// marker appended when the remainder is non-empty. `overflowCard`'s own
// delegate renders that marker with the SAME `notifSurface` chrome as a
// real card (centred text, `GradientBorder` rim) and opens the centre via
// the identical `NotifServer.openCentre()` verb the bar bell uses — one way
// to open the centre, never two.
//
// The clamp is deliberately NOT "however many happen to fit the full
// screen height" — on this host's 1080px display that would allow roughly
// thirteen compact cards before ever summarizing, which would make even a
// pathological burst of notifications look like normal behaviour. Popups
// are capped to the top two-thirds of the screen height instead (Claude's
// Discretion, matching the everyday-notification-stack convention neither
// reference shell's own source pins to an exact fraction) — the stack must
// never claim the WHOLE screen, leaving room below for whatever else is on
// screen and giving a bounded, checkable trigger point for D-19-03's own
// acceptance criterion.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"
import "../dashboard"
import "../bar"

PanelWindow {
    id: popupStack

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notif-popups"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false
    color: "transparent"

    // A stack of independently-floating cards reserves nothing —
    // matches PanelDialog/SectionPopout's own `exclusiveZone: 0`.
    exclusiveZone: 0
    // Ignore, matching SectionPopout.qml's own choice and reasoning
    // (this file's header comment above) — inert either way since this
    // surface's own exclusiveZone is 0, kept for family consistency.
    exclusionMode: ExclusionMode.Ignore

    // ── Position (quick-260821-6z1 Task 9, D-01 bundle 2/D-02) — a
    //    four-corner Prefs.notifs.position value, default "top-right"
    //    (byte-identical to the prior hardcoded anchors). Whichever
    //    corner is chosen, the anchor pair is simply that corner's own
    //    two edges — this PRESERVES the file's own established mechanism
    //    (this header's own text above) without a special case: any
    //    corner that shares an edge with what the bar can ever reserve
    //    (top when horizontal, right when vertical) still anchors that
    //    shared edge as one of its own two, so the compositor's own
    //    auto-push-past-exclusive-zone behaviour keeps applying exactly
    //    as before; a corner sharing neither (bottom-left) never collides
    //    with the bar in the first place. `exclusiveZone: 0` above is
    //    unchanged — no margin here re-adds a zone the compositor already
    //    applied for either edge.
    readonly property string _position: Prefs.getValue("notifs.position")
    readonly property var _positionParts: popupStack._position.split("-")
    readonly property bool _anchorTop: popupStack._positionParts[0] !== "bottom"
    readonly property bool _anchorLeft: popupStack._positionParts[1] === "left"

    anchors {
        top: popupStack._anchorTop
        bottom: !popupStack._anchorTop
        left: popupStack._anchorLeft
        right: !popupStack._anchorLeft
    }

    margins.top: popupStack._anchorTop ? Design.barSideMargin : 0
    margins.bottom: !popupStack._anchorTop ? Design.barSideMargin : 0
    margins.left: popupStack._anchorLeft ? Design.barSideMargin : 0
    margins.right: !popupStack._anchorLeft ? Design.barSideMargin : 0

    implicitWidth: Design.notifSurfaceWidth
    implicitHeight: Math.max(0, notifListView.contentHeight)

    // ── D-19-03 depth clamp math ──────────────────────────────────────────
    readonly property real _availableHeight: (popupStack.screen ? popupStack.screen.height : 1080) * 2 / 3
    // Compact-card height estimate (icon slot + top/bottom padding) plus
    // the ListView's own inter-card spacing — the same shape a real
    // compact NotifCard resolves to via its own `implicitHeight` formula.
    readonly property real _perCardHeight: Design.notifImageSize + Design.spacingMd * 2 + Design.spacingSm
    // GATE-02 gap-closure (round 7, item 3 — "reduce the max limit of popup
    // notifications that can appear at a time"). Previously this was the
    // geometric fit alone: on this host's monitor that resolves to roughly
    // a dozen simultaneous cards before the "+N more" summary ever appears,
    // which is a wall of popups, not a stack. The geometric bound stays as
    // the hard ceiling (a short monitor must still never overflow its own
    // 2/3-height budget), and `Design.notifMaxVisiblePopups` is layered on
    // top as the DESIGN bound — whichever is smaller wins. The "+N more"
    // overflow card and every count below are unchanged and pick this up
    // automatically, so nothing is dropped or hidden: the surplus is
    // summarised exactly as it already was when the screen ran out of room.
    readonly property int _rawMaxVisible: Math.min(Design.notifMaxVisiblePopups, Math.max(1, Math.floor(popupStack._availableHeight / popupStack._perCardHeight)))
    readonly property int _totalCount: NotifServer.popups.length
    readonly property bool _needsClamp: popupStack._totalCount > popupStack._rawMaxVisible
    // One slot is reserved for the "+N more" card itself when clamped.
    readonly property int visibleCount: popupStack._needsClamp ? Math.max(1, popupStack._rawMaxVisible - 1) : popupStack._totalCount
    readonly property int overflowCount: popupStack._needsClamp ? (popupStack._totalCount - popupStack.visibleCount) : 0

    readonly property var _displayModel: {
        var visible = NotifServer.popups.slice(0, popupStack.visibleCount);
        if (popupStack.overflowCount > 0)
            return visible.concat([{
                isOverflow: true,
                overflowCount: popupStack.overflowCount
            }]);
        return visible;
    }

    ListView {
        id: notifListView
        anchors.fill: parent
        interactive: false
        spacing: Design.spacingSm
        model: popupStack._displayModel
        // Task 9: for a bottom-anchored position, the newest card (index
        // 0 — NotifServer.qml's own onNotification handler prepends)
        // renders nearest the anchored edge, matching the existing
        // top-anchored default's own "newest at the top" reading.
        verticalLayoutDirection: popupStack._anchorTop ? ListView.TopToBottom : ListView.BottomToTop

        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
        displaced: Transition {
            NumberAnimation {
                properties: "y"
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
        remove: Transition {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: Motion.emphasizedOutDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasizedOutEasing
            }
        }

        // Switches between a real card and the "+N more" summary card per
        // element — `modelData.isOverflow` is `undefined` (falsy) on every
        // real NotifData wrapper, since NotifData declares no such
        // property, so the discriminator is safe without a type tag.
        //
        // ── Rule 1 bug fix (found live, this plan) ────────────────────────
        // A `Component { ... }` block is its own ID scope in QML — ids from
        // the surrounding document (here, this `Loader`'s own `cardLoader`
        // id) are NOT visible inside it. The original version of
        // `realCardComponent`/`overflowCardComponent` below referenced
        // `cardLoader.modelData` directly from inside those Components,
        // which compiled cleanly (id resolution is late-bound in QML) but
        // threw `ReferenceError: cardLoader is not defined` on every single
        // delegate instantiation at runtime — confirmed live in
        // ~/.cache/quickshell.log, one line per popup card ever rendered.
        // The fix forwards data across that scope boundary explicitly via
        // `Loader.onLoaded` + `Qt.binding()`, which keeps the forwarded
        // property LIVE (not a one-shot snapshot) exactly like a normal
        // declarative `prop: expression` binding would, the standard QML
        // idiom for passing data into a dynamically-selected `sourceComponent`.
        delegate: Loader {
            id: cardLoader
            required property var modelData
            readonly property bool _isOverflow: cardLoader.modelData && cardLoader.modelData.isOverflow === true
            sourceComponent: cardLoader._isOverflow ? overflowCardComponent : realCardComponent
            onLoaded: {
                if (cardLoader._isOverflow) {
                    cardLoader.item.overflowCount = Qt.binding(function () {
                        return cardLoader.modelData.overflowCount;
                    });
                } else {
                    cardLoader.item.notifData = Qt.binding(function () {
                        return cardLoader.modelData;
                    });
                }
            }
        }
    }

    Component {
        id: realCardComponent
        NotifCard {}
    }

    Component {
        id: overflowCardComponent
        Rectangle {
            id: overflowCardRoot
            property int overflowCount: 0

            width: Design.notifSurfaceWidth
            implicitHeight: Design.notifImageSize + Design.spacingMd * 2
            height: implicitHeight
            radius: Design.popoutCornerRadius
            color: BarRoles.notifSurface

            GradientBorder {
                anchors.fill: parent
                borderWidth: Design.notifRingStrokeWidth
                topLeftRadius: Design.popoutCornerRadius
                topRightRadius: Design.popoutCornerRadius
                bottomLeftRadius: Design.popoutCornerRadius
                bottomRightRadius: Design.popoutCornerRadius
            }

            Text {
                anchors.centerIn: parent
                text: qsTr("+%1 more").arg(overflowCardRoot.overflowCount)
                textFormat: Text.PlainText
                font.pixelSize: Design.fontHeading
                font.weight: Design.weightEmphasis
                color: BarRoles.notifSurfaceFg
            }

            TapHandler {
                onTapped: NotifServer.openCentre()
            }
        }
    }
}
