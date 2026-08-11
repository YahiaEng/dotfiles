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
// and hover mechanics (18-13/14), auto-hide and the `bar` IPC handler
// (18-15), the hot zone (18-16), doctor checks (18-17), the restart unit
// (18-07, QBAR-10).
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
    // LIVE-MEASURED CORRECTION (this task, found and fixed the same way
    // 18-01's Task 2 found and fixed the original instance of this exact
    // bug): the surface's own submitted exclusiveZone is its content
    // extent ALONE — Design.barHeight horizontally, Design.barColumnWidth
    // vertically — never plus the edge margin, because Hyprland's own
    // reservation TOTAL is margins.<anchored-edge> + exclusiveZone, and
    // margins.top/.right above ALREADY carry Design.barEdgeMargin on
    // their respective axis. Folding it into exclusiveZone too would
    // double-count it — reproduced live this task (co-existing reading
    // [[0,98,0,0]] instead of the expected [[0,92,0,0]], the exact +6
    // signature of the double-margin bug) before being corrected here.
    // Total reservation = margins.<edge> + exclusiveZone. Horizontally
    // that total is Design.barHeight + Design.barEdgeMargin = 46,
    // unchanged from 18-01's live-proven arithmetic; vertically it is
    // Design.barColumnWidth + Design.barEdgeMargin = 50 — a SINGLE edge
    // margin on whichever axis is anchored, never doubled into both
    // terms. Both terms below are compile-time expressions over readonly
    // property int tokens; no runtime value reaches either.
    exclusiveZone: barWindow.vertical ? Design.barColumnWidth : Design.barHeight
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
