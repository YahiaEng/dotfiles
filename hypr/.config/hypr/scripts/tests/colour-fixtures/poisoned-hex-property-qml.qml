// colour-lint fixture (18-03, GATE-04).
// Models CHECK B2 — a `property color <name>:` declaration carrying a
// quoted hex right-hand side. Carries, in the SAME file, a co-located
// `property string` declaration with a quoted hex default mirroring
// Colours.qml's own JsonAdapter fallback shape (`property string
// <name>: "#FF00FF"`) — that sibling line must NOT be flagged, since it
// is string-typed, not colour-typed. This is the single most important
// assertion in the whole plan: it proves the 19 Colours.qml false
// positives are structurally excluded rather than incidentally missed.
// Never loaded by any live Quickshell surface — colour-lint self-test
// fixture only.
import QtQuick

QtObject {
    id: root
    readonly property color accentGlow: "#00FF00" // CORRUPTED: was Colours.primary via a real color property
    property string debugFallback: "#FF00FF"
}
