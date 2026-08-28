// modules/appearance/AppearanceBackend.qml — pragma Singleton. The one
// owner of everything this shell knows about the installed icon-theme set,
// the collapsed font-family model and (Task 3) the installable icon-theme
// catalogue (quick task 260828-ah9, D-01).
//
// ── WHY A SINGLETON ───────────────────────────────────────────────────
// Same reason PackagesBackend.qml is one (see its own header): a page is
// destroyed when the operator navigates away, and a component-scoped
// Process dies with its LazyLoader the instant a surface dismisses. FOUR
// surfaces read this backend — Settings > Appearance's two SelectRows,
// the Atelier's Icons/Fonts/Catalogue tabs, the launcher's `icon`/`font`
// word routes and the bar's clock drawer — and they must agree. One
// backend, four readers, never four models.
//
// ── PRIVILEGE: NONE HERE ────────────────────────────────────────────────
// `applyIconTheme`/`applyFont` run the exact `--set` verb the retired
// interactive pickers ran on Enter — a fixed-argv Process, never a
// string-built shell command. The scripts own the state write, the
// VSCodium settings merge and the `theme-apply` re-run through their own
// `_persist_and_apply()` tail (D-03) — this backend never reimplements
// that. Task 3 adds the catalogue install path, which is its own
// privilege story (see that section's header once it lands).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root

    // ═══════════════════════════════════════════════════════════════
    //  Constants
    // ═══════════════════════════════════════════════════════════════

    readonly property string _iconScript: Quickshell.env("HOME") + "/.config/hypr/scripts/icon-theme-picker.sh"
    readonly property string _fontScript: Quickshell.env("HOME") + "/.config/hypr/scripts/font-switcher.sh"

    // M1 — the 12-probe set `--preview` renders, byte-identical to the
    // retired interactive preview's own NAMES array. Kept in one place so
    // a future edit to the probe set only ever needs one file changed.
    readonly property var _PREVIEW_PROBES: ["folder", "user-home", "network-server", "drive-harddisk", "applications-system", "utilities-terminal", "text-x-generic", "image-x-generic", "audio-x-generic", "video-x-generic", "package-x-generic", "preferences-system"]

    // ═══════════════════════════════════════════════════════════════
    //  How every surface asks for the Atelier — Task 2 (D-01). The
    //  Atelier is a TYPE mounted once in shell.qml, not a singleton, so
    //  no other file can reach it directly. Rather than thread a handle
    //  through the launcher's menu tree and the bar's clock drawer, each
    //  of them raises this on the backend they all already hold, and
    //  shell.qml — which owns the one instance — connects it. `tab` may
    //  be empty, meaning "just open on whatever tab was left open".
    //  Mirrors PackagesBackend.openWorkbenchRequested's exact shape.
    // ═══════════════════════════════════════════════════════════════

    signal openAtelierRequested(string tab)

    function openAtelier(tab: string): void {
        root.openAtelierRequested(tab || "");
    }

    // ═══════════════════════════════════════════════════════════════
    //  Icon themes — observable state
    // ═══════════════════════════════════════════════════════════════

    property var iconThemes: []
    property bool iconThemesProbed: false
    property bool iconApplying: false

    FileView {
        id: iconThemeStateFile
        path: Quickshell.env("HOME") + "/.local/state/theme/icon-theme"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string iconThemeName: (iconThemeStateFile.text() || "").trim()

    function refreshIconThemes(): void {
        if (!iconThemesProc.running) {
            iconThemesWatchdog.restart();
            iconThemesProc.running = true;
        }
    }

    function applyIconTheme(name: string): void {
        root.iconApplying = true;
        iconApplyWatchdog.restart();
        iconApplyProc.command = [root._iconScript, "--set", name];
        iconApplyProc.running = true;
    }

    Timer {
        id: iconThemesWatchdog
        interval: 5000
        onTriggered: {
            if (iconThemesProc.running)
                iconThemesProc.running = false;
        }
    }
    Process {
        id: iconThemesProc
        running: false
        command: [root._iconScript, "--list"]
        stdout: StdioCollector {
            id: iconThemesCollector
        }
        onExited: (code, status) => {
            iconThemesWatchdog.stop();
            if (code === 0)
                root.iconThemes = iconThemesCollector.text.split("\n").map(l => l.trim()).filter(l => l.length > 0);
            root.iconThemesProbed = true;
        }
    }

    Timer {
        id: iconApplyWatchdog
        interval: 5000
        onTriggered: {
            if (iconApplyProc.running)
                iconApplyProc.running = false;
        }
    }
    Process {
        id: iconApplyProc
        running: false
        command: ["true"]
        onExited: (code, status) => {
            iconApplyWatchdog.stop();
            root.iconApplying = false;
            if (code !== 0)
                console.warn("AppearanceBackend: icon-theme-picker.sh --set failed (exit " + code + ")");
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  Icon previews — M1: 22px, never 48. Queued single-flight, one
    //  `--preview` Process at a time, cached per theme name so a repaint
    //  of the Icons tab never re-shells out for a theme already asked
    //  about.
    // ═══════════════════════════════════════════════════════════════

    property var _previewCache: ({})
    property var _previewQueue: []
    property string _previewRunningTheme: ""

    // Returns the cached probe rows for `theme` — `[{probe, path}]`, where
    // `path` is `"-"` for a probe that resolved in no size under any name
    // in its chain (M3: a miss is shown, not hidden). Returns `[]` and
    // queues a fetch on the first ask; the caller re-reads once the
    // backend's `_previewCache` changes (a QML property, so any binding
    // reading `previewFor()` re-evaluates automatically).
    function previewFor(theme: string): var {
        if (!theme)
            return [];
        if (root._previewCache.hasOwnProperty(theme))
            return root._previewCache[theme];
        root._queuePreview(theme);
        return [];
    }

    function _queuePreview(theme) {
        if (root._previewRunningTheme === theme)
            return;
        if (root._previewQueue.indexOf(theme) >= 0)
            return;
        var q = root._previewQueue.slice();
        q.push(theme);
        root._previewQueue = q;
        root._pumpPreviewQueue();
    }

    function _pumpPreviewQueue() {
        if (root._previewRunningTheme !== "")
            return;
        if (root._previewQueue.length === 0)
            return;
        var next = root._previewQueue[0];
        root._previewQueue = root._previewQueue.slice(1);
        root._previewRunningTheme = next;
        previewWatchdog.restart();
        previewProc.command = [root._iconScript, "--preview", next, "22"];
        previewProc.running = true;
    }

    Timer {
        id: previewWatchdog
        interval: 5000
        onTriggered: {
            if (previewProc.running)
                previewProc.running = false;
        }
    }
    Process {
        id: previewProc
        running: false
        command: ["true"]
        stdout: StdioCollector {
            id: previewCollector
        }
        onExited: (code, status) => {
            previewWatchdog.stop();
            var theme = root._previewRunningTheme;
            root._previewRunningTheme = "";
            if (theme !== "") {
                var rows = [];
                if (code === 0) {
                    var lines = (previewCollector.text || "").split("\n");
                    for (var i = 0; i < lines.length; ++i) {
                        if (lines[i].length === 0)
                            continue;
                        var parts = lines[i].split("\t");
                        if (parts.length === 2)
                            rows.push({
                                probe: parts[0],
                                path: parts[1]
                            });
                    }
                }
                var cache = {};
                for (var k in root._previewCache)
                    cache[k] = root._previewCache[k];
                cache[theme] = rows;
                root._previewCache = cache;
            }
            root._pumpPreviewQueue();
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  Fonts — observable state
    // ═══════════════════════════════════════════════════════════════

    property var rawFonts: []
    property bool rawFontsProbed: false
    property bool fontApplying: false

    FileView {
        id: fontChoiceFile
        path: Quickshell.env("HOME") + "/.local/state/theme/font-choice"
        watchChanges: true
        onFileChanged: reload()
    }
    // Fallback source when font-choice is absent or empty — the exact
    // field AppearancePage read before this backend existed, so the
    // displayed value can never go blank during the changeover.
    FileView {
        id: kittyFontFile
        path: Quickshell.env("HOME") + "/.local/state/theme/kitty-font.conf"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string activeFontRaw: {
        var v = (fontChoiceFile.text() || "").trim();
        if (v.length > 0)
            return v;
        var lines = (kittyFontFile.text() || "").split("\n");
        for (var i = 0; i < lines.length; ++i) {
            var m = lines[i].match(/^font_family\s+(.+)$/);
            if (m)
                return m[1].trim();
        }
        return "";
    }

    function refreshFonts(): void {
        if (!fontsProc.running) {
            fontsWatchdog.restart();
            fontsProc.running = true;
        }
    }

    function applyFont(rawName: string): void {
        root.fontApplying = true;
        fontApplyWatchdog.restart();
        fontApplyProc.command = [root._fontScript, "--set", rawName];
        fontApplyProc.running = true;
    }

    Timer {
        id: fontsWatchdog
        interval: 5000
        onTriggered: {
            if (fontsProc.running)
                fontsProc.running = false;
        }
    }
    Process {
        id: fontsProc
        running: false
        command: [root._fontScript, "--list"]
        stdout: StdioCollector {
            id: fontsCollector
        }
        onExited: (code, status) => {
            fontsWatchdog.stop();
            if (code === 0)
                root.rawFonts = fontsCollector.text.split("\n").map(l => l.trim()).filter(l => l.length > 0);
            root.rawFontsProbed = true;
        }
    }

    Timer {
        id: fontApplyWatchdog
        interval: 5000
        onTriggered: {
            if (fontApplyProc.running)
                fontApplyProc.running = false;
        }
    }
    Process {
        id: fontApplyProc
        running: false
        command: ["true"]
        onExited: (code, status) => {
            fontApplyWatchdog.stop();
            root.fontApplying = false;
            if (code !== 0)
                console.warn("AppearanceBackend: font-switcher.sh --set failed (exit " + code + ")");
        }
    }

    // ── The M2 collapse ────────────────────────────────────────────────
    // 39 raw names = 13 families x {`Nerd Font`, `Nerd Font Mono`,
    // `Nerd Font Propo`}. Measured: `Nerd Font` and `Nerd Font Mono` are
    // metrically identical on every probed advance width — only `Propo`
    // differs, and only on icon glyphs. So this offers 13 families x 2
    // SPACING BEHAVIOURS, never 39 rows and never a third "Nerd Font
    // alone" cut: "mono" resolves to `<family> Nerd Font Mono` when that
    // exact name is installed, else falls back to `<family> Nerd Font` —
    // the same font by measurement, just whichever name fontconfig
    // actually has. A raw name that does not match the
    // `<family> Nerd Font[ Mono| Propo]` shape passes through unchanged
    // as its own single-behaviour row, so a non-Nerd family can never
    // disappear from the model.
    readonly property var fontFamilies: {
        var raw = root.rawFonts;
        var setMap = {};
        for (var i = 0; i < raw.length; ++i)
            setMap[raw[i]] = true;

        var familyNames = [];
        var seenFamily = {};
        var passthroughRows = [];

        for (var j = 0; j < raw.length; ++j) {
            var name = raw[j];
            var m = name.match(/^(.*) Nerd Font(| Mono| Propo)$/);
            if (!m) {
                passthroughRows.push({
                    family: name,
                    behaviour: "",
                    rawName: name,
                    active: name === root.activeFontRaw
                });
                continue;
            }
            var fam = m[1];
            if (!seenFamily[fam]) {
                seenFamily[fam] = true;
                familyNames.push(fam);
            }
        }
        familyNames.sort();

        var rows = [];
        for (var k = 0; k < familyNames.length; ++k) {
            var f = familyNames[k];
            var monoName = setMap[f + " Nerd Font Mono"] ? (f + " Nerd Font Mono") : (setMap[f + " Nerd Font"] ? (f + " Nerd Font") : null);
            var propoName = setMap[f + " Nerd Font Propo"] ? (f + " Nerd Font Propo") : null;
            if (monoName)
                rows.push({
                    family: f,
                    behaviour: "mono",
                    rawName: monoName,
                    active: monoName === root.activeFontRaw
                });
            if (propoName)
                rows.push({
                    family: f,
                    behaviour: "propo",
                    rawName: propoName,
                    active: propoName === root.activeFontRaw
                });
        }
        return rows.concat(passthroughRows);
    }

    // ═══════════════════════════════════════════════════════════════
    Component.onCompleted: {
        root.refreshIconThemes();
        root.refreshFonts();
    }
}
