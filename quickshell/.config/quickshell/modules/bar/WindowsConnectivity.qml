pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool enabled: Quickshell.env("DONT_PROMPT_WSL_INSTALL") === "1"
        && !!Quickshell.env("WEASELWAY_VSOCK_PORT")
    readonly property string wslDir: Quickshell.env("HOME") + "/dotfiles/wsl/"
    readonly property var wifi: snapshot?.wifi ?? null
    readonly property var bluetooth: snapshot?.bluetooth ?? null
    property var snapshot: null
    property double lastRefresh: 0

    function refresh() {
        if (!root.enabled || probe.running || Date.now() - root.lastRefresh < 2000)
            return;
        root.lastRefresh = Date.now();
        probe.running = true;
    }

    function openSettings(section) {
        if (!root.enabled)
            return;
        const uri = section === "wifi" ? "ms-settings:network-wifi" : "ms-settings:bluetooth";
        Quickshell.execDetached(["/usr/bin/bash", "-c",
            '"$1" --hide; exec /mnt/c/Windows/System32/cmd.exe /c start "" "$2"',
            "windows-connectivity", root.wslDir + "launch-desktop", uri]);
    }

    Component.onCompleted: root.refresh()

    Process {
        id: probe
        command: ["/usr/bin/timeout", "9s", "/usr/bin/bash", "-ec",
            'ARCH_CONNECTIVITY_SCRIPT="$(wslpath -w "$1")"; export ARCH_CONNECTIVITY_SCRIPT; '
            + 'export WSLENV="${WSLENV:+$WSLENV:}ARCH_CONNECTIVITY_SCRIPT/w"; '
            + 'exec /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -NonInteractive -Command '
            + "'& ([ScriptBlock]::Create([IO.File]::ReadAllText($env:ARCH_CONNECTIVITY_SCRIPT)))'",
            "windows-connectivity", root.wslDir + "windows-connectivity.ps1"]
        stdout: StdioCollector { id: result }
        onExited: code => {
            try {
                root.snapshot = code === 0 ? JSON.parse(result.text) : null;
            } catch (_) {
                root.snapshot = null;
            }
        }
    }
}
