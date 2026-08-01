// GradientBorder.qml — an animated gradient rim, matching Hyprland's own
// window border (DASH-10, Phase 14).
//
// WHAT THIS IS
// Hyprland draws focused windows with a multi-stop gradient border whose
// angle rotates continuously (`general:col.active_border` + the `borderangle`
// animation, `style=loop`). The dashboard drawer is a layer-shell surface,
// not a window, so it gets no border from the compositor at all. This
// component reproduces that treatment so the drawer reads as part of the same
// desktop rather than as a foreign panel.
//
// EXACT PARITY, NOT AN IMITATION — every value below is either a token or a
// live-verified Hyprland setting, none is a taste call:
//   - stops       Colours.primary -> secondary -> tertiary. On this theme
//                 those resolve to #ff79c6 / #bd93f9 / #8be9fd, which is
//                 BYTE-IDENTICAL to the live `general:col.active_border`
//                 gradient. Reading them as tokens rather than hex keeps the
//                 repo-wide zero-hex invariant intact AND means the border
//                 re-themes with everything else on a theme switch.
//   - width       `general:border_size` (3 on this host).
//   - start angle `col.active_border`'s own 45deg.
//   - period      Motion.borderRotateDuration — the SAME `border-rotate`
//                 token Hyprland's `borderangle` consumes, already
//                 ceiling-clamped by lib/motion.sh to what Hyprland actually
//                 runs, so the drawer's rim and every window border on screen
//                 stay in step at every motion-scale preset.
//
// ── HOW THE RIM IS DRAWN, AND WHY NOT WITH A MASK ────────────────────────
// The first implementation of this file drew the full gradient and masked it
// to a ring with `MultiEffect` + a bordered `Rectangle` as the mask shape.
// It worked, but the human reported the rounded bottom corners as visibly
// pixelated, and measurement confirmed it: walking the corner arc, the first
// non-background pixel jumped straight to the full rim colour with no
// intermediate blend — a hard, binary edge.
//
// Two fixes were tried against that design and BOTH failed, which is what
// condemned the approach rather than the parameters:
//   1. `layer.samples: 4` + `antialiasing: true` on the mask — no visible
//      change. The mask's own rasterisation was not the bottleneck.
//   2. `maskSpreadAtMin: 0.4` on the MultiEffect — far worse: it widened the
//      mask threshold until the whole interior filled with gradient.
// The mask path runs the shape through an offscreen texture and then applies
// an alpha threshold, and a thresholded texture lookup cannot reproduce a
// crisp analytic curve at a 3px stroke width.
//
// So the rim is now real geometry: a `Shape` whose `ShapePath` contains TWO
// closed rounded-rect subpaths — the outer edge and the inner edge — filled
// with `ShapePath.OddEvenFill`. The odd-even rule leaves the interior (two
// crossings) unfilled, so the fill lands exactly on the band between the two
// paths. `Shape.CurveRenderer` then antialiases that band analytically rather
// than by sampling a texture, which is the whole point.
//
// This also removes the reason the old design needed masking at all. The
// cheap trick of a gradient rect under an opaque inset rect was never usable
// here — the drawer's surface is translucent over a compositor blur, so an
// inset "cover" would let the gradient show through the whole panel — but
// with real ring geometry nothing is covering anything, so translucency
// stops mattering.
//
// ROTATION
// Nothing rotates geometrically. The gradient's own endpoints are swept
// around the centre of the item, which rotates the gradient direction
// without moving the ring. `LinearGradient` endpoints are item coordinates,
// so they are placed on a circle of the item's half-diagonal to guarantee the
// gradient spans the whole rim at every angle.
//
// The spin is gated on `Motion.motionEnabled`, so the `off` motion-scale
// preset yields a still gradient rather than an animation that ignores the
// axis. This surface is summon-only (the drawer's whole window is destroyed
// on dismiss), so a continuously-running animation here does not violate the
// zero-idle doctrine: nothing spins while the drawer is closed.
import QtQuick
import QtQuick.Shapes
import "../"

Item {
    id: root

    // Hyprland's `general:border_size`. Not a token — Hyprland's border width
    // has no representation in the motion/colour pipelines — so it is named
    // here once rather than repeated at the call site.
    property int borderWidth: 3

    // `col.active_border`'s own starting angle, kept separate from the
    // animated `angle` so the loop can run a clean 0->360 while still
    // beginning where Hyprland begins.
    property real startAngle: 45

    // Per-corner radii, mirroring Rectangle's own property names so a caller
    // can hand across exactly what it gave its surface. The drawer is
    // square-topped and round-bottomed, so a single uniform `radius` would
    // not fit it.
    property real topLeftRadius: 0
    property real topRightRadius: 0
    property real bottomLeftRadius: 0
    property real bottomRightRadius: 0

    // Lets a caller stop the spin without unloading the component.
    property bool active: true

    property real angle: 0

    // Half-diagonal: the radius the gradient endpoints ride on, so the
    // gradient axis still spans the entire rim at every rotation angle.
    readonly property real _halfDiagonal: Math.sqrt(width * width + height * height) / 2

    readonly property real _radians: (root.startAngle + root.angle) * Math.PI / 180

    // ── Ring path ───────────────────────────────────────────────────────
    // One SVG path string holding two closed rounded-rect subpaths. Built in
    // JS rather than from Path elements because this Qt build has no
    // `PathRectangle` (checked against QtQuick/Shapes' own qmltypes), so the
    // alternative is a fixed chain of PathLine/PathArc segments that cannot
    // drop an arc when a corner radius is 0 — and this drawer has two square
    // corners and two round ones.
    function _roundedRect(x, y, w, h, tl, tr, br, bl) {
        // Clamp so no pair of radii on an edge can exceed that edge's length,
        // which would otherwise produce a self-crossing path.
        var m = Math.min(w, h) / 2;
        tl = Math.max(0, Math.min(tl, m));
        tr = Math.max(0, Math.min(tr, m));
        br = Math.max(0, Math.min(br, m));
        bl = Math.max(0, Math.min(bl, m));
        var p = "M " + (x + tl) + " " + y;
        p += " L " + (x + w - tr) + " " + y;
        if (tr > 0)
            p += " A " + tr + " " + tr + " 0 0 1 " + (x + w) + " " + (y + tr);
        p += " L " + (x + w) + " " + (y + h - br);
        if (br > 0)
            p += " A " + br + " " + br + " 0 0 1 " + (x + w - br) + " " + (y + h);
        p += " L " + (x + bl) + " " + (y + h);
        if (bl > 0)
            p += " A " + bl + " " + bl + " 0 0 1 " + x + " " + (y + h - bl);
        p += " L " + x + " " + (y + tl);
        if (tl > 0)
            p += " A " + tl + " " + tl + " 0 0 1 " + (x + tl) + " " + y;
        return p + " Z";
    }

    readonly property string _ringPath: {
        var bw = root.borderWidth;
        // Inner radii shrink by the stroke width so the band keeps a constant
        // thickness around the curve instead of pinching at the corners.
        var outer = root._roundedRect(0, 0, root.width, root.height, root.topLeftRadius, root.topRightRadius, root.bottomRightRadius, root.bottomLeftRadius);
        var inner = root._roundedRect(bw, bw, Math.max(0, root.width - bw * 2), Math.max(0, root.height - bw * 2), Math.max(0, root.topLeftRadius - bw), Math.max(0, root.topRightRadius - bw), Math.max(0, root.bottomRightRadius - bw), Math.max(0, root.bottomLeftRadius - bw));
        return outer + " " + inner;
    }

    Shape {
        anchors.fill: parent
        // Analytic antialiasing — this is the property that fixes the
        // pixelated corners the mask-based implementation could not.
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            // Odd-even leaves the interior unfilled, so the fill lands on the
            // band between the two subpaths regardless of their winding.
            fillRule: ShapePath.OddEvenFill
            // Fill only: a stroke here would sit on BOTH subpath outlines and
            // read as two hairlines rather than one solid rim.
            strokeWidth: -1
            strokeColor: "transparent"

            fillGradient: LinearGradient {
                x1: root.width / 2 - Math.cos(root._radians) * root._halfDiagonal
                y1: root.height / 2 - Math.sin(root._radians) * root._halfDiagonal
                x2: root.width / 2 + Math.cos(root._radians) * root._halfDiagonal
                y2: root.height / 2 + Math.sin(root._radians) * root._halfDiagonal

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
                path: root._ringPath
            }
        }
    }

    // Linear and looping, matching `borderangle`'s own `style=loop` and
    // `motion-linear` curve. `Easing.Linear` is QML's own enum rather than a
    // bezier read off the token: the token's `linear` curve is [1,1,1,1],
    // which is a Hyprland curve-registration value, and feeding it to
    // BezierSpline would NOT produce uniform rotation. The period — the part
    // that actually has to match Hyprland — still comes from the token.
    NumberAnimation on angle {
        running: Motion.motionEnabled && root.active
        from: 0
        to: 360
        duration: Motion.borderRotateDuration
        loops: Animation.Infinite
        easing.type: Easing.Linear
    }
}
