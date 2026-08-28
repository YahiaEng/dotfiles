// modules/packages/PackagesBackend.qml — pragma Singleton. The one owner
// of everything this shell knows about installed packages, the repo
// catalogue, pending updates and orphans (quick task 260828-75k).
//
// ── WHY A SINGLETON ───────────────────────────────────────────────────
// The same reason SecurityBackend.qml is one: a page is destroyed when
// the operator navigates away (`Pages.qml:_swapTo` destroys before
// incubating the next), so a page-scoped Process's lifetime is capped.
// Four surfaces read this backend — the workbench window, the Settings
// page, the launcher's `pkg` route and the bar capsule — and they must
// agree. Four readers of ONE model, never four models.
//
// ── WHY NO CACHE FILE, NO DAEMON, NO INCREMENTAL LOAD ─────────────────
// Measured on this host 2026-08-28: `pacman -Qi` returns all 1420
// installed packages with every field in 0.20 s / 1.33 MB, and the JS
// parse below runs in ~0.19 s. That is fast enough to do on first open
// and keep in memory. Every other query is under 0.2 s except the two
// network ones (`checkupdates` 0.81 s, `paru -Qua` 0.90 s), which is why
// only those two are behind an explicit "checking" state.
//
// ── `env LC_ALL=C` IS LOAD-BEARING, NOT DECORATION ────────────────────
// `pacman -Qi`'s FIELD NAMES and DATE FORMAT are both localised. The
// parser below keys off the literal English "Installed Size" /
// "Install Reason" / "Install Date", and `_parseDate` expects C's
// `Sun Mar 15 00:04:20 2026` rather than the EET locale's
// `Sun 15 Mar 2026 12:04:20 AM EET`. Under any other locale this file
// silently produces records with no size, no reason and no date — no
// error, just empty fields. `env` is used as the argv[0] rather than a
// shell so nothing is re-split: this repo's standing prohibition on
// string-built shell commands stays intact.
//
// ── PRIVILEGE: NONE, BY CONSTRUCTION ──────────────────────────────────
// Every read here runs as the user — verified: `pacman -Q*`, `pacman
// -Sl`, `checkupdates`, `paru -Qua`, and (the one that surprises people)
// `pacman -Rs --print`, which resolves a full removal cascade WITHOUT
// root. This singleton never escalates. Writes do not happen here at
// all: `runTransaction` hands a literal argv array to the terminal, so
// pacman prints what it will do and asks, exactly as it would if you had
// typed it. There is no pkexec verb and no polkit action for packages.
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

    // The pacman database lock. Its presence means a transaction is
    // running RIGHT NOW — ours or someone else's. Every write path
    // checks it first, because starting a second transaction is how you
    // get a "unable to lock database" wall of text in a terminal that
    // then closes.
    readonly property string dbLockPath: "/var/lib/pacman/db.lck"

    // Arch package names permit letters, digits, @ . _ + - and nothing
    // else. Every name this backend passes into an argv array is checked
    // against this first. The argv arrays cannot be shell-injected (no
    // shell is invoked), so this is defence in depth rather than the
    // only guard — but a name that fails it means the parse went wrong,
    // and running a transaction on a misparsed name is exactly what we
    // do not want to do quietly.
    readonly property var _NAME_RE: /^[a-zA-Z0-9@._+-]+$/

    readonly property var _MONTHS: ({
            Jan: 0,
            Feb: 1,
            Mar: 2,
            Apr: 3,
            May: 4,
            Jun: 5,
            Jul: 6,
            Aug: 7,
            Sep: 8,
            Oct: 9,
            Nov: 10,
            Dec: 11
        })

    // ═══════════════════════════════════════════════════════════════
    //  Observable state
    // ═══════════════════════════════════════════════════════════════

    // Every installed package, parsed from `pacman -Qi`. See _parseQi for
    // the record shape.
    property var packages: []
    property bool packagesProbed: false

    // name -> repo ("core", "extra", "multilib", …) for everything in the
    // sync databases. Also the install-side catalogue.
    property var repoOf: ({})
    property var catalogue: []          // [{name, repo, version, installed}]
    property bool catalogueProbed: false

    // name -> true for foreign packages (`pacman -Qm`) — the AUR, plus
    // anything built locally. Authoritative; the repoOf miss is not.
    property var foreign: ({})
    property bool foreignProbed: false

    property var orphans: []            // names, from `pacman -Qdtq`
    property bool orphansProbed: false

    // Pending updates. `{name, from, to, source}` where source is "repo"
    // or "aur".
    property var repoUpdates: []
    property var aurUpdates: []
    property bool repoUpdatesProbed: false
    property bool aurUpdatesProbed: false
    property double lastCheckedAt: 0

    // True while a pacman transaction holds the database lock.
    property bool dbLocked: false

    // The last removal preview, keyed by the request that produced it so
    // a stale answer cannot be shown against a new selection.
    property var previewFor: []         // names asked about
    property var previewCascade: []     // [{name, version}] actually removed
    property string previewError: ""
    property bool previewRunning: false

    signal transactionLaunched(string kind)

    // ── How every surface asks for the workbench ──────────────────────
    // The workbench is a TYPE mounted once in shell.qml, not a singleton,
    // so no other file can reach it directly. Rather than thread a handle
    // through the bar, the launcher and the settings tree, each of them
    // raises this on the backend they all already hold, and shell.qml —
    // which owns the one instance — connects it. `focusName` may be empty,
    // meaning "just open".
    signal openWorkbenchRequested(string focusName)

    function openWorkbench(name: string): void {
        root.openWorkbenchRequested(name || "");
    }

    // ═══════════════════════════════════════════════════════════════
    //  Derived — declared before anything that reads them at
    //  construction time (this tree's declare-before-use discipline).
    // ═══════════════════════════════════════════════════════════════

    readonly property bool updatesProbed: root.repoUpdatesProbed && root.aurUpdatesProbed

    // The count the bar capsule shows. Repo AND aur — the capsule read
    // `checkupdates` alone until this task, so it under-reported every
    // AUR update that was ever pending.
    readonly property int pendingCount: root.repoUpdates.length + root.aurUpdates.length

    readonly property var allUpdates: root.repoUpdates.concat(root.aurUpdates)

    readonly property int installedCount: root.packages.length

    readonly property int explicitCount: {
        var n = 0;
        for (var i = 0; i < root.packages.length; ++i)
            if (root.packages[i].explicit)
                n++;
        return n;
    }

    readonly property int foreignCount: {
        var n = 0;
        for (var k in root.foreign)
            n++;
        return n;
    }

    readonly property real totalSizeMiB: {
        var t = 0;
        for (var i = 0; i < root.packages.length; ++i)
            t += root.packages[i].sizeMiB;
        return t;
    }

    // The biggest single package, so a size bar can be drawn relative to
    // something real rather than to an invented ceiling.
    readonly property real largestSizeMiB: {
        var m = 0;
        for (var i = 0; i < root.packages.length; ++i)
            if (root.packages[i].sizeMiB > m)
                m = root.packages[i].sizeMiB;
        return m;
    }

    // ═══════════════════════════════════════════════════════════════
    //  Formatting + parsing helpers — ALL declared above the Processes
    //  that call them.
    // ═══════════════════════════════════════════════════════════════

    function formatSize(mib: real): string {
        if (mib >= 1024)
            return (mib / 1024).toFixed(2) + " GiB";
        if (mib >= 1)
            return mib.toFixed(2) + " MiB";
        return (mib * 1024).toFixed(0) + " KiB";
    }

    function _sizeToMiB(text) {
        // "885.66 MiB" / "8.13 KiB" / "0.00 B" — C locale, always
        // "<number> <unit>".
        var m = (text || "").match(/^([\d.]+)\s+(B|KiB|MiB|GiB)$/);
        if (!m)
            return 0;
        var n = parseFloat(m[1]);
        switch (m[2]) {
        case "B":
            return n / 1048576;
        case "KiB":
            return n / 1024;
        case "GiB":
            return n * 1024;
        default:
            return n;
        }
    }

    function _parseDate(text) {
        // C locale asctime: "Sun Mar 15 00:04:20 2026". Returns ms, or 0
        // when the shape is anything else — a package with an
        // unparseable date sorts last rather than breaking the sort.
        var m = (text || "").match(/^\w{3}\s+(\w{3})\s+(\d{1,2})\s+(\d{2}):(\d{2}):(\d{2})\s+(\d{4})$/);
        if (!m)
            return 0;
        var mon = root._MONTHS[m[1]];
        if (mon === undefined)
            return 0;
        return new Date(parseInt(m[6], 10), mon, parseInt(m[2], 10), parseInt(m[3], 10), parseInt(m[4], 10), parseInt(m[5], 10)).getTime();
    }

    function _splitList(text) {
        // pacman prints "None" for an empty list, and separates entries
        // by run-on whitespace once continuation lines are folded in.
        if (!text || text === "None")
            return [];
        return text.split(/\s{2,}/).map(s => s.trim()).filter(s => s.length > 0);
    }

    function _parseQi(text) {
        // Blocks separated by a blank line; each line is
        // "Field Name     : value", with continuation lines indented.
        var out = [];
        var blocks = (text || "").split("\n\n");
        for (var b = 0; b < blocks.length; ++b) {
            var block = blocks[b];
            if (!block || block.trim().length === 0)
                continue;
            var f = {};
            var key = "";
            var lines = block.split("\n");
            for (var i = 0; i < lines.length; ++i) {
                var line = lines[i];
                if (line.trim().length === 0)
                    continue;
                var m = (line.charAt(0) !== " ") ? line.match(/^(\S[^:]*?)\s*: (.*)$/) : null;
                if (m) {
                    key = m[1].trim();
                    f[key] = m[2].trim();
                } else if (key.length > 0) {
                    // Continuation of the previous field. Joined with two
                    // spaces so _splitList's separator stays consistent
                    // with pacman's own column padding.
                    f[key] = f[key] + "  " + line.trim();
                }
            }
            if (!f["Name"])
                continue;
            var sizeText = f["Installed Size"] || "";
            out.push({
                name: f["Name"],
                version: f["Version"] || "",
                description: f["Description"] || "",
                url: f["URL"] || "",
                licenses: f["Licenses"] || "",
                groups: f["Groups"] || "None",
                arch: f["Architecture"] || "",
                provides: root._splitList(f["Provides"]),
                dependsOn: root._splitList(f["Depends On"]),
                optionalDeps: root._splitList(f["Optional Deps"]),
                requiredBy: root._splitList(f["Required By"]),
                optionalFor: root._splitList(f["Optional For"]),
                conflicts: root._splitList(f["Conflicts With"]),
                replaces: root._splitList(f["Replaces"]),
                sizeText: sizeText,
                sizeMiB: root._sizeToMiB(sizeText),
                packager: f["Packager"] || "",
                buildDate: f["Build Date"] || "",
                installDate: f["Install Date"] || "",
                installedAt: root._parseDate(f["Install Date"]),
                explicit: (f["Install Reason"] || "").indexOf("Explicit") === 0,
                validatedBy: f["Validated By"] || ""
            });
        }
        return out;
    }

    function _parseUpdateLine(line, source) {
        // "<name> <old> -> <new>". Same shape from `checkupdates` and
        // `paru -Qua`, measured. A line that does not match is kept
        // rather than dropped, so an unexpected format degrades to the
        // raw line instead of silently losing a package — the exact
        // defensive shape UpdatesPage.qml already uses.
        var m = line.match(/^(\S+)\s+(\S+)\s+->\s+(\S+)$/);
        if (m)
            return {
                name: m[1],
                from: m[2],
                to: m[3],
                source: source
            };
        return {
            name: line,
            from: "",
            to: "",
            source: source
        };
    }

    // ═══════════════════════════════════════════════════════════════
    //  Lookups the surfaces use
    // ═══════════════════════════════════════════════════════════════

    function isForeign(name: string): bool {
        return root.foreign[name] === true;
    }

    function sourceOf(name: string): string {
        if (root.foreign[name] === true)
            return "AUR";
        var r = root.repoOf[name];
        if (r)
            return r;
        // NOT "local" — that is a specific pacman word (the local db) and
        // using it as a fallback labelled every repo package "local" until
        // the catalogue loaded. An unknown repo is stated as unknown.
        return root.catalogueProbed ? "?" : "…";
    }

    function isOrphan(name: string): bool {
        return root.orphans.indexOf(name) >= 0;
    }

    function updateFor(name: string): var {
        var u = root.allUpdates;
        for (var i = 0; i < u.length; ++i)
            if (u[i].name === name)
                return u[i];
        return null;
    }

    function packageByName(name: string): var {
        for (var i = 0; i < root.packages.length; ++i)
            if (root.packages[i].name === name)
                return root.packages[i];
        return null;
    }

    // ═══════════════════════════════════════════════════════════════
    //  Probes
    // ═══════════════════════════════════════════════════════════════

    function refreshLocal(): void {
        if (!qiProc.running)
            qiProc.running = true;
        if (!foreignProc.running)
            foreignProc.running = true;
        if (!orphanProc.running)
            orphanProc.running = true;
        lockProc.running = true;
    }

    function refreshCatalogue(): void {
        if (!catalogueProc.running)
            catalogueProc.running = true;
    }

    // Single-flighted, like SystemCapsule's own updates probe: a call
    // that arrives while a check is in flight is dropped rather than
    // queued, so a slow mirror can never stack a second child.
    function refreshUpdates(): void {
        if (!repoUpdProc.running) {
            root.repoUpdatesProbed = false;
            repoUpdProc.running = true;
        }
        // `packages.includeAur` off means the AUR probe is not RUN at
        // all — the point of the toggle is to skip a network call, so
        // running it and discarding the answer would defeat it. The list
        // is cleared and marked probed so `updatesProbed` still settles
        // and nothing waits forever on a check that will never happen.
        if (!Prefs.getValue("packages.includeAur")) {
            root.aurUpdates = [];
            root.aurUpdatesProbed = true;
            root._markChecked();
        } else if (!aurUpdProc.running) {
            root.aurUpdatesProbed = false;
            aurUpdProc.running = true;
        }
    }

    function refreshAll(): void {
        root.refreshLocal();
        root.refreshCatalogue();
        root.refreshUpdates();
    }

    Process {
        id: qiProc
        running: false
        // See this file's header: `env LC_ALL=C` is required for the
        // English field names and the C date format the parser expects.
        command: ["env", "LC_ALL=C", "pacman", "-Qi"]
        stdout: StdioCollector {
            id: qiCollector
        }
        onExited: (code, status) => {
            root.packages = root._parseQi(qiCollector.text || "");
            root.packagesProbed = true;
        }
    }

    Process {
        id: foreignProc
        running: false
        command: ["pacman", "-Qmq"]
        stdout: StdioCollector {
            id: foreignCollector
        }
        onExited: (code, status) => {
            var map = {};
            var lines = (foreignCollector.text || "").split("\n");
            for (var i = 0; i < lines.length; ++i) {
                var n = lines[i].trim();
                if (n.length > 0)
                    map[n] = true;
            }
            root.foreign = map;
            root.foreignProbed = true;
        }
    }

    Process {
        id: orphanProc
        running: false
        // Exits non-zero when there are NO orphans, which is the good
        // case — the exit code is deliberately ignored and the answer
        // comes from stdout alone, the same convention every other
        // "nothing to report" tool in this tree uses.
        command: ["pacman", "-Qdtq"]
        stdout: StdioCollector {
            id: orphanCollector
        }
        onExited: (code, status) => {
            root.orphans = (orphanCollector.text || "").split("\n").map(l => l.trim()).filter(l => l.length > 0);
            root.orphansProbed = true;
        }
    }

    Process {
        id: catalogueProc
        running: false
        // "<repo> <name> <version> [installed]" — one line per package in
        // every sync database. 15,412 lines / 0.17 s on this host.
        command: ["pacman", "-Sl"]
        stdout: StdioCollector {
            id: catalogueCollector
        }
        onExited: (code, status) => {
            var map = {};
            var list = [];
            var lines = (catalogueCollector.text || "").split("\n");
            for (var i = 0; i < lines.length; ++i) {
                var parts = lines[i].trim().split(/\s+/);
                if (parts.length < 3)
                    continue;
                map[parts[1]] = parts[0];
                list.push({
                    name: parts[1],
                    repo: parts[0],
                    version: parts[2],
                    installed: lines[i].indexOf("[installed") >= 0
                });
            }
            root.repoOf = map;
            root.catalogue = list;
            root.catalogueProbed = true;
        }
    }

    Process {
        id: repoUpdProc
        running: false
        command: ["checkupdates"]
        stdout: StdioCollector {
            id: repoUpdCollector
        }
        onExited: (code, status) => {
            // checkupdates documents exit 2 for "nothing to do"; any
            // non-zero exit degrades to "no repo updates", never a
            // distinct error state.
            var out = [];
            if (code === 0) {
                var lines = (repoUpdCollector.text || "").split("\n");
                for (var i = 0; i < lines.length; ++i) {
                    var l = lines[i].trim();
                    if (l.length > 0)
                        out.push(root._parseUpdateLine(l, "repo"));
                }
            }
            root.repoUpdates = out;
            root.repoUpdatesProbed = true;
            root._markChecked();
        }
    }

    Process {
        id: aurUpdProc
        running: false
        command: ["paru", "-Qua"]
        stdout: StdioCollector {
            id: aurUpdCollector
        }
        onExited: (code, status) => {
            var out = [];
            if (code === 0) {
                var lines = (aurUpdCollector.text || "").split("\n");
                for (var i = 0; i < lines.length; ++i) {
                    var l = lines[i].trim();
                    if (l.length > 0)
                        out.push(root._parseUpdateLine(l, "aur"));
                }
            }
            root.aurUpdates = out;
            root.aurUpdatesProbed = true;
            root._markChecked();
        }
    }

    function _markChecked() {
        // Stamped only when BOTH have settled, never when either alone
        // does — otherwise "last checked" claims a completeness it does
        // not have.
        if (root.repoUpdatesProbed && root.aurUpdatesProbed)
            root.lastCheckedAt = Date.now();
    }

    Process {
        id: lockProc
        running: false
        command: ["test", "-e", root.dbLockPath]
        onExited: (code, status) => {
            root.dbLocked = (code === 0);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  Removal preview — the one thing Octopi does that earns its keep
    // ═══════════════════════════════════════════════════════════════
    //
    // `pacman -Rs --print --print-format '%n %v'` resolves the FULL
    // cascade without root (measured: 6 selected orphans cascade to 11
    // actual removals in 0.05 s). When the removal would break a
    // dependency it exits non-zero and says which package needs what, on
    // stderr — that message is the honest answer and is surfaced as-is.
    //
    // `-Rs`, deliberately NOT `-Rns`: pacman refuses `--nosave` together
    // with `--print` ("invalid option: '--nosave' and '--print' may not
    // be used together"), so a `-Rns` preview is impossible. Rather than
    // preview one command and run another, both the preview here and
    // `removeCommand` below use `-Rs`. The preview therefore describes
    // exactly what will run.

    function previewRemoval(names): void {
        root.previewError = "";
        root.previewCascade = [];
        root.previewFor = names ? names.slice() : [];
        if (root.previewFor.length === 0)
            return;
        for (var i = 0; i < root.previewFor.length; ++i) {
            if (!root._NAME_RE.test(root.previewFor[i])) {
                root.previewError = "Refusing to preview a package name that is not a valid package name: " + root.previewFor[i];
                root.previewFor = [];
                return;
            }
        }
        if (previewProc.running)
            return;
        root.previewRunning = true;
        previewProc.command = ["pacman", "-Rs", "--print", "--print-format", "%n %v"].concat(root.previewFor);
        previewProc.running = true;
    }

    Process {
        id: previewProc
        running: false
        command: ["true"]
        stdout: StdioCollector {
            id: previewCollector
        }
        stderr: StdioCollector {
            id: previewErrCollector
        }
        onExited: (code, status) => {
            root.previewRunning = false;
            if (code !== 0) {
                // MEASURED, and not what it looks like: pacman writes the
                // `error:` SUMMARY to stderr but the `:: removing X breaks
                // dependency 'Y' required by Z` REASONS to STDOUT. Reading
                // stderr alone (the first version here) produced "failed to
                // prepare transaction (could not satisfy dependencies)" with
                // the useful half missing — caught by running the refuse
                // path rather than by reasoning about it.
                //
                // The reasons are also near-duplicates: harfbuzz emits ~30
                // lines naming only a handful of distinct packages, once per
                // soname. What the operator needs is the SET of packages
                // that still need this one, so that is what is extracted.
                var head = (previewErrCollector.text || "").split("\n").map(l => l.replace(/^error:\s*/, "").trim()).filter(l => l.length > 0);
                var needers = [];
                var reasons = (previewCollector.text || "").split("\n");
                for (var r = 0; r < reasons.length; ++r) {
                    var m = reasons[r].match(/required by (\S+)\s*$/);
                    if (m && needers.indexOf(m[1]) < 0)
                        needers.push(m[1]);
                }
                var msg = head.length > 0 ? head[0] : "pacman refused this removal.";
                if (needers.length > 0) {
                    var shown = needers.length > 8 ? needers.slice(0, 8).join(", ") + " and " + (needers.length - 8) + " more" : needers.join(", ");
                    msg += "\n\nStill needed by: " + shown;
                }
                root.previewError = msg;
                root.previewCascade = [];
                return;
            }
            var out = [];
            var rows = (previewCollector.text || "").split("\n");
            for (var i = 0; i < rows.length; ++i) {
                var parts = rows[i].trim().split(/\s+/);
                if (parts.length >= 2)
                    out.push({
                        name: parts[0],
                        version: parts[1]
                    });
                else if (parts.length === 1 && parts[0].length > 0)
                    out.push({
                        name: parts[0],
                        version: ""
                    });
            }
            root.previewCascade = out;
        }
    }

    // How much disk the previewed cascade actually returns. Only packages
    // we have a record for contribute — a cascade member that is somehow
    // not in `packages` is counted as 0 rather than guessed at.
    readonly property real previewReclaimMiB: {
        var t = 0;
        for (var i = 0; i < root.previewCascade.length; ++i) {
            var p = root.packageByName(root.previewCascade[i].name);
            if (p)
                t += p.sizeMiB;
        }
        return t;
    }

    // ═══════════════════════════════════════════════════════════════
    //  Transactions — terminal handoff, always
    // ═══════════════════════════════════════════════════════════════
    //
    // Every one of these opens the configured terminal on a real `paru`
    // command, so pacman prints the transaction and asks before doing
    // anything. That is a deliberate choice over a pkexec helper: the
    // list of what will actually change IS the reason to pause, and
    // pacman already prints it and already asks. There is no polkit
    // action for packages and nothing for this feature in install.sh.
    //
    // `Quickshell.execDetached`, never a surface-scoped `Process` — this
    // repo's own 260822-sht lesson. A component-scoped Process dies with
    // its LazyLoader the instant the surface dismisses, killing paru
    // mid-build.
    //
    // Every argv element is either a literal written here or a package
    // name that has passed `_NAME_RE`. Nothing is concatenated into a
    // command line and no shell is invoked.

    function _terminal() {
        return Prefs.getValue("apps.terminal");
    }

    function _validNames(names) {
        if (!names || names.length === 0)
            return null;
        for (var i = 0; i < names.length; ++i)
            if (!root._NAME_RE.test(names[i]))
                return null;
        return names;
    }

    function upgradeAll(): bool {
        if (root.dbLocked)
            return false;
        Quickshell.execDetached([root._terminal(), "-e", "paru", "-Syu"]);
        root.transactionLaunched("upgrade");
        return true;
    }

    function install(names): bool {
        var safe = root._validNames(names);
        if (!safe || root.dbLocked)
            return false;
        // No `-y`, ever. `-Sy <pkg>` is the documented Arch
        // partial-upgrade footgun: it refreshes the sync database and
        // then installs one package against a system that has not been
        // upgraded. `--needed` turns a stale-database hit into a skip
        // rather than a same-version reinstall.
        Quickshell.execDetached([root._terminal(), "-e", "paru", "-S", "--needed"].concat(safe));
        root.transactionLaunched("install");
        return true;
    }

    function remove(names): bool {
        var safe = root._validNames(names);
        if (!safe || root.dbLocked)
            return false;
        // `-Rs`, matching previewRemoval above exactly — see its comment
        // for why this is not `-Rns`.
        Quickshell.execDetached([root._terminal(), "-e", "paru", "-Rs"].concat(safe));
        root.transactionLaunched("remove");
        return true;
    }

    function markExplicit(names): bool {
        var safe = root._validNames(names);
        if (!safe || root.dbLocked)
            return false;
        Quickshell.execDetached([root._terminal(), "-e", "paru", "-D", "--asexplicit"].concat(safe));
        root.transactionLaunched("mark");
        return true;
    }

    // ═══════════════════════════════════════════════════════════════
    //  Polling
    // ═══════════════════════════════════════════════════════════════

    // Reuses the interval the Services page already owns rather than
    // inventing a second knob. Thirty minutes by default — two runs an
    // hour against public mirror infrastructure from one desktop.
    Timer {
        id: updateTimer
        interval: Prefs.getValue("services.updatesPollMs")
        running: true
        repeat: true
        onTriggered: root.refreshUpdates()
    }

    // The lock is cheap to check and changes without warning while a
    // terminal transaction runs, so it is polled far more often than
    // anything else — this is what lets a surface grey out its actions
    // while paru is working.
    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: lockProc.running = true
    }

    // When a transaction we launched finishes, the local database has
    // moved under us. Re-reading on lock release is what keeps the
    // workbench honest without the operator pressing anything.
    onDbLockedChanged: {
        if (!root.dbLocked && root.packagesProbed)
            root.refreshLocal();
    }

    Component.onCompleted: {
        root.refreshLocal();
        root.refreshUpdates();
        // Loaded at startup rather than deferred to the Repos filter. The
        // first version deferred it, which left the Source column reading
        // a fallback for every repo package until the operator happened to
        // click Repos — caught on the first render. Measured at 0.17 s for
        // all 15,412 entries, which is not worth deferring anything for.
        root.refreshCatalogue();
    }

    // ═══════════════════════════════════════════════════════════════
    //  IPC
    // ═══════════════════════════════════════════════════════════════
    //
    // `status` exists because this shell has no other way to read a
    // backend's computed value without rendering it: qmllint is blind
    // here (verified 2026-08-28 — it returns 0 for a truncated file), and
    // the hot-reload log proves only that a binding RESOLVED, never what
    // it resolved TO. A capsule that silently reports the wrong number is
    // exactly the defect this task exists to fix, so the number is made
    // readable rather than trusted.
    //
    // `refresh` is the same channel a keybind or a post-transaction hook
    // can use. Neither function takes an argument that reaches a command.
    IpcHandler {
        target: "packages"

        function status(): string {
            return JSON.stringify({
                installed: root.installedCount,
                explicit: root.explicitCount,
                foreign: root.foreignCount,
                orphans: root.orphans.length,
                catalogue: root.catalogue.length,
                pending: root.pendingCount,
                pendingRepo: root.repoUpdates.length,
                pendingAur: root.aurUpdates.length,
                totalSizeMiB: Math.round(root.totalSizeMiB),
                dbLocked: root.dbLocked,
                preview: {
                    asked: root.previewFor,
                    running: root.previewRunning,
                    error: root.previewError,
                    cascade: root.previewCascade.map(c => c.name),
                    reclaimMiB: Math.round(root.previewReclaimMiB)
                },
                probed: {
                    packages: root.packagesProbed,
                    foreign: root.foreignProbed,
                    orphans: root.orphansProbed,
                    catalogue: root.catalogueProbed,
                    updates: root.updatesProbed
                }
            });
        }

        function refresh(): void {
            root.refreshAll();
        }

        // `preview` + the preview block in `status` exist for the same
        // reason `status` itself does: the removal cascade is the one
        // capability that justified building a whole window, and its
        // correctness cannot be read off a rendered pane. Names arrive
        // comma-separated and go through previewRemoval, which validates
        // every one against _NAME_RE before it reaches an argv array.
        function preview(names: string): string {
            var list = (names || "").split(",").map(n => n.trim()).filter(n => n.length > 0);
            root.previewRemoval(list);
            return "previewing " + list.length + " package(s); read the result from status";
        }
    }
}
