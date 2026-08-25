// IdleInhibitorCapsule.qml — the idle-inhibitor bulb's own capsule slot
// (GATE-02 operator fix, item (b): relocate the bulb out of the
// clock/actions capsule and into the centre zone, beside workspaces).
//
// Upstream Athena places `idle_inhibitor` in modules-center, immediately
// right of `hyprland/workspaces` (ATHENA-UPSTREAM-SPEC.md) — NOT beside
// clock/settings on the right, which is where ClockActionsCapsule.qml had
// it before this fix. Only the BAR CELL moves here: the backend
// (`IdleInhibitor`, `idleInhibited`) is carried over verbatim from
// ClockActionsCapsule.qml's own block, unchanged in behaviour.
//
// OPERATOR CONSTRAINT: no power-profiles-daemon pill is added here or
// anywhere else on this bar, even though upstream Athena also places one in
// modules-center (left of workspaces) — the operator explicitly does not
// want it. Only the bulb moves.
//
// `surfaced` is left at BarCapsule's own false default (Operator decision,
// GATE-02 round 2, recorded on BarCapsule.qml): only WorkspaceCapsule sets
// it true. This capsule is its own pill in the entry-list/zone sense — a
// distinct BarEntryModel/componentFor() slot, not folded into
// WorkspaceCapsule — but renders as a bare glyph on the wallpaper like
// every other capsule.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"
import "../dashboard"

BarCapsule {
    id: idleInhibitorCapsule
    capsuleId: "idleInhibitor"

    // Operator: the centre bulb carries a background. This is also what
    // upstream does — `#power-profiles-daemon, #idle_inhibitor` get
    // `background-color: @surface_container` exactly like every group
    // (ATHENA-UPSTREAM-SPEC.md) — so the bar's surfaced set is now the
    // workspace capsule plus this one, and nothing else.
    surfaced: true

    // F3 (quick task 260812-69w) — Task 1's Probe C measured the FILL
    // variable axis genuinely functional on this host (byte-different
    // grabToImage renders for FILL:0 vs FILL:1; fc-match's own resolved
    // file carries the axis list in its name:
    // MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf). So the operator's
    // "the bulb doesn't read as on" complaint is not a broken axis — it is
    // a small glyph changing colour being too subtle a signal at bar
    // scale. The fix: when inhibited, fill the WHOLE capsule pill with
    // BarRoles.accent — the identical "on" language WorkspaceCapsule's own
    // active-slot pill already speaks (slotFillColour: BarRoles.accent /
    // slotTextColour: BarRoles.onAccent) and ClockActionsCapsule's own
    // gamingCell tint idiom echoes (`active ? BarRoles.accent :
    // contentColour`) — no new visual vocabulary. Overriding `color` here
    // (rather than adding a fillActive/fillColour pair to BarCapsule.qml,
    // ActionCell's own idiom) keeps BarCapsule's shared `Behavior on
    // color` animating this override too, and leaves the other five
    // consumers of that shared chrome untouched. fillAxisAvailable below
    // is read by the glyph's own font.variableAxes expression — its VALUE
    // is unchanged by this fix; only the FILL glyph's insufficient legibility.
    color: idleInhibitorCapsule.idleInhibited ? BarRoles.accent : (idleInhibitorCapsule.hovered ? BarRoles.capsuleHover : BarRoles.capsule)

    // 14-02's recorded per-file capability flag — Design.qml's own header
    // note records this is deliberately not a shared token, since it is a
    // claim about the font build rather than a design token.
    readonly property bool fillAxisAvailable: true

    // ── Idle inhibitor — carried verbatim from ClockActionsCapsule.qml's
    //    own block (this plan only relocates the BAR CELL, not the
    //    mechanism): the native wayland idle-inhibit client, bound to the
    //    bar's own permanently-mapped window. Starts disabled on every
    //    shell start and is never persisted: an inhibitor restored after
    //    an automatic restart would keep the machine awake with no visible
    //    cause, the same failure class this repo already records for a
    //    stale gaming state — failing to "not inhibiting" is the only safe
    //    default. ─────────────────────────────────────────────────────────
    property bool idleInhibited: false

    IdleInhibitor {
        id: barIdleInhibitor
        window: QsWindow.window
        enabled: idleInhibitorCapsule.idleInhibited
    }

    // ── The bulb — one bare cell, reproducing ClockActionsCapsule.qml's
    //    own ActionCell geometry (a barGlyphSize glyph inside
    //    spacingXs-on-each-side padding) directly rather than importing it,
    //    since ActionCell is a private inline component scoped to that
    //    file, not a shared type. Tint idiom matches gamingCell's own:
    //    `active ? BarRoles.accent : contentColour`. ─────────────────────
    Item {
        id: idleCell
        width: Design.barGlyphSize + Design.spacingXs * 2
        height: Design.barGlyphSize + Design.spacingXs * 2

        Text {
            id: idleGlyph
            anchors.centerIn: parent
            text: "lightbulb"
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.barGlyphSize
            font.variableAxes: idleInhibitorCapsule.fillAxisAvailable ? { "FILL": idleInhibitorCapsule.idleInhibited ? 1 : 0 } : ({})
            // F3 — onAccent, not accent, now that the capsule's own pill
            // fills accent when inhibited (see the capsule root's `color`
            // override above): the glyph is content ON that fill, the
            // same on-fill/fill pairing WorkspaceCapsule's own
            // slotTextColour/slotFillColour already use.
            color: idleInhibitorCapsule.idleInhibited ? BarRoles.onAccent : idleInhibitorCapsule.contentColour

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }
        }

        MouseArea {
            id: idleMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: idleInhibitorCapsule.idleInhibited = !idleInhibitorCapsule.idleInhibited
        }
    }

    // F2 (quick task 260812-69w) — a QtQuick.Controls ToolTip is a Popup,
    // clamped to its own window; Bar.qml's horizontal window is only 42px
    // tall (Task 1's Probe B measured the clamp live: an assigned y=60
    // resolved back to y=-2). BarTooltipHost mounts an escaping
    // layer-shell surface instead, below the bar in horizontal
    // orientation and left of it in vertical.
    BarTooltipHost {
        anchorItem: idleCell
        text: "Keep Awake"
        active: idleMouseArea.containsMouse
        tipId: "idleInhibitor"
    }
}
