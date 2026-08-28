// modules/settings/pages/PackagesPage.qml — Settings ▸ Packages.
//
// ── THIS PAGE IS DELIBERATELY THIN ────────────────────────────────────
// It is NOT a package browser, and the omission is the design. The
// study's D1 drew a full browser here — chips, list, and a `pacman -Qi`
// detail pane — and it was cut once D4 was picked as the main surface,
// because the two would have been the same browser in two frames. That
// is precisely the redundancy that got the Security Center's two layouts
// merged in its operator round 3 ("both security layouts feel
// redundant"), and this task is not repeating it.
//
// So: one button into the workbench, and the settings the workbench and
// the bar capsule both read. A flat page, no sub-pages, so a plain
// PageBase rather than a StackPage — D-2's rule applies to pages that
// actually HAVE sub-pages.
//
// ── NO Process, NO probe ──────────────────────────────────────────────
// Every number shown here is read from PackagesBackend, which is a
// singleton that has already loaded. Unlike UpdatesPage.qml this page
// owns no `Process` at all, so there is nothing to bound to the page's
// lifetime.
import QtQuick
import ".."
import "../common"
import "../../"
import "../../dashboard"
import "../../packages"

PageBase {
    id: root

    title: "Packages"

    readonly property string _summary: {
        if (!PackagesBackend.packagesProbed)
            return "Reading the package database…";
        var parts = [];
        parts.push(PackagesBackend.installedCount + " installed");
        parts.push(PackagesBackend.foreignCount + " from the AUR");
        if (PackagesBackend.pendingCount > 0)
            parts.push(PackagesBackend.pendingCount + " pending");
        if (PackagesBackend.orphans.length > 0)
            parts.push(PackagesBackend.orphans.length + " orphans");
        return parts.join(" · ") + " · " + PackagesBackend.formatSize(PackagesBackend.totalSizeMiB);
    }

    SettingsSection {
        title: "Package manager"
        icon: "inventory_2"

        NavRow {
            label: "Open package manager"
            icon: "inventory_2"
            subtext: root._summary
            onActivated: PackagesBackend.openWorkbench("")
        }

        InfoRow {
            label: "Orphans"
            icon: "delete_sweep"
            visible: Prefs.getValue("packages.warnOrphans") && PackagesBackend.orphans.length > 0
            subtext: PackagesBackend.orphans.length + " packages are installed that nothing depends on: " + PackagesBackend.orphans.join(", ") + ". Open the package manager and pick Orphans to see what removing them would take with them."
        }
    }

    SettingsSection {
        title: "Settings"
        icon: "tune"

        // MOVED here from the Services page (quick task 260828-75k) rather
        // than duplicated — it writes the same services.updatesPollMs key
        // the bar has always read, and it now sits beside the rest of the
        // package settings instead of among the weather and news timers.
        StepperRow {
            label: "Update check"
            subtext: "How often to check for pending package updates (minutes)"
            from: 5
            to: 240
            stepSize: 5
            value: Prefs.getValue("services.updatesPollMs") / 60000
            onMoved: v => Prefs.setValue("services.updatesPollMs", Math.round(v) * 60000)
        }

        ToggleRow {
            label: "Include AUR updates"
            subtext: "Also run paru -Qua, so AUR packages are counted. Off, the count covers repo packages only — which is what the bar did before this was added, and it under-reported."
            checked: Prefs.getValue("packages.includeAur")
            onToggled: checked => Prefs.setValue("packages.includeAur", checked)
        }

        ToggleRow {
            label: "Warn about orphans"
            subtext: "Show a row above when packages are installed that nothing depends on."
            checked: Prefs.getValue("packages.warnOrphans")
            onToggled: checked => Prefs.setValue("packages.warnOrphans", checked)
        }

        // The same bar.entries.updates key the Bar page's own entry list
        // writes — one preference reachable from either page, not a second
        // one to keep in sync.
        ToggleRow {
            label: "Show the updates pill on the bar"
            subtext: "The pill appears only when something is pending, and opens a card listing it."
            checked: Prefs.getValue("bar.entries.updates")
            onToggled: checked => Prefs.setValue("bar.entries.updates", checked)
        }

        // An InfoRow, NOT a toggle. There is no in-shell transaction path
        // to switch to, so a switch here would be a control that does
        // nothing — see PackagesBackend's header for why terminal handoff
        // is the design rather than a limitation.
        InfoRow {
            label: "How changes are applied"
            icon: "terminal"
            subtext: "Installing, removing and upgrading always open " + Prefs.getValue("apps.terminal") + " on the real paru command, so pacman prints what it will do and asks before doing it. Nothing here runs as root, and no polkit rule is installed for packages."
        }
    }
}
