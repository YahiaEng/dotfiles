// modules/settings/pages/AppearancePage.qml — Task 1 ships one working
// knob: Theme (PD-05). The page enumerates
// ~/.config/theme-engine/palettes itself at runtime (never a hardcoded
// case ladder — theme-switch.sh:13's own rule) and calls theme-apply
// directly; theme-switch.sh itself is a walker-dmenu wrapper whose own UI
// would collide with this window's. Task 2 adds Wallpaper/Icon theme/Font/
// Bar orientation to this same page.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    title: "Appearance"

    // ── Palette enumeration — a Process listing the palettes directory,
    //    never a hardcoded array (theme-switch.sh:13's rule, mirrored
    //    exactly). The two Material You dynamic literals are appended
    //    after the listing, matching theme-switch.sh's own NAMES array. ──
    property var themeOptions: []

    function _prettify(raw) {
        var words = raw.split("-");
        var out = [];
        for (var i = 0; i < words.length; i++) {
            var w = words[i];
            out.push(w.length > 0 ? (w.charAt(0).toUpperCase() + w.slice(1)) : w);
        }
        return out.join(" ");
    }

    Process {
        id: paletteListProc
        running: false
        command: ["ls", Quickshell.env("HOME") + "/.config/theme-engine/palettes"]
        stdout: StdioCollector {
            id: paletteCollector
        }
        onExited: (exitCode, exitStatus) => {
            var lines = paletteCollector.text.split("\n");
            var opts = [];
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line.length > 5 && line.slice(-5) === ".json") {
                    var name = line.slice(0, -5);
                    opts.push({ value: name, display: root._prettify(name) });
                }
            }
            opts.push({ value: "materialyou", display: "Material You (Dynamic)" });
            opts.push({ value: "materialyou-light", display: "Material You Light (Dynamic)" });
            root.themeOptions = opts;
        }
        Component.onCompleted: running = true
    }

    // ── Current theme — plain-text state read, Probe.qml's own
    //    `.text()` pattern (Probe.qml:110-124), never
    //    ~/.cache/current-theme (a plausible-looking orphan). ────────────
    FileView {
        id: currentThemeFile
        path: Quickshell.env("HOME") + "/.local/state/theme/current-theme"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string currentThemeName: (currentThemeFile.text() || "").trim()

    // ── Apply — the script owns the write (D-03); this page writes
    //    nothing itself. Fixed argv, the theme name is never interpolated
    //    into a shell string. ──────────────────────────────────────────
    Process {
        id: themeApplyProc
        running: false
        command: [Quickshell.env("HOME") + "/.config/theme-engine/theme-apply", root.pendingThemeName]
    }
    property string pendingThemeName: ""

    function applyTheme(name) {
        root.pendingThemeName = name;
        themeApplyProc.running = true;
    }

    SettingsSection {
        title: "Theme"
        icon: "palette"

        SelectRow {
            label: "Theme"
            subtext: "Static palette or wallpaper-driven Material You"
            model: root.themeOptions
            currentValue: root.currentThemeName
            onSelected: (value) => root.applyTheme(value)
        }
    }
}
