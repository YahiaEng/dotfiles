// modules/settings/PageRegistry.qml — pragma Singleton, the ordered
// {label, icon, description, category, slug} metadata list (RESEARCH.md's
// borrowable pattern #1: metadata separate from components, so NavRail can
// render labels/icons/descriptions without instantiating any page).
//
// Ten-page split (quick-260821-6z1 Task 2, D-05/PD-02) — the operator's
// own rendered layout: [Appearance, Wallpaper, Bar] / [Audio, Network] /
// [Display, Input] / [Window manager, Notifications, Session], in that
// order. `category` groups the rail's corner-radius grouping
// (NavRail.qml's own isCategoryStart/isCategoryEnd) into the operator's
// four visual clusters: appearance / connectivity / display / shell.
//
// ── Deep-link resolution (PD-03) — TWO-STAGE, in `shell.qml`'s
//    `openSettingsPage(name)`:
//      1. Exact `slug` match FIRST — the new, precise per-page keys below
//         (`bar`, `notifications`, `session`, …).
//      2. `category` first-match-wins by index SECOND — the legacy keys
//         (`appearance`, `connectivity`, `display`, `shell`) resolve to
//         whichever page is FIRST in `pages[]` carrying that category,
//         exactly as they did before this split (`appearance`->0,
//         `connectivity`->3, `display`->5, `shell`->7). There are zero
//         external callers of the legacy keys today (grepped over
//         quickshell/, hypr/ — only the IPC verb itself), so this
//         introduces no regression.
//    `shell.qml`'s own `Component.onCompleted` runs an assertion that all
//    four legacy category keys still resolve to an in-range index, and
//    warns by name if one stops. ─────────────────────────────────────────
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property list<var> pages: [
        {
            label: "Appearance",
            icon: "palette",
            description: "Theme, icon theme, font",
            category: "appearance",
            slug: "appearance"
        },
        {
            label: "Wallpaper",
            icon: "wallpaper",
            description: "Wallpaper and wallpaper motion",
            category: "appearance",
            slug: "wallpaper"
        },
        {
            label: "Bar",
            icon: "dock_to_bottom",
            description: "Orientation, visibility, capsules",
            category: "appearance",
            slug: "bar"
        },
        {
            label: "Audio",
            icon: "volume_up",
            description: "Volume, devices, per-app mixer",
            category: "connectivity",
            slug: "audio"
        },
        {
            label: "Network",
            icon: "settings_input_antenna",
            description: "Wi-Fi, Bluetooth",
            category: "connectivity",
            slug: "network"
        },
        {
            label: "Display",
            icon: "desktop_windows",
            description: "Monitor resolution, refresh, scale, position",
            category: "display",
            slug: "display"
        },
        {
            label: "Input",
            icon: "keyboard",
            description: "Keyboard and mouse, per-device settings",
            category: "display",
            slug: "input"
        },
        {
            label: "Window manager",
            icon: "tune",
            description: "Gaps, rounding, blur, animation, workspaces",
            category: "shell",
            slug: "window-manager"
        },
        {
            label: "Notifications",
            icon: "notifications",
            description: "Popups, OSD, dashboard panels",
            category: "shell",
            slug: "notifications"
        },
        {
            label: "Session",
            icon: "lock_clock",
            description: "Idle, lock, gaming mode, recording, power menu",
            category: "shell",
            slug: "session"
        },
        // Apps (quick task 260825-wj2 Task 2) — appended at index 10, no
        // renumbering of the ten pages above. StackPage-wrapped (D-2): two
        // sub-pages, All apps and App info.
        {
            label: "Apps",
            icon: "apps",
            description: "Default applications, favourites and hidden",
            category: "shell",
            slug: "apps"
        },
        // Updates + About (quick task 260825-wj2 Task 3) — appended at 11,
        // 12. No renumbering; both flat, no sub-pages.
        {
            label: "Updates",
            icon: "update",
            description: "Pending package updates, system upgrade",
            category: "system",
            slug: "updates"
        },
        {
            label: "About",
            icon: "info",
            description: "System information, credits",
            category: "about",
            slug: "about"
        }
    ]

    // Legacy category keys that resolved a page before this split — every
    // one of these must still resolve to an in-range `pages[]` index via
    // the first-match-wins rule above.
    readonly property var _legacyCategoryKeys: ["appearance", "connectivity", "display", "shell"]

    function _resolveCategory(name) {
        for (var i = 0; i < root.pages.length; i++) {
            if (root.pages[i].category === name)
                return i;
        }
        return -1;
    }

    Component.onCompleted: {
        for (var i = 0; i < root._legacyCategoryKeys.length; i++) {
            var key = root._legacyCategoryKeys[i];
            var idx = root._resolveCategory(key);
            if (idx < 0 || idx >= root.pages.length)
                console.warn("PageRegistry: legacy category key stopped resolving: " + key);
        }
    }
}
