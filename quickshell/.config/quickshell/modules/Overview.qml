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
    signal dismissRequested()

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
    // transparency (ags-media's own documented past mistake, reproduced
    // firsthand rather than assumed). `LayerRule`'s only blur field is a
    // boolean (`hl.meta.lua` line 551); blur intensity has no per-surface
    // knob at all — "turn it down" has exactly one honest answer for this
    // architecture: off. windowrules.lua now pulls D-16-06's own
    // pre-authorized fallback lever #1 (`blur = false`, exact-match
    // override on `quickshell-overview`) instead of chasing an alpha value
    // that either does nothing (above 0.5) or breaks blur outright (below
    // it). With blur off for this namespace, the `ignore_alpha` floor is
    // moot here, so this alpha is free to read as a plain, deliberate tint
    // rather than a frost — 0.45, screenshot-compared before shipping.
    // Named as a property (not an anonymous literal) matching
    // PanelDialog.qml/Dashboard.qml's own panelSurfaceOpacity/
    // drawerSurfaceOpacity convention — a bare numeric opacity constant is
    // established precedent in this repo, not a zero-hex/motion-lint
    // violation (Design.qml carries no opacity token; neither sibling file
    // sources this value from Colours/Design either).
    readonly property real scrimOpacity: 0.45

    // Full-bleed scrim (D-16-06) — the tiles are the content here, the
    // scrim is context, not cover (16-UI-SPEC.md "Color" section).
    Rectangle {
        anchors.fill: parent
        color: Colours.surface
        opacity: overviewWindow.scrimOpacity
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
    function activateTile(workspace) {
        if (workspace)
            workspace.activate();
        overviewWindow.dismissRequested();
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
        overviewWindow.dismissRequested();
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
    // type here would be a second "type to find a thing" surface competing
    // with walker (REQUIREMENTS.md's OVER-05 exclusion). T-16-34 enforces
    // this mechanically via the acceptance grep, not by convention alone —
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
    // source-visible modulo over the eleven-slot count, which is also
    // what makes "Right eleven times returns to the start" provable by
    // inspection rather than by trusting a loop. Edge-stop (clamping
    // instead of wrapping) is the one-line fallback if Task 3's render
    // gate finds the row-crossing jump reads as unnatural — replace the
    // modulo with Math.max(0, Math.min(10, selectedTile + delta)).
    function moveLinear(delta) {
        overviewWindow.selectedTile = (overviewWindow.selectedTile + delta + 11) % 11;
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
    // Down on tile level DESCENDS instead of jumping a row when the current
    // tile has windows (D-16-16: "Enter (or Down) drops into a tile that
    // has windows") — the row-jump only fires for an empty tile, where
    // there is nothing to descend into.
    function handleDown() {
        if (overviewWindow.selectedWindow >= 0) {
            overviewWindow.moveWindowSelection(1);
            return;
        }
        var tops = overviewWindow.toplevelsForSlot(overviewWindow.selectedTile);
        if (tops.length > 0) {
            overviewWindow.selectedWindow = 0;
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
        overviewWindow.activateTile(overviewWindow.slotWorkspace(index));
    }

    // Maps Shift+<number> to the workspace id the existing Super+Shift+N
    // Hyprland binds already use (keybinds.lua lines 227-236) — 1-9 map to
    // themselves, 0 maps to 10. Returns null for any other key so the
    // caller can tell "not a workspace-number key" apart from "workspace 0",
    // which does not exist.
    function shiftNumberToWorkspaceId(key) {
        if (key === Qt.Key_0)
            return 10;
        if (key >= Qt.Key_1 && key <= Qt.Key_9)
            return key - Qt.Key_0;
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
    readonly property string modeIndicatorText: overviewWindow.selectedWindow >= 0
        ? `Workspace ${overviewWindow.modeIndicatorLabel} windows`
        : "Tiles"

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
        overviewWindow.dismissRequested();
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
                    onActivated: overviewWindow.activateTile(workspace)
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
                    onActivated: overviewWindow.activateTile(workspace)
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
        onActivated: overviewWindow.activateTile(workspace)
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

    // Named property, matching PanelDialog.qml/this file's own
    // `scrimOpacity` precedent for a bare numeric opacity constant — a
    // bit darker than the base scrim so the message reads as sitting on
    // its own layer above the (non-rendering) grid beneath it.
    readonly property real catchScrimOpacity: 0.7

    Rectangle {
        id: wholeGridCatch
        anchors.fill: parent
        visible: overviewWindow.wholeGridCatchVisible
        color: Colours.surface
        opacity: overviewWindow.catchScrimOpacity

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
        onCleared: overviewWindow.dismissRequested()
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
