.pragma library

// edgebarpath.js — the edge bar's single path-building implementation
// (quick task 260824-ns3, Task 2, hazard 1 + hazard 4). Extracted
// verbatim from EdgeBar.qml's own `_arcCentre`/`_shoulderSweep`/
// `_outlinePath` (round 7-11 vocabulary, quick task 260823-9ak Task 3)
// and then taught a second axis. No `Design.*`, `Colours.*`, `Motion.*`
// or any other QML identifier appears anywhere in this file — every
// input arrives as an explicit numeric argument, which is what makes
// this testable under plain `node`
// (hypr/.config/hypr/scripts/tests/edgebar-path-test.mjs) and what keeps
// `colour-lint` structurally satisfied.
//
// `.pragma library` makes this a stateless JS module, the same idiom
// launcher/fuzzy.js already established in this repo — a single shared
// instance across every `import "edgebarpath.js" as EdgeBarPath`, no QML
// type declared here, so no `qmldir` entry is needed (only `.qml` types
// require one).

// Candidate arc centre for a minor (large-arc-flag=0) arc from
// (x1,y1) to (x2,y2) at the given radius, per the SVG endpoint-to-
// centre formula (spec F.6.5): `sweepPositive` selects which of the
// two valid centres (large-arc-flag != sweep-flag when true).
//
// ── DOMAIN: 90-DEGREE ARCS ONLY (operator round 10, 2026-08-24) ─────
// F.6.5's offset from the chord midpoint is
//   sqrt((r^2 - d^2) / d^2) * (y1p, -x1p),   d^2 = x1p^2 + y1p^2
// and this function omits that scalar, i.e. it hardcodes it to 1. That
// is exact when d^2 = r^2/2 — a quarter-circle, chord = r*sqrt(2) —
// and wrong for every other sweep angle.
//
// Every fillet and bulge corner in `buildOutline` is a quarter arc, so
// this held. The two pill caps were NOT: each was one 180-degree arc,
// for which the true centre is the chord midpoint (offset zero). With
// the scalar pinned at 1 the two candidates came out r to either side
// of that midpoint, so NEITHER matched the expected centre and
// `_shoulderSweep` fell through to its `: 0` branch — the INWARD
// direction. Measured on the live strip: the top edge's ends curved
// concave, biting 4px off the left and 6px off the right, while the
// bottom edge looked right purely because `Y()` mirrors the path and
// flips which flag means outward.
//
// The scalar is deliberately NOT added here. Adding it would be a
// floating-point change on four arcs that currently resolve exactly,
// and `_shoulderSweep` matches its expected centre to a 0.01
// tolerance — a wrong flag there silently inverts a fillet with no
// error anywhere. The caps are drawn as two quarter arcs each instead
// (see `buildOutline`), which brings them inside this domain and lets
// the same verify-the-centre mechanism resolve them like everything
// else.
//
// EVERY arc this task and every future consumer of this file emits
// MUST be a quarter circle. If a non-quarter arc is ever genuinely
// necessary, add the scalar back AND re-verify all four existing arcs
// against the golden test, in that order — not the reverse.
function _arcCentre(x1, y1, x2, y2, r, sweepPositive) {
    var x1p = (x1 - x2) / 2, y1p = (y1 - y2) / 2;
    var sign = sweepPositive ? 1 : -1;
    return { x: sign * y1p + (x1 + x2) / 2, y: -sign * x1p + (y1 + y2) / 2 };
}

// Returns the sweep-flag (0 or 1) whose candidate centre matches the
// EXPECTED centre this geometry demands, rather than a hand-derived
// flag trusted blind — the same caution AttachedCorner.qml's own header
// names.
function _shoulderSweep(x1, y1, x2, y2, r, expectedCx, expectedCy) {
    var c = _arcCentre(x1, y1, x2, y2, r, true);
    return (Math.abs(c.x - expectedCx) < 0.01 && Math.abs(c.y - expectedCy) < 0.01) ? 1 : 0;
}

// buildOutline(params) — every value an explicit numeric/string argument:
//
//   t             flat run depth
//   b             bulge depth beyond the flat run
//   re            pill-cap radius (= t/2, a true semicircle)
//   f             concave shoulder fillet radius
//   rc            convex bulge-corner radius
//   along         the strip's own along-axis extent (was `ww`)
//   xl, xr        the bulge span's along-axis bounds
//   surfaceDepth  the surface's own depth (the mirror axis for `flip`)
//   flip          mirror the depth axis (edge: bottom/right)
//   squareEnd     OPT-IN. Omit the far-end pill cap and finish the run
//                 square, so another surface can continue it without a
//                 visible bulge at the joint. Continuous needs it: the
//                 strip does not terminate there, the bar carries it on.
//                 Default false, so every existing caller — and the
//                 committed golden — is byte-identical by construction.
//   axis          "horizontal" | "vertical" — default "horizontal"
//
// Built entirely in ALONG/DEPTH space — "along" runs the length of the
// strip, "depth" runs from the anchored screen edge inward — and every
// coordinate pair is emitted through ONE helper, `P(a, d)`, which maps
// (along, depth) onto (x, y) for the requested axis: `a + " " + d` for
// horizontal, `d + " " + a` for vertical. `_shoulderSweep`'s
// EXPECTED-centre arguments go through the SAME mapping (see `S()`
// below), so a sweep flag is always resolved by matching the centre
// THIS axis's real geometry demands, never a lookup table — transposing
// swaps handedness (every sweep flag flips), and because the expected
// centre is transposed too, this resolves it automatically rather than
// needing a hand-maintained flip table.
function buildOutline(params) {
    var t = params.t, b = params.b, re = params.re, f = params.f, rc = params.rc;
    var along = params.along, xl = params.xl, xr = params.xr;
    var surfaceDepth = params.surfaceDepth, flip = !!params.flip;
    var squareEnd = !!params.squareEnd;
    var axis = params.axis || "horizontal";
    var vertical = axis === "vertical";

    // (along, depth) -> (x, y) for the requested axis. The ONLY place
    // that decision is made — every coordinate in the path (including
    // the sweep-flag resolver's expected centre, via `S()`) goes through
    // this one function.
    function P(a, d) {
        return vertical ? (d + " " + a) : (a + " " + d);
    }

    var yb = t + b; // the bulge face, in DEPTH units

    // Mirror about the SURFACE depth, not `yb` (the painted depth) — see
    // EdgeBar.qml's own `_outlinePath` comment for why (`_surfaceDepth`
    // vs `_paintedDepth`, operator round 10).
    function Y(v) {
        return flip ? surfaceDepth - v : v;
    }

    // Resolves a sweep flag by transposing BOTH the two real endpoints
    // and the expected centre through the same P()-derived along/depth
    // -> x/y mapping the path itself uses, then matching candidates in
    // that same real coordinate space — never mixing along/depth values
    // with real x/y ones.
    function S(a1, d1, a2, d2, r, expectedA, expectedD) {
        var x1, y1, x2, y2, ex, ey;
        if (vertical) {
            x1 = d1; y1 = a1; x2 = d2; y2 = a2; ex = expectedD; ey = expectedA;
        } else {
            x1 = a1; y1 = d1; x2 = a2; y2 = d2; ex = expectedA; ey = expectedD;
        }
        return _shoulderSweep(x1, y1, x2, y2, r, ex, ey);
    }

    // Clockwise (in along/depth space, matching the original x/y
    // walk-order exactly for axis:"horizontal"). The OUTER edge (depth
    // 0, flush to the screen) is one straight run from cap to cap; the
    // bulge is an excursion of the INNER face only.
    var p = "M " + P(re, Y(0));
    if (squareEnd) {
        // Butt end. The run reaches the surface's far edge at full
        // thickness and stops there with no cap, because something else
        // continues it past this surface's boundary. A pill cap here
        // reads as a rounded lump mid-rail once the continuation is
        // drawn, which is exactly what it looked like.
        p += " L " + P(along, Y(0));
        p += " L " + P(along, Y(t));
    } else {
        p += " L " + P(along - re, Y(0));
        // Right pill cap, as TWO quarter arcs through the cap's outermost
        // point — see `_arcCentre`'s domain note above for why the single-arc
        // form could not have its sweep flag resolved and silently drew
        // inward. PRECONDITION, the token pair's own contract: this is a true
        // semicircle only while `re == t / 2`.
        p += " A " + re + " " + re + " 0 0 " + S(along - re, Y(0), along, Y(re), re, along - re, Y(re)) + " " + P(along, Y(re));
        p += " A " + re + " " + re + " 0 0 " + S(along, Y(re), along - re, Y(t), re, along - re, Y(re)) + " " + P(along - re, Y(t));
    }
    // Inner face inward to the right shoulder.
    p += " L " + P(xr + f, Y(t));
    // Concave fillet down into the bulge's right side.
    p += " A " + f + " " + f + " 0 0 " + S(xr + f, Y(t), xr, Y(t + f), f, xr + f, Y(t + f)) + " " + P(xr, Y(t + f));
    p += " L " + P(xr, Y(yb - rc));
    // Convex corner, bulge face, convex corner.
    p += " A " + rc + " " + rc + " 0 0 " + S(xr, Y(yb - rc), xr - rc, Y(yb), rc, xr - rc, Y(yb - rc)) + " " + P(xr - rc, Y(yb));
    p += " L " + P(xl + rc, Y(yb));
    p += " A " + rc + " " + rc + " 0 0 " + S(xl + rc, Y(yb), xl, Y(yb - rc), rc, xl + rc, Y(yb - rc)) + " " + P(xl, Y(yb - rc));
    // Up the bulge's left side, concave fillet back to the flat run.
    p += " L " + P(xl, Y(t + f));
    p += " A " + f + " " + f + " 0 0 " + S(xl, Y(t + f), xl - f, Y(t), f, xl - f, Y(t + f)) + " " + P(xl - f, Y(t));
    // Inner face onward to the left cap.
    p += " L " + P(re, Y(t));
    // Left pill cap, same two-quarter-arc construction as the right.
    p += " A " + re + " " + re + " 0 0 " + S(re, Y(t), 0, Y(re), re, re, Y(re)) + " " + P(0, Y(re));
    p += " A " + re + " " + re + " 0 0 " + S(0, Y(re), re, Y(0), re, re, Y(re)) + " " + P(re, Y(0));
    return p + " Z";
}
