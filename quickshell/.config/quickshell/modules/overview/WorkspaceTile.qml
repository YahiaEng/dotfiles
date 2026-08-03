// WorkspaceTile.qml — one workspace's live window thumbnails, its identity,
// empty state and monitor badge (Phase 16 Plan 03 Task 1, expanding the
// tracer's single-tile slice into D-16-01's fixed ten-slot numbered grid).
//
// Renders every window on `workspace` as a live thumbnail positioned and
// scaled at its real `hyprctl clients` geometry (D-16-02) — a tile is a
// true miniature of the workspace, recognisable by shape alone, not text.
// `workspace` stays a PROPERTY, never an internal `Hyprland.focusedWorkspace`
// read — the tracer's own design, unchanged, is exactly what lets
// Overview.qml instantiate ten of these against ten different resolved
// workspaces (or null, for a slot Hyprland does not yet know about)
// without touching this type at all.
//
// `isScratchpad` (D-16-05, wired by Task 2) changes exactly three things
// and nothing else: the border colour becomes Colours.tertiary (a steady,
// non-animated identity colour distinct from both the drag accent and the
// keyboard accent, so it never collides with an interactive state); the
// empty-state glyph becomes `inventory_2` instead of `apps`; and the
// identity overlay draws that same glyph instead of a numeral, since the
// scratchpad has no number. Everything else — clipping, real geometry,
// capture, click-to-focus, the occupied/unoccupied background split — is
// the numbered tiles' code path, unchanged. That sameness is what makes
// plan 16-06's drag-in and drag-out symmetric rather than a special case.
//
// Capture itself now lives entirely in WindowThumbnail.qml — this file
// instantiates one per window and reads nothing off ScreencopyView directly.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../"
import "../dashboard"

Item {
    id: root

    // The HyprlandWorkspace this tile renders, or null for an unoccupied
    // slot (a slot id Hyprland does not yet know about).
    property var workspace: null
    // The string drawn as this tile's identity — "1".."10" for numbered
    // slots.
    property string slotLabel: ""
    property real captureScale: 1
    property bool isFocusedWorkspace: false
    // D-16-05, wired by plan 16-03 Task 2 — see header note above.
    property bool isScratchpad: false

    // Multi-monitor honesty (D-16-04): a window's `at` coordinates are
    // monitor-relative in real Hyprland geometry, so they must be offset by
    // the owning monitor's own x/y before scaling into tile-local space —
    // WindowThumbnail.qml does this arithmetic itself, this type only
    // threads the monitor through.
    property var monitor: Hyprland.focusedMonitor

    // D-16-13/D-16-20: clicking a tile's empty area (behind every
    // thumbnail) focuses this tile's own workspace and closes the
    // overview.
    signal activated()
    // D-16-20's other half, Phase 16 Plan 05 Task 2: clicking a SPECIFIC
    // window thumbnail focuses that window (and its workspace) and closes
    // the overview — exact parity with what Enter on a selected window
    // will do in plan 16-07, so nothing is learned or tested twice. Carries
    // the HyprlandToplevel itself (not just an address) so Overview.qml's
    // handler can call straight into `toplevel.wayland.activate()`.
    signal windowActivated(var toplevel)

    // Phase 16 Plan 06 (D-16-12): pure relay of WindowThumbnail's own
    // three drag-lifecycle signals, added because Overview.qml's drag
    // session owns the gesture end-to-end and needs it — the tile does
    // NOT interpret these, only passes them up (see the delegate below and
    // this file's header note on isScratchpad's symmetry: a drag crossing
    // tile boundaries cannot be a tile-local concept).
    signal dragStarted(var toplevel, point globalPos, size sourceSize)
    signal dragMoved(point globalPos)
    signal dragEnded(point globalPos)

    // D-16-02: a window positioned partly offscreen, sized larger than the
    // monitor, or carrying stale coordinates must crop at the tile edge
    // instead of painting over its neighbours.
    clip: true

    // Local, non-hoisted constant — QuickToggles.qml's own `chipRadius`
    // precedent (16-UI-SPEC.md's Spacing Scale "Exceptions" note). No other
    // consumer needs a tile-scaled radius yet.
    readonly property int tileRadius: 12

    // Whether this slot has anything to show — drives the background fill
    // split and the empty-state visibility. A single source of truth so the
    // two never disagree.
    readonly property bool occupied: windowRepeater.count > 0

    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.tileRadius
        color: root.occupied ? Colours.surface : Colours.surfaceVariant
        border.width: Design.borderWidth
        border.color: root.isScratchpad ? Colours.tertiary : Colours.outline
    }

    // Whole-tile click target BEHIND the thumbnails (D-16-20's "click a
    // tile's empty area focuses the workspace" meaning). Declared before
    // the Repeater below so it paints — and, if anything above it ever
    // gains its own input handling, loses input priority to — the
    // thumbnails, not the other way around.
    MouseArea {
        anchors.fill: parent
        onClicked: root.activated()
    }

    // One WindowThumbnail per window, in model order — no sort, no
    // z-reordering, no decluttering pass. Overlapping floating windows
    // render overlapping; that is D-16-02's explicit accepted cost and the
    // reason the positions stay honest.
    //
    // D-16-20 click parity: each thumbnail owns its OWN tap target now
    // (Phase 16 Plan 06 moved this from an externally-added `MouseArea`
    // into WindowThumbnail.qml's own `TapHandler`, alongside the new drag
    // gesture — see that file's header note for why the two input models
    // could not stay split across two files). Bounded to exactly this
    // thumbnail's own real-geometry bounds (WindowThumbnail sets its own
    // x/y/width/height from the window's actual scaled position), so a tap
    // landing on the tile background BETWEEN windows still falls through
    // to root's own whole-tile MouseArea above, which means "focus this
    // workspace and close". A thumbnail in the `failed` state stays
    // tappable: the window exists and focusing it is valid even though its
    // preview is missing. An unoccupied tile has no thumbnail delegate at
    // all (the Repeater's model is empty), so drag — like tap — is simply
    // unavailable there; a structural consequence, not a guard.
    Repeater {
        id: windowRepeater
        model: root.workspace ? root.workspace.toplevels : null

        delegate: WindowThumbnail {
            id: thumbnailDelegate
            toplevel: modelData
            captureScale: root.captureScale
            monitor: root.monitor

            onActivated: root.windowActivated(thumbnailDelegate.toplevel)
            onDragStarted: (draggedToplevel, globalPos, sourceSize) => root.dragStarted(draggedToplevel, globalPos, sourceSize)
            onDragMoved: (globalPos) => root.dragMoved(globalPos)
            onDragEnded: (globalPos) => root.dragEnded(globalPos)
        }
    }

    // Empty state (D-41's vocabulary): quiet Material Symbol + nothing
    // else. No descriptive body text — inventing a caption here would be
    // new chrome the copywriting contract explicitly rules out.
    Item {
        anchors.centerIn: parent
        visible: !root.occupied
        width: emptyGlyph.implicitWidth
        height: emptyGlyph.implicitHeight

        Text {
            id: emptyGlyph
            text: root.isScratchpad ? "inventory_2" : "apps"
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.iconSizeMd
            color: Colours.onSurfaceVariant
        }
    }

    // Identity overlay: the workspace number for a numbered tile, or the
    // scratchpad's own glyph in place of a numeral — the scratchpad has no
    // number (D-16-05). Sits on a legibility-backing pill because it draws
    // over arbitrary live window imagery and must stay readable without
    // hiding what is beneath it (16-UI-SPEC.md "Typography").
    Rectangle {
        id: identityPill
        anchors {
            top: parent.top
            left: parent.left
            margins: Design.spacingSm
        }
        width: identityLabel.implicitWidth + Design.spacingXs * 2
        height: identityLabel.implicitHeight + Design.spacingXs * 2
        radius: height / 2
        color: Colours.surface
        opacity: 0.6

        Text {
            id: identityLabel
            anchors.centerIn: parent
            text: root.isScratchpad ? "inventory_2" : root.slotLabel
            font.family: root.isScratchpad ? Design.symbolFontFamily : Qt.application.font.family
            font.pixelSize: Design.fontHeading
            font.weight: Design.weightEmphasis
            color: Colours.onSurface
        }
    }

    // Focused-workspace orientation ring: deliberately a neutral role, not
    // an accent, so it never competes with the drag highlight's
    // Colours.primary or the keyboard selection's Colours.secondary that
    // later plans add.
    Rectangle {
        anchors.fill: parent
        radius: root.tileRadius
        color: "transparent"
        border.width: Design.borderWidth
        border.color: Colours.outline
        visible: root.isFocusedWorkspace
    }

    // Monitor badge: only rendered when 2+ displays are connected. This
    // host has one display, so this path is structurally present and
    // functionally unexercised — 16-UI-SPEC.md's E8 backstop truth records
    // this explicitly rather than faking a badge to make it visible.
    Rectangle {
        id: monitorBadge
        anchors {
            top: parent.top
            right: parent.right
            margins: Design.spacingSm
        }
        visible: Quickshell.screens.length > 1
        width: Math.min(badgeLabel.implicitWidth, root.width / 3) + Design.spacingXs * 2
        height: badgeLabel.implicitHeight + Design.spacingXs * 2
        radius: height / 2
        color: Colours.surfaceVariant

        Text {
            id: badgeLabel
            anchors.centerIn: parent
            width: Math.min(implicitWidth, root.width / 3)
            text: root.monitor ? root.monitor.name : ""
            font.pixelSize: Design.fontLabel
            color: Colours.onSurfaceVariant
            elide: Text.ElideRight
        }
    }

    // Aggregated live counts (D-16-23 check 6's `overview` IPC status verb
    // reads these off Overview.qml, which sums across all tiles). A JS-loop
    // binding tracks every property it reads during evaluation as a
    // dependency, so this stays live without a manual per-item signal
    // wire-up.
    readonly property int thumbnailCount: windowRepeater.count
    readonly property int thumbnailsWithContent: {
        var n = 0;
        for (var i = 0; i < windowRepeater.count; i++) {
            var item = windowRepeater.itemAt(i);
            if (item && item.hasContent)
                n++;
        }
        return n;
    }
    // Phase 16 Plan 05 Task 2: how many of this tile's thumbnails have
    // reached a terminal (populated or failed) capture state — Overview.qml
    // sums this across all eleven tiles to know when it is safe to
    // evaluate the whole-grid catch at all.
    readonly property int thumbnailsSettled: {
        var n = 0;
        for (var i = 0; i < windowRepeater.count; i++) {
            var item = windowRepeater.itemAt(i);
            if (item && item.settled)
                n++;
        }
        return n;
    }
}
