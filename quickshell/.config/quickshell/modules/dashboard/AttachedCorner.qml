// AttachedCorner.qml — the concave flare that joins a panel's vertical side
// to the screen edge it hangs from (quick task 260823-9ak, Task 1, R7).
//
// WHAT THIS IS, AND WHY IT IS ADDITIVE (P-1)
// R7 asks for a concave corner where a panel meets the edge it attaches to.
// The panel's own fill is a plain `Rectangle` (Launcher.qml/Dashboard.qml),
// and a `Rectangle` cannot render a concave corner at all — and the flare
// must paint OUTSIDE the panel's own bounds, which a component filling the
// panel could never do either. So this is a SEPARATE piece, instantiated
// twice per panel (one per side) as a sibling of the panel's own background,
// painting its own fill and its own rim segment. Neither existing panel's
// `Rectangle` + `GradientBorder` pair is touched.
//
// ── THE GEOMETRY, WORKED OUT ONCE SO IT NEVER NEEDS RE-DERIVING ─────────
// One instance owns a square of side `flareRadius` (R), local origin at its
// own top-left, x right, y down — exactly like every other item in this
// tree. `edge` ("top"/"bottom") picks which local y is the screen-edge
// line; `side` ("left"/"right") picks which local x is the panel-touching
// line. Four corners of that square:
//   touchX = side === "left" ? R : 0      — the line flush against the panel
//   edgeY  = edge === "top"  ? 0 : R      — the line flush against the edge
//   farX   = R - touchX                   — the outermost x (away from panel)
//   farY   = R - edgeY                    — the outermost y (away from edge)
//
// The FILL is the closed loop (farX,edgeY) -> (touchX,edgeY) -> (touchX,farY)
// -> arc -> back to (farX,edgeY), where the arc is centred on (farX,farY) —
// the box's OWN diagonally-opposite corner from the shared (touchX,edgeY)
// corner where the two straight runs meet. Both arc endpoints are exactly R
// from that centre by construction (each is R away along one of the box's
// own edges), which is the check the plan text asked to confirm before
// writing this. The arc is tangent to the screen-edge run at (farX,edgeY)
// and tangent to the panel-touching run at (touchX,farY) — both runs meet
// the arc along the SAME line they already travel, so the curve reads as a
// seamless continuation of each flat run rather than a kink. This is the
// concave "quarter-pipe" shape: solid material hugs the shared (touchX,
// edgeY) corner, tapering away via the arc, leaving the diagonally-opposite
// corner (farX,farY) as open background — the opposite of a normal convex
// rounded-rectangle corner, whose arc centre sits INSET from the true
// corner rather than coinciding with the box's own opposite corner.
//
// SWEEP-FLAG DERIVATION (the trap the plan text warns about — the wrong
// flag silently picks the OTHER geometrically valid centre for the same two
// endpoints and radius, i.e. (touchX,edgeY)'s mirror, which produces a
// convex bulge instead). Worked through the SVG endpoint-to-centre formula
// (spec §F.6.5) for start=(touchX,farY), end=(farX,edgeY), radius R: with
// s = (side === "left" ? 1 : -1) and t = (edge === "top" ? 1 : -1), the
// centre lands on (farX,farY) — the one this file wants — exactly when
// large-arc-flag == sweep-flag. This file always wants the MINOR (90°) arc,
// so large-arc-flag is always 0, which pins sweep-flag = 0 when s*t = 1
// (top+left or bottom+right) and sweep-flag = 1 when s*t = -1 (top+right or
// bottom+left) — i.e. `sweep = ((side === "left") === (edge === "top")) ?
// 0 : 1`. The other two combinations (edge/side pairs) are this same
// formula, not four hand-authored path strings.
//
// ── WHY THE RIM IS A FILLED RIBBON, NOT A STROKE ─────────────────────────
// `ShapePath` has no gradient-stroke property in this Qt build (only
// `fillGradient`, verified against
// /usr/lib/qt6/qml/QtQuick/Shapes/plugins.qmltypes) — the same fact that
// makes GradientBorder.qml build its ring as two nested closed paths filled
// with a gradient rather than a stroked single path. This file reuses that
// same principle for a NON-closed rim: the outer boundary is the arc-plus-
// screen-edge-run at radius R (matching the fill's own outer boundary
// exactly, so there is no seam between fill and rim), the inner boundary is
// the same shape offset inward by `borderWidth` (arc radius R-borderWidth,
// concentric on the same centre; the straight run offset perpendicular by
// borderWidth), and the two are joined into ONE closed ribbon polygon by
// two short straight caps. The inner arc runs the endpoints in the OPPOSITE
// order from the outer arc (it traces back from the far end to the shared-
// corner end), so it needs the FLIPPED sweep flag for the same centre —
// `1 - sweep`, not `sweep` again.
//
// Deliberately excludes the panel-touching run (the plan's own
// instruction): a rim stroke there would sit directly on top of the
// panel's own `GradientBorder` rim at that exact seam and read as two
// hairlines rather than one continuous line — the identical reasoning
// GradientBorder.qml's own header already records for why its ring is
// filled rather than double-stroked at a shared edge.
//
// NO ANIMATION LIVES HERE. `angle` is a plain input, driven by whichever
// host `GradientBorder` this instance is attached to (its `startAngle +
// angle`, so the two components' gradients read the same effective
// rotation at every frame) — a second independent loop here would drift
// out of phase with the panel's own rim within seconds.
import QtQuick
import QtQuick.Shapes
import "../"

Item {
    id: root

    // ── Public properties, in the order construction-time reads them ────
    property real flareRadius: 24
    property string edge: "top" // "top" | "bottom"
    property string side: "left" // "left" | "right"
    property color fillColour: "transparent" // colour-typed (GT-5) — never a Colours.* string role read directly
    property int borderWidth: 3
    property real angle: 0 // driven from outside; see file header
    property point gradientCentre: Qt.point(0, 0) // this instance's local coords
    property real gradientHalfDiagonal: 0

    width: root.flareRadius
    height: root.flareRadius

    readonly property real _radians: root.angle * Math.PI / 180

    // ── Shared corner geometry (see file header for the full derivation) ─
    function _cornerGeometry() {
        var r = root.flareRadius;
        var touchX = root.side === "left" ? r : 0;
        var edgeY = root.edge === "top" ? 0 : r;
        var farX = r - touchX;
        var farY = r - edgeY;
        var sweep = ((root.side === "left") === (root.edge === "top")) ? 0 : 1;
        return {
            touchX: touchX,
            edgeY: edgeY,
            farX: farX,
            farY: farY,
            sweep: sweep
        };
    }

    // The solid fill: (farX,edgeY) -> (touchX,edgeY) -> (touchX,farY) ->
    // arc, centred on (farX,farY), back to (farX,edgeY).
    readonly property string _fillPath: {
        var g = root._cornerGeometry();
        var r = root.flareRadius;
        var p = "M " + g.farX + " " + g.edgeY;
        p += " L " + g.touchX + " " + g.edgeY;
        p += " L " + g.touchX + " " + g.farY;
        p += " A " + r + " " + r + " 0 0 " + g.sweep + " " + g.farX + " " + g.edgeY;
        return p + " Z";
    }

    // The rim ribbon: the ARC ALONE, as a band between radius R and
    // R + borderWidth, concentric on the same centre (farX, farY).
    //
    // ── TWO CORRECTIONS, OPERATOR FEEDBACK ROUND 3 (2026-08-23), both
    //    found by pixel-measuring a region capture rather than by reading
    //    this file ─────────────────────────────────────────────────────
    //
    // (1) THE BAND WAS ON THE WRONG SIDE OF ITS OWN ARC. It used to run
    //     from R - borderWidth to R, i.e. offset TOWARD the centre. That
    //     is right for a CONVEX corner, where the material lies inside the
    //     arc — and wrong here, because this corner is CONCAVE: the solid
    //     fill is the region at radius >= R (see `_fillPath`, whose arc
    //     bulges toward the centre and leaves (farX,farY) as open
    //     background). Offsetting inward therefore painted the rim into
    //     the EMPTY quarter, floating clear of the fill it was meant to
    //     edge. Measured on the launcher's bottom-left flare, arc centre
    //     (911,1408) R=24: at y=1422 the band sat at x 926-929, while the
    //     fill boundary was at x=930.5 — the rim was outside its own
    //     material, and read as a second line beside the panel's border.
    //     The junction was measurably discontinuous too: the panel's own
    //     3px border ran at x 935-937 down to y=1407, then the band
    //     resumed at x 932-934 — a 3px lateral jog, exactly borderWidth.
    //
    //     At R -> R + borderWidth the same junction lands at x 935-938,
    //     which is the panel border's own 935-937 span. The two rims are
    //     then colinear at the seam by construction, not by tuning.
    //
    // (2) THE SCREEN-EDGE RUN IS NO LONGER PART OF THE RIM. It used to be
    //     included on the reasoning that it is an outer boundary. Once the
    //     panel sits flush against the strip that is false: the run along
    //     the edge is where flare material MEETS the strip, an interior
    //     seam of the merged silhouette, and drawing it left a ~24px
    //     horizontal rim stub beside the panel's bottom on each side
    //     (measured at y 1429-1431). The rim is now the arc alone — the
    //     only genuinely outer boundary this piece owns. The panel-
    //     touching run stays excluded for the original reason.
    //
    // The band extends borderWidth PAST this Item's own R x R box at both
    // arc endpoints, which is intended: at the panel end it overlaps the
    // panel's own border span so the seam is continuous, and at the edge
    // end it runs into the strip, where the host surface's own bounds clip
    // it. QQuickShape does not clip to its item rect, so this renders.
    readonly property string _rimPath: {
        var g = root._cornerGeometry();
        var r = root.flareRadius;
        var bw = root.borderWidth;
        var ro = r + bw;
        // Unit directions from the arc centre (farX,farY) out to each of
        // the two arc endpoints. Each is exactly +/-1 because both
        // endpoints sit exactly r away along one of the box's own axes.
        var dx = (g.touchX - g.farX) / r;
        var dy = (g.edgeY - g.farY) / r;
        // The same two endpoints pushed out to the outer radius.
        var oTouchX = g.farX + dx * ro; // beside the panel-touching run
        var oEdgeY = g.farY + dy * ro;  // beside the screen-edge run
        var p = "M " + g.touchX + " " + g.farY;
        p += " A " + r + " " + r + " 0 0 " + g.sweep + " " + g.farX + " " + g.edgeY;
        p += " L " + g.farX + " " + oEdgeY;
        p += " A " + ro + " " + ro + " 0 0 " + (1 - g.sweep) + " " + oTouchX + " " + g.farY;
        return p + " Z";
    }

    Shape {
        anchors.fill: parent
        // Analytic antialiasing — same reason GradientBorder.qml carries
        // this, and the same fix it needed for pixelated curved corners.
        preferredRendererType: Shape.CurveRenderer

        // The solid mass, drawn first so the rim below paints on top of it.
        ShapePath {
            fillColor: root.fillColour
            strokeWidth: -1
            strokeColor: "transparent"
            PathSvg {
                path: root._fillPath
            }
        }

        // The rim, as a filled ribbon (see file header — no gradient-stroke
        // property exists on this Qt build).
        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: root.gradientCentre.x - Math.cos(root._radians) * root.gradientHalfDiagonal
                y1: root.gradientCentre.y - Math.sin(root._radians) * root.gradientHalfDiagonal
                x2: root.gradientCentre.x + Math.cos(root._radians) * root.gradientHalfDiagonal
                y2: root.gradientCentre.y + Math.sin(root._radians) * root.gradientHalfDiagonal

                GradientStop {
                    position: 0.0
                    color: Colours.primary
                }
                GradientStop {
                    position: 0.5
                    color: Colours.secondary
                }
                GradientStop {
                    position: 1.0
                    color: Colours.tertiary
                }
            }
            PathSvg {
                path: root._rimPath
            }
        }
    }
}
