// SystemResources.qml — the drawer's one shared resource reader (Phase 14
// Plan 06, DASH-05, D-36/D-39). Filled from 14-03's inert stub; the `Scope`
// root, `drawerOpen` gate and `widgetState` register below are 14-03's own
// contract, kept exactly where it left them.
//
// This is the ONE shared instance both PerformanceTab's four dials (this
// plan) and DashboardTab's resources strip (14-08) read — mounted once
// inside Dashboard.qml, `drawerOpen` bound to the window's own visibility.
//
// ── Cadences (D-36) ─────────────────────────────────────────────────────
// CPU/memory/network sample every `fastPollInterval` (~2s); storage samples
// every `slowPollInterval` (~30s) via a subprocess, since there is no kernel
// pseudo-file for filesystem usage. Battery gets NO TIMER — this is an
// improvement, not an omission: the typed UPower wrapper is push-based, its
// device properties carry Qt property-change notifications, so a binding
// updates the instant the device does. Naming both cadences as constants is
// a source assertion, not a mechanically-enforced one: motion-lint's raw-
// value check (`QML_DURATION_RE`, hypr/.config/hypr/scripts/motion-lint
// ~line 914) is anchored on a lowercase `duration:` key, and a Timer's
// `interval:` period is structurally invisible to it.
//
// ── Lifecycle contract ──────────────────────────────────────────────────
// Every timer's `running` and the storage `Process`'s `running` bind to (or
// are forced by) `drawerOpen` alone — nothing here starts on its own, and
// closing the drawer kills every in-flight read (T-14-19/T-14-20). Reopening
// re-baselines through the `resetBaselines()` call below rather than
// resuming from a stale sample: the first fast tick after a reset only
// establishes baselines (no CPU figure, no rate published that tick); the
// second tick publishes real values. That is what the "pending" register
// value is for — it is not a decorative third word.
//
// ── Defensive parsing (Security V5, T-14-19) ────────────────────────────
// Every kernel-text parse below is wrapped in try/catch with an explicit
// finite-number check before any value reaches a published property. A
// missing, renamed or non-numeric field leaves the previous good value in
// place and drops that metric's own D-41 register to "empty" — never a NaN,
// never a thrown error out of a Timer callback (which would freeze this
// surface's whole binding graph, since the drawer holds a compositor-
// exclusive focus grab).
//
// ── Battery (RESEARCH Don't Hand-Roll, A4/OQ3) ──────────────────────────
// Battery reads exclusively through `Quickshell.Services.UPower`'s
// `UPower.displayDevice`, behind the one named seam `batterySource` — never
// the raw `/sys/class/power_supply` tree. Every property name below
// (isLaptopBattery, isPresent, percentage, state, ready, energy,
// energyCapacity, changeRate, timeToEmpty, timeToFull, healthPercentage,
// healthSupported, iconName, nativePath, model, type, powerSupply) was
// confirmed present, at planning time AND re-confirmed live during this
// task, against the installed
// /usr/lib/qt6/qml/Quickshell/Services/UPower/quickshell-service-upower.qmltypes
// — RESEARCH A4/Open Question 3 exist precisely because a sketch was once
// written from memory instead of the real qmltypes file.
//
// D-41 widget-state register — "populated" / "pending" / "empty" — carried
// on every one of this phase's nine modules/dashboard/ files, even the
// non-visual backends, so the vocabulary is uniform across the whole
// module surface.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Scope {
    id: root

    // D-41: "populated" | "pending" | "empty" — the reader's own aggregate
    // self-report. Flips to "populated" the first time any fast metric
    // completes a real (post-baseline) tick, and back to "pending" on every
    // reset (Component.onCompleted, every drawerOpen flip).
    property string widgetState: "empty"

    // Lifecycle gate (D-36) — bound by Dashboard.qml to the window's own
    // visibility. Every timer/process below runs only while this is true.
    property bool drawerOpen: false

    // ── Cadence + smoothing constants (D-36) — named so no timer below
    //    ever carries a bare number; motion-lint cannot see this, so this
    //    is a source assertion (see acceptance criteria). ─────────────────
    readonly property int fastPollInterval: 2000
    readonly property int slowPollInterval: 30000
    readonly property int cpuSampleWindow: 3

    // ── Published metric properties — the ONLY surface any consumer (this
    //    phase's PerformanceTab, 14-08's resources strip) reads; the read
    //    path behind them stays swappable. ──────────────────────────────
    property real cpuFraction: 0
    property real memoryFraction: 0
    property real memoryUsedBytes: 0
    property real memoryTotalBytes: 0
    property real storageFraction: 0
    property real storageUsedBytes: 0
    property real storageTotalBytes: 0
    // Rates, in bytes per second — never normalised into a fraction of
    // anything. D-36 is explicit that a rate is not a percentage.
    property real netRxRate: 0
    property real netTxRate: 0

    // ── Per-metric D-41 state registers ─────────────────────────────────
    property string cpuState: "empty"
    property string memoryState: "empty"
    property string storageState: "empty"
    property string networkState: "empty"
    // batteryState is NOT declared here — it is a readonly computed
    // property further down (derived purely from batterySource, which is
    // push-notified rather than polled), so declaring a second, separately-
    // assignable property with the same name here would be a duplicate
    // (caught live: quickshell.log reported exactly this "Duplicate
    // property name" error on first load of this file).

    // ── Internal sampling state (not part of the published surface) ────
    property var _cpuPrevTotals: null // { total, idle }
    property var _cpuSamples: []
    property var _netPrev: null // { rx, tx, ts }

    // Clears every stored baseline and drops every per-metric register back
    // to "pending" — called from Component.onCompleted and from
    // onDrawerOpenChanged in BOTH directions, so the reader is equally
    // clean whether it is torn down and rebuilt (a fresh instance) or
    // merely gated (this one, mounted once at the drawer root).
    function resetBaselines() {
        root._cpuPrevTotals = null;
        root._cpuSamples = [];
        root._netPrev = null;
        root.cpuState = "pending";
        root.memoryState = "pending";
        root.networkState = "pending";
        root.storageState = "pending";
        root.widgetState = "pending";
    }

    Component.onCompleted: root.resetBaselines()

    onDrawerOpenChanged: {
        root.resetBaselines();
        if (!root.drawerOpen) {
            // Force the storage subprocess dead the instant the drawer
            // closes so an in-flight `df` read cannot outlive this surface
            // (T-14-20) — a torn-down consumer receiving a late collector
            // signal is a use-after-teardown hazard, not merely wasted work.
            storageProcess.running = false;
        }
    }

    // ── The three kernel readers ─────────────────────────────────────────
    // procfs has no change notification, so `watchChanges` is never set —
    // these are pulled on the fast timer, not pushed.
    //
    // LIVE-MEASURED FINDING (not assumed from the wrapper source alone):
    // `preload: false` + `blockLoading: true` alone is NOT sufficient for a
    // synchronous fresh read on this build — proven live with a temporary
    // instrumentation pass (see 14-06-SUMMARY.md): with only those two set,
    // `reload()` followed immediately by `.text()` returned the PREVIOUS
    // tick's content bit-for-bit identical (verified via a JSON.stringify
    // dump of the parsed CPU totals across two consecutive ticks), lagging
    // one full fast-poll interval behind the real file content, which would
    // have silently under-reported CPU/network for the first real tick
    // every time the drawer opens. Adding `blockAllReads: true` closed the
    // gap — confirmed live afterwards: parsed CPU totals differ tick-to-
    // tick as expected, and cross-checked memory/storage fractions matched
    // `free -b`/`df -B1 /` within timing noise. The working combination is
    // therefore all three: `preload: false`, `blockLoading: true`,
    // `blockAllReads: true`, plus calling `reload()` then `waitForJob()`
    // then `.text()` in that order every tick (the explicit `waitForJob()`
    // is kept as a belt-and-suspenders synchronisation point even though
    // `blockAllReads` was the load-bearing property in this live test). A
    // procfs read is microseconds, so blocking here is the right trade.
    FileView {
        id: statFile
        path: "/proc/stat"
        preload: false
        blockLoading: true
        blockAllReads: true
        printErrors: true
    }
    FileView {
        id: meminfoFile
        path: "/proc/meminfo"
        preload: false
        blockLoading: true
        blockAllReads: true
        printErrors: true
    }
    FileView {
        id: netdevFile
        path: "/proc/net/dev"
        preload: false
        blockLoading: true
        blockAllReads: true
        printErrors: true
    }

    // ── The fast sampler (D-36, ~2s) ─────────────────────────────────────
    Timer {
        id: fastTimer
        interval: root.fastPollInterval
        repeat: true
        running: root.drawerOpen
        onTriggered: root.sampleFast()
    }

    // Aggregate CPU line parse — the first `cpu` line only, dropping the
    // leading label token. Fields in order: user, nice, system, idle,
    // iowait, irq, softirq, steal, guest, guest_nice. Total sums the FIRST
    // EIGHT ONLY — guest/guest_nice are already counted inside user/nice, so
    // summing all ten would double-count virtualised time. Idle is idle
    // plus iowait.
    function _parseCpuLine(text) {
        var firstLine = (text || "").split("\n")[0] || "";
        var parts = firstLine.trim().split(/\s+/);
        // label token + at least 8 numeric fields required.
        if (parts.length < 9)
            return null;
        var fields = [];
        for (var i = 1; i <= 8; i++) {
            var n = Number(parts[i]);
            if (!isFinite(n))
                return null;
            fields.push(n);
        }
        var user = fields[0], nice = fields[1], system = fields[2], idle = fields[3],
            iowait = fields[4], irq = fields[5], softirq = fields[6], steal = fields[7];
        var total = user + nice + system + idle + iowait + irq + softirq + steal;
        return { total: total, idle: idle + iowait };
    }

    // MemTotal/MemAvailable are both reported in KiB; used is total minus
    // AVAILABLE (not the free line) — free excludes reclaimable cache and
    // would report this machine as far more loaded than it actually is.
    function _parseMeminfo(text) {
        var lines = (text || "").split("\n");
        var totalKb = null, availKb = null;
        for (var i = 0; i < lines.length; i++) {
            var mTotal = lines[i].match(/^MemTotal:\s+(\d+)/);
            if (mTotal) { totalKb = Number(mTotal[1]); continue; }
            var mAvail = lines[i].match(/^MemAvailable:\s+(\d+)/);
            if (mAvail) { availKb = Number(mAvail[1]); continue; }
        }
        if (totalKb === null || availKb === null || !isFinite(totalKb) || !isFinite(availKb))
            return null;
        return { totalBytes: totalKb * 1024, availBytes: availKb * 1024 };
    }

    // Skips the file's two header lines. Splits each remaining line on the
    // COLON FIRST — when a counter grows past its column width the kernel
    // glues the first number directly onto the interface's colon with no
    // separating space (this machine's own wired interface is already
    // close to that width today), and a naive whitespace-first split would
    // silently mis-index every field on that line. After the colon, receive
    // bytes is field 0 and transmit bytes is field 8 of the whitespace-
    // separated remainder. Loopback is skipped by name; everything else is
    // summed.
    function _parseNetDev(text) {
        var lines = (text || "").split("\n");
        var rx = 0, tx = 0, any = false;
        for (var i = 2; i < lines.length; i++) {
            var line = lines[i];
            if (!line || line.trim() === "")
                continue;
            var colonIdx = line.indexOf(":");
            if (colonIdx < 0)
                continue;
            var iface = line.substring(0, colonIdx).trim();
            if (iface === "lo")
                continue;
            var rest = line.substring(colonIdx + 1).trim();
            var fields = rest.split(/\s+/);
            if (fields.length < 9)
                continue;
            var rxBytes = Number(fields[0]);
            var txBytes = Number(fields[8]);
            if (!isFinite(rxBytes) || !isFinite(txBytes))
                continue;
            rx += rxBytes;
            tx += txBytes;
            any = true;
        }
        if (!any)
            return null;
        return { rx: rx, tx: tx };
    }

    // One function, one tick, all three kernel reads — each guarded in its
    // own try/catch so a malformed line in one file can never take another
    // metric down with it.
    function sampleFast() {
        // ── CPU ──
        try {
            statFile.reload();
            statFile.waitForJob();
            var cpuNow = root._parseCpuLine(statFile.text());
            if (cpuNow) {
                if (root._cpuPrevTotals) {
                    var totalDelta = cpuNow.total - root._cpuPrevTotals.total;
                    var idleDelta = cpuNow.idle - root._cpuPrevTotals.idle;
                    if (totalDelta > 0) {
                        var busyFrac = 1 - (idleDelta / totalDelta);
                        if (!isFinite(busyFrac))
                            busyFrac = 0;
                        busyFrac = Math.max(0, Math.min(1, busyFrac));
                        var samples = root._cpuSamples.slice();
                        samples.push(busyFrac);
                        while (samples.length > root.cpuSampleWindow)
                            samples.shift();
                        root._cpuSamples = samples;
                        var sum = 0;
                        for (var si = 0; si < samples.length; si++)
                            sum += samples[si];
                        root.cpuFraction = sum / samples.length;
                        root.cpuState = "populated";
                        root.widgetState = "populated";
                    }
                    // else: non-positive total delta — publish nothing this
                    // tick, keep the previous value standing.
                }
                root._cpuPrevTotals = cpuNow;
            } else {
                root.cpuState = "empty";
            }
        } catch (e) {
            root.cpuState = "empty";
        }

        // ── Memory ──
        try {
            meminfoFile.reload();
            meminfoFile.waitForJob();
            var mem = root._parseMeminfo(meminfoFile.text());
            if (mem && mem.totalBytes > 0) {
                var usedBytes = mem.totalBytes - mem.availBytes;
                if (usedBytes < 0)
                    usedBytes = 0;
                root.memoryTotalBytes = mem.totalBytes;
                root.memoryUsedBytes = usedBytes;
                root.memoryFraction = Math.max(0, Math.min(1, usedBytes / mem.totalBytes));
                root.memoryState = "populated";
                root.widgetState = "populated";
            } else {
                root.memoryState = "empty";
            }
        } catch (e) {
            root.memoryState = "empty";
        }

        // ── Network ──
        try {
            netdevFile.reload();
            netdevFile.waitForJob();
            var netNow = root._parseNetDev(netdevFile.text());
            if (netNow) {
                var nowMs = Date.now();
                if (root._netPrev) {
                    var dtSeconds = (nowMs - root._netPrev.ts) / 1000;
                    var rxDelta = netNow.rx - root._netPrev.rx;
                    var txDelta = netNow.tx - root._netPrev.tx;
                    // A backwards counter (interface vanished, or a counter
                    // wrapped) or a non-positive elapsed time both mean
                    // "re-baseline", never an arithmetic negative/absurd
                    // rate — timer drift is divided out by the REAL elapsed
                    // wall time, not the nominal period.
                    if (dtSeconds > 0 && rxDelta >= 0 && txDelta >= 0) {
                        root.netRxRate = rxDelta / dtSeconds;
                        root.netTxRate = txDelta / dtSeconds;
                    } else {
                        root.netRxRate = 0;
                        root.netTxRate = 0;
                    }
                    root.networkState = "populated";
                    root.widgetState = "populated";
                }
                root._netPrev = { rx: netNow.rx, tx: netNow.tx, ts: nowMs };
            } else {
                root.networkState = "empty";
            }
        } catch (e) {
            root.networkState = "empty";
        }
    }

    // ── The storage reader (D-36, ~30s) ─────────────────────────────────
    // No kernel pseudo-file reports filesystem usage, so this one metric
    // needs a subprocess (T-14-20). Fixed argv, no shell, no interpolated
    // component: the `df` binary, a one-byte block-size flag, an output
    // selector restricting columns to size/used, and the root mount path.
    readonly property string dfPath: "df"

    Timer {
        id: slowTimer
        interval: root.slowPollInterval
        repeat: true
        running: root.drawerOpen
        // Reads promptly on open rather than making the very first storage
        // figure wait a full slow-cadence period — every subsequent read
        // still lands exactly slowPollInterval apart. Pure timer ergonomics,
        // not a change to the published cadence.
        triggeredOnStart: true
        onTriggered: {
            if (root.drawerOpen)
                storageProcess.running = true;
        }
    }

    Process {
        id: storageProcess
        running: false
        command: [root.dfPath, "-B1", "--output=size,used", "/"]
        stdout: StdioCollector {
            id: storageCollector
            onStreamFinished: root._onStorageStreamFinished()
        }
    }

    // Parses on the collector's stream-finished signal, not on process
    // exit — the last non-empty line (df's data row, after its header) is
    // split on whitespace; both fields must be finite numbers or the
    // previous storage values stand and the register drops to "empty". The
    // drawer-closed guard means a line arriving during teardown is dropped
    // rather than written into a property whose consumers are being
    // destroyed.
    function _onStorageStreamFinished() {
        if (!root.drawerOpen)
            return;
        try {
            var lines = (storageCollector.text || "").split("\n").filter(function (l) {
                return l.trim() !== "";
            });
            if (lines.length < 1) {
                root.storageState = "empty";
                return;
            }
            var fields = lines[lines.length - 1].trim().split(/\s+/);
            if (fields.length < 2) {
                root.storageState = "empty";
                return;
            }
            var size = Number(fields[0]);
            var used = Number(fields[1]);
            if (!isFinite(size) || !isFinite(used) || size <= 0) {
                root.storageState = "empty";
                return;
            }
            root.storageTotalBytes = size;
            root.storageUsedBytes = Math.max(0, used);
            root.storageFraction = Math.max(0, Math.min(1, used / size));
            root.storageState = "populated";
            root.widgetState = "populated";
        } catch (e) {
            root.storageState = "empty";
        }
    }

    // ── Battery ──────────────────────────────────────────────────────────
    // One named seam, defaulting to the real service — the only place
    // `UPower` is named. Every battery property below reads through this
    // seam, which is what lets Task 2 prove the populated path on hardware
    // with no battery by substituting a stub for one observation, then
    // reverting (T-14-21).
    property var batterySource: UPower.displayDevice

    readonly property bool batteryPresent: !!root.batterySource
        && root.batterySource.isLaptopBattery === true
        && root.batterySource.isPresent === true

    // The service documents charge level only as "Current charge level as a
    // percentage. This would be equivalent to energy / energyCapacity" —
    // implying a 0-to-1 fraction but never stating the range, and no
    // battery exists on this machine to settle it empirically (recorded
    // assumption, see must_haves). Guard: a value above 1 is read as a
    // hundred-based percentage; anything at or below 1 is read as an
    // already-normalised fraction. Accepted cost: a real sub-one-percent
    // charge level would misread as a fraction under this guard — a case
    // this hardware structurally cannot exercise. One conversion, one
    // comment, one line to correct the day this runs on a laptop.
    readonly property real batteryFraction: {
        if (!root.batteryPresent)
            return 0;
        var raw = root.batterySource.percentage;
        if (!isFinite(raw) || raw < 0)
            return 0;
        return raw > 1 ? Math.min(1, raw / 100) : Math.min(1, raw);
    }

    readonly property string batteryStateText: {
        if (!root.batteryPresent)
            return "";
        switch (root.batterySource.state) {
        case UPowerDeviceState.Charging:
            return "Charging";
        case UPowerDeviceState.Discharging:
            return "Discharging";
        case UPowerDeviceState.FullyCharged:
            return "Full";
        default:
            return "Unknown";
        }
    }

    // Populated only when the source reports present AND ready — otherwise
    // empty, which on this machine (no battery hardware) is the permanent
    // and correct answer.
    readonly property string batteryState: (root.batteryPresent
        && !!root.batterySource
        && root.batterySource.ready === true) ? "populated" : "empty"

    // ── Shared formatters — this phase's tab and 14-08's resources strip
    //    format identically without either copying the other. Every one
    //    returns a sane string for a non-finite/negative input rather than
    //    throwing, since all three are called from bindings. ─────────────
    function formatPercent(fraction) {
        if (!isFinite(fraction))
            return "0%";
        var pct = Math.round(Math.max(0, Math.min(1, fraction)) * 100);
        return pct + "%";
    }

    // Binary units (KiB/MiB/GiB/TiB), one decimal — correct here because
    // memory comes from a kibibyte-denominated kernel file and filesystem
    // sizes are conventionally reported the same way.
    function formatBytes(bytes) {
        if (!isFinite(bytes) || bytes < 0)
            return "0 B";
        var units = ["B", "KiB", "MiB", "GiB", "TiB"];
        var value = bytes;
        var unitIndex = 0;
        while (value >= 1024 && unitIndex < units.length - 1) {
            value /= 1024;
            unitIndex++;
        }
        return (unitIndex === 0 ? value.toFixed(0) : value.toFixed(1)) + " " + units[unitIndex];
    }

    // Decimal units (B/s, KB/s, MB/s, GB/s), one decimal — correct here for
    // the opposite reason: link rates are an SI-denominated quantity, and
    // mislabelling 1024-based steps as KB would be the small dishonesty
    // D-36's "a rate is not a percentage" instruction is written against.
    function formatRate(bytesPerSecond) {
        if (!isFinite(bytesPerSecond) || bytesPerSecond < 0)
            return "0 B/s";
        var units = ["B/s", "KB/s", "MB/s", "GB/s"];
        var value = bytesPerSecond;
        var unitIndex = 0;
        while (value >= 1000 && unitIndex < units.length - 1) {
            value /= 1000;
            unitIndex++;
        }
        return (unitIndex === 0 ? value.toFixed(0) : value.toFixed(1)) + " " + units[unitIndex];
    }
}
