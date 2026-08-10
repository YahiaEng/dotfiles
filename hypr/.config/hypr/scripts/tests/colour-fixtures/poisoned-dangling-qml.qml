// colour-lint fixture (18-03, GATE-04).
// Models CHECK A — a reference to a `Colours.<name>` that Colours.qml
// does not declare. Resolved against the LIVE Colours.qml at self-test
// time (colour-lint's definition source lives outside any fixture
// directory), so the dangling name below is one no live role could
// plausibly acquire. Never loaded by any live Quickshell surface —
// colour-lint self-test fixture only.
import QtQuick

Rectangle {
    id: root
    color: Colours.definitelyNotARealRole // CORRUPTED: was Colours.surface
}
