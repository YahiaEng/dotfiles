// modules/settings/common/NavRow.qml — label + subtext + a
// chevron-trailing button that launches something (RESEARCH.md pattern
// #4, Caelestia's NavRow). Same `Control`-subclass + never-anchor-
// contentItem discipline as SelectRow.qml — see that file's header for the
// full reasoning.
//
// `icon` (quick-260826-1n9 Task 5, Rule 2) — same defaulted shape
// InfoRow.qml's own `icon` property (D-2) already established: empty
// default, so every existing call site (10 across this module, none of
// which set `icon` today) renders byte-identically. Added here, not
// listed in this plan's Task 2/5 `<files>` blocks, because D-5's own
// settled decision ("prominence is bought with the download glyph… not
// by leaving the row system") is unfulfillable without it — a NavRow had
// no icon slot to carry that glyph at all.
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
    property string icon: ""
    signal activated()

    // Two-pane keyboard focus — see Pages.qml's header for the full
    // design; ToggleRow.qml's own header has the geometry-stability
    // reasoning for the border-color-only focus ring (merged below into
    // this row's `background`).
    readonly property bool focusable: true
    property bool rowFocused: false

    implicitWidth: parent ? parent.width : 400
    implicitHeight: 56
    padding: Design.spacingMd

    contentItem: Item {
        id: rowContent
        implicitHeight: Math.max(labelCol.implicitHeight, chevron.implicitHeight)

        // Reserves no space at all when `icon` is empty (the default) —
        // `labelCol` anchors straight to `parent.left` in that case,
        // identical to this row's shape before this property existed.
        Text {
            id: iconGlyph
            visible: root.icon.length > 0
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.iconSizeMd
            text: root.icon
            color: Colours.onSurfaceVariant
        }

        Column {
            id: labelCol
            anchors.left: root.icon.length > 0 ? iconGlyph.right : parent.left
            anchors.leftMargin: root.icon.length > 0 ? Design.spacingSm : 0
            anchors.right: chevron.left
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

        Text {
            id: chevron
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.iconSizeMd
            text: "chevron_right"
            color: Colours.onSurfaceVariant
        }
    }

    // Row hover fix (operator burst-screenshot + PIL pixel-sample,
    // fourth live-pass) — MEASURED root cause, not the popup this
    // module's prior three fix rounds all targeted: the page pane
    // paints `Colours.surfaceVariant` (Settings.qml's own window
    // background) and this row's OWN hover fill was the SAME
    // `Colours.surfaceVariant` — invisible by construction, confirmed
    // by pixel sample (fill == pane, identical RGB). Replaced with the
    // same border-ring language every other row in this module uses.
    // Coexistence with keyboard focus, decided deliberately: the ring
    // shows when EITHER `rowFocused` (keyboard) OR `hoverArea.containsMouse`
    // is true — one shared visual, matching the operator's own request
    // that hover look like keyboard selection rather than a second style.
    // `hoverArea` already spans the whole row and is the row's one click
    // target — its own built-in `pressed` drives the shared surface's
    // immediate press fill directly, no new handler needed.
    background: RowSurface {
        focused: root.rowFocused
        hovered: hoverArea.containsMouse
        pressed: hoverArea.pressed
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.activated()
    }
}
