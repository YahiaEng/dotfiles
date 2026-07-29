// QuickToggles.qml — inert toggle-grid stub (Phase 14 Plan 03, filled by
// Plan 14-04, D-23..D-27: 3 swaync-mirrored chips — Gaming, DND, Dark —
// plus the motion-scale segmented row).
//
// Root type Item. Not mounted by this plan — 14-04 mounts this inside
// DashboardTab as the tab's footer row (D-38). Left completely unsized and
// content-free in stub form: nothing reaches for this type until 14-04
// wires it in, so there is no drawer-frame sizing concern yet (D-04 only
// bites once something is actually mounted).
//
// D-41 widget-state register — "populated" / "pending" / "empty" — carried
// on every one of this phase's nine modules/dashboard/ files.
import QtQuick

Item {
    id: root

    // D-41: "populated" | "pending" | "empty"
    property string widgetState: "empty"
}
