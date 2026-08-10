// colour-lint fixture (18-03, GATE-04).
// Models CHECK B3 — a Qt.rgba/hsla/hsva call whose first three arguments
// are all numeric literals. Carries, in the SAME file, a compliant
// token-plus-opacity call (Qt.rgba(base.r, base.g, base.b, 0.5)) that
// must NOT be flagged — a literal FOURTH argument (alpha) is explicitly
// in-contract, proving the idiom survives. Never loaded by any live
// Quickshell surface — colour-lint self-test fixture only.
import QtQuick

Rectangle {
    id: root
    property color base: "transparent"
    shadowColor: Qt.rgba(0, 0, 0, 0.5) // CORRUPTED: was Qt.rgba(base.r, base.g, base.b, 0.5)
    borderColor: Qt.rgba(base.r, base.g, base.b, 0.5)
}
