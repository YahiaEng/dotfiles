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

    // ── Two-pane keyboard focus (operator spec correction, second
    //    live-pass): "left/right arrows move between the left side and
    //    right side of the options menu" — Right moves focus from the
    //    rail INTO the content pane's first row; Left returns it to the
    //    rail; Up/Down walk rows within whichever pane holds focus. This
    //    shell has no real QML focus-chain for the rail either (NavRail's
    //    selection is virtual — index-driven, not `activeFocus`), so the
    //    content pane follows the SAME virtual-selection idiom rather
    //    than introducing a second, competing focus model: `contentFocused`
    //    + `contentRowIdx` are plain properties, and each row's own
    //    `rowFocused` visual is written directly here, not bound through
    //    a page-supplied index (a page has no numbering of its own rows —
    //    SettingsSection/Repeater nesting varies per page).
    property var _focusableRows: []
    property bool contentFocused: false
    property int contentRowIdx: -1

    // Recursive tree walk, not a fixed SettingsSection/Repeater path —
    // page shapes vary (DisplayInputPage repeats a whole SettingsSection
    // per monitor; other pages declare them directly), so this walks
    // ANY descendant chain looking for the `focusable` marker every row
    // type (ToggleRow/SliderRow/SelectRow/NavRow) now declares, in
    // strict child-declaration order (QML's `children` array preserves
    // it) — the same order the rows actually render in, top to bottom.
    function _collectFocusableRows(item) {
        var result = [];
        if (!item || !item.children)
            return result;
        for (var i = 0; i < item.children.length; i++) {
            var child = item.children[i];
            if (child.focusable === true)
                result.push(child);
            else
                result = result.concat(root._collectFocusableRows(child));
        }
        return result;
    }

    function _applyRowFocusVisual() {
        for (var i = 0; i < root._focusableRows.length; i++)
            root._focusableRows[i].rowFocused = root.contentFocused && i === root.contentRowIdx;
    }

    // Scroll-into-view (Rule 2 follow-on, discovered verifying the
    // row-hover fix with grim+PIL: SliderRow's ring measured with
    // strong contrast, but only its extreme bottom-right corner sliver
    // fell inside the capture — the row itself was scrolled past the
    // Flickable's bottom edge. A `rowFocused` ring nobody can see is no
    // fix at all.) Maps the focused row's position into the page's own
    // Flickable content-item space (PageBase's `flickable` alias) and
    // nudges `contentY` only as far as needed to bring the row fully
    // into view — never re-centers, so a row already visible does not
    // cause an unnecessary jump.
    function _scrollRowIntoView() {
        if (!root.contentFocused || root.contentRowIdx < 0 || root.contentRowIdx >= root._focusableRows.length)
            return;
        if (!root.currentItem || !root.currentItem.flickable)
            return;
        var flick = root.currentItem.flickable;
        var row = root._focusableRows[root.contentRowIdx];
        var rowTop = row.mapToItem(flick.contentItem, 0, 0).y;
        var rowBottom = rowTop + row.height;
        if (rowTop < flick.contentY)
            flick.contentY = Math.max(0, rowTop);
        else if (rowBottom > flick.contentY + flick.height)
            flick.contentY = Math.min(Math.max(0, flick.contentHeight - flick.height), rowBottom - flick.height);
    }

    // Right: enters the content pane at its first row. No-op (stays on
    // the rail) if the current page has no focusable rows at all, rather
    // than focusing nothing visibly.
    function enterContent() {
        if (root._focusableRows.length === 0)
            return;
        root.contentFocused = true;
        root.contentRowIdx = Math.max(0, Math.min(root.contentRowIdx, root._focusableRows.length - 1));
        root._applyRowFocusVisual();
        root._scrollRowIntoView();
    }

    // Left: returns focus to the rail. `contentRowIdx` is deliberately
    // NOT reset to -1 here (only on a page swap, in `_swapTo` below) — a
    // Left then Right round-trip on the SAME page returns to the same
    // row, matching the rail's own "selection persists" behaviour.
    function exitContent() {
        root.contentFocused = false;
        root._applyRowFocusVisual();
    }

    function moveContentRow(delta) {
        if (!root.contentFocused || root._focusableRows.length === 0)
            return;
        root.contentRowIdx = Math.max(0, Math.min(root._focusableRows.length - 1, root.contentRowIdx + delta));
        root._applyRowFocusVisual();
        root._scrollRowIntoView();
    }

    // Declared ABOVE every construction-time caller in this file (MEMORY
    // qml-declare-before-construction-time-use) — Component.onCompleted
    // below calls this.
    function _swapTo(idx) {
        console.log("SQDDIAG t=" + Date.now() + " Pages._swapTo-start idx=" + idx);
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
        // A new page has an entirely different (possibly differently
        // shaped) row list — re-collect and reset pane focus to the
        // rail every swap, never carry a stale row index across pages.
        root._focusableRows = root._collectFocusableRows(root.currentItem);
        root.contentFocused = false;
        root.contentRowIdx = -1;
        console.log("SQDDIAG t=" + Date.now() + " Pages._swapTo-done idx=" + idx + " focusableRows=" + root._focusableRows.length);
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
    //
    // ── Re-check (operator, second live-pass) — "snappier now, could
    //    still be improved" ────────────────────────────────────────────
    // Re-measured fresh (temporary diagnostic, removed after use): stable
    // 493-502ms across 4 samples, unchanged from the prior fix. Checked
    // Motion.qml's ACTUAL vocabulary (not assumed) for anything faster
    // and still correctly scoped to a within-surface transition: the
    // only one-shot durations faster than `standardDuration` (250ms) are
    // `emphasizedOutDuration` (187ms, this codebase's own convention for
    // a SURFACE's own close — already ruled out above, the exact
    // wrong-scope mistake this fix corrected) and `staggerOffsetDuration`
    // (62ms, the DELAY GAP between staggered list items animating in
    // sequence, e.g. notification cards — not a transition duration for
    // a single swap; using it here would misapply a token the same way
    // this fix's own root cause did). The animation is already
    // opacity-only (no slide/transform to trim). Per the coordinator's
    // own explicit instruction, nothing in the vocabulary is faster
    // without hand-rolling a raw value or misusing a wrongly-scoped
    // token — left as-is rather than hardcode a duration motion-lint
    // would (correctly) reject anyway.
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

    // Diagnostic instrumentation (operator-ordered — see SelectRow.qml's
    // instrumentation-block header for full context). This is the ONE
    // path (via `Connections.onCurrentPageIdxChanged` below) both a
    // nav-rail click (`SettingsState.goToPage` -> `currentPageIdx = idx`)
    // AND an already-open-window IPC `openPage` deep-link
    // (`settingsLoader.item.sState.currentPageIdx = idx` in shell.qml)
    // funnel through — logging here, plus the `Component.onCompleted`
    // direct-swap path below (the ONLY genuinely different path: the
    // FIRST page shown whenever the window transitions closed->open,
    // regardless of entry mechanism), exposes whichever asymmetry is
    // actually real rather than assuming it from code reading alone.
    function goTo(idx) {
        console.log("SQDDIAG t=" + Date.now() + " Pages.goTo-called idx=" + idx + " (animated swapAnim path)");
        swapAnim.targetIdx = idx;
        swapAnim.restart();
    }

    Connections {
        target: root.sState
        function onCurrentPageIdxChanged() {
            console.log("SQDDIAG t=" + Date.now() + " SettingsState.currentPageIdx changed to " + root.sState.currentPageIdx + " -> Pages.goTo");
            root.goTo(root.sState.currentPageIdx);
        }
    }

    Component.onCompleted: {
        console.log("SQDDIAG t=" + Date.now() + " Pages.onCompleted initial-swap idx=" + root.sState.currentPageIdx + " (DIRECT _swapTo, no swapAnim — first page of a freshly (re)opened window)");
        root._swapTo(root.sState.currentPageIdx);
    }
}
