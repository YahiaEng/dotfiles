// modules/settings/pages/AboutPage.qml — page index 12 (quick task
// 260825-wj2 Task 3). Flat page, no sub-pages. Reuses the exact fastfetch
// JSON parse (`byType` reduction, `_fmtBytes`/`_fmtUptime`) already proven
// against this host by `modules/launcher/SystemInfoMode.qml`.
import QtQuick
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "About"

    property var _rows: []

    function _fmtBytes(n) {
        if (!n || n <= 0)
            return "0 GB";
        return (n / 1073741824).toFixed(1) + " GB";
    }

    function _fmtUptime(ms) {
        if (!ms || ms <= 0)
            return "0m";
        var totalMinutes = Math.floor(ms / 60000);
        var hours = Math.floor(totalMinutes / 60);
        var minutes = totalMinutes % 60;
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }

    Component.onCompleted: fastfetchProcess.running = true

    Process {
        id: fastfetchProcess
        running: false
        command: ["fastfetch", "--format", "json"]
        stdout: StdioCollector {
            id: fastfetchCollector
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root._rows = [];
                return;
            }
            try {
                var data = JSON.parse(fastfetchCollector.text || "[]");
                var byType = {};
                for (var i = 0; i < data.length; i++)
                    byType[data[i].type] = data[i].result;

                var rows = [];
                if (byType.OS)
                    rows.push({
                        label: "OS",
                        value: byType.OS.prettyName || byType.OS.name || ""
                    });
                if (byType.Host)
                    rows.push({
                        label: "Host",
                        value: byType.Host.name || ""
                    });
                if (byType.Kernel)
                    rows.push({
                        label: "Kernel",
                        value: byType.Kernel.release || ""
                    });
                if (byType.Uptime)
                    rows.push({
                        label: "Uptime",
                        value: root._fmtUptime(byType.Uptime.uptime)
                    });
                if (byType.Packages)
                    rows.push({
                        label: "Packages",
                        value: String(byType.Packages.all || 0)
                    });
                if (byType.Shell)
                    rows.push({
                        label: "Shell",
                        value: (byType.Shell.prettyName || "") + " " + (byType.Shell.version || "")
                    });
                if (byType.CPU)
                    rows.push({
                        label: "CPU",
                        value: byType.CPU.cpu || ""
                    });
                if (byType.GPU && byType.GPU.length > 0)
                    rows.push({
                        label: "GPU",
                        value: byType.GPU[0].name || ""
                    });
                if (byType.Memory)
                    rows.push({
                        label: "Memory",
                        value: root._fmtBytes(byType.Memory.used) + " / " + root._fmtBytes(byType.Memory.total)
                    });
                root._rows = rows;
            } catch (e) {
                root._rows = [];
            }
        }
    }

    SettingsSection {
        title: "System"
        icon: "info"

        Repeater {
            model: root._rows

            InfoRow {
                id: infoRow
                required property var modelData

                // STATIC label (RowIndex's jump key is an exact label
                // match — the same reasoning every other per-item Repeater
                // in this quick task applies).
                label: "System information"
                subtext: infoRow.modelData.label + ": " + infoRow.modelData.value
            }
        }
    }

    SettingsSection {
        title: "Shell"

        InfoRow {
            label: "Shell"
            subtext: "Quickshell config at ~/.config/quickshell — the bar, notification popups and centre, OSD indicators, power menu, media readout and this launcher/settings window all run in one process."
        }
        InfoRow {
            label: "Credits"
            subtext: "This settings window's structure is borrowed from Caelestia and end-4/dots-hyprland, two reference Hyprland shells."
        }
    }
}
