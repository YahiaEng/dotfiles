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
        { pageIdx: 0, section: "Personalization", label: "Icon theme", keywords: "icon theme symbols" },
        { pageIdx: 0, section: "Personalization", label: "Font", keywords: "font typeface text" },

        // ── pageIdx 1 — Wallpaper ─────────────────────────────────────────
        { pageIdx: 1, section: "Wallpaper", label: "Wallpaper", keywords: "wallpaper background image video picture" },

        // ── pageIdx 2 — Bar ───────────────────────────────────────────────
        { pageIdx: 2, section: "Bar", label: "Bar orientation", keywords: "bar orientation horizontal vertical dock topbar" },

        // ── pageIdx 3 — Audio ─────────────────────────────────────────────
        { pageIdx: 3, section: "Audio", label: "Audio", keywords: "audio volume sound output mixer" },

        // ── pageIdx 4 — Network ───────────────────────────────────────────
        { pageIdx: 4, section: "Devices", label: "Wi-Fi", keywords: "wifi wi-fi wireless network internet" },
        { pageIdx: 4, section: "Devices", label: "Bluetooth", keywords: "bluetooth pairing devices" },

        // ── pageIdx 5 — Display ───────────────────────────────────────────
        { pageIdx: 5, section: "Display", label: "Resolution & refresh rate", keywords: "resolution refresh rate monitor screen display hz" },
        { pageIdx: 5, section: "Display", label: "Scale", keywords: "scale scaling dpi zoom monitor screen display" },
        { pageIdx: 5, section: "Advanced", label: "Open nwg-displays", keywords: "monitor arrangement layout editor display advanced" },

        // ── pageIdx 6 — Input ─────────────────────────────────────────────
        { pageIdx: 6, section: "Input", label: "Keyboard layout", keywords: "keyboard layout xkb language" },
        { pageIdx: 6, section: "Input", label: "Follow mouse", keywords: "follow mouse focus input" },
        { pageIdx: 6, section: "Input", label: "Pointer sensitivity", keywords: "mouse sensitivity pointer speed input" },
        { pageIdx: 6, section: "Input", label: "Natural scroll (touchpad)", keywords: "natural scroll touchpad reverse direction input" },

        // ── pageIdx 7 — Window manager ────────────────────────────────────
        { pageIdx: 7, section: "Motion", label: "Motion preset", keywords: "motion animation speed preset shell" },

        // ── pageIdx 8 — Notifications ─────────────────────────────────────
        { pageIdx: 8, section: "Notifications", label: "Do not disturb", keywords: "notifications dnd quiet do not disturb popup" },

        // ── pageIdx 9 — Session ───────────────────────────────────────────
        { pageIdx: 9, section: "Idle & lock", label: "Bar idle-hide", keywords: "idle bar hide auto-hide timeout" },
        { pageIdx: 9, section: "Idle & lock", label: "Screen dim", keywords: "idle dim screen timeout" },
        { pageIdx: 9, section: "Idle & lock", label: "Lock", keywords: "idle lock screen timeout session" },
        { pageIdx: 9, section: "Idle & lock", label: "Screen off", keywords: "idle screen off dpms display timeout" },
        { pageIdx: 9, section: "Idle & lock", label: "Suspend", keywords: "idle suspend sleep timeout power" },
        { pageIdx: 9, section: "Idle & lock", label: "Open in editor", keywords: "idle lock editor advanced session" }
    ]
}
