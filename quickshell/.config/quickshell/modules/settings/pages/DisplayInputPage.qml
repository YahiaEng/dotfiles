// modules/settings/pages/DisplayInputPage.qml — D-01's Display + input
// group, the new territory (Task 3). The data this page needs is already
// in `hyprctl monitors -j` — the `availableModes` list IS the
// resolution/refresh dropdown model, so there is no probing, no
// `wlr-randr` and no `nwg-displays` parsing (RESEARCH.md). Every change
// calls `hypr-overrides.sh`, which owns validate -> apply live -> verify
// -> persist (D-03) — this page writes nothing itself, and reads nothing
// but `hyprctl -j` (read-only) and `hyprctl getoption -j` (read-only).
//
// Input is global `input { }` granularity (F-03): `hyprctl devices -j`
// reports 7 keyboards and 6 mice on this host, most of them phantom
// sub-devices of the same physical hardware — a per-device UI would be
// noise.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Display & input"

    // ── Monitors — read-only hyprctl monitors -j, re-queried after every
    //    successful apply so the model reflects the JUST-VERIFIED state,
    //    never an assumption. ─────────────────────────────────────────
    property var monitorsModel: []

    function _refreshMonitors() {
        monitorsListProc.running = true;
    }

    Process {
        id: monitorsListProc
        running: false
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("DisplayInputPage: hyprctl monitors -j failed (exit " + exitCode + ")");
                return;
            }
            try {
                root.monitorsModel = JSON.parse(monitorsCollector.text);
            } catch (e) {
                console.warn("DisplayInputPage: failed to parse hyprctl monitors -j: " + e);
            }
        }
        Component.onCompleted: running = true
    }

    // Normalises an `availableModes` entry ("2560x1440@165.00Hz") down to
    // the "WxH@R" shape hypr-overrides.sh accepts and hl.monitor emits —
    // strip "Hz", trim a trailing ".00" (RESEARCH.md's own normalisation
    // note).
    function _normaliseMode(raw) {
        var noHz = raw.endsWith("Hz") ? raw.slice(0, -2) : raw;
        return noHz.replace(/\.00$/, "").replace(/(\.\d*?)0+$/, "$1").replace(/\.$/, "");
    }

    function _currentModeString(mon) {
        return mon.width + "x" + mon.height + "@" + Math.round(mon.refreshRate);
    }

    // T-SQD-04: `output` is a DEVICE-supplied string (hyprctl monitors -j's
    // own `.name` field, sourced from the hardware/EDID, outside this
    // repo's control). It — and every other value here — is passed as a
    // discrete argv element to hypr-overrides.sh, NEVER through a shell
    // (no `bash -c`, no string concatenation into a command line): a
    // monitor reporting a name containing shell metacharacters cannot
    // break out of anything, because there is no shell here to break out
    // of. hypr-overrides.sh's own validation is the second, independent
    // check (it verifies the name against its own fresh `hyprctl
    // monitors -j` read before ever using it).
    Process {
        id: monitorApplyProc
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root._refreshMonitors();
            else
                console.warn("DisplayInputPage: hypr-overrides.sh monitor failed (exit " + exitCode + ")");
        }
    }

    function applyMonitorMode(output, mode) {
        monitorApplyProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/hypr-overrides.sh", "monitor", output, "--mode", mode];
        monitorApplyProc.running = true;
    }

    function applyMonitorScale(output, scale) {
        monitorApplyProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/hypr-overrides.sh", "monitor", output, "--scale", scale];
        monitorApplyProc.running = true;
    }

    Repeater {
        model: root.monitorsModel

        SettingsSection {
            id: monitorSection
            required property var modelData

            title: modelData.name
            icon: "desktop_windows"

            readonly property var resolutionOptions: {
                var seen = {};
                var opts = [];
                var modes = modelData.availableModes || [];
                for (var i = 0; i < modes.length; i++) {
                    var norm = root._normaliseMode(modes[i]);
                    if (!seen[norm]) {
                        seen[norm] = true;
                        opts.push({ value: norm, display: norm.replace("@", " @ ") + "Hz" });
                    }
                }
                return opts;
            }
            readonly property var scaleOptions: [
                { value: "1", display: "100%" },
                { value: "1.25", display: "125%" },
                { value: "1.5", display: "150%" },
                { value: "2", display: "200%" }
            ]

            SelectRow {
                label: "Resolution & refresh rate"
                subtext: monitorSection.modelData.make + " " + monitorSection.modelData.model
                model: monitorSection.resolutionOptions
                currentValue: root._currentModeString(monitorSection.modelData)
                onSelected: (value) => root.applyMonitorMode(monitorSection.modelData.name, value)
            }
            SelectRow {
                label: "Scale"
                subtext: "Display scaling"
                model: monitorSection.scaleOptions
                currentValue: monitorSection.modelData.scale.toString()
                onSelected: (value) => root.applyMonitorScale(monitorSection.modelData.name, value)
            }
        }
    }

    // ── Input — global granularity (F-03). Current values are read-only
    //    hyprctl getoption -j calls; writes go through hypr-overrides.sh
    //    input, never a direct hyprctl call from this page. ─────────────
    SettingsSection {
        id: inputSection
        title: "Input"
        icon: "keyboard"

        property string kbLayout: "us"
        property int followMouseValue: 1
        property real sensitivityValue: 0
        property bool naturalScroll: true

        function refresh() {
            kbLayoutProc.running = true;
            followMouseProc.running = true;
            sensitivityProc.running = true;
            naturalScrollProc.running = true;
        }

        Process {
            id: kbLayoutProc
            running: false
            command: ["hyprctl", "getoption", "input:kb_layout", "-j"]
            stdout: StdioCollector { id: kbLayoutCollector }
            onExited: (code, status) => {
                if (code === 0) {
                    try {
                        inputSection.kbLayout = JSON.parse(kbLayoutCollector.text).str;
                    } catch (e) {}
                }
            }
            Component.onCompleted: running = true
        }
        Process {
            id: followMouseProc
            running: false
            command: ["hyprctl", "getoption", "input:follow_mouse", "-j"]
            stdout: StdioCollector { id: followMouseCollector }
            onExited: (code, status) => {
                if (code === 0) {
                    try {
                        inputSection.followMouseValue = JSON.parse(followMouseCollector.text).int;
                    } catch (e) {}
                }
            }
            Component.onCompleted: running = true
        }
        Process {
            id: sensitivityProc
            running: false
            command: ["hyprctl", "getoption", "input:sensitivity", "-j"]
            stdout: StdioCollector { id: sensitivityCollector }
            onExited: (code, status) => {
                if (code === 0) {
                    try {
                        inputSection.sensitivityValue = JSON.parse(sensitivityCollector.text).float;
                    } catch (e) {}
                }
            }
            Component.onCompleted: running = true
        }
        Process {
            id: naturalScrollProc
            running: false
            command: ["hyprctl", "getoption", "input:touchpad:natural_scroll", "-j"]
            stdout: StdioCollector { id: naturalScrollCollector }
            onExited: (code, status) => {
                if (code === 0) {
                    try {
                        inputSection.naturalScroll = JSON.parse(naturalScrollCollector.text).int === 1;
                    } catch (e) {}
                }
            }
            Component.onCompleted: running = true
        }

        // Fixed argv, same discipline as monitorApplyProc above — no
        // shell, every element a discrete array entry.
        Process {
            id: inputApplyProc
            running: false
            onExited: (exitCode, exitStatus) => {
                if (exitCode === 0)
                    inputSection.refresh();
                else
                    console.warn("DisplayInputPage: hypr-overrides.sh input failed (exit " + exitCode + ")");
            }
        }

        function apply(flag, value) {
            inputApplyProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/hypr-overrides.sh", "input", flag, value];
            inputApplyProc.running = true;
        }

        SelectRow {
            label: "Keyboard layout"
            subtext: "xkb layout code"
            model: [
                { value: "us", display: "US" },
                { value: "gb", display: "UK" },
                { value: "de", display: "German" },
                { value: "fr", display: "French" },
                { value: "es", display: "Spanish" },
                { value: "ru", display: "Russian" }
            ]
            currentValue: inputSection.kbLayout
            onSelected: (value) => inputSection.apply("--kb-layout", value)
        }
        SelectRow {
            label: "Follow mouse"
            subtext: "Hyprland's own input:follow_mouse mode (0-3)"
            model: [
                { value: "0", display: "0" },
                { value: "1", display: "1" },
                { value: "2", display: "2" },
                { value: "3", display: "3" }
            ]
            currentValue: inputSection.followMouseValue.toString()
            onSelected: (value) => inputSection.apply("--follow-mouse", value)
        }
        SliderRow {
            label: "Pointer sensitivity"
            subtext: "libinput sensitivity, -1.0 to 1.0"
            from: -1.0
            to: 1.0
            stepSize: 0.05
            value: inputSection.sensitivityValue
            onMoved: (value) => inputSection.apply("--sensitivity", value.toFixed(2))
        }
        ToggleRow {
            label: "Natural scroll (touchpad)"
            subtext: "Reverse scroll direction to match touch gestures"
            checked: inputSection.naturalScroll
            onToggled: (value) => inputSection.apply("--natural-scroll", value ? "true" : "false")
        }
    }

    // ── Advanced escape hatch — the same nwg-displays the walker Display
    //    row already points at (D-06/PanelDialog.qml's own
    //    advancedLabel/advancedCommand precedent). ───────────────────────
    SettingsSection {
        title: "Advanced"
        icon: "open_in_new"

        Process {
            id: nwgDisplaysProc
            running: false
            command: ["uwsm", "app", "--", "nwg-displays"]
        }

        NavRow {
            label: "Open nwg-displays"
            subtext: "Full display layout editor, for anything the rows above don't cover"
            onActivated: {
                nwgDisplaysProc.running = true;
                root.sState.close();
            }
        }
    }
}
