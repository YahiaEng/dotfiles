// modules/settings/Pages.qml — the content host: lazily incubates the
// current page and destroys the previous one, so only one page's bindings
// are ever live (RESEARCH.md pattern #2, Caelestia's Pages.qml).
//
// The swap is sequenced through a SequentialAnimation with a ScriptAction,
// NOT a bare onCurrentPageIdxChanged handler (MEMORY
// child-binding-lags-parent-signal + this plan's own Pitfall 7): inside
// onXChanged a child binding still sees the OLD value, and deferring the
// destroy/incubate past the fade-out sidesteps that entirely.
import QtQuick
import "../"

Item {
    id: root

    required property SettingsState sState
    property Item currentItem: null

    // Declared ABOVE every construction-time caller in this file (MEMORY
    // qml-declare-before-construction-time-use) — Component.onCompleted
    // below calls this.
    function _swapTo(idx) {
        if (idx < 0 || idx >= PageCompRegistry.comps.length) {
            console.warn("Pages: index out of range: " + idx);
            return;
        }
        if (root.currentItem) {
            root.currentItem.destroy();
            root.currentItem = null;
        }
        var comp = PageCompRegistry.comps[idx];
        var incubator = comp.incubateObject(root, { sState: root.sState }, Qt.Synchronous);
        if (incubator && incubator.object) {
            root.currentItem = incubator.object;
            root.currentItem.anchors.fill = root;
        } else {
            console.warn("Pages: failed to incubate page at index " + idx);
        }
    }

    // Operator live-pass item 3 (PARTIAL — "moving between them feels
    // laggy"): MEASURED, not assumed — a temporary timestamp diagnostic
    // showed destroy+incubate cost is trivial (0-13ms across several
    // switches) while the full swap consistently took 552-568ms
    // end-to-end, matching emphasizedOut(187ms)+emphasizedIn(375ms)
    // almost exactly. The lag IS the animation, not re-incubation.
    // `emphasizedIn`/`emphasizedOut` are this codebase's own convention
    // for a SURFACE's own open/close (e.g. NotifCentre.qml:116-120, the
    // whole centre appearing/disappearing) — `Motion.standardDuration`
    // is the established token for moving BETWEEN tabs/pages within an
    // already-open surface (NotifCentre.qml:924's own pager
    // `highlightMoveDuration`). This swap borrowed the wrong pair;
    // switched to the correctly-scoped one for both stages (250ms each,
    // 500ms total, down from 562ms, and semantically the right speed
    // class for a frequent in-window interaction rather than a rare
    // whole-surface transition).
    SequentialAnimation {
        id: swapAnim

        property int targetIdx: 0

        PropertyAnimation {
            target: root
            property: "opacity"
            to: 0
            duration: Motion.motionEnabled ? Motion.standardDuration : 0
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }
        ScriptAction {
            script: root._swapTo(swapAnim.targetIdx)
        }
        PropertyAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: Motion.motionEnabled ? Motion.standardDuration : 0
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }
    }

    function goTo(idx) {
        swapAnim.targetIdx = idx;
        swapAnim.restart();
    }

    Connections {
        target: root.sState
        function onCurrentPageIdxChanged() {
            root.goTo(root.sState.currentPageIdx);
        }
    }

    Component.onCompleted: root._swapTo(root.sState.currentPageIdx)
}
