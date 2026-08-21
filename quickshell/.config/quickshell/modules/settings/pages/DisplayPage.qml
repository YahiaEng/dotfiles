// modules/settings/pages/DisplayPage.qml — page index 5 of the ten-page
// layout (quick-260821-6z1 Task 2 split, D-05/PD-02). Carries the
// per-monitor Resolution/Scale Repeater and the "Open nwg-displays"
// escape hatch moved out of DisplayInputPage.qml (now retired),
// byte-identical in behaviour to before the split — the Input section of
// that page moved to its own InputPage.qml (index 6) instead. The data
// this page needs is already in `hyprctl monitors -j` — the
// `availableModes` list IS the resolution/refresh dropdown model, so
// there is no probing, no `wlr-randr` and no `nwg-displays` parsing.
// Every change calls hypr-overrides.sh, which owns validate -> apply live
// -> verify -> persist (D-03) — this page writes nothing itself, and
// reads nothing but `hyprctl -j` (read-only). Task 7 adds per-monitor
// Position and a Primary-monitor picker.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Display"

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
                console.warn("DisplayPage: hyprctl monitors -j failed (exit " + exitCode + ")");
                return;
            }
            try {
                root.monitorsModel = JSON.parse(monitorsCollector.text);
            } catch (e) {
                console.warn("DisplayPage: failed to parse hyprctl monitors -j: " + e);
            }
        }
        Component.onCompleted: running = true
    }

    // Shared trailing-zero trim ("165.00" -> "165", "119.88" unchanged) —
    // both call sites run through the exact same `.toFixed(2)` + trim
    // pipeline so the "current mode" marker always matches its own
    // dropdown entry, including fractional refresh rates.
    function _trimTrailingZeros(numStr) {
        return numStr.replace(/\.00$/, "").replace(/(\.\d*?)0+$/, "$1").replace(/\.$/, "");
    }

    // Normalises an `availableModes` entry ("2560x1440@165.00Hz") down to
    // the "WxH@R" shape hypr-overrides.sh accepts and hl.monitor emits.
    function _normaliseMode(raw) {
        var noHz = raw.endsWith("Hz") ? raw.slice(0, -2) : raw;
        return root._trimTrailingZeros(noHz);
    }

    function _currentModeString(mon) {
        return mon.width + "x" + mon.height + "@" + root._trimTrailingZeros(mon.refreshRate.toFixed(2));
    }

    // `output` is a DEVICE-supplied string (hyprctl monitors -j's own
    // `.name` field, sourced from hardware/EDID, outside this repo's
    // control) — passed as a discrete argv element to hypr-overrides.sh,
    // NEVER through a shell. hypr-overrides.sh's own validation is the
    // second, independent check.
    Process {
        id: monitorApplyProc
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root._refreshMonitors();
            else
                console.warn("DisplayPage: hypr-overrides.sh monitor failed (exit " + exitCode + ")");
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

    function applyMonitorPosition(output, position) {
        monitorApplyProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/hypr-overrides.sh", "monitor", output, "--position", position];
        monitorApplyProc.running = true;
    }

    // Position options derived from the LIVE monitor set (Task 7,
    // D-01 bundle 4) — never free-form coordinates. Single-monitor hosts
    // get exactly one option (the origin); a second/third monitor adds
    // one relative-placement option per neighbour per edge. Values are
    // the "XxY" shape hypr-overrides.sh monitor --position already
    // validates and verifies against .x/.y.
    function _positionOptions(mon) {
        var opts = [{ value: "0x0", display: "Origin (0, 0)" }];
        for (var i = 0; i < root.monitorsModel.length; i++) {
            var other = root.monitorsModel[i];
            if (other.name === mon.name)
                continue;
            opts.push({ value: (other.x + other.width) + "x" + other.y, display: "Right of " + other.name });
            opts.push({ value: (other.x - mon.width) + "x" + other.y, display: "Left of " + other.name });
            opts.push({ value: other.x + "x" + (other.y + other.height), display: "Below " + other.name });
            opts.push({ value: other.x + "x" + (other.y - mon.height), display: "Above " + other.name });
        }
        return opts;
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
            SelectRow {
                label: "Position"
                subtext: "Where this monitor sits relative to the others"
                model: root._positionOptions(monitorSection.modelData)
                currentValue: monitorSection.modelData.x + "x" + monitorSection.modelData.y
                onSelected: (value) => root.applyMonitorPosition(monitorSection.modelData.name, value)
            }
        }
    }

    // ── Arrangement — N-04 (measured this task, not anticipated by
    //    RESEARCH.md): `hyprctl eval 'return hl.monitor({ output = "…",
    //    primary = true })'` returns "hl.monitor: unknown field
    //    'primary'" on this build — Hyprland exposes no primary-monitor
    //    concept through `hl.monitor` at all, and `hyprctl getoption`
    //    has no matching key either ("no such option"). An honest
    //    InfoRow instead of a knob that would silently no-op. ───────────
    SettingsSection {
        title: "Arrangement"
        icon: "desktop_windows"

        InfoRow {
            label: "No primary-monitor setting on this build"
            subtext: "Hyprland has no primary-monitor concept exposed through hyprctl on this version — there is nothing here to make settable. Position above controls monitor layout."
        }
    }

    // ── Advanced escape hatch — the same nwg-displays the walker Display
    //    row already points at. `Process.startDetached()`, not
    //    `running = true`: `onActivated` calls `root.sState.close()` in
    //    the same tick, which destroys this page (and any `running: true`
    //    Process owned by it) before uwsm's slower systemd/dbus hand-off
    //    completes — the exact race PowerMenu.qml's own header documents
    //    and fixes the same way. ────────────────────────────────────────
    SettingsSection {
        title: "Advanced"
        icon: "open_in_new"

        Process {
            id: nwgDisplaysProc
            command: ["uwsm", "app", "--", "nwg-displays"]
        }

        NavRow {
            label: "Open nwg-displays"
            subtext: "Full display layout editor, for anything the rows above don't cover"
            onActivated: {
                nwgDisplaysProc.startDetached();
                root.sState.close();
            }
        }
    }
}
