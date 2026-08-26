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
// Design (the shared spacing/type constants) is registered in
// modules/dashboard/qmldir, not modules/qmldir — this import is what makes
// `Design.panelPadding` below resolve. qmllint does NOT catch a missing QML
// import; an unresolved singleton reads as `undefined` at runtime and only
// surfaces in ~/.cache/quickshell.log.
import "../dashboard"

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
            // Defect 3 fix (quick-260826-1n9, Task 3) — a StackPage is a
            // StackView, and QQC2 keeps every non-current element parented
            // to the StackView with `visible: false` rather than removed.
            // Without this guard the walk returned BOTH the hidden root
            // page's rows and the visible sub-page's rows on any page
            // with a sub-page pushed (Apps, Connected devices) — a search
            // jump could ring a row on the invisible page underneath, and
            // keyboard focus could land there too. Skipping (and not
            // recursing into) an invisible child fixes both, and also
            // silently fixes `visible: false` rows on flat pages.
            if (child.visible === false)
                continue;
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

    // ── Fix WR-02 (code review, quick-260821-6z1 fix wave) — the two-pane
    //    focus system above draws a ring on whichever row holds
    //    `contentRowIdx` but, until this fix, wired no way to actually DO
    //    anything to that row from the keyboard: no row type declared a
    //    `Keys.onReturnPressed`/`onSpacePressed` handler, and none of them
    //    ever receive real QML `activeFocus` (`rowFocused` is a plain
    //    externally-set property this file writes, not `Item.focus`).
    //    Settings.qml's `escCatcher` dispatches Enter/Space here.
    //
    //    Duck-types on each row TYPE's own distinguishing property/signal
    //    rather than a `type`/`kind` string this file would have to keep
    //    in step with five separate row files — a genuinely-declared QML
    //    property is either present (a real value) or `undefined` (never
    //    declared), so this reads reliably regardless of the row's
    //    current value:
    //      - ToggleRow — the only type with a `checked` property.
    //      - SelectRow — the only type with a `model` property.
    //      - NavRow — has neither `checked` nor `model`, but DOES expose
    //        an `activated()` signal.
    //    SliderRow and InfoRow are DELIBERATELY not handled here — see
    //    SUMMARY.md's "Deferred: SliderRow keyboard value adjustment"
    //    note. A single Enter/Space keypress has no natural "the one
    //    thing to do" semantics for a continuous-value slider the way it
    //    does for a boolean/enum/navigation row, and the reviewer's own
    //    suggested shape (Left/Right nudges the value once inside a row)
    //    would collide directly with THIS SAME escCatcher's existing
    //    Left/Right bindings (`exitContent()`/`enterContent()`, the
    //    two-pane rail<->content switch) — reusing those keys for a
    //    third, row-local meaning is a genuine interaction-model
    //    decision, not a contained per-row handler, so it is named as a
    //    follow-up rather than started here. InfoRow is intentionally
    //    non-interactive (PD-07) and has no action to take at all.
    //
    //    StepperRow (quick task 260825-wj2 Task 5) IS handled — checked
    //    FIRST, ahead of the three branches above: a genuinely-declared
    //    function is either present or `undefined`, no other row type
    //    declares `stepUp`, and putting the most specific marker first
    //    means the ordering cannot rot as row types are added. This
    //    differs from the SliderRow deferral right above for a real
    //    reason, not an inconsistency: that note rules out a single
    //    keypress for a CONTINUOUS value with no natural "the one thing
    //    to do" — a stepper is discrete and bounded, so "advance by one
    //    `stepSize`, clamped at `to`" is well defined. Left/Right are
    //    deliberately NOT reached for here either, for the identical
    //    collision this file already names for SliderRow.
    //
    //    TextRow (quick-260826-1n9, D-10) IS handled too — `beginEdit`
    //    checked alongside `stepUp`, ahead of the generic three, for the
    //    identical reason: a genuinely-declared function is either
    //    present or `undefined`, and no other row type declares
    //    `beginEdit`, so this ordering cannot rot as row types are added.
    function activateContentRow() {
        if (!root.contentFocused || root.contentRowIdx < 0 || root.contentRowIdx >= root._focusableRows.length)
            return;
        var row = root._focusableRows[root.contentRowIdx];
        if (typeof row.stepUp === "function") {
            row.stepUp();
        } else if (typeof row.beginEdit === "function") {
            row.beginEdit();
        } else if (row.checked !== undefined) {
            row.toggled(!row.checked);
        } else if (row.model !== undefined) {
            row.openMenu();
        } else if (typeof row.activated === "function") {
            row.activated();
        }
    }

    // _rowKey (quick-260826-437 D-1, Step 2) — the search-jump match key,
    // split off the displayed `label` so a repeater-backed row (e.g.
    // AllAppsPage's per-app title) can vary its label without breaking the
    // jump. Declared ABOVE `_recollectRows()` below (MEMORY
    // qml-declare-before-construction-time-use — `_recollectRows` is
    // reached from `Component.onCompleted` via `_swapTo`). Prefers
    // `indexLabel` when the row declares a non-empty one; falls back to
    // `label` otherwise — `_collectFocusableRows()` pushes anything
    // declaring `focusable === true`, a duck-type contract, not a base
    // class, so a future row type that forgets `indexLabel` degrades to
    // today's behaviour instead of matching `undefined`.
    function _rowKey(row) {
        return (row.indexLabel !== undefined && row.indexLabel.length > 0) ? row.indexLabel : row.label;
    }

    // Extracted from `_swapTo`'s own tail (quick task 260825-wj2 Task 1) so
    // it can ALSO run off a sub-page push/pop, not just a whole-page swap —
    // a StackView push changes the focusable-row set exactly the way a
    // page swap does, and search still needs to land on the right row
    // whichever kind of navigation got it there. Declared ABOVE `_swapTo`
    // below (MEMORY qml-declare-before-construction-time-use), which is
    // itself called from Component.onCompleted.
    function _recollectRows() {
        // A new page (or a newly-pushed sub-page) has an entirely
        // different (possibly differently shaped) row list — re-collect
        // and reset pane focus to the rail every time, never carry a
        // stale row index across pages/sub-pages.
        root._focusableRows = root._collectFocusableRows(root.currentItem);
        root.contentFocused = false;
        root.contentRowIdx = -1;

        // ── Search-result jump target (quick-260821-6z1 Task 3, D-06/R-4)
        //    — SettingsState.selectSearchResult() sets `pendingRowLabel`
        //    BEFORE calling `goToPage()`, so it is already populated by
        //    the time this swap lands. Reuses the EXISTING focus-ring and
        //    scroll mechanisms (`_applyRowFocusVisual()`/
        //    `_scrollRowIntoView()`) rather than building a second
        //    highlight visual — this plan's own explicit instruction. A
        //    label that matches nothing (a stale RowIndex entry, a rename
        //    landed in one place and not the other) clears the pending
        //    label and logs a NAMED warning rather than returning
        //    silently — a guard that returns silently is what turned a
        //    real ordering rejection into "the edit did nothing" in a
        //    prior wave on this same surface. ─────────────────────────
        if (root.sState.pendingRowLabel.length > 0) {
            var targetLabel = root.sState.pendingRowLabel;
            var foundIdx = -1;
            for (var j = 0; j < root._focusableRows.length; j++) {
                if (root._rowKey(root._focusableRows[j]) === targetLabel) {
                    foundIdx = j;
                    break;
                }
            }
            if (foundIdx >= 0) {
                root.contentFocused = true;
                root.contentRowIdx = foundIdx;
                root._applyRowFocusVisual();
                // Defect 2 fix — deferred ONLY here, not in
                // enterContent()/moveContentRow() below (both already
                // operator-verified working, grim+PIL, quick-260821-6z1;
                // changing a verified path to fix an unverified one is
                // not this fix's job). `_swapTo` incubates the new page
                // synchronously and calls `_recollectRows()` in the very
                // next statement — Qt has not yet run the polish pass
                // that lays out the page's Column/sizes its Flickable, so
                // `_scrollRowIntoView()`'s `row.mapToItem(...)` and
                // `flick.contentHeight` reads would both see stale/zeroed
                // geometry (every row maps to y≈0, contentHeight unset)
                // and the nudge would silently never move `contentY` — the
                // row WOULD be ringed, just off-screen. `Qt.callLater`
                // pushes the read past that pass.
                Qt.callLater(root._scrollRowIntoView);
            } else {
                console.warn("Pages: search jump target not found on this page: " + targetLabel);
            }
            root.sState.pendingRowLabel = "";
        }
    }

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

        // ── Sub-page deep-link (quick task 260825-wj2 Task 1, D-5; fixed
        //    quick-260826-1n9 Task 3, defect 4) — the target page object
        //    does not exist until the incubation just above, so this is
        //    the earliest point a sub-page push can be requested. Only a
        //    StackPage-wrapped comp exposes `openSubPage`; a bare
        //    PageBase does not, so this is guarded rather than assumed —
        //    a plain page whose pendingSubPageIdx somehow arrived >0 (it
        //    should not, since only sub-page-bearing rows set it) simply
        //    lands on the page's root with no sub-page opened, not a
        //    crash.
        //
        //    ROUTED THROUGH `sState.openSubPage()`, not
        //    `currentItem.openSubPage()` directly — calling the
        //    StackPage's own method bypassed `sState.subPageIdxStack`
        //    entirely: StackView.depth became 2 while the stack stayed
        //    `[]`, so Settings.qml's Escape handler (gated on
        //    `subPageIdxStack.length > 0`) closed the whole WINDOW
        //    instead of popping the sub-page. `sState.openSubPage()`
        //    updates the stack AND emits `subPageOpened`, which
        //    StackPage's own `Connections` (StackPage.qml:136) picks up
        //    to perform the actual push — the identical mechanism a
        //    real (non-search) sub-page navigation already uses. ────────
        var didDeepLinkSubPage = root.sState.pendingSubPageIdx > 0 && root.currentItem && typeof root.currentItem["openSubPage"] === "function";
        if (didDeepLinkSubPage)
            root.sState.openSubPage(root.sState.pendingSubPageIdx);
        root.sState.pendingSubPageIdx = -1;

        // Skip the immediate recollect when a sub-page deep-link was just
        // requested: the StackPage's push (triggered above, via its own
        // Connections) has not settled on this same tick, so an immediate
        // `_recollectRows()` here would fail to find the pending label,
        // log the not-found warning, and CLEAR `pendingRowLabel` — leaving
        // nothing for the deferred pass this file's own `onSubPageOpened`
        // handler (above) runs once the push HAS settled. A LOCAL
        // boolean, not `sState` state — this decision belongs to this one
        // `_swapTo` call only.
        if (!didDeepLinkSubPage)
            root._recollectRows();
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
    // ── Directional slide alongside the fade (quick task 260825-v3u) ─────
    //    Caelestia's Pages.qml does exactly this: the incoming page enters
    //    offset by one padding step in the direction of travel and settles
    //    to 0 while it fades in. Forward (a higher page index) enters from
    //    below, backward from above, so the rail's own up/down geometry and
    //    the content's motion agree instead of the content appearing in
    //    place regardless of which way you moved.
    //
    //    THE TOTAL DURATION IS DELIBERATELY UNCHANGED, and that is the whole
    //    reason this is safe to add here. The comment block above records
    //    two rounds of operator pushback on this swap FEELING LAGGY, both
    //    resolved by shortening it (562ms -> ~500ms) and ending with "the
    //    animation is already opacity-only (no slide/transform to trim)".
    //    The slide runs INSIDE the existing fade-in stage, in parallel, on
    //    the same token — it adds a dimension to the motion, never a
    //    millisecond to it. If the swap is ever judged laggy again, the
    //    duration is still the thing to cut, and this transform is not it.
    //
    //    `Translate` rather than Caelestia's anchors.topMargin: pages here
    //    are incubated with `anchors.fill = root` (:177), so a margin
    //    animation would fight the fill anchor. A transform moves the
    //    rendered result without touching layout at all.
    readonly property int _swapShiftDistance: Design.panelPadding
    property int _lastIdx: 0

    transform: Translate {
        id: swapShift
    }

    SequentialAnimation {
        id: swapAnim

        property int targetIdx: 0
        // Set at `goTo()` time, before the sequence runs: +1 when moving
        // down the rail, -1 when moving up.
        property int direction: 1

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
        // Placed the new page at its start offset in the same frame it was
        // incubated, so the first frame of the fade-in is already displaced
        // rather than jumping on the second.
        PropertyAction {
            target: swapShift
            property: "y"
            value: Motion.motionEnabled ? root._swapShiftDistance * swapAnim.direction : 0
        }
        ParallelAnimation {
            PropertyAnimation {
                target: root
                property: "opacity"
                to: 1
                duration: Motion.motionEnabled ? Motion.standardDuration : 0
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
            PropertyAnimation {
                target: swapShift
                property: "y"
                to: 0
                duration: Motion.motionEnabled ? Motion.standardDuration : 0
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

    // This is the ONE path (via `Connections.onCurrentPageIdxChanged`
    // below) both a nav-rail click (`SettingsState.goToPage` ->
    // `currentPageIdx = idx`) AND an already-open-window IPC `openPage`
    // deep-link (`settingsLoader.item.sState.currentPageIdx = idx` in
    // shell.qml) funnel through — both take the SAME animated swapAnim
    // route (confirmed live via SQDDIAG instrumentation, ninth live-pass:
    // no asymmetry between the two entry mechanisms). The ONLY genuinely
    // different path is `Component.onCompleted` below's direct `_swapTo`
    // — the first page shown whenever the window transitions
    // closed->open, regardless of entry mechanism.
    function goTo(idx) {
        swapAnim.targetIdx = idx;
        // Direction is read BEFORE `_lastIdx` is updated, and `_lastIdx`
        // tracks what was asked for rather than what is currently mounted:
        // `restart()` on an in-flight swap replaces its target, so keying
        // off the mounted page would give the wrong direction for a second
        // click that lands mid-animation.
        swapAnim.direction = (idx >= root._lastIdx) ? 1 : -1;
        root._lastIdx = idx;
        swapAnim.restart();
    }

    Connections {
        target: root.sState
        function onCurrentPageIdxChanged() {
            root.goTo(root.sState.currentPageIdx);
        }

        // Defect 1 fix (quick-260826-1n9, Task 3) — the same-page half of
        // a search jump: SettingsState emits this instead of a
        // currentPageIdx write when the target row is already on the
        // showing page (that write would be a no-op and fire no change
        // signal at all). `Qt.callLater`, not a bare call: the same
        // child-binding-lags-parent-signal reasoning `onSubPageOpened`/
        // `onSubPageClosed` below already state.
        function onRowJumpRequested() {
            Qt.callLater(root._recollectRows);
        }

        // Sub-page push/pop (quick task 260825-wj2 Task 1) — a StackPage
        // handles the actual push/pop itself (its own Connections on the
        // same signals), but the row-focus system here also needs to
        // re-collect for the newly-visible sub-page/root. `Qt.callLater`,
        // not a bare call: inside `onXChanged` a child binding still sees
        // the OLD value and the StackView's push has not settled yet
        // (MEMORY child-binding-lags-parent-signal — the same reason
        // `_swapTo` is already sequenced through a `ScriptAction` rather
        // than a bare handler).
        function onSubPageOpened(idx) {
            Qt.callLater(root._recollectRows);
        }
        function onSubPageClosed() {
            Qt.callLater(root._recollectRows);
        }
    }

    Component.onCompleted: {
        // The first page of a closed->open transition is shown directly,
        // unanimated, exactly as before — `_lastIdx` is seeded here so the
        // FIRST swap after that has a real reference to compare against
        // instead of always reading as "forward from 0".
        root._lastIdx = root.sState.currentPageIdx;
        root._swapTo(root.sState.currentPageIdx);
    }
}
