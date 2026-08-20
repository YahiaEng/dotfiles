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

    SequentialAnimation {
        id: swapAnim

        property int targetIdx: 0

        PropertyAnimation {
            target: root
            property: "opacity"
            to: 0
            duration: Motion.motionEnabled ? Motion.emphasizedOutDuration : 0
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.emphasizedOutEasing
        }
        ScriptAction {
            script: root._swapTo(swapAnim.targetIdx)
        }
        PropertyAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: Motion.motionEnabled ? Motion.emphasizedInDuration : 0
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.emphasizedInEasing
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
