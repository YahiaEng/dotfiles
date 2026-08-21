// modules/Prefs.qml — the shell-preferences store (quick-260821-6z1 Task 1,
// D-02, R-1). Copies `NotifServer.qml:617-730`'s write-back idiom
// VERBATIM IN SHAPE: `FileView{watchChanges:false; atomicWrites:true}` +
// manual JSON.parse/JSON.stringify + `Component.onCompleted: reload()`.
// Deliberately NOT `JsonAdapter` + `onAdapterUpdated: writeAdapter()` — that
// idiom appears exactly once tree-wide, in Probe.qml (a diagnostic), and
// `Colours.qml:33` records it was deliberately omitted from both of its own
// FileViews. See RESEARCH.md §1 for the full comparison.
//
// ── `watchChanges: false` consequence (MEMORY
//    live-shell-ignores-disk-state-edits) — stated plainly, per this
//    task's own instruction: a LIVE shell will NOT see a hand-edit to this
//    file. Edit it with the shell stopped, or through the settings window
//    (which round-trips through `setValue()` below, same as the `prefs`
//    IPC surface in shell.qml). `FileView` carries no per-write completion
//    token, only `onSaveFailed` — that absence is exactly why this store is
//    NOT also watched: a watched-and-written store risks a self-triggered
//    reload racing an in-flight edit, and nothing else in this repo does
//    both on the SAME FileView. If a future need for external writes ever
//    appears, adopt `NewsBackend.qml:582-603`'s surgical read-modify-write,
//    not a watched whole-object republish.
//
// Schema (PD-01) — flat top-level namespaces, `"version": 1` from the
// first write, path `~/.local/state/quickshell/prefs.json` (mode
// drwxr-xr-x, already holds this shell's other two state files;
// `~/.local/state/theme/` is drwx------ and is the theme engine's own
// render-target dir — not used here). Every value has a HARDCODED default
// declared in `_defaults` below, keyed by the SAME dotted path `getValue`/
// `setValue` use — a missing prefs.json, or a missing individual key
// inside an existing one, both degrade to exactly today's behaviour.
// Do NOT migrate `bar-orientation`, `motion.json`, `idle-overrides.conf`,
// `overrides.json`, `font-choice` or `icon-theme` into this file (D-04) —
// they stay exactly where they are.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // True once the first load attempt (success OR "never persisted") has
    // settled — `setValue` refuses to write before this, so a first-run
    // write can never race the first read (NotifServer.qml's own
    // `_stateLoaded` guard, same shape).
    property bool _loaded: false

    // The live in-memory tree. Always a plain object (never null/array) —
    // `_loadPrefs()` below enforces that on every load, including the
    // malformed-file path. Reassigned wholesale (never mutated in place)
    // on every `setValue()` call, so the `readonly property` bindings in
    // `getValue()` callers correctly re-evaluate: QML change notification
    // for a `property var` fires on REASSIGNMENT, not on in-place mutation
    // of the object it currently holds.
    property var _data: ({})

    // ── Closed key allowlist (D-02's own instruction) — the ONLY dotted
    //    paths `setValue()` will accept. Every task that adds a new
    //    operator-facing knob extends this array, and `_defaults` below,
    //    in the SAME commit that adds the knob's row. An unknown path is
    //    refused with `console.warn` and no write — a typo cannot grow
    //    junk in the operator's own file. Starts with exactly the three
    //    keys Task 1 wires into Design.qml; later tasks extend it. ───────
    readonly property var _allowedKeys: [
        "notifs.historyCap",
        "notifs.maxVisiblePopups",
        "osd.hideDelayMs"
    ]

    // Hardcoded default per allowlisted key, keyed by the identical dotted
    // path — the literal every consumer used before this store existed.
    // `getValue()` falls back to this when the key is absent OR present
    // with the wrong JS type (the false-is-falsy-footgun guard, done via
    // an explicit `typeof` comparison rather than `||`/`or`, matching
    // `NotifServer.qml:666`'s own discipline — see `getValue()` below).
    readonly property var _defaults: ({
        "notifs.historyCap": 100,
        "notifs.maxVisiblePopups": 3,
        "osd.hideDelayMs": 1200
    })

    // ── Helper functions — ALL declared here, above the FileView and
    //    above Component.onCompleted below (MEMORY
    //    qml-declare-before-construction-time-use: a later-declared
    //    member throws "is not a function" and a fallback chain converts
    //    that into a plausible wrong answer; SettingsState.qml:22-30 and
    //    NewsBackend.qml:85-88 both carry the same standing note). ───────

    // Read a dotted path out of a plain-object tree. Returns `undefined`
    // if any segment along the way is missing or non-object.
    function _lookup(obj, path) {
        var parts = path.split(".");
        var cur = obj;
        for (var i = 0; i < parts.length; i++) {
            if (cur === undefined || cur === null || typeof cur !== "object")
                return undefined;
            cur = cur[parts[i]];
        }
        return cur;
    }

    // Immutable nested set: returns a NEW top-level object with `value`
    // written at `parts`, shallow-copying every object along the path so
    // sibling keys are preserved and the reassignment above (`_data = ...`)
    // is a real reference change QML's change notification can see.
    function _setPath(obj, parts, value) {
        var key = parts[0];
        var rest = parts.slice(1);
        var out = {};
        if (obj && typeof obj === "object") {
            for (var k in obj)
                out[k] = obj[k];
        }
        if (rest.length === 0) {
            out[key] = value;
        } else {
            var child = (obj && typeof obj[key] === "object" && obj[key] !== null && !Array.isArray(obj[key])) ? obj[key] : {};
            out[key] = root._setPath(child, rest, value);
        }
        return out;
    }

    // Public read. Every consumer — Design.qml's readonly properties, a
    // settings row's `currentValue:`, the `prefs` IPC `get()` verb — goes
    // through this one function, never `_data` directly.
    //
    // The false-is-falsy footgun (260820-sqd deviation 6 shipped this bug
    // TWICE in one commit, through Lua's `and/or` and jq's `//`): an
    // explicit `typeof v !== typeof def` type-mismatch guard is used
    // instead of a truthiness test, so a genuinely-stored `false` is
    // returned as `false`, never silently replaced by a truthy default.
    function getValue(path) {
        var def = root._defaults.hasOwnProperty(path) ? root._defaults[path] : undefined;
        var v = root._lookup(root._data, path);
        if (v === undefined)
            return def;
        if (def !== undefined && typeof v !== typeof def)
            return def;
        return v;
    }

    // Public write. Validates against the closed allowlist, refuses any
    // write before the first read has settled, then reassigns `_data`
    // wholesale (never an in-place mutation — see `_data`'s own comment)
    // and persists. Returns true on a real write, false on a refusal —
    // callers (the `prefs` IPC verb, a settings row's error path) can
    // surface the refusal rather than silently doing nothing.
    function setValue(path, value) {
        if (root._allowedKeys.indexOf(path) === -1) {
            console.warn("Prefs: refusing to set unknown key: " + path);
            return false;
        }
        if (!root._loaded) {
            console.warn("Prefs: refusing to set before initial load has settled: " + path);
            return false;
        }
        root._data = root._setPath(root._data, path.split("."), value);
        root._persist();
        return true;
    }

    // List of every allowlisted key, for the `prefs` IPC `keys()` verb.
    function listKeys() {
        return root._allowedKeys.join(",");
    }

    // T-6z1-05 (malformed/hand-edited prefs.json degrades to defaults, not
    // a crash) — parse sits inside try/catch behind an explicit shape
    // check (`typeof obj === "object"`), matching
    // NotifServer.qml/WeatherBackend.qml's own discipline. A non-object
    // (bare array, a scalar, or a JSON.parse failure) all fall through to
    // an empty `_data`, which makes every `getValue()` call return its
    // hardcoded default — exactly today's behaviour.
    function _loadPrefs() {
        root._loaded = true;
        try {
            var raw = prefsFile.text();
            if (!raw || raw.trim().length === 0) {
                root._data = {};
                return;
            }
            var obj = JSON.parse(raw);
            if (obj && typeof obj === "object" && !Array.isArray(obj)) {
                root._data = obj;
            } else {
                console.warn("Prefs: prefs.json is not a JSON object — ignoring, using defaults");
                root._data = {};
            }
        } catch (e) {
            console.warn("Prefs: prefs.json parse failed, using defaults: " + e);
            root._data = {};
        }
    }

    function _persist() {
        if (!root._loaded)
            return;
        var out = {};
        for (var k in root._data)
            out[k] = root._data[k];
        out.version = 1;
        prefsFile.setText(JSON.stringify(out, null, 2));
    }

    FileView {
        id: prefsFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell/prefs.json"
        watchChanges: false
        atomicWrites: true
        printErrors: true
        onLoaded: root._loadPrefs()
        onLoadFailed: (error) => {
            // Never-persisted / first run is the expected state, not an
            // error (WeatherBackend.qml's own cache-miss framing) — every
            // `getValue()` call returns its hardcoded default until the
            // first real write.
            root._loaded = true;
            root._data = {};
        }
        onSaveFailed: (error) => {
            console.log("Prefs: state write failed: " + error);
        }
    }

    Component.onCompleted: prefsFile.reload()
}
