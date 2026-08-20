// modules/settings/common/SettingsSection.qml — end-4's ContentSection
// shape (RESEARCH.md's "prefer Caelestia's decomposition, borrow end-4's
// one idea"): icon + title header row over a spaced content column, so
// each group page's rows are visually grouped without inventing a second
// frame per section.
import QtQuick
import "../../"
import "../../dashboard"

Column {
    id: root

    property string title: ""
    property string icon: ""
    default property alias content: contentColumn.data

    // FIX (tracer checkpoint fail, garbled visuals): without an explicit
    // width, `root` is a bare Column whose width derives from the MAX of
    // its own children's widths — and `contentColumn` below binds ITS OWN
    // width back to `root.width`. That is a genuine circular binding, not
    // a hypothetical one: measured live (diagnostic Component.onCompleted)
    // at root.width=81px — just enough to fit the "Theme" header row — so
    // every row inside `contentColumn` (SelectRow/NavRow, whose own
    // implicitWidth reads `parent.width`) rendered squeezed into ~81px,
    // overlapping its own label/dropdown internally. `parent` here is
    // whichever Column places this section (PageBase's `bodyColumn`,
    // itself bound to the page's own concrete `bodyFlick.width`) — binding
    // to THAT breaks the cycle with a real, non-self-referential width.
    width: parent ? parent.width : implicitWidth

    spacing: Design.spacingSm

    Row {
        spacing: Design.spacingSm
        visible: root.title.length > 0

        Text {
            visible: root.icon.length > 0
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.iconSizeMd
            text: root.icon
            color: Colours.onSurfaceVariant
        }
        Text {
            text: root.title
            font.pixelSize: Design.fontBody
            font.weight: Design.weightEmphasis
            color: Colours.onSurfaceVariant
        }
    }

    Column {
        id: contentColumn
        width: root.width
        spacing: Design.spacingMd
    }
}
