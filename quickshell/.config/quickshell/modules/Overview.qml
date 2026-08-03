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
                    onActivated: overviewWindow.activateTile(workspace)
                    onWindowActivated: (toplevel) => overviewWindow.activateWindow(toplevel)
                    onDragStarted: (toplevel, globalPos, sourceSize) => overviewWindow.handleDragStarted(toplevel, globalPos, sourceSize)
                    onDragMoved: (globalPos) => overviewWindow.handleDragMoved(globalPos)
                    onDragEnded: (globalPos) => overviewWindow.handleDragEnded(globalPos)
                }
            }
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

    DragGhost {
        id: dragGhost
    }

    function handleDragStarted(toplevel, globalPos, sourceSize) {
        overviewWindow.dragToplevel = toplevel;
        overviewWindow.dragActive = true;
        overviewWindow.dragPos = globalPos;
        dragGhost.beginDrag(toplevel, globalPos, sourceSize);
    }

    function handleDragMoved(globalPos) {
        overviewWindow.dragPos = globalPos;
        dragGhost.moveTo(globalPos);
    }

    // Task 1's own shape: every release cancels — there is no drop-target
    // resolution or move dispatch yet, only the ghost's own lifecycle.
    // (Plan 16-06 Task 2 replaces this body with the real hit-test +
    // dispatch-or-cancel logic; the session-teardown lines below stay
    // shared via cancelDragSession().)
    function handleDragEnded(globalPos) {
        overviewWindow.cancelDragSession();
    }

    function cancelDragSession() {
        dragGhost.cancelDrag();
        overviewWindow.dragActive = false;
        overviewWindow.dragToplevel = null;
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

    // ── Content root (D-10 Esc dismiss) ──────────────────────────────────
    Item {
        id: content
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: overviewWindow.dismissRequested()

        // forceActiveFocus() is required for the key handler above to
        // actually receive events under WlrKeyboardFocus.OnDemand —
        // Dashboard.qml ships the identical mechanism, and
        // 16-SPIKE-FINDINGS.md's ONDEMAND-SUFFICIENT verdict confirmed it
        // live with zero prior pointer interaction.
        Component.onCompleted: content.forceActiveFocus()
    }
}
