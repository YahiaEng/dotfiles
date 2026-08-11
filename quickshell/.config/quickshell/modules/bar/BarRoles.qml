// BarRoles.qml — the bar-scoped colour role layer (Phase 18.1 Plan 01,
// D-03/D-04/D-05). Every colour a bar capsule needs is exposed here as one
// of seventeen named roles, each resolving through Colours.qml's live
// Material You singleton — never a hex literal, never a second colour
// pipeline. This is the ONLY colour source for modules/bar/: the
// matugen-dynamic and static-preset pipelines both keep working by
// construction, because both write through the same palette.json Colours
// already reads.
//
// pragma Singleton + qmldir's `singleton` keyword ARE both required
// (12-06's finding, restated in this qmldir's own header for
// BarEntryModel/PopoutController/BarReveal): with only one of the two,
// `BarRoles.accent`-style bare-type-name access resolves to `undefined`
// FOREVER, with no load error. Verification for this plan therefore
// asserts a resolved colour value, never merely the absence of an error.
//
// Alpha idiom: the five rows below that need a non-1.0 alpha channel a
// role's r/g/b components plus a literal alpha through the repo's own
// proven blend call — not a new helper (PanelDialog.qml:168,
// Dashboard.qml:367, Overview.qml:974). The five alpha literals are
// written as the exact literal decimals Athena's theme.scss uses —
// 0.55, 0.78, 0.85, 0.95, 0.5 — passed directly with no intermediate
// arithmetic, so the value can never drift by a rounding error (QBAR-01
// precision edge).
pragma Singleton
import QtQuick
import Quickshell
import "../"

Singleton {
    id: root

    // ── Surfaces — theme.scss:56/58 ──────────────────────────────────────
    // The translucent island surface and its hover state. Built on
    // Colours.surface via alpha(), matching Athena's own @surface-derived
    // bar-surface/bar-surface-hover roles.
    readonly property color barSurface: Qt.rgba(Colours.surface.r, Colours.surface.g, Colours.surface.b, 0.55)
    readonly property color barSurfaceHover: Qt.rgba(Colours.surface.r, Colours.surface.g, Colours.surface.b, 0.78)

    // ── Capsule/drawer roles — theme.scss:110/116/120/125 ────────────────
    // Athena's discrete raised-pill surface, built on Colours.surfaceVariant
    // (the palette's only distinctly-raised neutral token) exactly as
    // theme.scss's own @capsule/@capsule-hover derive from @surface_variant.
    readonly property color capsule: Qt.rgba(Colours.surfaceVariant.r, Colours.surfaceVariant.g, Colours.surfaceVariant.b, 0.85)
    readonly property color capsuleFg: Colours.onSurfaceVariant
    readonly property color capsuleHover: Qt.rgba(Colours.surfaceVariant.r, Colours.surfaceVariant.g, Colours.surfaceVariant.b, 0.95)
    // Slider trough — built on Colours.outline (theme.scss:125's own
    // @capsule-track source), a real palette member.
    readonly property color capsuleTrack: Qt.rgba(Colours.outline.r, Colours.outline.g, Colours.outline.b, 0.5)

    // ── State — theme.scss:93-97 ─────────────────────────────────────────
    // The active workspace, and only the active workspace, plus genuinely-
    // active module states, carry hue.
    readonly property color accent: Colours.primary
    readonly property color onAccent: Colours.onPrimary
    readonly property color warn: Colours.tertiary
    readonly property color danger: Colours.error
    readonly property color onDanger: Colours.onError

    // ── Filled-pill accent hues — theme.scss:140-145 ─────────────────────
    // Only three pills ever carry a solid colour fill: clock, updates
    // alert, notification alert. Three distinct hues so the filled trio
    // never repeats a colour side by side.
    readonly property color fillClock: Colours.secondary
    readonly property color fillClockFg: Colours.onSecondary
    readonly property color fillUpdates: Colours.tertiary
    readonly property color fillUpdatesFg: Colours.onTertiary
    readonly property color fillNotification: Colours.primary
    readonly property color fillNotificationFg: Colours.onPrimary
}
