// colour-lint fixture (18-03, GATE-04).
// Models CHECK B1 — a `color:`-family property assignment carrying a
// quoted hex right-hand side. Never loaded by any live Quickshell
// surface — colour-lint self-test fixture only.
import QtQuick

Rectangle {
    id: root
    color: "#1A1A2E" // CORRUPTED: was Colours.surface
}
