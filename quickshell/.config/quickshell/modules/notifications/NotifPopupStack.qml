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
// A `ListView` bound to `NotifServer.popups` with `add`/`move`/`displaced`/
// `remove` transitions so cards enter and reflow on animation rather than
// snapping. New arrivals prepend (NotifServer.qml's own `onNotification`
// handler), so the ListView's default top-to-bottom layout renders the
// newest card at the top of the stack. Depth clamping and the "+N more"
// summary card (D-19-03) are wave-2 scope, not this tracer's.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"
import "../dashboard"

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

    anchors {
        top: true
        right: true
    }

    margins.top: Design.barSideMargin
    margins.right: Design.barSideMargin

    implicitWidth: Design.notifSurfaceWidth
    implicitHeight: Math.max(0, notifListView.contentHeight)

    ListView {
        id: notifListView
        anchors.fill: parent
        interactive: false
        spacing: Design.spacingSm
        model: NotifServer.popups

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

        delegate: NotifCard {
            notifData: modelData
        }
    }
}
