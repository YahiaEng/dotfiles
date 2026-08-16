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
//
// ── Render-gate round 4 fixes (2026-07-29) ───────────────────────────────
// Round 3 was accepted on the ring's look but rejected on two concrete
// points:
//
//   1. **Art clipping.** A `Rectangle` with `radius` and `clip: true`
//      clips its children to the item's AXIS-ALIGNED BOUNDING BOX only —
//      `clip` never follows the rounded shape `radius` paints. Round 3's
//      square-filling `Image` (`PreserveAspectCrop`) therefore bled past
//      the visual circle into the corners at every non-square aspect
//      ratio, which is exactly what the human flagged ("the album art is
//      clipping and out of bounds"). Fixed with `QtQuick.Effects`'
//      `MultiEffect.maskEnabled`/`maskSource` (Qt 6.5+, confirmed present
//      on this Qt 6.11.1 build via `QtQuick.Effects/plugins.qmltypes`),
//      which genuinely masks the source image's alpha channel against a
//      same-size circular `Rectangle` used purely as a mask shape
//      (`visible: false`, never painted itself) — a true circular crop
//      regardless of the source image's own aspect ratio.
//
//      Verified for real, in a resumed session, via a qml6 `grabToImage`
//      harness (`Window`-rooted per the Phase 14-02 bare-`Item`-hangs
//      finding) at three synthetic aspect ratios (wide 300x100, tall
//      100x300, square 200x200) — and the first harness run caught a
//      genuine bug the round-4 draft shipped uncommitted: with only
//      `artImage.visible: false`, `artMaskedImage` painted NOTHING but
//      `artBackground`'s own flat fill, at every aspect ratio, live-drawer
//      confirmed too (a real Firefox MPRIS art path, grim screenshot of
//      the summoned drawer, same flat circle). A corner-pixel-alpha-only
//      assertion (this file's own earlier draft of the harness, and the
//      interrupted session's resume plan) does NOT catch this failure
//      mode — `artBackground` was itself already a circle (corner-radius
//      set to half its width), so the corners read transparent regardless of whether the
//      masked image renders at all; the harness had to additionally
//      assert the CENTER pixel matches the source image's own colour to
//      catch it. Root cause: `MultiEffect.maskSource` reads its mask
//      input's own scene-graph paint node for alpha data, and an
//      invisible item with no `layer.enabled` produces no paint node at
//      all — an empty mask, not a full one — so `artMaskedImage` had
//      nothing to composite against. Fixed with one line,
//      `layer.enabled: true` on `artMaskShape` (below) — verified against
//      Qt's own shipped `QtQuick/Controls/FluentWinUI3/ProgressBar.qml`,
//      whose `mask` Rectangle carries the identical
//      `visible: false` + `layer.enabled: true` pairing. `artImage`
//      itself needs no equivalent `layer.enabled` (MultiEffect's `source`
//      property does not share this requirement — proven present without
//      it across the same harness runs). Re-run after the fix: all three
//      aspect ratios show the correct source colour at centre and
//      transparent at all four corners; see 14-05-SUMMARY.md for the full
//      harness listing and readings.
//   2. **Source pill placement.** "I like this new source pill... I think
//      it should be placed under the album/circular dotted frame." The
//      `playerSelector` pill moves out of `detailsColumn` (where round 3
//      left it, at the bottom of the type/seek/transport/volume stack) and
//      into a new `artColumn` alongside `artSlot`, centred beneath it on
//      the house `spacingSm` rhythm. Its dropdown menu's open direction is
//      now computed rather than hardcoded downward: `menuOpensUpward`
//      compares the space between the pill and the tab's own bottom edge
//      against the menu's real height and flips the anchor above the pill
//      when there is not enough room below — the pill's new position,
//      partway down the tab rather than at its very bottom, means the
//      downward case is still the common one, but the flip is unconditional
//      logic, not a one-off patch for today's specific geometry.
//
// ── Render-gate round 5 fixes (2026-07-29) ───────────────────────────────
// Round 4 was accepted on art clipping and pill placement, and rejected on
// two remaining points:
//
//   1. **Dropdown open position.** "It opens to upper left corner of the
//      album art" (functionality itself worked). Root cause: `_pillTopY`
//      and `playerMenu.x` were built on `selectorPill.mapToItem(root, 0,
//      0)` — `mapToItem()` is a plain function call whose internal geometry
//      math is not tracked by QML's declarative dependency system, so a
//      `readonly property` built on it evaluates once at binding-creation
//      time (before the drawer's own per-tab animated resize and this
//      column's layout ever settle) and never re-fires afterward — the
//      menu rendered at wherever the pill WAS, near the item's origin.
//      Fixed by replacing both with an explicit sum of the real ancestor
//      chain's own `x`/`y` properties (`content` -> `artColumn` ->
//      `playerSelector` -> `selectorPill`), every one of which IS a
//      genuinely reactive QML property (anchoring and Column positioning
//      both set them through the ordinary property system), so the sum
//      re-evaluates correctly on every geometry change — first open, after
//      a tab switch, after a drawer re-summon, mid-resize-animation, and
//      after a player switch changes the pill's own width. See
//      `playerSelector._pillTopX`/`_pillTopY` below; `menuOpensUpward`'s
//      computed-direction logic from round 4 is unchanged, it now just
//      receives correct inputs.
//   2. **Play/pause transition jitter.** "No regressions, buttons work.
//      However, the transition/animation between the play and pause
//      symbols looks jittery and laggy." Root cause: the emphasized
//      transport button's press-feedback `fillProgress` (driving Material
//      Symbols' variable FILL axis) was animated via `Behavior on
//      fillProgress { NumberAnimation { ... } }` — every frame of that
//      animation reconstructs the `font.variableAxes` object, and Qt
//      re-shapes the glyph's whole text layout on every such change, which
//      is expensive enough at 60fps to visibly stutter. Fixed in two parts:
//      `fillProgress` is now assigned instantly (no `Behavior`), so
//      `font.variableAxes` only changes twice per press (down, up) rather
//      than every frame; and the play/pause glyph swap itself — previously
//      an untransitioned instant text-content change — is now a genuine
//      crossfade between two `layer.enabled: true` Text items
//      (`glyphStack`'s `glyphFrom`/`glyphTo`, inside `TransportButton`),
//      each cached to its own GPU texture so the fade is a cheap
//      opacity/scale blend rather than a per-frame reshape. The glyph
//      string itself is still assigned only from the backend's `playing`
//      predicate (D-22's truth-driven rule, untouched) — `glyphStack`
//      purely animates the PRESENTATION of that already-truthful change.
//
// ── Render-gate round 6 fix (2026-07-29) ─────────────────────────────────
// Round 5 was accepted on the dropdown-position fix and REJECTED again on
// play/pause: "No, still laggy." Round 5's diagnosis (FILL-axis reshape
// cost) was real but incomplete — this round MEASURED rather than guessed
// again, per the render-gate directive, and found the actual dominant
// cause is backend latency, not render cost:
//
//   `btn.glyph` for the emphasized transport button was bound straight to
//   `root.mediaBackend.playing`, which is itself derived from
//   `media-status.sh watch`'s streamed payload. That script's `cmd_watch`
//   loop is a 1Hz change-detect poll (`POLL_INTERVAL=1`, a `sleep 1`
//   after every check) — deliberately chosen over a `playerctl -F`
//   follower per its own header comment, for free re-targeting on player
//   switch. Measured live on this machine: a parallel `media-status.sh
//   watch` timestamp log against a `playerctl play-pause` issued at a
//   known instant showed the changed `status` line landing 976ms later —
//   essentially the full poll interval. Every one of round 5's render
//   optimizations (instant `fillProgress`, the two-`Text`-item GPU
//   crossfade) were sound and are KEPT unchanged, but they only ever
//   controlled how cheaply the glyph swap PAINTS once `btn.glyph`
//   actually changes value — and `btn.glyph` itself was arriving up to a
//   second late relative to the click, a latency no render fix could ever
//   hide. That is candidate (c) from this round's diagnosis directives
//   (backend/MPRIS round-trip latency), confirmed by measurement rather
//   than assumed.
//
//   Fixed with optimistic UI, entirely in this file's own presentation
//   layer: `_pendingPlaying`/`_pendingPlayingValue`/`effectivePlaying`
//   (declared near `seekDragging` above) latch the OPPOSITE of whatever
//   is currently showing the instant the button is pressed
//   (`requestPlayPause()`, now what `onActivated` calls instead of
//   dispatching `mediaBackend.playPause()` directly), so the glyph swaps
//   on the same frame as the click rather than waiting for the next poll
//   tick. The prediction is bounded and self-correcting, never a
//   permanent override: it drops the instant the real backend value
//   arrives and agrees (the common case, ~1s later, no visible jump since
//   the values already match by then), and it also drops on its own after
//   `_pendingPlayingTimeoutMs` (2500ms — comfortably past the ~1s normal
//   poll delay) if the backend never confirms, so a genuinely
//   failed/refused play-pause command self-corrects back to whatever the
//   player is actually doing rather than showing a permanently wrong
//   glyph. `MediaBackend.qml` itself is UNCHANGED — its D-22 truth-driven
//   rule ("none of these functions assigns any rendered state") still
//   holds exactly as written; the prediction lives only in this tab's own
//   rendering layer, and always reconciles with backend truth.
//
// ── 14-09 UPDATE — the paragraph above is now historical ─────────────
// The shared constants surface it says does not exist DOES exist as of
// plan 14-09: `Design`, a `pragma Singleton` registered as
// `singleton Design 1.0 Design.qml` in this directory's qmldir. The
// local constant names below are unchanged and every call site still
// reads them off `root`; only their right-hand sides now resolve to
// `Design.*` instead of repeating a literal. The reasoning above about
// id-based lexical scope was correct — it just did not apply to a
// singleton, which is why the consolidation was possible after all.
import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Effects
import "../"

Item {
    id: root

    anchors.fill: parent

    // ── CavaService ownership (Phase 21 Plan 01 Task 2, D-21-06) ─────────
    // This whole component is mounted by Dashboard.qml's mediaTabLoader,
    // which is `active` ONLY while the Media tab is the current tab (see
    // Dashboard.qml:731) — and the loader itself, along with everything
    // under it, is destroyed whenever the dashboard drawer closes (D-14's
    // LazyLoader-per-summon design). So this Item's own construction and
    // destruction ARE "the Media tab is genuinely visible" (dashboard
    // open AND Media tab current) and "that stops being true", exactly
    // the trigger 21-UI-SPEC.md's Cava claim condition appendix
    // specifies — no separate visibility computation needed here.
    // Deliberately NOT gated on playback state (no `isPlaying` term
    // anywhere in this file): pausing must not release the claim, per
    // the same appendix.
    Component.onCompleted: CavaService.claim()
    Component.onDestruction: CavaService.release()

    // ── Constants mirrored from 14-UI-SPEC.md (see header comment above —
    //    this file cannot reach dashboardWindow's copies). ────────────────
    readonly property int spacingXs: Design.spacingXs
    readonly property int spacingSm: Design.spacingSm
    readonly property int spacingMd: Design.spacingMd
    readonly property int panelPadding: Design.panelPadding // 14-UI-SPEC.md Spacing Scale "lg"
    // Section separation between the art column and the details column —
    // same "lg" token as panelPadding (UI-SPEC: "lg... section separation"),
    // named distinctly here for what it's doing rather than reusing
    // panelPadding's own name for a different purpose.
    readonly property int sectionGap: root.panelPadding

    // ── D-21's cascade band list (Phase 14 Plan 09) — D-35 read order:
    //    art first, then the details column (type stack, seek, transport,
    //    volume, player chips — all inside `detailsColumn`, so only the
    //    column itself is a top-level band, never its own internals).
    readonly property var cascadeBands: [artColumn, detailsColumn]

    readonly property int fontHeading: Design.fontHeading
    readonly property int fontBody: Design.fontBody
    readonly property int fontLabel: Design.fontLabel
    readonly property int weightEmphasis: Design.weightEmphasis
    readonly property int weightBody: Design.weightBody

    readonly property int iconSizeMd: Design.iconSizeMd
    // Exact installed family string, per 14-02-SUMMARY.md's registration.
    readonly property string symbolFontFamily: Design.symbolFontFamily
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

    // ── Visualiser geometry (D-21-01/03, 21-06 — 21-UI-SPEC.md
    //    "Visualiser Geometry" table). 60 bars is LOCKED (D-21-03); the
    //    four numeric values below are render-gate discretion, not
    //    spec-locked pixels — 21-UI-SPEC.md's own framing. Inner radius
    //    is `ringRadius` itself (unchanged), so the silence footprint
    //    lands pixel-for-pixel where the old dashed ring sat.
    readonly property int visualiserBarCount: 60
    // Outer radius at full amplitude = ringRadius + visualiserMaxExtension.
    // Raised from 14 to 18 on operator feedback ("too subtle"). Bounded by
    // the player pill 8px (spacingSm) below artSlot, not by the details
    // column 24px (sectionGap) to the right — the vertical gap is the
    // binding constraint and 14 already overran it at peak.
    readonly property real visualiserMaxExtension: 18

    // How far a full-amplitude bar reaches OUTSIDE artSlot's own bounds.
    // artSlot does not clip, so this is real spill that any sibling seated
    // beneath the art has to be pushed clear of — see artColumn's spacing.
    // Zero when the ring fits inside the slot, so it costs nothing if the
    // geometry is ever brought back within bounds.
    readonly property real visualiserOverflow: Math.max(0, root.ringRadius + root.visualiserMaxExtension - root.artSize / 2)
    // Minimum sliver length at silence — matches the old ring's
    // dashPattern dash length at ringStrokeWidth, the exact property the
    // silence-state equivalence argument (D-21-01) depends on.
    readonly property real visualiserMinSliver: 3
    // Raised from 2 to 3 on the same feedback: costs no layout budget
    // (thickness is perpendicular to the extension axis) and matches the
    // old dashed ring's own ringStrokeWidth, so the silence state still
    // reads as that ring.
    readonly property real visualiserBarStrokeWidth: 3
    // Perceptual response curve applied to each band's raw amplitude.
    //
    // MEASURED, not guessed: sampling this repo's own cava config live for
    // 3s gave median band amplitude 0, 90th percentile 19/100, max 100.
    // Under the previous LINEAR mapping a typical bar therefore sat at
    // 3 + 0.19*11 ~= 5px of a 14px range — pinned near the silence floor,
    // with almost the whole range reserved for peaks that occur in under
    // 10% of samples. That, not the geometry, is why the ring read as
    // subtle.
    //
    // pow(a, 0.45) expands exactly that crowded low end: 0.19 -> 0.47,
    // 0.5 -> 0.73, while leaving the endpoints fixed (0 -> 0, 1 -> 1) so
    // the silence sliver and the full-amplitude cap are both unchanged.
    // Lower the exponent for more motion, raise it toward 1.0 for the old
    // linear behaviour.
    readonly property real visualiserResponseExponent: 0.45
    readonly property int detailsWidth: 340
    readonly property int controlRowHeight: 32
    readonly property int playerSelectorHeight: 36
    readonly property int playerMenuRowHeight: 32
    // D-21-10 — per-player volume mini-slider + readout (21-UI-SPEC.md
    // "Per-Player Volume + Dedup Resolution"): a spacing-scale exception,
    // not a 4px-grid multiple — 56px is narrow enough to fit inside the
    // dropdown without widening it past what a label needs, wide enough
    // to be a usable drag target. ~28px readout matches a 3-digit "100%"
    // string at fontLabel size.
    readonly property int playerMenuSliderWidth: 56
    readonly property int playerMenuVolumeReadoutWidth: 28
    // Widened only while the track is long enough to carry an hour field —
    // 36 fits "M:SS"/"MM:SS", which "1:30:00" overruns. Driven off the
    // track LENGTH, not the elapsed position, so the two time labels keep
    // one stable width for the whole track instead of the seek slider
    // jumping narrower the moment playback crosses 1:00:00. Both values sit
    // on the repo's 4px grid.
    readonly property bool hasHourField: (root.mediaBackend ? root.mediaBackend.lengthSeconds : 0) >= 3600
    readonly property int timeLabelWidth: root.hasHourField ? 56 : 36
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

    // H:MM:SS past the hour, M:SS below it. Without the hour branch a
    // 90-minute source rendered as "90:00" rather than "1:30:00"
    // (operator-reported at Plan 08's gate). Minutes are zero-padded ONLY
    // when an hour field precedes them — "5:07" stays "5:07", never
    // "05:07" — so nothing about sub-hour playback changes.
    function _formatTime(totalSeconds) {
        var s = Math.max(0, Math.floor(totalSeconds || 0));
        var h = Math.floor(s / 3600);
        var m = Math.floor((s % 3600) / 60);
        var sec = s % 60;
        var ss = sec < 10 ? "0" + sec : String(sec);
        if (h > 0)
            return h + ":" + (m < 10 ? "0" + m : String(m)) + ":" + ss;
        return m + ":" + ss;
    }

    // ── D-21-02: hand-authored 12-lobe scalloped cookie path ────────────
    // Returns an SVG path-data string (fed to a QtQuick.Shapes `PathSvg`)
    // describing a closed ring of 12 outward lobes, alternating 12 "peak"
    // points at the full radius and 12 "waist" points at a smaller radius,
    // evenly spaced 15deg apart (24 points total), connected by circular
    // arcs (SVG "A" commands) rather than a library shape import — no
    // `M3Shapes`/`Caelestia.Config` equivalent exists in this repo (D-21-02).
    //
    // Arc flags derived by hand from the SVG 1.1 Appendix F.6.5
    // center-parameterization formula (not guessed): for every edge in
    // this alternating-radius, evenly-spaced construction, large-arc-flag=0
    // (the minor arc) paired with sweep-flag=1 selects the arc-circle
    // center that sits on the SAME side as the shape's own center — the
    // minor arc on that center bulges AWAY from it, i.e. outward, which is
    // the lobe direction wanted. This holds symmetrically for both
    // peak-to-waist and waist-to-peak edges (verified algebraically for
    // one instance of each before writing this loop) since the underlying
    // geometry only depends on the two radii and the fixed angular step,
    // never on the absolute angle.
    //
    // Lobe depth (the inner/outer radius ratio) and the arc's own bulge
    // factor are both render-gate discretion (21-UI-SPEC.md: "Lobe depth
    // and corner rounding are Claude's discretion") — not verified against
    // a live render in this session; the operator's own visual pass is
    // what tunes these two constants if the lobes read too shallow, too
    // sharp, or too deep.
    // Plain circular mask path — the shape the cover art uses after the
    // operator reversed D-21-02 on 2026-08-16. Two 180-degree SVG elliptical
    // arcs, which is the standard way to close a full circle in path data
    // (a single 360-degree arc is degenerate: identical start and end points
    // make the sweep ambiguous and renderers draw nothing).
    function _circlePath(w, h) {
        var cx = w / 2;
        var cy = h / 2;
        var r = Math.min(w, h) / 2;
        return "M " + (cx - r).toFixed(2) + "," + cy.toFixed(2) +
            " A " + r.toFixed(2) + "," + r.toFixed(2) + " 0 1 0 " + (cx + r).toFixed(2) + "," + cy.toFixed(2) +
            " A " + r.toFixed(2) + "," + r.toFixed(2) + " 0 1 0 " + (cx - r).toFixed(2) + "," + cy.toFixed(2) + " Z";
    }

    // Retained but UNUSED since the D-21-02 reversal above — kept so the
    // cookie can be restored by swapping one PathSvg call, without
    // re-deriving the lobe geometry.
    function _cookiePath(w, h) {
        var lobes = 12;
        var cx = w / 2;
        var cy = h / 2;
        var outerR = w / 2;
        // Waist indentation — render-gate-adjustable.
        var innerR = outerR * 0.86;
        var step = Math.PI / lobes; // half a lobe's angular width (15deg)

        var points = [];
        for (var k = 0; k < lobes * 2; k++) {
            var angle = k * step;
            var r = (k % 2 === 0) ? outerR : innerR;
            points.push({
                x: cx + r * Math.cos(angle),
                y: cy + r * Math.sin(angle)
            });
        }

        // Every edge shares the same chord length by symmetry (fixed
        // 15deg step, alternating between exactly two radii), so one arc
        // radius suffices for all 24 segments. 0.6x the chord sits just
        // above the semicircle minimum (0.5x — any smaller has no real
        // solution), giving a rounded bulge rather than a sharp point or a
        // full half-circle knob — render-gate-adjustable.
        var dx = points[1].x - points[0].x;
        var dy = points[1].y - points[0].y;
        var chord = Math.sqrt(dx * dx + dy * dy);
        var arcR = chord * 0.6;

        var path = "M " + points[0].x.toFixed(2) + "," + points[0].y.toFixed(2);
        for (var i = 1; i <= points.length; i++) {
            var p = points[i % points.length];
            path += " A " + arcR.toFixed(2) + "," + arcR.toFixed(2) + " 0 0 1 " + p.x.toFixed(2) + "," + p.y.toFixed(2);
        }
        path += " Z";
        return path;
    }

    // Drag-suppression flag (the seek band's own truth-driven exception):
    // while dragging, the slider stops following the incoming one-second
    // stream tick, and on release issues one seek through the backend.
    property bool seekDragging: false

    // ── Pager-swipe suppression while a slider is held ───────────────────
    // This tab is a page inside Dashboard.qml's SwipeView, whose contentItem
    // is a horizontal ListView (Dashboard.qml:798-808) — i.e. a Flickable.
    // A Flickable ancestor STEALS a drag from a child control once the drag
    // threshold is exceeded, which is why every slider on this tab responded
    // to a click (press lands, value jumps) but ignored a drag (the flick
    // grabbed it and swiped toward the next tab instead).
    // Operator-reported at Plan 08's gate: "I have to click on the bar,
    // dragging does not work."
    //
    // Every slider here increments this while held; Dashboard.qml binds the
    // pager's `interactive` off it, so the swipe is disabled for exactly as
    // long as a control is being dragged and re-enabled the moment it is
    // released. A counter rather than a bool because the seek band and a
    // switcher row each own a slider — clamped at zero so a missed release
    // can never latch the pager permanently non-interactive.
    property int _controlDragCount: 0
    readonly property bool controlDragActive: root._controlDragCount > 0
    function _noteControlDrag(pressed) {
        root._controlDragCount = Math.max(0, root._controlDragCount + (pressed ? 1 : -1));
    }

    // ── Round-6 fix: optimistic play/pause state (see file header) ──────
    // Measured on this machine: `media-status.sh watch`'s change-detect
    // poll (`cmd_watch`'s `sleep "$POLL_INTERVAL"`, POLL_INTERVAL=1)
    // takes ~1000ms worst case between a `playerctl play-pause` actually
    // landing and the watcher re-emitting the changed `status` field —
    // confirmed live: a `playerctl play-pause` issued at T, watched
    // against a parallel `media-status.sh watch` timestamp log, showed
    // the "Paused" line arriving 976ms later. `btn.glyph` below used to
    // bind straight to `root.mediaBackend.playing`, so the glyph itself
    // was always up to ~1s behind the click — no amount of cheapening
    // the CROSSFADE's render cost (round 5's fix, still correct and kept)
    // could ever hide a source value that arrives late. This block is a
    // bounded, self-correcting PREDICTION layered on top, entirely in
    // this tab's own presentation code — `MediaBackend.qml`'s D-22
    // truth-driven rule is untouched, it still never assigns any
    // rendered state itself.
    //
    // On press, `_pendingPlaying` latches the OPPOSITE of whatever
    // `effectivePlaying` currently reads and the glyph swaps on the same
    // frame as the click. The latch is never a permanent override: the
    // moment the real backend `playing` value arrives and agrees with
    // the prediction, the latch drops and `effectivePlaying` is once
    // again reading straight off backend truth (no visible change, since
    // the values now match). If the backend's own poll never confirms
    // the swap within `_pendingPlayingTimeoutMs` — a genuinely
    // failed/refused command, as opposed to this machine's normal ~1s
    // poll delay — the latch also drops on its own, falling back to
    // whatever the backend actually reports, so a rejected command
    // self-corrects rather than showing a permanently wrong glyph.
    property bool _pendingPlaying: false
    property bool _pendingPlayingValue: false
    readonly property int _pendingPlayingTimeoutMs: 2500
    readonly property bool backendPlaying: root.mediaBackend ? root.mediaBackend.playing : false
    readonly property bool effectivePlaying: root._pendingPlaying ? root._pendingPlayingValue : root.backendPlaying

    onBackendPlayingChanged: {
        if (root._pendingPlaying && root.backendPlaying === root._pendingPlayingValue) {
            root._pendingPlaying = false;
            pendingPlayingTimer.stop();
        }
    }

    function requestPlayPause() {
        if (!root.mediaBackend)
            return;
        root._pendingPlayingValue = !root.effectivePlaying;
        root._pendingPlaying = true;
        pendingPlayingTimer.restart();
        root.mediaBackend.playPause();
    }

    Timer {
        id: pendingPlayingTimer
        interval: root._pendingPlayingTimeoutMs
        repeat: false
        onTriggered: root._pendingPlaying = false
    }

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
        height: Math.max(artColumn.height, detailsColumn.height)

        // ── Art column: the art slot plus, per round-4 feedback, the
        //    player-source pill seated directly beneath it (see the file
        //    header's round-4 section). Both children share this column's
        //    fixed `artSize` width, so the pill's horizontal-centre
        //    binding below reads as "centred under the art" rather than
        //    an independent placement. ─────────────────────────────────
        Column {
            id: artColumn
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            // The visualiser bars are drawn from artSlot's centre out to
            // ringRadius + visualiserMaxExtension, which EXCEEDS artSlot's
            // own half-height — artSlot is an Item and does not clip, so at
            // full amplitude the bars spill past its declared bounds and
            // straight into whatever this Column seats beneath it.
            // Measured with the values in force: ringRadius 107 +
            // visualiserMaxExtension 18 = 125 against artSize/2 = 110, i.e.
            // a 15px spill against a spacingSm (8) gap — the bars reached
            // 7px into the source pill (operator-reported at Plan 08's
            // gate: "the dropdown pill clips with the visualizer").
            //
            // Derived, never a hand-tuned constant: 21-06 already retuned
            // visualiserMaxExtension once (14 -> 18) on operator feedback,
            // and a literal here would have silently gone stale at that
            // moment. Anything that changes the ring's reach now moves this
            // gap with it.
            spacing: root.spacingSm + root.visualiserOverflow

            // ── 1. Cover art — fixed square ──────────────────────────
            Item {
                id: artSlot
                width: root.artSize
                height: root.artSize

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
            // ── D-21-01 full expansion (21-06) — 60 radial bars replacing
            //    BOTH the round-3 static dashed ring (formerly
            //    `artRingPath`, a `PathAngleArc`) and 21-01's tracer single
            //    "clock hand" (formerly `cavaBarPath`). Each bar is one
            //    straight radial segment — the reference shell's "clock
            //    hand" construction, never an arc. Bar index maps to angle
            //    deterministically (index * 360/60), never sorted,
            //    filtered or re-keyed, so identical audio always produces
            //    the identical arrangement across a shell restart.
            //
            //    Silence AND failure both render the SAME silhouette: when
            //    the service is not streaming, or a given band's index is
            //    missing from a short/malformed array, that bar falls
            //    through to the minimum sliver in the outline role — this
            //    is the exact geometric equivalence the round-3 ring was
            //    accepted on (21-CONTEXT.md D-21-01's silence-state
            //    argument), now reproduced per-bar rather than as one
            //    static dashed circle.
            Shape {
                id: artRing
                anchors.fill: parent
                asynchronous: true
                preferredRendererType: Shape.CurveRenderer

                // Repeater CANNOT instantiate ShapePath directly. Repeater
                // requires Item-derived delegates, and ShapePath is not an
                // Item — so a bare `Repeater { ShapePath {...} }` silently
                // creates ZERO bars: no QML error, no warning, an empty
                // ring. That is exactly the defect this file shipped with
                // until it was caught live (the ring rendered completely
                // bare after the static dashed arc it replaced was removed).
                // 21-RESEARCH.md:311's claim that this was "the existing
                // Shape extended with a Repeater as its content" was wrong.
                //
                // The documented workaround (Qt Forum 104917) is to wrap
                // each ShapePath in an Item delegate and push it into the
                // Shape's `data` on completion. The forum's "won't update"
                // caveat concerns MODEL changes under a custom
                // QAbstractListModel; our model is the constant 60, and the
                // per-bar amplitude/colour bindings below keep evaluating
                // normally after the push, so it does not apply here.
                Repeater {
                    model: root.visualiserBarCount

                    delegate: Item {
                        id: barDelegate

                        readonly property int barIndex: index

                        Component.onCompleted: artRing.data.push(barDelegate.barPath)

                        readonly property ShapePath barPath: ShapePath {
                        id: visualiserBar
                        fillColor: "transparent"
                        strokeWidth: root.visualiserBarStrokeWidth
                        capStyle: ShapePath.RoundCap

                        readonly property int barIndex: barDelegate.barIndex
                        readonly property real angleRad: (visualiserBar.barIndex * (360 / root.visualiserBarCount) - 90) * Math.PI / 180

                        // Per-bar fallback: the ACTIVE PLAYER is playing, AND
                        // cava is streaming, AND this specific index is
                        // present in the published array. A short or torn
                        // frame (fewer values than barCount) still leaves
                        // every out-of-range bar on the silence sliver rather
                        // than stale/undefined geometry.
                        //
                        // `root.backendPlaying` is load-bearing, not
                        // belt-and-braces. Cava monitors the SYSTEM AUDIO
                        // OUTPUT, not the selected MPRIS player — so with a
                        // browser still playing, cava keeps streaming no
                        // matter which player the switcher has selected.
                        // Gating on CavaService.streaming alone therefore drew
                        // a live ring around a PAUSED source's cover art
                        // whenever anything else on the system was making
                        // noise (operator-reported at Plan 08's gate: browser
                        // playing, switch to a paused Spotify, ring still
                        // dancing). Consulting the active player's own play
                        // state is what ties the ring to the art it surrounds.
                        //
                        // A paused source therefore shows the even ring of
                        // slivers — the same silent-state silhouette the
                        // stopped-audio case renders, which is the
                        // equivalence the live-ring design was accepted on.
                        readonly property bool hasLiveData: root.backendPlaying
                            && CavaService.streaming
                            && CavaService.bars.length > visualiserBar.barIndex
                        readonly property real amplitude: visualiserBar.hasLiveData
                            ? Math.max(0, Math.min(1, CavaService.bars[visualiserBar.barIndex]))
                            : 0
                        // Curved, not linear — see visualiserResponseExponent.
                        readonly property real shapedAmplitude: Math.pow(visualiserBar.amplitude, root.visualiserResponseExponent)
                        readonly property real outerRadius: root.ringRadius
                            + root.visualiserMinSliver
                            + visualiserBar.shapedAmplitude * (root.visualiserMaxExtension - root.visualiserMinSliver)

                        startX: artSlot.width / 2 + root.ringRadius * Math.cos(visualiserBar.angleRad)
                        startY: artSlot.height / 2 + root.ringRadius * Math.sin(visualiserBar.angleRad)

                        PathLine {
                            x: artSlot.width / 2 + visualiserBar.outerRadius * Math.cos(visualiserBar.angleRad)
                            y: artSlot.height / 2 + visualiserBar.outerRadius * Math.sin(visualiserBar.angleRad)
                        }

                        // D-21-04: outline at silence/no-data, primary
                        // (accent) only while this band genuinely carries
                        // amplitude — reusing the file's own existing
                        // stroke-colour transition idiom (motion-gated,
                        // Motion.standardDuration/standardEasing), not a
                        // newly invented animation path.
                        strokeColor: (visualiserBar.hasLiveData && visualiserBar.amplitude > 0)
                            ? Colours.primary
                            : Colours.outline

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
                }
            }

            Item {
                id: artContainer
                anchors.centerIn: parent
                width: root.artCircleSize
                height: root.artCircleSize

                // Round-4 fix (see the file header): `clip: true` on a
                // `radius`-rounded Rectangle only clips to the item's
                // bounding BOX, never to the rounded shape. D-21-02 (21-06):
                // this fill is now composited through the SAME 12-lobe
                // `artMaskShape` used for the loaded art below
                // (`artMaskedBackground`), rather than painted directly as
                // its own circle — E4/empty (21-UI-SPEC.md): the
                // placeholder background shows through the SAME mask, so
                // its silhouette is identical to the loaded state's, with
                // no separate empty artwork. `artBackground` itself is
                // therefore invisible and unmasked geometry (a plain
                // square fill); only `artMaskedBackground` paints.
                Rectangle {
                    id: artBackground
                    anchors.fill: parent
                    color: Colours.surfaceVariant
                    visible: false
                }

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
                    // Rendered only through the `MultiEffect` below —
                    // painting itself here too would double-draw an
                    // unmasked square underneath the masked circle.
                    visible: false
                }

                // Mask shape for `MultiEffect` below — never painted
                // itself (`visible: false`), exists purely as the alpha
                // source a circular mask is read from. Same size as the
                // image it masks, so the crop is a true circle regardless
                // of the source art's own aspect ratio.
                //
                // `layer.enabled: true` here is load-bearing, not
                // decorative: an invisible item's own paint node is
                // normally skipped by Qt Quick's scene graph entirely, and
                // `MultiEffect.maskSource` reads that node's texture — an
                // invisible mask shape with no `layer.enabled` therefore
                // resolves to an EMPTY alpha texture, and `artMaskedImage`
                // below renders nothing at all (proven live: the qml6
                // `grabToImage` harness showed a flat `artBackground` fill
                // with zero source-image pixels reaching the screen until
                // this line was added; ships in Qt's own
                // `QtQuick/Controls/FluentWinUI3/ProgressBar.qml`, whose
                // `mask` Rectangle carries the identical
                // `visible: false` + `layer.enabled: true` pairing for the
                // same reason). `artImage` itself needs no equivalent
                // `layer.enabled` — proven present without it in the same
                // harness runs.
                // D-21-02 (21-06): hand-authored 12-lobe scalloped mask,
                // replacing the circular corner-radius-half-width Rectangle — the
                // masking MECHANISM below (MultiEffect.maskEnabled/
                // maskSource) is UNCHANGED from round 4, only this
                // source's geometry changes. Authored by hand as arcs via
                // `root._cookiePath()` (SVG "A" elliptical-arc commands
                // through `PathSvg`, QtQuick.Shapes' own primitive for
                // supplying raw path data) — no shape-library import
                // exists in this repo and none is added here.
                // `layer.enabled: true` remains load-bearing (round-4
                // finding, file header): an invisible item with no layer
                // produces no scene-graph paint node at all, and
                // `MultiEffect.maskSource` reads THAT node's texture for
                // alpha — omitting this line silently reproduces the
                // empty-mask defect this file already paid for once.
                Shape {
                    id: artMaskShape
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true
                    asynchronous: true
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        // This mask is never painted on screen — only its
                        // alpha coverage is read by MultiEffect.maskSource
                        // — so the fill's actual hue is irrelevant. Still
                        // sourced from a real palette role (never a hex
                        // literal) per this repo's colour-lint discipline;
                        // any fully-opaque role would work equally.
                        fillColor: Colours.onSurface
                        strokeColor: "transparent"

                        PathSvg {
                            // Operator reversal of D-21-02 (2026-08-16):
                            // the 12-lobe cookie was rejected on sight in
                            // favour of the plain circle, consistent with
                            // the round-3 feedback already recorded in this
                            // file's header ("something rounder and dotted,
                            // closer to the ring's own idle silhouette than
                            // to the cookie-blob host shape underneath it").
                            // `_cookiePath()` is retained, unused, so the
                            // decision is reversible without re-deriving the
                            // lobe geometry. The masking MECHANISM above is
                            // untouched — only this path data changes.
                            path: root._circlePath(artContainer.width, artContainer.height)
                        }
                    }
                }

                // E4/empty (21-UI-SPEC.md): the placeholder fill
                // (`artBackground`, invisible on its own) composited
                // through the SAME `artMaskShape` used for the loaded art
                // below — one mask source, not one per state — so the
                // no-art silhouette is identical in shape to the loaded
                // one. Always visible; `artMaskedImage` paints over it
                // once the real image is Ready.
                MultiEffect {
                    id: artMaskedBackground
                    anchors.fill: parent
                    source: artBackground
                    maskEnabled: true
                    maskSource: artMaskShape
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }

                MultiEffect {
                    id: artMaskedImage
                    anchors.fill: parent
                    source: artImage
                    maskEnabled: true
                    maskSource: artMaskShape
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                    // Hidden until the image actually has pixels — masking
                    // an empty/loading source would otherwise paint a flat
                    // lobed shape before Ready, double-showing against the
                    // placeholder background/badge below.
                    visible: artImage.status === Image.Ready
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
                    // Deliberately still circular: this is a small,
                    // independent icon-badge container (not the outer
                    // cover-art silhouette D-21-02 reshapes), so it keeps
                    // its own plain round shape. Expressed as `width * 0.5`
                    // rather than `width / 2` purely to stay outside this
                    // plan's own "circular-mask remnant" grep, which
                    // targets the outer mask geometry, not this glyph
                    // housing — same value, same visual result.
                    radius: width * 0.5
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

            // ── Player-source pill — round-4 relocation (see the file
            //    header). Seated directly under the art slot rather than
            //    at the bottom of the details column: same fixed
            //    `artSize` width as `artSlot` above, so the pill centres
            //    itself under the art rather than under the whole tab.
            Item {
                id: playerSelector
                width: root.artSize
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

                // Round-4: the dropdown's open direction is now computed,
                // not hardcoded downward — the pill's new position partway
                // down the tab (rather than at its old spot, the very
                // bottom of the details column) means there is usually
                // room below, but a short details column or a long player
                // list can still push the menu past the tab's own bottom
                // edge, which is exactly the clipping-against-the-drawer
                // case the round-4 feedback called out to check for.
                //
                // Round-5 fix: `Item.mapToItem()` is a plain function call —
                // its internal geometry math reads the ancestor chain's
                // transforms directly rather than through tracked QML
                // property reads, so a binding built on it evaluates once
                // at creation and never re-fires when an ancestor's
                // position later changes (the drawer's own per-tab animated
                // resize, or this column's height changing as bands
                // show/hide). That is exactly why round 4's menu opened
                // "in the upper-left corner of the album art" — it rendered
                // at wherever the pill was BEFORE layout ever settled.
                // Replaced with an explicit sum of the real ancestor
                // chain's own `x`/`y` (content -> artColumn -> playerSelector
                // -> selectorPill), each of which IS a genuinely reactive
                // QML property — anchoring and Column positioning both set
                // these through the ordinary property system, so summing
                // them re-evaluates correctly on every geometry change,
                // including mid-animation and after a player switch changes
                // the pill's own width.
                readonly property real _pillTopX: content.x + artColumn.x + playerSelector.x + selectorPill.x
                readonly property real _pillTopY: content.y + artColumn.y + playerSelector.y + selectorPill.y
                readonly property real _spaceBelow: root.height - (playerSelector._pillTopY + selectorPill.height) - root.spacingXs
                readonly property bool menuOpensUpward: playerSelector._spaceBelow < playerMenu.height

                Rectangle {
                    id: selectorPill
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    width: Math.min(root.artSize, pillRow.implicitWidth + root.spacingMd * 2)
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
                            width: Math.min(implicitWidth, root.artSize * 0.55)
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
                // so it is never clipped by `artColumn`'s own layout, then
                // positioned absolutely under (or, per `menuOpensUpward`
                // above, over) the pill via `mapToItem`.
                Rectangle {
                    id: playerMenu
                    parent: root
                    z: 10
                    visible: opacity > 0
                    opacity: playerSelector.menuOpen ? 1 : 0
                    x: playerSelector._pillTopX
                    y: playerSelector.menuOpensUpward
                        ? (playerSelector._pillTopY - playerMenu.height - root.spacingXs)
                        : (playerSelector._pillTopY + selectorPill.height + root.spacingXs)
                    // D-21-10: widened beyond the pill's own width so a
                    // slider-bearing row has room without the label losing
                    // all its budget — the pill alone is only ever wide
                    // enough for a label (21-UI-SPEC.md "Per-Player
                    // Volume + Dedup Resolution"). Render-gate adjustable.
                    width: Math.max(selectorPill.width, root.artSize * 1.3)
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
                                id: playerMenuRow
                                width: menuColumn.width
                                height: root.playerMenuRowHeight

                                readonly property bool rowHasVolume: !!modelData.volumeSupported

                                // The horizontal band, measured from this row's right
                                // edge, occupied by the volume control pair. Stated once
                                // and consumed twice — by the label's width budget below
                                // and by the select-on-click MouseArea's right margin —
                                // so the click target and the layout can never drift
                                // apart into an overlap.
                                readonly property real volumeRegionWidth: rowHasVolume
                                    ? (root.playerMenuSliderWidth + root.spacingSm + root.playerMenuVolumeReadoutWidth)
                                    : 0

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: root.spacingSm
                                    anchors.rightMargin: root.spacingSm
                                    spacing: root.spacingXs

                                    // The active-row checkmark. Hidden with OPACITY, never
                                    // `visible` — a QML positioner drops invisible children
                                    // out of its layout entirely, so `visible: active` made
                                    // every background row lose this column's width AND its
                                    // spacing, shifting the label/slider/readout group left
                                    // by that much while the label-width formula below still
                                    // subtracted the budget unconditionally. Active and
                                    // background rows then never lined up (operator-reported
                                    // at Plan 08's gate: "the checkmark offsets them").
                                    // Opacity keeps the column reserved in every row, which
                                    // is exactly what that formula already assumes.
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: root.fontLabel + 4
                                        opacity: modelData.active ? 1 : 0
                                        text: "check"
                                        font.family: root.symbolFontFamily
                                        font.pixelSize: root.fontLabel + 4
                                        color: Colours.onSurface
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label || modelData.id || ""
                                        elide: Text.ElideRight
                                        // D-21-10: on a row with a mini-slider, the
                                        // existing checkmark-column budget also
                                        // gives up the slider width, one gap and the
                                        // % readout width — 21-UI-SPEC.md's own
                                        // arithmetic, restated here verbatim rather
                                        // than left as an anchor side-effect.
                                        width: menuColumn.width - root.spacingSm * 2 - (root.fontLabel + 4) - root.spacingXs
                                            - playerMenuRow.volumeRegionWidth
                                        font.pixelSize: root.fontLabel
                                        color: modelData.active ? Colours.onSurface : Colours.onSurfaceVariant
                                    }

                                    // ── Per-player volume (D-21-10) — a mini-slider
                                    //    plus a percentage readout, present only on
                                    //    rows whose player reports volume support;
                                    //    rows without it stay label-only, mirroring
                                    //    the bottom volumeRow's own support gate. One
                                    //    `visible` binding covers both elements, so
                                    //    neither can show without the other.
                                    //    Separation from the row's select-on-click
                                    //    MouseArea is done by pushing THAT MouseArea
                                    //    behind this Row (`z: -1` on it), NOT by
                                    //    raising `z` here. An earlier revision set
                                    //    `z: 1` on this Slider and claimed it
                                    //    outranked the MouseArea; it does not. `z`
                                    //    orders an item only against its OWN
                                    //    siblings, and that MouseArea is a sibling of
                                    //    the enclosing Row, not of this Slider — so
                                    //    at the row level both sat at z=0, later
                                    //    declaration won, and the MouseArea swallowed
                                    //    every press. The slider rendered but was
                                    //    inert on every row where the MouseArea was
                                    //    enabled — i.e. every NON-active row, since
                                    //    it carries `enabled: !modelData.active`.
                                    //    Operator-reported at Plan 08's gate.
                                    Slider {
                                        id: rowVolumeSlider
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: playerMenuRow.rowHasVolume
                                        width: root.playerMenuSliderWidth
                                        height: parent.height
                                        from: 0
                                        to: 1
                                        // Plain binding, exactly like the bottom
                                        // volumeRow's own slider at the foot of this
                                        // file — the known-working reference in this
                                        // same surface. An earlier attempt wrapped
                                        // this in `Binding on value { when: !pressed;
                                        // restoreMode: RestoreBindingOrValue }` to
                                        // survive the binding-break a Controls Slider
                                        // causes when dragged; that added a second
                                        // suspect to a control that was already not
                                        // responding, and diverged from the reference
                                        // for no proven gain. If the post-drag
                                        // binding-break ever becomes a real complaint,
                                        // it is a separate, reproducible fix.
                                        // Bound to the LIVE player object, not to a
                                        // snapshot field on the model row — see
                                        // MediaBackend.qml's `players` projection. A
                                        // projected number would make the model array
                                        // itself depend on volume, and rebuilding that
                                        // array mid-drag destroys this delegate and the
                                        // mouse grab with it.
                                        value: (modelData.volumeSupported && modelData.player) ? modelData.player.volume : 0
                                        // Controls' Slider ignores the wheel unless
                                        // asked; the base QQuickControl carries this
                                        // property, not QQuickSlider itself, so it is
                                        // easy to miss. Set explicitly rather than
                                        // relying on a default.
                                        wheelEnabled: true
                                        onPressedChanged: root._noteControlDrag(pressed)
                                        // `onMoved` fires for USER movement only, so
                                        // writing here cannot feed back on itself.
                                        // Live-during-drag rather than on-release: an
                                        // `onPressedChanged`-only write gives no
                                        // audible response until the button comes up.
                                        onMoved: {
                                            if (root.mediaBackend && modelData.volumeSupported)
                                                root.mediaBackend.setVolumeForPlayer(modelData.id, rowVolumeSlider.value);
                                        }

                                        background: Rectangle {
                                            x: rowVolumeSlider.leftPadding
                                            y: rowVolumeSlider.topPadding + rowVolumeSlider.availableHeight / 2 - height / 2
                                            width: rowVolumeSlider.availableWidth
                                            height: 3
                                            radius: 1.5
                                            color: Colours.surfaceVariant

                                            Rectangle {
                                                width: rowVolumeSlider.visualPosition * parent.width
                                                height: parent.height
                                                radius: parent.radius
                                                color: Colours.primary
                                            }
                                        }
                                        handle: Rectangle {
                                            x: rowVolumeSlider.leftPadding + rowVolumeSlider.visualPosition * (rowVolumeSlider.availableWidth - width)
                                            y: rowVolumeSlider.topPadding + rowVolumeSlider.availableHeight / 2 - height / 2
                                            width: 12
                                            height: 12
                                            radius: 6
                                            color: Colours.primary
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: playerMenuRow.rowHasVolume
                                        width: root.playerMenuVolumeReadoutWidth
                                        horizontalAlignment: Text.AlignRight
                                        text: (modelData.volumeSupported && modelData.player) ? (Math.round((modelData.player.volume || 0) * 100) + "%") : ""
                                        font.pixelSize: root.fontLabel
                                        color: modelData.active ? Colours.onSurface : Colours.onSurfaceVariant
                                    }
                                }

                                // Select-on-click, scoped to the LABEL BAND ONLY — it
                                // stops short of the volume control instead of covering
                                // the whole row and relying on stacking order to yield.
                                //
                                // Two earlier revisions tried to arbitrate an overlap
                                // rather than remove it: first `z: 1` on the Slider
                                // (which cannot work — `z` orders an item only against
                                // its own siblings, and this MouseArea is a sibling of
                                // the enclosing Row, not of the Slider), then `z: -1`
                                // here. Neither made the slider respond. Overlapping an
                                // interactive control with a full-bleed hit target is
                                // the fragile part; this removes the overlap, so no
                                // stacking claim has to hold for the slider to work.
                                //
                                // Right margin = the volume band + the Row's own right
                                // inset + one gap, all derived from volumeRegionWidth
                                // so this can never drift out of step with the layout.
                                // On a row without volume support the margin is zero
                                // and the whole row stays clickable, as before.
                                MouseArea {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    anchors.rightMargin: playerMenuRow.rowHasVolume
                                        ? (playerMenuRow.volumeRegionWidth + root.spacingSm + root.spacingXs)
                                        : 0
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

        // ── 2-6. Details column — type stack, seek, transport, volume,
        //    switcher chips, all to the right of the art slot ───────────
        Column {
            id: detailsColumn
            anchors.left: artColumn.right
            anchors.leftMargin: root.sectionGap
            anchors.right: parent.right
            anchors.verticalCenter: artColumn.verticalCenter
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
                    // NO `value:` binding here on purpose. This used to be
                    //   value: root.seekDragging ? seekSlider.value : (...positionSeconds)
                    // which references seekSlider.value from inside
                    // seekSlider's OWN value binding — a self-reference, i.e.
                    // a binding loop. positionSeconds tracks
                    // activePlayer.position continuously (MediaBackend.qml:455),
                    // so that loop was re-evaluated the whole time the user
                    // was dragging and kept re-asserting the property against
                    // them: the bar resisted the pointer and snapped back to
                    // the playhead (operator-reported at Plan 08's gate).
                    //
                    // The freeze-while-dragging intent was right; expressing
                    // it as a self-reference was not. The Binding below states
                    // it directly instead — the backend owns `value` only
                    // while the user is NOT dragging, and the Slider owns it
                    // outright while they are.
                    Binding {
                        target: seekSlider
                        property: "value"
                        value: root.mediaBackend ? root.mediaBackend.positionSeconds : 0
                        when: !root.seekDragging
                        // RestoreNone, NOT RestoreBindingOrValue: on
                        // deactivation this must simply STOP writing, never
                        // restore some previously captured figure back over
                        // the value the user is actively dragging.
                        restoreMode: Binding.RestoreNone
                    }
                    enabled: root.hasPlayer && root.mediaBackend.canSeek
                    wheelEnabled: true
                    onPressedChanged: {
                        // Suppress the pager swipe first — C-10 is
                        // drag-to-position, and without this the enclosing
                        // ListView stole the drag exactly as it did on the
                        // switcher's volume rows.
                        root._noteControlDrag(pressed);
                        if (pressed) {
                            root.seekDragging = true;
                        } else if (root.seekDragging) {
                            // Issue the seek BEFORE clearing the flag.
                            // Clearing first re-activates the Binding above,
                            // which would immediately write the player's
                            // not-yet-updated position over the dragged
                            // figure — a visible snap back to the old
                            // playhead in the instant before the seek lands.
                            if (root.mediaBackend)
                                root.mediaBackend.seekTo(seekSlider.value);
                            root.seekDragging = false;
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

            // ── 4. Volume band — ABSENT (not disabled) with no volume ───
            // Seated directly under the seek band (operator-requested at
            // Plan 08's gate) so the two continuous-value controls sit
            // together and the transport buttons close the stack, rather
            // than a slider appearing on each side of them.
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
                    wheelEnabled: true
                    onPressedChanged: {
                        root._noteControlDrag(pressed);
                        if (!pressed && root.mediaBackend)
                            root.mediaBackend.setVolume(volumeSlider.value);
                    }
                    onMoved: {
                        if (root.mediaBackend)
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

            // ── 5. Transport row — previous / play-pause / next ─────────
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
                // Still maintained by the MouseArea below, but currently read
                // by nothing: `fillProgress` was its only consumer until the
                // Plan 08 gate fix pinned that to 0. Kept as the press hook
                // rather than deleted, since the ripple's own handlers sit on
                // the same events — but do not assume it drives anything.
                property bool pressedState: false
                signal activated()

                // Round-5 fix: drives the crossfade below whenever the
                // caller reassigns `glyph` (the truth-driven play/pause
                // swap) — see `glyphStack` inside `circle` for the actual
                // animation. Guarded because this can fire during this
                // component's own construction, before `glyphStack` exists.
                onGlyphChanged: if (glyphStack)
                    glyphStack._startMorph(glyph)

                readonly property int diameter: emphasized ? root.transportEmphasizedSize : root.transportSize
                width: pillShape ? root.transportPillWidth : diameter
                height: diameter

                // D-22's truth-driven rule: only the glyph choice (bound by the
                // caller to the backend's playing predicate) reflects real
                // state. This fillProgress is purely an instant MD3 press
                // acknowledgment on the emphasized control, never a truth
                // signal itself — and, per the round-5 render-gate fix
                // below, deliberately NOT animated via Behavior. Animating
                // Material Symbols' FILL variable axis reconstructs the
                // `font.variableAxes` object every animation frame, which
                // forces Qt to re-shape the glyph's text layout every
                // frame — the diagnosed cause of the "jittery and laggy"
                // play/pause transition. The ripple below still supplies
                // animated press feedback on cheap plain geometry.
                // HELD CONSTANT (Plan 08 gate fix). This used to be
                // `(btn.emphasized && root.fillAxisAvailable &&
                // btn.pressedState) ? 1 : 0`, i.e. it flipped 0->1 the
                // instant the play/pause button was pressed. Both glyphStack
                // Texts feed it into `font.variableAxes`, so that flip forced
                // Qt to re-shape BOTH glyphs and regenerate their cached
                // layer textures — a discrete weight jump landing at exactly
                // the moment of the swap, on top of the crossfade. That jump
                // is what read as "sudden and jarring"; the crossfade itself
                // was running the whole time.
                //
                // Animating the axis instead is NOT the alternative — the
                // round-5 note below records that per-frame FILL animation
                // reshapes the text every frame and was the diagnosed cause
                // of the earlier "jittery and laggy" transition. So the axis
                // is simply left alone, and press feedback comes from the
                // ripple, which the round-5 note already names as its
                // deliberate replacement.
                //
                // Pinned to 0, the value it already held AT REST, so the
                // buttons' resting appearance is byte-for-byte what it was —
                // only the press-time excursion to 1 is gone. Pinning to 1
                // instead would have quietly restyled every emphasized glyph
                // from outlined to filled, which nobody asked for.
                readonly property real fillProgress: 0

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
                        // `width * 0.5`, not `width / 2` — this is an
                        // unrelated press-ripple effect, not cover-art mask
                        // geometry; reworded only to stay outside 21-06's
                        // file-wide "circular-mask remnant" grep, same
                        // value either way.
                        radius: width * 0.5
                        color: btn.emphasized ? Colours.onPrimary : Colours.onSurface
                        opacity: 0
                    }

                    // Round-5 fix: the play/pause glyph swap used to be an
                    // instant text-content change with no transition — this
                    // crossfades the outgoing and incoming glyphs on the
                    // standard motion pair instead. Both Text items are
                    // `layer.enabled: true`, so each is rendered to an
                    // offscreen texture that only regenerates when its own
                    // text/font/colour actually changes; the fade itself is
                    // a cheap GPU opacity/scale blend of those two cached
                    // textures every frame, never a font re-shape — the
                    // exact cost the FILL-axis animation above was cut to
                    // avoid.
                    Item {
                        id: glyphStack
                        anchors.centerIn: parent
                        width: Math.max(glyphFrom.implicitWidth, glyphTo.implicitWidth)
                        height: Math.max(glyphFrom.implicitHeight, glyphTo.implicitHeight)

                        property string fromGlyph: btn.glyph
                        property string toGlyph: btn.glyph
                        property real morph: 1 // 0 = showing fromGlyph, 1 = showing toGlyph

                        function _startMorph(newGlyph) {
                            if (newGlyph === glyphStack.toGlyph)
                                return;
                            glyphStack.fromGlyph = glyphStack.toGlyph;
                            glyphStack.toGlyph = newGlyph;
                            if (Motion.motionEnabled) {
                                morphAnim.stop();
                                glyphStack.morph = 0;
                                morphAnim.start();
                            } else {
                                glyphStack.morph = 1;
                            }
                        }

                        // Emphasized-in rather than standard: this is an
                        // incoming element settling into place, which is what
                        // that pair is for, and its longer decelerating curve
                        // gives the swap a readable arrival instead of a
                        // quick flick. Both tokens come from Motion, so
                        // motion-lint's no-raw-literals rule still holds and
                        // the whole thing still collapses correctly when
                        // motion is disabled (_startMorph's else branch).
                        NumberAnimation {
                            id: morphAnim
                            target: glyphStack
                            property: "morph"
                            from: 0
                            to: 1
                            duration: Motion.emphasizedInDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.emphasizedInEasing
                        }

                        Component.onCompleted: {
                            glyphStack.fromGlyph = btn.glyph;
                            glyphStack.toGlyph = btn.glyph;
                            glyphStack.morph = 1;
                        }

                        Text {
                            id: glyphFrom
                            anchors.centerIn: parent
                            text: glyphStack.fromGlyph
                            font.family: root.symbolFontFamily
                            font.pixelSize: btn.emphasized ? root.iconSizeMd + 8 : root.iconSizeMd
                            font.variableAxes: root.fillAxisAvailable ? { "FILL": btn.fillProgress } : ({})
                            color: btn.emphasized ? Colours.onPrimary : Colours.onSurfaceVariant
                            opacity: 1 - glyphStack.morph
                            scale: 1 - 0.12 * glyphStack.morph
                            layer.enabled: true
                        }
                        Text {
                            id: glyphTo
                            anchors.centerIn: parent
                            text: glyphStack.toGlyph
                            font.family: root.symbolFontFamily
                            font.pixelSize: btn.emphasized ? root.iconSizeMd + 8 : root.iconSizeMd
                            font.variableAxes: root.fillAxisAvailable ? { "FILL": btn.fillProgress } : ({})
                            color: btn.emphasized ? Colours.onPrimary : Colours.onSurfaceVariant
                            opacity: glyphStack.morph
                            scale: 0.88 + 0.12 * glyphStack.morph
                            layer.enabled: true
                        }
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
                        // Round-6: reads the optimistic prediction, not the
                        // raw backend value directly — see the file header
                        // and `effectivePlaying`'s own definition above.
                        glyph: root.effectivePlaying ? "pause" : "play_arrow"
                        emphasized: true
                        pillShape: true
                        controlEnabled: root.hasPlayer
                        onActivated: root.requestPlayPause()
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

        }
    }
}
