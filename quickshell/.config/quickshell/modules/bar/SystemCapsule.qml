// SystemCapsule.qml — the system-readouts slot (Phase 18 Plan 05, D-18-10).
//
// Owner: 18-08 — cpu, ram, disk and updates against the existing
// SystemResources backend.
// Entries BarEntryModel already declares for this capsule: `cpu`, `ram`,
// `disk`, `updates`.
//
// No content in this plan. Rendering an invented percentage or a
// stand-in label here would be fabricated data, which this phase forbids
// outright — an empty slot is an honest, complete structural declaration;
// the shared chrome's own visibility rule already removes it (and its
// share of the gap) from the layout until 18-08 fills it.

BarCapsule {
    capsuleId: "system"
}
