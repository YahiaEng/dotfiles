// modules/security/SecurityBackend.qml — pragma Singleton. Every probe,
// every action and the whole findings model for the Security Center.
//
// ── WHY A SINGLETON, AND NOT PAGE-SCOPED Processes ────────────────────
// `UpdatesPage.qml`'s own header states the rule this file exists to
// escape: "a page is destroyed when the user navigates away
// (`Pages.qml:_swapTo` destroys before incubating the next), so a
// page-scoped Process's lifetime is naturally capped."
//
// Every other probe in this shell is sub-second, so that cap has never
// mattered. A `clamscan` over a home directory runs for MINUTES. A
// page-scoped Process would be killed mid-scan, silently, the instant
// the operator clicked another rail item — and the pane would show no
// error, just a scan that never finished.
//
// So the scan lives here, on a singleton with the shell's own lifetime.
// This is the same rule the launcher already follows for work that must
// outlive its surface. It is also what makes the bar capsule possible at
// all: the capsule and the page are two readers of ONE scan, not two
// scans.
//
// ── PRIVILEGE ─────────────────────────────────────────────────────────
// Reads need none, by construction (measured 260827-np1): the SMART
// snapshot is a world-readable file written by a root timer, `sensors`,
// `ss`, `systemctl is-enabled` and `pacman -Q` all work unprivileged.
// This singleton NEVER runs a privileged read.
//
// Writes go through exactly one path — `runAction(verb)` — which invokes
// `pkexec /usr/local/lib/security-center/security-action <verb>` with a
// verb from `_ALLOWED_ACTIONS` below. The helper has its own hardcoded
// allowlist; this list is the second of the two, and both must agree.
// Neither takes a package name, path or unit from anywhere but a literal.
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

    readonly property string helperPath: "/usr/local/lib/security-center/security-action"
    readonly property string smartSnapshotPath: "/var/lib/security-center/smart.json"

    // The verbs this shell may ask for. Mirrors the helper's own `case`
    // arms exactly. A verb not in this list is refused HERE as well, so
    // a future call site cannot reach the helper with a typo'd or
    // attacker-influenced string and rely on the helper alone to catch
    // it. Defence in depth is the whole point of duplicating it.
    readonly property var _ALLOWED_ACTIONS: ["firewall-enable", "firewall-disable", "firewall-check", "install-clamav", "install-arch-audit", "install-rkhunter", "install-lynis", "signatures-update", "smart-refresh"]

    // Package -> the verb that installs it. Keyed so a tile can offer its
    // own install without any call site assembling a verb by string
    // concatenation.
    readonly property var _INSTALL_VERB: ({
            "clamav": "install-clamav",
            "arch-audit": "install-arch-audit",
            "rkhunter": "install-rkhunter",
            "lynis": "install-lynis"
        })

    readonly property var _TOOL_PKGS: ["clamav", "arch-audit", "rkhunter", "lynis", "smartmontools"]

    // ═══════════════════════════════════════════════════════════════
    //  Observable state
    // ═══════════════════════════════════════════════════════════════

    // Tool presence. `{pkg: version|""}` — empty string means absent.
    property var tools: ({})
    property bool toolsProbed: false

    property bool firewallEnabled: false
    property bool firewallActive: false
    property bool firewallProbed: false

    // Listening sockets, split by whether they are reachable from off
    // this machine. THIS distinction is the whole point of the probe:
    // "no firewall" and "exposed" are different claims, and conflating
    // them trains the operator to ignore the pane.
    property var listenersLocal: []
    property var listenersExposed: []
    property bool exposureProbed: false

    property var devices: []
    property real smartGenerated: 0

    property var cves: []
    property bool cvesProbed: false
    property string cveError: ""

    // ── Scan state (the thing that must outlive a page) ──
    property bool scanRunning: false
    property string scanKind: ""          // "virus" | "rootkit" | ""
    property real scanProgress: 0         // 0..1, -1 when indeterminate
    property int scanFilesSeen: 0
    property int scanThreats: 0
    property var scanFindings: []
    property string scanLastResult: ""
    property double scanStartedAt: 0
    // True from launch until clamscan's first `Scanning` line. The engine
    // spends several seconds loading its signature database before any
    // file is touched, and a progress bar with no explanation during that
    // window reads as a hang.
    property bool scanLoadingDb: false
    property string scanCurrentPath: ""

    property bool actionRunning: false
    property string actionVerb: ""
    property string actionError: ""

    // Whether the root-side helper is actually on disk. Probed up front so
    // the pane can say so BEFORE an action is attempted, rather than
    // letting every button fail at click time — the failure mode the
    // operator hit when install.sh had not finished.
    property bool helperMissing: false
    property bool helperProbed: false

    signal actionFinished(string verb, bool ok, string message)
    signal scanFinished(bool ok, int threats)

    // ═══════════════════════════════════════════════════════════════
    //  Derived: the findings model
    // ═══════════════════════════════════════════════════════════════

    // One merged, ranked list across all four domains. Both the S2
    // findings layout and the D1/H1 summaries read THIS — so the ordering
    // is defined once and the capsule can never disagree with the page.
    readonly property var findings: _buildFindings()

    readonly property int criticalCount: _countAtMost(Severity.rankCritical)
    readonly property int actionableCount: _countAtMost(Severity.rankLow)
    readonly property int absentCount: findings.filter(f => f.rank === Severity.rankAbsent).length

    // Real vulnerabilities with no released fix. Counted, never hidden —
    // they stay in `findings` and in `actionableCount`, because "you
    // cannot fix it today" is not the same as "it does not matter". The
    // layout collapses them for readability; the numbers stay honest.
    readonly property int unfixableCveCount: findings.filter(f => f.isCve === true && f.fixable === false).length
    readonly property int fixableCveCount: findings.filter(f => f.isCve === true && f.fixable !== false).length
    readonly property int healthyCount: findings.filter(f => f.rank === Severity.rankOk).length

    // Worst rank present. Drives the capsule glyph and the posture header.
    readonly property int worstRank: findings.length > 0 ? findings[0].rank : Severity.rankOk

    readonly property bool everythingProbed: toolsProbed && firewallProbed && exposureProbed

    function _countAtMost(maxRank) {
        return findings.filter(f => f.rank <= maxRank).length;
    }

    function _buildFindings() {
        var out = [];

        // ── Network ──
        if (root.firewallProbed) {
            if (!root.firewallActive) {
                out.push({
                    id: "fw-off",
                    rank: Severity.rankCritical,
                    domain: "Network",
                    title: "No firewall is running",
                    // Say what is actually true. Everything on this host
                    // listens on loopback, so "unfirewalled" is correct
                    // and "exposed" would be a lie.
                    detail: root.listenersExposed.length === 0 ? "nftables is inactive. Nothing is currently listening on a public interface, so there is no live exposure — but anything that starts listening would be reachable." : "nftables is inactive and " + root.listenersExposed.length + " service(s) are already listening on a public interface.",
                    actionVerb: "firewall-enable",
                    actionLabel: "Enable"
                });
            } else {
                out.push({
                    id: "fw-on",
                    rank: Severity.rankOk,
                    domain: "Network",
                    title: "Firewall is active",
                    detail: "nftables is loaded and enabled at boot.",
                    actionVerb: "firewall-disable",
                    actionLabel: "Disable"
                });
            }
        }

        if (root.exposureProbed && root.listenersExposed.length > 0) {
            out.push({
                id: "exposed",
                rank: root.firewallActive ? Severity.rankLow : Severity.rankHigh,
                domain: "Network",
                title: root.listenersExposed.length + " service(s) listening on a public interface",
                detail: root.listenersExposed.map(l => l.port + "/" + l.proto).join(", "),
                actionVerb: "",
                actionLabel: ""
            });
        } else if (root.exposureProbed) {
            out.push({
                id: "exposure-ok",
                rank: Severity.rankOk,
                domain: "Network",
                title: "Nothing is listening outward",
                detail: root.listenersLocal.length + " service(s) bound to loopback only.",
                actionVerb: "",
                actionLabel: ""
            });
        }

        // ── Malware ──
        if (root.toolsProbed) {
            if (!root.hasTool("clamav")) {
                out.push({
                    id: "no-clamav",
                    rank: Severity.rankAbsent,
                    domain: "Malware",
                    title: "Virus scanning is unavailable",
                    detail: "clamav is not installed.",
                    actionVerb: "install-clamav",
                    actionLabel: "Install"
                });
            } else if (root.scanRunning && root.scanKind === "virus") {
                out.push({
                    id: "scan-running",
                    rank: Severity.rankScanning,
                    domain: "Malware",
                    title: "Virus scan in progress",
                    detail: root.scanThreats + " threat(s) so far · " + root.scanFilesSeen + " files scanned",
                    actionVerb: "",
                    actionLabel: ""
                });
            } else if (root.scanThreats > 0) {
                out.push({
                    id: "threats",
                    rank: Severity.rankCritical,
                    domain: "Malware",
                    title: root.scanThreats + " infected file(s) found",
                    detail: root.scanFindings.slice(0, 3).join(" · "),
                    actionVerb: "",
                    actionLabel: ""
                });
            } else if (root.scanLastResult.length > 0) {
                out.push({
                    id: "scan-clean",
                    rank: Severity.rankOk,
                    domain: "Malware",
                    title: "Last virus scan found nothing",
                    detail: root.scanLastResult,
                    actionVerb: "",
                    actionLabel: ""
                });
            }

            if (!root.hasTool("rkhunter")) {
                out.push({
                    id: "no-rkhunter",
                    rank: Severity.rankAbsent,
                    domain: "Malware",
                    title: "Rootkit scanning is unavailable",
                    detail: "rkhunter is not installed.",
                    actionVerb: "install-rkhunter",
                    actionLabel: "Install"
                });
            }

            // ── Vulnerabilities ──
            if (!root.hasTool("arch-audit")) {
                out.push({
                    id: "no-audit",
                    rank: Severity.rankAbsent,
                    domain: "Vulnerabilities",
                    title: "CVE audit is unavailable",
                    detail: "arch-audit is not installed.",
                    actionVerb: "install-arch-audit",
                    actionLabel: "Install"
                });
            }
        }

        if (root.cvesProbed && root.cves.length > 0) {
            // arch-audit's own severity words map onto the ramp. Anything
            // it does not name falls to medium rather than being dropped —
            // a CVE with an unparsed severity is still a CVE.
            for (var i = 0; i < root.cves.length; ++i) {
                var c = root.cves[i];
                out.push({
                    id: "cve-" + c.pkg,
                    rank: c.rank,
                    domain: "Vulnerabilities",
                    // arch-audit's %s already reads "High risk"/"Medium
                    // risk", so appending "severity" produced the
                    // operator-visible "pam — high risk severity". Use it
                    // verbatim.
                    title: c.pkg + " — " + c.severity,
                    detail: c.detail,
                    // The distinction that decides everything downstream:
                    // a CVE with a fixed version is something you can act
                    // on today (`pacman -Syu`); one without is a to-do
                    // item for Arch's security team, not for you.
                    // MEASURED on this host: all 17 affected packages have
                    // status "Vulnerable" with fixed: None, and
                    // `arch-audit -u` returns nothing.
                    fixable: c.fixedIn.length > 0,
                    isCve: true,
                    actionVerb: "",
                    actionLabel: ""
                });
            }
        } else if (root.cvesProbed && root.hasTool("arch-audit")) {
            out.push({
                id: "cve-clean",
                rank: Severity.rankOk,
                domain: "Vulnerabilities",
                title: "No known vulnerable packages",
                detail: "arch-audit reports nothing affecting installed packages.",
                actionVerb: "",
                actionLabel: ""
            });
        }

        // ── Devices ──
        for (var d = 0; d < root.devices.length; ++d) {
            var dev = root.devices[d];
            var f = root._deviceFinding(dev);
            if (f)
                out.push(f);
        }

        // Worst first; then ACTIONABLE first at equal severity; then by
        // domain so equal-rank rows group sensibly.
        //
        // The middle key is the operator's round-5 request. Severity
        // stays primary on purpose: a critical vulnerability nobody can
        // fix yet still outranks a low one you could patch this minute —
        // demoting it would be telling you the more dangerous thing
        // matters less because it is inconvenient. Fixability only breaks
        // ties.
        //
        // `fixable` defaults to TRUE for anything that does not set it
        // (every non-CVE finding), so nothing else is demoted by a field
        // it never opted into.
        out.sort(function (a, b) {
            if (a.rank !== b.rank)
                return a.rank - b.rank;
            var af = (a.fixable === false) ? 1 : 0;
            var bf = (b.fixable === false) ? 1 : 0;
            if (af !== bf)
                return af - bf;
            return a.domain < b.domain ? -1 : (a.domain > b.domain ? 1 : 0);
        });
        return out;
    }

    function _deviceFinding(dev) {
        var name = dev.model || dev.node;
        var bits = [];
        if (dev.node)
            bits.push(dev.node.replace("/dev/", ""));
        if (dev.percent_used !== null && dev.percent_used !== undefined)
            bits.push(dev.percent_used + "% life used");
        if (dev.power_on_hours !== null && dev.power_on_hours !== undefined)
            bits.push(dev.power_on_hours + " h powered on");
        if (dev.temp_c !== null && dev.temp_c !== undefined)
            bits.push(dev.temp_c + " °C");

        // A drive that FAILS SMART is the loudest thing this pane can
        // say — it predicts imminent data loss.
        if (dev.passed === false) {
            return {
                id: "dev-" + dev.node,
                rank: Severity.rankCritical,
                domain: "Devices",
                title: name + " is failing SMART",
                detail: bits.join(" · ") + " — back this drive up now.",
                actionVerb: "",
                actionLabel: ""
            };
        }
        if (dev.passed === null || dev.passed === undefined) {
            return {
                id: "dev-" + dev.node,
                rank: Severity.rankAbsent,
                domain: "Devices",
                title: name + " health is unknown",
                detail: bits.join(" · "),
                actionVerb: "smart-refresh",
                actionLabel: "Refresh"
            };
        }
        // Passing, but with wear worth naming. A reallocated sector on a
        // spinning disk is the single most predictive early warning
        // there is, so it is surfaced even while SMART still says PASSED.
        if ((dev.realloc || 0) > 0 || (dev.media_errors || 0) > 0 || (dev.percent_used || 0) >= 80) {
            return {
                id: "dev-" + dev.node,
                rank: Severity.rankMedium,
                domain: "Devices",
                title: name + " is ageing",
                detail: bits.join(" · ") + ((dev.realloc || 0) > 0 ? " · " + dev.realloc + " reallocated sector(s)" : "") + ((dev.media_errors || 0) > 0 ? " · " + dev.media_errors + " media error(s)" : "") + " — still reports PASSED.",
                actionVerb: "",
                actionLabel: ""
            };
        }
        return {
            id: "dev-" + dev.node,
            rank: Severity.rankOk,
            domain: "Devices",
            title: name + " is healthy",
            detail: bits.join(" · "),
            actionVerb: "",
            actionLabel: ""
        };
    }

    function hasTool(pkg) {
        return (root.tools[pkg] || "").length > 0;
    }

    function installVerbFor(pkg) {
        return root._INSTALL_VERB[pkg] || "";
    }

    // ═══════════════════════════════════════════════════════════════
    //  Probes — all unprivileged
    // ═══════════════════════════════════════════════════════════════

    function refreshAll() {
        helperProc.running = true;
        toolsProc.running = true;
        fwEnabledProc.running = true;
        fwActiveProc.running = true;
        exposureProc.running = true;
        smartFile.reload();
        if (root.hasTool("arch-audit"))
            cveProc.running = true;
    }

    // `test -x` rather than a FileView: this asks the question that
    // actually matters (can pkexec execute it), not merely whether a path
    // exists.
    Process {
        id: helperProc
        running: false
        command: ["test", "-x", root.helperPath]
        onExited: (code, status) => {
            root.helperMissing = (code !== 0);
            root.helperProbed = true;
        }
    }

    Process {
        id: toolsProc
        running: false
        // `pacman -Q a b c` prints a line per FOUND package and errors
        // for missing ones, exiting non-zero when any is absent. That
        // non-zero is the NORMAL case here (four of five are absent on a
        // fresh box), so the exit code is deliberately ignored and
        // presence is derived from stdout alone.
        command: ["pacman", "-Q", "clamav", "arch-audit", "rkhunter", "lynis", "smartmontools"]
        stdout: StdioCollector {
            id: toolsCollector
        }
        onExited: (code, status) => {
            var found = {};
            for (var i = 0; i < root._TOOL_PKGS.length; ++i)
                found[root._TOOL_PKGS[i]] = "";
            var lines = (toolsCollector.text || "").split("\n");
            for (var j = 0; j < lines.length; ++j) {
                var parts = lines[j].trim().split(/\s+/);
                if (parts.length >= 2 && found.hasOwnProperty(parts[0]))
                    found[parts[0]] = parts[1];
            }
            root.tools = found;
            root.toolsProbed = true;
            if (root.hasTool("arch-audit") && !root.cvesProbed)
                cveProc.running = true;
        }
    }

    Process {
        id: fwEnabledProc
        running: false
        command: ["systemctl", "is-enabled", "nftables.service"]
        stdout: StdioCollector {
            id: fwEnabledCollector
        }
        onExited: (code, status) => {
            root.firewallEnabled = (fwEnabledCollector.text || "").trim() === "enabled";
            root.firewallActive = root.firewallEnabled && root.firewallLoadedOk;
            root.firewallProbed = true;
        }
    }

    // ── `is-active` IS THE WRONG QUESTION FOR THIS UNIT ──────────────
    // Measured 2026-08-28, after the operator enabled the firewall and
    // the pane still said "No firewall is running": nftables.service is
    // `Type=oneshot` with NO RemainAfterExit and no ExecStop. It runs
    // `nft -f /etc/nftables.conf`, loads the ruleset into the kernel and
    // exits — so `systemctl is-active` reports `inactive` FOREVER, even
    // though the ruleset is live. The journal showed the unit had run at
    // 04:33:19 with status=0/SUCCESS while the UI claimed it was off.
    //
    // Reading the ruleset directly would be authoritative but needs root
    // (`nft list table inet filter` -> "Operation not permitted"), and
    // this singleton never runs a privileged read. The honest
    // unprivileged answer is: the unit is enabled AND its last run
    // succeeded.
    //
    // KNOWN LIMIT, stated rather than hidden: a manual `nft flush
    // ruleset` after a successful load would leave this reporting active
    // while the kernel has no rules. The pane cannot see that without
    // privilege.
    Process {
        id: fwActiveProc
        running: false
        command: ["systemctl", "show", "nftables.service", "-p", "Result", "-p", "ExecMainStatus", "--value"]
        stdout: StdioCollector {
            id: fwActiveCollector
        }
        onExited: (code, status) => {
            var lines = (fwActiveCollector.text || "").split("\n").map(l => l.trim()).filter(l => l.length > 0);
            var result = lines.length > 0 ? lines[0] : "";
            var mainStatus = lines.length > 1 ? lines[1] : "";
            root.firewallLoadedOk = (result === "success" && mainStatus === "0");
        }
    }

    // Enabled at boot AND last load succeeded. Both halves matter: enabled
    // alone would claim a firewall on a machine where the ruleset failed
    // to parse, and a successful past run alone would ignore that the
    // operator has since turned it off.
    property bool firewallLoadedOk: false
    onFirewallLoadedOkChanged: root.firewallActive = root.firewallEnabled && root.firewallLoadedOk

    Process {
        id: exposureProc
        running: false
        // -H drops the header, -n keeps ports numeric, -l is listening
        // only. No -p: that needs root for other users' processes and we
        // do not need the process name to judge exposure.
        command: ["ss", "-tulnH"]
        stdout: StdioCollector {
            id: exposureCollector
        }
        onExited: (code, status) => {
            var local = [];
            var exposed = [];
            var lines = (exposureCollector.text || "").split("\n");
            for (var i = 0; i < lines.length; ++i) {
                var line = lines[i].trim();
                if (line.length === 0)
                    continue;
                var f = line.split(/\s+/);
                if (f.length < 5)
                    continue;
                var proto = f[0];
                var addr = f[4];
                // Split "host:port" from the RIGHT — an IPv6 local
                // address is full of colons, so indexOf would take the
                // wrong one and every v6 listener would misparse.
                var cut = addr.lastIndexOf(":");
                if (cut < 0)
                    continue;
                var host = addr.substring(0, cut);
                var port = addr.substring(cut + 1);
                var entry = {
                    proto: proto,
                    host: host,
                    port: port
                };
                // Loopback in both families, plus link-local v6 which is
                // not routable off-link.
                if (host === "127.0.0.1" || host === "[::1]" || host.indexOf("127.") === 0 || host.indexOf("[fe80:") === 0)
                    local.push(entry);
                else
                    exposed.push(entry);
            }
            root.listenersLocal = local;
            root.listenersExposed = exposed;
            root.exposureProbed = true;
        }
    }

    // SMART comes from a file a root timer writes — never from a
    // privileged read here. `watchChanges` picks up each timer run with
    // no polling on our side.
    FileView {
        id: smartFile
        path: root.smartSnapshotPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                var d = JSON.parse(smartFile.text());
                root.devices = d.devices || [];
                root.smartGenerated = d.generated || 0;
            } catch (e) {
                root.devices = [];
            }
        }
        onLoadFailed: error => {
            // Absent snapshot is the normal pre-install state, not an
            // error worth surfacing as one — the device section simply
            // reports nothing rather than claiming a failure.
            root.devices = [];
        }
    }

    Process {
        id: cveProc
        running: false
        // %n pkgname | %s severity | %c CVEs | %v fixed version.
        // `%v` is the one that matters most and is easy to miss: it is
        // EMPTY when no fixed version exists yet, which is the difference
        // between "run an update" and "there is nothing you can do today".
        command: ["arch-audit", "--format", "%n|%s|%c|%v"]
        stdout: StdioCollector {
            id: cveCollector
        }
        onExited: (code, status) => {
            var out = [];
            var lines = (cveCollector.text || "").split("\n");
            for (var i = 0; i < lines.length; ++i) {
                var line = lines[i].trim();
                if (line.length === 0)
                    continue;
                var bits = line.split("|");
                var pkg = (bits[0] || line).trim();
                var sev = (bits[1] || "unknown").trim();
                var cveList = (bits[2] || "").split(",").map(c => c.trim()).filter(c => c.length > 0);
                var fixedIn = (bits[3] || "").trim();

                // Name at most two CVEs — linux-lts alone reports 21 and
                // a wall of identifiers is not readable in a settings row.
                var cveText = "";
                if (cveList.length === 1)
                    cveText = cveList[0];
                else if (cveList.length === 2)
                    cveText = cveList[0] + ", " + cveList[1];
                else if (cveList.length > 2)
                    cveText = cveList[0] + " and " + (cveList.length - 1) + " more";

                var fixText = fixedIn.length > 0 ? "fixed in " + fixedIn : "no fix available yet";

                out.push({
                    pkg: pkg,
                    severity: sev,
                    rank: root._cveRank(sev),
                    cves: cveList,
                    fixedIn: fixedIn,
                    detail: cveText.length > 0 ? cveText + " · " + fixText : fixText
                });
            }
            root.cves = out;
            root.cvesProbed = true;
        }
    }

    function _cveRank(sev) {
        var s = (sev || "").toLowerCase();
        if (s.indexOf("critical") >= 0)
            return Severity.rankCritical;
        if (s.indexOf("high") >= 0)
            return Severity.rankHigh;
        if (s.indexOf("low") >= 0)
            return Severity.rankLow;
        // Medium AND unknown. An unrecognised severity must never sort
        // below a known-low one — it is unassessed, not benign.
        return Severity.rankMedium;
    }

    // ═══════════════════════════════════════════════════════════════
    //  Scanning — the work that outlives every surface
    // ═══════════════════════════════════════════════════════════════

    // Chosen by the operator (Settings -> Security -> Scan target) and
    // persisted, so a scan started tomorrow covers the same ground. The
    // fallback is HOME, which is what it was before this became a knob.
    readonly property string scanTarget: {
        var v = Prefs.getValue("security.scanTarget");
        var home = Quickshell.env("HOME") || "/home";
        if (!v || v === "home")
            return home;
        if (v === "downloads")
            return home + "/Downloads";
        if (v === "documents")
            return home + "/Documents";
        if (v === "root")
            return "/";
        return home;
    }

    readonly property string scanTargetLabel: {
        var v = Prefs.getValue("security.scanTarget");
        switch (v) {
        case "downloads":
            return "Downloads";
        case "documents":
            return "Documents";
        case "root":
            return "Whole filesystem";
        default:
            return "Home folder";
        }
    }

    function startVirusScan() {
        if (root.scanRunning || !root.hasTool("clamav"))
            return;
        root.scanKind = "virus";
        root.scanRunning = true;
        root.scanProgress = -1;
        root.scanFilesSeen = 0;
        root.scanThreats = 0;
        root.scanFindings = [];
        root.scanCurrentPath = "";
        root.scanLoadingDb = true;
        root.scanStartedAt = Date.now();
        virusScan.running = true;
    }

    function cancelScan() {
        if (!root.scanRunning)
            return;
        // signal(15), not a hard kill: clamscan closes its database
        // cleanly on SIGTERM.
        virusScan.signal(15);
    }

    Process {
        id: virusScan
        running: false
        // `-v`, NOT `-i`. MEASURED 2026-08-28: with `-i` clamscan prints
        // absolutely nothing until the final SCAN SUMMARY, so
        // `scanFilesSeen` stayed 0 for the entire run and the operator
        // correctly reported "I do not know if it is hanging or doing its
        // work". `-v` emits `Scanning <path>` and `<path>: OK` per file,
        // which is the only live progress clamscan offers.
        //
        // The line volume that `-i` existed to avoid is handled by NOT
        // accumulating: only a counter and the current path are kept, and
        // FOUND lines still go into scanFindings.
        command: ["clamscan", "-r", "-v", "--stdout", root.scanTarget]

        // SplitParser gives us a line at a time WHILE the process runs —
        // a StdioCollector would only hand us the text at exit, which
        // would make progress reporting impossible for the one probe in
        // this shell that actually needs it.
        stdout: SplitParser {
            onRead: line => {
                var t = (line || "").trim();
                if (t.length === 0)
                    return;
                if (t.indexOf("FOUND") >= 0) {
                    root.scanThreats = root.scanThreats + 1;
                    var f = root.scanFindings.slice();
                    f.push(t);
                    root.scanFindings = f;
                } else if (t.indexOf("Scanning ") === 0) {
                    // First `Scanning` line means the signature database
                    // has finished loading — measured at 6.7s for 3.6M
                    // signatures even on a two-file directory, which is
                    // dead air the pane must not present as a stalled
                    // scan.
                    root.scanLoadingDb = false;
                    root.scanFilesSeen = root.scanFilesSeen + 1;
                    root.scanCurrentPath = t.substring(9);
                } else if (t.indexOf("Scanned files:") === 0) {
                    // The summary's count is authoritative — it counts
                    // files clamscan actually scanned, where our `Scanning`
                    // tally includes ones it then skipped.
                    var n = parseInt(t.split(":")[1]);
                    if (!isNaN(n))
                        root.scanFilesSeen = n;
                }
            }
        }
        onExited: (code, status) => {
            root.scanRunning = false;
            root.scanKind = "";
            root.scanProgress = 0;
            root.scanLoadingDb = false;
            root.scanCurrentPath = "";
            // clamscan exits 0 = clean, 1 = virus found, 2 = error.
            // Only 2 is a failure of the SCAN; 1 is a successful scan
            // with a bad result, and conflating them would report an
            // infection as a tool error.
            var ok = (code === 0 || code === 1);
            root.scanLastResult = ok ? (root.scanThreats === 0 ? "Clean · " + root.scanFilesSeen + " files" : root.scanThreats + " infected") : "Scan failed";
            root.scanFinished(ok, root.scanThreats);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  Privileged actions — the ONLY write path
    // ═══════════════════════════════════════════════════════════════

    property string _pendingVerb: ""

    function runAction(verb) {
        if (root.actionRunning)
            return;
        // Refuse anything not on the allowlist HERE, before pkexec is
        // ever reached. The helper refuses it too; that redundancy is
        // deliberate.
        if (root._ALLOWED_ACTIONS.indexOf(verb) < 0) {
            root.actionError = "Refused unknown action: " + verb;
            root.actionFinished(verb, false, root.actionError);
            return;
        }
        if (root.helperMissing) {
            root.actionError = "The privileged helper is not installed. Run install.sh (or its section_security) to place /usr/local/lib/security-center/security-action.";
            root.actionFinished(verb, false, root.actionError);
            return;
        }
        root.actionVerb = verb;
        root.actionError = "";
        root.actionRunning = true;
        root._pendingVerb = verb;
        actionProc.command = ["pkexec", root.helperPath, verb];
        actionProc.running = true;
    }

    Process {
        id: actionProc
        running: false
        command: ["true"]
        stderr: StdioCollector {
            id: actionErrCollector
        }
        onExited: (code, status) => {
            var verb = root._pendingVerb;
            root.actionRunning = false;
            // ── 126 vs 127 ARE NOT THE SAME THING ────────────────────
            // I originally treated BOTH as "cancelled". Measured on this
            // host: `pkexec <missing-path>` exits **127**, printing
            // "Error accessing …: No such file or directory". So with the
            // helper not yet installed, a real failure was reported as a
            // user cancellation and shown NOWHERE — the operator pressed
            // Enable, then Confirm, and the button silently reset. That
            // is exactly what was reported.
            //
            // pkexec(1): 126 = authorisation could not be obtained (the
            // dialog was dismissed, or the user is not authorised) — that
            // genuinely is not a failure. 127 = an error occurred, e.g.
            // the program could not be found. Only 126 is a cancel.
            var cancelled = (code === 126);
            var ok = (code === 0);
            if (!ok && !cancelled) {
                var stderrText = (actionErrCollector.text || "").trim();
                if (code === 127)
                    root.actionError = root.helperMissing ? "The privileged helper is not installed. Run install.sh (or its section_security) to place it." : (stderrText || "pkexec could not run the helper (exit 127).");
                else
                    root.actionError = stderrText || ("The helper failed with exit " + code + ".");
            }
            root.actionFinished(verb, ok, cancelled ? "Cancelled" : (ok ? "Done" : root.actionError));
            root._pendingVerb = "";
            root.actionVerb = "";
            // Re-probe whatever the verb could have changed, so the pane
            // reflects the new truth without the operator refreshing.
            if (ok)
                root.refreshAll();
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  Lifecycle
    // ═══════════════════════════════════════════════════════════════

    // Re-probe periodically. Cheap: five short-lived processes, none
    // privileged. Deliberately NOT while a scan runs — the scan is the
    // expensive thing and a probe storm alongside it buys nothing.
    Timer {
        interval: 300000
        running: true
        repeat: true
        onTriggered: {
            if (!root.scanRunning)
                root.refreshAll();
        }
    }

    Component.onCompleted: root.refreshAll()
}
