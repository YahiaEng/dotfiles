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
// borderWidth     15-10 (G-15-1b gap closure): Hyprland's own
//                 `general:border_size`, read live via `hyprctl getoption
//                 general:border_size` (3 on this host). Not a token — it
//                 has no representation in the colour or motion pipelines,
//                 unlike GradientBorder's gradient stops and rotation
//                 period, which ARE tokens — so this is a hand-carried
//                 parity number. Hoisted here (rather than left as
//                 Dashboard.qml's own literal, or duplicated a second time
//                 in PanelDialog.qml) because Phase 15's PanelDialog.qml
//                 now needs the identical value: a per-file literal in
//                 each would be two homes for one parity claim, and this is
//                 the only location both `Dashboard.qml` (`import
//                 "dashboard"`) and `PanelDialog.qml` (`import "../"` plus
//                 same-directory resolution) can already read. If
//                 Hyprland's border_size changes, this is the line to
//                 follow it.
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

    // ── Border width — see the provenance note above (15-10, G-15-1b) ───
    readonly property int borderWidth: 3

    // ── Bar tokens (Phase 18 Plan 01) — provenance: 18-UI-SPEC.md
    //    "## New Tokens". This is the tracer's minimum: only the four
    //    tokens Bar.qml actually reads in this plan. The remaining
    //    UI-SPEC bar tokens (barColumnWidth, hotZoneDepth, popoutDwellMs,
    //    popoutDismissGraceMs, barReHideGraceMs, popoutHeaderHeight,
    //    popoutCornerRadius, popoutMinWidth, popoutMaxWidth,
    //    mediaTitleMaxChars, trayMaxExtent) belong to the later plans that
    //    consume them — the standing rule for this phase is that each plan
    //    appends only the tokens it actually reads, so no plan ships an
    //    unconsumed constant.
    //
    //    barEdgeMargin (6) and barSideMargin (10) are the ONLY two values
    //    in this phase exempt from the repo's 4px grid (spacingXs/Sm/Md/
    //    Lg/Xl above are all multiples of 4). The exemption exists SOLELY
    //    to reproduce config-athena.jsonc's `margin-top` and
    //    `margin-left`/`margin-right` byte-for-byte (6 and 10
    //    respectively), so the QML bar lands positionally identical to
    //    the waybar layout it retires (D-18-38). No future token may cite
    //    this exemption — it is a one-time parity requirement, not a
    //    precedent.
    readonly property int barHeight: 40
    readonly property int barEdgeMargin: 6
    readonly property int barSideMargin: 10
    readonly property int barCapsuleRadius: barHeight / 2

    // ── barColumnWidth (Phase 18 Plan 05) — provenance: 18-UI-SPEC.md
    //    "## New Tokens" + D-18-14 (text-bearing entries re-stack into this
    //    exact column width in vertical orientation). 44 IS on the repo's
    //    4px grid — it does NOT use the two-token grid exemption recorded
    //    above for barEdgeMargin/barSideMargin, which exists solely for
    //    waybar positional parity and is not a precedent for this token.
    readonly property int barColumnWidth: 44

    // ── mediaTitleMaxChars (Phase 18 Plan 08) — provenance: 18-UI-SPEC.md
    //    "## New Tokens". 30 is the EXACT cap the retired bar already
    //    applied to this same track-title string, so 18-19's parity
    //    judgment compares like with like. A character count, not a
    //    spacing value — the repo's 4px-grid discipline does not apply to
    //    it. Appended alone, per 18-05's standing rule for this phase that
    //    each plan appends only the tokens it actually reads;
    //    trayMaxExtent and the popout tokens belong to 18-10/18-13/18-14.
    readonly property int mediaTitleMaxChars: 30

    // ── trayMaxExtent (Phase 18 Plan 10) — provenance: 18-UI-SPEC.md
    //    "## New Tokens" + D-18-04. The maximum extent of the tray
    //    capsule's icon row on its long axis (width horizontal, height
    //    vertical) before the row scrolls internally rather than the
    //    capsule growing further — a safety bound, not a collapse: every
    //    icon stays reachable by scrolling, nothing is folded behind an
    //    expander. 240 IS on the repo's 4px grid and does NOT use the
    //    two-token grid exemption 18-01 recorded for barEdgeMargin/
    //    barSideMargin, which exists solely for waybar positional parity
    //    and is not a precedent for this token. At the fixed 32px cell
    //    pitch (iconSizeMd 24 + spacingXs*2) with 4px (spacingXs) gaps,
    //    six icons measure 212 and render unbounded; seven measure 248 and
    //    are the first count to scroll.
    readonly property int trayMaxExtent: 240

    // ── barScrollStepPercent (Phase 18 Plan 12) — provenance: three
    //    independent sources on this host already agree on 5, so this
    //    token inherits one step vocabulary rather than inventing a
    //    fourth: config-floating.jsonc's pulseaudio module ("scroll-step":
    //    5), its backlight module's own `light -A 5`/`light -U 5` delta,
    //    and this host's hardware media keys via `swayosd-client
    //    --output-volume raise/lower`/`--brightness raise/lower`, whose
    //    own default step is 5. A percentage-point count, not a spacing
    //    value — the repo's 4px-grid discipline does not apply to it.
    //    Appended alone, per 18-05's standing rule that each plan appends
    //    only the tokens it actually reads.
    readonly property int barScrollStepPercent: 5

    // ── Popout tokens (Phase 18 Plan 13, QBAR-09) — provenance:
    //    18-UI-SPEC.md "## Section Popout Frame" + "## Popout Hover
    //    Mechanics". Appended alone, per this phase's standing rule that
    //    each plan appends only the tokens it actually reads.
    //
    //    popoutDwellMs/popoutDismissGraceMs gate WHETHER an animation
    //    starts (D-18-20/D-18-21) — they are not an animation's own
    //    duration or easing, so they live here rather than on the Motion
    //    singleton, and Phase 12's semantic-motion-layer growth policy
    //    stays shut.
    readonly property int popoutDwellMs: 400
    readonly property int popoutDismissGraceMs: 200
    readonly property int popoutHeaderHeight: 48
    readonly property int popoutCornerRadius: 20
    readonly property int popoutMinWidth: 300
    readonly property int popoutMaxWidth: 360
}
