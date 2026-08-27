// SystemResources.qml — the drawer's one shared resource reader (Phase 14
// Plan 06, DASH-05, D-36/D-39). Filled from 14-03's inert stub; the `Scope`
// root, `drawerOpen` gate and `widgetState` register below are 14-03's own
// contract, kept exactly where it left them.
//
// This is the ONE shared instance both PerformanceTab's four dials (this
// plan) and DashboardTab's resources strip (14-08) read — mounted once in
// shell.qml as a sibling of `dashboardLoader` (round-3 render-gate
// correction, defect B: moved OUT of Dashboard.qml, which is destroyed and
// rebuilt by the LazyLoader on every dismiss, so a warm cache of last-known
// readings across a close/reopen needs a mount that survives that — same
// reasoning shell.qml already applies to MediaBackend/WeatherBackend).
// `drawerOpen` is bound to `dashboardLoader.active`, not to this file's own
// lifetime, since this file's own lifetime no longer ends at dismiss.
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
// re-baselines through `_clearSamplingState()` rather than resuming from a
// stale sample: the first fast sample after a reset only establishes
// baselines (no CPU figure, no rate published that sample); the next one
// (primed in ~400ms later — see round-3 note on `onDrawerOpenChanged`, not
// left to wait for `fastTimer`'s own ~2s cadence) publishes real values.
//
// Round-3 warm-start addendum: only the reader's TRUE first-ever run
// (Component.onCompleted, once per session) resets the D-41 registers and
// published values to "pending"/zero. Every SUBSEQUENT re-summon leaves the
// last-known values and registers standing (a warm cache) while the primed
// samples above refresh them — so a repeat open reads instantly rather than
// flashing back to pending. That is what "pending" is for on first run only;
// it is not replayed on every open.
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
//
// ── 14-10 Task 2 addition: the GPU metric ────────────────────────────────
// A fifth reading, DASH-09. Unlike CPU/memory/network (a pseudo-file read)
// and unlike storage (a subprocess, but polled only every ~30s), the GPU
// figure comes from `nvidia-smi`, a subprocess spawn on a materially
// shorter, human-perceptible cadence — so it gets its own decision, not a
// silent reuse of an existing pattern:
//   - Sampling shape: one-shot fixed-argv queries on their own named
//     cadence (`gpuPollInterval`), copying the STORAGE metric's five
//     properties exactly (fixed argv, no shell; timer running bound to
//     drawerOpen; fire-on-start; collector guarded on drawerOpen; process
//     forced dead on close) — never a long-lived streaming query, because
//     this reader's whole subprocess idiom is a collector that fires once
//     when the stream FINISHES, and a stream that never finishes never
//     fires it. A rejected shape, not an unconsidered one.
//   - The binary seam (`gpuQueryPath`) is declared WITHOUT `readonly`,
//     unlike `dfPath` above — deliberately, because it is the one seam this
//     plan's synthetic no-GPU verification substitutes, and only a non-
//     readonly property can be. It follows `dfPath`'s SHAPE (a bare command
//     name, consumed as element zero of a fixed argv array) and `batterySource`'s
//     MUTABILITY (the one other seam a prior plan actually substituted a
//     fault into).
//   - Absent/non-NVIDIA hardware: the dial is ALWAYS PRESENT and renders
//     the D-41 empty state — never omitted — because omission would make
//     the drawer's WIDTH a function of GPU hardware (the fresh-Arch-install
//     constraint, `.claude/CLAUDE.md`). All three failure shapes (binary
//     absent, binary present reporting no devices, binary present exiting
//     non-zero) land in the identical empty state via one shared handler,
//     `_onGpuProbeFinished()`.
//   - The one-shot presence probe (`gpuProbeProcess`) fires on the first
//     real open only, exactly like `hwmonDiscoveryProcess` above, and
//     determines `gpuAvailable` for the rest of the session — the sample
//     timer's own `running` binding cannot fire before this answers and
//     cannot fire while the drawer is closed.
//   - In-flight overlap: `_gpuSampleInFlight` guards every tick. A tick
//     that arrives while the previous query is still running is SKIPPED,
//     never queued or restarted — the dial holds its last value and its
//     state register does not move.
// See 14-10-SUMMARY.md for the live proof of every one of these decisions.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
// Prefs (quick task 260825-wj2 Task 6) — the modules/-root `qs.modules`
// manifest, the same relative import Design.qml already uses.
import "../"

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
    // Quick task 260825-wj2 Task 6 — Services page's "System stats
    // refresh" stepper (seconds in the UI, ms in Prefs — the reference's
    // own convention). The literal `2000` stays as Prefs' own `_defaults`
    // value, so an install that never opens that page is unaffected.
    readonly property int fastPollInterval: Prefs.getValue("services.resourcesPollMs")
    readonly property int slowPollInterval: 30000
    // The short first CPU/network delta window. Named here in 14-09 rather
    // than left as a bare `interval: 400` on primeTimer — this block's own
    // header promises no timer below carries a bare number, and round-3's
    // primeTimer was quietly breaking that promise. motion-lint's CHECK B
    // is anchored on a lowercase `duration:` and cannot see an `interval:`,
    // so nothing but this source assertion was ever going to catch it.
    readonly property int primeSampleWindow: 400
    readonly property int cpuSampleWindow: 3
    // GPU cadence (14-10 Task 2) — deliberately TWICE `fastPollInterval`,
    // and the reason is the mechanism, not a preference: this is a
    // subprocess spawn (`nvidia-smi`), materially heavier than the pseudo-
    // file reads every other fast metric here uses, while storage's own
    // subprocess gets 15x this cadence because filesystem usage changes far
    // more slowly than GPU load. The dial's own value transition already
    // smooths the arc between samples, and the drawer is a summoned overlay
    // typically up for only seconds, so fire-on-start behaviour matters more
    // to how live this reads than the steady-state period does. A starting
    // point the gate may retune — named here precisely so retuning it is a
    // one-word edit, not a hunt through this file.
    readonly property int gpuPollInterval: 4000

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
    // CPU temperature (Celsius) and current frequency (GHz) — render-gate
    // round 2's Caelestia-look feedback ("more details"). Both are NaN
    // until a real read lands; PerformanceTab.qml composes whichever of
    // the two resolved into the CPU dial's detail line and silently omits
    // whichever did not, rather than showing a broken half-string.
    property real cpuTempCelsius: NaN
    property real cpuFreqGHz: NaN

    // ── GPU metric (14-10 Task 2, DASH-09) — see the file header's own
    //    "GPU metric" section for the full design record. `gpuAvailable`
    //    is decided ONCE, by the one-shot probe, and never revisited by the
    //    recurring sampler — a mid-session sample failure (in-flight skip,
    //    a transient non-zero exit) leaves the last-known values standing
    //    and does not flip this back to false. ───────────────────────────
    property real gpuFraction: 0
    property real gpuUsedBytes: 0
    property real gpuTotalBytes: 0
    property string gpuName: ""
    property bool gpuAvailable: false

    // ── Identity readings (quick task 260827-50i) ───────────────────────
    // Three static-or-slow facts that no existing consumer needed, added
    // for the two Caelestia-derived layouts: `cpuName` is P1's hero-card
    // subtitle (the counterpart to `gpuName`, which already existed and is
    // why P1's cost note read "SystemResources: device names"); `uptimeText`
    // and `distroName` are D1's identity cell.
    //
    // None of them is a D-41 metric and none carries a state register: they
    // are labels, not readings. An unreadable source leaves the string
    // empty and the consuming layout composes around it — the same quiet-
    // failure posture `cpuFreqGHz` already takes, and for the same reason
    // (a container or a VM missing one of these is not an error worth a log
    // line, let alone an "Unavailable" chip in the UI).
    //
    // `cpuName` and `distroName` cannot change while the shell is running,
    // so both are read ONCE on the first real drawer open and cached
    // forever — the same zero-idle doctrine as the hwmon and GPU probes.
    // `uptimeSeconds` obviously does change, so it rides the existing ~30s
    // slow timer rather than adding a fourth cadence; a minute-resolution
    // readout does not need the 2s fast poll.
    property string cpuName: ""
    property string distroName: ""
    property real uptimeSeconds: 0

    // Formatted for direct display: "4h 12m", "12m", "3d 4h". Deliberately
    // at most two components — an uptime line is a glance, and "3d 4h 12m
    // 9s" is four facts where one was wanted. Empty until the first read so
    // a consumer can tell "not yet" from "zero minutes".
    readonly property string uptimeText: {
        if (!(root.uptimeSeconds > 0))
            return "";
        var total = Math.floor(root.uptimeSeconds);
        var d = Math.floor(total / 86400);
        var h = Math.floor((total % 86400) / 3600);
        var m = Math.floor((total % 3600) / 60);
        if (d > 0)
            return d + "d " + h + "h";
        if (h > 0)
            return h + "h " + m + "m";
        return m + "m";
    }

    // One-shot guards, mirroring `_hwmonDiscoveryDone`/`_gpuProbeDone`.
    property bool _identityReadDone: false

    // ── Per-metric D-41 state registers ─────────────────────────────────
    property string cpuState: "empty"
    property string memoryState: "empty"
    property string storageState: "empty"
    property string networkState: "empty"
    property string gpuState: "empty"
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

    // ── Rolling history (quick task 260826-rfy, P3 "Telemetry Strip") ───
    // The design study's finding was that every reading this reader
    // publishes is INSTANTANEOUS — nothing here could answer "is this
    // climbing?", which is the question a performance tab exists for. These
    // four buffers are that missing time axis.
    //
    // Oldest-first, newest LAST, so a consumer draws left-to-right by index
    // with no reversal. Values are the same units the scalar properties
    // publish: cpu/gpu are 0..1 fractions, the two net buffers are bytes/sec
    // (NOT normalised — a rate has no ceiling to normalise against, which is
    // D-36's standing rule and the reason the rate row was never a dial).
    //
    // `historyLength` is a CAP, not a guarantee: a buffer is short until it
    // fills, and a consumer must render a partial buffer rather than waiting.
    // At the default 2000ms fast poll, 60 samples is a two-minute window.
    readonly property int historyLength: 60
    property var cpuHistory: []
    property var gpuHistory: []
    property var netRxHistory: []
    property var netTxHistory: []

    // Every buffer goes through here. Reassigns rather than mutating in
    // place: this file's own header records that a `property var` notifies
    // on REASSIGNMENT only, so an in-place push would update the array and
    // never repaint the consumer — the exact trap `_cpuSamples` above is
    // already written around.
    function _pushHistory(buf, value) {
        if (!isFinite(value))
            return buf;
        var next = buf.slice();
        next.push(value);
        while (next.length > root.historyLength)
            next.shift();
        return next;
    }

    // Largest value in a buffer, floored at `floorValue` so a flat-zero
    // series still yields a usable scale instead of dividing by zero. Lives
    // here rather than in the drawing code because both the sparkline and any
    // future readout need the SAME ceiling to agree on.
    function historyMax(buf, floorValue) {
        var m = floorValue;
        for (var i = 0; i < buf.length; i++)
            if (isFinite(buf[i]) && buf[i] > m)
                m = buf[i];
        return m;
    }

    // Clears every stored baseline AND drops every per-metric register back
    // to "pending" — the full first-run reset. Called ONLY from
    // Component.onCompleted, i.e. exactly once per session, since nothing is
    // cached yet the very first time this reader exists. A re-summon later
    // in the session does NOT call this — see `_clearSamplingState()` below
    // and the round-3 warm-cache note on `onDrawerOpenChanged`.
    function resetBaselines() {
        root._clearSamplingState();
        root.cpuState = "pending";
        root.memoryState = "pending";
        root.networkState = "pending";
        root.storageState = "pending";
        // GPU starts "pending" too, exactly like its four siblings — even
        // though it may end this session's FIRST open at "empty" instead of
        // "populated" (the one-shot probe hasn't run yet at this point,
        // Component.onCompleted, so which of the two it will resolve to is
        // not yet known). `gpuAvailable`/`_gpuProbeDone` are NOT reset here:
        // this function runs exactly once per session (Component.onCompleted
        // only) and their compiled-in defaults (false) are already correct
        // at that point — see the file header's GPU section.
        root.gpuState = "pending";
        root.widgetState = "pending";
        // Once per session (this function's own contract) — see the note in
        // `_clearSamplingState()` for why the re-summon path must not do this.
        root.cpuHistory = [];
        root.gpuHistory = [];
        root.netRxHistory = [];
        root.netTxHistory = [];
    }

    // Round-3 render-gate defect B ("takes a few seconds for the readings
    // to come in, CPU last — reads as clunky"). Clears ONLY the internal
    // delta-tracking baselines that CPU/network correctness requires on
    // every re-summon (the untouchable invariant: a rate/fraction must
    // never be computed as an average smeared across the whole time the
    // drawer sat closed) — and deliberately leaves every PUBLISHED metric
    // and D-41 register standing exactly as it was. That is the warm
    // cache: a repeat open shows last-known values instantly instead of
    // flashing back to "pending"/"—", while a genuinely fresh sample is
    // primed in behind it (see onDrawerOpenChanged) and glides onto screen
    // via Dial.qml's existing motion-token Behavior once it lands.
    function _clearSamplingState() {
        root._cpuPrevTotals = null;
        root._cpuSamples = [];
        root._netPrev = null;
        // The four 260826-rfy history buffers are deliberately NOT cleared
        // here. This function runs on every RE-SUMMON (see the warm-start
        // note below), and its own contract above is that it re-baselines
        // delta state and "never the displayed values". A history buffer is
        // a displayed value — clearing it here would blank every sparkline
        // each time the drawer opens, which is precisely the two-minute
        // window the telemetry layout exists to show. They are cleared in
        // `resetBaselines()` instead, which runs once per session.
    }

    Component.onCompleted: root.resetBaselines()

    // Round-3 warm-start priming: a re-summon re-baselines the DELTA state
    // (never the displayed values — see `_clearSamplingState()` above) and
    // then immediately fires two samples rather than waiting for
    // `fastTimer`'s own next tick, which would otherwise land a full
    // `fastPollInterval` (~2s) later and, since CPU/network are delta-based,
    // need a SECOND tick after that before their first real figure exists —
    // "a few seconds, CPU last" was exactly this wait made visible.
    //   Sample #1 (synchronous, below): establishes the fresh CPU/network
    //     baseline (publishes nothing new for either — by design, see
    //     `sampleFast()`) while ALSO publishing a live memory figure
    //     immediately, since memory needs no delta at all.
    //   Sample #2 (`primeTimer`, ~400ms later): a SHORT first delta window
    //     — long enough for a real, if slightly noisy, CPU/network read,
    //     short enough that first paint lands well under a second — after
    //     which `fastTimer` (already running since the block below) takes
    //     over on the normal ~2s cadence.
    // First-EVER open (nothing cached yet) can still show dials filling in
    // from empty — that is fine and expected. It is the repeat-open case
    // this priming makes feel instant.
    onDrawerOpenChanged: {
        if (root.drawerOpen) {
            root._clearSamplingState();
            root.sampleFast();
            primeTimer.restart();
            if (!root._hwmonDiscoveryDone) {
                // One-shot hwmon path discovery, fired on the first real
                // open only — never again afterwards, cached in
                // `_cpuTempPath` (zero-idle doctrine: a day the drawer is
                // never summoned spawns nothing).
                hwmonDiscoveryProcess.running = true;
            }
            if (!root._gpuProbeDone) {
                // One-shot GPU presence probe (14-10 Task 2) — same shape
                // as hwmon discovery immediately above: fired on the first
                // real open only, cached forever in `gpuAvailable`/
                // `gpuName`. Not force-stopped in the closed branch below,
                // for the same reason hwmon discovery isn't — a fixed-argv
                // `nvidia-smi` query returns in well under a second.
                gpuProbeProcess.running = true;
            }
            // Third one-shot, same doctrine as the two above (260827-50i):
            // CPU model and distro name, read on the first real open only.
            // No subprocess at all for this one — three synchronous procfs/
            // sysfs reads, so it is cheaper than either probe above.
            root.readIdentityOnce();
        } else {
            // Force the storage subprocess dead the instant the drawer
            // closes so an in-flight `df` read cannot outlive this surface
            // (T-14-20) — a torn-down consumer receiving a late collector
            // signal is a use-after-teardown hazard, not merely wasted work.
            storageProcess.running = false;
            // Same reasoning, same discipline, for the GPU sample process
            // (14-10 Task 2) — an in-flight `nvidia-smi` query must not
            // outlive the drawer either.
            gpuSampleProcess.running = false;
            // The priming sample is single-shot and already guards itself
            // on `drawerOpen` (see below), but stopping it here too means a
            // rapid close-then-reopen never leaves a stale one-shot armed
            // from the PREVIOUS open still pending.
            primeTimer.stop();
        }
    }

    // Round-3: the short first CPU/network delta window (300-500ms) named
    // in the checkpoint — deliberately NOT `fastPollInterval`, which stays
    // the steady-state ~2s cadence untouched below.
    Timer {
        id: primeTimer
        interval: root.primeSampleWindow
        repeat: false
        onTriggered: {
            if (root.drawerOpen)
                root.sampleFast();
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

    // ── Identity sources (quick task 260827-50i) ────────────────────────
    // Same blocking-read triple as the metric files above, for the same
    // reason: these are procfs/sysfs reads measured in microseconds, and a
    // synchronous read is the only shape that composes with the
    // reload()/waitForJob()/text() sequence this file already uses
    // everywhere. `printErrors: false` on all three — see the quiet-failure
    // note on the property declarations.
    FileView {
        id: cpuinfoFile
        path: "/proc/cpuinfo"
        preload: false
        blockLoading: true
        blockAllReads: true
        printErrors: false
    }
    FileView {
        id: osReleaseFile
        path: "/etc/os-release"
        preload: false
        blockLoading: true
        blockAllReads: true
        printErrors: false
    }
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        preload: false
        blockLoading: true
        blockAllReads: true
        printErrors: false
    }

    // Read once, cached forever. Called from the first real drawer open.
    function readIdentityOnce() {
        if (root._identityReadDone)
            return;
        root._identityReadDone = true;

        // /proc/cpuinfo: the first "model name" line. Every core repeats
        // it, so the first match is the answer and scanning further is
        // wasted work on a 64-thread machine's 2000-line file.
        try {
            cpuinfoFile.reload();
            cpuinfoFile.waitForJob();
            var cpuLines = (cpuinfoFile.text() || "").split("\n");
            for (var i = 0; i < cpuLines.length; i++) {
                // ARM and some VMs report "Model" or "Hardware" instead of
                // "model name"; matching the x86 key only is deliberate —
                // a wrong-but-plausible label is worse here than none, and
                // the consuming card already composes around an empty
                // string.
                if (cpuLines[i].indexOf("model name") === 0) {
                    var colon = cpuLines[i].indexOf(":");
                    if (colon >= 0) {
                        root.cpuName = cpuLines[i].substring(colon + 1).trim();
                    }
                    break;
                }
            }
        } catch (eCpu) {
            root.cpuName = "";
        }

        // /etc/os-release: PRETTY_NAME, falling back to NAME. Values may be
        // double-quoted per the os-release spec, so strip one matched pair
        // — never a blind character trim, which would eat a legitimate
        // trailing quote from a distro that ships one.
        try {
            osReleaseFile.reload();
            osReleaseFile.waitForJob();
            var osLines = (osReleaseFile.text() || "").split("\n");
            var pretty = "";
            var plain = "";
            for (var j = 0; j < osLines.length; j++) {
                var line = osLines[j].trim();
                if (line.indexOf("PRETTY_NAME=") === 0)
                    pretty = line.substring("PRETTY_NAME=".length);
                else if (line.indexOf("NAME=") === 0)
                    plain = line.substring("NAME=".length);
            }
            var picked = pretty !== "" ? pretty : plain;
            if (picked.length >= 2 && picked.charAt(0) === '"'
                && picked.charAt(picked.length - 1) === '"') {
                picked = picked.substring(1, picked.length - 1);
            }
            root.distroName = picked;
        } catch (eOs) {
            root.distroName = "";
        }
    }

    // /proc/uptime's first field is seconds since boot as a float. Called
    // from the slow timer, which already fires on drawer open.
    function readUptime() {
        try {
            uptimeFile.reload();
            uptimeFile.waitForJob();
            var first = ((uptimeFile.text() || "").trim().split(/\s+/))[0];
            var secs = parseFloat(first);
            if (isFinite(secs) && secs >= 0)
                root.uptimeSeconds = secs;
        } catch (eUp) {
            // Previous value stands — an uptime that briefly fails to read
            // has not reset to zero, and showing "0m" would be a lie.
        }
    }

    // CPU frequency (round 2 detail) — a fixed, stable sysfs path (every
    // amd_pstate/intel_pstate/acpi-cpufreq-driven machine has a cpu0), so
    // unlike the temperature sensor below this needs no discovery at all.
    // kHz on read; converted to GHz where consumed.
    FileView {
        id: cpuFreqFile
        path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
        preload: false
        blockLoading: true
        blockAllReads: true
        // Quiet failure only: a machine with no cpufreq sysfs interface
        // (a container, a VM) simply never populates cpuFreqGHz, and the
        // CPU dial's detail line composes around its absence — not worth
        // a log line every 2s on such a machine.
        printErrors: false
    }

    // CPU temperature (round 2 detail) — unlike cpu0's cpufreq path, the
    // hwmon device that reports package temperature (k10temp on this AMD
    // machine) is NOT at a fixed index: hwmon numbering is assigned by
    // driver-probe order, which varies across boots and across different
    // machines (RESEARCH's own "don't hand-roll/don't guess a path"
    // discipline applies here exactly as it did to the battery seam).
    // Resolved ONCE via a fixed-argv `grep -l` over a bounded, literal
    // candidate list (no shell, no interpolation, same T-14-20 discipline
    // the storage subprocess follows) the first time the drawer opens, then
    // cached forever in `_cpuTempPath` — a day the drawer is never summoned
    // still spawns nothing (zero-idle doctrine).
    readonly property var _hwmonNameCandidates: {
        var arr = [];
        for (var i = 0; i < 16; i++)
            arr.push("/sys/class/hwmon/hwmon" + i + "/name");
        return arr;
    }
    property bool _hwmonDiscoveryDone: false
    property string _cpuTempPath: ""

    Process {
        id: hwmonDiscoveryProcess
        running: false
        command: ["grep", "-l", "k10temp"].concat(root._hwmonNameCandidates)
        stdout: StdioCollector {
            id: hwmonDiscoveryCollector
            onStreamFinished: root._onHwmonDiscovered()
        }
    }

    function _onHwmonDiscovered() {
        root._hwmonDiscoveryDone = true;
        hwmonDiscoveryProcess.running = false;
        try {
            var lines = (hwmonDiscoveryCollector.text || "").split("\n").filter(function (l) {
                return l.trim() !== "";
            });
            if (lines.length > 0)
                root._cpuTempPath = lines[0].trim().replace(/\/name$/, "/temp1_input");
        } catch (e) {
            root._cpuTempPath = "";
        }
    }

    FileView {
        id: cpuTempFile
        path: root._cpuTempPath
        preload: false
        blockLoading: true
        blockAllReads: true
        printErrors: false
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
                        root.cpuHistory = root._pushHistory(root.cpuHistory, root.cpuFraction);
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
                    // Both branches above have published a rate by now (the
                    // re-baseline branch publishes an honest 0), so the
                    // buffers advance on every populated tick — a gap in the
                    // series would misread as a flat line rather than a
                    // missing sample.
                    root.netRxHistory = root._pushHistory(root.netRxHistory, root.netRxRate);
                    root.netTxHistory = root._pushHistory(root.netTxHistory, root.netTxRate);
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

        // ── CPU frequency + temperature (round 2 detail) ──
        // Neither failure here touches `cpuState` — a missing/unreadable
        // sensor is a quiet detail-line omission, not a reason to drop the
        // CPU dial's own percentage figure to empty.
        try {
            cpuFreqFile.reload();
            cpuFreqFile.waitForJob();
            var khz = Number((cpuFreqFile.text() || "").trim());
            if (isFinite(khz) && khz > 0)
                root.cpuFreqGHz = khz / 1e6;
        } catch (e) {
            // leave the previous value standing
        }
        if (root._cpuTempPath !== "") {
            try {
                cpuTempFile.reload();
                cpuTempFile.waitForJob();
                var milliC = Number((cpuTempFile.text() || "").trim());
                if (isFinite(milliC))
                    root.cpuTempCelsius = milliC / 1000;
            } catch (e) {
                // leave the previous value standing
            }
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
            if (!root.drawerOpen)
                return;
            storageProcess.running = true;
            // Uptime rides this cadence rather than adding a fourth timer
            // (260827-50i). `triggeredOnStart` above means the first read
            // lands on open, so D1's identity cell is never blank-then-
            // populated a full 30s later.
            root.readUptime();
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

    // ── The GPU metric (14-10 Task 2, D-36 extended by the same reasoning
    //    already applied to storage) — see the file header's own "GPU
    //    metric" section for the full design record. ─────────────────────
    // The binary seam. A bare command name (matching `dfPath`'s shape
    // above), consumed as element zero of a fixed argv array — deliberately
    // NOT `readonly` (matching `batterySource`'s mutability, not `dfPath`'s
    // immutability): this is the one seam this plan's synthetic no-GPU
    // verification substitutes, in-tree, with a hot reload between each
    // case, and only a non-readonly property can be substituted this way.
    // The absent `readonly` is LOAD-BEARING for verification, not an
    // oversight — do not "tidy" it away.
    property string gpuQueryPath: "nvidia-smi"

    // One-shot presence probe state — parallels `_hwmonDiscoveryDone`/
    // `_cpuTempPath` above exactly: fired on the first real open only,
    // cached forever, so a session that never summons the drawer spawns
    // nothing (zero-idle doctrine).
    property bool _gpuProbeDone: false
    // Tracks whether `onExited` has already fired for the CURRENT probe
    // run, so `onRunningChanged`'s false-transition can tell "the process
    // exited normally (already handled)" apart from "the process layer
    // failed to start it (exited never fires for that case — confirmed
    // live, see 14-10-SUMMARY.md's Task 1... Task 2 render evidence)".
    property bool _gpuProbeExitSeen: false
    // Same pattern, for the recurring sampler.
    property bool _gpuSampleInFlight: false
    property bool _gpuSampleExitSeen: false

    Process {
        id: gpuProbeProcess
        running: false
        // Name only — no numeric fields, no unit suffixes needed. The name
        // is stable and wanted once; it is deliberately NOT re-requested on
        // every sample (see the per-sample query below and the file header
        // for why).
        command: [root.gpuQueryPath, "--query-gpu=name", "--format=csv,noheader"]
        stdout: StdioCollector {
            id: gpuProbeCollector
        }
        onExited: (exitCode, exitStatus) => {
            root._gpuProbeExitSeen = true;
            root._onGpuProbeFinished(exitCode, gpuProbeCollector.text);
        }
        onRunningChanged: {
            if (gpuProbeProcess.running) {
                root._gpuProbeExitSeen = false;
            } else if (!root._gpuProbeExitSeen) {
                // The process layer failed to start it (binary missing at
                // this path) — `onExited` never fires for this shape.
                // Treated identically to "reports no devices"/"exits non-
                // zero": DECISION 2's designed empty state, all three
                // failure shapes landing in one place.
                root._onGpuProbeFinished(-1, "");
            }
        }
    }

    // All three synthetic failure shapes this plan verifies converge here:
    // binary absent (exitCode -1, sentinel from the branch above, no real
    // process ever ran), binary present but reporting no devices (exitCode
    // 0, empty/blank name line), binary present but exiting non-zero
    // (exitCode != 0). Every one sets `gpuAvailable: false` and
    // `gpuState: "empty"` — the designed placeholder, at identical
    // footprint, never an omitted dial (DECISION 2).
    function _onGpuProbeFinished(exitCode, text) {
        root._gpuProbeDone = true;
        var name = ((text || "").split("\n")[0] || "").trim();
        if (exitCode === 0 && name !== "") {
            root.gpuName = name;
            root.gpuAvailable = true;
            // gpuState stays "pending" (set by resetBaselines()) until the
            // sample timer's own first tick — bound below on
            // `drawerOpen && gpuAvailable`, fire-on-start — lands a real
            // reading and flips it to "populated", mirroring how
            // `cpuState` only flips once a real post-baseline value exists.
        } else {
            root.gpuAvailable = false;
            root.gpuName = "";
            root.gpuState = "empty";
        }
    }

    // The recurring sampler. Cannot run before the probe has answered
    // (`gpuAvailable`) and cannot run while the drawer is down
    // (`drawerOpen`) — both conditions in one `running` binding, so no
    // separate start/stop call site can drift out of sync with either.
    Timer {
        id: gpuSampleTimer
        interval: root.gpuPollInterval
        repeat: true
        running: root.drawerOpen && root.gpuAvailable
        triggeredOnStart: true
        onTriggered: {
            if (!root.drawerOpen || !root.gpuAvailable)
                return;
            if (root._gpuSampleInFlight) {
                // In flight when the next tick fires: skip. Never queued,
                // never a second process spawned. The dial holds its last
                // value; `gpuState` does not move. Exercised deliberately
                // against a scratch slow-answering stub — see
                // 14-10-SUMMARY.md.
                return;
            }
            root._gpuSampleInFlight = true;
            root._gpuSampleExitSeen = false;
            gpuSampleProcess.running = true;
        }
    }

    Process {
        id: gpuSampleProcess
        running: false
        // Numeric fields only, no unit suffixes (`nounits`) — the parse is
        // numeric rather than string-peeling. No name field: unlike the
        // numeric fields, a name could in principle contain the CSV
        // separator this output format uses, mis-indexing every field
        // after it — the name comes from the one-shot probe instead (see
        // the file header).
        command: [root.gpuQueryPath, "--query-gpu=utilization.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            id: gpuSampleCollector
        }
        onExited: (exitCode, exitStatus) => {
            root._gpuSampleExitSeen = true;
            root._gpuSampleInFlight = false;
            if (!root.drawerOpen)
                return; // torn-down consumer guard, mirrors storage's own
            if (exitCode === 0)
                root._onGpuSampleFinished(gpuSampleCollector.text);
            // A non-zero exit leaves the last-known values standing — a
            // slow or failed sample is not a missing metric.
        }
        onRunningChanged: {
            if (gpuSampleProcess.running) {
                root._gpuSampleExitSeen = false;
            } else if (!root._gpuSampleExitSeen) {
                // Process layer failed to start this tick's query (or this
                // Process was force-stopped on drawer close, see
                // `onDrawerOpenChanged` above) — either way, release the
                // in-flight guard so the NEXT open/tick is never
                // permanently stuck skipping.
                root._gpuSampleInFlight = false;
            }
        }
    }

    function _onGpuSampleFinished(text) {
        try {
            var line = (text || "").split("\n")[0] || "";
            var parts = line.split(",").map(function (s) {
                return s.trim();
            });
            if (parts.length < 3)
                return;
            var util = Number(parts[0]);
            var usedMiB = Number(parts[1]);
            var totalMiB = Number(parts[2]);
            if (!isFinite(util) || !isFinite(usedMiB) || !isFinite(totalMiB) || totalMiB <= 0)
                return;
            // MiB (nvidia-smi's default memory unit even with `nounits`,
            // which strips only the printed suffix, not the magnitude) ->
            // bytes, so the shared byte formatter the other dials already
            // use formats this identically.
            root.gpuFraction = Math.max(0, Math.min(1, util / 100));
            root.gpuHistory = root._pushHistory(root.gpuHistory, root.gpuFraction);
            root.gpuUsedBytes = usedMiB * 1024 * 1024;
            root.gpuTotalBytes = totalMiB * 1024 * 1024;
            root.gpuState = "populated";
            root.widgetState = "populated";
        } catch (e) {
            // leave previous values standing
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
