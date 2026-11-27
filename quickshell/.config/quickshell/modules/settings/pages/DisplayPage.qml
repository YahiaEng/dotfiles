// Read the active modes, positions and scales from Hyprland. Native display
// changes go through hypr-overrides.sh. In Weaselway the Windows viewer
// owns display arrangement and applies automatic or saved per-display scales.
import QtQuick
import Quickshell
import Quickshell.Hyprland
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
    property var windowsScales: ({})
    property string scaleError: ""
    readonly property bool weaselway: Quickshell.env("DONT_PROMPT_WSL_INSTALL") === "1"
    readonly property string desktopLauncher: Quickshell.env("HOME") + "/dotfiles/wsl/launch-desktop"

    function _refreshMonitors() {
        monitorsListProc.running = true;
        if (root.weaselway)
            windowsScalesProc.running = true;
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["configreloaded", "monitoradded", "monitorremoved"].includes(event.name))
                monitorRefresh.restart();
        }
    }

    Timer {
        id: monitorRefresh
        interval: 200
        onTriggered: root._refreshMonitors()
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
    }

    Process {
        id: windowsScalesProc
        command: [root.desktopLauncher, "--display-scales"]
        stdout: StdioCollector { id: windowsScalesOutput }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                try {
                    root.windowsScales = JSON.parse(windowsScalesOutput.text);
                } catch (e) {
                    console.warn("DisplayPage: invalid Windows scale options: " + e);
                }
            }
        }
    }

    Component.onCompleted: root._refreshMonitors()

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

    Process {
        id: windowsScaleApplyProc
        stderr: StdioCollector { id: windowsScaleError }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.scaleError = windowsScaleError.text.trim() || "The scale could not be applied.";
            root._refreshMonitors();
        }
    }

    function _scalePercent(scale) {
        return root._trimTrailingZeros((scale * 100).toFixed(2)) + "%";
    }

    function _windowsScaleOptions(info) {
        var opts = [{ value: "auto", display: "Automatic" }];
        if (!info)
            return opts;
        for (var units of info.choices)
            opts.push({ value: String(units), display: root._scalePercent(units / 120) });
        if (info.saved !== null && !info.choices.includes(info.saved))
            opts.push({ value: String(info.saved), display: root._scalePercent(info.saved / 120) + " (saved)", enabled: false });
        return opts;
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

    function _logicalSize(mon) {
        return mon.transform % 2 === 0
            ? Qt.size(Math.round(mon.width / mon.scale), Math.round(mon.height / mon.scale))
            : Qt.size(Math.round(mon.height / mon.scale), Math.round(mon.width / mon.scale));
    }

    // Position options derived from the LIVE monitor set (Task 7,
    // D-01 bundle 4) — never free-form coordinates. Single-monitor hosts
    // get exactly one option (the origin); a second/third monitor adds
    // one relative-placement option per neighbour per edge. Values are
    // the "XxY" shape hypr-overrides.sh monitor --position already
    // validates and verifies against .x/.y.
    function _positionOptions(mon) {
        var opts = [{ value: "0x0", display: "Origin (0, 0)" }];
        var size = root._logicalSize(mon);
        for (var i = 0; i < root.monitorsModel.length; i++) {
            var other = root.monitorsModel[i];
            if (other.name === mon.name)
                continue;
            var otherSize = root._logicalSize(other);
            opts.push({ value: (other.x + otherSize.width) + "x" + other.y, display: "Right of " + other.name });
            opts.push({ value: (other.x - size.width) + "x" + other.y, display: "Left of " + other.name });
            opts.push({ value: other.x + "x" + (other.y + otherSize.height), display: "Below " + other.name });
            opts.push({ value: other.x + "x" + (other.y - size.height), display: "Above " + other.name });
        }
        return opts;
    }

    Repeater {
        model: root.monitorsModel

        SettingsSection {
            id: monitorSection
            required property var modelData
            readonly property var windowsScale: root.windowsScales[modelData.name]

            title: modelData.name + (windowsScale ? " · " + windowsScale.name : "")
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
                visible: root.weaselway
                label: "Scale"
                subtext: root._scalePercent(monitorSection.modelData.scale) + " active · "
                    + monitorSection.modelData.width + " × " + monitorSection.modelData.height
                model: root._windowsScaleOptions(monitorSection.windowsScale)
                currentValue: monitorSection.windowsScale && monitorSection.windowsScale.saved !== null
                    ? String(monitorSection.windowsScale.saved) : "auto"
                enabled: !!monitorSection.windowsScale
                busy: windowsScaleApplyProc.running
                onSelected: (value) => {
                    if (monitorSection.windowsScale && !windowsScaleApplyProc.running) {
                        root.scaleError = "";
                        windowsScaleApplyProc.exec([root.desktopLauncher, "--display-scales", monitorSection.windowsScale.id, value]);
                    }
                }
            }

            SelectRow {
                visible: !root.weaselway
                label: "Resolution & refresh rate"
                subtext: monitorSection.modelData.make + " " + monitorSection.modelData.model
                model: monitorSection.resolutionOptions
                currentValue: root._currentModeString(monitorSection.modelData)
                onSelected: (value) => root.applyMonitorMode(monitorSection.modelData.name, value)
            }
            SelectRow {
                visible: !root.weaselway
                label: "Scale"
                subtext: "Display scaling"
                model: monitorSection.scaleOptions
                currentValue: monitorSection.modelData.scale.toString()
                onSelected: (value) => root.applyMonitorScale(monitorSection.modelData.name, value)
            }
            SelectRow {
                visible: !root.weaselway
                label: "Position"
                subtext: "Where this monitor sits relative to the others"
                model: root._positionOptions(monitorSection.modelData)
                currentValue: monitorSection.modelData.x + "x" + monitorSection.modelData.y
                onSelected: (value) => root.applyMonitorPosition(monitorSection.modelData.name, value)
            }
        }
    }

    SettingsSection {
        visible: root.weaselway
        title: "Arrangement"
        icon: "desktop_windows"

        Process {
            id: windowsDisplaysProc
            command: [root.desktopLauncher, "--display-settings"]
        }

        NavRow {
            label: "Open Arch Linux display settings"
            subtext: "Choose connected displays and the Linux main display"
            onActivated: {
                windowsDisplaysProc.startDetached();
                root.sState.close();
            }
        }
    }

    InfoRow {
        visible: root.scaleError.length > 0
        label: "Display scaling"
        subtext: root.scaleError
    }

    // ── Arrangement — N-04 (measured this task, not anticipated by
    //    RESEARCH.md): `hyprctl eval 'return hl.monitor({ output = "…",
    //    primary = true })'` returns "hl.monitor: unknown field
    //    'primary'" on this build — Hyprland exposes no primary-monitor
    //    concept through `hl.monitor` at all, and `hyprctl getoption`
    //    has no matching key either ("no such option"). An honest
    //    InfoRow instead of a knob that would silently no-op. ───────────
    SettingsSection {
        visible: !root.weaselway
        title: "Arrangement"
        icon: "desktop_windows"

        // Operator fix wave finding 4: plain-language rewrite — the
        // engineering rationale above (N-04) is unchanged, this is just
        // the row text.
        InfoRow {
            label: "No primary monitor setting"
            subtext: "There's no way to set a primary monitor here. Use Position above to arrange your monitors."
        }
    }

    // ── Advanced escape hatch — the same nwg-displays the QML menu's
    //    Display row already points at (MenuTree.qml).
    //    `Process.startDetached()`, not
    //    `running = true`: `onActivated` calls `root.sState.close()` in
    //    the same tick, which destroys this page (and any `running: true`
    //    Process owned by it) before uwsm's slower systemd/dbus hand-off
    //    completes — the exact race PowerMenu.qml's own header documents
    //    and fixes the same way. ────────────────────────────────────────
    SettingsSection {
        visible: !root.weaselway
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
