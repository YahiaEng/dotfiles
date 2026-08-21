// modules/settings/pages/WindowManagerPage.qml — page index 7 of the
// ten-page layout (quick-260821-6z1 Task 2 split, D-05/PD-02). Carries
// the Motion preset SelectRow moved out of ShellBehaviourPage.qml (now
// retired), byte-identical in behaviour to before the split. Task 5
// relabels this row "Animation speed" and adds the N-01 InfoRow beside
// it (the Motion preset IS the compositor animation-speed control on
// this build — see Task 5's own header once it lands), plus the full
// compositor-knob Layout/Borders/Decoration/Workspaces sections and the
// N-02 InfoRow. Motion preset is intentionally NOT renamed in this
// commit — Task 2 is pure restructuring, so any breakage here is
// unambiguously the split's fault, not a new row's.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Window manager"

    // ── Motion preset — never a hardcoded case ladder. `--list` output is
    //    human-formatted ("  Lively (x1.25)"); the slug is that word
    //    lower-cased, recovering exactly what the state file itself holds
    //    (motion-switch.sh's own `_read_motion_scale` case list is
    //    single-word, lower-case slugs). ─────────────────────────────────
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
}
