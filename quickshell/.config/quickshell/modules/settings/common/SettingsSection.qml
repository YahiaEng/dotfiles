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
