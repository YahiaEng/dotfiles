// Dashboard.qml — the dashboard drawer's tracer surface (Phase 14 Plan 01,
// DASH-01/DASH-08), now the pager host (Phase 14 Plan 03, DASH-02). This is
// the whole "Super+D summons the drawer" path's production surface, not a
// prototype: the PanelWindow this file creates is the one plans
// 14-04..14-09 build their tab content inside, `quickshell-dashboard`
// is the namespace Phases 15/16 inherit by naming their own surfaces
// `quickshell-<surface>` (D-42), and the constants declared on this window
// root are read by every later widget rather than re-declared.
//
// Layer posture, focus mechanics and dismiss wiring are reused VERBATIM from
// ScreencopyProbe.qml/Probe.qml's QS-02-proven combination (WlrKeyboardFocus.
// OnDemand + HyprlandFocusGrab bound to this window) — this closes D-12's
// named research item with a live result, not a prediction. Single instance,
// no per-screen `Variants` fan-out: QS-03's per-screen mounting gap is an
// accepted permanent limitation on this quickshell 0.3.0-2 build (D-13,
// PROJECT.md), and D-14 does not ask for a multi-monitor summon here.
//
// Geometry (D-01/D-02/D-03/D-04 — D-02/D-04 SUPERSEDED 2026-07-29 at this
// plan's render gate, see 14-03-SUMMARY.md's Deviations): only anchors.top
// is set, so the compositor centres the window horizontally; exclusiveZone 0
// + ExclusionMode.Normal mean the drawer reserves nothing but still respects
// the bar's own reservation, landing flush below it with zero per-layout
// offset logic.
//
// D-02/D-04 originally locked one uniform 850x860 frame identical on every
// tab. The render gate's human sign-off rejected that outright: the user
// asked for a wider, shorter baseline AND genuine per-tab dynamic
// proportions, following the Caelestia dashboard's content-driven sizing
// convention (D-02's own text already flagged widening as "a one-constant
// change" — this goes further and makes BOTH axes a function of whichever
// tab is current, animated on a resize whenever the tab changes). See the
// `drawerWidth`/`drawerHeight` block below for the mechanism.
//
// ── Pager (Plan 14-03, DASH-02, D-15..D-19) ────────────────────────────
// A header `TabBar` synced one-way FROM a four-pane `SwipeView` — the
// pager is the single source of truth for which tab is showing (D-16);
// every header visual reads `pager.currentIndex`/`swipeProgress`, never a
// `checked` state the header holds independently. `QtQuick.Controls`
// (Basic style) is imported, deliberately NOT
// `QtQuick.Controls.Material` — Qt's Material palette is not
// `Colours.qml`, and this drawer's whole premise is that `Colours.qml` is
// the only colour source, so every pager/header visual below is
// overridden with a token-driven item instead of Qt's stock styling.
// `import "dashboard"` resolves the nine types Plan 14-03's Task 1
// registered in modules/dashboard/qmldir.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "dashboard"

PanelWindow {
    id: dashboardWindow

    // Emitted on every dismissal path (Super+D toggle, Esc, click-outside,
    // focus-loss). shell.qml's dashboardLoader listens for this to
    // deactivate itself, which destroys the wl_surface (D-14) rather than
    // merely hiding it.
    signal dismissRequested()
    // 15-07 — the relay-up half of the tile chevron's summon path. The
    // drawer inspects nothing and decides nothing here; it only forwards
    // what dashboardTabLoader's own onPanelRequested handler re-emits.
    // shell.qml's handler on this Dashboard {} instance is the ONLY place
    // this becomes a summon (see <binding_corrections> / Flagged
    // Assumption 2).
    signal panelRequested(string name)

    // ── Layer posture: FULL-SCREEN surface, panel positioned in QML ─────
    // (quick task 260818-nwo — the weather-tab jitter root cause.)
    //
    // This used to be `anchors.top: true` alone, which makes the compositor
    // horizontally centre the surface. That is what caused the jitter, and
    // it took three attempts to find because the first two looked inside the
    // tab: with a compositor-centred surface, ANY width change drags the
    // whole surface sideways, and every pixel painted inside it goes along.
    //
    // Measured on the live session (7210 samples of `hyprctl layers`,
    // committed as drawer-geometry-trace.txt): Performance is 1040 wide and
    // Weather is 760, so switching between them moved the surface
    // x = 875 -> 735. That is exactly 140px = the 280px width delta halved,
    // confirming compositor centring rather than anything in the QML. Worse,
    // the centring is not applied atomically: the invariant `2x + w` (which
    // must equal the 2510px available span) held at rest but swung
    // 2416..2599 mid-animation, with the per-frame off-centre error
    // oscillating +5.5, 0, +11, +9.5, +8, -0.5, ... — a back-and-forth
    // wobble on top of the slide. That oscillation IS the reported jitter,
    // which is why it only ever appeared on the Performance<->Weather pair:
    // every other tab pair shares the 760 floor width, so the surface never
    // resizes and never moves.
    //
    // The fix is the reference-shell convention (research/FEATURES.md:97 —
    // end-4 uses "a true full-screen overlay, PanelWindow spanning the
    // output, not an inline popout") and is already shipped once in this
    // repo: PowerMenu.qml:184-207. The surface now spans the output and
    // NEVER resizes, so the compositor has nothing to re-centre; the drawer
    // rectangle is a plain QML Item (`panel` below) that carries the size
    // animation and is centred by QML, which moves position and size in the
    // same frame.
    //
    // `exclusionMode` stays Normal (NOT PowerMenu's Ignore): this drawer
    // must still sit clear of the bar's reserved zone, and Normal is what
    // makes the compositor hand back the 2510px span the panel centres in —
    // so the panel's resting x is unchanged at 875.
    // ── REVISION (same task, after the first full-screen attempt) ───────
    // The first cut anchored all four edges. That fixed the jitter but cost
    // three things, all reported back immediately:
    //   1. `animation = "slide"` (windowrules.lua) slid the drawer up from
    //      the BOTTOM. A slide needs an unambiguous anchored edge to slide
    //      from; with all four anchored there is none, so the compositor
    //      picked one — not the top-edge dropdown this drawer is supposed to
    //      have.
    //   2. The surface grew from 760x439 to 2510x1430, so the compositor was
    //      blurring and compositing a full-screen surface every frame while
    //      the drawer was open. Worst on the heaviest tab.
    //   3. (Separately: nothing clipped the pager any more — see `panel`.)
    //
    // Anchoring top+left+right instead keeps the property that actually
    // fixed the jitter — the surface's WIDTH never changes, so the compositor
    // never re-centres it — while giving back both of the above:
    //   * a real top edge to slide from, so "slide" is a dropdown again;
    //   * a surface only as tall as the drawer, not the whole screen.
    // The height still animates, which is harmless: `anchors.top` pins the
    // top edge, so growth extends downward and nothing moves sideways or up.
    // ── REVISION 2 — the surface must never resize AT ALL ───────────────
    // Revision 1 anchored top+left+right so `slide` would have a top edge to
    // drop from. Width stayed fixed (verified: w=2510, x=0 on every tab), so
    // the compositor never re-centred — but the jitter came straight back,
    // because HEIGHT then animated, and an animating layer surface is
    // re-configured, re-buffered and re-rendered every single frame.
    //
    // Measured: revision 1 gave w=2510 constant with h=502 vs 439 per tab —
    // so the returning jitter was NOT re-centring (x never moved). The one
    // property the jitter-free version had and revision 1 gave up is simply:
    // the surface never changed size on any axis.
    //
    // So: all four edges, fixed extent, zero resizes for the surface's whole
    // lifetime. EVERY motion — the drop-down entrance and the per-tab resize
    // — happens inside QML, on `panel`, where it is a scene-graph transform
    // rather than a Wayland reconfigure. That is what the reference shells do
    // and what PowerMenu.qml already does here.
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    // ── Top margin (render-gate feedback 2026-07-29) ────────────────────
    // Without this, the drawer's surface sits flush at y = the bar's
    // reserved-zone bottom (0px gap) — measured directly via
    // `hyprctl -j layers` at exactly the same y as
    // the retired notification daemon's own LAYER surface. But that
    // surface was a full-screen transparent canvas; its actual VISIBLE
    // panel was inset from it by its own `control-center-margin-top: 10`,
    // landing that panel flush with where a
    // REAL tiled Hyprland window starts (`hyprland.lua`'s
    // `general.gaps_out: 10` inset from the reserved zone) — not flush
    // with the bar itself. A drawer sitting at the bar's exact edge (this
    // window's old behaviour) is therefore 10px CLOSER to the bar than
    // either that daemon's own panel or a real tiled window ever is — it
    // visually occupies the bare gap strip between the bar and where
    // window content actually begins, reading as "dropped in an awkward
    // place between the bar and the window area" rather than "dropping
    // from the top of the window area" the way that daemon's control
    // centre did. Mirrors its `control-center-margin-top` value
    // directly (both numbers are hand-authored literals in their own
    // component's config, not a shared token — the same relationship that
    // daemon's JSON had to `hyprland.lua`'s gaps_out) so the drawer's top
    // edge lines up with where a real window starts,
    // while `exclusiveZone: 0`/`ExclusionMode.Normal` below still keep
    // the bar's own reserved zone completely untouched — this is a margin
    // INSIDE the space Hyprland already leaves free for layer-shell
    // surfaces, not a change to what any surface reserves.
    readonly property int drawerTopMargin: 10
    margins.top: dashboardWindow.drawerTopMargin

    // ── Dynamic per-tab geometry (D-02/D-04 SUPERSEDED, render-gate
    //    checkpoint feedback 2026-07-29) ───────────────────────────────────
    // `drawerMinWidth`/`drawerMinHeight` are floors, not targets: the
    // header's four icon+label tabs need a minimum width regardless of tab
    // content, and the frame should never collapse below a usable minimum
    // even if some future tab's content turns out tiny.
    readonly property int drawerMinWidth: 760
    readonly property int drawerMinHeight: 420

    // Reads whichever tab's Loader is currently active — RESEARCH Pattern 4
    // guarantees exactly one of the four ever holds a live `item` at a time,
    // so there is no ambiguity about which implicit size is "the" active
    // one. Falls back to the floor before the very first Loader has
    // settled. This is metadata-only: it never touches a tab item's own
    // actual rendered geometry — every tab still fills whatever space its
    // Loader gives it via anchors.fill: parent (unchanged from Task 2), so
    // content always matches the frame exactly, including mid-resize.
    // `implicitWidth`/`implicitHeight` on the four tab types is the D-04
    // prohibition deliberately reversed: 14-04..14-07 will replace today's
    // placeholder numbers with a value derived from each tab's own real
    // layout once built.
    readonly property real activeContentWidth: {
        if (dashboardTabLoader.item) return dashboardTabLoader.item.implicitWidth;
        if (mediaTabLoader.item) return mediaTabLoader.item.implicitWidth;
        if (performanceTabLoader.item) return performanceTabLoader.item.implicitWidth;
        if (weatherTabLoader.item) return weatherTabLoader.item.implicitWidth;
        return drawerMinWidth;
    }
    readonly property real activeContentHeight: {
        if (dashboardTabLoader.item) return dashboardTabLoader.item.implicitHeight;
        if (mediaTabLoader.item) return mediaTabLoader.item.implicitHeight;
        if (performanceTabLoader.item) return performanceTabLoader.item.implicitHeight;
        if (weatherTabLoader.item) return weatherTabLoader.item.implicitHeight;
        return drawerMinHeight - tabBarHeight;
    }

    // `content`'s anchors.margins (spacingLg on all four sides) plus the
    // fixed tabBarHeight header are added back on top of the active tab's
    // own desired content size to get the WHOLE window's target size — this
    // is exactly why the pager (anchored top: header.bottom, bottom:
    // parent.bottom, inside content) always ends up exactly
    // activeContentHeight tall: window height minus 2*spacingLg minus
    // tabBarHeight equals activeContentHeight by construction, and every
    // header-derived measurement (tab button width, indicator geometry)
    // already reads off `header.width` reactively, so nothing downstream
    // needed a change to follow this resize.
    readonly property real drawerWidth: Math.max(drawerMinWidth, activeContentWidth + spacingLg * 2)
    readonly property real drawerHeight: Math.max(drawerMinHeight, tabBarHeight + activeContentHeight + spacingLg * 2)
    // No implicitWidth/implicitHeight: the surface takes its extent from the
    // four anchors and never resizes. `panel` carries both size animations.

    // The width a tab's own root WILL have once the frame settles, published
    // for tabs that must lay their content out at the destination size rather
    // than at whatever the frame happens to be mid-animation.
    //
    // `drawerWidth` is the un-animated TARGET (`implicitWidth` is the animated
    // follower of it), and `activeContentWidth` switches to the incoming tab's
    // hint the instant `currentIndex` changes — so this value is already
    // correct on the transition's first frame. The `- spacingLg * 2` mirrors
    // the `content` item's own margins, which is the single inset between this
    // window and the pager the tab loaders sit in.
    //
    // Added for the Weather tab's entrance jitter; see WeatherTab.qml's
    // `contentColumn` note for the failure it fixes. Any tab may opt in, but
    // only WeatherTab does today — a tab that ignores it keeps the previous
    // fill-the-animating-frame behaviour unchanged.
    readonly property real settledPaneWidth: drawerWidth - spacingLg * 2

    // The height counterpart, added by quick task 260818-nwo — the axis
    // WeatherTab.qml's own entrance-jitter note deliberately left tracking
    // the animating frame ("changing one axis at a time keeps this
    // reviewable"). Same derivation as `settledPaneWidth`, from the same
    // un-animated target: the pager sits below the fixed-height header and
    // inside `content`'s margins, so this is exactly the height a tab's root
    // will have once the frame settles.
    //
    // No binding loop: every band in WeatherTab self-sizes from its own
    // content (`heroInner.height`, `hourColumnsRow.height`,
    // `dayColumnsRow.height`, `root.separatorHeight`) and none reads
    // `parent.height`, so a tab's `implicitHeight` — which feeds
    // `activeContentHeight` -> `drawerHeight` -> this value — never depends
    // on the height handed back to it. Verified by reading every band's
    // height binding before adding this, not assumed from the width case.
    readonly property real settledPaneHeight: drawerHeight - tabBarHeight - spacingLg * 2

    // Animated on the SAME token pair, triggered by the SAME event
    // (pager.currentIndex changing), as the pager's own highlightMoveDuration
    // content transition below — so the frame and the content it holds
    // settle together rather than reading as two separate motions. Respects
    // the motion-scale axis exactly like every other Behavior in this file
    // (off/reduced/normal/lively via Motion.motionEnabled/standardDuration/
    // standardEasing).

    // Reserve nothing (D-03/D-08/D-43): the drawer holds zero exclusive
    // zone on any edge the bar reserves, but ExclusionMode.Normal means it
    // still respects what the bar already reserves, so the compositor
    // places the drawer flush below the bar automatically.
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Normal

    // ── Layer posture (D-42/D-43) — the namespace scheme Phases 15/16
    //    inherit by naming their own surfaces `quickshell-<surface>`. ─────
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-dashboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Only the background Rectangle below paints — the window itself stays
    // transparent so the bottom-only rounding is visible (D-03/D-07).
    color: "transparent"

    // ── Drawer-family constants (D-06 8dp spacing scale + 14-UI-SPEC.md's
    //    four-role type scale), declared exactly once here — plans
    //    14-03..14-08 read them off `dashboardWindow` instead of
    //    re-declaring their own. ──────────────────────────────────────────
    readonly property int spacingXs: Design.spacingXs
    readonly property int spacingSm: Design.spacingSm
    readonly property int spacingMd: Design.spacingMd
    readonly property int spacingLg: Design.spacingLg
    readonly property int spacingXl: Design.spacingXl

    readonly property int fontDisplay: Design.fontDisplay
    readonly property int fontHeading: Design.fontHeading
    readonly property int fontBody: Design.fontBody
    readonly property int fontLabel: Design.fontLabel
    readonly property int weightDisplay: Design.weightDisplay
    readonly property int weightEmphasis: Design.weightEmphasis
    readonly property int weightBody: Design.weightBody
    readonly property real lineHeightTight: 1.2
    readonly property real lineHeightNormal: 1.5

    readonly property int cornerRadius: 28

    // DASH-10: Hyprland's own `general:border_size` (3 on this host, read via
    // `hyprctl getoption general:border_size`). Hyprland's border width has
    // no representation in the colour or motion pipelines, so unlike the
    // gradient's stops and period there is no token to read it from.
    //
    // 15-10 (G-15-1b): the home moved to `Design.borderWidth`, not restated
    // here. Phase 15's `PanelDialog.qml` — a second summonable-layer-surface
    // consumer — now needs this identical parity number for its own
    // GradientBorder instance; a bare literal in each of two files would be
    // two homes for one claim, not one. `Design.qml` is the one place both
    // this file (`import "dashboard"`) and `PanelDialog.qml` (`import "../"`)
    // can already read. If Hyprland's border_size changes, follow it there.
    readonly property int borderWidth: Design.borderWidth
    // REVISED 0.78 -> 0.38 (D-21-26, frost unification, measured
    // 2026-08-15/16). The UI-SPEC's own frost table names 0.5 as this
    // surface's "current fill", but that is the namespace's ignore_alpha
    // THRESHOLD (windowrules.lua's family-inherited floor before this
    // plan), not this constant — this file's own drawerSurfaceOpacity was
    // measured at 0.78 this session, a different value entirely. Lowered
    // in step with windowrules.lua's quickshell-dashboard ignore_alpha
    // (0.5 -> 0.2, that file's own comment) to the notification family's
    // own fill (BarRoles.notifSurface, 0.38) so the drawer reads at the
    // SAME frost strength as every other panel-class surface — 0.38
    // stays strictly above the new 0.2 cutoff, so blur is not silently
    // discarded (this file's own recorded failure mode, see the
    // `background` Rectangle's Behavior comment below and 21-CONTEXT.md's
    // D-21-26 constraint 1).
    readonly property real drawerSurfaceOpacity: 0.38
    readonly property color surfaceBase: Colours.surface

    // ── Pager & tab constants (D-15..D-19, Task 2) — declared beside the
    //    constants above so wave-3/wave-4 plans read them from one place.
    //    ─────────────────────────────────────────────────────────────────
    readonly property int tabCount: 4
    // D-15's fixed order: Dashboard, Media, Performance, Weather.
    readonly property int tabIndexDashboard: 0
    readonly property int tabIndexMedia: 1
    readonly property int tabIndexPerformance: 2
    readonly property int tabIndexWeather: 3
    // MD3 primary-tab height for an icon-plus-label tab.
    readonly property int tabBarHeight: 64
    // MD3 primary-tab active-indicator thickness.
    readonly property int tabIndicatorHeight: 3
    readonly property int iconSizeMd: Design.iconSizeMd
    // Exact installed family string per 14-02-SUMMARY.md's Material
    // Symbols Rounded registration.
    readonly property string symbolFontFamily: Design.symbolFontFamily

    // Continuous swipe position across the four tabs (0..tabCount-1) —
    // derived from pagerList's own contentX/width so it tracks a drag AND
    // an animated tap/arrow move for free, since both animate the same
    // contentX. This is what lets the header indicator track the drag
    // continuously instead of jumping on commit (D-16).
    readonly property real swipeProgress: {
        if (pagerList.width <= 0)
            return 0;
        var raw = pagerList.contentX / pagerList.width;
        return Math.max(0, Math.min(dashboardWindow.tabCount - 1, raw));
    }

    // ── Shell-root tab memory + shared backend contract (D-14) ──────────
    // Seeded once from shell.qml's own dashboardTabIndex on summon (an
    // assignment in Component.onCompleted below, never a binding, so a
    // user's swipe is never fought by the seed); tabSelected is emitted on
    // every change so shell.qml can write the index back for the NEXT
    // summon, since the LazyLoader destroys this surface on dismiss.
    property int initialTabIndex: 0
    readonly property alias currentTabIndex: pager.currentIndex
    signal tabSelected(int index)

    // ── D-21's entrance cascade (Phase 14 Plan 09) ──────────────────────
    // True for the surface's whole lifetime until consumed once — the
    // drawer is destroyed on dismiss (D-14), so this is re-created true on
    // every summon and the runner below consumes it exactly once. No
    // second guard keyed on tab index or elapsed time: this one flag,
    // cleared before any animation starts (Cascade.qml's own run()), is
    // the entire tab-switch fence.
    property bool cascadeArmed: true

    readonly property Cascade entranceCascade: Cascade {}

    // Wired off each pane's Loader.onLoaded below via Qt.callLater — NOT
    // read synchronously inside onLoaded itself. `pager`'s default
    // currentIndex is 0, so `dashboardTabLoader` (tab 0) always loads
    // synchronously FIRST, during the window's own initial construction,
    // BEFORE `Component.onCompleted` below reassigns `pager.currentIndex`
    // to the remembered `initialTabIndex` — a live-reproduced race: acting
    // inside `onLoaded` itself cascaded tab 0 even when the drawer reopened
    // on a different remembered tab. Deferring the actual read to the next
    // idle tick (`Qt.callLater`) lets `onCompleted`'s reassignment settle
    // first, so this function always inspects `pager.currentIndex` at
    // call time and reads whichever loader is active THEN — the pane
    // that is actually showing, exactly what D-21 asks the cascade to
    // animate. A later real tab switch also fires its own Loader's
    // onLoaded (deferred the same way), but by then `cascadeArmed` (and
    // the runner's own mirrored `armed`) is already false, so `run()` is
    // a no-op — the fence, not a second branch of it.
    function runCascadeForActivePane() {
        var item = null;
        if (pager.currentIndex === dashboardWindow.tabIndexDashboard)
            item = dashboardTabLoader.item;
        else if (pager.currentIndex === dashboardWindow.tabIndexMedia)
            item = mediaTabLoader.item;
        else if (pager.currentIndex === dashboardWindow.tabIndexPerformance)
            item = performanceTabLoader.item;
        else if (pager.currentIndex === dashboardWindow.tabIndexWeather)
            item = weatherTabLoader.item;

        if (!item || !item.cascadeBands)
            return;

        dashboardWindow.entranceCascade.tabIndex = pager.currentIndex;
        dashboardWindow.entranceCascade.bands = item.cascadeBands;
        dashboardWindow.entranceCascade.armed = dashboardWindow.cascadeArmed;
        dashboardWindow.entranceCascade.run();
        dashboardWindow.cascadeArmed = false;
    }

    // Shared instances mounted once at the shell root (shell.qml) and
    // passed in here — declaring them there (not in each wave-3 plan's own
    // file) is what leaves 14-05/14-07 with exactly one file each to touch
    // (see 14-03-PLAN.md's "Scope correction carried by this plan").
    property var mediaBackend: null
    property var weatherBackend: null
    // Round-3 render-gate correction (14-06, defect B): moved here from a
    // local instantiation below — see shell.qml's own `systemResourcesInstance`
    // for why. Same passed-in-property shape as `mediaBackend`/`weatherBackend`
    // immediately above.
    property var systemResources: null
    // 15-07 — the same passed-in-instance shape, threaded straight through
    // to DashboardTab's own toggle-footer. This file never reads any of
    // the three itself; it is the middle of the mount chain.
    property var audioBackend: null
    property var wifiBackend: null
    property var bluetoothBackend: null

    Component.onCompleted: pager.setCurrentIndex(dashboardWindow.initialTabIndex)

    HyprlandFocusGrab {
        id: grab
        windows: [ dashboardWindow ]
        active: true
        onCleared: dashboardWindow.dismissRequested()
    }

    // ── Dismiss scrim (quick task 260818-nwo) ───────────────────────────
    // Required by the full-screen surface above, and lifted straight from
    // PowerMenu.qml:59-70, which hit and documented this exact regression on
    // 2026-08-15: once the surface spans the output, a click "outside the
    // drawer" lands INSIDE this window, so HyprlandFocusGrab's onCleared —
    // which fires on a focus CHANGE — never sees it and the drawer stops
    // dismissing. An explicit full-surface MouseArea behind the panel closes
    // it deterministically. The grab above is kept for the different case of
    // focus genuinely moving to another surface.
    //
    // Transparent and unpainted: this is an input target only. The drawer is
    // deliberately scrim-less (D-08) and that is unchanged — nothing here
    // dims anything.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: dashboardWindow.dismissRequested()
    }

    // ── The drawer rectangle itself ─────────────────────────────────────
    // Everything that used to fill the window now fills THIS, which is the
    // only thing that resizes. Centred in QML rather than by the compositor,
    // so position and size always update in the same frame — the property
    // the compositor could not give us (see the layer-posture note above).
    Item {
        id: panel
        width: dashboardWindow.drawerWidth
        height: dashboardWindow.drawerHeight
        anchors.horizontalCenter: parent.horizontalCenter

        // ── Drop-down entrance, in QML (reported: Super+D slid up from the
        //    bottom) ────────────────────────────────────────────────────────
        // With a full-screen surface the compositor's own `slide` has no
        // unambiguous edge to slide from and picked the bottom. Rather than
        // fight it, the layer rule is now `animation = "fade"` — exactly what
        // the equally full-screen PowerMenu uses (windowrules.lua:579) — and
        // the directional motion is done here, where the edge is explicit.
        //
        // The drawer is created fresh by a LazyLoader on every summon (D-14),
        // so `Component.onCompleted` IS the open event; there is no reopen
        // case to reset.
        property bool opened: false
        y: opened ? 0 : -height
        opacity: opened ? 1 : 0
        Component.onCompleted: panel.opened = true

        Behavior on y {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.emphasizedInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasizedInEasing
            }
        }
        Behavior on opacity {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.emphasizedInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasizedInEasing
            }
        }

        // ── clip (reported: content appears outside the panel, then slides in)
        // The drawer rectangle used to BE the wl_surface, and a Wayland
        // surface physically cannot paint outside itself — so the pager's
        // off-screen pages were clipped for free, by the window system. A
        // plain Item has no such property: once the drawer became an Item
        // inside a larger surface, SwipeView's incoming page rendered outside
        // the drawer's bounds and was visible over the scrim before sliding
        // in. That reads as a bug because it is one; this restores the clip
        // the surface boundary used to provide implicitly.
        clip: true

        Behavior on width {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
        Behavior on height {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }

    // ── Background (D-03/D-07): the window's own footprint IS the drawer
    //    rectangle — bottom-only rounding, translucent over the compositor
    //    blur Task 2 turns on for this namespace, no scrim anywhere (D-08).
    Rectangle {
        id: background
        anchors.fill: parent
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: dashboardWindow.cornerRadius
        bottomRightRadius: dashboardWindow.cornerRadius
        color: Qt.rgba(dashboardWindow.surfaceBase.r, dashboardWindow.surfaceBase.g, dashboardWindow.surfaceBase.b, dashboardWindow.drawerSurfaceOpacity)

        // Probe.qml lines 229-240's exact shape — the Phase 12 theme-switch
        // crossfade reaches the drawer too. Only the seven allowed Motion.*
        // names may be read; motionScale/pairs are motion-lint CHECK A
        // dangling references on this build.
        Behavior on color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

    // DASH-10 — the animated gradient rim, matching Hyprland's own window
    // border so the drawer reads as part of the same desktop rather than as
    // a foreign panel. Declared AFTER `background` so it paints on top of the
    // surface, and BEFORE `content` so it never sits over the tab bar or a
    // tab's own controls (a rim painted above `content` would also intercept
    // nothing — it has no input handlers — but it would visually overlay the
    // header's edge, which is not what a window border does).
    //
    // Radii are handed across from the same properties `background` uses, so
    // the rim and the surface can never disagree about the drawer's shape.
    GradientBorder {
        anchors.fill: parent
        borderWidth: dashboardWindow.borderWidth
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: dashboardWindow.cornerRadius
        bottomRightRadius: dashboardWindow.cornerRadius
    }

    // One shared resource reader for PerformanceTab's dials (14-06) and
    // DashboardTab's resources strip (14-08).
    //
    // Round-3 render-gate correction (defect B, "warm cache across opens"):
    // this used to be instantiated HERE, gated on `dashboardWindow.visible`
    // — but this whole window is itself destroyed and rebuilt by shell.qml's
    // LazyLoader on every dismiss (D-14), so an instance mounted here can
    // never hold a "last known reading" across a close/reopen: there is no
    // surviving instance to hold it in. The reader now lives in shell.qml,
    // a sibling of `dashboardLoader` exactly like `MediaBackend`/
    // `WeatherBackend` already are (for the identical reason, stated there),
    // and is threaded in below as the `systemResources` property beside
    // `mediaBackend`/`weatherBackend` — same passed-in-instance shape, no
    // new pattern invented. `drawerOpen` still gates every timer/process in
    // `SystemResources.qml` itself, so D-36's "polling only while the
    // drawer is open" zero-idle doctrine is completely unaffected: only the
    // VALUES now survive dismissal, not the polling.
    //
    // The previous local id was deliberately `sharedSystemResources`, NOT
    // `systemResources` — both DashboardTab.qml and PerformanceTab.qml
    // declare their own `property var systemResources`, and a same-named
    // `systemResources: systemResources` binding below would resolve its RHS
    // to THAT tab's own not-yet-assigned property first (QML's innermost-
    // scope-wins lookup) rather than reaching out to an outer id — a silent
    // self-referencing no-op (live-reproduced once already: PerformanceTab's
    // `hasReader` read `false` forever until fixed). The same hazard applies
    // to `dashboardWindow.systemResources` below just as much as it would to
    // a same-named local id, which is why every reference below is written
    // fully qualified as `dashboardWindow.systemResources`, never a bare
    // `systemResources`.

    // ── Dismiss wiring (D-12/D-13) — Probe.qml/ScreencopyProbe.qml's
    //    existing, QS-02-proven combination reused verbatim: click-outside
    //    and focus-loss both land on the same signal, D-13's
    //    deprecated-blind coexistence rule with zero edits to walker or
    //    the (now-retired) GTK4 power-menu surface.

    // ── Content root (D-10 Esc dismiss, D-18 clamped arrows) ────────────
    Item {
        id: content
        anchors.fill: parent
        anchors.margins: dashboardWindow.spacingLg
        focus: true

        Keys.onEscapePressed: dashboardWindow.dismissRequested()

        // D-18: arrow keys are keyboard swipes — one spatial model for
        // both inputs — so they route through the same setCurrentIndex
        // the taps/drags do, clamped totally at both ends. At index 0 a
        // Left press and at index 3 a Right press change nothing and wrap
        // nothing.
        Keys.onLeftPressed: pager.setCurrentIndex(Math.max(0, pager.currentIndex - 1))
        Keys.onRightPressed: pager.setCurrentIndex(Math.min(dashboardWindow.tabCount - 1, pager.currentIndex + 1))

        // forceActiveFocus() is required for the key handlers above to
        // actually receive events under WlrKeyboardFocus.OnDemand.
        Component.onCompleted: content.forceActiveFocus()

        // ── Header row (D-16) — the tab bar + active indicator ─────────
        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: dashboardWindow.tabBarHeight

            // Fixed 4-entry model in D-15's order — labels stay short by
            // construction (UI-SPEC dismisses long-text handling for the
            // tab bar precisely because these are fixed and short).
            // Ligature names resolve through Material Symbols' glyph
            // lookup by text (D-28).
            ListModel {
                id: tabModel
                ListElement { label: "Dashboard"; symbol: "dashboard" }
                ListElement { label: "Media"; symbol: "music_note" }
                ListElement { label: "Performance"; symbol: "speed" }
                ListElement { label: "Weather"; symbol: "partly_cloudy_day" }
            }

            TabBar {
                id: tabBar
                anchors.fill: parent

                // Render-gate regression fix (checkpoint feedback
                // 2026-07-29): once the frame's width/height became per-tab
                // dynamic (see dashboardWindow's drawerWidth/drawerHeight
                // above), `header.width` ticks every animation frame during
                // a resize instead of staying a one-shot constant. Control's
                // own default `implicitWidth` (Math.max(...,
                // implicitContentWidth + padding)) reads back through this
                // Row's/TabButton's own implicit-size machinery, and now
                // that it re-evaluates every frame instead of once, Qt's
                // binding-loop detector trips on it — a warning that never
                // fired against the old static width. TabBar's implicitWidth
                // is not consumed anywhere (actual geometry always comes
                // from `anchors.fill: parent` above), so it is overridden
                // here with a direct, non-cyclical mirror of `header.width`
                // that never round-trips through the content machinery,
                // eliminating the loop without changing anything visible.
                implicitWidth: header.width
                implicitHeight: dashboardWindow.tabBarHeight

                // One-way sync target (D-16): this binding holds until a
                // TabButton click imperatively re-assigns currentIndex
                // (Container's own internal click handling) — the
                // Connections block below on `pager` re-asserts it on
                // every pager change so the flow stays one-way for the
                // surface's whole lifetime, not just until the first tap.
                currentIndex: pager.currentIndex

                background: Item {}

                // RESEARCH/plan-mandated override: a plain non-flickable
                // Row over control.contentModel, NOT the stock (Fusion
                // style, on this build) ListView-based contentItem. A
                // flickable header inside a horizontal pager is a second
                // horizontal drag surface competing with the pager for the
                // same gesture (the same collision class D-37 rejects for
                // the weather hour strip) — and empirically, leaving the
                // stock ListView-based contentItem in place while also
                // binding each button's own width explicitly produced a
                // genuine QML binding-loop warning (the ListView's own
                // item-sizing fighting this file's width binding), not
                // merely a cosmetic implicitWidth churn. Overriding
                // contentItem removes both the gesture collision and the
                // loop in one move. This also removes the stock header's
                // own hardcoded highlightMoveDuration/Material.accentColor
                // highlight, neither of which this drawer wants.
                contentItem: Row {
                    anchors.fill: parent
                    Repeater {
                        model: tabBar.contentModel
                    }
                }

                // Populated via Repeater over tabModel rather than four
                // static TabButton children — TabBar's own contentModel
                // picks up Repeater-generated children the same as
                // statically-declared ones (documented QQC2 pattern). This
                // Repeater GENERATES the four TabButton objects (thus
                // populating contentModel); the Row+Repeater above merely
                // POSITIONS whatever contentModel already holds — two
                // different Repeaters serving two different jobs.
                Repeater {
                    model: tabModel

                    delegate: TabButton {
                        id: tabButtonDelegate

                        required property int index
                        required property string label
                        required property string symbol

                        // Derived from `header.width` (the wrapping Item,
                        // anchored directly to the content root), NOT
                        // `tabBar.width` — binding to the control's own
                        // width here would feed back into TabBar's
                        // Control.implicitWidth (which reads
                        // implicitContentWidth off this Row's own implicit
                        // size, itself a function of every button's width)
                        // and trip QML's binding-loop detector, even though
                        // tabBar's actual `width` is fixed by its own
                        // anchors.fill and never truly unstable. `header`
                        // has no such feedback path.
                        width: header.width / dashboardWindow.tabCount

                        // No ripple rectangle paints an untokenised colour.
                        background: Item {}

                        contentItem: Column {
                            spacing: dashboardWindow.spacingXs

                            Text {
                                id: iconGlyph
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tabButtonDelegate.symbol
                                font.family: dashboardWindow.symbolFontFamily
                                font.pixelSize: dashboardWindow.iconSizeMd
                                // D-25/D-26's outlined-to-filled lit-state
                                // language, applied to tabs — 14-02-SUMMARY.md
                                // recorded the fill-axis-renders verdict on
                                // this build, so the FILL axis is bound (not
                                // left static).
                                property real iconFill: tabButtonDelegate.index === pager.currentIndex ? 1 : 0
                                font.variableAxes: { "FILL": iconFill }
                                Behavior on iconFill {
                                    enabled: Motion.motionEnabled
                                    NumberAnimation {
                                        duration: Motion.standardDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Motion.standardEasing
                                    }
                                }
                                // Colour reads the pager, never this
                                // button's own `checked` state (D-16) — the
                                // two can never disagree.
                                color: tabButtonDelegate.index === pager.currentIndex ? Colours.onSurface : Colours.onSurfaceVariant
                                Behavior on color {
                                    enabled: Motion.motionEnabled
                                    ColorAnimation {
                                        duration: Motion.standardDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Motion.standardEasing
                                    }
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tabButtonDelegate.label
                                font.pixelSize: dashboardWindow.fontLabel
                                font.weight: dashboardWindow.weightBody
                                color: tabButtonDelegate.index === pager.currentIndex ? Colours.onSurface : Colours.onSurfaceVariant
                                Behavior on color {
                                    enabled: Motion.motionEnabled
                                    ColorAnimation {
                                        duration: Motion.standardDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Motion.standardEasing
                                    }
                                }
                            }
                        }

                        // D-16's direct tap-to-jump — animates over
                        // Motion.standardDuration because it moves the
                        // same contentX highlightMoveDuration animates.
                        onClicked: pager.setCurrentIndex(tabButtonDelegate.index)
                    }
                }
            }

            // MD3 primary-tab active indicator (D-16) — its x is derived
            // from swipeProgress alone, so it tracks the drag continuously
            // rather than jumping on commit. No Behavior/animation on x:
            // the value already moves with highlightMoveDuration's own
            // animation of contentX: a second animation on top would make
            // the indicator lag the content it reports.
            Rectangle {
                id: tabIndicator
                height: dashboardWindow.tabIndicatorHeight
                // header.width, not tabBar.width — same binding-loop
                // avoidance rationale as the TabButton width above.
                width: (header.width / dashboardWindow.tabCount) / 2
                y: header.height - height
                topLeftRadius: 4
                topRightRadius: 4
                bottomLeftRadius: 0
                bottomRightRadius: 0
                color: Colours.primary
                x: {
                    var cellWidth = header.width / dashboardWindow.tabCount;
                    return cellWidth * dashboardWindow.swipeProgress + (cellWidth - width) / 2;
                }
            }
        }

        // Re-asserts the header's currentIndex on every pager change —
        // TabBar writes its own currentIndex imperatively when a button is
        // clicked (Container's internal click handling), which breaks a
        // plain binding; this Connections block is what makes the one-way
        // flow (pager holds selection, header reports it) hold for the
        // surface's whole lifetime rather than until the first tap.
        Connections {
            target: pager
            function onCurrentIndexChanged() {
                tabBar.setCurrentIndex(pager.currentIndex);
                dashboardWindow.tabSelected(pager.currentIndex);
            }
        }

        // ── The pager (D-17/D-18, RESEARCH Pattern 3/4) ─────────────────
        SwipeView {
            id: pager
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            // Zero spacing so the contentItem's scroll offset maps to the
            // tab index with no correction term (swipeProgress relies on
            // this).
            spacing: 0

            // ── Yield the swipe while a page's slider is being dragged ────
            // This pager's contentItem is a horizontal ListView (below), and
            // a Flickable ancestor steals a drag from a child control once
            // the drag threshold is exceeded. That made every slider on the
            // Media tab click-only: the press landed and the value jumped,
            // but a drag was grabbed by the flick and became a tab swipe.
            // Reported at Phase 21 Plan 08's gate for the switcher's
            // per-player volume rows; it applied equally to the seek band
            // (C-10, drag-to-position) and the main volume slider.
            //
            // MediaTab publishes `controlDragActive` for exactly this, held
            // for as long as any of its sliders is pressed. Only the media
            // page is consulted because it is the only page that owns drag
            // controls today; a future page with its own sliders declares
            // the same property and gets added to this expression. The
            // `=== true` keeps an undefined property (a page that does not
            // declare it, or a Loader whose item has not been created yet)
            // from reading as truthy and disabling the swipe outright.
            interactive: !(mediaTabLoader.item && mediaTabLoader.item.controlDragActive === true)

            // RESEARCH Pattern 4 (borrowed from Caelestia, not its pager
            // mechanism): one Loader per tab, active only when it is the
            // current tab, so an off-screen Performance/Weather tab runs
            // no timers or fetches. asynchronous:false so a tab is present
            // the instant the swipe reaches it.
            Loader {
                id: dashboardTabLoader
                active: pager.currentIndex === dashboardWindow.tabIndexDashboard
                asynchronous: false
                sourceComponent: Component {
                    DashboardTab {
                        mediaBackend: dashboardWindow.mediaBackend
                        systemResources: dashboardWindow.systemResources
                        // 15-07 — fully qualified `dashboardWindow.` on every
                        // right-hand side: DashboardTab declares identically
                        // named properties, and a bare RHS here would resolve
                        // to that tab's own not-yet-assigned property under
                        // QML's innermost-scope-wins lookup (the live-
                        // reproduced shadowing bug this file's own header
                        // above records for systemResources).
                        audioBackend: dashboardWindow.audioBackend
                        wifiBackend: dashboardWindow.wifiBackend
                        bluetoothBackend: dashboardWindow.bluetoothBackend
                        mediaTabIndex: dashboardWindow.tabIndexMedia
                        performanceTabIndex: dashboardWindow.tabIndexPerformance
                        // D-39/D-40's compact-widget → its-full-tab deep-link
                        // convention, answered here once so 14-08 only has
                        // to emit.
                        onTabRequested: (index) => pager.setCurrentIndex(index)
                        // 15-07 — the exact analog for the tile chevron's
                        // relay: a tab-level signal answered once at the
                        // drawer level, forwarded unchanged.
                        onPanelRequested: (name) => dashboardWindow.panelRequested(name)
                    }
                }
                onLoaded: Qt.callLater(dashboardWindow.runCascadeForActivePane)
            }

            Loader {
                id: mediaTabLoader
                active: pager.currentIndex === dashboardWindow.tabIndexMedia
                asynchronous: false
                sourceComponent: Component {
                    MediaTab {
                        mediaBackend: dashboardWindow.mediaBackend
                    }
                }
                onLoaded: Qt.callLater(dashboardWindow.runCascadeForActivePane)
            }

            Loader {
                id: performanceTabLoader
                active: pager.currentIndex === dashboardWindow.tabIndexPerformance
                asynchronous: false
                sourceComponent: Component {
                    PerformanceTab {
                        systemResources: dashboardWindow.systemResources
                    }
                }
                onLoaded: Qt.callLater(dashboardWindow.runCascadeForActivePane)
            }

            Loader {
                id: weatherTabLoader
                active: pager.currentIndex === dashboardWindow.tabIndexWeather
                asynchronous: false
                sourceComponent: Component {
                    WeatherTab {
                        weatherBackend: dashboardWindow.weatherBackend
                        settledPaneWidth: dashboardWindow.settledPaneWidth
                        settledPaneHeight: dashboardWindow.settledPaneHeight
                    }
                }
                onLoaded: Qt.callLater(dashboardWindow.runCascadeForActivePane)
            }

            // ── RESEARCH Pitfall 1 — the whole point of this override:
            //    a custom ListView contentItem reproducing every property
            //    the stock Basic SwipeView.qml sets, with three deliberate
            //    differences (highlightMoveDuration bound to the motion
            //    token instead of Qt's literal 250; keyNavigationEnabled
            //    and focus both false so arrow keys and the content root's
            //    Escape handler are unaffected). Ship the stock drag
            //    physics with no custom threshold override — RESEARCH
            //    assumption A5/Open Question 5 defer that judgement to
            //    Task 3's render gate.
            //
            //    motion-lint's QML raw-value check is anchored on a
            //    lowercase `duration:` and the camel-cased
            //    `highlightMoveDuration` property name never matches it —
            //    a future edit dropping this back to a literal would pass
            //    every gate in the repo silently. This binding is a source
            //    assertion for exactly that reason (see 14-03-PLAN.md's
            //    acceptance criteria).
            contentItem: ListView {
                id: pagerList
                model: pager.contentModel
                interactive: pager.interactive
                currentIndex: pager.currentIndex
                focus: false

                spacing: pager.spacing
                orientation: pager.orientation
                snapMode: ListView.SnapOneItem
                boundsBehavior: Flickable.StopAtBounds

                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: 0
                highlightMoveDuration: Motion.standardDuration
                maximumFlickVelocity: 4 * (pager.orientation === Qt.Horizontal ? width : height)

                keyNavigationEnabled: false
            }
        }
    }
    }
}

