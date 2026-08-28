// modules/settings/common/SliderRow.qml — label + subtext + a value slider.
// Same `Control` + never-anchor-contentItem discipline as SelectRow.qml —
// see that file's header for the full QQC2 trap reasoning.
//
// ── Task 15 live-pass fix (MEASURED via grim -g pixel-sample on the real
//    settings toplevel, not assumed from reading the code) — the QQC2
//    `Slider` this row used to wrap rendered NOTHING at all: no track, no
//    handle, not even the overridden `background`/`handle` delegates'
//    own explicit-pixel Rectangles, on every page that used this row
//    (Window manager's 8 sliders, Input's pointer-sensitivity and
//    per-device scroll-factor rows, Audio's master/input-level/per-app
//    rows) — a total rendering failure, not a contrast defect. Rather
//    than chase QQC2 Slider's own internal implicit-size machinery
//    (`implicitBackgroundWidth`/`implicitHandleWidth` derive from a
//    delegate's `implicitWidth`, not its literal `width` — the likely
//    cause, unconfirmed), this row is now hand-rolled: a plain
//    Rectangle track + fill + handle + MouseArea, the SAME idiom
//    ToggleRow's switch pill and SelectRow's dropdown pill already use
//    successfully elsewhere in this module, rather than a THIRD QQC2
//    interactive primitive risking a THIRD blind spot. `import
//    QtQuick.Controls` stays only for `Control` itself (the row's own
//    focus-ring/padding host), not for anything inside it.
import QtQuick
import QtQuick.Controls
import "../../"
import "../../dashboard"

Control {
    id: root

    property string label: ""
    // indexLabel (quick-260826-437 D-1) — the string RowIndex keys on and
    // settings-index-check greps for; defaults to `label` so every existing
    // row keeps its exact current jump key. Override only when the displayed
    // `label` is dynamic (e.g. a Repeater over live data).
    property string indexLabel: root.label
    property string subtext: ""
    property real from: 0
    property real to: 1
    property real value: 0
    property real stepSize: 0.01
    signal moved(value: real)

    // ── Fix WR-04 (code review, quick-260821-6z1 fix wave) —
    // `hypr-overrides.sh`'s own `cmd_device` comment names a "reset to
    // default" affordance that "happens at the QML call site (Task 7),
    // not here", and Task 7's own InputPage.qml never built it. `false`
    // by default — harmless for every other SliderRow usage, which has
    // no meaningful "default" to reset TO. A consumer opts in with
    // `resettable: true` and handles `onResetRequested` itself (e.g.
    // InputPage.qml's per-device scroll-factor row writes back the
    // current GLOBAL `input:scroll_factor` value, per the script
    // comment's own instruction — the "-1 = inherit global" sentinel
    // itself is not writable, `hl.device` rejects it outright).
    property bool resettable: false
    signal resetRequested()

    // Two-pane keyboard focus — see Pages.qml's header for the full
    // design; ToggleRow.qml's own header has the geometry-stability
    // reasoning for the border-color-only focus ring below.
    readonly property bool focusable: true
    property bool rowFocused: false

    implicitWidth: parent ? parent.width : 400
    // Grown from Column's own real content (label row + subtext + the
    // hand-rolled track), never a hardcoded literal — the exact class
    // of bug this task's fix corrects. `rowContent` is `contentItem`'s
    // own id below; a property BINDING may reference it regardless of
    // textual order (unlike the imperative-JS-before-declaration trap
    // this repo's memory warns about elsewhere).
    implicitHeight: rowContent.implicitHeight + topPadding + bottomPadding
    padding: Design.spacingMd

    // Row hover — HoverHandler is passive/non-exclusive, so it does not
    // compete with the track's own MouseArea below for the drag gesture.
    HoverHandler {
        id: rowHover
    }

    // Round 5, item 2 — a press observer for RowSurface's `pressed` state.
    //
    // CORRECTED 2026-08-28 (quick task 260828-t22): this block used to set
    // `gesturePolicy: TapHandler.PassiveOnly` and the comment described a
    // handler that "never grabs the point". THERE IS NO SUCH VALUE. Measured
    // against /usr/lib/qt6/qml/QtQuick/plugins.qmltypes, GesturePolicy has
    // exactly four: DragThreshold, WithinBounds, ReleaseWithinBounds,
    // DragWithinBounds. `PassiveOnly` appears NOWHERE in Qt, so the
    // assignment failed at runtime — `Unable to assign [undefined] to
    // QQuickTapHandler::GesturePolicy`, logged on every instantiation — and
    // the handler silently used the DEFAULT all along.
    //
    // The line is REMOVED rather than replaced. What shipped and what the
    // operator approved live in round 5 IS the default; substituting a
    // real-but-different policy would change approved behaviour on a surface
    // that cannot be exercised from an agent shell. This makes the code
    // honest about what it already does. Choosing a different policy is a
    // separate, testable decision.
    TapHandler {
        id: rowPress
    }

    background: RowSurface {
        focused: root.rowFocused
        hovered: rowHover.hovered
        pressed: rowPress.pressed
    }

    contentItem: Column {
        id: rowContent
        spacing: Design.spacingXs

        Row {
            width: parent.width
            spacing: Design.spacingMd

            Text {
                width: parent.width - valueLabel.implicitWidth - Design.spacingMd - (root.resettable ? resetIcon.implicitWidth + Design.spacingMd : 0)
                text: root.label
                font.pixelSize: Design.settingsFontRow
                color: Colours.onSurface
                elide: Text.ElideRight
            }
            Text {
                id: valueLabel
                text: root.value.toFixed(2)
                font.pixelSize: Design.settingsFontSub
                color: Colours.onSurfaceVariant
            }
            // Reset-to-default affordance (WR-04) — a small clickable
            // glyph, not a fourth row primitive: `settings-index-check`'s
            // CHECK A counts row-primitive DECLARATIONS
            // (ToggleRow/SliderRow/SelectRow/NavRow/InfoRow), and this
            // stays inside the ONE SliderRow declaration it belongs to,
            // so it needs no separate RowIndex entry.
            Text {
                id: resetIcon
                visible: root.resettable
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                text: "restart_alt"
                color: resetHover.hovered ? Colours.primary : Colours.onSurfaceVariant

                HoverHandler {
                    id: resetHover
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetRequested()
                }
            }
        }

        Text {
            visible: root.subtext.length > 0
            text: root.subtext
            font.pixelSize: Design.settingsFontSub
            color: Colours.onSurfaceVariant
            width: parent.width
            elide: Text.ElideRight
        }

        // ── Hand-rolled track — a fixed-height hit area (24px, a
        //    touch/mouse-friendly target) taller than the 4px visual
        //    track itself, so the drag gesture does not require
        //    pixel-perfect precision on the thin line. `ratio` is the
        //    ONE place value<->position conversion happens, read by
        //    both the fill Rectangle and the handle's `x`. ─────────────
        Item {
            id: track
            width: parent.width
            height: 24

            readonly property real ratio: (root.to > root.from) ? Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from))) : 0

            Rectangle {
                id: trackBg
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Colours.surfaceVariant
                border.width: 1
                border.color: Colours.outline

                Rectangle {
                    width: track.ratio * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: Colours.primary
                }
            }

            Rectangle {
                id: handle
                width: 18
                height: 18
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                x: track.ratio * (track.width - width)
                color: Colours.primary
                border.width: 1
                border.color: Colours.onPrimary
            }

            // MouseArea fills `track` exactly, so `mouse.x` is already
            // in the same coordinate space `ratio`'s own math uses —
            // no separate margin/offset reconciliation needed. Pressing
            // anywhere on the track jumps to that position (matches
            // QQC2 Slider's own click-to-position convention); dragging
            // continues tracking the cursor.
            MouseArea {
                id: dragArea
                anchors.fill: parent

                // Fix IN-01 (code review, quick-260821-6z1 fix wave) — the
                // rendered handle sits at `track.ratio * (track.width -
                // handle.width)` (inset by its own 18px so it never
                // overflows the track — see `handle.x` above), but this
                // used to map a click/drag `x` back to a value via the
                // FULL `track.width`, with no equivalent inset. The two
                // mappings agreed exactly at the extremes (0 and 1) but
                // diverged by up to ~9px mid-track, so clicking the
                // visual center of the handle did not reproduce the value
                // it was currently displaying. Mirrors the `ratio`
                // binding's own inset exactly, so hit-test and render now
                // use the SAME value<->position mapping.
                function _emitFromX(x) {
                    var w = track.width - handle.width;
                    if (w <= 0)
                        return;
                    var r = Math.max(0, Math.min(1, (x - handle.width / 2) / w));
                    var raw = root.from + r * (root.to - root.from);
                    var stepped = root.stepSize > 0 ? Math.round(raw / root.stepSize) * root.stepSize : raw;
                    stepped = Math.max(root.from, Math.min(root.to, stepped));
                    root.moved(stepped);
                }

                onPressed: (mouse) => dragArea._emitFromX(mouse.x)
                onPositionChanged: (mouse) => {
                    if (pressed)
                        dragArea._emitFromX(mouse.x);
                }
            }
        }
    }
}
