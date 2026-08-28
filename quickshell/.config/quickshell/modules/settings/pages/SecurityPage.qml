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
// ── ONE LAYOUT ────────────────────────────────────────────────────────
// This shipped with an S1/S2 picker behind `security.pageLayout`.
// Operator round 3 merged them ("both security layouts feel redundant,
// they should be combined"), so the Loader, the pref and both layout
// files are gone and `SecurityOverview` is mounted directly. It keeps
// S2's verdict header and ranking AND S1's domain grouping — see its own
// header for how the merge orders things.
import QtQuick
import ".."
import "../common"
import "../../"
import "../../dashboard"
import "../../security"
import "../../filepicker"

PageBase {
    id: root

    title: "Security"

    // Re-probe on open. The backend's own 5-minute timer keeps it fresh
    // in the background, but an operator who just changed something
    // outside the shell should not have to wait for the next tick.
    Component.onCompleted: SecurityBackend.refreshAll()

    // ── Let the polkit prompt have focus (operator round 4) ────────────
    // Every privileged action raises an EXTERNAL toplevel
    // (polkit-gnome-authentication-agent-1, "Authenticate"). Settings'
    // HyprlandFocusGrab is exclusive and cannot include another process's
    // window, so without this the operator's click on the password prompt
    // is treated as a click outside the grab: Settings takes focus back
    // and the prompt drops behind it — they had to close Settings to
    // reach the box.
    //
    // A Binding rather than an assignment so the hold is RELEASED
    // automatically if this page is destroyed mid-action; a leaked hold
    // would disable click-outside-dismiss for the rest of the session.
    Binding {
        target: root.sState
        property: "externalDialogOpen"
        value: SecurityBackend.actionRunning
        restoreMode: Binding.RestoreBindingOrValue
    }

    SettingsSection {
        title: "Overview"
        icon: "security"

        // ONE layout (operator round 3). The S1/S2 picker is gone and
        // SecurityOverview merges both — see its header.
        SecurityOverview {}
    }

    SettingsSection {
        title: "Dashboard"
        icon: "tune"

        ToggleRow {
            label: "Security tab on the dashboard"
            subtext: "Adds a fifth tab to the Super+D drawer."
            checked: Prefs.getValue("security.showDashboardTab")
            onToggled: value => Prefs.setValue("security.showDashboardTab", value)
        }
        // The bar glyph's toggle deliberately lives ONLY on the Bar page,
        // next to the other capsule entries (operator round 3: the
        // duplicate here was redundant). One switch, one home.
    }

    SettingsSection {
        title: "Scanning"
        icon: "policy"

        NavRow {
            label: "Scan target"
            icon: "folder"
            // Was a SelectRow with four fixed choices (operator round 6:
            // "a dropdown list with limited options instead of opening a
            // dialog box to select scan directory"). Now it opens the
            // shell's own FilePicker in the directory mode this task
            // added to it — no second picker implementation.
            subtext: SecurityBackend.scanTargetMissing ? SecurityBackend.scanTarget + " — this folder no longer exists" : SecurityBackend.scanTarget
            onActivated: targetPicker.open()
        }

        FilePicker {
            id: targetPicker

            title: "Choose a folder to scan"
            selectDirectories: true
            startPath: SecurityBackend.scanTarget

            onAccepted: path => Prefs.setValue("security.scanTarget", String(path))

            // The picker is a second toplevel and Settings' focus grab is
            // exclusive, so it must join the grab while open or its clicks
            // land on the window behind. Reassignment, not an in-place
            // push: `extraGrabWindows` is a plain JS array behind a
            // `property var` and mutating it emits no change signal.
            // Keyed on `item`, not `active` — the window only exists once
            // the LazyLoader has built it, and registering a null would
            // put a null in the grab's list. Same shape WallpaperPage's
            // Browse picker already uses.
            onItemChanged: {
                root.sState.extraGrabWindows = targetPicker.item ? [targetPicker.item] : [];
            }
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
