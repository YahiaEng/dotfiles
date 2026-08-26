// modules/filepicker/FilePicker.qml — an in-shell "Open File…" window.
//
// Ported from caelestia-dots/shell @ 1d0e5a5 (components/filedialog/),
// vendored with provenance at .planning/notes/caelestia-filepicker/.
//
// WHAT THIS IS AND IS NOT: a file *picker*, not a file manager. It browses
// and returns one path. It does not copy, move, rename or delete, and it
// is not registered as any xdg handler — Thunar remains the file manager
// (which is, per that task's own finding, exactly what Caelestia does too).
//
// Usage — declare one inline and `open()` it; `accepted(path)` fires with
// an absolute path, `rejected()` on cancel or window close:
//
//     FilePicker {
//         id: browse
//         title: "Select an image"
//         filterLabel: "Image files"
//         nameFilters: ["*.png", "*.jpg"]
//         onAccepted: path => { ... }
//     }
//
// LazyLoader, not a bare FloatingWindow: the window is only constructed on
// first open, so a page that merely declares a picker costs nothing until
// the button is pressed.
import QtQuick
import Quickshell
import ".."
import "../dashboard"

LazyLoader {
    id: loader

    property string title: "Select a file"
    property string filterLabel: "All files"
    // Glob patterns, FolderListModel's own `nameFilters` vocabulary.
    property var nameFilters: ["*"]
    // Where the picker opens. Empty means $HOME.
    property string startPath: ""

    signal accepted(string path)
    signal rejected

    function open(): void {
        loader.activeAsync = true;
    }

    function close(): void {
        loader.rejected();
    }

    onAccepted: loader.activeAsync = false
    onRejected: loader.activeAsync = false

    FloatingWindow {
        id: win

        // The picker's own navigation state and the API the three child
        // components read. Declared before any construction-time use.
        property string currentPath: loader.startPath.length > 0 ? loader.startPath : (Quickshell.env("HOME") || "/")

        readonly property url folderUrl: "file://" + win.currentPath
        readonly property var nameFilters: loader.nameFilters
        readonly property string filterLabel: loader.filterLabel

        readonly property var currentEntry: body.currentEntry
        readonly property bool selectionValid: {
            const e = win.currentEntry;
            if (!e || e.isDir)
                return false;
            if (win.nameFilters.indexOf("*") !== -1)
                return true;
            for (let i = 0; i < win.nameFilters.length; i++) {
                const pat = String(win.nameFilters[i]).toLowerCase();
                if (pat.indexOf("*.") === 0 && pat.slice(2) === e.suffix)
                    return true;
            }
            return false;
        }

        function navigateTo(path: string): void {
            if (!path || path.length === 0)
                return;
            win.currentPath = path;
            body.clearSelection();
        }

        function navigateUp(): void {
            const p = win.currentPath;
            if (p === "/")
                return;
            const cut = p.lastIndexOf("/");
            win.navigateTo(cut <= 0 ? "/" : p.slice(0, cut));
        }

        function isImageSuffix(suffix: string): bool {
            // Caelestia's Images.validImageExtensions, plus the animated and
            // raw-ish formats a wallpaper directory on this host actually
            // holds (measured: jpg/png/webp/gif present under
            // ~/Pictures/Wallpapers).
            return ["jpg", "jpeg", "png", "webp", "tif", "tiff", "svg", "gif", "bmp", "avif"].indexOf(String(suffix).toLowerCase()) !== -1;
        }

        function glyphForSuffix(suffix: string): string {
            const s = String(suffix).toLowerCase();
            if (["mp4", "mkv", "webm", "mov", "avi", "m4v"].indexOf(s) !== -1)
                return "movie";
            if (["mp3", "flac", "ogg", "wav", "m4a", "opus"].indexOf(s) !== -1)
                return "music_note";
            if (["pdf"].indexOf(s) !== -1)
                return "picture_as_pdf";
            if (["zip", "tar", "gz", "xz", "zst", "7z", "rar"].indexOf(s) !== -1)
                return "folder_zip";
            if (["txt", "md", "conf", "toml", "json", "yaml", "yml", "ini", "log"].indexOf(s) !== -1)
                return "description";
            if (["sh", "bash", "fish", "zsh", "py", "js", "qml", "lua", "c", "cpp", "rs", "go"].indexOf(s) !== -1)
                return "code";
            return "draft";
        }

        title: loader.title
        color: Colours.surface
        implicitWidth: 1000
        implicitHeight: 600
        minimumSize.width: 480
        minimumSize.height: 340

        // A window dismissed by its own titlebar must resolve the promise
        // too, or a caller awaiting `accepted`/`rejected` hangs forever.
        onVisibleChanged: {
            if (!visible)
                loader.rejected();
        }

        Row {
            anchors.fill: parent
            spacing: 0

            FpSidebar {
                id: side

                height: parent.height
                picker: win
            }

            Column {
                width: parent.width - side.width
                height: parent.height
                spacing: 0

                FpHeaderBar {
                    id: head

                    width: parent.width
                    picker: win
                }

                FpFolderContents {
                    id: body

                    width: parent.width
                    height: parent.height - head.height - foot.height
                    picker: win

                    onEntered: path => win.navigateTo(path)
                    onChosen: path => loader.accepted(path)
                }

                FpFooter {
                    id: foot

                    width: parent.width
                    picker: win

                    onCancelled: loader.rejected()
                    onConfirmed: {
                        if (win.selectionValid)
                            loader.accepted(win.currentEntry.path);
                    }
                }
            }
        }
    }
}
