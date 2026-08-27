// SaverAurora.qml — screensaver style S3, "Palette Aurora" (quick task
// 260827-b52, operator pick 2 of 4).
//
// Three slow fields in primary/secondary/tertiary drifting over surface,
// with the wordmark ghosted at centre. This is the project's own core
// value rendered — switch theme and the screensaver becomes a different
// screensaver with no per-style work, because it IS the palette.
//
// ── The blur budget, which the design study flagged as this plate's one
//    genuine risk ─────────────────────────────────────────────────────
// A naive full-size blur here is a 2560×1440 gaussian every frame at
// 165 Hz for an ambient surface nobody is looking at closely. Instead the
// three circles are drawn into ONE layer rendered at a fraction of the
// output resolution (`layer.textureSize`), and that downscale does most
// of the blurring for free — magnifying an eighth-scale texture back to
// full size is bilinear interpolation on the GPU's own sampler, which is
// effectively free. MultiEffect then only has to soften what is left, so
// its `blurMax` is small.
//
// This is why `blurMax` looks low for the visual result: the radius is
// in TEXTURE pixels, so 24 there is ~192 output pixels after the 8×
// magnification. Raising `_downscale` (fewer texture pixels) makes this
// cheaper AND blurrier at the same time; the two are not traded off.
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

    // One eighth in each axis: 1/64 of the fragment work of a full-size
    // blur, before MultiEffect's own radius is considered.
    readonly property int _downscale: 8

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
        layer.textureSize: Qt.size(Math.max(1, Math.round(root.width / root._downscale)), Math.max(1, Math.round(root.height / root._downscale)))
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 24
            blurMultiplier: 1
        }

        Repeater {
            model: 3

            delegate: Rectangle {
                id: blob

                required property int index

                // Each field is a different size so the three never read
                // as one shape moving; the largest is the slowest.
                readonly property real span: root.width * (0.46 + blob.index * 0.09)
                // Periods are deliberately non-multiples of each other so
                // the three never return to the same relative positions —
                // a repeating pattern is the one thing an ambient field
                // must not do.
                readonly property int periodX: Design.saverDriftMs + blob.index * 7000
                readonly property int periodY: Math.round(Design.saverDriftMs * 1.37) + blob.index * 5000

                width: span
                height: span
                radius: span / 2
                opacity: 0.55
                color: blob.index === 0 ? Colours.primary : (blob.index === 1 ? Colours.secondary : Colours.tertiary)

                // Travel beyond both edges so a field is sometimes only
                // partly on screen — three fields fully inside the frame
                // at all times reads as a composition rather than a drift.
                SequentialAnimation on x {
                    running: root.active
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: -blob.span * 0.45
                        to: root.width - blob.span * 0.55
                        duration: blob.periodX
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        from: root.width - blob.span * 0.55
                        to: -blob.span * 0.45
                        duration: blob.periodX
                        easing.type: Easing.InOutSine
                    }
                }

                SequentialAnimation on y {
                    running: root.active
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: root.height - blob.span * 0.62
                        to: -blob.span * 0.38
                        duration: blob.periodY
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        from: -blob.span * 0.38
                        to: root.height - blob.span * 0.62
                        duration: blob.periodY
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    // ── The wordmark, ghosted ─────────────────────────────────────────
    // Low enough to read as a watermark in the field rather than as a
    // label on top of it. It breathes rather than sitting still, which is
    // what keeps this style burn-in safe even though the mark never moves
    // from centre — at this opacity, over a field that is itself always
    // moving, no pixel holds a constant value.
    Column {
        anchors.centerIn: parent
        spacing: 0
        opacity: 0.17

        SequentialAnimation on opacity {
            running: root.active
            loops: Animation.Infinite
            NumberAnimation {
                from: 0.13
                to: 0.22
                duration: Math.round(Design.saverDriftMs / 3)
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                from: 0.22
                to: 0.13
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
