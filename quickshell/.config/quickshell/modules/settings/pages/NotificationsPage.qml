// modules/settings/pages/NotificationsPage.qml — page index 8 of the
// ten-page layout (quick-260821-6z1 Task 2 split, D-05/PD-02). Carries
// the Do not disturb ToggleRow moved out of ShellBehaviourPage.qml (now
// retired), byte-identical in behaviour to before the split — a second
// VIEW of NotifServer's own already-persisted DND state, never a new
// writer (D-04). Task 9 fills in popup timeout, position, history limit,
// max visible popups, OSD duration/position, dashboard panel toggles and
// the weather/news source pickers.
import QtQuick
import ".."
import "../common"
import "../../"
import "../../dashboard"
import "../../notifications"

PageBase {
    id: root

    title: "Notifications"

    SettingsSection {
        title: "Notifications"
        icon: "notifications"

        ToggleRow {
            label: "Do not disturb"
            subtext: "Suppress notification popups"
            checked: NotifServer.dnd
            onToggled: NotifServer.toggleDnd()
        }
    }
}
