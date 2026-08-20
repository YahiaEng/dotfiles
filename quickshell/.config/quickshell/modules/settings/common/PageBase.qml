// modules/settings/common/PageBase.qml — the page contract every group page
// implements (RESEARCH.md pattern #5, Caelestia's PageBase). Title band
// plus a flickable body, matching PanelDialog.qml's own header+Flickable
// shape rather than inventing a second frame idiom in this shell.
import QtQuick
import ".."
import "../../"
import "../../dashboard"

Item {
    id: root

    required property string title
    required property SettingsState sState
    default property alias contentChild: bodyColumn.data

    Column {
        id: headerColumn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Design.panelPadding

        Text {
            text: root.title
            font.pixelSize: Design.fontHeading
            font.weight: Design.weightEmphasis
            color: Colours.onSurface
        }
    }

    Flickable {
        id: bodyFlick
        anchors.top: headerColumn.bottom
        anchors.topMargin: Design.spacingLg
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Design.panelPadding
        clip: true
        contentHeight: bodyColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: bodyColumn
            width: bodyFlick.width
            spacing: Design.spacingLg
        }
    }
}
