// SystemInfoMode.qml — R-2, System ▸ System info (quick task 260822-sht,
// Task 4). A read-only rows view of machine information, sourced from
// `fastfetch --format json` (installed, already listed at
// `install.sh:128` — no new package, this task touches `install.sh` not
// at all, verified by its own `<automated>` gate). JSON output is parsed
// into structured fields rather than scraping fastfetch's own rendered
// ASCII-art box, per this task's own plan text.
//
// This is the one real net-new capability in this task alongside
// UpdatesMode.qml and MenuTree.qml's Apps leaf (D-3) — nothing else may be
// added. Per DQ-4 it is also the SECOND thing to cut if verification gets
// noisy (R-3 → R-2 → R-1), so it stays deliberately minimal: ten fixed
// fields, no live-refresh, no interactivity beyond being visible.
import QtQuick
import Quickshell.Io
import ".."
import "."
import "../dashboard"

Item {
    id: root

    width: parent ? parent.width : 0
    height: Math.min(320, Math.max(root._rows.length, 1) * 32)

    property var _rows: [
        {
            label: "",
            value: "Reading system info…"
        }
    ]

    // Duck-typed interface Launcher.qml's generic keyboard-nav glue reads
    // — a read-only report has nothing to activate (R-1/R-2's own scope:
    // "this surface reports, it does not install/act").
    property int currentIndex: 0
    readonly property int count: root._rows.length
    function activate() {
    }

    Component.onCompleted: fastfetchProcess.running = true

    function _fmtBytes(n) {
        if (!n || n <= 0)
            return "0 GB";
        return (n / 1073741824).toFixed(1) + " GB";
    }

    function _fmtUptime(ms) {
        if (!ms || ms <= 0)
            return "0m";
        const totalMinutes = Math.floor(ms / 60000);
        const hours = Math.floor(totalMinutes / 60);
        const minutes = totalMinutes % 60;
        return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }

    Process {
        id: fastfetchProcess

        command: ["fastfetch", "--format", "json"]
        stdout: StdioCollector {
            id: fastfetchCollector
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root._rows = [
                    {
                        label: "",
                        value: "Could not read system info"
                    }
                ];
                return;
            }
            try {
                const data = JSON.parse(fastfetchCollector.text || "[]");
                const byType = {};
                for (let i = 0; i < data.length; i++)
                    byType[data[i].type] = data[i].result;

                const rows = [];
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

                root._rows = rows.length > 0 ? rows : [
                    {
                        label: "",
                        value: "No system info available"
                    }
                ];
            } catch (e) {
                root._rows = [
                    {
                        label: "",
                        value: "Could not parse system info"
                    }
                ];
            }
        }
    }

    ListView {
        id: infoListView
        anchors.fill: parent
        clip: true
        interactive: false
        model: root._rows

        delegate: Item {
            id: infoDelegate
            required property var modelData
            required property int index

            width: infoListView.width
            height: 32

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 12
                spacing: Design.spacingSm

                Text {
                    width: 80
                    text: infoDelegate.modelData.label
                    color: Colours.onSurfaceVariant
                    font.pixelSize: 13
                }
                Text {
                    text: infoDelegate.modelData.value
                    color: Colours.onSurface
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
            }
        }
    }
    // Scroll indicator (quick task 260828-pol). Sibling of the view,
    // never a child: a Flickable/ListView appends Item children to its
    // scrolled contentItem, so a bar declared inside scrolls away.
    ThemedScrollBar {
        flickable: infoListView
    }
}
