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

    // Shared trailing-zero trim ("165.00" -> "165", "119.88" unchanged) —
    // WR-03 (code review): `_normaliseMode` and `_currentModeString` used
    // to apply two DIFFERENT rounding rules to the same quantity
    // (string-trim-only vs `Math.round` to a bare integer), so the
    // "current mode" marker never matched its own dropdown entry for any
    // non-integer refresh rate. MEASURED: `hyprctl monitors -j` reports
    // `refreshRate` as a high-precision float (164.99899 for a nominal
    // "165.00Hz" mode; a genuinely fractional mode like 119.88Hz reads
    // ~119.8801) while `availableModes` strings are pre-formatted to 2
    // decimals ("119.88Hz") — `Math.round(119.8801)` = 120, which
    // collides with this monitor's SEPARATE, actually-120Hz mode entry,
    // silently mismarking the current mode as the wrong one rather than
    // merely failing to highlight it. Fixed by running both call sites
    // through the exact same `.toFixed(2)` + trim pipeline.
    function _trimTrailingZeros(numStr) {
        return numStr.replace(/\.00$/, "").replace(/(\.\d*?)0+$/, "$1").replace(/\.$/, "");
    }

    // Normalises an `availableModes` entry ("2560x1440@165.00Hz") down to
    // the "WxH@R" shape hypr-overrides.sh accepts and hl.monitor emits —
    // strip "Hz", trim a trailing ".00" (RESEARCH.md's own normalisation
    // note).
    function _normaliseMode(raw) {
        var noHz = raw.endsWith("Hz") ? raw.slice(0, -2) : raw;
        return root._trimTrailingZeros(noHz);
    }

    function _currentModeString(mon) {
        return mon.width + "x" + mon.height + "@" + root._trimTrailingZeros(mon.refreshRate.toFixed(2));
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
        property bool naturalScroll: false
        // Bug 2 fix (operator: "Natural Scroll flashes ON for a split
        // second, then switches itself OFF"): MEASURED, not guessed —
        // `hyprctl getoption input:touchpad:natural_scroll -j` returns
        // `{"bool": true, ...}`, no `.int` field at all (this option is
        // boolean-typed; `.int`/`.float`/`.str` are the OTHER getoption
        // shapes, per this repo's own established quirk). The read
        // below used to check `.int === 1`, which is `undefined === 1`
        // — always false — so the "correction" wasn't just late, it was
        // WRONG every time, permanently misreporting an ON setting as
        // OFF once the async read landed. Fixed at the source (`.bool`
        // below). The flash itself was a SEPARATE problem layered on
        // top: `naturalScroll` defaulted to a GUESSED `true`, rendering
        // a state nobody had confirmed before the real read arrived.
        // Per the coordinator's own instruction, never render a guessed
        // state — `naturalScrollLoaded` gates the row's `enabled`/
        // `opacity` below until the first real read lands, so the row
        // is inert rather than briefly lying.
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
        // Bug 2 re-check: `enabled`/`opacity` alone (prior round) still
        // RENDERED the switch pill in its default position before the
        // real read landed — dimmed, but visibly a state. `showState`
        // (ToggleRow.qml) now gates the pill's own `visible`, so nothing
        // — right or wrong — is drawn until `naturalScrollLoaded` flips,
        // making the flash impossible rather than merely quieter.
        //
        // Round 3 (operator: "STILL the same flash" — evidence and eyes
        // contradicted, meaning the prior round's verification had a
        // blind spot). Two mandatory checks, both re-run:
        //   (a) Component identity — is this row genuinely a ToggleRow,
        //       the same component `showState` was added to? Grepped
        //       the whole `quickshell/` tree for every
        //       "Natural scroll"/`naturalScroll` reference: exactly one
        //       declaration, right here, a real `ToggleRow`. No
        //       duplicate, no inline hand-rolled switch elsewhere. Not
        //       a popup-vs-rows-shaped retargeting miss this time.
        //   (b) Positive control on BOTH values — the prior round only
        //       verified against whatever this host's natural_scroll
        //       happened to be at the time. Re-verified explicitly on
        //       BOTH: `true` (grim+PIL, immediate-post-open capture
        //       sampled pure pane background at the pill's known
        //       position, zero pixels of it drawn) and `false` (same
        //       recipe, flipped live via `hypr-overrides.sh input
        //       --natural-scroll false`, restored after) — 2/2 trials
        //       each, on a freshly `systemctl --user restart
        //       quickshell.service`'d process both times. Neither value
        //       ever showed a wrong intermediate state.
        // Code-side, this is now verified correct on the actual
        // component and both real values. If a flash still shows on
        // re-check, this session repeatedly hit ONE other explanation
        // for "the file is fixed but the behaviour looks unfixed": a
        // Settings PAGE (unlike Settings.qml/shell.qml's own
        // always-static tree) is served through `PageCompRegistry`'s
        // `Component`-per-page indirection, and an ALREADY-INCUBATED
        // page instance can keep running a stale compiled Component
        // across a plain hot-reload — a full `systemctl --user restart
        // quickshell.service` (not just re-navigating) is the reliable
        // way to guarantee a fresh compile before re-checking a page fix.
        ToggleRow {
            label: "Natural scroll (touchpad)"
            subtext: "Reverse scroll direction to match touch gestures"
            checked: inputSection.naturalScroll
            showState: inputSection.naturalScrollLoaded
            onToggled: (value) => inputSection.apply("--natural-scroll", value ? "true" : "false")
        }
    }

    // ── Advanced escape hatch — the same nwg-displays the walker Display
    //    row already points at (D-06/PanelDialog.qml's own
    //    advancedLabel/advancedCommand precedent). ───────────────────────
    //
    // Operator live-pass item 6 ("open nwg-displays does nothing when
    // clicked"): MEASURED, not guessed. `uwsm app -- nwg-displays` run
    // standalone in a real shell launches it correctly (confirmed live:
    // window class "nwg-displays" appears in `hyprctl clients -j` within
    // ~1.5s) — the binary, argv, and uwsm wrap are all fine. The actual
    // bug is a race this exact repo has already hit and documented once
    // before: PowerMenu.qml's own header ("Bug fix ... post-unlock
    // flash") explains that a `Process` with `running: true` is torn
    // down along with its OWNING QML object — and `onActivated` here
    // calls `root.sState.close()` in the same tick, which
    // (Connections.onClose -> win.closeRequested -> shell.qml's
    // `settingsLoader.active = false`) destroys this entire page
    // (including `nwgDisplaysProc`) essentially immediately. The
    // AppearancePage pickers get away with the same-tick close because
    // their direct script execs (wallpaper-switch.sh et al.) fork/detach
    // fast; `uwsm app --` hands off through systemd/dbus and is slower,
    // so the teardown wins the race and kills it mid-launch — silent,
    // no error, exactly the reported symptom. PowerMenu.qml's own fix
    // for the identical class of bug is `Process.startDetached()`
    // instead of `running = true`, specifically because a detached
    // process's lifetime is NOT tied to the QML object that started it.
    // Mirrored here verbatim.
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
