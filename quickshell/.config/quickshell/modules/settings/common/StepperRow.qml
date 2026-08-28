// modules/settings/common/StepperRow.qml — label + subtext + a −/+ value
// pill (quick task 260825-wj2 Task 5, D-9). Ports Caelestia's own
// `common/StepperRow.qml` property set verbatim — `label`, `subtext`,
// `value`, `from` (default 0), `to` (default 99), `stepSize` (default 1),
// `signal moved(value: real)` — the primitive the reference reserves for
// every polling value (media position, CPU/memory/GPU refresh, network
// rescans) and every input increment, keeping `SelectRow` for genuine
// pick-from-a-list choices only.
//
// Hand-rolled from plain Rectangles/Text/MouseAreas rather than wrapping
// their `StyledSpinBox` — see `SliderRow.qml`'s own header for the
// measured reason this tree does not reach for a THIRD QQC2 interactive
// primitive: the QQC2 `Slider` that row used to wrap rendered NOTHING at
// all — no track, no handle, not even its own overridden delegates' own
// explicit-pixel Rectangles — on every page that used it. A `SpinBox`
// would be exactly that third primitive, risking a third blind spot.
// Follows `ToggleRow`'s switch-pill / `SelectRow`'s dropdown-pill idiom
// instead: a single Rectangle pill, `−`/`+` Text glyphs with their own
// MouseAreas, one place (`stepUp()`/`stepDown()`) the increment is ever
// applied.
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
    property real value: 0
    property real from: 0
    property real to: 99
    property real stepSize: 1
    // Lets a row render "15 min" / "2 s" without the page formatting the
    // number itself — the reference carries the unit in its subtext
    // instead; this keeps both options available without a second Text
    // element in the consuming page.
    property string valueSuffix: ""
    signal moved(value: real)

    // Two-pane keyboard focus — see Pages.qml's header for the full
    // design; ToggleRow.qml's own header has the geometry-stability
    // reasoning for the border-color-only focus ring below.
    readonly property bool focusable: true
    property bool rowFocused: false

    implicitWidth: parent ? parent.width : 400
    implicitHeight: rowContent.implicitHeight + topPadding + bottomPadding
    padding: Design.spacingMd

    // The ONE place the increment is applied — the `−`/`+` MouseAreas
    // below call these, and so does `Pages.activateContentRow`'s own
    // `stepUp` branch (Task 5's own keyboard-activation wiring). Both
    // clamp to `[from, to]` before emitting, so a caller never has to
    // re-clamp. Hold-to-repeat is deliberately not built — the reference
    // has no such behaviour either.
    function stepUp() {
        var next = Math.min(root.to, root.value + root.stepSize);
        root.moved(next);
    }
    function stepDown() {
        var next = Math.max(root.from, root.value - root.stepSize);
        root.moved(next);
    }

    // Row hover — HoverHandler is passive/non-exclusive, so it does not
    // compete with the pill's own MouseAreas for click delivery, the
    // same coexistence every other row primitive in this module relies on.
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

    // Never anchor `contentItem` itself (MEMORY
    // qqc2-contentitem-anchors-break-sizing) — only the CHILDREN inside it
    // are anchored, exactly the discipline SelectRow.qml/NavRow.qml/
    // ToggleRow.qml already established for this same Control subclass.
    contentItem: Item {
        id: rowContent
        implicitHeight: Math.max(labelCol.implicitHeight, stepperPill.implicitHeight)

        Column {
            id: labelCol
            anchors.left: parent.left
            anchors.right: stepperPill.left
            anchors.rightMargin: Design.spacingMd
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: root.label
                font.pixelSize: Design.settingsFontRow
                color: Colours.onSurface
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                visible: root.subtext.length > 0
                text: root.subtext
                font.pixelSize: Design.settingsFontSub
                color: Colours.onSurfaceVariant
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Single pill background — SelectRow's own `dropdownPill` idiom,
        // never two separate button rectangles, so the row reads as one
        // control rather than three.
        Rectangle {
            id: stepperPill
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: pillContent.implicitWidth + Design.spacingLg * 2
            implicitHeight: 36
            radius: height / 2
            color: Colours.surfaceVariant
            border.width: 1
            border.color: Colours.outline

            Row {
                id: pillContent
                anchors.centerIn: parent
                spacing: Design.spacingMd

                Item {
                    id: minusHit
                    readonly property bool enabledNow: root.value > root.from
                    width: Design.iconSizeMd
                    height: Design.iconSizeMd

                    Text {
                        anchors.centerIn: parent
                        text: "−"
                        font.pixelSize: Design.settingsFontRow
                        font.weight: Design.weightEmphasis
                        color: minusHit.enabledNow ? Colours.primary : Colours.onSurfaceVariant
                        opacity: minusHit.enabledNow ? 1 : 0.4
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: minusHit.enabledNow
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.stepDown()
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.value.toFixed(0) + root.valueSuffix
                    font.pixelSize: Design.settingsFontRow
                    color: Colours.onSurfaceVariant
                }

                Item {
                    id: plusHit
                    readonly property bool enabledNow: root.value < root.to
                    width: Design.iconSizeMd
                    height: Design.iconSizeMd

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        font.pixelSize: Design.settingsFontRow
                        font.weight: Design.weightEmphasis
                        color: plusHit.enabledNow ? Colours.primary : Colours.onSurfaceVariant
                        opacity: plusHit.enabledNow ? 1 : 0.4
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: plusHit.enabledNow
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.stepUp()
                    }
                }
            }
        }
    }
}
