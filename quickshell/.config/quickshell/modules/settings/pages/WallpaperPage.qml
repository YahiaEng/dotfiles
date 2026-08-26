// modules/settings/pages/WallpaperPage.qml — page index 1 of the ten-page
// layout (quick-260821-6z1 Task 14, D-08/PD-06). The Wallpaper picker row
// is an inline thumbnail GridView — the operator's own Task 14 decision,
// selected knowing the sized cost (a new grid component, bounded image
// loading/caching, an active-selection indicator, and a validated
// non-interactive setter on wallpaper-picker.sh, the largest and most
// intricate of the four picker scripts). Task 11's Motion section and
// theme-scope InfoRow are unchanged.
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
                wallpaperSection.applyDefaultFilter();
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

            onAccepted: path => {
                // --set takes a relpath under the wallpaper dir. A file from
                // ANYWHERE else is out of that contract, so it is reported
                // rather than silently passed to a script that would reject
                // it with a bare non-zero exit.
                var prefix = wallpaperSection.wallpaperDir + "/";
                if (String(path).indexOf(prefix) === 0)
                    wallpaperSection.applyWallpaper(String(path).slice(prefix.length));
                else
                    wallpaperSection.listError = "Only wallpapers under " + wallpaperSection.wallpaperDir + " can be set — copy it there first.";
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
        //    Still a bounded, virtualising GridView for the reason the
        //    previous implementation documented: an eager Grid instantiates
        //    every delegate and every image decode at page-incubation time.
        //    Four per row is Caelestia's `wallpapersPerRow` default
        //    (nexusConfig.hpp:11).
        GridView {
            id: grid

            width: parent.width
            height: Math.min(3, Math.ceil(wallpaperSection.tileModel.length / 4)) * cellHeight + Design.spacingSm
            clip: true

            readonly property int columns: 4
            readonly property int tileWidth: Math.floor((width - Design.spacingSm * (columns - 1)) / columns)

            cellWidth: tileWidth + Design.spacingSm
            cellHeight: tileWidth + Design.spacingXl
            model: wallpaperSection.tileModel

            delegate: Item {
                id: tile

                required property var modelData
                required property int index

                width: grid.tileWidth
                height: grid.cellHeight - Design.spacingSm

                // Viewport gate for live tiles — see WallpaperTile's header.
                // GridView destroys off-screen delegates, but the band that
                // is instantiated-but-not-visible would otherwise decode.
                readonly property bool inViewport: {
                    var top = grid.contentY;
                    var bottom = top + grid.height;
                    var y0 = tile.y;
                    var y1 = y0 + tile.height;
                    return y1 > top && y0 < bottom;
                }

                WallpaperTile {
                    anchors.fill: parent

                    source: wallpaperSection.absPathFor(tile.modelData.relpath)
                    poster: wallpaperSection.posterFor(tile.modelData.relpath)
                    caption: tile.modelData.kind === "category" ? (tile.modelData.name.charAt(0).toUpperCase() + tile.modelData.name.slice(1)) : tile.modelData.name
                    live: tile.modelData.isLive
                    playing: tile.inViewport
                    stackCount: tile.modelData.count
                    active: tile.modelData.kind === "wallpaper" && wallpaperSection.activeRelpath === tile.modelData.relpath

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
