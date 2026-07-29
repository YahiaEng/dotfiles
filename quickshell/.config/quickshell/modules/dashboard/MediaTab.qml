// MediaTab.qml — the MD3 full player (Phase 14 Plan 05, D-35): cover art,
// title/artist/album type stack, seek slider, Material Symbols transport,
// volume row, player-switcher chips, and the D-41 in-place empty register.
//
// Root type Item, filled via anchors.fill: parent by the Loader Dashboard.qml
// places it in — actual rendered geometry always matches whatever size its
// Loader currently has, including mid-resize-animation.
//
// `implicitWidth`/`implicitHeight` below are D-04's "no implicit size"
// prohibition, deliberately reversed at 14-03's render gate (checkpoint
// feedback 2026-07-29, see 14-03-SUMMARY.md's Deviations): Dashboard.qml
// reads these as an advisory hint to compute the drawer's own animated frame
// target — a pure metadata read, independent of this item's actual rendered
// size. They are derived from this file's own layout's natural size.
//
// ── Design constants — NOT read off `dashboardWindow` ───────────────────
// Same mechanism gap QuickToggles.qml's header already records: `id`-based
// lookup in QML is lexical to the declaring FILE, and `MediaTab` is a
// separate registered component type instantiated inside `dashboardWindow`'s
// object tree, not textually nested inside Dashboard.qml — so a bare
// `dashboardWindow.spacingLg`-style reference from this file would not
// resolve. Per 14-05-PLAN.md's own fallback instruction, this file declares
// its own copies of exactly the constants it needs, sourced from
// 14-UI-SPEC.md's Spacing Scale/Typography tables and 14-02-SUMMARY.md's
// recorded font family/FILL-axis verdict — consolidating every tab onto one
// shared constants surface is left to 14-08's composition pass.
//
// D-41 widget-state register — "populated" / "pending" / "empty" — carried
// on every one of this phase's nine modules/dashboard/ files. This tab is
// ONE layout with two content states (D-41's whole point): every slot below
// occupies the same space and sits at the same position whether or not a
// player exists — there is no separate empty screen.
//
// ── Render-gate round 1 redesign (2026-07-29) ────────────────────────────
// Round 1's vertical single-column player was REJECTED at the render gate:
// "I am not a fan of the media tab design. Copy caelestia's look instead,
// it looks more aesthetically pleasing." This file's visual layer (layout,
// typography hierarchy, control shapes) is now redrawn against the real
// source of github.com/caelestia-dots/shell's
// `modules/dashboard/Media.qml` + `modules/dashboard/media/{Details,
// CoverVisualiser}.qml`, studied via a shallow clone rather than guessed
// from a screenshot. The DATA layer (MediaBackend, the mutator dispatch,
// the D-41 register, the must_haves this plan's frontmatter locks) is
// UNCHANGED — the directive was about the look, not the architecture:
//
//   - Art-left / details-right split (Caelestia's `RowLayout(
//     CoverVisualiser | Details)`), replacing the earlier stacked column —
//     this is the layout signature that most reads as "instrument" rather
//     than "bigger copy of the ambient card" (Task 3 gate check 1).
//   - Title promoted from the body role to the heading role (this plan's
//     own recorded headroom clause: "a one-constant change that stays
//     inside the four declared roles"); album tinted with the `secondary`
//     role rather than `onSurfaceVariant`, mirroring Caelestia's own
//     title/artist/album weight-and-tint hierarchy (`Details.qml`).
//   - The cover-art placeholder now sits inside its own filled circular
//     badge (`primaryContainer`/`onPrimaryContainer`), echoing Caelestia's
//     `MaterialShape.ClamShell` empty-state icon container — approximated
//     as a plain filled circle since this repo has no MaterialShape/M3Shapes
//     library, never transplanted as a literal shape import.
//   - Transport restyled to Caelestia's tonal-icon-button convention:
//     previous/next sit on a filled `surfaceVariant` disc instead of a bare
//     glyph, and play/pause becomes a wide pill (`Caelestia`'s
//     `fillWidth` capsule) rather than a plain larger circle.
//
// Two features Caelestia's own Media view carries were deliberately NOT
// transplanted, and are recorded here rather than half-built:
//   - Shuffle/repeat transport buttons: `media-players.sh cmd`'s allowlist
//     (D-35 fence 2, byte-unchanged this phase) is exactly play-pause /
//     next / previous / seek / volume — there is no shuffle or loop verb to
//     dispatch, so no button is drawn for either.
//   - The cava-driven cover-art audio visualiser ring and the decorative
//     `BackgroundShapes` bokeh layer: both depend on services/shape
//     libraries this repo does not have (a cava audio service, an
//     `M3Shapes`-style path renderer) and neither is a must_haves truth —
//     out of scope per this plan's own "map onto MediaBackend's existing
//     capabilities, or note as out of scope" instruction.
//   - The lyrics panel (`LyricsAndSelector`/`LyricList`): no lyrics service
//     exists anywhere in this repo's backend; not attempted.
//   - The player switcher stays chips (this plan's own locked artifact,
//     `playerChipRow`/`PlayerChip`), not Caelestia's dropdown `SplitButton`
//     — the must_haves/artifacts table names chips explicitly and the
//     redesign directive is about visual language, not swapping this
//     already-decided widget shape.
//     [SUPERSEDED round 3 below — the chip row itself was named as one of
//     the two things that still look wrong.]
//
// ── Render-gate round 3 refinement (2026-07-29) ──────────────────────────
// Round 2 was accepted as "a step in the right direction" but rejected as
// not yet matching latest Caelestia, on two named points. Re-studied via a
// FRESH shallow clone of github.com/caelestia-dots/shell (round 1's clone
// was discarded) — the exact files read this round:
// `modules/dashboard/media/CoverVisualiser.qml`,
// `components/widgets/CoverArt.qml`, `modules/dashboard/media/Details.qml`,
// `modules/dashboard/media/LyricsAndSelector.qml`,
// `modules/dashboard/Media.qml`, `plugin/src/Caelestia/Config/
// serviceconfig.hpp` (visualiserBars default = 60).
//
//   1. **Cover art — circular with a dotted ring.** Real Caelestia's cover
//      (`CoverArt.qml`) is an M3 "Cookie12Sided" blob shape, not a plain
//      circle, wrapped by `CoverVisualiser.qml`'s `Shape` of 60
//      (`visualiserBars`) individual radial `ShapePath` bars — one per
//      audio-frequency band read from `Audio.cava`, each bar's length a
//      function of that band's live amplitude (`bar.value`), each
//      permanently at least a `1e-2 * maxMagnitude` sliver even at silence.
//      That "ring" is therefore an idle-state audio visualiser, not a
//      decorative border, and its host M3Shapes cookie geometry has no
//      equivalent in this repo (no `M3Shapes` import, no `Caelestia.Config`).
//      The human's feedback asks for something rounder and dotted, closer
//      to the ring's own idle silhouette than to the cookie-blob host shape
//      underneath it — the art below is redrawn as a genuine circle
//      (radius = half its diameter, not the round-corner-rectangle radius
//      round 2 used) with a static dashed circle drawn around it via
//      `QtQuick.Shapes`' `ShapePath`/`PathAngleArc` (`strokeStyle:
//      ShapePath.DashLine`, `capStyle: ShapePath.RoundCap`), dash/gap tuned
//      to land near 56 marks — close to upstream's 60-bar density at this
//      radius. This repo has no cava/audio-analysis service anywhere in its
//      backend (MediaBackend's whole read surface is media-status.sh /
//      media-players.sh — no audio signal exists to sample), so the ring is
//      deliberately static rather than amplitude-reactive: an honest
//      approximation of the idle silhouette, not a fake live signal. For
//      the same reason it is NOT wired as a seek/progress arc either — real
//      Caelestia's ring answers to audio amplitude, never to track
//      position, so doubling it as a progress indicator would not actually
//      match upstream's behaviour. The straight seek slider below stays the
//      one real seek control (this plan's own locked must_have). Colour is
//      `Colours.outline` rather than Caelestia's literal `m3primary` tint —
//      14-UI-SPEC.md's Color section reserves the primary/accent role for
//      an enumerated list (tab indicator, lit toggle chips, active
//      motion-scale segment, play/pause pressed state, calendar "today",
//      pending-pulse) and explicitly forbids using it as "a general
//      interactive-element default"; a decorative frame is exactly that
//      general case, so `outline` — the role literally named for a frame —
//      is the spec-compliant substitute for this tab's borrowed accent.
//
//   2. **The media-source pill, redesigned.** Real Caelestia's player
//      switcher (`LyricsAndSelector.qml`) is not a row of always-visible
//      chips at all: it is one compact `SplitButton` (`type:
//      SplitButton.Tonal`) showing the active player's identity, opening a
//      small checkmark menu of every player on tap
//      (`Players.manualActive = item.modelData`) — exactly the "subtle
//      SplitButton" this repo's render-gate feedback independently proposed
//      before this file was re-checked against upstream, confirming the
//      shape rather than guessing it. Round 2's always-visible full-width
//      chip row is REPLACED by a single compact pill (an icon plus the
//      active player's elided label, sized to content rather than the full
//      row width) that opens a small anchored dropdown list of every
//      player on tap. This is this file's own build of the same
//      interaction on house tokens — no `Caelestia.Components`/
//      `SplitButton` import exists here — not a transplanted control.
//      Round 2's header note that "the player switcher stays chips ...
//      the must_haves/artifacts table names chips explicitly" is
//      SUPERSEDED: this round's human feedback explicitly rescinds that
//      choice where it conflicts with looking right ("a minimal equivalent
//      on house tokens is fine"). The underlying mechanism is unchanged —
//      every row still calls `mediaBackend.selectPlayer(id)`, the same
//      function round 1 and round 2 both dispatched through — so
//      multi-player switching keeps working end to end; only the
//      always-visible-row presentation is gone.
import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import "../"

Item {
    id: root

    anchors.fill: parent

    // ── Constants mirrored from 14-UI-SPEC.md (see header comment above —
    //    this file cannot reach dashboardWindow's copies). ────────────────
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 16
    readonly property int panelPadding: 24 // 14-UI-SPEC.md Spacing Scale "lg"
    // Section separation between the art column and the details column —
    // same "lg" token as panelPadding (UI-SPEC: "lg... section separation"),
    // named distinctly here for what it's doing rather than reusing
    // panelPadding's own name for a different purpose.
    readonly property int sectionGap: root.panelPadding

    readonly property int fontHeading: 20
    readonly property int fontBody: 16
    readonly property int fontLabel: 12
    readonly property int weightEmphasis: Font.DemiBold
    readonly property int weightBody: Font.Normal

    readonly property int iconSizeMd: 24
    // Exact installed family string, per 14-02-SUMMARY.md's registration.
    readonly property string symbolFontFamily: "Material Symbols Rounded"
    // 14-02-SUMMARY.md's live-measured verdict: `fill-axis-renders` — Qt
    // 6.11.1 genuinely drives this font's FILL variable axis on this build.
    // If a future build ever regresses this, flip this one property to fix
    // the lit-state language back to a static glyph weight.
    readonly property bool fillAxisAvailable: true

    // ── This tab's own layout constants ─────────────────────────────────
    // Caelestia's art-left/details-right split (see header) — art is a
    // fixed square on the left, the details column holds everything else
    // and gets whatever width the drawer's own floor/content negotiation
    // (Dashboard.qml's activeContentWidth, D-02/D-04 superseded) leaves it.
    readonly property int artSize: 220
    // Round 3: `artSize` above is now the whole SLOT's bounding box (the
    // layout anchor other bands measure against, unchanged from round 2);
    // the circular art itself is `artCircleSize`, shrunk to leave room
    // inside that same box for the dotted ring drawn around it — the
    // slot's footprint against the rest of the layout does not move.
    readonly property int ringGap: 8
    readonly property int ringStrokeWidth: 3
    readonly property int artCircleSize: root.artSize - (root.ringGap + root.ringStrokeWidth) * 2
    readonly property real ringRadius: root.artCircleSize / 2 + root.ringGap
    readonly property int artBadgeSize: Math.round(root.artCircleSize * 0.42)
    readonly property int detailsWidth: 340
    readonly property int controlRowHeight: 32
    readonly property int playerSelectorHeight: 36
    readonly property int playerMenuRowHeight: 32
    readonly property int timeLabelWidth: 36
    readonly property int transportSize: 44
    readonly property int transportEmphasizedSize: 60
    // Play/pause's pill width — Caelestia's `fillWidth` capsule convention:
    // wider than tall, fully rounded ends, rather than a plain larger disc.
    readonly property int transportPillWidth: Math.round(root.transportEmphasizedSize * 1.6)

    // D-41 register vocabulary, carried for register consistency across
    // every modules/dashboard/ file (same precedent as QuickToggles.qml).
    readonly property var widgetStateVocabulary: ["populated", "pending", "empty"]
    // Mirrors the backend's own register so the D-41 vocabulary reads the
    // same from either file.
    readonly property string widgetState: root.mediaBackend ? root.mediaBackend.widgetState : "empty"

    property var mediaBackend: null

    // Advisory content-driven size hint (D-04 superseded) — read by
    // Dashboard.qml's activeContentWidth/activeContentHeight, not by this
    // item's own actual rendered geometry (still anchors.fill: parent
    // above). The natural (unstretched) width is art + gap + the details
    // column's own declared width; height follows the taller of the art
    // slot and the details column reactively, so a band that disappears
    // (the volume row, when the active player exposes no volume) is
    // reflected honestly rather than left as a stale estimate.
    implicitWidth: root.artSize + root.sectionGap + root.detailsWidth + root.panelPadding * 2
    implicitHeight: content.height + root.panelPadding * 2

    readonly property bool hasPlayer: root.mediaBackend ? root.mediaBackend.hasPlayer : false

    function _formatTime(totalSeconds) {
        var s = Math.max(0, Math.floor(totalSeconds || 0));
        var m = Math.floor(s / 60);
        var sec = s % 60;
        return m + ":" + (sec < 10 ? "0" + sec : sec);
    }

    // Drag-suppression flag (the seek band's own truth-driven exception):
    // while dragging, the slider stops following the incoming one-second
    // stream tick, and on release issues one seek through the backend.
    property bool seekDragging: false

    // ── One layout, two content states — the whole of D-41 ──────────────
    // Art-left / details-right, per the redesign header above. Both
    // columns share this Item's vertical center so a short details column
    // (no volume band) still reads as balanced against the fixed art slot.
    Item {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.panelPadding
        height: Math.max(artSlot.height, detailsColumn.height)

        // ── 1. Cover art — fixed square, left column ────────────────────
        Item {
            id: artSlot
            width: root.artSize
            height: root.artSize
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            // Round 3: the static dotted ring, drawn once around the
            // circular art below at `ringRadius` (the art's own radius
            // plus `ringGap`) — see the redesign header for why this is a
            // plain dashed circle rather than a live cava visualiser or a
            // seek/progress arc. Declared before `artContainer` so it sits
            // behind it in paint order, matching Caelestia's own
            // Shape-then-CoverArt sibling order (the two never actually
            // overlap since the ring's radius is strictly outside the
            // art's own). Static geometry — repaints only on resize or a
            // theme-driven colour change, never per frame while idle.
            Shape {
                id: artRing
                anchors.fill: parent
                asynchronous: true
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    id: artRingPath
                    fillColor: "transparent"
                    strokeColor: Colours.outline
                    strokeWidth: root.ringStrokeWidth
                    capStyle: ShapePath.RoundCap
                    strokeStyle: ShapePath.DashLine
                    // Dash length ~= strokeWidth (a round dot under
                    // RoundCap), gap wide enough that each mark reads as
                    // separate rather than a solid ring. At this radius the
                    // pattern lands near 56 marks — close to upstream's
                    // fixed 60-bar visualiser density (`visualiserBars`
                    // default, `serviceconfig.hpp`) without depending on
                    // any bar count this repo has no audio service to
                    // supply.
                    dashPattern: [1, 3]

                    startX: artSlot.width / 2 + root.ringRadius
                    startY: artSlot.height / 2

                    PathAngleArc {
                        centerX: artSlot.width / 2
                        centerY: artSlot.height / 2
                        radiusX: root.ringRadius
                        radiusY: root.ringRadius
                        startAngle: 0
                        sweepAngle: 360
                    }

                    Behavior on strokeColor {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }
                }
            }

            Rectangle {
                id: artContainer
                anchors.centerIn: parent
                width: root.artCircleSize
                height: root.artCircleSize
                radius: width / 2
                clip: true
                color: Colours.surfaceVariant

                Image {
                    id: artImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    // media-art-resolve.sh's `http(s)://` branch keys its
                    // on-disk cache path off a sha256 of the FULL url, so
                    // that path genuinely is stable per-track. Its
                    // `file://` branch instead passes the third-party
                    // player's own path straight through with no
                    // repo-owned cache-path guarantee of its own — the
                    // payload's `art` field never reveals which branch
                    // produced it, so the two cannot be told apart here.
                    // Firefox's own MPRIS art-thumbnail file (the case
                    // observed live on this machine) is outside this
                    // repo's control, and a wrongly-cached reused path
                    // would show the previous track's art — a failure that
                    // reads as a metadata bug, not a caching one. `cache:
                    // false` is therefore the universally-safe choice:
                    // it never shows stale art, and the only cost is a
                    // redundant decode of bytes the resolver script (and,
                    // for `file://`, the player itself) already cached on
                    // disk.
                    cache: false
                    source: (root.mediaBackend && root.mediaBackend.artPath) ? ("file://" + root.mediaBackend.artPath) : ""
                }

                // Quiet placeholder — shows while loading, when the art
                // path is empty, and when the image fails to load. Three
                // cases, one visual, zero layout shift: whenever the image
                // is not in its Ready state, this badge is what occupies
                // the slot. The filled circular badge (rather than a bare
                // glyph directly on the surface-variant container) is this
                // redesign's echo of Caelestia's `MaterialShape.ClamShell`
                // empty-state icon container, approximated with a plain
                // circle since this repo carries no M3Shapes-style path
                // renderer.
                Rectangle {
                    id: artPlaceholderBadge
                    anchors.centerIn: parent
                    visible: artImage.status !== Image.Ready
                    width: root.artBadgeSize
                    height: root.artBadgeSize
                    radius: width / 2
                    color: Colours.primaryContainer

                    Text {
                        id: artPlaceholder
                        anchors.centerIn: parent
                        text: "music_note"
                        font.family: root.symbolFontFamily
                        font.pixelSize: root.artBadgeSize * 0.52
                        color: Colours.onPrimaryContainer
                    }
                }
            }
        }

        // ── 2-6. Details column — type stack, seek, transport, volume,
        //    switcher chips, all to the right of the art slot ───────────
        Column {
            id: detailsColumn
            anchors.left: artSlot.right
            anchors.leftMargin: root.sectionGap
            anchors.right: parent.right
            anchors.verticalCenter: artSlot.verticalCenter
            spacing: root.spacingMd

            // ── 2. Type stack — fixed height, per-field fallbacks ───────
            Column {
                id: typeStack
                width: parent.width
                height: titleLine.height + artistLine.height + albumLine.height + root.spacingXs * 2
                spacing: root.spacingXs

                Text {
                    id: titleLine
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.hasPlayer ? (root.mediaBackend.displayTitle || "") : "Nothing playing"
                    font.pixelSize: root.hasPlayer ? root.fontHeading : root.fontBody
                    font.weight: root.hasPlayer ? root.weightEmphasis : root.weightBody
                    color: root.hasPlayer ? Colours.onSurface : Colours.onSurfaceVariant
                }
                // Artist/album stay structurally present (default `visible:
                // true`) rather than toggling `visible` directly — a Column
                // positioner excludes an invisible child from layout entirely,
                // which would shift the sibling below it upward and collapse
                // the reserved slot, the opposite of D-41's "hidden without
                // collapsing" rule. An empty `text` renders nothing but keeps
                // occupying its normal line-height slot, which is the actual
                // in-place-hide behaviour this block needs.
                Text {
                    id: artistLine
                    width: parent.width
                    elide: Text.ElideRight
                    text: (root.hasPlayer && root.mediaBackend.displayArtist !== "") ? root.mediaBackend.displayArtist : ""
                    font.pixelSize: root.fontBody
                    font.weight: root.weightBody
                    color: Colours.onSurfaceVariant
                }
                // Album is tinted with the `secondary` role rather than
                // `onSurfaceVariant` — mirroring Caelestia's own
                // title/artist/album hierarchy (`media/Details.qml`:
                // title on-surface, artist on-surface-variant, album
                // secondary), a distinguishing accent rather than a third
                // shade of grey.
                Text {
                    id: albumLine
                    width: parent.width
                    elide: Text.ElideRight
                    text: (root.hasPlayer && root.mediaBackend.displayAlbum !== "") ? root.mediaBackend.displayAlbum : ""
                    font.pixelSize: root.fontLabel
                    font.weight: root.weightBody
                    color: Colours.secondary
                }
            }

            // ── 3. Seek band — present-but-disabled when unseekable ─────
            Row {
                id: seekRow
                width: parent.width
                height: root.controlRowHeight
                spacing: root.spacingSm

                Text {
                    id: elapsedLabel
                    width: root.timeLabelWidth
                    height: parent.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    text: root._formatTime(root.mediaBackend ? root.mediaBackend.positionSeconds : 0)
                    font.pixelSize: root.fontLabel
                    color: Colours.onSurfaceVariant
                }

                Slider {
                    id: seekSlider
                    width: seekRow.width - elapsedLabel.width - totalLabel.width - root.spacingSm * 2
                    height: parent.height
                    from: 0
                    to: Math.max(1, root.mediaBackend ? root.mediaBackend.lengthSeconds : 1)
                    value: root.seekDragging ? seekSlider.value : (root.mediaBackend ? root.mediaBackend.positionSeconds : 0)
                    enabled: root.hasPlayer && root.mediaBackend.canSeek
                    onPressedChanged: {
                        if (pressed) {
                            root.seekDragging = true;
                        } else if (root.seekDragging) {
                            root.seekDragging = false;
                            if (root.mediaBackend)
                                root.mediaBackend.seekTo(seekSlider.value);
                        }
                    }

                    background: Rectangle {
                        x: seekSlider.leftPadding
                        y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                        width: seekSlider.availableWidth
                        height: 4
                        radius: 2
                        color: Colours.surfaceVariant
                        opacity: seekSlider.enabled ? 1 : 0.38

                        Rectangle {
                            width: seekSlider.visualPosition * parent.width
                            height: parent.height
                            radius: parent.radius
                            color: Colours.primary
                        }
                    }
                    handle: Rectangle {
                        x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                        y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                        width: 16
                        height: 16
                        radius: 8
                        color: Colours.primary
                        opacity: seekSlider.enabled ? 1 : 0.38
                    }
                }

                Text {
                    id: totalLabel
                    width: root.timeLabelWidth
                    height: parent.height
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    text: root._formatTime(root.mediaBackend ? root.mediaBackend.lengthSeconds : 0)
                    font.pixelSize: root.fontLabel
                    color: Colours.onSurfaceVariant
                }
            }

            // ── 4. Transport row — previous / play-pause / next ─────────
            // Caelestia's tonal-icon-button convention: previous/next sit
            // on a filled `surfaceVariant` disc rather than a bare glyph
            // (a `pillShape: false` TransportButton), and play/pause is a
            // wide filled pill rather than a plain larger disc
            // (`pillShape: true`) — Caelestia's own `fillWidth` capsule.
            component TransportButton: Item {
                id: btn

                property string glyph: ""
                property bool emphasized: false
                property bool pillShape: false
                property bool controlEnabled: true
                property bool pressedState: false
                signal activated()

                readonly property int diameter: emphasized ? root.transportEmphasizedSize : root.transportSize
                width: pillShape ? root.transportPillWidth : diameter
                height: diameter

                // D-22's truth-driven rule: only the glyph choice (bound by the
                // caller to the backend's playing predicate) reflects real
                // state. This fillProgress is purely an instant MD3 press
                // acknowledgment on the emphasized control, never a truth
                // signal itself.
                property real fillProgress: (btn.emphasized && root.fillAxisAvailable && btn.pressedState) ? 1 : 0
                Behavior on fillProgress {
                    enabled: Motion.motionEnabled
                    NumberAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }

                Rectangle {
                    id: circle
                    anchors.fill: parent
                    radius: height / 2
                    clip: true
                    // Previous/next are tonal now (surface-variant filled
                    // disc) rather than transparent — Caelestia's
                    // `IconButton.Tonal` convention — so every transport
                    // control reads as a designed button rather than a
                    // bare floating glyph.
                    color: btn.emphasized ? Colours.primary : Colours.surfaceVariant
                    opacity: btn.controlEnabled ? 1 : 0.38
                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }

                    Rectangle {
                        id: rippleCircle
                        width: 0
                        height: 0
                        radius: width / 2
                        color: btn.emphasized ? Colours.onPrimary : Colours.onSurface
                        opacity: 0
                    }

                    Text {
                        anchors.centerIn: parent
                        text: btn.glyph
                        font.family: root.symbolFontFamily
                        font.pixelSize: btn.emphasized ? root.iconSizeMd + 8 : root.iconSizeMd
                        font.variableAxes: root.fillAxisAvailable ? { "FILL": btn.fillProgress } : ({})
                        color: btn.emphasized ? Colours.onPrimary : Colours.onSurfaceVariant
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        enabled: btn.controlEnabled
                        onPressed: (mouse) => {
                            btn.pressedState = true;
                            if (!Motion.motionEnabled)
                                return;
                            const d = Math.max(circle.width, circle.height) * 2;
                            rippleCircle.x = mouse.x - d / 2;
                            rippleCircle.y = mouse.y - d / 2;
                            rippleCircle.width = 0;
                            rippleCircle.height = 0;
                            rippleCircle.opacity = 0.16;
                            rippleGrowAnim.stop();
                            rippleFadeAnim.stop();
                            rippleGrowAnim.to = d;
                            rippleGrowAnim.start();
                        }
                        onReleased: btn.pressedState = false
                        onCanceled: btn.pressedState = false
                        onClicked: btn.activated()

                        NumberAnimation {
                            id: rippleGrowAnim
                            target: rippleCircle
                            properties: "width,height"
                            duration: Motion.emphasizedInDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.emphasizedInEasing
                            onFinished: rippleFadeAnim.start()
                        }
                        NumberAnimation {
                            id: rippleFadeAnim
                            target: rippleCircle
                            property: "opacity"
                            to: 0
                            duration: Motion.emphasizedOutDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.emphasizedOutEasing
                        }
                    }
                }
            }

            Item {
                id: transportRowSlot
                width: parent.width
                height: root.transportEmphasizedSize

                Row {
                    id: transportRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: root.transportEmphasizedSize
                    spacing: root.spacingMd

                    TransportButton {
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: "skip_previous"
                        emphasized: false
                        controlEnabled: root.hasPlayer
                        onActivated: if (root.mediaBackend) root.mediaBackend.previousTrack()
                    }
                    TransportButton {
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: (root.mediaBackend && root.mediaBackend.playing) ? "pause" : "play_arrow"
                        emphasized: true
                        pillShape: true
                        controlEnabled: root.hasPlayer
                        onActivated: if (root.mediaBackend) root.mediaBackend.playPause()
                    }
                    TransportButton {
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: "skip_next"
                        emphasized: false
                        controlEnabled: root.hasPlayer
                        onActivated: if (root.mediaBackend) root.mediaBackend.nextTrack()
                    }
                }
            }

            // ── 5. Volume band — ABSENT (not disabled) with no volume ───
            // A real player-capability limit signalled by the payload's own
            // sentinel, asymmetric with the seek band's present-but-disabled
            // treatment above — recorded here rather than left to look like
            // an inconsistency. Caelestia's own Media view has no volume
            // control at all in this pane; this repo's must_haves require
            // one whenever the payload signals `hasVolume`, so the band
            // stays, restyled onto the same pill/tonal language as the
            // rest of this redesign.
            Row {
                id: volumeRow
                width: parent.width
                height: root.controlRowHeight
                spacing: root.spacingSm
                visible: root.hasPlayer && root.mediaBackend.hasVolume

                Text {
                    width: root.iconSizeMd
                    height: parent.height
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "volume_up"
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.iconSizeMd
                    color: Colours.onSurfaceVariant
                }

                Slider {
                    id: volumeSlider
                    width: volumeRow.width - root.iconSizeMd - root.spacingSm
                    height: parent.height
                    from: 0
                    to: 1
                    value: root.mediaBackend ? root.mediaBackend.volumeLevel : 0
                    onPressedChanged: {
                        if (!pressed && root.mediaBackend)
                            root.mediaBackend.setVolume(volumeSlider.value);
                    }

                    background: Rectangle {
                        x: volumeSlider.leftPadding
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        width: volumeSlider.availableWidth
                        height: 4
                        radius: 2
                        color: Colours.surfaceVariant

                        Rectangle {
                            width: volumeSlider.visualPosition * parent.width
                            height: parent.height
                            radius: parent.radius
                            color: Colours.primary
                        }
                    }
                    handle: Rectangle {
                        x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        width: 16
                        height: 16
                        radius: 8
                        color: Colours.primary
                    }
                }
            }

            // ── 6. Player switcher — round 3 SplitButton-style pill ─────
            // Replaces round 2's always-visible chip row (see the redesign
            // header above for why). One compact pill sized to its own
            // content, holding an icon plus the active player's elided
            // label; tapping it opens a small anchored dropdown of every
            // player, each row still dispatching the exact same
            // `mediaBackend.selectPlayer(id)` call the old chips issued.
            // The row keeps its slot at every player count: zero players
            // shows the disabled "No players" pill, one shows it filled
            // but non-interactive (nothing to switch to), several make it
            // tappable.
            Item {
                id: playerSelector
                width: parent.width
                height: root.playerSelectorHeight

                readonly property var playerList: root.mediaBackend ? root.mediaBackend.players : []
                readonly property var activeEntry: {
                    const list = playerSelector.playerList;
                    for (var i = 0; i < list.length; i++) {
                        if (list[i] && list[i].active)
                            return list[i];
                    }
                    return null;
                }
                readonly property bool hasChoice: playerSelector.playerList.length > 1

                property bool menuOpen: false

                Rectangle {
                    id: selectorPill
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    width: Math.min(root.detailsWidth, pillRow.implicitWidth + root.spacingMd * 2)
                    radius: height / 2
                    color: playerSelector.menuOpen ? Colours.primary : Colours.surfaceVariant
                    opacity: playerSelector.playerList.length > 0 ? 1 : 0.5
                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }

                    Row {
                        id: pillRow
                        anchors.centerIn: parent
                        spacing: root.spacingXs

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "graphic_eq"
                            font.family: root.symbolFontFamily
                            font.pixelSize: root.fontLabel + 4
                            color: playerSelector.menuOpen ? Colours.onPrimary : Colours.onSurfaceVariant
                        }
                        Text {
                            id: selectorLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: playerSelector.activeEntry ? (playerSelector.activeEntry.label || playerSelector.activeEntry.id || "") : "No players"
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, root.detailsWidth * 0.5)
                            font.pixelSize: root.fontLabel
                            color: playerSelector.menuOpen ? Colours.onPrimary : Colours.onSurfaceVariant
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: playerSelector.hasChoice
                            text: playerSelector.menuOpen ? "expand_less" : "expand_more"
                            font.family: root.symbolFontFamily
                            font.pixelSize: root.fontLabel + 4
                            color: playerSelector.menuOpen ? Colours.onPrimary : Colours.onSurfaceVariant
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: playerSelector.hasChoice
                        onClicked: playerSelector.menuOpen = !playerSelector.menuOpen
                    }
                }

                // Click-away scrim — only present while the menu is open,
                // so it never intercepts a click anywhere else in the tab
                // otherwise. Raised above every other band but below the
                // menu itself.
                MouseArea {
                    parent: root
                    z: 9
                    anchors.fill: parent
                    visible: playerSelector.menuOpen
                    enabled: playerSelector.menuOpen
                    onClicked: playerSelector.menuOpen = false
                }

                // The dropdown itself — reparented onto the tab's own root
                // so it is never clipped by `detailsColumn`'s layout, then
                // positioned absolutely under the pill via `mapToItem`.
                Rectangle {
                    id: playerMenu
                    parent: root
                    z: 10
                    visible: opacity > 0
                    opacity: playerSelector.menuOpen ? 1 : 0
                    x: selectorPill.mapToItem(root, 0, 0).x
                    y: selectorPill.mapToItem(root, 0, 0).y + selectorPill.height + root.spacingXs
                    width: selectorPill.width
                    height: menuColumn.height + root.spacingXs * 2
                    radius: root.spacingSm
                    color: Colours.surfaceVariant

                    Behavior on opacity {
                        enabled: Motion.motionEnabled
                        NumberAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }

                    Column {
                        id: menuColumn
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: root.spacingXs
                        spacing: 0

                        Repeater {
                            model: playerSelector.playerList
                            delegate: Item {
                                width: menuColumn.width
                                height: root.playerMenuRowHeight

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: root.spacingSm
                                    anchors.rightMargin: root.spacingSm
                                    spacing: root.spacingXs

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: root.fontLabel + 4
                                        visible: !!modelData.active
                                        text: "check"
                                        font.family: root.symbolFontFamily
                                        font.pixelSize: root.fontLabel + 4
                                        color: Colours.onSurface
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label || modelData.id || ""
                                        elide: Text.ElideRight
                                        width: menuColumn.width - root.spacingSm * 2 - (root.fontLabel + 4) - root.spacingXs
                                        font.pixelSize: root.fontLabel
                                        color: modelData.active ? Colours.onSurface : Colours.onSurfaceVariant
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !modelData.active
                                    onClicked: {
                                        if (root.mediaBackend)
                                            root.mediaBackend.selectPlayer(modelData.id);
                                        playerSelector.menuOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
