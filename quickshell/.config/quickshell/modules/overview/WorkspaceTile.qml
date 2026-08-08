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
// QtQuick.Shapes ships inside qt6-declarative, which quickshell already
// requires — deliberately NOT Qt5Compat.GraphicalEffects, whose OpacityMask
// would express the sweep ring below more directly but whose package
// (qt6-5compat) install.sh does not provision. A fresh Arch system built
// from install.sh + stow must render this surface, so the import has to come
// from something already guaranteed present (PROJECT.md's reproducibility
// constraint).
import QtQuick.Shapes
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

    // D-16-14 (Phase 16 Plan 06 Task 2): true for the ONE tile the cursor is
    // currently over during a drag, driven by Overview.qml — this tile
    // never decides for itself, it only renders whatever Overview.qml's
    // own single hit-test result says. The primary role is reserved for
    // this and nothing else in this surface (16-UI-SPEC.md "Color").
    property bool dropTargetActive: false

    // D-16-15/D-16-16 (Phase 16 Plan 07): true for the ONE tile the
    // keyboard selection is currently on, driven by Overview.qml the same
    // way dropTargetActive is — this tile never decides for itself. The
    // SECONDARY role is reserved for this and nothing else, so it never
    // collides in meaning with dropTargetActive's PRIMARY fill (an
    // outline reading "the keyboard is here", never "drop here").
    property bool keyboardSelected: false
    // Task 2: which of this tile's own windows (by windowRepeater index) is
    // window-level selected, or -1 when no window level is active for this
    // tile — Overview.qml drives this the same way, comparing its own
    // selectedTile/selectedWindow pair against this tile's identity.
    // Threaded straight to the WindowThumbnail delegate below.
    property int selectedWindowIndex: -1

    readonly property int sweepRingWidth: Design.borderWidth
    // One revolution every 6 seconds (6 x the 1000ms ambient pulse period).
    readonly property int sweepPeriodFactor: 6

    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.tileRadius
        // Same lit-tile treatment QuickToggles.qml's ToggleChip already
        // ships (fill shifts to Colours.primary, Behavior on the standard
        // motion pair) — reused verbatim rather than a second idiom
        // invented for drags (D-16-14/D-26).
        // ── An empty tile has NO fill at all (16-07 render gate, round 6) ──
        // Its interior is the frosted scrim, nothing else. This arrived in
        // three steps and the middle one is worth keeping, because each was
        // wrong for a different reason:
        //
        //   round 4 — solid Colours.surfaceVariant dropped to 0.32 alpha.
        //     Blur was still off for this layer at that point, and
        //     translucency under a blur cutoff is raw transparency rather
        //     than frost (ags-media 10-06c, wleave 09-03 both record it), so
        //     it read as unchanged.
        //   round 5 — blur restored for the quickshell-overview namespace
        //     with ignore_alpha lowered to 0.25 (windowrules.lua ~line 338).
        //     The frost was real but sat BEHIND a surfaceVariant tint, and a
        //     tint over frost mostly reads as tint: "hard to notice alongside
        //     the fill colour".
        //   round 6 — the tint is gone. What is left is exactly the frosted
        //     desktop inside a bordered frame, which is what "glassy" meant.
        //
        // ── The frost does NOT depend on this property any more ───────────
        // With no fill, an empty tile's region composites to the scrim alone
        // — Overview.qml's scrimOpacity, 0.45 — which clears the 0.25 cutoff
        // on its own. That makes scrimOpacity the single value this surface's
        // glass now hangs on: take it under 0.25 and every empty tile
        // silently degrades to unblurred transparency, with nothing in this
        // file to compensate. It is also the only softening lever left, since
        // blur STRENGTH is global (decoration:blur:size/passes) with no
        // per-layer override.
        //
        // Occupied tiles stay opaque — their fill is almost entirely covered
        // by thumbnails anyway, and keeping it solid is what makes the
        // occupied/empty distinction readable at a glance.
        color: root.dropTargetActive
            ? Colours.primary
            : (root.occupied ? Colours.surface : "transparent")
        border.width: Design.borderWidth
        border.color: root.dropTargetActive ? Colours.primary : (root.isScratchpad ? Colours.tertiary : Colours.outline)
        Behavior on color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
        Behavior on border.color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
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
            keyboardSelected: index === root.selectedWindowIndex

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
    //
    // ── Why the alpha moved into the colour (16-07 render gate, round 1) ──
    // This was `color: Colours.surface` plus `opacity: 0.6` on the Rectangle.
    // QML opacity applies to an item AND everything it parents, so the
    // NUMERAL was being drawn at 60% too — the one element that had to stay
    // legible was the one being faded, which is why the label read as hard to
    // see on occupied tiles specifically (over an empty tile there is nothing
    // behind it to lose the contrast fight with). Alpha now lives in the
    // pill's own colour, following Dashboard.qml/PanelDialog.qml's existing
    // Qt.rgba(surfaceBase…, opacity) precedent, so the backing stays
    // translucent while the numeral above it is fully opaque. The pill is
    // also darkened a little, since it no longer dims its own text.
    // ── Round 2: near-solid, after round 1 was still reported unreadable ───
    // Round 1 moved the alpha off the item and into the colour, which stopped
    // the NUMERAL being faded — necessary, but not sufficient. At 0.75 a
    // bright thumbnail still shows through enough to drag the backing toward
    // mid-grey, and mid-grey is where a Colours.onSurface numeral loses its
    // contrast from BOTH directions. The backing now reads as its own chip
    // rather than a tint over whatever happens to be behind it, and gains an
    // outline so it stays a defined shape against a light window too.
    readonly property color pillBase: Colours.surface
    readonly property real pillOpacity: 0.94

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
        color: Qt.rgba(root.pillBase.r, root.pillBase.g, root.pillBase.b, root.pillOpacity)
        // Hairline, not Design.borderWidth (3) — this is a chip outline
        // holding a shape, not a structural tile edge, and at 3px it would
        // read as a second competing ring on a tile that already has two.
        border.width: 1
        border.color: Colours.outline

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

    // Keyboard selection ring (Phase 16 Plan 07, D-16-15/D-16-16): a
    // SECONDARY-role OUTLINE, deliberately never a fill — the drag
    // highlight's Colours.primary FILL above means "drop here"; this
    // outline means "the keyboard is here".
    //
    // ── Weight, not hue, is what separates it (16-07 render gate, round 1) ─
    // The original claim above — that three distinct colour ROLES stay
    // readable when they collide — did not survive being looked at: this
    // ring and the focused-workspace ring were both exactly
    // Design.borderWidth, so they differed by hue alone, and
    // Colours.secondary against Colours.outline is not a reliable separation
    // under a matugen palette the wallpaper chooses. Reported as "not
    // distinct". Doubling the width makes the discriminator geometric, which
    // holds under EVERY generated palette including a monochrome one, and
    // insetting it keeps both rings visible at once instead of the thicker
    // one swallowing the thinner.
    // ── Keyboard-selection sweep ring (16-07 render gate, rounds 2-3) ──────
    // A colour travelling continuously around the selected tile's edge.
    // Chosen at the gate over a static outline: the two static rings were
    // distinguishable but disliked, and the selection is the one thing on
    // this surface the user is actively steering, so it earns the motion —
    // the focused-workspace ring stays deliberately quiet orientation.
    //
    // ── Why this is a real donut and not a rim behind the background ──────
    // Round 2 drew a SOLID rounded rect one ring-width larger than the tile,
    // beneath the opaque `background`, so only the overhang showed. That is a
    // legitimate technique and it does not work HERE: `root` sets
    // `clip: true` (line ~87), which WindowThumbnail.qml explicitly depends
    // on to crop thumbnails that overflow the tile, so the clip cannot be
    // lifted. Every pixel of the overhang was therefore cropped, and the only
    // sweep left visible was the notch at each corner where the background's
    // radius pulls back inside the tile bounds — reported at the gate as
    // "only the corners are visible".
    //
    // So the ring is built as a genuine annulus that lives ENTIRELY inside
    // the tile: two concentric rounded rectangles in one ShapePath under
    // OddEvenFill, which excludes the overlapping interior and leaves a band
    // exactly sweepRingWidth wide. Nothing extends past `root`, so the clip
    // never touches it, and the tile still cannot displace its neighbours.
    Shape {
        id: sweepRing
        anchors.fill: parent
        visible: root.keyboardSelected && Motion.motionEnabled
        // The default triangulating renderer re-tessellates this two-subpath
        // annulus as the gradient angle changes; CurveRenderer resolves the
        // fill per-fragment instead, which is what keeps an animated gradient
        // from shimmering along the band's inner edge.
        preferredRendererType: Shape.CurveRenderer
        // Drives the conical gradient's angle. Not animated when motion is
        // off — the static ring below takes over entirely in that case, so
        // nothing is left spinning invisibly.
        property real sweepAngle: 0
        NumberAnimation on sweepAngle {
            running: sweepRing.visible
            from: 0
            to: 360
            // ambientDuration is Motion.qml's LOOP-PERIOD token (G-15-1),
            // the one semantic pair meant for a continuous cycle rather than
            // a one-shot transition — already multiplier-scaled, so a
            // `reduced` motion scale slows this without a second knob here.
            //
            // ── Why it is multiplied (16-07 render gate, round 4) ─────────
            // The token resolves to extra-long4 (1000ms), which is a period
            // for an ambient PULSE — one full 360-degree traversal per second
            // reads as spinning, and was reported as too fast. The token
            // stays the source of truth (a `reduced` scale still slows this
            // proportionally, and retuning motion.json still moves it); the
            // named factor below converts a pulse period into a drift period
            // rather than hard-coding a duration that would drift out of
            // sync with the rest of the motion system.
            duration: Motion.ambientDuration * root.sweepPeriodFactor
            loops: Animation.Infinite
            easing.type: Easing.Linear
        }
        ShapePath {
            // Negative disables the stroke entirely — the fill IS the ring.
            strokeWidth: -1
            // Excludes the inner rectangle from the outer one, making the
            // band. Without this the shape fills solid and hides the tile.
            fillRule: ShapePath.OddEvenFill
            // Two accent roles half a turn apart, repeating the first at 1.0
            // so the loop has no visible seam where the gradient wraps.
            fillGradient: ConicalGradient {
                centerX: sweepRing.width / 2
                centerY: sweepRing.height / 2
                angle: sweepRing.sweepAngle
                GradientStop { position: 0.0; color: Colours.primary }
                GradientStop { position: 0.5; color: Colours.tertiary }
                GradientStop { position: 1.0; color: Colours.primary }
            }
            PathRectangle {
                x: 0
                y: 0
                width: sweepRing.width
                height: sweepRing.height
                radius: root.tileRadius
            }
            PathRectangle {
                x: root.sweepRingWidth
                y: root.sweepRingWidth
                width: sweepRing.width - root.sweepRingWidth * 2
                height: sweepRing.height - root.sweepRingWidth * 2
                radius: Math.max(0, root.tileRadius - root.sweepRingWidth)
            }
        }
    }

    // ── Reduced-motion fallback for the sweep ring above ──────────────────
    // Round 1 doubled this ring's width so weight, not hue, separated it from
    // the focused-workspace ring — that separation was confirmed at the gate
    // and is kept here verbatim. Round 2 then narrowed its ROLE: the sweep
    // ring is the selection indicator whenever motion is on, and this draws
    // only when it is off, so the two are never on screen together and
    // `Motion.motionEnabled: false` still leaves the selection unmistakable.
    Rectangle {
        anchors.fill: parent
        anchors.margins: Design.borderWidth
        radius: root.tileRadius - Design.borderWidth
        color: "transparent"
        border.width: Design.borderWidth * 2
        border.color: Colours.secondary
        visible: root.keyboardSelected && !Motion.motionEnabled
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
