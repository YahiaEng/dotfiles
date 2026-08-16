// CavaService.qml — pragma Singleton owning the shell's shared cava
// subprocess (Phase 21 Plan 01, QMEDIA-02 tracer + D-21-06 ownership).
//
// Mirrors ags/.config/ags/lib/cava.ts's proven streaming contract exactly:
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
// ── Task 1 (this plan's tracer) ──────────────────────────────────────────
// No claim/release ownership model exists yet. The process starts the
// moment this singleton is first constructed (QML singletons instantiate
// lazily on first reference — MediaTab.qml's new visualiser segment is
// that first reference), so the audio path can be proven end-to-end
// before the ownership model is built. Task 2 replaces the
// `Component.onCompleted` starter below with the real claim()/release()
// refcount and a linger timer (D-21-06); nothing here should be read as
// the final lifecycle.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

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

    // ── Tracer-only starter — REPLACED by Task 2's claim()/release() ────
    Component.onCompleted: cavaProcess.running = true

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
                    .map(s => Number(s) / 100)
                    .slice(0, root.barCount);
                // Publish ONLY when at least one value survived — a blank
                // or torn line must leave the previous array in place
                // rather than clobbering it, mirroring
                // ags/lib/cava.ts's own reader exactly.
                if (vals.length > 0)
                    root._bars = vals;
            }
        }
    }
}
