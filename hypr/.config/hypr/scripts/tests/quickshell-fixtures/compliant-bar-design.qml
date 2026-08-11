// compliant-bar-design.qml — Synthetic fixture (Phase 18 Plan 17, QBAR-12).
// Minimal stand-in for the real Design.qml's bar tokens, in the EXACT
// `readonly property int <name>: <value>` declaration form the real file
// uses (18-01/18-05 provenance) — the expected-extent parser matches on
// this exact shape. Target: _qsd_expected_extent. Expected verdict:
// axis 1 (top) resolves to barHeight+barEdgeMargin, axis 2 (right)
// resolves to barColumnWidth+barEdgeMargin — both PASS, and the two
// values differ (proving a single edge margin is applied once per axis,
// never doubled into both).
pragma Singleton
import QtQuick

QtObject {
    readonly property int barHeight: 40
    readonly property int barEdgeMargin: 6
    readonly property int barColumnWidth: 44
}
