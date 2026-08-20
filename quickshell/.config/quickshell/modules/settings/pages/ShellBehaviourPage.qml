// modules/settings/pages/ShellBehaviourPage.qml — D-01's Shell behaviour
// group: motion preset (`motion-switch.sh`, already settings-ready via
// its own `--list`/`--get`) and notification DND (`NotifServer`,
// already in-process and already persisted — this row is a second VIEW
// of state that already exists, not a new writer). The idle/lock section
// is Task 4's seam, deliberately left unbuilt here (PD-03) — Task 4 must
// re-measure the persistence mechanism against the installed hypridle
// binary before any UI is wired to it.
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

    // ── Idle & lock — Task 4's seam (PD-03). Left visibly marked, not a
    //    silent placeholder: Task 4 owns both the mechanism re-measurement
    //    (hypridle's `source =` support, re-confirmed against the
    //    installed binary before any control here is wired) and this
    //    section's own content.
    SettingsSection {
        title: "Idle & lock"
        icon: "lock_clock"
        // Task 4 fills this section with one row per listener
        // (screen dim, screen off, lock, suspend), each backed by
        // idle-overrides.sh. Intentionally empty until then.
    }
}
