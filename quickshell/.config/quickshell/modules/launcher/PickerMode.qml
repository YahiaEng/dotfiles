// PickerMode.qml — reusable non-interactive-picker rows view (quick task
// 260822-sht, Task 5, extended Task 6, Stage 2 dmenu-consumer migration).
// D-1's inversion of control: the retired pattern blocked a shell script
// on an external picker and read the pick off stdout; a QML surface
// cannot do that, so the launcher now owns the list and the selection,
// and on pick invokes the consumer non-interactively with an argument.
// This file is the shared half of that shape — a rows view over parallel
// display/value arrays, an optional preselect, and a command-on-Enter —
// reused by three consumers now (`pickerId` selects which): Style ▸
// Theme, Style ▸ Bar orientation (Task 5) and Capture ▸ Record toggle
// audio (Task 6, mid-flow — `record-toggle.sh`'s own `pick_audio()`
// summons this directly via `qs ipc call launcher open recordaudio`
// rather than through a MenuTree leaf). Escape dismisses with no action,
// which is the whole of the old exit-130 cancel contract: there is no
// second process left to signal.
//
// Duck-typed interface Launcher.qml's generic keyboard-nav glue reads:
// `currentIndex`, `count`, `activate()` — same rows shape FilesMode.qml
// uses.
//
// `dismissCallback` is the same function-valued-property shape
// MenuMode.qml's own header documents: evaluated in the wrapping
// Component's enclosing scope (Launcher.qml), where `launcherWindow` is a
// visible id, then handed down as a plain property value.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "."

Item {
    id: root

    width: parent ? parent.width : 0
    height: Math.min(320, Math.max(root.count, 1) * 40)

    // "theme" (Style ▸ Theme), "barorientation" (Style ▸ Bar orientation)
    // or "recordaudio" (Capture ▸ Record toggle audio). Each owns its own
    // data source and command invocation below; everything else in this
    // file (rows rendering, keyboard nav, Enter -> exec -> dismiss) is
    // shared.
    required property string pickerId
    property var dismissCallback: null

    readonly property bool _isTheme: root.pickerId === "theme"
    readonly property bool _isRecordAudio: root.pickerId === "recordaudio"

    // Parallel index-matched arrays — never reverse-transform a
    // prettified label back to a value (T-05-06's own rule, carried over
    // verbatim from the retired theme-switch.sh this supersedes).
    property var displays: []
    property var values: []
    property int currentIndex: 0
    readonly property int count: root.displays.length

    // ── Bug 1 fix (quick task 260822-sht) ────────────────────────────────
    // The retired shape here ran `execProcess.running = true` then called
    // `dismissCallback()` on the very next line — which tears down this
    // whole surface (and every child `Process` on it) via shell.qml's
    // LazyLoader. `theme-apply` in particular renders ~22 targets and
    // reloads apps, well past this surface's own teardown, which is why
    // "Style ▸ Theme ▸ switching does not work" was reported: the child
    // process died mid-flight almost every time. None of these three
    // commands read stdin or need this file to observe their stdout/exit
    // code, so `Quickshell.execDetached` — the same primitive
    // MenuMode.qml's own leaf-command dispatch already used — spawns them
    // independent of this Item's lifetime instead of a longer-lived
    // `Process`.
    function activate() {
        const value = root.values[root.currentIndex];
        if (value === undefined)
            return;
        const home = Quickshell.env("HOME");
        let command;
        if (root._isTheme)
            command = [home + "/.config/theme-engine/theme-apply", value];
        else if (root._isRecordAudio)
            command = [home + "/.config/hypr/scripts/record-toggle.sh", "--audio", value];
        else
            command = [home + "/.config/hypr/scripts/bar-orientation.sh", value];
        Quickshell.execDetached(command);
        if (typeof root.dismissCallback === "function")
            root.dismissCallback();
    }

    // ── Theme data source (consumer 1) ──────────────────────────────────
    // `theme-engine/palettes/*.json` basenames, prettified (hyphen ->
    // space, title case) for display, plus the two Material You literals
    // — byte-identical to the retired `theme-switch.sh`'s own list. The
    // real name/literal is always what gets applied; prettifying is
    // display-only.
    function _prettify(raw) {
        const spaced = raw.replace(/-/g, " ");
        const words = spaced.split(" ");
        const out = [];
        for (let i = 0; i < words.length; i++) {
            const w = words[i];
            out.push(w.length > 0 ? w.charAt(0).toUpperCase() + w.slice(1) : w);
        }
        return out.join(" ");
    }

    property bool _paletteLoaded: false
    property bool _currentLoaded: false
    property string _currentValue: ""

    function _maybeFinalize() {
        if (!root._paletteLoaded || !root._currentLoaded)
            return;
        let idx = root.values.indexOf(root._currentValue);
        root.currentIndex = idx >= 0 ? idx : 0;
    }

    Process {
        id: paletteListProcess
        command: ["bash", "-c", "for f in " + Quickshell.env("HOME") + "/.config/theme-engine/palettes/*.json; do [ -f \"$f\" ] && basename \"$f\" .json; done"]
        stdout: StdioCollector {
            id: paletteCollector
        }
        onExited: exitCode => {
            const names = (paletteCollector.text || "").split("\n").filter(function (l) {
                return l.length > 0;
            });
            names.push("materialyou", "materialyou-light");
            const disps = names.map(function (n) {
                if (n === "materialyou")
                    return "Material You (Dynamic)";
                if (n === "materialyou-light")
                    return "Material You Light (Dynamic)";
                return root._prettify(n);
            });
            root.values = names;
            root.displays = disps;
            root._paletteLoaded = true;
            root._maybeFinalize();
        }
    }

    // Stale-theme-tracker-trap precedent (this repo's own recorded
    // finding): the current value lives at
    // `~/.local/state/theme/current-theme`, never the `~/.cache/`
    // orphan.
    Process {
        id: currentThemeProcess
        command: ["cat", Quickshell.env("HOME") + "/.local/state/theme/current-theme"]
        stdout: StdioCollector {
            id: currentThemeCollector
        }
        onExited: exitCode => {
            root._currentValue = exitCode === 0 ? (currentThemeCollector.text || "").trim() : "";
            root._currentLoaded = true;
            root._maybeFinalize();
        }
    }

    // ── Bar orientation data source (consumer 6) ────────────────────────
    // Same two display labels and slugs `bar-orientation.sh`'s own arrays
    // hold, preselected from the same state file the script writes
    // (`~/.local/state/quickshell/bar-orientation` — the script's own
    // `STATE_FILE`, verified against its source, not the plan text's
    // shorthand path).
    readonly property var _barDisplays: ["Horizontal", "Vertical"]
    readonly property var _barValues: ["horizontal", "vertical"]

    Process {
        id: barOrientationStateProcess
        command: ["cat", Quickshell.env("HOME") + "/.local/state/quickshell/bar-orientation"]
        stdout: StdioCollector {
            id: barOrientationCollector
        }
        onExited: exitCode => {
            const current = exitCode === 0 ? (barOrientationCollector.text || "").trim() : "horizontal";
            const idx = root._barValues.indexOf(current);
            root.displays = root._barDisplays;
            root.values = root._barValues;
            root.currentIndex = idx >= 0 ? idx : 0;
        }
    }

    // ── Record audio data source (consumer 5) ───────────────────────────
    // Same three display labels and device-string mappings
    // `record-toggle.sh`'s own retired `pick_audio()` interactive branch
    // held, moved here unchanged (this task's own plan text). No
    // preselect: this mode is reached only when the stored default is
    // "ask", so there is no "current" audio mode to highlight — opens
    // with Silent (index 0) under the cursor, the least-surprising
    // default for a mode with no persisted state of its own.
    readonly property var _audioDisplays: ["🔇 Silent (no audio)", "🔊 Desktop Audio", "🎙️ Desktop + Mic"]
    readonly property var _audioValues: ["silent", "desktop", "desktop+mic"]

    Component.onCompleted: {
        if (root._isTheme) {
            paletteListProcess.running = true;
            currentThemeProcess.running = true;
        } else if (root._isRecordAudio) {
            root.displays = root._audioDisplays;
            root.values = root._audioValues;
            root.currentIndex = 0;
        } else {
            barOrientationStateProcess.running = true;
        }
    }

    ListView {
        id: pickerListView
        anchors.fill: parent
        clip: true
        interactive: false
        model: root.displays
        currentIndex: root.currentIndex

        delegate: Rectangle {
            id: pickerDelegate
            required property string modelData
            required property int index

            width: pickerListView.width
            height: 40
            radius: 8
            color: root.currentIndex === pickerDelegate.index ? Colours.surfaceVariant : "transparent"

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 12
                text: pickerDelegate.modelData
                color: Colours.onSurface
                font.pixelSize: 15
                elide: Text.ElideRight
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.currentIndex = pickerDelegate.index;
                    root.activate();
                }
            }
        }
    }
    // Scroll indicator (quick task 260828-pol). Sibling of the view,
    // never a child: a Flickable/ListView appends Item children to its
    // scrolled contentItem, so a bar declared inside scrolls away.
    ThemedScrollBar {
        flickable: pickerListView
    }
}
