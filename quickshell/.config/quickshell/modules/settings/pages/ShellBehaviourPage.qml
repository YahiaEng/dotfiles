// modules/settings/pages/ShellBehaviourPage.qml — D-01's Shell behaviour
// group: motion preset (`motion-switch.sh`, already settings-ready via
// its own `--list`/`--get`), notification DND (`NotifServer`, already
// in-process and already persisted — this row is a second VIEW of state
// that already exists, not a new writer), and Idle & lock (Task 4).
//
// Idle & lock reads current timeouts from
// ~/.local/state/hypr/idle-overrides.conf — NEVER the tracked
// hypridle.conf, which no longer holds them (Task 4 Step 2 moved all
// five listener blocks out; hyprlang APPENDS rather than replaces, so a
// listener left behind there would coexist with its override). Every
// change calls idle-overrides.sh, which owns validate -> apply -> verify
// -> rollback (PD-03/T-SQD-08) — this page writes nothing itself.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"
import "../../notifications"

PageBase {
    id: root

    title: "Shell behaviour"

    // ── Motion preset — never a hardcoded case ladder. `--list` output is
    //    human-formatted ("  Lively (x1.25)"); the slug is that word
    //    lower-cased, recovering exactly what the state file itself holds
    //    (motion-switch.sh's own `_read_motion_scale` case list is
    //    single-word, lower-case slugs — title-casing only capitalises the
    //    first letter, so lower-casing back is lossless here). ───────────
    property var motionOptions: []

    Process {
        id: motionListProc
        running: false
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/motion-switch.sh", "--list"]
        stdout: StdioCollector {
            id: motionListCollector
        }
        onExited: (exitCode, exitStatus) => {
            var lines = motionListCollector.text.split("\n");
            var opts = [];
            for (var i = 0; i < lines.length; i++) {
                var m = lines[i].match(/^\s{2}(\S+)\s+\(x/);
                if (m) {
                    var display = m[1];
                    opts.push({ value: display.toLowerCase(), display: display });
                }
            }
            root.motionOptions = opts;
        }
        Component.onCompleted: running = true
    }

    Process {
        id: motionGetProc
        running: false
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/motion-switch.sh", "--get"]
        stdout: StdioCollector {
            id: motionGetCollector
        }
        onExited: (exitCode, exitStatus) => {
            root.currentMotionScale = motionGetCollector.text.trim();
        }
        Component.onCompleted: running = true
    }
    property string currentMotionScale: "normal"

    Process {
        id: motionApplyProc
        running: false
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/motion-switch.sh", root.pendingMotionScale]
    }
    property string pendingMotionScale: ""

    function applyMotionScale(name) {
        root.pendingMotionScale = name;
        motionApplyProc.running = true;
        // The script re-triggers theme-apply itself; re-read our own
        // current value after it settles rather than assuming the write
        // succeeded.
        motionGetProc.running = true;
    }

    SettingsSection {
        id: motionSection
        title: "Motion"
        icon: "tune"

        SelectRow {
            label: "Motion preset"
            subtext: "How much the shell's own animations move"
            model: root.motionOptions
            currentValue: root.currentMotionScale
            onSelected: (value) => root.applyMotionScale(value)
        }
    }

    // ── Notification DND — a second view of NotifServer's own already-
    //    persisted state (D-19-07's own `~/.local/state/quickshell/
    //    notifications.json`), never a new writer. ─────────────────────
    SettingsSection {
        title: "Notifications"
        icon: "notifications"

        ToggleRow {
            label: "Do not disturb"
            subtext: "Suppress notification popups"
            checked: NotifServer.dnd
            onToggled: NotifServer.toggleDnd()
        }
    }

    // ── Idle & lock (Task 4, PD-03) ──────────────────────────────────────
    SettingsSection {
        id: idleSection
        title: "Idle & lock"
        icon: "lock_clock"

        // Plain-text read of the state-dir file, Probe.qml's own
        // `.text()` pattern — never the tracked hypridle.conf.
        FileView {
            id: idleConfFile
            path: Quickshell.env("HOME") + "/.local/state/hypr/idle-overrides.conf"
            watchChanges: true
            onFileChanged: reload()
        }

        // The five `timeout = N` values, in the file's own fixed
        // declaration order (bar-idle, dim, lock, display-off, suspend —
        // idle-overrides.sh's `_render()` never reorders them). Positional
        // parsing, not per-block matching, since the file's comments
        // (deliberately kept verbatim from the original tracked config)
        // would otherwise need their own parser.
        readonly property var timeouts: {
            var text = idleConfFile.text() || "";
            var matches = text.match(/timeout\s*=\s*(\d+)/g) || [];
            return matches.map(function (m) {
                return parseInt(m.replace(/[^\d]/g, ""), 10);
            });
        }
        readonly property int barIdleSec: timeouts.length > 0 ? timeouts[0] : 120
        readonly property int dimSec: timeouts.length > 1 ? timeouts[1] : 300
        readonly property int lockSec: timeouts.length > 2 ? timeouts[2] : 600
        readonly property int displayOffSec: timeouts.length > 3 ? timeouts[3] : 900
        readonly property int suspendSec: timeouts.length > 4 ? timeouts[4] : 1800

        // Bounded minute values (>= 1 minute, comfortably above
        // idle-overrides.sh's own 30s floor) — never a free-text field,
        // matching this repo's closed-set discipline for every other row.
        function _minuteOptions() {
            var mins = [1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120];
            return mins.map(function (m) {
                return { value: String(m * 60), display: m === 1 ? "1 minute" : m + " minutes" };
            });
        }

        Process {
            id: idleApplyProc
            running: false
            onExited: (exitCode, exitStatus) => {
                if (exitCode !== 0)
                    console.warn("ShellBehaviourPage: idle-overrides.sh failed (exit " + exitCode + ")");
            }
        }

        // Fixed argv — same discipline as hypr-overrides.sh's own callers
        // (no shell, every element a discrete array entry).
        function applyListener(key, seconds) {
            idleApplyProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/idle-overrides.sh", "--set", key + "=" + seconds];
            idleApplyProc.running = true;
        }

        SelectRow {
            label: "Bar idle-hide"
            subtext: "Hide the bar after this long with no input"
            model: idleSection._minuteOptions()
            currentValue: idleSection.barIdleSec.toString()
            onSelected: (value) => idleSection.applyListener("bar-idle", value)
        }
        SelectRow {
            label: "Screen dim"
            subtext: "Dim the display and pause the live wallpaper"
            model: idleSection._minuteOptions()
            currentValue: idleSection.dimSec.toString()
            onSelected: (value) => idleSection.applyListener("dim", value)
        }
        SelectRow {
            label: "Lock"
            subtext: "Lock the session"
            model: idleSection._minuteOptions()
            currentValue: idleSection.lockSec.toString()
            onSelected: (value) => idleSection.applyListener("lock", value)
        }
        SelectRow {
            label: "Screen off"
            subtext: "Turn off the display (DPMS)"
            model: idleSection._minuteOptions()
            currentValue: idleSection.displayOffSec.toString()
            onSelected: (value) => idleSection.applyListener("display-off", value)
        }
        SelectRow {
            label: "Suspend"
            subtext: "Suspend the machine"
            model: idleSection._minuteOptions()
            currentValue: idleSection.suspendSec.toString()
            onSelected: (value) => idleSection.applyListener("suspend", value)
        }

        // Opens the state-dir file in $EDITOR inside a floating kitty, on
        // wallpaper-switch.sh/icon-theme-switch.sh/font-switch.sh's own
        // launcher shape (fixed argv — no shell string, `$EDITOR` is
        // read directly by Quickshell.env, falling back to nvim, this
        // session's own default, when unset). Inlined here rather than a
        // new shim script: the plan's own Task 4 file list names no such
        // script, and a fixed argv array needs none.
        //
        // Operator live-pass item 8 ("open in editor does nothing when
        // clicked"): MEASURED, not guessed — same root cause as item 6
        // (see DisplayInputPage.qml's nwgDisplaysProc for the full
        // writeup): `running = true` ties the Process's lifetime to this
        // page, which `root.sState.close()` destroys in the same tick;
        // `uwsm app -- kitty ... -- nvim ...`'s systemd/dbus hand-off is
        // slow enough that the teardown wins the race and kills it
        // before nvim/kitty ever map a window. `nvim` being a TUI is
        // NOT the cause here (kitty is already the terminal host, per
        // the D-09 wrap this command already uses) — it is the same
        // destroy-before-spawn-completes race PowerMenu.qml's header
        // documents and fixes with `Process.startDetached()`. Mirrored
        // here verbatim.
        Process {
            id: editorProc
            command: ["uwsm", "app", "--", "kitty",
                "--class", "idle-overrides-editor",
                "--title", "Idle & Lock Overrides",
                "-o", "background_opacity=0.85",
                "-o", "font_size=11",
                "--", (Quickshell.env("EDITOR") || "nvim"), Quickshell.env("HOME") + "/.local/state/hypr/idle-overrides.conf"]
        }

        NavRow {
            label: "Open in editor"
            subtext: "Edit the state-dir file directly for anything the rows above don't cover"
            onActivated: {
                editorProc.startDetached();
                root.sState.close();
            }
        }
    }
}
