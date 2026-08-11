// LauncherCapsule.qml — the launcher slot (Phase 18 Plan 05, D-18-10).
//
// Owner: 18-11 — D-18-01's 8-icon app-launcher drawer, which expands
// inward horizontally in vertical orientation per D-18-11.
// Entries BarEntryModel already declares for this capsule: `apps`.
//
// No content in this plan. Rendering an invented glyph or a stand-in
// label here would be fabricated data, which this phase forbids outright
// — an empty slot is an honest, complete structural declaration; the
// shared chrome's own visibility rule already removes it (and its share
// of the gap) from the layout until 18-11 fills it.

BarCapsule {
    capsuleId: "launcher"
}
