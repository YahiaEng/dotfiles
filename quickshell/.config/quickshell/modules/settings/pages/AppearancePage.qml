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
import "../../appearance"

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

    // ── Personalization — Icon theme, Font, Fastfetch logo. Icon theme
    //    and Font now read AppearanceBackend (quick task 260828-ah9,
    //    Task 1) — one backend, four readers: this page, the Atelier's
    //    Icons/Fonts tabs, the launcher's `icon`/`font` routes and the
    //    bar's clock drawer. Fastfetch logo is a DIFFERENT script and
    //    stays exactly as it was, page-scoped. ─────────────────────────
    SettingsSection {
        id: personalizationSection
        title: "Personalization"
        icon: "style"

        function _fontRowDisplay(f) {
            if (f.behaviour === "mono")
                return f.family + " · Mono";
            if (f.behaviour === "propo")
                return f.family + " · Propo";
            return f.family;
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
            model: AppearanceBackend.iconThemes.map(function (n) { return { value: n, display: n }; })
            currentValue: AppearanceBackend.iconThemeName
            busy: AppearanceBackend.iconApplying
            onSelected: (value) => AppearanceBackend.applyIconTheme(value)
        }
        SelectRow {
            label: "Font"
            subtext: "Installed Nerd Fonts — 13 families, Mono/Propo spacing (M2: the third cut was a measured duplicate)"
            model: AppearanceBackend.fontFamilies.map(function (f) { return { value: f.rawName, display: personalizationSection._fontRowDisplay(f) }; })
            currentValue: AppearanceBackend.activeFontRaw
            busy: AppearanceBackend.fontApplying
            onSelected: (value) => AppearanceBackend.applyFont(value)
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

    // ── Lock screen (quick task 260827-833, LOCK-01) ────────────────────
    // Which of the five operator-approved in-process lock-screen layouts
    // `LockSurface.qml`'s own switch resolves. A QML Loader re-instantiates
    // on `sourceComponent` change (the same mechanism the dashboard
    // drawer's own layout picker above already relies on), so a pick here
    // applies the next time the session locks — no shell restart.
    //
    // `Prefs.qml` already carries `lock.layout` in both `_allowedKeys` and
    // `_defaults` (Task 1); this section only adds the row. Default stays
    // "continuity" — flipping it is the operator's own call (operator
    // checklist item 9). It was held there during the migration so the
    // old lock config stayed mechanically comparable; that config was
    // retired in 260827-ar3, so nothing pins the default now.
    SettingsSection {
        id: lockLayoutSection
        title: "Lock screen"
        icon: "lock"

        readonly property var lockLayoutOptions: [
            { display: "Three columns", value: "caelestia" },
            { display: "Continuity", value: "continuity" },
            { display: "Edge rail", value: "rail" },
            { display: "Split canvas", value: "split" },
            { display: "Quiet focus", value: "focus" }
        ]

        SelectRow {
            label: "Lock screen layout"
            subtext: "Edge rail and split canvas leave the wallpaper sharp; the other three blur what was on screen"
            model: lockLayoutSection.lockLayoutOptions
            currentValue: Prefs.getValue("lock.layout")
            onSelected: (value) => Prefs.setValue("lock.layout", value)
        }
    }

    // ── Screensaver (quick task 260827-b52) ─────────────────────────────
    // Which of the four operator-picked styles the idle screensaver
    // renders, plus "Off". "Off" is a STYLE VALUE, not a separate toggle:
    // `Screensaver.qml` treats it as an inhibit reason and never mounts a
    // surface, which makes this one row both the picker and the kill
    // switch — the same shape the edge bar's own style picker uses.
    //
    // A pick applies at the next idle timeout, not immediately: the
    // surface reads `style` when it mounts, and nothing is mounted while
    // you are sitting in the settings window changing it.
    SettingsSection {
        id: screensaverSection
        title: "Screensaver"
        icon: "screenshot_monitor"

        readonly property var screensaverStyleOptions: [
            { display: "Off", value: "off" },
            { display: "Terminal effects", value: "terminal" },
            { display: "Palette aurora", value: "aurora" },
            { display: "Constellation", value: "constellation" },
            { display: "Edge rail", value: "rail" }
        ]

        SelectRow {
            label: "Screensaver style"
            subtext: "Appears with the screen dim after 5 minutes idle, and clears on any input. Off disables it entirely"
            model: screensaverSection.screensaverStyleOptions
            currentValue: Prefs.getValue("screensaver.style")
            onSelected: (value) => Prefs.setValue("screensaver.style", value)
        }
    }
}
