// compliant-no-mpris-reader.qml — self-test fixture (21-04, QMEDIA-03).
// An ordinary QML file with no MPRIS surface at all — no
// Quickshell.Services.Mpris import, no Mpris* type instantiation, not
// even a prose mention. Stands in for the zero-reader boundary: the real
// reader was deleted or moved, which is a defect, not a clean state.
// Target check: the standing MPRIS-reader-count check (source half, via
// _qsd_assert_mpris_reader). Expected verdict when this file is the ONLY
// file in the scanned directory: FAIL (hits=0).

import QtQuick

QtObject {
    id: root
    property int dummy: 0
}
