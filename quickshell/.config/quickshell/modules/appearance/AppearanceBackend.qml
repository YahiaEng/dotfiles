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

    // Raised the instant a catalogue install (Task 3) hands off to a
    // terminal — `Atelier.qml` listens and releases its
    // HyprlandFocusGrab, exactly mirroring
    // `PackagesBackend.transactionLaunched`: a grab is exclusive, so the
    // terminal launched while it is held would be input-dead.
    signal transactionLaunched(string kind)

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
    //  Catalogue — browse and install new icon themes (Task 3, D-04).
    //
    //  ── PRIVILEGE: NONE HERE, SAME POSTURE AS PackagesBackend ─────────
    //  No `pkexec`, no polkit action, no in-process `sudo`, no
    //  auto-confirm flag. `installCatalogue` charset-checks the name,
    //  re-validates it against the catalogue this backend itself
    //  enumerated, checks the pacman db lock, confirms the package is
    //  real via `pacman -Si`/`<helper> -Si` (the package manager's own
    //  exit code is authoritative — never a bespoke legitimacy
    //  heuristic), snapshots the installed theme-directory set, then
    //  hands the actual install to a terminal with a fixed argv array —
    //  the exact mechanism `PackagesBackend.runTransaction`-shaped calls
    //  use, so pacman/paru print what they will do and ask. The
    //  privileged step is the terminal's, never this process's.
    // ═══════════════════════════════════════════════════════════════

    readonly property string dbLockPath: "/var/lib/pacman/db.lck"
    readonly property var _NAME_RE: /^[a-zA-Z0-9@._+-]+$/

    property var catalogue: []
    property bool catalogueProbed: false
    property bool catalogueRunning: false

    property string _aurHelper: ""
    property bool _aurHelperProbed: false
    property string _repoSearchText: ""
    property string _aurSearchText: ""
    property bool _repoSearchDone: false
    property bool _aurSearchDone: false

    // An append-only log — lives on THIS singleton (not the Atelier
    // window), so it survives the window closing. Reopening the Atelier
    // shows the whole history, per Task 3's own instruction.
    property var installLog: []

    function logLine(level: string, text: string): void {
        var next = root.installLog.slice();
        next.push({
            at: Date.now(),
            level: level,
            text: text
        });
        root.installLog = next;
    }

    function _terminal() {
        return Prefs.getValue("apps.terminal");
    }

    // Ported from icon-theme-picker.sh's own `parse_search_output`
    // grammar verbatim: a `repo/pkgname version [markers]` header line
    // followed by a 4-space-indented description line. `[installed]`
    // (pacman) or `[Installed` (paru) marks installed state.
    function _parseCatalogueBlock(text, sourceKind) {
        var out = [];
        var lines = (text || "").split("\n");
        var pkgname = "";
        var repoToken = "";
        var installed = false;
        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i];
            var m = line.match(/^(\S+)\/(\S+)\s/);
            if (m) {
                repoToken = m[1];
                pkgname = m[2];
                installed = (line.indexOf("[installed") >= 0) || (line.indexOf("[Installed") >= 0);
            } else if (line.indexOf("    ") === 0 && pkgname.length > 0) {
                out.push({
                    name: pkgname,
                    repo: sourceKind === "aur" ? "AUR" : repoToken,
                    description: line.slice(4).trim(),
                    installed: installed,
                    source: sourceKind
                });
                pkgname = "";
            }
        }
        return out;
    }

    // Dedupe by package name, repo winning over AUR, then sort by name —
    // the exact rule the retired script's own awk pipeline enforced.
    function _mergeCatalogue(repoRows, aurRows) {
        var byName = {};
        var order = [];
        var all = repoRows.concat(aurRows);
        for (var i = 0; i < all.length; ++i) {
            var row = all[i];
            var existing = byName[row.name];
            if (!existing) {
                byName[row.name] = row;
                order.push(row.name);
            } else if (row.source === "repo" && existing.source !== "repo") {
                byName[row.name] = row;
            }
        }
        var out = [];
        for (var j = 0; j < order.length; ++j)
            out.push(byName[order[j]]);
        out.sort(function (a, b) {
            return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0);
        });
        return out;
    }

    // Fetched on demand when the Catalogue tab is first opened, never at
    // startup — the repos filter in Workbench sets that precedent for a
    // large on-demand list.
    function refreshCatalogue(): void {
        if (root.catalogueRunning)
            return;
        root.catalogueRunning = true;
        root._repoSearchDone = false;
        root._aurSearchDone = false;
        catalogueWatchdog.restart();
        if (!root._aurHelperProbed) {
            aurHelperProc.running = true;
        } else {
            root._startCatalogueSearches();
        }
    }

    function _startCatalogueSearches() {
        repoSearchProc.running = true;
        if (root._aurHelper.length > 0) {
            aurSearchProc.command = [root._aurHelper, "-Ss", "-a", "icon-theme"];
            aurSearchProc.running = true;
        } else {
            // Absence of an AUR helper is a note in the log, not an
            // error — the same posture icon-theme-picker.sh's own
            // interactive path took.
            root._aurSearchText = "";
            root._aurSearchDone = true;
            root.logLine("info", "No AUR helper (paru/yay) found — showing official-repo results only.");
            root._maybeFinishCatalogue();
        }
    }

    function _maybeFinishCatalogue() {
        if (!root._repoSearchDone || !root._aurSearchDone)
            return;
        catalogueWatchdog.stop();
        var repoRows = root._parseCatalogueBlock(root._repoSearchText, "repo");
        var aurRows = root._aurHelper.length > 0 ? root._parseCatalogueBlock(root._aurSearchText, "aur") : [];
        root.catalogue = root._mergeCatalogue(repoRows, aurRows);
        root.catalogueProbed = true;
        root.catalogueRunning = false;
    }

    Timer {
        id: catalogueWatchdog
        interval: 20000
        onTriggered: {
            if (repoSearchProc.running)
                repoSearchProc.running = false;
            if (aurSearchProc.running)
                aurSearchProc.running = false;
        }
    }

    Process {
        id: aurHelperProc
        running: false
        command: ["sh", "-c", "command -v paru 2>/dev/null || command -v yay 2>/dev/null || true"]
        stdout: StdioCollector {
            id: aurHelperCollector
        }
        onExited: (code, status) => {
            var path = (aurHelperCollector.text || "").trim();
            if (path.length > 0) {
                var parts = path.split("/");
                root._aurHelper = parts[parts.length - 1];
            } else {
                root._aurHelper = "";
            }
            root._aurHelperProbed = true;
            root._startCatalogueSearches();
        }
    }

    Process {
        id: repoSearchProc
        running: false
        command: ["pacman", "-Ss", "icon-theme"]
        stdout: StdioCollector {
            id: repoSearchCollector
        }
        onExited: (code, status) => {
            root._repoSearchText = code === 0 ? (repoSearchCollector.text || "") : "";
            root._repoSearchDone = true;
            root._maybeFinishCatalogue();
        }
    }

    Process {
        id: aurSearchProc
        running: false
        command: ["true"]
        stdout: StdioCollector {
            id: aurSearchCollector
        }
        onExited: (code, status) => {
            root._aurSearchText = code === 0 ? (aurSearchCollector.text || "") : "";
            root._aurSearchDone = true;
            root._maybeFinishCatalogue();
        }
    }

    // ── Install ─────────────────────────────────────────────────────
    property string _pendingInstallName: ""
    property string _pendingInstallSource: ""
    property var _installBefore: []
    property bool _hasInstallSnapshot: false

    function installCatalogue(name: string, source: string): void {
        if (root._pendingInstallName.length > 0) {
            root.logLine("error", "An install is already in progress — wait for it to finish before starting another.");
            return;
        }
        root.logLine("info", "Install requested: " + name + " (" + source + ")");
        // 1. Charset check — defence in depth (the argv arrays below
        //    cannot be shell-injected, no shell is invoked, but a name
        //    that fails this means the parse went wrong).
        if (!root._NAME_RE.test(name)) {
            root.logLine("error", "Refusing to install — '" + name + "' is not a valid package name.");
            return;
        }
        // 2. Re-validate against the catalogue THIS backend actually
        //    enumerated — never free text before a package-manager
        //    invocation.
        var entry = null;
        for (var i = 0; i < root.catalogue.length; ++i) {
            if (root.catalogue[i].name === name && root.catalogue[i].source === source) {
                entry = root.catalogue[i];
                break;
            }
        }
        if (!entry) {
            root.logLine("error", "Refusing to install — '" + name + "' did not resolve to an enumerated catalogue entry.");
            return;
        }
        // Every install — repo or AUR — goes through the resolved AUR
        // helper (`paru`/`yay`), the exact same posture
        // `PackagesBackend.install()` already uses: a helper installs a
        // repo package fine, and this backend never constructs a bespoke
        // `sudo pacman` invocation of its own. If no helper is present,
        // there is nothing this backend can install (PackagesBackend has
        // the identical limitation) — refuse rather than reach for
        // `sudo` as a fallback.
        if (root._aurHelper.length === 0) {
            root.logLine("error", "No AUR helper (paru/yay) available — cannot install any package from here.");
            return;
        }
        root._pendingInstallName = name;
        root._pendingInstallSource = source;
        root.logLine("info", "Checking for a running pacman transaction…");
        dbLockCheckProc.running = true;
    }

    // 3. Refuse if a transaction is already running — starting a second
    //    one is how you get a wall of lock errors in a terminal that
    //    then closes.
    Process {
        id: dbLockCheckProc
        running: false
        command: ["test", "-e", root.dbLockPath]
        onExited: (code, status) => {
            if (code === 0) {
                root.logLine("error", "Refusing to install — a pacman transaction is already running (db lock present).");
                root._pendingInstallName = "";
                root._pendingInstallSource = "";
                return;
            }
            root.logLine("info", "Confirming " + root._pendingInstallName + " in the authoritative database…");
            if (root._pendingInstallSource === "repo")
                existsCheckProc.command = ["pacman", "-Si", root._pendingInstallName];
            else
                existsCheckProc.command = [root._aurHelper, "-Si", root._pendingInstallName];
            existsCheckProc.running = true;
        }
    }

    // 4. Confirm existence in the authoritative database. The package
    //    manager's exit code is authoritative — never a bespoke
    //    legitimacy heuristic.
    Process {
        id: existsCheckProc
        running: false
        command: ["true"]
        onExited: (code, status) => {
            if (code !== 0) {
                root.logLine("error", root._pendingInstallName + " did not resolve to a real " + (root._pendingInstallSource === "repo" ? "repo" : "AUR") + " package.");
                root._pendingInstallName = "";
                root._pendingInstallSource = "";
                return;
            }
            root.logLine("info", "Snapshotting the installed theme-directory set…");
            installSnapshotProc.running = true;
        }
    }

    // 5. Snapshot before the install so the newly-appeared directory can
    //    be diffed out afterward — package name != theme directory name.
    Process {
        id: installSnapshotProc
        running: false
        command: [root._iconScript, "--list"]
        stdout: StdioCollector {
            id: installSnapshotCollector
        }
        onExited: (code, status) => {
            root._installBefore = (installSnapshotCollector.text || "").split("\n").map(l => l.trim()).filter(l => l.length > 0);
            root._hasInstallSnapshot = true;
            var name = root._pendingInstallName;
            var source = root._pendingInstallSource;
            root._pendingInstallName = "";
            root._pendingInstallSource = "";
            // 6. Hand off to a terminal with a fixed argv array — the
            //    IDENTICAL shape PackagesBackend.install() uses
            //    (`[helper, "-S", "--needed", name]`), one code path for
            //    both repo and AUR sources since the helper handles a
            //    repo package fine on its own. Never an auto-confirm
            //    flag: the package manager prints what it will do and
            //    asks.
            var pmArgs = [root._aurHelper, "-S", "--needed", name];
            root.logLine("info", "Handing off to a terminal: " + pmArgs.join(" "));
            Quickshell.execDetached([root._terminal(), "-e"].concat(pmArgs));
            root.transactionLaunched("install-icon-theme");
        }
    }

    // 7. Reconciliation — re-runs --list, diffs against the last
    //    snapshot, and logs the outcome. Called when the Atelier next
    //    opens (AtCatalogueTab.qml's Component.onCompleted) and from a
    //    manual "Re-check" action; a no-op before any install has ever
    //    been attempted this session (nothing to reconcile against).
    function reconcileInstall(): void {
        if (!root._hasInstallSnapshot)
            return;
        reconcileProc.running = true;
    }

    Process {
        id: reconcileProc
        running: false
        command: [root._iconScript, "--list"]
        stdout: StdioCollector {
            id: reconcileCollector
        }
        onExited: (code, status) => {
            var after = (reconcileCollector.text || "").split("\n").map(l => l.trim()).filter(l => l.length > 0);
            var beforeSet = {};
            for (var i = 0; i < root._installBefore.length; ++i)
                beforeSet[root._installBefore[i]] = true;
            var added = [];
            for (var j = 0; j < after.length; ++j)
                if (!beforeSet[after[j]])
                    added.push(after[j]);
            if (added.length === 0) {
                root.logLine("warn", "No new icon-theme directory appeared — installed, but shipped no icon-theme directory.");
            } else if (added.length === 1) {
                root.logLine("success", "New theme detected: " + added[0] + ". Applying it from the Icons tab is one click away.");
            } else {
                root.logLine("info", "Multiple new theme directories appeared: " + added.join(", ") + ". Pick one from the Icons tab.");
            }
            root.iconThemes = after;
            root.iconThemesProbed = true;
            root._installBefore = after;
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  Uninstall — icon themes and fonts (operator round 1, defect 1).
    //
    //  ── PRIVILEGE: NONE HERE, IDENTICAL POSTURE TO INSTALL ABOVE ──────
    //  No pkexec, no polkit action, no in-process sudo, no --noconfirm.
    //  Ownership is resolved via `pacman -Qoq <path>` BEFORE anything is
    //  proposed, so the operator sees every package that will be
    //  affected (the Adwaita two-package case — `adwaita-cursors` AND
    //  `adwaita-icon-theme` — is shown, never auto-picked down to one).
    //  Removal is a literal argv handed to a terminal: `paru -Rs` for an
    //  owned theme/font (mirrors `PackagesBackend.remove()` exactly),
    //  `rm -rvI` for an UNOWNED user-dir copy — `rm`'s own `-I` prompts
    //  once before a recursive removal and keeps the terminal open for
    //  that answer, the same "the tool itself asks" posture pacman/paru
    //  already carry. Never auto-deletes: `confirmUninstall()` only runs
    //  from an explicit operator action on the resolved plan below.
    // ═══════════════════════════════════════════════════════════════

    readonly property string _iconSystemDir: "/usr/share/icons/"
    readonly property string _iconUserDir: Quickshell.env("HOME") + "/.local/share/icons/"

    // The current uninstall PROPOSAL. `null` until a `propose*` call
    // resolves; the UI renders a "Resolving…" state for
    // `kind === "resolving"` so it never shows a stale plan for a
    // different target. Shape: `{ kind, target, forFonts, packages?,
    // path?, active? }` — `kind` is one of `resolving`, `packages`,
    // `userdir`, `missing`, `error`.
    property var uninstallPlan: null

    property string _pendingUninstallIconName: ""
    property string _pendingUninstallFontRaw: ""
    property string _pendingUninstallDirPath: ""

    function proposeUninstallIconTheme(name: string): void {
        if (root._pendingUninstallIconName.length > 0 || root._pendingUninstallFontRaw.length > 0)
            return;
        if (!root._NAME_RE.test(name)) {
            root.uninstallPlan = {
                kind: "error",
                target: name,
                forFonts: false,
                message: "Refused — '" + name + "' is not a safe theme name."
            };
            return;
        }
        root._pendingUninstallIconName = name;
        root.uninstallPlan = {
            kind: "resolving",
            target: name,
            forFonts: false
        };
        iconSystemDirCheckProc.command = ["test", "-d", root._iconSystemDir + name];
        iconSystemDirCheckProc.running = true;
    }

    Process {
        id: iconSystemDirCheckProc
        running: false
        command: ["true"]
        onExited: (code, status) => {
            if (root._pendingUninstallIconName.length === 0)
                return;
            if (code === 0) {
                root._resolveOwnership(root._iconSystemDir + root._pendingUninstallIconName, false);
            } else {
                iconUserDirCheckProc.command = ["test", "-d", root._iconUserDir + root._pendingUninstallIconName];
                iconUserDirCheckProc.running = true;
            }
        }
    }

    Process {
        id: iconUserDirCheckProc
        running: false
        command: ["true"]
        onExited: (code, status) => {
            if (root._pendingUninstallIconName.length === 0)
                return;
            if (code === 0) {
                root._resolveOwnership(root._iconUserDir + root._pendingUninstallIconName, false);
            } else {
                // Neither system nor user dir exists any more — the
                // theme vanished between the rail rendering it and the
                // operator clicking Uninstall.
                root.uninstallPlan = {
                    kind: "missing",
                    target: root._pendingUninstallIconName,
                    forFonts: false
                };
                root._pendingUninstallIconName = "";
            }
        }
    }

    // Fonts resolve through the installed FILE, via `fc-match` — the
    // same fontconfig name this backend already applies through
    // `--set`, never a guessed path.
    function proposeUninstallFont(rawName: string): void {
        if (!rawName || rawName.length === 0)
            return;
        if (root._pendingUninstallIconName.length > 0 || root._pendingUninstallFontRaw.length > 0)
            return;
        root._pendingUninstallFontRaw = rawName;
        root.uninstallPlan = {
            kind: "resolving",
            target: rawName,
            forFonts: true
        };
        fontFileResolveProc.command = ["fc-match", "-f", "%{file}", rawName];
        fontFileResolveProc.running = true;
    }

    Process {
        id: fontFileResolveProc
        running: false
        command: ["true"]
        stdout: StdioCollector {
            id: fontFileResolveCollector
        }
        onExited: (code, status) => {
            if (root._pendingUninstallFontRaw.length === 0)
                return;
            var filePath = (fontFileResolveCollector.text || "").trim();
            if (code !== 0 || filePath.length === 0) {
                root.uninstallPlan = {
                    kind: "missing",
                    target: root._pendingUninstallFontRaw,
                    forFonts: true
                };
                root._pendingUninstallFontRaw = "";
                return;
            }
            root._resolveOwnership(filePath, true);
        }
    }

    function _resolveOwnership(path, isFont) {
        root._pendingUninstallDirPath = path;
        ownerResolveProc.command = ["pacman", "-Qoq", path];
        ownerResolveProc._forFonts = isFont;
        ownerResolveProc.running = true;
    }

    Process {
        id: ownerResolveProc
        running: false
        command: ["true"]
        property bool _forFonts: false
        stdout: StdioCollector {
            id: ownerResolveCollector
        }
        onExited: (code, status) => {
            var forFonts = ownerResolveProc._forFonts;
            var target = forFonts ? root._pendingUninstallFontRaw : root._pendingUninstallIconName;
            var path = root._pendingUninstallDirPath;
            var active = forFonts ? (target === root.activeFontRaw) : (target === root.iconThemeName);
            if (code === 0) {
                var pkgs = (ownerResolveCollector.text || "").split("\n").map(l => l.trim()).filter(l => l.length > 0);
                root.uninstallPlan = {
                    kind: "packages",
                    target: target,
                    forFonts: forFonts,
                    packages: pkgs,
                    active: active
                };
            } else {
                // Unowned — a user-dir copy (measured: ~/.local/share/
                // icons/Papirus and Papirus-Dark are both unowned on
                // this host, shadowing the system ones).
                root.uninstallPlan = {
                    kind: "userdir",
                    target: target,
                    forFonts: forFonts,
                    path: path,
                    active: active
                };
            }
            root._pendingUninstallIconName = "";
            root._pendingUninstallFontRaw = "";
        }
    }

    function cancelUninstall(): void {
        root.uninstallPlan = null;
    }

    // Only ever called from an explicit operator confirm on the RESOLVED
    // plan above — never from a propose* call directly.
    function confirmUninstall(): void {
        var plan = root.uninstallPlan;
        if (!plan)
            return;
        var kind = plan.forFonts ? "font" : "icon theme";
        if (plan.kind === "packages") {
            if (root._aurHelper.length === 0) {
                root.logLine("error", "No AUR helper (paru/yay) available — cannot remove any package from here.");
                root.uninstallPlan = null;
                return;
            }
            if (plan.active)
                root.logLine("warn", "Removing the ACTIVE " + kind + " (" + plan.target + ") — the desktop falls back once it is gone.");
            root.logLine("info", "Handing off to a terminal: " + root._aurHelper + " -Rs " + plan.packages.join(" "));
            Quickshell.execDetached([root._terminal(), "-e", root._aurHelper, "-Rs"].concat(plan.packages));
            root.transactionLaunched(plan.forFonts ? "uninstall-font" : "uninstall-icon-theme");
        } else if (plan.kind === "userdir") {
            if (plan.active)
                root.logLine("warn", "Deleting the ACTIVE " + kind + "'s user-dir copy (" + plan.target + ") — the desktop falls back once it is gone.");
            root.logLine("info", "Handing off to a terminal: rm -rvI " + plan.path);
            Quickshell.execDetached([root._terminal(), "-e", "rm", "-rvI", plan.path]);
            root.transactionLaunched(plan.forFonts ? "uninstall-font" : "uninstall-icon-theme");
        }
        root.uninstallPlan = null;
    }

    // ═══════════════════════════════════════════════════════════════
    Component.onCompleted: {
        root.refreshIconThemes();
        root.refreshFonts();
    }
}
