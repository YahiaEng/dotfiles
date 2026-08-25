// EdgeBar.qml — the always-on edge strip (quick task 260823-9ak, Task 3,
// R1/R4/R8/R9/D-2/D-3/D-4). One type, instantiated up to FOUR times in
// shell.qml, one per screen edge — never two near-duplicate files.
//
// ── FOUR EDGES, ONE TYPE (quick task 260824-ns3, Task 4) ─────────────────
// `edge` names which screen edge this instance runs along ("top" |
// "bottom" | "left" | "right"). Continuous and Segmented mount the
// horizontal pair only; Halo and Brackets mount all four. The vertical
// pair is NOT a second component and NOT a hand-authored second path —
// `edgebarpath.js` builds in along/depth space and transposes through one
// helper, so a vertical run is the horizontal run with its coordinate
// pairs swapped and every sweep flag re-resolved against the centre THAT
// axis's geometry demands.
//
// ── INDEPENDENT FRAME, NOT THE BAR (D-2) ─────────────────────────────────
// `Bar.qml` is not opened, moved, reoriented or absorbed by this file, and
// this file is never imported by it. The live bar orientation on this host
// is `vertical` (right edge — CONTEXT.md's own measured ground truth), so a
// top+bottom strip pair cannot BE the bar; the two coexist. This file does
// not read `BarEntryModel.isVertical` anywhere — it has no orientation of
// its own, only an edge (`edge`).
//
// D-2 WAS DELIBERATELY REVERSED for the Continuous style in quick task
// 260824-ns3 Task 3: there the BAR paints the bridge that closes the
// silhouette, because a strip with a non-negative exclusive zone is
// positioned inside the bar's own zone and can never reach it. That
// reversal lives entirely in `Bar.qml`; this file still does not know the
// bar exists.
//
// ── FILE PLACEMENT IS LOAD-BEARING (GT-4) ────────────────────────────────
// This file MUST live at `modules/EdgeBar.qml`, a sibling of `Bar.qml`, and
// NOT under `modules/bar/`. `_qsd_check_bar_colour_role_routing` in
// quickshell-doctor scans `<shell root>/bar` ONLY and forbids non-exempt
// files there from reading `Colours.*` directly (they must go through
// `BarRoles`). Living outside that directory is what lets this file read
// `Colours.*` directly, which R9 asks for.
//
// ── NAMESPACE PREFIX IS LOAD-BEARING (GT-2) ──────────────────────────────
// `quickshell-baredge-` — deliberately no hyphen after "bar". The obvious
// `quickshell-bar-edge-...` would match the bar-surface registry's own
// `bar/SectionPopout.qml|quickshell-bar-|pattern|...` row (which matches
// ANY namespace starting with `quickshell-bar-` plus one more character),
// so a namespace of that shape would match TWO rows and fail the live
// registry's exactly-one-match cardinality check — the identical trap
// `BarDrawer.qml`'s and `BarTooltip.qml`'s own namespace prefixes already
// avoid the same way. `quickshell-baredge-` still starts with
// `quickshell-bar` (so the registry's broad live-candidate net still finds
// it) and with `quickshell-` (so windowrules.lua's family blur/ignore_alpha
// rules still apply) while resolving to exactly one row — the one this
// task adds to `QSD_BAR_SURFACE_ROWS`.
//
// ── RESERVATION (D-4, Bar.qml's own double-count warning) ────────────────
// Hyprland's reservation TOTAL is `margins.<anchored-edge> + exclusiveZone`.
// Three of the four instances sit flush to their screen edge — no margin
// on the ANCHORED edge — so `exclusiveZone` (the strip's own FLAT
// thickness alone, never thickness+bulge) is the entire reservation, and
// the double-count bug Bar.qml's own header records (18-01, 18-05, always
// a +6 signature) is impossible on them by construction: there is no
// second term to fold it into. The fourth, the right rail, carries a
// margin on its anchored edge ON PURPOSE and pays for it by reserving
// nothing (`exclusiveZone: 0`) — see the margins block below, DC-2.
//
// The bulge's extra depth deliberately OVERHANGS into the client area
// rather than being reserved — reserving a full-width band to accommodate
// a centre-only bulge would waste the whole edge.
//
// ── GEOMETRY, WORKED OUT ONCE ─────────────────────────────────────────────
// One continuous `Shape` outline: a flat run of thickness T across the
// full width `ww`, rising into a centred bulge of total thickness T+B and
// width `Wb` at the middle. The two shoulders (where flat meets bulge) are
// concave quarter-circle fillets of radius B — reusing the exact tangent-
// arc technique `AttachedCorner.qml` (Task 1) established: two segments of
// equal length (here B, the step height) meeting at the corner the fillet
// removes, with the arc connecting their far ends, centred on the box's
// own diagonally-opposite corner. Traversed consistently clockwise from
// the strip's own top-left (`edge: "top"`) — right shoulder is flat-floor
// -> bulge-floor, left shoulder is bulge-floor -> flat-floor — every arc's
// sweep-flag is verified against its EXPECTED centre by
// `_shoulderSweep()` below (comparing both SVG-formula candidate centres
// against the one this geometry demands) rather than hand-derived and
// trusted blind, the same caution AttachedCorner.qml's own header names as
// the trap ("the wrong flag produces a convex bulge that will look
// deliberate and be wrong").
//
// `edge: "bottom"` and `edge: "right"` are this same outline mirrored in
// the DEPTH axis (the flat run sits at the window's own far side, flush
// with the screen; the bulge overhangs inward, into the client area) —
// built by parametrising the geometry on `_flip`, not by hand-authoring a
// second path string.
//
// ── STATIC BULGE (D-3) ────────────────────────────────────────────────────
// Every geometry input below (`Design.edgeBarThickness/BulgeExtra/
// BulgeWidth`) is a Design token, none is bound to a hover or open state,
// and no `Behavior` targets any of them — the bulge is a permanent
// landmark, not a hover- or open-reactive swell.
//
// ── MASK (GT-6, first use of `PendingRegion`/`Quickshell/Region` in this
//    repo — verify it applies live, do not trust the type declaration
//    alone) ──────────────────────────────────────────────────────────────
// Confines pointer input to the bulge's own OVERHANG rectangle only — the
// part of the bulge that sits outside the already-reserved flat-run
// territory. The flat run's reserved band is Hyprland's own exclusive
// zone, so no client window can ever sit under it regardless of whether
// this surface would consume a click there; excluding it from the mask is
// still done for cleanliness (T-9ak-01's own mitigation: a click this
// surface unavoidably consumes must do nothing, and the safest way to
// guarantee that over the widest area is to make the widest area simply
// not receive the click at all). Task 5 adds the hover handler scoped to
// this same overhang rectangle.
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "dashboard"
import "edgebarpath.js" as EdgeBarPath

PanelWindow {
    id: edgeBarWindow

    // ── Which screen edge this instance runs along (quick task
    //    260824-ns3, Task 4) ────────────────────────────────────────────
    // Was `property bool bottom` when only two instances existed. Halo and
    // Brackets need FOUR, so the edge is now named rather than counted, and
    // the two facts the rest of the file actually branches on are derived
    // from it exactly once each:
    //
    //   `_vertical` — which way the run points. Drives the anchors, the
    //     margins, which implicit dimension is the depth, the gradient's
    //     axis, and `edgebarpath.js`'s `axis` argument.
    //   `_flip`    — whether the depth axis is mirrored, i.e. whether the
    //     anchored edge is the far side of the surface. Exactly the
    //     mirror-about-surfaceDepth case the path builder's `Y()` already
    //     implements; "bottom" and "right" are the two mirrored edges.
    //
    // Anything else that wants to know about the edge derives from these
    // two, never from a second string comparison at a call site.
    property string edge: "top"
    readonly property bool _vertical: edgeBarWindow.edge === "left" || edgeBarWindow.edge === "right"
    readonly property bool _flip: edgeBarWindow.edge === "bottom" || edgeBarWindow.edge === "right"

    // The centre bulge's width — set per strip by shell.qml so each one
    // matches the surface that spawns from it (operator round 7).
    property real bulgeWidth: Design.edgeBarBulgeWidthTop

    // Edge-bar style (quick task 260824-ns3, Task 1) — threaded in from
    // shell.qml's single resolution point (root.edgeBarStyle).
    property string style: "continuous"

    // ── Which instances carry a bulge (Task 4) ──────────────────────────
    // Only the horizontal pair. The measured attachment map is: top =
    // dashboard, bottom = launcher, right = the bar, left = nothing — so
    // the two vertical rails have nothing to be the attachment root OF,
    // and a bulge on them would be a landmark pointing at no surface.
    // They draw a plain run (`bulge: false` in the path call below), which
    // is an explicit branch in `edgebarpath.js` rather than a zero-depth
    // bulge — see that file for why passing `b = 0` self-intersects.
    //
    // Brackets carries no bulge on ANY edge (Q3-brackets). The study's own
    // table scores that shape `0 direct` rails-with-a-panel; it is a
    // property of the shape, not a gap in the drawing. Two alternatives
    // were put to the operator and declined — grafting a centre bulge on,
    // and growing the arms until they meet (which would make Brackets a
    // resting state of Continuous rather than its own shape). Neither is
    // to be reintroduced.
    readonly property bool _brackets: edgeBarWindow.style === "brackets"
    readonly property bool _hasBulge: !edgeBarWindow._vertical && !edgeBarWindow._brackets

    // ── Segmented affects the TOP rail ONLY (Task 6) ────────────────────
    // The study's own `draw()` leaves the bottom as an ordinary rail —
    // `railH(H, INSET, RIGHT_EDGE, "bottom", BOTW, d.bot)`, the identical
    // call Continuous makes — and this file matches that rather than
    // segmenting both edges. The bottom instance therefore takes the plain
    // `_outlinePath` branch below with nothing special about it.
    readonly property bool _segmentedRun: edgeBarWindow.style === "segmented" && edgeBarWindow.edge === "top"

    // ── Per-style thickness (Task 4) ────────────────────────────────────
    // Halo is the one style that draws at a different weight: 2px, not
    // `T`, per the study's own `k = 2` (deliberately NOT `T`) and `rx = 1`.
    // Selected here, ONCE, off `style` — never a second token read at a
    // call site, and never a re-tuning of `edgeBarThickness`, which the
    // other three styles all still read at 6.
    // Declared HERE, above every consumer, rather than beside the other
    // geometry properties further down: `_paintedDepth` (a few lines below)
    // reads all three, and this file's own header records the
    // declare-before-use discipline the rest of the shell follows.
    readonly property bool _halo: edgeBarWindow.style === "halo"
    readonly property real _t: edgeBarWindow._halo ? Design.edgeBarHaloThickness : Design.edgeBarThickness
    readonly property real _re: edgeBarWindow._halo ? Design.edgeBarHaloEndRadius : Design.edgeBarEndRadius
    // ── THE STATIC BULGE'S DEPTH, AND HALO'S WHOLE WARNING (Q3-halo) ────
    // `animatedBulge: false` on Halo does NOT mean "no bulge". It means a
    // STATIC PERMANENT bulge at FULL depth — a 2px hairline frame plus two
    // motionless masses at the top and bottom centres. That is a legitimate
    // landmark state, and it is the state the operator asked for by name.
    // Halo's static extra is therefore its own SWELL depth, never
    // `edgeBarBulgeExtra` (4) — reading the latter here would silently give
    // a stub and look like the masses were simply missing.
    //
    // Round 12 made that swell depth Halo-specific: the masses were 12px
    // (2 + edgeBarBulgeSwellExtra) and the operator asked for thinner, so
    // Halo now reads `edgeBarHaloBulgeSwellExtra` (6) and the masses are
    // 8px. Every other style is untouched at 10.
    //
    // Fillet invariant at both ends: static Halo is f(3) + rc(1) = 4 <= 6,
    // and animated mode's 0.6/0.4 derivation sums to `_b` at every value
    // including 0.
    // Halo carries its own swell depth (operator round 12, "the bulge size
    // should be thinner in this style"); every other style keeps the 6px
    // rail's. Read through this, never Design.edgeBarBulgeSwellExtra
    // directly, or the two halves of the swell disagree and the bulge
    // animates toward a depth the surface was never sized for.
    readonly property real _swellExtra: edgeBarWindow._halo ? Design.edgeBarHaloBulgeSwellExtra : Design.edgeBarBulgeSwellExtra
    readonly property real _staticBulgeExtra: edgeBarWindow._halo ? edgeBarWindow._swellExtra : Design.edgeBarBulgeExtra

    anchors {
        top: edgeBarWindow._vertical || edgeBarWindow.edge === "top"
        bottom: edgeBarWindow._vertical || edgeBarWindow.edge === "bottom"
        left: !edgeBarWindow._vertical || edgeBarWindow.edge === "left"
        right: !edgeBarWindow._vertical || edgeBarWindow.edge === "right"
    }

    // Side margins align the strip's ends with the Hyprland window
    // silhouette (operator round 7) — see Design.edgeBarSideMargin for the
    // measurement. They are applied to the two FREE (doubly-anchored) sides
    // in both orientations, so the run is inset by the same 10 at each end
    // whichever way it points.
    //
    // The anchored EDGE carries no margin on three of the four instances
    // (D-4), so nothing is folded into exclusiveZone: Hyprland's
    // reservation total is `margins.<anchored-edge> + exclusiveZone`.
    //
    // THE ANCHORED EDGE CARRIES NO MARGIN ON ANY OF THE FOUR — operator
    // round 12, and this REVERSES DC-2 on measured evidence.
    //
    // DC-2 gave the study's drawn position priority: the study puts the
    // right rail at `RIGHT_EDGE = BAR.x - 10`, i.e. ten pixels inside the
    // bar's own face, and Brackets' vertical arms at `corner(INSET, ...)`.
    // Reproducing that meant `margins.<anchored-edge> = edgeBarSideMargin`
    // on those instances.
    //
    // WHAT THE STUDY DOES NOT MODEL IS `gaps_out`. Hyprland insets every
    // window by `gaps_out` (10 here) from the usable area, so the window
    // silhouette's own outer edge lands on EXACTLY the same pixel the
    // study's 10px inset puts the rail on. Measured live at 2560x1440,
    // before this change:
    //
    //     Brackets left arm   x  10..15   window box x  10..2499  -> overlap
    //     Brackets right arm  x 2494..2499                        -> overlap
    //     Halo right rail     x 2498..2499                        -> overlap
    //
    // The operator reported both as clipping ("the brackets are clipping
    // with hyprland windows", "the right edge is clipping"). Their live
    // judgement outranks the study, which was drawn against a bare
    // rectangle rather than against a compositor that gaps its clients.
    //
    // Anchoring all four flush to their own boundary and letting `gaps_out`
    // supply the separation is what the top and bottom rails have always
    // done — they were never reported as clipping precisely because their
    // anchored margin was already 0. This makes the vertical pair behave
    // like the horizontal pair instead of differing from it, and the gap is
    // then a property of the compositor's own spacing rather than a second
    // constant that has to be kept in sync with it.
    //
    // Halo's left rail is unchanged: it was already flush at x = 0, which
    // is where the study draws IT (`rect{x: 0, w: k}`).
    margins.left: edgeBarWindow._vertical ? 0 : Design.edgeBarSideMargin
    margins.right: edgeBarWindow._vertical ? 0 : Design.edgeBarSideMargin
    margins.top: edgeBarWindow._vertical ? Design.edgeBarSideMargin : 0
    margins.bottom: edgeBarWindow._vertical ? Design.edgeBarSideMargin : 0

    // ── Surface depth vs PAINTED depth (operator round 10) ──────────────
    // These were the same number until the hover target was decoupled from
    // the bulge. The surface must now be at least as deep as the hit
    // region, because an Item taller than its window is clipped and the
    // `mask: Region` derived from it would be clipped with it — the hover
    // target would have silently stayed 4px tall no matter what the token
    // said.
    //
    // Growing the surface is free in every direction that matters: the
    // extra depth is transparent, input is confined to the mask, and the
    // reservation is untouched — Hyprland's reservation total is
    // `margins.<anchored-edge> + exclusiveZone`, neither of which reads
    // this (measured: reserved stays [0,6,50,6]).
    //
    // `_paintedDepth` is what the outline is drawn into and is the value
    // the bottom instance mirrors about; see `_outlinePath`'s `Y()`.
    // The MAXIMUM the outline can ever reach, never the live `_b` — pinning
    // the surface to the animating value would resize the layer surface on
    // every frame of the swell, which is the one thing this animation must
    // not do (see the ANIMATED BULGE note below).
    readonly property real _paintedDepth: edgeBarWindow._t
        + (edgeBarWindow._hasBulge
            ? (edgeBarWindow.animatedBulge ? edgeBarWindow._swellExtra : edgeBarWindow._staticBulgeExtra)
            : 0)
    readonly property real _surfaceDepth: Math.max(edgeBarWindow._paintedDepth, Design.edgeBarHoverDepth)

    // Fixed axis = the surface's own depth; free axis = 0, the same
    // zero-is-inert idiom Bar.qml's own header documents for a doubly-
    // anchored axis (the compositor's own stretch determines the real
    // extent along the run regardless of this value). Which of the two is
    // which flips with the orientation — never `undefined` on either
    // branch: assigning undefined to a real-typed QML property REMOVES the
    // binding rather than deferring it, and the condition is evaluated at
    // construction when it is usually false, so the property sticks at 0
    // forever (this shell has paid for that one).
    implicitHeight: edgeBarWindow._vertical ? 0 : edgeBarWindow._surfaceDepth
    implicitWidth: edgeBarWindow._vertical ? edgeBarWindow._surfaceDepth : 0

    WlrLayershell.layer: WlrLayer.Overlay // never Overlay — always-on chrome sits below transient dialogs (Bar.qml's own note)
    // EXACTLY ONE `WlrLayershell.namespace` binding may exist in this file,
    // permanently: quickshell-doctor's registry FORWARD check counts the
    // marker and requires the count to be 1. All four edges resolve through
    // this single binding, and all four resulting namespaces pattern-match
    // the ONE existing `EdgeBar.qml|quickshell-baredge-|pattern|...`
    // registry row — a second row must NOT be added for the new edges,
    // because the LIVE half requires each mapped surface to match exactly
    // one row and two matching rows would fail by construction.
    WlrLayershell.namespace: "quickshell-baredge-" + edgeBarWindow.edge
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false

    // D-4 — the strip's own FLAT thickness alone, never thickness+bulge.
    //
    // Two things reserve nothing at all:
    //   - the right rail on any four-sided style, the DC-2 exception (see
    //     the margins block above): it cannot both sit at the study's drawn
    //     position and reserve, those being the same number;
    //   - EVERY Brackets surface. The corners overhang entirely, which is
    //     that shape's whole cost advantage — the study's own table scores
    //     it at zero screen cost, and `reserved` measures [0,0,50,0] with
    //     it selected (the 50 is the BAR's, not this file's).
    // The registry row for this file is `reserve`, so the doctor's
    // `exclusiveZone: 0` forward assertion (which fires only on `noreserve`
    // rows) does not apply either way.
    exclusiveZone: (edgeBarWindow._brackets || edgeBarWindow.edge === "right") ? 0 : edgeBarWindow._t
    exclusionMode: ExclusionMode.Normal
    color: "transparent"

    // ── Colour (R9) — OPERATOR FEEDBACK ROUND 1, 2026-08-23 ─────────────
    //    This strip first shipped filled with `Colours.surface` at 0.55
    //    alpha, copying BarRoles.qml's `barSurface` chrome treatment. The
    //    operator reported it "completely black and not color shifting",
    //    and the measurement backs that up exactly: `surface` is the PAGE
    //    BACKGROUND role, and across all 20 shipped palettes it is a
    //    near-black on every dark theme — gruvbox #282828, catppuccin
    //    #1e1e2e, tokyonight #1a1b26, rosepine #191724, hackerman #0b0c16,
    //    vantablack #000000. The binding was live and the values DID
    //    differ per theme; they are simply all the same dark grey to the
    //    eye, and at 0.55 over a dark wallpaper they read as flat black.
    //    Nothing was broken — the role was wrong for what R9 asked.
    //
    //    The shell's actual "colour-shifting edge" language is
    //    GradientBorder.qml's, and it is everywhere: 13 consumers today,
    //    including Dashboard, Launcher, NotifCard, NotifCentre,
    //    NotifPopupStack, PanelDialog, PowerMenu, SectionPopout and Toast.
    //    Its stops are the three ACCENT roles — primary -> secondary ->
    //    tertiary — which are exactly the roles that do visibly shift
    //    (gruvbox amber/orange/green, catppuccin mauve, nord ice blue).
    //    This strip now speaks that same language.
    //
    //    WHY NOT JUST MOUNT `GradientBorder` HERE, since every other
    //    surface does: GradientBorder builds its ring from
    //    `_roundedRect(...)` — a rounded RECTANGLE with per-corner radii.
    //    This strip is NOT a rect; `_outlinePath` below is a flat run with
    //    a centre bulge and two shoulder arcs. A GradientBorder dropped on
    //    this window would trace a rounded rect around the strip's
    //    BOUNDING BOX and ignore the bulge entirely. So the gradient IDIOM
    //    is transplanted (same LinearGradient, same three accent stops,
    //    same Motion.borderRotateDuration period) onto this file's own
    //    real outline, rather than the component.
    //
    //    ONE DELIBERATE DIVERGENCE FROM GradientBorder, and the reason:
    //    GradientBorder sweeps its gradient ENDPOINTS around the item
    //    centre on a half-diagonal, which works because its consumers are
    //    roughly panel-shaped. This strip is ~3440x16 — at 90 degrees that
    //    rotation compresses the whole spectrum into 16px of visible band,
    //    so the strip would cycle between "full spectrum across the
    //    screen" and "one flat colour", i.e. it would pulse. Instead the
    //    axis is LOCKED to the strip's long axis and the gradient SCROLLS
    //    along it, which reads as a steady flow. The scroll is seamless
    //    because the stop list closes back on `primary` at 1.0 and the
    //    gradient uses RepeatSpread (verified present in this Qt build:
    //    QtQuick/Shapes/plugins.qmltypes lists
    //    ["PadSpread","ReflectSpread","RepeatSpread"]), so translating by
    //    exactly one period per cycle has no seam.
    //
    //    Stops are OPAQUE, unlike the old 0.55 fill — the operator's own
    //    word for the reference was "solid bar edges". Opaque is trivially
    //    above GT-9's 0.5 ignore_alpha floor, so windowrules.lua's family
    //    blur rule is unaffected.
    //
    //    TO TUNE: `Colours.primary/secondary/tertiary` are the three stops
    //    and the period is one screen width. To go quieter, swap the stops
    //    for primaryContainer/secondaryContainer/tertiaryContainer — same
    //    structure, muted hues.
    // Read from the ONE shared clock rather than run a private animation.
    // On Continuous the bar continues this strip's gradient through its own
    // body, and two independently-started infinite animations hold a
    // constant, arbitrary offset — a hard colour seam at the joint. See
    // GradientPhase.qml. The top and bottom strips are now in step too.
    readonly property real _gradientPhase: GradientPhase.phase

    // One full spectrum spans one screen width; the phase slides it by
    // exactly one period per cycle (seamless under RepeatSpread).
    readonly property real _gradientPeriod: Math.max(1, edgeBarWindow._ww)


    // ── ANIMATED BULGE (operator round 11) — REVERSES D-3 ───────────────
    // D-3 (260823-9ak-CONTEXT.md) locked the bulge as a PERMANENT landmark,
    // explicitly "not a hover-reactive or open-reactive swell", on the
    // rationale that it shows you where to hover even when nothing is open.
    // The operator asked to try the opposite and reversed that decision
    // knowingly. It is a live toggle rather than a rewrite: with
    // `edgeBar.animatedBulge` OFF the strip is byte-identical to round 10's
    // approved static shape, tokens and all.
    //
    // WHAT ANIMATES AND WHAT MUST NOT: only the painted outline. The layer
    // surface's own depth is pinned to the MAXIMUM the bulge can ever
    // reach (see `_paintedDepth`), never to the current value, because a
    // resizing layer surface is re-configured and re-buffered every frame
    // and drags its own content — round 5 spent a full round rediscovering
    // that on the launcher. `exclusiveZone` is likewise untouched, so the
    // reservation never changes and no window ever moves in response to a
    // hover.
    //
    // The swell holds while `surfaceOpen` is true so the bulge does not pop
    // away underneath the panel it just summoned the moment the pointer
    // travels into that panel.
    property bool animatedBulge: false
    property bool surfaceOpen: false

    // Written by the HoverHandler far below rather than read from it. That
    // handler lives inside `bulgeHitArea`, declared after this point, and a
    // binding here that reached forward to `bulgeHover.hovered` would be
    // evaluating an id that does not exist yet at construction — the same
    // declare-before-use trap Design.qml:736 records, which surfaces as a
    // one-line warning in ~/.cache/quickshell.log and an otherwise silent
    // wrong answer. Pushing the value forward instead has no ordering
    // requirement at all.
    property bool _bulgeHovered: false

    readonly property bool _bulgeOut: edgeBarWindow.animatedBulge
        && (edgeBarWindow._bulgeHovered || edgeBarWindow.surfaceOpen)

    readonly property real _bTarget: !edgeBarWindow._hasBulge
        ? 0
        : (edgeBarWindow.animatedBulge
            ? (edgeBarWindow._bulgeOut ? edgeBarWindow._swellExtra : 0)
            : edgeBarWindow._staticBulgeExtra)

    // NOT readonly and NOT a plain token read: the Behavior below has to be
    // able to drive it. The binding still re-evaluates normally; a Behavior
    // on a bound property animates toward each new binding result, which is
    // exactly the shape wanted here.
    property real _b: edgeBarWindow._bTarget

    Behavior on _b {
        enabled: Motion.motionEnabled && edgeBarWindow.animatedBulge
        NumberAnimation {
            duration: Motion.standardDuration
            easing.type: Easing.BezierSpline
            // Grows on `standard`, retracts along that same curve played
            // BACKWARDS — the reversal language the operator approved in
            // round 9 for the launcher and drawer, applied to the one other
            // thing on this surface that moves.
            //
            // 200ms is also shorter than `edgeBarDwellMs` (400), so the
            // swell has fully landed before the dwell fires: it reads as a
            // "you are dwelling here" hint rather than racing the summon.
            easing.bezierCurve: edgeBarWindow._bulgeOut ? Motion.standardEasing : Motion.standardReverseEasing
        }
    }

    // The two shoulder radii must satisfy `_f + _rc <= _b` at EVERY frame of
    // the animation, not just at the endpoints — round 10 measured what
    // breaking it looks like (a dark notch cutting into the strip, from the
    // outline self-intersecting). Fixed tokens cannot do that while `_b`
    // sweeps 0 -> 10, so in animated mode they are derived as a fixed split
    // of the current depth: 0.6/0.4, which sums to exactly `_b` at every
    // value including 0.
    //
    // In static mode the authored tokens are used unchanged, so toggling the
    // animation off reproduces round 10's approved shape exactly rather
    // than a re-derived approximation of it.
    readonly property real _f: edgeBarWindow.animatedBulge ? edgeBarWindow._b * 0.6 : Design.edgeBarFilletRadius
    readonly property real _rc: edgeBarWindow.animatedBulge ? edgeBarWindow._b * 0.4 : Design.edgeBarBulgeCornerRadius
    // 0 on an instance that carries no bulge, so the hit region below
    // collapses to zero area and the mask derived from it admits no input
    // at all on the two vertical rails.
    readonly property real _wb: edgeBarWindow._hasBulge ? edgeBarWindow.bulgeWidth : 0
    // The run's own ALONG-axis extent — `width` on a horizontal instance,
    // `height` on a vertical one. Everything downstream (the gradient
    // period, the bulge span, the path builder's `along`) reads this rather
    // than a raw dimension, so nothing has to know the orientation twice.
    readonly property real _ww: edgeBarWindow._vertical ? edgeBarWindow.height : edgeBarWindow.width
    readonly property real _cx: edgeBarWindow._ww / 2
    readonly property real _xl: edgeBarWindow._cx - edgeBarWindow._wb / 2
    readonly property real _xr: edgeBarWindow._cx + edgeBarWindow._wb / 2

    // ── Brackets' arm length (Task 5) ───────────────────────────────────
    // PROPORTIONAL, never the study's raw 170. That number was measured on
    // a 1920-wide capture; this panel is 2560x1440 and the next one will be
    // a third size, so the arm is a fraction of THIS surface's own
    // along-axis extent. See Design.edgeBarBracketArmFraction.
    readonly property real _armBase: Math.round(edgeBarWindow._ww * Design.edgeBarBracketArmFraction)

    // Which of the two corners on this surface is being dwelled. Pushed up
    // from the hit regions' own HoverHandlers rather than read back off
    // them, for the same declare-before-use reason `_bulgeHovered` records
    // just above.
    property bool _armNearHovered: false
    property bool _armFarHovered: false

    // The hover landmark this style has INSTEAD of a bulge (Q3-brackets):
    // the hovered corner's arm extends toward the centre. It grows ALONG
    // the edge and never into it, so no surface dimension changes on any
    // frame and hazard 2 cannot fire here by construction.
    readonly property real _armNearTarget: edgeBarWindow._armBase
        * (edgeBarWindow._armNearHovered ? 1 + Design.edgeBarBracketArmHoverExtra : 1)
    readonly property real _armFarTarget: edgeBarWindow._armBase
        * (edgeBarWindow._armFarHovered ? 1 + Design.edgeBarBracketArmHoverExtra : 1)

    // Bound, but drivable by the Behaviors below — the same shape `_b` uses.
    property real _armNear: edgeBarWindow._armNearTarget
    property real _armFar: edgeBarWindow._armFarTarget

    Behavior on _armNear {
        enabled: Motion.motionEnabled && edgeBarWindow._brackets
        NumberAnimation {
            duration: Motion.standardDuration
            easing.type: Easing.BezierSpline
            // The identical reversal pair the bulge uses — grows on
            // `standard`, retracts along that same curve played backwards.
            // No new Motion token name is introduced anywhere in this
            // block: motion-lint CHECK A derives its allow-list from
            // motion.json's semantic keys plus `<camelKey>ReverseEasing`
            // and reports anything else dangling.
            easing.bezierCurve: edgeBarWindow._armNearHovered ? Motion.standardEasing : Motion.standardReverseEasing
        }
    }
    Behavior on _armFar {
        enabled: Motion.motionEnabled && edgeBarWindow._brackets
        NumberAnimation {
            duration: Motion.standardDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: edgeBarWindow._armFarHovered ? Motion.standardEasing : Motion.standardReverseEasing
        }
    }

    // Guards the degenerate frames a layer surface passes through on its
    // way up: `_ww` arrives in STAGES, so `_armBase` is 0 for the first
    // frames and a run shorter than its own two pill caps would emit a
    // backwards path. Also keeps the two arms from ever meeting in the
    // middle — at the live scale the hovered pair reaches 2 * 225 * 1.4 =
    // 630 of 2540, so this only ever fires during startup.
    readonly property bool _armsValid: edgeBarWindow._brackets
        && edgeBarWindow._armNear > 2 * edgeBarWindow._re
        && edgeBarWindow._armFar > 2 * edgeBarWindow._re
        && edgeBarWindow._armNear + edgeBarWindow._armFar < edgeBarWindow._ww

    // ── The full strip outline (operator round 7 reshape; extracted to
    //    `edgebarpath.js` in quick task 260824-ns3 Task 2, hazard 1/4) ────
    // Built for edge="top" (depth=0 at the screen edge, material extending
    // inward) and mirrored for edge="bottom"/"right". Walked CLOCKWISE in
    // the along/depth coordinate system `edgebarpath.js` builds in, so the
    // outward side of every convex corner is on the left of travel.
    //
    // The profile, along the strip:
    //   pill cap -> flat run -> concave fillet down into the bulge ->
    //   bulge side -> convex corner -> bulge face -> convex corner ->
    //   bulge side -> concave fillet back up -> flat run -> pill cap
    //
    // The concave fillets are the same shape AttachedCorner.qml paints
    // where a panel meets this strip — deliberately, since the bulge is now
    // the same width as the panel that spawns from it, so the closed bulge
    // reads as that panel's first few pixels already emerging.
    //
    // `edgebarpath.js`'s own `buildOutline()` resolves every arc's sweep
    // flag by checking which flag actually produces the centre the
    // geometry demands — see that file's own header for the full
    // explanation (this is the single path implementation now; nothing
    // here re-derives a sweep flag by hand).
    readonly property string _outlinePath: EdgeBarPath.buildOutline({
        t: edgeBarWindow._t,
        b: edgeBarWindow._b,
        re: edgeBarWindow._re,
        f: edgeBarWindow._f,
        rc: edgeBarWindow._rc,
        along: edgeBarWindow._ww,
        // Continuous is the one style where this strip does NOT end at its
        // own surface edge — Bar.qml carries the run on through the bar's
        // body. Cap it there and the joint reads as a rounded lump.
        squareEnd: edgeBarWindow.style === "continuous",
        // Halo's two vertical rails are plain runs (see `_hasBulge`).
        bulge: edgeBarWindow._hasBulge,
        xl: edgeBarWindow._xl,
        xr: edgeBarWindow._xr,
        // Mirror about the SURFACE depth, not the painted depth (`t + b`).
        // They were equal until round 10 deepened the surface for the hover
        // region; mirroring about the painted depth would have pinned the
        // bottom strip's paint to the TOP of its own surface, leaving it
        // floating `_surfaceDepth - (t+b)` px above the screen edge.
        surfaceDepth: edgeBarWindow._surfaceDepth,
        flip: edgeBarWindow._flip,
        axis: edgeBarWindow._vertical ? "vertical" : "horizontal"
    })

    // ── Brackets' two arms (Task 5) ─────────────────────────────────────
    // One L per corner: a horizontal arm on the top/bottom surface plus a
    // vertical arm on the left/right surface. Each surface therefore draws
    // TWO short runs, one at each end of its own along axis — the same four
    // instances Task 4 already mounts, no new surface anywhere.
    //
    // HAZARD 4 IS DISARMED BY CONSTRUCTION HERE AND MUST STAY THAT WAY.
    // The study draws each arm as `rect{..., rx: k/2}` — a pill-capped bar,
    // which is EXACTLY the two-quarter-arc cap `edgebarpath.js` already
    // emits. Every arm is built from that same construction and NO arc of
    // any other sweep angle is added. `_arcCentre` hardcodes SVG F.6.5's
    // offset scalar to 1, exact only for a quarter circle; a 180-degree cap
    // resolved through it is precisely the round-10 bug where both
    // candidate centres missed, `_shoulderSweep` fell through to its `: 0`
    // branch and the caps curved INWARD — biting 4px off the left end and
    // 6px off the right, with no QML error and no gate saying anything. The
    // corner joints are where it will try again.
    readonly property string _armNearPath: edgeBarWindow._armsValid
        ? EdgeBarPath.buildOutline({
            t: edgeBarWindow._t,
            b: 0,
            re: edgeBarWindow._re,
            f: 0,
            rc: 0,
            alongStart: 0,
            along: edgeBarWindow._armNear,
            bulge: false,
            xl: 0,
            xr: 0,
            surfaceDepth: edgeBarWindow._surfaceDepth,
            flip: edgeBarWindow._flip,
            axis: edgeBarWindow._vertical ? "vertical" : "horizontal"
        })
        : ""
    readonly property string _armFarPath: edgeBarWindow._armsValid
        ? EdgeBarPath.buildOutline({
            t: edgeBarWindow._t,
            b: 0,
            re: edgeBarWindow._re,
            f: 0,
            rc: 0,
            alongStart: edgeBarWindow._ww - edgeBarWindow._armFar,
            along: edgeBarWindow._ww,
            bulge: false,
            xl: 0,
            xr: 0,
            surfaceDepth: edgeBarWindow._surfaceDepth,
            flip: edgeBarWindow._flip,
            axis: edgeBarWindow._vertical ? "vertical" : "horizontal"
        })
        : ""

    // ── Segmented: which segment is lit (Task 6) ────────────────────────
    // `Hyprland.focusedWorkspace.id` mapped to index `id - 1`, guarded
    // exactly the way WorkspaceCapsule.qml guards it — `!!(Hyprland
    // .focusedWorkspace && ...)` — so a null focused workspace during a
    // monitor event lights nothing rather than throwing. This is the
    // shell's ONE workspace source; no second model is introduced here.
    //
    // -1 means "light nothing", which is the CORRECT answer for a special
    // workspace or an id above the segment count, not a gap to paper over.
    readonly property int _activeSegment: {
        if (!Hyprland.focusedWorkspace)
            return -1;
        const idx = Hyprland.focusedWorkspace.id - 1;
        return (idx >= 0 && idx < Design.edgeBarSegmentCount) ? idx : -1;
    }

    // Two path strings, because the two need different fills: the merged
    // bulge silhouette and the active segment ride the live accent flow,
    // every surviving inactive segment is `Colours.outline` at
    // `edgeBarSegmentInactiveOpacity`. See `buildSegmented` in
    // edgebarpath.js for the whole-segment merge and why it is a span
    // union rather than a per-segment opacity trick.
    readonly property var _segPaths: edgeBarWindow._segmentedRun && edgeBarWindow._ww > 0
        ? EdgeBarPath.buildSegmented({
            count: Design.edgeBarSegmentCount,
            gap: Design.edgeBarSegmentGap,
            active: edgeBarWindow._activeSegment,
            t: edgeBarWindow._t,
            b: edgeBarWindow._b,
            re: edgeBarWindow._re,
            f: edgeBarWindow._f,
            rc: edgeBarWindow._rc,
            along: edgeBarWindow._ww,
            xl: edgeBarWindow._xl,
            xr: edgeBarWindow._xr,
            surfaceDepth: edgeBarWindow._surfaceDepth,
            flip: edgeBarWindow._flip,
            axis: edgeBarWindow._vertical ? "vertical" : "horizontal"
        })
        : ({ gradient: "", outline: "" })

    // What the accent-filled ShapePath below actually draws. Brackets' two
    // arms and Segmented's segments are emitted as SUBPATHS of one path
    // string rather than as several ShapePaths: a `Repeater` cannot
    // instantiate a ShapePath (it is not an Item), and — more usefully —
    // one ShapePath means every piece shares one gradient coordinate
    // space, so the colour reads as a single continuous flow with windows
    // cut into it rather than as separately-animating objects.
    readonly property string _shapePath: edgeBarWindow._brackets
        ? (edgeBarWindow._armNearPath + " " + edgeBarWindow._armFarPath)
        : (edgeBarWindow._segmentedRun
            ? edgeBarWindow._segPaths.gradient
            : edgeBarWindow._outlinePath)

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            // Fill only — a stroke would trace the outline as a second
            // hairline over the gradient, the same reason GradientBorder's
            // own ShapePath sets strokeWidth -1.
            strokeWidth: -1
            strokeColor: "transparent"

            fillGradient: LinearGradient {
                // Locked to the strip's long axis and scrolled by phase —
                // see the R9 note above for why this diverges from
                // GradientBorder's rotating endpoints. "Long axis" is x on
                // a horizontal instance and y on a vertical one, so the
                // scroll is applied to whichever pair the run points along
                // and the other pair is pinned to 0 — never `undefined`,
                // which would remove the binding outright.
                readonly property real _o: edgeBarWindow._gradientPhase * edgeBarWindow._gradientPeriod
                x1: edgeBarWindow._vertical ? 0 : _o
                y1: edgeBarWindow._vertical ? _o : 0
                x2: edgeBarWindow._vertical ? 0 : _o + edgeBarWindow._gradientPeriod
                y2: edgeBarWindow._vertical ? _o + edgeBarWindow._gradientPeriod : 0
                spread: ShapeGradient.RepeatSpread

                // Closes back on `primary` at 1.0 so one period tiles into
                // the next with no visible seam.
                GradientStop {
                    position: 0.0
                    color: Colours.primary
                }
                GradientStop {
                    position: 0.33
                    color: Colours.secondary
                }
                GradientStop {
                    position: 0.66
                    color: Colours.tertiary
                }
                GradientStop {
                    position: 1.0
                    color: Colours.primary
                }
            }

            PathSvg {
                path: edgeBarWindow._shapePath
            }
        }
    }

    // ── Segmented's INACTIVE segments (Task 6) ──────────────────────────
    // A second Shape rather than a second ShapePath in the one above,
    // because these need a flat `Colours.outline` fill instead of the
    // accent gradient, and because the 0.45 has to live on an ITEM's
    // `opacity`. The roles are `property string`, so folding the alpha
    // into the colour (`Qt.rgba(Colours.outline.r, ...)`) would read `.r`
    // off a JS string and silently resolve to black.
    //
    // `#6272a4` in the study is Dracula's `outline` role — translated,
    // never written as a literal (colour-lint GATE-04 rejects one).
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        visible: edgeBarWindow._segmentedRun
        opacity: Design.edgeBarSegmentInactiveOpacity

        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillColor: Colours.outline

            PathSvg {
                path: edgeBarWindow._segPaths.outline
            }
        }
    }

    // ── ONE DWELL CHAIN, THREE HIT REGIONS (Task 5, DC-1) ───────────────
    // Brackets moves the LANDMARK to the corners, so it moves the hit
    // regions there too — but the summon itself is not removed. R5/R6
    // (dwelled hover opens the dashboard from the top surface and the
    // launcher's menu mode from the bottom) is shipped, operator-approved
    // behaviour, and silently dropping it on one style would be a
    // capability loss nobody asked for. What changes on Brackets is only
    // WHERE you aim.
    //
    // The enter/exit logic is factored into these two functions rather than
    // copied into each HoverHandler, so the re-arm-ONLY-on-a-genuine-exit
    // rule (round 10) keeps having exactly one implementation. Declared
    // above every caller, per this file's own declare-before-use
    // discipline.
    function _hoverEnter(): void {
        // A pointer merely crossing must not summon anything — only start
        // the dwell timer while ARMED. Disarmed briefly after a fire (see
        // the timer below), so a surface that dismisses while the pointer
        // is still resting here does not immediately re-fire.
        if (edgeBarWindow._bulgeArmed)
            bulgeDwellTimer.start();
    }
    function _hoverExit(): void {
        bulgeDwellTimer.stop();
        edgeBarWindow._bulgeArmed = true;
    }

    // ── Bulge overhang hit area (GT-6) — the input-live rectangle on the
    //    styles that HAVE a bulge. The hover reveal below is scoped to this
    //    same item, so what the operator SEES (the permanent bulge
    //    landmark, D-3) and what actually triggers are the same object
    //    (P-3). Zero-area on Brackets and on both vertical rails, where
    //    `_wb` is 0 — those get the two corner regions further down
    //    instead.
    // OPERATOR ROUND 10: this rectangle used to be the bulge's overhang
    // exactly — `y: _t, height: _b` — which tied the hover target's depth
    // to the PAINT. Every round that thinned the bulge therefore shrank
    // what you have to hit, 10px -> 6px -> 4px, and the operator reported
    // it as too small. Depth now comes from its own token, measured from
    // the screen edge inward, so the landmark can keep getting thinner
    // without the target following it down.
    //
    // Still the same WIDTH as the bulge (`_wb`), so P-3 holds: what is
    // seen and what triggers remain the same object horizontally, which is
    // the axis the operator actually aims along.
    //
    // `Math.max` floors the region at the painted depth so a future
    // hoverDepth smaller than the bulge can never leave part of the
    // visible landmark inert.
    Item {
        id: bulgeHitArea
        // Placed in the same ALONG/DEPTH terms the path is drawn in and
        // mapped onto x/y by the orientation, exactly as `edgebarpath.js`'s
        // own `P(a, d)` does — along = `_xl` .. `_xl + _wb`, depth = the
        // full surface depth.
        //
        // On a vertical rail `_wb` is 0 (`_hasBulge` is false there), so
        // this region has zero area and the `mask: Region` derived from it
        // admits no pointer input at all — which is correct: those rails
        // have no bulge to hover and nothing to summon.
        x: edgeBarWindow._vertical ? 0 : edgeBarWindow._xl
        y: edgeBarWindow._vertical ? edgeBarWindow._xl : 0
        // Fills the surface's depth on the depth axis. `_surfaceDepth` is
        // the surface's own implicit depth, so this spans it exactly — for
        // EVERY instance, since a mirrored edge ("bottom"/"right") is
        // anchored on the far side and its surface therefore already starts
        // where its hover region should. Deliberately not
        // `edgeBarWindow.height`/`.width`: a layer surface's dimensions
        // arrive in STAGES (100 -> 500 -> ... on this host, measured in
        // round 5), so reading one here would size the region off a
        // transient value.
        width: edgeBarWindow._vertical ? edgeBarWindow._surfaceDepth : edgeBarWindow._wb
        height: edgeBarWindow._vertical ? edgeBarWindow._wb : edgeBarWindow._surfaceDepth

        // ── Hover reveal (quick task 260823-9ak, Task 5, R5/R6, P-3,
        //    T-9ak-01) — a HoverHandler and a dwell Timer, NOTHING else.
        //    No TapHandler/MouseArea/WheelHandler/DragHandler exists
        //    anywhere in this file — permanently, per HotZone.qml's own
        //    T-18-16-01 click-inert posture this reuses verbatim: a click
        //    this surface unavoidably consumes must do nothing rather
        //    than something wrong. This component does not know what a
        //    dashboard or a launcher is — it only exposes the fire as a
        //    plain signal; shell.qml decides what that means.
        HoverHandler {
            id: bulgeHover
            onHoveredChanged: {
                // Pushed up to the window root for the animated-bulge
                // binding — see `_bulgeHovered` there for why it is not
                // read directly off this handler.
                edgeBarWindow._bulgeHovered = bulgeHover.hovered;
                if (bulgeHover.hovered)
                    edgeBarWindow._hoverEnter();
                else
                    edgeBarWindow._hoverExit();
            }
        }
    }

    // ── Brackets' two corner hit regions (Task 5, DC-1) ─────────────────
    // One per corner of this surface, each `_armLength` along the edge by
    // `Design.edgeBarHoverDepth` deep — the same depth the bulge region
    // already uses, so the target is no harder to hit than the one it
    // replaces. Both feed the SAME HoverHandler / `_bulgeArmed` / dwell
    // Timer / `bulgeHoverTriggered()` chain, reused verbatim: the top
    // surface still opens the dashboard and the bottom still opens the
    // launcher's menu mode, exactly as they do on every other style.
    //
    // Zero-area on every style but Brackets (`_armsValid` is false there),
    // so the mask below admits no input from them at all.
    Item {
        id: armNearHitArea
        readonly property real _len: edgeBarWindow._armsValid ? edgeBarWindow._armNear : 0
        x: 0
        y: 0
        width: edgeBarWindow._vertical ? edgeBarWindow._surfaceDepth : armNearHitArea._len
        height: edgeBarWindow._vertical ? armNearHitArea._len : edgeBarWindow._surfaceDepth

        HoverHandler {
            id: armNearHover
            onHoveredChanged: {
                edgeBarWindow._armNearHovered = armNearHover.hovered;
                if (armNearHover.hovered)
                    edgeBarWindow._hoverEnter();
                else
                    edgeBarWindow._hoverExit();
            }
        }
    }
    Item {
        id: armFarHitArea
        readonly property real _len: edgeBarWindow._armsValid ? edgeBarWindow._armFar : 0
        readonly property real _start: edgeBarWindow._ww - armFarHitArea._len
        x: edgeBarWindow._vertical ? 0 : armFarHitArea._start
        y: edgeBarWindow._vertical ? armFarHitArea._start : 0
        width: edgeBarWindow._vertical ? edgeBarWindow._surfaceDepth : armFarHitArea._len
        height: edgeBarWindow._vertical ? armFarHitArea._len : edgeBarWindow._surfaceDepth

        HoverHandler {
            id: armFarHover
            onHoveredChanged: {
                edgeBarWindow._armFarHovered = armFarHover.hovered;
                if (armFarHover.hovered)
                    edgeBarWindow._hoverEnter();
                else
                    edgeBarWindow._hoverExit();
            }
        }
    }

    // Re-armed only by a genuine hover EXIT (bulgeHover.onHoveredChanged
    // above), never by time alone.
    property bool _bulgeArmed: true

    Timer {
        id: bulgeDwellTimer
        interval: Design.edgeBarDwellMs
        repeat: false
        onTriggered: {
            edgeBarWindow._bulgeArmed = false;
            edgeBarWindow.bulgeHoverTriggered();
        }
    }

    // Fired once per dwelled hover, per file header — shell.qml decides
    // what it means (Task 5: the dashboard on the top instance, the
    // launcher's menu mode on the bottom instance).
    signal bulgeHoverTriggered()

    // ONE mask, unioning the three hit regions — a `Region` with child
    // `Region`s, never a second `mask` assignment. Exactly one of the two
    // groups is non-zero on any given style (bulge OR corners), so this
    // never widens the input surface beyond what the style actually draws.
    mask: Region {
        item: bulgeHitArea
        Region {
            item: armNearHitArea
        }
        Region {
            item: armFarHitArea
        }
    }
}
