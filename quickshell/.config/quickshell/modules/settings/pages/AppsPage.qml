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
//
// Category-filtered, executable-storing pickers (quick-260826-1n9 Task 6,
// F5, D-6) — the picker used to list all 52 non-hidden apps under both
// "Terminal" and "Audio" and store `e.id` (a desktop-entry id, e.g.
// "kitty.desktop"), a value none of the four real consumers
// (SystemCapsule.qml, SessionPage.qml, UpdatesPage.qml, MenuTree.qml) can
// exec — all four exec the stored value DIRECTLY, two of them inside an
// argv array. Terminal now filters on the `TerminalEmulator` category
// (measured: exactly two entries on this host, kitty.desktop and
// kitty-open.desktop) and Audio on Audio/AudioVideo/Mixer (measured: six
// — mpv, qv4l2, qvidcap, spotify, vlc, pavucontrol). Both store an
// EXECUTABLE token via `_exe()`, matching `Prefs`' own defaults
// ("kitty"/"pavucontrol").
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
    // ── Category / executable normalisers ────────────────────────────────
    // Both defensive by MEASUREMENT, not assumption:
    // `quickshell-core.qmltypes` declares `DesktopEntry.categories` and
    // `.command` with the surface tag `type: "QString"`, but ALSO
    // `isList: true` on both — strong static evidence they ARE list
    // properties at the QML/JS boundary (matching Quickshell's own docs),
    // not the `;`-joined strings the bare `QString` tag alone would
    // suggest. That reading could not be fully confirmed with a live probe
    // (no `qml6` probe is safe on this host — it crashes the compositor),
    // so both functions below still accept EITHER shape: correct either
    // way, and free once written.
    function _cats(e) {
        var raw = e.categories;
        var arr = Array.isArray(raw) ? raw : String(raw || "").split(";");
        var out = [];
        for (var i = 0; i < arr.length; i++) {
            var c = String(arr[i]).trim();
            if (c.length > 0)
                out.push(c);
        }
        return out;
    }

    // Returns the executable token, never a whole `Exec=` line: prefers
    // `command[0]` when `command` is a non-empty array; otherwise takes
    // `execString || command` as a string, splits on whitespace, drops
    // `%`-prefixed field codes and any `-`-leading flag, and returns the
    // first survivor. Measured need: `vlc` is `Exec=/usr/bin/vlc
    // --started-from-file %U` and `kitty-open` is `Exec=kitty +open %U` —
    // both must reduce to a single bare token an argv array can exec.
    function _exe(e) {
        var cmd = e.command;
        if (Array.isArray(cmd) && cmd.length > 0 && String(cmd[0]).length > 0)
            return String(cmd[0]);
        var raw = String(e.execString || e.command || "");
        var tokens = raw.split(/\s+/).filter(function (t) {
            return t.length > 0;
        });
        for (var i = 0; i < tokens.length; i++) {
            var t = tokens[i];
            if (t.charAt(0) === "%" || t.charAt(0) === "-")
                continue;
            return t;
        }
        return "";
    }

    // Filters `_sortedApps` by `predicate(categories)`, drops any entry
    // whose `_exe()` is empty (an unusable choice is worse than a shorter
    // list), and NEVER offers an empty menu: if the filter yields nothing,
    // or the currently-stored value isn't in the filtered set (a
    // hand-edited prefs.json, or an uninstalled app), a synthetic entry
    // for the current value is added so the row still shows what is
    // configured and a `SelectRow` never renders a blank pill.
    function _filteredModel(predicate, currentValue) {
        var out = [];
        for (var i = 0; i < root._sortedApps.length; i++) {
            var e = root._sortedApps[i];
            if (!predicate(root._cats(e)))
                continue;
            var exe = root._exe(e);
            if (exe.length === 0)
                continue;
            out.push({
                value: exe,
                display: e.name
            });
        }
        var hasCurrent = false;
        for (var j = 0; j < out.length; j++) {
            if (out[j].value === currentValue) {
                hasCurrent = true;
                break;
            }
        }
        if (!hasCurrent && currentValue.length > 0)
            out.unshift({
                value: currentValue,
                display: currentValue
            });
        if (out.length === 0)
            out.push({
                value: currentValue,
                display: currentValue.length > 0 ? currentValue : "(none)"
            });
        return out;
    }

    readonly property var _terminalModel: root._filteredModel(function (cats) {
        return cats.indexOf("TerminalEmulator") !== -1;
    }, Prefs.getValue("apps.terminal"))

    readonly property var _audioModel: root._filteredModel(function (cats) {
        return cats.indexOf("Audio") !== -1 || cats.indexOf("AudioVideo") !== -1 || cats.indexOf("Mixer") !== -1;
    }, Prefs.getValue("apps.audio"))

    SettingsSection {
        title: "Default applications"
        icon: "apps"

        SelectRow {
            label: "Terminal"
            icon: "terminal"
            subtext: "The executable used by the update action, the idle-overrides editor and any other shell-launched terminal"
            model: root._terminalModel
            currentValue: Prefs.getValue("apps.terminal")
            onSelected: (value) => Prefs.setValue("apps.terminal", value)
        }
        SelectRow {
            label: "Audio"
            icon: "volume_up"
            subtext: "The executable opened by the launcher's Setup ▸ Audio entry"
            model: root._audioModel
            currentValue: Prefs.getValue("apps.audio")
            onSelected: (value) => Prefs.setValue("apps.audio", value)
        }
        InfoRow {
            label: "Media playback"
            icon: "play_circle"
            subtext: "Nothing in this shell launches a media player, so there is no command to set here."
        }
        InfoRow {
            label: "File manager"
            icon: "folder"
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
