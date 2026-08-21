// modules/settings/pages/BarPage.qml — page index 2 of the ten-page layout
// (quick-260821-6z1 Task 2 split, D-05/PD-02). Carries the Bar orientation
// SelectRow moved out of AppearancePage.qml, byte-identical in behaviour
// to before the split. Task 8 adds Visibility, Idle auto-hide and the six
// capsule toggles.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Bar"

    // ── Bar orientation — inline SelectRow over bar-orientation.sh's own
    //    closed two-value set. Current value from the entry model's own
    //    state file; the script owns the write. ─────────────────────────
    SettingsSection {
        id: barSection
        title: "Bar"
        icon: "dock_to_bottom"

        FileView {
            id: barOrientationFile
            path: Quickshell.env("HOME") + "/.local/state/quickshell/bar-orientation"
            watchChanges: true
            onFileChanged: reload()
        }
        readonly property string barOrientationValue: {
            var v = (barOrientationFile.text() || "").trim();
            return (v === "horizontal" || v === "vertical") ? v : "horizontal";
        }

        property string pendingOrientation: ""

        Process {
            id: barOrientationProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/bar-orientation.sh", barSection.pendingOrientation]
        }

        SelectRow {
            label: "Bar orientation"
            subtext: "Where the bar sits and which axis it lays out along"
            model: [
                { value: "horizontal", display: "Horizontal" },
                { value: "vertical", display: "Vertical" }
            ]
            currentValue: barSection.barOrientationValue
            onSelected: (value) => {
                barSection.pendingOrientation = value;
                barOrientationProc.running = true;
            }
        }
    }
}
