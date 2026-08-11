// TrayCapsule.qml — the system tray slot (Phase 18 Plan 05, D-18-10).
//
// Owner: 18-10 — native Quickshell.Services.SystemTray plus
// Quickshell.DBusMenu, always visible with no chevron and no threshold
// collapse per D-18-04, bounded at trayMaxExtent with internal scroll.
// Entries BarEntryModel already declares for this capsule: `tray`.
//
// No content in this plan. At zero tray icons this capsule collapses and
// disappears from the layout entirely — the shared chrome's own
// visibility rule already delivers that, so 18-10 does not need to
// reimplement it. Rendering an invented icon here would be fabricated
// data, which this phase forbids outright.

BarCapsule {
    capsuleId: "tray"
}
