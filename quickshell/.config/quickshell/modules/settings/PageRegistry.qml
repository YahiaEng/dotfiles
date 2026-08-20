// modules/settings/PageRegistry.qml — pragma Singleton, the ordered
// {label, icon, description, category} metadata list (RESEARCH.md's
// borrowable pattern #1: metadata separate from components, so NavRail can
// render labels/icons/descriptions without instantiating any page).
//
// Nav order is D-01's four locked groups, in that order: Appearance,
// Audio & connectivity, Display & input, Shell behaviour.
// `category` is the deep-link key `shell.qml`'s `openSettingsPage(name)`
// resolves against (F-05's foundation) — never renamed without also
// updating every caller of that function.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property list<var> pages: [
        {
            label: "Appearance",
            icon: "palette",
            description: "Theme, wallpaper, icon theme, font, bar orientation",
            category: "appearance"
        },
        {
            label: "Audio & connectivity",
            icon: "settings_input_antenna",
            description: "Audio mixer, Wi-Fi, Bluetooth",
            category: "connectivity"
        },
        {
            label: "Display & input",
            icon: "desktop_windows",
            description: "Monitor resolution, refresh, scale, keyboard and mouse",
            category: "display"
        },
        {
            label: "Shell behaviour",
            icon: "tune",
            description: "Motion, notifications, idle and lock",
            category: "shell"
        }
    ]
}
