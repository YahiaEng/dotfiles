// modules/settings/pages/InputPage.qml — page index 6 of the ten-page
// layout (quick-260821-6z1 Task 2 split, D-05/PD-02). Carries the global
// Input section (keyboard layout, follow mouse, pointer sensitivity,
// natural scroll) moved out of DisplayInputPage.qml (now retired),
// byte-identical in behaviour to before the split — that page's monitor
// half moved to its own DisplayPage.qml (index 5) instead. Global
// `input {}` granularity for now (F-03 not yet in scope this task);
// Task 7 adds the "Show all devices" toggle and per-device keyboard
// layout / scroll factor Repeaters on top of these four rows, plus the
// N-03 InfoRow explaining why per-device sensitivity cannot be added.
// Current values are read-only `hyprctl getoption -j` calls; writes go
// through hypr-overrides.sh input, never a direct hyprctl call from this
// page (D-03).
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Input"

    SettingsSection {
        id: inputSection
        title: "Input"
        icon: "keyboard"

        property string kbLayout: "us"
        property int followMouseValue: 1
        property real sensitivityValue: 0
        property bool naturalScroll: false
        // `hyprctl getoption input:touchpad:natural_scroll -j` returns
        // `.bool`, never `.int` (this repo's own established quirk) — see
        // naturalScrollProc below. `naturalScrollLoaded` gates the row's
        // own rendered state until the first real read lands, so nothing
        // — right or wrong — is ever drawn as a guess.
        property bool naturalScrollLoaded: false

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
                        inputSection.naturalScroll = JSON.parse(naturalScrollCollector.text).bool === true;
                        inputSection.naturalScrollLoaded = true;
                    } catch (e) {}
                }
            }
            Component.onCompleted: running = true
        }

        // Fixed argv, same discipline as DisplayPage.qml's own monitor
        // apply — no shell, every element a discrete array entry.
        Process {
            id: inputApplyProc
            running: false
            onExited: (exitCode, exitStatus) => {
                if (exitCode === 0)
                    inputSection.refresh();
                else
                    console.warn("InputPage: hypr-overrides.sh input failed (exit " + exitCode + ")");
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
            subtext: "libinput sensitivity, -1.0 to 1.0 — applies to all pointers"
            from: -1.0
            to: 1.0
            stepSize: 0.05
            value: inputSection.sensitivityValue
            onMoved: (value) => inputSection.apply("--sensitivity", value.toFixed(2))
        }
        // `showState` (ToggleRow.qml) gates the pill's own `visible`, so
        // nothing — right or wrong — is drawn until
        // `naturalScrollLoaded` flips: the row is inert rather than
        // briefly rendering a guessed state.
        ToggleRow {
            label: "Natural scroll (touchpad)"
            subtext: "Reverse scroll direction to match touch gestures — applies to all pointers"
            checked: inputSection.naturalScroll
            showState: inputSection.naturalScrollLoaded
            onToggled: (value) => inputSection.apply("--natural-scroll", value ? "true" : "false")
        }
        InfoRow {
            label: "No per-device sensitivity setting"
            subtext: "This compositor build reports no value back for per-device pointer sensitivity or per-device natural scroll, so neither can be verified — and an unverifiable write is not shipped here. The two rows above apply to every pointer."
        }
    }

    // ── Per-device (Task 7, D-08/F-03/R-5) ──────────────────────────────
    SettingsSection {
        id: devicesSection
        title: "Per-device"
        icon: "keyboard"

        ToggleRow {
            label: "Show all devices"
            subtext: "Off shows only the primary keyboard and the pointers this compositor reports; on shows every joined device"
            checked: Prefs.getValue("input.showAllDevices")
            onToggled: (value) => Prefs.setValue("input.showAllDevices", value)
        }

        // Fetched once on page mount from the udev-filtered device list
        // (hypr-overrides.sh devices) — never the raw `hyprctl devices -j`
        // list directly, which still contains the phantom ID_INPUT_KEY
        // -only nodes (power buttons, headset consumer-control) this
        // script already excludes. A watchdog Timer keeps a hung script
        // from leaving this section permanently empty with no
        // explanation.
        property var devicesModel: ({ keyboards: [], mice: [] })
        property bool devicesLoaded: false
        property string devicesError: ""

        // Live current values (layout/scrollFactor) come from the raw
        // `hyprctl devices -j` oracle — the ONLY per-device read-back
        // this build has (RESEARCH.md §5.3); `hypr-overrides.sh devices`
        // itself carries only name/primary/joined, not current values.
        property var liveDevicesModel: ({ keyboards: [], mice: [] })

        // Fix WR-04 (code review, quick-260821-6z1 fix wave) — the GLOBAL
        // `input:scroll_factor` value, read separately from the per-device
        // ones above. `hypr-overrides.sh`'s own `cmd_device` comment names
        // this as the value a per-device "reset to default" must write
        // back, since the real "-1 = inherit global" sentinel is not
        // writable through this script (`hl.device` rejects a negative
        // scroll_factor outright) — this is that substitution, at the
        // "QML call site" the script's own comment names.
        property real globalScrollFactor: 1.0

        readonly property var visibleKeyboards: {
            var all = (devicesSection.devicesModel.keyboards || []).filter(function (k) { return k.joined; });
            if (Prefs.getValue("input.showAllDevices"))
                return all;
            return all.filter(function (k) { return k.primary; });
        }
        readonly property var visibleMice: {
            var all = (devicesSection.devicesModel.mice || []).filter(function (m) { return m.joined; });
            if (Prefs.getValue("input.showAllDevices"))
                return all;
            return all.filter(function (m) { return m.primary; });
        }

        function _liveLayoutFor(name) {
            var kbs = devicesSection.liveDevicesModel.keyboards || [];
            for (var i = 0; i < kbs.length; i++) {
                if (kbs[i].name === name)
                    return kbs[i].layout || "us";
            }
            return "us";
        }
        function _liveScrollFactorFor(name) {
            var mice = devicesSection.liveDevicesModel.mice || [];
            for (var i = 0; i < mice.length; i++) {
                if (mice[i].name === name)
                    return mice[i].scrollFactor;
            }
            return 1.0;
        }

        function refresh() {
            devicesSection.devicesError = "";
            devicesListProc.running = true;
            liveDevicesProc.running = true;
            devicesWatchdog.restart();
        }

        Timer {
            id: devicesWatchdog
            interval: 5000
            onTriggered: {
                if (devicesListProc.running) {
                    devicesListProc.running = false;
                    devicesSection.devicesError = "hypr-overrides.sh devices did not respond within 5s";
                }
            }
        }

        Process {
            id: devicesListProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/hypr-overrides.sh", "devices"]
            stdout: StdioCollector { id: devicesListCollector }
            onExited: (code, status) => {
                devicesWatchdog.stop();
                devicesSection.devicesLoaded = true;
                if (code === 0) {
                    try {
                        devicesSection.devicesModel = JSON.parse(devicesListCollector.text);
                    } catch (e) {
                        devicesSection.devicesError = "hypr-overrides.sh devices returned unparseable output";
                    }
                } else {
                    devicesSection.devicesError = "hypr-overrides.sh devices failed (exit " + code + ")";
                }
            }
            Component.onCompleted: running = true
        }

        Process {
            id: liveDevicesProc
            running: false
            command: ["hyprctl", "devices", "-j"]
            stdout: StdioCollector { id: liveDevicesCollector }
            onExited: (code, status) => {
                if (code === 0) {
                    try {
                        devicesSection.liveDevicesModel = JSON.parse(liveDevicesCollector.text);
                    } catch (e) {}
                }
            }
            Component.onCompleted: running = true
        }

        Process {
            id: globalScrollFactorProc
            running: false
            command: ["hyprctl", "getoption", "input:scroll_factor", "-j"]
            stdout: StdioCollector { id: globalScrollFactorCollector }
            onExited: (code, status) => {
                if (code === 0) {
                    try {
                        devicesSection.globalScrollFactor = JSON.parse(globalScrollFactorCollector.text).float;
                    } catch (e) {}
                }
            }
            Component.onCompleted: running = true
        }

        Process {
            id: deviceApplyProc
            running: false
            onExited: (code, status) => {
                if (code === 0)
                    devicesSection.refresh();
                else
                    console.warn("InputPage: hypr-overrides.sh device failed (exit " + code + ")");
            }
        }

        function applyDeviceKbLayout(name, layout) {
            deviceApplyProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/hypr-overrides.sh", "device", name, "--kb-layout", layout];
            deviceApplyProc.running = true;
        }
        function applyDeviceScrollFactor(name, factor) {
            deviceApplyProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/hypr-overrides.sh", "device", name, "--scroll-factor", factor];
            deviceApplyProc.running = true;
        }

        Text {
            visible: devicesSection.devicesError.length > 0
            width: parent.width
            wrapMode: Text.WordWrap
            text: devicesSection.devicesError
            font.pixelSize: Design.fontLabel
            color: Colours.error
        }

        Repeater {
            model: devicesSection.visibleKeyboards

            SelectRow {
                id: kbRow
                required property var modelData

                label: "Per-device keyboard layout"
                subtext: kbRow.modelData.name + (kbRow.modelData.primary ? " (main keyboard)" : " (secondary keyboard)")
                model: [
                    { value: "us", display: "US" },
                    { value: "gb", display: "UK" },
                    { value: "de", display: "German" },
                    { value: "fr", display: "French" },
                    { value: "es", display: "Spanish" },
                    { value: "ru", display: "Russian" }
                ]
                currentValue: devicesSection._liveLayoutFor(kbRow.modelData.name)
                onSelected: (value) => devicesSection.applyDeviceKbLayout(kbRow.modelData.name, value)
            }
        }

        Repeater {
            model: devicesSection.visibleMice

            SliderRow {
                id: mouseRow
                required property var modelData

                label: "Per-device pointer scroll factor"
                subtext: mouseRow.modelData.name + " — 0.0 (slowest) to 10.0 (fastest)"
                from: 0.0
                to: 10.0
                stepSize: 0.1
                value: devicesSection._liveScrollFactorFor(mouseRow.modelData.name)
                onMoved: (value) => devicesSection.applyDeviceScrollFactor(mouseRow.modelData.name, value.toFixed(2))
                // Fix WR-04 — "reset to default" writes back the current
                // GLOBAL input:scroll_factor value (the real -1 "inherit
                // global" sentinel cannot be written through this script;
                // see globalScrollFactorProc's own comment above).
                resettable: true
                onResetRequested: devicesSection.applyDeviceScrollFactor(mouseRow.modelData.name, devicesSection.globalScrollFactor.toFixed(2))
            }
        }
    }
}
