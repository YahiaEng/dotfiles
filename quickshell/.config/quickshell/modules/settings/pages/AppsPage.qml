// modules/settings/pages/AppsPage.qml — page index 10, the root of the
// Apps StackPage (quick task 260825-wj2 Task 2, D-2/D-6/D-7). The mechanism's
// first real path: StackPage -> PageBase.isSubPage -> SettingsState ->
// RowIndex + the pair-keyed gate -> Prefs -> the launcher's own filter.
//
// Default-app rows follow D-6/D-7: Terminal and Audio are real SelectRows
// (this tree's own measured consumers exist — SystemCapsule.qml's update
// action, SessionPage.qml's idle-overrides editor, MenuTree.qml's Setup ▸
// Audio entry), while Media playback and File manager stay honest InfoRows
// — nothing in this shell launches a media player, and folder links already
// go through xdg-open (`FilesMode.qml:39`), the desktop-wide default, not
// this window's to set. `SelectRow` stands in for Caelestia's `PopupRow`
// (D-7) — this tree already has a counted, working dropdown-pill row and
// adding a second popup primitive would only grow settings-index-check's
// row-primitive alternation for no reason.
import QtQuick
import Quickshell
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Apps"

    // Favourites sort to the top of BOTH default-app pickers' own model,
    // exactly as the reference's own popup does (D-7) — not a duplicate
    // filter/sort, the SAME favourites array `AppInfoPage.qml`'s toggles
    // write, read here only for display order.
    readonly property var _sortedApps: {
        var all = DesktopEntries.applications.values.filter(function (e) {
            return !e.noDisplay;
        });
        var favs = Prefs.getValue("launcher.favouriteApps");
        var favSet = {};
        for (var i = 0; i < favs.length; i++)
            favSet[favs[i]] = true;
        return all.slice().sort(function (a, b) {
            var fa = favSet[a.id] ? 1 : 0;
            var fb = favSet[b.id] ? 1 : 0;
            if (fa !== fb)
                return fb - fa;
            return a.name.localeCompare(b.name);
        });
    }
    readonly property var _appModel: root._sortedApps.map(function (e) {
        return {
            value: e.id,
            display: e.name
        };
    })

    SettingsSection {
        title: "Default applications"
        icon: "apps"

        SelectRow {
            label: "Terminal"
            subtext: "Used by the update action, the idle-overrides editor and any other shell-launched terminal"
            model: root._appModel
            currentValue: Prefs.getValue("apps.terminal")
            onSelected: (value) => Prefs.setValue("apps.terminal", value)
        }
        SelectRow {
            label: "Audio"
            subtext: "Opened by the launcher's Setup ▸ Audio entry"
            model: root._appModel
            currentValue: Prefs.getValue("apps.audio")
            onSelected: (value) => Prefs.setValue("apps.audio", value)
        }
        InfoRow {
            label: "Media playback"
            subtext: "Nothing in this shell launches a media player, so there is no command to set here."
        }
        InfoRow {
            label: "File manager"
            subtext: "Folder links already open through xdg-open, the desktop-wide default — not set from this window."
        }
    }

    SettingsSection {
        title: "Library"
        icon: "list"

        NavRow {
            label: "All apps"
            subtext: "Browse installed apps, set favourites and hidden"
            onActivated: root.sState.openSubPage(1)
        }
    }
}
