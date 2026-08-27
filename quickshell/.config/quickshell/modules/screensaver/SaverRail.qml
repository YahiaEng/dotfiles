// SaverRail.qml — screensaver style S6, "Edge Rail" (quick task
// 260827-b52, operator pick 4 of 4).
//
// A lit head running the screen perimeter with a fading tail, over black,
// with the wordmark quiet at centre. The stroke carries the same
// primary → secondary → tertiary stops `GradientBorder.qml` draws around
// the dashboard, which are themselves byte-identical to Hyprland's live
// `general:col.active_border` — so this is the shell's own rim language
// at output scale, not a screensaver effect that happens to be coloured.
//
// ── Canvas, not Shapes, and the reason is the dash ────────────────────
// `GradientBorder.qml` draws its rim as `Shape` geometry with an
// OddEvenFill band, for reasons its own header sets out at length
// (analytic antialiasing on a 3px curve). That approach cannot express
// THIS shape: a travelling segment needs a dash pattern with an animated
// offset, and `ShapePath`'s dash support depends on which renderer the
// Shape resolves to — `Shape.CurveRenderer`, which is exactly what
// GradientBorder needs for its corners, is the one that does not
// guarantee it.
//
// `Canvas`'s `setLineDash` / `lineDashOffset` are plain Context2D and
// carry no such condition. That matters more than usual here: this
// surface cannot be verified from an agent shell (restarting quickshell
// from one kills the session), so the option that cannot half-work is the
// correct option even though it is the less elegant one.
//
// ── The tail is the gradient, not an alpha ramp ───────────────────────
// There is no per-dash opacity ramp in Context2D. The fade comes from the
// stroke gradient itself being anchored to the CANVAS rather than to the
// dash: as the lit segment travels it samples a different part of the
// gradient, so its colour shifts continuously and its ends meet the dim
// track. A hand-built tail (N short dashes at decreasing alpha) was the
// alternative and would have cost N strokes per frame for a subtler
// result.
pragma ComponentBehavior: Bound

import QtQuick
import "../"
import "../dashboard"

Item {
    id: root

    required property SaverArt art
    property bool active: true

    readonly property real cellWidth: root.width * Design.saverArtWidthFraction * 0.55 / Math.max(1, root.art.cols)
    readonly property real glyphSize: Math.max(5, cellWidth / 0.6)

    // Inset from the true screen edge. Bound to the spacing scale rather
    // than picked: the rail should sit off the bezel by the same measure
    // every other surface in this shell uses.
    readonly property real _inset: Design.spacingMd
    readonly property real _radius: Design.spacingXl
    // Reuses the rim's own stroke weight — the same reasoning
    // `Design.notifRingStrokeWidth` records, rather than inventing a
    // second line weight for the same visual language.
    readonly property real _stroke: Design.borderWidth

    // Position of the lit head along the perimeter, 0..1. Driven by an
    // Animation rather than a Timer because nothing else on this style
    // needs a tick — the wordmark's pulse is its own Behavior.
    property real _phase: 0

    NumberAnimation on _phase {
        running: root.active && root.visible
        loops: Animation.Infinite
        from: 0
        to: 1
        duration: Design.saverRailLapMs
        easing.type: Easing.Linear
    }

    onWidthChanged: rail.requestPaint()
    onHeightChanged: rail.requestPaint()
    on_PhaseChanged: rail.requestPaint()

    Canvas {
        id: rail

        anchors.fill: parent
        // RENDER TARGET LEFT AT THE DEFAULT — see the measurement note in
        // this file's header. FramebufferObject was measured non-functional here.

        // Traces a rounded rectangle. Written out rather than using
        // `arcTo` so the start point is unambiguous — the dash offset is
        // measured from it, and an implicit start would make "where does
        // the head begin its lap" depend on the renderer.
        function _path(ctx, x, y, w, h, r) {
            ctx.beginPath();
            ctx.moveTo(x + r, y);
            ctx.lineTo(x + w - r, y);
            ctx.arc(x + w - r, y + r, r, -Math.PI / 2, 0);
            ctx.lineTo(x + w, y + h - r);
            ctx.arc(x + w - r, y + h - r, r, 0, Math.PI / 2);
            ctx.lineTo(x + r, y + h);
            ctx.arc(x + r, y + h - r, r, Math.PI / 2, Math.PI);
            ctx.lineTo(x, y + r);
            ctx.arc(x + r, y + r, r, Math.PI, Math.PI * 1.5);
            ctx.closePath();
        }

        // Maps an arc length (any real; wrapped) onto the rounded
        // rectangle, walking the eight segments in the same clockwise order
        // `_path` traces them: top, TR arc, right, BR arc, bottom, BL arc,
        // left, TL arc. Returns [x, y].
        function _pointAt(s, m, rw, rh, r, perim) {
            let d = s % perim;
            if (d < 0)
                d += perim;
            const hLine = rw - 2 * r;
            const vLine = rh - 2 * r;
            const arc = Math.PI * r / 2;
            const x0 = m, y0 = m, x1 = m + rw, y1 = m + rh;

            if (d < hLine)
                return [x0 + r + d, y0];
            d -= hLine;
            if (d < arc) {
                const t = d / arc * (Math.PI / 2);
                return [x1 - r + r * Math.sin(t), y0 + r - r * Math.cos(t)];
            }
            d -= arc;
            if (d < vLine)
                return [x1, y0 + r + d];
            d -= vLine;
            if (d < arc) {
                const t = d / arc * (Math.PI / 2);
                return [x1 - r + r * Math.cos(t), y1 - r + r * Math.sin(t)];
            }
            d -= arc;
            if (d < hLine)
                return [x1 - r - d, y1];
            d -= hLine;
            if (d < arc) {
                const t = d / arc * (Math.PI / 2);
                return [x0 + r - r * Math.sin(t), y1 - r + r * Math.cos(t)];
            }
            d -= arc;
            if (d < vLine)
                return [x0, y1 - r - d];
            d -= vLine;
            const t = d / arc * (Math.PI / 2);
            return [x0 + r - r * Math.cos(t), y0 + r - r * Math.sin(t)];
        }

        onPaint: {
            var ctx = getContext("2d");
            var w = width, h = height;
            ctx.clearRect(0, 0, w, h);
            if (w <= 0 || h <= 0)
                return;

            var m = root._inset;
            var rw = w - m * 2;
            var rh = h - m * 2;
            var r = Math.min(root._radius, Math.min(rw, rh) / 2);
            if (rw <= 0 || rh <= 0)
                return;

            // Exact perimeter of the rounded rect: the four straight runs
            // plus one full circle's worth of corner arc.
            var perim = 2 * (rw - 2 * r) + 2 * (rh - 2 * r) + 2 * Math.PI * r;

            // ── The track: the whole perimeter, dim ───────────────────
            ctx.setLineDash([]);
            ctx.lineWidth = Math.max(1, root._stroke / 2);
            // Qt.alpha, NOT Qt.rgba(track.r, ...) — Colours roles are hex
            // STRINGS, so the channel accessors are undefined and the whole
            // stroke resolved to black-on-black. That is why the rail
            // appeared to "vanish": the track was never visible at all, and
            // only the travelling head ever drew.
            ctx.strokeStyle = Qt.alpha(Colours.surfaceVariant, 0.55);
            rail._path(ctx, m, m, rw, rh, r);
            ctx.stroke();

            // ── The head, walked BY ARC LENGTH — no dash pattern ───────
            // Two dash-based builds both left the head missing for part of
            // every lap. `[lit, perim]` gave a pattern period 1.19x the
            // path, so the lit run walked off the END with nothing wrapping
            // back to the start. `[lit, perim - lit]` made the period tile
            // the path exactly, which SHOULD wrap — and measurably did not:
            // sampling the perimeter band every 2s found no head at all in
            // 5 of 12 frames, on the lap's own ~9s cycle. Canvas dashing
            // does not reliably wrap a closed sub-path here.
            //
            // So the head is no longer a dash. `_pointAt(s)` maps an arc
            // length onto the rounded rectangle directly, and the head is
            // stroked as a short polyline walked from its tail to its tip,
            // wrapping with a plain modulo. That cannot gap: every frame
            // draws the same number of segments, wherever they land.
            //
            // The tail fades via `globalAlpha` per segment rather than via
            // the stroke gradient, which is what makes it a TAIL and not
            // just a moving colour — the gradient still supplies the hue,
            // so the head keeps the shell's primary/secondary/tertiary rim
            // language.
            const g = ctx.createLinearGradient(0, 0, w, h);
            g.addColorStop(0, Colours.tertiary);
            g.addColorStop(0.5, Colours.secondary);
            g.addColorStop(1, Colours.primary);

            const headLen = perim * 0.19;
            const segs = 28;
            const tip = root._phase * perim;
            ctx.lineWidth = root._stroke;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.strokeStyle = g;
            for (let k = 0; k < segs; k++) {
                // k = 0 is the tip; alpha falls away toward the tail.
                const a0 = tip - headLen * (k / segs);
                const a1 = tip - headLen * ((k + 1) / segs);
                ctx.globalAlpha = 1 - k / segs;
                const p0 = rail._pointAt(a0, m, rw, rh, r, perim);
                const p1 = rail._pointAt(a1, m, rw, rh, r, perim);
                ctx.beginPath();
                ctx.moveTo(p0[0], p0[1]);
                ctx.lineTo(p1[0], p1[1]);
                ctx.stroke();
            }
            ctx.globalAlpha = 1;
        }
    }

    // ── The wordmark, quiet at centre ─────────────────────────────────
    // Smaller than every other style's (the `* 0.55` on cellWidth above):
    // on this plate the rail is the event and the mark is the label. It
    // breathes on the rail's own lap period so the two read as one system
    // rather than two loops running at unrelated speeds.
    Column {
        anchors.centerIn: parent
        spacing: 0
        opacity: 0.42

        SequentialAnimation on opacity {
            running: root.active
            loops: Animation.Infinite
            NumberAnimation {
                from: 0.30
                to: 0.56
                duration: Math.round(Design.saverRailLapMs / 2)
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                from: 0.56
                to: 0.30
                duration: Math.round(Design.saverRailLapMs / 2)
                easing.type: Easing.InOutSine
            }
        }

        Repeater {
            model: root.art.rowCount

            delegate: Text {
                required property int index

                font.family: root.art.fontFamily
                font.pixelSize: root.glyphSize
                font.hintingPreference: Font.PreferNoHinting
                lineHeight: 1.0
                color: Colours.onSurface
                text: root.art.rows[index] || ""
            }
        }
    }
}
