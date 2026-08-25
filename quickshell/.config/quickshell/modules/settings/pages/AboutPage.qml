// modules/settings/pages/AboutPage.qml — page index 15. Flat page, no
// sub-pages. Reuses the exact fastfetch JSON parse (`byType` reduction,
// `_fmtBytes`/`_fmtUptime`) already proven against this host by
// `modules/launcher/SystemInfoMode.qml`.
//
// System field enumeration (quick-260826-1n9 Task 4, D-3) — the static-
// label rule exists because a Repeater's per-item label breaks
// `pendingRowLabel`'s exact-match jump key. Nine system fields are a
// FIXED set (fastfetch's own `--format json` type list never grows or
// shrinks per-run), so the Repeater this page used to hold was never
// buying anything: nine literal InfoRows give nine real titles, nine
// RowIndex entries, and nine independently searchable rows. Absent
// fastfetch fields render with an honest "Not reported by fastfetch"
// subtext rather than disappearing — `_collectFocusableRows` does not
// filter on `visible`, so a hidden row would still occupy a keyboard
// slot.
import QtQuick
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "About"

    // Field map keyed by fastfetch's own field name (quick-260826-1n9
    // Task 4) — replaces the old `_rows` array the Repeater consumed.
    // `_val()` is the one place a missing field's fallback text lives.
    property var _fields: ({})

    function _val(name) {
        var v = root._fields[name];
        return (v !== undefined && v !== null && v !== "") ? v : "";
    }

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
                root._fields = {};
                return;
            }
            try {
                var data = JSON.parse(fastfetchCollector.text || "[]");
                var byType = {};
                for (var i = 0; i < data.length; i++)
                    byType[data[i].type] = data[i].result;

                var fields = {};
                if (byType.OS)
                    fields.OS = byType.OS.prettyName || byType.OS.name || "";
                if (byType.Host)
                    fields.Host = byType.Host.name || "";
                if (byType.Kernel)
                    fields.Kernel = byType.Kernel.release || "";
                if (byType.Uptime)
                    fields.Uptime = root._fmtUptime(byType.Uptime.uptime);
                if (byType.Packages)
                    fields.Packages = String(byType.Packages.all || 0);
                if (byType.Shell)
                    fields.Shell = (byType.Shell.prettyName || "") + " " + (byType.Shell.version || "");
                if (byType.CPU)
                    fields.CPU = byType.CPU.cpu || "";
                if (byType.GPU && byType.GPU.length > 0)
                    fields.GPU = byType.GPU[0].name || "";
                if (byType.Memory)
                    fields.Memory = root._fmtBytes(byType.Memory.used) + " / " + root._fmtBytes(byType.Memory.total);
                root._fields = fields;
            } catch (e) {
                root._fields = {};
            }
        }
    }

    SettingsSection {
        title: "System"
        icon: "info"

        InfoRow {
            label: "OS"
            icon: "computer"
            subtext: root._val("OS") || "Not reported by fastfetch"
        }
        InfoRow {
            label: "Host"
            icon: "monitor"
            subtext: root._val("Host") || "Not reported by fastfetch"
        }
        InfoRow {
            label: "Kernel"
            icon: "dns"
            subtext: root._val("Kernel") || "Not reported by fastfetch"
        }
        InfoRow {
            label: "Uptime"
            icon: "schedule"
            subtext: root._val("Uptime") || "Not reported by fastfetch"
        }
        InfoRow {
            label: "Packages"
            icon: "package_2"
            subtext: root._val("Packages") || "Not reported by fastfetch"
        }
        // Renamed from "Shell" to "Shell version" (quick-260826-1n9 Task
        // 4) — the section-level "Shell" row below is about THIS shell
        // (Quickshell config), this row is about $SHELL. Both were
        // labelled "Shell" before this task, which is a RowIndex label
        // collision: two entries with the same label on the same page
        // make `pendingRowLabel`'s first-match jump ambiguous, and CHECK
        // B's verbatim grep passes for both — they were never the same
        // thing and are named accordingly now.
        InfoRow {
            label: "Shell version"
            icon: "terminal"
            subtext: root._val("Shell") || "Not reported by fastfetch"
        }
        InfoRow {
            label: "CPU"
            icon: "developer_board"
            subtext: root._val("CPU") || "Not reported by fastfetch"
        }
        InfoRow {
            label: "GPU"
            icon: "widgets"
            subtext: root._val("GPU") || "Not reported by fastfetch"
        }
        InfoRow {
            label: "Memory"
            icon: "memory"
            subtext: root._val("Memory") || "Not reported by fastfetch"
        }
    }

    SettingsSection {
        title: "Shell"

        InfoRow {
            label: "Shell"
            icon: "dashboard"
            subtext: "Quickshell config at ~/.config/quickshell — the bar, notification popups and centre, OSD indicators, power menu, media readout and this launcher/settings window all run in one process."
        }
        InfoRow {
            label: "Credits"
            icon: "info"
            subtext: "This settings window's structure is borrowed from Caelestia and end-4/dots-hyprland, two reference Hyprland shells."
        }
    }
}
