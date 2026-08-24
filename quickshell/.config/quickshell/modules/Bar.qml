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
        width: barWindow._weldRunEnd
        height: Design.edgeBarThickness
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
                path: "M 0 0 L " + weldStubTop.width + " 0 L " + weldStubTop.width + " " + weldStubTop.height + " L 0 " + weldStubTop.height + " Z"
            }
        }
    }
    Shape {
        id: weldStubBottom
        visible: barWindow._continuousWeld
        x: 0
        y: Math.max(0, barWindow.height - Design.edgeBarThickness)
        width: barWindow._weldRunEnd
        height: Design.edgeBarThickness
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
                path: "M 0 0 L " + weldStubBottom.width + " 0 L " + weldStubBottom.width + " " + weldStubBottom.height + " L 0 " + weldStubBottom.height + " Z"
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
                path: barWindow._weldRoundedRect(weldSlab.width, weldSlab.height, weldSlab.width / 2)
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
