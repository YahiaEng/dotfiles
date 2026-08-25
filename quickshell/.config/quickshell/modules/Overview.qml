// Overview.qml — the full-screen workspace overview surface (Phase 16 Plan
// 03, expanding the tracer's single tile into D-16-01's fixed eleven-slot
// grid, OVER-01/OVER-02).
//
// Ten WorkspaceTile instances in a fixed 5-column x 2-row arrangement
// mirroring the number row (D-16-01/D-16-03) — every slot renders on every
// summon, occupied or not, so a tile's screen position never moves between
// summons — plus D-16-05's always-present, visually distinct eleventh
// scratchpad tile beneath the block. The whole assembly enters on a
// row-level cascade (D-16-24): row 1, row 2, scratchpad — three bands, not
// eleven. The fit arithmetic (16-UI-SPEC.md "Grid geometry" / "Spacing
// Scale") is load-bearing and re-run in the comments beside the grid block
// below on any tile/gap/border change.
//
// Every layer between Super+O and live pixels is wired end-to-end here:
// layer posture, scrim, focus grab, dismissal, click-to-focus-and-close,
// and the `overview` IPC status verb — all inherited unchanged from the
// tracer (16-02).
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "overview"
import "dashboard"

PanelWindow {
    id: overviewWindow

    // shell.qml's LazyLoader listens for this to deactivate itself so the
    // wl_surface is actually destroyed on every dismissal path (D-14), not
    // merely hidden — matching Dashboard.qml/ScreencopyProbe.qml's own
    // proven combination.
    //
    // EMITTED ONLY AT THE END OF THE EXIT, never by a caller (quick task
    // 260825-v3u). This signal means "the exit has finished playing, tear
    // me down", not "please close" — `_beginDismiss()` below is the
    // request half. Emitting it directly is what made the overview pop:
    // the loader destroys the surface on the frame it fires, so nothing
    // this file animates gets a chance to run. Exactly the split quick
    // task 260825-x9p round 3 had to make for the bar popouts, for the
    // same reason.
    signal dismissRequested()

    // ── The single dismissal funnel (quick task 260825-v3u) ──────────────
    // Mirrors PowerMenu.qml:411-437 — the other Cascade consumer, which has
    // had this shape since Phase 20 — rather than inventing a second one.
    // Every dismissal route in this file goes through here, so the
    // wait-for-the-exit guarantee lives in one place instead of five.
    //
    // Before this, all five routes emitted `dismissRequested()` straight at
    // shell.qml, which answered `overviewLoader.active = false`. The
    // entrance cascade was armed and run on `Component.onCompleted` (:95)
    // but `Cascade.runExit()` — which has existed the whole time — was
    // never called from this file at all, so the overview had an entrance
    // and no exit.
    //
    // WHY THE WORKSPACE SWITCH IS NOT DEFERRED BEHIND THE EXIT, unlike
    // PowerMenu's action dispatch: `activateTile`/`activateWindow` call
    // `activate()` BEFORE this function, and that ordering is deliberate.
    // D-16-19 states the overview's job is navigation, and navigation is
    // the thing that must stay instant — adding a spatial-out duration of
    // latency to every workspace switch would tax the common path to
    // decorate the rare one. The surface is on the Overlay layer, so the
    // tiles sweep out ABOVE the workspace that has already been switched
    // to, which reads as the overview lifting off the new workspace.
    // PowerMenu defers because its actions (poweroff/reboot) must never
    // fire while a frame of the surface could still be on screen; nothing
    // here is destructive that way.
    property bool _dismissing: false
    function _beginDismiss() {
        if (overviewWindow._dismissing)
            return;
        overviewWindow._dismissing = true;

        function afterExit() {
            overviewWindow.entranceCascade.exitFinished.disconnect(afterExit);
            overviewWindow.dismissRequested();
        }
        overviewWindow.entranceCascade.exitFinished.connect(afterExit);
        // Motion-off and empty-bands both land in `exitFinished` synchronously
        // (Cascade.runExit()'s own early return), so the no-motion path still
        // tears down on the same frame it used to.
        overviewWindow.entranceCascade.runExit();
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // ── Layer posture (D-43, inherited) ──────────────────────────────────
    // Overlay layer, zero exclusive zone, namespace named
    // "quickshell-overview" so the family-wide `^quickshell-.*` blur/
    // ignore_alpha layerrules apply automatically (D-42) with no new
    // Hyprland config beyond the per-namespace `fade` animation rule
    // (D-16-24, windowrules.lua). WlrKeyboardFocus.OnDemand: measured
    // ONDEMAND-SUFFICIENT in 16-SPIKE-FINDINGS.md's "VERDICT — keyboard
    // focus posture" — arrow/Escape keys reached a throwaway harness's key
    // handlers with zero prior pointer click under this exact posture, so
    // no Exclusive escalation is taken here.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-overview"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0
    color: "transparent"

    // ── D-16-24's row-level entrance cascade ──────────────────────────────
    // Three bands, in order: row 1, row 2, the scratchpad — never per-tile.
    // Reuses D-21's existing stagger token verbatim (Motion.staggerOffsetDuration
    // / Motion.emphasizedInDuration / emphasizedInEasing) so motion.json does
    // not grow and Phase 12's D-25 semantic-layer growth policy stays shut.
    // Three bands at the stagger offset each lands the last band around
    // 380ms, clearing D-21's 700ms fence with margin — cascading all eleven
    // tiles individually would land between ~630ms and ~850ms and straddle
    // it, which is exactly why this is row-level, not tile-level.
    readonly property Cascade entranceCascade: Cascade {}

    // ── Render-gate defect, round 2 root cause (2026-08-03) ──────────────
    // Real root cause of "only shows the current window", confirmed with a
    // per-delegate IPC measurement (x/y/width/height/hasContent/sourceSize
    // per window), not screenshots: HyprlandToplevel.lastIpcObject starts as
    // an EMPTY QVariantMap ({}, rawIpcHasKeys=0 — not null) for any window
    // created after Quickshell's initial sync, and never spontaneously
    // populates — proven by waiting 4+ seconds inside one still-summoned
    // session with zero change. This is the SAME lag shell.qml's own
    // fullscreenBlocking guard already documents and works around
    // ("Hyprland.activeToplevel.lastIpcObject can lag... force a refresh").
    // WorkspaceTile.qml's own `(ipc && ipc.at) ? ipc.at : [0,0]` guard was
    // therefore firing CORRECTLY on an empty object and staying collapsed
    // forever, not corrupting anything — the missing piece was ever asking
    // Hyprland to repopulate it. Concurrent capture itself was never
    // broken: every delegate in that same measurement had hasContent=true
    // with correct, DISTINCT sourceSize values throughout — refuting the
    // "only one concurrent screencopy stream" hypothesis directly.
    //
    // Both refresh and cascade arming happen here, in the same
    // Component.onCompleted block — QML permits exactly one handler per
    // signal per object, and by the time overviewWindow's own onCompleted
    // fires, every descendant referenced below (rowOne/rowTwo/scratchpadTile)
    // is already constructed (Component.onCompleted fires bottom-up),
    // mirroring PanelDialog.qml's own arming point rather than inventing a
    // second trigger.
    Component.onCompleted: {
        Hyprland.refreshToplevels();
        overviewWindow.entranceCascade.bands = [rowOne, rowTwo, scratchpadTile];
        overviewWindow.entranceCascade.armed = true;
        overviewWindow.entranceCascade.run();
        overviewWindow.seedSelectedTile();
    }

    // ── Render-gate deviation from 16-UI-SPEC.md (2026-08-03) ────────────
    // UI-SPEC recommended 0.55 (already lower than PanelDialog's own
    // panelSurfaceOpacity/drawerSurfaceOpacity of 0.78). At the Task 3
    // render gate the operator judged the backdrop "too strong" even at
    // 0.55. First attempt (recorded for the record, corrected before
    // shipping): tried lowering ONLY this alpha to 0.35, on the assumption
    // alpha was the sole surface-local lever available since blur strength
    // is global. Screenshot-compared live against the original 0.55 and
    // found this was WRONG — 0.35 sits below the family `^quickshell-.*`
    // `ignore_alpha` floor (0.5, windowrules.lua), which does not soften the
    // blur, it silently DISABLES it — the backdrop read as raw unblurred
    // transparency (windowrules.lua's own FILE-LEVEL FINDING documents this
    // exact mistake from an earlier surface's history; this reproduced it
    // firsthand rather than assumed). `LayerRule`'s only blur field is a
    // boolean (`hl.meta.lua` line 551); blur intensity has no per-surface
    // knob at all — "turn it down" has exactly one honest answer for this
    // architecture: off. windowrules.lua now pulls D-16-06's own
    // pre-authorized fallback lever #1 (`blur = false`, exact-match
    // override on `quickshell-overview`) instead of chasing an alpha value
    // ── NO full-bleed scrim (16-07 render gate, round 12) ─────────────────
    // Supersedes D-16-06's "the scrim is context, not cover". The gate's
    // objection was that summoning the overview "overtakes the entire
    // screen" — the whole desktop got the fill-and-frost treatment when only
    // the tiles were meant to. That is what a full-bleed scrim does by
    // definition, and no alpha value fixes it: any scrim above the blur
    // cutoff frosts the entire screen, and any scrim below it stops the
    // tiles frosting too (rounds 6-9 walked that whole range).
    //
    // Removing it is what makes the compositor rule express the intent
    // instead of fighting it. `ignore_alpha` skips blur wherever composited
    // alpha falls under the threshold, so with nothing painted outside the
    // tiles those regions sit at alpha 0, far below the 0.25 cutoff, and the
    // desktop behind is left completely untouched — not dimmed, not blurred.
    // The tiles carry their own alpha, clear the cutoff, and frost. The grid
    // reads as floating panes of glass over a live desktop.
    //
    // Consequence worth knowing: tile legibility no longer has a scrim
    // helping it. Each tile's own fill is now solely responsible for
    // separating it from whatever is behind — see WorkspaceTile.qml.

    // ── Click-outside dismiss, the scrim half (16-07 render gate, round 1) ─
    // The HyprlandFocusGrab below cannot deliver this on its own: it clears
    // when focus moves to ANOTHER surface, and this surface is full-screen,
    // so a click on empty space lands on the overview itself and the grab
    // never fires. The panels and the drawer get click-outside free precisely
    // because they are small and have a real outside; the overview has to
    // spell it out. Declared here, before the grid, so it sits UNDERNEATH
    // every tile — tiles keep their own click handling untouched and only
    // genuinely empty space reaches this.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: overviewWindow._beginDismiss()
    }

    // Fixed tile geometry (16-UI-SPEC.md "Grid geometry") — named constants
    // so the fit arithmetic below reads as arithmetic, not magic numbers.
    readonly property int tileWidth: 480
    readonly property int tileHeight: 270
    // 480 / 2560 = 0.1875 on this host — computed, not hardcoded, per
    // D-16-02, so a different monitor width still produces a correct scale.
    readonly property real captureScale: overviewWindow.tileWidth / Hyprland.focusedMonitor.width

    // Scratchpad tile geometry (D-16-05): ~0.625x a numbered tile, still
    // 16:9. Its own captureScale (not the numbered tiles' one reused) so
    // its windows render at the scratchpad's own smaller scale rather than
    // being scaled twice.
    readonly property int scratchpadWidth: 300
    readonly property int scratchpadHeight: 169
    readonly property real scratchpadCaptureScale: overviewWindow.scratchpadWidth / Hyprland.focusedMonitor.width

    // Resolves a fixed slot id (1..10) against Hyprland's live workspace
    // list, or returns null for an id Hyprland does not yet know about.
    // Hyprland.workspaces itself is never padded — the ten SLOTS are the
    // fixed thing (D-16-01), the workspace behind each is what may be
    // absent.
    function workspaceForSlot(slotId) {
        var list = Hyprland.workspaces.values;
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === slotId)
                return list[i];
        }
        return null;
    }

    function isFocusedSlot(slotId) {
        return !!(Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === slotId);
    }

    // D-16-05: resolves the scratchpad workspace by the exact token
    // keybinds.lua's Super+Shift+S bind uses ("special:magic"), or null
    // when no window has ever been sent there yet — the tile's own
    // position is permanently reserved either way (see below).
    function scratchpadWorkspace() {
        var list = Hyprland.workspaces.values;
        for (var i = 0; i < list.length; i++) {
            if (list[i].name === "special:magic")
                return list[i];
        }
        return null;
    }

    // D-16-13/D-16-20: clicking a tile's empty area focuses that workspace
    // and closes the overview in the same gesture (OVER-02). Shared by
    // every numbered tile below rather than repeated ten times.
    //
    // ── Why slotIndex is needed as well (16-07 render gate, round 1) ──────
    // `workspace` is null for a workspace that is EMPTY, because Hyprland
    // does not create a workspace object until something lands on it — so
    // workspaceForSlot() finds nothing and the old single-argument form
    // silently dismissed without navigating anywhere. That defect was never
    // keyboard-specific: clicking an empty tile took the same dead path, it
    // just went unnoticed because 16-05's gate only exercised occupied
    // tiles. The slot index is what survives a nonexistent workspace, so it
    // is passed alongside the object and used as the fallback below.
    function activateTile(workspace, slotIndex) {
        if (workspace)
            workspace.activate();
        else if (slotIndex !== undefined && slotIndex !== null)
            overviewWindow.dispatchWorkspaceFocus(slotIndex);
        overviewWindow._beginDismiss();
    }

    // Focuses a workspace Hyprland has no object for yet, by dispatching the
    // SAME expressions keybinds.lua's own Super+N / Super+S binds use
    // (`hl.dsp.focus({workspace=N})`, `hl.dsp.workspace.toggle_special`) —
    // Hyprland creates the workspace on demand. Range-checked through
    // isValidWorkspaceToken() before interpolation, exactly as
    // dispatchWindowMove() does: the only value substituted here is an
    // integer this file computed, never a client-supplied string (T-16-25).
    function dispatchWorkspaceFocus(slotIndex) {
        if (slotIndex === 10) {
            Hyprland.dispatch("hl.dsp.workspace.toggle_special(\"magic\")");
            return true;
        }
        var id = slotIndex + 1;
        if (!overviewWindow.isValidWorkspaceToken(id)) {
            console.warn("overview: refusing workspace focus — slot index out of range");
            return false;
        }
        Hyprland.dispatch("hl.dsp.focus({workspace=" + String(id) + "})");
        return true;
    }

    // D-16-20's other half (Phase 16 Plan 05 Task 2): clicking a SPECIFIC
    // window thumbnail focuses that window and its workspace, then closes
    // — exact parity with what Enter on a selected window will do in plan
    // 16-07. `toplevel.wayland` is the generic
    // Quickshell.Wayland.Toplevel (wlr-foreign-toplevel-management) handle
    // — the same object ScreencopyView.captureSource already binds to —
    // and its own activate() request is what "brings its workspace with
    // it" (HyprlandToplevel itself exposes no activate() method; only
    // HyprlandWorkspace and the generic wayland handle do, confirmed
    // against the installed qmltypes). A thumbnail in the `failed` state
    // reaches here identically — the window still exists.
    function activateWindow(toplevel) {
        if (toplevel && toplevel.wayland)
            toplevel.wayland.activate();
        overviewWindow._beginDismiss();
    }

    // ── D-16-15/D-16-16 keyboard selection state (Phase 16 Plan 07) ──────
    // The whole selection is exactly one index pair: `selectedTile` (0-10,
    // 0-4 row 1, 5-9 row 2, 10 the scratchpad — the SAME canonical order the
    // 5x2 grid below already renders in) and `selectedWindow` (Task 2:
    // negative when no window level is active, otherwise an index into the
    // selected tile's own toplevel list). No third mode exists.
    //
    // ── THE BOUNDARY (D-16-15's hard boundary) ────────────────────────────
    // No editable-text QML control of any kind, no filter property, no
    // search state — arrows and modifiers only, on this file and every
    // file it composes. This is deliberate, not an oversight: a place to
    // type here would be a second "type to find a thing" surface
    // competing with the app launcher (REQUIREMENTS.md's OVER-05
    // exclusion). T-16-34 enforces this mechanically via the acceptance
    // grep, not by convention alone —
    // which is also why this note itself avoids spelling out the three
    // banned type names literally.
    property int selectedTile: 0
    // Remembers the column (0-4) last occupied in row 1/row 2, so an Up
    // press from the scratchpad — which has no column of its own — returns
    // to the SAME column it left, honouring the "column-preserving" half of
    // the 2D row movement below even across the scratchpad's one exception.
    property int lastColumn: 0
    onSelectedTileChanged: {
        if (overviewWindow.selectedTile < 10)
            overviewWindow.lastColumn = overviewWindow.selectedTile % 5;
    }

    // Resolves a fixed slot index (0-10, this file's own canonical order —
    // see the property comment above) to the HyprlandWorkspace it names, or
    // null. Slot 10 is always the scratchpad; slots 0-9 defer to
    // workspaceForSlot()'s existing 1-10 id resolution, unchanged.
    function slotWorkspace(index) {
        return index === 10 ? overviewWindow.scratchpadWorkspace() : overviewWindow.workspaceForSlot(index + 1);
    }

    // The live toplevel list for a slot, or an empty array for an
    // unoccupied/nonexistent workspace — never null, so every caller can
    // read `.length` without its own null guard. `.values` is
    // `UntypedObjectModel`'s own array snapshot (the same model
    // WorkspaceTile.qml's windowRepeater already binds `.toplevels` to
    // directly as a Repeater model); reading it here as a plain JS array is
    // what lets arrow movement address "window N of this tile" by index.
    function toplevelsForSlot(index) {
        var ws = overviewWindow.slotWorkspace(index);
        if (ws && ws.toplevels && ws.toplevels.values)
            return ws.toplevels.values;
        return [];
    }

    // ── Left/Right: linear wrap across all eleven tiles ───────────────────
    // Chosen over edge-stop at the UI-consideration gate (16-UI-SPEC.md
    // "Keyboard model") despite genuine tension with D-16-03's
    // spatial-constancy argument — under wrap, a single Right from tile 5
    // lands on tile 6 in the row below, so tile position and travel
    // direction stop agreeing at the row boundary. Implemented as one
    // source-visible modulo over the eleven-slot count.
    //
    // ── Edge-stop taken at the Task 3 render gate, round 4 ────────────────
    // The gate's pre-authorised one-line fallback, exercised exactly as the
    // plan wrote it. Under the modulo, slot 0 (workspace 1) and slot 10 (the
    // scratchpad) were adjacent, so one Left from workspace 1 jumped the
    // selection from the top-left corner to the tile below the whole grid —
    // the row-crossing tension the comment above anticipated, at its widest.
    // Clamping makes Left/Right one straight line with real ends; the
    // scratchpad is still one Down away from row 2, so nothing became
    // unreachable. The mid-grid 5->6 row jump was judged fine at the gate
    // and is unchanged.
    function moveLinear(delta) {
        overviewWindow.selectedTile = Math.max(0, Math.min(10, overviewWindow.selectedTile + delta));
    }

    // ── Up/Down: column-preserving 2D row movement, NOT part of the linear
    // sequence above — a fast row jump. Down from row 1 goes to row 2 in
    // the same column; Down from row 2 goes to the scratchpad; Up reverses,
    // using lastColumn to return to the right column from the scratchpad's
    // single columnless slot. Down from the scratchpad and Up from row 1
    // are no-ops (nothing further in that direction).
    function moveVertical(dy) {
        if (overviewWindow.selectedTile === 10) {
            if (dy < 0)
                overviewWindow.selectedTile = 5 + overviewWindow.lastColumn;
            return;
        }
        var col = overviewWindow.selectedTile % 5;
        var row = Math.floor(overviewWindow.selectedTile / 5);
        if (dy > 0)
            overviewWindow.selectedTile = row === 0 ? col + 5 : 10;
        else if (row === 1)
            overviewWindow.selectedTile = col;
    }

    // Seeds selectedTile to the slot holding the currently-focused
    // workspace on summon, falling back to slot 0 — the selection starts
    // where the user already is rather than at an arbitrary corner.
    function seedSelectedTile() {
        var focused = Hyprland.focusedWorkspace;
        if (focused) {
            if (focused.name === "special:magic") {
                overviewWindow.selectedTile = 10;
                return;
            }
            if (focused.id >= 1 && focused.id <= 10) {
                overviewWindow.selectedTile = focused.id - 1;
                return;
            }
        }
        overviewWindow.selectedTile = 0;
    }

    // ── Task 2 (D-16-16/D-16-20): window-level selection ──────────────────
    // Negative when no window level is active; otherwise an index into
    // `selectedTile`'s own toplevel list (model order — the same order
    // WorkspaceTile.qml's windowRepeater already renders in). Together with
    // selectedTile above, this is the WHOLE selection state — one index
    // pair, no third mode.
    property int selectedWindow: -1

    // Arrow movement WITHIN the selected tile's windows — clamps at the
    // ends rather than wrapping into a neighbouring tile, because crossing
    // a tile boundary at window level is exactly the ambiguity D-16-16
    // rejected a flat 2D field of windows over.
    function moveWindowSelection(delta) {
        var tops = overviewWindow.toplevelsForSlot(overviewWindow.selectedTile);
        if (tops.length === 0) {
            overviewWindow.selectedWindow = -1;
            return;
        }
        var next = overviewWindow.selectedWindow + delta;
        overviewWindow.selectedWindow = Math.max(0, Math.min(tops.length - 1, next));
    }

    // Every directional key is gated on selectedWindow first: window level
    // owns arrow input entirely while active (clamped, per above); tile
    // level's own linear-wrap/row-jump movement only runs once it is not.
    function handleLeft() {
        if (overviewWindow.selectedWindow >= 0)
            overviewWindow.moveWindowSelection(-1);
        else
            overviewWindow.moveLinear(-1);
    }
    function handleRight() {
        if (overviewWindow.selectedWindow >= 0)
            overviewWindow.moveWindowSelection(1);
        else
            overviewWindow.moveLinear(1);
    }
    function handleUp() {
        if (overviewWindow.selectedWindow >= 0)
            overviewWindow.moveWindowSelection(-1);
        else
            overviewWindow.moveVertical(-1);
    }
    // Down ALWAYS jumps a row at tile level — it never descends into a tile.
    //
    // ── Supersedes D-16-16's "Enter (or Down) drops into a tile" ──────────
    // 16-07's render gate rejected the overloaded form: because Down
    // descended whenever the current tile happened to hold windows, moving
    // through the grid silently changed selection LEVEL, and the mode
    // indicator flipping from "Tiles" to "Workspace N windows" was the only
    // outward sign. Reported as a jarring label change; the label was
    // reporting an unrequested level change correctly. Enter is now the one
    // and only way down a level, which also makes Up/Down behave identically
    // over empty and occupied tiles.
    function handleDown() {
        if (overviewWindow.selectedWindow >= 0) {
            overviewWindow.moveWindowSelection(1);
            return;
        }
        overviewWindow.moveVertical(1);
    }

    // Enter: at window level, focuses the selected window and dismisses —
    // exact parity with clicking that thumbnail (D-16-20), so nothing is
    // learned or tested twice. At tile level, a tile with windows descends
    // (selectedWindow = 0); a tile with none — or a slot id Hyprland does
    // not yet know about — activates the workspace and dismisses, exactly
    // what clicking that tile's empty area does (D-16-13/D-16-20).
    function handleEnter() {
        if (overviewWindow.selectedWindow >= 0) {
            var tops = overviewWindow.toplevelsForSlot(overviewWindow.selectedTile);
            var toplevel = tops[overviewWindow.selectedWindow];
            if (toplevel)
                overviewWindow.activateWindow(toplevel);
            return;
        }
        var index = overviewWindow.selectedTile;
        var tops2 = overviewWindow.toplevelsForSlot(index);
        if (tops2.length > 0) {
            overviewWindow.selectedWindow = 0;
            return;
        }
        overviewWindow.activateTile(overviewWindow.slotWorkspace(index), index);
    }

    // Maps Shift+<number> to the workspace id the existing Super+Shift+N
    // Hyprland binds already use (keybinds.lua lines 227-236) — 1-9 map to
    // themselves, 0 maps to 10. Returns null for any other key so the
    // caller can tell "not a workspace-number key" apart from "workspace 0",
    // which does not exist.
    //
    // ── Why the punctuation table exists (16-07 render gate, round 1) ─────
    // Qt delivers the SHIFTED keysym, not the digit: with Shift held, `1`
    // arrives as Qt.Key_Exclam and `2` as Qt.Key_At — Qt.Key_1..Qt.Key_9
    // never match, which is why this returned null for every press and
    // Shift+number appeared to do nothing at all. The digit branch below is
    // kept (layouts and keypads that do report the digit still work), with
    // the US-layout shifted row added as an explicit ordered table rather
    // than arithmetic: these keysyms are NOT contiguous in Qt's enum, so
    // `key >= Key_Exclam && key <= Key_ParenRight` would be wrong.
    readonly property var shiftedNumberRow: [
        Qt.Key_ParenRight,  // Shift+0 -> workspace 10
        Qt.Key_Exclam,      // Shift+1
        Qt.Key_At,          // Shift+2
        Qt.Key_NumberSign,  // Shift+3
        Qt.Key_Dollar,      // Shift+4
        Qt.Key_Percent,     // Shift+5
        Qt.Key_AsciiCircum, // Shift+6
        Qt.Key_Ampersand,   // Shift+7
        Qt.Key_Asterisk,    // Shift+8
        Qt.Key_ParenLeft    // Shift+9
    ]
    function shiftNumberToWorkspaceId(key) {
        if (key === Qt.Key_0)
            return 10;
        if (key >= Qt.Key_1 && key <= Qt.Key_9)
            return key - Qt.Key_0;
        var shifted = overviewWindow.shiftedNumberRow.indexOf(key);
        if (shifted === 0)
            return 10;
        if (shifted > 0)
            return shifted;
        return null;
    }

    // Shift+1..0: moves the WINDOW-level selected window to that workspace
    // through plan 16-06's own guarded dispatchWindowMove() below — this is
    // the only call site, reused, never re-derived (T-16-31's mitigation:
    // the dispatch call-site count in this file stays unchanged from its
    // post-16-06 value). With no window selected this is a no-op: a
    // keystroke silently acting on something other than what is visibly
    // selected (e.g. falling back to "the active window") is worse than a
    // keystroke that does nothing (T-16-32).
    function handleShiftMove(workspaceId) {
        if (overviewWindow.selectedWindow < 0)
            return;
        var sourceTile = overviewWindow.selectedTile;
        var tops = overviewWindow.toplevelsForSlot(sourceTile);
        if (overviewWindow.selectedWindow >= tops.length)
            return;
        var toplevel = tops[overviewWindow.selectedWindow];
        if (!toplevel)
            return;
        var moved = overviewWindow.dispatchWindowMove(toplevel, workspaceId);
        if (!moved)
            return;
        // Keep the selection sensible: CLAMP WITHIN THE SOURCE TILE rather
        // than following the window to its new tile. Hyprland.toplevels is
        // a live, re-derived model (toplevelsForSlot() reads it fresh every
        // call, never a snapshot) — the destination tile's own future index
        // for this window is not knowable at the moment of dispatch, only
        // after Hyprland's own event lands, so "follow" would mean guessing.
        // Clamping to what remains in the SOURCE tile is answerable right
        // now, from data already in hand.
        var remaining = overviewWindow.toplevelsForSlot(sourceTile).length;
        overviewWindow.selectedWindow = remaining > 0 ? Math.min(overviewWindow.selectedWindow, remaining - 1) : -1;
    }

    // ── Mode indicator copy (D-16-16/D-16-17, PROVISIONAL) ─────────────────
    // Bounded interpolation only — the tile-level default label below, or
    // "Workspace {label} windows" once descended, where label is 1-10 or
    // the scratchpad naming itself instead of a
    // number (T-16-33's accepted disclosure: a workspace number/name, never
    // a window title or address). Marked provisional per D-16-17's
    // pre-agreed fallback: if Task 3's render gate finds this cluttered,
    // remove this pill and the window-level selection entirely — no new
    // decision needed.
    readonly property string modeIndicatorLabel: overviewWindow.selectedTile === 10 ? "scratchpad" : String(overviewWindow.selectedTile + 1)
    // Stable stem, appended suffix (16-07 render gate, round 1). The old
    // copy replaced the WHOLE string on descent ("Tiles" -> "Workspace 3
    // windows"), which read as the label glitching rather than as a level
    // change. The workspace identity is now always present and never moves;
    // descending only appends, so the eye tracks one added word instead of
    // re-reading a new sentence.
    readonly property string modeIndicatorText: overviewWindow.selectedWindow >= 0
        ? `Workspace ${overviewWindow.modeIndicatorLabel} · windows`
        : `Workspace ${overviewWindow.modeIndicatorLabel}`

    // Two-stage Esc, routed through one seam (D-16-16), following
    // PanelDialog.qml/WifiPanel.qml's own handleEscape() precedent
    // (D-15-14): a later stage is added by PREPENDING a branch before the
    // dismiss, never by restructuring this function. The first press backs
    // out of window-level selection; the second (this function's own
    // fallthrough) dismisses.
    function handleEscape() {
        if (overviewWindow.selectedWindow >= 0) {
            overviewWindow.selectedWindow = -1;
            return;
        }
        overviewWindow._beginDismiss();
    }

    // ── The fixed 5x2 numbered grid (D-16-01) ────────────────────────────
    // Block width: 5*480 + 4*24 = 2496px; height: 2*270 + 24 = 564px;
    // centred with a spacingLg (24px) scrim margin per side — 2544px total
    // on this 2560px display, 16px spare (16-UI-SPEC.md's load-bearing fit
    // arithmetic). Any change to tile width, gap or border must re-run it.
    // A Column of two Rows (not a single Grid) keeps each row independently
    // addressable as its own entrance-cascade band — plan 16-03 Task 2
    // wires that up without restructuring this container.
    Column {
        id: gridBlock
        anchors.centerIn: parent
        spacing: Design.spacingLg

        Row {
            id: rowOne
            spacing: Design.spacingLg

            Repeater {
                id: rowOneRepeater
                model: 5

                delegate: WorkspaceTile {
                    width: overviewWindow.tileWidth
                    height: overviewWindow.tileHeight
                    slotLabel: String(index + 1)
                    captureScale: overviewWindow.captureScale
                    monitor: Hyprland.focusedMonitor
                    workspace: overviewWindow.workspaceForSlot(index + 1)
                    isFocusedWorkspace: overviewWindow.isFocusedSlot(index + 1)
                    dropTargetActive: overviewWindow.dragActive && overviewWindow.dropTargetToken === (index + 1)
                    keyboardSelected: overviewWindow.selectedTile === index
                    selectedWindowIndex: overviewWindow.selectedTile === index ? overviewWindow.selectedWindow : -1
                    onActivated: overviewWindow.activateTile(workspace, index)
                    onWindowActivated: (toplevel) => overviewWindow.activateWindow(toplevel)
                    onDragStarted: (toplevel, globalPos, sourceSize) => overviewWindow.handleDragStarted(toplevel, globalPos, sourceSize)
                    onDragMoved: (globalPos) => overviewWindow.handleDragMoved(globalPos)
                    onDragEnded: (globalPos) => overviewWindow.handleDragEnded(globalPos)
                }
            }
        }

        Row {
            id: rowTwo
            spacing: Design.spacingLg

            Repeater {
                id: rowTwoRepeater
                model: 5

                delegate: WorkspaceTile {
                    width: overviewWindow.tileWidth
                    height: overviewWindow.tileHeight
                    slotLabel: String(index + 6)
                    captureScale: overviewWindow.captureScale
                    monitor: Hyprland.focusedMonitor
                    workspace: overviewWindow.workspaceForSlot(index + 6)
                    isFocusedWorkspace: overviewWindow.isFocusedSlot(index + 6)
                    dropTargetActive: overviewWindow.dragActive && overviewWindow.dropTargetToken === (index + 6)
                    keyboardSelected: overviewWindow.selectedTile === (index + 5)
                    selectedWindowIndex: overviewWindow.selectedTile === (index + 5) ? overviewWindow.selectedWindow : -1
                    onActivated: overviewWindow.activateTile(workspace, index + 5)
                    onWindowActivated: (toplevel) => overviewWindow.activateWindow(toplevel)
                    onDragStarted: (toplevel, globalPos, sourceSize) => overviewWindow.handleDragStarted(toplevel, globalPos, sourceSize)
                    onDragMoved: (globalPos) => overviewWindow.handleDragMoved(globalPos)
                    onDragEnded: (globalPos) => overviewWindow.handleDragEnded(globalPos)
                }
            }
        }
    }

    // ── Mode indicator (D-16-16/D-16-17, PROVISIONAL) ────────────────────
    // Reuses QuickToggles.qml's segmented-pill visual language (a rounded
    // shape with a tonal fill background, not a new chrome idiom) rather
    // than minting a second pill convention beyond the identity/monitor
    // pills WorkspaceTile.qml already draws. Sized to its own content —
    // the copy is bounded interpolation (modeIndicatorText above), never
    // free text. Sits above the grid, centred over it.
    //
    // This whole element is the render gate's fallback surface: if Task 3
    // finds it clutter, delete this Rectangle (and the selectedWindow
    // state above / keyboardSelected on WindowThumbnail) to take D-16-17's
    // pre-agreed fallback — no new decision needed.
    Rectangle {
        id: modeIndicator
        anchors {
            bottom: gridBlock.top
            horizontalCenter: gridBlock.horizontalCenter
            bottomMargin: Design.spacingSm
        }
        width: modeIndicatorLabelText.implicitWidth + Design.spacingMd * 2
        height: modeIndicatorLabelText.implicitHeight + Design.spacingXs * 2
        radius: height / 2
        color: Colours.surfaceVariant

        Text {
            id: modeIndicatorLabelText
            anchors.centerIn: parent
            text: overviewWindow.modeIndicatorText
            font.pixelSize: Design.fontLabel
            color: Colours.onSurfaceVariant
        }
    }

    // The eleventh tile (D-16-05): always rendered, whatever the scratchpad
    // holds. Position permanently reserved beneath the 5x2 block, so the
    // ten numbered tiles never move — D-16-01's constancy is untouched.
    // Everything but border colour, empty-state glyph and identity content
    // (isScratchpad, wired in WorkspaceTile.qml) is the numbered tiles'
    // own code path.
    WorkspaceTile {
        id: scratchpadTile
        anchors {
            top: gridBlock.bottom
            horizontalCenter: gridBlock.horizontalCenter
            topMargin: Design.spacingLg
        }
        width: overviewWindow.scratchpadWidth
        height: overviewWindow.scratchpadHeight
        isScratchpad: true
        captureScale: overviewWindow.scratchpadCaptureScale
        monitor: Hyprland.focusedMonitor
        workspace: overviewWindow.scratchpadWorkspace()
        dropTargetActive: overviewWindow.dragActive && overviewWindow.dropTargetToken === "special:magic"
        keyboardSelected: overviewWindow.selectedTile === 10
        selectedWindowIndex: overviewWindow.selectedTile === 10 ? overviewWindow.selectedWindow : -1
        onActivated: overviewWindow.activateTile(workspace, 10)
        onWindowActivated: (toplevel) => overviewWindow.activateWindow(toplevel)
        onDragStarted: (toplevel, globalPos, sourceSize) => overviewWindow.handleDragStarted(toplevel, globalPos, sourceSize)
        onDragMoved: (globalPos) => overviewWindow.handleDragMoved(globalPos)
        onDragEnded: (globalPos) => overviewWindow.handleDragEnded(globalPos)
    }

    // ── D-16-12/D-16-13/D-16-14 drag session (Phase 16 Plan 06) ──────────
    // Overview.qml owns this end-to-end — WorkspaceTile.qml and
    // WindowThumbnail.qml only report gestures, they hold no session state
    // of their own (see both files' own header notes).
    property var dragToplevel: null
    property bool dragActive: false
    property point dragPos: Qt.point(0, 0)
    // The single tile currently under the cursor during a drag: an integer
    // 1-10 for a numbered slot, the literal "special:magic" for the
    // scratchpad, or null when the cursor is over the gap between tiles or
    // outside the grid entirely. Every WorkspaceTile's own
    // `dropTargetActive` above compares itself against this ONE value, so
    // at most one tile is ever lit (Task 2's own acceptance bar).
    property var dropTargetToken: null

    DragGhost {
        id: dragGhost
    }

    function handleDragStarted(toplevel, globalPos, sourceSize) {
        overviewWindow.dragToplevel = toplevel;
        overviewWindow.dragActive = true;
        overviewWindow.dragPos = globalPos;
        overviewWindow.dropTargetToken = overviewWindow.resolveDropToken(globalPos);
        dragGhost.beginDrag(toplevel, globalPos, sourceSize);
    }

    function handleDragMoved(globalPos) {
        overviewWindow.dragPos = globalPos;
        overviewWindow.dropTargetToken = overviewWindow.resolveDropToken(globalPos);
        dragGhost.moveTo(globalPos);
    }

    // The eleven {item, token} pairs drop resolution hit-tests against —
    // built fresh per call rather than cached, since a drag is a rare,
    // short-lived gesture and this is a plain array of already-existing
    // item references, not new allocation-heavy work.
    function dropCandidates() {
        var list = [];
        for (var i = 0; i < rowOneRepeater.count; i++)
            list.push({
                item: rowOneRepeater.itemAt(i),
                token: i + 1
            });
        for (var i = 0; i < rowTwoRepeater.count; i++)
            list.push({
                item: rowTwoRepeater.itemAt(i),
                token: i + 6
            });
        list.push({
            item: scratchpadTile,
            token: "special:magic"
        });
        return list;
    }

    // Geometric hit-test against each tile's own real on-screen bounds
    // (`mapToItem(null, ...)` maps to scene/window coordinates — the SAME
    // coordinate system `DragHandler.centroid.scenePosition` already uses,
    // per WindowThumbnail.qml's own dragStarted/dragMoved payloads, so no
    // further translation is needed here). The 24px gap between tiles
    // belongs to no tile's bounds — resting there resolves to null, which
    // is a property of the fixed-slot layout itself, not an arbitration
    // rule this function has to encode.
    function resolveDropToken(globalPos) {
        var candidates = overviewWindow.dropCandidates();
        for (var i = 0; i < candidates.length; i++) {
            var tileItem = candidates[i].item;
            if (!tileItem)
                continue;
            var topLeft = tileItem.mapToItem(null, 0, 0);
            if (globalPos.x >= topLeft.x && globalPos.x < topLeft.x + tileItem.width
                && globalPos.y >= topLeft.y && globalPos.y < topLeft.y + tileItem.height) {
                return candidates[i].token;
            }
        }
        return null;
    }

    // Whether `token` names the workspace `toplevel` is CURRENTLY on — the
    // same-tile no-op check (dropping a window back where it came from).
    function tokenMatchesWorkspace(token, workspace) {
        if (!workspace)
            return false;
        if (token === "special:magic")
            return workspace.name === "special:magic";
        return workspace.id === token;
    }

    // 16-05-SUMMARY.md's confirmed root cause: HyprlandToplevel.address
    // (QML) omits the "0x" prefix hyprctl clients -j's own address field
    // carries. Normalising here, once, at the one call site that builds a
    // dispatch string, is what keeps this correct — building the selector
    // off the raw property anywhere else would silently target nothing
    // (the exact trap 16-03's own SUMMARY mis-diagnosed before 16-05 found
    // the real cause).
    function normalizeAddress(address) {
        if (!address)
            return "";
        return address.indexOf("0x") === 0 ? address : "0x" + address;
    }

    // T-16-25's mandatory guard: the address must match a strict
    // hexadecimal shape and the workspace token must be an integer 1-10 or
    // the exact scratchpad literal — checked here, at dispatch time, not
    // merely at drag start (T-16-26), so a stale value re-validates at the
    // moment it is actually used.
    function isValidWorkspaceToken(token) {
        if (token === "special:magic")
            return true;
        return typeof token === "number" && Number.isInteger(token) && token >= 1 && token <= 10;
    }

    // The one dispatch call site in this file — 16-SPIKE-FINDINGS.md's
    // DECISION locked this string verbatim (`window=`, the `address:`
    // prefix, `follow=false` for D-16-13's silence); this function
    // implements it exactly, substituting only the two validated values
    // below. No window title, appId or other client-supplied string is
    // ever concatenated here (T-16-25) — the only interpolated values are
    // the shape-checked address and the range-checked workspace token.
    function dispatchWindowMove(toplevel, token) {
        var addr = overviewWindow.normalizeAddress(toplevel.address);
        var addrValid = /^0x[0-9a-fA-F]+$/.test(addr);
        if (!addrValid || !overviewWindow.isValidWorkspaceToken(token)) {
            console.warn("overview: refusing drop dispatch — invalid address or workspace token");
            return false;
        }
        var wsLiteral = token === "special:magic" ? "\"special:magic\"" : String(token);
        var moveExpr = "hl.dsp.window.move({workspace=" + wsLiteral + ", window=\"address:" + addr + "\", follow=false})";
        Hyprland.dispatch(moveExpr);
        return true;
    }

    // A drop on a valid target that is not the source tile moves the
    // window silently and keeps the overview open (D-16-13) — the ghost
    // hides immediately, nothing to animate back to. Everything else (no
    // target, the source tile itself, or a validation failure) cancels at
    // zero cost (D-16-14): the ghost snaps home and no dispatch happens.
    // A failed dispatch gets no bespoke error UI (UI-SPEC E6 "error") — the
    // grid is a live projection of Hyprland's own event stream, so a
    // failed move simply never produces a move event and the window stays
    // where it was; reusing the cancel path here is what makes that
    // failure read as a deliberate rejection rather than a dropped input.
    function handleDragEnded(globalPos) {
        var toplevel = overviewWindow.dragToplevel;
        var token = overviewWindow.resolveDropToken(globalPos);
        var isSourceTile = token !== null && toplevel && overviewWindow.tokenMatchesWorkspace(token, toplevel.workspace);

        if (token !== null && !isSourceTile && toplevel && overviewWindow.dispatchWindowMove(toplevel, token)) {
            dragGhost.completeDrag();
            overviewWindow.dragActive = false;
            overviewWindow.dragToplevel = null;
            overviewWindow.dropTargetToken = null;
        } else {
            overviewWindow.cancelDragSession();
        }
    }

    function cancelDragSession() {
        dragGhost.cancelDrag();
        overviewWindow.dragActive = false;
        overviewWindow.dragToplevel = null;
        overviewWindow.dropTargetToken = null;
    }

    // ── Mid-drag destruction guard (16-RESEARCH.md Open Question 4) ──────
    // A window closing while its drag is in flight leaves a dangling
    // toplevel reference — the destroyed WindowThumbnail delegate itself
    // stops emitting dragMoved/dragEnded (it no longer exists), so nothing
    // would otherwise ever clear this session. This binding stays live
    // against `Hyprland.toplevels` the same way `workspaceForSlot()`
    // already does (a JS loop inside a property binding tracks every
    // property it reads as a dependency — WorkspaceTile.qml's own
    // thumbnailsWithContent comment records this same pattern), so no
    // manual per-toplevel signal wiring is needed.
    readonly property bool dragToplevelStillExists: {
        if (!overviewWindow.dragToplevel)
            return false;
        var list = Hyprland.toplevels.values;
        for (var i = 0; i < list.length; i++) {
            if (list[i] === overviewWindow.dragToplevel)
                return true;
        }
        return false;
    }

    onDragToplevelStillExistsChanged: {
        if (overviewWindow.dragActive && !overviewWindow.dragToplevelStillExists)
            overviewWindow.cancelDragSession();
    }

    // D-16-23 check 6's `overview` IPC status verb reads these off the
    // loaded Overview instance — summed across all eleven tiles so the verb
    // keeps reporting truthfully at eleven tiles as it did at one.
    readonly property int tileCount: 11
    readonly property int thumbnailCount: {
        var n = 0;
        for (var i = 0; i < rowOneRepeater.count; i++)
            n += rowOneRepeater.itemAt(i).thumbnailCount;
        for (var i = 0; i < rowTwoRepeater.count; i++)
            n += rowTwoRepeater.itemAt(i).thumbnailCount;
        return n + scratchpadTile.thumbnailCount;
    }
    readonly property int thumbnailsWithContent: {
        var n = 0;
        for (var i = 0; i < rowOneRepeater.count; i++)
            n += rowOneRepeater.itemAt(i).thumbnailsWithContent;
        for (var i = 0; i < rowTwoRepeater.count; i++)
            n += rowTwoRepeater.itemAt(i).thumbnailsWithContent;
        return n + scratchpadTile.thumbnailsWithContent;
    }

    // ── D-16-10's whole-grid permission catch (Phase 16 Plan 05 Task 2) ──
    // How many of the eleven tiles' thumbnails have reached a terminal
    // (populated or failed) capture state — summed the same way
    // thumbnailCount/thumbnailsWithContent already are above.
    readonly property int thumbnailsSettled: {
        var n = 0;
        for (var i = 0; i < rowOneRepeater.count; i++)
            n += rowOneRepeater.itemAt(i).thumbnailsSettled;
        for (var i = 0; i < rowTwoRepeater.count; i++)
            n += rowTwoRepeater.itemAt(i).thumbnailsSettled;
        return n + scratchpadTile.thumbnailsSettled;
    }

    // A ceiling, not the normal path: forces `allSettled` true even if some
    // capture's own settle timer (WindowThumbnail.qml,
    // Motion.ambientDuration * 3) somehow never fires, so a genuinely stuck
    // view cannot hide the catch below forever. In the ordinary case every
    // thumbnail settles well before this fires — a multiple of the same
    // token family, chosen with margin for eleven tiles' worth of
    // independent timers to land, not a duplicate literal.
    property bool settleCeilingReached: false

    Timer {
        id: settleCeilingTimer
        interval: Motion.ambientDuration * 6
        running: true
        repeat: false
        onTriggered: overviewWindow.settleCeilingReached = true
    }

    // Never true while anything in the grid is still pending — the term
    // that stops a merely slow grid from false-alarming the catch below.
    readonly property bool allSettled: overviewWindow.settleCeilingReached
        || overviewWindow.thumbnailsSettled === overviewWindow.thumbnailCount

    // Raised only once every capture in the grid has settled AND none of
    // them produced content — that combination is a permission problem,
    // not fifteen simultaneously-slow windows, so it is said ONCE here
    // instead of on every tile. A mix of captured and denied windows never
    // reaches this (thumbnailsWithContent > 0 in that case) — exactly what
    // keeps UI-SPEC E5's partial case per-window-only.
    readonly property bool wholeGridCatchVisible: overviewWindow.thumbnailCount > 0
        && overviewWindow.allSettled
        && overviewWindow.thumbnailsWithContent === 0

    // Named property, matching PanelDialog.qml/Dashboard.qml's own
    // panelSurfaceOpacity/drawerSurfaceOpacity precedent for a bare numeric
    // opacity constant. This is the ONE case that still covers the whole
    // surface, because a grid where every capture failed has nothing worth
    // seeing through to — unlike the ordinary case, which deliberately
    // ships no full-bleed scrim at all (round 12, above); the ordinary
    // case's own frost is instead governed by each WorkspaceTile's own
    // fill against windowrules.lua's quickshell-overview ignore_alpha
    // threshold, neither of which this plan touches.
    //
    // REVISED 0.7 -> 0.38 (D-21-26, frost unification, measured
    // 2026-08-15/16). This is the only surface-wide fill constant left in
    // this file after round 12 removed the full-bleed scrim, so it is
    // what "the overview's own fill" means for D-21-26's purposes — moved
    // to the notification family's own fill (BarRoles.notifSurface) in
    // step with windowrules.lua's quickshell-overview ignore_alpha
    // (0.25 -> 0.2, that file's own comment), staying strictly above the
    // new cutoff. Losing the former deliberate heaviness only affects the
    // rare whole-grid-capture-failure state this property gates, not the
    // ordinary overview appearance.
    readonly property color catchBase: Colours.surface
    readonly property real catchScrimOpacity: 0.38

    Rectangle {
        id: wholeGridCatch
        anchors.fill: parent
        visible: overviewWindow.wholeGridCatchVisible
        // ── Alpha in the COLOUR, not on the item (deferred-items #2) ──────
        // `opacity` on a Rectangle applies to it AND everything it parents,
        // so setting it here faded the Column below — the lock glyph, the
        // heading and the permission guidance were all drawn at 70%. The one
        // element that has to be readable was being dimmed by its own
        // backing. Identical bug to the tile identity pill fixed in 72d04cd,
        // and fixed the same way, following Dashboard.qml/PanelDialog.qml's
        // Qt.rgba(surfaceBase…, opacity) precedent: the backing stays
        // translucent, the message above it is fully opaque.
        color: Qt.rgba(overviewWindow.catchBase.r, overviewWindow.catchBase.g, overviewWindow.catchBase.b, overviewWindow.catchScrimOpacity)

        Column {
            anchors.centerIn: parent
            // Spans the same width as the numbered grid block, for visual
            // symmetry, rather than an arbitrary new magic number.
            width: gridBlock.width
            spacing: Design.spacingSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                text: "lock"
                color: Colours.onSurface
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Design.fontHeading
                font.weight: Design.weightEmphasis
                color: Colours.onSurface
                text: "Can't show live thumbnails"
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.pixelSize: Design.fontLabel
                color: Colours.onSurfaceVariant
                // Leads with what the user sees, puts the mechanism second
                // as a next step rather than a verdict (16-CONTEXT.md
                // <specifics> — the plain-language standing instruction),
                // and never claims certainty the surface cannot have
                // (T-16-21's repudiation mitigation).
                text: "Screen capture looks blocked for every window — check Hyprland's screencopy permission, then reopen the overview (Super+O)."
            }
        }
    }

    // ── Click-outside dismiss (D-10 dismissal set) — Dashboard.qml's
    //    proven click-outside/focus-loss combination, reused verbatim. ────
    HyprlandFocusGrab {
        id: grab
        windows: [ overviewWindow ]
        active: true
        onCleared: overviewWindow._beginDismiss()
    }

    // ── Content root (D-10 Esc dismiss; D-16-15/D-16-16 arrow/Enter nav) ──
    Item {
        id: content
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: overviewWindow.handleEscape()

        // Arrows move the selection (tile level or window level, gated
        // inside handleLeft/Right/Up/Down), Enter descends/activates,
        // Shift+<number> moves the window-level selection — no other key
        // is handled here (THE BOUNDARY, above: no text field of any kind
        // exists on this surface for any key to feed).
        Keys.onPressed: event => {
            if (event.modifiers & Qt.ShiftModifier) {
                var workspaceId = overviewWindow.shiftNumberToWorkspaceId(event.key);
                if (workspaceId !== null) {
                    overviewWindow.handleShiftMove(workspaceId);
                    event.accepted = true;
                    return;
                }
            }
            switch (event.key) {
            case Qt.Key_Left:
                overviewWindow.handleLeft();
                event.accepted = true;
                break;
            case Qt.Key_Right:
                overviewWindow.handleRight();
                event.accepted = true;
                break;
            case Qt.Key_Up:
                overviewWindow.handleUp();
                event.accepted = true;
                break;
            case Qt.Key_Down:
                overviewWindow.handleDown();
                event.accepted = true;
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                overviewWindow.handleEnter();
                event.accepted = true;
                break;
            }
        }

        // forceActiveFocus() is required for the key handler above to
        // actually receive events under WlrKeyboardFocus.OnDemand —
        // Dashboard.qml ships the identical mechanism, and
        // 16-SPIKE-FINDINGS.md's ONDEMAND-SUFFICIENT verdict confirmed it
        // live with zero prior pointer interaction.
        Component.onCompleted: content.forceActiveFocus()
    }
}
