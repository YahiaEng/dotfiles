// modules/launcher/WallpaperMode.qml — the horizontal wallpaper carousel
// (quick task 260826-wl3).
//
// Ported from caelestia-dots/shell @ 1d0e5a5
// (modules/launcher/WallpaperList.qml + items/WallpaperItem.qml), vendored
// at .planning/notes/caelestia-wallpaper-carousel/. This is the picker the
// operator actually meant: a strip that spawns from the bar's bottom bulge,
// scrolls left/right, and updates the desktop LIVE as the selection moves.
// The Settings ▸ Wallpaper grid (260826-pk2) stays as the browse-everything
// surface; this is the fast one.
//
// A PathView, not a ListView — that is the whole trick. With
// `preferredHighlightBegin/End` both 0.5 and `StrictlyEnforceRange`, the
// current item is pinned to the centre of the strip and the CONTENT moves
// under it, which is what makes the neighbours fan out symmetrically.
// `pathItemCount` is forced ODD so a true centre exists; an even count has
// no middle slot and the highlight sits between two tiles.
//
// LIVE PREVIEW IS A PREVIEW, NOT AN APPLY. Scrolling calls `awww img` —
// one IPC message to the already-running daemon, the exact mechanism
// wallpaper-picker.sh's own fzf preview has always used, so this is a
// proven-cheap call and not a new capability. It does NOT run the theme
// pipeline: regenerating the whole Material You palette on every scroll
// step would take seconds per tile. Committing (Enter/click) runs
// `wallpaper-picker.sh --set`, which does the full apply including the
// palette. Caelestia previews colours too, via a C++ colour-quantiser this
// repo does not have; matching that would mean a matugen run per scroll.
//
// Leaving without committing restores whatever was on screen when the mode
// opened — otherwise a browse-and-escape silently leaves the desktop on the
// last previewed image.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../dashboard"

Item {
    id: root

    // Launcher.qml hands this in — this file has no other way to close the
    // surface it is hosted in (same contract as MenuMode's).
    property var dismissCallback: null

    // Filter text, fed by the launcher's search field.
    property string query: ""

    readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    // { relpath, displayName, isLive, path }
    property var entries: []
    // Absolute path of whatever was on screen when this mode opened, so an
    // uncommitted exit can put it back.
    property string restorePath: ""
    property bool committed: false

    readonly property var filtered: {
        const q = String(root.query || "").trim().toLowerCase();
        if (q.length === 0)
            return root.entries;
        const out = [];
        for (let i = 0; i < root.entries.length; i++)
            if (root.entries[i].relpath.toLowerCase().indexOf(q) !== -1)
                out.push(root.entries[i]);
        return out;
    }

    // ── The duck-typed trio Launcher.qml's keyboard glue reads ───────────
    // `columns: count` is the deliberate part: `moveSelectionColumn()`
    // requires `columns > 0` and steps within a row, so declaring the whole
    // strip as ONE row makes Left/Right walk it and wrap, with no change to
    // Launcher.qml. Up/Down then resolve to a single row and correctly do
    // nothing — this strip has no vertical axis.
    readonly property int count: root.filtered.length
    readonly property int columns: Math.max(1, root.count)
    property alias currentIndex: view.currentIndex

    function activate() {
        const e = root.filtered[view.currentIndex];
        if (!e)
            return;
        root.committed = true;
        // execDetached, per this tree's standing rule: a component-scoped
        // Process is destroyed with the LazyLoader the instant the launcher
        // dismisses, killing the apply mid-flight.
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-picker.sh", "--set", e.relpath]);
        if (root.dismissCallback)
            root.dismissCallback();
    }

    implicitHeight: view.implicitHeight

    // ── Data ─────────────────────────────────────────────────────────────
    Process {
        id: listProc

        running: false
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-picker.sh", "--list"]

        stdout: StdioCollector {
            id: listOut
        }

        onExited: (code, status) => {
            if (code !== 0)
                return;
            const rows = String(listOut.text || "").trim().split("\n").filter(l => l.length > 0);
            root.entries = rows.map(relpath => ({
                        relpath: relpath,
                        displayName: relpath.split("/").pop(),
                        // Same shape test as wallpaper-picker.sh's own
                        // theme_engine_wallpaper_is_live_ref — a path
                        // component literally named "live", never a
                        // per-extension guess.
                        isLive: relpath.indexOf("/live/") !== -1,
                        path: root.wallpaperDir + "/" + relpath
                    }));
            activeProc.running = true;
        }
    }

    // Resolve what is on screen NOW: line 1 is the absolute path to restore
    // to, line 2 is the active RELPATH used to seed the selection.
    //
    // The relpath comes from `--active`, NOT from string-slicing the
    // absolute path against `wallpaperDir`. That slicing was wrong and the
    // seeding silently never matched: ~/Pictures/Wallpapers is a stow
    // symlink into the repo, so `readlink -f` returns
    // /home/aorus/dotfiles/wallpapers/... while wallpaperDir is the symlink
    // path — the prefix test could never hit. `--active` already resolves
    // BOTH sides (_active_relpath does its own readlink -f on the root), so
    // this defers to that one implementation instead of keeping a second,
    // subtly-different copy of the same mapping.
    Process {
        id: activeProc

        running: false
        command: ["sh", "-c", "readlink -f \"$HOME/.local/state/theme/current.jpg\"; \"$HOME/.config/hypr/scripts/wallpaper-picker.sh\" --active"]

        stdout: StdioCollector {
            id: activeOut
        }

        onExited: (code, status) => {
            const lines = String(activeOut.text || "").split("\n");
            root.restorePath = (lines[0] || "").trim();
            const rel = (lines[1] || "").trim();
            if (rel.length > 0)
                for (let i = 0; i < root.filtered.length; i++)
                    if (root.filtered[i].relpath === rel) {
                        view.currentIndex = i;
                        break;
                    }
            root.ready = true;
        }
    }

    // Preview is suppressed until the initial selection is seeded, so
    // opening the mode does not immediately re-apply the wallpaper that is
    // already showing.
    property bool ready: false

    Component.onCompleted: listProc.running = true

    Component.onDestruction: {
        // Uncommitted exit — put back what was there. Committed exits leave
        // it alone: --set is already applying the real choice, and racing it
        // with a restore would fight the transition.
        if (!root.committed && root.restorePath.length > 0)
            Quickshell.execDetached(["awww", "img", root.restorePath, "--transition-type", "center", "--transition-duration", "1", "--transition-fps", "165"]);
    }

    // ── Live preview, debounced ──────────────────────────────────────────
    // Held-arrow or flung scroll fires currentIndexChanged far faster than a
    // wallpaper transition can finish; without this, awww queues a message
    // per intermediate tile and the desktop churns through images the user
    // never stopped on. The timer collapses a run of moves into the one that
    // was actually landed on.
    Timer {
        id: previewDebounce

        interval: Motion.standardDuration
        repeat: false
        onTriggered: root._preview()
    }

    // Declared before any construction-time use (this tree's standing QML
    // rule — a later-declared member throws "is not a function").
    function posterFor(relpath) {
        return Quickshell.env("HOME") + "/.local/state/theme/wallpaper-frames/" + String(relpath).replace("/live/", "/") + ".png";
    }

    function _preview() {
        if (!root.ready)
            return;
        const e = root.filtered[view.currentIndex];
        if (!e)
            return;
        // awww cannot play video, so a live entry previews through the frame
        // the wallpaper pipeline already extracts. If no frame exists yet,
        // preview nothing rather than blanking the desktop — extraction is
        // wallpaper-picker.sh's job, not this surface's.
        const target = e.isLive ? root.posterFor(e.relpath) : e.path;
        Quickshell.execDetached(["awww", "img", target, "--transition-type", "center", "--transition-duration", "1", "--transition-fps", "165"]);
    }

    // ── The carousel ─────────────────────────────────────────────────────
    PathView {
        id: view

        // Derived from the available width, not hardcoded. A fixed thumb
        // width made itemWidth 208 against a 608px panel, so only 2 fitted
        // and the odd-count rule below knocked that down to 1 — measured,
        // the strip rendered a single tile. Deriving guarantees the target
        // count fits at whatever width the panel happens to be.
        readonly property int visibleItems: 3
        readonly property int itemWidth: Math.max(120, Math.floor(width / visibleItems))
        readonly property int thumbWidth: itemWidth - Design.spacingMd * 2
        readonly property int thumbHeight: Math.round(thumbWidth / 16 * 9)

        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: thumbHeight + Design.spacingXl + Design.spacingMd * 2
        // height, not just implicitHeight: anchoring only left/right leaves
        // a PathView at height 0, and `startY: height / 2` then collapses
        // the path to the top edge.
        height: implicitHeight

        model: root.filtered
        // Odd, always — an even count has no middle slot for the highlight,
        // and the current item must sit dead centre.
        pathItemCount: {
            const fit = Math.max(1, Math.floor(width / Math.max(1, itemWidth)));
            return fit % 2 === 0 ? Math.max(1, fit - 1) : fit;
        }
        cacheItemCount: 4

        snapMode: PathView.SnapToItem
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange

        onCurrentIndexChanged: previewDebounce.restart()

        path: Path {
            startX: 0
            startY: view.height / 2

            PathAttribute {
                name: "itemZ"
                value: 0
            }
            PathLine {
                x: view.width / 2
                relativeY: 0
            }
            PathAttribute {
                name: "itemZ"
                value: 1
            }
            PathLine {
                x: view.width
                relativeY: 0
            }
        }

        delegate: Item {
            id: tile

            required property var modelData
            required property int index

            readonly property bool current: PathView.isCurrentItem

            width: view.itemWidth
            height: view.implicitHeight
            z: PathView.itemZ ?? 0

            scale: tile.current ? 1 : (PathView.onPath ? 0.8 : 0)
            opacity: PathView.onPath ? 1 : 0

            Behavior on scale {
                enabled: Motion.motionEnabled
                NumberAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }
            Behavior on opacity {
                enabled: Motion.motionEnabled
                NumberAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: Design.spacingXs

                Rectangle {
                    width: view.thumbWidth
                    height: view.thumbHeight
                    radius: 16
                    color: Colours.surfaceVariant
                    clip: true

                    Image {
                        anchors.fill: parent
                        asynchronous: true
                        cache: true
                        fillMode: Image.PreserveAspectCrop
                        // Smooth only when the strip is still — smoothing
                        // every frame of a fling is wasted filtering.
                        smooth: !view.moving
                        sourceSize.width: view.thumbWidth * 2
                        sourceSize.height: view.thumbHeight * 2
                        // A live entry is a video; Image cannot decode one,
                        // so it shows the frame the wallpaper pipeline
                        // already extracted (measured: the mp4 tile rendered
                        // as an empty rectangle before this).
                        source: "file://" + (tile.modelData.isLive ? root.posterFor(tile.modelData.relpath) : tile.modelData.path)
                    }

                    Rectangle {
                        visible: tile.modelData.isLive
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: Design.spacingXs
                        width: 20
                        height: 20
                        radius: 10
                        color: Colours.surface
                        opacity: 0.85

                        Text {
                            anchors.centerIn: parent
                            font.family: Design.symbolFontFamily
                            font.pixelSize: 13
                            color: Colours.primary
                            text: "play_arrow"
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: tile.current ? 2 : 0
                        border.color: Colours.primary
                    }
                }

                Text {
                    width: view.thumbWidth
                    text: tile.modelData.relpath
                    color: tile.current ? Colours.onSurface : Colours.onSurfaceVariant
                    font.pixelSize: Design.settingsFontSub
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    view.currentIndex = tile.index;
                    root.activate();
                }
            }
        }
    }

    // Empty state — a filter that matches nothing must say so rather than
    // showing a blank strip.
    Text {
        anchors.centerIn: parent
        visible: root.count === 0
        text: root.entries.length === 0 ? "Loading wallpapers…" : "No wallpaper matches that"
        color: Colours.outline
        font.pixelSize: Design.settingsFontRow
    }
}
