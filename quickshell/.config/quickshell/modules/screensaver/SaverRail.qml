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
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Cooperative

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
            var track = Colours.surfaceVariant;
            ctx.setLineDash([]);
            ctx.lineWidth = Math.max(1, root._stroke / 2);
            ctx.strokeStyle = Qt.rgba(track.r, track.g, track.b, 0.55);
            rail._path(ctx, m, m, rw, rh, r);
            ctx.stroke();

            // ── The lit head ─────────────────────────────────────────
            var g = ctx.createLinearGradient(0, 0, w, h);
            g.addColorStop(0, Colours.tertiary);
            g.addColorStop(0.5, Colours.secondary);
            g.addColorStop(1, Colours.primary);

            var lit = perim * 0.19;
            ctx.setLineDash([lit, perim]);
            // Negative so the head travels clockwise from the top-left
            // corner, matching the direction GradientBorder's own angle
            // rotates.
            ctx.lineDashOffset = -root._phase * perim;
            ctx.lineWidth = root._stroke;
            ctx.lineCap = "round";
            ctx.strokeStyle = g;
            rail._path(ctx, m, m, rw, rh, r);
            ctx.stroke();
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
