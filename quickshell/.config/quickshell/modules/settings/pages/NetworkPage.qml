// modules/settings/pages/NetworkPage.qml — page index 4 of the ten-page
// layout (quick-260821-6z1 Task 2 split, D-05/PD-02). Carries the Wi-Fi
// and Bluetooth NavRows moved out of ConnectivityPage.qml (now retired),
// byte-identical in behaviour: each still summons its existing panel via
// the same guarded `sState.panelRequested()` relay every other entry
// point uses (D-04) — nothing here is rebuilt.
import QtQuick
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Network"

    SettingsSection {
        title: "Devices"
        icon: "settings_input_antenna"

        NavRow {
            label: "Wi-Fi"
            subtext: "Saved and nearby networks"
            onActivated: root.sState.panelRequested("wifi")
        }
        NavRow {
            label: "Bluetooth"
            subtext: "Paired and discovered devices"
            onActivated: root.sState.panelRequested("bluetooth")
        }
    }
}
