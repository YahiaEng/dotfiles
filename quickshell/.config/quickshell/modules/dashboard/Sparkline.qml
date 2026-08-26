// Sparkline.qml — a filled line chart over a rolling sample buffer (quick
// task 260826-rfy, P3 "Telemetry Strip").
//
// Why this exists: the design study's finding was that every figure
// SystemResources publishes is INSTANTANEOUS, so the Performance tab could
// never answer "is this climbing?" — the actual question you open it to ask.
// This draws the buffers `SystemResources` now keeps.
//
// ── Canvas, not a C++ item ──────────────────────────────────────────────
// The reference (`caelestia-dots/shell` @ a788c432,
// `modules/dashboard/performance/NetworkCard.qml`) draws its equivalent with
// `SparklineItem`, which is a compiled item from that repo's own `plugin/`
// tree. We have no compiled plugin, and adding one would put a build step in
// front of "the whole setup reproduces from one script" — so this is a plain
// `Canvas`. Vendored reference and the full port analysis:
// `.planning/notes/caelestia-dashboard/PROVENANCE.md`.
//
// ── RIGHT-ANCHORED, and that is a correctness choice ────────────────────
// Samples are laid out at a FIXED pitch derived from `capacity`, with the
// newest at the right edge — never spread to fill the width. A buffer that
// has only collected 3 of its 60 samples therefore draws a short trace in
// the right-hand corner and grows leftwards as it fills. Spreading 3 samples
// across the full width would render a two-minute window and a six-second
// window identically, which is exactly the kind of plausible-looking lie
// this widget exists to avoid.
//
// D-41 widget-state register: this component deliberately does NOT carry
// one. It is a drawing primitive over whatever array it is handed; the
// populated/pending/empty judgement belongs to the row that owns the data,
// which is where the caller's own guard already lives.
import QtQuick
import "../"

Item {
    id: root

    // Oldest-first, newest LAST — the order SystemResources' buffers publish.
    property var values: []

    // How many samples the buffer holds when FULL. Drives the horizontal
    // pitch, so it must be the producer's own cap (`historyLength`), not the
    // current length — see the right-anchored note above.
    property int capacity: 60

    // The value that maps to the top of the box. A caller graphing a 0..1
    // fraction passes 1; a caller graphing an unbounded rate passes the
    // buffer's own running maximum (`SystemResources.historyMax`).
    property real maxValue: 1

    // A second, optional series drawn UNDER the first in the same box, for
    // the up/down pair a network row needs. Empty means "single series".
    property var secondaryValues: []

    property color lineColour: Colours.primary
    property color secondaryLineColour: Colours.secondary

    // Area fill opacity beneath each trace. Both are alpha over the line's
    // own colour rather than a separate palette role, so a sparkline stays
    // correct through a theme switch with nothing to re-derive.
    property real fillAlpha: 0.18
    property real secondaryFillAlpha: 0.13

    property real strokeWidth: 2
    // A dot on the newest sample — the "you are here" marker. Suppressed on
    // the secondary series so a two-line box does not sprout two dots.
    property bool showEndpoint: true

    // Repaint triggers. `values` is a `property var` holding an array, and
    // SystemResources reassigns rather than mutating precisely so this fires
    // — see that file's own `_pushHistory` note.
    onValuesChanged: canvas.requestPaint()
    onSecondaryValuesChanged: canvas.requestPaint()
    onMaxValueChanged: canvas.requestPaint()
    onLineColourChanged: canvas.requestPaint()
    onSecondaryLineColourChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        // The default renderer re-uploads the whole texture per repaint; at
        // one repaint per poll (2s) that is irrelevant, and it avoids the
        // threaded renderer's own surface juggling inside a Loader that gets
        // torn down with the drawer.
        renderStrategy: Canvas.Immediate

        function _plot(ctx, series, colour, alpha, withDot) {
            var n = series.length;
            if (n < 2)
                return;

            var w = width;
            var h = height;
            // Inset by the stroke so a value pinned at 0 or at maxValue is
            // not clipped in half by the box edge.
            var pad = root.strokeWidth;
            var usable = Math.max(1, h - pad * 2);
            var pitch = root.capacity > 1 ? w / (root.capacity - 1) : w;
            var ceiling = root.maxValue > 0 ? root.maxValue : 1;

            function px(i) { return w - (n - 1 - i) * pitch; }
            function py(v) {
                var f = Math.max(0, Math.min(1, v / ceiling));
                return pad + (1 - f) * usable;
            }

            // Area first, so the line sits on top of its own fill.
            ctx.beginPath();
            ctx.moveTo(px(0), h);
            for (var i = 0; i < n; i++)
                ctx.lineTo(px(i), py(series[i]));
            ctx.lineTo(px(n - 1), h);
            ctx.closePath();
            ctx.fillStyle = Qt.rgba(colour.r, colour.g, colour.b, alpha);
            ctx.fill();

            ctx.beginPath();
            for (var j = 0; j < n; j++) {
                if (j === 0)
                    ctx.moveTo(px(j), py(series[j]));
                else
                    ctx.lineTo(px(j), py(series[j]));
            }
            ctx.strokeStyle = Qt.rgba(colour.r, colour.g, colour.b, 1);
            ctx.lineWidth = root.strokeWidth;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            ctx.stroke();

            if (withDot && root.showEndpoint) {
                ctx.beginPath();
                ctx.arc(px(n - 1), py(series[n - 1]), root.strokeWidth * 1.8, 0, Math.PI * 2);
                ctx.fillStyle = Qt.rgba(colour.r, colour.g, colour.b, 1);
                ctx.fill();
            }
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            var sec = root.secondaryValues;
            if (sec && sec.length >= 2)
                _plot(ctx, sec, root.secondaryLineColour, root.secondaryFillAlpha, false);

            var pri = root.values;
            if (pri && pri.length >= 2)
                _plot(ctx, pri, root.lineColour, root.fillAlpha, true);
        }
    }
}
