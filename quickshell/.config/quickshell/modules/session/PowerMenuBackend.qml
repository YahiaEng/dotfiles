// PowerMenuBackend.qml — QPOWER-03's three safety detectors (Phase 20 Plan
// 07, D-20-27..30). Non-visual (`Scope` root — CapsLockBackend.qml's/
// AudioBackend.qml's own precedent for a non-singleton, Process/Timer-
// bearing backend type), instantiated once inside `PowerMenu.qml` and bound
// to that surface's own visibility — never a singleton, since a singleton
// would have no natural "menu is open" lifetime to bind a Timer's `running`
// to.
//
// ── Warn only, never a gate (D-20-28, T-20-07-02) ─────────────────────────
// This file exposes three READ-ONLY booleans (plus one count) and NOTHING
// that any pill's `enabled`/`opacity` could bind to disable it. A stuck or
// wedged detector can, at worst, leave a stale warning line showing — it can
// NEVER lock the user out of powering their own machine down. That
// invariant is enforced by PowerMenu.qml (Task 2), not by this file, but
// this file's own contract is what makes it possible: three plain booleans,
// no verb that blocks anything.
//
// ── Three detectors (D-20-27) ─────────────────────────────────────────────
// 1. Package-manager-busy — `pgrep -x` on each of pacman/paru/yay's EXACT
//    process name. Deliberately NOT `/var/lib/pacman/db.lck`: D-20-27
//    rejects lockfile detection explicitly — a stale lock left behind by a
//    crashed pacman would warn on every future shutdown forever, and a
//    warning that always fires is one a user stops reading. `pgrep -x`
//    true-positives correctly even on a pacman that is itself blocked
//    waiting on its own lock (the more conservative, still-correct signal),
//    and a process merely named similarly never false-positives. Measured
//    live at 0.016s wall for a single `pgrep -x pacman`
//    (20-RESEARCH.md § Priority Research Findings item 1) — negligible for
//    this low-frequency poll.
// 2. Active downloads — end-4's own second check, deliberately a HEURISTIC
//    and recorded as one: a recent `.part`/`.crdownload` file under
//    `~/Downloads`. A download tool that names its partial file differently
//    is invisible to this check; a stale partial left behind by an
//    abandoned download reads as "active" until it is removed. Both
//    limitations are accepted, not hidden.
// 3. Toplevel count against a hand-maintained window-class deny-list —
//    recorded HONESTLY, in D-20-27's own words: this is a hand-maintained
//    list, not a detector. It warns about what it was told to warn about.
//    It is the bounded stand-in for the unkillable-client hazard; the
//    hazard ITSELF is characterised by LEDGER-02
//    (20-LEDGER-02-RECORD.md), never by this list. `denyListClasses` below
//    is the one place to edit it — additions are expected, and an empty
//    list is a valid, warning-free configuration.
//
// ── Single-flight round guard (T-20-07-01) ────────────────────────────────
// One low-frequency `Timer`, running ONLY while `active` is true (bound
// externally by PowerMenu.qml to the window's own `visible` — never
// Component.onCompleted, never an unconditional `true`: nothing runs while
// the menu is dismissed, the standing zero-idle rule, D-20-30). Each tick
// calls `_runDetectors()`, which checks whether ANY of the three detector
// `Process` objects from the previous round is still `.running` — if so,
// the WHOLE tick is SKIPPED, never queued, so two rounds can never overlap
// or accumulate, matching `BrightnessBackend.qml`'s own
// `adjustProcess.running` single-flight guard, applied here to a
// three-Process round rather than a single writer. `onActiveChanged` runs
// one round immediately the moment the menu becomes visible, so the first
// result does not wait a full poll interval (D-20-30's own "checked on
// open, THEN polled" ordering).
//
// ── Trust boundary (T-20-07-03) ───────────────────────────────────────────
// Every `Process.command` below is a fixed literal array, written verbatim
// — nothing is built by string concatenation or interpolation, and no
// detector's own output is ever fed into a further command. The deny-list
// comparison happens entirely IN-PROCESS (a plain JS loop over parsed JSON),
// never passed to `hyprctl`'s own arguments — `hyprctl -j clients` is
// invoked with the identical fixed argv regardless of what the deny-list
// currently contains.
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    // ── Public contract — three independent read-only states + one count.
    //    Nothing here is a verb; nothing here can disable anything. ───────
    readonly property bool pkgManagerBusy: _pkgManagerBusy
    readonly property bool downloadsActive: _downloadsActive
    readonly property bool denyListActive: _denyListCount > 0
    readonly property int denyListCount: _denyListCount

    property bool _pkgManagerBusy: false
    property bool _downloadsActive: false
    property int _denyListCount: 0

    // Bound externally to the power menu's own visibility (D-20-30) — set
    // by PowerMenu.qml, never assigned here. Driving the poll Timer's
    // `running` off this (rather than off Component.onCompleted or an
    // unconditional `true`) is the whole zero-idle mechanism: nothing below
    // spawns a single child process while this is false.
    property bool active: false

    // ── Detector 3's deny-list (D-20-27 item 3) — a single named,
    //    hand-maintained property, editable in exactly one place. Compared
    //    case-insensitively against `hyprctl -j clients`' own "class"
    //    field, entirely in-process (see file header). Starting contents
    //    (Claude's Discretion, per 20-CONTEXT.md's own "Claude's
    //    Discretion" list) — no live reproduction of an unkillable client
    //    was available on this host this session, so the seed is two
    //    widely-known classes that hold local transactional state across a
    //    session and are known to stall or prompt rather than exit
    //    cleanly on SIGTERM: Steam (library/download-cache writes) and
    //    GIMP (unsaved-image autosave prompt). An EMPTY list is equally
    //    valid and produces zero warnings from this detector — this is not
    //    a mandatory minimum, just a defensible starting point. Append
    //    here, nowhere else.
    readonly property var denyListClasses: ["steam", "gimp"]

    readonly property string downloadsDir: Quickshell.env("HOME") + "/Downloads"

    // A functional POLL cadence, not an animation duration — named here
    // rather than written as a bare `interval: 3000` literal, the same
    // reasoning `Osd.qml`'s own `_tickerIntervalMs` comment already
    // records: this keeps a scheduler interval off motion-lint's raw-
    // duration reach and off the motion-scale axis. A poll cadence
    // shrinking at a reduced motion-scale preset would be a bug, not an
    // accessibility feature.
    readonly property int _pollIntervalMs: 3000

    // ── Single-flight round dispatch — see file header. ───────────────────
    function _runDetectors() {
        if (pkgManagerProcess.running || downloadsProcess.running || denyListProcess.running) {
            // Previous round still in flight — SKIPPED, never queued
            // (T-20-07-01). Two rounds never overlap or accumulate.
            return;
        }
        pkgManagerProcess.running = true;
        downloadsProcess.running = true;
        denyListProcess.running = true;
    }

    // ── Detector 1 — package manager busy ─────────────────────────────────
    // Three fixed `pgrep -x` checks chained with shell `||` inside ONE
    // literal command array (the array itself is written verbatim, never
    // assembled from a variable at runtime) — exits 0 the moment any one of
    // the three matches, 1 if none do. A missing `pgrep` binary also exits
    // non-zero here and degrades to "not busy", never a distinct error
    // state (D-20-27's own "reports nothing" framing, restated for every
    // detector below).
    Process {
        id: pkgManagerProcess
        command: ["sh", "-c", "pgrep -x pacman >/dev/null 2>&1 || pgrep -x paru >/dev/null 2>&1 || pgrep -x yay >/dev/null 2>&1"]
        onExited: (exitCode, exitStatus) => {
            root._pkgManagerBusy = exitCode === 0;
        }
    }

    // ── Detector 2 — active downloads, a heuristic ─────────────────────────
    // `-quit` after the first match keeps this cheap regardless of
    // directory size. `root.downloadsDir` is a plain resolved-once property
    // read as its own array element below — never concatenated inline into
    // the command array itself (T-18-12-01's own argument-construction
    // discipline, applied here exactly as `BrightnessBackend.qml`'s device
    // name already is).
    Process {
        id: downloadsProcess
        command: ["find", root.downloadsDir, "-maxdepth", "1", "(", "-iname", "*.part", "-o", "-iname", "*.crdownload", ")", "-print", "-quit"]
        stdout: StdioCollector {
            id: downloadsCollector
        }
        onExited: (exitCode, exitStatus) => {
            // A missing/unreadable Downloads directory also exits non-zero
            // here and degrades to "no active download", never a distinct
            // error state.
            root._downloadsActive = exitCode === 0 && (downloadsCollector.text || "").trim().length > 0;
        }
    }

    // ── Detector 3 — toplevel count against the deny-list above ───────────
    // `hyprctl -j clients` is the standard toplevel-enumeration mechanism
    // on this host (already used elsewhere in this repo — 20-RESEARCH.md §
    // Priority Research Findings item 3). The deny-list comparison below
    // runs entirely in-process against the parsed JSON; no deny-list entry
    // or detector output is ever handed to `hyprctl`'s own argv.
    Process {
        id: denyListProcess
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            id: denyListCollector
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                // hyprctl unavailable/failed -> reports nothing, never a
                // distinct error state.
                root._denyListCount = 0;
                return;
            }
            var count = 0;
            try {
                var clients = JSON.parse(denyListCollector.text || "[]");
                for (var i = 0; i < clients.length; i++) {
                    var cls = ((clients[i] && clients[i].class) || "").toLowerCase();
                    if (root.denyListClasses.indexOf(cls) !== -1)
                        count++;
                }
            } catch (e) {
                // Malformed JSON -> reports nothing, never a distinct
                // error state.
                count = 0;
            }
            root._denyListCount = count;
        }
    }

    // ── Polling discipline (D-20-30) — the ONE `Timer` in this file,
    //    running only while `active` is true. See file header for why
    //    binding to `active` (never Component.onCompleted, never an
    //    unconditional `true`) is the whole zero-idle mechanism. ──────────
    Timer {
        id: pollTimer
        interval: root._pollIntervalMs
        repeat: true
        running: root.active
        onTriggered: root._runDetectors()
    }

    // Run one round immediately the moment the menu becomes visible, so the
    // first result does not wait a full poll interval (D-20-30's "checked
    // on open, THEN polled" ordering). Firing this from becoming active
    // (not from Component.onCompleted) also means a re-open after a prior
    // close runs a fresh immediate round rather than relying on stale
    // state from before this instance's own construction.
    onActiveChanged: {
        if (root.active)
            root._runDetectors();
    }
}
