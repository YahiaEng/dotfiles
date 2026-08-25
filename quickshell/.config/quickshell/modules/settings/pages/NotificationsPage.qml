// modules/settings/pages/NotificationsPage.qml — page index 8 of the
// ten-page layout (quick-260821-6z1 Task 9, D-01 bundle 2/D-02). Carries
// the Do not disturb ToggleRow moved out of ShellBehaviourPage.qml (now
// retired) — a second VIEW of NotifServer's own already-persisted DND
// state, never a new writer (D-04). Every OTHER knob on this page is
// shell-internal and goes to Prefs.
//
// N-06 (measured this task, not anticipated by RESEARCH.md) — Weather
// and News "source" rows are InfoRows, not pickers. `WeatherBackend`/
// `NewsBackend` are NOT singletons: each is ONE shared instance owned by
// shell.qml (`weatherBackendInstance`/`newsBackendInstance`) and threaded
// down to its one real consumer via an explicit property
// (`NotifCentre.newsBackend`, `WeatherTab.weatherBackend`) — the exact
// same instance-threading pattern Task 13 uses for AudioBackend, which
// THIS task's file list does not budget for (no shell.qml/
// SettingsState.qml/Settings.qml edit here). `weather.json` is also
// explicitly documented "hand-editable only" (WeatherBackend.qml's own
// header) with no writer function at all — adding one would be a second
// writer this task has no mandate to add. News sources DO have a real
// editor already (NewsBackend.addSource/removeSource/renameSource), but
// it lives in the notification centre's own News pane — this row points
// there rather than duplicating that machinery.
import QtQuick
import Quickshell
import Quickshell.Io
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

    // ── Popup timeout, position, limits ─────────────────────────────────
    SettingsSection {
        id: popupsSection
        title: "Popups"
        icon: "notifications"

        function _timeoutOptions() {
            var vals = [1500, 2000, 3000, 5000, 8000, 10000, 15000];
            return vals.map(function (v) {
                return { value: String(v), display: (v / 1000) + "s" };
            });
        }

        SelectRow {
            label: "Popup timeout"
            subtext: "Normal-urgency notifications auto-dismiss after this long"
            model: popupsSection._timeoutOptions()
            currentValue: Prefs.getValue("notifs.popupTimeoutMs").toString()
            onSelected: (value) => Prefs.setValue("notifs.popupTimeoutMs", parseInt(value, 10))
        }
        SelectRow {
            label: "Low-priority timeout"
            subtext: "Low-urgency notifications auto-dismiss after this long"
            model: popupsSection._timeoutOptions()
            currentValue: Prefs.getValue("notifs.lowPriorityTimeoutMs").toString()
            onSelected: (value) => Prefs.setValue("notifs.lowPriorityTimeoutMs", parseInt(value, 10))
        }
        // Operator fix wave finding 4: plain-language rewrite. Engineering
        // note (kept, not deleted): this is enforced at the notification
        // card's own single dismiss-timer site, so it is not a bug and
        // there is no timeout value to expose here.
        InfoRow {
            label: "Critical notifications never auto-dismiss"
            subtext: "Critical notifications stay on screen until you dismiss them — there's no timeout to set."
        }
        SelectRow {
            label: "Popup position"
            subtext: "Which corner popups appear in"
            model: [
                { value: "top-right", display: "Top right" },
                { value: "top-left", display: "Top left" },
                { value: "bottom-right", display: "Bottom right" },
                { value: "bottom-left", display: "Bottom left" }
            ]
            currentValue: Prefs.getValue("notifs.position")
            onSelected: (value) => Prefs.setValue("notifs.position", value)
        }
        SelectRow {
            label: "History limit"
            subtext: "Notification history caps at this many entries, oldest dropped"
            model: [10, 25, 50, 100, 200, 500].map(function (v) { return { value: String(v), display: String(v) }; })
            currentValue: Prefs.getValue("notifs.historyCap").toString()
            onSelected: (value) => Prefs.setValue("notifs.historyCap", parseInt(value, 10))
        }
        SelectRow {
            label: "Max visible popups"
            subtext: "Simultaneous popups before the rest summarise into a single \"+N more\" card"
            model: [1, 2, 3, 4, 5].map(function (v) { return { value: String(v), display: String(v) }; })
            currentValue: Prefs.getValue("notifs.maxVisiblePopups").toString()
            onSelected: (value) => Prefs.setValue("notifs.maxVisiblePopups", parseInt(value, 10))
        }
    }

    // ── OSD ──────────────────────────────────────────────────────────────
    SettingsSection {
        title: "On-screen display"
        icon: "notifications"

        SelectRow {
            label: "OSD duration"
            subtext: "How long the volume/brightness/caps-lock indicator stays on screen"
            model: [500, 800, 1000, 1200, 1500, 2000, 3000].map(function (v) {
                return { value: String(v), display: (v / 1000) + "s" };
            })
            currentValue: Prefs.getValue("osd.hideDelayMs").toString()
            onSelected: (value) => Prefs.setValue("osd.hideDelayMs", parseInt(value, 10))
        }
        SelectRow {
            label: "OSD position"
            subtext: "Which edge the indicator anchors to"
            model: [
                { value: "top", display: "Top" },
                { value: "bottom", display: "Bottom" }
            ]
            currentValue: Prefs.getValue("osd.position")
            onSelected: (value) => Prefs.setValue("osd.position", value)
        }
    }

    // ── Dashboard panels ─────────────────────────────────────────────────
    SettingsSection {
        title: "Dashboard panels"
        icon: "dashboard"

        ToggleRow {
            label: "Clock"
            subtext: "Clock/date hero band"
            checked: Prefs.getValue("dashboard.panels.clock")
            onToggled: (value) => Prefs.setValue("dashboard.panels.clock", value)
        }
        ToggleRow {
            label: "Calendar"
            subtext: "Month grid band"
            checked: Prefs.getValue("dashboard.panels.calendar")
            onToggled: (value) => Prefs.setValue("dashboard.panels.calendar", value)
        }
        ToggleRow {
            label: "Media"
            subtext: "Compact now-playing widget"
            checked: Prefs.getValue("dashboard.panels.media")
            onToggled: (value) => Prefs.setValue("dashboard.panels.media", value)
        }
        ToggleRow {
            label: "Resources"
            subtext: "CPU/memory/storage/battery strip"
            checked: Prefs.getValue("dashboard.panels.resources")
            onToggled: (value) => Prefs.setValue("dashboard.panels.resources", value)
        }
    }

    // ── Content sources — N-06, InfoRows (see file header) ───────────────
    // Weather location moved to Language & region (quick task 260825-wj2
    // Task 6) — its own FileView/weatherCityOverride reader moved with it.
    SettingsSection {
        id: sourcesSection
        title: "Content sources"
        icon: "cloud"

        FileView {
            id: newsSourcesFile
            path: Quickshell.env("HOME") + "/.local/state/theme/news-sources.json"
            watchChanges: true
            onFileChanged: reload()
        }
        readonly property var newsSourceNames: {
            try {
                var obj = JSON.parse(newsSourcesFile.text() || "{}");
                var list = (obj && Array.isArray(obj.sources)) ? obj.sources : [];
                return list.map(function (s) { return s && s.name ? s.name : "?"; });
            } catch (e) {
                return [];
            }
        }

        // Operator fix wave finding 4: plain-language rewrite. Engineering
        // note (kept, not deleted): NewsBackend is not a singleton, so
        // this page has no writer to call — the News pane already owns
        // the real read-modify-write path for this list (N-06).
        InfoRow {
            label: "News sources"
            subtext: (sourcesSection.newsSourceNames.length > 0 ? sourcesSection.newsSourceNames.join(", ") : "None configured") + " — manage sources from the News pane in the notification centre."
        }
    }
}
