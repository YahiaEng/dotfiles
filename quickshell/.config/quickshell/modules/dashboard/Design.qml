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
    // ── Font FAMILY is deliberately NOT a token here (decided 2026-08-14)
    //    Every Text in this shell inherits Qt's default family, which since
    //    the round-10 icon fix (`QT_QPA_PLATFORMTHEME=gtk3` in uwsm/env)
    //    resolves to the GTK font from gsettings. That is the CHOSEN
    //    behaviour, confirmed by the user when the side effect was surfaced:
    //    it makes this repo's own `font-switcher.sh` re-font the bar,
    //    notifications and centre in the same stroke it re-fonts GTK apps,
    //    which is the project's core value ("one switch re-themes the entire
    //    desktop") applied to typography.
    //
    //    So: do NOT add a `fontFamily` token here to "fix" the shell looking
    //    different after a font switch — that is the feature. Pinning a
    //    family would decouple the shell from font-switcher.sh and silently
    //    reintroduce the split this decision closed. Sizes stay tokenised
    //    below; only the family is delegated.
    readonly property int fontHeading: 20
    readonly property int fontBody: 16
    readonly property int fontLabel: 12

    readonly property int weightDisplay: Font.Medium
    readonly property int weightEmphasis: Font.DemiBold
    // Athena sets `font-weight: bold` on #clock and #custom-updates — CSS bold
    // is 700, i.e. Font.Bold, not DemiBold (600). Named here rather than left
    // as a raw numeric at the call site: ClockActionsCapsule previously
    // recorded that no bold token existed and settled for weightBody
    // (Normal), which is why the operator reported the clock font as lighter
    // than Athena's. Minting the token is the honest fix.
    readonly property int weightBold: Font.Bold
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
    //    the retired bar's layout it replaces (D-18-38, RETIRE-02/18-20).
    //    No future token may cite this exemption — it is a one-time
    //    parity requirement, not a precedent.
    readonly property int barHeight: 42
    readonly property int barEdgeMargin: 6
    readonly property int barSideMargin: 10
    readonly property int barCapsuleRadius: barHeight / 2

    // ── Bar-scoped type/padding parity tokens (Phase 18.1 gap closure) ───
    //    GATE-02 failed partly because the bar rendered "unmistakably
    //    larger" than the Athena retired-bar layout it replaces. Root
    //    cause: the bar borrowed the DASHBOARD's iconSizeMd (24) for its
    //    glyphs and spacingSm (8) for capsule padding, where Athena's own
    //    stylesheet specifies 16px glyphs and 6px capsule padding. These
    //    three tokens carry Athena's literal values so the bar stops
    //    inheriting dashboard sizing (exact retired-stylesheet file+line
    //    citations for barGlyphSize/barBodySize/barCapsulePadding are
    //    recorded in 18-20-SUMMARY.md's scrubbed-history section, since
    //    that stylesheet no longer exists in this tree).
    //    Like barEdgeMargin/barSideMargin above, barBodySize (13) and
    //    barCapsulePadding (6) are OFF the repo's 4px grid. They carry the
    //    same one-time retired-bar-parity exemption and are equally not a
    //    precedent — they exist to match a stylesheet this bar had to
    //    replace without visibly downgrading it.
    readonly property int barGlyphSize: 16
    readonly property int barBodySize: 13
    readonly property int barCapsulePadding: 6

    //    Athena's capsules also carry `margin: 4px 5px`
    //    (style-athena.scss:70), so a capsule is 8px SHORTER than the bar
    //    and adjacent capsules sit 10px apart — they read as pills floating
    //    in the bar. The QML bar had no such margin: BarCapsule's horizontal
    //    implicitHeight returned barHeight outright, making every capsule a
    //    full-bar-height slab. Measured on screen before this fix: Athena's
    //    capsule 32px tall, the QML's 40px. That is a large part of GATE-02's
    //    "big and clunky". barCapsuleHeight is derived from barHeight so the
    //    two can never drift apart.
    //    Values below come from the UPSTREAM Athena repo
    //    (github.com/haikal-hakim/athena), read directly — see
    //    18.1-qml-bar-athena-restoration/ATHENA-UPSTREAM-SPEC.md. They are NOT
    //    from this repo's own retired-bar style-athena.scss (RETIRE-02/
    //    18-20 deleted it), which was a local reinterpretation and was
    //    the wrong reference the first time.
    //
    //    barCapsuleGap is margin(5) + bar spacing(6) + margin(5) = 16.
    //    A previous pass used 10 (margin only) and missed config.jsonc's own
    //    `"spacing": 6`, which is why the operator reported the left modules
    //    sitting closer together than Athena's.
    readonly property int barCapsuleMarginV: 4
    readonly property int barCapsuleMarginH: 5
    readonly property int barSpacing: 6
    readonly property int barCapsuleHeight: barHeight - barCapsuleMarginV * 2
    readonly property int barCapsuleGap: barCapsuleMarginH * 2 + barSpacing

    //    Athena's drawers are GTK drawers with an explicit transition-duration
    //    and NO dwell delay — hovering opens them immediately
    //    (modules/groups.jsonc). Ours ran the generic 375ms emphasized curve
    //    behind a 400ms popoutDwellMs, which the operator reported as both
    //    clunkier and slower to open than Athena's.
    //      650 — distro-group (the app drawer) and audio
    //      500 — connections and tray
    readonly property int barDrawerTransitionMs: 650
    readonly property int barDrawerTransitionFastMs: 500
    //    GATE-02 round 4: every bar drawer strip's width/height Behavior was
    //    running Motion.emphasizedIn/OutEasing — a semantic-motion-layer
    //    bezier tuned for panel/dialog reveals, with aggressive acceleration
    //    that the operator reported as "not smooth"/"very rough". Athena's
    //    own drawer is a GTK Revealer, whose slide transition is a plain
    //    ease-out curve, not an emphasized in/out pair — one direction, one
    //    shape, the whole time. Easing.OutCubic is Qt's built-in equivalent
    //    (no bezier array, no Motion.qml round-trip needed since this is not
    //    a theme-driven semantic token, just Qt's own enum), named here so
    //    the four drawer strips (launcher, settings, audio, connections)
    //    share one literal rather than repeating the enum value at each
    //    call site.
    readonly property int barDrawerEasingType: Easing.OutCubic
    //    Kept nonzero but small: a literal 0 makes the drawer fire on an
    //    incidental pointer transit across the trigger, which Athena avoids
    //    only because its own drawer is cheap to reopen. 80ms is below the
    //    ~100ms threshold at which a delay becomes perceptible, so it reads as
    //    immediate while still filtering pass-through motion.
    readonly property int barDrawerDwellMs: 80
    //    The collapse side of the same gesture, and deliberately NOT
    //    popoutDismissGraceMs (200), which the two drawer grace timers
    //    borrowed until 2026-08-12. That value is correct for dismissing a
    //    popout — a large surface sitting directly under the pointer — and
    //    wrong here for two measured reasons. First, it is less than half
    //    barDrawerTransitionFastMs (500), so a drawer could begin collapsing
    //    before it had finished opening. Second, reaching a revealed glyph
    //    means traversing barCapsuleGap (16) between trigger and strip, and
    //    across that gap neither HoverHandler reports hovered while the
    //    clock is already running — the operator's report was that the
    //    drawers "disappear too fast making it hard to reach the expanded
    //    bluetooth/mic glyphs".
    //    600 exceeds the 500ms reveal so a collapse can never race the open,
    //    and leaves 100ms of traversal headroom. It equals barReHideGraceMs
    //    (600) on purpose: that token is already 3x popoutDismissGraceMs on
    //    the recorded reasoning that re-hiding the whole bar is a costlier
    //    mistake than dismissing a popout, and collapsing a drawer the user
    //    is actively reaching into is that same class of mistake.
    //    CORRECTED 2026-08-13. The 600 above was sized against
    //    barDrawerTransitionFastMs (500) — but only the CONNECTIONS strip
    //    animates at that duration. The audio strip (MediaConnectivityCapsule
    //    audioStripHost), the settings strip (ClockActionsCapsule) and the
    //    launcher strip (LauncherCapsule) all animate at
    //    barDrawerTransitionMs (650), so for three of the four drawers the
    //    grace window was SHORTER than the reveal it was supposed to outlast:
    //    the collapse could begin before the drawer had finished opening, with
    //    -50ms of traversal headroom instead of +100. That is the operator's
    //    "the expanded volume bar disappears too quickly", reported after the
    //    600 fix had already landed — the fix was right in shape and measured
    //    against the wrong one of two transition tokens.
    //    Deriving from the SLOWEST drawer transition restores the invariant
    //    this token exists to state, and keeps it true by construction if
    //    either duration is ever retuned. The +100 is the same traversal
    //    headroom the reasoning above already argued for across
    //    barCapsuleGap (16), unchanged.
    readonly property int barDrawerGraceMs: barDrawerTransitionMs + 100

    //    ── Intra- vs inter-group gap, and why intra is the LARGER one ─────
    //    Upstream Athena's readout modules carry `padding: 0 8px` plus
    //    `margin-right: 2px`, so two adjacent glyphs inside one group sit
    //    8+8+2 = 18px apart — while two adjacent GROUPS sit 5+6+5 = 16px
    //    apart (barCapsuleGap). Intra-group spacing is therefore WIDER than
    //    inter-group spacing upstream.
    //
    //    Ours was inverted: 8px inside a capsule against 16px between them.
    //    With the capsules also unsurfaced (operator decision — only the
    //    workspace capsule has a background), that inversion is what made the
    //    operator report the system readouts as "too close together and too
    //    far apart from the drawer glyph": the group read as one clump
    //    floating far from its neighbour, instead of evenly-pitched glyphs.
    //
    //    barCellGap is the DEFAULT capsule content gap. Capsules whose
    //    upstream counterpart is tighter override it: workspace buttons carry
    //    only `margin: 0 2px` (a 4px gap) and the right-hand action glyphs
    //    `margin: 4px 2px`, so both use spacingXs instead.
    readonly property int barCellGap: 18

    //    A workspace button fills its group's content box upstream
    //    (`min-width: 32px` with the group's own 6px padding), so the active
    //    pill is as tall as the content area — not as tall as one glyph. Ours
    //    sized the slot to barGlyphSize (16), which made the accent fill look
    //    "too thin" and left a glyph no vertical room to centre inside.
    readonly property int barSlotHeight: barCapsuleHeight - barCapsulePadding * 2

    // ── barColumnWidth (Phase 18 Plan 05) — provenance: 18-UI-SPEC.md
    //    "## New Tokens" + D-18-14 (text-bearing entries re-stack into this
    //    exact column width in vertical orientation). 44 IS on the repo's
    //    4px grid — it does NOT use the two-token grid exemption recorded
    //    above for barEdgeMargin/barSideMargin, which exists solely for
    //    retired-bar positional parity and is not a precedent for this token.
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

    // ── mediaTitleVerticalRun (2026-08-13) — the maximum length, ALONG the
    //    column, of the rotated now-playing title in vertical orientation.
    //    Provenance: operator report that the vertical bar showed no title at
    //    all. It showed none by design — a 44px column fits roughly five
    //    characters at barBodySize (measured: a two-digit clock is 14.8px, so
    //    ~7.4px/char), so UI-SPEC's vertical "no truncation" bar left the title
    //    to MediaPopout, exactly as network leaves the SSID there.
    //    Rotating the title 90 degrees changes which axis the constraint lives
    //    on: the title then runs down the column, where the budget is the bar's
    //    height rather than its 44px width, and most titles fit outright.
    //    This cap exists so a pathological title cannot grow the capsule without
    //    bound — UI-SPEC's E7 row requires the capsule extent stay fixed as the
    //    title changes. 160 is 10x the glyph pitch and comfortably longer than
    //    any title that fit the horizontal bar's own 30-char cap.
    readonly property int mediaTitleVerticalRun: 160

    // ── trayMaxExtent (Phase 18 Plan 10) — provenance: 18-UI-SPEC.md
    //    "## New Tokens" + D-18-04. The maximum extent of the tray
    //    capsule's icon row on its long axis (width horizontal, height
    //    vertical) before the row scrolls internally rather than the
    //    capsule growing further — a safety bound, not a collapse: every
    //    icon stays reachable by scrolling, nothing is folded behind an
    //    expander. 240 IS on the repo's 4px grid and does NOT use the
    //    two-token grid exemption 18-01 recorded for barEdgeMargin/
    //    barSideMargin, which exists solely for retired-bar positional
    //    parity and is not a precedent for this token. At the fixed 32px cell
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

    // ── Popout body tokens (Phase 18 Plan 14, QBAR-09) — provenance:
    //    18-UI-SPEC.md's glance-scope rule for `popoutListCap`; this plan
    //    itself for `backendResolveDeadlineMs`, since UI-SPEC's token table
    //    carries no row for it. Appended alone, per this phase's standing
    //    rule that each plan appends only the tokens it actually reads.
    //
    //    One number governs every popout list across all six bodies —
    //    wifi's saved networks, bluetooth's devices, audio's sinks (18-13's
    //    own literal is retrofitted onto this token by this same plan's
    //    last task) — so the rule that keeps a popout a glance surface
    //    lives in one place rather than as a literal repeated per body.
    readonly property int popoutListCap: 3

    // What it bounds: how long the shell will keep claiming a connectivity
    // service is still resolving before it says instead that there is
    // nothing there. It decides which of two true sentences is shown and
    // never what value is shown — no number anywhere is derived from it.
    readonly property int backendResolveDeadlineMs: 2000

    // ── Reveal tokens (Phase 18 Plan 16, QBAR-08) — provenance:
    //    18-UI-SPEC.md "## New Tokens". The last two unclaimed bar tokens
    //    in that table; appended alone, per this phase's standing rule that
    //    each plan appends only the tokens it actually reads.
    //
    //    hotZoneDepth (4) — D-18-25's decided 3-5px range for the invisible
    //    input-only reveal strip, resolved under Claude's Discretion to the
    //    midpoint, and 4 IS on the repo's 4px grid (unlike barEdgeMargin/
    //    barSideMargin's one-time retired-bar-parity exemption above, this
    //    token needs no exemption).
    readonly property int hotZoneDepth: 4

    // barReHideGraceMs (600) — D-18-26's re-hide grace window. Deliberately
    // three times popoutDismissGraceMs (200) above: re-hiding the WHOLE bar
    // is the more consequential event than dismissing one popout, and "must
    // never vanish under the pointer" is the harder constraint to honour.
    readonly property int barReHideGraceMs: 600

    // ── Notification tokens (Phase 19 Plan 01 tracer, QNOTIF-01/02) —
    //    provenance: 19-UI-SPEC.md "## New Tokens" -> `Design.qml`
    //    additions table. Declared in ONE pass per this plan's own
    //    instruction, so no later Phase 19 plan needs to reopen this file
    //    for a token addition.
    readonly property int notifSurfaceWidth: 430
    // ── OSD tokens (Phase 20 Plan 03, QOSD-01/QOSD-04) — provenance:
    //    20-UI-SPEC.md "## New Tokens". Declared here, adjacent to
    //    notifSurfaceWidth/notifToastDurationMs, since the OSD is their
    //    deliberate sibling: it reuses Toast.qml's frame (Phase 19 Plan
    //    01) but is its own layer namespace and its own width/dwell.
    //
    //    osdWidth (380) — D-20-10, locked. Deliberately narrower than
    //    notifSurfaceWidth (430) so the OSD reads as a lighter surface
    //    than the popup/centre family it shares chrome with.
    readonly property int osdWidth: 380
    // osdHideDelayMs (1200) — D-20-06, Claude's Discretion resolved by
    // UI-SPEC. Independent of notifToastDurationMs (2000) on purpose, and
    // deliberately longer than SwayOSD's own 1000: interactive: true means
    // a drag must be able to complete inside the dwell window, and the
    // hover-pause already covers genuinely slow interaction.
    readonly property int osdHideDelayMs: 1200
    // osdRecencyWindowMs (1500) — D-20-08, Claude's Discretion resolved by
    // UI-SPEC. Gates SLIDER-ROW MEMBERSHIP (a control earns a row only if
    // its value changed within this window), not the dwell.
    readonly property int osdRecencyWindowMs: 1500
    readonly property int notifImageSize: 42
    readonly property int notifBadgeSize: 20
    // Reuses the rim's own stroke weight rather than inventing a fourth
    // line-weight value on this surface (D-19-09).
    readonly property int notifRingStrokeWidth: borderWidth
    // D-19-05's vertical drag-to-expand threshold, bound to the existing
    // spacing scale rather than a new literal.
    readonly property int notifExpandThresholdPx: spacingXl
    // D-19-07's horizontal drag-to-dismiss threshold — a FRACTION of card
    // width (Caelestia's `clearThreshold`), never a pixel offset. This
    // codebase's first dimensionless-fraction token: it does not sit on
    // the 4px grid every property above does, because it reproduces a
    // ratio, not a screen-space offset (19-UI-SPEC.md's own "Spacing
    // Scale" exceptions note). 0.3 is the conventional swipe-to-confirm
    // dismiss range, resolved under Claude's Discretion.
    readonly property real notifDismissThresholdFraction: 0.3
    // ── GATE-02 gap-closure round 7 additions ───────────────────────────
    // Item 3 — the DESIGN bound on simultaneous popups, layered on top of
    // NotifPopupStack's own geometric 2/3-screen-height fit (whichever is
    // smaller wins there). Three is the depth at which a stack still reads
    // as a stack: enough for a burst to be visible at once, few enough
    // that the surplus rolls into the existing "+N more" summary card
    // instead of tiling the right edge of the screen.
    readonly property int notifMaxVisiblePopups: 3
    // Item 2 — expanded-state body clamp. The compact state already elides
    // the body to one line; the EXPANDED state had no bound at all
    // (`maximumLineCount: 0`, `elide: ElideNone`), so a long-bodied
    // notification grew its card without limit and could run off-screen —
    // the "long content looks weird inside the card" report. 19-UI-SPEC.md
    // (N1/overflow) specifies "expanded state scrolls if content still
    // exceeds the clamp", but a Flickable nested inside this card would
    // have to fight the card's OWN two drag gestures for the same
    // vertical/horizontal touch stream (D-19-05 expand, D-19-07 dismiss),
    // so the clamp is enforced by line count with an ellipsis instead of a
    // scroll view — same bound, no gesture contention. Eight lines keeps
    // a normal multi-paragraph message fully visible.
    readonly property int notifBodyMaxLines: 8
    // Item 1 — the notification centre's persistent decorative picture
    // band. Round 6 shipped this picture inside the EMPTY-STATE block, so
    // it was visible only while history was completely empty; with any
    // notification present it was gone, which is the "where is the picture"
    // report. It is now a permanent element of the centre and this is the
    // vertical band it occupies, under the header and above the history
    // list. Large enough to read as artwork rather than an icon, small
    // enough that a full-height centre still shows plenty of history.
    readonly property int notifCentrePictureHeight: 132
    // D-19-36 — the DND-toggle toast's own auto-dismiss window,
    // deliberately its own number rather than reused from D-19-04's 3s/5s
    // notification timeouts: a toast is feedback for an action just
    // taken, not content to read.
    readonly property int notifToastDurationMs: 2000
    // Content-hugging cap for the toast frame, narrower than
    // notifSurfaceWidth because a toast carries one line of text, never a
    // card's full content.
    readonly property int notifToastMaxWidth: 320
    // D-19-29 — Caelestia's verified per-app clear-all batching interval.
    readonly property int notifHistoryBatchSize: 30
    // D-19-30 — the named divergence from Caelestia's uncapped history:
    // oldest item dropped past 100, since this shell hot-reloads and
    // restarts far more often than either reference shell's deployment.
    readonly property int notifHistoryCap: 100

    // ── Session (power menu) tokens (Phase 20 Plan 03, QPOWER-01) —
    //    provenance: 20-UI-SPEC.md "## New Tokens". Declared in ONE pass
    //    per this plan's own instruction, so no later Phase 20 power-half
    //    plan needs to reopen this file for a token addition.
    //
    //    sessionDialogWidth (488) — D-20-21. Derivation, recorded so the
    //    number is never re-derived wrong: sessionTileWidth (136) × 3 +
    //    spacingMd (16) × 2 gaps + panelPadding (24) × 2 sides
    //    = 408 + 32 + 48 = 488.
    readonly property int sessionDialogWidth: 488
    readonly property int sessionTileWidth: 136
    readonly property int sessionTileHeight: 104
    // sessionTileRadius (16) — D-20-21. Deliberately NOT popoutCornerRadius
    // (20, reserved for the outer frame); matches QuickToggles.qml's own
    // chipRadius (16) so a session tile reads as a sibling of a
    // quick-toggle chip.
    readonly property int sessionTileRadius: 16
    // sessionTileIconSize (32) — D-20-21. The one deliberate departure
    // from the shell's uniform iconSizeMd (24) icon discipline: a session
    // tile is a large tap target carrying a single glyph as its entire
    // content, not an icon alongside a label, so it earns a larger size.
    readonly property int sessionTileIconSize: 32
    // sessionScrimOpacity (0.55) — D-20-21/D-20-34. Matches
    // BarRoles.barSurface's own 0.55 and therefore already clears the
    // `^quickshell-.*` family's ignore_alpha: 0.5 floor with headroom.
    readonly property real sessionScrimOpacity: 0.55
}
