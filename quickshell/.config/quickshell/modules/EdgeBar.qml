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

    anchors {
        top: !edgeBarWindow.bottom
        bottom: edgeBarWindow.bottom
        left: true
        right: true
    }

    // No margins on any edge (D-4) — flush to the screen edge by
    // construction, so there is nothing to fold into exclusiveZone.

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

    // ── Colour (R9) — Colours.surface, blended at the SAME alpha
    //    BarRoles.qml's own `barSurface` role already uses for the bar's
    //    own chrome background (0.55 — matching Athena's own @surface-
    //    derived treatment). Declared locally rather than read through
    //    BarRoles (GT-4: this file is deliberately outside `modules/bar/`
    //    so it can read `Colours.*` directly). Per GT-5, `Colours.surface`
    //    is a STRING role — blending `.r`/`.g`/`.b` straight off it would
    //    read BLACK silently, so it is captured as a colour-typed property
    //    first. 0.55 sits above GT-9's 0.5 ignore_alpha floor, so
    //    windowrules.lua's family blur rule stays alive behind the strip.
    readonly property color surfaceBase: Colours.surface
    readonly property color fillColour: Qt.rgba(edgeBarWindow.surfaceBase.r, edgeBarWindow.surfaceBase.g, edgeBarWindow.surfaceBase.b, 0.55)

    readonly property real _t: Design.edgeBarThickness
    readonly property real _b: Design.edgeBarBulgeExtra
    readonly property real _wb: Design.edgeBarBulgeWidth
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

    // The full strip outline, clockwise from the strip's own top-left
    // (edge="top" orientation), then mirrored in y for edge="bottom" — see
    // file header for the full derivation.
    readonly property string _outlinePath: {
        var t = edgeBarWindow._t, b = edgeBarWindow._b, ww = edgeBarWindow._ww;
        var xl = edgeBarWindow._xl, xr = edgeBarWindow._xr;

        // Right shoulder: flat floor (xr+b, t) -> bulge floor (xr, t+b).
        var rCx = xr + b, rCy = t + b;
        var rSweep = edgeBarWindow._shoulderSweep(xr + b, t, xr, t + b, b, rCx, rCy);
        // Left shoulder: bulge floor (xl, t+b) -> flat floor (xl-b, t).
        var lCx = xl - b, lCy = t + b;
        var lSweep = edgeBarWindow._shoulderSweep(xl, t + b, xl - b, t, b, lCx, lCy);

        var p;
        if (!edgeBarWindow.bottom) {
            p = "M 0 0";
            p += " L " + ww + " 0";
            p += " L " + ww + " " + t;
            p += " L " + (xr + b) + " " + t;
            p += " A " + b + " " + b + " 0 0 " + rSweep + " " + xr + " " + (t + b);
            p += " L " + xl + " " + (t + b);
            p += " A " + b + " " + b + " 0 0 " + lSweep + " " + (xl - b) + " " + t;
            p += " L 0 " + t;
        } else {
            // Same outline mirrored in y (flat run flush with the bottom
            // screen edge, bulge overhanging upward into the client area).
            // Mirroring y flips every arc's sweep-flag (standard SVG
            // mirror rule) — re-verified against `_shoulderSweep` above
            // using the mirrored points/centres, not assumed.
            var h = t + b;
            var rSweepM = edgeBarWindow._shoulderSweep(xr + b, b, xr, 0, b, rCx, h - rCy);
            var lSweepM = edgeBarWindow._shoulderSweep(xl, 0, xl - b, b, b, lCx, h - lCy);
            p = "M 0 " + h;
            p += " L " + ww + " " + h;
            p += " L " + ww + " " + b;
            p += " L " + (xr + b) + " " + b;
            p += " A " + b + " " + b + " 0 0 " + rSweepM + " " + xr + " 0";
            p += " L " + xl + " 0";
            p += " A " + b + " " + b + " 0 0 " + lSweepM + " " + (xl - b) + " " + b;
            p += " L 0 " + b;
        }
        return p + " Z";
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: edgeBarWindow.fillColour
            strokeWidth: -1
            strokeColor: "transparent"
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
