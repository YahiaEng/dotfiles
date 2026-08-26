// modules/filepicker/FpFolderContents.qml — the browsable grid body.
//
// Ported from caelestia-dots/shell @ 1d0e5a5
// (components/filedialog/FolderContents.qml), vendored at
// .planning/notes/caelestia-filepicker/. Their version is backed by the
// C++ `FileSystemModel` from their compiled Caelestia.Models plugin, which
// this repo does not have and will not add. `Qt.labs.folderlistmodel` is
// installed here (verified at /usr/lib/qt6/qml/Qt/labs/folderlistmodel)
// and provides the same directory-listing shape, so it stands in.
//
// WHAT THE MODEL SWAP COSTS, stated rather than hidden: FolderListModel
// exposes fileName/filePath/fileIsDir/fileSuffix/fileSize but has no
// mimeType. Caelestia picks a per-file icon from the mime type; we key off
// the suffix instead, which is coarser but needs no mime database lookup
// per row. Image files still show a real thumbnail either way, which is
// what a wallpaper picker actually cares about.
//
// The surrounding frame is theirs: a surface-container fill with a rounded
// inset "hole" punched in it, so the content area reads as recessed. They
// build it with an inverted layer mask; the same result here is two
// rectangles, which avoids a layer/effect on a scrolling view.
import QtQuick
import Qt.labs.folderlistmodel
import ".."
import "../dashboard"

Item {
    id: root

    // The owning FilePicker window. Read for `folder`, `nameFilters` and
    // the current selection; never written to from here except through
    // the two signals below.
    required property var picker

    readonly property var currentEntry: view.currentIndex >= 0 && view.currentIndex < folderModel.count ? ({
            name: folderModel.get(view.currentIndex, "fileName"),
            path: folderModel.get(view.currentIndex, "filePath"),
            isDir: folderModel.get(view.currentIndex, "fileIsDir"),
            suffix: String(folderModel.get(view.currentIndex, "fileSuffix") || "").toLowerCase(),
            size: folderModel.get(view.currentIndex, "fileSize")
        }) : null

    signal entered(string path)
    signal chosen(string path)

    function clearSelection(): void {
        view.currentIndex = -1;
    }

    // Recessed frame — surface-container everywhere except a rounded inset.
    Rectangle {
        anchors.fill: parent
        color: Colours.surfaceVariant
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: Design.spacingXs
        radius: 12
        color: Colours.surface
    }

    FolderListModel {
        id: folderModel

        folder: root.picker.folderUrl
        nameFilters: root.picker.nameFilters
        showDirs: true
        showFiles: true
        showDotAndDotDot: false
        showHidden: false
        sortField: FolderListModel.Type
        caseSensitive: false

        onFolderChanged: view.currentIndex = -1
    }

    GridView {
        id: view

        anchors.fill: parent
        anchors.margins: Design.spacingXs + Design.spacingMd

        // Caelestia's Sizes.itemWidth is 103 with spacing.small (8) between
        // cells; cell height adds the label row beneath the icon.
        readonly property int itemWidth: 103

        cellWidth: itemWidth + Design.spacingSm
        cellHeight: itemWidth + Design.spacingMd * 2 + Design.spacingLg

        clip: true
        focus: true
        currentIndex: -1
        model: folderModel

        Keys.onEscapePressed: view.currentIndex = -1
        Keys.onReturnPressed: root._activate()
        Keys.onEnterPressed: root._activate()

        delegate: Item {
            id: cell

            required property int index
            required property string fileName
            required property string filePath
            required property bool fileIsDir
            required property string fileSuffix

            readonly property bool isImage: !cell.fileIsDir && root.picker.isImageSuffix(cell.fileSuffix)
            readonly property bool current: GridView.isCurrentItem

            width: view.itemWidth
            height: view.cellHeight - Design.spacingSm

            Rectangle {
                anchors.fill: parent
                anchors.bottomMargin: Design.spacingSm
                radius: 16
                color: cell.current ? Colours.surfaceVariant : "transparent"

                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.colourDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.colourEasing
                    }
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: Design.spacingMd
                anchors.bottomMargin: Design.spacingSm
                spacing: Design.spacingSm

                Item {
                    width: parent.width
                    height: width

                    // A real thumbnail for images, a glyph for everything
                    // else. `sourceSize` caps decode cost per cell — without
                    // it a directory of 4K wallpapers decodes at full size.
                    Image {
                        anchors.fill: parent
                        visible: cell.isImage
                        asynchronous: true
                        cache: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 160
                        sourceSize.height: 160
                        source: cell.isImage ? ("file://" + cell.filePath) : ""
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !cell.isImage
                        font.family: Design.symbolFontFamily
                        font.pixelSize: 56
                        color: cell.fileIsDir ? Colours.primary : Colours.onSurfaceVariant
                        text: cell.fileIsDir ? "folder" : root.picker.glyphForSuffix(cell.fileSuffix)
                    }
                }

                Text {
                    width: parent.width
                    text: cell.fileName
                    color: Colours.onSurface
                    font.pixelSize: Design.settingsFontSub
                    horizontalAlignment: Text.AlignHCenter
                    // The selected cell shows its full name; everything else
                    // elides, so a long filename cannot push the grid around.
                    elide: cell.current ? Text.ElideNone : Text.ElideRight
                    wrapMode: cell.current ? Text.WrapAtWordBoundaryOrAnywhere : Text.NoWrap
                    maximumLineCount: cell.current ? 3 : 1
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: view.currentIndex = cell.index
                onDoubleClicked: {
                    view.currentIndex = cell.index;
                    root._activate();
                }
            }
        }
    }

    // Empty-folder state, same shape as Caelestia's.
    Column {
        anchors.centerIn: parent
        visible: folderModel.count === 0
        spacing: Design.spacingSm

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: Design.symbolFontFamily
            font.pixelSize: 64
            color: Colours.outline
            text: "scan_delete"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "This folder is empty"
            color: Colours.outline
            font.pixelSize: Design.settingsFontRow
        }
    }

    // Declared BEFORE any construction-time use (this repo's standing QML
    // rule — a later-declared member throws "is not a function" and a
    // fallback chain turns it into a plausible wrong answer).
    function _activate(): void {
        const e = root.currentEntry;
        if (!e)
            return;
        if (e.isDir)
            root.entered(e.path);
        else if (root.picker.selectionValid)
            root.chosen(e.path);
    }
}
