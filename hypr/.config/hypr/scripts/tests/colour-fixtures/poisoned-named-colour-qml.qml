// colour-lint fixture (18-03, GATE-04).
// Models CHECK B4 — a `color:`-family assignment carrying a quoted named
// SVG colour that is neither a `#`-hex nor exactly "transparent",
// proving the hex-to-named-colour evasion is closed. Never loaded by any
// live Quickshell surface — colour-lint self-test fixture only.
import QtQuick

Rectangle {
    id: root
    color: "hotpink" // CORRUPTED: was Colours.surface
}
