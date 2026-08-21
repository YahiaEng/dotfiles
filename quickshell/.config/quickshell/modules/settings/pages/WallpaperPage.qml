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
