// modules/settings/pages/AppearancePage.qml — Theme (Task 1, PD-05) plus
// Wallpaper/Icon theme/Font/Bar orientation (Task 2), D-01's full
// Appearance group. The page enumerates ~/.config/theme-engine/palettes
// itself at runtime (never a hardcoded case ladder — theme-switch.sh:13's
// own rule) and calls theme-apply directly; theme-switch.sh itself is a
// walker-dmenu wrapper whose own UI would collide with this window's.
// Wallpaper/Icon theme/Font are summoned, never rebuilt (D-04) — each
// NavRow runs the EXACT script the walker row runs today, then closes
// this window (via `sState.close()`) so the picker's own floating kitty
// is not summoned behind it.
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

    // ── Wallpaper / Icon theme / Font — summoned pickers (D-04). Each
    //    NavRow runs the identical command the walker row runs today and
    //    closes this window via `sState.close()` so the picker's own
    //    floating kitty is never summoned behind it. ─────────────────────
    SettingsSection {
        id: personalizationSection
        title: "Personalization"
        icon: "style"

        FileView {
            id: iconThemeFile
            path: Quickshell.env("HOME") + "/.local/state/theme/icon-theme"
            watchChanges: true
            onFileChanged: reload()
        }
        readonly property string iconThemeName: (iconThemeFile.text() || "").trim()

        FileView {
            id: kittyFontFile
            path: Quickshell.env("HOME") + "/.local/state/theme/kitty-font.conf"
            watchChanges: true
            onFileChanged: reload()
        }
        // `font_family      <name>` is the first line kitty-font.conf's
        // renderer emits — every value after the keyword, arbitrary
        // internal whitespace tolerated, is the family name.
        readonly property string fontFamilyName: {
            var lines = (kittyFontFile.text() || "").split("\n");
            for (var i = 0; i < lines.length; i++) {
                var m = lines[i].match(/^font_family\s+(.+)$/);
                if (m)
                    return m[1].trim();
            }
            return "";
        }

        Process {
            id: wallpaperBasenameProc
            running: false
            command: ["readlink", "-f", Quickshell.env("HOME") + "/.local/state/theme/current.jpg"]
            stdout: StdioCollector {
                id: wallpaperBasenameCollector
            }
            onExited: (exitCode, exitStatus) => {
                var full = wallpaperBasenameCollector.text.trim();
                var parts = full.split("/");
                personalizationSection.wallpaperBasename = parts.length > 0 ? parts[parts.length - 1] : full;
            }
        }
        property string wallpaperBasename: ""
        Component.onCompleted: wallpaperBasenameProc.running = true

        Process {
            id: wallpaperLaunchProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-switch.sh"]
        }
        Process {
            id: iconThemeLaunchProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/icon-theme-switch.sh"]
        }
        Process {
            id: fontLaunchProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/font-switch.sh"]
        }

        NavRow {
            label: "Wallpaper"
            subtext: personalizationSection.wallpaperBasename
            onActivated: {
                wallpaperLaunchProc.running = true;
                root.sState.close();
            }
        }
        NavRow {
            label: "Icon theme"
            subtext: personalizationSection.iconThemeName
            onActivated: {
                iconThemeLaunchProc.running = true;
                root.sState.close();
            }
        }
        NavRow {
            label: "Font"
            subtext: personalizationSection.fontFamilyName
            onActivated: {
                fontLaunchProc.running = true;
                root.sState.close();
            }
        }
    }

    // ── Bar orientation — inline SelectRow over bar-orientation.sh's own
    //    closed two-value set (lines 27-30). Current value from the
    //    entry model's own state file; the script owns the write. ───────
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
}
