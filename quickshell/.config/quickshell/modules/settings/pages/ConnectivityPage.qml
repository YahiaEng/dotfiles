// modules/settings/pages/ConnectivityPage.qml — D-01's Audio + connectivity
// group: three NavRows, each summoning the existing in-shell panel via the
// SAME guarded `openPanel()` path every other entry point uses (D-04 —
// nothing here is rebuilt). A row calls `sState.panelRequested(name)`,
// which Settings.qml re-emits and shell.qml's LazyLoader turns into
// `root.openPanel(name)` — this page never touches a panel loader
// directly, and never even sees one; it has no way to.
//
// Subtext is a fixed description, not a live backend read: the three
// panel backends (`audioBackendInstance`/`wifiBackendInstance`/
// `bluetoothBackendInstance`) gate their own live PipeWire/NM/bluez
// polling behind a `panelOpen`-shaped condition (`audioTruthNeeded`'s own
// OR-chain in shell.qml) — reading them from here without ALSO widening
// that gate would risk a frozen/stale summary, exactly the class of bug
// 15-07 found and fixed for the dashboard's own Volume tile. Widening
// three backend gates for a subtitle line is out of proportion to what
// D-01 actually requires ("summon the panel"); recorded as a deliberate
// simplification in this plan's own SUMMARY rather than silently doing
// the wider thing.
import QtQuick
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Audio & connectivity"

    SettingsSection {
        id: devicesSection
        title: "Devices"
        icon: "settings_input_antenna"

        NavRow {
            label: "Audio"
            subtext: "Output device, volume and per-app mixer"
            onActivated: root.sState.panelRequested("audio")
        }
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
