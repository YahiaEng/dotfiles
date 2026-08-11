// WorkspaceCapsule.qml — the workspaces slot (Phase 18 Plan 05, D-18-10).
//
// Owner: 18-09 — live per-app window icons in athena's icon-plus-windows
// shape per D-18-02, fixed-height slots with +N overflow in BOTH
// orientations per D-18-12, click-to-switch through Quickshell.Hyprland
// copying Overview.qml's validate-before-interpolate discipline.
// Entries BarEntryModel already declares for this capsule: `workspaces`.
//
// No content in this plan. Rendering an invented workspace icon here
// would be fabricated data, which this phase forbids outright — an empty
// slot is an honest, complete structural declaration; the shared chrome's
// own visibility rule already removes it (and its share of the gap) from
// the layout until 18-09 fills it.

BarCapsule {
    capsuleId: "workspaces"
}
