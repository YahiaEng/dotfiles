// modules/appearance/AtFontsTab.qml — the Atelier's Fonts tab (quick task
// 260828-ah9, Task 2). A ListView over `AppearanceBackend.fontFamilies`,
// each row rendered IN that row's own font.
//
// M2 — MEASURED, not a style choice: 13 of 39 installed font entries are
// metrically identical twins. 39 names = 13 families x {`Nerd Font`,
// `Nerd Font Mono`, `Nerd Font Propo`}; `Nerd Font` and `Nerd Font Mono`
// are identical on every probed advance width (fontTools hmtx/head,
// checked across FiraCode/JetBrainsMono/Hack/Iosevka/CaskaydiaCove/
// MesloLGS) — only `Propo` differs, and only on icon glyphs. This tab
// therefore renders 13 families x 2 SPACING BEHAVIOURS (Mono/Propo),
// never 39 rows and NEVER a third "Nerd Font alone" row — if a future
// edit reintroduces that cut, it is re-offering the exact same font
// twice. `AppearanceBackend.fontFamilies` already resolved which raw
// name backs each behaviour; this file only renders what it hands back.
import QtQuick
import ".."
import "../dashboard"

Item {
    id: root

    readonly property var _families: AppearanceBackend.fontFamilies

    Text {
        anchors.centerIn: parent
        visible: root._families.length === 0
        text: AppearanceBackend.rawFontsProbed ? "No nerd fonts found" : "Loading fonts…"
        color: Colours.outline
        font.pixelSize: Design.settingsFontSub
    }

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        model: root._families

        delegate: Rectangle {
            id: row
            required property var modelData

            width: list.width
            height: 108
            radius: 12
            color: row.modelData.active ? Colours.surfaceVariant : "transparent"

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Design.spacingMd
                spacing: Design.spacingXs

                Row {
                    spacing: Design.spacingSm

                    Text {
                        text: row.modelData.family
                        color: row.modelData.active ? Colours.primary : Colours.onSurface
                        font.pixelSize: Design.settingsFontRow
                        textFormat: Text.PlainText
                    }

                    Rectangle {
                        visible: row.modelData.behaviour.length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 8
                        color: Colours.surfaceVariant
                        width: behaviourChip.implicitWidth + Design.spacingSm
                        height: behaviourChip.implicitHeight + 4

                        Text {
                            id: behaviourChip
                            anchors.centerIn: parent
                            text: row.modelData.behaviour === "mono" ? "Mono" : (row.modelData.behaviour === "propo" ? "Propo" : "")
                            color: Colours.primary
                            font.pixelSize: Design.fontLabel
                            textFormat: Text.PlainText
                        }
                    }
                }

                // Pangram — rendered IN the row's own font, per family.
                Text {
                    text: "The quick brown fox jumps over the lazy dog"
                    font.family: row.modelData.rawName
                    font.pixelSize: 16
                    color: Colours.onSurfaceVariant
                    textFormat: Text.PlainText
                }

                // A short code sample.
                Text {
                    text: "fn main() { let x = 42; println!(\"{}\", x); }"
                    font.family: row.modelData.rawName
                    font.pixelSize: 13
                    color: Colours.onSurfaceVariant
                    textFormat: Text.PlainText
                }

                // Nerd Font glyph run — home / folder / git-branch /
                // terminal / gear, the same five code points
                // font-switcher.sh's own retired preview verified present
                // in the installed set's cmap. Written as explicit `\u`
                // escapes, never a literal pasted glyph — a private-use
                // codepoint is invisible in a diff and in this file's own
                // source, so an escape is the only anchor a later edit
                // (or `git blame`) can actually read.
                Text {
                    text: "\uf015 \uf07b \ue725 \uf489 \uf013"
                    font.family: row.modelData.rawName
                    font.pixelSize: 18
                    color: Colours.onSurfaceVariant
                    textFormat: Text.PlainText
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: AppearanceBackend.applyFont(row.modelData.rawName)
            }
        }
    }
}
