// modules/settings/common/RowSurface.qml — shared rest/hover/focus/press
// background for the settings-row primitives (operator round 5, item 2).
//
// WHY THIS EXISTS: every row (InfoRow/NavRow/SelectRow/SliderRow/
// StepperRow/TextRow/ToggleRow) declared its own `background: Rectangle`
// with the identical border-ring focus/hover language — 7 copies of the
// same code, none of which painted anything on PRESS at all. Clicking a
// row produced: no press response, then a 300ms animated ring. The
// operator's own report ("does not feel satisfying / no mouse feedback")
// is exactly that gap. One shared component instead of a fix repeated
// per-row, per the standing lesson: fix the population, not the instance.
//
// PRESS IS IMMEDIATE. No `Behavior` on the press fill — a press that
// fades in over `Motion.colourDuration` (300ms) is the same class of bug
// item 1 this round just fixed (a discrete state change animated too
// slowly reads as a flash, not a response). `focused`/`hovered` keep the
// existing animated border ring — unchanged behaviour, only centralised.
//
// COLOUR STAYS RESTRAINED. The press fill is a deeper NEUTRAL tint
// (`Qt.alpha(Colours.onSurface, 0.13)`), the same tone family every row's
// own hover-adjacent fills already use elsewhere in this module — never a
// new bright accent. The operator has rejected a loud accent three times
// (rounds 2-4); this is not a fourth attempt.
//
// `accent` stays a property (not hardcoded `Colours.primary`) so a future
// row type sharing this surface is not locked to the wrong ring hue —
// every current row's own inline background used `Colours.primary`
// verbatim, so the default matches every existing call site byte-for-byte.
import QtQuick
import "../../"

Rectangle {
    id: root

    // Discrete, keyboard-driven selection state — unchanged animated
    // border-ring behaviour every row already had.
    property bool focused: false
    // Continuous pointer-hover state — same ring, same animation, just
    // OR'd with `focused` exactly as every row's own inline background did.
    property bool hovered: false
    // Immediate press response. Defaults false and stays false for rows
    // with no whole-row click target (InfoRow is explicitly
    // non-interactive per its own header; TextRow's click target is the
    // inner TextField, which paints its own background) — this property
    // is simply never driven true there, so those two rows keep their
    // exact prior rest/hover/focus-only behaviour.
    property bool pressed: false
    property color accent: Colours.primary
    property real cornerRadius: 12

    radius: root.cornerRadius
    color: root.pressed ? Qt.alpha(Colours.onSurface, 0.13) : Qt.alpha(Colours.onSurface, 0)
    // No `Behavior on color` — press must be instantaneous, not a fade.

    border.width: 2
    border.color: (root.focused || root.hovered) ? root.accent : Qt.alpha(root.accent, 0)

    Behavior on border.color {
        enabled: Motion.motionEnabled
        ColorAnimation {
            duration: Motion.colourDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.colourEasing
        }
    }
}
