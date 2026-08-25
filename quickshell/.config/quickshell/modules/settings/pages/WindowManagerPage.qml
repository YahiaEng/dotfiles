// modules/settings/pages/WindowManagerPage.qml — page index 7 of the
// ten-page layout (quick-260821-6z1 Task 5, D-01 bundle 1/D-03/R-2).
// Every write is a fixed-argv `hypr-overrides.sh look` call — the QML
// side does no validation, it submits and reports; the script owns
// validate -> apply -> verify -> persist. Every read is a read-only
// `hyprctl getoption -j` call using the ledger's own field name for that
// key (`gaps_in`/`gaps_out` parse the first component of the `.css`
// four-tuple, never `.int`).
//
// N-01 (Animation) — the Motion preset row moved here in Task 2 was
// relabelled "Animation speed" and paired with an InfoRow. quick-260821-swp
// (D-01/D-03) replaces that single speed axis with two independent rows:
// an "Animation style" picker (curve shape/duration character/Hyprland
// entry shape — config/animations.lua derives every style-varying leaf
// from motion.json's active `.styles` entry, so a second compositor knob
// would still be the same "second owner of a value motion.json owns"
// violation animations.lua's own header refuses to make) and a separate
// "Reduce motion" row for the accessibility axis (off/reduced/full),
// reachable without touching the style picker at all.
//
// N-02 (Borders) — an InfoRow beside border size states that border
// colour follows the active theme: theme-engine/lib/reload.sh runs
// `hyprctl reload` on every theme apply, which re-sources hyprland.lua's
// own `col.active_border` gradient from the token table — an
// eval-applied override would silently revert on the very next theme
// switch, and making it operator-owned would permanently remove the
// border from the theming pipeline (contrary to this project's Core
// Value). No border-colour control is added here.
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

    // ── Shared apply chain — ONE Process + ONE watchdog, reused by every
    //    row on this page (idle-overrides.sh's own proven shape,
    //    SessionPage.qml's `idleApplyProc`/`idleApplyWatchdog`): a script
    //    that hangs without ever firing `onExited` must not leave a row
    //    permanently `busy` — the watchdog force-clears it with a visible
    //    error after 10s, matching this repo's own established idiom for
    //    exactly this failure class (wave 7's root cause on the sibling
    //    Idle & lock section). `applyingKey` names WHICH row is in
    //    flight, since `applying` alone only says something is. ─────────
    property bool applying: false
    property string applyingKey: ""
    property bool watchdogFired: false
    property string lastError: ""

    function _readAll() {
        gapsInProc.running = true;
        gapsOutProc.running = true;
        gapsWorkspacesProc.running = true;
        borderSizeProc.running = true;
        roundingProc.running = true;
        blurEnabledProc.running = true;
        frostProc.running = true;
        blurSizeProc.running = true;
        blurPassesProc.running = true;
        inactiveOpacityProc.running = true;
        shadowEnabledProc.running = true;
        wbfProc.running = true;
        awcProc.running = true;
    }

    Timer {
        id: applyWatchdog
        interval: 10000
        onTriggered: {
            if (applyProc.running) {
                root.watchdogFired = true;
                applyProc.running = false;
            }
        }
    }

    Process {
        id: applyProc
        running: false
        stderr: StdioCollector { id: applyStderr }
        onExited: (exitCode, exitStatus) => {
            applyWatchdog.stop();
            root.applying = false;
            root.applyingKey = "";
            if (root.watchdogFired) {
                root.watchdogFired = false;
                root.lastError = "hypr-overrides.sh did not respond within 10s — it may be stuck; try again";
            } else if (exitCode !== 0) {
                root.lastError = applyStderr.text.trim() || ("hypr-overrides.sh look failed (exit " + exitCode + ")");
                console.warn("WindowManagerPage: " + applyStderr.text.trim());
            } else {
                root.lastError = "";
                root._readAll();
            }
        }
    }

    // `flag` is a fixed CLI flag name (e.g. "--gaps-in"); `value` is
    // always a String — SliderRow.moved()/ToggleRow.toggled() both hand
    // us a real/bool, converted to string ONLY here, at the argv
    // boundary, never string-concatenated into a shell command.
    function applyLook(key, flag, value) {
        root.lastError = "";
        root.applying = true;
        root.applyingKey = key;
        applyProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/hypr-overrides.sh", "look", flag, String(value)];
        applyProc.running = true;
        applyWatchdog.restart();
    }

    // ── Reads — one read-only hyprctl getoption -j Process per field,
    //    each re-run after every successful apply (root._readAll(),
    //    above) so the model reflects the JUST-VERIFIED state, never an
    //    assumption. gaps_in/gaps_out parse the FIRST component of the
    //    `.css` four-tuple field (the ledger's own field-name rule — NOT
    //    `.int`, the exact class of bug that already bit natural_scroll).
    property real gapsInValue: 5
    property real gapsOutValue: 10
    property real gapsWorkspacesValue: 0
    property real borderSizeValue: 3
    property real roundingValue: 12
    property bool blurEnabledValue: true
    // Frost is NOT a hyprctl option — it is the set of layer rules in
    // windowrules.lua, which this build applies at compositor startup only.
    // So it is read from and written through frost.sh rather than
    // `hyprctl getoption`/hypr-overrides.sh like every other row here.
    property bool frostValue: true
    property real blurSizeValue: 8
    property real blurPassesValue: 3
    property real inactiveOpacityValue: 0.92
    property bool shadowEnabledValue: true
    property bool wbfValue: false
    property bool awcValue: false

    function _firstCssToken(text) {
        var m = text.match(/"css"\s*:\s*"(\d+)/);
        return m ? parseFloat(m[1]) : NaN;
    }

    Process {
        id: gapsInProc
        running: false
        command: ["hyprctl", "getoption", "general:gaps_in", "-j"]
        stdout: StdioCollector { id: gapsInCollector }
        onExited: (code, status) => {
            var v = root._firstCssToken(gapsInCollector.text);
            if (!isNaN(v)) root.gapsInValue = v;
        }
        Component.onCompleted: running = true
    }
    Process {
        id: gapsOutProc
        running: false
        command: ["hyprctl", "getoption", "general:gaps_out", "-j"]
        stdout: StdioCollector { id: gapsOutCollector }
        onExited: (code, status) => {
            var v = root._firstCssToken(gapsOutCollector.text);
            if (!isNaN(v)) root.gapsOutValue = v;
        }
        Component.onCompleted: running = true
    }
    Process {
        id: gapsWorkspacesProc
        running: false
        command: ["hyprctl", "getoption", "general:gaps_workspaces", "-j"]
        stdout: StdioCollector { id: gapsWorkspacesCollector }
        onExited: (code, status) => {
            if (code === 0) {
                try { root.gapsWorkspacesValue = JSON.parse(gapsWorkspacesCollector.text).int; } catch (e) {}
            }
        }
        Component.onCompleted: running = true
    }
    Process {
        id: borderSizeProc
        running: false
        command: ["hyprctl", "getoption", "general:border_size", "-j"]
        stdout: StdioCollector { id: borderSizeCollector }
        onExited: (code, status) => {
            if (code === 0) {
                try { root.borderSizeValue = JSON.parse(borderSizeCollector.text).int; } catch (e) {}
            }
        }
        Component.onCompleted: running = true
    }
    Process {
        id: roundingProc
        running: false
        command: ["hyprctl", "getoption", "decoration:rounding", "-j"]
        stdout: StdioCollector { id: roundingCollector }
        onExited: (code, status) => {
            if (code === 0) {
                try { root.roundingValue = JSON.parse(roundingCollector.text).int; } catch (e) {}
            }
        }
        Component.onCompleted: running = true
    }
    Process {
        id: frostProc
        running: false
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/frost.sh", "--get"]
        stdout: StdioCollector { id: frostCollector }
        onExited: (code, status) => {
            if (code === 0)
                root.frostValue = frostCollector.text.trim() === "on";
        }
        Component.onCompleted: running = true
    }
    Process {
        id: frostSetProc
        running: false
        property string arg: "on"
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/frost.sh", arg]
        onExited: (code, status) => {
            // Re-read rather than trusting the write: frost.sh reports a
            // non-zero exit when any individual eval was rejected, and the
            // stored preference is the only thing worth believing.
            frostProc.running = true;
        }
    }
    Process {
        id: blurEnabledProc
        running: false
        command: ["hyprctl", "getoption", "decoration:blur:enabled", "-j"]
        stdout: StdioCollector { id: blurEnabledCollector }
        onExited: (code, status) => {
            if (code === 0) {
                try { root.blurEnabledValue = JSON.parse(blurEnabledCollector.text).bool === true; } catch (e) {}
            }
        }
        Component.onCompleted: running = true
    }
    Process {
        id: blurSizeProc
        running: false
        command: ["hyprctl", "getoption", "decoration:blur:size", "-j"]
        stdout: StdioCollector { id: blurSizeCollector }
        onExited: (code, status) => {
            if (code === 0) {
                try { root.blurSizeValue = JSON.parse(blurSizeCollector.text).int; } catch (e) {}
            }
        }
        Component.onCompleted: running = true
    }
    Process {
        id: blurPassesProc
        running: false
        command: ["hyprctl", "getoption", "decoration:blur:passes", "-j"]
        stdout: StdioCollector { id: blurPassesCollector }
        onExited: (code, status) => {
            if (code === 0) {
                try { root.blurPassesValue = JSON.parse(blurPassesCollector.text).int; } catch (e) {}
            }
        }
        Component.onCompleted: running = true
    }
    Process {
        id: inactiveOpacityProc
        running: false
        command: ["hyprctl", "getoption", "decoration:inactive_opacity", "-j"]
        stdout: StdioCollector { id: inactiveOpacityCollector }
        onExited: (code, status) => {
            if (code === 0) {
                try { root.inactiveOpacityValue = JSON.parse(inactiveOpacityCollector.text).float; } catch (e) {}
            }
        }
        Component.onCompleted: running = true
    }
    Process {
        id: shadowEnabledProc
        running: false
        command: ["hyprctl", "getoption", "decoration:shadow:enabled", "-j"]
        stdout: StdioCollector { id: shadowEnabledCollector }
        onExited: (code, status) => {
            if (code === 0) {
                try { root.shadowEnabledValue = JSON.parse(shadowEnabledCollector.text).bool === true; } catch (e) {}
            }
        }
        Component.onCompleted: running = true
    }
    Process {
        id: wbfProc
        running: false
        command: ["hyprctl", "getoption", "binds:workspace_back_and_forth", "-j"]
        stdout: StdioCollector { id: wbfCollector }
        onExited: (code, status) => {
            if (code === 0) {
                try { root.wbfValue = JSON.parse(wbfCollector.text).bool === true; } catch (e) {}
            }
        }
        Component.onCompleted: running = true
    }
    Process {
        id: awcProc
        running: false
        command: ["hyprctl", "getoption", "binds:allow_workspace_cycles", "-j"]
        stdout: StdioCollector { id: awcCollector }
        onExited: (code, status) => {
            if (code === 0) {
                try { root.awcValue = JSON.parse(awcCollector.text).bool === true; } catch (e) {}
            }
        }
        Component.onCompleted: running = true
    }

    SettingsSection {
        title: "Layout"
        icon: "space_dashboard"

        SliderRow {
            label: "Gaps in"
            subtext: "Space between windows"
            from: 0; to: 30; stepSize: 1
            value: root.gapsInValue
            enabled: !root.applying

            opacity: (root.applying && root.applyingKey === "gaps-in") ? 0.6 : 1
            onMoved: (v) => root.applyLook("gaps-in", "--gaps-in", Math.round(v))
        }
        SliderRow {
            label: "Gaps out"
            subtext: "Space between windows and screen edge"
            from: 0; to: 60; stepSize: 1
            value: root.gapsOutValue
            enabled: !root.applying

            opacity: (root.applying && root.applyingKey === "gaps-out") ? 0.6 : 1
            onMoved: (v) => root.applyLook("gaps-out", "--gaps-out", Math.round(v))
        }
        SliderRow {
            label: "Gaps between workspaces"
            subtext: "Space shown while swiping between workspaces"
            from: 0; to: 100; stepSize: 1
            value: root.gapsWorkspacesValue
            enabled: !root.applying

            opacity: (root.applying && root.applyingKey === "gaps-workspaces") ? 0.6 : 1
            onMoved: (v) => root.applyLook("gaps-workspaces", "--gaps-workspaces", Math.round(v))
        }
    }

    SettingsSection {
        title: "Borders"
        icon: "crop_square"

        SliderRow {
            label: "Border size"
            subtext: "Window border thickness, in pixels"
            from: 0; to: 10; stepSize: 1
            value: root.borderSizeValue
            enabled: !root.applying

            opacity: (root.applying && root.applyingKey === "border-size") ? 0.6 : 1
            onMoved: (v) => root.applyLook("border-size", "--border-size", Math.round(v))
        }
        // Operator fix wave finding 4: plain-language rewrite. Engineering
        // note (kept, not deleted): theme-apply re-runs `hyprctl reload`
        // on every theme switch (N-02), which re-sources the border
        // colour from the active theme — a persisted override here would
        // silently revert on the next switch.
        InfoRow {
            label: "Border colour"
            subtext: "Border colour follows your theme. Change it in Appearance → Theme."
        }
    }

    SettingsSection {
        title: "Decoration"
        icon: "blur_on"

        SliderRow {
            label: "Rounding"
            subtext: "Corner radius, in pixels"
            from: 0; to: 30; stepSize: 1
            value: root.roundingValue
            enabled: !root.applying

            opacity: (root.applying && root.applyingKey === "rounding") ? 0.6 : 1
            onMoved: (v) => root.applyLook("rounding", "--rounding", Math.round(v))
        }
        ToggleRow {
            label: "Blur"
            subtext: "Background blur behind transparent surfaces"
            checked: root.blurEnabledValue
            onToggled: (v) => root.applyLook("blur-enabled", "--blur-enabled", v ? "true" : "false")
        }
        ToggleRow {
            label: "Frost shell surfaces"
            subtext: "Frosted glass behind the bar, drawers, notifications and OSD. Off leaves them plainly transparent."
            checked: root.frostValue
            onToggled: (v) => {
                root.frostValue = v;
                frostSetProc.arg = v ? "on" : "off";
                frostSetProc.running = true;
            }
        }
        SliderRow {
            label: "Blur size"
            subtext: "Blur kernel radius"
            from: 1; to: 20; stepSize: 1
            value: root.blurSizeValue
            enabled: !root.applying

            opacity: (root.applying && root.applyingKey === "blur-size") ? 0.6 : 1
            onMoved: (v) => root.applyLook("blur-size", "--blur-size", Math.round(v))
        }
        SliderRow {
            label: "Blur passes"
            subtext: "More passes deepen the blur at a performance cost"
            from: 1; to: 5; stepSize: 1
            value: root.blurPassesValue
            enabled: !root.applying

            opacity: (root.applying && root.applyingKey === "blur-passes") ? 0.6 : 1
            onMoved: (v) => root.applyLook("blur-passes", "--blur-passes", Math.round(v))
        }
        SliderRow {
            label: "Inactive opacity"
            subtext: "Opacity of unfocused windows"
            from: 0.5; to: 1.0; stepSize: 0.01
            value: root.inactiveOpacityValue
            enabled: !root.applying

            opacity: (root.applying && root.applyingKey === "inactive-opacity") ? 0.6 : 1
            onMoved: (v) => root.applyLook("inactive-opacity", "--inactive-opacity", v.toFixed(2))
        }
        ToggleRow {
            label: "Shadow"
            subtext: "Drop shadow behind windows"
            checked: root.shadowEnabledValue
            onToggled: (v) => root.applyLook("shadow-enabled", "--shadow-enabled", v ? "true" : "false")
        }
    }

    SettingsSection {
        title: "Workspaces"
        icon: "view_carousel"

        ToggleRow {
            label: "Workspace back-and-forth"
            subtext: "Switching to the already-active workspace returns to the previous one"
            checked: root.wbfValue
            onToggled: (v) => root.applyLook("workspace-back-and-forth", "--workspace-back-and-forth", v ? "true" : "false")
        }
        ToggleRow {
            label: "Allow workspace cycles"
            subtext: "Cycling past the last workspace wraps around to the first"
            checked: root.awcValue
            onToggled: (v) => root.applyLook("allow-workspace-cycles", "--allow-workspace-cycles", v ? "true" : "false")
        }
    }

    // ── Animation — N-01, rebased onto the style/accessibility axis split
    //    by quick-260821-swp (D-01/D-03). The old single Motion preset
    //    conflated curve SHAPE with reduce-motion; this page now offers TWO
    //    independent rows: an animation STYLE picker (curve shape, duration
    //    character, Hyprland entry shape — `config/animations.lua` derives
    //    every style-varying leaf from the active style, same "one owner"
    //    reasoning the old comment gave) and a separate reduce-motion row
    //    (D-01: reachable from a control that is NOT the style picker).
    //    ──────────────────────────────────────────────────────────────
    property var motionStyleOptions: []
    property var motionAccessibilityOptions: []

    Process {
        id: motionListProc
        running: false
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/motion-switch.sh", "--list"]
        stdout: StdioCollector {
            id: motionListCollector
        }
        onExited: (exitCode, exitStatus) => {
            // motion-switch.sh --list's contract (R-2/R-3): a header line,
            // then one style per line as "  <key>\t<label>" — two leading
            // spaces, tab-separated. This parser and that format change
            // together, never one without the other.
            var lines = motionListCollector.text.split("\n");
            var opts = [];
            for (var i = 0; i < lines.length; i++) {
                var m = lines[i].match(/^  (\S+)\t(.+)$/);
                if (m) {
                    opts.push({ value: m[1], display: m[2] });
                }
            }
            root.motionStyleOptions = opts;
        }
        Component.onCompleted: running = true
    }

    Process {
        id: motionAccessListProc
        running: false
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/motion-switch.sh", "--list-accessibility"]
        stdout: StdioCollector {
            id: motionAccessListCollector
        }
        onExited: (exitCode, exitStatus) => {
            var lines = motionAccessListCollector.text.split("\n");
            var opts = [];
            for (var i = 0; i < lines.length; i++) {
                var m = lines[i].match(/^  (\S+)\t(.+)$/);
                if (m) {
                    opts.push({ value: m[1], display: m[2] });
                }
            }
            root.motionAccessibilityOptions = opts;
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
            root.currentMotionStyle = motionGetCollector.text.trim();
        }
        Component.onCompleted: running = true
    }
    property string currentMotionStyle: "md3"

    Process {
        id: motionAccessGetProc
        running: false
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/motion-switch.sh", "--get-accessibility"]
        stdout: StdioCollector {
            id: motionAccessGetCollector
        }
        onExited: (exitCode, exitStatus) => {
            root.currentMotionAccessibility = motionAccessGetCollector.text.trim();
        }
        Component.onCompleted: running = true
    }
    property string currentMotionAccessibility: "full"

    // The authoritative re-read MUST be chained off the apply process's own
    // onExited, never fired alongside it. motion-switch.sh writes
    // ~/.local/state/theme/motion-style and then re-renders; `--get` reads
    // that same file. Starting both in one tick raced them: `--get` won,
    // read the PREVIOUS value, and wrote it back over currentMotionStyle.
    // Since SelectRow is fully controlled (its currentDisplay derives only
    // from currentValue), the row visibly snapped back to the old style and
    // the user had to pick twice — the second pick reading the value the
    // FIRST pick had by then finished writing.
    Process {
        id: motionApplyProc
        running: false
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/motion-switch.sh", root.pendingMotionStyle]
        onExited: (exitCode, exitStatus) => {
            motionGetProc.running = true;
        }
    }
    property string pendingMotionStyle: ""

    Process {
        id: motionAccessApplyProc
        running: false
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/motion-switch.sh", "--accessibility", root.pendingMotionAccessibility]
        onExited: (exitCode, exitStatus) => {
            motionAccessGetProc.running = true;
        }
    }
    property string pendingMotionAccessibility: ""

    // The optimistic assignment gives the row instant feedback instead of
    // leaving it on the old value for the whole re-render; the chained
    // `--get` above is still the authority and will correct it if the apply
    // failed.
    function applyMotionStyle(name) {
        root.pendingMotionStyle = name;
        root.currentMotionStyle = name;
        motionApplyProc.running = true;
    }

    function applyMotionAccessibility(name) {
        root.pendingMotionAccessibility = name;
        root.currentMotionAccessibility = name;
        motionAccessApplyProc.running = true;
    }

    SettingsSection {
        id: motionSection
        title: "Animation"
        icon: "tune"

        SelectRow {
            label: "Animation style"
            subtext: "Controls animation shape, duration character, and Hyprland entry shape — the bar, panels, and window manager"
            model: root.motionStyleOptions
            currentValue: root.currentMotionStyle
            onSelected: (value) => root.applyMotionStyle(value)
        }
        SelectRow {
            label: "Reduce motion"
            subtext: "Shortens or disables animation everywhere — independent of the style above"
            model: root.motionAccessibilityOptions
            currentValue: root.currentMotionAccessibility
            onSelected: (value) => root.applyMotionAccessibility(value)
        }
    }

    Text {
        visible: root.lastError.length > 0
        width: parent.width
        wrapMode: Text.WordWrap
        text: root.lastError
        font.pixelSize: Design.fontLabel
        color: Colours.error
    }
}
