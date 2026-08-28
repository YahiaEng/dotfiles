// modules/settings/pages/BarPage.qml — page index 2 of the ten-page layout
// (quick-260821-6z1 Task 2 split, D-05/PD-02). Carries the Bar orientation
// SelectRow moved out of AppearancePage.qml, byte-identical in behaviour
// to before the split. Task 8 adds Visibility, Idle auto-hide and the six
// capsule toggles.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Bar"

    // ── Bar orientation — inline SelectRow over bar-orientation.sh's own
    //    closed two-value set. Current value from the entry model's own
    //    state file; the script owns the write. ─────────────────────────
    SettingsSection {
        id: barSection
        title: "Bar"
        icon: "dock_to_bottom"

        FileView {
            id: barOrientationFile
            path: Quickshell.env("HOME") + "/.local/state/quickshell/bar-orientation"
            watchChanges: true
            onFileChanged: reload()
        }
        readonly property string barOrientationValue: {
            var v = (barOrientationFile.text() || "").trim();
            return (v === "horizontal" || v === "vertical") ? v : "horizontal";
        }

        property string pendingOrientation: ""

        Process {
            id: barOrientationProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/bar-orientation.sh", barSection.pendingOrientation]
        }

        SelectRow {
            label: "Bar orientation"
            subtext: "Where the bar sits and which axis it lays out along"
            model: [
                { value: "horizontal", display: "Horizontal" },
                { value: "vertical", display: "Vertical" }
            ]
            currentValue: barSection.barOrientationValue
            onSelected: (value) => {
                barSection.pendingOrientation = value;
                barOrientationProc.running = true;
            }
        }
    }

    // ── Visibility (Task 8, D-01 bundle 2) — `bar-visibility.sh status`
    //    is THREE-valued (visible/hidden-idle/hidden-hard), so a
    //    ToggleRow's checked/unchecked pair cannot represent it honestly
    //    on its own — the toggle drives the `keybind toggle` verb, and
    //    the real three-valued status rides along as subtext so the
    //    operator sees not just THAT it is hidden but WHY. `main()`
    //    takes an flock before doing anything, so status is polled only
    //    while this page is mounted (a Timer started in
    //    Component.onCompleted, stopped in Component.onDestruction),
    //    never on a background timer that outlives the page. ────────────
    SettingsSection {
        id: visibilitySection
        title: "Visibility"
        icon: "visibility"

        property string statusValue: "visible"

        function refreshStatus() {
            statusProc.running = true;
        }

        Process {
            id: statusProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/bar-visibility.sh", "status"]
            stdout: StdioCollector { id: statusCollector }
            onExited: (code, status) => {
                if (code === 0) {
                    var v = statusCollector.text.trim();
                    if (v.length > 0)
                        visibilitySection.statusValue = v;
                }
            }
        }

        Process {
            id: toggleProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/bar-visibility.sh", "keybind", "toggle"]
            onExited: (code, status) => visibilitySection.refreshStatus()
        }

        Timer {
            id: statusPoll
            interval: 3000
            repeat: true
            onTriggered: visibilitySection.refreshStatus()
        }
        Component.onCompleted: {
            visibilitySection.refreshStatus();
            statusPoll.start();
        }
        Component.onDestruction: statusPoll.stop()

        ToggleRow {
            label: "Bar visible"
            subtext: "Current state: " + visibilitySection.statusValue
            checked: visibilitySection.statusValue === "visible"
            onToggled: (value) => toggleProc.running = true
        }
    }

    // ── Idle auto-hide (Task 8, D-01 bundle 2/D-02) — measured limit,
    //    stated plainly rather than shipping a fake toggle: idle-hide is
    //    wired unconditionally through a hypridle listener
    //    (idle-overrides.sh's own `on-timeout`/`on-resume` block calling
    //    `bar-visibility.sh idle hide`/`idle show`), and idle-overrides.sh
    //    has no per-listener enable/disable knob — only the TIMEOUT
    //    duration, which stays on the Session page's own "Bar idle-hide"
    //    row. Extending idle-overrides.sh for a real on/off gate is out
    //    of this task's file scope. This toggle is real but LIMITED: OFF
    //    immediately shows the bar and remembers the preference; it does
    //    not suppress a FUTURE idle timeout, which is why the subtext
    //    says so rather than implying full control. ─────────────────────
    SettingsSection {
        title: "Idle behaviour"
        icon: "lock_clock"

        Process {
            id: idleShowProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/bar-visibility.sh", "idle", "show"]
        }
        Process {
            id: idleReassertProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/bar-visibility.sh", "reassert"]
        }

        ToggleRow {
            label: "Idle auto-hide"
            subtext: "Off shows the bar immediately, but the next idle timeout may hide it again — this does not change the timeout itself (see Session → Bar idle-hide)"
            checked: Prefs.getValue("bar.autoHideOnIdle")
            onToggled: (value) => {
                Prefs.setValue("bar.autoHideOnIdle", value);
                if (!value)
                    idleShowProc.running = true;
                else
                    idleReassertProc.running = true;
            }
        }
    }

    // ── Edge bar (quick task 260823-9ak Task 4 R1/R2/R3, replaced with a
    //    five-entry style picker by quick task 260824-ns3 Task 1, Q1/Q2) —
    //    off unmounts both strips entirely (shell.qml's LazyLoader, not a
    //    visible:false binding, since a mounted-but-hidden layer surface
    //    would still hold its exclusiveZone and silently fail R3's "off is
    //    exactly today's behaviour") and the launcher reverts to its
    //    original top-drop direction. No switch anywhere and no
    //    greyed-out row — Q2 forbids a reachable "enabled:false +
    //    style:halo" dead state, and this picker's five values are the
    //    whole state space.
    SettingsSection {
        title: "Edge bar"
        icon: "border_horizontal"

        SelectRow {
            id: edgeBarStyleRow
            label: "Edge bar style"
            // One sentence per shape, describing what you will actually
            // SEE — not what the code does. `SelectRow` carries a single
            // subtext, so it follows the selection rather than listing all
            // five at once, which keeps the row one line tall.
            subtext: {
                switch (Prefs.getValue("edgeBar.style")) {
                case "continuous":
                    return "The rails run into the bar and stop, so the frame and the bar read as one shape.";
                case "brackets":
                    return "Four short corner pieces, nothing in between. Costs no screen space, and panels open free-floating.";
                case "segmented":
                    return "The top rail breaks into one piece per workspace, with the current one lit.";
                case "halo":
                    return "A 2px outline on all four edges, with the colour doing the work.";
                case "off":
                    return "No frame. The launcher drops from the top as it did before.";
                default:
                    return "Which shape, if any, the dashboard and launcher rise from.";
                }
            }
            model: [
                { value: "continuous", display: "Continuous" },
                { value: "brackets", display: "Brackets" },
                { value: "segmented", display: "Segmented" },
                { value: "halo", display: "Halo" },
                { value: "off", display: "Off" }
            ]
            currentValue: Prefs.getValue("edgeBar.style")
            onSelected: (value) => Prefs.setValue("edgeBar.style", value)
        }

        // Operator round 11. Reverses D-3 (the bulge was locked as a
        // permanent landmark); offered as a toggle rather than a swap so
        // both shapes stay reachable without a rollback.
        ToggleRow {
            label: "Animate the bulge"
            // True on every style this row is visible for, which is why it
            // says "a permanent one" rather than naming a size: on
            // Continuous switching this off leaves the shallow 4px static
            // bulge, and on Halo it leaves a deeper 6px motionless mass at
            // each centre. Both are landmarks; neither is "nothing".
            // (Segmented used to be in this list — round 12 removed the
            // choice there, see the visibility comment below.)
            subtext: "Rest the edges flat and swell the centre only while you hover it or its panel is open, instead of showing a permanent one"
            // ── SHOWN ON EXACTLY TWO STYLES ─────────────────────────────
            // An ALLOW-list, not a chain of exclusions. Three of the five
            // styles hide this row for three different reasons, and reading
            // "not brackets and not segmented and not off" tells you none
            // of them; "continuous or halo" is the actual rule.
            //
            //   Brackets  — draws no bulge at all, so there is nothing here
            //               to animate.
            //   Segmented — round 12. The row DID work, but the operator
            //               judged the permanent-merge state and removed
            //               the choice: the merge is the bulge ABSORBING
            //               whole segments, and holding that union reads as
            //               segments simply missing. shell.qml forces the
            //               animated value so the pref cannot strand it.
            //   off       — round 12c, and this REVERSES the reasoning that
            //               used to sit here. That reasoning argued only
            //               against `enabled: false` (ToggleRow has no
            //               styled disabled state, so a disabled row reads
            //               as broken) and then wrongly concluded the row
            //               should stay VISIBLE. Hiding it was the third
            //               option and the right one. The operator: "it has
            //               an 'animate bulge' option inside the settings
            //               menu which obviously does nothing and should
            //               not be there." With no rail mounted there is no
            //               bulge to animate, exactly as on Brackets.
            //
            // The row DECLARATION stays in the file in every case, so
            // settings-index-check's static scan keeps counting it against
            // its RowIndex entry regardless of what is on screen.
            visible: Prefs.getValue("edgeBar.style") === "continuous"
                || Prefs.getValue("edgeBar.style") === "halo"
            checked: Prefs.getValue("edgeBar.animatedBulge")
            onToggled: (value) => Prefs.setValue("edgeBar.animatedBulge", value)
        }
    }

    // ── Capsules (Task 8, D-01 bundle 2/D-02/PD-04) — FIVE capsule-level
    //    ToggleRows, each backed by Prefs.bar.capsules.<id> with a default
    //    of true. FOUR, not six: the "Clock & actions" and "System" parents
    //    were both RETIRED on operator request (2026-08-21) as redundant
    //    once every one of their children gained a per-entry toggle below —
    //    clock/gaming/notifications/settings/power for the first,
    //    cpu/ram/disk/gpu/updates for the second. Both keys are gone from
    //    Prefs' allowlist too, so nothing can write them any more;
    //    capsulesForZone()'s `typeof visible !== "boolean" -> true` guard
    //    means an absent key reads as visible, which is the intended
    //    behaviour. A capsule whose every child is toggled off collapses on
    //    its own — that is the per-entry filter's job, not a parent's. Consumed at
    //    exactly ONE place, BarEntryModel.capsulesForZone() — see that
    //    function's own header for why requiresBackend()/the three
    //    aggregate properties are deliberately NOT filtered. ─────────────
    SettingsSection {
        title: "Capsules"
        icon: "view_module"

        ToggleRow {
            label: "Launcher"
            subtext: "The app-launcher icon"
            checked: Prefs.getValue("bar.capsules.launcher")
            onToggled: (value) => Prefs.setValue("bar.capsules.launcher", value)
        }
        // ── Per-entry toggles for "System" (operator fix wave finding 3)
        //    — nested here, under their parent capsule's toggle, so the
        //    hierarchy reads. Turning the capsule off above still hides
        //    all five regardless of these; each is independently backed
        //    by Prefs.bar.entries.<id>, consumed at
        //    BarEntryModel.entryVisible()'s own single filter point. ─────
        ToggleRow {
            label: "CPU"
            subtext: "The CPU usage readout"
            checked: Prefs.getValue("bar.entries.cpu")
            onToggled: (value) => Prefs.setValue("bar.entries.cpu", value)
        }
        ToggleRow {
            label: "RAM"
            subtext: "The memory usage readout"
            checked: Prefs.getValue("bar.entries.ram")
            onToggled: (value) => Prefs.setValue("bar.entries.ram", value)
        }
        ToggleRow {
            label: "Disk"
            subtext: "The disk usage readout"
            checked: Prefs.getValue("bar.entries.disk")
            onToggled: (value) => Prefs.setValue("bar.entries.disk", value)
        }
        ToggleRow {
            label: "GPU"
            subtext: "The GPU usage readout — only renders on a host with a detected GPU"
            checked: Prefs.getValue("bar.entries.gpu")
            onToggled: (value) => Prefs.setValue("bar.entries.gpu", value)
        }
        ToggleRow {
            label: "Updates"
            subtext: "The pending-updates pill — only renders when updates are pending"
            checked: Prefs.getValue("bar.entries.updates")
            onToggled: (value) => Prefs.setValue("bar.entries.updates", value)
        }
        ToggleRow {
            label: "Workspaces"
            subtext: "The workspace indicator"
            checked: Prefs.getValue("bar.capsules.workspaces")
            onToggled: (value) => Prefs.setValue("bar.capsules.workspaces", value)
        }
        ToggleRow {
            label: "Idle inhibitor"
            subtext: "The idle-inhibitor bulb"
            checked: Prefs.getValue("bar.capsules.idleInhibitor")
            onToggled: (value) => Prefs.setValue("bar.capsules.idleInhibitor", value)
        }
        // ── Per-entry toggles for what used to be one "Media & connectivity"
        //    row (operator, quick task 260825-v3u). The parent row is GONE,
        //    not merely supplemented: the operator asked for individual
        //    toggles per capsule and for the group toggle to be removed,
        //    which is the same call already made for "Clock & actions" and
        //    "System" on 2026-08-21 once their children gained per-entry
        //    toggles. `bar.capsules.mediaConnectivity` is off Prefs'
        //    allowlist too, so nothing can write it any more; an absent key
        //    reads as visible through capsulesForZone()'s
        //    `typeof visible !== "boolean" -> true` guard, so the capsule
        //    itself simply stops being hideable as a unit and collapses on
        //    its own when all six children are off.
        //
        //    Order tracks the bar's own render order (BarEntryModel.qml:189-207),
        //    the same rule the System and Clock groups above and below follow.
        ToggleRow {
            label: "Media"
            subtext: "The now-playing readout and its popout — only renders while something is playing"
            checked: Prefs.getValue("bar.entries.media")
            onToggled: (value) => Prefs.setValue("bar.entries.media", value)
        }
        ToggleRow {
            label: "Audio"
            subtext: "The volume glyph, its scroll-to-adjust drawer and the mixer popout"
            checked: Prefs.getValue("bar.entries.audio")
            onToggled: (value) => Prefs.setValue("bar.entries.audio", value)
        }
        ToggleRow {
            label: "Brightness"
            subtext: "The screen-brightness readout — only renders on a host with a backlight"
            checked: Prefs.getValue("bar.entries.brightness")
            onToggled: (value) => Prefs.setValue("bar.entries.brightness", value)
        }
        ToggleRow {
            label: "Network"
            subtext: "The Wi-Fi glyph and its picker, plus the wired readout when Ethernet is up"
            checked: Prefs.getValue("bar.entries.network")
            onToggled: (value) => Prefs.setValue("bar.entries.network", value)
        }
        ToggleRow {
            label: "Bluetooth"
            // Said plainly rather than left to be discovered: the bar reveals
            // bluetooth by hovering the network glyph, so turning Network off
            // while leaving this on leaves bluetooth with nothing to hide
            // behind.
            subtext: "The Bluetooth glyph and its device list — revealed by hovering Network, so it sits on its own if Network is off"
            checked: Prefs.getValue("bar.entries.bluetooth")
            onToggled: (value) => Prefs.setValue("bar.entries.bluetooth", value)
        }
        ToggleRow {
            label: "Battery"
            subtext: "The battery readout — only renders on a host with a battery"
            checked: Prefs.getValue("bar.entries.battery")
            onToggled: (value) => Prefs.setValue("bar.entries.battery", value)
        }
        // System tray (quick task 260823-65s, D-4) — placed here so the
        // settings order tracks the bar order (D-3: the capsule renders
        // immediately after mediaConnectivity, before clockActions).
        ToggleRow {
            label: "System tray"
            subtext: "Tray icons from apps that minimise to tray"
            checked: Prefs.getValue("bar.capsules.systemTray")
            onToggled: (value) => Prefs.setValue("bar.capsules.systemTray", value)
        }
        // Icon tint (quick task 260823-65s, operator round-3 feedback) —
        // placed immediately after "System tray" so settings order keeps
        // tracking bar order. Pure Prefs read/write, same shape as every
        // other SelectRow in this file (AudioPage.qml's device pickers
        // are the fuller reference) — no `busy` state is needed since
        // there is no external process/device confirmation to wait on,
        // unlike the "Bar orientation" row above.
        SelectRow {
            label: "Tray icon tint"
            subtext: "How app tray icons are coloured to match the theme"
            model: [
                { value: "tinted", display: "Tinted" },
                { value: "desaturate", display: "Desaturated" },
                { value: "off", display: "Off" }
            ]
            // Migration (round 5) — "monochrome" (the prior build's value,
            // which some installs, including this host during development,
            // already persisted) is not in the model above any more and
            // would otherwise render as raw, unmatched text instead of a
            // selected pill (SelectRow.currentDisplay falls back to the raw
            // currentValue string when no model entry matches it). Mapped
            // forward to "tinted" here, same rule TrayCapsule.qml/
            // TrayPopout.qml apply at their own read sites.
            currentValue: {
                var raw = Prefs.getValue("bar.tray.iconTint");
                return raw === "monochrome" ? "tinted" : raw;
            }
            onSelected: (value) => Prefs.setValue("bar.tray.iconTint", value)
        }
        // ── Per-entry toggles for "Clock & actions" (operator fix wave
        //    finding 3) — same nesting/consumption pattern as System's
        //    five above. `power` shipped deliberately: Super+Shift+Q
        //    (hypr/config/keybinds.lua) opens the same power menu, so
        //    hiding this bar entry removes no capability.
        ToggleRow {
            label: "Clock"
            subtext: "The clock and its popout"
            checked: Prefs.getValue("bar.entries.clock")
            onToggled: (value) => Prefs.setValue("bar.entries.clock", value)
        }
        ToggleRow {
            label: "Gaming mode"
            subtext: "The gaming-mode toggle glyph"
            checked: Prefs.getValue("bar.entries.gaming")
            onToggled: (value) => Prefs.setValue("bar.entries.gaming", value)
        }
        ToggleRow {
            label: "Notifications"
            subtext: "The notification bell and its centre"
            checked: Prefs.getValue("bar.entries.notifications")
            onToggled: (value) => Prefs.setValue("bar.entries.notifications", value)
        }
        ToggleRow {
            label: "Security"
            subtext: "The security status glyph, next to the notification bell"
            checked: Prefs.getValue("bar.entries.security")
            onToggled: (value) => Prefs.setValue("bar.entries.security", value)
        }
        ToggleRow {
            label: "Settings"
            subtext: "The settings gear and its quick-settings strip"
            checked: Prefs.getValue("bar.entries.settings")
            onToggled: (value) => Prefs.setValue("bar.entries.settings", value)
        }
        ToggleRow {
            label: "Power"
            subtext: "The power-menu glyph — Super+Shift+Q opens the same menu either way"
            checked: Prefs.getValue("bar.entries.power")
            onToggled: (value) => Prefs.setValue("bar.entries.power", value)
        }
    }
}
