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

    // Same late-delegate problem as the root page, though this page's data
    // arrives via sState rather than its own Process.
    onCategoryEntriesChanged: root.sState.focusRowsInvalidated()

    function posterFor(relpath) {
        return Quickshell.env("HOME") + "/.local/state/theme/wallpaper-frames/" + String(relpath).replace("/live/", "/") + ".png";
    }

    SettingsSection {
        title: root.title
        icon: "wallpaper"

        // Eager Grid for the same reason as the root page's — a single
        // theme folder is a bounded set (18 at most here) and real children
        // are what make the tiles keyboard-reachable.
        Grid {
            id: grid

            width: parent.width
            columns: 4
            spacing: Design.spacingSm

            readonly property int tileWidth: Math.floor((width - spacing * (columns - 1)) / columns)

            Repeater {
                model: root.categoryEntries

                delegate: WallpaperTile {
                    id: tile

                    required property var modelData

                    width: grid.tileWidth

                    source: root.wallpaperDir + "/" + tile.modelData.relpath
                    poster: root.posterFor(tile.modelData.relpath)
                    caption: tile.modelData.displayName
                    live: tile.modelData.isLive
                    active: root.sState.wallpaperActiveRelpath === tile.modelData.relpath

                    playing: {
                        const f = root.flickable;
                        if (!f)
                            return false;
                        const pos = tile.mapToItem(f.contentItem, 0, 0);
                        return pos.y + tile.height > f.contentY && pos.y < f.contentY + f.height;
                    }

                    onClicked: root.sState.requestWallpaper(tile.modelData.relpath)
                }
            }
        }
    }
}
