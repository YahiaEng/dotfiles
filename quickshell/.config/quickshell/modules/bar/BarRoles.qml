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

    // ── Colour-typed sources for the alpha blends ────────────────────────
    // REQUIRED INDIRECTION — do not inline these back into the Qt.rgba
    // calls below. Colours.qml declares every palette role as
    // `property string` (Colours.qml:100-109/131-139), because its
    // JsonAdapter loads them from palette.json's hex strings. A JS string
    // has no .r/.g/.b members, so reading `Colours.surfaceVariant.r`
    // yields `undefined` and `Qt.rgba(undefined, undefined, undefined, a)`
    // silently returns BLACK at alpha `a` — no error, no warning, just a
    // black bar. That is exactly the GATE-02 failure recorded in
    // 18.1-VERIFICATION.md: five of these seventeen roles rendered as
    // opaque black while every automated check passed, because the checks
    // asserted routing (no direct Colours.* reference) and a non-alpha
    // role's type, never that a BLENDED role resolves to a real colour.
    //
    // Assigning a hex string to a `color`-typed property is where QML
    // performs the string->colour conversion, so these five aliases are
    // what make .r/.g/.b real numbers. Same idiom as PanelDialog.qml:168,
    // which blends off a colour-typed property rather than a string.
    readonly property color surfaceColour: Colours.surface
    readonly property color surfaceVariantColour: Colours.surfaceVariant
    readonly property color outlineColour: Colours.outline

    // ── Surfaces — theme.scss:56/58 ──────────────────────────────────────
    // The translucent island surface and its hover state. Built on
    // Colours.surface via alpha(), matching Athena's own @surface-derived
    // bar-surface/bar-surface-hover roles.
    readonly property color barSurface: Qt.rgba(root.surfaceColour.r, root.surfaceColour.g, root.surfaceColour.b, 0.55)
    readonly property color barSurfaceHover: Qt.rgba(root.surfaceColour.r, root.surfaceColour.g, root.surfaceColour.b, 0.78)

    // ── Capsule/drawer roles — theme.scss:110/116/120/125 ────────────────
    // Athena's discrete raised-pill surface, built on Colours.surfaceVariant
    // (the palette's only distinctly-raised neutral token) exactly as
    // theme.scss's own @capsule/@capsule-hover derive from @surface_variant.
    readonly property color capsule: Qt.rgba(root.surfaceVariantColour.r, root.surfaceVariantColour.g, root.surfaceVariantColour.b, 0.85)
    readonly property color capsuleFg: Colours.onSurfaceVariant
    readonly property color capsuleHover: Qt.rgba(root.surfaceVariantColour.r, root.surfaceVariantColour.g, root.surfaceVariantColour.b, 0.95)
    // Slider trough — built on Colours.outline (theme.scss:125's own
    // @capsule-track source), a real palette member.
    readonly property color capsuleTrack: Qt.rgba(root.outlineColour.r, root.outlineColour.g, root.outlineColour.b, 0.5)

    // ── State — theme.scss:93-97 ─────────────────────────────────────────
    // The active workspace, and only the active workspace, plus genuinely-
    // active module states, carry hue.
    readonly property color accent: Colours.primary
    readonly property color onAccent: Colours.onPrimary
    readonly property color warn: Colours.tertiary
    // onWarn (Phase 20 Plan 03, QPOWER-03) — completes the existing `warn`
    // pair rather than opening a new colour family, mirroring the
    // danger/onDanger pairing immediately below. `warn` has existed since
    // Phase 18.1 with no paired foreground colour because nothing needed
    // one until QPOWER-03's warning banner.
    readonly property color onWarn: Colours.onTertiary
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

    // ── Notification surfaces (Phase 19 Plan 01 tracer, D-19-43) — the
    //    popup card, centre frame and toast all read these three rows;
    //    never a direct Colours.* reference from a notification-family
    //    file.
    //
    // GATE-02 gap-closure (round 7, item 4 — "give notifications and the
    // notification centre a glass look"). These were 0.78/0.90, inherited
    // verbatim from PanelDialog.qml's own panelSurfaceOpacity. Both
    // notification surfaces ALREADY sit under the `^quickshell-.*` family
    // blur rule (windowrules.lua) via their `quickshell-notif-popups` /
    // `quickshell-notif-centre` namespaces — so the compositor was already
    // frosting the backdrop; at 0.78 almost none of that frost reached the
    // eye, and the surfaces read as solid panels. The lever is this
    // surface's OWN alpha, exactly as windowrules.lua's own family comment
    // states ("if this reads too strong, the lever is this surface's own
    // alpha ... not another boolean") — no compositor change is made here,
    // so no hyprctl reload/eval is required for this to take effect.
    //
    // ROUND 8 (item 2 — "glass/frosty look is not noticeable enough").
    // Round 7 stopped at 0.55 because that was the floor: the family's own
    // `ignore_alpha = 0.5` means a region composited BELOW that cutoff is
    // not blurred at all and renders as raw unblurred transparency (the
    // failure mode recorded at the ags-media and quickshell-overview
    // rules), so 0.55 was as transparent as this surface could get while
    // staying frosted. Round 8 lifts that constraint at its source:
    // windowrules.lua now declares `ignore_alpha = 0.2` for the three
    // notification namespaces specifically, DECLARED LAST so it beats the
    // family floor it contradicts. That reopens the range below 0.5, and
    // these values move into it — 0.38 resting / 0.52 hover, both clear of
    // the new 0.2 cutoff by a wide margin, so every region of both
    // surfaces still frosts while showing far more of the blurred desktop
    // through it. The ~0.14 resting→hover step is preserved, so a hovered
    // card still reads as lifting toward the viewer.
    //
    // THESE TWO VALUES AND THAT RULE ARE A PAIR. Raising the threshold
    // back toward 0.5, or dropping these alphas below 0.2, silently
    // switches blur off on this surface family rather than erroring —
    // change one, re-check the other.
    readonly property color notifSurface: Qt.rgba(root.surfaceColour.r, root.surfaceColour.g, root.surfaceColour.b, 0.38)
    readonly property color notifSurfaceFg: Colours.onSurface
    readonly property color notifSurfaceHover: Qt.rgba(root.surfaceColour.r, root.surfaceColour.g, root.surfaceColour.b, 0.52)

    // ── Do-not-disturb ambient capsule tint (Phase 21 Plan 05, D-21-27,
    //    21-UI-SPEC.md § DND Capsule Tint) ─────────────────────────────────
    // For as long as NotifServer.dnd is true, ClockActionsCapsule.qml's own
    // root capsule instance overrides its inherited `color:` to this
    // surface, so the WHOLE capsule reads as a mode change rather than a
    // badge on one glyph — the tint is applied there, at the instance
    // level, never inside BarCapsule.qml's own shared expression.
    //
    // Built off `root.accent` (already a `color`-typed property, itself
    // assigned from `Colours.primary` above) rather than a fresh
    // indirection — this file's own REQUIRED INDIRECTION rule (see header)
    // is that no blend may read a `Colours.*` role directly, because
    // Colours.qml's roles are JSON-parsed strings with no .r/.g/.b members
    // and blending one directly silently yields opaque black. `accent` has
    // already performed that string->colour coercion, so reusing it here
    // satisfies the rule with no new property.
    //
    // 0.28 is a recommended starting point (D-21-27), not a locked value —
    // render-gate adjustable roughly between 0.20 and 0.35 without
    // touching the mechanism.
    readonly property color dndSurface: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
    // Deliberately onSurface, NOT onAccent: a 0.28-alpha accent wash over
    // the capsule surface does not reach onPrimary's contrast target, so
    // switching the clock text/glyph tint to onAccent would reduce
    // legibility rather than improve it. The clock and action glyphs keep
    // reading exactly as they do untinted.
    readonly property color dndSurfaceFg: Colours.onSurface
}
