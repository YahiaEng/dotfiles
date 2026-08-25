// modules/settings/pages/UpdatesPage.qml — page index 14. A flat,
// no-sub-page page (plain Component comp, not a StackPage — D-2's rule
// applies to whichever pages actually HAVE sub-pages, and this one does
// not). Owns its own two `Process` children, bounded: a page is destroyed
// when the user navigates away (`Pages.qml:_swapTo` destroys before
// incubating the next), so a page-scoped Process's lifetime is naturally
// capped.
//
// Reuses the exact command set and defensive exit handling
// `modules/launcher/UpdatesMode.qml` already proves against this host's
// `checkupdates`/`paru -Qua`: ANY non-zero exit degrades to "nothing
// pending", never a distinct error state (`checkupdates` itself documents
// exit 2 for "nothing to do"). Rebuilt (quick-260826-1n9 Task 5, F4) to
// parse each line into a real package record instead of pushing the raw
// `checkupdates`/`paru -Qua` line straight into an InfoRow's subtext.
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

    // Set once, the moment BOTH probes have settled (never when either one
    // alone does) — reads "Never" until then.
    property string _lastChecked: "Never"

    // (a) Parse `<name> <old-version> -> <new-version>` (measured, both
    // `checkupdates` and `paru -Qua` emit this shape). A line that does
    // NOT match is never dropped — it becomes `{name: line, from: "",
    // to: "", source}`, so an unexpected format degrades to the OLD
    // behaviour (the raw line, alone) instead of silently losing a
    // package. Declared above `_packages` below, which reads it (MEMORY
    // qml-declare-before-construction-time-use).
    function _parseLine(line, source) {
        var m = line.match(/^(\S+)\s+(\S+)\s+->\s+(\S+)$/);
        if (m)
            return {
                name: m[1],
                from: m[2],
                to: m[3],
                source: source
            };
        return {
            name: line,
            from: "",
            to: "",
            source: source
        };
    }

    readonly property var _packages: {
        var out = [];
        for (var i = 0; i < root.repoUpdates.length; i++)
            out.push(root._parseLine(root.repoUpdates[i], "repo"));
        for (var j = 0; j < root.aurUpdates.length; j++)
            out.push(root._parseLine(root.aurUpdates[j], "aur"));
        return out;
    }

    // (b) Status subtext — total count FIRST, then the repo/AUR split.
    readonly property string _statusText: {
        if (root._loading)
            return "Checking for updates…";
        if (root._upToDate)
            return "Up to date — no pending repo or AUR updates.";
        var total = root.repoUpdates.length + root.aurUpdates.length;
        return total + " updates pending — " + root.repoUpdates.length + " repo, " + root.aurUpdates.length + " AUR";
    }

    Component.onCompleted: {
        repoProcess.running = true;
        aurProcess.running = true;
    }

    function _maybeMarkChecked() {
        if (root._repoDone && root._aurDone)
            root._lastChecked = new Date().toLocaleTimeString(Qt.locale());
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
            root._maybeMarkChecked();
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
            root._maybeMarkChecked();
        }
    }

    // Locally-declared, deliberately NOT a row primitive — invisible to
    // `ROW_PRIMITIVE_RE` (measured: `component PackageCell: Rectangle {`
    // does not match), so the grid needs no RowIndex entries and cannot
    // re-create the repeated-static-label defect this task fixes. Width
    // is computed from the GRID's own width every time (never a
    // literal), and children never derive width from a cell that itself
    // derives width from them — this module's own SettingsSection header
    // records exactly that circular-binding failure at 81px.
    component PackageCell: Rectangle {
        id: cell
        required property var pkg

        implicitHeight: cellCol.implicitHeight + Design.spacingSm * 2
        radius: 10
        color: Colours.surfaceVariant
        border.width: 1
        border.color: Colours.outline

        Column {
            id: cellCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Design.spacingSm
            spacing: 2

            Row {
                width: parent.width
                spacing: Design.spacingXs

                Text {
                    text: cell.pkg.name
                    font.pixelSize: Design.settingsFontRow
                    color: Colours.onSurface
                    elide: Text.ElideRight
                    width: parent.width - (aurTag.visible ? aurTag.width + Design.spacingXs : 0)
                }

                // AUR membership drawn as a tag from Colours.qml, not the
                // old `"  (AUR)"` string suffix — `source` carries it now.
                Rectangle {
                    id: aurTag
                    visible: cell.pkg.source === "aur"
                    anchors.verticalCenter: parent.verticalCenter
                    radius: height / 2
                    color: Colours.tertiary
                    implicitWidth: aurLabel.implicitWidth + Design.spacingSm * 2
                    implicitHeight: aurLabel.implicitHeight + 4

                    Text {
                        id: aurLabel
                        anchors.centerIn: parent
                        text: "AUR"
                        font.pixelSize: Design.settingsFontSub
                        color: Colours.onTertiary
                    }
                }
            }

            // An unparsed row (from/to both empty) shows the raw line
            // alone — this second line simply does not appear.
            Text {
                visible: cell.pkg.from.length > 0 || cell.pkg.to.length > 0
                text: cell.pkg.from + " -> " + cell.pkg.to
                font.pixelSize: Design.settingsFontSub
                color: Colours.onSurfaceVariant
                elide: Text.ElideRight
                width: parent.width
            }
        }
    }

    SettingsSection {
        title: "Updates"
        icon: "update"

        // (b) Real header block, exactly three row primitives, in order.
        NavRow {
            label: "Update all"
            icon: "download"
            subtext: root._upToDate ? "Nothing to update" : "Opens " + Prefs.getValue("apps.terminal") + " and runs a full system upgrade (" + (root.repoUpdates.length + root.aurUpdates.length) + " pending)"
            enabled: !root._upToDate
            // execDetached, never a component-scoped Process (this
            // repo's own 260822-sht lesson, restated in this task's own
            // action text): a page-scoped Process dies with the page the
            // instant the user navigates away, killing the upgrade
            // mid-flight.
            onActivated: Quickshell.execDetached([Prefs.getValue("apps.terminal"), "-e", "paru", "-Syu"])
        }
        InfoRow {
            label: "Update status"
            icon: "update"
            subtext: root._statusText
        }
        InfoRow {
            label: "Last checked"
            icon: "schedule"
            subtext: root._lastChecked
        }
    }

    // Below the section, inside PageBase's own Flickable — D-4, no
    // nested scrollable. `columnSpacing`/`rowSpacing` are the ONLY
    // spacing tokens read here; every PackageCell's own `width` derives
    // from `packagesGrid.width`, never a literal.
    Grid {
        id: packagesGrid
        width: parent ? parent.width : 400
        columns: 2
        columnSpacing: Design.spacingMd
        rowSpacing: Design.spacingMd
        visible: root._packages.length > 0

        Repeater {
            model: root._packages

            PackageCell {
                required property var modelData
                width: (packagesGrid.width - packagesGrid.columnSpacing) / 2
                pkg: modelData
            }
        }
    }
}
