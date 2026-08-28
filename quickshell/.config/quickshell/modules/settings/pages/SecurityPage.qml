// modules/settings/pages/SecurityPage.qml — the Security Center's
// settings surface (quick task 260827-np1).
//
// A flat, no-sub-page page (plain Component in PageCompRegistry, not a
// StackPage). Owns NO Process children — every probe and the running
// scan live on the `SecurityBackend` singleton instead. That is the
// whole architectural point of this feature and the one thing a future
// edit must not undo:
//
//   `UpdatesPage.qml`'s header states the rule — "a page is destroyed
//   when the user navigates away (`Pages.qml:_swapTo` destroys before
//   incubating the next), so a page-scoped Process's lifetime is
//   naturally capped." Every other probe in this shell is sub-second so
//   that cap never mattered. A clamscan runs for MINUTES. Move a probe
//   into this file and it dies the instant the operator clicks another
//   rail item, silently.
//
// ── THE LAYOUT SWITCH LIVES HERE, NOT INSIDE THE LAYOUTS ──────────────
// Same shape `Dashboard.qml`'s two tab Loaders already ship: this page
// resolves the pref and picks a Component, so SecuritySections and
// SecurityFindings each know nothing about being one of several. Adding
// a third layout later is one new file, one qmldir line and one branch —
// no edit to a sibling.
import QtQuick
import ".."
import "../common"
import "../../"
import "../../dashboard"
import "../../security"

PageBase {
    id: root

    title: "Security"

    // Re-probe on open. The backend's own 5-minute timer keeps it fresh
    // in the background, but an operator who just changed something
    // outside the shell should not have to wait for the next tick.
    Component.onCompleted: SecurityBackend.refreshAll()

    SettingsSection {
        title: "Overview"
        icon: "security"

        Loader {
            width: parent ? parent.width : 0
            // `active` rather than a conditional sourceComponent: an
            // inactive Loader has null item and zero height, which is the
            // correct empty state if a layout name is ever unrecognised.
            active: true
            sourceComponent: Prefs.getValue("security.pageLayout") === "sections" ? sectionsComp : findingsComp
        }

        Component {
            id: findingsComp
            SecurityFindings {}
        }

        Component {
            id: sectionsComp
            SecuritySections {}
        }
    }

    SettingsSection {
        title: "Layout"
        icon: "tune"

        SelectRow {
            label: "Security page layout"
            subtext: "Findings puts one ranked list behind a verdict. Sections groups by domain."
            model: [
                {
                    value: "findings",
                    display: "Findings feed"
                },
                {
                    value: "sections",
                    display: "Four sections"
                }
            ]
            currentValue: Prefs.getValue("security.pageLayout")
            onSelected: value => Prefs.setValue("security.pageLayout", value)
        }

        ToggleRow {
            label: "Security glyph in the bar"
            // Writes the BAR's own key, not a second security-side one:
            // BarEntryModel.capsulesForZone() is the single filter point
            // every capsule already goes through, and a parallel pref
            // would be a second way to hide the same thing.
            subtext: "A status glyph next to the notification bell, and the only place a running scan stays visible once this window is closed."
            checked: Prefs.getValue("bar.entries.security")
            onToggled: value => Prefs.setValue("bar.entries.security", value)
        }

        ToggleRow {
            label: "Security tab on the dashboard"
            subtext: "Adds a fifth tab to the Super+D drawer."
            checked: Prefs.getValue("security.showDashboardTab")
            onToggled: value => Prefs.setValue("security.showDashboardTab", value)
        }
    }

    SettingsSection {
        title: "Scanning"
        icon: "policy"

        InfoRow {
            label: "Scan target"
            icon: "folder"
            subtext: SecurityBackend.scanTarget
        }

        InfoRow {
            label: "Virus signatures"
            icon: "coronavirus"
            subtext: SecurityBackend.hasTool("clamav") ? "clamav " + SecurityBackend.tools["clamav"] + " · freshclam keeps signatures current" : "clamav is not installed — install it from the overview above."
        }

        InfoRow {
            label: "Disk health source"
            icon: "hard_drive"
            // Name the mechanism honestly: this is a file a root timer
            // writes, which is why the pane never asks for a password to
            // show disk health.
            subtext: SecurityBackend.smartGenerated > 0 ? "smart-snapshot.timer · last written " + new Date(SecurityBackend.smartGenerated * 1000).toLocaleString(Qt.locale(), Locale.ShortFormat) : "No snapshot yet — smart-snapshot.timer may not be enabled."
        }

        InfoRow {
            label: "Privileged actions"
            icon: "admin_panel_settings"
            subtext: "Enable, Install and Refresh each ask for your password through polkit, every time. Nothing here runs unattended."
        }
    }
}
