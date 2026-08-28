// modules/appearance/AtTabBar.qml — the Atelier's Icons/Fonts/Catalogue
// tab strip (quick task 260828-ah9, Task 2). A plain Item-rooted
// component, not borrowed from `modules/packages/WbButton.qml` — this
// module owns its own button shape rather than importing a sibling one.
import QtQuick
import ".."
import "../dashboard"

Item {
    id: root

    property string currentTab: "icons"
    signal tabSelected(string tab)

    readonly property var _tabs: [
        {
            id: "icons",
            label: "Icons"
        },
        {
            id: "fonts",
            label: "Fonts"
        },
        {
            id: "catalogue",
            label: "Catalogue"
        }
    ]

    implicitHeight: 40

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Design.spacingSm

        Repeater {
            model: root._tabs

            delegate: Rectangle {
                id: tabDelegate
                required property var modelData

                readonly property bool selected: root.currentTab === tabDelegate.modelData.id

                width: tabLabel.implicitWidth + Design.spacingLg
                height: 32
                radius: 10
                // ── Operator round 2, defect 2 — WHY NOTHING LOOKED
                //    SELECTED. ────────────────────────────────────────────
                // The highlight was `Colours.surfaceVariant`, and the
                // Atelier's own body panel IS `surfaceVariant`
                // (`Atelier.qml`'s `surfaceBase`, drawn at 0.78 opacity).
                // A selected row was therefore the same role as the
                // surface behind it and read as no highlight at all,
                // while the detail pane updated correctly — exactly the
                // "expands on the right but does not highlight" report.
                // This is the fourth recurrence of this class in this
                // shell (the Dial track, and 14-10's GPU ring before it):
                // a widget that draws nothing is usually the same colour
                // as its backing surface, not broken data.
                //
                // The study already specified the answer and the build
                // diverged from it — `.frow.sel` is
                // `background: rgba(255,121,198,.13)` plus
                // `border-left: 2px solid var(--stage-acc)`. That is the
                // accent at 13%, which cannot collide with any surface
                // role, plus an accent bar that survives even if the
                // tint is lost to a low-contrast palette.
                color: tabDelegate.selected ? Qt.alpha(Colours.primary, 0.13) : "transparent"

                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.colourDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.colourEasing
                    }
                }

                Text {
                    id: tabLabel
                    anchors.centerIn: parent
                    text: tabDelegate.modelData.label
                    color: tabDelegate.selected ? Colours.primary : Colours.onSurfaceVariant
                    font.pixelSize: Design.settingsFontSub
                    textFormat: Text.PlainText

                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.colourDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.colourEasing
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.tabSelected(tabDelegate.modelData.id)
                }
            }
        }
    }
}
