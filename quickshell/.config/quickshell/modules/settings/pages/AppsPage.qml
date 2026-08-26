// modules/settings/pages/AppsPage.qml — page index 10, the root of the
// Apps StackPage (quick task 260825-wj2 Task 2, D-2/D-6/D-7). The mechanism's
// first real path: StackPage -> PageBase.isSubPage -> SettingsState ->
// RowIndex + the pair-keyed gate -> Prefs -> the launcher's own filter.
//
// Default-app rows follow D-6/D-7: Terminal and Audio are real SelectRows
// (this tree's own measured consumers exist — SystemCapsule.qml's update
// action, SessionPage.qml's idle-overrides editor, MenuTree.qml's Setup ▸
// Audio entry). Media playback and File manager (quick-260826-437 Task 2,
// D-7/D-8) are now ALSO real SelectRows — the desktop-wide default via
// `xdg-mime default`, not a shell-internal setting, which is exactly what
// `xdg-open` consults and what `FilesMode.qml:39` already shells to.
// `SelectRow` stands in for Caelestia's `PopupRow` (D-7) — this tree
// already has a counted, working dropdown-pill row and adding a second
// popup primitive would only grow settings-index-check's row-primitive
// alternation for no reason.
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
//
// Opposite value types, on purpose, in the SAME section (D-4): Terminal and
// Audio store a bare EXECUTABLE because four consumers exec the value
// directly in argv arrays; Media playback and File manager store a
// DESKTOP-ENTRY ID because `xdg-mime default` accepts nothing else — never
// apply `_exe()` to the new rows, and never make `_filteredModel()`
// polymorphic to cover both (`_mimeModel()` below is a second, separate
// helper).
//
// Current value = `xdg-mime query default`, NOT `gio mime`'s first line
// (D-7) — measured on this host, they disagree: `xdg-mime query default
// inode/directory` reads `codium.desktop` while `gio mime inode/directory`
// reads `kitty-open.desktop`. `XDG_CURRENT_DESKTOP=Hyprland` has no
// `detectDE` case in `/usr/bin/xdg-open`, so it falls to `DE=generic` ->
// `open_generic()` -> `open_generic_xdg_mime`, which itself calls
// `xdg-mime query default` — that is the authoritative read for what
// actually opens a file on this host.
//
// -- Follow-up (operator-reported, same day) ------------------------------
// Three defects in the first cut of these rows: one cause, two naming.
//
// 1. `_mimeModel` compared `e.id + ".desktop"` against gio's registered
//    ids. Correct ONLY if `DesktopEntry.id` never carries the suffix
//    itself -- unverifiable statically here (no `qml6` probe is safe on
//    this host) and silently fatal if wrong: every comparison misses, the
//    filtered list empties, and the not-in-list fallback then shows the
//    current default ALONE. It reads as a content bug ("why is VLC
//    missing", "why is codium a file manager") when in fact nothing ever
//    matched. `_idKey()` now strips the suffix on BOTH sides, so the
//    comparison is right either way rather than betting on one shape.
// 2. The fallback entry was unlabelled, so "your current setting,
//    unrecognised" was indistinguishable from a genuine candidate -- which
//    is precisely how `codium.desktop` appeared under "File manager" while
//    being neither registered for `inode/directory` (measured: only
//    kitty-open, thunar and yazi are) nor carrying a FileManager category
//    (it is Utility;Development;IDE). It carries a suffix now.
// 3. "File manager" named the wrong concept for what the row governs.
//    Split in two: "File explorer" keeps `inode/directory` + the
//    FileManager category (measured: thunar, yazi), and a new "File
//    editor" row takes the plain-text family + TextEditor/IDE/Development
//    (measured: codium, nvim, vim -- libreoffice-writer registers for
//    text/plain but is Office/WordProcessor and is correctly dropped).
//    The explorer row keeps `indexLabel: "File manager"` so RowIndex and
//    settings-index-check CHECK B stay stable across the rename.
import QtQuick
import Quickshell
import Quickshell.Io
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

    // ── Default-app pickers (D-7/D-8) ──────────────────────────────────────
    // Declared constants, never inline literals — `_fmTypes` is the one
    // type `xdg-open` resolves a folder to (measured: both candidate
    // entries declare exactly `MimeType=inode/directory`, nothing else).
    // `_mediaTypes` is the seventeen types measured on this host as
    // registered to both mpv and vlc, eight video then nine audio.
    readonly property var _fmTypes: ["inode/directory"]
    readonly property var _mediaTypes: ["video/mp4", "video/x-matroska", "video/webm", "video/quicktime", "video/x-msvideo", "video/mpeg", "video/x-flv", "video/ogg", "audio/mpeg", "audio/flac", "audio/ogg", "audio/x-vorbis+ogg", "audio/x-wav", "audio/mp4", "audio/aac", "audio/opus", "audio/x-m4a"]
    // `_editorTypes` — the plain-text family a "file editor" default
    // actually governs. Kept deliberately narrow: setting an editor as the
    // handler for every text/* subtype would capture things like
    // `text/html`, which belongs to a browser.
    readonly property var _editorTypes: ["text/plain", "text/x-csrc", "text/x-chdr", "text/x-c++src", "text/x-python", "text/x-shellscript", "text/markdown", "application/json", "application/x-yaml", "text/x-log"]
    // The representative type each row reads its current value and its
    // candidate list from. `video/mp4` specifically — measured, registered
    // to mpv and vlc ONLY, while webm/ogg/flac/vorbis+ogg also list
    // `zen.desktop` (a browser is not a media-playback default).
    readonly property string _fmProbeType: "inode/directory"
    readonly property string _mediaProbeType: "video/mp4"
    readonly property string _editorProbeType: "text/plain"

    // Live-read state, filled by the four bounded Process children below —
    // bounded and page-scoped (D-8), the same shape and reasoning this
    // page's own `repoProcess`/`aurProcess` neighbours in UpdatesPage.qml
    // already document. Any non-zero exit or unparseable output degrades
    // to an empty list/string, never a distinct error state.
    property string _fmCurrent: ""
    property var _fmRegistered: []
    property string _mediaCurrent: ""
    property var _mediaRegistered: []
    property string _editorCurrent: ""
    property var _editorRegistered: []

    // Optimistic-override properties — set the instant a row's own
    // `onSelected` fires, alongside the write. No Timer, no re-query, no
    // race: the override wins until this page is next created, at which
    // point the `xdg-mime query default` probe is truth again.
    property string _fmChosen: ""
    property string _mediaChosen: ""
    property string _editorChosen: ""

    // Parses the `Registered applications:` block out of `gio mime`'s own
    // output — the ONLY source for "which apps declare they can open this
    // type" (measured against `/usr/lib/qt6/qml/Quickshell/quickshell-core.qmltypes`:
    // `DesktopEntry` exposes no MIME field at all). Anchored on BOTH exact
    // heading lines; if either is absent, yields an empty list and lets
    // the model's own never-empty guard fall back, rather than guessing at
    // a format this function did not measure.
    function _parseGioMime(text) {
        var lines = String(text || "").split("\n");
        var start = -1, end = -1;
        for (var i = 0; i < lines.length; i++) {
            if (start === -1 && lines[i].indexOf("Registered applications:") !== -1) {
                start = i;
                continue;
            }
            if (start !== -1 && lines[i].indexOf("Recommended applications:") !== -1) {
                end = i;
                break;
            }
        }
        if (start === -1 || end === -1)
            return [];
        var out = [];
        for (var j = start + 1; j < end; j++) {
            var t = lines[j].trim();
            if (t.length > 0 && t.endsWith(".desktop"))
                out.push(t);
        }
        return out;
    }

    // A second model helper, parallel to `_filteredModel` above but never
    // merged with it (D-4) — registration alone is not enough
    // (`kitty-open.desktop` registers for `inode/directory` but is not a
    // file manager) and category alone is not enough either
    // (`spotify.desktop` carries `Player` but its whole `MimeType=` is
    // `x-scheme-handler/spotify`, unable to open a local file). `value` is
    // `e.id + ".desktop"` (`e.id` itself carries no suffix — Launcher.qml:467
    // appends it). `display` gets a measured, not decorative, suffix:
    // `xdg-open`'s generic path takes the first word of the entry's `Exec`
    // line and runs it directly, ignoring `Terminal=true` — selecting
    // `yazi.desktop` yields no window, so the entry is labelled rather than
    // silently dropped. Same never-empty guard `_filteredModel` already
    // implements.
    // Compare desktop-entry identity WITHOUT depending on whether a given
    // source spells it with the `.desktop` suffix. The previous version
    // compared `e.id + ".desktop"` against gio's output directly, which is
    // correct only if `DesktopEntry.id` never carries the suffix itself —
    // an assumption this file cannot verify statically (runtime QML probes
    // are barred on this host) and which, if wrong, makes EVERY comparison
    // miss. That failure is silent and misreads as a content bug: the
    // filtered list comes out empty, `_mimeModel`'s not-in-list fallback
    // then shows the current default alone, and the row looks like it is
    // "missing VLC" or "offering codium as a file manager" when in fact it
    // never matched anything at all. Normalising both sides removes the
    // assumption instead of betting on it.
    function _idKey(s) {
        var t = String(s || "").trim();
        return t.endsWith(".desktop") ? t.slice(0, -8) : t;
    }

    function _mimeModel(registeredIds, predicate, currentId) {
        var registeredKeys = [];
        for (var r = 0; r < registeredIds.length; r++)
            registeredKeys.push(root._idKey(registeredIds[r]));
        var out = [];
        for (var i = 0; i < root._sortedApps.length; i++) {
            var e = root._sortedApps[i];
            var id = root._idKey(e.id) + ".desktop";
            if (registeredKeys.indexOf(root._idKey(e.id)) === -1)
                continue;
            if (!predicate(root._cats(e)))
                continue;
            out.push({
                value: id,
                display: e.name + (e.runInTerminal ? " (needs a terminal)" : "")
            });
        }
        // Keep the CURRENT default selectable even when it does not pass
        // this row's predicate — otherwise the dropdown would silently
        // show a different app than the one actually in effect. But LABEL
        // it, because an unlabelled fallback entry is indistinguishable
        // from a genuine candidate: that is exactly how `codium.desktop`
        // came to look like a legitimate "File manager" option when it is
        // neither registered for `inode/directory` nor carrying any
        // FileManager category — it was only ever "your current setting,
        // unrecognised", with nothing on screen saying so.
        var hasCurrent = false;
        for (var j = 0; j < out.length; j++) {
            if (root._idKey(out[j].value) === root._idKey(currentId)) {
                hasCurrent = true;
                break;
            }
        }
        if (!hasCurrent && currentId.length > 0)
            out.unshift({
                value: currentId,
                display: currentId + " (current, not a recognised choice)"
            });
        if (out.length === 0)
            out.push({
                value: currentId,
                display: currentId.length > 0 ? currentId + " (current, not a recognised choice)" : "(none found)"
            });
        return out;
    }

    readonly property var _fmModel: root._mimeModel(root._fmRegistered, function (cats) {
        return cats.indexOf("FileManager") !== -1;
    }, root._fmCurrent)

    readonly property var _mediaModel: root._mimeModel(root._mediaRegistered, function (cats) {
        return cats.indexOf("Player") !== -1;
    }, root._mediaCurrent)

    // File EDITOR, not file manager. Measured on this host: `text/plain`
    // registers codium, libreoffice-writer, nvim and vim; the predicate
    // keeps the three that are editors and drops libreoffice-writer, whose
    // categories are Office/WordProcessor. `nvim`/`vim` are Terminal=true
    // and pick up `_mimeModel`'s "(needs a terminal)" suffix.
    readonly property var _editorModel: root._mimeModel(root._editorRegistered, function (cats) {
        return cats.indexOf("TextEditor") !== -1 || cats.indexOf("IDE") !== -1 || cats.indexOf("Development") !== -1;
    }, root._editorCurrent)

    // Four bounded reads (D-8) — never a distinct error state, degrading
    // to empty on any non-zero exit. `xdg-mime query default` is the
    // CURRENT value (this file's own header states why it, not `gio`, is
    // authoritative); `gio mime` is the CANDIDATE list.
    Process {
        id: _fmCurrentProcess
        running: false
        command: ["xdg-mime", "query", "default", root._fmProbeType]
        stdout: StdioCollector {
            id: _fmCurrentCollector
        }
        onExited: (exitCode, exitStatus) => {
            root._fmCurrent = exitCode === 0 ? (_fmCurrentCollector.text || "").trim() : "";
        }
    }

    Process {
        id: _fmRegisteredProcess
        running: false
        command: ["gio", "mime", root._fmProbeType]
        stdout: StdioCollector {
            id: _fmRegisteredCollector
        }
        onExited: (exitCode, exitStatus) => {
            root._fmRegistered = exitCode === 0 ? root._parseGioMime(_fmRegisteredCollector.text) : [];
        }
    }

    Process {
        id: _mediaCurrentProcess
        running: false
        command: ["xdg-mime", "query", "default", root._mediaProbeType]
        stdout: StdioCollector {
            id: _mediaCurrentCollector
        }
        onExited: (exitCode, exitStatus) => {
            root._mediaCurrent = exitCode === 0 ? (_mediaCurrentCollector.text || "").trim() : "";
        }
    }

    Process {
        id: _editorCurrentProcess
        running: false
        command: ["xdg-mime", "query", "default", root._editorProbeType]
        stdout: StdioCollector {
            id: _editorCurrentCollector
        }
        onExited: (exitCode, exitStatus) => {
            root._editorCurrent = exitCode === 0 ? (_editorCurrentCollector.text || "").trim() : "";
        }
    }

    Process {
        id: _editorRegisteredProcess
        running: false
        command: ["gio", "mime", root._editorProbeType]
        stdout: StdioCollector {
            id: _editorRegisteredCollector
        }
        onExited: (exitCode, exitStatus) => {
            root._editorRegistered = exitCode === 0 ? root._parseGioMime(_editorRegisteredCollector.text) : [];
        }
    }

    Process {
        id: _mediaRegisteredProcess
        running: false
        command: ["gio", "mime", root._mediaProbeType]
        stdout: StdioCollector {
            id: _mediaRegisteredCollector
        }
        onExited: (exitCode, exitStatus) => {
            root._mediaRegistered = exitCode === 0 ? root._parseGioMime(_mediaRegisteredCollector.text) : [];
        }
    }

    Component.onCompleted: {
        _fmCurrentProcess.running = true;
        _fmRegisteredProcess.running = true;
        _mediaCurrentProcess.running = true;
        _mediaRegisteredProcess.running = true;
        _editorCurrentProcess.running = true;
        _editorRegisteredProcess.running = true;
    }

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
        SelectRow {
            label: "Media playback"
            icon: "play_circle"
            subtext: "Rebinds all eight video and nine audio types this shell measured to one player, desktop-wide, in a single write — shown value reflects video/mp4's current default."
            model: root._mediaModel
            currentValue: root._mediaChosen || root._mediaCurrent
            onSelected: (value) => {
                root._mediaChosen = value;
                Quickshell.execDetached(["xdg-mime", "default", value].concat(root._mediaTypes));
            }
        }
        SelectRow {
            label: "File explorer"
            indexLabel: "File manager"
            icon: "folder"
            subtext: "Opens folders — sets inode/directory desktop-wide, which xdg-open and this shell's own file links already go through."
            model: root._fmModel
            currentValue: root._fmChosen || root._fmCurrent
            onSelected: (value) => {
                root._fmChosen = value;
                Quickshell.execDetached(["xdg-mime", "default", value].concat(root._fmTypes));
            }
        }
        SelectRow {
            label: "File editor"
            icon: "edit_note"
            subtext: "Opens text and source files — sets the plain-text family desktop-wide. Deliberately excludes text/html, which belongs to a browser."
            model: root._editorModel
            currentValue: root._editorChosen || root._editorCurrent
            onSelected: (value) => {
                root._editorChosen = value;
                Quickshell.execDetached(["xdg-mime", "default", value].concat(root._editorTypes));
            }
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
