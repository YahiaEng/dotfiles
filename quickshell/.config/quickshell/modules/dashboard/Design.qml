// Design.qml — the drawer's shared design constants (Phase 14 Plan 09).
//
// Four plans (14-03 through 14-08) each recorded the same deferral: the
// spacing and type constants below are declared identically in five or six
// sibling files, and no shared mechanism existed to hang them on. 14-08's
// stated rationale was that "a QML id is lexically scoped to its declaring
// file, and every tab type here is a separate registered component" — true
// of an id, but not of a singleton. `Colours` and `Motion` already cross
// exactly this boundary from modules/qmldir, so the mechanism did exist;
// this file is it, one directory down.
//
// ── The 12-06 finding, restated because it is easy to get half-right ────
// A singleton needs BOTH the `pragma Singleton` below AND the `singleton`
// keyword on its qmldir line. With only the pragma, the manifest hands back
// a type that is never constructed and every name on it reads `undefined`
// forever — silently, with no load error. Both are present; the pair was
// verified live by summoning the drawer and confirming its frame geometry
// was byte-identical to the pre-consolidation measurement, which it could
// not be if these resolved to undefined.
//
// ── Provenance — every value below is sourced from the contract, not from
//    whichever sibling file happened to be read first ─────────────────────
// spacing*        14-UI-SPEC.md "## Spacing Scale" (xs/sm/md/lg/xl rows)
// panelPadding    14-UI-SPEC.md's lg row — "Panel padding (D-06's ~24px
//                 panel padding)". Kept as its own name rather than folded
//                 into spacingLg: the two names mean different things at
//                 their call sites and this consolidation is a pure
//                 value-for-value substitution, not a renaming pass.
// font*/weight*   14-UI-SPEC.md "## Typography" (Display/Heading/Body/Label
//                 rows, sizes and weights both)
// symbolFontFamily 14-02's recorded family string for the Material Symbols
//                 Rounded variable font it installed behind the AUR
//                 legitimacy checkpoint (D-28).
// iconSizeMd      THE ONE EXCEPTION, recorded rather than hidden:
//                 14-UI-SPEC.md declares no icon-size row — it names the
//                 icon library only. 24 is what all six sibling files
//                 independently agreed on and is MD3's standard 24dp icon
//                 size. Its provenance is unanimous sibling agreement, not
//                 a contract row, and the SUMMARY says so.
//
// Deliberately NOT consolidated, though its name and value agree across two
// files: `fillAxisAvailable`. It is a per-file capability flag about what
// the font build supports, not a design token with a contract row behind
// it, and hoisting it would change what it means.
//
// ── 14-09 Task 4 addition: `tooltipDelayMs` ──────────────────────────────
// `QuickToggles.qml` carried `ToolTip.delay: 400` as a bare literal at two
// call sites, found at the Task 4 render-gate change request while adding
// a third tooltip site to `WeatherTab.qml`. This is a fourth blind-spot
// class motion-lint's CHECK B cannot see: `delay:` is a duration-shaped
// property name exactly like `duration:`/`interval:`, but CHECK B's regex
// is anchored on the literal string `duration` — see 14-09-SUMMARY.md's
// Task 4 section for the verdict on whether the two pre-existing
// `QuickToggles.qml` sites were in Task 2's original hand enumeration.
// Named here (not left local to one file) because both `QuickToggles.qml`
// and `WeatherTab.qml` need the identical value — pure name extraction, the
// value (400) is unchanged from what both sites already used.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // ── Spacing scale — 14-UI-SPEC.md, multiples of 4, D-06's 8dp grid ──
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 16
    readonly property int spacingLg: 24
    readonly property int spacingXl: 32
    readonly property int panelPadding: 24

    // ── Icon sizing — see the provenance note above ─────────────────────
    readonly property int iconSizeMd: 24

    // ── Typography — 14-UI-SPEC.md "## Typography" ──────────────────────
    readonly property int fontDisplay: 32
    readonly property int fontHeading: 20
    readonly property int fontBody: 16
    readonly property int fontLabel: 12

    readonly property int weightDisplay: Font.Medium
    readonly property int weightEmphasis: Font.DemiBold
    readonly property int weightBody: Font.Normal

    readonly property string symbolFontFamily: "Material Symbols Rounded"

    // ── Tooltip delay — see the header note above for provenance ────────
    readonly property int tooltipDelayMs: 400
}
