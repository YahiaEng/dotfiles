// CavaService.qml — pragma Singleton owning the shell's shared cava
// subprocess (Phase 21 Plan 01, QMEDIA-02 tracer + D-21-06 ownership).
//
// Mirrors the retired standalone media applet's own lib/cava.ts (Phase 10,
// RETIRE-06-deleted) proven streaming contract exactly:
// `cava -p <config>`, one line per frame, `;`-delimited ascii 0..100,
// normalised to 0..1, blank/partial lines ignored rather than clobbering
// the last good frame. `bar_delimiter = 59` (the ';' codepoint) in the new
// `cava/.config/cava/config` and this file's `.split(";")` must never
// change independently of each other.
//
// Both `pragma Singleton` below AND the `singleton` keyword on the
// top-level `modules/qmldir` line are required — the 12-06 finding this
// repo's every singleton header restates: with only one of the two, bare
// `CavaService.bars`-style access resolves to `undefined` forever, with no
// load error. Registered at the TOP level (not modules/dashboard/qmldir)
// because `modules/bar/MediaPopout.qml` must resolve the SAME instance in
// a later plan — `Colours`/`Motion` are the existing precedent for a
// cross-directory singleton reached from both `dashboard/` and `bar/`.
//
// ── Ownership (Task 2, D-21-06 + 21-UI-SPEC.md's "Cava claim condition"
//    appendix) ───────────────────────────────────────────────────────────
// A surface claims this singleton while genuinely visible and releases the
// instant it stops being visible — never on pause. Either surface (the
// Media tab today; the bar's MediaPopout in a later plan) may hold the
// claim; the counter floors at 0 and a short linger timer delays the
// actual kill so a claim handover inside the window (popout close ->
// dashboard open, or an accidental close-and-reopen) never re-pays the
// measured ~350ms cold start. `alwaysOn` is D-21-06's required one-knob
// reversal: flip it and the linger timer becomes a permanent no-op, with
// no other change to the ownership model — see its own declaration below.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "dashboard"

Singleton {
    id: root

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string cavaConfigPath: root.homeDir + "/.config/cava/config"

    // D-21-03's bar count. Also the cap the reader enforces on every
    // published frame (T-21-02) — a malformed or hostile stdout line
    // carrying more fields than this is truncated, never allowed to grow
    // the array without bound.
    readonly property int barCount: 60

    // The parsed amplitude array, values 0..1, one per cava band.
    property var _bars: []

    // Published surface. Presents as empty whenever the process is not
    // actually running, so consumers fall to their own silence rendering
    // without needing a separate flag.
    readonly property var bars: cavaProcess.running ? root._bars : []
    readonly property bool streaming: cavaProcess.running

    // ── Reference-counted ownership ──────────────────────────────────────
    property int _claimCount: 0

    // D-21-06's one-knob always-on reversal — the operator's reserved
    // revisit. Flip this to `true` and the linger timer below permanently
    // declines to stop the process; nothing else in this file, and no
    // caller's claim()/release() usage, needs to change for that reversal
    // to take effect.
    property bool alwaysOn: false

    function claim() {
        root._claimCount += 1;
        lingerTimer.stop();
        if (!cavaProcess.running)
            cavaProcess.running = true;
    }

    function release() {
        root._claimCount = Math.max(0, root._claimCount - 1);
        if (root._claimCount === 0)
            lingerTimer.restart();
    }

    // Non-repeating — fires at most once per claim-drop-to-zero, re-armed
    // only by the next release() that brings the counter back to 0.
    // Mirrors modules/bar/PopoutController.qml's graceTimer STRUCTURE
    // (re-check the live condition inside onTriggered, never trust
    // anything captured when the timer was armed), not its constant —
    // Design.cavaLingerMs is its own named value at a different scale.
    Timer {
        id: lingerTimer
        interval: Design.cavaLingerMs
        repeat: false
        running: false
        onTriggered: {
            // Re-read the live claim count and alwaysOn HERE, at fire
            // time — a claim can land during the wait (the
            // popout-close-then-dashboard-open flow this timer exists to
            // protect), so trusting state captured when the timer was
            // armed would kill a process a surface just re-claimed.
            if (root.alwaysOn || root._claimCount > 0)
                return;
            cavaProcess.running = false;
            // Drop the last frame with the process. `bars` masks _bars while
            // stopped, but the NEXT claim() flips `running` true again the
            // instant it is called — one frame ahead of any fresh stdout —
            // and would otherwise re-publish this pre-kill amplitude data.
            // Silence and failure must render the same silhouette.
            root._bars = [];
        }
    }

    Process {
        id: cavaProcess
        running: false
        // Fixed three-element argv: binary, config flag, resolved config
        // path. No element is derived from track metadata, MPRIS state or
        // any other runtime input (T-21-01).
        command: ["cava", "-p", root.cavaConfigPath]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                const vals = line
                    .split(";")
                    .filter(s => s.length > 0)
                    // Non-finite guard, positional: the length filter above
                    // runs on the RAW token, so a malformed field still
                    // reaches Number() and yields NaN — and NaN survives
                    // every consumer's `Math.max(0, Math.min(1, v))` clamp
                    // untouched, propagating into ring geometry. Map it to
                    // silence rather than dropping it, so the bad field does
                    // not shift every later band one index to the left.
                    .map(s => { const n = Number(s) / 100; return Number.isFinite(n) ? n : 0; })
                    .slice(0, root.barCount);
                // Publish ONLY when at least one value survived — a blank
                // or torn line must leave the previous array in place
                // rather than clobbering it, mirroring the retired
                // applet's own lib/cava.ts reader exactly (Phase 10,
                // RETIRE-06-deleted).
                if (vals.length > 0)
                    root._bars = vals;
            }
        }
    }
}
