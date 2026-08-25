// modules/settings/pages/AllAppsPage.qml — sub-page 1 of the Apps
// StackPage (quick task 260825-wj2 Task 2, D-5). Every non-hidden desktop
// entry, alphabetical, one NavRow per app drilling into AppInfoPage.
//
// The row's label is the STATIC string "App", never the app's own name —
// RowIndex's jump key is an exact label match, and a per-item dynamic label
// would collide with itself across every Repeater instance, the same
// reasoning AudioPage.qml's per-app mixer already documents for its own
// Repeater. Deviation from the vendored reference (documented in the
// SUMMARY): the reference's own delegate paints an icon and a filled
// `favorite` glyph beside the name; this tree's `NavRow` primitive has no
// icon/decoration slot (label + subtext + chevron only, `common/NavRow.qml`),
// and NavRow is deliberately NOT in this task's `<files>` list — editing a
// primitive this many OTHER pages already depend on is a structural change
// out of this task's scope. Favourite status is instead folded into the
// subtext text itself (a "★" prefix), and the app icon is not shown here at
// all — it IS shown on AppInfoPage's own header, once a single app is
// selected rather than 52 Repeater instances each loading one.
import QtQuick
import Quickshell
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "All apps"
    isSubPage: true

    readonly property var _apps: {
        var all = DesktopEntries.applications.values.filter(function (e) {
            return !e.noDisplay;
        });
        return all.slice().sort(function (a, b) {
            return a.name.localeCompare(b.name);
        });
    }
    readonly property var _favourites: Prefs.getValue("launcher.favouriteApps")

    function _isFavourite(id) {
        return root._favourites.indexOf(id) !== -1;
    }

    SettingsSection {
        title: "Installed apps"
        icon: "apps"

        Repeater {
            model: root._apps

            NavRow {
                id: appRow
                required property var modelData

                readonly property string _extra: (appRow.modelData.comment || appRow.modelData.genericName) || ""

                // STATIC label (see this file's own header) — the real
                // per-app name and detail ride as subtext instead.
                label: "App"
                subtext: (root._isFavourite(appRow.modelData.id) ? "★ " : "") + appRow.modelData.name + (appRow._extra.length > 0 ? " — " + appRow._extra : "")
                onActivated: {
                    root.sState.selectedApp = appRow.modelData;
                    root.sState.openSubPage(2);
                }
            }
        }
        InfoRow {
            visible: root._apps.length === 0
            label: "No apps found"
            subtext: "No installed, non-hidden desktop entries were found on this host."
        }
    }
}
