// SaverAurora.qml — screensaver style S3, "Palette Aurora" (quick task
// 260827-b52, operator pick 2 of 4).
//
// Three slow fields in primary/secondary/tertiary drifting over surface,
// with the wordmark ghosted at centre. This is the project's own core
// value rendered — switch theme and the screensaver becomes a different
// screensaver with no per-style work, because it IS the palette.
//
// ── The blur budget, resolved by measurement after an operator report ──
// The first build drew the fields into a layer rendered at 1/8 output
// resolution (`layer.textureSize`) so the downscale would do most of the
// blurring for free. Operator: "the blur effect does not work".
//
// MEASURED, by sampling a row across a field boundary and counting the
// 15%–85% transition band: with `layer.textureSize` the edge ramped over
// ~320px; with it removed and `blurMax: 64`, over ~816px. So the
// downscale did NOT disable the effect — an earlier note here claimed it
// did, and that claim was wrong — it simply produced a much tighter edge
// than an aurora wants, because `blurMax` is in TEXTURE pixels and 24 of
// them is a small radius once the texture is only 320×180.
//
// The trade accepted: this now runs a real full-resolution blur, which is
// the GPU cost the design study flagged as this plate's one genuine risk.
// It is an idle surface, so the cost is paid only while nobody is using
// the machine. Do not reintroduce `layer.textureSize` to claw it back
// without re-measuring the ramp — that is the knob that regressed it.
//
// ── Painting its own ground ───────────────────────────────────────────
// The surface's ground is true black (ruling D2). This style paints
// `Colours.surface` over it, because an aurora needs something to sit on
// — three coloured fields over pure black read as three lights in a void
// rather than as a tinted field. Styles are allowed to paint their own
// ground; the black is the default, not a constraint.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import "../"
import "../dashboard"

Item {
    id: root

    required property SaverArt art
    property bool active: true

    readonly property real cellWidth: root.width * Design.saverArtWidthFraction / Math.max(1, root.art.cols)
    readonly property real glyphSize: Math.max(6, cellWidth / 0.6)

    Rectangle {
        anchors.fill: parent
        color: Colours.surface
    }

    Item {
        id: fields

        anchors.fill: parent

        layer.enabled: true
        layer.smooth: true
        // NO `layer.textureSize` HERE — see the header. It did NOT disable
        // the effect (an earlier note claimed that and was wrong); it
        // tightened the edge ramp from ~816px to ~320px, which is not what
        // an aurora wants.
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            // A HARD CAP, not a free parameter. The study asks for
            // `filter: blur(7cqw)`, which at 2560 wide is ~179px — and
            // MultiEffect rendered NOTHING AT ALL at that value: the fields
            // vanished completely and the screen was bare surface. Measured
            // by bisection, ~64 is the largest radius that still draws here.
            // Raising this to chase the study's figure re-breaks the plate;
            // if more softness is ever needed, get it from the field sizes
            // and opacity, not from this number.
            blurMax: 64
            blurMultiplier: 1
        }

        Repeater {
            id: fieldRepeater

            model: 3

            delegate: Rectangle {
                id: blob

                required property int index

                // ── Geometry and motion are the STUDY's, not re-derived ───
                // `.planning/notes/aorus-screensaver/studies.html`, buildS3:
                // widths 46/55/64% of the container, `filter: blur(7cqw)`,
                // `opacity: .55`, over `--surface`; positions are fractions
                // that drift at a CONSTANT velocity and bounce at -0.35 and
                // 0.95.
                //
                // Two earlier builds got this wrong in opposite directions
                // and both were operator-visible. First, easing: driving x
                // and y with `Easing.InOutSine` between two endpoints makes
                // a field DECELERATE TO A STOP at each extreme, which is
                // exactly where it is mostly off-screen — so the screen
                // read as bare surface with one lobe in a corner. The study
                // bounces at constant speed and therefore spends its time
                // spread evenly across the range. Second, over-correcting
                // that by sizing the fields past the screen diagonal made
                // all three overlap everywhere and the plate collapsed to
                // ONE FLAT COLOUR.
                //
                // The sizes below are the study's 46/55/64% SCALED UP to
                // 68/78/88%, which is a deliberate divergence: the operator
                // asked for the fields to "fill the entire screen", and at
                // the study's own sizes the measured coverage was 57%. At
                // these it is 92.7% with all three hues still distinct
                // (pink 33% / purple 22% / cyan 45%) — the point being that
                // they must overlap enough to cover, but not so much that
                // they blend into one colour.
                readonly property real span: root.width * (0.68 + blob.index * 0.10)

                // Position as a fraction of the output, drifting at a
                // constant rate. Seeded so the three neither start together
                // nor share a direction.
                property real fx: [-0.10, 0.30, 0.46][blob.index]
                property real fy: [-0.06, 0.24, -0.02][blob.index]
                property real vx: [0.021, -0.026, 0.016][blob.index]
                property real vy: [0.017, 0.013, -0.020][blob.index]

                x: root.width * blob.fx
                y: root.height * blob.fy
                width: blob.span
                height: blob.span
                radius: blob.span / 2
                // 0.42, not the study's 0.55 — operator, on the built
                // version: "the colors are too bright and the text is hard
                // to read". Lowering the fields is the half of that fix
                // that does not touch the wordmark.
                opacity: 0.42
                color: blob.index === 0 ? Colours.primary : (blob.index === 1 ? Colours.secondary : Colours.tertiary)
            }
        }

        // One ticker for all three fields — the study's own tick(), which
        // integrates a constant velocity and reverses it at the bounds.
        // A Timer rather than three Animations, because the bounce is a
        // condition on position, not a fixed pair of endpoints.
        Timer {
            running: root.active && root.visible
            repeat: true
            interval: Design.saverTickMs
            onTriggered: {
                const s = Design.saverTickMs / 1000;
                for (let i = 0; i < fieldRepeater.count; i++) {
                    const b = fieldRepeater.itemAt(i);
                    if (!b)
                        continue;
                    b.fx += b.vx * s;
                    b.fy += b.vy * s;
                    if (b.fx < -0.30 || b.fx > 0.62)
                        b.vx = -b.vx;
                    if (b.fy < -0.30 || b.fy > 0.55)
                        b.vy = -b.vy;
                }
            }
        }
    }

    // ── The wordmark ──────────────────────────────────────────────────
    // The study ghosts this at 0.17, and at that value the operator could
    // not read it against the fields: "the text is hard to read". This is
    // a DELIBERATE divergence from the reference on the operator's own
    // report — 0.17 is a watermark, and a watermark is not what this plate
    // needs once the fields behind it carry real colour.
    //
    // It still breathes rather than sitting still, which is what keeps
    // this style burn-in safe even though the mark never moves from
    // centre — no pixel holds a constant value.
    Column {
        anchors.centerIn: parent
        spacing: 0
        opacity: 0.62

        SequentialAnimation on opacity {
            running: root.active
            loops: Animation.Infinite
            NumberAnimation {
                from: 0.52
                to: 0.72
                duration: Math.round(Design.saverDriftMs / 3)
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                from: 0.72
                to: 0.52
                duration: Math.round(Design.saverDriftMs / 3)
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
