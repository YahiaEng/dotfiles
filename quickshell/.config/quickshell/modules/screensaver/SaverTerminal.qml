// SaverTerminal.qml — screensaver style S1, "Terminal Effects" (quick
// task 260827-b52, operator pick 1 of 4, the DEFAULT style).
//
// The faithful port of what Omarchy's screensaver does: the wordmark
// re-revealed forever by a rotating set of effects. Omarchy gets its
// effects from `tte --random-effect`; that binary is not packaged on
// Arch, so the five below are written here.
//
// ── Three Text layers per row, not one Text per cell ──────────────────
// The obvious shape — one Text per character — is 780 items for the
// shipped 10×78 wordmark, each with its own binding graph, rebuilt on
// every theme change. This file instead draws each row THREE times, once
// per visual state, and moves characters between the layers by rewriting
// three strings:
//
//   scrambleLayer  cells about to resolve, showing noise   (outline)
//   accentLayer    cells that JUST resolved                (accent)
//   resolvedLayer  cells that have settled                 (onSurface)
//
// Every layer renders the full row width with non-member cells replaced
// by spaces, so the three overlay exactly. That is 30 Text items for the
// whole surface instead of 780, and a tick rewrites 30 strings rather
// than touching 780 bindings. The monospace grid (SaverArt.fontFamily)
// is what makes the overlay register.
//
// ── The clock is a counter, not a wall clock ──────────────────────────
// `_elapsed` accumulates `Design.saverTickMs` per tick. A Date-based
// clock would make every effect's timing depend on how long the tick
// actually took, and would jump on a suspend/resume — this surface
// outlives both.
pragma ComponentBehavior: Bound

import QtQuick
import "../"
import "../dashboard"

Item {
    id: root

    required property SaverArt art
    // Set false by the surface while it is animating out, so the tick
    // stops rewriting strings behind a fading layer.
    property bool active: true

    readonly property int cols: root.art.cols
    readonly property int rowCount: root.art.rowCount

    // Derived from the container, never an eyeballed point size (MEMORY
    // derive-size-from-container). One character cell is
    // `width * fraction / cols` wide; a monospace advance is ~0.6em, so
    // the point size that fills that cell is that divided by 0.6.
    readonly property real cellWidth: root.width * Design.saverArtWidthFraction / Math.max(1, root.cols)
    readonly property real glyphSize: Math.max(6, cellWidth / 0.6)

    // ── Effect state ──────────────────────────────────────────────────
    readonly property var effects: ["decrypt", "rain", "burn", "expand", "slide"]
    property int effectIndex: 0
    property int _elapsed: 0
    // "reveal" while the stagger window runs, "hold" while the finished
    // wordmark sits, "wipe" while it fades out before the next effect.
    property string phase: "reveal"
    // Per-cell reveal offsets, flat row-major, regenerated per effect.
    property var _t0: []
    // Rebuilt every tick: three arrays of `rowCount` strings.
    property var _scramble: []
    property var _accent: []
    property var _resolved: []

    readonly property color _accentColour: {
        switch (root.effectIndex % 3) {
        case 0:
            return Colours.primary;
        case 1:
            return Colours.secondary;
        default:
            return Colours.tertiary;
        }
    }

    // How long a cell stays accent-coloured after resolving. Derived from
    // the reveal window rather than declared, so shortening an effect
    // shortens its flash proportionally instead of leaving a flash longer
    // than the effect that produced it.
    readonly property int _flashMs: Math.round(Design.saverEffectRevealMs / 6)
    // How far ahead of its own reveal a cell starts showing noise.
    readonly property int _previewMs: Math.round(Design.saverEffectRevealMs / 4)

    // Builds the per-cell reveal offsets for one effect. Every branch
    // returns a real number — `undefined` here would resolve to NaN and
    // the cell would never reveal (MEMORY
    // qml-undefined-branch-destroys-binding, same class).
    function _plan(kind) {
        var rows = root.art.rows;
        var n = root.rowCount * root.cols;
        var out = new Array(n);
        var cx = (root.cols - 1) / 2;
        var cy = (root.rowCount - 1) / 2;
        var window = Design.saverEffectRevealMs;
        // One random head start per column, shared down the column, so
        // "rain" reads as columns falling rather than cells twinkling.
        var heads = new Array(root.cols);
        for (var h = 0; h < root.cols; h++)
            heads[h] = Math.random() * window * 0.45;

        for (var r = 0; r < root.rowCount; r++) {
            for (var c = 0; c < root.cols; c++) {
                var d;
                switch (kind) {
                case "decrypt":
                    d = Math.random() * window * 0.72;
                    break;
                case "rain":
                    d = heads[c] + r * (window * 0.045);
                    break;
                case "burn":
                    d = (root.rowCount - 1 - r) * (window * 0.075) + Math.random() * (window * 0.1);
                    break;
                case "expand":
                    // Elliptical so the wide, short wordmark resolves as a
                    // ring rather than a vertical band: the x term is
                    // divided by the grid's own aspect.
                    d = Math.hypot((c - cx) / (root.cols / root.rowCount / 2), r - cy) * (window * 0.05) + Math.random() * (window * 0.06);
                    break;
                default:
                    // slide — both edges inward
                    d = Math.min(c, root.cols - 1 - c) * (window * 0.017) + Math.random() * (window * 0.07);
                    break;
                }
                out[r * root.cols + c] = d;
            }
        }
        return out;
    }

    function _restart() {
        root._t0 = root._plan(root.effects[root.effectIndex]);
        root._elapsed = 0;
        root.phase = "reveal";
        root._rebuild();
    }

    // Rewrites the three layer strings for the current `_elapsed`.
    function _rebuild() {
        var rows = root.art.rows;
        var t = root._elapsed;
        var sc = new Array(root.rowCount);
        var ac = new Array(root.rowCount);
        var rs = new Array(root.rowCount);
        var glyphs = root.art.scrambleGlyphs;

        for (var r = 0; r < root.rowCount; r++) {
            var line = rows[r] || "";
            var s = "", a = "", v = "";
            for (var c = 0; c < root.cols; c++) {
                var ch = c < line.length ? line[c] : " ";
                if (ch === " ") {
                    s += " ";
                    a += " ";
                    v += " ";
                    continue;
                }
                var t0 = root._t0[r * root.cols + c];
                if (root.phase !== "reveal" || t >= t0 + root._flashMs) {
                    s += " ";
                    a += " ";
                    v += ch;
                } else if (t >= t0) {
                    s += " ";
                    a += ch;
                    v += " ";
                } else if (t >= t0 - root._previewMs) {
                    s += glyphs[Math.floor(Math.random() * glyphs.length)];
                    a += " ";
                    v += " ";
                } else {
                    s += " ";
                    a += " ";
                    v += " ";
                }
            }
            sc[r] = s;
            ac[r] = a;
            rs[r] = v;
        }
        root._scramble = sc;
        root._accent = ac;
        root._resolved = rs;
    }

    // Regenerate whenever the art itself changes (a branding file edit
    // lands mid-cycle) — the old plan is sized to the old grid.
    Connections {
        target: root.art
        function onRowsChanged() {
            root._restart();
        }
    }

    Component.onCompleted: root._restart()

    Timer {
        running: root.active && root.visible
        repeat: true
        interval: Design.saverTickMs
        onTriggered: {
            root._elapsed += Design.saverTickMs;
            var revealEnd = Design.saverEffectRevealMs;
            if (root.phase === "reveal") {
                root._rebuild();
                if (root._elapsed >= revealEnd) {
                    root.phase = "hold";
                    root._elapsed = 0;
                    root._rebuild();
                }
            } else if (root.phase === "hold") {
                if (root._elapsed >= Design.saverEffectHoldMs) {
                    root.phase = "wipe";
                    root._elapsed = 0;
                }
            } else if (root._elapsed >= Motion.standardDuration) {
                root.effectIndex = (root.effectIndex + 1) % root.effects.length;
                root._restart();
            }
        }
    }

    // ── The grid ──────────────────────────────────────────────────────
    Column {
        id: grid

        anchors.centerIn: parent
        spacing: 0
        // Fades between effects. `phase === "wipe"` is the only state that
        // hides it, so a stalled tick leaves the wordmark visible rather
        // than leaving a black screen.
        opacity: root.phase === "wipe" ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }

        Repeater {
            model: root.rowCount

            delegate: Item {
                id: rowItem

                required property int index

                implicitWidth: resolvedLayer.implicitWidth
                implicitHeight: resolvedLayer.implicitHeight

                Text {
                    id: resolvedLayer

                    font.family: root.art.fontFamily
                    font.pixelSize: root.glyphSize
                    font.hintingPreference: Font.PreferNoHinting
                    lineHeight: 1.0
                    color: Colours.onSurface
                    text: root._resolved[rowItem.index] || ""
                }

                Text {
                    anchors.fill: resolvedLayer
                    font: resolvedLayer.font
                    lineHeight: 1.0
                    color: root._accentColour
                    text: root._accent[rowItem.index] || ""
                }

                Text {
                    anchors.fill: resolvedLayer
                    font: resolvedLayer.font
                    lineHeight: 1.0
                    color: Colours.outline
                    text: root._scramble[rowItem.index] || ""
                }
            }
        }
    }

    // The effect's own name, set very quiet under the wordmark. Omarchy
    // shows nothing here; this is the one addition, and it earns its place
    // by making "which effect is this" answerable without reading the
    // source during a live check.
    Text {
        anchors.horizontalCenter: grid.horizontalCenter
        anchors.top: grid.bottom
        anchors.topMargin: Design.spacingXl
        font.family: root.art.fontFamily
        font.pixelSize: Design.fontLabel
        font.letterSpacing: Design.fontLabel * 0.24
        color: Colours.outline
        opacity: root.phase === "wipe" ? 0 : 0.55
        text: root.effects[root.effectIndex].toUpperCase()

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }
}
