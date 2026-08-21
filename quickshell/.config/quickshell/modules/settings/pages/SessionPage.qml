// modules/settings/pages/SessionPage.qml — page index 9 of the ten-page
// layout (quick-260821-6z1 Task 2 split, D-05/PD-02). Carries the Idle &
// lock section (five timing rows + Open in editor) moved out of
// ShellBehaviourPage.qml (now retired), byte-identical in behaviour to
// before the split. Every change calls idle-overrides.sh, which owns
// validate -> apply -> verify -> rollback — this page writes nothing
// itself. Task 12 adds Gaming mode, Recording defaults, Power-menu
// behaviour and the two service-status InfoRows.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"
import "../../session"

PageBase {
    id: root

    title: "Session"

    // ── Idle & lock ──────────────────────────────────────────────────────
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
            printErrors: true
            onFileChanged: reload()
        }

        // The five `timeout = N` values, in the file's own fixed
        // declaration order (bar-idle, dim, lock, display-off, suspend —
        // idle-overrides.sh's `_render()` never reorders them).
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
        // idle-overrides.sh's own 30s floor) — never a free-text field.
        function _minuteOptions() {
            var mins = [1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120];
            return mins.map(function (m) {
                return { value: String(m * 60), display: m === 1 ? "1 minute" : m + " minutes" };
            });
        }

        property bool idleApplying: false
        property string applyingKey: ""
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
                    console.warn("SessionPage: " + idleApplyStderr.text.trim());
                } else {
                    idleSection.lastError = "";
                }
            }
        }

        property string lastError: ""

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

        // Fixed argv — no shell, every element a discrete array entry.
        function applyListener(key, seconds) {
            idleSection.lastError = "";
            idleSection.idleApplying = true;
            idleSection.applyingKey = key;
            idleApplyProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/idle-overrides.sh", "--set", key + "=" + seconds];
            idleApplyProc.running = true;
            idleApplyWatchdog.restart();
        }

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

        Text {
            visible: idleSection.lastError.length > 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: idleSection.lastError
            font.pixelSize: Design.fontLabel
            color: Colours.error
        }

        // Fixed argv launcher, `Process.startDetached()` (not
        // `running = true`) for the same reason DisplayPage.qml's
        // nwg-displays launcher uses it — `onActivated` closes this
        // window in the same tick, and a `running: true` Process would
        // be torn down mid-launch along with this page.
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

    // ── Gaming mode (Task 12, D-01 bundle 3) — bound to
    //    ToggleState.gamingState, which already watches
    //    ~/.cache/gaming-mode with a FileView (ToggleState.qml/
    //    NotifServer.qml both already read it this way) — no second
    //    reader, no polling `gaming-mode-toggle.sh status` in a timer.
    //    The write is a fixed-argv invocation of the script itself; the
    //    row shows `busy` until the watched file changes, with a
    //    watchdog so a stuck script cannot spin forever. ─────────────────
    SettingsSection {
        id: gamingSection
        title: "Gaming"
        icon: "sports_esports"

        property bool applying: false

        Timer {
            id: gamingWatchdog
            interval: 5000
            onTriggered: gamingSection.applying = false
        }
        // Clears the busy state the instant the WATCHED file itself
        // changes — not on the script's own exit, since the script forks
        // detached work and the file write is the actual completion
        // signal this row cares about.
        Connections {
            target: ToggleState
            function onGamingStateChanged() {
                gamingSection.applying = false;
                gamingWatchdog.stop();
            }
        }

        Process {
            id: gamingToggleProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/gaming-mode-toggle.sh"]
        }

        ToggleRow {
            label: "Gaming mode"
            subtext: "Disables idle timeouts and notification popups while gaming"
            checked: ToggleState.gamingState
            enabled: !gamingSection.applying
            opacity: gamingSection.applying ? 0.6 : 1
            onToggled: (value) => {
                gamingSection.applying = true;
                gamingWatchdog.restart();
                gamingToggleProc.running = true;
            }
        }
    }

    // ── Recording defaults (Task 12, D-01 bundle 3, PD-05) ──────────────
    SettingsSection {
        id: recordingSection
        title: "Screen recording"
        icon: "videocam"

        property var defaultsValue: ({ fps: 60, codec: "auto", audio: "ask" })
        property string statusValue: "idle"

        function refresh() {
            defaultsProc.running = true;
            statusProc.running = true;
        }

        Process {
            id: defaultsProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/record-toggle.sh", "get-defaults"]
            stdout: StdioCollector { id: defaultsCollector }
            onExited: (code, status) => {
                if (code === 0) {
                    try { recordingSection.defaultsValue = JSON.parse(defaultsCollector.text); } catch (e) {}
                }
            }
        }
        Process {
            id: statusProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/record-toggle.sh", "status"]
            stdout: StdioCollector { id: statusCollector }
            onExited: (code, status) => {
                if (code === 0) {
                    var v = statusCollector.text.trim();
                    if (v.length > 0)
                        recordingSection.statusValue = v;
                }
            }
        }
        Process {
            id: setDefaultProc
            running: false
            onExited: (code, status) => recordingSection.refresh()
        }
        function setDefault(key, value) {
            setDefaultProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/record-toggle.sh", "set-default", key, value];
            setDefaultProc.running = true;
        }

        Timer {
            id: recordingStatusPoll
            interval: 3000
            repeat: true
            onTriggered: recordingSection.refresh()
        }
        Component.onCompleted: {
            recordingSection.refresh();
            recordingStatusPoll.start();
        }
        Component.onDestruction: recordingStatusPoll.stop()

        SelectRow {
            label: "Recording fps"
            subtext: "Frame rate for new recordings"
            model: [24, 30, 60, 120].map(function (v) { return { value: String(v), display: String(v) }; })
            currentValue: String(recordingSection.defaultsValue.fps || 60)
            onSelected: (value) => recordingSection.setDefault("fps", value)
        }
        SelectRow {
            label: "Recording codec"
            subtext: "Video codec for new recordings"
            model: [
                { value: "auto", display: "Auto" },
                { value: "h264", display: "H.264" },
                { value: "hevc", display: "HEVC" },
                { value: "av1", display: "AV1" },
                { value: "vp8", display: "VP8" },
                { value: "vp9", display: "VP9" }
            ]
            currentValue: recordingSection.defaultsValue.codec || "auto"
            onSelected: (value) => recordingSection.setDefault("codec", value)
        }
        SelectRow {
            label: "Recording audio"
            subtext: "Skips the interactive picker unless set to Ask"
            model: [
                { value: "ask", display: "Ask every time" },
                { value: "silent", display: "Silent (no audio)" },
                { value: "desktop", display: "Desktop audio" },
                { value: "desktop+mic", display: "Desktop + mic" }
            ]
            currentValue: recordingSection.defaultsValue.audio || "ask"
            onSelected: (value) => recordingSection.setDefault("audio", value)
        }
        InfoRow {
            label: "Recording status"
            subtext: recordingSection.statusValue === "recording" ? "Currently recording" : "Idle — not recording"
        }
    }

    // ── Power-menu behaviour (Task 12, D-01 bundle 3) ───────────────────
    SettingsSection {
        title: "Power menu"
        icon: "power_settings_new"

        ToggleRow {
            label: "Warn when busy"
            subtext: "Show a warning if a package manager transaction or download is in progress"
            checked: Prefs.getValue("session.warnWhenBusy")
            onToggled: (value) => Prefs.setValue("session.warnWhenBusy", value)
        }
        SelectRow {
            label: "Default focused action"
            subtext: "Which power-menu action is focused when it opens"
            model: PowerActions.actions.map(function (a) { return { value: a.label, display: a.label }; })
            currentValue: Prefs.getValue("session.defaultAction")
            onSelected: (value) => Prefs.setValue("session.defaultAction", value)
        }
    }

    // ── Service status (Task 12, D-01 bundle 3) — read-only: this page
    //    reports service state, it does not start or stop anything. ─────
    SettingsSection {
        id: servicesSection
        title: "Services"
        icon: "dns"

        property string quickshellStatus: "unknown"
        property string watchdogStatus: "unknown"

        Process {
            id: quickshellStatusProc
            running: false
            command: ["systemctl", "--user", "is-active", "quickshell.service"]
            stdout: StdioCollector { id: quickshellStatusCollector }
            onExited: (code, status) => {
                var v = quickshellStatusCollector.text.trim();
                if (v.length > 0)
                    servicesSection.quickshellStatus = v;
            }
            Component.onCompleted: running = true
        }
        Process {
            id: watchdogStatusProc
            running: false
            command: ["systemctl", "--user", "is-active", "quickshell-bar-watchdog.service"]
            stdout: StdioCollector { id: watchdogStatusCollector }
            onExited: (code, status) => {
                var v = watchdogStatusCollector.text.trim();
                if (v.length > 0)
                    servicesSection.watchdogStatus = v;
            }
            Component.onCompleted: running = true
        }

        InfoRow {
            label: "quickshell.service"
            subtext: "Status: " + servicesSection.quickshellStatus
        }
        InfoRow {
            label: "quickshell-bar-watchdog.service"
            subtext: "Status: " + servicesSection.watchdogStatus
        }
    }
}
