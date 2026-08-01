// GradientBorder.qml — an animated gradient rim, matching Hyprland's own
// window border (DASH-10, Phase 14).
//
// WHAT THIS IS
// Hyprland draws focused windows with a multi-stop gradient border whose
// angle rotates continuously (`general:col.active_border` + the `borderangle`
// animation, `style=loop`). The dashboard drawer is a layer-shell surface,
// not a window, so it gets no border from the compositor at all. This
// component reproduces that treatment so the drawer reads as part of the same
// desktop rather than as a foreign panel.
//
// EXACT PARITY, NOT AN IMITATION — every value below is either a token or a
// live-verified Hyprland setting, none is a taste call:
//   - stops       Colours.primary -> secondary -> tertiary. On this theme
//                 those resolve to #ff79c6 / #bd93f9 / #8be9fd, which is
//                 BYTE-IDENTICAL to the live `general:col.active_border`
//                 gradient. Reading them as tokens rather than hex keeps the
//                 repo-wide zero-hex invariant intact AND means the border
//                 re-themes with everything else on a theme switch.
//   - width       `general:border_size` (3 on this host).
//   - start angle `col.active_border`'s own 45deg.
//   - period      Motion.borderRotateDuration — the SAME `border-rotate`
//                 token Hyprland's `borderangle` consumes, already
//                 ceiling-clamped by lib/motion.sh to what Hyprland actually
//                 runs, so the drawer's rim and every window border on screen
//                 stay in step at every motion-scale preset.
//
// HOW THE RIM IS DRAWN
// QML's `Rectangle.border` takes a solid colour only — there is no gradient
// border primitive, and `ShapePath` applies gradients to fill, never stroke.
// The standard construction is therefore: draw the full gradient, then mask
// it to a ring.
//
// The usual cheap trick — a gradient rectangle with an opaque inset rectangle
// on top — is NOT usable here: the drawer's surface is translucent (it sits
// over a compositor blur), so an inset "cover" rectangle would let the
// gradient show straight through the whole panel. Real alpha masking is
// required, which is why this uses MultiEffect rather than two stacked rects.
//
// The mask is a `Rectangle` with a transparent fill and a coloured border —
// a Rectangle's border IS the ring shape, so no hand-built path is needed and
// per-corner radii come along for free.
//
// `visible: false` + `layer.enabled: true` on BOTH mask and source is
// load-bearing, not tidiness. 14-05 lost a session to exactly this: a
// MultiEffect mask input with no `layer.enabled` produces no scene-graph
// paint node at all, which reads as an EMPTY mask rather than a full one, and
// the effect composites nothing. See MediaTab.qml's `artMaskShape` for the
// same pairing and the full write-up.
//
// ROTATION
// The gradient item is oversized to the bounding diagonal and centred, so
// that at every angle its rotated footprint still covers all four corners of
// the rim — a parent-sized gradient would sweep its own empty corners across
// the border as it turned. It is clipped back to the rim's bounds by
// `gradientSource`, so the oversize costs nothing on screen.
//
// The spin is gated on `Motion.motionEnabled`, so the `off` motion-scale
// preset yields a still gradient rather than an animation that ignores the
// axis. This surface is summon-only (the drawer's whole window is destroyed
// on dismiss), so a continuously-running animation here does not violate the
// zero-idle doctrine: nothing spins while the drawer is closed.
import QtQuick
import QtQuick.Effects
import "../"

Item {
    id: root

    // Hyprland's `general:border_size`. Not a token — Hyprland's border width
    // has no representation in the motion/colour pipelines — so it is named
    // here once rather than repeated at the call site.
    property int borderWidth: 3

    // `col.active_border`'s own starting angle, kept separate from the
    // animated `angle` so the loop can run a clean 0->360 while still
    // beginning where Hyprland begins.
    property real startAngle: 45

    // Per-corner radii, mirroring Rectangle's own property names so a caller
    // can hand across exactly what it gave its surface. The drawer is
    // square-topped and round-bottomed, so a single uniform `radius` would
    // not fit it.
    property real topLeftRadius: 0
    property real topRightRadius: 0
    property real bottomLeftRadius: 0
    property real bottomRightRadius: 0

    // Lets a caller stop the spin without unloading the component.
    property bool active: true

    // Rotating a WxH rectangle sweeps a circle of its diagonal; sizing the
    // gradient to that guarantees full coverage at every angle.
    readonly property real _diagonal: Math.ceil(Math.sqrt(width * width + height * height))

    property real angle: 0

    // ── Source: the gradient, clipped back to the rim's own bounds so the
    //    oversized rotating rectangle never inflates this item ────────────
    Item {
        id: gradientSource
        anchors.fill: parent
        clip: true
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.centerIn: parent
            width: root._diagonal
            height: root._diagonal
            rotation: root.startAngle + root.angle

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: Colours.primary
                }
                GradientStop {
                    position: 0.5
                    color: Colours.secondary
                }
                GradientStop {
                    position: 1.0
                    color: Colours.tertiary
                }
            }
        }
    }

    // ── Mask: the ring ──────────────────────────────────────────────────
    // `transparent` fill + opaque border are ALPHA-CHANNEL values, not design
    // colours — this Rectangle is never painted (`visible: false`), it exists
    // only as a mask shape, so it is deliberately not themed and is not a
    // zero-hex-invariant exception.
    Rectangle {
        id: ringMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        color: "transparent"
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        border.width: root.borderWidth
        border.color: "white"
    }

    MultiEffect {
        anchors.fill: parent
        source: gradientSource
        maskEnabled: true
        maskSource: ringMask
    }

    // Linear and looping, matching `borderangle`'s own `style=loop` and
    // `motion-linear` curve. `Easing.Linear` is QML's own enum rather than a
    // bezier read off the token: the token's `linear` curve is [1,1,1,1],
    // which is a Hyprland curve-registration value, and feeding it to
    // BezierSpline would NOT produce uniform rotation. The period — the part
    // that actually has to match Hyprland — still comes from the token.
    NumberAnimation on angle {
        running: Motion.motionEnabled && root.active
        from: 0
        to: 360
        duration: Motion.borderRotateDuration
        loops: Animation.Infinite
        easing.type: Easing.Linear
    }
}
