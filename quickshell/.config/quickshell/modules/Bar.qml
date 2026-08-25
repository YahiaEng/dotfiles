// Bar.qml — the orientation-driven root (Phase 18 Plan 05, QBAR-02).
//
// `BarEntryModel.isVertical` is the ONE value every geometry binding in
// this file reads. There is no second arrangement, no forked layout file
// and no branch deciding which capsules render or in what order. The
// capsule-to-capsule axis is one positioner whose rows/columns are bound
// rather than a pair of sibling positioners, because a pair is the
// forked-arrangement failure in miniature. The vertical reservation
// totals 50 — the bar's own column width plus a SINGLE edge margin, the
// exact D-18-38 arithmetic 18-01 proved at 46 on the horizontal axis,
// applied unchanged on the other axis. See the exclusiveZone binding
// below for the exact formula and the live measurement that proved it.
//
// This file, modules/bar/qmldir and shell.qml's bar wiring are FROZEN
// for wave 3: 18-08, 18-09, 18-10 and 18-11 each fill exactly one
// capsule component and none of them edits this file — a wave-3 plan
// that finds it needs an edit here has found an 18-05 scope correction.
//
// ── Carried unchanged from 18-01 (the phase's tracer, QBAR-01) ──────────
//   1. exclusiveZone: the surface's own content extent alone
//      (Design.barHeight horizontally, Design.barColumnWidth + margin
//      vertically) — Hyprland's own reservation total is
//      margins.<edge> + exclusiveZone, so the margin must never be
//      folded into both terms. See 18-01-SUMMARY.md's Deviations section
//      for the full live-measurement trail this file's horizontal branch
//      still reproduces exactly.
//   2. No dismissed state: this surface never unmounts for the life of
//      the session, so anything it schedules runs permanently — the
//      clock (now inside ClockActionsCapsule.qml, moved out of this file
//      by this plan) is event-driven rather than a repeating Timer for
//      exactly this reason.
//
// Root type is PanelWindow, copying Overview.qml's single-PanelWindow
// posture verbatim. Per-screen fan-out (Variants-rooted, QS-03) is
// permanently dropped under D-13 (PROJECT.md Out of Scope) — no fan-out
// root type may be reintroduced here.
//
// Namespace "quickshell-bar" inherits windowrules.lua's ^quickshell-.*
// family blur rule together with its ignore_alpha = 0.5 floor
// (hypr/.config/hypr/config/windowrules.lua:397/449) with zero new
// Hyprland config — so no fill on this surface may sit below 0.5 alpha
// without silently killing that blur.
//
// Explicitly NOT built here (each owned by a named later plan): popouts
// and hover mechanics (18-13/14), the hot zone (18-16), doctor checks
// (18-17), the restart unit (18-07, QBAR-10). Auto-hide and the `bar`
// IPC handler (18-15) are built by THIS plan — see the visibility-state
// block below; the owner script and the IpcHandler both live in
// shell.qml, never in this file (see that block's own closing note).
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "dashboard"
import "bar"
// The rails' own path builder (quick task 260825-pyf, Task 3). The slab is
// a vertical run with pill caps and a bulge on its inner face — which is
// precisely what `buildOutline` already draws, so the popout bulge reuses
// the golden-tested builder rather than hand-rolling a second one with its
// own sweep-flag risk. Verified before adoption: with `bulge: false` it
// reproduces `_weldRoundedRect(52, 1440, 26)` exactly, same bbox, same
// shape, differing only in drawing each cap as two quarter arcs.
import "edgebarpath.js" as EdgeBarPath

PanelWindow {
    id: barWindow

    // The single value the whole file binds to.
    readonly property bool vertical: BarEntryModel.isVertical

    // ── Continuous edge-bar weld (quick task 260824-ns3, Task 3, Q4b) ────
    // DELIBERATE REVERSAL OF D-2 ("Bar.qml is not opened, moved,
    // reoriented or absorbed" by the edge bar, see this file's own header
    // above) — recorded here and in the SUMMARY exactly the way D-3's
    // reversal was recorded in round 11, not discovered mid-task. The
    // brief's own words: "Continuous requires the bar and the rail to
    // share a shape." Continuous is the DEFAULT edge-bar style (Q4), so
    // this fires on first install, not on some rare opt-in path.
    //
    // The mechanism, and why it is this one and not the obvious one: the
    // study draws the rails running from the screen inset to the bar's
    // OWN centre line — past the bar's left edge. The strip surface
    // cannot get there; it is anchored left+right with a non-negative
    // `exclusiveZone`, and a layer-shell surface with a non-negative
    // exclusive zone is positioned INSIDE every other surface's zone, so
    // the vertical bar's own 50px reservation already pins the strip's
    // right end at the bar's left edge no matter what margin is set.
    // Setting the strip's own exclusiveZone negative to escape that would
    // surrender its own 6px reservation — one surface cannot do both. So
    // the strips stop exactly where they already stop, and the BAR itself
    // paints the bridge from that point through its own body — which is
    // the whole content of "the bar and the rail must share a shape".
    //
    // `&& vertical` is load-bearing: Continuous is drawn against a
    // right-edge VERTICAL bar (the live orientation). This shell's bar
    // can be flipped horizontal from Settings; in that orientation there
    // is no meaningful "weld" (the strips run along the top/bottom edges,
    // orthogonal to a horizontal bar's own edge), so this collapses to
    // false and the bar renders exactly as it does today — the strips
    // simply end at their own right edge, no weld, no error.
    property string edgeBarStyle: "off"
    readonly property bool _continuousWeld: barWindow.edgeBarStyle === "continuous" && barWindow.vertical

    // ── Anchors — each a boolean binding off `vertical`, no branch. These
    //    are PanelWindow's own bool anchor flags (layer-shell edge
    //    anchoring), NOT QtQuick's AnchorLine-typed Item.anchors — the
    //    undefined-clears-an-anchor idiom used below for the zone
    //    containers does not apply here; live-verified (this task's own
    //    reload log): assigning `undefined` to one of these produces a
    //    "Unable to assign [undefined] to bool" warning, so a plain
    //    boolean ternary is used instead. top and right are true in both
    //    orientations; left is true only when not vertical; bottom is
    //    true only when vertical. ─────────────────────────────────────
    anchors {
        top: true
        left: !barWindow.vertical
        right: true
        bottom: barWindow.vertical
    }

    // ── Margins — a ternary per property, never a branch ────────────────
    // Continuous weld (Task 3): margins.top/.bottom go to 0 so the slab
    // spans the FULL screen height, matching the study's `rect{y:0, h:H}`.
    // Neither is the anchored edge that carries the reservation — that is
    // `margins.right` below, per this file's own documented arithmetic
    // (`margins.<edge> + exclusiveZone`) — so `reserved` cannot move; this
    // file has shipped the double-count version of that bug twice, hence
    // the explicit note.
    margins.top: barWindow.vertical ? (barWindow._continuousWeld ? 0 : Design.barSideMargin) : Design.barEdgeMargin
    margins.right: barWindow.vertical ? Design.barEdgeMargin : Design.barSideMargin
    margins.left: barWindow.vertical ? 0 : Design.barSideMargin
    margins.bottom: barWindow.vertical ? (barWindow._continuousWeld ? 0 : Design.barSideMargin) : 0

    // ── Extent — the free axis is the one both opposite edges anchor, so
    //    the compositor's own stretch behaviour determines its real size
    //    regardless of implicit value here (18-01's own Bar.qml already
    //    proved this live: it set only implicitHeight and left
    //    implicitWidth unset entirely, and the left+right-anchored width
    //    stretched correctly). 0 on the free axis is therefore inert, not
    //    a magic number — the fixed axis's ternary branch is what is
    //    load-bearing. ──────────────────────────────────────────────────
    //
    // Continuous weld (Task 3): the surface widens LEFTWARD by
    // `edgeBarSideMargin + barColumnWidth / 2` (10 + 22 = 32, both
    // already-existing tokens — no new one added). `margins.right` and
    // `exclusiveZone` below are BOTH unchanged, so a surface wider than
    // its own exclusive zone overhangs into the client area — the exact
    // idiom the edge bar's own bulge already uses. `reserved` must still
    // measure `[0, 6, 50, 6]` afterwards; measured, not asserted (see the
    // SUMMARY).
    implicitHeight: barWindow.vertical ? 0 : Design.barHeight
    implicitWidth: barWindow.vertical
        ? Design.barColumnWidth + (barWindow._continuousWeld ? (Design.edgeBarSideMargin + Design.barColumnWidth / 2) : 0)
        : 0

    // ── Layer posture — copies Overview.qml's structural template; the
    //    only properties whose VALUE changes are exclusiveZone/implicit
    //    extent, both driven by `vertical`. ─────────────────────────────
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false
    // LIVE-MEASURED CORRECTION (18-05's Task 2, found and fixed the same
    // way 18-01's Task 2 found and fixed the original instance of this
    // exact bug): the surface's own submitted exclusiveZone is its content
    // extent ALONE — Design.barHeight horizontally, Design.barColumnWidth
    // vertically — never plus the edge margin, because Hyprland's own
    // reservation TOTAL is margins.<anchored-edge> + exclusiveZone, and
    // margins.top/.right above ALREADY carry Design.barEdgeMargin on
    // their respective axis. Folding it into exclusiveZone too would
    // double-count it — reproduced live in 18-05 (co-existing reading
    // [[0,98,0,0]] instead of the expected [[0,92,0,0]], the exact +6
    // signature of the double-margin bug) before being corrected there.
    // Total reservation = margins.<edge> + exclusiveZone. Horizontally
    // that total is Design.barHeight + Design.barEdgeMargin = 48
    // (42 + 6), live-confirmed 2026-08-12 as [[0,48,0,0]]. It read 46
    // from 18-01 through 18-18, when barHeight was 40; Phase 18.1 raised
    // it to upstream Athena's own "height": 42 (ATHENA-UPSTREAM-SPEC.md),
    // which moved the reservation by the same 2px. Vertically it is
    // Design.barColumnWidth + Design.barEdgeMargin = 50 — a SINGLE edge
    // margin on whichever axis is anchored, never doubled into both
    // terms. Both terms below are compile-time expressions over readonly
    // property int tokens; no runtime value reaches either.
    //
    // ── Phase 18 Plan 15 (QBAR-07) — the content extent moved into its
    //    own named property, `reservedZoneExtent`, and `exclusiveZone`
    //    below now gates it on `zoneReserved` (declared further down,
    //    beside `barRendered`) rather than submitting it unconditionally.
    //    The right-hand side is the EXACT expression this property held
    //    before this plan — moved, not re-derived; see the property's own
    //    trailing comment for why it must stay content-only. ────────────
    readonly property int reservedZoneExtent: barWindow.vertical ? Design.barColumnWidth : Design.barHeight // content only — margins.<edge> above independently carries the single Design.barEdgeMargin; never add it here too, or the reservation doubles
    exclusiveZone: barWindow.zoneReserved ? barWindow.reservedZoneExtent : 0
    exclusionMode: ExclusionMode.Normal
    color: "transparent"

    // Never Overlay: always-on chrome sits below transient dialogs and
    // below an ext-session-lock surface, unlike Overview's deliberately
    // top-most Overlay layer.

    // ── Backend handles — bound in from shell.qml, re-bound uniformly
    //    into all six capsule slots below. ───────────────────────────────
    property var audioBackend
    property var mediaBackend
    property var systemResources
    property var wifiBackend
    property var bluetoothBackend

    // Re-exported straight through from the one entry list, so shell.qml
    // reads the always-on charge through this already-mounted instance
    // instead of taking a second import path into modules/bar/ — one
    // hop, no new import-resolution risk.
    readonly property bool requiresAudio: BarEntryModel.requiresAudio
    readonly property bool requiresMedia: BarEntryModel.requiresMedia
    readonly property bool requiresResources: BarEntryModel.requiresResources

    // ── Summon seams — 18-05 froze this at exactly two for wave 3 and
    //    wave 6 alike, and a later plan needing a third seam would find an
    //    18-05 scope correction: this is that correction (Phase 20 Plan 06
    //    Task 2, QPOWER-01/D-20-22). Nothing emits from any of the three
    //    here — 18-11's actions and 18-14's wayfinding links are the
    //    callers for the first two; PopoutController.requestPowerMenu()
    //    (called from `powerCell.onClicked` below) is the caller for the
    //    third — `powerCell.onClicked` in ClockActionsCapsule.qml. ───────
    signal panelRequested(string name)
    signal dashboardRequested(int tabIndex)
    signal powerMenuRequested()
    signal settingsRequested()

    // ── Visibility state (Phase 18 Plan 15, QBAR-07) — this file's own
    //    slice of the single-owner claim: `visibilityState` is written
    //    ONLY by shell.qml's binding on the `Bar { id: barInstance }`
    //    mount below (a binding, never an external assignment), never by
    //    anything inside this file. Three values only:
    //    "visible" | "hidden-idle" | "hidden-hard" — the same vocabulary
    //    the on-disk owner script's own status verb prints. ────────────
    property string visibilityState: "visible"

    // 18-16's seam (QBAR-08, not built here): a strictly transient
    // presentation override that may make a hidden bar temporarily
    // rendered, may NEVER make a visible bar hidden, never writes an
    // intent file anywhere, and never affects the reservation below —
    // `zoneReserved` is deliberately independent of this property so a
    // hover reveal over a fullscreen window draws the bar without
    // re-reserving space, and therefore cannot reflow the game the user
    // is playing.
    property bool revealOverride: false

    readonly property bool barRendered: barWindow.visibilityState === "visible" || barWindow.revealOverride
    // Independent of revealOverride by construction — see the comment on
    // that property above. Reserves for every state except the one
    // explicit, hard, want-the-pixels-back state (fullscreen, gaming
    // mode, or the keybind override); a merely-idle hide keeps the zone.
    readonly property bool zoneReserved: barWindow.visibilityState !== "hidden-hard"

    // The observable 18-16 consumes: that plan drives PopoutController's
    // own reveal-settled latch off `barRendered` and this flag together.
    // This plan adds no writer of that latch itself — ownership of it
    // stays with 18-16, which is the only file that ever assigns it.
    readonly property bool barTransitionRunning: barFadeAnim.running

    // ── Hidden-state slide offsets — the bar slides out through its own
    //    anchored edge in either orientation. Zero whenever rendered; on
    //    the free (non-anchored) axis it stays zero even while hidden,
    //    since sliding along the axis nothing anchors to would not read
    //    as "leaving through the edge". ───────────────────────────────
    readonly property real hiddenTranslateY: (barWindow.barRendered || barWindow.vertical) ? 0 : -barWindow.reservedZoneExtent
    readonly property real hiddenTranslateX: (barWindow.barRendered || !barWindow.vertical) ? 0 : barWindow.reservedZoneExtent

    // Closes any open popout the instant this surface stops rendering —
    // idle, fullscreen, gaming mode, keybind, all funnel through
    // `barRendered` going false. A pinned popout floating with no bar
    // beneath it (over a fullscreen window, say) is the failure this
    // guard exists to prevent. The separate rule that a hover-reveal must
    // not re-hide while a popout is open is 18-16's grace condition and
    // is not implemented here.
    onBarRenderedChanged: {
        if (!barWindow.barRendered && PopoutController.anyOpen)
            PopoutController.close();
    }

    // ── Popout wayfinding relay (Phase 18 Plan 13 Task 3, QBAR-09) —
    //    named seam into this 18-05-owned file, additive and bounded to
    //    exactly this one block. A popout lives inside a capsule
    //    instantiated through a loader and has no declarative path to
    //    this window root's signals, and reaching for the window through
    //    an ambient attached lookup would be a second way to do what this
    //    repo already does by passing handles down — so this plan reuses
    //    the existing seam above instead of adding a third one. No other
    //    line of this file changes. ──────────────────────────────────────
    Connections {
        target: PopoutController
        function onPanelRequested(name) { barWindow.panelRequested(name); }
        function onDashboardRequested(tabIndex) { barWindow.dashboardRequested(tabIndex); }
        function onPowerMenuRequested() { barWindow.powerMenuRequested(); }
        function onSettingsRequested() { barWindow.settingsRequested(); }
    }

    // Mirrors shell.qml's own panelLoaderFor(name) name-to-object map
    // rather than inventing a second lookup shape. An unrecognised id
    // resolves to null and renders nothing, exactly as panelLoaderFor
    // does.
    function componentFor(capsuleId) {
        if (capsuleId === "launcher")
            return launcherComponent;
        if (capsuleId === "system")
            return systemComponent;
        if (capsuleId === "workspaces")
            return workspaceComponent;
        if (capsuleId === "idleInhibitor")
            return idleInhibitorComponent;
        if (capsuleId === "mediaConnectivity")
            return mediaConnectivityComponent;
        if (capsuleId === "systemTray")
            return systemTrayComponent;
        if (capsuleId === "clockActions")
            return clockActionsComponent;
        return null;
    }

    // Binding all five backend handles to all six capsule types (tray was
    // a different sixth, removed under phase 18.1 plan 04's D-15 and
    // reinstated by quick task 260823-65s; the GATE-02 fix that relocated
    // the idle-inhibitor bulb into its own capsule, IdleInhibitorCapsule,
    // added a new sixth here) is deliberate redundancy: it is what lets a
    // wave-3 plan discover a backend need inside its own file instead of
    // editing this one and serialising the wave.
    Component {
        id: launcherComponent
        LauncherCapsule {
            audioBackend: barWindow.audioBackend
            mediaBackend: barWindow.mediaBackend
            systemResources: barWindow.systemResources
            wifiBackend: barWindow.wifiBackend
            bluetoothBackend: barWindow.bluetoothBackend
        }
    }
    Component {
        id: systemComponent
        SystemCapsule {
            audioBackend: barWindow.audioBackend
            mediaBackend: barWindow.mediaBackend
            systemResources: barWindow.systemResources
            wifiBackend: barWindow.wifiBackend
            bluetoothBackend: barWindow.bluetoothBackend
        }
    }
    Component {
        id: workspaceComponent
        WorkspaceCapsule {
            audioBackend: barWindow.audioBackend
            mediaBackend: barWindow.mediaBackend
            systemResources: barWindow.systemResources
            wifiBackend: barWindow.wifiBackend
            bluetoothBackend: barWindow.bluetoothBackend
        }
    }
    Component {
        id: idleInhibitorComponent
        IdleInhibitorCapsule {
            audioBackend: barWindow.audioBackend
            mediaBackend: barWindow.mediaBackend
            systemResources: barWindow.systemResources
            wifiBackend: barWindow.wifiBackend
            bluetoothBackend: barWindow.bluetoothBackend
        }
    }
    Component {
        id: mediaConnectivityComponent
        MediaConnectivityCapsule {
            audioBackend: barWindow.audioBackend
            mediaBackend: barWindow.mediaBackend
            systemResources: barWindow.systemResources
            wifiBackend: barWindow.wifiBackend
            bluetoothBackend: barWindow.bluetoothBackend
        }
    }
    Component {
        id: systemTrayComponent
        TrayCapsule {
            audioBackend: barWindow.audioBackend
            mediaBackend: barWindow.mediaBackend
            systemResources: barWindow.systemResources
            wifiBackend: barWindow.wifiBackend
            bluetoothBackend: barWindow.bluetoothBackend
        }
    }
    Component {
        id: clockActionsComponent
        ClockActionsCapsule {
            audioBackend: barWindow.audioBackend
            mediaBackend: barWindow.mediaBackend
            systemResources: barWindow.systemResources
            wifiBackend: barWindow.wifiBackend
            bluetoothBackend: barWindow.bluetoothBackend
        }
    }
    // ── Continuous weld — the bridge from the strip's end into the bar's
    //    own body (Task 3, D-2 reversal) ─────────────────────────────────
    // Three pieces, painted BEHIND `barContent` (declared before it —
    // QtQuick z-order is declaration order for siblings with no explicit
    // `z`): the full-height slab, its inset `Colours.surface` core, and
    // two horizontal weld stubs that close the 1860 -> 1892 run from the
    // strip's own end into the slab's rounded cap. All inert
    // (zero-visible) whenever `_continuousWeld` is false.
    //
    // Reuses the SAME three accent roles the strip's own gradient uses
    // (Colours.primary/.secondary/.tertiary) and the SAME scrolling idiom
    // EdgeBar.qml's strip already established (a phase property animated
    // 0 -> 1 over `Motion.borderRotateDuration`, `ShapeGradient.RepeatSpread`,
    // period = the consumer's own extent) — no new `Motion.*` token name.
    // ── Weld geometry, all derived from ONE token ───────────────────────
    // The slab is the bar's own body painted in the rail's vocabulary. It
    // is `edgeBarWeldRim` wider than the bar's column on EACH side, so the
    // surface-coloured core it encloses is exactly `barColumnWidth` — the
    // width every bar widget was built for. Sizing the slab AT the column
    // width instead (what round 1 did) leaves a 36px interior, and the
    // 44px widgets then straddle the rim: measured, the workspace group's
    // outer 4px on both sides came back blended with the gradient.
    // The extra width is taken LEFTWARD into the surface's existing
    // non-reserving overhang, so `margins.right` and `exclusiveZone` are
    // untouched and `reserved` cannot move.
    readonly property real _weldSlabWidth: Design.barColumnWidth + 2 * Design.edgeBarWeldRim
    // Local x of the slab: flush to the surface's right edge.
    readonly property real _weldSlabX: barWindow.width - barWindow._weldSlabWidth
    // The rail runs to the bar's CENTRE LINE — the study's own
    // `railH(0, INSET, BAR.x + BAR.w/2, ...)`. Stopping at the slab's left
    // edge leaves the slab's corner radius uncovered as a notch.
    readonly property real _weldRunEnd: barWindow._weldSlabX + barWindow._weldSlabWidth / 2
    // Solid gradient depth at the slab's two ends. Rim alone is not enough
    // (see the core's own note); the rail run must land entirely on solid
    // colour. Content is inset by this same number for the same reason —
    // they are one quantity, not two that happen to match.
    readonly property real _weldCapDepth: Design.edgeBarThickness + Design.edgeBarWeldRim

    // ── Gradient continuity with the strip ──────────────────────────────
    // Phase comes from the shared clock (GradientPhase.qml) so this cannot
    // drift against the strip. PERIOD and ORIGIN are the other half, and
    // the half that was actually wrong in round 1: the stub carried its own
    // 54px period, compressing the WHOLE primary/secondary/tertiary
    // spectrum into the joint, which is why it read as a rainbow band
    // against a strip that spreads the same spectrum over 2490px.
    //
    // The strip's period is its own surface width and its origin is
    // `edgeBarSideMargin`. Mapping this surface's local u onto that space:
    //     absX = u + _barSurfaceX      strip-local s = absX - edgeBarSideMargin
    // so an x1 of `phase * period - (_barSurfaceX - edgeBarSideMargin)`
    // makes the colour at any absolute x identical on both surfaces.
    readonly property real _barSurfaceX: barWindow.screen
        ? barWindow.screen.width - Design.barEdgeMargin - barWindow.width
        : 0
    readonly property real _stripPeriod: barWindow.screen
        ? Math.max(1, barWindow.screen.width - 2 * Design.edgeBarSideMargin - (Design.barColumnWidth + Design.barEdgeMargin))
        : 1
    readonly property real _stripGradX1: GradientPhase.phase * barWindow._stripPeriod - (barWindow._barSurfaceX - Design.edgeBarSideMargin)

    // ── The popout's root: a bulge on the bar's own edge (quick task
    //    260825-pyf, Task 3) ───────────────────────────────────────────
    // The dashboard grows out of a bulge on the top rail; a bar popout now
    // grows out of one on the bar's edge, in the same vocabulary. The
    // dashboard's bulge is CENTRED because the dashboard is centred — the
    // principle is "a bulge sized to the panel, at the panel's position",
    // and for a glance surface that position is beside its own capsule.
    //
    // CONTINUOUS ONLY, by the same `_continuousWeld` predicate that gates
    // every other weld piece in this file. It is not a style check bolted
    // on: outside Continuous the bar has no painted edge at all
    // (`barContent` is a bare Item, and the slab and its core are both
    // `visible: _continuousWeld`), so there is no edge to swell. The other
    // four styles take the popout's unattached posture instead.
    //
    // ── DEPTH AND SPAN COME FROM THE RAILS' OWN TOKENS ──────────────────
    // Not new numbers. `edgeBarBulgeExtra` (the rails' resting bulge) plus
    // `edgeBarBulgeSwellExtra` (what a rail adds while the surface it roots
    // is open) is exactly the depth a rail reaches under an open dashboard,
    // so an open popout sits on the same shelf. The span is the popout's own
    // along-axis extent, which is the direct analogue of the top rail's
    // `edgeBarBulgeWidthTop: dashboardMinWidth` — the panel's own size.
    // Fillet and corner radii are the rails' verbatim.
    readonly property real _popoutBulgeDepthOpen: Design.edgeBarBulgeExtra + Design.edgeBarBulgeSwellExtra

    // Animated 0 -> depth so the shelf grows under the popout rather than
    // popping. Driven off `anyOpen`, NOT off the centre/extent pair — those
    // are snapshots and must never be animated (see PopoutController).
    // A DIRECT binding, not a `Binding` element targeting this same object.
    // The first version used `Binding { target: barWindow; property:
    // "popoutBulgeDepth"; ... }` and it silently never applied — the
    // diagnostic below never emitted a single line, so the depth stayed 0
    // and no bulge was ever drawn, while the three `Binding`s aimed at
    // PopoutController in this same file worked fine. A self-targeted
    // Binding is the one shape to avoid here; an ordinary binding
    // expression animates through the Behavior just the same.
    property real popoutBulgeDepth: (barWindow._continuousWeld && PopoutController.anyOpen)
        ? barWindow._popoutBulgeDepthOpen : 0
    Behavior on popoutBulgeDepth {
        enabled: Motion.motionEnabled
        NumberAnimation {
            // The dashboard's own register, which is the point of the
            // exercise: the same growth the rail performs under a drawer.
            duration: PopoutController.anyOpen ? Motion.spatialInDuration : Motion.spatialOutDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: PopoutController.anyOpen ? Motion.spatialInEasing : Motion.spatialOutEasing
        }
    }

    // The bulge's span in the SLAB's own along coordinates. `openCentre` is
    // already in the bar window's along-axis space and the slab is
    // `y: 0, height: barWindow.height`, so slab-local along IS window along
    // — zero conversions, which is the whole reason PopoutController
    // publishes in that space (see its own comment on the three times this
    // family shipped a double-added origin).
    //
    // CLAMPED INTO THE SLAB'S STRAIGHT SECTION. `buildOutline` assumes the
    // bulge sits on the flat run, not across a pill cap; letting a span
    // reach into a cap would put a fillet on top of the cap's own arc and
    // self-intersect the outline — the same silent class as round 10's
    // broken fillet invariant, which raised nothing and just looked wrong.
    // A popout near the very top or bottom of the bar therefore roots at
    // the nearest legal point rather than off the end.
    // ── THE BULGE IS EXACTLY ITS PANEL'S EXTENT ─────────────────────────
    // Operator, quick task 260825-t6j: "The bulge width is wrong. It needs
    // to be the same width of its corresponding panel." Measured at the
    // time: panel 281 along-axis, bulge span 865..1140 = 275, i.e. 3px short
    // at each end.
    //
    // Those 6px were `2 * Design.edgeBarFilletRadius`, and round 4 of
    // 260825-pyf subtracted them for a real reason. `buildOutline` draws
    // each concave shoulder OUTSIDE the span it is handed — from the flat
    // run it travels to `xr + f` before filleting back to `xr` — so a span
    // at the panel's extent overshot the panel by `f` at both ends. In that
    // band only the flare's quarter-pipe fill is painted and it hugs the
    // weld corner, leaving the outer part transparent, so the bulge showed
    // through as a small square tab of bar-coloured pixels. Confirmed then
    // by controlled comparison, not by reading: with the bulge forced to
    // zero depth those rows read 132-139 (background) where they had read
    // ~606 (the bar's rim blue), nothing else in the frame changing.
    //
    // Insetting made the bulge's total FOOTPRINT match the panel
    // (275 + 2 x 3 = 281) at the cost of its visible FACE being short. The
    // fix is to remove the cause instead of paying for it: the popout
    // bulge's `buildOutline` call now passes `f: 0`, so nothing is drawn
    // outside the span at all and the face can be the panel's exact extent
    // with no overshoot to hide. See that call site for why dropping the
    // shoulder costs nothing here — the two `AttachedCorner` flares already
    // weld these corners.
    //
    // So: no inset. Any future change that restores a non-zero `f` on that
    // call MUST restore the `- Design.edgeBarFilletRadius` term with it;
    // the two are one decision.
    readonly property real _popoutBulgeHalf: Math.max(0,
        PopoutController.openExtent / 2)
    readonly property real _popoutBulgeCap: barWindow._weldSlabWidth / 2
    readonly property real _popoutBulgeCentre: Math.max(
        barWindow._popoutBulgeCap + barWindow._popoutBulgeHalf,
        Math.min(PopoutController.openCentre,
                 barWindow.height - barWindow._popoutBulgeCap - barWindow._popoutBulgeHalf))
    readonly property real _popoutBulgeXl: barWindow._popoutBulgeCentre - barWindow._popoutBulgeHalf
    readonly property real _popoutBulgeXr: barWindow._popoutBulgeCentre + barWindow._popoutBulgeHalf

    // A span that would not fit between the two caps at all collapses the
    // bulge rather than drawing a degenerate one — `buildOutline`'s own
    // note on why `bulge: false` is an explicit branch and not "pass b = 0":
    // a zero-width bulge still emits four zero-radius arcs and a backwards
    // face segment, which self-intersects silently.
    readonly property bool _popoutBulgeVisible: barWindow.popoutBulgeDepth > 0.01
        && barWindow._popoutBulgeXr > barWindow._popoutBulgeXl

    // One line per bulge SETTLE, on the shell's existing log idiom. It
    // logged every animated frame at first — 2042 lines in one session,
    // which buries the log the way the retired per-frame debug lines did.
    // The guard keeps the two states that carry information (fully grown,
    // fully retracted) and drops the ~60 intermediate frames between them.
    //
    // The bulge is a shape on a layer surface, so the only ways to observe
    // it are a screenshot or this; having both means a disagreement between
    // them is itself informative — and this line is what proved the bulge
    // was never painting at all, by emitting nothing rather than a wrong
    // value.
    onPopoutBulgeDepthChanged: if (barWindow.popoutBulgeDepth <= 0.01
        || barWindow.popoutBulgeDepth >= barWindow._popoutBulgeDepthOpen - 0.01)
        console.log("barbulge: depth=" + barWindow.popoutBulgeDepth.toFixed(1)
        + " visible=" + barWindow._popoutBulgeVisible
        + " weld=" + barWindow._continuousWeld
        + " anyOpen=" + PopoutController.anyOpen
        + " span=" + barWindow._popoutBulgeXl.toFixed(0) + ".." + barWindow._popoutBulgeXr.toFixed(0))

    // ── Publish the shelf back to the popout ────────────────────────────
    // The bar owns this arithmetic and the popout reads the finished
    // numbers — see PopoutController's own comment for why a second copy in
    // the popout would be the exact shape of every position bug this family
    // has shipped.
    //
    // `rootInset` walks out from the screen's right edge: the bar's own edge
    // margin, then the full slab, then however deep the bulge has grown this
    // frame. Measured against live values 6 + 52 + 14 = 72, and the slab's
    // left edge is at screen x 2502 (2560 - 58), so the bulge face lands at
    // 2488 — which is 2560 - 72. Consistent by construction, not by tuning.
    //
    // `_popoutBulgeCentre` is already SCREEN along-axis: the weld sets
    // `margins.top: 0`, so this surface's y origin is the screen's. That is
    // only true while welded, which is exactly when `rootAttached` is true —
    // so the value is never published out of a frame where it would be wrong.
    Binding {
        target: PopoutController
        property: "rootAttached"
        value: barWindow._continuousWeld
    }
    Binding {
        target: PopoutController
        property: "rootInset"
        // ── MEASURED, and both halves of this were wrong first time ──────
        //
        // (1) THE PANEL TOUCHES THE SLAB'S FLAT FACE, NOT THE BULGE'S.
        // The bulge is not a shelf the panel sits beside — it protrudes
        // OVER the panel, exactly as the top rail's bulge does over the
        // dashboard. Measured on the dashboard: its panel top sits at y=6,
        // the rail's flat run is 6 deep, and the bulge reaches y=20 while
        // open — so the bulge covers the drawer's top 14px. Adding the
        // bulge depth here pushed the popout a further 14px off the bar
        // and left the bulge standing in the gap between them.
        //
        // (2) MARGINS ARE MEASURED FROM THE USABLE AREA, NOT THE SCREEN
        // EDGE. `SectionPopout` sets `exclusionMode: ExclusionMode.Ignore`
        // and its own comment claims that makes its margins measure from
        // the true screen edge. It does not, on this build: with
        // `margins.right` at 72 the surface came back with its right edge
        // at 2438, and 2560 - 72 = 2488 while 2510 - 72 = 2438 — the bar's
        // own 50px reservation is subtracted first. That 50px is exactly
        // the gap the operator reported as "far away from the bar".
        //
        // So this walks from the usable boundary to the slab's flat face,
        // both taken from the bar's own live geometry rather than
        // reassembled from tokens.
        // The TOTAL reservation, not the exclusive zone alone. Hyprland's
        // reservation is `margins.<edge> + exclusiveZone` — this file's own
        // header says so and has shipped the double-count bug twice — so
        // the usable boundary is 6 + 44 = 50 in from the right, not 44.
        // Using `reservedZoneExtent` by itself put the popout 6px short of
        // the slab (measured right edge 2496 against a face at 2502).
        value: barWindow.screen
            ? (barWindow.screen.width - (Design.barEdgeMargin + barWindow.reservedZoneExtent))
              - (barWindow._barSurfaceX + barWindow._weldSlabX)
            : 0
    }
    Binding {
        target: PopoutController
        property: "rootCentre"
        value: barWindow._popoutBulgeCentre
    }

    // A single rounded-rect fill path — GradientBorder.qml's own
    // `_roundedRect` reasoning applies verbatim (no `PathRectangle` in
    // this Qt build's QtQuick/Shapes), simplified to one uniform radius
    // since both the slab and its core are pills/near-pills, never
    // per-corner radii.
    function _weldRoundedRect(w, h, r) {
        var rr = Math.max(0, Math.min(r, Math.min(w, h) / 2));
        var p = "M " + rr + " 0";
        p += " L " + (w - rr) + " 0";
        if (rr > 0)
            p += " A " + rr + " " + rr + " 0 0 1 " + w + " " + rr;
        p += " L " + w + " " + (h - rr);
        if (rr > 0)
            p += " A " + rr + " " + rr + " 0 0 1 " + (w - rr) + " " + h;
        p += " L " + rr + " " + h;
        if (rr > 0)
            p += " A " + rr + " " + rr + " 0 0 1 0 " + (h - rr);
        p += " L 0 " + rr;
        if (rr > 0)
            p += " A " + rr + " " + rr + " 0 0 1 " + rr + " 0";
        return p + " Z";
    }

    // ── The weld stub's outline, WITH its corner flare (quick task
    //    260825-ore) ───────────────────────────────────────────────────
    // Was a bare four-point rectangle on each stub. Measured on the live
    // Continuous bar (grim + raw per-pixel dump, the operator's standing
    // rule for any visual claim): at y=5 material ran left from x=2543, at
    // y=6 it collapsed to x=2510. That step was the rail's underside
    // terminating in a hard kink against the slab's pill cap — the joint
    // Caelestia's frame does not have anywhere (`ContentWindow.qml` builds
    // the whole border as ONE SDF `BlobInvertedRect`, so its 10px border
    // and its bar share a single outline through one 25px corner —
    // `borderconfig.hpp`: thickness 10, rounding 25, smoothing 20).
    //
    // ── WHY THE RADIUS IS DERIVED AND NOT TUNED ─────────────────────────
    // The slab is a pill, so its cap radius is `_weldSlabWidth / 2` and the
    // cap's WIDEST point — the one place its tangent is vertical — sits at
    // exactly that depth. The flare's arc is centred at
    // `(_weldSlabX - F, t + F)`, which puts:
    //
    //   near end  (_weldSlabX - F, t)      tangent HORIZONTAL -> continues
    //                                      the rail's underside
    //   far end   (_weldSlabX,     t + F)  tangent VERTICAL   -> continues
    //                                      the slab's flank
    //
    // and `Design.edgeBarWeldFlareRadius` is defined as
    // `capRadius - edgeBarThickness`, which is precisely the F that makes
    // that far end LAND ON the cap's widest point. So the two curves are
    // coincident AND tangent by construction, and the rail, the arc and the
    // slab read as one continuous outline. See that token's own comment for
    // what each other value would break.
    //
    // ── SWEEP FLAGS ARE DERIVED, NOT GUESSED ────────────────────────────
    // The trap `AttachedCorner.qml` and `edgebarpath.js` both spell out at
    // length: the wrong flag silently selects the OTHER valid centre for the
    // same endpoints and radius, rendering a CONVEX bulge that looks
    // deliberate and is wrong. Worked through `edgebarpath.js`'s own
    // `_arcCentre` (in domain — both arcs here are quarter circles):
    //
    //   top    (_weldSlabX, t+F) -> (_weldSlabX-F, t), centre wanted
    //          (_weldSlabX-F, t+F): x1p = y1p = F/2 -> sign -1 -> sweep 0
    //   bottom (_weldSlabX, 0)   -> (_weldSlabX-F, F), centre wanted
    //          (_weldSlabX-F, 0):   y1p = -F/2       -> sign +1 -> sweep 1
    //
    // The bottom is the top mirrored in depth, and a mirror flips
    // handedness — so it is RE-DERIVED above rather than reused, the same
    // discipline `edgebarpath.js` enforces by resolving every flag against
    // the centre its own axis demands.
    //
    // `flip` mirrors the depth axis for the bottom stub, so one
    // implementation serves both corners — never a second hand-authored
    // path string, which is the doctrine `edgebarpath.js` already
    // established for this same silhouette.
    function _weldStubPath(flip) {
        var t = Design.edgeBarThickness;
        var f = Design.edgeBarWeldFlareRadius;
        var w = barWindow._weldRunEnd;
        var sx = barWindow._weldSlabX;
        var h = t + f; // the stub box's own depth — the mirror axis
        function Y(v) {
            return flip ? h - v : v;
        }
        // Clockwise from the screen-edge corner. The outer edge (depth 0,
        // flush to the screen) is the full run; the flare is an excursion
        // of the INNER face alone, exactly like the strip's own bulge.
        var p = "M 0 " + Y(0);
        p += " L " + w + " " + Y(0);
        // Down the far side and back along the flare's deepest line. Both
        // lie beyond `_weldSlabX`, i.e. UNDER the slab (which is declared
        // after these stubs and therefore paints over them), so this pair
        // is never visible — it exists so the flare joins the slab with no
        // seam rather than butting against its edge.
        p += " L " + w + " " + Y(h);
        p += " L " + sx + " " + Y(h);
        // The concave fillet itself.
        p += " A " + f + " " + f + " 0 0 " + (flip ? 1 : 0) + " " + (sx - f) + " " + Y(t);
        // The rail's underside, on to the far end of the run.
        p += " L 0 " + Y(t);
        return p + " Z";
    }

    // 3. Two horizontal weld stubs — the 1860 -> 1892 run that closes the
    //    silhouette: strip end -> stub -> slab. Tucked under the slab's
    //    own rounded cap (the stub's x=0 sits at the widened surface's
    //    own left edge, and the slab starts exactly `edgeBarSideMargin +
    //    barColumnWidth / 2` in, so the stub's right end runs UNDER the
    //    cap rather than butting against it).
    Shape {
        id: weldStubTop
        visible: barWindow._continuousWeld
        x: 0
        y: 0
        // Deep enough to CONTAIN the flare, rather than relying on
        // QQuickShape rendering outside its own item rect (it does — see
        // AttachedCorner.qml's rim note — but a box that matches the
        // geometry is what makes the path below readable).
        width: barWindow._weldRunEnd
        height: Design.edgeBarThickness + Design.edgeBarWeldFlareRadius
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: barWindow._stripGradX1
                y1: 0
                x2: barWindow._stripGradX1 + barWindow._stripPeriod
                y2: 0
                spread: ShapeGradient.RepeatSpread
                GradientStop {
                    position: 0.0
                    color: Colours.primary
                }
                GradientStop {
                    position: 0.33
                    color: Colours.secondary
                }
                GradientStop {
                    position: 0.66
                    color: Colours.tertiary
                }
                GradientStop {
                    position: 1.0
                    color: Colours.primary
                }
            }
            PathSvg {
                path: barWindow._weldStubPath(false)
            }
        }
    }
    Shape {
        id: weldStubBottom
        visible: barWindow._continuousWeld
        x: 0
        // Moved UP by the flare depth (and grown by it), so the box still
        // ends flush with the screen edge while containing the flare — the
        // mirror of the top stub, whose `y` stays 0 and which grows
        // downward instead.
        y: Math.max(0, barWindow.height - Design.edgeBarThickness - Design.edgeBarWeldFlareRadius)
        width: barWindow._weldRunEnd
        height: Design.edgeBarThickness + Design.edgeBarWeldFlareRadius
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: barWindow._stripGradX1
                y1: 0
                x2: barWindow._stripGradX1 + barWindow._stripPeriod
                y2: 0
                spread: ShapeGradient.RepeatSpread
                GradientStop {
                    position: 0.0
                    color: Colours.primary
                }
                GradientStop {
                    position: 0.33
                    color: Colours.secondary
                }
                GradientStop {
                    position: 0.66
                    color: Colours.tertiary
                }
                GradientStop {
                    position: 1.0
                    color: Colours.primary
                }
            }
            PathSvg {
                path: barWindow._weldStubPath(true)
            }
        }
    }
    // 1. The full-height slab — the bar's own body, painted in the rail's
    //    own vocabulary continuing through it (`rect{x:BAR.x, y:0, w:44,
    //    h:H, rx:22}` in the study).
    Shape {
        id: weldSlab
        visible: barWindow._continuousWeld
        x: barWindow._weldSlabX
        y: 0
        width: barWindow._weldSlabWidth
        height: barWindow.height
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0
                y1: GradientPhase.phase * Math.max(1, weldSlab.height)
                x2: 0
                y2: GradientPhase.phase * Math.max(1, weldSlab.height) + Math.max(1, weldSlab.height)
                spread: ShapeGradient.RepeatSpread
                GradientStop {
                    position: 0.0
                    color: Colours.primary
                }
                GradientStop {
                    position: 0.33
                    color: Colours.secondary
                }
                GradientStop {
                    position: 0.66
                    color: Colours.tertiary
                }
                GradientStop {
                    position: 1.0
                    color: Colours.primary
                }
            }
            PathSvg {
                // Was `_weldRoundedRect(w, h, w/2)`. Same shape when no
                // popout is open — verified before the switch, identical
                // bbox and identical geometry, the only difference being
                // that each cap is drawn as two quarter arcs (which is what
                // keeps every arc inside `_arcCentre`'s quarter-circle
                // domain — see edgebarpath.js's own domain note).
                //
                // `flip: true` because the slab's OUTER edge is its right
                // side, flush to the screen, and its INNER face is the left
                // one the bulge protrudes from — the mirror case `Y()`
                // already implements. `re == t / 2` is the pill-cap
                // precondition the builder states, and it holds exactly
                // here: 26 == 52 / 2.
                path: EdgeBarPath.buildOutline({
                    t: weldSlab.width,
                    b: barWindow.popoutBulgeDepth,
                    re: weldSlab.width / 2,
                    // ── NO SHOULDER ON THIS BULGE (quick task 260825-t6j)
                    // `f: 0`, not `Design.edgeBarFilletRadius`, and this is
                    // the one call that differs — the rails and the static
                    // centre bulge keep the token.
                    //
                    // The shoulder is what forced this bulge to be narrower
                    // than the panel it roots. `buildOutline` draws each
                    // concave shoulder OUTSIDE the span it is handed (the
                    // flat run travels to `xr + f` before filleting back to
                    // `xr`), so a span at the panel's extent overshot it by
                    // `f` at both ends, and in that band the flare's fill
                    // does not reach — the bulge showed through as a square
                    // tab of bar-coloured pixels. Round 4 of 260825-pyf paid
                    // for that by insetting the span, which made the total
                    // footprint match the panel but left the VISIBLE face 6px
                    // short. That shortfall is what the operator reported.
                    //
                    // With no shoulder there is nothing drawn outside the
                    // span at all, so the face can be the panel's exact
                    // extent AND nothing overshoots it. The concave blend is
                    // not lost: the popout's two `AttachedCorner` flares weld
                    // precisely these corners — that is what they are for —
                    // and a clean butt at the panel's edge is the joint their
                    // quarter-pipes are built to sweep into.
                    //
                    // CHECKED, not assumed: `_arcCentre` is pure midpoint
                    // arithmetic with no division, so coincident endpoints
                    // return that point and `_shoulderSweep` matches it
                    // exactly — no NaN and no wrong flag. `A 0 0 ...` with
                    // identical start and end is omitted per the SVG arc
                    // spec rather than being degenerate. And Design's
                    // `fillet + cornerRadius <= bulgeExtra` invariant still
                    // holds trivially: 0 + 1 <= 14 at the open depth.
                    f: 0,
                    rc: Design.edgeBarBulgeCornerRadius,
                    along: weldSlab.height,
                    alongStart: 0,
                    xl: barWindow._popoutBulgeXl,
                    xr: barWindow._popoutBulgeXr,
                    bulge: barWindow._popoutBulgeVisible,
                    surfaceDepth: weldSlab.width,
                    flip: true,
                    axis: "vertical"
                })
            }
        }
    }

    // 2. The inset core — `rect{x:BAR.x+4, y:22, w:36, h:H-44, rx:18,
    //    fill:surface}` in the study. `Colours.surface` assigned straight
    //    to `color:` — never `Qt.rgba(Colours.surface.r, ...)`, since the
    //    roles are `property string`, not colour-typed, and that
    //    silently resolves to black.
    Rectangle {
        visible: barWindow._continuousWeld
        x: weldSlab.x + Design.edgeBarWeldRim
        // The cap must be AT LEAST as deep as the rail it swallows, which
        // is why this is not the plain rim. The weld run is
        // `edgeBarThickness` deep and is drawn UNDER the slab so the slab
        // hides where the horizontal run becomes the vertical body. At a
        // uniform 4px inset the core's own rounded cap rises into those
        // same rows and punches a hole straight through the run — measured
        // as an 8px dark bite at y=4 dead on the bar's centre line, which
        // is exactly where the joint is supposed to be solid.
        y: barWindow._weldCapDepth
        width: weldSlab.width - 2 * Design.edgeBarWeldRim
        height: Math.max(0, barWindow.height - 2 * barWindow._weldCapDepth)
        radius: (weldSlab.width - 2 * Design.edgeBarWeldRim) / 2
        color: Colours.surface
    }


    Item {
        id: barContent
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        // Confined to the slab's core when welded: the decoration and the
        // content must not share pixels. Round 1 let them, and the first
        // and last widgets rendered their glyphs on the gradient.
        anchors.rightMargin: barWindow._continuousWeld ? Design.edgeBarWeldRim : 0
        anchors.topMargin: barWindow._continuousWeld ? barWindow._weldCapDepth : 0
        anchors.bottomMargin: barWindow._continuousWeld ? barWindow._weldCapDepth : 0
        // NEVER `: undefined` here. `vertical` is FALSE at construction
        // (BarEntryModel.isVertical settles later), so an undefined branch
        // is what QML actually evaluates first — and assigning undefined to
        // a real-typed property DESTROYS the binding rather than deferring
        // it. `width` then stays 0 forever, the vertical flip never
        // re-evaluates it, and the zone children (which position off
        // `(parent.width - width) / 2`) resolve against a zero-width parent
        // and clip to a sliver. Measured: barContent w=0, x=76, content
        // visible only across 2532-2553 of a 2510-2554 column. Right-anchor
        // plus a real width in BOTH branches has no undefined to trip over.
        width: barWindow.vertical ? Design.barColumnWidth : barWindow.width

        // ── Rendering the three-state model (Phase 18 Plan 15, QBAR-07)
        //    — boolean visibility plus a token-driven slide-and-fade.
        //    Precision contract: there is no fractional visibility
        //    anywhere on this path — opacity is a plain 0/1 boolean
        //    ternary, and the only real-valued quantities anywhere below
        //    are the animation durations/offsets, both token-sourced. ───
        opacity: barWindow.barRendered ? 1 : 0
        transform: Translate {
            id: hideTranslate
            x: barWindow.hiddenTranslateX
            y: barWindow.hiddenTranslateY

            // The duration/easing ternary is read at the MOMENT each
            // Behavior's animation starts, when `barRendered` already
            // holds its new value — so a reveal takes the standard
            // register and a re-hide takes the emphasized-out register
            // from one Behavior per property, never from two competing
            // animations. Same quick-to-leave asymmetry this whole shell
            // already encodes numerically elsewhere.
            Behavior on x {
                enabled: Motion.motionEnabled
                NumberAnimation {
                    duration: barWindow.barRendered ? Motion.spatialMoveDuration : Motion.spatialOutDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: barWindow.barRendered ? Motion.spatialMoveEasing : Motion.spatialOutEasing
                }
            }
            Behavior on y {
                enabled: Motion.motionEnabled
                NumberAnimation {
                    duration: barWindow.barRendered ? Motion.spatialMoveDuration : Motion.spatialOutDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: barWindow.barRendered ? Motion.spatialMoveEasing : Motion.spatialOutEasing
                }
            }
        }
        Behavior on opacity {
            enabled: Motion.motionEnabled
            NumberAnimation {
                id: barFadeAnim
                duration: barWindow.barRendered ? Motion.standardDuration : Motion.emphasizedOutDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: barWindow.barRendered ? Motion.standardEasing : Motion.emphasizedOutEasing
            }
        }

        // Phase 18 Plan 16 (QBAR-08) — the bar's half of the combined
        // hover region; the hot zone (modules/bar/HotZone.qml) is the
        // other half. One report through the reveal singleton's single
        // entry point; nothing else in this file changes.
        HoverHandler {
            id: barHoverHandler
            onHoveredChanged: BarReveal.reportHover("bar", barHoverHandler.hovered)
        }

        // Three zone containers exist in BOTH orientations; only which
        // capsules land in each differs. Each is a Grid with the same
        // single-positioner axis binding BarCapsule uses internally.
        //
        // POSITIONED BY EXPLICIT x/y, NOT BY CONDITIONAL ANCHORS (2026-08-12).
        // Each zone used to carry four anchor bindings that switched by
        // orientation, clearing the unused pair with `undefined`. That idiom
        // does NOT reliably clear an anchor line from inside a binding, and the
        // consequence was measurable: with `verticalCenter` still bound in
        // vertical, pairing it with `top` or `bottom` makes Qt DERIVE the
        // height. startZone came out top=0 + verticalCenter=710 -> height
        // 2*710 = 1420; endZone came out bottom=1420 + verticalCenter=710 ->
        // height 1420 at y=0. Both grids therefore spanned the whole column and
        // both packed their content at the top, so endZone's capsules rendered
        // OVER startZone's instead of at the bottom, and the bar looked
        // top-crammed with dead space below (measured via BARPROBE: zone:start
        // h=1420 ih=624, zone:end h=1420 ih=404, both sceneY=0).
        //
        // Explicit x/y cannot half-apply. Height stays implicit, so each Grid is
        // exactly its content and the positioner does the rest.
        Grid {
            id: startZone
            spacing: Design.barCapsuleGap
            rows: barWindow.vertical ? -1 : 1
            columns: barWindow.vertical ? 1 : -1
            // start = left edge horizontally, top edge vertically.
            x: barWindow.vertical ? (parent.width - width) / 2 : 0
            y: barWindow.vertical ? 0 : (parent.height - height) / 2

            Repeater {
                model: BarEntryModel.capsulesForZone(BarEntryModel.zoneStart)
                delegate: Loader {
                    required property var modelData
                    sourceComponent: barWindow.componentFor(modelData.id)
                }
            }
        }

        Grid {
            id: centerZone
            spacing: Design.barCapsuleGap
            rows: barWindow.vertical ? -1 : 1
            columns: barWindow.vertical ? 1 : -1
            // center = the middle on the laid-out axis, in both orientations.
            // (Empty in vertical by UI-SPEC's no-centre-banding rule, but the
            // container still exists and still positions correctly if used.)
            x: (parent.width - width) / 2
            // Centred BETWEEN the other two zones, not on the whole bar. MEASURED
            // 2026-08-12 once workspaces was centre-banded: centring on the bar put
            // this zone at y=490-930 while endZone starts at 922, so idleInhibitor
            // (894-930) overlapped mediaConnectivity (922-1166) by 8px. Centring in
            // the gap the other two leave cannot collide as long as that gap is big
            // enough; if it ever is not, this clamps to just below startZone rather
            // than drifting upward into it.
            y: barWindow.vertical
                ? Math.max(startZone.y + startZone.height,
                           startZone.y + startZone.height
                           + ((endZone.y - (startZone.y + startZone.height)) - height) / 2)
                : (parent.height - height) / 2

            Repeater {
                model: BarEntryModel.capsulesForZone(BarEntryModel.zoneCenter)
                delegate: Loader {
                    required property var modelData
                    sourceComponent: barWindow.componentFor(modelData.id)
                }
            }
        }

        Grid {
            id: endZone
            spacing: Design.barCapsuleGap
            rows: barWindow.vertical ? -1 : 1
            columns: barWindow.vertical ? 1 : -1
            // end = right edge horizontally, bottom edge vertically.
            x: barWindow.vertical ? (parent.width - width) / 2 : (parent.width - width)
            y: barWindow.vertical ? (parent.height - height) : (parent.height - height) / 2

            // The Repeater is what makes render order equal declaration
            // order and therefore stable — the ordering contract in
            // must_haves.
            Repeater {
                model: BarEntryModel.capsulesForZone(BarEntryModel.zoneEnd)
                delegate: Loader {
                    required property var modelData
                    sourceComponent: barWindow.componentFor(modelData.id)
                }
            }
        }
    }
}
