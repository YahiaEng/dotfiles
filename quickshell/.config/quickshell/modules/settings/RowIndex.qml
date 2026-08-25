// modules/settings/RowIndex.qml — the declarative per-row search index
// (quick-260821-6z1 Task 3, D-06/F-01/R-4). Live-instance search is
// structurally impossible here: `Pages.qml:_swapTo()` destroys the
// previous page before incubating the next, so exactly one page object
// exists at a time — instantiating all ten pages to build an index would
// start ten pages' worth of live Process/FileView children at once. This
// is a SEPARATE singleton from PageRegistry (not a `searchTerms` field
// folded into `pages[]`): PageRegistry is per-PAGE and index-locked to
// PageCompRegistry, and folding a ~75-entry array into a 10-entry
// index-locked list would make that one invariant harder to see. A third
// singleton with a `pageIdx` foreign key leaves it untouched.
//
// `label` is the row's own `label:` string, BYTE-FOR-BYTE — that is the
// jump key `Pages.qml`'s `pendingRowLabel` matching uses. `settings-
// index-check` (hypr/.config/hypr/scripts/settings-index-check) enforces
// that every row declared in a page file has a matching entry here, and
// that every entry's label appears verbatim in its mapped page — every
// task that adds a row adds its RowIndex entry in the SAME commit, or the
// gate fails.
//
// ── Sub-page fields (quick task 260825-wj2 Task 1, D-4/D-5) — two OPTIONAL
//    fields, both absent on every entry below this header (all 113
//    pre-existing rows stay byte-identical):
//      - `subPageIdx` — which level of the page this row lives on. Absent
//        means 0, the root page. A row on a StackPage-wrapped page's
//        sub-page N carries `subPageIdx: N`. The canonical row TEXT
//        (settings-index-check's own grep key) is therefore
//        `{ pageIdx: N, section: …` for a root row and
//        `{ pageIdx: N, subPageIdx: S, section: …` for a sub-page row —
//        those exact strings, verbatim, since CHECK A/B grep them.
//      - `jumpSubPageIdx` — the deepest sub-page level search can actually
//        OPEN this row on without a prior user selection. Defaults to
//        `subPageIdx` when absent. Diverges from `subPageIdx` only for a
//        selection-dependent sub-page (e.g. App info, which needs
//        `sState.selectedApp` already set) — that row's `subPageIdx`
//        stays the level it truly lives on (what CHECK A/B grep against),
//        while `jumpSubPageIdx` names the shallower level
//        `selectSearchResult()` actually jumps to.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property list<var> rows: [
        // ── pageIdx 0 — Appearance ───────────────────────────────────────
        { pageIdx: 0, section: "Theme", label: "Theme", keywords: "theme palette colour color scheme dracula matugen" },
        { pageIdx: 0, section: "Theme", label: "What Theme actually re-themes", keywords: "theme scope border terminal gtk" },
        { pageIdx: 0, section: "Personalization", label: "Icon theme", keywords: "icon theme symbols" },
        { pageIdx: 0, section: "Personalization", label: "Font", keywords: "font typeface text" },
        { pageIdx: 0, section: "Personalization", label: "Fastfetch logo", keywords: "logo ascii fastfetch greeter sprite" },

        // ── pageIdx 1 — Wallpaper ─────────────────────────────────────────
        { pageIdx: 1, section: "Wallpaper", label: "Filter by folder", keywords: "wallpaper folder filter theme grid all" },
        { pageIdx: 1, section: "Wallpaper", label: "The wallpaper drives dynamic theming", keywords: "wallpaper theme dynamic materialyou palette" },
        { pageIdx: 1, section: "Motion", label: "Wallpaper motion", keywords: "wallpaper motion video playing stopped animation" },

        // ── pageIdx 2 — Bar ───────────────────────────────────────────────
        { pageIdx: 2, section: "Bar", label: "Bar orientation", keywords: "bar orientation horizontal vertical dock topbar" },
        { pageIdx: 2, section: "Visibility", label: "Bar visible", keywords: "bar hide show visibility toggle" },
        { pageIdx: 2, section: "Idle behaviour", label: "Idle auto-hide", keywords: "bar idle hide autohide timeout" },
        // Edge bar style picker (quick task 260823-9ak added the row,
        // quick task 260824-ns3 Task 1 closes the pre-existing
        // settings-index-check CHECK A gap by adding both entries here,
        // Task 7 widens the keywords to the shapes themselves).
        //
        // Both labels are BYTE-FOR-BYTE the row's own `label:` string in
        // BarPage.qml — that string is the jump key, so any wording change
        // there has to land here in the same commit.
        //
        // The "Animate the bulge" row is HIDDEN on Brackets but its
        // declaration never leaves the page, so this entry stays valid on
        // every style; search still finds it and jumping to it on Brackets
        // simply lands on the section.
        { pageIdx: 2, section: "Edge bar", label: "Edge bar style", keywords: "edge bar style continuous brackets segmented halo off picker frame rail outline corner workspace shape" },
        { pageIdx: 2, section: "Edge bar", label: "Animate the bulge", keywords: "edge bar bulge animate swell hover landmark permanent static continuous segmented halo off" },
        { pageIdx: 2, section: "Capsules", label: "Launcher", keywords: "bar capsule launcher apps icon" },
        { pageIdx: 2, section: "Capsules", label: "CPU", keywords: "bar entry cpu readout system" },
        { pageIdx: 2, section: "Capsules", label: "RAM", keywords: "bar entry ram memory readout system" },
        { pageIdx: 2, section: "Capsules", label: "Disk", keywords: "bar entry disk storage readout system" },
        { pageIdx: 2, section: "Capsules", label: "GPU", keywords: "bar entry gpu readout system" },
        { pageIdx: 2, section: "Capsules", label: "Updates", keywords: "bar entry updates pending readout system" },
        { pageIdx: 2, section: "Capsules", label: "Workspaces", keywords: "bar capsule workspaces indicator" },
        { pageIdx: 2, section: "Capsules", label: "Idle inhibitor", keywords: "bar capsule idle inhibitor bulb" },
        { pageIdx: 2, section: "Capsules", label: "Media", keywords: "bar entry media nowplaying mpris player song track" },
        { pageIdx: 2, section: "Capsules", label: "Audio", keywords: "bar entry audio volume sound mixer speaker mute" },
        { pageIdx: 2, section: "Capsules", label: "Brightness", keywords: "bar entry brightness backlight screen display" },
        { pageIdx: 2, section: "Capsules", label: "Network", keywords: "bar entry network wifi wireless ethernet wired connection" },
        { pageIdx: 2, section: "Capsules", label: "Bluetooth", keywords: "bar entry bluetooth bt device pairing" },
        { pageIdx: 2, section: "Capsules", label: "Battery", keywords: "bar entry battery power charge percentage" },
        // System tray + Icon tint (quick task 260823-65s) — the System
        // tray row itself was added to BarPage.qml in this same task's
        // Task 1 but missed its RowIndex entry then (settings-index-check
        // is not wired into quickshell-doctor, so nothing caught it until
        // this later pass ran it directly — recorded honestly in the
        // SUMMARY rather than left silently fixed).
        { pageIdx: 2, section: "Capsules", label: "System tray", keywords: "bar capsule tray systemtray statusnotifieritem sni steam discord" },
        { pageIdx: 2, section: "Capsules", label: "Tray icon tint", keywords: "bar tray icon tint colour color tinted desaturate theme" },
        { pageIdx: 2, section: "Capsules", label: "Clock", keywords: "bar entry clock popout" },
        { pageIdx: 2, section: "Capsules", label: "Gaming mode", keywords: "bar entry gaming mode toggle" },
        { pageIdx: 2, section: "Capsules", label: "Notifications", keywords: "bar entry notifications bell centre" },
        { pageIdx: 2, section: "Capsules", label: "Settings", keywords: "bar entry settings gear strip" },
        { pageIdx: 2, section: "Capsules", label: "Power", keywords: "bar entry power menu glyph" },

        // ── pageIdx 3 — Audio ─────────────────────────────────────────────
        { pageIdx: 3, section: "Output", label: "Master volume", keywords: "audio volume sound output speaker" },
        { pageIdx: 3, section: "Output", label: "Mute", keywords: "audio mute output speaker sound" },
        { pageIdx: 3, section: "Output", label: "Output device", keywords: "audio output device speaker headphone" },
        { pageIdx: 3, section: "Output", label: "Output device switch failed", keywords: "audio output device error failed" },
        { pageIdx: 3, section: "Input", label: "Input device", keywords: "audio input mic microphone device" },
        { pageIdx: 3, section: "Input", label: "Input level", keywords: "audio input mic microphone volume level" },
        { pageIdx: 3, section: "Input", label: "Mic mute", keywords: "audio input mic microphone mute" },
        { pageIdx: 3, section: "Input", label: "Input device switch failed", keywords: "audio input device error failed" },
        { pageIdx: 3, section: "Per-app mixer", label: "Per-app volume", keywords: "audio app mixer stream volume" },
        { pageIdx: 3, section: "Per-app mixer", label: "Nothing playing", keywords: "audio app mixer stream empty" },
        { pageIdx: 3, section: "Per-app mixer", label: "Full mixer", keywords: "audio mixer panel full app" },

        // ── pageIdx 4 — Network (quick-260821-6z1 fix wave: "make wifi
        //    and bluetooth options open inline" — the NavRows became
        //    real inline controls, same labels retained). ────────────────
        { pageIdx: 4, section: "Wi-Fi", label: "Wi-Fi", keywords: "wifi wi-fi wireless network internet toggle radio" },
        { pageIdx: 4, section: "Wi-Fi", label: "Wi-Fi hardware is off", keywords: "wifi radio blocked airplane mode hardware switch" },
        { pageIdx: 4, section: "Wi-Fi", label: "Turn on Wi-Fi to see nearby networks", keywords: "wifi off networks list" },
        { pageIdx: 4, section: "Wi-Fi", label: "Advanced network settings", keywords: "wifi hidden network enterprise 802.1x nm-connection-editor advanced" },
        { pageIdx: 4, section: "Bluetooth", label: "Bluetooth", keywords: "bluetooth pairing devices toggle radio" },
        { pageIdx: 4, section: "Bluetooth", label: "No Bluetooth adapter found", keywords: "bluetooth adapter missing controller" },
        { pageIdx: 4, section: "Bluetooth", label: "Bluetooth is blocked", keywords: "bluetooth rfkill blocked hardware switch" },
        { pageIdx: 4, section: "Bluetooth", label: "Turn on Bluetooth to manage devices", keywords: "bluetooth off devices paired" },
        { pageIdx: 4, section: "Bluetooth", label: "Advanced Bluetooth settings", keywords: "bluetooth blueman-manager advanced" },

        // ── pageIdx 5 — Display ───────────────────────────────────────────
        { pageIdx: 5, section: "Display", label: "Resolution & refresh rate", keywords: "resolution refresh rate monitor screen display hz" },
        { pageIdx: 5, section: "Display", label: "Scale", keywords: "scale scaling dpi zoom monitor screen display" },
        { pageIdx: 5, section: "Display", label: "Position", keywords: "position monitor arrangement layout left right above below" },
        { pageIdx: 5, section: "Arrangement", label: "No primary monitor setting", keywords: "primary monitor arrangement" },
        { pageIdx: 5, section: "Advanced", label: "Open nwg-displays", keywords: "monitor arrangement layout editor display advanced" },

        // ── pageIdx 6 — Input ─────────────────────────────────────────────
        { pageIdx: 6, section: "Input", label: "Keyboard layout", keywords: "keyboard layout xkb language" },
        { pageIdx: 6, section: "Input", label: "Follow mouse", keywords: "follow mouse focus input" },
        { pageIdx: 6, section: "Input", label: "Pointer sensitivity", keywords: "mouse sensitivity pointer speed input" },
        { pageIdx: 6, section: "Input", label: "Natural scroll (touchpad)", keywords: "natural scroll touchpad reverse direction input" },
        { pageIdx: 6, section: "Input", label: "No per-device sensitivity setting", keywords: "sensitivity per-device device mouse pointer" },
        { pageIdx: 6, section: "Per-device", label: "Show all devices", keywords: "device keyboard mouse show all filter" },
        { pageIdx: 6, section: "Per-device", label: "Per-device keyboard layout", keywords: "keyboard layout device secondary" },
        { pageIdx: 6, section: "Per-device", label: "Per-device pointer scroll factor", keywords: "scroll factor mouse pointer device" },

        // ── pageIdx 7 — Window manager (quick-260821-6z1 Task 5) ────────────
        { pageIdx: 7, section: "Layout", label: "Gaps in", keywords: "gap spacing margin gaps in window" },
        { pageIdx: 7, section: "Layout", label: "Gaps out", keywords: "gap spacing margin gaps out screen edge" },
        { pageIdx: 7, section: "Layout", label: "Gaps between workspaces", keywords: "gap spacing workspace swipe" },
        { pageIdx: 7, section: "Borders", label: "Border size", keywords: "border size thickness outline" },
        { pageIdx: 7, section: "Borders", label: "Border colour", keywords: "border colour color outline theme" },
        { pageIdx: 7, section: "Decoration", label: "Rounding", keywords: "round corner radius decoration" },
        { pageIdx: 7, section: "Decoration", label: "Blur", keywords: "blur frost glass decoration" },
        { pageIdx: 7, section: "Decoration", label: "Frost shell surfaces", keywords: "frost frosted glass blur bar drawer notification osd layer rule translucent transparent" },
        { pageIdx: 7, section: "Decoration", label: "Blur size", keywords: "blur size kernel radius decoration" },
        { pageIdx: 7, section: "Decoration", label: "Blur passes", keywords: "blur passes decoration" },
        { pageIdx: 7, section: "Decoration", label: "Inactive opacity", keywords: "opacity transparency fade inactive unfocused" },
        { pageIdx: 7, section: "Decoration", label: "Shadow", keywords: "shadow drop decoration" },
        { pageIdx: 7, section: "Workspaces", label: "Workspace back-and-forth", keywords: "workspace back and forth switch toggle" },
        { pageIdx: 7, section: "Workspaces", label: "Allow workspace cycles", keywords: "workspace cycle wrap around" },
        { pageIdx: 7, section: "Animation", label: "Animation style", keywords: "animation style motion preset shell md3 smooth snappy bouncy wavy zen caelestia" },
        { pageIdx: 7, section: "Animation", label: "Reduce motion", keywords: "animation reduce motion accessibility off reduced full" },

        // ── pageIdx 8 — Notifications ─────────────────────────────────────
        { pageIdx: 8, section: "Notifications", label: "Do not disturb", keywords: "notifications dnd quiet do not disturb popup" },
        { pageIdx: 8, section: "Popups", label: "Popup timeout", keywords: "notification popup toast timeout dismiss duration" },
        { pageIdx: 8, section: "Popups", label: "Low-priority timeout", keywords: "notification popup toast timeout dismiss low priority" },
        { pageIdx: 8, section: "Popups", label: "Critical notifications never auto-dismiss", keywords: "critical urgency notification timeout" },
        { pageIdx: 8, section: "Popups", label: "Popup position", keywords: "notification popup toast position corner" },
        { pageIdx: 8, section: "Popups", label: "History limit", keywords: "notification history limit cap" },
        { pageIdx: 8, section: "Popups", label: "Max visible popups", keywords: "notification popup visible count max" },
        { pageIdx: 8, section: "On-screen display", label: "OSD duration", keywords: "osd indicator volume brightness duration timeout" },
        { pageIdx: 8, section: "On-screen display", label: "OSD position", keywords: "osd indicator volume brightness position edge" },
        { pageIdx: 8, section: "Dashboard panels", label: "Clock", keywords: "dashboard panel clock date hero" },
        { pageIdx: 8, section: "Dashboard panels", label: "Calendar", keywords: "dashboard panel calendar month grid" },
        { pageIdx: 8, section: "Dashboard panels", label: "Media", keywords: "dashboard panel media now playing" },
        { pageIdx: 8, section: "Dashboard panels", label: "Resources", keywords: "dashboard panel resources cpu memory storage battery" },
        { pageIdx: 8, section: "Content sources", label: "Weather location", keywords: "weather source location city forecast" },
        { pageIdx: 8, section: "Content sources", label: "News sources", keywords: "news source feed rss" },

        // ── pageIdx 9 — Session ───────────────────────────────────────────
        { pageIdx: 9, section: "Idle & lock", label: "Bar idle-hide", keywords: "idle bar hide auto-hide timeout" },
        { pageIdx: 9, section: "Idle & lock", label: "Screen dim", keywords: "idle dim screen timeout" },
        { pageIdx: 9, section: "Idle & lock", label: "Lock", keywords: "idle lock screen timeout session" },
        { pageIdx: 9, section: "Idle & lock", label: "Screen off", keywords: "idle screen off dpms display timeout" },
        { pageIdx: 9, section: "Idle & lock", label: "Suspend", keywords: "idle suspend sleep timeout power" },
        { pageIdx: 9, section: "Idle & lock", label: "Open in editor", keywords: "idle lock editor advanced session" },
        { pageIdx: 9, section: "Gaming", label: "Gaming mode", keywords: "gaming performance mode idle notifications" },
        { pageIdx: 9, section: "Screen recording", label: "Recording fps", keywords: "record capture screencast fps frame rate" },
        { pageIdx: 9, section: "Screen recording", label: "Recording codec", keywords: "record capture screencast codec video h264 hevc av1" },
        { pageIdx: 9, section: "Screen recording", label: "Recording audio", keywords: "record capture screencast audio mic desktop silent" },
        { pageIdx: 9, section: "Screen recording", label: "Recording status", keywords: "record capture screencast status idle recording" },
        { pageIdx: 9, section: "Power menu", label: "Warn when busy", keywords: "power shutdown reboot logout warn busy package manager" },
        { pageIdx: 9, section: "Power menu", label: "Default focused action", keywords: "power shutdown reboot logout default focus" },
        { pageIdx: 9, section: "Services", label: "Shell service", keywords: "service daemon autostart quickshell status" },
        { pageIdx: 9, section: "Services", label: "Bar watchdog", keywords: "service daemon autostart watchdog bar status" },

        // ── pageIdx 10 — Apps (quick task 260825-wj2 Task 2, D-2/D-5) ────
        { pageIdx: 10, section: "Default applications", label: "Terminal", keywords: "apps default terminal kitty command" },
        { pageIdx: 10, section: "Default applications", label: "Audio", keywords: "apps default audio mixer pavucontrol command" },
        { pageIdx: 10, section: "Default applications", label: "Media playback", keywords: "apps default media player playback" },
        { pageIdx: 10, section: "Default applications", label: "File manager", keywords: "apps default file manager explorer xdg-open" },
        { pageIdx: 10, section: "Library", label: "All apps", keywords: "apps library browse favourite hidden list" },
        // Sub-page 1 — All apps (D-5): the "App" label is STATIC (see
        // AllAppsPage.qml's own header) — this is the row's jump key, not
        // any one app's name.
        { pageIdx: 10, subPageIdx: 1, section: "Installed apps", label: "App", keywords: "apps all installed favourite hidden browse" },
        { pageIdx: 10, subPageIdx: 1, section: "Installed apps", label: "No apps found", keywords: "apps all installed empty" },
        // Sub-page 2 — App info: selection-dependent, so search actually
        // lands on All apps (subPageIdx 1) where a user picks one first —
        // `jumpSubPageIdx: 1` names that, while `subPageIdx: 2` stays the
        // level these rows truly live on (what CHECK A/B grep against).
        { pageIdx: 10, subPageIdx: 2, section: "Launcher", label: "Favourite", keywords: "apps info favourite pin launcher", jumpSubPageIdx: 1 },
        { pageIdx: 10, subPageIdx: 2, section: "Launcher", label: "Hidden", keywords: "apps info hidden hide launcher", jumpSubPageIdx: 1 },
        { pageIdx: 10, subPageIdx: 2, section: "Details", label: "App ID", keywords: "apps info id desktop entry", jumpSubPageIdx: 1 },
        { pageIdx: 10, subPageIdx: 2, section: "Details", label: "Command", keywords: "apps info command exec", jumpSubPageIdx: 1 }
    ]
}
