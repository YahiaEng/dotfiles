// Synthetic minimal stand-in (Phase 20 Plan 04, D-20-33) — the OSD
// surface's registry row (osd/Osd.qml|quickshell-osd|exact|3|noreserve|
// transient). Deliberately mirrors the REAL Osd.qml's shape rather than
// toast/Toast.qml's own literal-declaring fixture in this same directory:
// a bare `layerNamespace` property override, no direct
// `WlrLayershell.namespace` binding and no own `exclusiveZone` literal —
// so this fixture exercises _qsd_assert_bar_surface_registry_forward's two
// fallback markers (the layerNamespace declaration fallback, and the
// inherited-exclusiveZone fallback against this same fixture dir's
// toast/Toast.qml) rather than only the direct-literal path every other
// fixture here exercises.
import QtQuick

QtObject {
    property string layerNamespace: "quickshell-osd"
}
