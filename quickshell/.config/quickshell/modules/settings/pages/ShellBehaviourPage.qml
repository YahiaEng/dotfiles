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
        // `printErrors` surfaces a load failure into quickshell.log
        // directly rather than failing silently.
        FileView {
            id: idleConfFile
            path: Quickshell.env("HOME") + "/.local/state/hypr/idle-overrides.conf"
            watchChanges: true
            printErrors: true
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

        // Bug 1 — operator re-check round 2 (operator: "the error now
        // shows but is INCORRECT — it fires even when the operator
        // follows the correct order, and they still cannot change
        // lock/screen off/suspend at all"). The prior round's mechanical
        // test called `.selected(...)` directly with hand-picked values
        // — real evidence, but of the wrong layer (the write plumbing,
        // not the display->value mapping the operator's finger actually
        // drives). Re-measured through the REAL path this round: opened
        // each row's popup exactly as a click would
        // (`optionsMenu.popup()`, the same call `dropdownPill`'s own
        // MouseArea makes) and drove a REAL `MenuItem` via keyboard
        // Down+Enter — QQC2's own `triggered()` signal, not a bypass.
        //
        // Two specific hypotheses this round, BOTH REFUTED by measurement:
        //   - Unit mismatch (minutes sent where seconds are expected):
        //     `_minuteOptions()` already converts (`String(m * 60)`);
        //     logged the EXACT argv reaching the script for lock,
        //     screen-off, AND suspend — every one was already in
        //     seconds, matching what the script expects, e.g.
        //     `--set lock=900` for a real "15 minutes" pick, exit 0,
        //     file updated correctly.
        //   - Dropped second request (all five rows share ONE
        //     `idleApplyProc`, and the script itself takes ~1.6-3.3s —
        //     measured directly, three internal `sleep`s): fired lock
        //     then suspend ~1.5s apart, inside that window. Both argvs
        //     landed, both exited 0, both persisted — Quickshell's
        //     `Process` correctly defers the second `running=true`
        //     rather than dropping it. Not a race.
        //
        // What DID reproduce, repeatedly, using values a real user would
        // plausibly reach for: dim defaults to "5 minutes" and this
        // round's own first real-path attempt at lock ALSO picked
        // "5 minutes" — REJECTED, because the rule is a STRICT `<`, not
        // `<=`, and nothing in the UI communicates that picking the
        // SAME duration for two adjacent stages is invalid. Combined
        // with the script's own ~1.6-3.3s runtime and zero pending
        // feedback during it (the row just sits there, unchanged, for
        // several seconds), a genuinely-successful selection can read as
        // "nothing happened" long enough for a normal user to try again
        // or move to the next row — which is indistinguishable from "I
        // cannot change this at all." The error TEXT itself is a
        // real, correct validation message, but it lists four raw
        // second-counts with no labels — "(got 300, 60, 900, 1800)" —
        // which reads as inscrutable/wrong to someone who selected
        // "5 minutes," not "300." Fixed both: `idleApplying` now drives
        // a visible pending state on all five rows for the ~1.6-3.3s the
        // script genuinely takes, and the rendered error re-labels the
        // script's own four numbers in minutes instead of raw seconds —
        // reformatting, not re-implementing, the script's authoritative
        // validation output.
        property bool idleApplying: false

        // Busy-state UX (operator decision, folded into this same wave):
        // "keep the serialized apply and the row disabling exactly as
        // they are, but the edited row shows a small spinner/'Applying…'
        // state during the script's runtime so the wait reads as working
        // rather than broken." `applyingKey` names WHICH of the five
        // rows to show it on (`idleApplying` alone only says something
        // is in flight, not which row triggered it); each row below
        // binds `busy: idleSection.applyingKey === "<its own key>"`.
        // Cleared on EVERY `onExited` path (success AND error) and on
        // watchdog fire, same as `idleApplying` itself — never left
        // showing a spinner after the row is usable again.
        property string applyingKey: ""

        // Bug 1 — operator re-check round 3: "lock/screen-off/suspend
        // stay GREYED OUT permanently; only closing and reopening the
        // window re-enables them." Re-driven through the real popup+
        // keyboard path repeatedly this round — a fast-validation-
        // rejection, a genuine slow success (~3.3s, matching the
        // measured script runtime), and a second consecutive edit
        // immediately after, all without reopening — `idleApplying`
        // correctly cleared and the row correctly re-enabled every
        // single time on THIS machine. The unconditional
        // `idleApplying = false` in `onExited` is provably correct when
        // `onExited` fires.
        //
        // The one thing that CANNOT be tested here and directly matches
        // every symptom (permanently stuck; only a fresh page
        // construction — i.e. reopening — clears it, exactly the
        // "flag lives in page state that only a fresh incubation
        // resets" shape) is `onExited` never firing at all: this
        // Process has no timeout, and `idle-overrides.sh` genuinely
        // restarts the hypridle service — a real external dependency
        // this dev host's hypridle happens to restart cleanly and
        // promptly every time, but which has no guarantee of doing so
        // on the operator's own system (a stuck systemd unit, a dbus
        // timeout, anything that hangs the script before it reaches its
        // own exit). With no watchdog, a hung process leaves
        // `idleApplying` stuck true forever — the UI never learns the
        // attempt failed, so nothing except destroying and
        // reconstructing the whole page (closing the window) can ever
        // clear it. Fixed defensively: a Timer bounds the wait at 10s
        // (roughly 3x the measured ~3.3s worst case on this machine,
        // generous headroom without making a genuinely slow-but-alive
        // run look stuck) and force-clears `idleApplying` with a
        // visible error if the process hasn't exited by then — the UI
        // recovers on its own instead of requiring a reopen.
        // Killing the process (below) does not clear `idleApplying`
        // itself — that's left to `onExited`, which the kill triggers
        // asynchronously a moment later. Verified live: an early version
        // that set `idleApplying`/`lastError` directly in `onTriggered`
        // raced with `onExited` firing right after and overwriting the
        // clearer watchdog message with the killed process's own
        // "exit 15" — functionally harmless (the row still correctly
        // re-enabled) but a worse message. `watchdogFired` lets
        // `onExited` recognise ITS OWN trigger came from a timeout,
        // for the accurate message, with no dependency on which of the
        // two handlers happens to run first.
        property bool watchdogFired: false

        Timer {
            id: idleApplyWatchdog
            interval: 10000
            onTriggered: {
                if (idleApplyProc.running) {
                    idleSection.watchdogFired = true;
                    idleApplyProc.running = false;
                }
            }
        }

        Process {
            id: idleApplyProc
            running: false
            stderr: StdioCollector {
                id: idleApplyStderr
            }
            onExited: (exitCode, exitStatus) => {
                idleApplyWatchdog.stop();
                idleSection.idleApplying = false;
                idleSection.applyingKey = "";
                if (idleSection.watchdogFired) {
                    idleSection.watchdogFired = false;
                    idleSection.lastError = "idle-overrides.sh did not respond within 10s — it may be stuck; try again";
                } else if (exitCode !== 0) {
                    idleSection.lastError = idleSection._friendlyError(idleApplyStderr.text.trim()) || ("idle-overrides.sh failed (exit " + exitCode + ")");
                    console.warn("ShellBehaviourPage: " + idleApplyStderr.text.trim());
                } else {
                    idleSection.lastError = "";
                }
            }
        }

        // Cleared on a fresh attempt (not just a successful one) so a
        // stale error never survives a user retrying with a new value —
        // matches this row's own `onSelected` re-firing immediately.
        property string lastError: ""

        // Re-labels idle-overrides.sh's own stderr — "need dim < lock <
        // display-off < suspend (got A, B, C, D)" — replacing the raw
        // second-counts with minute-labeled ones ("dim=5min, lock=5min,
        // display-off=15min, suspend=30min"), in the SAME fixed order
        // the script always reports them. Reformats the script's
        // authoritative message; does not re-implement its validation
        // logic, so the two can never drift apart on what "valid" means
        // — only on how the numbers are displayed.
        function _friendlyError(raw) {
            var m = raw.match(/\(got\s+(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\)/);
            if (!m)
                return raw;
            var names = ["dim", "lock", "display-off", "suspend"];
            var labeled = names.map(function (name, i) {
                return name + "=" + Math.round(parseInt(m[i + 1], 10) / 60) + "min";
            }).join(", ");
            return "idle-overrides.sh: ordering violated — need dim < lock < display-off < suspend (" + labeled + ")";
        }

        // Fixed argv — same discipline as hypr-overrides.sh's own callers
        // (no shell, every element a discrete array entry).
        function applyListener(key, seconds) {
            idleSection.lastError = "";
            idleSection.idleApplying = true;
            idleSection.applyingKey = key;
            idleApplyProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/idle-overrides.sh", "--set", key + "=" + seconds];
            idleApplyProc.running = true;
            idleApplyWatchdog.restart();
        }

        // `enabled`/`opacity` on all five rows below: pending-state
        // feedback for the ~1.6-3.3s idle-overrides.sh genuinely takes
        // (measured directly, three internal `sleep`s) — previously a
        // clicked row just sat there unchanged for several seconds with
        // no indication anything was happening, which reads as "nothing
        // happened" long enough to plausibly explain "I cannot change
        // this at all" on its own, independent of the ordering rule.
        SelectRow {
            label: "Bar idle-hide"
            subtext: "Hide the bar after this long with no input"
            model: idleSection._minuteOptions()
            currentValue: idleSection.barIdleSec.toString()
            enabled: !idleSection.idleApplying
            opacity: idleSection.idleApplying ? 0.6 : 1
            busy: idleSection.applyingKey === "bar-idle"
            onSelected: (value) => idleSection.applyListener("bar-idle", value)
        }
        SelectRow {
            label: "Screen dim"
            subtext: "Dim the display and pause the live wallpaper"
            model: idleSection._minuteOptions()
            currentValue: idleSection.dimSec.toString()
            enabled: !idleSection.idleApplying
            opacity: idleSection.idleApplying ? 0.6 : 1
            busy: idleSection.applyingKey === "dim"
            onSelected: (value) => idleSection.applyListener("dim", value)
        }
        SelectRow {
            label: "Lock"
            subtext: "Lock the session"
            model: idleSection._minuteOptions()
            currentValue: idleSection.lockSec.toString()
            enabled: !idleSection.idleApplying
            opacity: idleSection.idleApplying ? 0.6 : 1
            busy: idleSection.applyingKey === "lock"
            onSelected: (value) => idleSection.applyListener("lock", value)
        }
        SelectRow {
            label: "Screen off"
            subtext: "Turn off the display (DPMS)"
            model: idleSection._minuteOptions()
            currentValue: idleSection.displayOffSec.toString()
            enabled: !idleSection.idleApplying
            opacity: idleSection.idleApplying ? 0.6 : 1
            busy: idleSection.applyingKey === "display-off"
            onSelected: (value) => idleSection.applyListener("display-off", value)
        }
        SelectRow {
            label: "Suspend"
            subtext: "Suspend the machine"
            model: idleSection._minuteOptions()
            currentValue: idleSection.suspendSec.toString()
            enabled: !idleSection.idleApplying
            opacity: idleSection.idleApplying ? 0.6 : 1
            busy: idleSection.applyingKey === "suspend"
            onSelected: (value) => idleSection.applyListener("suspend", value)
        }

        // Visible failure feedback (the actual fix) — was previously
        // console.warn-only. idle-overrides.sh's own stderr message is
        // already precise and actionable (states the exact ordering
        // rule and the four values it saw), so this surfaces that
        // verbatim rather than inventing a paraphrase that could drift
        // out of sync with the script's own validation logic.
        Text {
            visible: idleSection.lastError.length > 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: idleSection.lastError
            font.pixelSize: Design.fontLabel
            color: Colours.error
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
