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
            font.pixelSize: Design.fontLabel
            color: Colours.error
        }

        // ── The grid itself — a bounded-height, independently-scrollable
        //    GridView (never an eager Grid/Flow): with the library's
        //    ~90 entries on this host alone, an unbounded Grid would
        //    instantiate every delegate — including every Image's decode
        //    — at page-incubation time. GridView virtualises against its
        //    OWN viewport height, which is why that height must stay
        //    bounded rather than sized to full contentHeight (a
        //    full-content height would defeat virtualisation the same
        //    way an eager Grid would). `clip: true` keeps off-screen
        //    tiles from painting outside this bounded viewport. ─────────
        GridView {
            id: grid
            width: parent.width
            height: 4 * cellHeight
            clip: true
            cellWidth: 132
            cellHeight: 104
            model: wallpaperSection.entries

            delegate: Item {
                id: tile
                required property var modelData

                width: grid.cellWidth - Design.spacingXs
                height: grid.cellHeight - Design.spacingXs

                readonly property bool isActive: wallpaperSection.activeRelpath === tile.modelData.relpath
                readonly property bool isBusy: wallpaperSection.applyingRelpath === tile.modelData.relpath

                Rectangle {
                    id: tileBg
                    anchors.fill: parent
                    radius: 10
                    clip: true
                    color: Colours.surfaceVariant
                    // Active indicator — a BORDER RING, never a fill (the
                    // exact surfaceVariant-on-surfaceVariant invisibility
                    // class this surface has already shipped four times;
                    // Q-1/Q-3's own discipline, applied here even though
                    // this tile is not a QQC2 control).
                    border.width: tile.isActive ? 3 : 1
                    border.color: tile.isActive ? Colours.primary : Colours.outline

                    Behavior on border.color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }

                    // Still entries — a real, bounded-decode thumbnail.
                    // `sourceSize` caps decode cost regardless of the
                    // source file's own resolution (this library holds
                    // multi-megapixel images); `asynchronous: true` keeps
                    // a slow decode off the incubation path.
                    Image {
                        visible: !tile.modelData.isLive
                        anchors.fill: parent
                        anchors.margins: 3
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 200
                        sourceSize.height: 160
                        source: tile.modelData.isLive ? "" : ("file://" + wallpaperSection.wallpaperDir + "/" + tile.modelData.relpath)
                    }

                    // Live (video) entries — a FIXED placeholder, never an
                    // attempted Image decode. Every "live/" entry gets the
                    // SAME placeholder regardless of its own extension
                    // (this library's live/ folder holds the identical
                    // clip as .gif/.mp4/.webp side by side) — QtQuick's
                    // Image cannot decode video containers at all, and a
                    // per-extension special case (thumbnail the .gif,
                    // placeholder the rest) would make three tiles of the
                    // same clip look inconsistent for no real benefit.
                    Text {
                        visible: tile.modelData.isLive
                        anchors.centerIn: parent
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd * 1.5
                        text: "movie"
                        color: Colours.onSurfaceVariant
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: captionText.implicitHeight + 6
                        color: Colours.surface
                        opacity: 0.85

                        Text {
                            id: captionText
                            anchors.centerIn: parent
                            width: parent.width - 8
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.pixelSize: Design.fontLabel
                            color: Colours.onSurface
                            text: tile.modelData.displayName
                        }
                    }

                    Text {
                        visible: tile.isActive && !tile.isBusy
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 4
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        text: "check_circle"
                        color: Colours.primary
                    }

                    Text {
                        id: busyGlyph
                        visible: tile.isBusy
                        anchors.centerIn: parent
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd * 1.5
                        text: "progress_activity"
                        color: Colours.onSurfaceVariant

                        RotationAnimation on rotation {
                            running: tile.isBusy && Motion.motionEnabled
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: Motion.ambientDuration
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: wallpaperSection.applyingRelpath.length === 0
                        onClicked: wallpaperSection.applyWallpaper(tile.modelData.relpath)
                    }
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
