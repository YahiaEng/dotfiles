// modules/settings/pages/WallpaperCategoryPage.qml — one theme folder's
// wallpapers (quick task 260826-pk2).
//
// Ported from caelestia-dots/shell @ 1d0e5a5
// (modules/nexus/pages/wallandstyle/WallpaperCategory.qml), vendored at
// .planning/notes/caelestia-filepicker/WallpaperCategory.qml. Reached by
// tapping a category tile on WallpaperPage, which sets
// `sState.selectedWallpaperCategory` and calls `openSubPage(1)`.
//
// Deliberately owns NO data plumbing: the list, the active marker and the
// --set call all live on WallpaperPage's `wallpaperSection` and are passed
// down through `sState`. Duplicating the Process blocks here would give the
// two pages independent, silently divergent copies of the same state — the
// failure this repo already paid for once with the theme trackers.
//
// NO ROW PRIMITIVES BY DESIGN: this page is a grid, so it declares zero
// rows and therefore has zero RowIndex entries. settings-index-check CHECK A
// compares those two counts, so 0 == 0 passes; it is not an omission.
import QtQuick
import Quickshell
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    // Capitalised the same way Caelestia titles theirs.
    title: {
        const c = String(root.sState.selectedWallpaperCategory || "");
        return c.length > 0 ? c.charAt(0).toUpperCase() + c.slice(1) : "Wallpapers";
    }
    isSubPage: true

    // The owning page's section, handed down so this page reads ONE source
    // of truth. Assigned by PageCompRegistry's StackPage wiring is not
    // possible (sub-pages are constructed independently), so it is resolved
    // through sState instead — see `entries` below.
    readonly property var categoryEntries: {
        const cat = String(root.sState.selectedWallpaperCategory || "");
        const all = root.sState.wallpaperEntries || [];
        const out = [];
        for (let i = 0; i < all.length; i++)
            if (String(all[i].relpath).split("/")[0] === cat)
                out.push(all[i]);
        out.sort(function (a, b) {
            return String(a.relpath).localeCompare(String(b.relpath));
        });
        return out;
    }

    readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    function posterFor(relpath) {
        return Quickshell.env("HOME") + "/.local/state/theme/wallpaper-frames/" + String(relpath).replace("/live/", "/") + ".png";
    }

    SettingsSection {
        title: root.title
        icon: "wallpaper"

        GridView {
            id: grid

            width: parent.width
            height: Math.max(1, Math.ceil(root.categoryEntries.length / 4)) * cellHeight + Design.spacingSm
            clip: true

            readonly property int columns: 4
            readonly property int tileWidth: Math.floor((width - Design.spacingSm * (columns - 1)) / columns)

            cellWidth: tileWidth + Design.spacingSm
            cellHeight: tileWidth + Design.spacingXl
            model: root.categoryEntries

            delegate: Item {
                id: tile

                required property var modelData

                width: grid.tileWidth
                height: grid.cellHeight - Design.spacingSm

                readonly property bool inViewport: {
                    const top = grid.contentY;
                    const bottom = top + grid.height;
                    const y0 = tile.y;
                    const y1 = y0 + tile.height;
                    return y1 > top && y0 < bottom;
                }

                WallpaperTile {
                    anchors.fill: parent

                    source: root.wallpaperDir + "/" + tile.modelData.relpath
                    poster: root.posterFor(tile.modelData.relpath)
                    caption: tile.modelData.displayName
                    live: tile.modelData.isLive
                    playing: tile.inViewport
                    active: root.sState.wallpaperActiveRelpath === tile.modelData.relpath

                    onClicked: root.sState.requestWallpaper(tile.modelData.relpath)
                }
            }
        }
    }
}
