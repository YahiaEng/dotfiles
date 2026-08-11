// MediaConnectivityCapsule.qml — the media + connectivity slot (Phase 18
// Plan 05, D-18-10).
//
// Owner: 18-08 — media, audio, network, bluetooth, battery; battery
// renders nothing when absent per D-18-06; network renders its glyph
// only.
// Entries BarEntryModel already declares for this capsule: `media`,
// `audio`, `network`, `bluetooth`, `battery`.
//
// No content in this plan. Rendering an invented reading here would be
// fabricated data, which this phase forbids outright — an empty slot is
// an honest, complete structural declaration; the shared chrome's own
// visibility rule already removes it (and its share of the gap) from the
// layout until 18-08 fills it.

BarCapsule {
    capsuleId: "mediaConnectivity"
}
