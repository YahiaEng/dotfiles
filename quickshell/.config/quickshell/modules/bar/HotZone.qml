// HotZone.qml — the invisible input-only reveal surface (Phase 18 Plan 16,
// QBAR-08). One transparent PanelWindow, one hover handler, nothing else.
//
// Mounted by shell.qml behind a loader keyed on the INVERSE of the owner's
// base visible state — the LazyLoader.active idiom (D-18-24) — so this
// surface exists only while the bar is hidden and costs nothing while it
// is visible: no wl_surface, no handler, zero idle cost.
// `bar-visibility.sh` remains the sole owner of visibility; this file only
// reports hover through BarReveal.reportHover() below and writes nothing.
//
// Copies Overview.qml's layer posture (modules/Overview.qml lines 26-70)
// verbatim, changing only what must change: anchors (the full physical
// edge, not the whole screen), cross-axis extent (Design.hotZoneDepth, not
// the whole screen) and layer (Overlay, so the strip receives the pointer
// above a fullscreen client — the only state hover reveal is reachable in,
// per this plan's objective: idle-hide clears on any pointer movement
// through hypridle's own on-resume listener, so the pointer motion that
// would reach this strip clears the idle intent first). A session-lock
// surface sits above even the overlay layer, so this strip is inert while
// the screen is locked.
//
// No click-, wheel- or drag-accepting item exists anywhere in this file —
// deliberately, and permanently. The strip must never ACT on a press: a
// click it unavoidably consumes (T-18-16-01, this plan's threat register)
// must do NOTHING rather than something wrong. A HoverHandler tracks
// pointer enter/leave without grabbing button state, so a click passing
// through this surface reaches nothing here to mishandle it. If a future
// reader wants to add a click handler, read T-18-16-01 first — the bound
// depth, the bound lifetime and this click-inert posture are the three
// reasons that threat's residual is rated `medium` and not `high`.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../dashboard"

PanelWindow {
    id: hotZoneWindow

    // The same entry-model boolean every capsule already binds to — one
    // orientation truth in the shell, not a second.
    readonly property bool vertical: BarEntryModel.isVertical

    anchors {
        top: true
        left: !hotZoneWindow.vertical
        right: true
        bottom: hotZoneWindow.vertical
    }

    // Cross-axis extent is the surface's OWN geometry — Design.hotZoneDepth
    // — never a coordinate comparison in QML, so the boundary is the
    // compositor's rather than arithmetic that can drift (this plan's
    // "boundary contract" edge truth). The free axis stretches to the full
    // monitor extent through the anchors above, the same zero-is-inert
    // idiom Bar.qml's own header documents for its own free axis.
    implicitHeight: hotZoneWindow.vertical ? 0 : Design.hotZoneDepth
    implicitWidth: hotZoneWindow.vertical ? Design.hotZoneDepth : 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-bar-hotzone"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false
    exclusiveZone: 0
    color: "transparent"

    // The sole content of this surface: one hover handler, reporting both
    // edges through BarReveal's single entry point. Nothing else — no
    // visual item, no text, no timing object of its own (the one timing
    // object this plan introduces lives in BarReveal.qml, not here).
    HoverHandler {
        id: hoverHandler
        onHoveredChanged: BarReveal.reportHover("hotzone", hoverHandler.hovered)
    }
}
