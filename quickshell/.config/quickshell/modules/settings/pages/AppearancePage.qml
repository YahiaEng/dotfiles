// modules/settings/pages/AppearancePage.qml — Theme, Icon theme, Font,
// Fastfetch logo (quick-260821-6z1 Task 11, D-01 bundles 3/4, F-06 —
// page index 0 of the ten-page layout). Icon theme, Font and Fastfetch
// logo are now real inline SelectRows, populated from each script's
// `--list` (Task 10) and applied via its `--set`, with a `busy` spinner
// during the apply chain (the sprite regen alone costs ~250ms) so the
// wait reads as progress rather than nothing happening. Theme stays a
// SelectRow over the palettes directory listing, never a hardcoded case
// ladder (theme-switch.sh:13's own rule).
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
        // Operator fix wave finding 4: plain-language rewrite. The window
        // manager (borders/gaps) is a separate re-theme path from GTK/the
        // terminal — this row exists so the operator knows both follow
        // the same theme switch, and where the border settings live.
        InfoRow {
            label: "What Theme actually re-themes"
            subtext: "Switching the theme also changes your window borders and gaps, the terminal, and GTK apps — not just this window. Border settings live in Window manager → Borders."
        }
    }

    // ── Personalization — Icon theme, Font, Fastfetch logo, all real
    //    inline pickers now (Task 10 lands their --list/--set surface).
    //    Each list is fetched once on page mount by a fixed-argv Process
    //    with a watchdog Timer, parsed line-wise; each row shows `busy`
    //    during its own apply so the wait reads as progress. ─────────────
    SettingsSection {
        id: personalizationSection
        title: "Personalization"
        icon: "style"

        // ── Icon theme ───────────────────────────────────────────────────
        property var iconThemeOptions: []
        property bool iconThemeApplying: false

        FileView {
            id: iconThemeFile
            path: Quickshell.env("HOME") + "/.local/state/theme/icon-theme"
            watchChanges: true
            onFileChanged: reload()
        }
        readonly property string iconThemeName: (iconThemeFile.text() || "").trim()

        Timer {
            id: iconThemeListWatchdog
            interval: 5000
            onTriggered: {
                if (iconThemeListProc.running)
                    iconThemeListProc.running = false;
            }
        }
        Process {
            id: iconThemeListProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/icon-theme-picker.sh", "--list"]
            stdout: StdioCollector { id: iconThemeListCollector }
            onExited: (code, status) => {
                iconThemeListWatchdog.stop();
                if (code === 0) {
                    var lines = iconThemeListCollector.text.split("\n").filter(function (l) { return l.trim().length > 0; });
                    personalizationSection.iconThemeOptions = lines.map(function (n) { return { value: n, display: n }; });
                }
            }
            Component.onCompleted: {
                iconThemeListWatchdog.restart();
                running = true;
            }
        }
        Process {
            id: iconThemeApplyProc
            running: false
            onExited: (code, status) => {
                personalizationSection.iconThemeApplying = false;
                if (code !== 0)
                    console.warn("AppearancePage: icon-theme-picker.sh --set failed (exit " + code + ")");
            }
        }
        function applyIconTheme(name) {
            personalizationSection.iconThemeApplying = true;
            iconThemeApplyProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/icon-theme-picker.sh", "--set", name];
            iconThemeApplyProc.running = true;
        }

        // ── Font ─────────────────────────────────────────────────────────
        property var fontOptions: []
        property bool fontApplying: false

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

        Timer {
            id: fontListWatchdog
            interval: 5000
            onTriggered: {
                if (fontListProc.running)
                    fontListProc.running = false;
            }
        }
        Process {
            id: fontListProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/font-switcher.sh", "--list"]
            stdout: StdioCollector { id: fontListCollector }
            onExited: (code, status) => {
                fontListWatchdog.stop();
                if (code === 0) {
                    var lines = fontListCollector.text.split("\n").filter(function (l) { return l.trim().length > 0; });
                    personalizationSection.fontOptions = lines.map(function (n) { return { value: n, display: n }; });
                }
            }
            Component.onCompleted: {
                fontListWatchdog.restart();
                running = true;
            }
        }
        Process {
            id: fontApplyProc
            running: false
            onExited: (code, status) => {
                personalizationSection.fontApplying = false;
                if (code !== 0)
                    console.warn("AppearancePage: font-switcher.sh --set failed (exit " + code + ")");
            }
        }
        function applyFont(name) {
            personalizationSection.fontApplying = true;
            fontApplyProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/font-switcher.sh", "--set", name];
            fontApplyProc.running = true;
        }

        // ── Fastfetch logo (F-06) ───────────────────────────────────────
        property var fastfetchLogoOptions: []
        property bool fastfetchLogoApplying: false

        FileView {
            id: fastfetchLogoFile
            path: Quickshell.env("HOME") + "/.local/state/theme/fastfetch-logo"
            watchChanges: true
            onFileChanged: reload()
        }
        readonly property string fastfetchLogoName: (fastfetchLogoFile.text() || "").trim()

        Timer {
            id: fastfetchLogoListWatchdog
            interval: 5000
            onTriggered: {
                if (fastfetchLogoListProc.running)
                    fastfetchLogoListProc.running = false;
            }
        }
        Process {
            id: fastfetchLogoListProc
            running: false
            command: [Quickshell.env("HOME") + "/.config/hypr/scripts/fastfetch-logo-picker.sh", "--list"]
            stdout: StdioCollector { id: fastfetchLogoListCollector }
            onExited: (code, status) => {
                fastfetchLogoListWatchdog.stop();
                if (code === 0) {
                    var lines = fastfetchLogoListCollector.text.split("\n").filter(function (l) { return l.trim().length > 0; });
                    personalizationSection.fastfetchLogoOptions = lines.map(function (n) { return { value: n, display: n }; });
                }
            }
            Component.onCompleted: {
                fastfetchLogoListWatchdog.restart();
                running = true;
            }
        }
        Process {
            id: fastfetchLogoApplyProc
            running: false
            onExited: (code, status) => {
                personalizationSection.fastfetchLogoApplying = false;
                if (code !== 0)
                    console.warn("AppearancePage: fastfetch-logo-picker.sh --set failed (exit " + code + ")");
            }
        }
        function applyFastfetchLogo(name) {
            personalizationSection.fastfetchLogoApplying = true;
            fastfetchLogoApplyProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/fastfetch-logo-picker.sh", "--set", name];
            fastfetchLogoApplyProc.running = true;
        }

        SelectRow {
            label: "Icon theme"
            subtext: "Installed icon themes"
            model: personalizationSection.iconThemeOptions
            currentValue: personalizationSection.iconThemeName
            busy: personalizationSection.iconThemeApplying
            onSelected: (value) => personalizationSection.applyIconTheme(value)
        }
        SelectRow {
            label: "Font"
            subtext: "Installed Nerd Fonts"
            model: personalizationSection.fontOptions
            currentValue: personalizationSection.fontFamilyName
            busy: personalizationSection.fontApplying
            onSelected: (value) => personalizationSection.applyFont(value)
        }
        SelectRow {
            label: "Fastfetch logo"
            subtext: "The logo the greeter draws — sprites, ASCII art, random, or none"
            model: personalizationSection.fastfetchLogoOptions
            currentValue: personalizationSection.fastfetchLogoName
            busy: personalizationSection.fastfetchLogoApplying
            onSelected: (value) => personalizationSection.applyFastfetchLogo(value)
        }
    }

    // ── Drawer layouts (quick task 260826-rfy) ─────────────────────────
    // Which layout each of the Super+D drawer's two composed tabs draws.
    // The options and the design rationale behind them are the plates in
    // `.planning/notes/dashboard-perf-studies.html`; the vendored reference
    // they were drawn against is `.planning/notes/caelestia-dashboard/`.
    //
    // Both keys are read by `Dashboard.qml`'s tab Loaders, and a QML Loader
    // re-instantiates on `sourceComponent` change — so a pick here takes
    // effect the next time the pane is shown, with no shell restart.
    SettingsSection {
        id: drawerLayoutSection
        title: "Dashboard drawer"
        icon: "dashboard"

        readonly property var dashLayoutOptions: [
            { display: "Two lanes", value: "lanes" },
            { display: "Bento grid", value: "bento" },
            { display: "Wide column", value: "column" }
        ]
        readonly property var performanceLayoutOptions: [
            { display: "Telemetry strip", value: "telemetry" },
            { display: "Weighted arcs", value: "arcs" },
            { display: "Bento", value: "cards" },
            { display: "Tightened dials", value: "dials" }
        ]

        SelectRow {
            label: "Dashboard layout"
            // The bento grid is wider than the other two, so it pairs with
            // the Performance tab's "Caelestia cards" — picking one of the
            // two wide layouts on its own means the drawer changes width as
            // you cross between those tabs.
            subtext: "Lanes and wide column fit the frame; bento is wider — pair it with Performance's bento"
            model: drawerLayoutSection.dashLayoutOptions
            currentValue: Prefs.getValue("dashboard.layout.dash")
            onSelected: (value) => Prefs.setValue("dashboard.layout.dash", value)
        }
        SelectRow {
            label: "Performance layout"
            // "Bento" is the wide one here, and it pairs with the Dashboard's
            // bento grid above for the same reason given there. Both wide
            // layouts share the name deliberately — they are the matched
            // pair, and the value stays "cards" so an existing prefs.json
            // keeps resolving.
            subtext: "Telemetry graphs history; bento is wider — pair it with the Dashboard's bento"
            model: drawerLayoutSection.performanceLayoutOptions
            currentValue: Prefs.getValue("dashboard.layout.performance")
            onSelected: (value) => Prefs.setValue("dashboard.layout.performance", value)
        }
    }
}
