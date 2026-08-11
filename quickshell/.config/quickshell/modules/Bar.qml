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
import Quickshell
import Quickshell.Wayland
import "dashboard"
import "bar"

PanelWindow {
    id: barWindow

    // The single value the whole file binds to.
    readonly property bool vertical: BarEntryModel.isVertical

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
    margins.top: barWindow.vertical ? Design.barSideMargin : Design.barEdgeMargin
    margins.right: barWindow.vertical ? Design.barEdgeMargin : Design.barSideMargin
    margins.left: barWindow.vertical ? 0 : Design.barSideMargin
    margins.bottom: barWindow.vertical ? Design.barSideMargin : 0

    // ── Extent — the free axis is the one both opposite edges anchor, so
    //    the compositor's own stretch behaviour determines its real size
    //    regardless of implicit value here (18-01's own Bar.qml already
    //    proved this live: it set only implicitHeight and left
    //    implicitWidth unset entirely, and the left+right-anchored width
    //    stretched correctly). 0 on the free axis is therefore inert, not
    //    a magic number — the fixed axis's ternary branch is what is
    //    load-bearing. ──────────────────────────────────────────────────
    implicitHeight: barWindow.vertical ? 0 : Design.barHeight
    implicitWidth: barWindow.vertical ? Design.barColumnWidth : 0

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
    // that total is Design.barHeight + Design.barEdgeMargin = 46,
    // unchanged from 18-01's live-proven arithmetic; vertically it is
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

    // ── Summon seams — the ONLY two this file exposes, frozen for wave 3
    //    and wave 6 alike. A later plan needing a third seam has found an
    //    18-05 scope correction. Nothing emits from either here — 18-11's
    //    actions and 18-14's wayfinding links are the callers. ──────────
    signal panelRequested(string name)
    signal dashboardRequested(int tabIndex)

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
        if (capsuleId === "mediaConnectivity")
            return mediaConnectivityComponent;
        if (capsuleId === "clockActions")
            return clockActionsComponent;
        if (capsuleId === "tray")
            return trayComponent;
        return null;
    }

    // Binding all five backend handles to all six capsule types is
    // deliberate redundancy: it is what lets a wave-3 plan discover a
    // backend need inside its own file instead of editing this one and
    // serialising the wave.
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
        id: clockActionsComponent
        ClockActionsCapsule {
            audioBackend: barWindow.audioBackend
            mediaBackend: barWindow.mediaBackend
            systemResources: barWindow.systemResources
            wifiBackend: barWindow.wifiBackend
            bluetoothBackend: barWindow.bluetoothBackend
        }
    }
    Component {
        id: trayComponent
        TrayCapsule {
            audioBackend: barWindow.audioBackend
            mediaBackend: barWindow.mediaBackend
            systemResources: barWindow.systemResources
            wifiBackend: barWindow.wifiBackend
            bluetoothBackend: barWindow.bluetoothBackend
        }
    }

    Item {
        id: barContent
        anchors.fill: parent

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
                    duration: barWindow.barRendered ? Motion.standardDuration : Motion.emphasizedOutDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: barWindow.barRendered ? Motion.standardEasing : Motion.emphasizedOutEasing
                }
            }
            Behavior on y {
                enabled: Motion.motionEnabled
                NumberAnimation {
                    duration: barWindow.barRendered ? Motion.standardDuration : Motion.emphasizedOutDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: barWindow.barRendered ? Motion.standardEasing : Motion.emphasizedOutEasing
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
        Grid {
            id: startZone
            spacing: Design.spacingSm
            rows: barWindow.vertical ? -1 : 1
            columns: barWindow.vertical ? 1 : -1
            anchors.left: !barWindow.vertical ? parent.left : undefined
            anchors.top: barWindow.vertical ? parent.top : undefined
            anchors.verticalCenter: !barWindow.vertical ? parent.verticalCenter : undefined
            anchors.horizontalCenter: barWindow.vertical ? parent.horizontalCenter : undefined

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
            spacing: Design.spacingSm
            rows: barWindow.vertical ? -1 : 1
            columns: barWindow.vertical ? 1 : -1
            anchors.centerIn: parent

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
            spacing: Design.spacingSm
            rows: barWindow.vertical ? -1 : 1
            columns: barWindow.vertical ? 1 : -1
            anchors.right: !barWindow.vertical ? parent.right : undefined
            anchors.bottom: barWindow.vertical ? parent.bottom : undefined
            anchors.verticalCenter: !barWindow.vertical ? parent.verticalCenter : undefined
            anchors.horizontalCenter: barWindow.vertical ? parent.horizontalCenter : undefined

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
