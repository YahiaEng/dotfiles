// modules/settings/common/StackPage.qml — the sub-page host a root page
// wraps itself in when it has drill-in children (quick task 260825-wj2
// Task 1, D-2). Ported from Caelestia's `common/StackPage.qml`: a
// `StackView` holding `pages[0]` as the root and `pages[1..N]` as
// sub-pages, with `openSubPage(idx)` pushing and `SettingsState`'s
// `subPageOpened`/`subPageClosed` signals kept in step via a `Connections`
// block — the exact shape the vendored reference uses, values not
// "improved" (this project's standing rule: Caelestia's convention wins).
//
// `comps[i]` only becomes a StackPage for a page that actually HAS
// sub-pages (D-2) — the other twelve root pages stay bare page Components,
// so `compSlugs` stays exactly 1:1 with registered pages and
// settings-index-check's CHECK C/D/E need no change at all.
//
// `flickable` is proxied from `currentItem` (D-3) so
// `Pages.qml:_scrollRowIntoView`'s `root.currentItem.flickable` keeps
// working unchanged for both a bare PageBase and a StackPage-wrapped one —
// PageBase itself exposes `flickable` as an alias, and this mirrors that
// exact contract one level up.
import QtQuick
import QtQuick.Controls
import "../../"
import "../../dashboard"

StackView {
    id: root

    required property SettingsState sState
    default property list<Component> pages

    // D-3 — proxy through to whichever sub-page is on top, so
    // `Pages._scrollRowIntoView` keeps working with zero edits.
    readonly property var flickable: root.currentItem ? root.currentItem.flickable : null

    // Slide distance for the push/pop transitions below — the same token
    // `Pages.qml`'s own `_swapShiftDistance` reads, so a sub-page push
    // moves the same visual distance a whole-page swap does.
    readonly property int _slideDistance: Design.panelPadding

    clip: true

    // Never a silent return on an invalid index (this repo's standing
    // rule, restated in this task's own action block) — warn by name and
    // fall back to closing the sub-page rather than pushing `undefined`.
    function openSubPage(idx, immediate) {
        var page = root.pages[idx];
        if (page) {
            root.push(page, {
                sState: root.sState
            }, immediate ? StackView.Immediate : StackView.PushTransition);
        } else {
            console.warn("StackPage: attempted to open invalid sub-page index " + idx);
            root.sState.closeSubPage();
        }
    }

    Component.onCompleted: {
        root.openSubPage(0, true);
        for (var i = 0; i < root.sState.subPageIdxStack.length; i++)
            root.openSubPage(root.sState.subPageIdxStack[i], true);
    }

    pushEnter: Transition {
        ParallelAnimation {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Motion.motionEnabled ? Motion.standardDuration : 0
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
            PropertyAnimation {
                property: "x"
                from: Motion.motionEnabled ? root._slideDistance : 0
                to: 0
                duration: Motion.motionEnabled ? Motion.standardDuration : 0
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

    pushExit: Transition {
        PropertyAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: Motion.motionEnabled ? Motion.standardDuration : 0
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }
    }

    popEnter: Transition {
        ParallelAnimation {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Motion.motionEnabled ? Motion.standardDuration : 0
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
            PropertyAnimation {
                property: "x"
                from: Motion.motionEnabled ? -root._slideDistance : 0
                to: 0
                duration: Motion.motionEnabled ? Motion.standardDuration : 0
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

    popExit: Transition {
        PropertyAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: Motion.motionEnabled ? Motion.standardDuration : 0
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }
    }

    Connections {
        target: root.sState

        function onSubPageOpened(idx) {
            root.openSubPage(idx, false);
        }

        function onSubPageClosed() {
            if (root.depth < root.sState.subPageIdxStack.length) {
                console.log("StackPage: attempted to close page while depth < stack depth. Ignoring.");
                return;
            }
            root.pop();
        }
    }
}
