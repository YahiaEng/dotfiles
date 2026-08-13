// BarTooltipHost.qml — the dwell-timer + LazyLoader host each bar-window
// tooltip site mounts (quick task 260812-69w, F2). A plain, zero-size
// Item declared as a sibling of the hover target, never a wrapper around
// it — the four BAR-WINDOW sites (IdleInhibitorCapsule.qml,
// ClockActionsCapsule.qml's ActionCell, MediaConnectivityCapsule.qml,
// LauncherCapsule.qml) each declare one instance beside the MouseArea
// whose hover state drives `active`.
//
// The two POPOUT-WINDOW sites (AudioPopout.qml, SectionPopout.qml) do NOT
// use this host — Task 1's Probe B measured their tooltips rendering
// clear of their own glyph already, inside a window several hundred
// pixels tall, so converting them would fix nothing that was broken.
import QtQuick
import Quickshell
import "../"
import "../dashboard"

Item {
    id: hostRoot
    width: 0
    height: 0

    // ── Public contract ───────────────────────────────────────────────
    property Item anchorItem: null
    property string text: ""
    property bool active: false
    property string tipId: ""

    // Published ONCE when the dwell timer fires, never a live binding —
    // scene mapping does not re-evaluate when an ancestor moves, the same
    // reasoning SectionPopout.qml's own triggerCentre and BarDrawer.qml's
    // own triggerCentre both carry.
    property real _publishedCentre: 0
    property bool _dwellElapsed: false

    // ── Host clearance (2026-08-13) ───────────────────────────────────
    // How far the tooltip must be pushed off the bar's edge to avoid
    // covering the surface its own anchor lives in.
    //
    // In vertical orientation BarTooltip anchors right with a spacingXs
    // gap, and that gap is measured from the RESERVED boundary — so a
    // tooltip for a bar cell lands just clear of the bar, which is right.
    // But a settings-axis cell lives in BarDrawer, a floating surface that
    // extends 146px further left (its own margins.right 10 + width 136),
    // so the same gap put the tooltip directly on top of the five options
    // it was describing — the operator's "their placement is obstructing
    // the view", measured as a tooltip at x 2448..2506 over a drawer at
    // 2364..2500.
    //
    // The discriminator is `exclusiveZone`, not a name or a size: a host
    // that RESERVES its space is already behind the boundary the tooltip
    // measures from and needs no clearance, while a host that floats over
    // the desktop must be stepped around. That keeps this correct for any
    // future floating host without another special case here.
    readonly property real _hostClearance: {
        var win = QsWindow.window;
        if (!win || !win.margins)
            return 0;
        if (win.exclusiveZone && win.exclusiveZone > 0)
            return 0;
        return win.margins.right + win.width;
    }

    onActiveChanged: {
        if (hostRoot.active) {
            dwellTimer.restart();
        } else {
            dwellTimer.stop();
            hostRoot._dwellElapsed = false;
        }
    }

    Timer {
        id: dwellTimer
        interval: Design.tooltipDelayMs
        repeat: false
        onTriggered: {
            if (!hostRoot.anchorItem)
                return;
            var scenePos = hostRoot.anchorItem.mapToItem(null, hostRoot.anchorItem.width / 2, hostRoot.anchorItem.height / 2);
            // ── Window-origin conversion (2026-08-13) ────────────────────
            // `mapToItem(null, ...)` maps into the item's OWN WINDOW, never
            // the screen — a fact this family assumed the other way round in
            // three separate files. BarTooltip positions itself with
            // `margins`, which ARE screen-relative, so the two spaces differ
            // by the host window's own origin and the tooltip has to add it.
            //
            // This went unnoticed while every tooltip site lived in the bar
            // window, where the error is a uniform 10px (Design.barSideMargin,
            // the bar's own margin) — visible only if you measured. It became
            // obvious once ActionCell was reused inside BarDrawer, which is a
            // SEPARATE window: a settings-axis cell then mapped to ~12 inside
            // that drawer, and its tooltip rendered at screen y=10, clamped to
            // the top of the display about 1370px from the cell it describes.
            // Measured live: tooltip surface `quickshell-bartip-clockActions-
            // contrast` at (2448, 10) while its cell sat at y=1386. The
            // operator reported it as the settings options having "no
            // tooltips", which is what a tooltip in the far corner looks like.
            //
            // `QsWindow.window.margins` is the general answer rather than a
            // per-site constant: for the bar it yields barSideMargin, for the
            // drawer it yields that drawer's own computed screen top, and any
            // future host window is correct without touching this file.
            var win = QsWindow.window;
            var originX = (win && win.margins) ? win.margins.left : 0;
            var originY = (win && win.margins) ? win.margins.top : 0;
            hostRoot._publishedCentre = BarEntryModel.isVertical ? (scenePos.y + originY) : (scenePos.x + originX);
            hostRoot._dwellElapsed = true;
        }
    }

    // Nothing exists while nothing is hovered — the same LazyLoader
    // lifecycle HotZone.qml established under D-18-24: active only while
    // BOTH the dwell has elapsed AND the hover that armed it is still
    // live, so a pointer that left before the dwell finished never
    // mounts a surface at all.
    LazyLoader {
        id: tooltipLoader
        active: hostRoot._dwellElapsed && hostRoot.active

        BarTooltip {
            text: hostRoot.text
            vertical: BarEntryModel.isVertical
            triggerCentre: hostRoot._publishedCentre
            tipId: hostRoot.tipId
            hostClearance: hostRoot._hostClearance
        }
    }
}
