// modules/settings/pages/WallpaperPage.qml — page index 1 of the ten-page
// layout (quick-260821-6z1 Task 2 split, D-05/PD-02). Carries the
// Wallpaper NavRow moved out of AppearancePage.qml, byte-identical in
// behaviour to before the split. Task 11 adds the Wallpaper motion row
// and the theme-scope InfoRow; Task 14's decision determines this page's
// final picker-row shape (launcher vs inline thumbnail grid) before
// Task 15's live pass.
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

        Process {
            id: wallpaperBasenameProc
            running: false
            command: ["readlink", "-f", Quickshell.env("HOME") + "/.local/state/theme/current.jpg"]
            stdout: StdioCollector {
                id: wallpaperBasenameCollector
            }
            onExited: (exitCode, exitStatus) => {
                var full = wallpaperBasenameCollector.text.trim();
                var parts = full.split("/");
                wallpaperSection.wallpaperBasename = parts.length > 0 ? parts[parts.length - 1] : full;
            }
        }
        property string wallpaperBasename: ""
        Component.onCompleted: wallpaperBasenameProc.running = true

        Process {
            id: wallpaperLaunchProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-switch.sh"]
        }

        NavRow {
            label: "Wallpaper"
            subtext: wallpaperSection.wallpaperBasename
            onActivated: {
                wallpaperLaunchProc.running = true;
                root.sState.close();
            }
        }
    }
}
