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
    }
}
