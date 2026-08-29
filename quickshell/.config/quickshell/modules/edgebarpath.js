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
//   along         the run's FAR along-axis bound (was `ww`)
//   alongStart    the run's NEAR along-axis bound. Default 0, so every
//                 caller that draws a full-surface run — and the
//                 committed golden — is byte-identical by construction.
//                 Brackets needs it: that style draws TWO short runs per
//                 surface, one at each end, from ONE builder rather than
//                 a second hand-authored path (Task 5).
//   xl, xr        the bulge span's along-axis bounds
//   surfaceDepth  the surface's own depth (the mirror axis for `flip`)
//   flip          mirror the depth axis (edge: bottom/right)
//   squareEnd     OPT-IN. Omit the far-end pill cap and finish the run
//                 square, so another surface can continue it without a
//                 visible bulge at the joint. Continuous needs it: the
//                 strip does not terminate there, the bar carries it on.
//                 Default false, so every existing caller — and the
//                 committed golden — is byte-identical by construction.
//   bulge         OPT-OUT (default true). false emits the flat run with
//                 its two pill caps and NO centre excursion at all —
//                 `b`, `xl`, `xr`, `f` and `rc` are then unread. Halo's
//                 left/right rails need it (nothing attaches on those
//                 edges, so there is nothing for a bulge to be the root
//                 of) and Brackets' four arms need it (Q3-brackets: no
//                 bulge is drawn on that style at all). Written as an
//                 explicit branch rather than "pass b = 0": a zero-depth
//                 bulge still emits four zero-radius arcs and a
//                 backwards face segment when xl == xr, which
//                 self-intersects exactly the way round 10's broken
//                 fillet invariant did — silently, with no error.
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
    var a0 = params.alongStart === undefined ? 0 : params.alongStart;
    var surfaceDepth = params.surfaceDepth, flip = !!params.flip;
    var squareEnd = !!params.squareEnd;
    // Rounds the OUTER corner of a square end (quick task 260829-2ov). 0 (the
    // default) keeps the butt end exactly as it was. Used where a run ends AT
    // a screen corner and turns into a perpendicular run rather than being
    // carried on by something else: the horizontal bar's band turning into
    // the right rail, and the bottom rail turning up into it.
    //
    // MUST be <= t. The arc lands at depth `squareEndRadius`, and the inner
    // face is at depth `t`, so a larger radius would put the arc's end past
    // the face it is supposed to meet and the outline would self-intersect —
    // the same class of silent breakage `bulge: false` exists to avoid.
    var squareEndRadius = params.squareEndRadius === undefined ? 0 : params.squareEndRadius;
    var bulge = params.bulge === undefined ? true : !!params.bulge;
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
    var p = "M " + P(a0 + re, Y(0));
    if (squareEnd) {
        // Butt end. The run reaches the surface's far edge at full
        // thickness and stops there with no cap, because something else
        // continues it past this surface's boundary. A pill cap here
        // reads as a rounded lump mid-rail once the continuation is
        // drawn, which is exactly what it looked like.
        if (squareEndRadius > 0) {
            p += " L " + P(along - squareEndRadius, Y(0));
            // Sweep resolved against the centre this geometry demands, never
            // hand-picked — the file-wide rule. Quarter arc, so inside
            // `_arcCentre`'s documented domain.
            p += " A " + squareEndRadius + " " + squareEndRadius + " 0 0 "
                + S(along - squareEndRadius, Y(0), along, Y(squareEndRadius), squareEndRadius, along - squareEndRadius, Y(squareEndRadius))
                + " " + P(along, Y(squareEndRadius));
        } else {
            p += " L " + P(along, Y(0));
        }
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
    if (bulge) {
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
    }
    // Inner face onward to the left cap. With `bulge: false` this is the
    // WHOLE inner face — one straight run, cap to cap.
    p += " L " + P(a0 + re, Y(t));
    // Left pill cap, same two-quarter-arc construction as the right.
    p += " A " + re + " " + re + " 0 0 " + S(a0 + re, Y(t), a0, Y(re), re, a0 + re, Y(re)) + " " + P(a0, Y(re));
    p += " A " + re + " " + re + " 0 0 " + S(a0, Y(re), a0 + re, Y(0), re, a0 + re, Y(re)) + " " + P(a0 + re, Y(0));
    return p + " Z";
}

// buildSegmented(params) — the Segmented style's top rail, as TWO path
// strings so the caller can fill them differently:
//
//   { gradient, outline }
//
// `gradient` carries everything painted in the live accent flow — the
// merged bulge silhouette (when the bulge has depth) plus the ACTIVE
// segment if that segment survived the merge. `outline` carries every
// surviving inactive segment. Both are multi-subpath strings; either may
// be empty.
//
// Inputs, all explicit numbers as everywhere else in this file:
//   count, gap          the study's own n = 10 and gap = 8
//   active              index of the lit segment, or -1 for none
//   t, b, re, f, rc     the same geometry the flat run uses
//   along               the rail's along-axis extent
//   xl, xr              the bulge span
//   surfaceDepth, flip, axis
//
// ── THE MERGE, AND WHY IT IS A SPAN UNION RATHER THAN A PER-SEGMENT
//    OPACITY TRICK ───────────────────────────────────────────────────
// When the bulge has any depth the segments it covers must merge into the
// bulge's own CONTINUOUS silhouette, because an attachment root cannot
// have gaps in it — the AttachedCorner flare would have nothing to weld
// to and the one-silhouette effect would break at exactly the joint it
// exists to hide. So an intersecting segment is absorbed WHOLE: the
// merged span grows out to that segment's own far end rather than cutting
// it at the bulge boundary, and a half-segment can never be drawn.
//
// Segment geometry is the study's, verbatim:
//   seg = (along - gap * (count - 1)) / count
//   segment i spans [i * (seg + gap), i * (seg + gap) + seg]
// and every segment is pill-capped through the SAME two-quarter-arc
// construction `buildOutline` already emits. No new arc of any other
// sweep angle is introduced anywhere here, so hazard 4 stays disarmed.
function buildSegmented(params) {
    var n = params.count, gap = params.gap;
    var along = params.along, b = params.b;
    var xl = params.xl, xr = params.xr, active = params.active;
    var seg = (along - gap * (n - 1)) / n;

    function span(i) {
        var s = i * (seg + gap);
        return { start: s, end: s + seg };
    }

    // The merged span: the bulge's own span, grown out to swallow every
    // segment it touches whole. Null when the bulge has no depth, which
    // is the resting state in animated mode — all `count` segments then
    // stand separate, which is the intended reading.
    var merged = null;
    if (b > 0) {
        var ms = xl, me = xr;
        for (var i = 0; i < n; i++) {
            var sp = span(i);
            if (sp.end > xl && sp.start < xr) {
                if (sp.start < ms) ms = sp.start;
                if (sp.end > me) me = sp.end;
            }
        }
        merged = { start: ms, end: me };
    }

    var gradient = "", outline = "";
    function add(target, p) {
        if (target === "gradient") gradient += (gradient ? " " : "") + p;
        else outline += (outline ? " " : "") + p;
    }

    if (merged) {
        // ONE continuous silhouette across the merged span, built by the
        // ordinary flat-run-plus-bulge builder so its fillets, bulge
        // corners and pill caps are the same shapes every other style
        // uses — the bulge is not a special case here, the merged run is
        // simply a shorter rail that happens to have one.
        add("gradient", buildOutline({
            t: params.t, b: b, re: params.re, f: params.f, rc: params.rc,
            alongStart: merged.start, along: merged.end,
            xl: xl, xr: xr,
            surfaceDepth: params.surfaceDepth, flip: params.flip, axis: params.axis
        }));
    }

    for (var j = 0; j < n; j++) {
        var s2 = span(j);
        // Absorbed into the merged silhouette — not drawn again, and never
        // drawn as the half that fell outside.
        if (merged && s2.end > merged.start && s2.start < merged.end)
            continue;
        add(j === active ? "gradient" : "outline", buildOutline({
            t: params.t, b: 0, re: params.re, f: 0, rc: 0,
            alongStart: s2.start, along: s2.end, bulge: false,
            xl: 0, xr: 0,
            surfaceDepth: params.surfaceDepth, flip: params.flip, axis: params.axis
        }));
    }

    return { gradient: gradient, outline: outline };
}
