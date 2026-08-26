// modules/settings/pages/WallpaperPage.qml — page index 1 (originally
// quick-260821-6z1 Task 14, D-08/PD-06).
//
// THE BROWSE-EVERYTHING SURFACE. Rebuilt on Caelestia's WallpaperSelect
// structure in 260826-pk2: theme folders collapse to one tile each and drill
// into WallpaperCategoryPage, and Browse opens the shell's own FilePicker
// for an image from anywhere. The FAST picker is a different surface —
// the launcher carousel (modules/launcher/WallpaperMode.qml, 260826-wl3),
// which is what Super+W and Style > Wallpaper open.
//
// The tile grid is an EAGER Grid, not the virtualising GridView this page
// originally used. That reversal is deliberate and is explained at the grid
// itself: the collapsing category model made the set small and bounded, and
// eager children are what make the tiles keyboard-reachable.
//
// Task 11's Motion section and the theme-scope InfoRow are unchanged.
//
// wallpaper-picker.sh gained --list/--active/--set for this task,
// extracted from its own existing "confirm selection" tail
// (_confirm_and_apply(), zero logic changes) and its own existing
// active-detection algorithm (_active_relpath(), copied not re-derived)
// — see that script's own header for the full contract.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"
import "../../filepicker"

PageBase {
    id: root

    title: "Wallpaper"

    SettingsSection {
        id: wallpaperSection
        title: "Wallpaper"
        icon: "wallpaper"

        readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

        // { relpath, displayName, isLive }
        property var entries: []
        property string activeRelpath: ""
        // "" = nothing in flight; otherwise the relpath currently applying.
        property string applyingRelpath: ""
        property string listError: ""

        // ── Categories (quick task 260826-pk2) — replaces the old
        //    "Filter by folder" SelectRow with Caelestia's own collapsing
        //    model (WallpaperSelect.qml). Their rule is "is this file's
        //    parent directory the wallpapers ROOT?": loose files get their
        //    own tile, anything inside a subdirectory collapses to ONE tile
        //    per subdirectory that drills into a category page. Our
        //    per-theme folders ARE that structure already — `relpath` is
        //    `<theme>/<name>` and wallpaper-picker.sh:506 uses the same
        //    folder-name == theme-name identity — so this is their design
        //    applied unchanged, not an adaptation.
        //
        //    A live entry is `<theme>/live/<name>`, so its category is still
        //    the FIRST segment; `live/` is an implementation detail of the
        //    theme folder, never a category of its own.
        readonly property var categories: {
            var seen = ({});
            var out = [];
            for (var i = 0; i < wallpaperSection.entries.length; i++) {
                var e = wallpaperSection.entries[i];
                var parts = String(e.relpath).split("/");
                if (parts.length < 2)
                    continue;
                var cat = parts[0];
                if (!seen[cat]) {
                    seen[cat] = { name: cat, count: 0, cover: e };
                    out.push(seen[cat]);
                }
                seen[cat].count += 1;
                // Cover is the alphabetically first entry, matching
                // Caelestia's `localeCompare` pick — a stable cover rather
                // than whichever file the lister happened to emit first.
                if (String(e.relpath).localeCompare(String(seen[cat].cover.relpath)) < 0)
                    seen[cat].cover = e;
            }
            out.sort(function (x, y) {
                return x.name.localeCompare(y.name);
            });
            return out;
        }

        // Entries sitting directly in the wallpapers root, which get their
        // own tile rather than a category. Empty on this host today; kept
        // because the layout must not assume every wallpaper is foldered.
        readonly property var looseEntries: {
            var out = [];
            for (var i = 0; i < wallpaperSection.entries.length; i++)
                if (String(wallpaperSection.entries[i].relpath).indexOf("/") === -1)
                    out.push(wallpaperSection.entries[i]);
            return out;
        }

        readonly property var tileModel: {
            var out = [];
            for (var i = 0; i < wallpaperSection.categories.length; i++) {
                var c = wallpaperSection.categories[i];
                out.push({
                    kind: "category",
                    name: c.name,
                    relpath: c.cover.relpath,
                    isLive: c.cover.isLive,
                    count: c.count
                });
            }
            for (var j = 0; j < wallpaperSection.looseEntries.length; j++) {
                var e = wallpaperSection.looseEntries[j];
                out.push({
                    kind: "wallpaper",
                    name: e.displayName,
                    relpath: e.relpath,
                    isLive: e.isLive,
                    count: 0
                });
            }
            return out;
        }

        // The frame the wallpaper pipeline already extracts for a live entry
        // (theme_engine_wallpaper_frame_path). Used as the poster under a
        // video tile so it is never a blank rectangle before playback.
        function posterFor(relpath) {
            return Quickshell.env("HOME") + "/.local/state/theme/wallpaper-frames/" + String(relpath).replace("/live/", "/") + ".png";
        }

        function absPathFor(relpath) {
            return wallpaperSection.wallpaperDir + "/" + relpath;
        }

        // Publish UP to SettingsState so WallpaperCategoryPage reads this
        // page's data rather than duplicating the plumbing. Bindings, not
        // one-shot assignments: `entries` is replaced wholesale on every
        // --list, and a Component.onCompleted copy would freeze at whatever
        // was true at construction (which, for a list filled by an async
        // Process, is the empty array).
        Binding {
            target: root.sState
            property: "wallpaperEntries"
            value: wallpaperSection.entries
        }
        Binding {
            target: root.sState
            property: "wallpaperActiveRelpath"
            value: wallpaperSection.activeRelpath
        }

        Connections {
            target: root.sState

            function onWallpaperRequested(relpath) {
                wallpaperSection.applyWallpaper(relpath);
            }
        }

        // The tiles are Repeater delegates over data an async --list fills
        // in, so they do not exist when Pages.qml collects the focus set at
        // page-swap time. Tell it to re-collect once they do, or the grid is
        // permanently unreachable by keyboard.
        onTileModelChanged: root.sState.focusRowsInvalidated()

        // Same plain-text state read AppearancePage.qml's `currentThemeFile`
        // already uses (MEMORY stale-theme-tracker-trap: read
        // ~/.local/state/theme/current-theme, never ~/.cache/current-theme).
        FileView {
            id: currentThemeFile
            path: Quickshell.env("HOME") + "/.local/state/theme/current-theme"
            watchChanges: true
            onFileChanged: reload()
        }

        function refreshActive() {
            activeProc.running = true;
        }

        function refreshList() {
            wallpaperSection.listError = "";
            listWatchdog.restart();
            listProc.running = true;
        }

        // ── List — bounded watchdog so a hung script leaves a visible
        //    error instead of a permanently empty grid. ─────────────────
        Timer {
            id: listWatchdog
            interval: 8000
            onTriggered: {
                if (listProc.running) {
                    listProc.running = false;
                    wallpaperSection.listError = "wallpaper-picker.sh --list did not respond within 8s";
                }
            }
        }
        Process {
            id: listProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-picker.sh", "--list"]
            stdout: StdioCollector { id: listCollector }
            onExited: (code, status) => {
                listWatchdog.stop();
                if (code !== 0) {
                    wallpaperSection.listError = "wallpaper-picker.sh --list failed (exit " + code + ")";
                    return;
                }
                var lines = listCollector.text.split("\n").filter(function (l) { return l.trim().length > 0; });
                wallpaperSection.entries = lines.map(function (relpath) {
                    var parts = relpath.split("/");
                    return {
                        relpath: relpath,
                        displayName: parts[parts.length - 1],
                        // "live/" classification matches wallpaper-picker.sh's
                        // own theme_engine_wallpaper_is_live_ref shape — a
                        // path component literally named "live" — never a
                        // per-extension guess.
                        isLive: relpath.indexOf("/live/") !== -1
                    };
                });
            }
            Component.onCompleted: {
                listWatchdog.restart();
                running = true;
            }
        }

        Process {
            id: activeProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-picker.sh", "--active"]
            stdout: StdioCollector { id: activeCollector }
            onExited: (code, status) => {
                if (code === 0)
                    wallpaperSection.activeRelpath = activeCollector.text.trim();
            }
            Component.onCompleted: running = true
        }

        Timer {
            id: applyWatchdog
            interval: 15000
            onTriggered: {
                if (applyProc.running) {
                    applyProc.running = false;
                    wallpaperSection.applyingRelpath = "";
                    wallpaperSection.listError = "wallpaper-picker.sh --set did not respond within 15s";
                }
            }
        }
        Process {
            id: applyProc
            running: false
            onExited: (code, status) => {
                applyWatchdog.stop();
                wallpaperSection.applyingRelpath = "";
                if (code !== 0)
                    console.warn("WallpaperPage: wallpaper-picker.sh --set failed (exit " + code + ")");
                wallpaperSection.refreshActive();
            }
        }
        function applyWallpaper(relpath) {
            if (wallpaperSection.applyingRelpath.length > 0)
                return;
            wallpaperSection.applyingRelpath = relpath;
            applyWatchdog.restart();
            applyProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-picker.sh", "--set", relpath];
            applyProc.running = true;
        }

        Text {
            visible: wallpaperSection.listError.length > 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: wallpaperSection.listError
            font.pixelSize: Design.settingsFontSub
            color: Colours.error
        }

        // ── Browse / Random (Caelestia WallpaperSelect.qml's ButtonRow) ──
        //    Browse is the "pick any wallpaper, from anywhere" override the
        //    per-theme folders cannot express; it opens this shell's own
        //    picker rather than a GTK portal dialog.
        Row {
            width: parent.width
            spacing: Design.spacingSm

            Item {
                width: (parent.width - Design.spacingSm) / 2
                height: 48

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Colours.primary
                    opacity: browseHover.containsMouse ? 0.9 : 1

                    Behavior on opacity {
                        enabled: Motion.motionEnabled
                        NumberAnimation {
                            duration: Motion.colourDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.colourEasing
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: Design.spacingSm

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Design.symbolFontFamily
                            font.pixelSize: 20
                            color: Colours.onPrimary
                            text: "photo_library"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Browse"
                            color: Colours.onPrimary
                            font.pixelSize: Design.settingsFontSub
                            font.weight: Design.weightEmphasis
                        }
                    }

                    MouseArea {
                        id: browseHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: browsePicker.open()
                    }
                }
            }

            Item {
                width: (parent.width - Design.spacingSm) / 2
                height: 48

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Colours.primaryContainer
                    opacity: randomHover.containsMouse ? 0.9 : 1

                    Behavior on opacity {
                        enabled: Motion.motionEnabled
                        NumberAnimation {
                            duration: Motion.colourDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.colourEasing
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: Design.spacingSm

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Design.symbolFontFamily
                            font.pixelSize: 20
                            color: Colours.onSurface
                            text: "shuffle"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Random"
                            color: Colours.onSurface
                            font.pixelSize: Design.settingsFontSub
                            font.weight: Design.weightEmphasis
                        }
                    }

                    MouseArea {
                        id: randomHover
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: wallpaperSection.entries.length > 0 && wallpaperSection.applyingRelpath.length === 0
                        onClicked: {
                            // Random over the WHOLE library, categories
                            // included — the button means "surprise me", not
                            // "surprise me within this folder".
                            var n = wallpaperSection.entries.length;
                            if (n > 0)
                                wallpaperSection.applyWallpaper(wallpaperSection.entries[Math.floor(Math.random() * n)].relpath);
                        }
                    }
                }
            }
        }

        FilePicker {
            id: browsePicker

            title: "Select a wallpaper"
            filterLabel: "Image files"
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.bmp", "*.avif"]
            startPath: wallpaperSection.wallpaperDir

            // --set learned absolute paths in this same task, so Browse can
            // apply an image from anywhere. The script folds a path that is
            // actually inside the wallpapers root back to its relpath, so
            // an in-library pick keeps its theme recording and live handling
            // — no need to pre-classify the path here.
            onAccepted: path => wallpaperSection.applyWallpaper(String(path))

            // Defect 2 fix (operator live pass, quick task 260826-oyu) — the
            // picker is a second toplevel, and the settings window's Hyprland
            // focus grab holds input exclusively to the surfaces it lists.
            // Join the grab while open, leave it on close. Reassignment, not
            // an in-place push: `extraGrabWindows` is a plain JS array behind
            // a `property var`, and mutating it emits no change signal.
            //
            // Keyed on the LazyLoader's `item` rather than on `active`: the
            // window only exists once the loader has actually built it, and
            // registering a null would put a null in the grab's list.
            onItemChanged: {
                root.sState.extraGrabWindows = browsePicker.item ? [browsePicker.item] : [];
            }
        }

        Text {
            width: parent.width
            visible: wallpaperSection.tileModel.length > 0
            topPadding: Design.spacingSm
            text: "Local wallpapers"
            color: Colours.onSurface
            font.pixelSize: Design.settingsFontRow
            font.weight: Design.weightEmphasis
        }

        // ── The tile grid ────────────────────────────────────────────────
        //    An EAGER Grid, deliberately, reversing this page's earlier
        //    GridView. The old comment's reason for virtualising was ~90
        //    wallpaper entries; the collapsing category model replaced that
        //    with one tile per theme folder (16 here) plus any loose files,
        //    so the eager cost is bounded and small. In exchange the tiles
        //    are real, permanent children, which is what makes them
        //    keyboard-reachable: Pages.qml collects focusable stops by
        //    walking `children`, and a virtualising view creates delegates
        //    lazily, so the focus set would change size as the user scrolls.
        Grid {
            id: grid

            width: parent.width
            columns: 4
            spacing: Design.spacingSm

            readonly property int tileWidth: Math.floor((width - spacing * (columns - 1)) / columns)

            Repeater {
                model: wallpaperSection.tileModel

                delegate: WallpaperTile {
                    id: tile

                    required property var modelData
                    required property int index

                    width: grid.tileWidth

                    source: wallpaperSection.absPathFor(tile.modelData.relpath)
                    poster: wallpaperSection.posterFor(tile.modelData.relpath)
                    caption: tile.modelData.kind === "category" ? (tile.modelData.name.charAt(0).toUpperCase() + tile.modelData.name.slice(1)) : tile.modelData.name
                    live: tile.modelData.isLive
                    stackCount: tile.modelData.count
                    active: tile.modelData.kind === "wallpaper" && wallpaperSection.activeRelpath === tile.modelData.relpath

                    // Live playback gate, now that there is no GridView
                    // viewport to test against: ask the page's own Flickable
                    // whether this tile is on screen. Same intent as before —
                    // only visible tiles decode video.
                    playing: {
                        const f = root.flickable;
                        if (!f)
                            return false;
                        const pos = tile.mapToItem(f.contentItem, 0, 0);
                        return pos.y + tile.height > f.contentY && pos.y < f.contentY + f.height;
                    }

                    onClicked: {
                        if (tile.modelData.kind === "category") {
                            root.sState.selectedWallpaperCategory = tile.modelData.name;
                            root.sState.openSubPage(1);
                        } else if (wallpaperSection.applyingRelpath.length === 0) {
                            wallpaperSection.applyWallpaper(tile.modelData.relpath);
                        }
                    }
                }
            }
        }

        // Empty state, same shape as Caelestia's `hide_image` panel.
        Rectangle {
            width: parent.width
            visible: wallpaperSection.tileModel.length === 0 && wallpaperSection.listError.length === 0
            height: visible ? 160 : 0
            radius: 28
            color: Colours.surfaceVariant

            Column {
                anchors.centerIn: parent
                spacing: Design.spacingXs

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: Design.symbolFontFamily
                    font.pixelSize: 44
                    color: Colours.outline
                    text: "hide_image"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No local wallpapers found"
                    color: Colours.outline
                    font.pixelSize: Design.settingsFontRow
                }
            }
        }

        InfoRow {
            label: "The wallpaper drives dynamic theming"
            subtext: "In the Material You dynamic theme mode, changing the wallpaper regenerates the whole palette — that is why a wallpaper change re-themes the desktop."
        }
    }

    // ── Wallpaper motion (Task 11) — wallpaper-visibility.sh's own
    //    `status` is two-shaped: "stopped" or "playing:<selection>".
    //    Parsed on the colon, never string-compared whole, and the
    //    selection rides as subtext. `main()` takes an flock before
    //    doing anything (same discipline as bar-visibility.sh), so
    //    status is polled only while this page is mounted. ───────────────
    SettingsSection {
        id: motionSection
        title: "Motion"
        icon: "wallpaper"

        property string statusValue: "stopped"
        property string playingSelection: ""

        function refreshStatus() {
            motionStatusProc.running = true;
        }

        Process {
            id: motionStatusProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-visibility.sh", "status"]
            stdout: StdioCollector { id: motionStatusCollector }
            onExited: (code, status) => {
                if (code === 0) {
                    var v = motionStatusCollector.text.trim();
                    if (v.length > 0) {
                        var idx = v.indexOf(":");
                        if (idx >= 0) {
                            motionSection.statusValue = v.slice(0, idx);
                            motionSection.playingSelection = v.slice(idx + 1);
                        } else {
                            motionSection.statusValue = v;
                            motionSection.playingSelection = "";
                        }
                    }
                }
            }
        }

        Process {
            id: motionToggleProc
            running: false
            onExited: (code, status) => motionSection.refreshStatus()
        }

        Timer {
            id: motionStatusPoll
            interval: 3000
            repeat: true
            onTriggered: motionSection.refreshStatus()
        }
        Component.onCompleted: {
            motionSection.refreshStatus();
            motionStatusPoll.start();
        }
        Component.onDestruction: motionStatusPoll.stop()

        ToggleRow {
            label: "Wallpaper motion"
            subtext: motionSection.statusValue === "playing"
                ? ("Playing: " + motionSection.playingSelection)
                : "Stopped"
            checked: motionSection.statusValue === "playing"
            onToggled: (value) => {
                motionToggleProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-visibility.sh", "motion", value ? "show" : "hide"];
                motionToggleProc.running = true;
            }
        }
    }
}
