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
        { pageIdx: 1, section: "Wallpaper", label: "Wallpaper", keywords: "wallpaper background image video picture" },
        { pageIdx: 1, section: "Wallpaper", label: "The wallpaper drives dynamic theming", keywords: "wallpaper theme dynamic materialyou palette" },
        { pageIdx: 1, section: "Motion", label: "Wallpaper motion", keywords: "wallpaper motion video playing stopped animation" },

        // ── pageIdx 2 — Bar ───────────────────────────────────────────────
        { pageIdx: 2, section: "Bar", label: "Bar orientation", keywords: "bar orientation horizontal vertical dock topbar" },
        { pageIdx: 2, section: "Visibility", label: "Bar visible", keywords: "bar hide show visibility toggle" },
        { pageIdx: 2, section: "Idle behaviour", label: "Idle auto-hide", keywords: "bar idle hide autohide timeout" },
        { pageIdx: 2, section: "Capsules", label: "Launcher", keywords: "bar capsule launcher apps icon" },
        { pageIdx: 2, section: "Capsules", label: "System", keywords: "bar capsule system cpu ram disk gpu" },
        { pageIdx: 2, section: "Capsules", label: "Workspaces", keywords: "bar capsule workspaces indicator" },
        { pageIdx: 2, section: "Capsules", label: "Idle inhibitor", keywords: "bar capsule idle inhibitor bulb" },
        { pageIdx: 2, section: "Capsules", label: "Media & connectivity", keywords: "bar capsule media audio brightness network bluetooth battery" },
        { pageIdx: 2, section: "Capsules", label: "Clock & actions", keywords: "bar capsule clock gaming notifications settings power" },

        // ── pageIdx 3 — Audio ─────────────────────────────────────────────
        { pageIdx: 3, section: "Audio", label: "Audio", keywords: "audio volume sound output mixer" },

        // ── pageIdx 4 — Network ───────────────────────────────────────────
        { pageIdx: 4, section: "Devices", label: "Wi-Fi", keywords: "wifi wi-fi wireless network internet" },
        { pageIdx: 4, section: "Devices", label: "Bluetooth", keywords: "bluetooth pairing devices" },

        // ── pageIdx 5 — Display ───────────────────────────────────────────
        { pageIdx: 5, section: "Display", label: "Resolution & refresh rate", keywords: "resolution refresh rate monitor screen display hz" },
        { pageIdx: 5, section: "Display", label: "Scale", keywords: "scale scaling dpi zoom monitor screen display" },
        { pageIdx: 5, section: "Display", label: "Position", keywords: "position monitor arrangement layout left right above below" },
        { pageIdx: 5, section: "Arrangement", label: "No primary-monitor setting on this build", keywords: "primary monitor arrangement" },
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
        { pageIdx: 7, section: "Decoration", label: "Blur size", keywords: "blur size kernel radius decoration" },
        { pageIdx: 7, section: "Decoration", label: "Blur passes", keywords: "blur passes decoration" },
        { pageIdx: 7, section: "Decoration", label: "Inactive opacity", keywords: "opacity transparency fade inactive unfocused" },
        { pageIdx: 7, section: "Decoration", label: "Shadow", keywords: "shadow drop decoration" },
        { pageIdx: 7, section: "Workspaces", label: "Workspace back-and-forth", keywords: "workspace back and forth switch toggle" },
        { pageIdx: 7, section: "Workspaces", label: "Allow workspace cycles", keywords: "workspace cycle wrap around" },
        { pageIdx: 7, section: "Animation", label: "Animation speed", keywords: "animation speed motion preset shell" },
        { pageIdx: 7, section: "Animation", label: "No separate compositor animation-speed option", keywords: "animation speed motion compositor" },

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
        { pageIdx: 9, section: "Idle & lock", label: "Open in editor", keywords: "idle lock editor advanced session" }
    ]
}
