// poisoned-prose-only-mpris-mention.qml — self-test fixture (21-04,
// QMEDIA-03). This file's ONLY mention of the MPRIS surface is inside
// this very sentence, naming the service by name with no import
// statement and no type instantiation anywhere below. Protects the
// standing check's precision guarantee: a documentation comment merely
// mentioning the service must never increment the reader count, only an
// actual API surface (an import line or a `Mpris*{` instantiation) may.
// Target check: the standing MPRIS-reader-count check (source half, via
// _qsd_assert_mpris_reader). Expected verdict when copied alongside
// MediaBackend.qml into the same scanned directory: PASS, with the
// reported count still exactly 1 (hits=1, basenames=MediaBackend.qml) —
// this file must contribute zero to that count.

import QtQuick

QtObject {
    id: root
}
