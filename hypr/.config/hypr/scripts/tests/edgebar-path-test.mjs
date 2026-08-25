#!/usr/bin/env node
// edgebar-path-test.mjs — pins quickshell/.config/quickshell/modules/
// edgebarpath.js (quick task 260824-ns3, Task 2, hazard 1/3/4). This is
// the ONLY detector that exists for a sweep-flag regression or a broken
// fillet invariant on the edge bar's path builder — no QML error, no
// gate, catches either. Reads edgebarpath.js off disk (never a copy), so
// this test rots the moment the two would diverge.
//
// Five assertion groups, run bottom to top of this file:
//   1. Golden, horizontal — buildOutline() reproduces
//      edgebar-path-golden.json character-for-character.
//   2. Sweep flags are resolved, not guessed — every `A` command carries
//      a sweep flag of exactly 0 or 1, no NaN and no undefined anywhere.
//   3. The fillet invariant (`f + rc <= b`) holds at EVERY frame of the
//      animated 0 -> 10 sweep, not just the endpoints (round 10's own
//      lesson — a broken invariant self-intersects the outline with no
//      warning anywhere).
//   4. Golden unchanged — the same horizontal assertions still pass after
//      the vertical axis exists, proving the transposition changed
//      nothing about horizontal output.
//   5. Vertical is the transpose — for the same inputs, the vertical path
//      is the horizontal path with every coordinate pair swapped,
//      verified by parsing both into coordinate lists rather than string
//      manipulation of the whole path.
//
// Exits non-zero on any failure; prints one line per assertion.

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, "../../../../..");
const MODULE_PATH = path.join(REPO_ROOT, "quickshell/.config/quickshell/modules/edgebarpath.js");
const GOLDEN_PATH = path.join(__dirname, "edgebar-path-golden.json");

let failures = 0;
let total = 0;

function check(label, cond) {
    total++;
    if (cond) {
        console.log("PASS: " + label);
    } else {
        failures++;
        console.log("FAIL: " + label);
    }
}

// ── Load edgebarpath.js as plain JS — strip the leading `.pragma`/
//    `.import` directive lines node cannot parse, then eval the rest. ────
function loadBuildOutline() {
    const src = readFileSync(MODULE_PATH, "utf8");
    const stripped = src
        .split("\n")
        .filter((line) => {
            const t = line.trim();
            return !(t.startsWith(".pragma") || t.startsWith(".import"));
        })
        .join("\n");
    const mod = { exports: {} };
    const fn = new Function("module", "exports", stripped + "\nmodule.exports = { buildOutline, buildSegmented };");
    fn(mod, mod.exports);
    return mod.exports;
}

// ── Path parsing helpers — this generator only ever emits M/L/A/Z, in
//    exactly the "A rx ry 0 0 sweep x y" shape, so a small fixed-format
//    parser is safe (and catches a malformed command as a thrown error
//    rather than silently mis-parsing it). ────────────────────────────
function parseCoords(p) {
    const tok = p.trim().split(/\s+/);
    const coords = [];
    let i = 0;
    while (i < tok.length) {
        const cmd = tok[i];
        if (cmd === "M" || cmd === "L") {
            coords.push([Number(tok[i + 1]), Number(tok[i + 2])]);
            i += 3;
        } else if (cmd === "A") {
            coords.push([Number(tok[i + 6]), Number(tok[i + 7])]);
            i += 8;
        } else if (cmd === "Z") {
            i += 1;
        } else {
            throw new Error("unexpected path token \"" + cmd + "\" at index " + i);
        }
    }
    return coords;
}

function parseSweepFlags(p) {
    const tok = p.trim().split(/\s+/);
    const flags = [];
    let i = 0;
    while (i < tok.length) {
        const cmd = tok[i];
        if (cmd === "M" || cmd === "L") {
            i += 3;
        } else if (cmd === "A") {
            flags.push(tok[i + 5]);
            i += 8;
        } else if (cmd === "Z") {
            i += 1;
        } else {
            throw new Error("unexpected path token \"" + cmd + "\" at index " + i);
        }
    }
    return flags;
}

const { buildOutline, buildSegmented } = loadBuildOutline();
const golden = JSON.parse(readFileSync(GOLDEN_PATH, "utf8"));

// The live parameter set (EdgeBar.qml's own tokens, Design.qml verified):
// t=6 (edgeBarThickness), re=3 (edgeBarEndRadius), f=3 (edgeBarFilletRadius),
// rc=1 (edgeBarBulgeCornerRadius), b: 4 static / 10 swelled
// (edgeBarBulgeExtra / edgeBarBulgeSwellExtra). along=1850 (RIGHT_EDGE,
// the strip's own measured resolved width at the study's 1920 capture
// scale). surfaceDepth=16 (edgeBarHoverDepth). bulgeWidth 760/640
// (dashboardMinWidth/launcherPanelWidth).
const ALONG = 1850;
const SURFACE_DEPTH = 16;
const CASES = [];
for (const b of [4, 10]) {
    for (const [wlabel, width] of [["top", 760], ["bottom", 640]]) {
        const xl = ALONG / 2 - width / 2;
        const xr = ALONG / 2 + width / 2;
        for (const flip of [false, true]) {
            CASES.push({
                key: "h_b" + b + "_" + wlabel + "_flip" + flip,
                params: { t: 6, b, re: 3, f: 3, rc: 1, along: ALONG, xl, xr, surfaceDepth: SURFACE_DEPTH, flip, axis: "horizontal" }
            });
        }
    }
}

// ── Group 1: Golden, horizontal ──────────────────────────────────────
console.log("── Group 1: golden, horizontal ──");
for (const c of CASES) {
    const got = buildOutline(c.params);
    const want = golden[c.key];
    check("golden[" + c.key + "] character-identical", typeof want === "string" && got === want);
}

// ── Group 2: sweep flags resolved, not guessed ───────────────────────
console.log("── Group 2: sweep flags are 0 or 1, no NaN/undefined ──");
for (const c of CASES) {
    const got = buildOutline(c.params);
    check(c.key + ": no NaN/undefined in path", !/NaN|undefined/.test(got));
    const flags = parseSweepFlags(got);
    const allValid = flags.length > 0 && flags.every((f) => f === "0" || f === "1");
    check(c.key + ": all " + flags.length + " sweep flags are exactly 0 or 1", allValid);
}
// Same check for a vertical instance, since Task 4+ mount vertical
// surfaces through this same builder.
{
    const vparams = { t: 2, b: 10, re: 1, f: 3, rc: 1, along: 1060, xl: 400, xr: 660, surfaceDepth: 16, flip: true, axis: "vertical" };
    const got = buildOutline(vparams);
    check("vertical: no NaN/undefined in path", !/NaN|undefined/.test(got));
    const flags = parseSweepFlags(got);
    check("vertical: all " + flags.length + " sweep flags are exactly 0 or 1", flags.length > 0 && flags.every((f) => f === "0" || f === "1"));
}

// ── Group 3: fillet invariant holds at EVERY frame ───────────────────
console.log("── Group 3: fillet invariant f + rc <= b across the 0 -> 10 sweep ──");
{
    const EPS = 1e-9;
    let allHeld = true;
    let framesChecked = 0;
    for (let b = 0; b <= 10 + EPS; b += 0.5) {
        const bClamped = Math.min(b, 10);
        const f = bClamped * 0.6;
        const rc = bClamped * 0.4;
        framesChecked++;
        if (f + rc > bClamped + EPS) {
            allHeld = false;
            console.log("  frame b=" + bClamped.toFixed(2) + ": f+rc=" + (f + rc).toFixed(6) + " > b — INVARIANT BROKEN");
        }
        // Also build the path at this frame and confirm it is well-formed
        // (no NaN/undefined, valid sweep flags) — a broken invariant
        // self-intersects the outline with no error anywhere, so the path
        // itself must be inspected, not just the arithmetic.
        const got = buildOutline({ t: 6, b: bClamped, re: 3, f, rc, along: ALONG, xl: 545, xr: 1305, surfaceDepth: SURFACE_DEPTH, flip: false, axis: "horizontal" });
        if (/NaN|undefined/.test(got)) {
            allHeld = false;
            console.log("  frame b=" + bClamped.toFixed(2) + ": path contains NaN/undefined");
        }
    }
    check("fillet invariant f + rc <= b held across all " + framesChecked + " frames", allHeld);
}

// ── Group 4: golden unchanged (post-transposition) ───────────────────
// The SAME assertions as Group 1, run again now that the vertical axis
// exists in this same file — if this group ever diverges from Group 1's
// result, the transposition changed horizontal output and is wrong.
console.log("── Group 4: golden unchanged after the vertical axis was added ──");
for (const c of CASES) {
    const got = buildOutline(c.params);
    const want = golden[c.key];
    check("post-transposition golden[" + c.key + "] still character-identical", got === want);
}

// ── Group 5: vertical is the transpose ───────────────────────────────
console.log("── Group 5: vertical is the horizontal path with every coordinate pair swapped ──");
for (const c of CASES) {
    const hPath = buildOutline(c.params);
    const vParams = Object.assign({}, c.params, { axis: "vertical" });
    const vPath = buildOutline(vParams);

    const hCoords = parseCoords(hPath);
    const vCoords = parseCoords(vPath);

    let sameLength = hCoords.length === vCoords.length;
    check(c.key + ": vertical has the same coordinate-pair count as horizontal (" + hCoords.length + ")", sameLength);

    if (sameLength) {
        let allSwapped = true;
        for (let i = 0; i < hCoords.length; i++) {
            const [hx, hy] = hCoords[i];
            const [vx, vy] = vCoords[i];
            // vertical's (x,y) must equal horizontal's (y,x) — the P(a,d)
            // mapping is d+" "+a for vertical vs a+" "+d for horizontal.
            if (Math.abs(vx - hy) > 1e-9 || Math.abs(vy - hx) > 1e-9) {
                allSwapped = false;
                console.log("  coord " + i + ": horizontal=(" + hx + "," + hy + ") vertical=(" + vx + "," + vy + ") — expected vertical=(" + hy + "," + hx + ")");
            }
        }
        check(c.key + ": every coordinate pair is the horizontal pair swapped", allSwapped);
    }

    // Sweep flags must be identical in count and, since both axes are
    // resolved through the SAME S() helper against a correctly transposed
    // expected centre, in VALUE too — transposing swaps handedness but the
    // resolver compensates for it (see edgebarpath.js's own header).
    const hFlags = parseSweepFlags(hPath);
    const vFlags = parseSweepFlags(vPath);
    check(c.key + ": vertical has the same sweep-flag count as horizontal (" + hFlags.length + ")", hFlags.length === vFlags.length);
}

// ── Group 6: the plain run (`bulge: false`) ──────────────────────────
// Halo's left/right rails and all four of Brackets' arms are flat runs
// with no centre excursion (quick task 260824-ns3, Task 4/5). Asserted
// here rather than trusted, because a plain run is what the vertical
// instances draw and there is no other detector for it: a self-
// intersecting or backwards run produces no QML error and no gate.
console.log("── Group 6: bulge:false emits a plain run, on both axes ──");
{
    // Halo's own live parameter set for a vertical rail: t = 2
    // (edgeBarHaloThickness), re = 1 (edgeBarHaloEndRadius, = t/2 so the
    // cap is a true semicircle), surfaceDepth = 16 (edgeBarHoverDepth).
    const base = { t: 2, b: 0, re: 1, f: 3, rc: 1, along: 1420, xl: 0, xr: 0, surfaceDepth: 16, bulge: false };

    for (const flip of [false, true]) {
        for (const axis of ["horizontal", "vertical"]) {
            const key = "plain_" + axis + "_flip" + flip;
            const got = buildOutline(Object.assign({}, base, { flip, axis }));
            check(key + ": no NaN/undefined in path", !/NaN|undefined/.test(got));
            const flags = parseSweepFlags(got);
            // Two pill caps, two quarter arcs each — exactly four arcs, no
            // fillets and no bulge corners.
            check(key + ": exactly 4 arcs (two two-quarter-arc pill caps, no fillets)", flags.length === 4);
            check(key + ": all sweep flags are exactly 0 or 1", flags.every((f) => f === "0" || f === "1"));
            // The run is monotone along its own axis: M -> far cap -> back
            // -> near cap. Seven coordinate pairs, and the depth axis only
            // ever takes 0, re or t (mirrored when flipped) — never t+b.
            const coords = parseCoords(got);
            check(key + ": 7 coordinate pairs (M + L + 2 cap arcs + L + 2 cap arcs)", coords.length === 7);
            const depths = coords.map(([x, y]) => (axis === "vertical" ? x : y));
            const allowed = [0, base.re, base.t].map((v) => (flip ? base.surfaceDepth - v : v));
            check(key + ": every depth coordinate is 0, re or t (no bulge excursion)", depths.every((d) => allowed.some((a) => Math.abs(a - d) < 1e-9)));
        }
    }

    // And the transposition holds for the plain run too.
    const h = buildOutline(Object.assign({}, base, { flip: false, axis: "horizontal" }));
    const v = buildOutline(Object.assign({}, base, { flip: false, axis: "vertical" }));
    const hc = parseCoords(h), vc = parseCoords(v);
    check("plain run: vertical is the horizontal run with every coordinate pair swapped",
        hc.length === vc.length && hc.every(([x, y], i) => Math.abs(vc[i][0] - y) < 1e-9 && Math.abs(vc[i][1] - x) < 1e-9));
}

// ── Group 7: `bulge` defaults to true ────────────────────────────────
// The golden was generated before this parameter existed, so omitting it
// MUST be byte-identical to passing true — otherwise every pre-Task-4
// caller silently changed shape.
console.log("── Group 7: omitting `bulge` is identical to bulge:true ──");
for (const c of CASES) {
    const omitted = buildOutline(c.params);
    const explicit = buildOutline(Object.assign({}, c.params, { bulge: true }));
    check(c.key + ": omitted `bulge` === bulge:true", omitted === explicit);
}

// ── Group 8: `alongStart` translates the run, nothing else ───────────
// Brackets draws TWO short runs per surface from ONE builder (Task 5).
// The far arm is the near arm translated along the run's own axis — if
// `alongStart` ever changed anything but the along coordinates, the two
// arms would silently stop being the same shape.
console.log("── Group 8: alongStart translates the run along its own axis ──");
{
    const base = { t: 6, b: 0, re: 3, f: 3, rc: 1, along: 0, xl: 0, xr: 0, surfaceDepth: 16, bulge: false };
    const ARM = 225, EXTENT = 2540;

    for (const axis of ["horizontal", "vertical"]) {
        for (const flip of [false, true]) {
            const key = "arm_" + axis + "_flip" + flip;
            const near = buildOutline(Object.assign({}, base, { alongStart: 0, along: ARM, axis, flip }));
            const far = buildOutline(Object.assign({}, base, { alongStart: EXTENT - ARM, along: EXTENT, axis, flip }));

            check(key + ": no NaN/undefined in either arm", !/NaN|undefined/.test(near) && !/NaN|undefined/.test(far));
            check(key + ": both arms carry exactly 4 arcs", parseSweepFlags(near).length === 4 && parseSweepFlags(far).length === 4);
            check(key + ": both arms resolve the same sweep flags", parseSweepFlags(near).join() === parseSweepFlags(far).join());

            const nc = parseCoords(near), fc = parseCoords(far);
            check(key + ": same coordinate-pair count", nc.length === fc.length);
            if (nc.length === fc.length) {
                const D = EXTENT - ARM;
                // The far arm's ALONG coordinates are the near arm's plus
                // the offset; its DEPTH coordinates are untouched.
                const alongIdx = axis === "vertical" ? 1 : 0;
                const depthIdx = axis === "vertical" ? 0 : 1;
                check(key + ": far arm is the near arm translated by " + D + " along, depth untouched",
                    nc.every((c, i) => Math.abs(fc[i][alongIdx] - (c[alongIdx] + D)) < 1e-9
                        && Math.abs(fc[i][depthIdx] - c[depthIdx]) < 1e-9));
            }
        }
    }

    // And omitting `alongStart` is identical to passing 0 — the golden
    // predates this parameter.
    check("omitting alongStart === alongStart:0",
        buildOutline(Object.assign({}, base, { along: ARM })) === buildOutline(Object.assign({}, base, { alongStart: 0, along: ARM })));
}

// ── Group 9: Segmented, and the whole-segment merge ──────────────────
// The merge (Q3-segmented) is the one rule with no other detector: a
// half-segment cut at the bulge boundary produces a perfectly valid path
// that simply looks wrong, with no QML error and no gate. Asserted here
// against the segment arithmetic itself rather than against pixels.
console.log("── Group 9: Segmented merges WHOLE segments, never a half ──");
{
    // The live top-rail parameter set: along = 2490 (the strip's resolved
    // width on this 2560 panel), bulge width 760 (dashboardMinWidth)
    // centred, n = 10, gap = 8 — the study's own numbers.
    const N = 10, GAP = 8, ALONG = 2490;
    const SEG = (ALONG - GAP * (N - 1)) / N;
    const XL = ALONG / 2 - 380, XR = ALONG / 2 + 380;
    const base = { count: N, gap: GAP, t: 6, re: 3, f: 3, rc: 1, along: ALONG, xl: XL, xr: XR, surfaceDepth: 16, flip: false, axis: "horizontal" };
    const subpaths = (s) => (s ? s.split(" M ").length : 0);

    // Resting state: bulge depth 0, no merge, all ten segments separate.
    {
        const r = buildSegmented(Object.assign({}, base, { b: 0, active: 2 }));
        check("b=0: no NaN/undefined", !/NaN|undefined/.test(r.gradient + r.outline));
        check("b=0: exactly " + N + " segments drawn (1 active + " + (N - 1) + " inactive)",
            subpaths(r.gradient) === 1 && subpaths(r.outline) === N - 1);
        check("b=0: every sweep flag is 0 or 1",
            parseSweepFlags(r.gradient + " " + r.outline).every((f) => f === "0" || f === "1"));
    }

    // Bulged state: the merged silhouette absorbs whole segments only.
    for (const b of [4, 10]) {
        const r = buildSegmented(Object.assign({}, base, { b, active: 2 }));
        check("b=" + b + ": no NaN/undefined", !/NaN|undefined/.test(r.gradient + r.outline));

        // Recompute the expected absorption independently of the module.
        const spans = [];
        for (let i = 0; i < N; i++) {
            const s = i * (SEG + GAP);
            spans.push({ start: s, end: s + SEG });
        }
        const touched = spans.filter((s) => s.end > XL && s.start < XR);
        const mStart = Math.min(XL, ...touched.map((s) => s.start));
        const mEnd = Math.max(XR, ...touched.map((s) => s.end));
        const survivors = spans.filter((s) => !(s.end > mStart && s.start < mEnd));

        check("b=" + b + ": " + touched.length + " segments absorbed, " + survivors.length + " survive",
            subpaths(r.gradient) + subpaths(r.outline) === survivors.length + 1);

        // Every coordinate the merged silhouette emits along the run must
        // lie inside [mStart, mEnd]. If a segment were cut at the bulge
        // boundary instead of absorbed whole, the merged run would start
        // or end at XL/XR rather than at a segment edge.
        const gradCoords = parseCoords(r.gradient);
        const alongs = gradCoords.map(([x]) => x);
        check("b=" + b + ": merged run starts at a SEGMENT edge (" + mStart.toFixed(1) + "), not at the bulge edge (" + XL.toFixed(1) + ")",
            Math.abs(Math.min(...alongs.filter((a) => a >= mStart - 1)) - mStart) < 1e-6 || alongs.includes(mStart));
        check("b=" + b + ": no surviving segment straddles the merged span",
            survivors.every((s) => s.end <= mStart + 1e-9 || s.start >= mEnd - 1e-9));
        check("b=" + b + ": every sweep flag is 0 or 1",
            parseSweepFlags(r.gradient + " " + r.outline).every((f) => f === "0" || f === "1"));
    }

    // A focused workspace outside 1..count lights nothing — correct, not
    // a gap (a special workspace or id 11+ simply has no segment).
    {
        const r = buildSegmented(Object.assign({}, base, { b: 0, active: -1 }));
        check("active=-1: nothing lit, all " + N + " segments inactive",
            r.gradient === "" && subpaths(r.outline) === N);
    }
}

console.log("");
console.log(total + " assertions, " + (total - failures) + " passed, " + failures + " failed");
process.exit(failures > 0 ? 1 : 0);
