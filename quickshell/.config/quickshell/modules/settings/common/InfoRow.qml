// modules/settings/common/InfoRow.qml — a non-interactive explanatory row
// (quick-260821-6z1 Task 2, PD-07). Composed the same way NavRow.qml is
// (label + subtext, same paddings, same SettingsSection fit) but with no
// chevron and no `activated()` signal — this row does nothing when
// clicked. Exists to carry the honest "this is not a knob, and here is
// why" sentences the N-01/N-02/N-03 non-deliveries need (Window manager,
// Wallpaper, Input pages) rather than shipping a control that silently
// reverts or fakes a capability this compositor build does not have.
//
// `focusable: true` + `rowFocused` (PD-07) — declared with no activation
// behaviour, matching every other row primitive's marker so
// `Pages.qml`'s `_collectFocusableRows()` denominator stays uniform
// across all five row types, and so an explanatory row is reachable by
// both keyboard two-pane focus and `RowIndex` search, not just by
// scrolling past it.
//
// `icon` (quick-260826-1n9, D-2) — defaulted to "info" so every existing
// call site (40+ across the tree) renders byte-identically with no other
// file needing to change in this same commit. The default is NOT the
// point, though — a page that leaves nine rows on the default is
// precisely the defect this property exists to let a page fix: SHOULD
// override it with a glyph that actually names the field.
import QtQuick
import "../../"
import "../../dashboard"

Item {
    id: root

    property string label: ""
    // indexLabel (quick-260826-437 D-1) — the string RowIndex keys on and
    // settings-index-check greps for; defaults to `label` so every existing
    // row keeps its exact current jump key. Override only when the displayed
    // `label` is dynamic (e.g. a Repeater over live data).
    property string indexLabel: root.label
    property string subtext: ""
    property string icon: "info"

    readonly property bool focusable: true
    property bool rowFocused: false

    implicitWidth: parent ? parent.width : 400
    implicitHeight: contentCol.implicitHeight + Design.spacingMd * 2
    width: parent ? parent.width : 400

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "transparent"
        border.width: 2
        border.color: root.rowFocused ? Colours.primary : Qt.alpha(Colours.primary, 0)

        Behavior on border.color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.colourDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.colourEasing
            }
        }
    }

    Column {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Design.spacingMd
        spacing: 2

        Row {
            width: parent.width
            spacing: Design.spacingXs

            Text {
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                text: root.icon
                color: Colours.onSurfaceVariant
            }
            Text {
                width: parent.width - Design.iconSizeMd - Design.spacingXs
                text: root.label
                font.pixelSize: Design.settingsFontRow
                color: Colours.onSurface
                wrapMode: Text.WordWrap
            }
        }
        Text {
            visible: root.subtext.length > 0
            // The whole point of this row is to carry a sentence — it
            // must WRAP rather than elide, unlike every other row's
            // subtext (NavRow/ToggleRow/SliderRow/SelectRow all elide,
            // since their subtext is a short descriptor, not the payload).
            text: root.subtext
            font.pixelSize: Design.settingsFontSub
            color: Colours.onSurfaceVariant
            width: parent.width
            wrapMode: Text.WordWrap
        }
    }
}
