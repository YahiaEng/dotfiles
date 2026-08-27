// SaverConstellation.qml — screensaver style S4, "Constellation" (quick
// task 260827-b52, operator pick 3 of 4).
//
// Every filled cell of the wordmark grid is a DESTINATION rather than a
// glyph. Points drift and link to near neighbours, migrate into
// formation, hold, and scatter. The wordmark is legible for about a
// quarter of each lap and absent the rest.
//
// The design study called this the highest-effort plate on the board and
// the one with no existing pattern in this repo to copy — that is still
// true, and it is the reason for the three notes below.
//
// ── Canvas with an FBO render target, not the default ─────────────────
// A QML `Canvas` defaults to `Canvas.Image`: the scene is rasterised on
// the CPU into a QImage and uploaded every repaint. At 2560×1440 that is
// a ~14 MB upload per frame and it is the wrong tool here.
// `renderTarget: Canvas.FramebufferObject` keeps the drawing on the GPU,
// and `renderStrategy: Canvas.Cooperative` keeps it off the render
// thread's critical path.
//
// ── The link pass is bounded, and the bound is visible ────────────────
// Linking every pair is O(n²) — 300 points is 45,000 distance tests per
// frame. The loop below strides both indices by 2 and caps the inner
// window at 26, which is ~1,950 tests. That is a DELIBERATE cap, not a
// full solution: some genuinely-near pairs go unlinked. On a field of
// drifting dots that reads as variation rather than as absence, which is
// why it is acceptable here and would not be in a graph renderer.
//
// ── Points are sampled, and the sample is even ────────────────────────
// The shipped wordmark has ~430 filled cells. Rendering all of them
// makes the assembled state a solid slab rather than a constellation, so
// it is strided down toward `_wantPoints`. The stride is uniform rather
// than random so the assembled wordmark stays legible — a random sample
// leaves holes in strokes.
pragma ComponentBehavior: Bound

import QtQuick
import "../"
import "../dashboard"

Item {
    id: root

    required property SaverArt art
    property bool active: true

    readonly property int _wantPoints: 300

    property int _elapsed: 0
    // Flat arrays, parallel by index: target cell (grid fractions),
    // current position (surface fractions), and drift velocity.
    property var _tx: []
    property var _ty: []
    property var _px: []
    property var _py: []
    property var _vx: []
    property var _vy: []

    // 0 while loose, 1 while assembled. Smoothstepped so the migration
    // eases at both ends without an Animation driving it — the phase is a
    // function of position in the lap, not a triggered transition.
    readonly property real _pull: {
        var ph = root._elapsed / Math.max(1, Design.saverCycleMs);
        var raw;
        if (ph < 0.28)
            raw = 0;
        else if (ph < 0.52)
            raw = (ph - 0.28) / 0.24;
        else if (ph < 0.76)
            raw = 1;
        else
            raw = 1 - Math.min(1, (ph - 0.76) / 0.24);
        return raw * raw * (3 - 2 * raw);
    }

    // The box the assembled wordmark occupies, as fractions of the
    // surface. Width comes from the same container-derived fraction every
    // other style uses; height follows from the grid's own aspect so the
    // glyph cells stay square.
    readonly property real _boxW: Design.saverArtWidthFraction
    readonly property real _boxH: {
        var cw = root.width * root._boxW / Math.max(1, root.art.cols);
        // A half-block cell is about twice as tall as it is wide.
        return root.height > 0 ? (cw * 2 * root.art.rowCount) / root.height : 0.16;
    }

    function _build() {
        var rows = root.art.rows;
        var cols = root.art.cols;
        var n = root.art.rowCount;
        var filled = [];
        for (var r = 0; r < n; r++) {
            var line = rows[r] || "";
            for (var c = 0; c < cols; c++) {
                if (c < line.length && line[c] !== " ")
                    filled.push([c / Math.max(1, cols - 1), r / Math.max(1, n - 1)]);
            }
        }
        if (filled.length === 0)
            filled.push([0.5, 0.5]);

        var stride = Math.max(1, Math.floor(filled.length / root._wantPoints));
        var tx = [], ty = [], px = [], py = [], vx = [], vy = [];
        for (var i = 0; i < filled.length; i += stride) {
            tx.push(filled[i][0]);
            ty.push(filled[i][1]);
            px.push(Math.random());
            py.push(Math.random());
            // Slow enough that the loose field reads as a drift rather
            // than as noise; the units are surface fractions per second.
            vx.push((Math.random() - 0.5) * 0.05);
            vy.push((Math.random() - 0.5) * 0.05);
        }
        root._tx = tx;
        root._ty = ty;
        root._px = px;
        root._py = py;
        root._vx = vx;
        root._vy = vy;
    }

    Component.onCompleted: root._build()

    Connections {
        target: root.art
        function onRowsChanged() {
            root._build();
        }
    }

    Timer {
        running: root.active && root.visible
        repeat: true
        interval: Design.saverTickMs
        onTriggered: {
            root._elapsed = (root._elapsed + Design.saverTickMs) % Math.max(1, Design.saverCycleMs);
            // Only integrate the drift while the points are loose —
            // integrating under a pull would fight the migration and make
            // the assembled wordmark jitter.
            if (root._pull < 0.02) {
                var s = Design.saverTickMs / 1000;
                var px = root._px, py = root._py, vx = root._vx, vy = root._vy;
                for (var i = 0; i < px.length; i++) {
                    px[i] += vx[i] * s;
                    py[i] += vy[i] * s;
                    if (px[i] < 0 || px[i] > 1)
                        vx[i] = -vx[i];
                    if (py[i] < 0 || py[i] > 1)
                        vy[i] = -vy[i];
                }
            }
            field.requestPaint();
        }
    }

    Canvas {
        id: field

        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d");
            var w = width, h = height;
            ctx.clearRect(0, 0, w, h);
            if (!root._px || root._px.length === 0)
                return;

            var pull = root._pull;
            var ox = (1 - root._boxW) / 2;
            var oy = (1 - root._boxH) / 2;
            var n = root._px.length;

            // Resolve each point's drawn position once, into local arrays
            // the link pass below reuses — recomputing the lerp inside the
            // O(n·k) link loop would do the same work ~26 times over.
            var dx = new Array(n), dy = new Array(n);
            for (var i = 0; i < n; i++) {
                var gx = ox + root._tx[i] * root._boxW;
                var gy = oy + root._ty[i] * root._boxH;
                dx[i] = (root._px[i] + (gx - root._px[i]) * pull) * w;
                dy[i] = (root._py[i] + (gy - root._py[i]) * pull) * h;
            }

            // ── Links, strongest while the field is loose ──────────────
            var linkBase = 0.30 * (1 - pull) + 0.06;
            var reach = Math.max(40, w * 0.03);
            var reach2 = reach * reach;
            var lc = Colours.outline;
            ctx.lineWidth = 1;
            for (var a = 0; a < n; a += 2) {
                for (var b = a + 2; b < Math.min(a + 26, n); b += 2) {
                    var ddx = dx[a] - dx[b];
                    var ddy = dy[a] - dy[b];
                    var d2 = ddx * ddx + ddy * ddy;
                    if (d2 < reach2) {
                        ctx.strokeStyle = Qt.rgba(lc.r, lc.g, lc.b, linkBase * (1 - d2 / reach2));
                        ctx.beginPath();
                        ctx.moveTo(dx[a], dy[a]);
                        ctx.lineTo(dx[b], dy[b]);
                        ctx.stroke();
                    }
                }
            }

            // ── Points ────────────────────────────────────────────────
            // Loose points take the secondary accent; assembled ones
            // resolve toward onSurface, so the wordmark arrives as a
            // colour change as well as a position change.
            var loose = Colours.secondary;
            var solid = Colours.onSurface;
            var mixR = loose.r + (solid.r - loose.r) * pull;
            var mixG = loose.g + (solid.g - loose.g) * pull;
            var mixB = loose.b + (solid.b - loose.b) * pull;
            var radius = Math.max(1.2, w / 1400) * (1 + pull * 0.8);
            ctx.fillStyle = Qt.rgba(mixR, mixG, mixB, 0.72 + pull * 0.28);
            for (var k = 0; k < n; k++) {
                ctx.beginPath();
                ctx.arc(dx[k], dy[k], radius, 0, Math.PI * 2);
                ctx.fill();
            }
        }
    }
}
