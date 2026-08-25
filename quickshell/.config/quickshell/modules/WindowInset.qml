// WindowInset.qml — where a real tiled Hyprland window's edge actually is
// (quick task 260825-pyf, Task 2).
//
// ── WHY THIS EXISTS: FOUR SURFACES WERE SILENTLY WRONG ──────────────────
// Every panel in this shell that means to line its edge up with a real
// window's edge had the answer HARDCODED, each with its own copy of the
// same measurement taken on a day when `gaps_out` was 10:
//
//   Dashboard.qml           `drawerTopMargin: 10`
//   launcher/Launcher.qml   `drawerTopMargin: 10`   ("same value and same
//                                                     rationale as
//                                                     Dashboard.qml's")
//   bar/SectionPopout.qml   `Design.barSideMargin` (10) as a stand-in
//   centre/NotifCentre.qml  13  (gaps_out 10 + border_size 3)
//
// `SectionPopout.qml` even wrote down the fuse: "It matches gaps_out by
// value rather than by binding — if general:gaps_out changes, this
// alignment needs revisiting (a QML surface cannot read it live)."
//
// It changed. MEASURED on this host 2026-08-25, after the operator
// confirmed the drifted override values as intended:
//
//     general:gaps_out  = 20        general:border_size = 0
//     reserved          = [0, 6, 50, 6]
//     tiled clients report at=[20, 26]
//
// 0 + 20 = 20 and 6 + 20 = 26, so the window edge is the reserved boundary
// plus `gaps_out`, exactly as those comments describe — but the constant is
// now 20, and all four surfaces still say 10 (or 13). They are each off by
// 10px (7 for the notification centre) against the windows they align to.
//
// A QML surface genuinely cannot read a Hyprland option directly, but it
// CAN shell out, which is what every page under settings/pages/ already
// does (`InputPage.qml`, `DisplayPage.qml`: `hyprctl getoption <opt> -j`).
// This singleton is that same idiom, hoisted so the answer is read ONCE and
// shared, instead of copied by hand into a fifth file the next time.
//
// ── THE BORDER TERM IS DELIBERATELY NOT FOLDED IN ───────────────────────
// `border_size` is 0 on this host and intentionally so — every edge-bar
// style except `off` zeroes it (260824-ns3 Task 4, the rimless windows),
// because the operator's reason for rimless is sensory load: the animated
// window border was a second scrolling gradient competing with the rail's.
//
// At border 0 the two candidate definitions of a window's edge — with the
// border and without it — are the same number, so this host cannot
// distinguish them, and the two existing comments in this tree DISAGREE
// about which one Hyprland's `at` reports: `NotifCentre.qml:194` says "at"
// includes the border, while `SectionPopout.qml:186` reports at=[13,61]
// against an outer border edge of 58, i.e. excluding it. One of them is
// wrong and nothing on this host can say which.
//
// So `border_size` is exposed but NOT added into `inset`. Adding it would
// be picking a side of an unresolved question on a host that cannot test
// it, which is exactly how the hardcoded 13 above got there. `inset` is
// `gaps_out` alone, which is the term BOTH measurements agree on and the
// only one this host can verify. If rimless is ever turned off and a
// border returns, resolve it by measuring `hyprctl clients` against a
// screenshot — not by reasoning from either comment.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    // How far inside the reserved boundary a real tiled window's edge sits.
    // Consumers add this to the boundary they are anchored against; they do
    // not use it as an absolute coordinate.
    readonly property int inset: root._gapsOut

    // Exposed for a consumer that genuinely needs it. See the header for
    // why it is not part of `inset`.
    property int borderSize: 0

    // Seeded with the value that was hardcoded across the tree, so the
    // very first frame after a cold start is never WORSE than the
    // behaviour this file replaces — the readers below overwrite it within
    // a frame or two. Not a fallback that can persist: if hyprctl fails the
    // shell is not running under Hyprland at all, and every other surface
    // here has bigger problems than a 10px margin.
    property int _gapsOut: 10

    // ── Parsing ─────────────────────────────────────────────────────────
    // `hyprctl getoption general:gaps_out -j` does NOT return a plain
    // number, and does not carry an `int` key at all. MEASURED on this
    // build rather than assumed — the first draft of this file guessed a
    // `custom` key with an `int` fallback and BOTH were wrong:
    //
    //     $ hyprctl getoption general:gaps_out -j
    //     {"option": "general:gaps_out", "css": "20 20 20 20", "set": true }
    //
    //     $ hyprctl getoption general:border_size -j
    //     {"option": "general:border_size", "int": 0, "set": true }
    //
    // So gaps_out parses from `css` and border_size from `int` — two
    // different shapes from the same subcommand, which is exactly why each
    // is read against its own measured output instead of one shared
    // assumption. The value is a four-sided CSS-style gap
    // (top right bottom left), because gaps_out is per-edge. Taking
    // `[0]` alone would silently be the TOP gap only and would be wrong
    // the moment the operator sets asymmetric gaps — so every edge is
    // kept and a consumer asks for the one it needs via `insetFor()`,
    // with the bare `inset` property being the top edge (the only one
    // every current consumer wants).
    property int gapTop: 10
    property int gapRight: 10
    property int gapBottom: 10
    property int gapLeft: 10

    function insetFor(edge) {
        switch (edge) {
        case "top": return root.gapTop;
        case "right": return root.gapRight;
        case "bottom": return root.gapBottom;
        case "left": return root.gapLeft;
        default: return root.gapTop;
        }
    }

    function _applyGaps(text) {
        // Accepts either the JSON object's `css` string ("20 20 20 20")
        // or a bare number, and tolerates 1, 2 or 4 values the way CSS
        // shorthand does — 1 value means all four, 2 means vertical then
        // horizontal. Anything else is left alone rather than
        // half-applied.
        var parts = String(text).trim().split(/\s+/).map(function (n) {
            return parseInt(n, 10);
        }).filter(function (n) {
            return !isNaN(n);
        });
        if (parts.length === 1)
            parts = [parts[0], parts[0], parts[0], parts[0]];
        else if (parts.length === 2)
            parts = [parts[0], parts[1], parts[0], parts[1]];
        if (parts.length !== 4)
            return;
        root.gapTop = parts[0];
        root.gapRight = parts[1];
        root.gapBottom = parts[2];
        root.gapLeft = parts[3];
        root._gapsOut = parts[0];
    }

    Process {
        id: gapsProcess
        command: ["hyprctl", "getoption", "general:gaps_out", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var o = JSON.parse(text);
                    // `css` is the measured key (see the parsing note
                    // above). `int` is accepted only as a forward
                    // fallback for a build that changes the shape; it is
                    // NOT present today, so this never silently reads a
                    // single edge on this host.
                    root._applyGaps(o.css !== undefined && String(o.css).length > 0 ? o.css : o.int);
                } catch (e) {
                    console.log("WindowInset: gaps_out parse failed: " + e);
                }
            }
        }
    }

    Process {
        id: borderProcess
        command: ["hyprctl", "getoption", "general:border_size", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.borderSize = JSON.parse(text).int;
                } catch (e) {
                    console.log("WindowInset: border_size parse failed: " + e);
                }
            }
        }
    }

    function refresh() {
        gapsProcess.running = true;
        borderProcess.running = true;
    }

    // Logged on CHANGE only, never on every read — `hyprctl reload` fires
    // on every theme and motion apply, so logging each refresh would bury
    // the log the way the retired per-frame debug lines did. Matches the
    // shell's existing one-line state-change idiom ("bar: visibility=…",
    // "popout: open section=…"). This is the only channel that can show
    // the parse actually worked: a singleton is lazily constructed, so
    // until some surface reads it there is nothing to observe at all.
    onInsetChanged: console.log("windowinset: gaps=" + root.gapTop + " " + root.gapRight
        + " " + root.gapBottom + " " + root.gapLeft + " border=" + root.borderSize)

    // Re-read whenever Hyprland reloads its config, because that is
    // precisely when these change — `lib/reload.sh` runs `hyprctl reload`
    // on EVERY theme and motion apply, and that re-applies
    // `~/.local/state/hypr/overrides.lua`, which is where `gaps_out` and
    // `border_size` actually live on this host. A value read once at
    // startup would go stale on the operator's next theme switch, which is
    // the same class of bug as hardcoding it.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                root.refresh();
        }
    }

    Component.onCompleted: root.refresh()
}
