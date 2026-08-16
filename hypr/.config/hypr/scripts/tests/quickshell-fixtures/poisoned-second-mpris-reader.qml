// poisoned-second-mpris-reader.qml — self-test fixture (21-04, QMEDIA-03).
// A second, differently-named file that also imports
// Quickshell.Services.Mpris — simulating QMEDIA-03's forbidden case: a
// second, uncoordinated MPRIS reader appearing alongside the real one
// (MediaBackend.qml). This is the case the standing check exists to
// prevent, and the one a live run on a healthy tree can never exercise.
// Target check: the standing MPRIS-reader-count check (source half, via
// _qsd_assert_mpris_reader). Expected verdict when copied alongside
// MediaBackend.qml into the same scanned directory: FAIL (hits=2).

import QtQuick
import Quickshell.Services.Mpris

QtObject {
    id: root
}
