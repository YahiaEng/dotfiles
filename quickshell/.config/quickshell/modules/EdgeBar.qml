// EdgeBar.qml — the always-on top/bottom strip (quick task 260823-9ak,
// Task 3, R1/R4/R8/R9/D-2/D-3/D-4). One type, instantiated twice in
// shell.qml (top and bottom) — never two near-duplicate files.
//
// ── INDEPENDENT FRAME, NOT THE BAR (D-2) ─────────────────────────────────
// `Bar.qml` is not opened, moved, reoriented or absorbed by this file, and
// this file is never imported by it. The live bar orientation on this host
// is `vertical` (right edge — CONTEXT.md's own measured ground truth), so a
// top+bottom strip pair cannot BE the bar; the two coexist. This file does
// not read `BarEntryModel.isVertical` anywhere — it has no orientation of
// its own, only an edge (`bottom`).
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
// This surface sits flush to the screen edge — no margin at all, on any
// edge — so `exclusiveZone` (the strip's own FLAT thickness alone, never
// thickness+bulge) is the entire reservation, and the double-count bug
// Bar.qml's own header records (18-01, 18-05, always a +6 signature) is
// impossible here by construction: there is no second term to fold it
// into. The bulge's extra depth deliberately OVERHANGS into the client
// area rather than being reserved — reserving a full-width band to
// accommodate a centre-only bulge would waste the whole edge.
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
// `edge: "bottom"` is this same outline mirrored in y (the flat run sits
// at the window's own bottom, flush with the screen; the bulge overhangs
// upward, into the client area) — built by parametrising the geometry on
// `bottom`, not by hand-authoring a second path string.
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
import Quickshell.Wayland
import "dashboard"

PanelWindow {
    id: edgeBarWindow

    // Selects which screen edge this instance flares from. shell.qml
    // mounts two instances, one per value.
    property bool bottom: false

    // The centre bulge's width — set per strip by shell.qml so each one
    // matches the surface that spawns from it (operator round 7).
    property real bulgeWidth: Design.edgeBarBulgeWidthTop

    anchors {
        top: !edgeBarWindow.bottom
        bottom: edgeBarWindow.bottom
        left: true
        right: true
    }

    // Side margins align the strip's ends with the Hyprland window
    // silhouette (operator round 7) — see Design.edgeBarSideMargin for the
    // measurement. The anchored EDGE still carries no margin (D-4), so
    // nothing is folded into exclusiveZone: Hyprland's reservation total is
    // margins.<anchored-edge> + exclusiveZone, and only left/right are
    // margined here, neither of which is the anchored edge.
    margins.left: Design.edgeBarSideMargin
    margins.right: Design.edgeBarSideMargin

    // Fixed axis = the strip's full painted extent (flat thickness + bulge
    // overhang); free axis = 0, the same zero-is-inert idiom Bar.qml's own
    // header documents for a doubly-anchored axis (both left and right are
    // anchored here, so the compositor's own stretch determines the real
    // width regardless of this value).
    implicitHeight: Design.edgeBarThickness + Design.edgeBarBulgeExtra
    implicitWidth: 0

    WlrLayershell.layer: WlrLayer.Top // never Overlay — always-on chrome sits below transient dialogs (Bar.qml's own note)
    WlrLayershell.namespace: "quickshell-baredge-" + (edgeBarWindow.bottom ? "bottom" : "top")
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false

    // D-4 — the strip's own FLAT thickness alone, never thickness+bulge.
    exclusiveZone: Design.edgeBarThickness
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
    property real _gradientPhase: 0

    // One full spectrum spans one screen width; the phase slides it by
    // exactly one period per cycle (seamless under RepeatSpread).
    readonly property real _gradientPeriod: Math.max(1, edgeBarWindow._ww)

    NumberAnimation on _gradientPhase {
        running: Motion.motionEnabled
        from: 0
        to: 1
        duration: Motion.borderRotateDuration
        loops: Animation.Infinite
        easing.type: Easing.Linear
    }

    readonly property real _t: Design.edgeBarThickness
    readonly property real _b: Design.edgeBarBulgeExtra
    readonly property real _re: Design.edgeBarEndRadius
    readonly property real _f: Design.edgeBarFilletRadius
    readonly property real _rc: Design.edgeBarBulgeCornerRadius
    readonly property real _wb: edgeBarWindow.bulgeWidth
    readonly property real _ww: edgeBarWindow.width
    readonly property real _cx: edgeBarWindow._ww / 2
    readonly property real _xl: edgeBarWindow._cx - edgeBarWindow._wb / 2
    readonly property real _xr: edgeBarWindow._cx + edgeBarWindow._wb / 2

    // Candidate arc centre for a minor (large-arc-flag=0) arc from
    // (x1,y1) to (x2,y2) at the given radius, per the SVG endpoint-to-
    // centre formula (spec F.6.5): `sweepPositive` selects which of the
    // two valid centres (large-arc-flag != sweep-flag when true).
    function _arcCentre(x1, y1, x2, y2, r, sweepPositive) {
        var x1p = (x1 - x2) / 2, y1p = (y1 - y2) / 2;
        var sign = sweepPositive ? 1 : -1;
        return Qt.point(sign * y1p + (x1 + x2) / 2, -sign * x1p + (y1 + y2) / 2);
    }

    // Returns the sweep-flag (0 or 1) whose candidate centre matches the
    // EXPECTED centre this geometry demands, rather than a hand-derived
    // flag trusted blind — the same caution AttachedCorner.qml's own
    // header names.
    function _shoulderSweep(x1, y1, x2, y2, r, expectedCx, expectedCy) {
        var c = edgeBarWindow._arcCentre(x1, y1, x2, y2, r, true);
        return (Math.abs(c.x - expectedCx) < 0.01 && Math.abs(c.y - expectedCy) < 0.01) ? 1 : 0;
    }

    // ── The full strip outline (operator round 7 reshape) ───────────────
    // Built for edge="top" (y=0 at the screen edge, material extending
    // downward) and mirrored in y for edge="bottom". Walked CLOCKWISE in
    // this y-down coordinate system, so the outward side of every convex
    // corner is on the left of travel.
    //
    // The profile, left to right:
    //   pill cap -> flat run -> concave fillet down into the bulge ->
    //   bulge side -> convex corner -> bulge face -> convex corner ->
    //   bulge side -> concave fillet back up -> flat run -> pill cap
    //
    // The concave fillets are the same shape AttachedCorner.qml paints
    // where a panel meets this strip — deliberately, since the bulge is now
    // the same width as the panel that spawns from it, so the closed bulge
    // reads as that panel's first few pixels already emerging.
    //
    // EVERY arc's sweep flag is resolved by `_shoulderSweep`, which checks
    // which flag actually produces the centre the geometry demands. None is
    // hand-derived: the wrong flag silently selects the other geometrically
    // valid centre for the same endpoints and radius, turning a concave
    // fillet into a convex bulge (or vice versa) with no error anywhere.
    readonly property string _outlinePath: {
        var t = edgeBarWindow._t;          // flat run depth
        var b = edgeBarWindow._b;          // bulge depth beyond the flat run
        var re = edgeBarWindow._re;        // pill-cap radius (= t/2, a true semicircle)
        var f = edgeBarWindow._f;          // concave shoulder fillet radius
        var rc = edgeBarWindow._rc;        // convex bulge-corner radius
        var ww = edgeBarWindow._ww;
        var xl = edgeBarWindow._xl, xr = edgeBarWindow._xr;
        var yb = t + b;                    // the bulge face
        var S = edgeBarWindow._shoulderSweep;

        var flip = edgeBarWindow.bottom;
        var h = yb;
        function Y(v) {
            return flip ? h - v : v;
        }

        // Clockwise. The OUTER edge (y=0, flush to the screen) is one
        // straight run from cap to cap; the bulge is an excursion of the
        // INNER face only.
        var p = "M " + re + " " + Y(0);
        p += " L " + (ww - re) + " " + Y(0);
        // Right pill cap.
        p += " A " + re + " " + re + " 0 0 " + S(ww - re, Y(0), ww - re, Y(t), re, ww - re, Y(re)) + " " + (ww - re) + " " + Y(t);
        // Inner face leftward to the right shoulder.
        p += " L " + (xr + f) + " " + Y(t);
        // Concave fillet down into the bulge's right side.
        p += " A " + f + " " + f + " 0 0 " + S(xr + f, Y(t), xr, Y(t + f), f, xr + f, Y(t + f)) + " " + xr + " " + Y(t + f);
        p += " L " + xr + " " + Y(yb - rc);
        // Convex corner, bulge face, convex corner.
        p += " A " + rc + " " + rc + " 0 0 " + S(xr, Y(yb - rc), xr - rc, Y(yb), rc, xr - rc, Y(yb - rc)) + " " + (xr - rc) + " " + Y(yb);
        p += " L " + (xl + rc) + " " + Y(yb);
        p += " A " + rc + " " + rc + " 0 0 " + S(xl + rc, Y(yb), xl, Y(yb - rc), rc, xl + rc, Y(yb - rc)) + " " + xl + " " + Y(yb - rc);
        // Up the bulge's left side, concave fillet back to the flat run.
        p += " L " + xl + " " + Y(t + f);
        p += " A " + f + " " + f + " 0 0 " + S(xl, Y(t + f), xl - f, Y(t), f, xl - f, Y(t + f)) + " " + (xl - f) + " " + Y(t);
        // Inner face onward to the left cap.
        p += " L " + re + " " + Y(t);
        p += " A " + re + " " + re + " 0 0 " + S(re, Y(t), re, Y(0), re, re, Y(re)) + " " + re + " " + Y(0);
        return p + " Z";
    }

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
                // GradientBorder's rotating endpoints.
                x1: edgeBarWindow._gradientPhase * edgeBarWindow._gradientPeriod
                y1: 0
                x2: edgeBarWindow._gradientPhase * edgeBarWindow._gradientPeriod + edgeBarWindow._gradientPeriod
                y2: 0
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
                path: edgeBarWindow._outlinePath
            }
        }
    }

    // ── Bulge overhang hit area (GT-6) — the only input-live rectangle on
    //    this surface. The hover reveal below is scoped to this same
    //    item, so what the operator SEES (the permanent bulge landmark,
    //    D-3) and what actually triggers are the same object (P-3).
    Item {
        id: bulgeHitArea
        x: edgeBarWindow._xl
        width: edgeBarWindow._wb
        y: edgeBarWindow.bottom ? 0 : edgeBarWindow._t
        height: edgeBarWindow._b

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
                if (bulgeHover.hovered) {
                    // A pointer merely crossing the bulge must not summon
                    // anything — only start the dwell timer while ARMED.
                    // Disarmed briefly after a fire (see the timer below),
                    // so a surface that dismisses while the pointer is
                    // still resting here does not immediately re-fire.
                    if (edgeBarWindow._bulgeArmed)
                        bulgeDwellTimer.start();
                } else {
                    bulgeDwellTimer.stop();
                    edgeBarWindow._bulgeArmed = true;
                }
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

    mask: Region {
        item: bulgeHitArea
    }
}
