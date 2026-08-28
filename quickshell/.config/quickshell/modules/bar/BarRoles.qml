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
    // failure mode windowrules.lua's own FILE-LEVEL FINDING records, and
    // the quickshell-overview rule reproduces firsthand), so 0.55 was as
    // transparent as this surface could get while
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

    // ── Popout content (quick task 260828-so7) ──────────────────────────
    // The body foreground for popout CONTENT, as opposed to the capsule
    // foregrounds above. One role, one consumer today: UpdatesPopout.qml.
    //
    // WHY IT EXISTS RATHER THAN REUSING notifSurfaceFg, which is the same
    // Colours.onSurface value: that role is notification-scoped by name and
    // by its header above ("the popup card, centre frame and toast all read
    // these three rows"). Borrowing it here would make a popout read as a
    // notification surface to the next person who greps for its consumers,
    // and would tie popout text to any future change made for notifications'
    // sake. Same value today, different reason to change tomorrow.
    //
    // WHY IT IS ONLY ONE ROLE: the other six references UpdatesPopout.qml
    // needed already existed (warn / outlineColour / accent / onAccent /
    // capsuleFg), so this is the single genuine gap. It is deliberately the
    // first role for popout content — WINDOWS.md row 57 records that the
    // nine exempt SectionPopout-family files should eventually migrate onto
    // BarRoles and shrink QSD_BAR_COLOUR_ROLE_EXEMPT; this is the anchor
    // that migration starts from, not a one-off.
    readonly property color popoutFg: Colours.onSurface

    // Extended 2026-08-28 (quick task 260828-t22) to complete the popout
    // family, closing WINDOWS.md row 57 — the nine SectionPopout-family files
    // are no longer exempt from bar-colour-role-routing and now read these.
    //
    // THESE ARE EXACT ALIASES, AND THAT IS THE WHOLE POINT. The obvious move
    // is to point popout backgrounds at `capsule`/`barSurface` above, which
    // are the same palette tokens — but those carry alpha (0.85 / 0.55), so
    // substituting them would have CHANGED how nine surfaces render. The
    // migration's guarantee is that it is a pure re-routing: every one of the
    // 75 references maps to a value-identical role, so no popout can look
    // different by construction. Appearance changes, if wanted, are a separate
    // decision made against a render, not smuggled in under a refactor.
    //
    // They are named for the popout family rather than reusing
    // surfaceColour/surfaceVariantColour above, which are documented there as
    // the internal colour-typed sources for THIS file's alpha blends — not
    // semantic roles for consumers to read.
    //
    // No matching `popoutOutline` exists, deliberately: the one outline
    // reference in the family routes to `outlineColour` above. That alias is
    // in the same "colour-typed source" block, but unlike the two surface
    // aliases its name carries no assumption about which surface it belongs
    // to, so a consumer reading it is not borrowing someone else's semantics.
    // One alias for one value beats a third name for the same colour.
    readonly property color popoutSurface: Colours.surface
    readonly property color popoutSurfaceVariant: Colours.surfaceVariant

    // ── Do-not-disturb deliberately owns NO role pair here (Phase 21
    //    Plan 05, D-21-27-R). A `dndSurface`/`dndSurfaceFg` pair (accent
    //    blended at 0.28, plus onSurface) briefly lived at this spot to
    //    back an ambient whole-capsule tint; the operator reversed that
    //    approach at Plan 05's blocking render gate and DND now reads as a
    //    lit bell glyph instead. A lit glyph needs no blended surface — it
    //    reuses `accent` above, exactly as gamingCell does — so the pair
    //    was removed rather than left dangling. Re-adding a DND surface
    //    role means re-opening D-21-27-R, not just restoring two lines.
}
