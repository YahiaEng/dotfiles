// modules/settings/pages/UpdatesPage.qml — page index 11 (quick task
// 260825-wj2 Task 3). A flat, no-sub-page page (plain Component comp, not
// a StackPage — D-2's rule applies to whichever pages actually HAVE
// sub-pages, and this one does not). Owns its own two `Process` children,
// bounded: a page is destroyed when the user navigates away
// (`Pages.qml:_swapTo` destroys before incubating the next), so a
// page-scoped Process's lifetime is naturally capped.
//
// Reuses the exact command set and defensive exit handling
// `modules/launcher/UpdatesMode.qml` already proves against this host's
// `checkupdates`/`paru -Qua`: ANY non-zero exit degrades to "nothing
// pending", never a distinct error state (`checkupdates` itself documents
// exit 2 for "nothing to do").
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Updates"

    property var repoUpdates: []
    property var aurUpdates: []
    property bool _repoDone: false
    property bool _aurDone: false
    readonly property bool _loading: !root._repoDone || !root._aurDone
    readonly property bool _upToDate: !root._loading && root.repoUpdates.length === 0 && root.aurUpdates.length === 0

    readonly property var _pending: {
        var rows = [];
        for (var i = 0; i < root.repoUpdates.length; i++)
            rows.push(root.repoUpdates[i]);
        for (var j = 0; j < root.aurUpdates.length; j++)
            rows.push(root.aurUpdates[j] + "  (AUR)");
        return rows;
    }

    readonly property string _statusText: {
        if (root._loading)
            return "Checking for updates…";
        if (root._upToDate)
            return "Up to date";
        return root.repoUpdates.length + " repo, " + root.aurUpdates.length + " AUR pending";
    }

    Component.onCompleted: {
        repoProcess.running = true;
        aurProcess.running = true;
    }

    Process {
        id: repoProcess
        running: false
        command: ["checkupdates"]
        stdout: StdioCollector {
            id: repoCollector
        }
        onExited: (exitCode, exitStatus) => {
            root.repoUpdates = exitCode === 0 ? (repoCollector.text || "").split("\n").filter((line) => line.length > 0) : [];
            root._repoDone = true;
        }
    }

    Process {
        id: aurProcess
        running: false
        command: ["paru", "-Qua"]
        stdout: StdioCollector {
            id: aurCollector
        }
        onExited: (exitCode, exitStatus) => {
            root.aurUpdates = exitCode === 0 ? (aurCollector.text || "").split("\n").filter((line) => line.length > 0) : [];
            root._aurDone = true;
        }
    }

    SettingsSection {
        title: "Updates"
        icon: "update"

        InfoRow {
            label: "Update status"
            subtext: root._statusText
        }
        Repeater {
            model: root._pending

            InfoRow {
                id: pendingRow
                required property string modelData

                // STATIC label (RowIndex's jump key is an exact label
                // match — the same reasoning AudioPage.qml's per-app
                // mixer and this quick task's own AllAppsPage row apply).
                label: "Pending update"
                subtext: pendingRow.modelData
            }
        }
        InfoRow {
            visible: root._upToDate
            label: "System is up to date"
            subtext: "No pending repo or AUR updates were found."
        }
        NavRow {
            label: "Update system"
            subtext: "Open the configured terminal and run a full system upgrade"
            // execDetached, never a component-scoped Process (this
            // repo's own 260822-sht lesson, restated in this task's own
            // action text): a page-scoped Process dies with the page the
            // instant the user navigates away, killing the upgrade
            // mid-flight.
            onActivated: Quickshell.execDetached([Prefs.getValue("apps.terminal"), "-e", "paru", "-Syu"])
        }
    }
}
