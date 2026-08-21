// modules/settings/pages/AudioPage.qml — page index 3 of the ten-page
// layout (quick-260821-6z1 Task 2 split, D-05/PD-02). Carries the Audio
// NavRow moved out of ConnectivityPage.qml (now retired), byte-identical
// in behaviour to before the split: it still summons the existing panel
// via the same guarded `sState.panelRequested("audio")` relay every other
// entry point uses (D-04). Task 13 builds the real inline mixer here,
// threading the shell's single AudioBackend instance through
// SettingsState the same way this relay already threads panelRequested.
import QtQuick
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Audio"

    SettingsSection {
        title: "Audio"
        icon: "volume_up"

        NavRow {
            label: "Audio"
            subtext: "Output device, volume and per-app mixer"
            onActivated: root.sState.panelRequested("audio")
        }
    }
}
