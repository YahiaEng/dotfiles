// modules/security/Severity.qml — pragma Singleton. The Security
// Center's severity ramp, and the one place allowed to define it.
//
// ── WHY THIS FILE EXISTS ───────────────────────────────────────────────
// `Colours.qml` exposes 19 roles (measured 260827-np1): primary,
// secondary, tertiary, surface, surfaceVariant, background, outline,
// error and their `on*` counterparts. There is no `warning`, no
// `success`, and no ramp. A CVE list needs four steps and a scanner
// verdict needs two more, so severity has to be DERIVED — and derived in
// exactly one place, because a ramp scattered across five call sites
// stops being a ramp the first time someone edits four of them.
//
// ── TWO TRAPS THIS FILE IS SHAPED AROUND ──────────────────────────────
//
// 1. `Colours` roles are `property string`, NOT `property color`.
//    `.r`/`.g`/`.b` are therefore `undefined`, and `Qt.rgba(role.r, …)`
//    renders PURE BLACK at the requested alpha with no warning. That
//    shipped a screensaver drawing 445 points per frame in black on
//    black (quick task 260827-b52, finding 1). Every derivation below
//    goes through `Qt.alpha()` / `Qt.tint()` / `Qt.darker()`, which
//    accept a colour-coercible string, and NEVER through channel access.
//
// 2. `colour-lint` CHECK A resolves every `Colours.<name>` against the
//    names actually parsed out of Colours.qml, and the gate is
//    deny-by-default on literal hex. So this file contains no hex at
//    all: the ramp is built only from role names that exist. That is a
//    structural pass, not an exemption — this module deliberately does
//    NOT appear in colour-lint's exemption tables.
//
// ── THE RAMP, AND WHY THESE ROLES ─────────────────────────────────────
// On dracula, `surfaceVariant`, `primaryContainer` and
// `secondaryContainer` are byte-identical (#44475a measured). There is
// exactly ONE container tint above surface, so severity CANNOT be
// carried by a tinted card back — two adjacent severities would render
// as the same slab. Severity therefore reads from the FOREGROUND plus a
// thin rim, and `back()` below is deliberately a low-alpha wash of the
// foreground rather than a named container role.
pragma Singleton
import QtQuick
import Quickshell
import ".."

Singleton {
    id: root

    // Ordered worst-first. `rank` is what the findings feed sorts on, so
    // it is the single source of ordering truth — a caller must never
    // hand-roll a comparator over these names.
    readonly property int rankCritical: 0
    readonly property int rankHigh: 1
    readonly property int rankMedium: 2
    readonly property int rankLow: 3
    readonly property int rankScanning: 4
    readonly property int rankAbsent: 5
    readonly property int rankOk: 6

    // ── Foreground colours ────────────────────────────────────────────
    // critical  — the palette's own error role, unmodified. The one
    //             severity that gets a named role to itself.
    // high      — error pulled toward primary, so it reads as adjacent
    //             to critical without being mistaken for it.
    // medium    — secondary. Distinct hue, mid weight.
    // low       — tertiary. The coolest, least urgent accent available.
    // scanning  — tertiary as well, but callers pair it with motion
    //             rather than a different hue; a scan in progress is a
    //             state, not a severity, and inventing a seventh colour
    //             for it would dilute the ramp.
    // absent    — outline. Deliberately the dimmest thing on the
    //             surface: "not installed" must never out-shout a real
    //             finding.
    // ok        — tertiary tinted toward the surface's own foreground so
    //             it reads as calm rather than as a sixth alert colour.
    readonly property color critical: Colours.error
    readonly property color high: Qt.tint(Colours.error, Qt.alpha(Colours.primary, 0.38))
    readonly property color medium: Colours.secondary
    readonly property color low: Colours.tertiary
    readonly property color scanning: Colours.tertiary
    readonly property color absent: Colours.outline
    readonly property color ok: Qt.tint(Colours.tertiary, Qt.alpha(Colours.onSurface, 0.22))

    // ── Lookup by rank ────────────────────────────────────────────────
    // A plain switch, not an array indexed by rank: an array would go
    // `undefined` on an out-of-range rank and paint transparent, which is
    // the invisible-widget failure this repo has now hit three times.
    // `absent` is the fallback because an unknown severity is exactly as
    // trustworthy as an unscanned one.
    function fg(rank) {
        switch (rank) {
        case root.rankCritical:
            return root.critical;
        case root.rankHigh:
            return root.high;
        case root.rankMedium:
            return root.medium;
        case root.rankLow:
            return root.low;
        case root.rankScanning:
            return root.scanning;
        case root.rankOk:
            return root.ok;
        default:
            return root.absent;
        }
    }

    // Wash behind a severity glyph or pill. Low alpha over the SAME hue
    // as the foreground — see the header on why a container role cannot
    // do this job here.
    function back(rank) {
        return Qt.alpha(root.fg(rank), 0.18);
    }

    // Rim for a card that needs to announce its severity at the edge.
    // Slightly stronger than `back()` so a 1px border still reads at a
    // glance without becoming a second fill.
    function rim(rank) {
        return Qt.alpha(root.fg(rank), 0.42);
    }

    // Text ON a `back()` wash. The wash is transparent, so the text sits
    // against the card underneath it — meaning the foreground colour is
    // already correct and this exists purely so call sites read
    // symmetrically with fg/back/rim rather than mixing idioms.
    function onBack(rank) {
        return root.fg(rank);
    }

    function label(rank) {
        switch (rank) {
        case root.rankCritical:
            return "Critical";
        case root.rankHigh:
            return "High";
        case root.rankMedium:
            return "Medium";
        case root.rankLow:
            return "Low";
        case root.rankScanning:
            return "Scanning";
        case root.rankOk:
            return "Healthy";
        default:
            return "Not scanned";
        }
    }

    // Material Symbols glyph per rank — the icon font the rest of the
    // shell already uses (`Design.symbolFontFamily`).
    function glyph(rank) {
        switch (rank) {
        case root.rankCritical:
            return "gpp_maybe";
        case root.rankHigh:
            return "warning";
        case root.rankMedium:
            return "info";
        case root.rankLow:
            return "info";
        case root.rankScanning:
            return "progress_activity";
        case root.rankOk:
            return "verified_user";
        default:
            return "help";
        }
    }
}
