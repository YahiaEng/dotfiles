// colour-lint fixture (18-03, GATE-04).
// Models a fully compliant QML surface: every colour resolves through a
// real Colours.<role> token, plus the single sanctioned literal
// `color: "transparent"` on the root — proving that literal is genuinely
// sanctioned rather than merely unmatched by accident (B4's control case).
// Also carries a compliant Qt.rgba(...) token-plus-opacity call, proving
// that idiom is never flagged by CHECK B3. Never loaded by any live
// Quickshell surface — colour-lint self-test fixture only.
import QtQuick

Rectangle {
    id: root
    color: "transparent"

    property color accent: Colours.primary

    Rectangle {
        anchors.fill: parent
        color: Colours.surface
        border.color: Colours.outline

        MultiEffect {
            anchors.fill: parent
            shadowEnabled: true
            shadowColor: Qt.rgba(accent.r, accent.g, accent.b, 0.35)
        }

        Text {
            color: Colours.onSurface
            text: "compliant"
        }
    }
}
