// MediaBackend.qml — self-test fixture (21-04, QMEDIA-03). A minimal
// stand-in for the real quickshell/.config/quickshell/modules/dashboard/
// MediaBackend.qml, carrying only what the MPRIS-reader-count check's
// regex actually matches: the Quickshell.Services.Mpris import line. Not
// a functional Quickshell singleton — provenance is the check's own
// target pattern, not a trimmed copy of the shipped file.
// Target check: the standing MPRIS-reader-count check (source half, via
// _qsd_assert_mpris_reader). Filename is load-bearing — the check also
// asserts the single match's basename equals "MediaBackend.qml"
// (T-21-08's identity guarantee), so this fixture must keep this exact
// name when copied into a self-test tmpdir.
// Expected verdict when this file is the ONLY file in the scanned
// directory: PASS (hits=1, basenames=MediaBackend.qml).

import QtQuick
import Quickshell.Services.Mpris

QtObject {
    id: root
}
